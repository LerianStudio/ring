---
name: ring:using-tracing
description: Dual-mode skill for github.com/LerianStudio/lib-observability/tracing — OpenTelemetry SDK lifecycle, trace context propagation across HTTP/gRPC/queues, span error and event recording, and struct-to-attribute conversion with PII redaction. Sweep Mode dispatches parallel explorers to find raw OTEL setup, hand-rolled header propagation, manual span attribute assembly, DIY redaction, and untraced boundaries. Reference Mode catalogs the API (Telemetry, TelemetryConfig, Redactor, propagation helpers, span handlers). Skip for non-Go services or frontend code.
---

# ring:using-tracing

## When to use
Sweep mode:
- "Sweep / audit tracing setup"
- "Find raw OpenTelemetry usage we should replace"
- "Are our HTTP/gRPC boundaries propagating trace context?"
- "Is there DIY field redaction in spans?"
- "Migrate this service to lib-observability/tracing"

Reference mode:
- "How do I bootstrap Telemetry for a new service?"
- "Which Inject/Extract helper do I use for X transport?"
- "How does the Redactor pipeline work?"
- "How do I record a business-error event on a span?"
- "What does RedactingAttrBagSpanProcessor do?"

## Skip when
- Working on non-Go services
- Working on frontend code
- Target codebase does not depend on `github.com/LerianStudio/lib-observability`

## Related
**Parent:** ring:using-lib-observability
**Similar:** ring:using-runtime, ring:using-assert, ring:using-lib-commons

The `tracing` subpackage owns OTEL provider lifecycle, trace context propagation, span helpers,
and the attribute-redaction pipeline (`RedactingAttrBagSpanProcessor` is wired automatically
inside `NewTelemetry`). Use this skill when tracing is the primary concern. For broader
lib-observability sweeps (logging, metrics, panic recovery), invoke `ring:using-lib-observability`.

## Mode Selection

| Request Shape | Mode |
|---|---|
| "Sweep / audit tracing / find raw OTEL / find untraced boundaries" | **Sweep** |
| "How do I bootstrap Telemetry?" | **Reference** |
| "Inject/Extract helper for HTTP/gRPC/queue?" | **Reference** |
| "How does Redactor / span processor work?" | **Reference** |

---

# SWEEP MODE

5-phase sweep. Each phase has a hard gate — do not proceed until the current phase produces its artifact.

```
Phase 1: Version Reconnaissance   → tracing-version-report.json
Phase 2: CHANGELOG Delta Analysis → tracing-delta-report.json
Phase 3: Multi-Angle DIY Sweep    → 6 × tracing-sweep-{N}-{angle}.json
Phase 4: Consolidated Report      → tracing-sweep-report.md + tracing-sweep-tasks.json
Phase 5: Handoff                  → offer ring:dev-cycle dispatch
```

## Phase 1: Version Reconnaissance

1. Read `go.mod` — extract pinned version of `github.com/LerianStudio/lib-observability`
2. WebFetch `https://api.github.com/repos/LerianStudio/lib-observability/releases/latest` — extract `tag_name`
3. Classify drift: up-to-date / minor-drift / moderate-drift / major-upgrade / not-imported
4. Emit `/tmp/tracing-version-report.json`: `{pinned_version, latest_version, drift_classification, module_path}`

## Phase 2: CHANGELOG Delta Analysis

1. WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-observability/main/CHANGELOG.md`
2. Filter entries affecting `tracing/` (otel.go, obfuscation.go, processor.go)
3. Emit `/tmp/tracing-delta-report.json` with classified entries (`new-api` / `breaking-change` / `security-fix` / `bugfix`)

## Phase 3: Multi-Angle DIY Sweep

### ⛔ STOP-CHECK BEFORE DISPATCH

Before emitting any Task call, count the explorers you intend to launch in this turn.
- Count MUST equal 6.
- If count < 6 → STOP. Do not partial-dispatch. Reconcile against the 6 angles below and try again.
- The 6 angles are the canonical sweep. No substitutions, no omissions.

### ⛔ MUST NOT trickle-dispatch

All 6 explorers leave in the SAME TURN, before reading any explorer output.

Forbidden sequences:
- Dispatch explorer 1 → read result → dispatch explorer 2
- Dispatch a subset → wait → dispatch the rest
- Dispatch follow-up explorers conditioned on partial output
- Loop sequentially over the angle list

If you find yourself about to dispatch an explorer in a turn AFTER any explorer has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the phase INCOMPLETE rather than completing the trickle.

### Self-verify after dispatch

After the dispatch turn, verify all 6 Task calls were emitted in that single turn. If fewer than 6 went out, the phase did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial pool.

### Parallel dispatch — atomic batch

Emit all 6 Task calls in a SINGLE TURN, as one atomic batch.

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete pool in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.

Dispatch all 6 explorer angles in **one parallel batch**. Wait for all before Phase 4.

**Per-explorer dispatch** (`subagent_type: ring:codebase-explorer`):

```
## Target: <absolute path to target repo root>
## Your Angle: <angle number + name from below>
## Severity / DIY Patterns / Replacement / Migration Complexity
<verbatim from angle table below>

## Output
Write to: /tmp/tracing-sweep-{N}-{angle-slug}.json
Schema: { angle_number, angle_name, severity, migration_complexity,
  findings: [{file, line, diy_pattern, replacement, evidence_snippet, notes}],
  summary }
If no findings: write file with empty findings array.
```

### The 6 Angles

| # | Angle | Severity | DIY Pattern | Replacement |
|---|---|---|---|---|
| 1 | Raw OTEL TracerProvider bootstrap | CRITICAL | `sdktrace.NewTracerProvider(...)` assembled by hand; `otel.SetTracerProvider(...)` called directly in service init | `tracing.NewTelemetry(cfg)` + `tl.ApplyGlobals()` |
| 2 | Hand-rolled HTTP header propagation | HIGH | Manual `req.Header.Set("traceparent", ...)` / `r.Header.Get("traceparent")` / custom carrier types | `tracing.InjectHTTPContext(ctx, req.Header)` / `tracing.ExtractHTTPContext(ctx, c)` |
| 3 | Hand-rolled gRPC / queue propagation | HIGH | Custom metadata copy for `traceparent`/`tracestate`; AMQP headers serialized by hand | `tracing.InjectGRPCContext` / `ExtractGRPCContext` / `PrepareQueueHeaders` / `ExtractTraceContextFromQueueHeaders` |
| 4 | Manual span attribute assembly from structs | MEDIUM | Looping over struct fields calling `span.SetAttributes(attribute.String(...))`; nested JSON flattening reinvented per service | `tracing.SetSpanAttributesFromValue(span, prefix, v, redactor)` / `BuildAttributesFromValue` |
| 5 | DIY field redaction before tracing | CRITICAL | Service-local `maskPassword(s)` / `redactToken(s)` helpers; sensitive-field lists duplicated outside `redaction` package; hand-written regex masking inside span hot path | `tracing.NewDefaultRedactor()` (or `NewRedactor(rules, mask)`) plumbed through `TelemetryConfig.Redactor` |
| 6 | Untraced HTTP/DB/Kafka boundaries | HIGH | Outbound HTTP clients, DB drivers, or queue publishers with no span around the call; missing `HandleSpanError`/`HandleSpanBusinessErrorEvent` on the error path | Wrap call with `tracer.Start(ctx, "op")` + `defer span.End()`; record errors via `tracing.HandleSpanError(span, msg, err)` |

**Severity calibration**

- CRITICAL: hides production failures or leaks PII (angles 1, 5)
- HIGH: breaks distributed traces or omits whole subsystems (angles 2, 3, 6)
- MEDIUM: duplicates library code; loud but correctable later (angle 4)

## Phase 4: Consolidated Report

Dispatch synthesizer (`subagent_type: ring:codebase-explorer`):

```
Read /tmp/tracing-version-report.json, /tmp/tracing-delta-report.json,
and /tmp/tracing-sweep-*.json (6 files).

Emit:
1. /tmp/tracing-sweep-report.md — findings grouped by severity, cross-referenced to angle table
2. /tmp/tracing-sweep-tasks.json — one task per DIY pattern cluster (same file/package = one task)

MUST NOT invent findings. MUST NOT omit explorer findings. MUST NOT reclassify severity without justification.
```

## Phase 5: Handoff

Surface report path + task count to the caller. Offer handoff to `ring:dev-cycle` for execution.

---

# REFERENCE MODE

Import path: `github.com/LerianStudio/lib-observability/tracing`

The package owns four concerns:

1. **Lifecycle** — build OTEL providers and shut them down cleanly
2. **Propagation** — move trace context across HTTP, gRPC, and message queues
3. **Span helpers** — record errors, events, and struct-derived attributes
4. **Redaction** — strip sensitive fields before they reach the collector

## 1. Lifecycle: `Telemetry` and `TelemetryConfig`

```go
type TelemetryConfig struct {
    LibraryName               string
    ServiceName               string
    ServiceVersion            string
    DeploymentEnv             string                            // "production" | "staging" | "development" | "local"
    CollectorExporterEndpoint string                            // "otel-collector:4317" — scheme stripped automatically
    EnableTelemetry           bool
    InsecureExporter          bool                              // forbidden in production unless ALLOW_INSECURE_OTEL is set
    Logger                    log.Logger                        // required; nil returns ErrNilTelemetryLogger
    Propagator                propagation.TextMapPropagator     // defaults to TraceContext + Baggage composite
    Redactor                  *Redactor                         // defaults to NewDefaultRedactor()
}

type Telemetry struct {
    TelemetryConfig
    TracerProvider *sdktrace.TracerProvider
    MeterProvider  *sdkmetric.MeterProvider
    LoggerProvider *sdklog.LoggerProvider
    MetricsFactory *metrics.MetricsFactory
    // shutdown handlers are unexported; use ShutdownTelemetry* methods
}

func NewTelemetry(cfg TelemetryConfig) (*Telemetry, error)
func (tl *Telemetry) ApplyGlobals() error
func (tl *Telemetry) Tracer(name string) (trace.Tracer, error)
func (tl *Telemetry) Meter(name string) (metric.Meter, error)
func (tl *Telemetry) ShutdownTelemetry()
func (tl *Telemetry) ShutdownTelemetryWithContext(ctx context.Context) error
```

### Bootstrap pattern

```go
tl, err := tracing.NewTelemetry(tracing.TelemetryConfig{
    LibraryName:               "my-service",
    ServiceName:               cfg.ServiceName,
    ServiceVersion:            cfg.Version,
    DeploymentEnv:             cfg.Env,
    CollectorExporterEndpoint: cfg.OTELEndpoint,   // "otel-collector:4317" or "http://..."
    EnableTelemetry:           cfg.OTELEnabled,
    Logger:                    logger,
})
if err != nil {
    return fmt.Errorf("init telemetry: %w", err)
}
if err := tl.ApplyGlobals(); err != nil {
    return fmt.Errorf("apply globals: %w", err)
}
defer func() {
    if err := tl.ShutdownTelemetryWithContext(context.Background()); err != nil {
        logger.Log(ctx, log.LevelError, "telemetry shutdown failed", log.Err(err))
    }
}()
```

### Sentinel errors

| Error | Trigger |
|---|---|
| `ErrNilTelemetryLogger` | `TelemetryConfig.Logger == nil` |
| `ErrEmptyEndpoint` | `EnableTelemetry=true` with empty `CollectorExporterEndpoint`; noop providers are installed but the call still returns this error so callers can decide whether to abort |
| `ErrNilTelemetry` | method called on nil `*Telemetry` |
| `ErrNilShutdown` | shutdown invoked but no shutdown function configured (corrupted state) |
| `ErrNilProvider` | `ApplyGlobals` called when `TracerProvider`/`MeterProvider`/`Propagator` is nil |

### Endpoint and security rules

- `http://host:4317` → scheme stripped, `InsecureExporter` forced to `true`
- `https://host:4317` → scheme stripped, secure exporter
- `host:4317` (no scheme) → treated as insecure (common in cluster-internal traffic)
- `InsecureExporter=true` in `production`/`prod` env aborts with an error unless `ALLOW_INSECURE_OTEL` is set with a justification — do not bypass this lightly

### Disabled / empty-endpoint fallback

When `EnableTelemetry=false` or the endpoint is empty, `NewTelemetry` installs no-op providers and `ApplyGlobals` ensures downstream libraries (e.g. `otelfiber`) do not spawn real gRPC exporters that leak goroutines. Code paths above the API stay unchanged.

## 2. Propagation Helpers

All helpers are nil-safe and use the globally configured `TextMapPropagator`.

### HTTP

```go
func InjectHTTPContext(ctx context.Context, headers http.Header)
func ExtractHTTPContext(ctx context.Context, c *fiber.Ctx) context.Context
func InjectTraceContext(ctx context.Context, carrier propagation.TextMapCarrier)
func ExtractTraceContext(ctx context.Context, carrier propagation.TextMapCarrier) context.Context
```

Outbound client:

```go
req, _ := http.NewRequestWithContext(ctx, http.MethodPost, url, body)
tracing.InjectHTTPContext(ctx, req.Header)
resp, err := httpClient.Do(req)
```

Inbound Fiber handler:

```go
func handler(c *fiber.Ctx) error {
    ctx := tracing.ExtractHTTPContext(c.UserContext(), c)
    c.SetUserContext(ctx)
    // ...
}
```

For non-Fiber HTTP servers, build a `propagation.HeaderCarrier` from `r.Header` and call `ExtractTraceContext`.

### gRPC

```go
func InjectGRPCContext(ctx context.Context, md metadata.MD) metadata.MD
func ExtractGRPCContext(ctx context.Context, md metadata.MD) context.Context
```

The gRPC helpers normalize `Traceparent`/`Tracestate` header casing — gRPC metadata is lowercase by spec, but some interceptors emit Pascal case. The helpers translate both ways. Do not reinvent this.

### Message queues (AMQP / Kafka / generic string-headers)

```go
func InjectQueueTraceContext(ctx context.Context) map[string]string
func ExtractQueueTraceContext(ctx context.Context, headers map[string]string) context.Context
func PrepareQueueHeaders(ctx context.Context, baseHeaders map[string]any) map[string]any
func InjectTraceHeadersIntoQueue(ctx context.Context, headers *map[string]any)
func ExtractTraceContextFromQueueHeaders(baseCtx context.Context, amqpHeaders map[string]any) context.Context
```

Publisher (RabbitMQ AMQP-style):

```go
headers := tracing.PrepareQueueHeaders(ctx, map[string]any{"x-event-type": "user.created"})
err := channel.Publish(exchange, key, false, false, amqp.Publishing{Headers: headers, Body: payload})
```

Consumer:

```go
ctx = tracing.ExtractTraceContextFromQueueHeaders(ctx, delivery.Headers)
ctx, span := tracer.Start(ctx, "consume.user.created")
defer span.End()
```

### Reading IDs out of context

```go
traceID := tracing.GetTraceIDFromContext(ctx)     // "" if no valid span
state   := tracing.GetTraceStateFromContext(ctx)
```

Use these for log correlation. Never parse `traceparent` headers by hand to recover the trace ID.

## 3. Span Helpers

```go
func HandleSpanError(span trace.Span, message string, err error)
func HandleSpanBusinessErrorEvent(span trace.Span, eventName string, err error)
func HandleSpanEvent(span trace.Span, eventName string, attributes ...attribute.KeyValue)
func SetSpanAttributesFromValue(span trace.Span, prefix string, value any, r *Redactor) error
func BuildAttributesFromValue(prefix string, value any, r *Redactor) ([]attribute.KeyValue, error)
func SetSpanAttributeForParam(c *fiber.Ctx, param, value, entityName string)
```

All helpers are nil-safe on the span argument (untyped nil and interface-wrapped typed nil both handled). Error messages are sanitized: bearer/basic tokens stripped and the message is truncated to 1024 bytes with valid-UTF-8 enforcement.

| Helper | Use when |
|---|---|
| `HandleSpanError` | Operation failed; mark span as failed (`codes.Error`) and record the error |
| `HandleSpanBusinessErrorEvent` | Domain rule rejected the request but the operation itself succeeded technically (e.g. balance insufficient) — adds an event without flipping the span to error |
| `HandleSpanEvent` | Generic milestone event with attributes (e.g. `cache.hit`, `retry.attempt`) |
| `SetSpanAttributesFromValue` | Flatten a struct/map into span attributes with redaction applied; bounded by 128 attributes and depth 32 |
| `BuildAttributesFromValue` | Same flattening but returns the attribute slice instead of writing to a span |
| `SetSpanAttributeForParam` | Fiber-specific: attach a request parameter to the context-scoped attribute bag, masking sensitive names |

Idiomatic span lifecycle:

```go
ctx, span := tracer.Start(ctx, "ledger.PostTransaction")
defer span.End()

if err := tracing.SetSpanAttributesFromValue(span, "request", req, tl.Redactor); err != nil {
    tracing.HandleSpanEvent(span, "attr.serialize.failed", attribute.String("error", err.Error()))
}

result, err := svc.Post(ctx, req)
if errors.Is(err, ErrInsufficientBalance) {
    tracing.HandleSpanBusinessErrorEvent(span, "business.balance_insufficient", err)
    return err
}
if err != nil {
    tracing.HandleSpanError(span, "post transaction", err)
    return err
}
```

## 4. Redaction

```go
type RedactionAction string  // "mask" | "hash" | "drop"

type RedactionRule struct {
    FieldPattern string  // regex matched against field name
    PathPattern  string  // regex matched against dotted path
    Action       RedactionAction
}

type Redactor struct{ /* unexported */ }

func NewDefaultRedactor() *Redactor                            // default sensitive-field list, action = mask
func NewAlwaysMaskRedactor() *Redactor                         // fail-safe; masks every field
func NewRedactor(rules []RedactionRule, mask string) (*Redactor, error)
func ObfuscateStruct(value any, r *Redactor) (any, error)
```

### Pipeline

1. `NewTelemetry` defaults `cfg.Redactor` to `NewDefaultRedactor()` if nil
2. The tracer provider is built with `RedactingAttrBagSpanProcessor{Redactor: cfg.Redactor}` — every span gets request-scoped attributes from `observability.AttributesFromContext` filtered through redaction
3. `SetSpanAttributesFromValue` invokes `ObfuscateStruct` before flattening, so struct-derived attributes inherit the same rules

### Custom rules

```go
r, err := tracing.NewRedactor([]tracing.RedactionRule{
    {FieldPattern: `(?i)^card_number$`, Action: tracing.RedactionDrop},
    {FieldPattern: `(?i)^email$`,        Action: tracing.RedactionHash},
    {PathPattern:  `^request\.headers\.authorization$`, Action: tracing.RedactionMask},
}, "[REDACTED]")
if err != nil {
    return err
}
cfg.Redactor = r
```

- `mask` replaces the value with the configured mask string
- `hash` produces `sha256:<hex>` using a per-instance HMAC key (so identical inputs in different processes produce different hashes — anti-rainbow-table)
- `drop` removes the field entirely

### `RedactingAttrBagSpanProcessor`

Custom `sdktrace.SpanProcessor` wired automatically inside `NewTelemetry`. It copies `observability.AttributesFromContext(ctx)` onto every started span and applies redaction by attribute key. Do not register it manually unless you are bypassing `NewTelemetry`.

## 5. Common Anti-Patterns

| Anti-pattern | Fix |
|---|---|
| Calling `otel.SetTracerProvider` directly during init | Use `tl.ApplyGlobals()` — it also wires the meter, logger provider, and propagator atomically |
| Building a `propagation.TraceContext{}` propagator per-call | Configure once on `TelemetryConfig.Propagator`; helpers read `otel.GetTextMapPropagator()` |
| Logging `traceparent` headers verbatim | Use `GetTraceIDFromContext(ctx)` and log the trace ID, not the header |
| Shutting down providers with `tp.Shutdown(ctx)` directly | Use `ShutdownTelemetryWithContext` — it shuts down exporters and providers in the right order and joins errors |
| Adding a custom `SpanProcessor` for redaction | `RedactingAttrBagSpanProcessor` already runs; add rules to the `Redactor` instead |
| Setting `InsecureExporter=true` in production | Either fix the collector to expose TLS, or set `ALLOW_INSECURE_OTEL="<justification>"` with a sunset date — never silently bypass |

## 6. Cross-References

- `[[using-lib-observability]]` — parent skill covering logging, metrics, panic recovery
- `[[using-runtime]]` — panic observability trident; uses tracing's span events for the panic record
- `[[using-assert]]` — production assertions; their `AssertionError` surfaces in spans via `HandleSpanError`
- `[[using-lib-commons]]` — broader Lerian shared-library sweep; Angle "observability DIY" delegates here when tracing-specific
