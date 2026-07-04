// serve.js — zero-dependency static server + model reverse-proxy.
//
// Backend-agnostic: the browser always speaks the Ollama-shaped API (/api/tags, /api/chat with
// NDJSON streaming). This proxy talks to whichever backend you configure and TRANSLATES as needed,
// so the front-end never changes:
//
//   MODEL_BACKEND=ollama  (default)  -> pipe straight to Ollama's native /api/*   (OLLAMA_URL)
//   MODEL_BACKEND=openai             -> translate to the OpenAI-compatible /v1 API (OPENAI_BASE_URL)
//                                       — this is how you run on NVIDIA NIM (a Gemma NIM microservice),
//                                         vLLM, or Ollama's own /v1 endpoint.
//
// Env:
//   PORT             (default 8422)
//   MODEL_BACKEND    ollama | openai        (default ollama)
//   OLLAMA_URL       default http://127.0.0.1:11434
//   OPENAI_BASE_URL  default http://127.0.0.1:8000/v1   (e.g. a local NVIDIA NIM)
//   OPENAI_API_KEY   optional Bearer token (e.g. NGC key / build.nvidia.com)
//   MODEL_ID         optional fallback model id for the openai backend
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

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
};
const modFor = (u) => (u.protocol === 'https:' ? https : http);
const NDJSON = { 'content-type': 'application/x-ndjson', 'cache-control': 'no-cache' };

const server = http.createServer((req, res) => {
  if (req.url.startsWith('/api/')) {
    return BACKEND === 'openai' ? handleOpenAI(req, res) : handleOllama(req, res);
  }
  serveStatic(req, res);
});

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
  let raw = '';
  req.on('data', (c) => (raw += c));
  req.on('end', () => {
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
  let rel = decodeURIComponent(req.url.split('?')[0]);
  if (rel === '/') rel = '/index.html';
  const filePath = path.normalize(path.join(ROOT, rel));
  if (!filePath.startsWith(ROOT)) { res.writeHead(403); return res.end('forbidden'); }
  fs.readFile(filePath, (err, data) => {
    if (err) { res.writeHead(404); return res.end('not found'); }
    res.writeHead(200, { 'content-type': TYPES[path.extname(filePath)] || 'application/octet-stream' });
    res.end(data);
  });
}

server.listen(PORT, () => {
  console.log('Resilience Compass demo → http://localhost:' + PORT);
  if (BACKEND === 'openai') console.log('Model backend: OpenAI-compatible (NVIDIA NIM) → ' + OPENAI_BASE);
  else console.log('Model backend: Ollama → ' + OLLAMA_URL);
});
