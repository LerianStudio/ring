#!/usr/bin/env node
/**
 * scan-integration-points.mjs — Step 1 (mechanical) of ring:reviewing-operational-risk.
 *
 * Deterministically walks a Go or TypeScript/Node.js repo and finds the points
 * where the service talks to the outside world:
 *   - outbound external HTTP calls
 *   - queue consumers (RabbitMQ, SQS, Kafka, NATS, ...)
 *   - event publishers / producers
 *   - outbound webhooks / callbacks
 *
 * For each integration point it records, from a window around the match, whether
 * the following resilience mechanisms appear to be present:
 *   retry, dlq, timeout, rollback/compensation, idempotency
 *
 * Output: a structured JSON report on stdout. Feed that JSON to the LLM (Step 2)
 * as structured context BEFORE starting the confirmation dialogue.
 *
 * Zero dependencies — Node.js built-ins only. Detection is heuristic (regex over
 * source, not full AST): treat every hit as a candidate to confirm, and expect
 * false positives/negatives. The LLM step exercises judgement over this data.
 *
 * Usage:
 *   node scan-integration-points.mjs [targetDir] [--json] [--out FILE] [--context N]
 *
 *   targetDir     Repo root to scan (default: current working directory)
 *   --out FILE    Also write the JSON report to FILE
 *   --context N   Lines of context each side of a match for resilience detection (default 12)
 *   --json        (default) emit JSON to stdout
 */

import { readdir, readFile, stat, writeFile } from 'node:fs/promises';
import { join, relative, extname, basename } from 'node:path';

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
let targetDir = process.cwd();
let outFile = null;
let contextLines = 12;
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === '--out') outFile = args[++i];
  else if (a === '--context') contextLines = parseInt(args[++i], 10) || 12;
  else if (a === '--json') { /* default */ }
  else if (!a.startsWith('--')) targetDir = a;
}

// ---------------------------------------------------------------------------
// Walk config
// ---------------------------------------------------------------------------
const SKIP_DIRS = new Set([
  '.git', 'node_modules', 'vendor', 'dist', 'build', 'out', '.next',
  'coverage', 'testdata', 'mocks', '.idea', '.vscode', 'bin', 'gen',
]);
const CODE_EXT = new Set(['.go', '.ts', '.tsx', '.js', '.mjs', '.cjs', '.jsx']);
const TEST_RE = /(_test\.go|\.test\.[tj]sx?|\.spec\.[tj]sx?)$/;

// ---------------------------------------------------------------------------
// Detection patterns. category -> [ {label, re} ]
// ---------------------------------------------------------------------------
const PATTERNS = {
  http_outbound: [
    { label: 'go net/http', re: /http\.(NewRequest(WithContext)?|Get|Post|Do)\s*\(/ },
    { label: 'go http.Client', re: /\bhttp\.Client\b|\(&?http\.Client\{|\.Do\(ctx/ },
    { label: 'go resty', re: /resty\.|\.R\(\)\.(Get|Post|Put|Delete|Patch)\(/ },
    { label: 'go grpc client', re: /grpc\.Dial\(|grpc\.NewClient\(/ },
    { label: 'ts axios', re: /\baxios\b|axios\.(get|post|put|delete|patch|request)\(/ },
    { label: 'ts fetch', re: /(?<![.\w])fetch\s*\(/ },
    { label: 'ts got/undici/superagent', re: /\bgot\s*\(|\bundici\b|superagent\.|node-fetch/ },
  ],
  queue_consumer: [
    { label: 'amqp consume', re: /\.Consume\s*\(|HandleDelivery|amqp\.|rabbitmq/i },
    { label: 'sqs receive', re: /ReceiveMessage|sqs\.|SQSClient/ },
    { label: 'kafka consume', re: /\bConsume(r)?\b.*(kafka|sarama|segmentio)|kafka\.|sarama\.|Reader\.ReadMessage/i },
    { label: 'nats subscribe', re: /nats\.|\.Subscribe\s*\(|QueueSubscribe/ },
    { label: 'ts amqplib/bull', re: /amqplib|\.consume\s*\(|new Worker\(|bull(mq)?|@nestjs\/microservices/i },
  ],
  event_publisher: [
    { label: 'go publish/produce', re: /\.Publish\s*\(|\.Produce\s*\(|PublishWithContext|SendMessage\s*\(/ },
    { label: 'kafka producer', re: /\.WriteMessages\s*\(|Producer\b.*(kafka|sarama)/i },
    { label: 'ts emit/publish', re: /\.publish\s*\(|\.emit\s*\(|producer\.send\(/ },
  ],
  outbound_webhook: [
    { label: 'webhook/callback', re: /webhook|callbackURL|CallbackURL|NotifyURL|notifyUrl|callback_url/i },
  ],
};

// Resilience detection over the surrounding window.
const RESILIENCE = {
  retry: /\bretry\b|retryCount|RetryCount|maxRetries|MaxRetries|WithRetry|backoff|Backoff|retryable|Retryable|\.Retry\(|attempts?\b/i,
  dlq: /\bdlq\b|dead[-_ ]?letter|DeadLetter|parkingLot|x-dead-letter|deadLetterQueue/i,
  timeout: /context\.WithTimeout|context\.WithDeadline|WithTimeout|SetTimeout|\btimeout\b|Timeout:|deadline/i,
  rollback: /rollback|Rollback|compensat|Compensat|\bsaga\b|Saga|revert|Revert|undo\b|unwind/i,
  idempotency: /idempoten|Idempoten|idempotency[-_ ]?key|dedup|deduplicat|exactly[-_ ]?once/i,
};

// ---------------------------------------------------------------------------
// Walk the tree
// ---------------------------------------------------------------------------
async function* walk(dir) {
  let entries;
  try {
    entries = await readdir(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const e of entries) {
    const full = join(dir, e.name);
    if (e.isDirectory()) {
      if (SKIP_DIRS.has(e.name) || e.name.startsWith('.')) continue;
      yield* walk(full);
    } else if (e.isFile()) {
      if (CODE_EXT.has(extname(e.name)) && !TEST_RE.test(e.name)) yield full;
    }
  }
}

function detectResilience(lines, idx, span) {
  const from = Math.max(0, idx - span);
  const to = Math.min(lines.length, idx + span + 1);
  const window = lines.slice(from, to).join('\n');
  const found = {};
  for (const [k, re] of Object.entries(RESILIENCE)) found[k] = re.test(window);
  return found;
}

function languageOf(file) {
  const ext = extname(file);
  if (ext === '.go') return 'go';
  return 'ts_node';
}

// ---------------------------------------------------------------------------
// Main scan
// ---------------------------------------------------------------------------
async function main() {
  try {
    const s = await stat(targetDir);
    if (!s.isDirectory()) throw new Error('not a directory');
  } catch {
    process.stderr.write(`error: target is not a directory: ${targetDir}\n`);
    process.exit(1);
  }

  const points = [];
  let filesScanned = 0;

  for await (const file of walk(targetDir)) {
    let content;
    try {
      content = await readFile(file, 'utf8');
    } catch {
      continue;
    }
    filesScanned++;
    const lines = content.split(/\r?\n/);
    const rel = relative(targetDir, file);
    const lang = languageOf(file);

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (!line.trim() || line.trim().startsWith('//') || line.trim().startsWith('*')) continue;
      for (const [category, defs] of Object.entries(PATTERNS)) {
        for (const { label, re } of defs) {
          if (re.test(line)) {
            const direction =
              category === 'queue_consumer' ? 'inbound' : 'outbound';
            points.push({
              category,
              matcher: label,
              direction,
              language: lang,
              file: rel,
              line: i + 1,
              snippet: line.trim().slice(0, 200),
              resilience: detectResilience(lines, i, contextLines),
            });
            break; // one hit per line per category is enough
          }
        }
      }
    }
  }

  // Deduplicate identical (file,line,category) entries.
  const seen = new Set();
  const deduped = points.filter((p) => {
    const key = `${p.file}:${p.line}:${p.category}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  // Aggregate resilience gaps.
  const gaps = [];
  for (const p of deduped) {
    const missing = Object.entries(p.resilience)
      .filter(([, v]) => !v)
      .map(([k]) => k);
    if (missing.length) gaps.push({ file: p.file, line: p.line, category: p.category, missing });
  }

  const byCategory = {};
  for (const p of deduped) byCategory[p.category] = (byCategory[p.category] || 0) + 1;

  const report = {
    schema: 'ring.ops-risk.integration-scan.v1',
    generated_at: new Date().toISOString(),
    target: targetDir,
    note:
      'Heuristic regex scan (not full AST). Each integration_point is a candidate to CONFIRM in the Step 2 dialogue. resilience flags mean the pattern was FOUND in a window around the match; a true value is a hint, not proof, and a false value is a prompt to verify, not a confirmed gap.',
    summary: {
      files_scanned: filesScanned,
      integration_points: deduped.length,
      by_category: byCategory,
    },
    integration_points: deduped,
    resilience_gaps: gaps,
  };

  const json = JSON.stringify(report, null, 2);
  if (outFile) {
    await writeFile(outFile, json + '\n', 'utf8');
    process.stderr.write(`wrote ${outFile}\n`);
  }
  process.stdout.write(json + '\n');
}

main().catch((err) => {
  process.stderr.write(`fatal: ${err?.stack || err}\n`);
  process.exit(1);
});
