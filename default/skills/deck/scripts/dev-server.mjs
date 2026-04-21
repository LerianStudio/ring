import express from 'express';
import { WebSocketServer } from 'ws';
import chokidar from 'chokidar';
import { createServer } from 'http';
import { readFileSync, appendFileSync, createReadStream, existsSync, unlink } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { spawn } from 'child_process';
import { randomBytes } from 'crypto';
import { tmpdir } from 'os';
import os from 'os';
import open from 'open';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const PORT = parseInt(process.env.PORT || '7007', 10);
const HOST = process.env.HOST || '0.0.0.0';

// state.total stays null until the first deck-stage client announces slide count
// via {type:'hello', total:N}. Remote/presenter clients render "?" while null.
const state = { slide: 0, blank: false, total: null };

function sendFile(res, relPath, contentType = 'text/html; charset=utf-8') {
  try {
    const body = readFileSync(join(ROOT, relPath));
    res.setHeader('Content-Type', contentType);
    // No-cache so live-reload actually reloads — browsers otherwise serve stale HTML.
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
    res.send(body);
  } catch (err) {
    // Distinguish error classes instead of masking everything as 404.
    if (err.code === 'ENOENT') {
      res.status(404).send(`Not found: ${relPath}`);
    } else if (err.code === 'EACCES') {
      console.error(`[sendFile] permission denied: ${relPath}`, err);
      res.status(403).send(`Forbidden: ${relPath}`);
    } else if (err.code === 'EISDIR') {
      console.error(`[sendFile] path is a directory: ${relPath}`, err);
      res.status(500).send(`Server misconfiguration: ${relPath}`);
    } else {
      console.error(`[sendFile] unexpected error for ${relPath}:`, err);
      res.status(500).send(`Server error: ${relPath}`);
    }
  }
}

// Tunnel interfaces (VPN, Tailscale, Cloudflare WARP, WireGuard) typically
// aren't reachable from a phone on the same Wi-Fi. Filter them so the LAN
// URL printed in the banner is something the remote can actually connect to.
// Declared above detectLanIp() usage to avoid Temporal Dead Zone on module init.
const TUNNEL_IFACE_RE = /^(utun|ppp|tun|wg)\d*/i;

const lanIp = detectLanIp();

// Allowed Origins for WS handshake (CSWSH defense). Computed once; non-browser
// WS clients (Puppeteer, curl) omit Origin entirely and are accepted below.
const allowedOrigins = new Set([
  `http://localhost:${PORT}`,
  `http://127.0.0.1:${PORT}`,
]);
if (lanIp) allowedOrigins.add(`http://${lanIp}:${PORT}`);

const app = express();

// Scoped JSON parsing — keep the attack surface minimal; only /feedback needs it.
app.use('/feedback', express.json({ limit: '10kb' }));

app.get('/health', (_req, res) => res.json({ ok: true }));
app.get('/', (_req, res) => sendFile(res, 'deck.html'));
app.get('/deck.html', (_req, res) => sendFile(res, 'deck.html'));
app.get('/presenter', (_req, res) => sendFile(res, 'presenter.html'));
app.get('/remote', (_req, res) => sendFile(res, 'remote.html'));
// Dev server — disable caching on assets so live-reload always fetches fresh.
app.use(
  '/assets',
  express.static(join(ROOT, 'assets'), {
    setHeaders: (res) => res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate'),
  })
);
// Note: /scripts is deliberately NOT mounted — no browser code fetches server
// source, and exposing it over LAN leaked dev-server.mjs + export-pdf.mjs.

app.post('/feedback', (req, res) => {
  const { slideIndex, slideLabel, text } = req.body || {};
  if (!Number.isInteger(slideIndex) || typeof text !== 'string' || text.trim() === '') {
    return res.status(400).json({ ok: false, error: 'Invalid body: expected {slideIndex:int, slideLabel:string, text:string non-empty}' });
  }
  if (text.length > 4000) {
    return res.status(400).json({ ok: false, error: 'Text too long (max 4000 chars)' });
  }
  const entry = {
    ts: new Date().toISOString(),
    slideIndex,
    slideLabel: typeof slideLabel === 'string' ? slideLabel : '',
    text: text.trim(),
  };
  try {
    appendFileSync(join(ROOT, 'feedback.jsonl'), JSON.stringify(entry) + '\n');
    res.json({ ok: true });
  } catch (err) {
    console.error('[feedback] append failed:', err);
    res.status(500).json({ ok: false, error: 'Server error writing feedback' });
  }
});

app.get('/lan-url', (_req, res) => {
  const host = lanIp || 'localhost';
  res.json({ url: `http://${host}:${PORT}/remote` });
});

// Serialize exports — Puppeteer opens a headless Chromium per run, which shares state
// with any other concurrent run in surprising ways. Serialize to sidestep that entirely.
let exportInFlight = false;

function runExport(kind, res) {
  if (exportInFlight) {
    return res.status(429).json({ ok: false, error: 'Another export is in progress' });
  }
  exportInFlight = true;

  const isPdf = kind === 'pdf';
  const scriptPath = join(ROOT, 'scripts', isPdf ? 'export-pdf.mjs' : 'export-pptx.mjs');
  const outPath = join(tmpdir(), `deck-export-${randomBytes(6).toString('hex')}.${isPdf ? 'pdf' : 'pptx'}`);
  const mime = isPdf
    ? 'application/pdf'
    : 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
  const filename = isPdf ? 'deck.pdf' : 'deck.pptx';

  const env = { ...process.env, SKIP_DEV_SERVER: 'true', PORT: String(PORT), OUT: outPath };
  const child = spawn('node', [scriptPath], { cwd: ROOT, env, stdio: ['ignore', 'pipe', 'pipe'] });

  let stderr = '';
  child.stdout.on('data', (b) => process.stdout.write(`[export:${kind}] ${b}`));
  child.stderr.on('data', (b) => { stderr += b.toString(); process.stderr.write(`[export:${kind}] ${b}`); });

  child.on('error', (err) => {
    exportInFlight = false;
    res.status(500).json({ ok: false, error: 'Spawn failed: ' + err.message });
  });

  child.on('exit', (code) => {
    if (code !== 0 || !existsSync(outPath)) {
      exportInFlight = false;
      const msg = stderr.split('\n').filter(Boolean).slice(-5).join('\n') || `exit ${code}`;
      return res.status(500).type('text/plain').send(msg);
    }
    res.setHeader('Content-Type', mime);
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    const stream = createReadStream(outPath);
    stream.on('error', (err) => {
      exportInFlight = false;
      if (!res.headersSent) res.status(500).send('Stream error: ' + err.message);
      else res.destroy();
    });
    stream.on('close', () => {
      unlink(outPath, () => {});  // best-effort cleanup
      exportInFlight = false;
    });
    stream.pipe(res);
  });

  // If client aborts mid-download, kill the child and clean up.
  res.on('close', () => {
    if (!child.killed) {
      try { child.kill('SIGTERM'); } catch {}
    }
  });
}

app.post('/export/pdf', (_req, res) => runExport('pdf', res));
app.post('/export/pptx', (_req, res) => runExport('pptx', res));

const server = createServer(app);
const wss = new WebSocketServer({
  server,
  path: '/ws',
  verifyClient: ({ origin }) => {
    // No Origin header → non-browser WS client (Puppeteer, Node scripts). Accept.
    if (!origin) return true;
    return allowedOrigins.has(origin);
  },
});

function broadcast(msg) {
  const payload = JSON.stringify(msg);
  for (const client of wss.clients) {
    if (client.readyState === 1 /* OPEN */) {
      client.send(payload);
    }
  }
}

// Per-connection token bucket: 10 msgs/sec with 10-token burst. Exceeded
// messages are silently dropped (not disconnected) to avoid tearing down a
// slow client during transient bursts.
const BUCKET_CAPACITY = 10;
const BUCKET_REFILL_PER_MS = 10 / 1000; // 10 tokens per 1000ms

function allowMessage(ws) {
  const now = Date.now();
  const bucket = ws._bucket;
  const elapsed = now - bucket.last;
  bucket.tokens = Math.min(BUCKET_CAPACITY, bucket.tokens + elapsed * BUCKET_REFILL_PER_MS);
  bucket.last = now;
  if (bucket.tokens < 1) return false;
  bucket.tokens -= 1;
  return true;
}

wss.on('connection', (ws) => {
  ws._bucket = { tokens: BUCKET_CAPACITY, last: Date.now() };

  // Send full state (including total — may be null if no deck-stage connected yet).
  ws.send(JSON.stringify({ type: 'state', slide: state.slide, blank: state.blank, total: state.total }));

  ws.on('message', (raw) => {
    if (!allowMessage(ws)) return; // Rate-limited; drop.

    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      return; // Ignore malformed frames.
    }

    if (msg.type === 'hello' && Number.isInteger(msg.total) && msg.total > 0) {
      // deck-stage announcing slide count. Update cached total and let everyone know.
      state.total = msg.total;
      broadcast({ type: 'state', slide: state.slide, blank: state.blank, total: state.total });
    } else if (msg.type === 'nav' && Number.isInteger(msg.slide)) {
      // Optional total piggyback — deck-stage may re-assert total on nav.
      if (Number.isInteger(msg.total) && msg.total > 0) {
        state.total = msg.total;
      }
      // Clamp to known bounds. When total is null (unknown), only clamp below 0.
      const upper = state.total != null ? state.total - 1 : Infinity;
      state.slide = Math.max(0, Math.min(msg.slide, upper));
      broadcast({ type: 'nav', slide: state.slide, total: state.total });
    } else if (msg.type === 'blank' && typeof msg.on === 'boolean') {
      state.blank = msg.on;
      broadcast({ type: 'blank', on: state.blank });
    }
    // Unknown types silently ignored per schema.
  });
});

// Debounce file-change bursts (editors often emit 2-4 events per save).
let reloadTimer = null;
function scheduleReload(event, filePath) {
  if (reloadTimer) return;
  reloadTimer = setTimeout(() => {
    reloadTimer = null;
    console.log(`[watch] ${event} ${filePath} — broadcasting reload`);
    broadcast({ type: 'reload' });
  }, 50);
}

const watcher = chokidar.watch(
  [
    join(ROOT, 'deck.html'),
    join(ROOT, 'presenter.html'),
    join(ROOT, 'remote.html'),
    join(ROOT, 'assets'),
    join(ROOT, 'scripts'),
  ],
  { ignoreInitial: true, ignored: /(^|[\\/])(node_modules|\.git|deck\.pdf)([\\/]|$)/ }
);
watcher.on('all', scheduleReload);

function detectLanIp() {
  const ifaces = os.networkInterfaces();
  const candidates = [];
  for (const [name, list] of Object.entries(ifaces)) {
    if (!list) continue;
    for (const iface of list) {
      if (iface.family !== 'IPv4' || iface.internal) continue;
      candidates.push({ name, address: iface.address });
    }
  }
  const nonTunnel = candidates.find((c) => !TUNNEL_IFACE_RE.test(c.name));
  if (nonTunnel) return nonTunnel.address;
  if (candidates.length > 0) return candidates[0].address;
  return null;
}

function printBanner() {
  const lan = lanIp || 'localhost';
  const lines = [
    '',
    'Ring Deck Server',
    `  Deck:       http://localhost:${PORT}`,
    `  Presenter:  http://localhost:${PORT}/presenter`,
    `  Remote:     http://${lan}:${PORT}/remote   ← open this on your phone`,
    '',
    '  Endpoints:',
    '    POST /feedback          append feedback.jsonl',
    '    POST /export/pdf        trigger PDF export',
    '    POST /export/pptx       trigger PPTX export',
    '    GET  /lan-url           LAN URL for remote control',
    '',
    '  Watching deck.html, presenter.html, remote.html, assets/, scripts/',
    '  Local network only — no authentication.',
    '',
  ];
  if (HOST === '0.0.0.0') {
    lines.push(
      '  ⚠  Bound to 0.0.0.0 (all LAN interfaces). Anyone on your Wi-Fi can reach this server.',
      '     For localhost-only, set HOST=127.0.0.1.',
      ''
    );
  }
  for (const line of lines) console.log(line);
}

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(
      `Port ${PORT} is already in use. Another deck server may be running.\n` +
      `Try:  PORT=${PORT + 1} npm run dev`
    );
    process.exit(1);
  }
  console.error('Server error:', err);
  process.exit(1);
});

server.listen(PORT, HOST, () => {
  printBanner();
  if (process.env.AUTO_OPEN !== 'false') {
    const url = `http://localhost:${PORT}`;
    open(url).catch((err) => {
      console.warn(`[open] could not auto-open browser: ${err.message}`);
      console.warn(`[open] open this URL manually: ${url}`);
    });
  }
});

async function shutdown(signal) {
  console.log(`\n[${signal}] shutting down...`);
  await watcher.close();
  for (const client of wss.clients) client.terminate();
  wss.close();
  server.close(() => process.exit(0));
  // Force-exit if close hangs (stuck sockets).
  setTimeout(() => process.exit(0), 2000).unref();
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
