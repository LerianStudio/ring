## Explorer Angle Specifications

MANDATORY: All 6 angles run on every sweep. The catalog below is the source of truth
for what each explorer looks for. MUST NOT edit angle specs at dispatch time — copy
verbatim into the explorer prompt.

---

#### Angle 1: Naked goroutine launches

**Severity:** CRITICAL

**DIY Patterns to Detect:**
- `go func()` in non-test code not wrapped by `runtime.SafeGo`, `runtime.SafeGoWithContext`, or `runtime.SafeGoWithContextAndComponent`
- `go someFunction(` — bare call-form goroutine launch
- `go method(` — bare method-form goroutine launch
- `go obj.Method(` — bare receiver-method-form goroutine launch
- Goroutines spawned inside HTTP handlers for per-request fan-out without recovery
- Long-lived consumer goroutines (RabbitMQ, Kafka, internal channels) launched raw
- Background workers launched from `init()`, `main()`, or package-level `func` without recovery

**lib-observability Replacement:**
- `runtime.SafeGo(logger, name, policy, fn)` — fire-and-forget with policy
- `runtime.SafeGoWithContext(ctx, logger, name, policy, fn)` — carries ctx into fn
- `runtime.SafeGoWithContextAndComponent(ctx, logger, component, name, policy, fn)` —
  **preferred for long-lived workers**; component label feeds the metric + log + span,
  making panics attributable to the subsystem that spawned them

**Split guidance:**

| Workload                                | Recommended API                                | Policy          |
| --------------------------------------- | ---------------------------------------------- | --------------- |
| HTTP handler per-request fan-out        | `SafeGoWithContext`                            | `KeepRunning`   |
| Long-lived consumer loop (AMQP/Kafka)   | `SafeGoWithContextAndComponent`                | `KeepRunning`   |
| Periodic worker (`time.NewTicker`)      | `SafeGoWithContextAndComponent`                | `KeepRunning`   |
| Bootstrap invariant goroutine           | `SafeGoWithContextAndComponent`                | `CrashProcess`  |

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE): long-lived consumer loop — panic here dies silently
go func() {
    for delivery := range deliveries {
        handleDelivery(delivery) // panic → goroutine dies, consumption stops, nothing logs
    }
}()

// lib-observability (AFTER):
runtime.SafeGoWithContextAndComponent(ctx, logger, "outbound-webhook-consumer",
    "amqp-consumer-loop", runtime.KeepRunning,
    func(ctx context.Context) {
        for delivery := range deliveries {
            handleDelivery(ctx, delivery) // panic → recovered, logged, metric++, span event, optional Sentry
        }
    },
)
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for naked goroutine launches. MUST find every `go func()`,
> `go someFunction(`, `go method(`, and `go obj.Method(` in non-test code that isn't
> wrapped by `runtime.SafeGo`, `runtime.SafeGoWithContext`, or
> `runtime.SafeGoWithContextAndComponent`. For each finding record file:line, the
> goroutine shape (fire-and-forget vs long-lived loop vs request fan-out), and whether
> the surrounding function has a `ctx context.Context` parameter in scope. MUST note the
> recommended API for each finding per the split guidance table (consumer loop →
> SafeGoWithContextAndComponent + KeepRunning; request fan-out → SafeGoWithContext +
> KeepRunning; bootstrap invariant goroutine → CrashProcess). Severity CRITICAL — naked
> goroutine panics are the single highest-signal silent-failure mode in Go services.

---

#### Angle 2: Unobservable `defer recover()`

**Severity:** CRITICAL

**DIY Patterns to Detect:**
- `defer func() { if r := recover(); r != nil { ... } }()` where the recovery branch doesn't
  emit a metric, a structured log with stack, or an OTel span event
- `defer recover()` used as a silencer (recover called, return value discarded) — panic
  is swallowed, nothing surfaces anywhere
- Framework-style recovery (e.g., middleware) that logs via `fmt.Printf` or `log.Println`
  rather than the structured logger, and doesn't increment a metric
- Recovery branches that format `r` into an error and return it without also firing the
  observability trident — the caller sees an error, but dashboards never see the panic

**lib-observability Replacement:**
- `runtime.RecoverWithPolicyAndContext(ctx, logger, component, operation, policy)` —
  preferred: carries ctx so the active span receives the `panic.recovered` event
- `runtime.RecoverWithPolicy(logger, component, operation, policy)` — when no ctx is
  available (rare; almost every call site has one)
- `runtime.HandlePanicValue(ctx, logger, recoveredValue, component, operation)` — when
  the panic was recovered *by a framework* (Fiber, gRPC) and you need to feed the value
  into the trident pipeline manually

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
func createOrder(ctx context.Context, req CreateOrderRequest) (*Order, error) {
    defer func() {
        if r := recover(); r != nil {
            // swallowed — no log, no metric, no span event
            _ = r
        }
    }()
    return processOrder(ctx, req)
}

// lib-observability (AFTER):
func createOrder(ctx context.Context, req CreateOrderRequest) (*Order, error) {
    defer runtime.RecoverWithPolicyAndContext(ctx, logger,
        "order-service", "createOrder", runtime.KeepRunning)
    return processOrder(ctx, req)
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for unobservable `defer recover()` patterns. MUST find every
> `defer func() { if r := recover(); r != nil` (multi-line and single-line variants) and
> `defer recover()` in non-test code. For each, inspect the recovery branch: does it
> call a structured logger with stack trace, emit a span event, and increment a metric?
> If it lacks any of those three, flag it. Record file:line, what the recovery branch
> does (swallows, logs to stdlib, returns error, re-panics), and which component the
> function belongs to. MUST also flag recovery branches that format `r` into an error
> and return it without firing the trident — the error path masks a missing metric.
> Severity CRITICAL — unobserved recoveries make panics invisible in production.

---

#### Angle 3: Missing `InitPanicMetrics` at startup

**Severity:** HIGH

**DIY Patterns to Detect:**
- Service imports and uses `runtime.SafeGo` / `runtime.RecoverWithPolicy*` / 
  `runtime.SafeGoWithContext*` somewhere in the codebase
- Bootstrap package (`main.go`, `cmd/*/main.go`, `internal/bootstrap/`, `internal/app/`)
  has **no call** to `runtime.InitPanicMetrics`
- `InitPanicMetrics` is called with a `nil` factory (e.g., telemetry was disabled but the
  call was left in place — metric registrations silently no-op)
- `InitPanicMetrics` is called **before** telemetry setup completes (factory not yet
  initialized)

**Grep pattern** (two-step detection):
1. `grep -r "runtime.SafeGo\|runtime.RecoverWith" --include="*.go"` → presence
2. `grep -r "runtime.InitPanicMetrics" --include="*.go"` → absence → FINDING

**lib-observability Replacement:**
- Add `runtime.InitPanicMetrics(tl.MetricsFactory, logger)` after telemetry setup,
  before any SafeGo launches — canonical location is right after `tl.ApplyGlobals()`

**Consequence of missing:** Recovered panics are logged and emit span events, but the
`panic_recovered_total` counter is **never emitted** — dashboards show nothing, alerts
never fire. You get half the trident.

**Migration Complexity:** trivial

**Example Transformation:**

```go
// DIY (BEFORE): bootstrap never wires panic metrics
logger, _ := zap.New(zapCfg)
tl, _ := tracing.NewTelemetry(otelCfg)
_ = tl.ApplyGlobals()

// launches SafeGo goroutines — metric never emits because factory not registered
runtime.SafeGoWithContextAndComponent(ctx, logger, "worker", "loop",
    runtime.KeepRunning, workerFn)

// lib-observability (AFTER):
logger, _ := zap.New(zapCfg)
tl, _ := tracing.NewTelemetry(otelCfg)
_ = tl.ApplyGlobals()

runtime.InitPanicMetrics(tl.MetricsFactory, logger)   // <-- wire metrics first
runtime.SetProductionMode(true)

runtime.SafeGoWithContextAndComponent(ctx, logger, "worker", "loop",
    runtime.KeepRunning, workerFn)                     // now the counter fires
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for missing `runtime.InitPanicMetrics` initialization. First,
> confirm the service actually uses `lib-observability/runtime` (or the lib-commons shim) by grep'ing for `runtime.SafeGo`,
> `runtime.RecoverWith`, `runtime.HandlePanicValue`. If the service uses runtime, MUST
> check for a call to `runtime.InitPanicMetrics` in bootstrap files (`main.go`,
> `cmd/*/main.go`, `internal/bootstrap/`, `internal/app/`). If the call is missing,
> flag it. If the call exists but is placed BEFORE telemetry setup or passes `nil` as
> the factory, flag it. Record file:line of the bootstrap sequence and the exact
> position where `InitPanicMetrics` should land (after `tl.ApplyGlobals()`, before any
> SafeGo launches). Severity HIGH — without this call, half the observability trident
> never emits and dashboards lie.

---

#### Angle 4: Missing `SetProductionMode(true)` in production services

**Severity:** MEDIUM

**DIY Patterns to Detect:**
- Bootstrap code lacks `runtime.SetProductionMode` call entirely
- `SetProductionMode` is called with a hardcoded `false`
- `SetProductionMode` is gated on a misconfigured or inverted env var (e.g.,
  `runtime.SetProductionMode(os.Getenv("DEBUG") == "true")` — reads wrong variable)
- `SetProductionMode(true)` called but then later in bootstrap `SetProductionMode(false)`
  is also called (rare but catches test scaffolding leaking into main)

**lib-observability Replacement:**
- `runtime.SetProductionMode(cfg.Env == "production")` — read from standard config, set
  deterministically once at startup, before any SafeGo launches

**Consequence of missing:**
- Panic value string flows verbatim into log fields, span events, and ErrorReporter
  payloads → **PII leakage risk** (the panic message may include user input, request
  bodies, or secrets that happened to be in the panicking stack frame)
- Stack traces are **not truncated** → 20 KB stack traces bloat span attributes, hit
  exporter limits, and may be rejected by the OTel collector
- Development-mode verbosity leaks into production log aggregators

**Migration Complexity:** trivial

**Example Transformation:**

```go
// DIY (BEFORE): no production-mode switch — panic values leak to span events verbatim
logger, _ := zap.New(zapCfg)
tl, _ := tracing.NewTelemetry(otelCfg)
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
// missing: SetProductionMode

// lib-observability (AFTER):
logger, _ := zap.New(zapCfg)
tl, _ := tracing.NewTelemetry(otelCfg)
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
runtime.SetProductionMode(cfg.Env == "production")  // panic values redacted, stack capped
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for missing or misconfigured `runtime.SetProductionMode` calls.
> Search bootstrap files for `runtime.SetProductionMode`. If absent, flag the service.
> If present, check the argument: `true` is correct for production services, `false`
> is correct only in test scaffolding, a boolean expression should derive from the
> deployment environment variable (typically `cfg.Env == "production"` or similar). MUST
> flag hardcoded `false`, inverted env-var reads (reading `DEBUG` instead of `ENV`), and
> any path where `SetProductionMode` is toggled multiple times. For each finding record
> file:line and the current argument. Severity MEDIUM — correctness issue, PII leak
> risk, span-attribute bloat. The failure is slow-developing (you discover it when
> someone grep's production logs and sees a credit card number in a panic message).

---

#### Angle 5: Framework panic handlers bypassing `HandlePanicValue`

**Severity:** HIGH

**DIY Patterns to Detect:**
- Fiber `recover.New(recover.Config{StackTraceHandler: ...})` where the handler logs the
  recovered value but does **not** call `runtime.HandlePanicValue(c.UserContext(),
  logger, e, component, operation)`
- gRPC unary/stream interceptors that use bare `defer recover()` without feeding the
  recovered value through `runtime.HandlePanicValue`
- Custom RabbitMQ consumer wrappers that wrap handler calls in `defer recover()` and
  route errors manually (ignoring the trident pipeline)
- Handler libraries that swallow panics silently (e.g., `defer func() { _ = recover() }()`
  inside an interceptor — the framework logs nothing, the trident fires nothing)

**lib-observability Replacement:**
- Fiber: wire `StackTraceHandler` → `runtime.HandlePanicValue(c.UserContext(), logger, e,
  "api", c.Path())`
- gRPC: `defer runtime.RecoverWithPolicyAndContext(ctx, logger, "grpc", info.FullMethod,
  runtime.KeepRunning)` at the top of the interceptor
- RabbitMQ wrapper: wrap the handler call with `runtime.SafeGoWithContextAndComponent`
  for the consumer loop, and `runtime.RecoverWithPolicyAndContext` for per-message
  processing if the consumer can't afford to lose the goroutine

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE): Fiber recover middleware logs, but trident never fires
app.Use(recover.New(recover.Config{
    EnableStackTrace: true,
    StackTraceHandler: func(c *fiber.Ctx, e interface{}) {
        log.Printf("panic in handler %s: %v", c.Path(), e) // stdlib log — no metric, no span event
    },
}))

// lib-observability (AFTER):
app.Use(recover.New(recover.Config{
    EnableStackTrace: true,
    StackTraceHandler: func(c *fiber.Ctx, e interface{}) {
        runtime.HandlePanicValue(c.UserContext(), logger, e, "api", c.Path())
    },
}))
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for framework panic handlers that bypass
> `runtime.HandlePanicValue`. MUST search for `recover.New(` (Fiber),
> `grpc.UnaryInterceptor(`, `grpc.StreamInterceptor(`, and any custom consumer wrapper
> that mentions `recover()`. For each, inspect the recovery path: does it eventually
> call `runtime.HandlePanicValue`, `runtime.RecoverWithPolicyAndContext`, or
> `runtime.RecoverWithPolicy`? If it logs via stdlib `log`, emits to a custom logger
> without metric emission, or silently swallows the panic, flag it. For gRPC
> specifically, MUST flag interceptors that don't pass the ctx into the recovery
> pipeline (losing trace context). Record file:line, the framework involved, and the
> current recovery behavior. Severity HIGH — framework handlers are where 50% of
> server-side panics land; if they bypass the trident, half your panics are invisible.

---

#### Angle 6: Policy mismatch (`KeepRunning` vs `CrashProcess`)

**Severity:** MEDIUM

**DIY Patterns to Detect:**
- `runtime.CrashProcess` passed to SafeGo for an HTTP request handler goroutine (wrong —
  one panicking request must not kill the service for all other tenants/users)
- `runtime.CrashProcess` in a consumer loop where one bad message should be routed to
  DLQ, not crash the whole service
- `runtime.KeepRunning` in a bootstrap-invariant goroutine where continuing past the
  panic leaves the service running in a corrupt state (e.g., license validation
  goroutine, schema migration runner)
- `runtime.KeepRunning` in a goroutine whose responsibility is a one-shot invariant
  check (e.g., "verify DB schema matches expected version") — silently continuing past
  a failed invariant check is worse than crashing

**lib-observability Replacement:**
- Apply the Reference Mode decision tree (Section 2). No mechanical rewrite — this is a
  **judgment call** per goroutine.

**Severity MEDIUM** because default usage is defensible; this is correctness-tuning, not
an outright bug. A service with `KeepRunning` everywhere usually works; a service with
`CrashProcess` everywhere restarts too often. The sweep flags the cases where the wrong
policy is measurably harmful.

**Migration Complexity:** moderate (requires per-goroutine decision, not a sed script)

**Example Transformation:**

```go
// DIY (BEFORE): bootstrap invariant using KeepRunning — service runs in corrupt state
runtime.SafeGoWithContextAndComponent(ctx, logger, "migrator", "apply-schema",
    runtime.KeepRunning, func(ctx context.Context) {
        if err := applySchemaMigrations(ctx); err != nil {
            panic(err) // recovered, logged, but service continues with unmigrated schema
        }
    })

// lib-observability (AFTER): flip to CrashProcess so k8s restarts the pod on failure.
//   (Import path: github.com/LerianStudio/lib-observability/runtime — same symbol names.)
// Mirror fix for the opposite case: request-handler fan-out using CrashProcess flips
// to KeepRunning so one bad request doesn't DoS the service replica.
runtime.SafeGoWithContextAndComponent(ctx, logger, "migrator", "apply-schema",
    runtime.CrashProcess, func(ctx context.Context) {
        if err := applySchemaMigrations(ctx); err != nil {
            panic(err)
        }
    })
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for policy mismatches between `runtime.KeepRunning` and
> `runtime.CrashProcess`. MUST find every call to `runtime.SafeGo`,
> `runtime.SafeGoWithContext`, `runtime.SafeGoWithContextAndComponent`,
> `runtime.RecoverWithPolicy`, and `runtime.RecoverWithPolicyAndContext`. For each,
> classify the goroutine's role: (a) HTTP/gRPC request handler, (b) per-request fan-out,
> (c) long-lived consumer loop, (d) periodic worker, (e) bootstrap invariant check, (f)
> one-shot migration/provisioning goroutine. MUST flag role (a), (b), (c), (d) using
> `CrashProcess` — these should use `KeepRunning`. MUST flag role (e), (f) using
> `KeepRunning` when continuing past a panic leaves the service in a corrupt state —
> these should use `CrashProcess`. For each finding record file:line, the goroutine
> role, the current policy, and the recommended policy with a one-sentence rationale.
> Severity MEDIUM — default usage is defensible, only flag cases where the wrong policy
> is measurably harmful.

---
