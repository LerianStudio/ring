---
name: ring:creating-grafana-dashboards
description: |
  Author Grafana dashboards for Lerian Go services rooted in real lib-observability
  telemetry (tracing, metrics, log, constants). Three phases — Sweep (telemetry inventory),
  Iterate (PM deliberation on SLIs/SLOs and alerts), Author (Grafonnet libsonnet → JSON in CI)
  — and installs a blocking CI drift gate. Use when scaffolding dashboards, building a
  telemetry dictionary, or auditing observability. Skip if service is non-Go, emits no
  telemetry, or task is just folder organization.
---

# Creating Grafana Dashboards (lib-observability, PM-team)

## When to use

Sweep mode:
- "Create / scaffold Grafana dashboards for this service"
- "Inventory telemetry / build telemetry dictionary"
- "Audit observability before designing dashboards"
- "Produce dashboards as code for {service}"
- "PM wants visibility into {domain} — what dashboards do we need?"

Reference mode:
- "What's the right panel for HTTP request latency?"
- "RED vs USE methodology for this metric type?"
- "How do I compose Grafonnet panels?"
- "Which Grafonnet template fits a counter / histogram / gauge?"

## Skip when

- Service is not a Go project (lib-observability is Go-only at this skill's scope)
- Service emits no telemetry (pre-instrumentation; instrument the service before dashboard authoring, then use ring:dev-implementation to verify observability checks pass)
- Task is purely Grafana folder organization or dashboard import (no authoring)
- Service is consumer-only sidecar with no metrics surface

## Sequence

**Runs before:** ring:dev-cycle, ring:dev-cycle-frontend

## Related

**Complementary:** ring:dev-implementation, ring:codebase-explorer, ring:streaming-event-mapping, ring:using-lib-observability, ring:using-tracing
**Similar:** ring:using-runtime, ring:using-assert

## Prerequisites

- Go service with lib-observability initialized in bootstrap (`tracing.NewTelemetry`, `metrics.NewFactory`, `zap.NewLogger`)
- At least one metric, span, or structured log emission point present
- docs/ directory writable
- Grafonnet toolchain available in CI (jsonnet + grafonnet-lib) — installer instructions in ci-drift-check.md


Orchestrates a 3-phase, 8-gate workflow to produce Grafana dashboards grounded in real telemetry. You orchestrate. Agents explore. PM iterates. You NEVER read, write, or edit source code directly during the sweep.

**Announce at start:** "Using ring:creating-grafana-dashboards through 8 gates (0–7)."

## Mode Selection

| Request Shape | Mode |
|---|---|
| "Create / scaffold dashboards" / "build telemetry dictionary" | **Sweep** (run gates 0–7) |
| "Which panel for X?" / "RED vs USE?" / "Grafonnet template for Y?" | **Reference** (load `sub-files/reference.md`) |

---

# SWEEP MODE

## Telemetry Architecture (lib-observability)

Lerian Go services emit telemetry through `github.com/LerianStudio/lib-observability`:
- **Tracing** via `lib-observability/tracing` — `tracer.Start(ctx, name, opts...)` returning `context.Context, trace.Span`
- **Metrics** via `lib-observability/metrics` — fluent factory producing `meter.Int64Counter`, `meter.Float64Histogram`, `meter.Int64UpDownCounter`, `meter.Int64ObservableGauge`
- **Logs** via `lib-observability/log` (interface) and `lib-observability/zap` (implementation) — structured fields, automatically correlated with active span via `trace_id`/`span_id`
- **OTel attribute / metric / event names** via `lib-observability/constants` — canonical string constants; dashboards reference these for label and metric names
- **Cross-cutting** — `tenant_id` propagation through context, error attribution via `span.RecordError` + `span.SetStatus`

> **Deprecated shims:** `lib-commons/v5/commons/{opentelemetry,zap,log,metrics}` still compile but route through lib-observability. New emission sites MUST import lib-observability directly. The sweep detects both canonical and shim imports.

**WebFetch canonical docs (lib-observability — develop branch; main has only LICENSE + README):**
- Tracing: `https://raw.githubusercontent.com/LerianStudio/lib-observability/develop/tracing/doc.go`
- Metrics: `https://raw.githubusercontent.com/LerianStudio/lib-observability/develop/metrics/doc.go`
- Log: `https://raw.githubusercontent.com/LerianStudio/lib-observability/develop/log/doc.go`
- Constants: `https://raw.githubusercontent.com/LerianStudio/lib-observability/develop/constants/doc.go`

**WebFetch changelog:** `https://raw.githubusercontent.com/LerianStudio/lib-observability/develop/CHANGELOG.md`

## Authoring Format: Grafonnet (Mandatory)

Dashboards are authored as **Grafonnet** (Jsonnet templating language) — compiled to JSON in CI. Raw JSON dashboards are FORBIDDEN.

Reasons:
- Diffable in PR review (libsonnet is code-shaped, JSON is not)
- Composable via `import` and inheritance
- Templated panel patterns reusable across themes
- Single source of truth — JSON is a build artifact, not a checked-in source

Toolchain setup: `sub-files/ci-drift-check.md`. Panel templates: `sub-files/grafonnet-templates/`.

## Theme Taxonomy

**Free-form per service.** PM defines the theme directories under `docs/dashboards/{theme}/` during Gate 5. No enforced taxonomy — Lerian services are observability islands and theme naming reflects each service's domain.

Common-but-not-mandatory examples: `transactions/`, `auth/`, `ledger/`, `infrastructure/`, `business-kpis/`, `sla/`. The skill SUGGESTS themes from dictionary contents in Gate 4; PM ACCEPTS, RENAMES, MERGES, or SPLITS in Gate 5.

## Drift Gate Posture

CI drift detection is **BLOCKING from day 1**. Any divergence between regenerated dictionary and committed `telemetry-dictionary.md` fails the PR. This is a deliberate cold-start choice — the skill is greenfield, no installed base to retrofit, every new metric emits under the strict regime.

Drift gate spec: `sub-files/ci-drift-check.md`.

## Gate Overview

| Gate | Name | Agent | Cadence |
|------|------|-------|---------|
| 0 | Stack Detection | Orchestrator (grep + read) | Once per run |
| 1 | Telemetry Sweep (7 angles) | ring:codebase-explorer × 7 parallel | Once per run |
| 2 | Dictionary Assembly + Validation | Orchestrator (deterministic merge) | Once per run |
| 3 | Dictionary Rendering | Orchestrator → markdown writer | Once per run |
| 4 | Theme Proposal + Dashboard Plans | Orchestrator (LLM opinion via reference.md) | Once per run |
| 5 | PM Iteration — NEVER SKIPPABLE | User (PM team) | Loops until APPROVED |
| 6 | Grafonnet Authoring | ring:backend-engineer-golang per theme | Per approved theme |
| 7 | CI Drift Gate Setup | Orchestrator | Once (idempotent) |

Gates execute sequentially. Gate 1 parallelizes internally across 7 angles. Gate 6 parallelizes per approved theme.

## Gate 0: Stack Detection

Orchestrator executes directly. Detect in parallel:

```
1. Go version:                grep "^go " go.mod | head -1
2. lib-observability version: grep "lib-observability" go.mod
3. lib-commons version:       grep "lib-commons" go.mod
4. Tracing package present:   grep -rn "lib-observability/tracing\|lib-commons/v5/commons/opentelemetry" internal/ cmd/   # canonical + deprecated shim
5. Metrics package present:   grep -rn "lib-observability/metrics\|lib-commons/v5/commons/opentelemetry" internal/ cmd/   # canonical + deprecated shim
6. Meter init:                grep -rn "Meter(\|NewMeter\|meter.Int64Counter\|meter.Float64Histogram" internal/ cmd/
7. Tracer init:               grep -rn "Tracer(\|NewTracer\|tracer.Start" internal/ cmd/
8. Log emission:              grep -rn "lib-observability/log\|lib-observability/zap\|lib-commons/v5/commons/log\|lib-commons/v5/commons/zap" internal/ cmd/   # canonical + deprecated shim
9. HTTP framework:            grep -rn "gofiber/fiber\|labstack/echo\|gin-gonic" go.mod
10. gRPC server:              grep -rn "grpc.NewServer" internal/ cmd/
11. RabbitMQ command consumers: grep -rn "lib-commons/v5/commons/rabbitmq" internal/ cmd/   # command queues; event emission goes through lib-streaming
12. lib-streaming present:    grep "lib-streaming" go.mod
13. Tenant source:            grep -rn "tmcore.GetTenantIDContext\|GetTenantID" internal/
14. Existing dictionary:      test -f docs/dashboards/telemetry-dictionary.md
15. Existing dashboards:      ls docs/dashboards/ 2>/dev/null
16. Grafonnet in CI:          test -f .github/workflows/telemetry-drift.yml
17. Service identity:         cat go.mod | grep "^module"
```

Emit `/tmp/dashboards-recon.json`:
```json
{
  "service_name": "...",
  "go_version": "...",
  "lib_observability_version": "...",
  "lib_commons_version": "...",
  "lib_streaming_present": false,
  "tracing_initialized": true,
  "metrics_initialized": true,
  "metric_emission_present": true,
  "trace_emission_present": true,
  "structured_log_present": true,
  "deprecated_shim_imports": ["lib-commons/v5/commons/opentelemetry"],
  "http_framework": "fiber|echo|gin|none",
  "grpc_server_present": true,
  "rabbitmq_command_consumers_present": true,
  "tenant_source": "tmcore.GetTenantIDContext",
  "existing_dictionary": true,
  "existing_themes": ["transactions", "ledger"],
  "drift_gate_installed": false
}
```

**HARD GATE:**
- If not Go → STOP.
  - If no lib-observability tracing/metrics usage detected (canonical or deprecated shim) → STOP, surface "service is not instrumented; instrument the service before dashboard authoring, then use ring:dev-implementation to verify observability checks pass" to user.
- If service has < 3 metric/trace/log emissions → STOP, surface "insufficient telemetry surface for dashboards".

## Gate 1: Telemetry Sweep (7 Parallel Angles)

### ⛔ STOP-CHECK BEFORE DISPATCH

Before emitting any Task call, count the explorers you intend to launch in this turn.
- Count MUST equal 7.
- If count < 7 → STOP. Do not partial-dispatch. Reconcile against the 7 angles below and try again.
- The 7 angles are the canonical sweep. No substitutions, no omissions.

### ⛔ MUST NOT trickle-dispatch

All 7 explorers leave in the SAME TURN, before reading any explorer output.

Forbidden sequences:
- Dispatch explorer 1 → read result → dispatch explorer 2
- Dispatch a subset → wait → dispatch the rest
- Dispatch follow-up explorers conditioned on partial output
- Loop sequentially over the angle list

If you find yourself about to dispatch an explorer in a turn AFTER any explorer has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the gate INCOMPLETE rather than completing the trickle.

### Self-verify after dispatch

After the dispatch turn, verify all 7 Task calls were emitted in that single turn. If fewer than 7 went out, the gate did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial pool.

### Parallel dispatch — atomic batch

Emit all 7 Task calls in a SINGLE TURN, as one atomic batch.

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete pool in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.

Dispatch all 7 angles in **one parallel batch**. Wait for all before Gate 2.

**Per-explorer dispatch** (`subagent_type: ring:codebase-explorer`):

```
## Target: <absolute path>
## Your Angle: <angle number + name>
## Severity / Detection Patterns / Schema / Notes
<verbatim from sub-files/sweep-angles.md for this angle>

## Output
Write to: /tmp/dashboards-sweep-{N}-{angle-slug}.json
Schema: { angle_number, angle_name, primitives: [...] }
Each primitive includes file:line, name, description, labels/attributes, unit, type-specific fields.
If no findings: write file with empty primitives array.
```

The 7 angles cover:
1. **Counter metrics** — `meter.Int64Counter`, `Float64Counter`, increments, labels, descriptions, units
2. **Histogram metrics** — `meter.Float64Histogram`, `Int64Histogram`, boundaries, units, labels
3. **Gauge metrics** — `meter.Int64UpDownCounter`, `Int64ObservableGauge`, callbacks
4. **Trace spans** — `tracer.Start`, span names, kind, attributes, parent-child structure, error recording
5. **Structured log fields** — `log.With`, level usage, contexts where emitted, trace correlation
6. **Cross-cutting concerns** — `tenant_id` labeling, `trace_id`/`span_id` propagation, error attribution, request correlation
7. **Framework instrumentation** — Fiber/gRPC/RabbitMQ middleware, auto-spans, manual override sites

Full angle specifications: `sub-files/sweep-angles.md`.

**Verification:** 7 JSON files exist, all parse, schema-valid per `sub-files/dictionary-schema.md`.

**HARD GATE:** Missing/malformed file → re-dispatch ONLY failing angle.

## Gate 2: Dictionary Assembly + Validation

Orchestrator merges 7 angle JSONs into `/tmp/dashboards-dictionary.json`. Validate per `sub-files/dictionary-schema.md`:

- Metric names match `^[a-z][a-z0-9_]*$` (Prometheus convention)
- Span names match `^[a-z][a-z0-9_.-]*$`
- All primitives have `description` ≥ 30 chars
- Histograms declare `unit` (seconds, bytes, count) and `boundaries` if custom
- Tenant-scoped primitives have `tenant_id` in labels/attributes
- No duplicate `(name, type)` pairs across angle outputs
- Cross-cutting Angle 6 findings cross-reference primitives from Angles 1–4

Validation failures → re-dispatch failing angle's explorer with correction notes. Do NOT manually edit JSON.

## Gate 3: Dictionary Rendering

Orchestrator writes `docs/dashboards/telemetry-dictionary.md` from validated JSON, following `sub-files/dictionary-schema.md` rendering contract:

- YAML frontmatter `_meta` block: service name, generated-at timestamp, source commit SHA, lib-commons version, primitive counts
- Metrics section: one `### {metric_name}` per metric, with stable YAML block (type, unit, labels, description, emission_sites)
- Traces section: one `### {span_name}` per span, with stable YAML block (kind, attributes, parents, emission_sites)
- Logs section: structured fields catalog with levels and emission contexts
- Cross-cutting section: tenant propagation map, trace correlation map, error attribution map

**Critical**: rendering MUST be deterministic — same input JSON produces byte-identical output. Order alphabetically within each section. Sort labels alphabetically within each primitive. This is what makes drift detection in Gate 7 possible.

## Gate 4: Theme Proposal + Dashboard Plans

Orchestrator analyzes the dictionary and proposes themes + dashboards. This is the LLM-opinion gate — apply `sub-files/reference.md` (RED/USE methodology, panel pattern catalog) to dictionary contents.

For each proposed theme, produce a **dashboard plan** stub at `/tmp/dashboards-plan-{theme}.md`:

```markdown
# Theme: {theme_name}

## Audience (proposed)
- Primary: <engineering | product | exec | ops | support>
- Secondary: <...>

## Dashboards
### {dashboard_1_name}
- Methodology: RED | USE | hybrid
- SLIs surfaced: <list>
- Time range default: <1h | 6h | 24h | 7d>
- Panels:
  1. {panel_name} — {panel_pattern} on metric {metric_ref} — Grafonnet template: {template}
  2. ...
- Alert candidates: <list with thresholds>

### {dashboard_2_name}
...
```

Themes are SUGGESTIONS only. PM may rename, merge, split, or reject in Gate 5.

## Gate 5: PM Iteration — NEVER SKIPPABLE

Present `sub-files/pm-iteration-prompts.md` checklist to PM team:

- Theme names — accept, rename, merge, split?
- Audience per theme — correct?
- Methodology choice (RED vs USE vs hybrid) — sound for this domain?
- SLIs surfaced — match what stakeholders actually need?
- Time range defaults — match operational cadence?
- Alert thresholds vs informational — which panels need alerts attached?
- Missing dashboards — anything PM expected that wasn't proposed?

**Response options:**
- `APPROVED: <theme1> <theme2> ...` → proceed to Gate 6 for listed themes
- `REVISE theme {name}: <change>` → loops Gate 4 for that theme only
- `RENAME theme {old} -> {new}` → renames in plan, loops Gate 4 light
- `REJECT theme {name}` → drops from approval list
- `ADD theme {name}: <description>` → orchestrator generates new plan, loops Gate 4
- `BLOCKED: <reason>` → halts skill, returns with surface for triage

**HARD GATE:** Must not proceed to Gate 6 without explicit `APPROVED: ...` listing at least one theme.

## Gate 6: Grafonnet Authoring (Per Approved Theme)

For EACH approved theme, dispatch `ring:backend-engineer-golang` (Lerian's Go specialist; Grafonnet is jsonnet, but the engineer's discipline around code quality and reusability transfers — and they own the lib-commons mental model that makes label correctness checkable).

Per-theme dispatch:

```
## Target: docs/dashboards/{theme}/
## Inputs:
- /tmp/dashboards-plan-{theme}.md (PM-approved plan)
- docs/dashboards/telemetry-dictionary.md (canonical primitive contract)
- pm-team/skills/creating-grafana-dashboards/sub-files/grafonnet-templates/ (panel libsonnet templates)
- pm-team/skills/creating-grafana-dashboards/sub-files/reference.md (panel pattern → template mapping)

## Task:
1. Create docs/dashboards/{theme}/ directory
2. Write {theme}.libsonnet importing relevant grafonnet-templates panels
3. Materialize each panel from the plan with concrete metric refs from the dictionary
4. Compose into a Dashboard with rows/grid per plan structure
5. Write README.md per theme explaining: audience, SLIs, intended use, alert thresholds
6. Validate: jsonnet compiles cleanly, panel queries reference only primitives present in dictionary

## Output:
- docs/dashboards/{theme}/{theme}.libsonnet
- docs/dashboards/{theme}/README.md
- /tmp/dashboards-build-{theme}.log (compilation output)

## Constraints:
- MUST NOT invent metric names — every PromQL/LogQL/TraceQL query references primitives from telemetry-dictionary.md
- MUST template tenant_id as a Grafana variable when present in primitive labels
- MUST follow Grafonnet conventions (no raw JSON; if a panel pattern isn't in templates/, propose a new template)
```

**Verification:** Per theme — libsonnet compiles to JSON, README present, no metric references missing from dictionary.

**HARD GATE:** Compilation failure → re-dispatch with diagnostic, do not move to Gate 7.

## Gate 7: CI Drift Gate Setup

Orchestrator installs (idempotent) the drift detection workflow per `sub-files/ci-drift-check.md`:

1. Write `.github/workflows/telemetry-drift.yml` (blocking PR check)
2. Write `scripts/regenerate-telemetry-dictionary.sh` (regenerates dictionary; called by CI and locally)
3. Update `Makefile`: add `make telemetry-dictionary` target invoking the regenerate script
4. Compile all theme libsonnet to JSON in `docs/dashboards/{theme}/{theme}.json` and add to .gitignore (build artifact)
5. Surface to user: workflow path, local regen command, expected first-CI-run behavior

**Idempotence:** If `.github/workflows/telemetry-drift.yml` already exists, diff against canonical version. Update only if drift detected. Surface diff to user before overwriting.

## State Persistence

Save to `/tmp/dashboards-state.json`:

```json
{
  "skill": "creating-grafana-dashboards",
  "service_name": "<from Gate 0>",
  "current_gate": 0,
  "gates": {
    "0": "PENDING",
    "1": "PENDING",
    "2": "PENDING",
    "3": "PENDING",
    "4": "PENDING",
    "5": "PENDING_USER_APPROVAL",
    "6": "PENDING",
    "7": "PENDING"
  },
  "metrics": {
    "primitives_counters": 0,
    "primitives_histograms": 0,
    "primitives_gauges": 0,
    "primitives_spans": 0,
    "primitives_log_fields": 0,
    "themes_proposed": 0,
    "themes_approved": 0,
    "dashboards_authored": 0
  }
}
```

---

# REFERENCE MODE

Full reference content in `sub-files/reference.md`. Load sections relevant to the question.

## Quick Navigation

| # | Section | What you'll find |
|---|---|---|
| 1 | RED Methodology | Rate, Errors, Duration — when each metric type fits |
| 2 | USE Methodology | Utilization, Saturation, Errors — for resources |
| 3 | Panel Pattern Catalog | Mapping primitive type → panel pattern → Grafonnet template |
| 4 | Theme Decision Tree | How to suggest themes from dictionary contents |
| 5 | Grafonnet Conventions | Naming, composition, variable conventions, tenant templating |
| 6 | Alert Threshold Heuristics | When to attach alerts, default thresholds, escalation tiers |
| 7 | Cross-cutting Patterns | Tenant variable, trace exemplars, log-to-trace links |
| 8 | Anti-pattern Catalog | Six failure modes (vanity panels, alert noise, etc.) |

Read `sub-files/reference.md` for full detail.
