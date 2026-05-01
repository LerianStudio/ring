---
name: ring:dev-systemplane-migration
description: |
  Systemplane migration orchestrator for Lerian Go services using lib-commons (latest v5.x). Migrates services from
  .env/YAML-based configuration of operational knobs (log levels, feature flags, rate limits, timeouts,
  worker intervals) to the v5 systemplane runtime config client — a database-backed, hot-reloadable plane
  using Postgres LISTEN/NOTIFY or MongoDB change streams. v5 API surface: systemplane.NewPostgres /
  NewMongoDB → Register keys → Start → Get*/OnChange → admin.Mount with custom authorizer. Detects v4
  residue (Supervisor, BundleFactory, ApplyBehavior, SYSTEMPLANE_* env vars — all DELETED in v5.0.0) and
  fails hard until removed. Each implementation gate dispatches ring:backend-engineer-golang. Loads latest
  v5 systemplane package docs via WebFetch of lib-commons repo commons/systemplane/doc.go.

trigger: |
  - User requests systemplane integration for a Go service
  - User asks to add hot-reloadable runtime configuration
  - Task mentions "systemplane", "runtime config", "hot reload", "LISTEN/NOTIFY config", "admin.Mount",
    "systemplane.NewPostgres", "systemplane.NewMongoDB", "OnChange subscription"
  - User asks to migrate from v4 systemplane (Supervisor/BundleFactory/ApplyBehavior) to v5 client

skip_when: |
  - Service is not a Go project
  - Task does not involve runtime configuration or operational knob management
  - Service has zero hot-reloadable knobs (everything is static env-var-at-startup config)
  - Task is documentation-only, configuration-only, or non-code

prerequisites: |
  - Go service with existing configuration surface (.env, YAML, or flags)
  - Postgres or MongoDB available as backend for systemplane storage

NOT_skip_when: |
  - "Service already has v4 systemplane" → v4 was REMOVED in lib-commons v5.0.0. CANNOT compile on v5 with v4 code.
  - "Just update the imports from v4 to v5" → The v5 API is NOT the v4 API. Imports alone fail compilation.
  - "Supervisor works today, leave it" → Supervisor does not exist in v5. Architecture rewrite is mandatory.
  - "Hot reload via fsnotify is fine" → fsnotify is NON-CANONICAL. Only v5 systemplane is approved.
  - "Keys are registered, migration is done" → Register without OnChange + admin.Mount + lifecycle = dead code.
  - "We'll add admin.Mount later" → Without admin.Mount, operators cannot change config. Gate 6 is mandatory.
  - "Default authorizer is fine" → Default is DENY-ALL. Every request returns 403 until WithAuthorizer is set.

sequence:
  after: [ring:dev-devops]

related:
  complementary: [ring:dev-cycle, ring:dev-implementation, ring:dev-devops, ring:dev-unit-testing, ring:codereview, ring:dev-validation, ring:using-lib-commons]

input_schema:
  description: |
    When invoked from ring:dev-cycle (post-cycle step), receives structured handoff context.
    When invoked standalone (direct user request), these fields are auto-detected in Gate 0.
  fields:
    - name: execution_mode
      type: string
      enum: ["FULL", "SCOPED"]
      description: "FULL = complete cycle. SCOPED = only adapt new files (when existing v5 systemplane is compliant)."
      required: false
      default: "FULL"
    - name: files_changed
      type: array
      items: string
      description: "File paths changed during dev-cycle (only in SCOPED mode). Used to limit adaptation scope."
      required: false
    - name: systemplane_exists
      type: boolean
      description: "Whether systemplane code was detected by dev-cycle Step 1.5 (v4 OR v5)."
      required: false
    - name: systemplane_v5_compliant
      type: boolean
      description: "Whether existing systemplane code passed v5 compliance audit."
      required: false
    - name: detected_backend
      type: object
      properties:
        postgres: boolean
        mongodb: boolean
      description: "Backend detection from dev-cycle. Systemplane requires one of the two."
      required: false
    - name: skip_gates
      type: array
      items: string
      description: "Gate identifiers to skip (e.g., '0', '1.5'). Set by dev-cycle based on execution_mode."
      required: false

output_schema:
  format: markdown
  required_sections:
    - name: "Systemplane Migration Summary"
      pattern: "^## Systemplane Migration Summary"
      required: true
    - name: "Backend Detection"
      pattern: "^## Backend Detection"
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
    - name: v4_residue_removed
      type: integer
    - name: keys_registered
      type: integer

---

# Systemplane Migration (lib-commons v5)

## Structured Tracking Contract (MANDATORY)

MUST follow the canonical contract in [CLAUDE.md](../../../CLAUDE.md#structured-tracking-json-contract). Create or update `docs/ring-tracking/<workflow>/current-work.json`, maintain canonical `items[]`, and use this JSON as the only Kanban source. Mirror legacy `docs/ring:*/current-cycle.json` or `docs/ring-*/current-cycle.json` only for compatibility/debug. Kanban uses canonical tracking JSON only; tool usage and TodoWrite/TodoRead MUST NOT create cards.

<cannot_skip>

## CRITICAL: This Skill ORCHESTRATES. Agents IMPLEMENT.

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Detect stack, determine gates, pass context to agent, verify outputs, enforce order |
| **ring:backend-engineer-golang** | Load v5 systemplane docs via WebFetch, implement following the canonical API |
| **10 reviewers** | Review at Gate 9 |

**CANNOT change scope:** the skill defines WHAT to implement. The agent implements HOW.

**FORBIDDEN: Orchestrator MUST NOT use Edit, Write, or Bash tools to modify source code files.**
All code changes MUST go through `Task(subagent_type="ring:backend-engineer-golang")`.
The orchestrator only verifies outputs (grep, go build, go test) — MUST NOT write implementation code.

**MANDATORY: TDD for all implementation gates (Gates 2-8).** MUST follow RED → GREEN → REFACTOR: write a failing test first, then implement to make it pass, then refactor for clarity/performance. MUST include in every dispatch: "Follow TDD: write failing test (RED), implement to make it pass (GREEN), then refactor for clarity/performance (REFACTOR)."

</cannot_skip>

---

## Systemplane Architecture (v5)

v5 systemplane is a **runtime config client** with a three-step lifecycle:

1. `systemplane.NewPostgres` / `systemplane.NewMongoDB` — construct client, pass an already-open `*sql.DB` or `*mongo.Client`
2. `client.Register(namespace, key, defaultValue, opts...)` — declare every key BEFORE `Start`
3. `client.Start(ctx)` — begin listening (Postgres LISTEN/NOTIFY or Mongo change stream / poll); then `Get*` for reads, `OnChange` for reactions

Single backend per client: Postgres (LISTEN/NOTIFY, default) or MongoDB (change stream; falls back to polling via `WithPollInterval`). No bundles, no reconcilers, no supervisors, no tiered apply behaviors — those concepts were **deliberately removed** in lib-commons v5.0.0.

**Standards reference:** There is no `systemplane.md` standards file. The authoritative source is:

1. The `ring:using-lib-commons` skill for v5 package overview
2. The lib-commons v5 systemplane package docs — `commons/systemplane/doc.go` in the lib-commons repo

**WebFetch URL (v5 package docs):** `https://raw.githubusercontent.com/LerianStudio/lib-commons/main/commons/systemplane/doc.go`

**Scope of v5 systemplane — operational knobs ONLY:**

v5 is designed for configuration values that can be **mutated in place** without teardown — log levels, feature flags, rate limits, per-request timeouts, worker poll intervals, debounce windows, circuit-breaker thresholds, canary percentages.

**NOT** for settings that require resource teardown:

| Non-systemplane setting | Belongs in |
|-------------------------|------------|
| Database DSN / connection string | env vars + process restart |
| TLS material / certificates | env vars + process restart |
| Listen addresses / ports | env vars + process restart |
| Connection pool sizes (if pool rebuild is required) | env vars + process restart |
| Cluster membership / peer lists | env vars + process restart |

If you need "teardown and rebuild" semantics, that is NOT systemplane. Put it in env vars.

### MANDATORY: Canonical Import Paths (v5)

Agents MUST use these exact import paths. Include this table in every gate dispatch. MUST NOT invent paths or reuse v4 paths.

| Alias | Import Path | Purpose |
|-------|-------------|---------|
| `systemplane` | `github.com/LerianStudio/lib-commons/v5/commons/systemplane` | `Client`, constructors (`NewPostgres`, `NewMongoDB`), `Option`/`KeyOption`, `RedactPolicy` |
| `admin` | `github.com/LerianStudio/lib-commons/v5/commons/systemplane/admin` | HTTP admin routes (`admin.Mount`, `admin.WithAuthorizer`, `admin.WithActorExtractor`, `admin.WithPathPrefix`) |
| `systemplanetest` | `github.com/LerianStudio/lib-commons/v5/commons/systemplane/systemplanetest` | Contract test suite — `systemplanetest.Run(t, factory)` |

**⛔ HARD GATE:** Agent MUST NOT use `lib-commons/v4/commons/systemplane`, `lib-commons/v4/...`, or any sub-packages like `domain/`, `ports/`, `registry/`, `service/`, `bootstrap/`, `adapters/`, `testutil/`, `catalog/`, `fiberhttp/`, `systemswagger/` — all DELETED in v5.

### MANDATORY: Namespace Model

Namespaces are **free-text strings** owned by the caller. v5 does not validate, enforce, or auto-generate namespace shapes.

**Recommended convention (Lerian-standard, NOT enforced by lib-commons):**

```
<service>.<component>      e.g., "ledger.worker", "plugin-pix.consumer", "identity.http"
```

Pick one convention per service and stick to it. Namespace strings appear in:

- `client.Register(namespace, key, ...)` at startup
- `client.Get*(namespace, key)` at read time
- `admin.Mount` URL path: `GET /system/:namespace/:key`
- Postgres row / Mongo document storage keys

**Anti-pattern:** using the empty string `""` as namespace — works, but collides across services sharing a backend. MUST use a non-empty, service-scoped prefix.

### MANDATORY: Redaction Policies

Every `Register` call accepts `systemplane.WithRedaction(policy)` to control how values appear in admin HTTP responses. Three policies exist:

| Policy | Admin GET returns | Use for |
|--------|-------------------|---------|
| `systemplane.RedactNone` (default) | Raw value | Log levels, feature flags, rate limits, non-sensitive knobs |
| `systemplane.RedactMask` | Type-aware mask (`"***"` for strings, `0` for numbers) | Low-sensitivity values that should not show in dashboards |
| `systemplane.RedactFull` | `null` or omitted | Secrets, tokens, API keys — values that MUST NOT appear in any response |

**⛔ HARD GATE:** Any key storing credentials, API keys, tokens, signing material, or PII MUST use `RedactFull`. Storing such values in systemplane at all is discouraged — prefer a vault. But if stored, redaction is NON-NEGOTIABLE.

`client.KeyRedaction(namespace, key)` returns the policy, used internally by `admin.Mount` to filter responses.

### MANDATORY: Deny-by-default Authorization

`admin.Mount` ships with a **DENY-ALL** default authorizer. Every PUT/GET returns 403 until the caller supplies a custom `admin.WithAuthorizer`. This is intentional. There is no "dev mode" exception.

```go
admin.Mount(router, client,
    admin.WithPathPrefix("/system"),                    // default
    admin.WithAuthorizer(func(c *fiber.Ctx, action string) error {
        // action is "read" or "write"
        // Inspect c.Locals() for authenticated actor from upstream auth middleware.
        // Return nil to allow, error to deny.
        return nil
    }),
    admin.WithActorExtractor(func(c *fiber.Ctx) string {
        // Return a stable identifier for audit: user email, service name, etc.
        return c.Get("X-User-Email")
    }),
)
```

**⛔ HARD GATE:** A service that calls `admin.Mount` without `admin.WithAuthorizer` is non-compliant. Every admin request will fail 403. MUST supply the authorizer.

### MANDATORY: Agent Instruction (include in EVERY gate dispatch)

MUST include these instructions in every dispatch to `ring:backend-engineer-golang`:

> **STANDARDS: WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-commons/main/commons/systemplane/doc.go` and follow the v5 API exactly. The v5 API is the ONLY valid surface — v4 is deleted.**
>
> **IMPORTS: Use only the three canonical import paths from the skill — `systemplane`, `admin`, `systemplanetest`. Do NOT invent paths. Do NOT import `lib-commons/v4/commons/systemplane/*` — those packages do not exist in v5.**
>
> **SCOPE: systemplane is for operational knobs that can mutate in place. Settings requiring resource teardown (DSNs, TLS material, listen addresses) MUST stay in env vars + restart. Do NOT push them into systemplane.**
>
> **TDD: For implementation gates (2-8), follow TDD methodology — write a failing test first (RED), then implement to make it pass (GREEN). MUST have test coverage for every change.**

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Security breach, compile-breaking residue, unauthenticated admin surface | v4 import present (build fails on v5), `admin.Mount` without `WithAuthorizer`, secret key registered with `RedactNone` |
| **HIGH** | Missing core v5 surface, wrong lifecycle, silent nil reads | No `Register` before `Start`, no `OnChange` for hot-reloadable key, `SYSTEMPLANE_*` env vars still referenced in code |
| **MEDIUM** | Partial compliance, observability gap | Missing `WithLogger`/`WithTelemetry`, no validator on numeric range, namespace not service-scoped |
| **LOW** | Documentation, naming | Missing `WithDescription`, inconsistent namespace casing |

MUST report all severities. CRITICAL: STOP immediately. HIGH: Fix before gate pass. MEDIUM: Fix in iteration. LOW: Document.

---

## Pressure Resistance

| User Says | This Is | Response |
|-----------|---------|----------|
| "The service has v4 systemplane, let's just keep it" | COMPLIANCE_BYPASS | "v4 was REMOVED in lib-commons v5.0.0. You CANNOT compile against v4 systemplane on v5. Gate 2 is mandatory." |
| "Just update v4 imports to v5" | COMPLIANCE_BYPASS | "v5 API is NOT v4. Imports alone fail compilation. `Supervisor`, `BundleFactory`, `ApplyBehavior` do not exist. Full architecture rewrite required." |
| "We'll put the DB DSN in systemplane so we can hot-swap it" | SCOPE_OVERREACH | "v5 deliberately does NOT support resource teardown. DSNs belong in env vars + restart. This is a design decision, not a limitation." |
| "We don't need admin.Mount" | SCOPE_REDUCTION | "Without `admin.Mount`, operators have no way to change runtime config. Gate 6 is mandatory unless service has zero public management surface (with explicit justification)." |
| "Default authorizer is fine for dev" | SECURITY_BYPASS | "Default is DENY-ALL. Every request returns 403 until `admin.WithAuthorizer` is supplied. This is not 'dev mode' — this is intentional." |
| "We'll add OnChange later" | QUALITY_BYPASS | "Without `OnChange`, `Set()` succeeds but runtime behavior doesn't change. Users will report 'I changed the config but nothing happened.' Gate 4 is mandatory." |
| "fsnotify works fine for hot-reload" | COMPLIANCE_BYPASS | "fsnotify is NON-CANONICAL. Only v5 systemplane is approved. Gate 0 Phase 3 flags it. MUST replace." |
| "viper.WatchConfig is simpler" | COMPLIANCE_BYPASS | "Simpler ≠ canonical. Only v5 systemplane is approved for runtime config. Replace in Gate 5." |
| "Keys are registered, migration is done" | SCOPE_REDUCTION | "Register is the START, not the end. Without `OnChange` + `admin.Mount` + lifecycle wiring, keys are dead code. Gates 3-7 all mandatory." |
| "ApplyBehavior was useful, surely v5 has something similar" | COMPLIANCE_BYPASS | "No. v5 deliberately removed tiered apply. If you need BundleRebuild semantics, that config belongs in env vars + restart, NOT systemplane." |
| "We can reimplement Supervisor on top of the v5 Client" | COMPLIANCE_BYPASS | "Reimplementation = non-canonical. Skill FAILS. Use the v5 API as designed. If the v5 surface doesn't cover your need, the need belongs outside systemplane." |
| "Skip code review, v5 is simple" | QUALITY_BYPASS | "v5's simplicity means ONE wiring mistake = silent nil-returning reads. MANDATORY 10 reviewers." |
| "I'll make a quick edit directly" | CODE_BYPASS | "FORBIDDEN: All code changes go through ring:backend-engineer-golang. Dispatch the agent." |
| "It's just one line, no need for an agent" | CODE_BYPASS | "FORBIDDEN: Even single-line changes MUST be dispatched. Agent ensures standards compliance." |
| "Skip TDD, we tested manually" | QUALITY_BYPASS | "MANDATORY: RED→GREEN→REFACTOR. Manual testing does not count." |
| "Swagger was useful in v4, re-add it" | SCOPE_CREEP | "v5 has no auto-swagger. Document the 3 admin routes manually in your service's OpenAPI spec. Do NOT reimplement `swagger.MergeInto`." |

---

## Gate Overview

| Gate | Name | Condition | Agent |
|------|------|-----------|-------|
| 0 | Stack Detection + Compliance Audit (3 phases) | Always | Orchestrator |
| 1 | Codebase Analysis (config focus) | Always | ring:codebase-explorer |
| 1.5 | Implementation Preview (visual report) | Always | Orchestrator (ring:visualize) |
| 2 | lib-commons v5 Upgrade + v4 Systemplane Removal | Skip only if `lib-commons/v5` in go.mod AND zero v4 systemplane imports | ring:backend-engineer-golang |
| 3 | Client Construction + Key Registration | Always — verify compliance or implement | ring:backend-engineer-golang |
| 4 | OnChange Subscriptions (dynamic reactions) | Always unless service has zero hot-reloadable keys (with justification) | ring:backend-engineer-golang |
| 5 | Config Bridge (Config struct ← systemplane values) | Skip if no existing Config struct reads need live values | ring:backend-engineer-golang |
| 6 | Admin HTTP Mount + Authorizer | Skip only if service deliberately exposes no admin API (with justification) | ring:backend-engineer-golang |
| 7 | Wiring + Lifecycle + Backward Compat ⛔ NEVER SKIPPABLE | Always | ring:backend-engineer-golang |
| 8 | Tests | Always | ring:backend-engineer-golang |
| 9 | Code Review | Always | 10 parallel reviewers |
| 10 | User Validation | Always | User |
| 11 | Activation Guide | Always | Orchestrator |

MUST execute gates sequentially. CANNOT skip or reorder.

### Input Validation (when invoked from dev-cycle)

If this skill receives structured input from ring:dev-cycle (post-cycle handoff):

```text
VALIDATE input:
1. execution_mode MUST be "FULL" or "SCOPED"
2. If execution_mode == "SCOPED":
   - files_changed MUST be non-empty (otherwise there's nothing to adapt)
   - systemplane_exists MUST be true
   - systemplane_v5_compliant MUST be true
   - skip_gates MUST include ["0", "1.5", "2", "10", "11"]
3. If execution_mode == "FULL":
   - Core gates always execute (0, 1, 1.5, 2, 3, 7, 8, 9)
   - Conditional gates may be in skip_gates based on detection:
     - "4" may be skipped ONLY with explicit justification (no hot-reloadable keys)
     - "5" may be skipped if no Config struct reads need live values
     - "6" may be skipped ONLY with explicit justification (no admin surface)
     - "10", "11" may be skipped when invoked from dev-cycle
   - skip_gates MUST NOT contain core gates (0, 1, 1.5, 2, 3, 7, 8, 9)
4. detected_backend (if provided) pre-populates Gate 0 — still MUST verify with grep (trust but verify)

If invoked standalone (no input_schema fields):
   - Default to execution_mode = "FULL"
   - Run full Gate 0 stack detection
```

<cannot_skip>

### HARD GATE: Existence ≠ Compliance (v4 is NON-COMPLIANT by definition)

**"The service already has systemplane code" is NOT a reason to skip any gate.**

If the existing code imports `lib-commons/v4/commons/systemplane` or any of its sub-packages, or references any v4 type (`Supervisor`, `Manager` from v4, `BundleFactory`, `ApplyBehavior`, `ReloadEvent`, etc.), it is **NON-COMPLIANT** — not because of style or drift, but because **v4 was deleted in lib-commons v5.0.0**. The code cannot compile against v5.

The only valid reason to skip a gate is when the existing implementation has been **verified** to use the v5 surface documented in `commons/systemplane/doc.go` of the lib-commons v5 repo.

**Compliance verification requires EVIDENCE, not assumption.** Gate 0 Phase 2 (v5 compliance audit, S1-S8) and Phase 3 (v4 residue + non-canonical detection) are MANDATORY.

**If ANY audit check is NON-COMPLIANT → the corresponding gate MUST execute to fix it. CANNOT skip.**

</cannot_skip>

---

## Gate 0: Stack Detection + Compliance Audit

**Orchestrator executes directly. No agent dispatch.**

**This gate has THREE phases: detection, v5 compliance audit, and v4-residue + non-canonical detection.**

### Phase 1: Stack Detection

```text
DETECT (run in parallel):

1. lib-commons version:  grep "lib-commons" go.mod
2. Postgres backend:     grep -rn "database/sql\|jackc/pgx\|lib/pq" internal/ go.mod
3. MongoDB backend:      grep -rn "go.mongodb.org/mongo-driver\|mongo.Client" internal/ go.mod
4. Fiber HTTP server:    grep -rn "gofiber/fiber" internal/ go.mod
5. Existing systemplane (v5):
   - Client:           grep -rn "systemplane.NewPostgres\|systemplane.NewMongoDB" internal/
   - Registration:     grep -rn "\.Register(" internal/ | grep -i "systemplane\|namespace\|key"
   - Admin mount:      grep -rn "admin.Mount\|systemplane/admin" internal/
6. Existing systemplane (v4 — ANY match = residue to remove):
   - Any v4 import:    grep -rn "lib-commons/v4/commons/systemplane" internal/
   - v4 sub-packages:  grep -rn "systemplane/domain\|systemplane/ports\|systemplane/registry\|systemplane/service\|systemplane/bootstrap\|systemplane/adapters\|systemplane/catalog\|systemplane/testutil\|systemplane/fiberhttp\|systemplane/systemswagger" internal/
7. Non-canonical hot-reload:
   - fsnotify:         grep -rn "fsnotify" internal/ pkg/ go.mod
   - viper watcher:    grep -rn "viper.WatchConfig\|viper.OnConfigChange" internal/ pkg/
   - inotify:          grep -rn "inotify" internal/ pkg/
8. Hot-reloadable knob candidates (implementation targets):
   - Log level references:   grep -rn "logger.SetLevel\|log.SetLevel\|LOG_LEVEL" internal/
   - Feature flag reads:     grep -rn "FeatureFlag\|feature_flag\|featureflag" internal/
   - Rate-limit reads:       grep -rn "RateLimit\|rate_limit\|RATE_LIMIT" internal/
   - Timeout env reads:      grep -rn "TIMEOUT_SEC\|timeout.*time.Duration" internal/
```

### Phase 2: v5 Compliance Audit (MANDATORY if v5 systemplane code is detected)

If Phase 1 step 5 returns results, MUST run a v5 compliance audit. MUST replace existing code that does not match the canonical v5 surface.

```text
AUDIT (run in parallel — only if step 5 found existing v5 systemplane code):

NOTE: All S-checks are POSITIVE (absence of canonical pattern = NON-COMPLIANT).

S1. Client construction:
    - MUST match: grep -rn "systemplane\.NewPostgres\|systemplane\.NewMongoDB" internal/
    - (no match = NON-COMPLIANT → Gate 3 MUST implement)

S2. Key registration BEFORE Start:
    - MUST match: grep -rn "\.Register(" internal/ near systemplane client
    - VERIFY: every Register call occurs before .Start(ctx) in the same init path
    - (Register after Start = NON-COMPLIANT → Gate 3 MUST fix)

S3. Lifecycle management:
    - MUST match: grep -rn "\.Start(ctx)" internal/ near systemplane client
    - MUST match: grep -rn "\.Close()" internal/ near systemplane client (shutdown path)
    - (missing Start or Close = NON-COMPLIANT → Gate 7 MUST fix)

S4. Typed reads:
    - MUST match: grep -rn "\.GetString\|\.GetInt\|\.GetBool\|\.GetFloat64\|\.GetDuration" internal/
    - Generic Get(any) acceptable but typed variants preferred for non-string scalars
    - (zero reads = NON-COMPLIANT → Gate 5 MUST wire bridge)

S5. OnChange subscriptions:
    - MUST match: grep -rn "\.OnChange(" internal/
    - For every hot-reloadable knob identified in Phase 1 step 8, a corresponding OnChange must exist
    - (knob without OnChange = NON-COMPLIANT → Gate 4 MUST add subscription)

S6. Admin HTTP mount with authorizer:
    - MUST match: grep -rn "admin\.Mount" internal/
    - MUST match: grep -rn "admin\.WithAuthorizer" internal/
    - (admin.Mount without WithAuthorizer = NON-COMPLIANT → Gate 6 MUST fix — every request returns 403)

S7. Validators on non-trivial keys:
    - Check: grep -rn "systemplane\.WithValidator" internal/
    - For every numeric/range/enum key, a WithValidator should exist
    - (missing validators on range-constrained keys = MEDIUM severity — Gate 3 MUST add)

S8. Redaction on secret keys:
    - MUST match if any secret-ish key name appears: grep -rn "systemplane\.WithRedaction\|RedactMask\|RedactFull" internal/
    - Cross-check: any key containing "secret", "token", "key", "password" in its name MUST have RedactFull
    - (secret key with RedactNone = CRITICAL → Gate 3 MUST fix)
```

**Output format for v5 compliance audit:**

```text
V5 COMPLIANCE AUDIT RESULTS:
| Component                     | Status                       | Evidence       | Gate Action          |
|-------------------------------|------------------------------|----------------|----------------------|
| Client construction           | COMPLIANT / NON-COMPLIANT    | {grep results} | Gate 3: SKIP / FIX   |
| Register before Start         | COMPLIANT / NON-COMPLIANT    | {grep results} | Gate 3: SKIP / FIX   |
| Lifecycle (Start + Close)     | COMPLIANT / NON-COMPLIANT    | {grep results} | Gate 7: SKIP / FIX   |
| Typed reads                   | COMPLIANT / NON-COMPLIANT    | {grep results} | Gate 5: SKIP / FIX   |
| OnChange subscriptions        | COMPLIANT / NON-COMPLIANT    | {grep results} | Gate 4: SKIP / FIX   |
| admin.Mount + WithAuthorizer  | COMPLIANT / NON-COMPLIANT    | {grep results} | Gate 6: SKIP / FIX   |
| Validators                    | COMPLIANT / NON-COMPLIANT    | {grep results} | Gate 3: SKIP / FIX   |
| Redaction on secret keys      | COMPLIANT / NON-COMPLIANT / N/A | {grep results} | Gate 3: SKIP / FIX |
```

**HARD GATE: A gate can only be marked as SKIP when ALL its compliance checks are COMPLIANT with evidence. One NON-COMPLIANT row → gate MUST execute.**

### Phase 3: v4 Residue + Non-Canonical Detection (MANDATORY)

v4 was deleted in lib-commons v5.0.0. ANY v4 reference means the service will not compile on v5. This phase is run on every invocation — not conditional.

```text
DETECT v4 residue (every match MUST be removed in Gate 2):

R1. v4 import path:
    grep -rn "lib-commons/v4/commons/systemplane" internal/ pkg/ go.mod

R2. v4 supervisor types:
    grep -rn "Supervisor\|SupervisorConfig\|NewSupervisor\|ReloadEvent" internal/

R3. v4 bundle types:
    grep -rn "BundleFactory\|IncrementalBundleFactory\|RuntimeBundle\|AdoptResourcesFrom" internal/

R4. v4 reconciler types:
    grep -rn "BundleReconciler\|ReconcilerPhase\|PhaseStateSync\|PhaseValidation\|PhaseSideEffect" internal/

R5. v4 apply behavior taxonomy (all 5 levels deleted):
    grep -rn "ApplyBehavior\|ApplyBootstrapOnly\|ApplyBundleRebuildAndReconcile\|ApplyBundleRebuild\|ApplyWorkerReconcile\|ApplyLiveRead" internal/

R6. v4 snapshot/effective value:
    grep -rn "SnapshotBuilder\|EffectiveValue\|KindConfig\|KindSetting\|KeyDef\|ValueType\|BackendKind\|ComponentNone" internal/

R7. v4 HTTP handler + swagger:
    grep -rn "fiberhttp\.NewHandler\|swagger\.MergeInto\|systemswagger" internal/

R8. v4 env vars (backend config via env — removed; v5 takes *sql.DB / *mongo.Client directly):
    grep -rn "SYSTEMPLANE_BACKEND\|SYSTEMPLANE_POSTGRES_DSN\|SYSTEMPLANE_MONGODB_URI\|SYSTEMPLANE_SECRET_MASTER_KEY" .env.example config/ internal/

R9. v4 testutil fakes:
    grep -rn "FakeStore\|FakeHistoryStore\|FakeBundle\|FakeReconciler\|FakeIncrementalBundleFactory" internal/

R10. v4 history API (removed — no history in v5):
    grep -rn "HistoryStore\|ListHistory\|HistoryEntry" internal/

DETECT non-canonical hot-reload (MUST be replaced by OnChange):

N1. fsnotify watchers:
    grep -rn "fsnotify" internal/ pkg/

N2. viper watchers:
    grep -rn "viper\.WatchConfig\|viper\.OnConfigChange" internal/ pkg/

N3. inotify / generic filesystem watchers:
    grep -rn "inotify" internal/ pkg/

N4. Custom hot-reload loops (outside systemplane):
    grep -rn "hot.reload\|config.watch\|ConfigReload\|ConfigChange" internal/ pkg/ \
      | grep -v "systemplane" | grep -v "_test.go"
    (any match = NON-CANONICAL → MUST be removed and replaced by client.OnChange)
```

**If v4 residue (R1-R10) is detected:** report as `V4 RESIDUE DETECTED — BLOCKS COMPILATION ON V5`. Gate 2 MUST remove all of it. CANNOT proceed to Gate 3 until Gate 2 passes.

**If non-canonical hot-reload (N1-N4) is detected:** report as `NON-CANONICAL HOT-RELOAD DETECTED`. The implementing agent MUST remove these files/patterns and replace their functionality with `client.OnChange` during Gates 4-5.

<block_condition>
HARD GATE: Phase 3 R1-R10 (v4 residue) findings BLOCK progression past Gate 2. Phase 3 N1-N4 (non-canonical hot-reload) findings BLOCK progression past Gate 5.
</block_condition>

---

## Gate 1: Codebase Analysis (Config Focus)

**Always executes. This gate builds the implementation roadmap for all subsequent gates.**

**Dispatch `ring:codebase-explorer` with config-focused context:**

> TASK: Analyze this codebase exclusively under the runtime configuration perspective.
> DETECTED BACKEND: {postgres: Y/N, mongodb: Y/N} (from Gate 0)
>
> CRITICAL: v5 systemplane is for OPERATIONAL KNOBS ONLY. Settings that require resource teardown (DB DSNs, TLS material, listen addresses, connection pool resize) do NOT belong in systemplane — they stay in env vars + restart.
>
> FOCUS AREAS (explore ONLY these — ignore everything else):
>
> 1. **Service name + bootstrap path**: What is the service called? (Look for `const ApplicationName`.) Where does it start? Where is the main init sequence? Identify the exact file:line where a `systemplane.Client` would be constructed, registered, and started.
> 2. **Config struct**: Where is the top-level Config struct? What fields does it have? Which fields are read at startup only (→ stay env var) vs. which are read on every request/loop iteration (→ candidates for systemplane)?
> 3. **Database connections**: How are `*sql.DB` (for Postgres backend) and/or `*mongo.Client` initialized today? What file:line? These are the handles that will be passed into `systemplane.NewPostgres(db, ...)` / `systemplane.NewMongoDB(client, database, ...)`. Systemplane does NOT open its own connections.
> 4. **HTTP router**: Is this service a Fiber app? Where is the router built? Where is auth middleware registered? Identify the exact insertion point for `admin.Mount(router, client, ...)` — it MUST be AFTER auth middleware so `admin.WithAuthorizer` can inspect authenticated actor.
> 5. **Hot-reloadable knob candidates**: List EVERY place where the following are read at runtime:
>    - Log level (`logger.SetLevel`, `log.SetLevel`, `LOG_LEVEL`)
>    - Feature flags (boolean toggles read per-request)
>    - Rate limits / quotas (read by middleware or handlers)
>    - Timeouts (read by HTTP clients, DB queries, etc.)
>    - Worker poll intervals, debounce windows, retry counts
>    - Circuit-breaker thresholds
>    For each, give file:line. These are the targets for `Register` + `OnChange`.
> 6. **Existing systemplane code**: Any imports of `lib-commons/v5/commons/systemplane`? Any `systemplane.NewPostgres`/`NewMongoDB` calls? Any `admin.Mount`? Any `OnChange` subscriptions? (NOTE: any `lib-commons/v4/commons/systemplane` import is residue — report separately.)
> 7. **Non-canonical hot-reload**: Any `fsnotify`, `viper.WatchConfig`, `inotify`, or custom filesystem watchers? Any custom polling loops that re-read config files? List file:line — these MUST be removed and replaced by `client.OnChange`.
> 8. **Secret-ish keys**: List any config field whose name contains "secret", "token", "key" (as in API key), "password", "credential". These — IF moved to systemplane at all — MUST use `systemplane.WithRedaction(systemplane.RedactFull)`. Recommend keeping them in a vault instead of systemplane.
>
> OUTPUT FORMAT: Structured report with file:line references for every point above.
> DO NOT write code. Analysis only.

**This report becomes the CONTEXT for all subsequent gates.**

<block_condition>
HARD GATE: MUST complete the analysis report before proceeding. All subsequent gates use this report to know exactly which keys to register, which sites to hook into with OnChange, and where to mount admin.
</block_condition>

MUST ensure backward compatibility context: the analysis MUST identify how the service reads each candidate knob today, so the systemplane wiring preserves the original value-source as a fallback for the case where systemplane is unavailable or disabled.

---

## Gate 1.5: Implementation Preview (Visual Report)

**Always executes. This gate generates a visual HTML report showing exactly what will change before any code is written.**

**Uses the `ring:visualize` skill to produce a self-contained HTML page.**

The report is built from Gate 0 (stack detection, v4 residue, v5 compliance audit) and Gate 1 (codebase analysis). It shows the developer a complete preview of every change that will be made across all subsequent gates.

**Orchestrator generates the report using `ring:visualize` with this content:**

The HTML page MUST include these sections:

### 1. Current State (Before)

- Mermaid diagram: current config flow — where values come from (env, YAML, flags), where they're read, what "hot-reload" paths exist today (if any — often fsnotify or v4 systemplane)
- Table of every hot-reloadable knob candidate with file:line and current mechanism
- v4 residue summary (if any): list of file:line where v4 imports/types appear, with severity CRITICAL (compilation-breaking)

### 2. Target State (After, v5)

- Mermaid diagram: v5 systemplane flow — `NewPostgres`/`NewMongoDB` → `Register` → `Start` → `Get*`/`OnChange` + `admin.Mount` served on the Fiber router
- Three-step lifecycle explicit: Register → Start → Reads/Subscriptions
- Namespace convention chosen for this service (e.g., `ledger.worker`)

### 3. Change Map (per gate)

Table with columns: Gate, File, What Changes, Impact. One row per file that will be modified.

Example:

| Gate | File | What Changes | Impact |
|------|------|-------------|--------|
| 2 | `go.mod` | Upgrade lib-commons to v5, remove any v4 systemplane import | Build breaks until Gates 3-7 complete |
| 2 | `internal/**/*.go` | Delete v4 residue (Supervisor, BundleFactory, ApplyBehavior, fiberhttp.NewHandler, etc.) | ~N files touched |
| 3 | `internal/bootstrap/systemplane.go` | NEW: construct `systemplane.NewPostgres(db, dsn)` or `NewMongoDB(client, db)`, register every key | ~80-120 lines |
| 4 | `internal/worker/worker.go` | Add `client.OnChange("ledger.worker", "poll_interval", func(v any) { ... })` to react to interval changes | ~10 lines per subscription |
| 5 | `internal/config/config.go` | Replace env-var reads of hot-reloadable knobs with `client.GetDuration(...)` etc., keeping env-var fallback | ~1 line per knob |
| 6 | `internal/http/router.go` | `admin.Mount(router, client, admin.WithPathPrefix("/system"), admin.WithAuthorizer(authz), admin.WithActorExtractor(actor))` | ~5 lines |
| 7 | `internal/bootstrap/app.go` | Wire lifecycle: `client.Start(ctx)` on boot, `client.Close()` on shutdown; feature flag for disabling systemplane | ~20 lines |
| 8 | `internal/bootstrap/systemplane_test.go` | NEW: tests using `systemplanetest.Run(t, factory)` for contract compliance; unit tests for OnChange reactions | ~150 lines |

**MANDATORY: Below the summary table, show per-file code diff panels for every file that will be modified.**

For each file in the change map, generate a before/after diff panel showing:

- **Before:** The exact current code from the codebase (sourced from the Gate 1 analysis) — or for brand-new files, mark as "NEW FILE"
- **After:** The exact code that will be written, using only the v5 canonical API
- Use syntax highlighting and line numbers (read `default/skills/visualize/templates/code-diff.html` for patterns)

Example diff panel for Gate 3 (client construction):

```go
// AFTER: internal/bootstrap/systemplane.go (NEW FILE)
package bootstrap

import (
    "context"
    "database/sql"
    "time"

    "github.com/LerianStudio/lib-commons/v5/commons/systemplane"
)

func NewSystemplane(ctx context.Context, db *sql.DB, logger Logger) (*systemplane.Client, error) {
    client, err := systemplane.NewPostgres(db, cfg.PostgresDSN,
        systemplane.WithLogger(logger),
        systemplane.WithTable("systemplane_entries"),
        systemplane.WithListenChannel("systemplane_changes"),
        systemplane.WithDebounce(100*time.Millisecond),
    )
    if err != nil {
        return nil, err
    }

    // Register every key BEFORE Start.
    if err := client.Register("ledger.worker", "poll_interval", 5*time.Second,
        systemplane.WithDescription("Worker poll interval"),
        systemplane.WithValidator(func(v any) error {
            d, ok := v.(time.Duration)
            if !ok || d < time.Second || d > time.Hour {
                return fmt.Errorf("poll_interval must be 1s..1h")
            }
            return nil
        }),
    ); err != nil {
        return nil, err
    }
    // ... more Register calls for every knob ...

    if err := client.Start(ctx); err != nil {
        return nil, err
    }
    return client, nil
}
```

### 4. Backward Compatibility Analysis

**MANDATORY: Show complete conditional initialization, not just skeleton.**

Systemplane adoption is gated by a feature flag (`SYSTEMPLANE_ENABLED`, `bool`, default `false`). When disabled:

- Client is nil — `Get*` and `OnChange` on nil receiver are no-ops (v5 guarantees nil-safety on reads)
- Config struct falls back to env-var values
- `admin.Mount` is not registered
- No Postgres LISTEN or Mongo change stream is established

```go
if cfg.SystemplaneEnabled {
    spClient, err = bootstrap.NewSystemplane(ctx, db, logger)  // NEW v5 path
    if err != nil {
        return err
    }
    admin.Mount(router, spClient, admin.WithAuthorizer(authz), admin.WithActorExtractor(actor))
} else {
    // Legacy: env-var-only config. Existing behavior unchanged.
    logger.Info("Running with STATIC CONFIG (systemplane disabled)")
}
```

Show the read-path bridge explicitly:

```go
// Config struct getter — live value via systemplane, fall back to env.
func (c *Config) PollInterval() time.Duration {
    if c.sp != nil {
        return c.sp.GetDuration("ledger.worker", "poll_interval")
    }
    return c.pollIntervalEnv
}
```

### 5. New Dependencies

Table showing what gets added to go.mod and which sub-packages are imported:

- `github.com/LerianStudio/lib-commons/v5/commons/systemplane` — Client + constructors
- `github.com/LerianStudio/lib-commons/v5/commons/systemplane/admin` — HTTP admin
- `github.com/LerianStudio/lib-commons/v5/commons/systemplane/systemplanetest` — test contract (test-only)

### 6. Key Registry

Table with the full list of keys the service will register: Namespace, Key, Default, Type, Redaction, Validator, Has-OnChange.

| Namespace | Key | Default | Type | Redaction | Validator | OnChange |
|-----------|-----|---------|------|-----------|-----------|----------|
| `ledger.worker` | `poll_interval` | `5s` | `time.Duration` | None | 1s..1h | Yes |
| `ledger.http` | `request_timeout` | `30s` | `time.Duration` | None | 1s..5m | Yes |
| `ledger.http` | `rate_limit_rps` | `100` | `int` | None | >=0 | Yes |
| `ledger.feat` | `enable_async_posting` | `false` | `bool` | None | — | Yes |
| `ledger.log` | `level` | `"info"` | `string` | None | debug/info/warn/error | Yes |

### 7. Risk Assessment

Table with: Risk, Mitigation, Verification. Examples:

- Compile break from v4 residue → Gate 2 removes all v4 imports/types → `go build ./...` passes
- Silent nil reads (client not constructed) → Gate 7 wires lifecycle with explicit error if Start fails → startup probe fails on nil
- Unauthenticated admin → `admin.WithAuthorizer` mandatory → integration test hits admin without auth, expects 403
- Schema drift between Register defaults and persisted rows → Register is idempotent and wins on default-only fields; value rows persist across restarts
- Backend unavailable at startup → Start returns error; service either fails fast or falls back via feature flag

### 8. Scope Fence

Explicit list of settings that were CONSIDERED for systemplane but EXCLUDED:

| Excluded setting | Why | Where it stays |
|------------------|-----|----------------|
| `POSTGRES_DSN` | Requires pool teardown on change | env var + restart |
| `TLS_CERT_PATH` | Requires listener restart | env var + restart |
| `HTTP_LISTEN_ADDR` | Requires listener restart | env var + restart |
| `DB_MAX_CONNS` (if changing requires pool rebuild) | Pool resize not supported by Go drivers | env var + restart |

The developer MUST confirm this exclusion list — these are the items that will NOT become live-reconfigurable.

**Output:** Save the HTML report to `docs/systemplane-migration-preview.html` in the project root.

**Open in browser** for the developer to review.

<block_condition>
HARD GATE: Developer MUST explicitly approve the implementation preview before any code changes begin. This prevents wasted effort on misunderstood requirements, incorrect knob selection, or scope creep into resource-teardown territory.
</block_condition>

**If the developer requests changes to the preview (knob list, namespace convention, validator rules), regenerate the report and re-confirm.**

---

## Gate 2: lib-commons v5 Upgrade + v4 Systemplane Removal

**SKIP only if:** `go.mod` contains `lib-commons/v5` AND Gate 0 Phase 3 returned zero v4 systemplane residue (R1-R10 all empty). Otherwise MANDATORY.

**This gate has two responsibilities: (a) bump lib-commons to v5, (b) delete every trace of v4 systemplane so the service compiles.**

**Dispatch `ring:backend-engineer-golang` with context:**

> TASK: Upgrade lib-commons to v5 AND remove all v4 systemplane residue.
> V4 RESIDUE DETECTED (from Gate 0 Phase 3):
> - R1 (imports): {file:line list}
> - R2 (Supervisor/ReloadEvent types): {file:line list}
> - R3 (BundleFactory/RuntimeBundle): {file:line list}
> - R4 (BundleReconciler/ReconcilerPhase): {file:line list}
> - R5 (ApplyBehavior): {file:line list}
> - R6 (SnapshotBuilder/EffectiveValue/KeyDef): {file:line list}
> - R7 (fiberhttp.NewHandler/systemswagger): {file:line list}
> - R8 (SYSTEMPLANE_* env vars): {file:line list}
> - R9 (FakeStore/FakeBundle etc.): {file:line list}
> - R10 (HistoryStore/ListHistory): {file:line list}
>
> Fetch latest v5 tag: `git ls-remote --tags https://github.com/LerianStudio/lib-commons.git | grep "v5" | sort -V | tail -1`
> Run in order:
> 1. `go get github.com/LerianStudio/lib-commons/v5@{latest-v5-tag}`
> 2. `go mod tidy`
> 3. Update every import path from `lib-commons/v4` (or v3, v2) to `lib-commons/v5`.
> 4. DELETE every v4 systemplane type reference listed above. v5 has NO equivalent for:
>    - `Supervisor`, `Manager` (from v4 systemplane), `SupervisorConfig`, `NewSupervisor`, `ReloadEvent`, `Observer`
>    - `BundleFactory`, `IncrementalBundleFactory`, `RuntimeBundle`, `AdoptResourcesFrom`
>    - `BundleReconciler`, `ReconcilerPhase`, `PhaseStateSync`, `PhaseValidation`, `PhaseSideEffect`
>    - `ApplyBehavior` and all 5 levels (`ApplyBootstrapOnly`, `ApplyBundleRebuildAndReconcile`, `ApplyBundleRebuild`, `ApplyWorkerReconcile`, `ApplyLiveRead`)
>    - `SnapshotBuilder`, `EffectiveValue`, `Entry`, `Kind`, `Scope`, `Target`, `Revision`, `Actor` (struct), `KeyDef`, `ValueType`, `BackendKind`, `ComponentNone`, `ValidatorFunc` (v4 signature), `Escalate`, `ConfigWriteValidator`, `StateSync`
>    - `fiberhttp.NewHandler`, `swagger.MergeInto`, `systemswagger.*`
>    - `catalog.ValidateKeyDefs`, `catalog.AllSharedKeys`
>    - `FakeStore`, `FakeHistoryStore`, `FakeBundle`, `FakeReconciler`, `FakeIncrementalBundleFactory`
>    - `HistoryStore`, `ListHistory`, `HistoryEntry` (v5 has no history API)
>    - AES-256-GCM secret encryption layer (v5 has no encryption — use a vault for secrets)
> 5. REMOVE every `SYSTEMPLANE_*` env var declaration:
>    - `SYSTEMPLANE_BACKEND`, `SYSTEMPLANE_POSTGRES_DSN`, `SYSTEMPLANE_MONGODB_URI`, `SYSTEMPLANE_SECRET_MASTER_KEY`
>    - v5 takes `*sql.DB` / `*mongo.Client` directly; callers do NOT configure backend via env
> 6. Do NOT yet wire the v5 client — that is Gate 3. This gate only removes residue so the build compiles AGAINST a v5 go.mod with no systemplane client yet.
>
> If a file's entire purpose was to support v4 systemplane (e.g., a custom `BundleFactory` implementation), DELETE the file. Do not attempt to "port" it to v5.
>
> **Verification required:** `go build ./...` MUST succeed. `go test ./...` MUST succeed (tests relying on v4 systemplane will need to be deleted or rewritten — record which in the dispatch output).

**Verification commands (orchestrator runs):**

- `grep -rn "lib-commons/v4/commons/systemplane" internal/ pkg/` — MUST return zero results
- `grep -rn "Supervisor\|BundleFactory\|ApplyBehavior\|fiberhttp\.NewHandler\|HistoryStore" internal/` — MUST return zero results (unless match is in a comment explaining the migration)
- `grep "lib-commons/v5" go.mod` — MUST return a result
- `grep "SYSTEMPLANE_BACKEND\|SYSTEMPLANE_POSTGRES_DSN\|SYSTEMPLANE_MONGODB_URI\|SYSTEMPLANE_SECRET_MASTER_KEY" .env.example config/ internal/` — MUST return zero results
- `go build ./...` — MUST pass
- `go test ./...` — MUST pass (tests updated/deleted as needed)

<block_condition>
HARD GATE: Zero v4 residue. go.mod on v5. Build and tests green. CANNOT proceed until all three hold.
</block_condition>

### Gate 2 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Keep v4 code, just pin to v4 for now" | The service is being migrated to lib-commons v5 platform-wide. v4 is end-of-life. | **MUST remove v4 residue now** |
| "Port Supervisor to v5 by wrapping the Client" | Reimplementing v4 semantics on v5 = non-canonical. Skill FAILS. | **DELETE Supervisor. Replace functionality with direct v5 Client usage.** |
| "The BundleFactory was doing important work" | Bundle semantics don't exist in v5. If the work was "teardown and rebuild on config change", that belongs outside systemplane (env vars + restart). | **DELETE BundleFactory. Identify which bits are teardown (→ env vars) and which are in-place (→ OnChange).** |
| "Just comment out v4 imports for now" | Commented imports don't compile, but the types they referenced don't exist in v5 either. Build will still fail. | **DELETE, do not comment.** |
| "swagger integration was user-facing, keep it" | v5 has no auto-swagger. The 3 admin routes (`GET /system/:ns`, `GET /system/:ns/:key`, `PUT /system/:ns/:key`) are simple enough to document manually. | **DELETE swagger code. Document routes in service's OpenAPI spec.** |

---

## Gate 3: Client Construction + Key Registration

**Always executes.** If v5 client construction already exists (Gate 0 Phase 2 S1-S2 compliant), this gate VERIFIES that every hot-reloadable knob from Gate 1 is registered, validators are present on range-constrained keys, and redaction is correct on secret-ish keys. Non-compliance MUST be fixed.

**Dispatch `ring:backend-engineer-golang` with context from Gate 1 analysis:**

> TASK: Construct the systemplane Client and Register every hot-reloadable key BEFORE Start.
> DETECTED BACKEND: {postgres OR mongodb} (from Gate 0)
> CONTEXT FROM GATE 1: {bootstrap path, existing *sql.DB / *mongo.Client location, full list of hot-reloadable knobs with file:line}
> KEY REGISTRY (from Gate 1.5 preview, approved by user): {namespace, key, default, type, redaction, validator — for every knob}
>
> Canonical v5 API:
> - Postgres: `systemplane.NewPostgres(db *sql.DB, listenDSN string, opts ...Option) (*Client, error)`
> - MongoDB: `systemplane.NewMongoDB(client *mongo.Client, database string, opts ...Option) (*Client, error)`
> - Options: `WithLogger`, `WithTelemetry`, `WithListenChannel` (Postgres, default "systemplane_changes"), `WithTable` (Postgres), `WithCollection` (Mongo), `WithPollInterval` (Mongo — switches to polling mode), `WithDebounce` (default 100ms; 0 to disable)
> - Register: `client.Register(namespace, key string, defaultValue any, opts ...KeyOption) error`
> - KeyOptions: `WithDescription(string)`, `WithValidator(func(any) error)`, `WithRedaction(RedactNone | RedactMask | RedactFull)`
>
> Constraints:
> 1. MUST pass the already-open `*sql.DB` or `*mongo.Client` from the service's existing bootstrap — systemplane does NOT open its own connections.
> 2. MUST use a service-scoped namespace prefix (e.g., `"{service}.{component}"`) — no empty string.
> 3. MUST register EVERY key identified in Gate 1 before calling `Start`. Post-Start `Register` calls return an error.
> 4. MUST add `WithValidator` to every numeric/range-constrained/enum key.
> 5. MUST add `WithRedaction(RedactFull)` to every key containing "secret", "token", "key" (API key sense), "password", or "credential" in its name — and loudly recommend moving those values to a vault instead.
> 6. MUST add `WithDescription` to every key — it appears in admin responses for operator discoverability.
> 7. Default values are the source of truth for the "unset" state. `client.GetDuration(...)` returns the default when no row exists.
>
> Follow v5 package docs via WebFetch:
> `https://raw.githubusercontent.com/LerianStudio/lib-commons/main/commons/systemplane/doc.go`
>
> DO NOT yet wire `OnChange` (Gate 4), Config bridge (Gate 5), or `admin.Mount` (Gate 6). This gate is ONLY client + Register + Start.
>
> Write a new bootstrap file (e.g., `internal/bootstrap/systemplane.go`) that exports a constructor `NewSystemplane(ctx, db, ...) (*systemplane.Client, error)`.

**Verification:**

- `grep "systemplane.NewPostgres\|systemplane.NewMongoDB" internal/bootstrap/` — MUST return exactly one constructor call
- `grep -c "\.Register(" internal/bootstrap/systemplane.go` — count MUST match approved key registry
- `grep "systemplane.WithValidator" internal/bootstrap/systemplane.go` — MUST return results (for every range-constrained key)
- `grep "systemplane.WithRedaction\|RedactFull\|RedactMask" internal/bootstrap/systemplane.go` — MUST return results if any secret-ish key exists
- `grep "\.Start(ctx)" internal/bootstrap/systemplane.go` — MUST return exactly one call, AFTER all Register calls
- `go build ./...` — MUST pass

<block_condition>
HARD GATE: All keys from the Gate 1.5 preview MUST be registered. Any key with name matching secret/token/key/password/credential regex MUST have `RedactFull`. Register calls MUST precede Start.
</block_condition>

---

## Gate 4: OnChange Subscriptions

**Always executes unless the service has zero hot-reloadable keys (requires explicit justification in Gate 1.5 preview).**

Registration without subscription is dead code. `client.Set(...)` will succeed (value persists), but the running code will not react. Users report "I changed the config but nothing happened."

**Dispatch `ring:backend-engineer-golang` with context from Gate 1 analysis:**

> TASK: Wire `client.OnChange` for every hot-reloadable knob so the running code reacts to Set().
> KEY REGISTRY: {same list from Gate 1.5 preview — every key here needs an OnChange callback unless explicitly marked as read-every-time via Get*}
> CONTEXT FROM GATE 1: {file:line for every place where the knob is currently read — each is a candidate for an OnChange handler OR a Get* call at read time}
>
> Canonical v5 API:
> - `unsubscribe := client.OnChange(namespace, key string, fn func(newValue any))`
> - Callback fires AFTER the debounce window (default 100ms) collapses rapid Sets
> - Callback is panic-safe: a panicking handler does NOT kill the client
> - Multiple subscriptions to the same key are supported; each gets its own callback
>
> Two valid patterns — pick per-knob based on read frequency:
>
> PATTERN A — OnChange with cached local value (for high-frequency reads):
> ```go
> type Worker struct {
>     pollInterval atomic.Pointer[time.Duration]
> }
> func NewWorker(sp *systemplane.Client) *Worker {
>     w := &Worker{}
>     initial := sp.GetDuration("ledger.worker", "poll_interval")
>     w.pollInterval.Store(&initial)
>     sp.OnChange("ledger.worker", "poll_interval", func(v any) {
>         if d, ok := v.(time.Duration); ok {
>             w.pollInterval.Store(&d)
>         }
>     })
>     return w
> }
> func (w *Worker) Loop() {
>     for {
>         time.Sleep(*w.pollInterval.Load())
>         // ... work ...
>     }
> }
> ```
>
> PATTERN B — direct Get* at read time (for low-frequency reads where in-memory caching is not worth it):
> ```go
> func (h *Handler) Serve(c *fiber.Ctx) error {
>     timeout := sp.GetDuration("ledger.http", "request_timeout")
>     ctx, cancel := context.WithTimeout(c.Context(), timeout)
>     defer cancel()
>     // ... handle request ...
> }
> ```
>
> For each knob in the registry:
> 1. Decide Pattern A (hot path) vs. Pattern B (cold path) based on read frequency from Gate 1.
> 2. If Pattern A: store the OnChange unsubscribe handle for shutdown (call in Close flow at Gate 7).
> 3. If Pattern B: replace the original env-var read site with `client.Get*(ns, key)`.
>
> Constraints:
> 1. MUST type-assert inside the callback — `v any` may be nil or wrong type if a malformed Set bypasses validation.
> 2. MUST NOT perform heavy work in the callback (no DB writes, no network). Callback should update in-memory state only.
> 3. MUST NOT spawn goroutines from the callback without an explicit lifecycle (leak risk).
> 4. For values that gate concurrent behavior (feature flags, rate limits), MUST use `atomic.Pointer` / `atomic.Int64` — not plain assignment.
>
> DO NOT yet mount `admin.Mount` (Gate 6). This gate is ONLY OnChange subscriptions + Get* read-path replacements.

**Verification:**

- `grep -c "\.OnChange(" internal/` — count MUST be >= number of hot-reloadable keys minus Pattern-B-only keys
- `grep -rn "\.GetDuration\|\.GetString\|\.GetInt\|\.GetBool\|\.GetFloat64" internal/` — MUST return results for every Pattern-B knob
- `grep -rn "atomic.Pointer\|atomic.Int\|atomic.Bool" internal/` near OnChange — recommended for concurrent-read state
- `go build ./...` — MUST pass
- `go test ./... -race` — MUST pass (data-race-free OnChange handlers)

### Gate 4 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Register is enough, we'll add OnChange when needed" | Without OnChange, Set() persists but nothing reacts. Operators see success, system ignores it. Silent breakage. | **MUST add OnChange in this gate** |
| "Plain variable assignment in the callback is fine" | The callback runs on a separate goroutine. Plain assignment is a data race. | **MUST use atomic primitives or mutex** |
| "I'll do DB work in the OnChange callback" | Callback runs under internal locks. Heavy work blocks further notifications. | **MUST keep callback trivial — update in-memory state only** |

<block_condition>
HARD GATE: Every hot-reloadable key in the registry has EITHER an OnChange handler (Pattern A) OR a direct Get* read-path replacement (Pattern B). Mixed is fine; missing is not.
</block_condition>

---

## Gate 5: Config Bridge (Config struct ← systemplane values)

**SKIP IF** the service has no existing Config struct whose consumers read live values at runtime (rare — usually only if all knobs were handled entirely via Pattern A in Gate 4).

Most services have a shared `Config` struct consumed by multiple packages. This gate bridges that struct to systemplane so the existing consumers don't need to know about systemplane — they keep reading `cfg.PollInterval()` as before, but the value is now live.

**Dispatch `ring:backend-engineer-golang` with context from Gate 1 analysis:**

> TASK: Bridge the service's existing Config struct to systemplane values with env-var fallback.
> CONTEXT FROM GATE 1: {Config struct location, current field reads with file:line}
> CONFIG BRIDGE TARGETS: {subset of the key registry whose values are read through the Config struct}
>
> Pattern: replace direct field access with getter methods that route through systemplane when available and fall back to the original env-var field otherwise.
>
> ```go
> type Config struct {
>     sp                *systemplane.Client  // nil when SYSTEMPLANE_ENABLED=false
>     pollIntervalEnv   time.Duration        // original env-var-backed field
>     rateLimitRPSEnv   int
>     logLevelEnv       string
> }
>
> func (c *Config) PollInterval() time.Duration {
>     if c.sp != nil {
>         return c.sp.GetDuration("ledger.worker", "poll_interval")
>     }
>     return c.pollIntervalEnv
> }
>
> func (c *Config) RateLimitRPS() int {
>     if c.sp != nil {
>         return c.sp.GetInt("ledger.http", "rate_limit_rps")
>     }
>     return c.rateLimitRPSEnv
> }
> ```
>
> Constraints:
> 1. MUST preserve the env-var field as fallback for the `SYSTEMPLANE_ENABLED=false` path.
> 2. MUST NOT store the systemplane value in a Config struct field — always read live via Get*.
> 3. MUST change every call site that reads the field directly (`cfg.PollInterval`) to the getter form (`cfg.PollInterval()`). Compile errors will find them all.
> 4. `client.Get*` is nil-safe on a nil receiver — but the `c.sp == nil` branch is still required because the default-returning nil path gives the *zero* value of the type, not the env-var value.
>
> This gate is where Pattern B read-path replacements from Gate 4 may also land if they flow through Config struct consumers.

**Verification:**

- `grep -rn "c\.sp\.GetDuration\|c\.sp\.GetString\|c\.sp\.GetInt\|c\.sp\.GetBool\|c\.sp\.GetFloat64" internal/config/` — MUST return results for every bridged knob
- Every previously-direct field read MUST now be a method call (compile check).
- `go build ./...` — MUST pass
- `go test ./...` — MUST pass with existing tests (tests exercising the env-var path should still work because `sp == nil` fallback preserves behavior)

<block_condition>
HARD GATE: No test regression. Env-var fallback path still produces identical behavior when `sp == nil`.
</block_condition>

---

## Gate 6: Admin HTTP Mount + Authorizer

**SKIP only if** the service deliberately exposes no admin HTTP surface (rare — e.g., a pure background worker with no ingress). Justification MUST appear in Gate 1.5 preview.

Without `admin.Mount`, operators have no standard way to change runtime config. They'd have to write directly to Postgres/Mongo or ship a new release for every knob change. That defeats the purpose.

**Dispatch `ring:backend-engineer-golang` with context from Gate 1 analysis:**

> TASK: Mount the systemplane admin HTTP routes on the service's Fiber router, AFTER authentication middleware, with a custom authorizer and actor extractor.
> CONTEXT FROM GATE 1: {router location, auth middleware location — admin.Mount MUST go AFTER auth middleware}
>
> Canonical v5 API:
> ```go
> admin.Mount(router *fiber.App, client *systemplane.Client,
>     admin.WithPathPrefix("/system"),                    // default: "/system"
>     admin.WithAuthorizer(func(c *fiber.Ctx, action string) error {
>         // action is "read" (GET) or "write" (PUT)
>         // Inspect c.Locals() for authenticated actor set by upstream auth middleware.
>         // Return nil to allow, error to deny.
>         return authz.Check(c, action)
>     }),
>     admin.WithActorExtractor(func(c *fiber.Ctx) string {
>         // Return a stable identifier for audit logs.
>         return c.Get("X-User-Email")
>     }),
> )
> ```
>
> Routes registered:
> - `GET  {prefix}/:namespace`           — list entries in a namespace
> - `GET  {prefix}/:namespace/:key`      — get a single entry
> - `PUT  {prefix}/:namespace/:key`      — set a value; body is the new value JSON-encoded; actor from WithActorExtractor is recorded via client.Set
>
> Constraints:
> 1. MUST pass `admin.WithAuthorizer` — default is DENY-ALL (every request returns 403). This is NOT a dev-mode allowance.
> 2. MUST pass `admin.WithActorExtractor` — audit trail needs stable actor identity. Blank actor is acceptable only if the upstream layer already enforces that requests are authenticated.
> 3. MUST mount AFTER auth middleware so `c.Locals()` contains the authenticated principal.
> 4. Recommended: place admin under a path prefix distinct from public API (e.g., `/system`, `/admin/system`) so network policy can gate it separately.
> 5. MUST NOT expose admin on a public-facing port without additional ACLs/VPN. Operator documentation (Gate 11) MUST call this out.
> 6. Default authorizer CAN be used in tests as a sentinel — it returns 403 for all requests. Integration tests (Gate 8) MUST verify the 403-by-default behavior.
>
> Write manual OpenAPI documentation for the three routes in the service's existing swagger spec. v5 has NO auto-swagger — do not attempt to port v4's `swagger.MergeInto`.

**Verification:**

- `grep "admin.Mount" internal/http/ internal/bootstrap/` — MUST return exactly one call
- `grep "admin.WithAuthorizer" internal/http/ internal/bootstrap/` — MUST return a call paired with Mount
- `grep "admin.WithActorExtractor" internal/http/ internal/bootstrap/` — MUST return a call paired with Mount
- Integration test: unauthenticated PUT to `/system/{ns}/{key}` → expect 403
- Integration test: authenticated but unauthorized (authorizer returns error) → expect 403
- Integration test: authorized PUT → expect 200 + client.Get reflects the new value after debounce window
- `go build ./...` — MUST pass

### Gate 6 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Default authorizer is fine for dev" | Default is DENY-ALL. Every request returns 403 — there is no "dev mode". | **MUST supply WithAuthorizer** |
| "Use the auth middleware, skip admin authorizer" | Auth middleware verifies identity. Admin authorizer verifies *permission to modify runtime config*. These are different concerns. | **MUST have BOTH: auth middleware upstream AND admin.WithAuthorizer** |
| "We'll add swagger back" | v5 has no auto-swagger. Porting v4 swagger = non-canonical. | **MUST document 3 routes manually in service's existing OpenAPI spec** |
| "Expose admin on the public port, it's authenticated" | Authentication is necessary but not sufficient. Network-level separation (prefix + ACL) is defense-in-depth. | **MUST use a path prefix and document network policy** |

<block_condition>
HARD GATE: `admin.Mount` without `admin.WithAuthorizer` = non-compliant. Every admin request will return 403. Fix before proceeding.
</block_condition>

---

## Gate 7: Wiring + Lifecycle + Backward Compat ⛔ NEVER SKIPPABLE

**Always executes. This gate cannot be skipped under any circumstance.**

This is the gate where everything connects: feature flag, client lifecycle, graceful shutdown, and the single-tenant / systemplane-disabled backward compat path.

**Dispatch `ring:backend-engineer-golang` with context:**

> TASK: Wire the systemplane client into the service's bootstrap and shutdown, add the `SYSTEMPLANE_ENABLED` feature flag, and validate backward compatibility.
> CONTEXT FROM GATE 1: {bootstrap path, existing shutdown/signal handling}
>
> Required changes:
>
> 1. **Feature flag** — add to Config struct:
>    ```go
>    SystemplaneEnabled bool `env:"SYSTEMPLANE_ENABLED" default:"false"`
>    ```
>
> 2. **Conditional construction** in bootstrap:
>    ```go
>    var spClient *systemplane.Client
>    if cfg.SystemplaneEnabled {
>        spClient, err = bootstrap.NewSystemplane(ctx, db, logger)
>        if err != nil {
>            return fmt.Errorf("systemplane init: %w", err)
>        }
>        logger.Info("Systemplane enabled")
>    } else {
>        logger.Info("Systemplane disabled — using static env-var config")
>    }
>    cfg.SetSystemplane(spClient)  // injects nil or live client into Config bridge
>    ```
>
> 3. **Lifecycle**:
>    - `spClient.Start(ctx)` is called inside `NewSystemplane` (already in Gate 3).
>    - On shutdown signal (SIGTERM/SIGINT), call `spClient.Close()` BEFORE closing the `*sql.DB` / `*mongo.Client`. Close order matters: systemplane uses the DB handle until its goroutines exit.
>    - MUST handle nil `spClient` in the shutdown path (when feature flag is off).
>
> 4. **Conditional admin.Mount**:
>    ```go
>    if spClient != nil {
>        admin.Mount(router, spClient, admin.WithAuthorizer(authz), admin.WithActorExtractor(actor))
>    }
>    ```
>
> 5. **Backward compatibility guarantees** when `SYSTEMPLANE_ENABLED=false`:
>    - `spClient` is nil
>    - Config getters (`cfg.PollInterval()` etc.) return env-var-backed values via the `sp == nil` branch
>    - No Postgres LISTEN / Mongo change stream is established
>    - No admin routes are registered
>    - `go test ./...` passes with zero changes to existing tests
>
> 6. **Write TestSystemplane_BackwardCompatibility**:
>    - Start service with `SYSTEMPLANE_ENABLED=false`
>    - Issue requests; assert behavior identical to pre-migration baseline
>    - Assert admin routes return 404 (not mounted)
>
> 7. **Write TestSystemplane_EnabledRoundtrip**:
>    - Start service with `SYSTEMPLANE_ENABLED=true`, real or in-memory Postgres/Mongo
>    - PUT a new value via admin (with test authorizer allowing all)
>    - Wait ≥ debounce window
>    - Assert a subsequent Get* returns the new value AND the registered OnChange callback was invoked
>
> Constraints:
> 1. MUST preserve existing startup ordering — systemplane client init comes AFTER DB init, BEFORE router wiring.
> 2. MUST NOT block startup on systemplane availability unless feature flag is on AND the service cannot operate without live config.
> 3. Close order: systemplane.Client.Close() → router shutdown → DB close. Reversing causes panics.

**Verification:**

- `grep "SystemplaneEnabled\|SYSTEMPLANE_ENABLED" internal/ config/` — MUST return results (feature flag present)
- `grep "spClient.Close()\|\.Close()" internal/` near shutdown handler — MUST appear
- `SYSTEMPLANE_ENABLED=false go test ./...` MUST pass
- `SYSTEMPLANE_ENABLED=true go test ./...` MUST pass (with backend available)
- TestSystemplane_BackwardCompatibility MUST exist and pass
- TestSystemplane_EnabledRoundtrip MUST exist and pass

<block_condition>
HARD GATE: Backward compat tests MUST pass. Feature-flag-off path MUST be behaviorally identical to pre-migration service. No exceptions.
</block_condition>

---

## Gate 8: Tests

**Always executes.**

**Dispatch `ring:backend-engineer-golang` with context:**

> TASK: Write comprehensive tests for the v5 systemplane integration.
> DETECTED BACKEND: {postgres OR mongodb}
>
> Required test layers:
>
> 1. **Contract compliance via `systemplanetest.Run(t, factory)`**:
>    - Import `github.com/LerianStudio/lib-commons/v5/commons/systemplane/systemplanetest`
>    - Provide a factory function that constructs a `*systemplane.Client` backed by a test container (Postgres via testcontainers-go, or MongoDB via embedded mongod)
>    - `systemplanetest.Run(t, factory)` executes the full contract suite — Register, Start, Close, Get, Set, OnChange, debounce behavior, panic safety, nil receiver safety
>
> 2. **Per-key validator tests** (unit):
>    - For every key with `WithValidator`, test the validator accepts expected values and rejects out-of-range ones
>    - Tests run without starting the client — pure function tests on the validator
>
> 3. **OnChange behavior tests** (unit with mock or integration):
>    - Register a key, subscribe, Set a new value, wait debounce, assert callback fired
>    - Panic-safety test: subscribe with a callback that panics, Set, assert client still alive and other subscribers still fire
>    - Multi-subscriber test: subscribe twice to same key, Set once, both callbacks fire
>
> 4. **Admin HTTP tests** (integration):
>    - Default authorizer returns 403 for all requests
>    - Custom authorizer that allows read but denies write — GET returns 200, PUT returns 403
>    - Authorized PUT → value persists, OnChange fires, subsequent GET returns new value
>    - Redacted key: `GET /system/:ns/:key` returns masked/omitted value for `RedactFull`/`RedactMask` keys
>
> 5. **Backward compat tests** (from Gate 7 — re-verified here):
>    - `SYSTEMPLANE_ENABLED=false` path gives identical behavior to pre-migration
>
> 6. **Shutdown tests** (integration):
>    - Start service, send SIGTERM, assert Close() is called, no goroutine leaks
>    - Use `go.uber.org/goleak` if already available in the project
>
> All tests MUST follow TDD: write failing test first, then implementation — but since this gate adds tests for already-implemented code, the "RED" equivalent is writing the test and confirming it exercises the real behavior (not a tautology).

**Verification:**

- `grep "systemplanetest.Run" internal/ | wc -l` — MUST return exactly 1 call per service component with a client
- `go test ./... -v -count=1` — MUST pass
- `go test ./... -cover` — coverage on systemplane-related files MUST be >= 85%
- `go test ./... -race` — MUST pass (OnChange callbacks, concurrent Get*, admin PUT)

---

## Gate 9: Code Review

**Dispatch 10 parallel reviewers (same pattern as ring:codereview).**

MUST include this context in ALL 10 reviewer dispatches:

> **SYSTEMPLANE MIGRATION REVIEW CONTEXT:**
> - Service is adopting lib-commons v5 systemplane for runtime configuration of operational knobs.
> - v4 systemplane was DELETED in lib-commons v5.0.0. ANY v4 import or v4 type reference is a compile-breaking residue and CRITICAL.
> - v5 surface is intentionally minimal: `NewPostgres`/`NewMongoDB` → `Register` → `Start` → `Get*`/`OnChange` → `admin.Mount`. No bundles, no reconcilers, no supervisors, no tiered apply behaviors.
> - Scope fence: systemplane is for knobs that mutate in place (log level, feature flags, rate limits, timeouts). DSNs, TLS, listen addresses stay in env vars + restart.
> - `admin.Mount` without `admin.WithAuthorizer` is CRITICAL — default authorizer is DENY-ALL.
> - Secret-ish keys (name contains secret/token/key/password/credential) MUST use `RedactFull`.
> - Backward compatibility is required: `SYSTEMPLANE_ENABLED=false` MUST produce behavior identical to pre-migration.

| Reviewer | Focus |
|----------|-------|
| ring:code-reviewer | Architecture, v5 API correctness, lifecycle ordering (Register → Start → reads; Close → DB close) |
| ring:business-logic-reviewer | Knob selection scope — no DSNs/TLS/listen addresses in systemplane; every knob is a true in-place mutation |
| ring:security-reviewer | Default-deny admin authorizer, redaction on secret-ish keys, no raw credential leakage in logs or admin responses |
| ring:test-reviewer | Coverage, `systemplanetest.Run` contract test present, admin 403 tests, OnChange panic-safety tests, backward compat tests |
| ring:nil-safety-reviewer | Nil client branch (`sp == nil` fallback in Config bridge), nil-safe Get* on nil receiver, type assertion safety in OnChange callbacks |
| ring:consequences-reviewer | Impact on single-tenant / SYSTEMPLANE_ENABLED=false path, startup/shutdown ordering, upstream/downstream services unaffected |
| ring:dead-code-reviewer | v4 residue removed (Supervisor, BundleFactory, ApplyBehavior, fiberhttp.NewHandler, swagger, HistoryStore, FakeStore/FakeBundle, SYSTEMPLANE_* env vars) |
| ring:performance-reviewer | Hot-path reads — Pattern A (cached via atomic) on hot paths, Pattern B (direct Get*) only on cold paths; debounce configured sensibly |
| ring:multi-tenant-reviewer | If service is multi-tenant, namespace strategy does NOT leak cross-tenant config; systemplane knobs are service-scoped not tenant-scoped (per-tenant config belongs in dispatch layer, not systemplane) |
| ring:lib-commons-reviewer | v5 API usage correctness; no reimplementation of deleted v4 types (Supervisor, BundleFactory); no custom wrappers around systemplane.Client; canonical import paths used |

MUST pass all 10 reviewers. Critical findings → fix and re-review.

---

## Gate 10: User Validation

MUST approve: present checklist for explicit user approval.

```markdown
## Systemplane Migration Complete

- [ ] lib-commons upgraded to v5 (verified in go.mod)
- [ ] Zero v4 systemplane residue (no Supervisor, BundleFactory, ApplyBehavior, fiberhttp.NewHandler, SYSTEMPLANE_* env vars)
- [ ] Zero non-canonical hot-reload (no fsnotify, viper.WatchConfig, inotify for config files)
- [ ] systemplane.Client constructed with NewPostgres OR NewMongoDB
- [ ] Every hot-reloadable key registered with namespace, default, validator (where applicable), description
- [ ] Secret-ish keys registered with WithRedaction(RedactFull)
- [ ] OnChange handlers (Pattern A) OR Get* read replacements (Pattern B) for every registered key
- [ ] Config bridge getters route through client when enabled, env fallback when disabled
- [ ] admin.Mount called with WithAuthorizer (custom, not default DENY-ALL) and WithActorExtractor
- [ ] Feature flag SYSTEMPLANE_ENABLED (default false) gates all new behavior
- [ ] Backward compat test passes with SYSTEMPLANE_ENABLED=false
- [ ] Enabled roundtrip test passes: admin PUT → debounce → Get* returns new value, OnChange fires
- [ ] systemplanetest.Run contract suite present and passing
- [ ] Graceful shutdown: Close() before DB close, nil-safe when feature flag off
- [ ] 10 reviewers passed
```

---

## Gate 11: Activation Guide

**MUST generate `docs/systemplane-guide.md` in the project root.** Direct, concise, no filler text.

The file is built from Gate 0 (stack), Gate 1 (analysis), and Gate 1.5 (approved key registry).

The guide MUST include:

1. **Overview**: what systemplane is in this service (one paragraph, scope fence explicit)
2. **Backend**: Postgres OR MongoDB, connection reuse from existing service handle (no separate credentials)
3. **Environment variables**:
   - `SYSTEMPLANE_ENABLED` (bool, default `false`) — master feature flag
   - No `SYSTEMPLANE_BACKEND`, no `SYSTEMPLANE_POSTGRES_DSN`, no `SYSTEMPLANE_MONGODB_URI` — v5 reuses the service's existing DB handles
4. **Key registry**: table with every registered key (namespace, key, default, type, redaction, validator rules, description) — derived from Gate 1.5 preview
5. **How to activate**:
   - Set `SYSTEMPLANE_ENABLED=true`
   - For Postgres: ensure the service's DB user has `LISTEN` privilege on the listen channel (default `systemplane_changes`) and write access to the systemplane table (default `systemplane_entries`)
   - For Mongo: ensure the user has change-stream read permission OR configure `WithPollInterval` if change streams unavailable (e.g., standalone mongod)
   - Restart the service
6. **How to verify**:
   - Startup logs show "Systemplane enabled"
   - `GET /system/{namespace}` via authenticated admin request returns the namespace's keys
   - `PUT /system/{namespace}/{key}` with a new value; confirm `GET` reflects it within the debounce window; confirm application behavior changed (e.g., log level, rate limit)
7. **How to deactivate**:
   - Set `SYSTEMPLANE_ENABLED=false` and restart
   - Service reverts to env-var-only config with no behavior change from pre-migration baseline
8. **Operational notes**:
   - Admin routes: `GET /system/:namespace`, `GET /system/:namespace/:key`, `PUT /system/:namespace/:key`
   - Default `admin.WithPathPrefix` is `/system` — can be overridden
   - Debounce window: 100ms default — rapid Sets collapse into one OnChange fire
   - Redaction: secret-ish keys return `null` in admin responses (RedactFull) or typed masks (RedactMask)
9. **Scope fence reminder**: what does NOT go in systemplane — DSNs, TLS, listen addresses, pool sizes requiring rebuild
10. **Common errors**:
    - `403` on admin → authorizer rejected the request; check auth middleware + authorizer logic
    - Value set but OnChange did not fire → registered key mismatch; confirm namespace + key exact match
    - `Register` returns error → called after `Start`; fix init order
    - Startup hang → Postgres LISTEN failed; check DB privileges

---

## State Persistence

Save to `docs/ring-dev-systemplane-migration/current-cycle.json` for resume support:

```json
{
  "cycle": "systemplane-migration",
  "lib_commons_version": "<resolved at runtime via `gh api repos/LerianStudio/lib-commons/releases/latest --jq .tag_name`>",
  "backend": "postgres",
  "v4_residue_files_pending": 0,
  "keys_registered": 12,
  "keys_with_onchange": 11,
  "keys_with_validator": 9,
  "keys_with_redaction": 2,
  "admin_mount_present": true,
  "admin_authorizer_configured": true,
  "feature_flag_default": false,
  "gates": {
    "0": "PASS",
    "1": "PASS",
    "1.5": "PASS",
    "2": "PASS",
    "3": "PASS",
    "4": "IN_PROGRESS",
    "5": "PENDING",
    "6": "PENDING",
    "7": "PENDING",
    "8": "PENDING",
    "9": "PENDING",
    "10": "PENDING",
    "11": "PENDING"
  },
  "current_gate": 4
}
```

---

## Anti-Rationalization Table

**Skill-specific rationalizations:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Just update the v4 imports to v5" | v5 API is NOT the v4 API. Imports alone fail compilation. Supervisor, BundleFactory, ApplyBehavior, ReloadEvent, HistoryStore — all DELETED. | **STOP. Execute Gate 2 to remove every v4 type reference before attempting any v5 code.** |
| "ApplyBehavior was useful, surely v5 has something similar" | No. v5 deliberately removed tiered apply. If you need BundleRebuild semantics, that config belongs in env vars + restart, not systemplane. | **STOP. Classify the config: mutates in place → systemplane. Requires teardown → env vars.** |
| "We can reimplement Supervisor on top of the v5 Client" | Reimplementation = non-canonical. Skill FAILS. Use the v5 API as designed. | **STOP. Do not write wrappers around systemplane.Client. Call it directly from bootstrap/adapters.** |
| "Swagger integration was useful in v4, re-add it" | v5 has no auto-swagger. Porting v4 swagger = non-canonical. | **STOP. Document the 3 admin routes manually in the service's OpenAPI spec.** |
| "The service already has v5 systemplane, skip the whole skill" | Existence ≠ compliance. The audit (Gate 0 Phase 2) verifies every S-check. Partial v5 adoption is not "done." | **STOP. Run compliance audit. Fix every NON-COMPLIANT S-check.** |
| "Register keys, move on" | Register without OnChange + admin.Mount + lifecycle wiring = dead code. Set() persists but nothing reacts. | **STOP. Every gate from 3 to 7 MUST complete.** |
| "fsnotify works fine for config hot-reload" | fsnotify is NON-CANONICAL. Only v5 systemplane is approved for runtime config. | **STOP. Remove fsnotify. Replace with client.OnChange.** |
| "Put the DB DSN in systemplane so we can hot-swap it" | v5 deliberately does NOT support resource teardown. DSNs require pool rebuild. | **STOP. DSN belongs in env vars. Use systemplane only for in-place mutations.** |
| "Default authorizer is fine for dev" | Default is DENY-ALL. Every request returns 403. This is not dev-mode; it is intentional. | **STOP. Supply admin.WithAuthorizer or admin.Mount is broken.** |
| "Skip code review, v5 is simple" | Simplicity means ONE wiring mistake = silent nil-returning reads or unauthenticated admin surface. | **MANDATORY: 10 reviewers.** |
| "Skip tests, systemplanetest.Run is overkill" | Contract suite catches debounce, panic-safety, nil-receiver, multi-subscriber — all easy to break manually. | **MANDATORY: systemplanetest.Run + custom unit tests.** |
| "Hardcode the namespace as empty string" | Empty namespace collides across services sharing a backend. | **MUST use a service-scoped prefix (e.g., `{service}.{component}`).** |
| "Skip backward compat, just flip the flag on" | SYSTEMPLANE_ENABLED=false MUST preserve identical behavior. Without compat, rollback is impossible. | **MUST write TestSystemplane_BackwardCompatibility.** |
| "Store the API key in systemplane with RedactMask" | RedactMask lets typed masks leak structure. Secrets need RedactFull — and preferably a vault, not systemplane. | **MUST use RedactFull; recommend moving to a vault.** |
| "Admin Mount on the public API port is fine if authenticated" | Authentication is necessary but not sufficient. Network separation is defense-in-depth. | **MUST use a path prefix + operator doc note on network policy.** |
| "Close() in shutdown is optional" | Missing Close() leaks goroutines (Postgres listener, Mongo change stream) and can hang the DB handle. | **MUST call Close() before DB close in shutdown path.** |
| "Put the callback's DB write inside OnChange" | OnChange runs under internal locks. Heavy work blocks further notifications. | **MUST keep callback trivial — update in-memory state only.** |
