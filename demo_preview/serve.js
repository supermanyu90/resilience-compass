// serve.js — zero-dependency static server + model reverse-proxy.
//
// Backend-agnostic: the browser always speaks the Ollama-shaped API (/api/tags, /api/chat with
// NDJSON streaming). This proxy talks to whichever backend you configure and TRANSLATES as needed,
// so the front-end never changes:
//
//   MODEL_BACKEND=ollama  (default)  -> pipe straight to Ollama's native /api/*   (OLLAMA_URL)
//   MODEL_BACKEND=openai             -> translate to the OpenAI-compatible /v1 API (OPENAI_BASE_URL)
//                                       — this is how you run on NVIDIA NIM (a Gemma NIM microservice),
//                                         Nebius AI Studio (hosted), vLLM, or Ollama's own /v1 endpoint.
//
// Env:
//   PORT             (default 8422)
//   MODEL_BACKEND    ollama | openai        (default ollama)
//   OLLAMA_URL       default http://127.0.0.1:11434
//   OPENAI_BASE_URL  default http://127.0.0.1:8000/v1   (local NVIDIA NIM; or https://api.studio.nebius.com/v1)
//   OPENAI_API_KEY   optional Bearer token (e.g. NGC key / build.nvidia.com)
//   MODEL_ID         optional fallback model id for the openai backend
//   GRADIUM_API_KEY  optional — enables the voice tier (Gradium STT/TTS); unset = voice buttons hidden
//   GRADIUM_VOICE_ID optional TTS voice id (default a library voice)
//
// All inference still runs on whatever host the backend points at — keep it local (on-prem NIM /
// Jetson / Ollama) to preserve the offline, on-device story.

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const ROOT = __dirname;
const PORT = process.env.PORT || 8422;
const BACKEND = (process.env.MODEL_BACKEND || 'ollama').toLowerCase();
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://127.0.0.1:11434';
const OPENAI_BASE = (process.env.OPENAI_BASE_URL || 'http://127.0.0.1:8000/v1').replace(/\/+$/, '');
const OPENAI_KEY = process.env.OPENAI_API_KEY || '';
const DEFAULT_MODEL = process.env.MODEL_ID || '';

// Optional voice tier (Gradium STT/TTS). Cloud service — key stays server-side, never in the browser.
const GRADIUM_KEY = process.env.GRADIUM_API_KEY || '';
const GRADIUM_BASE = (process.env.GRADIUM_BASE_URL || 'https://api.gradium.ai/api').replace(/\/+$/, '');
const GRADIUM_VOICE = process.env.GRADIUM_VOICE_ID || 'YTpq7expH9539ERJ';

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
};
const modFor = (u) => (u.protocol === 'https:' ? https : http);
const NDJSON = { 'content-type': 'application/x-ndjson', 'cache-control': 'no-cache' };
const MAX_BODY = 12 * 1024 * 1024; // hard cap on buffered request bodies (audio uploads etc.)

// Buffer a request body with a size limit; replies 413 and aborts if exceeded.
function bufferBody(req, res, max, binary, cb) {
  let size = 0; const chunks = [];
  req.on('data', (c) => {
    size += c.length;
    if (size > max) { if (!res.headersSent) { res.writeHead(413, { 'content-type': 'application/json' }); res.end(JSON.stringify({ error: 'payload too large' })); } req.destroy(); return; }
    chunks.push(c);
  });
  req.on('end', () => { if (res.writableEnded) return; cb(binary ? Buffer.concat(chunks) : Buffer.concat(chunks).toString()); });
  req.on('error', () => { if (!res.writableEnded) { res.writeHead(400); res.end(); } });
}

const server = http.createServer((req, res) => {
  if (req.url.startsWith('/gradium/')) return handleGradium(req, res);
  if (req.url.startsWith('/api/')) {
    return BACKEND === 'openai' ? handleOpenAI(req, res) : handleOllama(req, res);
  }
  serveStatic(req, res);
});

// ---------- Voice: Gradium STT/TTS proxy (key server-side) ----------
function handleGradium(req, res) {
  const p = req.url.split('?')[0];
  if (p === '/gradium/status') { // lets the UI show voice buttons only when configured
    res.writeHead(200, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ enabled: !!GRADIUM_KEY }));
  }
  if (!GRADIUM_KEY) { res.writeHead(503, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ error: 'voice not configured (set GRADIUM_API_KEY)' })); }
  if (req.method === 'POST' && p === '/gradium/tts') return gradiumTTS(req, res);
  if (req.method === 'POST' && p === '/gradium/stt') return gradiumSTT(req, res);
  res.writeHead(404, { 'content-type': 'application/json' }); res.end(JSON.stringify({ error: 'unknown voice route' }));
}

// text -> speech (returns audio/wav bytes)
function gradiumTTS(req, res) {
  bufferBody(req, res, 2e6, false, (raw) => {
    let text = '';
    try { text = (JSON.parse(raw || '{}').text || '').toString(); } catch (e) {}
    if (!text.trim()) { res.writeHead(400, { 'content-type': 'application/json' }); return res.end(JSON.stringify({ error: 'no text' })); }
    const body = JSON.stringify({ text: text.slice(0, 1500), voice_id: GRADIUM_VOICE, output_format: 'wav', only_audio: true, model_name: 'default' });
    const u = new URL(GRADIUM_BASE + '/post/speech/tts');
    const rq = https.request({ hostname: u.hostname, port: u.port || 443, path: u.pathname, method: 'POST',
      headers: { 'content-type': 'application/json', 'x-api-key': GRADIUM_KEY } }, (r) => {
      res.writeHead(r.statusCode || 502, { 'content-type': r.headers['content-type'] || 'audio/wav' });
      r.pipe(res);
    });
    rq.on('error', (e) => { res.writeHead(502, { 'content-type': 'application/json' }); res.end(JSON.stringify({ error: 'tts: ' + e.message })); });
    rq.write(body); rq.end();
  });
}

// speech (raw wav bytes) -> text  (parses Gradium's NDJSON, returns {text})
function gradiumSTT(req, res) {
  bufferBody(req, res, MAX_BODY, true, (audio) => {
    const u = new URL(GRADIUM_BASE + '/post/speech/asr?input_format=wav');
    const rq = https.request({ hostname: u.hostname, port: u.port || 443, path: u.pathname + u.search, method: 'POST',
      headers: { 'content-type': 'audio/wav', 'x-api-key': GRADIUM_KEY, 'content-length': audio.length } }, (r) => {
      let d = '';
      r.on('data', (c) => (d += c));
      r.on('end', () => {
        let txt = '';
        d.split('\n').forEach((line) => { line = line.trim(); if (!line) return;
          try { const o = JSON.parse(line); if (o.type === 'text') txt += (txt ? ' ' : '') + o.text; } catch (e) {} });
        txt = txt.replace(/\s+([,.!?;:])/g, '$1').replace(/\s{2,}/g, ' ').trim();
        res.writeHead(200, { 'content-type': 'application/json' }); res.end(JSON.stringify({ text: txt }));
      });
    });
    rq.on('error', (e) => { res.writeHead(502, { 'content-type': 'application/json' }); res.end(JSON.stringify({ error: 'stt: ' + e.message })); });
    rq.write(audio); rq.end();
  });
}

// ---------- Ollama backend: transparent streaming pipe ----------
function handleOllama(req, res) {
  const u = new URL(OLLAMA_URL);
  const up = modFor(u).request(
    { hostname: u.hostname, port: u.port || 11434, path: req.url, method: req.method,
      headers: { 'content-type': 'application/json' } },
    (r) => {
      res.writeHead(r.statusCode || 502,
        { 'content-type': r.headers['content-type'] || 'application/x-ndjson', 'cache-control': 'no-cache' });
      r.pipe(res);
    }
  );
  up.on('error', (e) => { res.writeHead(502, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: 'Ollama unreachable: ' + e.message })); });
  req.pipe(up);
}

// ---------- OpenAI-compatible backend (NVIDIA NIM / vLLM / Ollama /v1) ----------
function handleOpenAI(req, res) {
  const pathname = req.url.split('?')[0];
  bufferBody(req, res, 2e6, false, (raw) => {
    if (req.method === 'GET' && pathname === '/api/tags') return listModels(res);
    if (req.method === 'POST' && pathname === '/api/chat') return chatCompletions(raw, res);
    res.writeHead(404, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: 'unsupported endpoint: ' + pathname }));
  });
}

function oaHeaders() {
  const h = { 'content-type': 'application/json' };
  if (OPENAI_KEY) h['authorization'] = 'Bearer ' + OPENAI_KEY;
  return h;
}

// GET /api/tags  ->  GET {base}/models  ->  map to Ollama's {models:[{name}]}
function listModels(res) {
  const u = new URL(OPENAI_BASE + '/models');
  const rq = modFor(u).request(
    { hostname: u.hostname, port: u.port || (u.protocol === 'https:' ? 443 : 80),
      path: u.pathname + u.search, method: 'GET', headers: oaHeaders() },
    (r) => {
      let d = '';
      r.on('data', (c) => (d += c));
      r.on('end', () => {
        let models = [];
        try { models = (JSON.parse(d).data || []).map((m) => ({ name: m.id })); } catch (e) {}
        if (!models.length && DEFAULT_MODEL) models = [{ name: DEFAULT_MODEL }];
        res.writeHead(200, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ models }));
      });
    }
  );
  rq.on('error', (e) => { res.writeHead(502, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: 'NIM /models unreachable: ' + e.message })); });
  rq.end();
}

// Ollama message -> OpenAI message (handles multimodal images for vision NIMs)
function toOpenAIMessage(m) {
  if (m.images && m.images.length) {
    const content = [{ type: 'text', text: m.content || '' }];
    m.images.forEach((b64) => content.push({ type: 'image_url', image_url: { url: 'data:image/png;base64,' + b64 } }));
    return { role: m.role, content };
  }
  return { role: m.role, content: m.content };
}

// POST /api/chat (Ollama shape) -> POST {base}/chat/completions (OpenAI, SSE) -> back to NDJSON
function chatCompletions(raw, res) {
  let body = {};
  try { body = JSON.parse(raw || '{}'); } catch (e) {}
  const oa = {
    model: body.model || DEFAULT_MODEL,
    messages: (body.messages || []).map(toOpenAIMessage),
    stream: true,
    temperature: (body.options && typeof body.options.temperature === 'number') ? body.options.temperature : 0.6,
  };
  if (body.format === 'json') oa.response_format = { type: 'json_object' };

  const u = new URL(OPENAI_BASE + '/chat/completions');
  const rq = modFor(u).request(
    { hostname: u.hostname, port: u.port || (u.protocol === 'https:' ? 443 : 80),
      path: u.pathname + u.search, method: 'POST', headers: oaHeaders() },
    (r) => {
      if ((r.statusCode || 0) >= 400) { // surface upstream error as an NDJSON error line the app understands
        let d = '';
        r.on('data', (c) => (d += c));
        r.on('end', () => { res.writeHead(200, NDJSON);
          res.end(JSON.stringify({ error: 'NIM error ' + r.statusCode + ': ' + d.slice(0, 300) }) + '\n'); });
        return;
      }
      res.writeHead(200, NDJSON);
      let buf = '';
      r.on('data', (chunk) => {
        buf += chunk.toString();
        let i;
        while ((i = buf.indexOf('\n')) >= 0) {
          let line = buf.slice(0, i).trim();
          buf = buf.slice(i + 1);
          if (!line) continue;
          if (line.startsWith('data:')) line = line.slice(5).trim();
          if (line === '[DONE]') { res.write(JSON.stringify({ message: { content: '' }, done: true }) + '\n'); continue; }
          try {
            const j = JSON.parse(line);
            const delta = j.choices && j.choices[0] && j.choices[0].delta && j.choices[0].delta.content || '';
            if (delta) res.write(JSON.stringify({ message: { content: delta }, done: false }) + '\n');
          } catch (e) { /* keep-alive / non-JSON line */ }
        }
      });
      r.on('end', () => res.end(JSON.stringify({ message: { content: '' }, done: true }) + '\n'));
    }
  );
  rq.on('error', (e) => { res.writeHead(200, NDJSON);
    res.end(JSON.stringify({ error: 'NIM unreachable: ' + e.message }) + '\n'); });
  rq.write(JSON.stringify(oa));
  rq.end();
}

// ---------- static files (confined to ROOT) ----------
function serveStatic(req, res) {
  if (req.method !== 'GET' && req.method !== 'HEAD') { res.writeHead(405); return res.end('method not allowed'); }
  let rel;
  try { rel = decodeURIComponent(req.url.split('?')[0]); } catch (e) { res.writeHead(400); return res.end('bad request'); }
  if (rel === '/') rel = '/index.html';
  const filePath = path.normalize(path.join(ROOT, rel));
  // confine strictly to ROOT (avoid the sibling-prefix escape of a bare startsWith(ROOT))
  if (filePath !== ROOT && !filePath.startsWith(ROOT + path.sep)) { res.writeHead(403); return res.end('forbidden'); }
  // serve only known web assets; among scripts only logic.js; never server/test/dev scripts, manifests or dotfiles
  const base = path.basename(filePath), ext = path.extname(filePath);
  if (!TYPES[ext] || base.startsWith('.') || /^package(-lock)?\.json$/.test(base) || (ext === '.js' && base !== 'logic.js')) {
    res.writeHead(404); return res.end('not found');
  }
  fs.readFile(filePath, (err, data) => {
    if (err) { res.writeHead(404); return res.end('not found'); }
    res.writeHead(200, {
      'content-type': TYPES[path.extname(filePath)] || 'application/octet-stream',
      'x-content-type-options': 'nosniff', 'referrer-policy': 'no-referrer', 'x-frame-options': 'DENY',
    });
    res.end(req.method === 'HEAD' ? undefined : data);
  });
}

server.listen(PORT, () => {
  console.log('Resilience Compass demo → http://localhost:' + PORT);
  if (BACKEND === 'openai') console.log('Model backend: OpenAI-compatible (NVIDIA NIM) → ' + OPENAI_BASE);
  else console.log('Model backend: Ollama → ' + OLLAMA_URL);
  console.log('Voice (Gradium STT/TTS): ' + (GRADIUM_KEY ? 'enabled' : 'off (set GRADIUM_API_KEY)'));
});
