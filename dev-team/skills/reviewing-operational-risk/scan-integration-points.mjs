#!/usr/bin/env node
/**
 * scan-integration-points.mjs — Step 1 (mechanical) of ring:reviewing-operational-risk.
 *
 * Deterministically walks a Go or TypeScript/Node.js repo and finds the points
 * where the service talks to the outside world:
 *   - outbound external HTTP calls (incl. local http wrappers and SDK clients)
 *   - queue consumers (RabbitMQ, SQS, Kafka, NATS, ...)
 *   - event publishers / producers
 *   - outbound webhooks / callbacks
 *   - hexagonal outbound ports (each ports/out interface method + its adapter)
 *
 * For each integration point it records whether the following resilience
 * mechanisms appear present: retry, dlq, timeout, rollback/compensation,
 * idempotency. Resilience is inferred at the ENCLOSING-FUNCTION / ADAPTER-FILE
 * level for Go (so a `DoWithRetry` wrapper or a `New*Client(timeout)` client
 * defined elsewhere in the file/adapter still counts), not from a fixed ±N-line
 * window around the call site.
 *
 * SCOPE — IMPORTANT: in a hexagonal Go monorepo, scanning only a service subdir
 * (apps/<svc>) yields a FALSE 0 because the boundaries live in the imported
 * pkg/* adapters. This scanner therefore walks up to the repo/module root, scans
 * the whole tree, and attributes each boundary to the consuming service via its
 * top-level dir. It never returns 0 silently for a service that imports ports/out.
 *
 * Output: a structured JSON report on stdout (schema ring.ops-risk.integration-scan.v1).
 * Feed that JSON to the LLM (Step 2) as structured context BEFORE the dialogue.
 *
 * Zero dependencies — Node.js built-ins only. Detection is heuristic (regex over
 * source, not full AST): treat every hit as a candidate to confirm, and expect
 * false positives/negatives. The LLM step exercises judgement over this data.
 *
 * Usage:
 *   node scan-integration-points.mjs [targetDir] [--json] [--out FILE]
 *                                    [--context N] [--config FILE] [--no-gen-config]
 *                                    [--no-repo-root]
 *
 *   targetDir        Dir to scan from (default: cwd). Expanded to repo/module root.
 *   --out FILE       Also write the JSON report to FILE
 *   --context N      Fallback lines of context each side of a match (default 12)
 *   --config FILE    Path to a .ops-risk.json config (default: <repoRoot>/.ops-risk.json)
 *   --no-gen-config  Do not auto-generate a default .ops-risk.json when missing
 *   --no-repo-root   Do NOT expand to repo root; scan exactly targetDir (legacy)
 *   --json           (default) emit JSON to stdout
 */

import { readdir, readFile, stat, writeFile, access } from 'node:fs/promises';
import { join, relative, extname, dirname, basename, sep, isAbsolute, resolve } from 'node:path';
import { homedir } from 'node:os';

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
let targetDir = process.cwd();
let outFile = null;
let contextLines = 12;
let configPath = null;
let genConfig = true;
let expandToRepoRoot = true;
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === '--out') outFile = args[++i];
  else if (a === '--context') contextLines = parseInt(args[++i], 10) || 12;
  else if (a === '--config') configPath = args[++i];
  else if (a === '--no-gen-config') genConfig = false;
  else if (a === '--no-repo-root') expandToRepoRoot = false;
  else if (a === '--json') { /* default */ }
  else if (!a.startsWith('--')) targetDir = a;
}
targetDir = isAbsolute(targetDir) ? targetDir : resolve(process.cwd(), targetDir);

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
// Default per-repo config (.ops-risk.json)
// ---------------------------------------------------------------------------
const DEFAULT_CONFIG = {
  $schema: 'ring.ops-risk.config.v1',
  // Dirs that hold shared adapters / SDK wrappers imported by services.
  shared_adapter_dirs: ['pkg', 'internal/adapter', 'internal/adapters'],
  // Local packages that wrap net/http (e.g. "httpclient"). Auto-detection adds
  // to this list; declaring here forces inclusion.
  http_wrapper_packages: [],
  // Globs for hexagonal outbound port interfaces (each method = a boundary).
  outbound_port_globs: ['**/ports/out/**', '**/port/**', '**/ports/**'],
  // Inbound handler globs to EXCLUDE from outbound_webhook detection.
  exclude_handler_globs: [
    '**/handler/**', '**/handlers/**', '**/inbound/**', '**/in/**',
    '**/api/**', '**/rest/**', '**/http/in/**', '**/controller/**', '**/controllers/**',
  ],
};

// ---------------------------------------------------------------------------
// Detection patterns. category -> [ {label, re} ]
// ---------------------------------------------------------------------------
const BASE_PATTERNS = {
  http_outbound: [
    { label: 'go net/http', re: /http\.(NewRequest(WithContext)?|Get|Post|Do)\s*\(/ },
    { label: 'go http.Client', re: /\bhttp\.Client\b|\(&?http\.Client\{|\.Do\(ctx/ },
    { label: 'go resty', re: /resty\.|\.R\(\)\.(Get|Post|Put|Delete|Patch)\(/ },
    { label: 'go grpc client', re: /grpc\.Dial\(|grpc\.NewClient\(/ },
    // local http wrappers + generic client constructors + retry wrappers
    { label: 'go http wrapper/client ctor', re: /\bhttpclient\.|\bDoWithRetry\s*\(|\bNew\w+Client\s*\(|\b\w+\.Do\(\s*req\b/ },
    // SDK clients that talk to the outside without touching net/http directly
    { label: 'go sdk client', re: /\b\w*sdk\.[A-Z]\w*\s*\(|\bmidazsdk\./ },
    { label: 'ts axios', re: /\baxios\b|axios\.(get|post|put|delete|patch|request)\(/ },
    { label: 'ts fetch', re: /(?<![.\w])fetch\s*\(/ },
    { label: 'ts got/undici/superagent', re: /\bgot\s*\(|\bundici\b|superagent\.|node-fetch/ },
  ],
  queue_consumer: [
    { label: 'amqp consume', re: /\.Consume\s*\(|HandleDelivery/ },
    { label: 'sqs receive', re: /ReceiveMessage|SQSClient/ },
    { label: 'kafka consume', re: /Reader\.ReadMessage|\bConsumer\b/ },
    { label: 'nats subscribe', re: /\.Subscribe\s*\(|QueueSubscribe/ },
    { label: 'ts amqplib/bull', re: /\.consume\s*\(|new Worker\(/ },
  ],
  event_publisher: [
    { label: 'go publish/produce', re: /\.Publish\s*\(|\.Produce\s*\(|PublishWithContext|SendMessage\s*\(/ },
    { label: 'kafka producer', re: /\.WriteMessages\s*\(/ },
    { label: 'ts emit/publish', re: /\.publish\s*\(|producer\.send\(/ },
  ],
  // Tightened: require a SEND verb AND an explicit URL var; case-sensitive
  // (no blanket /i flag); inbound handler files are excluded before matching.
  outbound_webhook: [
    {
      label: 'webhook send + url',
      re: /(Post|Send|Notify|Dispatch|Deliver|Trigger|Call|Fire|Emit)[A-Za-z]*\s*\([^)]*\b(webhookURL|webhookUrl|WebhookURL|callbackURL|callbackUrl|CallbackURL|NotifyURL|notifyUrl|callback_url|webhook_url)\b/,
    },
  ],
};

// Broker imports that must be present for queue_consumer hits to count.
const BROKER_IMPORT_RE = /(streadway\/amqp|rabbitmq\/amqp091|amqp091|aws-sdk-go[^"]*\/sqs|aws\/aws-sdk[^"]*sqs|segmentio\/kafka-go|Shopify\/sarama|IBM\/sarama|nats-io\/nats|amqplib|bullmq|@nestjs\/microservices|"github\.com\/[^"]*kafka)/i;

// Import path signalling a hexagonal outbound port dependency.
const PORTS_OUT_IMPORT_RE = /["`][^"`]*(ports\/out|\/port|\/ports)\b[^"`]*["`]|\bport\.[A-Z]\w*Port\b/;

// ---------------------------------------------------------------------------
// Resilience detection.
// ---------------------------------------------------------------------------
const RESILIENCE = {
  retry: /\bretry\b|retryCount|RetryCount|maxRetries|MaxRetries|WithRetry|DoWithRetry|backoff|Backoff|retryable|Retryable|\.Retry\(|attempts?\b/i,
  dlq: /\bdlq\b|dead[-_ ]?letter|DeadLetter|parkingLot|x-dead-letter|deadLetterQueue/i,
  timeout: /context\.WithTimeout|context\.WithDeadline|WithTimeout|SetTimeout|\btimeout\b|Timeout:|deadline/i,
  rollback: /rollback|Rollback|compensat|Compensat|\bsaga\b|Saga|revert|Revert|undo\b|unwind/i,
  idempotency: /idempoten|Idempoten|idempotency[-_ ]?key|dedup|deduplicat|exactly[-_ ]?once/i,
};

function resilienceOver(text) {
  const found = {};
  for (const [k, re] of Object.entries(RESILIENCE)) found[k] = re.test(text);
  return found;
}

// ±span-line window (used for TS/Node and as a Go fallback).
function windowResilience(lines, idx, span) {
  const from = Math.max(0, idx - span);
  const to = Math.min(lines.length, idx + span + 1);
  return resilienceOver(lines.slice(from, to).join('\n'));
}

// Enclosing top-level Go func/method body [start, end).
function enclosingGoFunc(lines, idx) {
  let start = idx;
  for (; start >= 0; start--) if (/^func\b/.test(lines[start])) break;
  if (start < 0) return null;
  // Track brace depth from the function's opening `{` so nested if/for/switch
  // blocks don't truncate the body at the first indented-or-not `}`.
  let depth = 0;
  let sawOpen = false;
  for (let j = start; j < lines.length; j++) {
    for (const ch of lines[j]) {
      if (ch === '{') { depth++; sawOpen = true; }
      else if (ch === '}' && sawOpen) {
        depth--;
        if (depth === 0) return [start, j + 1];
      }
    }
  }
  return [start, lines.length];
}

// Go resilience: prefer the enclosing function body (so retry/timeout wrappers
// anywhere in the function count), fall back to the window if no func found.
function goResilience(lines, idx, span) {
  const range = enclosingGoFunc(lines, idx);
  if (!range) return windowResilience(lines, idx, span);
  return resilienceOver(lines.slice(range[0], range[1]).join('\n'));
}

function languageOf(file) {
  return extname(file) === '.go' ? 'go' : 'ts_node';
}

// ---------------------------------------------------------------------------
// glob helpers (support ** and *)
// ---------------------------------------------------------------------------
function toPosix(p) {
  return p.split(sep).join('/');
}
function globToRe(glob) {
  const re = glob
    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
    .replace(/\*\*/g, '\u0000')
    .replace(/\*/g, '[^/]*')
    .replace(/\u0000/g, '.*');
  return new RegExp('^' + re + '$');
}
function anyGlobMatch(globs, relPath) {
  const p = toPosix(relPath);
  return globs.some((g) => globToRe(g).test(p));
}

// Attribute a boundary to its consuming service via top-level dir.
function serviceOf(relPath) {
  const parts = toPosix(relPath).split('/');
  const roots = new Set(['apps', 'components', 'cmd', 'services', 'plugins']);
  if (parts.length > 1 && roots.has(parts[0])) return `${parts[0]}/${parts[1]}`;
  return parts[0] || '.';
}
function topDirOf(relPath) {
  return toPosix(relPath).split('/')[0] || '.';
}

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
      // 'out' is a common build-output dir, but in hexagonal Go it is also the
      // outbound-ports dir (ports/out). Never skip it under a 'ports' parent.
      const isHexOut = e.name === 'out' && basename(dir) === 'ports';
      if ((SKIP_DIRS.has(e.name) && !isHexOut) || e.name.startsWith('.')) continue;
      yield* walk(full);
    } else if (e.isFile()) {
      if (CODE_EXT.has(extname(e.name)) && !TEST_RE.test(e.name)) yield full;
    }
  }
}

async function exists(p) {
  try { await access(p); return true; } catch { return false; }
}

// Find the repo/module root. Prefer the INNERMOST enclosing .git (the actual
// project repo — avoids over-expanding into a parent workspace / monorepo-of-
// repos that also happens to be a git repo). If there is no .git, fall back to
// the OUTERMOST go.mod (module root). The upward walk stops at $HOME so a nested
// target can never escape into unrelated parent directories.
async function findRepoRoot(startDir) {
  const home = homedir();
  let dir = startDir;
  let innermostGit = null;
  const goModDirs = [];
  // eslint-disable-next-line no-constant-condition
  while (true) {
    if (!innermostGit && (await exists(join(dir, '.git')))) innermostGit = dir;
    if (await exists(join(dir, 'go.mod'))) goModDirs.push(dir);
    if (dir === home) break;
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  if (innermostGit) return innermostGit;
  if (goModDirs.length) return goModDirs[goModDirs.length - 1];
  return startDir;
}

// Parse Go interface method names out of a source file.
function goInterfaceMethods(content) {
  const methods = [];
  const ifaceRe = /type\s+(\w+)\s+interface\s*\{/g;
  let m;
  while ((m = ifaceRe.exec(content))) {
    const ifaceName = m[1];
    // scan from the opening brace to its matching close
    let depth = 1;
    let i = ifaceRe.lastIndex;
    let body = '';
    while (i < content.length && depth > 0) {
      const ch = content[i];
      if (ch === '{') depth++;
      else if (ch === '}') depth--;
      if (depth > 0) body += ch;
      i++;
    }
    for (const line of body.split(/\r?\n/)) {
      const mm = line.match(/^\s*([A-Z]\w*)\s*\(/);
      if (mm) methods.push({ iface: ifaceName, method: mm[1] });
    }
  }
  return methods;
}

// ---------------------------------------------------------------------------
// Main scan
// ---------------------------------------------------------------------------
async function main() {
  const warnings = [];

  try {
    const s = await stat(targetDir);
    if (!s.isDirectory()) throw new Error('not a directory');
  } catch {
    process.stderr.write(`error: target is not a directory: ${targetDir}\n`);
    process.exit(1);
  }

  // --- scope: expand to repo/module root -----------------------------------
  const repoRoot = expandToRepoRoot ? await findRepoRoot(targetDir) : targetDir;
  const scopeExpanded = expandToRepoRoot && repoRoot !== targetDir;
  const scanRoot = repoRoot;
  if (scopeExpanded) {
    warnings.push({
      level: 'info',
      code: 'scope_expanded',
      message:
        `requested target "${toPosix(relative(repoRoot, targetDir)) || '.'}" is inside repo root; ` +
        `scanning the full repo root so imported pkg/* adapters and ports/out boundaries are included. ` +
        `Boundaries are attributed to each service via top-level dir. Pass --no-repo-root to scan only the subdir.`,
    });
  }

  // --- config --------------------------------------------------------------
  const cfgFile = configPath
    ? (isAbsolute(configPath) ? configPath : resolve(process.cwd(), configPath))
    : join(scanRoot, '.ops-risk.json');
  let config = { ...DEFAULT_CONFIG };
  let configGenerated = false;
  if (await exists(cfgFile)) {
    try {
      const loaded = JSON.parse(await readFile(cfgFile, 'utf8'));
      config = { ...DEFAULT_CONFIG, ...loaded };
    } catch (e) {
      warnings.push({ level: 'warn', code: 'config_parse_error', message: `could not parse ${cfgFile}: ${e.message}; using defaults` });
    }
  } else if (genConfig) {
    try {
      await writeFile(cfgFile, JSON.stringify(DEFAULT_CONFIG, null, 2) + '\n', 'utf8');
      configGenerated = true;
      warnings.push({
        level: 'info',
        code: 'config_generated',
        message: `no .ops-risk.json found; generated a default at ${toPosix(relative(scanRoot, cfgFile))}. ` +
          `Edit shared_adapter_dirs / http_wrapper_packages / outbound_port_globs / exclude_handler_globs to tune this repo.`,
      });
    } catch {
      /* non-fatal */
    }
  }

  // ------------------------------------------------------------------------
  // Pass 1: read all files, collect metadata (imports, ports, func decls).
  // ------------------------------------------------------------------------
  const files = []; // { rel, lang, lines, content, importsBroker, importsPortsOut, importsNetHttp, pkgName, isPort, isHandler }
  const funcDecls = new Map(); // methodName -> [{ rel, line, entry }]
  const portMethods = []; // { rel, iface, method }
  const httpWrapperPkgs = new Set(config.http_wrapper_packages || []);
  // pkg name -> resilience contributed by the client CONSTRUCTION site
  // (e.g. `func New*Client(timeout ...) *http.Client { ... }`). Merged into
  // every call-site whose wrapper pkg is detected, eliminating false-negative
  // `timeout` flags when the deadline is configured once at construction.
  const wrapperResilienceByPkg = {};
  // TS wrapper resilience: file -> {timeout, retry}. Applied to points in that file.
  const tsWrapperResilienceByFile = {};
  let filesScanned = 0;
  const filesByTopDir = {};

  for await (const file of walk(scanRoot)) {
    let content;
    try {
      content = await readFile(file, 'utf8');
    } catch {
      continue;
    }
    filesScanned++;
    const rel = relative(scanRoot, file);
    const lang = languageOf(file);
    const lines = content.split(/\r?\n/);

    const td = topDirOf(rel);
    filesByTopDir[td] = (filesByTopDir[td] || 0) + 1;

    const importsBroker = BROKER_IMPORT_RE.test(content);
    const importsPortsOut = PORTS_OUT_IMPORT_RE.test(content);
    const importsNetHttp = /["`]net\/http["`]/.test(content);
    const isPort = anyGlobMatch(config.outbound_port_globs || [], rel);
    const isHandler = anyGlobMatch(config.exclude_handler_globs || [], rel);
    const pkgMatch = lang === 'go' ? content.match(/^package\s+(\w+)/m) : null;
    const pkgName = pkgMatch ? pkgMatch[1] : null;

    const entry = { rel, lang, lines, content, importsBroker, importsPortsOut, importsNetHttp, pkgName, isPort, isHandler };
    files.push(entry);

    // Auto-detect local http wrapper packages: a package that imports net/http
    // and lives under a shared adapter dir (or is named like a client wrapper).
    if (lang === 'go' && importsNetHttp && pkgName && pkgName !== 'http' && pkgName !== 'main') {
      const underShared = (config.shared_adapter_dirs || []).some((d) => {
        const dp = toPosix(d);
        return toPosix(rel).startsWith(dp + '/') || toPosix(rel).includes(`/${dp}/`);
      });
      if (underShared || /client|httpclient|gateway|rest/i.test(pkgName)) {
        httpWrapperPkgs.add(pkgName);
      }
    }

    // Auto-detect Go client-constructor sites and harvest resilience from the
    // construction body. Any `func New*Client(... timeout ...) *http.Client`
    // (or returning an interface-like *Client) counts. Timeout/retry configured
    // once here is inherited by every call site through the wrapper pkg.
    if (lang === 'go' && pkgName && pkgName !== 'http' && pkgName !== 'main') {
      const ctorRe = /func\s+(?:\([^)]*\)\s+)?(New\w*Client)\s*\(([^)]*)\)\s*(?:\([^)]*\)|\*?[\w.]+)?\s*\{/g;
      let cm;
      while ((cm = ctorRe.exec(content))) {
        const params = cm[2] || '';
        const decl = cm[0];
        // Only care about wrappers that either mention http.Client in return
        // or accept a timeout-shaped parameter; either signals the wrapper.
        const returnsHttpClient = /\*http\.Client\b/.test(decl) || /http\.Client\b/.test(decl);
        const timeoutInParams = /\btimeout\b/i.test(params) || /time\.Duration\b/.test(params);
        if (!returnsHttpClient && !timeoutInParams) continue;
        httpWrapperPkgs.add(pkgName);
        // resilience from the constructor body
        const startLine = content.slice(0, cm.index).split(/\r?\n/).length - 1;
        const range = enclosingGoFunc(lines, startLine);
        const body = range ? lines.slice(range[0], range[1]).join('\n') : decl;
        const res = resilienceOver(params + '\n' + body);
        const prev = wrapperResilienceByPkg[pkgName] || {};
        wrapperResilienceByPkg[pkgName] = {
          timeout: !!(prev.timeout || res.timeout || timeoutInParams),
          retry: !!(prev.retry || res.retry),
        };
      }
    }

    // TS equivalent: `axios.create({ timeout: ... })` / fetch-wrapper factories
    // inside a `create*Client` / `new*Client` / `make*Client` function. Any point
    // in the same file inherits that construction-site resilience.
    if (lang === 'ts_node') {
      const tsCtorRe = /(?:function|const|export\s+(?:const|function))\s+(new\w*Client|create\w*Client|make\w*Client|build\w*Client)\b/i;
      if (tsCtorRe.test(content)) {
        const res = resilienceOver(content);
        const looksHttp = /axios\.create\s*\(|got\.extend\s*\(|new\s+Agent\s*\(|\bfetch\b|\bundici\b/i.test(content);
        if (looksHttp && (res.timeout || res.retry)) {
          tsWrapperResilienceByFile[rel] = { timeout: !!res.timeout, retry: !!res.retry };
        }
      }
    }

    // Collect Go func/method declarations (for port->adapter mapping).
    if (lang === 'go') {
      for (let i = 0; i < lines.length; i++) {
        // Capture the receiver type (group 1) so port->adapter matching can
        // require the full interface method set on one concrete type instead
        // of matching by bare method name.
        const fm = lines[i].match(/^func\s+(?:\((?:\w+\s+)?\*?([\w.]+)\)\s+)?([A-Z]\w*)\s*\(/);
        if (fm) {
          const recv = fm[1] || null;
          const name = fm[2];
          if (!funcDecls.has(name)) funcDecls.set(name, []);
          funcDecls.get(name).push({ rel, line: i + 1, entry, recv });
        }
      }
      if (isPort) {
        for (const pm of goInterfaceMethods(content)) portMethods.push({ rel, ...pm });
      }
    }
  }

  // Build dynamic http_outbound patterns for detected wrapper packages.
  const patterns = {};
  for (const [cat, defs] of Object.entries(BASE_PATTERNS)) patterns[cat] = defs.slice();
  for (const pkg of httpWrapperPkgs) {
    if (!pkg || pkg === 'http') continue;
    patterns.http_outbound.push({
      label: `go http wrapper pkg (${pkg})`,
      re: new RegExp(`\\b${pkg.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\.[A-Z]?\\w*\\s*\\(`),
    });
  }

  // ------------------------------------------------------------------------
  // Pass 2: line-level pattern scan.
  // ------------------------------------------------------------------------
  const points = [];
  for (const f of files) {
    const { rel, lang, lines, importsBroker, isHandler } = f;
    // Entry-point handler signatures. Instead of silently dropping files under
    // exclude_handler_globs, we surface each handler function/route as an
    // integration_point with entry_point:true so the flow's entry is
    // discoverable in the JSON map without manual grep.
    if (isHandler) {
      const ENTRY_PATTERNS_GO = [
        { label: 'go net/http handler', re: /func\s+(?:\([^)]*\)\s+)?(\w+)\s*\([^)]*http\.ResponseWriter[^)]*\*http\.Request[^)]*\)/ },
        { label: 'go fiber handler', re: /func\s+(?:\([^)]*\)\s+)?(\w+)\s*\(\s*\w+\s+\*fiber\.Ctx\s*\)/ },
        { label: 'go gin handler', re: /func\s+(?:\([^)]*\)\s+)?(\w+)\s*\(\s*\w+\s+\*gin\.Context\s*\)/ },
        { label: 'go echo handler', re: /func\s+(?:\([^)]*\)\s+)?(\w+)\s*\(\s*\w+\s+echo\.Context\s*\)/ },
        { label: 'go chi/mux route', re: /\b(router|r|mux|app|api)\.(Get|Post|Put|Delete|Patch|Handle|HandleFunc|Method|Route)\s*\(/ },
      ];
      const ENTRY_PATTERNS_TS = [
        { label: 'ts express route', re: /\b(app|router|api)\.(get|post|put|delete|patch|all|use)\s*\(/ },
        { label: 'ts nest controller', re: /@(Get|Post|Put|Delete|Patch|All|Head|Options)\s*\(/ },
        { label: 'ts fastify route', re: /\b(fastify|app|server)\.(get|post|put|delete|patch|route)\s*\(/ },
        { label: 'ts handler arrow', re: /\((?:req|request)\b[^,)]*,\s*(?:res|response)\b[^)]*\)\s*(?::\s*[\w<>[\]]+\s*)?=>/ },
      ];
      const entryPats = lang === 'go' ? ENTRY_PATTERNS_GO : ENTRY_PATTERNS_TS;
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const t = line.trim();
        if (!t || t.startsWith('//') || t.startsWith('*')) continue;
        for (const { label, re } of entryPats) {
          if (re.test(line)) {
            const resilience = lang === 'go'
              ? goResilience(lines, i, contextLines)
              : windowResilience(lines, i, contextLines);
            points.push({
              category: 'entry_point',
              matcher: label,
              direction: 'inbound',
              language: lang,
              service: serviceOf(rel),
              file: rel,
              line: i + 1,
              snippet: t.slice(0, 200),
              resilience,
              entry_point: true,
            });
            break;
          }
        }
      }
    }

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const t = line.trim();
      if (!t || t.startsWith('//') || t.startsWith('*')) continue;
      for (const [category, defs] of Object.entries(patterns)) {
        // queue_consumer only counts in files that also import a broker.
        if (category === 'queue_consumer' && !importsBroker) continue;
        // outbound_webhook excludes inbound handler files (they're inbound
        // entry points, surfaced separately with entry_point:true above).
        if (category === 'outbound_webhook' && isHandler) continue;
        for (const { label, re } of defs) {
          if (re.test(line)) {
            const direction = category === 'queue_consumer' ? 'inbound' : 'outbound';
            const resilience = lang === 'go'
              ? goResilience(lines, i, contextLines)
              : windowResilience(lines, i, contextLines);
            // Merge in wrapper-construction-site resilience so a timeout/retry
            // configured once in `New*Client(...)` counts for every call site.
            let wrapperInherited = null;
            if (category === 'http_outbound') {
              // Prefer the dynamic per-pkg label; else detect wrapper pkg by
              // scanning the line for `<pkg>.` since the generic wrapper regex
              // may have already matched first.
              const pkgMatch = label.match(/^go http wrapper pkg \((\w+)\)$/);
              let wrapperPkg = pkgMatch ? pkgMatch[1] : null;
              if (!wrapperPkg && lang === 'go') {
                for (const pkg of httpWrapperPkgs) {
                  if (!pkg || pkg === 'http') continue;
                  if (new RegExp(`\\b${pkg.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\.`).test(line)) {
                    wrapperPkg = pkg;
                    break;
                  }
                }
              }
              if (wrapperPkg && wrapperResilienceByPkg[wrapperPkg]) {
                wrapperInherited = wrapperResilienceByPkg[wrapperPkg];
              } else if (lang === 'ts_node' && tsWrapperResilienceByFile[rel]) {
                wrapperInherited = tsWrapperResilienceByFile[rel];
              }
              if (wrapperInherited) {
                resilience.timeout = resilience.timeout || !!wrapperInherited.timeout;
                resilience.retry = resilience.retry || !!wrapperInherited.retry;
              }
            }
            const point = {
              category,
              matcher: label,
              direction,
              language: lang,
              service: serviceOf(rel),
              file: rel,
              line: i + 1,
              snippet: t.slice(0, 200),
              resilience,
            };
            if (wrapperInherited) point.resilience_source = 'wrapper_construction+call_site';
            points.push(point);
            break; // one hit per line per category is enough
          }
        }
      }
    }
  }

  // ------------------------------------------------------------------------
  // Pass 3: port-aware detection (hexagonal). Each ports/out interface method
  // is a boundary candidate; resilience is analysed over the concrete adapter
  // FILE that implements it (catches SDK adapters like midazsdk.WithTimeout
  // that never touch net/http on the call line).
  // ------------------------------------------------------------------------
  //
  // Matching is receiver-type aware, NOT name-only: a concrete type is treated
  // as an adapter for an interface only when it implements the FULL method set
  // of that interface. This prevents common method names (Close, Send, Publish)
  // on unrelated receivers from being misclassified as port implementations and
  // inflating outbound_port points / bogus resilience gaps.

  // Group interface method names by their declaring (file, interface).
  const ifaceSets = new Map(); // `${rel}::${iface}` -> { rel, iface, methods:Set }
  for (const pm of portMethods) {
    const key = `${pm.rel}::${pm.iface}`;
    if (!ifaceSets.has(key)) ifaceSets.set(key, { rel: pm.rel, iface: pm.iface, methods: new Set() });
    ifaceSets.get(key).methods.add(pm.method);
  }

  // Map each concrete (non-port) receiver type to the methods it defines.
  // Key by package-qualified receiver so same-named types in different
  // packages (Client, Service, Repository, Handler, ...) are not merged into
  // a single union that could spuriously satisfy an interface's method set.
  const receiverMethods = new Map(); // `${pkg}::${recv}` -> { recv, methods: Map(method -> decl) }
  for (const [name, decls] of funcDecls) {
    for (const d of decls) {
      if (d.entry.isPort || !d.recv) continue;
      const rkey = `${d.entry.pkgName || ''}::${d.recv}`;
      if (!receiverMethods.has(rkey)) receiverMethods.set(rkey, { recv: d.recv, methods: new Map() });
      const mmap = receiverMethods.get(rkey).methods;
      if (!mmap.has(name)) mmap.set(name, d);
    }
  }

  for (const { rel, iface, methods } of ifaceSets.values()) {
    const methodList = [...methods];
    if (!methodList.length) continue;
    for (const { recv, methods: mmap } of receiverMethods.values()) {
      // Require the receiver to implement EVERY method of the interface.
      if (!methodList.every((m) => mmap.has(m))) continue;
      for (const m of methodList) {
        const impl = mmap.get(m);
        const e = impl.entry;
        // whole adapter file: client ctor + retry wrapper may live elsewhere
        const resilience = resilienceOver(e.content);
        points.push({
          category: 'outbound_port',
          matcher: `port ${iface}.${m} -> adapter (${recv})`,
          direction: 'outbound',
          language: 'go',
          service: serviceOf(impl.rel),
          file: impl.rel,
          line: impl.line,
          snippet: `${iface}.${m}() implemented by ${recv}`.slice(0, 200),
          resilience,
          port: { interface: iface, method: m, declared_in: rel, adapter_type: recv },
        });
      }
    }
  }

  // ------------------------------------------------------------------------
  // Deduplicate identical (file,line,category) entries.
  // ------------------------------------------------------------------------
  const seen = new Set();
  const deduped = points.filter((p) => {
    const key = `${p.file}:${p.line}:${p.category}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  // Aggregate resilience gaps.
  const gaps = [];
  // Inbound entry points don't own outbound-recovery concerns (retry, dlq,
  // timeout, rollback); flagging those would flood resilience_gaps with inbound
  // noise. For inbound points only idempotency is a meaningful gap.
  const INBOUND_RELEVANT = new Set(['idempotency']);
  for (const p of deduped) {
    const inbound = p.entry_point === true || p.direction === 'inbound';
    const missing = Object.entries(p.resilience)
      .filter(([k, v]) => !v && (!inbound || INBOUND_RELEVANT.has(k)))
      .map(([k]) => k);
    if (missing.length) gaps.push({ file: p.file, line: p.line, category: p.category, service: p.service, missing });
  }

  const byCategory = {};
  const byService = {};
  for (const p of deduped) {
    byCategory[p.category] = (byCategory[p.category] || 0) + 1;
    byService[p.service] = (byService[p.service] || 0) + 1;
  }

  // ------------------------------------------------------------------------
  // Warnings: never report a silent 0 where ports/out is imported.
  // ------------------------------------------------------------------------
  const servicesImportingPortsOut = new Set();
  const portServiceFiles = {}; // service -> [files importing ports/out]
  for (const f of files) {
    if (f.importsPortsOut) {
      const svc = serviceOf(f.rel);
      servicesImportingPortsOut.add(svc);
      (portServiceFiles[svc] ||= []).push(f.rel);
    }
  }
  const anySharedAdapterBoundaries = deduped.some((p) =>
    (config.shared_adapter_dirs || []).some((d) => {
      const dp = toPosix(d);
      return toPosix(p.file).startsWith(dp + '/') || toPosix(p.file).includes(`/${dp}/`);
    }));
  for (const svc of servicesImportingPortsOut) {
    if (!byService[svc]) {
      // If the whole scan found nothing, this is a real scope error (warn).
      // If boundaries exist in shared adapter dirs (pkg/*), the service's
      // adapters simply live there — informational, not an error.
      const isScopeError = deduped.length === 0 || !anySharedAdapterBoundaries;
      warnings.push({
        level: isScopeError ? 'warn' : 'info',
        code: 'zero_boundaries_in_port_service',
        service: svc,
        message: isScopeError
          ? `0 fronteiras num serviço que importa ports/out — provável erro de escopo; ` +
            `escaneie o repo root ou pkg/. Service "${svc}" imports outbound ports but no boundary was ` +
            `attributed to it. Files importing ports/out: ${(portServiceFiles[svc] || []).slice(0, 5).join(', ')}` +
            ((portServiceFiles[svc] || []).length > 5 ? ' …' : '')
          : `Service "${svc}" imports outbound ports but its boundaries were attributed to shared adapter ` +
            `dirs (e.g. pkg/*) rather than the service tree — expected for hexagonal layouts. Cross-check ` +
            `outbound_port entries whose adapter lives under a shared dir when reviewing "${svc}".`,
      });
    }
  }
  if (deduped.length === 0 && servicesImportingPortsOut.size > 0) {
    warnings.push({
      level: 'warn',
      code: 'zero_integration_points',
      message:
        '0 fronteiras num serviço que importa ports/out — provável erro de escopo; escaneie o repo root ou pkg/. ' +
        'The scan found zero integration points but outbound ports are imported: this is almost certainly a scope error. ' +
        'Run from the repo root (default) or include pkg/*.',
    });
  }

  const report = {
    schema: 'ring.ops-risk.integration-scan.v1',
    generated_at: new Date().toISOString(),
    requested_target: targetDir,
    scan_root: scanRoot,
    config_file: (await exists(cfgFile)) ? cfgFile : null,
    note:
      'Heuristic regex scan (not full AST). Each integration_point is a candidate to CONFIRM in the Step 2 dialogue. ' +
      'For Go, resilience flags are inferred over the ENCLOSING FUNCTION (line-matched points) or the whole ADAPTER FILE ' +
      '(outbound_port points), so a DoWithRetry wrapper or a New*Client(timeout) defined elsewhere still counts. ' +
      'A true flag is a hint, not proof; a false flag is a prompt to verify, not a confirmed gap. ' +
      'In a hexagonal monorepo the scan runs from the repo root and attributes each boundary to its service via top-level dir.',
    warnings,
    summary: {
      files_scanned: filesScanned,
      integration_points: deduped.length,
      by_category: byCategory,
      by_service: byService,
      files_by_top_dir: filesByTopDir,
      services_importing_ports_out: [...servicesImportingPortsOut],
      http_wrapper_packages_detected: [...httpWrapperPkgs],
      config_generated: configGenerated,
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
