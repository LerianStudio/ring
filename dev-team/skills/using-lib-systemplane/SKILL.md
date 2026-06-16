---
name: ring:using-lib-systemplane
description: "Using lib-systemplane, the hot-reload runtime-config plane (Postgres LISTEN/NOTIFY or MongoDB change streams), in two modes. Sweep Mode detects DIY config reload (SIGHUP, fsnotify, viper, pgx LISTEN), manual tenant-scoping, hand-built admin CRUD, and v4 residue. Reference Mode catalogs client lifecycle and migration-only provisioning. Go-only. Gated migration goes to ring:migrating-to-lib-systemplane. Skip for non-Go."
---

# ring:using-lib-systemplane

## When to use
Sweep mode:
- "Sweep the codebase for lib-systemplane opportunities"
- "Find where we hot-reload config DIY (SIGHUP, fsnotify, viper.WatchConfig)"
- "Audit this service for lib-systemplane adoption"
- "Find raw pgx LISTEN / Mongo change-stream watchers wired against config tables"
- "Detect v4 systemplane residue (Supervisor, BundleFactory, SYSTEMPLANE_* env vars)"

Reference mode:
- "What does lib-systemplane provide?"
- "How do I construct the client for Postgres / MongoDB?"
- "Show me Register vs RegisterTenantScoped"
- "Which read accessor should I use for a duration / int / bool?"
- "How do OnChange and OnTenantChange differ?"
- "How do I mount the admin HTTP surface safely?"
- "What does the test harness look like?"

## Skip when
- Working on non-Go services
- Working on frontend code
- Target codebase has zero hot-reloadable runtime knobs (everything is static env-var-at-startup config — DSNs, TLS material, listen addresses, secrets stay outside the plane)
- Task is documentation-only or non-code

## Related
**Migration partner:** `ring:migrating-to-lib-systemplane` — end-to-end 11-gate migration cycle. This skill is the **adoption/reference** counterpart; the migration skill is the **transformation pipeline**.
**Similar:** [[ring:using-lib-commons]], [[ring:using-lib-observability]], [[ring:using-runtime]], [[ring:using-assert]]

---

## Mode Selection

| Request Shape | Mode |
|---|---|
| "Sweep / audit / find DIY runtime config / migrate to lib-systemplane" | **Sweep** |
| "What does lib-systemplane provide for X?" | **Reference** |
| "How do I initialize / register / subscribe?" | **Reference** |
| "Replace our fsnotify + SIGHUP plumbing with lib-systemplane" | **Sweep** |
| "Wire admin routes onto our Fiber app" | **Reference** |

---

## Module Facts (lock-checked)

- **Module path:** `github.com/LerianStudio/lib-systemplane`
- **Go version:** 1.26.3+
- **Tenant context:** `github.com/LerianStudio/lib-commons/v5 v5.0.2` (via `tenant-manager/core`)
- **Observability:** `github.com/LerianStudio/lib-observability v1.1.0` (`log.Logger`, `tracing.Telemetry`, `runtime.RecoverAndLog`)
- **Dual backend:** Postgres 13+ (LISTEN/NOTIFY) **or** MongoDB 4.4+ (change streams; polling fallback for standalone deployments)
- **Provisioning:** migration-only via `systemplane.SchemaSQL()` + `systemplane.DefaultSeedSQL()` public artifacts. Runtime DDL hook (`runSchema`) was removed in v1.6.0. Consumers vendor the artifacts into their own SQL migration pipeline via the `make systemplane-ddl` generator pattern — see `ring:migrating-to-lib-systemplane` Gate 3.5 and `multi-tenant.md` §27 "Cold-tenant resolution"
- **License:** Elastic 2.0
- **Scope:** runtime-mutable knobs only — never bootstrap-only material (DSNs, TLS, listen addresses, secrets)

---

# SWEEP MODE

Orchestrate a 4-phase sweep. Each phase has a hard gate — do not proceed until the current phase produces its artifact.

```
Phase 1: Version Reconnaissance     → systemplane-version-report.json
Phase 2: CHANGELOG Delta Analysis   → systemplane-delta-report.json
Phase 3: Multi-Angle DIY Sweep      → 7 × systemplane-sweep-{N}-{angle}.json
Phase 4: Consolidated Report        → systemplane-sweep-report.md + tasks.json
```

## Phase 1: Version Reconnaissance

1. Read `go.mod` — search for `github.com/LerianStudio/lib-systemplane` and any v4-era `github.com/LerianStudio/lib-commons/v[34]/commons/systemplane` imports
2. WebFetch `https://api.github.com/repos/LerianStudio/lib-systemplane/releases/latest` — extract `tag_name`
3. Classify drift: `not-adopted` / `up-to-date` / `minor-drift` / `moderate-drift` / `major-upgrade` / `v4-residue`
4. If any `v4/commons/systemplane` or `Supervisor`/`BundleFactory` import survives → flag `v4-residue: true`
5. Emit `/tmp/systemplane-version-report.json`:
   `{adopted, pinned_version, latest_version, drift_classification, v4_residue, module_path}`

## Phase 2: CHANGELOG Delta Analysis

1. WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-systemplane/main/CHANGELOG.md`
2. Extract entries between pinned_version (exclusive) and latest_version (inclusive). If not yet adopted, summarize the whole CHANGELOG.
3. Classify each entry: `new-api` / `breaking-change` / `tenant-feature` / `admin-feature` / `security-fix` / `performance` / `bugfix`
4. Cross-reference `MIGRATION_TENANT_SCOPED.md` for two-phase rolling-deploy implications when adopting tenant overrides
5. Emit `/tmp/systemplane-delta-report.json` with classified entries

## Phase 3: Multi-Angle DIY Sweep

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

If you find yourself about to dispatch an explorer in a turn AFTER any explorer has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the phase INCOMPLETE rather than completing the trickle.

### Self-verify after dispatch

After the dispatch turn, verify all 7 Task calls were emitted in that single turn. If fewer than 7 went out, the phase did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial pool.

### Parallel dispatch — atomic batch

Emit all 7 Task calls in a SINGLE TURN, as one atomic batch.

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete pool in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.

Dispatch all 7 explorer angles **in a single parallel batch**. Wait for all before Phase 4.

**Per-explorer dispatch** (`subagent_type: ring:codebase-explorer`):

```
## Target
<absolute path to target repo root>

## Your Angle
<angle number + name>

## Severity Calibration / DIY Patterns / Replacement / Migration Complexity / Version Context
<verbatim from the angle spec below>

## Output
Write findings to: /tmp/systemplane-sweep-{N}-{angle-slug}.json
Schema: { angle_number, angle_name, severity, migration_complexity,
  findings: [{file, line, diy_pattern, replacement, evidence_snippet, notes}],
  summary, requires_major_upgrade }
If no findings: write file with empty findings array and summary
"No DIY patterns detected for this angle".
```

### Angle 1 — SIGHUP / fsnotify .env reload (CRITICAL)

**DIY patterns to grep:**
- `signal.Notify(.*syscall.SIGHUP` paired with re-reading `.env`, YAML, or `os.Getenv` post-startup
- `fsnotify.NewWatcher()` watching config files
- Goroutines that `os.Open` a config file on a `time.Ticker`
- Any code path that re-loads env vars after `main()` has started

**Replacement:** `systemplane.NewPostgres` / `NewMongoDB` + `Register` + `Start` + `OnChange`. Per-key subscriptions replace the global reload pulse.

**Severity rationale:** SIGHUP/fsnotify reloads are racy by definition (no per-key fan-out, no validator, no audit trail). Hot-reload runtime config without observability is a class of silent misbehavior.

### Angle 2 — viper.WatchConfig / envconfig.Watch (HIGH)

**DIY patterns to grep:**
- `viper.WatchConfig()` / `viper.OnConfigChange(`
- `envconfig.Watch` / `kelseyhightower/envconfig` reload helpers
- Hand-rolled `time.Ticker` polling a settings table

**Replacement:** Same as Angle 1. Viper's file-watching does not bind keys to validators or redaction policies; lib-systemplane does both at `Register`.

### Angle 3 — Raw pgx LISTEN for config tables (CRITICAL)

**DIY patterns to grep:**
- `LISTEN ` SQL statements in code targeting a config / settings / feature-flag table
- `conn.WaitForNotification(` consumers on settings channels
- `pgx.Connect` long-lived connections used solely for config notifications
- Custom `NOTIFY` triggers on a runtime-config table without debounce or write-through cache

**Replacement:** `systemplane.NewPostgres(db, listenDSN, opts...)`. The library owns the LISTEN connection lifecycle, debounces per `(namespace, key, tenantID)` via `WithDebounce` (default 100ms), and provides a write-through cache so the in-process Get is consistent with the changefeed echo.

**Severity rationale:** Hand-rolled LISTEN paths typically miss the panic-recovery and reconnect-with-backoff machinery `internal/postgres` provides — silent goroutine death under load.

### Angle 4 — Hand-rolled MongoDB change-stream / polling watchers (CRITICAL)

**DIY patterns to grep:**
- `coll.Watch(` against a config collection
- `mongo.ChangeStream` consumers without panic recovery
- Polling loops (`time.Ticker` + `Find`) over a settings collection
- Manual `resumeAfter` token persistence for config streams

**Replacement:** `systemplane.NewMongoDB(client, "db", opts...)`. Pass `WithPollInterval(...)` for standalone Mongo (no replica set); otherwise change-streams are used automatically. The library wraps the subscribe goroutine with `runtime.RecoverAndLog`.

### Angle 5 — Manual tenant-scoping in config reads (HIGH)

**DIY patterns to grep:**
- Custom `(tenantID, key) → value` map indexed off a global config struct
- Calls to `core.GetTenantIDContext(ctx)` followed by manual cascade to a global value or default
- Tenant-specific config columns / Mongo fields read directly without validator or redaction
- Missing tenant-ID validation when reading config (no `core.IsValidTenantID` check)

**Replacement:** `RegisterTenantScoped(...)` + `GetForTenant(ctx, ns, key)` (or the typed `GetStringForTenant` / `GetIntForTenant` / `GetBoolForTenant` / `GetFloat64ForTenant` / `GetDurationForTenant`). The library's `extractTenantID` is **fail-closed** — `ErrMissingTenantContext` / `ErrInvalidTenantID` is returned rather than silently falling back to a shared global.

**Severity rationale:** Silent fallback from a missing tenant to a shared global is the cross-tenant-leak vector. The library's fail-closed contract makes the bug a loud error instead of a quiet data leak.

### Angle 6 — Hand-built HTTP admin UI for config CRUD (MEDIUM)

**DIY patterns to grep:**
- Custom Fiber/Gin/chi handlers for `GET/PUT/DELETE` on a settings table or collection
- Authorization middleware bolted onto a config admin route without a default-deny path
- Routes echoing config values without applying a redaction policy
- Handcrafted tenant-list endpoints (`GET /system/:ns/:key/tenants`)

**Replacement:** `admin.Mount(router, client, admin.WithPathPrefix(...), admin.WithAuthorizer(...), admin.WithTenantAuthorizer(...), admin.WithActorExtractor(...))`. The library serves the full six-route surface (list namespace, get/put one, list tenants for key, put/delete tenant override) with default-deny authorization and per-key redaction.

**Severity rationale:** Default-deny is the safe-by-default property. Hand-built admin routes routinely ship with weaker authorization than the lib-commons-backed reference implementation.

### Angle 7 — v4 systemplane residue + runtime DDL provisioning (CRITICAL)

**DIY patterns to grep:**
- `github.com/LerianStudio/lib-commons/v[34]/commons/systemplane` imports
- `Supervisor`, `BundleFactory`, `ApplyBehavior` types or methods
- `SYSTEMPLANE_*` environment variables (the v4-era runtime knobs)
- Sub-packages from the v4 layout: `domain/`, `ports/`, `registry/`, `service/`, `bootstrap/` under any `systemplane/` tree
- `lib-commons/v5/commons/systemplane` imports (the v5 package was **extracted** to the standalone `lib-systemplane` module; `lib-commons/v5/commons/systemplane` is the pre-extraction location and signals an out-of-date pin)
- Runtime DDL provisioning: `systemplane.SchemaSQL()` called at boot, `runSchema`-style hooks, `CREATE TABLE systemplane_entries` executed outside `migrations/`, missing `cmd/generate-systemplane-ddl/` + `migrations/systemplane_ddl_manifest.json`, missing `make systemplane-ddl` / `check-systemplane-ddl-drift` Make targets

**Replacement:**
- v4/v5-extracted paths → switch to the standalone module `github.com/LerianStudio/lib-systemplane`; delete the v4 sub-packages outright (v5 has no equivalent layers — the API surface is flat).
- Runtime DDL → migration-only provisioning via the `make systemplane-ddl` generator (canonical scaffold: `go-boilerplate-ddd` once its systemplane-ddl PR lands; reference implementation in `plugin-br-bank-transfer` at `cmd/generate-systemplane-ddl/`, `migrations/000011_systemplane_schema.{up,down}.sql` → `000013_systemplane_project_seed.{up,down}.sql`, `migrations/systemplane_ddl_manifest.json`, and the bootstrap seam `SystemplaneSeedEntries() ([]SystemplaneSeedEntry, error)` at `internal/bootstrap/systemplane_ddl_gen.go`).

**Severity rationale:** v4 packages and the runtime DDL hook are **deleted** from current lib-systemplane; any surviving call site will fail the build (v4) or fail at boot (runtime DDL under a least-privilege tenant-manager role). Surfacing both in the sweep prevents a CI/runtime surprise.

## Phase 4: Consolidated Report

Dispatch synthesizer (`subagent_type: ring:codebase-explorer`):

```
Read /tmp/systemplane-version-report.json, /tmp/systemplane-delta-report.json,
and /tmp/systemplane-sweep-*.json (7 files).

Emit:
1. /tmp/systemplane-sweep-report.md — aggregate findings by severity
2. /tmp/systemplane-sweep-tasks.json — one task per DIY-pattern cluster
   (same file/package = one task). Each task references the matching
   replacement API surface from Reference Mode.

MUST NOT invent findings.
MUST NOT omit explorer findings.
MUST NOT reclassify severity without justification.
```

Surface report path + task count to user; offer handoff to `ring:migrating-to-lib-systemplane` for the gated implementation cycle, or to `ring:running-dev-cycle` for ad-hoc remediation.

---

# REFERENCE MODE

The API is small enough to inline. Sections follow the **lifecycle order** the client enforces at runtime: construct → register → start → read/write/subscribe → close.

## 1. Construction

### `NewPostgres(db *sql.DB, listenDSN string, opts ...Option) (*Client, error)`

Backs the client with Postgres LISTEN/NOTIFY.

- `db` is the read/write handle (returned by `sql.Open("pgx", dsn)`).
- `listenDSN` is a **separate** DSN passed to `pgx.Connect` for the long-lived LISTEN connection. `database/sql` does not expose its underlying DSN, so the caller supplies it explicitly. Typically equal to the DSN used to open `db`.
- Returns `store.ErrNilBackend` if `db == nil`.

```go
db, err := sql.Open("pgx", dsn)
if err != nil { return err }

client, err := systemplane.NewPostgres(db, dsn,
    systemplane.WithLogger(logger),
    systemplane.WithTelemetry(telemetry),
    systemplane.WithDebounce(150*time.Millisecond),
)
```

### `NewMongoDB(client *mongo.Client, database string, opts ...Option) (*Client, error)`

Backs the client with MongoDB change-streams (or polling if `WithPollInterval` is set).

- Change-streams require a **replica set**. For standalone MongoDB, pass `WithPollInterval(2*time.Second)` (or another positive duration).
- Returns `store.ErrNilBackend` if `client == nil`.

```go
mc, _ := mongo.Connect(options.Client().ApplyURI("mongodb://..."))
client, err := systemplane.NewMongoDB(mc, "app",
    systemplane.WithPollInterval(2*time.Second), // standalone Mongo
)
```

## 2. Options (construction-time)

| Option | Default | Purpose |
|---|---|---|
| `WithLogger(log.Logger)` | `log.NewNop()` | Structured logger (lib-observability). Nil is ignored. |
| `WithTelemetry(*tracing.Telemetry)` | nil | OpenTelemetry provider for spans/metrics. Nil is ignored. |
| `WithListenChannel(string)` | `"systemplane_changes"` | Postgres LISTEN channel name. Ignored by MongoDB. |
| `WithPollInterval(time.Duration)` | 0 (change-streams) | Enables MongoDB polling mode. Ignored by Postgres. |
| `WithDebounce(time.Duration)` | 100ms | Trailing-edge debounce per `(ns, key, tenantID)` tuple. Zero/negative disables debouncing. |
| `WithCollection(string)` | `"systemplane_entries"` | MongoDB collection. Ignored by Postgres. |
| `WithTable(string)` | `"systemplane_entries"` | Postgres table. Ignored by MongoDB. |
| `WithLazyTenantLoad(maxEntries int)` | eager mode | Switches tenant cache from eager hydration to a bounded LRU (`hashicorp/golang-lru/v2`). Non-positive `max` falls back to eager. |
| `WithTenantSchemaEnabled()` | false (phase-1 compat) | Drops the legacy `(namespace, key)` unique constraint and creates the composite `(namespace, key, tenant_id)` unique. Required before tenant writes succeed. See `MIGRATION_TENANT_SCOPED.md` §4 for rolling-deploy ordering. |

## 3. Key Registration (before `Start`)

### `Register(namespace, key string, defaultValue any, opts ...KeyOption) error`

Declares a globals-only key. **Must be called before `Start`** — returns `ErrRegisterAfterStart` otherwise.

- Reserved key name: `"tenants"` (collides with the admin tenant routes — `ErrValidation`).
- Reserved character: `U+001F` (Unit Separator) in namespace or key — `ErrValidation`.
- Duplicate `(namespace, key)` registration → `ErrDuplicateKey`.
- If `WithValidator` is supplied and rejects the default value at registration time → `ErrValidation` wrapping the validator's own error.

### `RegisterTenantScoped(namespace, key string, defaultValue any, opts ...KeyOption) error`

Declares a tenant-scoped key. Same global semantics as `Register` (Get / Set / List / OnChange still operate on the legacy global row), **plus** the key becomes eligible for per-tenant overrides via `SetForTenant` / `GetForTenant` / `DeleteForTenant` / `OnTenantChange`.

**Mutable-default caveat (locked in code comments):** the registered default is held by reference. A subscriber mutating a slice/map default mutates it for every tenant falling through to the default. Prefer value types or wrap in a defensive copy.

### `KeyOption` setters

| Option | Effect |
|---|---|
| `WithDescription(string)` | Human-readable description surfaced via `KeyDescription` and admin GET responses |
| `WithValidator(func(any) error)` | Runs against the default at registration AND against every `Set` / `SetForTenant` value |
| `WithRedaction(RedactPolicy)` | Renders value as raw / `"****"` / `"[REDACTED]"` in admin output and logs |

### Redaction policies

```go
const (
    RedactNone RedactPolicy = iota // raw value
    RedactMask                     // "****"
    RedactFull                     // "[REDACTED]"
)

func ApplyRedaction(value any, policy RedactPolicy) any
```

Any key holding credentials / tokens / secrets MUST use `RedactFull`. The admin handlers call `ApplyRedaction` per key on every GET, with the policy looked up via `client.KeyRedaction(ns, key)`.

## 4. Lifecycle: `Start` and `Close`

### `Start(ctx context.Context) error`

1. Seeds the cache with registered defaults under `cacheMu`.
2. Hydrates from the backing store via `store.List`; unregistered rows are logged and skipped.
3. Eagerly hydrates the tenant cache (skipped in lazy mode — first-touch populates the LRU).
4. Launches the subscribe goroutine wrapped in `runtime.RecoverAndLog`.

Idempotent: a second `Start` returns nil. Returns `ErrClosed` on a closed receiver.

### `Close() error`

- Idempotent (via `sync.Once`), safe on a nil receiver.
- Cancels the subscribe goroutine and waits up to `closeWaitTimeout` (10s) for it to exit.
- Calls `store.Close` on the backend adapter. Does **not** close the externally-owned `*sql.DB` / `*mongo.Client`.

## 5. Reads (nil-receiver safe)

All read accessors return zero values when the receiver is nil, the client is closed, or the key is unregistered.

### Untyped

- `Get(ns, key string) (any, bool)` — `(value, true)` on hit; falls through cache → default.
- `KeyStatus(ns, key) (registered, tenantScoped bool)` — used by admin to distinguish 404 vs 400.
- `KeyDescription(ns, key) string`
- `KeyRedaction(ns, key) RedactPolicy`
- `Logger() log.Logger` — never nil; subpackages (notably `admin`) reuse the client's logger.

### Typed (legacy / globals)

- `GetString(ns, key) string` — `""` on miss.
- `GetInt(ns, key) int` — accepts both `int` and `float64` (JSON numbers decode as float64).
- `GetBool(ns, key) bool`
- `GetFloat64(ns, key) float64`
- `GetDuration(ns, key) time.Duration` — accepts `time.Duration`, `time.ParseDuration`-compatible strings, or float64 nanoseconds.

### `List(namespace string) []ListEntry`

Returns all currently-cached entries in the namespace, sorted by key. `ListEntry{Key, Value, Description}`. Empty namespace → empty slice (never nil).

### Typed tenant reads

These mirror the legacy typed accessors but **surface errors** instead of silently returning zeros. Type mismatches return `ErrValidation` (configuration bug, not a runtime miss).

- `GetStringForTenant(ctx, ns, key) (string, error)`
- `GetIntForTenant(ctx, ns, key) (int, error)` — rejects non-integral float64 with `ErrValidation` (silent truncation would convert one bad config into another valid-looking config).
- `GetBoolForTenant(ctx, ns, key) (bool, error)`
- `GetFloat64ForTenant(ctx, ns, key) (float64, error)`
- `GetDurationForTenant(ctx, ns, key) (time.Duration, error)`

Underlying primitive:

```go
GetForTenant(ctx, ns, key) (value any, found bool, err error)
```

Resolution order: `tenantCache[tenantID][nk]` → legacy `cache[nk]` → registered default. `found` is `true` whenever a value is returned (including the default fallthrough — the "no tenant override yet" case is **not** an error).

## 6. Writes

### `Set(ctx, namespace, key string, value any, actor string) error`

Globals-only write. Runs the registered validator (if any), `json.Marshal`s the value, persists via `store.Set`, then write-through-caches the **JSON-canonicalized** value (so a subsequent `GetInt` returns a `float64` consistently with the changefeed echo).

Errors: `ErrClosed`, `ErrNotStarted`, `ErrUnknownKey`, `ErrValidation` (validator or non-serializable value), or any wrapped store error.

**Subscribers are NOT fired from `Set`.** The changefeed echo drives `OnChange`. This invariant prevents double-firing and keeps the semantic that `OnChange` observes *backend* state changes.

### `SetForTenant(ctx, namespace, key string, value any, actor string) error`

Tenant write. Validates tenant ID via `extractTenantID` (fail-closed: `ErrMissingTenantContext`, `ErrInvalidTenantID`), checks `requireTenantScoped` (`ErrUnknownKey`, `ErrTenantScopeNotRegistered`), runs validator, marshals, persists via `store.SetTenantValue`, write-through-caches.

Additional errors: `ErrTenantSchemaNotEnabled` (phase-1 backend rejecting tenant writes).

### `DeleteForTenant(ctx, namespace, key, actor string) error`

Removes a tenant override. **Idempotent at the backend** (delete-missing returns nil). On a no-op delete the backend emits no event, so `OnTenantChange` does **not** fire — tests relying on the callback must `SetForTenant` first.

### `ListTenantsForKey(namespace, key string) []string`

Returns the sorted, deduplicated set of tenant IDs with an override for `(ns, key)`. Never returns nil — every error path returns the shared `emptyTenantList` sentinel. Excludes the `_global` sentinel. Bounded by an internal 5s timeout.

## 7. Subscriptions

### `OnChange(namespace, key string, fn func(newValue any)) (unsubscribe func())`

Per-key callback fired by the changefeed echo for **global-row** writes (i.e. tenant_id = `_global`). Callbacks are invoked sequentially, each wrapped in `runtime.RecoverAndLog`. The returned unsubscribe is `sync.Once`-guarded; safe to call multiple times.

Nil receiver, nil `fn`, or unregistered key → no-op unsubscribe.

### `OnTenantChange(namespace, key string, fn func(ctx context.Context, ns, key, tenantID string, newValue any)) (unsubscribe func())`

Tenant-aware callback fired by the changefeed echo for **tenant-row** writes. The `ctx` argument is pre-scoped to `tenantID` via `core.ContextWithTenantID`, so subscribers can pass it straight into tenant-aware lib-commons facilities (DLQ, idempotency, webhook delivery) without re-propagating the tenant ID.

A single subscription observes every tenant — the `tenantID` argument distinguishes which override changed.

Invariant (AC8 in the source): `OnChange` fires **exclusively** for `store.SentinelGlobal` events, `OnTenantChange` fires **exclusively** for tenant events. The split is on the row's `tenant_id`, not on whether the key was registered as tenant-scoped.

```go
unsub := client.OnTenantChange("global", "fees.fail_closed_default",
    func(ctx context.Context, ns, key, tenantID string, newValue any) {
        // ctx already carries tenantID — safe for DLQ / webhook / idempotency
    })
defer unsub()
```

## 8. Admin HTTP Surface (`admin` subpackage)

Import path: `github.com/LerianStudio/lib-systemplane/admin`.

### `admin.Mount(router fiber.Router, c *systemplane.Client, opts ...MountOption)`

Routes registered (default prefix `/system`):

```
GET    /<prefix>/:namespace                          - list entries
GET    /<prefix>/:namespace/:key                     - get one entry
PUT    /<prefix>/:namespace/:key                     - write a global value
GET    /<prefix>/:namespace/:key/tenants             - list tenants with overrides
PUT    /<prefix>/:namespace/:key/tenants/:tenantID   - write a tenant override
DELETE /<prefix>/:namespace/:key/tenants/:tenantID   - remove a tenant override
```

Path-segment caps enforced at the edge: namespace ≤ 256 bytes, key ≤ 512 bytes (BadRequest on overflow). Nil `router` or nil `client` makes `Mount` a no-op.

### Mount options

| Option | Effect |
|---|---|
| `WithPathPrefix(string)` | Override the URL prefix (default `/system`). Empty value ignored. |
| `WithAuthorizer(func(*fiber.Ctx, action string) error)` | Authorizes **legacy global routes**. action is `"read"` or `"write"`. Non-nil error → 403 with body `"forbidden"`. Default: deny-all. |
| `WithTenantAuthorizer(func(*fiber.Ctx, action, tenantID string) error)` | Authorizes **tenant routes**. Default: deny-all. For the tenant-list route, `tenantID` is empty. |
| `WithActorExtractor(func(*fiber.Ctx) string)` | Extracts the actor string passed into `client.Set` / `SetForTenant`. Default returns `""`. |

**Critical contract — default-deny escalation:** the two authorizers are **independent**. Configuring only `WithAuthorizer` does **NOT** implicitly grant access to tenant routes (and vice-versa). This prevents a silent privilege escalation: a service that pre-dates tenant support and configures only `WithAuthorizer` cannot accept tenant writes it was never authorized to handle.

**Wire-redaction contract:** authorizer error strings are NOT echoed on the wire (the body is the fixed string `"forbidden"`). The original error is logged at Debug level.

## 9. Errors (sentinel set)

All exported as package-level vars; check via `errors.Is`.

| Sentinel | When |
|---|---|
| `ErrClosed` | Receiver is nil or `Close` has run |
| `ErrNotStarted` | Read/write before `Start` |
| `ErrRegisterAfterStart` | `Register` / `RegisterTenantScoped` after `Start` |
| `ErrUnknownKey` | Unregistered `(namespace, key)` |
| `ErrValidation` | Validator rejected the value, non-JSON-serializable value, or typed accessor mismatch |
| `ErrDuplicateKey` | Re-registration of the same `(namespace, key)` |
| `ErrMissingTenantContext` | Tenant-scoped op called without a tenant ID in ctx |
| `ErrInvalidTenantID` | Tenant ID fails `core.IsValidTenantID` or equals `_global` sentinel |
| `ErrTenantScopeNotRegistered` | Tenant-scoped op against a key registered via `Register` |
| `ErrTenantSchemaNotEnabled` | Tenant write against a phase-1 backend (re-exported from `internal/store`) |

## 10. Test Harness (`NewForTesting`)

Build-tag gated: compiled only under `-tags=unit` or `-tags=integration`. **Excluded from production binaries.**

```go
//go:build unit || integration

client, err := systemplane.NewForTesting(myTestStore,
    systemplane.WithDebounce(0), // already the default for testing
)
```

- `TestStore` mirrors the internal `store.Store` interface with public `TestEntry` / `TestEvent` types.
- Debouncing is **disabled** by default for deterministic tests (override via `WithDebounce`).
- API stability is **not** promised — the harness is intentionally undocumented in README/API docs.

For contract testing against a real backend, see `systemplanetest` in the library repo (separate package, mirrors lib-commons conventions).

## 11. Composition With Adjacent Libraries

| Library | Touchpoint |
|---|---|
| `lib-commons/v5/commons/tenant-manager/core` | `ContextWithTenantID`, `GetTenantIDContext`, `IsValidTenantID` — the only allowed tenant-ID extraction path. `OnTenantChange` pre-scopes ctx via `ContextWithTenantID`. |
| `lib-observability/log` | `WithLogger` accepts a `log.Logger`. Logger is reused by `admin` via `client.Logger()` — no parallel admin logger option exists. |
| `lib-observability/tracing` | `WithTelemetry(*tracing.Telemetry)` enables spans on Start / Set / GetForTenant / SetForTenant / DeleteForTenant / ListTenantsForKey. |
| `lib-observability/runtime` | `runtime.RecoverAndLog` wraps the subscribe goroutine **and** every OnChange / OnTenantChange callback dispatch. |
| `lib-commons/v5/commons/net/http` | The admin package uses `commonshttp.RespondError` for uniform error responses. |

## 12. Provisioning Artifacts (`SchemaSQL` / `DefaultSeedSQL`) — migration-only

lib-systemplane v1.6.0+ publishes the DDL it needs as two public functions and removes the runtime `runSchema` hook. Consumers MUST fold the artifacts into their own SQL migration pipeline; provisioning at boot is FORBIDDEN.

| Artifact | Returns | Folds into |
|---|---|---|
| `systemplane.SchemaSQL() string` | Byte-faithful DDL for `systemplane_entries` table + `systemplane_notify_v3` function + 2 triggers (fully idempotent: `CREATE TABLE IF NOT EXISTS` / `CREATE OR REPLACE` / `DROP TRIGGER IF EXISTS`). Channel `systemplane_changes`, table `systemplane_entries` are fixed (no placeholders). | `migrations/NNN_systemplane_schema.up.sql` (`down` = drop triggers + function, never the table) |
| `systemplane.DefaultSeedSQL() string` | `INSERT ... ON CONFLICT (namespace, key) DO NOTHING` over the universal default keys (the lib's own runtime knobs). | `migrations/NNN+1_systemplane_default_seed.up.sql` (`down` = value-guarded DELETE of the universal keys) |

**Canonical scaffold:** `make systemplane-ddl` (generator under `cmd/generate-systemplane-ddl/`) vendors both artifacts into append-only migrations + a `migrations/systemplane_ddl_manifest.json`, then emits a third project-seed migration derived from the service's own registrations via a bootstrap seam returning `[]SystemplaneSeedEntry`. The full pattern (seam contract, manifest, drift guard, MT/ST symmetry) is normative in `multi-tenant.md` §27 "Cold-tenant resolution" and operational in `ring:migrating-to-lib-systemplane` Gate 3.5. Reference implementation: `plugin-br-bank-transfer` (`cmd/generate-systemplane-ddl/`, `internal/bootstrap/systemplane_ddl_gen.go`, `migrations/000011..000013_systemplane_*`).

**Invariants (locked):**

- NEVER call `SchemaSQL()` or `DefaultSeedSQL()` at boot. Runtime DDL is a CRITICAL deviation — least-privilege tenant-manager roles cannot execute it.
- NEVER hand-edit a generated `migrations/NNN_systemplane_*.sql`. The generator is the only writer; `check-systemplane-ddl-drift` enforces this.
- ALWAYS expose the seam — same signature (`SystemplaneSeedEntries() ([]SystemplaneSeedEntry, error)` or equivalent) across services. The generator depends on it; ad-hoc per-project shapes break the scaffold contract.
- ST and MT use the SAME migration pipeline (single-tenant `migrate-up` or multi-tenant tenant-manager provisioning — same `.sql` files).

## 13. Scope Reminder (locked)

Systemplane is for **runtime-mutable knobs only**. Bootstrap-only configuration (DB DSNs, secrets, TLS material, telemetry endpoints, server identity, listen addresses) belongs in environment variables or a secret manager — **never** in the systemplane plane. Anything requiring resource teardown to apply (reopening a DB pool, rotating a TLS cert) violates the hot-reload contract by definition.

## 14. Cross-references

- `ring:migrating-to-lib-systemplane` — gated end-to-end migration cycle (stack detection → v5 upgrade → register → subscribe → admin mount → tests → review). Use after this skill identifies adoption opportunities.
- [[ring:using-lib-commons]] — tenant-manager/core, idempotency, DLQ, webhook delivery, and the broader v5 surface that composes with systemplane.
- [[ring:using-lib-observability]] — `log.Logger`, `tracing.Telemetry`, `runtime.RecoverAndLog` — the three injected by `WithLogger` / `WithTelemetry`.
- [[ring:using-runtime]] — panic-observability trident used internally for the subscribe goroutine and callback shields. Match the same policy elsewhere in your service.
