---
name: ring:dev-readyz
description: |
  Readiness implementation orchestrator for Lerian services. Drives a 12-gate cycle that
  detects stack, audits existing /readyz compliance, previews changes visually, dispatches
  language-specific engineers (Go / TypeScript / Next.js) to implement the canonical
  /readyz contract, ValidateSaaSTLS() enforcement, metrics emission, startup self-probe,
  graceful-drain coupling, circuit-breaker integration, and multi-tenant carve-out — then
  runs 10 parallel reviewers and generates an operator activation guide.

  Origin: Monetarie SaaS incident — product-console started successfully but MongoDB was
  silently unreachable (TLS mismatch with DocumentDB). K8s liveness passed, traffic routed,
  clients hit errors. Two subsequent dogfood audits found /readyz implementations that
  independently reinvented anti-patterns (response caching, substring TLS detection,
  `/ready` alias paths, missing metrics). This skill ensures those failure modes never
  reappear.

trigger: |
  - New service being created
  - Service has external dependencies (DB, cache, queue, HTTP upstreams)
  - Gate 0 (Implementation) added connection code
  - Service lacks /readyz or has incomplete dependency checks
  - Service missing startup self-probe, SaaS TLS enforcement, or metrics
  - Existing /readyz detected but needs compliance audit

skip_when: |
  - Pure library package with no deployable service or HTTP server
  - Task is documentation-only, configuration-only, or non-code
  - Service has no external dependencies AND no network listeners
  - CLI tool or batch job that does not serve HTTP traffic

prerequisites: |
  - Go or TypeScript/Next.js service with HTTP surface
  - One or more external dependencies (DB, cache, queue, S3, HTTP upstream)

NOT_skip_when: |
  - "K8s TCP probe is enough" → TCP ≠ app ready. Monetarie proved it.
  - "/health already exists" → /health without self-probe = blind. /readyz validates ALL deps.
  - "TLS check is overkill" → TLS mismatch = silent failure. This incident exists because of it.
  - "Frontend doesn't need /readyz" → Console IS the product that broke. Every app needs it.
  - "We'll add checks later" → Later = client-facing incident. Add now.
  - "Service is simple" → Simple services still connect to databases. No exceptions.
  - "We'll cache readyz to reduce load" → Caching defeats freshness. FORBIDDEN.
  - "Metrics are optional" → Readyz without metrics is operationally blind. NON-NEGOTIABLE.
  - "Service already has /readyz, skip this skill" → Existence ≠ compliance. Gate 0 audits S1-S9.
  - "We'll implement it manually without the agent" → FORBIDDEN. All code via ring:backend-engineer-{language}.

sequence:
  after: [ring:dev-implementation]
  parallel_with: [ring:dev-sre]
  before: [ring:dev-devops]

related:
  complementary: [ring:dev-cycle, ring:dev-sre, ring:dev-devops, ring:dev-service-discovery, ring:codereview, ring:dev-validation]
  standards: [docs/standards/golang/bootstrap.md, docs/standards/sre.md, docs/standards/helm/templates.md]

input_schema:
  description: |
    When invoked from ring:dev-cycle (post-cycle step), receives structured handoff context.
    When invoked standalone (direct user request), these fields are auto-detected in Gate 0.
  fields:
    - name: execution_mode
      type: string
      enum: ["FULL", "SCOPED"]
      description: "FULL = complete 12-gate cycle. SCOPED = only adapt new files (when existing /readyz is compliant)."
      required: false
      default: "FULL"
    - name: files_changed
      type: array
      items: string
      description: "File paths changed during dev-cycle (only in SCOPED mode). Used to limit adaptation scope."
      required: false
    - name: readyz_exists
      type: boolean
      description: "Whether /readyz code was detected by dev-cycle Step 1.5."
      required: false
    - name: readyz_compliant
      type: boolean
      description: "Whether existing /readyz code passed compliance audit."
      required: false
    - name: language
      type: string
      enum: ["go", "typescript"]
      description: "Programming language — determines which engineer agent is dispatched."
      required: true
    - name: service_type
      type: string
      enum: ["api", "worker", "batch", "bff", "frontend"]
      description: "Service type — determines endpoint placement and self-probe mechanism."
      required: true
    - name: detected_dependencies
      type: object
      properties:
        postgres: boolean
        mongodb: boolean
        redis: boolean
        rabbitmq: boolean
        s3: boolean
        http_upstreams: boolean
      description: "Stack detection from dev-cycle. Each key indicates whether that dependency exists."
      required: false
    - name: deployment_mode
      type: string
      enum: ["saas", "byoc", "local"]
      description: "Target deployment mode. Determines TLS enforcement strictness."
      required: false
      default: "local"
    - name: skip_gates
      type: array
      items: string
      description: "Gate identifiers to skip (e.g., '0', '1.5'). Set by dev-cycle based on execution_mode."
      required: false

output_schema:
  format: markdown
  required_sections:
    - name: "Readyz Cycle Summary"
      pattern: "^## Readyz Cycle Summary"
      required: true
    - name: "Stack Detection"
      pattern: "^## Stack Detection"
      required: true
    - name: "Compliance Audit"
      pattern: "^## Compliance Audit"
      required: true
    - name: "Gate Results"
      pattern: "^## Gate Results"
      required: true
    - name: "Verification"
      pattern: "^## Verification"
      required: true
  metrics:
    - name: gates_passed
      type: integer
    - name: gates_failed
      type: integer
    - name: dependencies_detected
      type: integer
    - name: dependencies_covered
      type: integer
    - name: metrics_emitted
      type: boolean
    - name: saas_tls_enforced
      type: boolean
    - name: graceful_drain_wired
      type: boolean
    - name: response_caching_removed
      type: boolean
    - name: anti_patterns_removed
      type: integer

---

# Readyz & Self-Probe Development Cycle

<cannot_skip>

## CRITICAL: This Skill ORCHESTRATES. Agents IMPLEMENT.

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Detect stack, audit compliance, determine gates, pass context to agent, verify outputs, enforce order |
| **ring:backend-engineer-golang** | Go services — load readiness standards via WebFetch, implement canonical contract |
| **ring:backend-engineer-typescript** | TypeScript backend/BFF — same contract, TS idioms |
| **ring:frontend-bff-engineer-typescript** | Next.js BFF services — instrumentation.ts self-probe, App Router routes |
| **ring:codebase-explorer** | Gate 1 analysis |
| **ring:visualize** | Gate 1.5 HTML preview |
| **10 reviewers** | Review at Gate 9 |

**CANNOT change scope:** the skill defines WHAT to implement. The agent implements HOW.

**FORBIDDEN: Orchestrator MUST NOT use Edit, Write, or Bash tools to modify source code files.**
All code changes MUST go through `Task(subagent_type="ring:backend-engineer-{language}")` or `ring:frontend-bff-engineer-typescript` for Next.js.
The orchestrator only verifies outputs (grep, build, test) — MUST NOT write implementation code.

**MANDATORY: TDD for all implementation gates (Gates 2-8).** MUST follow RED → GREEN → REFACTOR: write a failing test first, then implement to make it pass, then refactor for clarity/performance. MUST include in every dispatch: "Follow TDD: write failing test (RED), implement to make it pass (GREEN), then refactor for clarity/performance (REFACTOR)."

</cannot_skip>

---

## Readiness Architecture

`/readyz` is a **runtime dependency probe** consumed by K8s readinessProbe and Tenant Manager post-provisioning. It has a strict response contract: per-dependency status, latency, TLS posture, and (when applicable) circuit-breaker state. `/health` is a **liveness probe** gated by a startup self-probe. Together they provide K8s with the signals to route traffic correctly and restart unhealthy pods.

**Scope:**

| Concern | In scope | Out of scope |
|---------|----------|--------------|
| DB/cache/queue reachability + TLS posture | ✅ | — |
| Startup self-probe gating /health | ✅ | — |
| SaaS TLS enforcement at bootstrap | ✅ | — |
| Graceful-drain signal handling | ✅ | — |
| Circuit breaker state surfacing | ✅ | — |
| Tenant-scoped readiness (per-tenant endpoint) | ✅ (carve-out) | — |
| Live cert validation | — | out of scope — TLS posture, not cert validity |
| Backend performance benchmarking | — | out of scope — belongs to telemetry |
| Synthetic business-logic probes | — | out of scope — /readyz is infra, not app |

**Standards references (loaded via WebFetch by implementation agents):**

| Resource | WebFetch URL |
|----------|--------------|
| Ring SRE standards | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md` |
| Ring Go bootstrap standards | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/bootstrap.md` |
| Helm readiness probe standards | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/helm/templates.md` |
| This skill (authoritative contract) | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/skills/dev-readyz/SKILL.md` |

---

### MANDATORY: Response Contract

Every `/readyz` response MUST match this shape. No deviations.

```json
{
  "status": "healthy",
  "checks": {
    "postgres": { "status": "up", "latency_ms": 2, "tls": true },
    "mongodb":  { "status": "up", "latency_ms": 3, "tls": true },
    "rabbitmq": { "status": "n/a", "tls": true, "reason": "multi-tenant: see /readyz/tenant/:id" },
    "redis":    { "status": "skipped", "reason": "REDIS_ENABLED=false" },
    "upstream_fees": { "status": "degraded", "breaker_state": "half-open", "latency_ms": 12 }
  },
  "version": "1.2.3",
  "deployment_mode": "saas"
}
```

**Per-check field rules:**

| Field | Required when | Omit when | Notes |
|-------|---------------|-----------|-------|
| `status` | ALWAYS | — | One of `up`/`down`/`degraded`/`skipped`/`n/a`. |
| `latency_ms` | status is `up` or `degraded` with an executed probe | `skipped`, `n/a`, or no probe ran | Integer milliseconds. |
| `tls` | dependency supports TLS (DBs, queues, HTTPS upstreams) | dep has no TLS concept | Boolean. Reflects configured posture, NOT runtime cert validation. |
| `error` | status is `down` or `degraded` | status is `up`/`skipped`/`n/a` | Operator-facing. MUST NOT leak credentials. |
| `reason` | status is `skipped` or `n/a` | status is `up`/`down`/`degraded` | Human-readable explanation. |
| `breaker_state` | dep is circuit-breaker-wrapped | dep has no breaker | `closed`/`half-open`/`open`. |

**Top-level fields:**

- `status`: `"healthy"` or `"unhealthy"` per aggregation rule below. MANDATORY.
- `version`: from build info or `VERSION` env. MANDATORY.
- `deployment_mode`: from `DEPLOYMENT_MODE` env. MANDATORY. Default `"local"` if env unset.

---

### MANDATORY: Status Vocabulary

Every per-dependency check uses one of these five values. No others.

| Status | Meaning | Counts as healthy? |
|--------|---------|---------------------|
| `up` | Dependency reachable, check passed | Yes |
| `down` | Dependency unreachable or check failed | **No (→ 503)** |
| `degraded` | Circuit breaker half-open OR partial failure | **No (→ 503)** |
| `skipped` | Optional dependency explicitly disabled via config | Yes (ignored in aggregation) |
| `n/a` | Dependency not applicable in current mode (e.g., tenant-scoped without tenant context) | Yes (ignored in aggregation) |

`skipped` and `n/a` MUST include a human-readable `reason` field.

---

### MANDATORY: Aggregation Rule

Top-level `status` is `"healthy"` **if and only if** every check has status in `{up, skipped, n/a}`.

ANY check with `down` OR `degraded` → top-level `"unhealthy"` → HTTP **503**.

A service that returns 200 while reporting a `degraded` or `down` check is lying to K8s.

---

### MANDATORY: Endpoint Paths (No Aliases)

| Stack | Readiness Path | Liveness Path |
|-------|----------------|---------------|
| Go API | `/readyz` | `/health` |
| Go Worker | `/readyz` on `HEALTH_PORT` | `/health` on `HEALTH_PORT` |
| TypeScript API | `/readyz` | `/health` |
| Next.js (BFF or frontend) | `/api/admin/health/readyz` | `/api/admin/health/readyz` (same handler) |

**FORBIDDEN variants:**

- ❌ `/ready` (alias — not acceptable)
- ❌ `/health/ready` (overloads /health)
- ❌ `/health/live` + `/health/ready` split (use single `/health` + separate `/readyz`)
- ❌ `/v1/readyz` (no API version prefix on infra endpoints)

---

### MANDATORY: Forbidden Anti-Patterns

Every detected anti-pattern in Gate 0 Phase 3 BLOCKS progression until removed.

| # | Anti-pattern | Why forbidden | Replaced by |
|---|--------------|---------------|-------------|
| 1 | Response caching (TTL in front of /readyz) | Masks transient failures; creates blind window in K8s probe cycle | Live checks every request with bounded per-dep timeouts |
| 2 | `/ready` alias path | Drift between K8s config, Tenant Manager, dashboards | Exact `/readyz` path everywhere |
| 3 | `/health/live` + `/health/ready` split | Duplicates /readyz surface without benefit | Single `/health` + separate `/readyz` |
| 4 | `strings.Contains(uri, "tls=true")` | Fragile substring match — false positives/negatives on URL-encoded params | `url.Parse` + `url.ParseQuery` |
| 5 | Reflection on `*amqp.Connection` for TLS state | Library does not reliably expose TLS after dial | URL scheme check (`amqps://`) |
| 6 | Inline TLS enforcement at each connection site | Scattered checks drift; one miss = silent insecure SaaS start | Centralized `ValidateSaaSTLS()` at bootstrap |
| 7 | `process.exit()` in Next.js `instrumentation.ts` on probe failure | Prevents K8s from collecting log tail | Module-level `startupHealthy` flag + 503 on /readyz |

---

### MANDATORY: Agent Instruction (include in EVERY gate dispatch)

MUST include these instructions in every dispatch to `ring:backend-engineer-golang` / `ring:backend-engineer-typescript` / `ring:frontend-bff-engineer-typescript`:

> **STANDARDS: WebFetch `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/skills/dev-readyz/SKILL.md` and follow the canonical response contract exactly. WebFetch `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md` for observability integration.**
>
> **CONTRACT: The response shape in this skill is the ONLY valid /readyz surface. Five-value status vocabulary: `up`/`down`/`degraded`/`skipped`/`n/a`. Aggregation: 503 iff any check is `down` or `degraded`.**
>
> **FORBIDDEN ANTI-PATTERNS: (1) response caching, (2) `/ready` alias, (3) `/health/live`+`/health/ready` split, (4) substring TLS detection, (5) reflection on connection objects for TLS, (6) inline TLS checks at each connection site, (7) `process.exit()` in instrumentation.ts. MUST NOT introduce any of these.**
>
> **TDD: For implementation gates, follow TDD methodology — write a failing test first (RED), then implement to make it pass (GREEN), then refactor (REFACTOR). MUST have test coverage for every change.**

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Security/safety breach, compile-breaking residue, client-facing silent failure | `DEPLOYMENT_MODE=saas` without `ValidateSaaSTLS` (silent insecure start), TLS reflection on RabbitMQ (false posture report), response caching (missed outages) |
| **HIGH** | Missing core contract surface, wrong behavior | Status vocabulary violated, aggregation rule wrong (503 not returned when check is `down`), metrics not emitted, self-probe missing |
| **MEDIUM** | Partial compliance, observability gap | Missing `reason` on `skipped`/`n/a`, drain grace period too short, validator missing on breaker integration |
| **LOW** | Documentation, naming | Missing per-dep description, inconsistent version string format |

MUST report all severities. CRITICAL: STOP immediately. HIGH: Fix before gate pass. MEDIUM: Fix in iteration. LOW: Document.

---

## Pressure Resistance

| User Says | This Is | Response |
|-----------|---------|----------|
| "K8s TCP probe is enough, skip /readyz" | COMPLIANCE_BYPASS | "TCP ≠ app ready. Monetarie incident: pod alive, Mongo unreachable. Gate 2 is MANDATORY." |
| "/health already exists, we're fine" | COMPLIANCE_BYPASS | "/health without self-probe is blind. /readyz validates deps. Both are MANDATORY." |
| "We'll add metrics later" | QUALITY_BYPASS | "Metrics are NON-NEGOTIABLE. Readyz without metrics is operationally blind. Gate 5 is MANDATORY." |
| "Cache /readyz for 5s to reduce load" | COMPLIANCE_BYPASS | "FORBIDDEN. Cache TTL + probe interval = blind window. Live checks are O(ms). Anti-pattern #1." |
| "`/ready` is fine, same thing" | COMPLIANCE_BYPASS | "K8s, Tenant Manager, dashboards target exact paths. Aliases create drift. Exact `/readyz` MANDATORY." |
| "Split /health into /health/live + /health/ready" | SCOPE_OVERREACH | "`/readyz` already covers readiness. Split adds surface without benefit. FORBIDDEN. Anti-pattern #3." |
| "`strings.Contains(uri, \"tls=true\")` works" | COMPLIANCE_BYPASS | "Substring match fails on URL-encoded params. MUST use `url.Parse`. Anti-pattern #4." |
| "Let's reflect on the live connection for TLS" | COMPLIANCE_BYPASS | "`amqp.Connection` does not reliably expose TLS after dial. URL scheme only. Anti-pattern #5." |
| "Inline TLS check at each connection is clearer" | QUALITY_BYPASS | "Scattered checks drift. One miss = silent SaaS insecure start. Centralized `ValidateSaaSTLS()`. Anti-pattern #6." |
| "Frontend doesn't need /readyz" | SCOPE_REDUCTION | "Console IS the product that broke (Monetarie). Every app with deps needs /readyz. MANDATORY." |
| "Existing /readyz is fine, skip compliance audit" | COMPLIANCE_BYPASS | "Existence ≠ compliance. Gate 0 Phase 2 runs S1-S9 audit. Partial compliance = NON-COMPLIANT." |
| "process.exit() on probe fail in Next.js" | COMPLIANCE_BYPASS | "Prevents K8s log tail collection. Use module-level flag + 503 on /readyz. Anti-pattern #7." |
| "Skip self-probe, /readyz covers it" | QUALITY_BYPASS | "/readyz runs per-request; self-probe gates traffic BEFORE first request. Both MANDATORY." |
| "Circuit breaker half-open = up" | COMPLIANCE_BYPASS | "Breaker is actively testing. Traffic during half-open = what breaker protects against. Map to `degraded`." |
| "Multi-tenant plugin, skip tenant-scoped deps" | COMPLIANCE_BYPASS | "Silent omission = invisible drift. Report `n/a` with reason + expose `/readyz/tenant/:id`." |
| "Skip code review, readyz is simple" | QUALITY_BYPASS | "Silent failure modes are this skill's whole motivation. 10 reviewers MANDATORY." |
| "I'll make a quick edit directly" | CODE_BYPASS | "FORBIDDEN. All code changes go through the engineer agent. Dispatch MANDATORY." |
| "Skip TDD, we tested manually" | QUALITY_BYPASS | "MANDATORY: RED→GREEN→REFACTOR. Manual testing does not count." |

---

## Gate Overview

| Gate | Name | Condition | Agent |
|------|------|-----------|-------|
| 0 | Stack Detection + /readyz Compliance Audit (3 phases) | Always | Orchestrator |
| 1 | Codebase Analysis (readyz focus) | Always | ring:codebase-explorer |
| 1.5 | Implementation Preview (visual HTML report) | Always | Orchestrator (ring:visualize) |
| 2 | /readyz Endpoint Implementation | Always — verify compliance or implement | ring:backend-engineer-{language} |
| 3 | TLS Detection (url.Parse) | Always — CRITICAL for SaaS services | ring:backend-engineer-{language} |
| 4 | SaaS TLS Enforcement (ValidateSaaSTLS) | Always — NON-NEGOTIABLE | ring:backend-engineer-{language} |
| 5 | Metrics Emission (3 metrics) | Always — NON-NEGOTIABLE | ring:backend-engineer-{language} |
| 6 | Circuit Breaker + Multi-Tenant Carve-Out | Skip only with explicit justification (no breakers AND single-tenant) | ring:backend-engineer-{language} |
| 7 | Startup Self-Probe + /health + Graceful Drain ⛔ NEVER SKIPPABLE | Always | ring:backend-engineer-{language} |
| 8 | Tests | Always | ring:backend-engineer-{language} |
| 9 | Code Review | Always | 10 parallel reviewers |
| 10 | User Validation | Always | User |
| 11 | Activation Guide | Always | Orchestrator |

MUST execute gates sequentially. CANNOT skip or reorder.

### Input Validation (when invoked from dev-cycle)

If this skill receives structured input from ring:dev-cycle (post-cycle handoff):

```text
VALIDATE input:
1. execution_mode MUST be "FULL" or "SCOPED"
2. language MUST be "go" or "typescript" (required)
3. service_type MUST be in enum (required)
4. If execution_mode == "SCOPED":
   - files_changed MUST be non-empty
   - readyz_exists MUST be true
   - readyz_compliant MUST be true
   - skip_gates MUST include ["0", "1.5", "10", "11"]
5. If execution_mode == "FULL":
   - Core gates always execute (0, 1, 1.5, 2, 4, 5, 7, 8, 9)
   - Conditional gates may be in skip_gates based on detection:
     - "3" MUST NOT be skipped if any DB/queue dep detected
     - "6" may be skipped ONLY with explicit justification (no breakers AND single-tenant)
     - "10", "11" may be skipped when invoked from dev-cycle
   - skip_gates MUST NOT contain non-skippable gates (0, 1, 1.5, 2, 4, 5, 7, 8, 9)
6. detected_dependencies (if provided) pre-populates Gate 0 — still MUST verify with grep (trust but verify)
7. deployment_mode (if provided) determines SaaS enforcement strictness; default "local"

If invoked standalone (no input_schema fields):
   - Default to execution_mode = "FULL"
   - MUST prompt user for language + service_type before Gate 0
   - Run full Gate 0 stack detection
```

<cannot_skip>

### HARD GATE: Existence ≠ Compliance

**"The service already has /readyz" is NOT a reason to skip any gate.**

Two real-world dogfood audits (matcher, plugin-br-bank-transfer) found /readyz implementations that were each ~20%-80% compliant with the canonical contract. Common gaps: missing metrics, substring TLS detection, response caching, `/ready` alias, missing `ValidateSaaSTLS`, missing graceful-drain coupling.

Compliance verification requires EVIDENCE via Gate 0 Phase 2 (S1-S9 audit) and Phase 3 (anti-pattern detection). Partial compliance = NON-COMPLIANT.

**If ANY audit check is NON-COMPLIANT → the corresponding gate MUST execute to fix it. CANNOT skip.**

</cannot_skip>

---

## Gate 0: Stack Detection + /readyz Compliance Audit

**Orchestrator executes directly. No agent dispatch.**

**This gate has THREE phases: stack detection, /readyz compliance audit, and anti-pattern detection.**

### Phase 1: Stack Detection

```text
DETECT (run in parallel):

1. Language + stack:
   - Go: test(-f go.mod) && grep "module" go.mod
   - TypeScript: test(-f package.json) && grep '"name"' package.json
   - Next.js: test(-f next.config.js) OR test(-f next.config.ts)

2. Dependencies — Go:
   - PostgreSQL:  grep -rn "pgx\|pgxpool\|lib/pq\|database/sql" go.mod internal/ pkg/ cmd/
   - MongoDB:     grep -rn "go.mongodb.org/mongo-driver" go.mod internal/
   - Redis:       grep -rn "go-redis\|valkey" go.mod internal/
   - RabbitMQ:    grep -rn "amqp091-go\|streadway/amqp" go.mod internal/
   - S3:          grep -rn "aws-sdk-go\|aws-sdk-go-v2/s3" go.mod internal/
   - HTTP upstream: grep -rn "lib-commons/.*httpclient\|http.Client" internal/

3. Dependencies — TypeScript:
   - PostgreSQL:  grep -n '"pg"\|"postgres"\|"drizzle"\|"prisma"' package.json
   - MongoDB:     grep -n '"mongodb"\|"mongoose"' package.json
   - Redis:       grep -n '"redis"\|"ioredis"' package.json
   - RabbitMQ:    grep -n '"amqplib"' package.json
   - S3:          grep -n '"@aws-sdk/client-s3"' package.json
   - HTTP upstream: grep -rn "fetch\|axios\|undici" src/ app/ lib/

4. Existing /readyz endpoint:
   - Go:       grep -rn '"/readyz"\|"/ready"' internal/ cmd/ pkg/
   - TS:       grep -rn 'readyz\|"/ready"' src/ app/ lib/

5. Existing /health endpoint:
   - grep -rn '"/health"\|"/healthz"' internal/ src/ app/ lib/

6. Existing startup self-probe:
   - Go:       grep -rn "RunSelfProbe\|SelfProbe\|startupHealthy\|selfProbeOK" internal/
   - TS/Next:  grep -rn "startupHealthy\|runSelfProbe" src/ app/ instrumentation.ts

7. Existing ValidateSaaSTLS (centralized enforcement):
   - Go:       grep -rn "ValidateSaaSTLS\|ValidateTLS\|DEPLOYMENT_MODE.*saas" internal/
   - TS:       grep -rn "validateSaaSTLS\|DEPLOYMENT_MODE" src/ app/

8. Existing metrics emission:
   - grep -rn "readyz_check_duration\|readyz_check_status\|selfprobe_result" internal/ src/

9. Deployment mode:
   - grep -rn "DEPLOYMENT_MODE" .env.example config/ internal/ src/ app/
```

### Phase 2: /readyz Compliance Audit (MANDATORY if /readyz code detected)

If Phase 1 step 4 returned results, MUST run the S1-S9 audit. MUST replace existing code that does not match the canonical contract.

```text
AUDIT (run in parallel — only if step 4 found existing /readyz code):

NOTE: All S-checks are POSITIVE (absence = NON-COMPLIANT).

S1. Endpoint path exact match:
    - MUST match: grep -rn '"/readyz"' internal/ src/ app/
    - FORBIDDEN: grep -rn '"/ready"\b\|"/health/ready"\|"/health/live"' internal/ src/
    - (any forbidden variant = NON-COMPLIANT → Gate 2 MUST rename)

S2. Status vocabulary:
    - Go:  grep -rn '"up"\|"down"\|"degraded"\|"skipped"\|"n/a"' internal/*/readyz*.go
    - TS:  grep -rn '"up"\|"down"\|"degraded"\|"skipped"\|"n/a"' src/*/readyz*.ts app/
    - (any custom value like "ok", "healthy" per-check, "failed" = NON-COMPLIANT → Gate 2 MUST fix)

S3. Aggregation rule (503 on down/degraded):
    - Go:  grep -rn "StatusServiceUnavailable\|503" internal/*/readyz*.go
    - (no 503 path in handler = NON-COMPLIANT → Gate 2 MUST fix)

S4. Response top-level fields:
    - MUST appear in response struct: `status`, `checks`, `version`, `deployment_mode`
    - (missing any = NON-COMPLIANT → Gate 2 MUST fix)

S5. TLS detection method:
    - MUST use: grep -rn "url\.Parse\|url\.ParseQuery" internal/ src/ near TLS detection
    - FORBIDDEN: grep -rn 'strings\.Contains.*"tls=\|strings\.Contains.*"sslmode=\|Contains\(.*tls=true' internal/ src/
    - (substring match = NON-COMPLIANT → Gate 3 MUST fix)

S6. ValidateSaaSTLS centralized function:
    - Go:  grep -rn "func ValidateSaaSTLS" internal/
    - TS:  grep -rn "validateSaaSTLS\|function validateSaaSTLS" src/
    - (absent = NON-COMPLIANT → Gate 4 MUST create)

S7. Metrics emission:
    - MUST match all three: grep -rn "readyz_check_duration_ms\|readyz_check_status\|selfprobe_result" internal/ src/
    - (any missing = NON-COMPLIANT → Gate 5 MUST emit)

S8. Startup self-probe + /health wiring:
    - Go:  grep -rn "RunSelfProbe\|atomic.Bool\|selfProbeOK" internal/
    - Go:  grep -rn "selfProbeOK\.Load()" internal/*/health*.go
    - TS/Next: grep -rn "startupHealthy" instrumentation.ts app/api/admin/health/
    - (missing self-probe OR /health not gated = NON-COMPLIANT → Gate 7 MUST fix)

S9. Graceful drain coupling:
    - Go:  grep -rn "drainingState\|draining.*atomic\.Bool\|SIGTERM.*drain" internal/
    - TS:  grep -rn "draining\|process\.on\(\"SIGTERM\"" src/ app/
    - (no drain flag wired to /readyz = NON-COMPLIANT → Gate 7 MUST fix)
```

**Output format for /readyz compliance audit:**

```text
/readyz COMPLIANCE AUDIT RESULTS:
| Check | Component                          | Status                    | Evidence       | Gate Action          |
|-------|------------------------------------|---------------------------|----------------|----------------------|
| S1    | Endpoint path (/readyz, no alias)  | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 2: SKIP / FIX   |
| S2    | Status vocabulary                  | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 2: SKIP / FIX   |
| S3    | Aggregation rule (503 on down)     | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 2: SKIP / FIX   |
| S4    | Response top-level fields          | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 2: SKIP / FIX   |
| S5    | TLS detection via url.Parse        | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 3: SKIP / FIX   |
| S6    | ValidateSaaSTLS centralized fn     | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 4: SKIP / FIX   |
| S7    | Metrics emission (3 metrics)       | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 5: SKIP / FIX   |
| S8    | Self-probe + /health wiring        | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 7: SKIP / FIX   |
| S9    | Graceful drain coupling            | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 7: SKIP / FIX   |
```

**HARD GATE: A gate can only be marked SKIP when ALL its compliance checks are COMPLIANT with evidence. One NON-COMPLIANT row → gate MUST execute.**

### Phase 3: Anti-Pattern Detection (MANDATORY)

Anti-pattern detection runs on every invocation — not conditional. Findings BLOCK progression until removed.

```text
DETECT anti-patterns (every match MUST be removed):

N1. Response caching (TTL in front of /readyz):
    - Go:  grep -rn "readyzResultTTL\|readyzCache\|ttl.*readyz\|cache.*readyz" internal/
    - TS:  grep -rn "readyzCache\|cacheControl.*readyz\|stale-while-revalidate.*readyz" src/ app/
    - (any match = CRITICAL → Gate 2 MUST remove cache layer)

N2. /ready alias path:
    - Go:  grep -rn '"/ready"\b' internal/ cmd/ pkg/
    - TS:  grep -rn '"/ready"\b' src/ app/
    - (any match = HIGH → Gate 2 MUST rename to /readyz)

N3. /health/live + /health/ready split:
    - grep -rn '"/health/live"\|"/health/ready"' internal/ src/ app/
    - (any match = HIGH → Gate 2 MUST consolidate to single /health + /readyz)

N4. Substring TLS detection:
    - grep -rn 'strings\.Contains.*"tls=\|strings\.Contains.*"sslmode=\|includes.*"tls="' internal/ src/
    - (any match = CRITICAL → Gate 3 MUST replace with url.Parse)

N5. Reflection on connection objects for TLS:
    - grep -rn "reflect\..*TLSConfig\|conn\.TLSConnectionState" internal/
    - (any match in /readyz context = HIGH → Gate 3 MUST use URL scheme instead)

N6. Inline SaaS TLS checks at connection sites:
    - Go:  grep -rn "DEPLOYMENT_MODE.*saas" internal/ | grep -v "ValidateSaaSTLS\|tls_enforcement"
    - TS:  grep -rn "DEPLOYMENT_MODE.*saas" src/ | grep -v "validateSaaSTLS\|tls-enforcement"
    - (scattered matches = HIGH → Gate 4 MUST extract to ValidateSaaSTLS)

N7. process.exit in Next.js instrumentation.ts:
    - grep -n "process\.exit" instrumentation.ts
    - (any match = HIGH → Gate 7 MUST replace with module-level flag + 503)
```

**If any anti-pattern detected:** report as `ANTI-PATTERNS DETECTED — BLOCKS PROGRESSION`. Specified gate MUST remove them.

<block_condition>
HARD GATE: Phase 3 N1 (caching) and N4 (substring TLS) findings are CRITICAL and BLOCK progression past Gate 3. N2/N3/N5/N6/N7 findings BLOCK past the gate that fixes them.
</block_condition>

---

## Gate 1: Codebase Analysis (Readyz Focus)

**Always executes. This gate builds the implementation roadmap for all subsequent gates.**

**Dispatch `ring:codebase-explorer` with readyz-focused context:**

> TASK: Analyze this codebase exclusively under the readiness probe perspective.
> DETECTED DEPENDENCIES: {from Gate 0} (each of postgres/mongodb/redis/rabbitmq/s3/http_upstream: Y/N)
> LANGUAGE: {go | typescript}
> SERVICE TYPE: {api | worker | batch | bff | frontend}
>
> FOCUS AREAS (explore ONLY these — ignore everything else):
>
> 1. **Service name + bootstrap path**: Where does the service start? Where is the main init sequence? Identify exact file:line where `/readyz` handler will be mounted and where `ValidateSaaSTLS()` will be called (MUST be before any connection opens).
>
> 2. **Dependency construction sites**: For each detected dep, find file:line where the connection is established (e.g., `pgxpool.New`, `mongo.Connect`, `amqp.Dial`, `redis.NewClient`). These are where TLS posture is determined.
>
> 3. **Connection URL/DSN sources**: Where do DSNs/URIs come from? Env var names? Config struct fields? This is what `detectPostgresTLS`/`detectMongoTLS`/etc. will parse.
>
> 4. **HTTP router location + middleware chain**: Where is the router built? Where does auth middleware register? Identify exact insertion point for `/readyz` + `/health` routes (MUST NOT go behind auth — K8s probes don't authenticate).
>
> 5. **Graceful shutdown wiring**: Where does the service handle SIGTERM? Is there a `server.Shutdown()` call? A draining sleep? Identify file:line for adding `drainingState.Store(true)`.
>
> 6. **Metrics registry**: Does the service have an existing metrics registry (Prometheus, lib-commons observability)? Where? This is where `readyz_check_duration_ms`/`readyz_check_status`/`selfprobe_result` will be registered.
>
> 7. **Circuit breaker usage**: Any `gobreaker`, `hystrix`, or `lib-commons/resilience` usage? For each, file:line + the dependency it protects. Gate 6 will wrap these into readyz.
>
> 8. **Multi-tenant indicators**: Any `MULTI_TENANT_ENABLED`, `tenantId` middleware, per-tenant connection managers (`tmpostgres.Manager`, `tmmongo.Manager`)? If yes, Gate 6 carve-out applies — tenant-scoped deps report `n/a` globally + `/readyz/tenant/:id` is created.
>
> 9. **Optional dependency flags**: Any `REDIS_ENABLED=false` or similar toggles? For each, file:line. These map to `skipped` status in readyz.
>
> 10. **Existing /readyz code** (if detected by Gate 0): every file that touches /readyz, /health, self-probe, TLS detection, or graceful drain. Full file:line inventory for Gate 2-7 work.
>
> 11. **Build-info source**: Where does the service report its version? `buildVersion` constant? ldflags `-X main.version=...`? LERIAN_VERSION env? This feeds the top-level `version` field.
>
> OUTPUT FORMAT: Structured report with file:line references for every point above.
> DO NOT write code. Analysis only.

**This report becomes the CONTEXT for all subsequent gates.**

<block_condition>
HARD GATE: MUST complete the analysis report before proceeding. All subsequent gates use this report to know exactly which deps to probe, where to insert handlers, and where to wire shutdown.
</block_condition>

---

## Gate 1.5: Implementation Preview (Visual Report)

**Always executes. This gate generates a visual HTML report showing every change before any code is written.**

**Uses the `ring:visualize` skill to produce a self-contained HTML page at `docs/readyz-implementation-preview.html`.**

The HTML page MUST include these sections:

### 1. Current State (Before)

- **Mermaid diagram**: current probe flow — what K8s hits today, where /health routes, any existing /readyz, self-probe path (or its absence), TLS enforcement path (or its absence)
- **/readyz compliance audit table** (from Gate 0 Phase 2): every S-check with COMPLIANT / NON-COMPLIANT + evidence
- **Anti-patterns detected** (from Gate 0 Phase 3): every N-check with file:line, severity, and target gate

### 2. Target State (After)

- **Mermaid diagram**: canonical probe flow — K8s readinessProbe → /readyz → per-dep checks → aggregated 200/503; K8s livenessProbe → /health → selfProbeOK gate → lib-commons deps; bootstrap path with ValidateSaaSTLS() before connection opens; SIGTERM → drainingState.Store(true) → /readyz returns 503
- **Response contract example** for THIS service: filled-in JSON showing every detected dep with its expected fields
- **Status vocabulary applied to THIS service**: which deps are mandatory (`up`/`down`), which are optional (`skipped` when disabled), which are tenant-scoped (`n/a`), which are breaker-wrapped (can be `degraded`)

### 3. Change Map (per gate)

| Gate | File | What Changes | Impact |
|------|------|-------------|--------|
| 2 | `internal/adapters/http/in/readyz.go` | NEW: /readyz handler + types + status vocabulary + aggregation | ~200 lines |
| 2 | `internal/adapters/http/router.go` | MOUNT /readyz before auth middleware | ~3 lines |
| 3 | `internal/bootstrap/tls_detection.go` | NEW: detectPostgresTLS / detectMongoTLS / detectAMQPTLS / detectRedisTLS — all via url.Parse | ~80 lines |
| 4 | `internal/bootstrap/tls_enforcement.go` | NEW: ValidateSaaSTLS() + requireTLS helper | ~60 lines |
| 4 | `internal/bootstrap/bootstrap.go` | CALL ValidateSaaSTLS before any connection | ~5 lines |
| 5 | `internal/observability/readyz_metrics.go` | NEW: 3 metrics registered + emit helpers | ~70 lines |
| 6 | `internal/adapters/http/in/readyz.go` | ADD breaker_state branch + multi-tenant n/a handling | ~40 lines |
| 7 | `internal/bootstrap/selfprobe.go` | NEW: RunSelfProbe + selfProbeOK atomic.Bool | ~80 lines |
| 7 | `internal/adapters/http/in/health.go` | GATE /health on selfProbeOK.Load() | ~10 lines |
| 7 | `internal/bootstrap/shutdown.go` | NEW: drainingState atomic.Bool + SIGTERM handler | ~40 lines |
| 8 | `internal/adapters/http/in/readyz_test.go` | NEW: contract tests + chaos tests for breaker | ~250 lines |

**MANDATORY: Below the summary table, show per-file code diff panels for every file that will be modified.**

For each file, generate a before/after panel:
- **Before:** Exact current code (from Gate 1 analysis) — or "NEW FILE" if greenfield
- **After:** Exact code that will be written, using the canonical contract

(Use syntax highlighting and line numbers — read `default/skills/visualize/templates/code-diff.html` for patterns.)

### 4. Contract Preview

Show the full filled-in /readyz JSON response for this specific service. Every detected dependency from Gate 0 appears with its expected status/latency_ms/tls/reason/breaker_state fields. This is what the operator will see when they curl /readyz.

### 5. Scope Fence

Explicit list of deps/concerns that were CONSIDERED but EXCLUDED from /readyz scope:

| Excluded | Why | Where it stays |
|----------|-----|----------------|
| Synthetic business-logic transaction check | /readyz is infra, not app | separate /biz-check endpoint if needed |
| Certificate validity / expiry check | /readyz reports TLS posture, not cert health | external cert-monitoring tool |
| Performance SLI (p99 latency) | /readyz is binary healthy/unhealthy | telemetry dashboards |
| Per-tenant business rules | Global /readyz is tenant-agnostic | /readyz/tenant/:id (Gate 6 carve-out) |

### 6. Risk Assessment

| Risk | Mitigation | Verification |
|------|-----------|--------------|
| /readyz behind auth middleware → K8s 401 | Gate 2 mounts /readyz BEFORE auth | Integration test: unauthenticated GET /readyz returns 200 or 503, never 401 |
| Drain grace period too short → in-flight requests killed | Gate 7 sets grace ≥ K8s `periodSeconds * failureThreshold + buffer` | Shutdown integration test |
| SaaS insecure start (non-TLS DB in SaaS mode) | Gate 4 ValidateSaaSTLS at bootstrap BEFORE connections | Integration test: DEPLOYMENT_MODE=saas + non-TLS DSN → refuses to start |
| Metrics registered but not emitted | Gate 5 emits from every handler execution | Integration test: scrape /metrics after hitting /readyz, assert counters incremented |
| Self-probe passes but deps become unreachable later | /readyz runs per-request, catches runtime drift | Chaos test: stop a dep mid-run, assert /readyz returns 503 within next probe |

### 7. Dependencies Added

Table of new imports required, per file:
- `github.com/prometheus/client_golang/prometheus` (if metrics registry absent)
- `sync/atomic` (for selfProbeOK and drainingState)
- `net/url` (for TLS detection parsing)
- etc.

**Output:** Save HTML to `docs/readyz-implementation-preview.html`. Open in browser.

<block_condition>
HARD GATE: Developer MUST explicitly approve the implementation preview before any code changes begin. This prevents wasted effort on misunderstood dep surface, wrong TLS detection approach, or drain grace period miscalibration.
</block_condition>

**If the developer requests changes (dep scope, drain timing, breaker integration strategy), regenerate the report and re-confirm.**

---

## Gate 2: /readyz Endpoint Implementation

**SKIP only if:** Gate 0 Phase 2 returned COMPLIANT for S1-S4 (path, vocabulary, aggregation, response fields) AND Phase 3 returned zero findings for N1-N3 (caching, alias, split).

Otherwise MANDATORY.

**Dispatch `ring:backend-engineer-golang` (Go) or `ring:backend-engineer-typescript` (TS) or `ring:frontend-bff-engineer-typescript` (Next.js) with context:**

> TASK: Implement (or fix) the `/readyz` endpoint with canonical response contract, status vocabulary, aggregation rule, and graceful-drain coupling.
>
> CONTEXT FROM GATE 1: {bootstrap path, router location, auth middleware file:line, dependency construction sites, existing /readyz code (if any)}
> DETECTED DEPENDENCIES: {list from Gate 0}
>
> {INCLUDE: MANDATORY Agent Instruction block from skill header}
>
> Canonical response contract (the ONLY valid shape):
> ```json
> {
>   "status": "healthy",
>   "checks": {
>     "postgres": { "status": "up", "latency_ms": 2, "tls": true },
>     "rabbitmq": { "status": "n/a", "tls": true, "reason": "multi-tenant: see /readyz/tenant/:id" }
>   },
>   "version": "1.2.3",
>   "deployment_mode": "saas"
> }
> ```
>
> Status vocabulary (five values ONLY): `up`/`down`/`degraded`/`skipped`/`n/a`. Reason field required for `skipped`/`n/a`.
>
> Aggregation rule: top-level `status` is `"healthy"` iff every check ∈ `{up, skipped, n/a}`. ANY `down` or `degraded` → 503.
>
> Mount path: `/readyz` (Go/TS API, Go worker) OR `/api/admin/health/readyz` (Next.js). NO aliases — do NOT create `/ready`, `/health/ready`, or versioned paths.
>
> MOUNT POSITION: /readyz MUST be registered BEFORE any authentication middleware. K8s probes do not authenticate.
>
> Per-dep timeouts: 2s for DB (Postgres, Mongo), 1s for cache (Redis, Valkey), 2s for queue (RabbitMQ), 2s for S3, 1s for HTTP upstream.
>
> Constraints:
> 1. FORBIDDEN: response caching (no TTL layer). Every request = live check. Bounded per-dep timeouts provide load protection.
> 2. FORBIDDEN: custom status values (e.g., "ok", "healthy" per-check, "failed"). Vocabulary is closed.
> 3. FORBIDDEN: returning 200 while reporting `down`/`degraded` checks. Aggregation is strict.
> 4. MUST wire graceful-drain: a `drainingState atomic.Bool` (Go) or module-level flag (TS/Next) that short-circuits /readyz to 503 when set. Implementation lives in Gate 7 — this gate only reserves the drain branch in the handler.
> 5. MUST read `version` from build info or VERSION env; `deployment_mode` from DEPLOYMENT_MODE env (default "local").
>
> Write the handler file (e.g., `internal/adapters/http/in/readyz.go` for Go, `app/api/admin/health/readyz/route.ts` for Next.js). Register it in the router before auth.
>
> TDD: write a failing test first — "GET /readyz with all deps up returns 200 and correct shape" — then implement.

**Verification (orchestrator runs):**

- `grep -rn '"/readyz"' internal/ src/ app/` — MUST return a handler registration
- `grep -rn '"/ready"\b\|"/health/ready"\|"/health/live"' internal/ src/ app/` — MUST return zero results
- `grep -rn "status.*:.*\"up\"\|status.*:.*\"down\"\|status.*:.*\"degraded\"\|status.*:.*\"skipped\"\|status.*:.*\"n/a\"" internal/ src/ app/` — MUST cover 5 values
- `grep -rn "cache.*readyz\|readyzCache\|readyzResultTTL" internal/ src/ app/` — MUST return zero
- Go: `go build ./...` MUST pass
- TS: `npm run build` or `pnpm build` MUST pass
- Integration test: unauthenticated GET /readyz returns 200 or 503, NEVER 401
- Integration test: when a dep is down, /readyz returns 503 with that dep's `status: "down"`

### Gate 2 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "`/ready` works, K8s doesn't care" | Drift between config, dashboards, Tenant Manager. Anti-pattern #2. | **MUST rename to `/readyz`. No alias.** |
| "Cache /readyz 5s to reduce load" | Cache + probe interval = blind window. Live checks are O(ms). Anti-pattern #1. | **FORBIDDEN. Remove cache layer.** |
| "Return 200 with degraded checks — K8s will figure it out" | K8s only acts on status code, not body. 200 = keep routing. | **MUST return 503 on any down/degraded.** |
| "Status 'ok' is more readable than 'up'" | Vocabulary is closed. Tooling parses exact strings. | **MUST use `up`/`down`/`degraded`/`skipped`/`n/a` exactly.** |
| "Put /readyz behind auth for security" | K8s probes are unauthenticated. Auth = 401 = K8s kills pod. | **MUST mount /readyz BEFORE auth middleware.** |

<block_condition>
HARD GATE: /readyz responds with correct shape. Aggregation rule returns 503 when any check is down/degraded. Mounted before auth. No caching. No alias paths.
</block_condition>

---

## Gate 3: TLS Detection (url.Parse, Not Substring)

**MANDATORY if any DB/queue dep detected. SKIP only if service has zero deps with TLS concern.**

**Dispatch `ring:backend-engineer-golang` or `ring:backend-engineer-typescript` with context:**

> TASK: Implement TLS detection helpers that parse connection URLs via `url.Parse` + `url.ParseQuery`. These will feed the `tls` field in /readyz responses AND be used by `ValidateSaaSTLS` in Gate 4.
>
> CONTEXT FROM GATE 1: {dependency construction sites, DSN/URI env vars}
> DETECTED DEPS requiring TLS detection: {subset of Gate 0 deps with TLS concern}
>
> {INCLUDE: MANDATORY Agent Instruction block}
>
> Required functions (Go):
> ```go
> func detectPostgresTLS(dsn string) (bool, error)  // sslmode != "disable"
> func detectMongoTLS(uri string) (bool, error)     // tls=true OR ssl=true OR scheme mongodb+srv
> func detectAMQPTLS(rawURL string) (bool, error)   // scheme amqps
> func detectRedisTLS(rawURL string) (bool, error)  // scheme rediss
> func detectS3TLS(endpoint string) (bool, error)   // scheme https OR empty (AWS default)
> func detectHTTPUpstreamTLS(baseURL string) (bool, error)  // scheme https
> ```
>
> TypeScript equivalents using the `URL` built-in or `new URL(str)`.
>
> Constraints:
> 1. FORBIDDEN: `strings.Contains(uri, "tls=true")` or `uri.includes("tls=")`. Substring match fails for URL-encoded params and is ambiguous (`tls=false` matches `tls=`). Anti-pattern #4.
> 2. FORBIDDEN: reflection on live connection objects (`*amqp.Connection`, `*mongo.Client`) — libraries do NOT reliably expose TLS state after dial. Anti-pattern #5.
> 3. MUST use `url.Parse` for scheme detection, `u.Query()` for query-param detection.
> 4. MUST handle the `mongodb+srv://` scheme as TLS-implicit.
> 5. MUST return `(false, nil)` for empty connection strings — not an error (dep not configured).
> 6. MUST return `(false, err)` for malformed URLs — surface parsing errors.
>
> Reference detection patterns:
> ```go
> func detectPostgresTLS(dsn string) (bool, error) {
>     if dsn == "" { return false, nil }
>     u, err := url.Parse(dsn)
>     if err != nil { return false, err }
>     sslmode := u.Query().Get("sslmode")
>     return sslmode != "" && sslmode != "disable", nil
> }
>
> func detectAMQPTLS(rawURL string) (bool, error) {
>     if rawURL == "" { return false, nil }
>     u, err := url.Parse(rawURL)
>     if err != nil { return false, err }
>     return u.Scheme == "amqps", nil
> }
> ```
>
> Write helpers in `internal/bootstrap/tls_detection.go` (Go) or `lib/tls-detection.ts` (TS). Unit tests MUST cover: valid TLS URL, valid non-TLS URL, empty string, malformed URL, URL-encoded params, ambiguous substring (e.g., `tls=false` embedded in another value).
>
> TDD: write table-driven failing tests first for each detection function, then implement.

**Verification:**

- `grep -rn "url\.Parse\|url\.ParseQuery\|new URL(" internal/bootstrap/tls_detection.go lib/tls-detection.ts` — MUST return results
- `grep -rn 'strings\.Contains.*"tls=\|strings\.Contains.*"sslmode=\|includes.*"tls="' internal/ src/` — MUST return zero results
- `grep -rn "reflect\..*TLSConfig\|conn\.TLSConnectionState" internal/` — MUST return zero results in TLS-detection context
- Unit tests: table-driven with min 6 cases per detection function (valid TLS, valid non-TLS, empty, malformed, URL-encoded, substring-ambiguous)
- `go test ./internal/bootstrap/... -run TLS` MUST pass with 100% coverage on detection functions

### Gate 3 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "`strings.Contains(uri, \"tls=true\")` works for my DSN format" | Fails on URL-encoded params; matches `tls=false` as substring of larger strings. Anti-pattern #4. | **MUST use `url.Parse` + `Query().Get(\"tls\")`.** |
| "Reflect on `*mongo.Client` to check TLS state" | Libraries don't reliably expose TLS after dial. Especially RabbitMQ. Anti-pattern #5. | **MUST use URL scheme (`mongodb+srv://`, `amqps://`, `rediss://`).** |
| "Skip TLS detection for Redis — we don't care about cache TLS" | SaaS mode enforces TLS on ALL DBs including Redis. Silent skip = SaaS TLS hole. | **MUST detect TLS for every dep, even cache.** |

<block_condition>
HARD GATE: Zero substring-match TLS detection. Zero reflection-based TLS detection. All six detection helpers present with 100% unit test coverage.
</block_condition>

---

## Gate 4: SaaS TLS Enforcement (ValidateSaaSTLS)

**Always executes. NON-NEGOTIABLE.** A service that starts silently without TLS in SaaS mode IS the Monetarie failure mode.

**Dispatch `ring:backend-engineer-golang` or `ring:backend-engineer-typescript` with context:**

> TASK: Implement `ValidateSaaSTLS()` as a single centralized function called from bootstrap BEFORE any connection is opened. This enforces the SaaS TLS requirement with a hard-fail at startup.
>
> CONTEXT FROM GATE 1: {bootstrap path, connection construction order, config struct location}
> DEPS WITH DSN/URI: {subset of Gate 0 deps}
> TLS DETECTION HELPERS: {from Gate 3 — import and reuse}
>
> {INCLUDE: MANDATORY Agent Instruction block}
>
> DEPLOYMENT_MODE contract:
> | Value | Meaning | TLS requirement |
> |-------|---------|-----------------|
> | `saas` | Lerian-hosted multi-tenant | MANDATORY for ALL DB connections |
> | `byoc` | Customer-hosted | Recommended, not hard-enforced |
> | `local` | Developer workstation | Optional |
> | (unset) | Defaults to `local` | Optional |
>
> Required function:
> ```go
> func ValidateSaaSTLS(cfg *Config) error {
>     if os.Getenv("DEPLOYMENT_MODE") != "saas" {
>         return nil
>     }
>
>     checks := []struct {
>         name    string
>         connStr string
>         detect  func(string) (bool, error)
>     }{
>         {"postgres", cfg.Postgres.DSN, detectPostgresTLS},
>         {"mongodb", cfg.Mongo.URI, detectMongoTLS},
>         {"rabbitmq", cfg.RabbitMQ.URL, detectAMQPTLS},
>         {"redis", cfg.Redis.URL, detectRedisTLS},
>     }
>
>     for _, c := range checks {
>         if c.connStr == "" { continue }
>         tls, err := c.detect(c.connStr)
>         if err != nil {
>             return fmt.Errorf("validate TLS for %s: %w", c.name, err)
>         }
>         if !tls {
>             return fmt.Errorf("DEPLOYMENT_MODE=saas: TLS required for %s but not configured", c.name)
>         }
>     }
>     return nil
> }
> ```
>
> Bootstrap integration:
> ```go
> func Bootstrap() error {
>     cfg := LoadConfig()
>     if err := ValidateSaaSTLS(cfg); err != nil {
>         return fmt.Errorf("TLS enforcement failed: %w", err)
>     }
>     // ... THEN open connections, register routes, etc.
> }
> ```
>
> Constraints:
> 1. FORBIDDEN: inline TLS checks at each connection site. Centralization prevents drift. Anti-pattern #6.
> 2. MUST run BEFORE any connection is opened. Runtime check is too late.
> 3. MUST return an error with the specific dependency name that failed. Operator needs to know which DSN to fix.
> 4. MUST short-circuit when DEPLOYMENT_MODE is not "saas" — do NOT enforce in byoc or local.
> 5. MUST be importable by tests — write tests that feed synthetic configs and assert pass/fail.
>
> File location: `internal/bootstrap/tls_enforcement.go` (Go) or `lib/tls-enforcement.ts` (TS).
>
> TDD: write failing tests first:
> - DEPLOYMENT_MODE=saas + non-TLS Postgres DSN → returns error mentioning "postgres"
> - DEPLOYMENT_MODE=saas + TLS DSNs for all deps → returns nil
> - DEPLOYMENT_MODE=local + non-TLS DSNs → returns nil (no enforcement)
> - DEPLOYMENT_MODE=saas + empty DSN → returns nil (dep not configured)
> - DEPLOYMENT_MODE=saas + malformed DSN → returns wrapped parse error

**Verification:**

- `grep -rn "func ValidateSaaSTLS\|function validateSaaSTLS\|export function validateSaaSTLS" internal/ src/` — MUST return exactly one definition
- `grep -rn "ValidateSaaSTLS(cfg)\|validateSaaSTLS(config)" internal/ src/` — MUST be called from bootstrap BEFORE connection-opening code
- `grep -rn "DEPLOYMENT_MODE.*saas" internal/ src/ | grep -v "ValidateSaaSTLS\|tls_enforcement\|tls-enforcement"` — MUST return zero (no scattered inline checks)
- Unit tests cover all 5 scenarios above
- Integration test: launch with DEPLOYMENT_MODE=saas + non-TLS DSN → service refuses to start with clear error

### Gate 4 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Inline TLS check at each connection site is clearer" | Scattered checks drift. One miss = SaaS silently insecure. Anti-pattern #6. | **MUST extract to `ValidateSaaSTLS()`.** |
| "Check TLS at runtime in /readyz, not startup" | Runtime check = connections already open with non-TLS. Too late. | **MUST run BEFORE connection opens, at bootstrap.** |
| "Skip enforcement for byoc — customer decides" | byoc is non-SaaS, enforcement is opt-in. But skip = byoc path silently works same as saas. Keep `DEPLOYMENT_MODE` check strict. | **MUST enforce ONLY when DEPLOYMENT_MODE=saas.** |
| "We'll add enforcement after the service is stable" | Shipping without enforcement = shipping the Monetarie failure mode. | **MANDATORY NOW. No deferral.** |

<block_condition>
HARD GATE: ValidateSaaSTLS exists as single function. Called from bootstrap before connections. Zero scattered DEPLOYMENT_MODE checks. Integration test: DEPLOYMENT_MODE=saas + non-TLS DSN refuses to start.
</block_condition>

---

## Gate 5: Metrics Emission

**Always executes. NON-NEGOTIABLE.** Two dogfood audits found /readyz implementations that met every other gate EXCEPT metrics. A blind /readyz is not a /readyz.

**Dispatch `ring:backend-engineer-golang` or `ring:backend-engineer-typescript` with context:**

> TASK: Register and emit three readyz metrics — histogram, counter, gauge — from the /readyz handler AND the startup self-probe.
>
> CONTEXT FROM GATE 1: {existing metrics registry file:line — Prometheus, lib-commons observability, etc.}
>
> {INCLUDE: MANDATORY Agent Instruction block}
>
> Required metrics:
> | Metric | Type | Labels | Emitted when |
> |--------|------|--------|--------------|
> | `readyz_check_duration_ms` | Histogram | `dep`, `status` | EVERY /readyz check execution |
> | `readyz_check_status` | Counter | `dep`, `status` | EVERY /readyz check outcome |
> | `selfprobe_result` | Gauge | `dep` (0=down, 1=up) | After startup self-probe completes per dep |
>
> Histogram buckets (ms): `[1, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000]` — covers cache-fast to timeout-slow.
>
> Go reference (Prometheus):
> ```go
> var (
>     readyzDuration = prometheus.NewHistogramVec(
>         prometheus.HistogramOpts{
>             Name:    "readyz_check_duration_ms",
>             Help:    "Duration of /readyz dependency checks in milliseconds",
>             Buckets: []float64{1, 5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000},
>         },
>         []string{"dep", "status"},
>     )
>     readyzStatus = prometheus.NewCounterVec(
>         prometheus.CounterOpts{Name: "readyz_check_status", Help: "Count of /readyz check outcomes"},
>         []string{"dep", "status"},
>     )
>     selfProbeResult = prometheus.NewGaugeVec(
>         prometheus.GaugeOpts{Name: "selfprobe_result", Help: "Last self-probe result per dependency (1=up, 0=down)"},
>         []string{"dep"},
>     )
> )
>
> func init() {
>     prometheus.MustRegister(readyzDuration, readyzStatus, selfProbeResult)
> }
>
> func emitCheckDuration(dep, status string, d time.Duration) {
>     readyzDuration.WithLabelValues(dep, status).Observe(float64(d.Milliseconds()))
> }
> func emitCheckStatus(dep, status string) {
>     readyzStatus.WithLabelValues(dep, status).Inc()
> }
> func emitSelfProbeResult(dep string, up bool) {
>     v := 0.0
>     if up { v = 1.0 }
>     selfProbeResult.WithLabelValues(dep).Set(v)
> }
> ```
>
> TypeScript / Next.js: use `prom-client` or the project's existing metrics registry with equivalent HistogramVec/CounterVec/GaugeVec.
>
> Integration constraints:
> 1. MUST call `emitCheckDuration` and `emitCheckStatus` from the /readyz handler for every per-dep check (Gate 2 handler loop).
> 2. MUST call `emitSelfProbeResult` from `RunSelfProbe` (Gate 7) for every dep probed.
> 3. MUST register metrics at package init or app bootstrap — expose via existing `/metrics` endpoint.
> 4. If the service has NO metrics registry, Gate 5 ADDS one. Do NOT defer to "add registry later".
> 5. Histogram Observe MUST be in milliseconds (not nanoseconds, not seconds). Name is `_ms`.
>
> TDD: write a failing integration test first — "hit /readyz, then scrape /metrics, assert all three metric names appear with expected labels" — then implement.

**Verification:**

- `grep -rn "readyz_check_duration_ms\|readyz_check_status\|selfprobe_result" internal/ src/` — MUST match all three
- `grep -rn "prometheus\.MustRegister\|registry\.register\|register(readyz" internal/ src/` — MUST register all three
- `grep -rn "emitCheckDuration\|emitCheckStatus" internal/*/readyz*.go src/*/readyz*.ts` — MUST be called from handler
- `grep -rn "emitSelfProbeResult" internal/*/selfprobe*.go src/*/selfprobe*.ts` — MUST be called from self-probe
- Integration test: hit /readyz → scrape /metrics → all three metric families present, labels include `dep` and `status`
- Integration test: trigger a down dep → counter increments with `status="down"` label

### Gate 5 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We already log /readyz results, metrics are redundant" | Logs don't aggregate. Cannot alert on rate-of-drift. Cannot graph trends. | **MUST emit all three metrics.** |
| "Emit metrics only on failure to reduce cardinality" | Status label has 5 values; dep count is bounded. Cardinality is fine. Selective emission breaks rate calculations. | **MUST emit on every check.** |
| "Histogram in seconds is fine" | Name is `_ms`. Mixing units = silent dashboard bugs. | **MUST observe in milliseconds.** |
| "Registry already exists for other metrics, assume it'll just work" | Register explicitly. MUST be visible in /metrics scrape. | **MUST verify /metrics scrape shows all three.** |

<block_condition>
HARD GATE: All three metrics registered and visible in /metrics scrape after hitting /readyz. Integration test passes. Phase 5 INCOMPLETE without this.
</block_condition>

---

## Gate 6: Circuit Breaker + Multi-Tenant Carve-Out

**SKIP only if** Gate 1 analysis found zero circuit breakers AND the service is single-tenant. Skip requires explicit justification in Gate 1.5 preview.

**Dispatch `ring:backend-engineer-golang` or `ring:backend-engineer-typescript` with context:**

> TASK: Extend /readyz to surface circuit-breaker state on breaker-wrapped deps, AND implement multi-tenant carve-out (`n/a` status + `/readyz/tenant/:id` endpoint) for tenant-scoped deps.
>
> CONTEXT FROM GATE 1: {breaker usage sites, multi-tenant indicators, tenant-scoped dep list}
>
> {INCLUDE: MANDATORY Agent Instruction block}
>
> ### Circuit Breaker Integration
>
> For each breaker-wrapped dep, the /readyz checker MUST:
>
> | Breaker state | readyz status | breaker_state field |
> |---------------|---------------|---------------------|
> | closed | `up` (run the probe; actual status from ping) | `"closed"` |
> | half-open | `degraded` (DO NOT probe; treat as degraded) | `"half-open"` |
> | open | `down` (DO NOT probe; error field = "circuit breaker open") | `"open"` |
>
> Reference (Go, gobreaker):
> ```go
> func (c *UpstreamFeesChecker) Check(ctx context.Context) DependencyCheck {
>     state := c.breaker.State()
>     check := DependencyCheck{BreakerState: state.String()}
>     switch state {
>     case gobreaker.StateClosed:
>         start := time.Now()
>         if err := c.ping(ctx); err != nil {
>             check.Status, check.Error = "down", err.Error()
>         } else {
>             check.Status = "up"
>         }
>         check.LatencyMs = time.Since(start).Milliseconds()
>     case gobreaker.StateHalfOpen:
>         check.Status = "degraded"
>     case gobreaker.StateOpen:
>         check.Status = "down"
>         check.Error = "circuit breaker open"
>     }
>     return check
> }
> ```
>
> Rationale for half-open → `degraded`: the breaker is actively testing recovery. Traffic during half-open is exactly what the breaker is protecting against. Mapping to `up` masks the recovery window; mapping to `down` is too aggressive. `degraded` + 503 is correct — K8s withholds traffic while breaker probes.
>
> ### Multi-Tenant Carve-Out
>
> For each tenant-scoped dep (per-tenant RabbitMQ broker, per-tenant Mongo):
>
> 1. Global `/readyz` returns `status: "n/a"` with `reason` explaining why.
> 2. NEW endpoint: `/readyz/tenant/:id` probes the tenant's deps. Same response contract.
> 3. Authentication: `/readyz/tenant/:id` requires an authenticated tenant-scoped request (goes THROUGH auth middleware, unlike global `/readyz` which is before auth).
> 4. NEVER silently omit a tenant-scoped dep from the global response — silent = invisible = future bug.
>
> Reference response shape:
> ```json
> {
>   "rabbitmq": {
>     "status": "n/a",
>     "tls": true,
>     "reason": "multi-tenant mode: no global broker; query /readyz/tenant/:id"
>   }
> }
> ```
>
> Constraints:
> 1. MUST NOT silently omit tenant-scoped deps from global /readyz. Explicit `n/a` with reason.
> 2. MUST report `tls` field when uniform across tenants (e.g., all tenants use `amqps://`).
> 3. MUST mount `/readyz/tenant/:id` AFTER tenant middleware so `c.Locals("tenantId")` resolves.
> 4. MUST use the same response contract (status vocabulary, aggregation, timeouts) for tenant-scoped endpoint.
>
> TDD: write failing tests:
> - Breaker closed + dep reachable → status `up`, breaker_state `closed`
> - Breaker half-open → status `degraded`, breaker_state `half-open`, NO ping executed
> - Breaker open → status `down`, breaker_state `open`, error = "circuit breaker open"
> - Multi-tenant: global /readyz for tenant-scoped dep → `n/a` + reason
> - Multi-tenant: /readyz/tenant/:id with valid tenant → probes that tenant's deps with correct shape

**Verification:**

- `grep -rn "breaker_state\|BreakerState" internal/ src/` — MUST return results if breakers detected
- `grep -rn "StateClosed\|StateHalfOpen\|StateOpen\|state === \"closed\"" internal/ src/` — MUST cover all three states
- `grep -rn "\"n/a\"\|status.*\"n/a\"" internal/ src/` — MUST return results if multi-tenant detected
- `grep -rn "/readyz/tenant" internal/ src/ app/` — MUST register endpoint if multi-tenant
- Unit tests: 3 breaker-state scenarios per wrapped dep
- Integration test (multi-tenant only): global /readyz shows `n/a`; tenant-scoped endpoint probes correctly

### Gate 6 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Treat half-open as up" | Breaker actively testing. Traffic during half-open = what breaker protects against. | **MUST map half-open → `degraded` → 503.** |
| "Probe the breaker-wrapped dep anyway, override the breaker" | Breaker exists precisely to prevent cascade failures. Bypassing = defeating the point. | **MUST respect breaker state. Do NOT ping on half-open/open.** |
| "Multi-tenant — just skip tenant-scoped deps from /readyz" | Silent omission = invisible. Operators can't distinguish skipped from bug. | **MUST report `n/a` with reason.** |
| "Pick a canonical tenant to probe for global /readyz" | Canonical tenant can be unhealthy while others are fine. False negative risk. | **MUST use `n/a` + tenant-scoped endpoint.** |

<block_condition>
HARD GATE (when applicable): Breaker state surfaces via breaker_state field. Half-open → degraded. Tenant-scoped deps report n/a + /readyz/tenant/:id endpoint exists.
</block_condition>

---

## Gate 7: Startup Self-Probe + /health + Graceful Drain ⛔ NEVER SKIPPABLE

**Always executes. CANNOT be skipped.**

This gate wires three runtime-critical behaviors: startup self-probe (blocks traffic until deps verified), /health gating (K8s restarts pod if self-probe failed), and graceful drain (K8s stops routing before deps close).

**Dispatch `ring:backend-engineer-golang` or `ring:backend-engineer-typescript` or `ring:frontend-bff-engineer-typescript` with context:**

> TASK: Implement startup self-probe, wire /health to reflect self-probe + lib-commons runtime state, and add graceful-drain coupling to /readyz.
>
> CONTEXT FROM GATE 1: {bootstrap path, /health handler location, SIGTERM/shutdown handling}
>
> {INCLUDE: MANDATORY Agent Instruction block}
>
> ### 7a. Startup Self-Probe (Go)
>
> ```go
> var selfProbeOK atomic.Bool
>
> func init() { selfProbeOK.Store(false) } // unhealthy until proven otherwise
>
> func RunSelfProbe(ctx context.Context, deps Dependencies, logger Logger) error {
>     logger.Infow("startup_self_probe_started", "probe", "self")
>     allHealthy := true
>
>     for name, checker := range deps.HealthCheckers() {
>         check := checker.Check(ctx)
>         emitSelfProbeResult(name, check.Status == "up")
>
>         if check.Status == "up" || check.Status == "skipped" || check.Status == "n/a" {
>             logger.Infow("self_probe_check",
>                 "probe", "self", "name", name, "status", check.Status,
>                 "duration_ms", check.LatencyMs, "tls", check.TLS, "reason", check.Reason,
>             )
>         } else {
>             logger.Errorw("self_probe_check",
>                 "probe", "self", "name", name, "status", check.Status,
>                 "duration_ms", check.LatencyMs, "error", check.Error,
>             )
>             allHealthy = false
>         }
>     }
>
>     if !allHealthy {
>         logger.Errorw("startup_self_probe_failed", "probe", "self")
>         return fmt.Errorf("self-probe failed: one or more dependencies unreachable")
>     }
>     logger.Infow("startup_self_probe_passed", "probe", "self")
>     return nil
> }
> ```
>
> Bootstrap integration:
> ```go
> if err := RunSelfProbe(ctx, deps, logger); err != nil {
>     // selfProbeOK stays false — /health returns 503 → K8s livenessProbe restarts pod
> } else {
>     selfProbeOK.Store(true)
> }
> ```
>
> ### 7b. /health Handler (Single Endpoint, No Split)
>
> ```go
> f.Get("/health", func(c *fiber.Ctx) error {
>     if !selfProbeOK.Load() {
>         return libHTTP.RenderError(c, fiber.StatusServiceUnavailable, "self-probe failed")
>     }
>     return libHTTP.HealthWithDependencies(deps)(c)
> })
> ```
>
> FORBIDDEN: `/health/live` + `/health/ready` split. /readyz covers readiness. Single /health covers liveness with self-probe gating. Anti-pattern #3.
>
> ### 7c. Graceful Drain
>
> ```go
> var drainingState atomic.Bool
>
> func RegisterShutdown(ctx context.Context, server *fiber.App, deps Dependencies, grace time.Duration) {
>     sig := make(chan os.Signal, 1)
>     signal.Notify(sig, syscall.SIGTERM, syscall.SIGINT)
>
>     go func() {
>         <-sig
>         drainingState.Store(true)
>         // Give K8s time to observe 503 on /readyz and stop routing
>         time.Sleep(grace) // typical: 10-15s, MUST be >= periodSeconds * failureThreshold + buffer
>         _ = server.Shutdown()
>         deps.Close()
>     }()
> }
> ```
>
> `/readyz` handler (from Gate 2) MUST short-circuit to 503 when `drainingState.Load() == true`. Add the check at the start of the handler (already reserved in Gate 2 scaffold).
>
> ### 7d. Next.js Self-Probe (instrumentation.ts)
>
> MANDATORY: use `register()` as the self-probe point. BLOCKS before first request.
>
> FORBIDDEN: `process.exit()` on probe failure inside `register()`. Prevents K8s log tail collection. Anti-pattern #7. Use a module-level flag + 503 on /readyz instead.
>
> ```ts
> // instrumentation.ts
> let startupHealthy = false;
> let startupChecks: Record<string, DependencyCheck> = {};
>
> export async function register() {
>   const results = await runAllChecks();
>   startupChecks = results;
>   startupHealthy = Object.values(results).every(c =>
>     c.status === "up" || c.status === "skipped" || c.status === "n/a"
>   );
>   emitSelfProbeResults(results);
> }
>
> export { startupHealthy, startupChecks };
> ```
>
> `/api/admin/health/readyz/route.ts` imports `startupHealthy` and returns 503 when false.
>
> Constraints:
> 1. MUST NOT call `process.exit()` in Next.js register(). Let K8s learn via /readyz 503.
> 2. MUST sequence shutdown: drainingState.Store(true) → grace period → server.Shutdown() → deps.Close(). Reversing causes panics.
> 3. Drain grace period MUST be >= K8s readinessProbe `periodSeconds * failureThreshold + buffer`. Default: 12s.
> 4. MUST emit `selfprobe_result` metric from RunSelfProbe for every dep.
> 5. MUST handle nil/missing deps gracefully — service may boot in degraded mode if feature flags disable optional deps.
>
> TDD: write failing tests:
> - Self-probe with all deps up → selfProbeOK becomes true, /health returns 200
> - Self-probe with a down dep → selfProbeOK stays false, /health returns 503
> - Drain signal received → /readyz returns 503 even if all deps up
> - Next.js register() with down dep → startupHealthy stays false, /api/admin/health/readyz returns 503
> - Next.js register() with down dep → process does NOT exit

**Verification:**

- `grep -rn "RunSelfProbe\|runSelfProbe" internal/ src/` — MUST return a function definition
- `grep -rn "selfProbeOK\.Load()\|startupHealthy" internal/*/health* src/ app/api/admin/health/` — MUST gate /health AND /readyz
- `grep -rn "drainingState\|draining\.store\|drainingFlag" internal/ src/` — MUST be wired to /readyz handler
- `grep -rn "signal\.Notify.*SIGTERM\|process\.on\(\"SIGTERM\"" internal/ src/` — MUST register handler
- `grep -rn "process\.exit" instrumentation.ts` — MUST return zero results
- `grep -rn "\"/health/live\"\|\"/health/ready\"" internal/ src/ app/` — MUST return zero results
- Integration tests: all 5 TDD scenarios pass

### Gate 7 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "/readyz covers it, self-probe is redundant" | /readyz runs per-request; self-probe gates traffic BEFORE first request. Different concerns. | **Both MANDATORY.** |
| "Split /health into /health/live + /health/ready" | /readyz covers readiness. Split adds surface, no benefit. Anti-pattern #3. | **Single /health. No split.** |
| "Skip drain — K8s rolling deploy handles it" | K8s only knows to stop routing when /readyz returns 503. Without drain-coupled 503, in-flight requests die mid-flight. | **MUST wire drainingState to /readyz.** |
| "process.exit() on probe failure in Next.js" | Prevents K8s log tail collection. Anti-pattern #7. | **MUST use module-level flag + 503.** |
| "Drain grace of 2 seconds is enough" | Must be >= K8s periodSeconds * failureThreshold + buffer. Default 12s. | **MUST calibrate against K8s probe config.** |

<block_condition>
HARD GATE: Self-probe implemented. /health gated on selfProbeOK. Drain flag wired to /readyz. Drain grace period >= 12s default. No process.exit in Next.js. No /health/live + /health/ready split.
</block_condition>

---

## Gate 8: Tests

**Always executes.**

**Dispatch `ring:backend-engineer-golang` or `ring:backend-engineer-typescript` with context:**

> TASK: Write comprehensive tests for the readyz implementation.
> LANGUAGE: {go | typescript}
> DETECTED DEPS: {from Gate 0}
>
> {INCLUDE: MANDATORY Agent Instruction block}
>
> Required test layers:
>
> 1. **Response contract tests** (unit/integration):
>    - All deps up → 200, shape matches contract, all per-dep fields present
>    - One dep down → 503, that dep has `status: "down"` + `error`, others still reported
>    - One dep degraded (breaker half-open) → 503, `status: "degraded"` + `breaker_state`
>    - All deps skipped/n/a → 200 (aggregation counts them healthy)
>    - Response includes top-level `version` and `deployment_mode`
>
> 2. **TLS detection tests** (already in Gate 3 — re-verify):
>    - Table-driven for each detection function: valid TLS, valid non-TLS, empty, malformed, URL-encoded, substring-ambiguous
>
> 3. **SaaS enforcement tests**:
>    - DEPLOYMENT_MODE=saas + non-TLS DSN → service fails to start with clear error
>    - DEPLOYMENT_MODE=saas + all TLS DSNs → start succeeds
>    - DEPLOYMENT_MODE=local + non-TLS DSN → start succeeds (no enforcement)
>
> 4. **Metrics emission tests**:
>    - Hit /readyz → scrape /metrics → all three metric families present
>    - Trigger down dep → counter increments with `status="down"` label
>    - Histogram buckets populated after multiple hits
>
> 5. **Self-probe tests**:
>    - All deps up → selfProbeOK true, /health 200
>    - Down dep → selfProbeOK false, /health 503
>    - Next.js: register() with down dep → startupHealthy false, process still alive
>
> 6. **Graceful drain tests**:
>    - Trigger drain → /readyz returns 503 immediately
>    - Drain grace period elapses → server.Shutdown called → deps.Close called
>    - In-flight requests complete during grace (no abrupt kill)
>
> 7. **Multi-tenant tests** (if applicable):
>    - Global /readyz shows `n/a` for tenant-scoped deps
>    - /readyz/tenant/:valid-id → 200 with tenant's dep statuses
>    - /readyz/tenant/:invalid-id → 404 or tenant-not-found error
>
> 8. **Chaos tests** (if toxiproxy available):
>    - Connection loss mid-run → /readyz returns 503 within next probe
>    - Latency injection → per-dep timeout fires, status `down`, error mentions timeout
>
> 9. **Goroutine leak tests** (Go, with `go.uber.org/goleak` if available):
>    - Full boot + drain → no goroutine leaks (breaker goroutines, metrics goroutines, deps cleanup)
>
> All tests follow TDD RED→GREEN→REFACTOR: write test first, confirm it fails correctly, implement, confirm it passes, refactor for clarity.

**Verification:**

- `go test ./... -v -count=1` MUST pass (Go)
- `npm test` or `pnpm test` MUST pass (TS)
- `go test ./... -cover` — coverage on readyz-related files MUST be >= 85%
- `go test ./... -race` MUST pass (concurrent probe handling, drain signal races)
- Integration tests exercise real endpoints (httptest or equivalent), not mocked handlers

<block_condition>
HARD GATE: All 9 test layers present and passing. Coverage >= 85%. No race conditions.
</block_condition>

---

## Gate 9: Code Review

**Dispatch 10 parallel reviewers (same pattern as ring:codereview).**

MUST include this context in ALL 10 reviewer dispatches:

> **/READYZ IMPLEMENTATION REVIEW CONTEXT:**
>
> - Service is implementing the canonical /readyz contract. Origin: Monetarie SaaS incident (silent MongoDB TLS mismatch caused client-facing outage while K8s liveness passed).
> - Response shape: `{status, checks: {<dep>: {status, latency_ms, tls, error?, reason?, breaker_state?}}, version, deployment_mode}`. 200 if healthy, 503 if any check is `down` or `degraded`.
> - Status vocabulary (closed set): `up`/`down`/`degraded`/`skipped`/`n/a`. Aggregation: ANY `down`/`degraded` → 503.
> - Mount path: `/readyz` (no aliases like `/ready`, `/health/ready`). Mounted BEFORE auth middleware.
> - FORBIDDEN anti-patterns: response caching, `/ready` alias, `/health/live`+`/health/ready` split, substring TLS detection, reflection-based TLS, scattered inline SaaS TLS checks, process.exit() in Next.js register().
> - SaaS TLS enforcement: centralized `ValidateSaaSTLS()` at bootstrap BEFORE any connection opens.
> - Metrics: `readyz_check_duration_ms` (histogram, ms), `readyz_check_status` (counter), `selfprobe_result` (gauge). All three NON-NEGOTIABLE.
> - Self-probe: `RunSelfProbe` at bootstrap sets `selfProbeOK atomic.Bool`; /health returns 503 when false.
> - Graceful drain: `drainingState atomic.Bool` flipped on SIGTERM → /readyz returns 503 → K8s stops routing → grace period → server + deps close.
> - Circuit breaker (when wrapped): half-open → `degraded` (DO NOT ping), open → `down` (DO NOT ping).
> - Multi-tenant: tenant-scoped deps return `n/a` globally + `/readyz/tenant/:id` for per-tenant probing.

| Reviewer | Focus |
|----------|-------|
| ring:code-reviewer | Response contract compliance, handler structure, status vocabulary correctness, aggregation rule |
| ring:business-logic-reviewer | Dep scope — no synthetic business-logic probes; dep list covers real integration points; deployment_mode handling |
| ring:security-reviewer | SaaS TLS enforcement, no credential leakage in error fields, /readyz mounted BEFORE auth (K8s can probe), /readyz/tenant/:id AFTER auth |
| ring:test-reviewer | Coverage, TDD evidence, chaos tests, drain tests, multi-tenant tests if applicable, contract tests cover all status values |
| ring:nil-safety-reviewer | selfProbeOK atomic nil-safety, type assertions in OnChange-like callbacks (if any), nil deps handling |
| ring:consequences-reviewer | Impact on K8s probe config, upstream Tenant Manager contract, downstream operator dashboards, drain grace vs K8s probe timing |
| ring:dead-code-reviewer | Anti-patterns removed: cache layer, /ready alias, /health/live+ready split, inline TLS checks, substring TLS detection, reflection TLS |
| ring:performance-reviewer | Per-dep timeouts appropriate (2s DB, 1s cache), no response caching, histogram buckets cover dep latency range, no unbounded goroutines |
| ring:multi-tenant-reviewer | Tenant-scoped deps correctly report n/a; /readyz/tenant/:id authenticated; no cross-tenant leakage in global /readyz |
| ring:lib-commons-reviewer | lib-commons observability integration (metrics registry), HealthWithDependencies usage on /health, no reimplementation of deleted utilities |

MUST pass all 10 reviewers. Critical findings → fix and re-review.

<block_condition>
HARD GATE: 10 reviewers PASS. Zero CRITICAL findings unresolved.
</block_condition>

---

## Gate 10: User Validation

MUST present checklist for explicit user approval:

```markdown
## Readyz Implementation Complete

Endpoint:
- [ ] `/readyz` mounted at correct path (Go: /readyz, Next.js: /api/admin/health/readyz)
- [ ] Mounted BEFORE authentication middleware (K8s probes unauthenticated)
- [ ] Returns canonical JSON shape (status, checks, version, deployment_mode)
- [ ] Status vocabulary: up/down/degraded/skipped/n/a only
- [ ] Aggregation rule: 503 iff any check is down or degraded
- [ ] No response caching layer
- [ ] No /ready alias path, no /health/live+/health/ready split

TLS:
- [ ] TLS detection via url.Parse (not substring, not reflection)
- [ ] ValidateSaaSTLS exists as centralized function
- [ ] Called from bootstrap BEFORE any connection opens
- [ ] DEPLOYMENT_MODE=saas + non-TLS DSN → service refuses to start

Metrics:
- [ ] readyz_check_duration_ms histogram registered and emitted per check
- [ ] readyz_check_status counter registered and emitted per check
- [ ] selfprobe_result gauge registered and emitted per dep
- [ ] All three visible in /metrics scrape

Self-probe + /health:
- [ ] RunSelfProbe runs at bootstrap BEFORE accepting traffic
- [ ] selfProbeOK atomic.Bool gates /health (or startupHealthy for Next.js)
- [ ] Self-probe results logged as structured JSON
- [ ] No process.exit() on probe failure in Next.js

Graceful drain:
- [ ] drainingState atomic.Bool flipped on SIGTERM
- [ ] /readyz returns 503 when draining
- [ ] Drain grace period >= K8s periodSeconds * failureThreshold + buffer

Conditional (if applicable):
- [ ] Circuit-breaker-wrapped deps surface breaker_state (closed/half-open/open)
- [ ] Half-open breaker → degraded status (NOT probed)
- [ ] Tenant-scoped deps report n/a with reason + /readyz/tenant/:id endpoint exists

Tests:
- [ ] Contract tests, TLS detection tests, SaaS enforcement tests, metrics tests, self-probe tests, drain tests all passing
- [ ] Coverage >= 85% on readyz-related files
- [ ] go test ./... -race (or equivalent) passes

Review:
- [ ] 10 reviewers passed with zero CRITICAL findings
```

---

## Gate 11: Activation Guide

**MUST generate `docs/readyz-guide.md` in the project root.** Direct, operator-focused, no filler.

Built from Gate 0 (stack), Gate 1 (analysis), and Gate 1.5 (approved plan).

The guide MUST include:

1. **Overview**: what /readyz probes in this service (one paragraph, scope fence explicit)

2. **Endpoints**:
   - `/readyz` — readiness probe (K8s readinessProbe target)
   - `/health` — liveness probe (K8s livenessProbe target, gated by startup self-probe)
   - `/readyz/tenant/:id` (if multi-tenant) — per-tenant readiness, authenticated
   - `/metrics` — Prometheus scrape (includes readyz metrics)

3. **Environment variables**:
   - `DEPLOYMENT_MODE` — `saas` / `byoc` / `local` (default `local`). SaaS enforces TLS on all DBs.
   - `HEALTH_PORT` (Go workers) — port for /readyz + /health
   - `VERSION` — injected at build or via ldflags
   - Any optional-dep flags (e.g., `REDIS_ENABLED`) that route to `skipped` status

4. **K8s probe configuration** (copy-pasteable):
   ```yaml
   readinessProbe:
     httpGet:
       path: /readyz
       port: http
     initialDelaySeconds: 5
     periodSeconds: 5
     failureThreshold: 2
   livenessProbe:
     httpGet:
       path: /health
       port: http
     initialDelaySeconds: 30
     periodSeconds: 10
     failureThreshold: 3
   ```

5. **Response contract**: filled-in JSON example with every dep this service probes

6. **Status vocabulary reference** (for operator dashboards):
   - `up` — probe succeeded
   - `down` — probe failed (dep unreachable, error in `error` field)
   - `degraded` — circuit breaker half-open OR partial failure
   - `skipped` — optional dep disabled
   - `n/a` — not applicable in current mode (multi-tenant global)

7. **Metrics reference**:
   - `readyz_check_duration_ms{dep, status}` — latency histogram (ms buckets)
   - `readyz_check_status{dep, status}` — count of check outcomes
   - `selfprobe_result{dep}` — gauge (0=down, 1=up) set at startup

8. **Operational runbook**:
   - `/readyz` returning 503 → check which dep is `down`/`degraded`, inspect error, verify network/credentials
   - `/health` returning 503 → self-probe failed at startup; K8s will restart pod; inspect startup logs for `startup_self_probe_failed`
   - Service refusing to start in SaaS mode → check `DEPLOYMENT_MODE=saas` + TLS posture of DSNs; `ValidateSaaSTLS` error names the failing dep
   - In-flight requests killed during deploy → drain grace period too short; increase past `periodSeconds * failureThreshold`

9. **Scope fence reminder**: what is NOT in /readyz — synthetic business-logic probes, certificate validity, performance SLIs

10. **Common errors**:
    - 401 on /readyz → /readyz mounted behind auth (fix: mount before auth middleware)
    - Metrics not in /metrics → registry not exposed or metrics not registered; check `prometheus.MustRegister` calls
    - `selfprobe_result` stays 0 → RunSelfProbe not invoked or dep unreachable at boot; check startup logs
    - /readyz returns cached/stale results → cache layer in front (FORBIDDEN); remove it

---

## State Persistence

Save to `docs/ring-dev-readyz/current-cycle.json` for resume support:

```json
{
  "cycle": "readyz-implementation",
  "language": "go",
  "service_type": "api",
  "deployment_mode": "saas",
  "dependencies_detected": 5,
  "dependencies_covered": 5,
  "existing_readyz": true,
  "compliance_audit": {
    "S1_path": "NON-COMPLIANT",
    "S2_vocabulary": "NON-COMPLIANT",
    "S3_aggregation": "COMPLIANT",
    "S4_response_fields": "NON-COMPLIANT",
    "S5_tls_detection": "NON-COMPLIANT",
    "S6_validate_saas_tls": "NON-COMPLIANT",
    "S7_metrics": "NON-COMPLIANT",
    "S8_self_probe": "NON-COMPLIANT",
    "S9_graceful_drain": "NON-COMPLIANT"
  },
  "anti_patterns_detected": {
    "N1_caching": true,
    "N2_ready_alias": true,
    "N3_health_split": false,
    "N4_substring_tls": true,
    "N5_reflection_tls": false,
    "N6_inline_saas_tls": false,
    "N7_next_process_exit": false
  },
  "gates": {
    "0": "PASS",
    "1": "PASS",
    "1.5": "PASS",
    "2": "IN_PROGRESS",
    "3": "PENDING",
    "4": "PENDING",
    "5": "PENDING",
    "6": "SKIP (no breakers, single-tenant)",
    "7": "PENDING",
    "8": "PENDING",
    "9": "PENDING",
    "10": "PENDING",
    "11": "PENDING"
  },
  "current_gate": 2
}
```

---

## Anti-Rationalization Table (Skill-Level)

**Skill-level rationalizations** (per-gate tables are inside each gate section above):

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "K8s TCP probe is enough" | TCP ≠ app ready. Monetarie incident: pod alive, Mongo dead. | **STOP. Implement /readyz (Gate 2).** |
| "Existing /readyz is fine, skip the skill" | Existence ≠ compliance. Two dogfood audits found 20%-80%-compliant implementations. | **STOP. Run Gate 0 compliance audit. Every NON-COMPLIANT S-check → corresponding gate executes.** |
| "Cache /readyz to reduce load" | Cache TTL + probe interval = blind window. Anti-pattern #1. | **STOP. FORBIDDEN. Remove cache layer.** |
| "`/ready` and `/readyz` are the same thing" | K8s, Tenant Manager, dashboards target exact paths. Drift. Anti-pattern #2. | **STOP. Exact `/readyz`. No alias.** |
| "Split /health into /live and /ready" | /readyz covers readiness. Split adds surface, no benefit. Anti-pattern #3. | **STOP. Single /health + /readyz.** |
| "`strings.Contains(uri, \"tls=true\")` works" | False positives/negatives on URL-encoded params. Anti-pattern #4. | **STOP. MUST use `url.Parse`.** |
| "Reflect on live connection for TLS" | Libraries don't reliably expose TLS after dial. Anti-pattern #5. | **STOP. MUST use URL scheme.** |
| "Inline TLS checks at each connection site" | Scattered = drift = silent SaaS insecure start. Anti-pattern #6. | **STOP. MUST centralize in `ValidateSaaSTLS()`.** |
| "process.exit() on probe failure in Next.js" | Kills log tail collection. Anti-pattern #7. | **STOP. MUST use module-level flag + 503.** |
| "Metrics are optional — we log everything" | Logs don't aggregate. Cannot alert. Cannot graph. | **STOP. Gate 5 is NON-NEGOTIABLE.** |
| "Skip self-probe, /readyz covers it" | /readyz is per-request; self-probe gates traffic BEFORE first request. | **STOP. Both MANDATORY (Gate 7).** |
| "Skip drain — K8s rolling deploy handles it" | K8s only acts on /readyz 503. Without drain-coupled 503, in-flight requests die. | **STOP. MUST wire drainingState to /readyz.** |
| "Circuit breaker half-open counts as up" | Breaker actively testing recovery. Traffic = exactly what breaker protects against. | **STOP. MUST map half-open → `degraded` → 503.** |
| "Multi-tenant plugin skips tenant-scoped deps" | Silent omission = invisible. | **STOP. MUST report `n/a` + `/readyz/tenant/:id`.** |
| "I'll make a quick edit directly" | FORBIDDEN. All code via engineer agent. | **STOP. Dispatch required.** |
| "Skip code review, readyz is simple" | Silent failure modes are this skill's whole motivation. | **STOP. 10 reviewers MANDATORY (Gate 9).** |
| "Skip TDD, manual testing is enough" | MANDATORY: RED→GREEN→REFACTOR. Manual testing does not count. | **STOP. TDD required for gates 2-8.** |
| "DEPLOYMENT_MODE is runtime, not startup" | TLS enforcement must run BEFORE connections open. Runtime is too late. | **STOP. ValidateSaaSTLS at bootstrap.** |
| "Frontend doesn't need /readyz" | Console caused Monetarie. Every app needs it. | **STOP. Gate 2 MANDATORY.** |
| "We'll add [X] later" | "Later" = client-facing incident. This skill exists because of "later". | **STOP. Implement in the corresponding gate now.** |
