---
name: ring:production-readiness-audit
description: Ring-standards-aligned production readiness audit across Structure, Security, Operations, Quality, and Infrastructure — 43 base dimensions + 1 conditional (multi-tenant) = up to 44 dimensions. Use before production deployment, periodic reviews, onboarding, or major releases. Skip for prototypes, libraries, or single-dimension checks. Runs explorers in batches of 10 and produces a scored report (0-430 base, max 440 with multi-tenant) with severity ratings.
---

# Production Readiness Audit

## When to use
- Preparing a service for production deployment
- Conducting periodic security or quality review of a codebase
- Onboarding to assess codebase health and maturity
- Evaluating technical debt before a major release
- Validating compliance with Ring engineering standards

## Skip when
- Project is a prototype or throwaway proof-of-concept not heading to production
- Codebase is a library or SDK with no deployable service component
- User only needs a single-dimension check (use targeted review instead)

## Audit categories
- **Structure** (11): pagination, errors, routes, bootstrap, runtime, core deps, naming, domain modeling, nil-safety, api-versioning, resource-leaks
- **Security** (9): auth, IDOR, SQL, validation, secret-scanning, data-encryption, multi-tenant, rate-limiting, cors
- **Operations** (7): telemetry, health, config, connections, logging, resilience, graceful-degradation
- **Quality** (10): idempotency, docs, debt, testing, dependencies, performance, concurrency, migrations, linting, caching
- **Infrastructure** (6): containers, hardening, cicd, async, makefile, license

A multi-agent audit system evaluating **43 base dimensions + 1 conditional (multi-tenant) = up to 44 dimensions** across 5 categories, aligned with Ring development standards. Detects project stack, loads relevant standards via WebFetch, runs explorers in **batches of 10**, appending results incrementally to a single report file.

**Announce at start:** "Using ring:production-readiness-audit to audit {N} dimensions in 5 batches."

## Audit Dimensions

| Category | Count | Dimensions |
|----------|-------|------------|
| A: Code Structure | 11 | Pagination, Errors, Routes, Bootstrap, Runtime, Core Deps, Naming, Domain Modeling, Nil Safety, API Versioning, Resource Leaks |
| B: Security | 9 (+1c) | Auth, IDOR, SQL, Input Validation, Secret Scanning, Data Encryption, Rate Limiting, CORS, Multi-Tenant* |
| C: Operations | 7 | Telemetry, Health, Config, Connections, Logging, Resilience, Graceful Degradation |
| D: Quality | 10 | Idempotency, API Docs, Tech Debt, Testing, Dependencies, Performance, Concurrency, Migrations, Linting, Caching |
| E: Infrastructure | 6 | Containers, HTTP Hardening, CI/CD, Async, Makefile, License |

*Conditional on MULTI_TENANT detection. Max score: 430 base + 10 conditional = 440.

## Execution Protocol

### Step 0: Stack Detection

```
Glob("**/go.mod")         → GO=true
Glob("**/package.json")   → parse for React/Next (FRONTEND) or Express/Fastify (TS_BACKEND)
Glob("**/Dockerfile*")    → DOCKER=true
Glob("**/Makefile")       → MAKEFILE=true
Glob("**/LICENSE*")       → LICENSE=true
Grep("MULTI_TENANT")      → if found in env/config files: MULTI_TENANT=true
```

### Step 0.5: Load Ring Standards

WebFetch based on detected stack. On failure, note and proceed with generic patterns.

**Go stack:** core.md, bootstrap.md, security.md, domain.md, api-patterns.md, quality.md, architecture.md, messaging.md, domain-modeling.md, idempotency.md from `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/`

**If MULTI_TENANT:** Also fetch multi-tenant.md from same base URL.

**Always:** devops.md and sre.md from `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/`

Store fetched content for injection between `---BEGIN STANDARDS---` / `---END STANDARDS---` markers in each explorer prompt.

### Step 1: Initialize Report File

Write header to `docs/audits/production-readiness-{YYYY-MM-DDTHH:MM:SS}.md` with detected stack, standards loaded, dimension count, and dynamic max score.

### Step 2–6: Batch Execution

Read the dimension-specific prompts from `dimensions/` subdirectory before dispatching each batch.

| Batch | Read File | Agents | Category Focus |
|-------|-----------|--------|----------------|
| 1 | `dimensions/structure.md` (agents 1-5) + `dimensions/security.md` (agents 6-9) + `dimensions/operations.md` (agent 10) | 10 | Structure + Security start + Telemetry |
| 2 | `dimensions/operations.md` (agents 12-15) + `dimensions/quality.md` (agents 16-20) | 9 | Operations + Quality start |
| 3 | `dimensions/quality.md` (agents 21-23) + `dimensions/infrastructure.md` (agents 24-27) + `dimensions/structure.md` (agents 28-30) | 10 | Quality + Infrastructure + Structure cont. |
| 4 | `dimensions/quality.md` (agents 31, 40) + `dimensions/infrastructure.md` (agents 32, 34) + `dimensions/security.md` (agents 33*, 37, 41) + `dimensions/structure.md` (agents 35, 38, 42) + `dimensions/operations.md` (agents 36, 39) | varies | Mixed (remaining dimensions) |
| 5 | `dimensions/security.md` (agents 43-44) | 2 | Rate Limiting + CORS |

*Agent 33 (Multi-Tenant) only if MULTI_TENANT=true.

**After each batch:** Append all results to report file before launching next batch.

**CRITICAL:** Each batch dispatches in a SINGLE turn with N parallel Task calls.

### ⛔ STOP-CHECK BEFORE DISPATCH (each batch)

Before emitting any Task call in a batch, count the explorers you intend to launch in this turn.
- Count MUST equal the batch size declared in the batch table above for the current batch.
- If your dispatch count diverges from the batch size → STOP and reconcile against the batch row.
- No substitutions, no omissions within a batch.

### ⛔ MUST NOT trickle-dispatch within a batch

All explorers in a batch leave in the SAME TURN, before reading any explorer output.

Forbidden sequences:
- Dispatch explorer 1 → read result → dispatch explorer 2
- Dispatch a subset of the batch → wait → dispatch the rest
- Dispatch follow-up explorers conditioned on partial output
- Loop sequentially over the batch's explorer list

If you find yourself about to dispatch an explorer in a turn AFTER any explorer in the SAME batch has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the batch INCOMPLETE rather than completing the trickle. (Sequential batch ordering is intentional; trickle within a batch is not.)

### Self-verify after dispatch

After each batch's dispatch turn, verify all batched Task calls were emitted in that single turn. If fewer went out than the batch size, the batch did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial batch.

### Parallel dispatch — atomic batch (within this batch)

Emit all Task calls for THIS BATCH in a SINGLE TURN, as one atomic batch. (Batches themselves remain sequential — do not dispatch batch N+1 until batch N has fully returned.)

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete batch in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.


### Step 7: Consolidate Report

1. Read `dimensions/scoring.md` for scoring rules
2. Calculate scores per dimension (0-10), category totals, overall score
3. Determine readiness classification (percentage-based)
4. Generate Standards Compliance Cross-Reference table
5. Update report with Executive Summary prepended

### Step 8: Visual Dashboard (MANDATORY)

Invoke `Skill("ring:visualize")` to produce an HTML dashboard at `docs/audits/production-readiness-{timestamp}-dashboard.html`.

Dashboard sections:
1. Score Hero (score/max, readiness badge, color-coded)
2. Category Scoreboard (5 cards with progress bars)
3. Dimension Heatmap (44 dims, color by score range)
4. HARD GATE Violations (if any)
5. Critical Blockers (if any)
6. Remediation Roadmap (4 phases)
7. Standards Compliance Summary

Open in browser after generation.

### Step 9: Present Summary

Summarize: stack detected, standards loaded, overall score/classification, critical/high counts, HARD GATE violations, top 3 recommendations, links to report and dashboard.

## Customization Options

| Flag | Effect |
|------|--------|
| `--modules=matching,ingestion` | Only audit specified modules |
| `--dimensions=security` | Run only security-related auditors |
| `--format=json` | Structured JSON output |
| `--no-standards` | Skip Ring standards loading (generic mode) |

## Blocker Conditions

| Condition | Action |
|-----------|--------|
| Stack undetectable | STOP — ask user to specify stack |
| Standards WebFetch fails for critical modules | STOP — audit requires standards |
| Entire batch fails | STOP — report infrastructure issue |
| docs/audits/ not writable | STOP — ensure directory exists |
