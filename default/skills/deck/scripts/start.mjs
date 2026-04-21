// One-command bootstrap for the deck. `npm start` runs this.
// 1. If node_modules is missing, run `npm install` with progress.
// 2. Spawn scripts/dev-server.mjs as a child.
// 3. Dev-server auto-opens the browser on listen (controlled via AUTO_OPEN env).
// 4. Forward stdout/stderr; on SIGINT/SIGTERM, kill the child cleanly.

import { spawn } from 'child_process';
import { existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');

function log(msg) { process.stdout.write(msg + '\n'); }

async function runInstall() {
  return new Promise((resolve, reject) => {
    log('[start] node_modules missing — running `npm install`...');
    // stdio:inherit streams npm's progress bars directly.
    const child = spawn('npm', ['install'], { cwd: ROOT, stdio: 'inherit' });
    child.on('error', reject);
    child.on('exit', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`npm install exited ${code}`));
    });
  });
}

function startDevServer() {
  const child = spawn('node', ['scripts/dev-server.mjs'], {
    cwd: ROOT,
    stdio: 'inherit',
    env: { ...process.env },  // AUTO_OPEN respected — unset or 'true' means open
  });
  child.on('exit', (code) => {
    process.exit(code ?? 0);
  });
  child.on('error', (err) => {
    console.error('[start] failed to spawn dev-server:', err.message);
    process.exit(1);
  });
  const forward = (sig) => () => {
    if (!child.killed) {
      try { child.kill(sig); } catch {}
    }
  };
  process.on('SIGINT', forward('SIGINT'));
  process.on('SIGTERM', forward('SIGTERM'));
  return child;
}

async function main() {
  const hasNodeModules = existsSync(join(ROOT, 'node_modules'));
  if (!hasNodeModules) {
    try { await runInstall(); }
    catch (err) {
      console.error('[start] install failed:', err.message);
      process.exit(1);
    }
  }
  startDevServer();
}

main();
