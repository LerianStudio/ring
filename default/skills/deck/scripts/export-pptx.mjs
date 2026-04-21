// Tested up to ~100 slides; memory usage scales linearly (~2MB/slide for 1920x1080
// PNG captures held in-memory before pptxgenjs assembly). For decks >200 slides,
// consider streaming the PPTX writer.

import puppeteer from 'puppeteer';
import PptxGenJS from 'pptxgenjs';
import { spawn } from 'child_process';
import { resolve } from 'path';

// Requires Node >=18 for global fetch and AbortController.

const PORT = parseInt(process.env.PORT || '7007', 10);
const BASE = `http://localhost:${PORT}`;
const USE_SYSTEM_CHROME = process.argv.includes('--chrome');
const OUT_PATH = resolve(process.cwd(), process.env.OUT || './deck.pptx');

let devServer = null;
let browser = null;
let serverBootError = null;

function log(msg) {
  process.stdout.write(`${msg}\n`);
}

async function waitForHealth(timeoutMs = 10_000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    // Fail fast if the child process has already errored or exited non-zero.
    if (serverBootError) {
      throw new Error(`Dev server failed to start: ${serverBootError.message}`);
    }
    try {
      const ctrl = new AbortController();
      const t = setTimeout(() => ctrl.abort(), 500);
      const res = await fetch(`${BASE}/health`, { signal: ctrl.signal });
      clearTimeout(t);
      if (res.ok) return;
    } catch {
      // Server not up yet — keep polling.
    }
    await new Promise((r) => setTimeout(r, 100));
  }
  if (serverBootError) {
    throw new Error(`Dev server failed to start: ${serverBootError.message}`);
  }
  throw new Error(
    `Dev server did not respond at ${BASE}/health within ${timeoutMs}ms. ` +
    `Check that scripts/dev-server.mjs runs without errors.`
  );
}

function startDevServer() {
  devServer = spawn('node', ['scripts/dev-server.mjs'], {
    cwd: process.cwd(),
    // Capture stderr so boot failures (syntax errors, EADDRINUSE, etc.) surface
    // immediately instead of hiding behind a cryptic 10s health-check timeout.
    stdio: ['ignore', 'ignore', 'pipe'],
    detached: false,
    env: { ...process.env, PORT: String(PORT) },
  });
  devServer.stderr.on('data', (chunk) => {
    process.stderr.write('[dev-server] ' + chunk);
  });
  devServer.on('error', (err) => {
    serverBootError = err;
    console.error('Failed to spawn dev server:', err.message);
  });
  devServer.on('exit', (code) => {
    if (code !== 0 && code !== null) {
      serverBootError = new Error('dev-server exited with code ' + code);
    }
  });
}

function killDevServer() {
  if (devServer && !devServer.killed) {
    try { devServer.kill('SIGTERM'); } catch { /* already gone */ }
  }
}

async function launchBrowser() {
  const opts = {
    // Puppeteer 22+ defaults `true` to the new headless mode; 'new' is deprecated.
    headless: true,
    args: [
      // safe: export mode navigates only to localhost; WS is stubbed via ?export=true;
      // no attacker-controlled content reaches this browser.
      '--no-sandbox',
      '--disable-dev-shm-usage',
    ],
    defaultViewport: { width: 1920, height: 1080, deviceScaleFactor: 1 },
  };
  if (USE_SYSTEM_CHROME) opts.channel = 'chrome';
  try {
    return await puppeteer.launch(opts);
  } catch (err) {
    console.error('Puppeteer failed to launch:', err.message);
    if (!USE_SYSTEM_CHROME) {
      console.error(
        'Hint: on Linux CI, missing sandbox libs are common. ' +
        'Try installing dependencies or rerun with: npm run export:chrome'
      );
    } else {
      console.error(
        'Hint: --chrome requires Google Chrome specifically (not Chromium, Brave, or Edge) ' +
        'installed at the default channel path. Either install Google Chrome, or omit --chrome ' +
        'to use Puppeteer\'s bundled Chromium.'
      );
    }
    throw err;
  }
}

async function main() {
  const startedAt = Date.now();
  const externalServer = process.env.SKIP_DEV_SERVER === 'true';

  if (!externalServer) {
    log('Starting dev server...');
    startDevServer();
    await waitForHealth();
  } else {
    log(`Using existing dev server at ${BASE}`);
    // Still do a health check — if the parent lied about the server being up, fail fast.
    await waitForHealth(3_000);
  }

  log('Launching headless Chromium...');
  browser = await launchBrowser();
  const page = await browser.newPage();

  await page.goto(`${BASE}/?export=true`, { waitUntil: 'networkidle0' });
  await page.evaluateHandle('document.fonts.ready');

  // networkidle0 doesn't wait for DOMContentLoaded listeners to finish wiring
  // window.__deck. Poll until deck-stage.js has initialized before checking.
  try {
    await page.waitForFunction(
      'typeof window.__deck?.total === "function"',
      { timeout: 10_000 }
    );
  } catch {
    throw new Error(
      'deck-stage.js did not initialize window.__deck within 10s — ' +
      'check /assets/deck-stage.js is loaded, and Google Fonts are accessible.'
    );
  }

  const hasDeck = await page.evaluate(() => typeof window.__deck?.total === 'function');
  if (!hasDeck) {
    throw new Error(
      'deck.html is malformed — window.__deck is not defined. ' +
      'Ensure assets/deck-stage.js is loaded and initialized.'
    );
  }

  const total = await page.evaluate(() => window.__deck.total());
  if (!Number.isInteger(total) || total <= 0) {
    throw new Error(`window.__deck.total() returned ${total}; expected positive integer.`);
  }

  // Belt-and-suspenders: controller already does both of these when ?export=true,
  // but explicit set here eliminates any upgrade-order race. Keeps Puppeteer capture
  // deterministic regardless of controller attach timing.
  await page.evaluate(() => {
    document.querySelector('deck-stage')?.setAttribute('noscale', '');
    document.body.classList.add('exporting');
  });

  // Fetch speaker notes once — they're rendered as a single JSON blob in the DOM.
  const notes = await page.evaluate(() => {
    const el = document.getElementById('speaker-notes');
    if (!el) return [];
    try { return JSON.parse(el.textContent || '[]'); } catch { return []; }
  });

  log(`Exporting ${total} slides at 1920x1080...`);

  // PPTX units default to inches. 1920x1080 at 96 DPI = 20x11.25 inches (16:9).
  const pptx = new PptxGenJS();
  pptx.defineLayout({ name: 'LER_1920', width: 20, height: 11.25 });
  pptx.layout = 'LER_1920';

  // NOTE: Serial per-slide export is intentional — parallelization risks font-state
  // race conditions between slides. Correctness > speed. Do not "optimize" into a
  // worker pool unless you've verified font.ready determinism per page.
  for (let i = 0; i < total; i++) {
    log(`[${i + 1}/${total}] capturing slide ${i + 1}...`);
    await page.evaluate((n) => window.__deck.goto(n), i);
    // Per-slide font-ready await — weights can be fetched lazily on navigation.
    await page.evaluateHandle('document.fonts.ready');

    const buf = await page.screenshot({
      type: 'png',
      fullPage: false,
      clip: { x: 0, y: 0, width: 1920, height: 1080 },
    });

    const slide = pptx.addSlide();
    slide.background = { data: 'data:image/png;base64,' + buf.toString('base64') };
    if (notes[i]) slide.addNotes(notes[i]);
  }

  await pptx.writeFile({ fileName: OUT_PATH });

  const elapsed = ((Date.now() - startedAt) / 1000).toFixed(1);
  log(`\n✓ Exported ${total} slides → ${OUT_PATH}`);
  log(`  Elapsed: ${elapsed}s`);
}

async function cleanup() {
  if (browser) {
    try { await browser.close(); } catch { /* already closed */ }
    browser = null;
  }
  if (process.env.SKIP_DEV_SERVER !== 'true') {
    killDevServer();
  }
}

process.on('exit', () => {
  // Synchronous best-effort kill — async cleanup already ran in finally.
  if (process.env.SKIP_DEV_SERVER !== 'true') {
    killDevServer();
  }
});
process.on('SIGINT', async () => { await cleanup(); process.exit(130); });
process.on('SIGTERM', async () => { await cleanup(); process.exit(143); });

try {
  await main();
  await cleanup();
  process.exit(0);
} catch (err) {
  console.error(`\nExport failed: ${err.message}`);
  await cleanup();
  process.exit(1);
}
