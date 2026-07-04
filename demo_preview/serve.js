// serve.js — zero-dependency static server + streaming reverse-proxy to local Ollama.
//
// The browser talks to ONE origin (this server), so there is no CORS and no need to set
// OLLAMA_ORIGINS. Requests to /api/* are piped through to http://127.0.0.1:11434, preserving
// Ollama's streamed NDJSON so tokens arrive live. All inference stays on this machine.
//
// Run:  node serve.js        (PORT env overrides the default 8422)

const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const PORT = process.env.PORT || 8422;
const OLLAMA = { host: '127.0.0.1', port: 11434 };

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

const server = http.createServer((req, res) => {
  // ---- reverse-proxy the Ollama API (streaming) ----
  if (req.url.startsWith('/api/')) {
    const upstream = http.request(
      { host: OLLAMA.host, port: OLLAMA.port, path: req.url, method: req.method,
        headers: { 'content-type': 'application/json' } },
      (up) => {
        res.writeHead(up.statusCode || 502, {
          'content-type': up.headers['content-type'] || 'application/x-ndjson',
          'cache-control': 'no-cache',
        });
        up.pipe(res); // stream tokens straight back to the browser
      }
    );
    upstream.on('error', (e) => {
      res.writeHead(502, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ error: 'Ollama unreachable on 11434: ' + e.message }));
    });
    req.pipe(upstream); // forward the request body (chat messages)
    return;
  }

  // ---- static files (confined to ROOT) ----
  let rel = decodeURIComponent(req.url.split('?')[0]);
  if (rel === '/') rel = '/index.html';
  const filePath = path.normalize(path.join(ROOT, rel));
  if (!filePath.startsWith(ROOT)) { res.writeHead(403); res.end('forbidden'); return; }
  fs.readFile(filePath, (err, data) => {
    if (err) { res.writeHead(404); res.end('not found'); return; }
    res.writeHead(200, { 'content-type': TYPES[path.extname(filePath)] || 'application/octet-stream' });
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log('Resilience Compass demo → http://localhost:' + PORT);
  console.log('Proxying /api/* → http://127.0.0.1:11434 (local Ollama)');
});
