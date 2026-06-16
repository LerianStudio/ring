---
name: ring:using-lib-observability
description: "Using lib-observability v1.1.0, Lerian's OpenTelemetry foundation (lib-commons, lib-systemplane, lib-streaming depend on it), in two modes. Sweep Mode detects DIY zap/slog logging, raw OTel metrics, hand-rolled redaction, and hard-coded attribute strings. Reference Mode catalogs the log, metrics, zap, redaction, and constants packages. Go-only. Skip for non-Go or assert/runtime/tracing."
---

# ring:using-lib-observability

## When to use
Sweep mode:
- "Sweep the codebase for lib-observability opportunities"
- "Find where we use raw zap / slog instead of lib-observability/log"
- "Audit OTel metric collectors and replace with MetricsFactory"
- "Find hand-rolled redaction or hard-coded OTel attribute strings"

Reference mode:
- "What does lib-observability provide for X?"
- "How do I initialize the logger for production vs local?"
- "What's the right way to create a counter / gauge / histogram?"
- "Which constants ship for OTel attributes/metric names/event names?"
- "How does redaction.IsSensitiveField decide what to mask?"

## Skip when
- Working on non-Go services
- Working on frontend code
- Target codebase is Ring itself (no lib-observability dependency)
- Target package is `assert/`, `runtime/`, or `tracing/` (see Related)

## Related
**Similar:** ring:using-assert, ring:using-runtime, ring:using-tracing, ring:using-lib-commons

`assert/` is owned by [[using-assert]] (production assertions).
`runtime/` is owned by [[using-runtime]] (panic recovery telemetry).
`tracing/` is owned by [[using-tracing]] (OTel trace SDK + processor).

This skill covers the foundation layer only: `log`, `metrics`, `zap`, `redaction`, `constants`.

---

## Mode Selection

| Request Shape | Mode |
|---|---|
| "Sweep / audit / find DIY observability" | **Sweep** |
| "Replace our zap.New / slog setup with lib-observability" | **Sweep** |
| "What logger interface do we use?" | **Reference** |
| "How do I build a Counter with attributes?" | **Reference** |
| "What constants exist for `db.system` etc?" | **Reference** |

---

# SWEEP MODE

Orchestrate a 3-phase sweep. Each phase has a hard gate — do not proceed until the current phase produces its artifact.

```
Phase 1: Version Reconnaissance  → version-report.json
Phase 2: Multi-Angle DIY Sweep   → 5 × libobs-sweep-{N}-{angle}.json
Phase 3: Consolidated Report     → libobs-sweep-report.md + tasks.json
```

## Phase 1: Version Reconnaissance

1. Read `go.mod` — extract pinned version of `github.com/LerianStudio/lib-observability`
2. WebFetch `https://api.github.com/repos/LerianStudio/lib-observability/releases/latest` — extract `tag_name`
3. Classify drift: up-to-date / minor-drift / moderate-drift / major-upgrade / not-pinned
4. Emit `version-report.json`: `{pinned_version, latest_version, drift_classification, module_path}`

If the target does not depend on `lib-observability` directly but depends on `lib-commons v5+`, note that lib-observability is pulled in transitively — sweep findings still apply.

## Phase 2: Multi-Angle DIY Sweep

### ⛔ STOP-CHECK BEFORE DISPATCH

Before emitting any Task call, count the explorers you intend to launch in this turn.
- Count MUST equal 5.
- If count < 5 → STOP. Do not partial-dispatch. Reconcile against the 5 angles below and try again.
- The 5 angles are the canonical sweep. No substitutions, no omissions.

### ⛔ MUST NOT trickle-dispatch

All 5 explorers leave in the SAME TURN, before reading any explorer output.

Forbidden sequences:
- Dispatch explorer 1 → read result → dispatch explorer 2
- Dispatch a subset → wait → dispatch the rest
- Dispatch follow-up explorers conditioned on partial output
- Loop sequentially over the angle list

If you find yourself about to dispatch an explorer in a turn AFTER any explorer has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the phase INCOMPLETE rather than completing the trickle.

### Self-verify after dispatch

After the dispatch turn, verify all 5 Task calls were emitted in that single turn. If fewer than 5 went out, the phase did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial pool.

### Parallel dispatch — atomic batch

Emit all 5 Task calls in a SINGLE TURN, as one atomic batch.

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete pool in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.

Dispatch all 5 explorer angles in **one batch** (`subagent_type: ring:codebase-explorer`).

Per-explorer dispatch prompt:

```
## Target
<absolute path to target repo root>

## Your Angle
<angle number + name from the catalog below>

## DIY Patterns / Replacement / Severity / Migration Complexity
<verbatim from this file for this angle>

## Output
Write findings to: /tmp/libobs-sweep-{N}-{angle-slug}.json
Schema: { angle_number, angle_name, severity, migration_complexity,
          findings: [{file, line, diy_pattern, replacement, evidence_snippet, notes}],
          summary }
If no findings: empty findings array, summary "No DIY patterns detected for this angle".
```

### Angle 1: Raw zap / slog logger setup

**Severity:** HIGH
**Migration Complexity:** moderate

**DIY Patterns to Detect:**
- `zap.NewProduction(`, `zap.NewDevelopment(`, `zap.NewExample(`, `zap.New(zapcore.NewCore(...))` outside `lib-observability/zap`
- `zap.Config{...}.Build(`, `zap.NewProductionConfig(`, `zap.NewDevelopmentConfig(` in service code
- `slog.New(`, `slog.NewJSONHandler(`, `slog.NewTextHandler(` in service code
- `log.New(` (stdlib) used for structured logging
- Service-owned environment switches (`if env == "prod" { ... } else { ... }`) wrapping zap config
- Hand-wired `otelzap.NewCore(` for trace correlation

**lib-observability Replacement:**
- `zap.New(zap.Config{Environment: zap.EnvironmentProduction, Level: "info", OTelLibraryName: "my-service"})` — returns `*zap.Logger` that implements `log.Logger`
- For tests: `log.NewNop()`
- For lightweight stdlib-style: `&log.GoLogger{Level: log.LevelInfo}` (implements `log.Logger`, includes CWE-117 sanitization)

**Why:** lib-observability/zap auto-injects `trace_id` and `span_id` from `ctx`, bridges to OTel Logs SDK via otelzap, applies CWE-117 control-char sanitization for console encoding, and exposes a runtime-adjustable `AtomicLevel` for hot reload.

**Evidence grep:**
```
grep -rn "zap\.NewProduction\|zap\.NewDevelopment\|zap\.NewProductionConfig\|slog\.New\|otelzap\.NewCore" --include="*.go"
```

### Angle 2: Raw OpenTelemetry metric instruments

**Severity:** HIGH
**Migration Complexity:** moderate

**DIY Patterns to Detect:**
- `otel.Meter(` followed by `Int64Counter(`, `Int64Gauge(`, `Int64Histogram(`, `Float64*(` in service code
- `meter.Int64Counter(`, `meter.Int64Histogram(` called directly without going through a factory
- Package-level `var counter, _ = meter.Int64Counter(...)` (no error handling, no caching coordination)
- Hand-rolled `sync.Map` or `map[string]metric.Int64Counter` caches for instrument reuse
- `metric.WithAttributes(attribute.String(...))` chains repeated inline per call site

**lib-observability Replacement:**
- `metrics.NewMetricsFactory(meter, logger)` — single factory, thread-safe lazy instrument cache via `sync.Map`
- `factory.Counter(metrics.Metric{...}).WithAttributes(...).AddOne(ctx)` — fluent builder
- `factory.Gauge(...)`, `factory.Histogram(...)` follow the same pattern
- For tests / nil-meter fallback: `metrics.NewNopFactory()`
- Histograms auto-select default buckets based on name substring (`latency`/`duration`/`time` → `DefaultLatencyBuckets`)

**Why:** the factory enforces error returns on negative counter values, prevents instrument re-registration, and offers `Builder.WithLabels(map[string]string)` for less-typed call sites. Direct OTel instruments leak nil-meter panics and have no shared cache.

**Evidence grep:**
```
grep -rn "otel\.Meter\|meter\.Int64Counter\|meter\.Int64Histogram\|meter\.Int64Gauge" --include="*.go" | grep -v lib-observability
```

### Angle 3: Hand-rolled environment-aware logger config

**Severity:** MEDIUM
**Migration Complexity:** simple

**DIY Patterns to Detect:**
- Service code branching on `os.Getenv("ENV")` / `os.Getenv("APP_ENV")` to pick logger encoding (JSON vs console)
- Service-owned LOG_LEVEL parsing (`zapcore.Level.Set`, `slog.Level.UnmarshalText`)
- Custom encoder configs (`zapcore.EncoderConfig{...}`) repeated per service
- Manual `EncodeLevel` / `EncodeTime` / `TimeKey` configuration
- Service-defined `Environment` enums shadowing what lib-observability already ships

**lib-observability Replacement:**
- `zap.Config{Environment: zap.EnvironmentLocal | EnvironmentDevelopment | EnvironmentStaging | EnvironmentUAT | EnvironmentProduction}` covers all five Lerian environments
- `Level` accepts "debug"/"info"/"warn"/"error" or empty (falls back to `LOG_LEVEL` env var, then environment default)
- `LOG_ENCODING` env override (`json` / `console`) is read by the library

**Why:** every Lerian service runs in the same five environments. Re-deriving the matrix per service is duplication that drifts; lib-observability/zap is the canonical source.

**Evidence grep:**
```
grep -rn "zapcore\.EncoderConfig\|zap\.NewProductionConfig\|zap\.NewDevelopmentConfig\|os\.Getenv(\"LOG_LEVEL\"\|os\.Getenv(\"APP_ENV\"" --include="*.go"
```

### Angle 4: Hand-rolled sensitive-field redaction

**Severity:** HIGH (security)
**Migration Complexity:** simple

**DIY Patterns to Detect:**
- Inline `strings.Contains(field, "password")` / `strings.Contains(field, "token")` checks before logging
- Regex-based field masking (`regexp.MustCompile("(?i)(password|token|secret)")`)
- Custom redaction maps (`var sensitiveKeys = map[string]bool{...}`) duplicating lib-observability's defaults
- String `Replace` chains that mask values before structured logging
- `if strings.HasSuffix(key, "_secret")` boundary checks done by hand
- Service-defined `[REDACTED]` / `***` placeholder constants

**lib-observability Replacement:**
- `redaction.IsSensitiveField(fieldName)` — case-insensitive, camelCase-aware, word-boundary aware
- Variadic extra fields: `redaction.IsSensitiveField(name, "internal_secret", "company_pin")`
- `redaction.DefaultSensitiveFields()` to inspect the default list
- `constants.ObfuscatedValue` (`"********"`) as the canonical placeholder

**Why:** the default list covers 70+ credentials/PII/financial identifiers (PAN, IBAN, SWIFT, SSN, MFA codes, etc.). DIY checks miss camelCase (`sessionToken` → `session_token`), short-token false positives (`monkey` shouldn't match `key`), and PII categories beyond credentials. Audit-grade correctness must be centralized.

**Evidence grep:**
```
grep -rEn "strings\.Contains.*(password|token|secret|key)|regexp.*([Pp]assword|[Tt]oken|[Ss]ecret)|REDACTED" --include="*.go" | grep -v _test.go
```

### Angle 5: Hard-coded OTel attribute / metric / event names

**Severity:** MEDIUM
**Migration Complexity:** trivial

**DIY Patterns to Detect:**
- String literals for OTel semantic conventions:
  - `"db.system"`, `"db.name"`, `"db.mongodb.collection"`
  - `"http.method"`, `"http.status_code"` (when matching what lib-observability already exposes)
- Hard-coded database system identifiers: `"postgresql"`, `"mongodb"`, `"redis"`, `"rabbitmq"`
- Hard-coded panic/assertion telemetry: `"panic_recovered_total"`, `"assertion_failed_total"`, `"panic.recovered"`, `"assertion.failed"`
- Inline attribute prefixes: `"app.request."`, `"assertion."`, `"panic."`
- Metric label truncation done by hand (`if len(label) > 64 { label = label[:64] }`) — breaks on multibyte UTF-8

**lib-observability Replacement:**
- `constants.AttrDBSystem`, `constants.AttrDBName`, `constants.AttrDBMongoDBCollection`
- `constants.DBSystemPostgreSQL`, `constants.DBSystemMongoDB`, `constants.DBSystemRedis`, `constants.DBSystemRabbitMQ`
- `constants.MetricPanicRecoveredTotal`, `constants.MetricAssertionFailedTotal`
- `constants.EventPanicRecovered`, `constants.EventAssertionFailed`
- `constants.AttrPrefixAppRequest`, `constants.AttrPrefixAssertion`, `constants.AttrPrefixPanic`
- `constants.SanitizeMetricLabel(value)` — rune-aware truncation at `MaxMetricLabelLength` (64)
- Header constants: `constants.HeaderTraceparent`, `constants.MetadataTraceparent`, `constants.MetadataTracestate`

**Why:** typos in attribute keys silently break dashboards. Constants make breakage compile-time. The `SanitizeMetricLabel` helper is rune-safe — naive `value[:64]` can split a UTF-8 codepoint and produce invalid OTel labels.

**Evidence grep:**
```
grep -rEn "\"db\.system\"|\"db\.name\"|\"http\.method\"|\"postgresql\"|\"mongodb\"|panic_recovered_total|assertion_failed_total" --include="*.go" | grep -v lib-observability
```

## Phase 3: Consolidated Report

Dispatch synthesizer (`subagent_type: ring:codebase-explorer`):

```
Read /tmp/version-report.json and /tmp/libobs-sweep-*.json (5 files).
Emit:
1. /tmp/libobs-sweep-report.md — aggregate findings grouped by severity (HIGH → MEDIUM → LOW)
2. /tmp/libobs-sweep-tasks.json — one task per DIY pattern cluster (same file/package = one task)

MUST NOT invent findings. MUST NOT omit explorer findings. MUST NOT reclassify severity
without justification. Each task carries the angle number, replacement API, and evidence
snippet so ring:running-dev-cycle can execute without re-discovery.
```

Surface report path + task count to user; offer handoff to `ring:running-dev-cycle`.

---

# REFERENCE MODE

Module: `github.com/LerianStudio/lib-observability` @ `v1.1.0`
Go: `1.25.9` | OTel: `1.43.0` / `log v0.19.0` | zap: `1.28.0`

## Package Index

| Package | Import path | One-line purpose |
|---|---|---|
| `log` | `github.com/LerianStudio/lib-observability/log` | Implementation-agnostic Logger interface, typed Fields, CWE-117-safe GoLogger, NopLogger |
| `metrics` | `github.com/LerianStudio/lib-observability/metrics` | Thread-safe OTel metric factory with fluent builders and lazy instrument cache |
| `zap` | `github.com/LerianStudio/lib-observability/zap` | Environment-aware zap Logger that implements `log.Logger`, with otelzap trace correlation |
| `redaction` | `github.com/LerianStudio/lib-observability/redaction` | Sensitive field detection (camelCase + word-boundary aware) |
| `constants` | `github.com/LerianStudio/lib-observability/constants` | OTel attribute / metric / event / header name constants + label sanitizer |

Cross-link packages (covered elsewhere):
- `assert/` → [[using-assert]]
- `runtime/` → [[using-runtime]]
- `tracing/` → [[using-tracing]]

---

## `log` — Logger interface

```go
type Logger interface {
    Log(ctx context.Context, level Level, msg string, fields ...Field)
    With(fields ...Field) Logger
    WithGroup(name string) Logger
    Enabled(level Level) bool
    Sync(ctx context.Context) error
}
```

### Levels

Lower numeric value = higher severity (inverted from slog/zap): `LevelError=0`, `LevelWarn=1`, `LevelInfo=2`, `LevelDebug=3`. Setting a logger's `Level` to `LevelInfo` enables Error+Warn+Info, suppresses Debug. `LevelUnknown=255`. `ParseLevel(s string) (Level, error)` parses `"debug"|"info"|"warn"|"error"`.

### Field constructors

```go
log.String(key, value string) Field
log.Int(key string, value int) Field
log.Bool(key string, value bool) Field
log.Err(err error) Field              // key is always "error"
log.Any(key string, value any) Field  // bypasses type-driven sanitization — use sparingly
```

### Implementations

```go
goLogger := &log.GoLogger{Level: log.LevelInfo} // stdlib-backed, CWE-117 sanitized
nop := log.NewNop()                              // no-op
```

`GoLogger` redacts sensitive field *keys* via `redaction.IsSensitiveField` (value becomes `"[REDACTED]"`) and escapes `\n`, `\r`, `\t`, `\x00` in keys, string values, and the message.

### Idiomatic usage

```go
logger.Log(ctx, log.LevelInfo, "account created",
    log.String("account_id", id),
    log.String("tenant_id", tenant),
    log.Err(err),
)
childLogger := logger.With(log.String("request_id", reqID))
groupLogger := logger.WithGroup("billing")
```

`Sync(ctx)` is a no-op for `GoLogger`/`NopLogger`. The zap adapter honours `ctx` cancellation and uses `runtime.HandlePanicValue` to keep flush panics observable.

---

## `zap` — Production logger

```go
type Config struct {
    Environment     Environment // EnvironmentLocal | Development | Staging | UAT | Production
    Level           string      // "debug"|"info"|"warn"|"error"; empty falls back to $LOG_LEVEL then env default
    OTelLibraryName string      // required; identifies the logger in OTel resource attrs
}

func New(cfg Config) (*Logger, error)
```

`*zap.Logger` implements `log.Logger`. Construction wraps the zap core in `otelzap.NewCore(OTelLibraryName)` so every entry also flows through the OTel Logs SDK.

### Environments

| Constant | Encoding default | Level default | Caller info |
|---|---|---|---|
| `EnvironmentLocal` | `console` (colored) | `debug` | yes |
| `EnvironmentDevelopment` | `console` (colored) | `debug` | yes |
| `EnvironmentStaging` | `json` | `info` | yes |
| `EnvironmentUAT` | `json` | `info` | yes |
| `EnvironmentProduction` | `json` | `info` | yes |

Override via `LOG_ENCODING` env (`json` or `console`) and `LOG_LEVEL` env (`debug`/`info`/`warn`/`error`).

### Trace correlation

Every `Log(ctx, ...)` call inspects `trace.SpanFromContext(ctx)`. If the span context is valid, `trace_id` and `span_id` fields are appended automatically.

### Idiomatic usage

```go
import "github.com/LerianStudio/lib-observability/zap"

logger, err := zap.New(zap.Config{
    Environment:     zap.EnvironmentProduction,
    Level:           "info",
    OTelLibraryName: "midaz-ledger",
})
if err != nil {
    return nil, fmt.Errorf("logger init: %w", err)
}
defer func() { _ = logger.Sync(ctx) }()

logger.Log(ctx, log.LevelInfo, "service started", log.String("version", buildVersion))

// Runtime level adjustment (hot reload via systemplane)
logger.Level().SetLevel(zapcore.DebugLevel)

// Direct zap fields for hot paths
logger.WithZapFields(zap.String("hot", "path")).Info("fast log")
```

The Logger also exposes typed helpers (`Debug`, `Info`, `Warn`, `Error`) that take `zap.Field` directly — use these only where the call site is performance-critical and you don't need the `ctx`-driven trace injection.

---

## `metrics` — Factory + builders

```go
type Metric struct {
    Name        string
    Description string
    Unit        string
    Buckets     []float64 // histograms only; auto-selected if nil
}

func NewMetricsFactory(meter metric.Meter, logger log.Logger) (*MetricsFactory, error)
func NewNopFactory() *MetricsFactory // OTel noop meter — safe fallback
```

### Builder API

```go
factory.Counter(m Metric) (*CounterBuilder, error)
factory.Gauge(m Metric)   (*GaugeBuilder, error)
factory.Histogram(m Metric) (*HistogramBuilder, error)
```

All three builders share:
- `WithLabels(map[string]string)` — converts to `attribute.String` set
- `WithAttributes(...attribute.KeyValue)` — typed OTel attributes
- Both return new builders (immutable composition)

Terminal ops:

```go
counter.Add(ctx, value int64) error  // ErrNegativeCounterValue if value < 0
counter.AddOne(ctx) error

gauge.Set(ctx, value int64) error

histogram.Record(ctx, value int64) error
```

### Auto-bucket selection (histograms)

If `Metric.Buckets` is nil, the factory inspects the metric name:

| Substring in name | Bucket set |
|---|---|
| `latency`, `duration`, `time` | `DefaultLatencyBuckets` (0.001s … 10s, 12 buckets) |
| `account` | `DefaultAccountBuckets` (1 … 5000, count) |
| `transaction` | `DefaultTransactionBuckets` (1 … 10000, count) |
| (default) | `DefaultLatencyBuckets` |

### Pre-configured domain metrics + recorders

```go
metrics.MetricAccountsCreated              // counter
metrics.MetricTransactionsProcessed        // counter
metrics.MetricTransactionRoutesCreated     // counter
metrics.MetricOperationRoutesCreated       // counter
metrics.MetricSystemCPUUsage               // gauge ("percentage" unit)
metrics.MetricSystemMemUsage               // gauge ("percentage" unit)

// One-liners:
factory.RecordAccountCreated(ctx, attrs...)
factory.RecordTransactionProcessed(ctx, attrs...)
factory.RecordTransactionRouteCreated(ctx, attrs...)
factory.RecordOperationRouteCreated(ctx, attrs...)
factory.RecordSystemCPUUsage(ctx, percentage int64) // ErrPercentageOutOfRange if not in [0,100]
factory.RecordSystemMemUsage(ctx, percentage int64)
```

### Sentinel errors

`ErrNilMeter`, `ErrNilFactory`, `ErrNegativeCounterValue`, `ErrPercentageOutOfRange`, `ErrNilCounter`, `ErrNilGauge`, `ErrNilHistogram`, `ErrNilCounterBuilder`, `ErrNilGaugeBuilder`, `ErrNilHistogramBuilder`. All methods return errors on nil receivers — no panics, ever.

### Idiomatic usage

```go
factory, err := metrics.NewMetricsFactory(meter, logger)
if err != nil {
    return fmt.Errorf("metrics factory: %w", err)
}

counter, err := factory.Counter(metrics.Metric{
    Name:        "ledger_postings_total",
    Description: "Total ledger postings processed",
    Unit:        "1",
})
if err != nil {
    return err
}

if err := counter.WithAttributes(
    attribute.String("tenant_id", tenant),
    attribute.String("status", "success"),
).AddOne(ctx); err != nil {
    logger.Log(ctx, log.LevelWarn, "counter add failed", log.Err(err))
}
```

---

## `redaction` — Sensitive field detection

```go
func IsSensitiveField(fieldName string, extra ...string) bool
func DefaultSensitiveFields() []string          // clone of default list
func DefaultSensitiveFieldsMap() map[string]bool // clone of cached lookup
```

### Detection rules

1. Case-insensitive exact match against the default list (70+ entries spanning credentials, PII, financial identifiers, MFA, security questions, biometrics).
2. camelCase / PascalCase normalization: `sessionToken` → `session_token`, `APIKey` → `api_key`.
3. Word-boundary substring match for long tokens (`password`, `secret`, `token`, `credential`, `email`, `phone`, …).
4. Exact-token match for short / generic tokens (`key`, `auth`, `pin`, `otp`, `cvv`, `cvc`, `ssn`, `pan`, `bic`, `bsb`, `dob`, `tin`, `jwt`, `zip`, `city`) — prevents false positives like `monkey` matching `key`.
5. `extra` parameter extends the list at call site without mutating shared state.

### Categories covered

Credentials (password, token, secret, api_key, jwt, bearer, session_id, cookie, private_key, client_secret, mfa_code, totp, otp), cards (card_number, cvv, cvc, pan, expiry_date), financial (account_number, routing_number, iban, swift, bic, sort_code, bsb), government IDs (ssn, tax_id, tin, national_id), PII (email, phone, address, street, city, zip, postal_code, date_of_birth, mother_maiden_name), biometric, connection strings (connection_string, database_url, certificate). Full list via `DefaultSensitiveFields()`.

### Idiomatic usage

```go
if redaction.IsSensitiveField(key) {
    value = constants.ObfuscatedValue // "********"
}

// Extend with service-specific fields
if redaction.IsSensitiveField(key, "internal_routing_id", "partner_secret") {
    value = constants.ObfuscatedValue
}
```

The `log.GoLogger` and `zap.Logger` already apply this check to every `Field` before emitting — manual redaction is only needed at the *value* layer (e.g., sanitizing a struct before logging it as `Any`).

---

## `constants` — Shared OTel names

### Resource

```go
TelemetrySDKName = "lib-observability/tracing"
MaxMetricLabelLength = 64
SanitizeMetricLabel(value string) string // rune-aware truncation
```

### Attribute prefixes

```go
AttrPrefixAppRequest = "app.request."
AttrPrefixAssertion  = "assertion."
AttrPrefixPanic      = "panic."
```

### Database attributes (OTel semantic conventions)

```go
AttrDBSystem            = "db.system"
AttrDBName              = "db.name"
AttrDBMongoDBCollection = "db.mongodb.collection"

DBSystemPostgreSQL = "postgresql"
DBSystemMongoDB    = "mongodb"
DBSystemRedis      = "redis"
DBSystemRabbitMQ   = "rabbitmq"
```

### Metric names

```go
MetricPanicRecoveredTotal  = "panic_recovered_total"  // emitted by runtime package
MetricAssertionFailedTotal = "assertion_failed_total" // emitted by assert package
```

### Span event names

```go
EventAssertionFailed = "assertion.failed"
EventPanicRecovered  = "panic.recovered"
```

### Headers + misc

```go
HeaderTraceparent, HeaderTraceparentPascal, HeaderTracestatePascal // W3C HTTP
MetadataTraceparent, MetadataTracestate                            // gRPC (lowercase)
ObfuscatedValue        = "********"
LoggerDefaultSeparator = " | "
```

### Idiomatic usage

```go
span.SetAttributes(
    attribute.String(constants.AttrDBSystem, constants.DBSystemPostgreSQL),
    attribute.String(constants.AttrDBName, "ledger"),
)

counter, _ := factory.Counter(metrics.Metric{
    Name: constants.MetricPanicRecoveredTotal,
    Unit: "1",
})

// Rune-safe truncation for cardinality control
label := constants.SanitizeMetricLabel(rawValue)
```

---

## Cross-skill map

| If you need… | Skill |
|---|---|
| Panic recovery, SafeGo, `runtime/` package | [[using-runtime]] |
| Production assertions, `assert/` package | [[using-assert]] |
| OTel tracer setup, span processors, `tracing/` package | [[using-tracing]] |
| Database / messaging / HTTP toolkit beyond observability | [[using-lib-commons]] |
| Outbox pattern (uses lib-observability for emission telemetry) | [[using-outbox]] |
| Event emission to per-tenant SaaS subscribers | [[using-lib-streaming]] |
| Hot-reloadable runtime config (consumes lib-observability/log) | [[using-lib-systemplane]] |

This library is the foundation: lib-commons v5, lib-systemplane, and lib-streaming all
depend on it. If you migrate a service to lib-observability/log, downstream lib-commons
adoption becomes a drop-in — the same `log.Logger` interface threads through every layer.
