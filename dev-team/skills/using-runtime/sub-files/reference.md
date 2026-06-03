---

## Report Template

MANDATORY: The synthesizer MUST produce `/tmp/runtime-sweep-report.md` following this
exact structure. MUST NOT add sections. MUST NOT reorder sections. MUST populate every
section even if empty (use "None detected" placeholders).

```markdown
# lib-observability/runtime Sweep Report

**Target:** <absolute path to target repo>
**Generated:** <ISO-8601 timestamp>
**Sweep duration:** <seconds>

---

## Version Status

| Field                    | Value             |
| ------------------------ | ----------------- |
| Pinned version           | <v5.0.0>          |
| Latest stable            | <resolved at runtime> |
| Drift classification     | <minor-drift>     |
| Major upgrade required   | <yes / no>        |
| Module path              | <.../v5>          |

**Assessment:** <one-paragraph narrative — e.g., "project is 2 patch releases behind,
straightforward `go get -u` upgrade; lib-observability/runtime API surface unchanged
since pinned version" or "project still imports the deprecated lib-commons/v5/commons/runtime
shim — migrate imports to github.com/LerianStudio/lib-observability/runtime before
adopting HandlePanicValue recommendations below">

---

## Unadopted Features

lib-observability/runtime features added between the pinned version and latest stable
that the target has not yet adopted:

| Version | Feature                                        | Classification  | Relevant Finding Angle |
| ------- | ---------------------------------------------- | --------------- | ---------------------- |
| <vX>    | <e.g., runtime.HandlePanicValue>               | new-api         | Angle 5                |
| <vX>    | <e.g., SetErrorReporter hook>                  | new-api         | (standalone highlight) |

---

## Quick Wins

Severity LOW–MEDIUM, migration complexity trivial. Low-risk, high-ergonomics fixes
batchable in a single dev-cycle task.

<bulleted list of findings grouped by angle — each bullet: "Angle N: <summary>, <file count> files, trivial">

---

## Strategic Migrations

Severity HIGH–CRITICAL, migration complexity moderate–complex. High-value, multi-task
efforts that MUST go through the full dev-cycle.

<bulleted list of findings grouped by angle — each bullet: "Angle N: <summary>, <file count> files, complexity, expected impact">

---

## Full Findings

| Angle                                    | Severity  | File                        | Line | DIY Pattern                         | Replacement                               | Complexity |
| ---------------------------------------- | --------- | --------------------------- | ---- | ----------------------------------- | ----------------------------------------- | ---------- |
| 1 Naked goroutine launches               | CRITICAL  | internal/worker/consumer.go | 34   | go func() long-lived consumer       | runtime.SafeGoWithContextAndComponent     | moderate   |
| 2 Unobservable defer recover()           | CRITICAL  | internal/http/handler.go    | 89   | defer recover() swallows panic      | runtime.RecoverWithPolicyAndContext       | moderate   |
| 3 Missing InitPanicMetrics               | HIGH      | cmd/api/main.go             | 52   | bootstrap skips metric init          | runtime.InitPanicMetrics                  | trivial    |
| 4 Missing SetProductionMode              | MEDIUM    | cmd/api/main.go             | 54   | no SetProductionMode call           | runtime.SetProductionMode                 | trivial    |
| 5 Framework handler bypass               | HIGH      | internal/http/middleware.go | 18   | Fiber recover logs via stdlib       | runtime.HandlePanicValue                  | moderate   |
| 6 Policy mismatch                        | MEDIUM    | internal/worker/migrate.go  | 71   | KeepRunning on migration goroutine  | CrashProcess                              | moderate   |
| ...                                      | ...       | ...                         | ...  | ...                                 | ...                                       | ...        |

---

## Summary Statistics

| Severity | Findings | Files affected | Estimated effort |
| -------- | -------- | -------------- | ---------------- |
| CRITICAL | N        | N              | N days           |
| HIGH     | N        | N              | N days           |
| MEDIUM   | N        | N              | N days           |
| LOW      | N        | N              | N days           |
| **Total**| **N**    | **N**          | **N days**       |

**Angles clean:** <list of angles where no DIY was detected — signals codebase health>

---

## Recommended Next Step

`ring:dev-cycle` consuming `/tmp/runtime-sweep-tasks.json` — N tasks generated,
grouped by severity, CRITICAL first.
```

---

## Task Generation for ring:dev-cycle

MANDATORY: The synthesizer MUST also emit `/tmp/runtime-sweep-tasks.json` — a JSON
array of tasks shaped for `ring:dev-cycle` consumption. The format matches what
`ring:dev-refactor`, `ring:using-lib-observability`, and `ring:using-lib-commons`
produce, so the downstream cycle doesn't need to special-case runtime sweeps.

**Task grouping rules:**

1. MUST group findings by severity — CRITICAL first, then HIGH, MEDIUM, LOW.
2. Within a severity tier, MUST group findings from the same file or tightly-related
   files into a single task (avoid one-task-per-line fragmentation).
3. CRITICAL findings MUST be standalone tasks (no batching across concerns) — each gets
   its own dev-cycle pass. Angles 1 and 2 in particular are standalone.
4. MUST include dependency references when one task's correctness depends on another:
   - Angle 3 (`InitPanicMetrics`) SHOULD land before Angles 1, 2, 5 so fixes emit metrics
     from the first run.
   - Angle 4 (`SetProductionMode`) SHOULD land before Angles 1, 2, 5 so fixes respect
     production-mode redaction from the first run.
   - Version upgrade (when `major_upgrade_required = true`) MUST land as task #1, with
     every other task depending on it.

**Task schema:**

```json
{
  "id": "runtime-sweep-001",
  "title": "Wrap naked goroutines in lib-observability runtime.SafeGo",
  "severity": "CRITICAL",
  "description": "Target service launches N goroutines via raw `go func()` / `go someFunc(` across the worker and HTTP handler layers. Panics inside these goroutines silently kill the goroutine, stop the work it was responsible for, and surface nothing in logs, metrics, or traces — the service appears healthy while work is silently dropped. Wrap each site in `runtime.SafeGoWithContextAndComponent` (long-lived workers) or `runtime.SafeGoWithContext` (per-request fan-out) with policy `KeepRunning`. This is the single highest-leverage reliability fix in the sweep.",
  "files_affected": [
    "internal/worker/consumer.go:34",
    "internal/worker/dispatcher.go:71",
    "internal/http/handler.go:112"
  ],
  "acceptance_criteria": [
    "All `go func()` / `go someFunc(` / `go obj.Method(` calls in non-test code wrapped in a runtime.SafeGo* variant",
    "Long-lived workers use SafeGoWithContextAndComponent with a descriptive component label",
    "Per-request fan-out uses SafeGoWithContext",
    "Policy is KeepRunning for request handlers and consumer loops",
    "Test: forced panic inside a wrapped goroutine emits the panic_recovered_total metric",
    "Test: forced panic inside a wrapped goroutine does not terminate the surrounding goroutine scope"
  ],
  "estimated_complexity": "moderate",
  "depends_on": ["runtime-sweep-003"],
  "angle": 1,
  "replacement_api": "runtime.SafeGoWithContextAndComponent"
}
```

**Task emission verbatim example** (first task is the Angle-3 bootstrap fix;
subsequent tasks `depends_on` it so fixes emit clean telemetry from their first run):

```json
[
  {
    "id": "runtime-sweep-001",
    "title": "Initialize panic metrics and production mode in bootstrap",
    "severity": "HIGH",
    "description": "Target service uses lib-observability/runtime (or the lib-commons shim) but bootstrap never calls runtime.InitPanicMetrics (counter never emits) nor runtime.SetProductionMode (panic values leak verbatim to logs/spans). Land these two calls first so subsequent fixes emit clean telemetry.",
    "files_affected": ["cmd/api/main.go:52"],
    "acceptance_criteria": [
      "main.go calls runtime.InitPanicMetrics(tl.MetricsFactory, logger) after telemetry setup",
      "main.go calls runtime.SetProductionMode(cfg.Env == \"production\") before any SafeGo launches",
      "Integration test: forced panic emits panic_recovered_total with correct component label"
    ],
    "estimated_complexity": "trivial",
    "depends_on": [],
    "angle": 3,
    "replacement_api": "runtime.InitPanicMetrics + runtime.SetProductionMode"
  },
  {
    "id": "runtime-sweep-002",
    "title": "Wrap naked goroutines in lib-observability runtime.SafeGo",
    "severity": "CRITICAL",
    "description": "<as above>",
    "files_affected": ["internal/worker/consumer.go:34", "..."],
    "acceptance_criteria": ["..."],
    "estimated_complexity": "moderate",
    "depends_on": ["runtime-sweep-001"],
    "angle": 1,
    "replacement_api": "runtime.SafeGoWithContextAndComponent"
  }
]
```

**Handoff message template** (orchestrator surfaces to user after Phase 4):

```
lib-observability/runtime sweep complete. Findings: <N> across <M> of 6 angles.
- CRITICAL: <N>   HIGH: <N>   MEDIUM: <N>   LOW: <N>

Report: /tmp/runtime-sweep-report.md
Tasks:  /tmp/runtime-sweep-tasks.json (<N> tasks)

Next: Invoke ring:dev-cycle with the task file to execute fixes. CRITICAL tasks
(Angles 1 and 2 — naked goroutines and unobservable defer recover) MUST be addressed
before the HIGH/MEDIUM tier. Angle 3 (InitPanicMetrics) is trivial and SHOULD land
first so all subsequent fixes emit metrics from the first run.
```

---

# REFERENCE MODE

Sections 1–10 below catalog lib-observability/runtime's API surface, decision trees,
patterns, and anti-patterns. Read the sections relevant to your current task. Sweep
Mode explorers receive extracts from these sections as context for their angle.

---

## 1. API Surface

Full catalog of exported symbols in `github.com/LerianStudio/lib-observability/runtime`
(v1.0.0+). All examples below assume `import "github.com/LerianStudio/lib-observability/runtime"`.
The `runtime.Logger` interface is defined in lib-observability and is satisfied by
`lib-commons/commons/log.Logger` and the standard `zap`-backed logger Lerian services
use.

### Goroutine Launchers

| Symbol | Signature | Purpose | When to Use |
|---|---|---|---|
| `SafeGo` | `func(logger Logger, name string, policy PanicPolicy, fn func())` | Launch a goroutine with panic recovery. No ctx, no component label. | Legacy call sites or trivial fire-and-forget where you have no ctx in scope. Prefer the `WithContext` variants when possible. |
| `SafeGoWithContext` | `func(ctx context.Context, logger Logger, name string, policy PanicPolicy, fn func(context.Context))` | Launch a goroutine that carries the parent ctx. Trace context propagates. | Per-request fan-out inside HTTP handlers, short-lived workers that need cancellation. |
| `SafeGoWithContextAndComponent` | `func(ctx context.Context, logger Logger, component, name string, policy PanicPolicy, fn func(context.Context))` | Launch with ctx AND a component label. The component label becomes a metric/log/span attribute, making panics attributable. | **Preferred for long-lived workers.** Consumer loops, periodic workers, bootstrap goroutines. |

### Defer-Form Recovery

| Symbol | Signature | Purpose | When to Use |
|---|---|---|---|
| `RecoverAndLog` | `func(logger Logger, name string)` | Deferred recovery with `KeepRunning` semantics; emits log + trident, no ctx. | Legacy fire-and-forget recovery without a ctx in scope. |
| `RecoverAndCrash` | `func(logger Logger, name string)` | Deferred recovery with `CrashProcess` semantics; emits trident then re-panics. | Bootstrap/invariant code without a ctx in scope. |
| `RecoverAndLogWithContext` | `func(ctx context.Context, logger Logger, component, name string)` | Like `RecoverAndLog` but ctx-aware; span receives the `panic.recovered` event. | Functions with ctx in scope where `KeepRunning` is the correct policy. |
| `RecoverAndCrashWithContext` | `func(ctx context.Context, logger Logger, component, name string)` | Like `RecoverAndCrash` but ctx-aware. | Functions with ctx where continuing past a panic would corrupt state. |
| `RecoverWithPolicy` | `func(logger Logger, name string, policy PanicPolicy)` | Deferred recovery with explicit policy. No ctx — trace context is not captured. | Functions without a ctx in scope (rare). |
| `RecoverWithPolicyAndContext` | `func(ctx context.Context, logger Logger, component, name string, policy PanicPolicy)` | Deferred recovery with ctx — the active span receives the `panic.recovered` event. | **Preferred.** Any function with ctx in scope. |

### Framework-Level Handling

| Symbol | Signature | Purpose | When to Use |
|---|---|---|---|
| `HandlePanicValue` | `func(ctx context.Context, logger Logger, panicValue any, component, name string)` | Feed a recovered panic value into the trident pipeline. Does not itself recover — it handles the value someone else already recovered. | Framework handlers that recover panics themselves (Fiber `StackTraceHandler`, gRPC interceptors, custom wrappers). |

### Bootstrap

| Symbol | Signature | Purpose | When to Use |
|---|---|---|---|
| `InitPanicMetrics` | `func(factory *metrics.MetricsFactory, logger ...Logger)` | Register the `panic_recovered_total` counter with the lib-observability `MetricsFactory`. The logger argument is variadic — pass one if you want bootstrap-time warnings logged through your structured logger. | Once, at bootstrap, after telemetry setup, before any SafeGo launches. |
| `SetProductionMode` | `func(enabled bool)` | Toggle production-mode behavior: redact panic values, truncate stack traces to 4096 bytes. | Once, at bootstrap. Pass `cfg.Env == "production"` (or equivalent). |
| `IsProductionMode` | `func() bool` | Read the current production-mode flag — primarily for tests asserting bootstrap wiring. | Test scaffolding; rarely used in production code. |
| `SetErrorReporter` | `func(reporter ErrorReporter)` | Register an external error reporter (Sentry, Bugsnag, etc.) that gets called on every recovered panic. | Once, at bootstrap, if the service uses external error tracking. Optional. |
| `GetErrorReporter` | `func() ErrorReporter` | Read the currently registered reporter — primarily for tests. | Test scaffolding. |

### Policy Constants

| Symbol | Type | Behavior |
|---|---|---|
| `KeepRunning` | `PanicPolicy` | Recover, log, emit trident, continue. The goroutine's `fn` returns normally. |
| `CrashProcess` | `PanicPolicy` | Recover, log, emit trident, **re-panic**. The process terminates (or its container restarts). |

### Interface

```go
type ErrorReporter interface {
    CaptureException(ctx context.Context, err error, tags map[string]string)
}
```

A minimal contract for external error reporters. Implementations forward to Sentry,
Bugsnag, Rollbar, or any other service. Called **after** the trident fires, so the
log/metric/span emission is never gated on the reporter being reachable.

`SetErrorReporter(nil)` is explicitly allowed — it clears any previously set reporter.

---

## 2. Policy Decision Tree

`KeepRunning` vs `CrashProcess` is **the** decision that matters in this package. Get
it wrong and either one bad request kills the service for everyone (`CrashProcess` in a
handler), or the service runs in a corrupt state indefinitely (`KeepRunning` on a
broken invariant).

### Decision Table

| Workload                                                    | Policy          | Rationale                                                                 |
| ----------------------------------------------------------- | --------------- | ------------------------------------------------------------------------- |
| HTTP request handler (the handler itself, via RecoverWith*) | `KeepRunning`   | One bad request panicking must not kill the service for other requests.   |
| Per-request fan-out goroutine                               | `KeepRunning`   | Same — the outer request fails, but the service stays up.                 |
| gRPC handler goroutine                                      | `KeepRunning`   | Same reasoning as HTTP.                                                   |
| Long-lived AMQP/Kafka consumer loop                         | `KeepRunning`   | One bad message → DLQ, not service death. Consumption must continue.      |
| Background retry worker                                     | `KeepRunning`   | Retries are by definition fault-tolerant; crashing defeats the purpose.   |
| Periodic ticker worker                                      | `KeepRunning`   | One bad tick doesn't invalidate future ticks.                             |
| Bootstrap invariant check (e.g., license, DB schema)        | `CrashProcess`  | Running past a broken invariant corrupts state. Fail-closed is correct.   |
| Schema migration runner                                     | `CrashProcess`  | Continuing with an unmigrated schema corrupts every subsequent write.     |
| Data-integrity verification (e.g., startup reconciliation)  | `CrashProcess`  | Continuing past a detected inconsistency amplifies the inconsistency.     |
| One-shot provisioning job                                   | `CrashProcess`  | If the provisioning step panics, the running process is in a hybrid state. |

### Gray Areas

- **Kafka consumer with manual offset commit**: `KeepRunning`. A panic during message
  processing recovers; the offset is not committed; the message redelivers. This is the
  correct behavior.
- **Consumer whose dependencies fail to initialize at startup**: `CrashProcess` for the
  initialization goroutine, `KeepRunning` for the consumer loop. Two different
  goroutines, two different policies.
- **One-time data import run as a CLI command**: `CrashProcess`. If the import panics,
  the exit code must reflect failure so the orchestrator (cron, k8s Job) knows not to
  mark success.
- **Shared library code (e.g., a helper that spawns a goroutine)**: `KeepRunning`
  unless the helper's caller explicitly requests otherwise. The library doesn't know
  enough about the caller's invariants to choose `CrashProcess` safely.

★ Insight ─────────────────────────────────────
The mental model: `KeepRunning` = "this work is replaceable; losing it is survivable";
`CrashProcess` = "this work is a precondition for anything else being correct". When in
doubt, ask: "if this panics and I silently continue, is the service still producing
correct output?" If yes, `KeepRunning`. If no, `CrashProcess`. The default is almost
always `KeepRunning` — most goroutines run work that can fail without corrupting the
service.
─────────────────────────────────────────────────

---

## 3. Pattern Catalog

Real-world usage patterns. Each pattern is a full working snippet with realistic
variable names.

### 3.1 Long-lived consumer loop (RabbitMQ)

The canonical use case for `SafeGoWithContextAndComponent`. The consumer loop runs for
the lifetime of the service; a panic inside must not kill the goroutine because
consumption would silently stop.

```go
func startOutboundConsumer(ctx context.Context, logger log.Logger, deliveries <-chan amqp.Delivery, handler MessageHandler) {
    runtime.SafeGoWithContextAndComponent(ctx, logger,
        "outbound-webhook-service", "amqp-consumer-loop", runtime.KeepRunning,
        func(ctx context.Context) {
            for {
                select {
                case <-ctx.Done():
                    return
                case delivery, ok := <-deliveries:
                    if !ok {
                        return
                    }
                    if err := handler.Handle(ctx, delivery); err != nil {
                        _ = delivery.Nack(false, false) // route to DLQ
                        continue
                    }
                    _ = delivery.Ack(false)
                }
            }
        })
}
```

`ctx` propagation means a shutdown signal from the parent Launcher cancels the
consumer loop cleanly. Policy `KeepRunning` — a panic in `handler.Handle` recovers,
emits the trident, and the outer `for` resumes pulling deliveries. Without
`SafeGoWithContextAndComponent`, consumption would stop forever on the first panic.

### 3.2 Per-request fan-out

HTTP handler that spawns parallel sub-requests (e.g., enrichment calls). Each sub-call
runs in its own goroutine; panics there must not crash the service.

```go
func getOrderWithEnrichment(c *fiber.Ctx) error {
    ctx := c.UserContext()
    order, err := orderRepo.Get(ctx, c.Params("id"))
    if err != nil {
        return http.RenderError(c, err)
    }

    var wg sync.WaitGroup
    wg.Add(2)
    runtime.SafeGoWithContext(ctx, logger, "order-enrich-customer", runtime.KeepRunning,
        func(ctx context.Context) {
            defer wg.Done()
            if cust, err := customerClient.Fetch(ctx, order.CustomerID); err == nil {
                order.Customer = cust
            }
        })
    runtime.SafeGoWithContext(ctx, logger, "order-enrich-shipping", runtime.KeepRunning,
        func(ctx context.Context) {
            defer wg.Done()
            if ship, err := shippingClient.Fetch(ctx, order.ShippingID); err == nil {
                order.Shipping = ship
            }
        })
    wg.Wait()
    return http.Respond(c, 200, order)
}
```

Prefer `commons/errgroup` when you need first-error cancellation — `SafeGo*` is
appropriate when best-effort enrichment is acceptable.

### 3.3 Periodic ticker worker

Background worker on a fixed interval. `SafeGoWithContextAndComponent` — the component
label makes the ticker identifiable in metrics (`panic_recovered_total{component="cache-warmer"}`).

```go
func startCacheWarmer(ctx context.Context, logger log.Logger, warmer *Warmer) {
    runtime.SafeGoWithContextAndComponent(ctx, logger, "cache-warmer", "periodic-tick",
        runtime.KeepRunning, func(ctx context.Context) {
            ticker := time.NewTicker(5 * time.Minute)
            defer ticker.Stop()
            for {
                select {
                case <-ctx.Done():
                    return
                case <-ticker.C:
                    if err := warmer.Warm(ctx); err != nil {
                        logger.Errorf("cache warm failed: %v", err)
                    }
                }
            }
        })
}
```

### 3.4 Graceful shutdown coordination

`SafeGoWithContext*` variants carry the parent ctx into the goroutine. When the parent
cancels (shutdown signal, Launcher draining), the ctx propagates, and the goroutine
observes `ctx.Done()` and exits cleanly. Each `SafeGoWithContextAndComponent` call
spawns a worker under the same derived ctx; `<-ctx.Done()` in the parent blocks until
shutdown, at which point every child observes cancellation and exits. This is the
canonical pattern for service-level graceful shutdown using lib-observability/runtime
+ `lib-commons/commons.Launcher` (the Launcher lifecycle still lives in lib-commons).

### 3.5 Framework integration — Fiber

Fiber's `recover.New` middleware catches panics in handler chains. Wire its
`StackTraceHandler` into `runtime.HandlePanicValue` so the trident fires.

```go
app := fiber.New()
app.Use(recover.New(recover.Config{
    EnableStackTrace: true,
    StackTraceHandler: func(c *fiber.Ctx, e interface{}) {
        runtime.HandlePanicValue(c.UserContext(), logger, e, "api", c.Path())
    },
}))

app.Get("/orders/:id", getOrder)
```

`c.UserContext()` carries the request's trace context, so the `panic.recovered` span
event lands on the correct span. `c.Path()` feeds the `operation` attribute, making
panics attributable to the route that triggered them.

### 3.6 Framework integration — gRPC interceptors

gRPC unary and stream interceptors are goroutines from the perspective of recovery —
each RPC runs in its own goroutine pair (server side), and a panic inside the handler
must not kill the server.

```go
func RecoveryUnaryInterceptor(logger log.Logger) grpc.UnaryServerInterceptor {
    return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (resp any, err error) {
        defer runtime.RecoverWithPolicyAndContext(ctx, logger,
            "grpc", info.FullMethod, runtime.KeepRunning)
        return handler(ctx, req)
    }
}

func RecoveryStreamInterceptor(logger log.Logger) grpc.StreamServerInterceptor {
    return func(srv any, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) (err error) {
        defer runtime.RecoverWithPolicyAndContext(ss.Context(), logger,
            "grpc", info.FullMethod, runtime.KeepRunning)
        return handler(srv, ss)
    }
}

// wire into the server
server := grpc.NewServer(
    grpc.UnaryInterceptor(RecoveryUnaryInterceptor(logger)),
    grpc.StreamInterceptor(RecoveryStreamInterceptor(logger)),
)
```

Unlike Fiber, gRPC does not have a built-in recovery middleware — you write it
yourself, and the canonical implementation is `defer RecoverWithPolicyAndContext`.

### 3.7 Framework integration — RabbitMQ consumer wrapper

If you wrap AMQP consumers with your own per-message function, guard the call with
`RecoverWithPolicyAndContext` so a panicking handler doesn't kill the consumer
goroutine.

```go
func wrapMessageHandler(logger log.Logger, component string, fn MessageHandler) MessageHandler {
    return MessageHandlerFunc(func(ctx context.Context, delivery amqp.Delivery) error {
        defer runtime.RecoverWithPolicyAndContext(ctx, logger,
            component, "handle-message", runtime.KeepRunning)
        return fn.Handle(ctx, delivery)
    })
}
```

Two-level protection: the outer consumer loop uses `SafeGoWithContextAndComponent`
(loop-level recovery); the inner wrapper uses `RecoverWithPolicyAndContext`
(message-level recovery). A panic on a single message is isolated to that message; the
loop keeps pulling deliveries.

### 3.8 Error reporter integration (Sentry-style)

Plug an external error tracker into the trident pipeline. The reporter is called
**after** the log/metric/span emission, so telemetry is never gated on reporter
reachability.

```go
type sentryReporter struct{ client *sentry.Client }

func (s *sentryReporter) CaptureException(ctx context.Context, err error, tags map[string]string) {
    hub := sentry.GetHubFromContext(ctx)
    if hub == nil {
        hub = sentry.CurrentHub()
    }
    hub.WithScope(func(scope *sentry.Scope) {
        for k, v := range tags {
            scope.SetTag(k, v)
        }
        hub.CaptureException(err)
    })
}

// at bootstrap, after InitPanicMetrics and SetProductionMode:
runtime.SetErrorReporter(&sentryReporter{client: sentryClient})
```

The `tags` map includes `component`, `operation`, and `goroutine_name` — grouping rules
in Sentry can fingerprint on these to avoid one-panic-per-unique-stack noise.

---

## 4. The Observability Trident

Every recovered panic produces four emissions:

```
panic happens
    ↓
runtime.SafeGo* or runtime.RecoverWith* catches it
    ↓
    ├─→ 1. Structured log  (via log.Logger)
    ├─→ 2. OTel span event (on the active span)
    ├─→ 3. Metric           (panic_recovered_total counter)
    └─→ 4. ErrorReporter    (if SetErrorReporter was called)
```

### Layer 1: Structured Log

Emitted via the `log.Logger` passed to `SafeGo*` or `RecoverWith*`. Log level is
`ERROR`. Fields:

| Field             | Value                                                                    |
| ----------------- | ------------------------------------------------------------------------ |
| `component`       | The component label (e.g., `"outbound-webhook-service"`)                 |
| `goroutine_name`  | Or `operation` for defer-form (e.g., `"amqp-consumer-loop"`)             |
| `recovered_value` | Stringified panic value (redacted to placeholder in production mode)     |
| `stack`           | Full stack trace (truncated to 4096 bytes in production mode)            |
| `trace_id`        | From ctx when `SafeGoWithContext*` / `RecoverWithPolicyAndContext` used  |
| `span_id`         | Same                                                                     |

### Layer 2: OTel Span Event

Emitted on the **active span** in the ctx passed to the recovery function. Event name:
`panic.recovered`. Attributes:

| Attribute                   | Value                                                                   |
| --------------------------- | ----------------------------------------------------------------------- |
| `panic.component`           | Component label                                                         |
| `panic.operation`           | Operation / goroutine name                                              |
| `panic.recovered_value`     | Stringified value (redacted in production mode)                         |
| `panic.stack`               | Stack (truncated in production mode)                                    |

Side effect: the span's status is set to `Error`. This means the trace view in your
observability backend shows the request's span as failed, not misleadingly green.

### Layer 3: Metric

Counter: `panic_recovered_total`.

Labels:

| Label          | Value                          |
| -------------- | ------------------------------ |
| `component`    | Component label                |
| `goroutine`    | Goroutine name / operation     |

Incremented by 1 on each recovery. **Requires `InitPanicMetrics` to have been called at
bootstrap** — otherwise the counter is never registered and the increment is a no-op.

### Layer 4: ErrorReporter Callback

Only fires if `SetErrorReporter` was called with a non-nil reporter. Signature:

```go
reporter.CaptureException(ctx, err, tags)
```

`err` is synthesized from the panic value (`fmt.Errorf("panic recovered: %v", r)` in
non-production mode; a redacted placeholder in production mode). `tags` includes
`component`, `operation`, and `goroutine_name`.

### Observing in Dashboards

| Use Case                                  | Query                                                                         |
| ----------------------------------------- | ----------------------------------------------------------------------------- |
| Recovered panics per service per minute   | `sum(rate(panic_recovered_total[1m])) by (component)`                         |
| Top panicking goroutines                  | `topk(10, sum(rate(panic_recovered_total[5m])) by (component, goroutine))`    |
| Traces containing panics                  | `event.name = "panic.recovered"` in Tempo/Jaeger/Datadog APM                  |
| Alert on regressions                      | `sum(rate(panic_recovered_total[5m])) > 0.1` (>1 recovery per 10 min average) |

★ Insight ─────────────────────────────────────
The trident's point is **defense in depth**. Logs can be dropped by an overwhelmed
aggregator; span events can be dropped by a sampling decision; metrics can be missed if
the dashboard query is wrong. By emitting all three, at least one signal reaches the
operator. Add the optional ErrorReporter callback and you have four independent
channels — the probability of a panic going unnoticed drops toward zero. This is the
whole reason `lib-observability/runtime` exists.
─────────────────────────────────────────────────

---

## 5. Testing Patterns

Tests that prove the trident actually fires. All patterns use a deliberate panic
inside a wrapped goroutine and assert on the observable side effects.

### 5.1 Counter incremented

Inject an in-memory `MetricsFactory`, trigger a panic in a `SafeGo` goroutine, read the
counter.

```go
func TestSafeGo_PanicIncrementsMetric(t *testing.T) {
    factory := metricstesting.NewInMemoryFactory()
    logger := logtesting.NewBuffered()
    runtime.InitPanicMetrics(factory, logger)

    done := make(chan struct{})
    runtime.SafeGo(logger, "test-goroutine", runtime.KeepRunning, func() {
        defer close(done)
        panic("boom")
    })
    <-done

    // allow async metric emission to flush
    time.Sleep(10 * time.Millisecond)

    got := factory.CounterValue("panic_recovered_total",
        map[string]string{"goroutine": "test-goroutine"})
    if got != 1 {
        t.Fatalf("panic_recovered_total = %d, want 1", got)
    }
}
```

### 5.2 Span event emitted

Use an in-memory OTel exporter (`tracetest.NewInMemoryExporter`), start a parent span,
trigger a panic inside `runtime.SafeGoWithContext(ctx, ...)`, call `span.End()`, and
scan `exporter.GetSpans()` for an event named `panic.recovered`. Assert its attributes
include the expected `panic.component` and `panic.operation`. The span's status MUST be
`Error` — assert that too.

### 5.3 Structured log emitted

Use a buffered logger that captures entries. Wrap a closure with
`defer runtime.RecoverWithPolicyAndContext(ctx, logger, component, op, KeepRunning)`,
panic inside it, then assert the captured entries contain an Error-level entry with
`component` and `operation` fields matching the values passed to the defer.

### 5.4 ErrorReporter called

Implement a test reporter that records calls, trigger a panic, assert the reporter's
`CaptureException` fired with the expected tags (`component`, `operation`,
`goroutine_name`). Use `t.Cleanup(func() { runtime.SetErrorReporter(nil) })` to avoid
leaking the reporter across tests. The structure mirrors 5.1–5.3: inject a fake,
trigger, assert.

### 5.5 Leak detection alongside

`lib-observability/runtime` does not leak goroutines by itself, but the code that uses it might.
Pair panic-recovery tests with `goleak` to catch goroutines that should have exited but
didn't. See `ring:dev-goroutine-leak-testing` skill for the full pattern.

```go
func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}
```

This catches the case where a `SafeGo` goroutine panics, recovers, but was supposed to
signal a waitgroup that now leaks because `defer wg.Done()` was inside the recovered
block rather than outside it.

---

## 6. Anti-Pattern Catalog

Six ways to get this wrong. Each has a BEFORE example and a consequence narrative.

### 6.1 Naked goroutine

```go
go func() {
    for msg := range deliveries {
        process(msg)
    }
}()
```

**Consequence:** `process` panics, the goroutine dies, consumption of `deliveries`
stops forever, the `for range` loop is now an orphan. Nothing surfaces in logs (no
panic recovery = no log). Nothing surfaces in metrics. The service reports healthy to
its health check because the HTTP server is still up. The queue backs up. An operator
eventually notices the message backlog, investigates, and finds the goroutine never
existed in traces because there was no span on it.

### 6.2 `defer recover()` without trident

```go
defer func() {
    if r := recover(); r != nil {
        // ignored
    }
}()
```

**Consequence:** Panic recovery works — the function returns normally. But nothing
emits. No log, no metric, no span event. The panic is invisible. A latent bug (nil
dereference, divide-by-zero, map concurrent write) runs in production for months
before someone notices the symptom (corrupted data, missed transactions) and traces it
back. The recovery itself is what made the bug hard to find.

### 6.3 Missing `InitPanicMetrics`

```go
// bootstrap uses SafeGo but forgot to call InitPanicMetrics
runtime.SafeGo(logger, "worker", runtime.KeepRunning, workerFn)
```

**Consequence:** Logs fire, span events fire, ErrorReporter fires — but the
`panic_recovered_total` counter never registers, so alerts based on metrics never
trigger. Dashboards show zero panics. Operators trust the dashboards. The service
quietly accumulates recovered panics that no one sees until a different signal (slow
latency, customer complaint) prompts investigation.

### 6.4 `SetProductionMode(false)` in production

```go
// production bootstrap (misconfigured)
runtime.SetProductionMode(false)
```

**Consequence:** Panic values are emitted verbatim. A panic triggered by a malformed
request body that contains a credit card number causes the credit card number to land
in log aggregators (retained for 90 days), span attributes (kept by trace backend),
and ErrorReporter payloads (sent to a third-party service). Compliance incident.
Stack traces are not truncated either — 20 KB stack traces per recovery bloat the OTel
exporter and may be rejected by the collector.

### 6.5 `KeepRunning` for bootstrap invariants

```go
runtime.SafeGoWithContextAndComponent(ctx, logger, "bootstrap", "verify-schema",
    runtime.KeepRunning, func(ctx context.Context) {
        if !schemaMatches(ctx) {
            panic("schema mismatch")
        }
    })
```

**Consequence:** Schema mismatch detected, goroutine panics, recovery logs the panic,
goroutine returns. Service continues running. Every subsequent query operates on a
schema it doesn't understand. Data corruption accumulates. The log entry that would
have warned the operator is buried under request-log volume. A log-based alert might
catch it; a metric-based alert on `panic_recovered_total{component="bootstrap"}` is
more reliable. Either way, `CrashProcess` was the right choice — k8s restarts the pod,
the startup probe fails, and the operator is notified within minutes.

### 6.6 `CrashProcess` for request handlers

```go
app.Use(func(c *fiber.Ctx) error {
    defer runtime.RecoverWithPolicyAndContext(c.UserContext(), logger,
        "api", c.Path(), runtime.CrashProcess)
    return c.Next()
})
```

**Consequence:** One malformed request triggers a panic in a handler. Recovery fires,
logs, emits trident, then re-panics. The process dies. The k8s pod restarts (~30s
downtime). The load balancer marks the replica unhealthy and drains traffic to the
remaining replicas. If the attacker (or buggy client) sends the same malformed request
in a loop, they DoS the entire fleet replica-by-replica. Request handlers must use
`KeepRunning`; the cost of one failed request is strictly bounded, the cost of a
cascading restart is not.

---

## 7. Bootstrap Order

Where `lib-observability/runtime` setup fits in service initialization.

**Requirements:**

- **AFTER** logger is constructed (runtime emits structured logs through it)
- **AFTER** telemetry is initialized (runtime registers metrics on the factory; span
  events need a TracerProvider)
- **BEFORE** any `SafeGo*` or `RecoverWith*` launches (obvious — metrics must be
  registered before increments fire)

**Canonical sequence:**

```
1. Logger                (zap.New)
2. Telemetry             (tracing.NewTelemetry + ApplyGlobals)
3. runtime.InitPanicMetrics(tl.MetricsFactory, logger)
4. runtime.SetProductionMode(cfg.Env == "production")
5. runtime.SetErrorReporter(reporter)     // optional
6. assert.InitAssertionMetrics(...)       // independent, same section
7. DB connections, HTTP app, etc.
8. SafeGo launches for consumers / workers
```

For the full snippet with all surrounding init, see
[ring:using-lib-commons Section 2 "Common Initialization Pattern"](https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/skills/using-lib-commons/SKILL.md).
The runtime-specific lines are steps 3–5 above.

---

## 8. Cross-Cutting Patterns

### 8.1 Nil-safety of `logger`

If `logger` passed to `SafeGo*` or `RecoverWith*` is nil, the goroutine still runs and
recovery still fires, but the log emission is skipped. The **metric still fires** if
`InitPanicMetrics` was called at bootstrap. The **span event still fires** if a
tracer is globally registered. Nil-logger is therefore a degraded mode, not a crash.

This is intentional — it lets bootstrap code call `SafeGo` for very-early goroutines
before the logger is fully wired, without crashing on the very line that's supposed to
catch crashes. In production you should never rely on this; pass a real logger.

### 8.2 Stack-trace truncation in production mode

When `SetProductionMode(true)` is in effect, stack traces in logs, span events, and
ErrorReporter payloads are capped at 4096 bytes. This is a deliberate trade-off:

- **For**: prevents span-attribute bloat (OTel collectors reject events over a certain
  size), prevents log ingest cost explosion on panic storms, limits PII surface area
  (less stack = less chance of in-memory secrets leaking)
- **Against**: deep stacks get truncated; sometimes the root cause is at frame 40 of a
  50-frame stack

The default is correct for production. For development/staging, call
`SetProductionMode(false)` to get full stacks.

### 8.3 Context propagation through recovery

When you use `SafeGoWithContext` or `SafeGoWithContextAndComponent`, the ctx passed
into `fn` is the same ctx carried through recovery. If the goroutine panics, the
`panic.recovered` span event lands on the span attached to that ctx (the parent's
span, by default, since no new span was started inside the wrapper).

`RecoverWithPolicyAndContext` behaves the same way — the ctx argument is the span
anchor for the recovery event.

If you want the recovery event to land on a **child** span (e.g., you started a span
for the goroutine's unit of work), start that span inside `fn` and the recovery will
still land on the active span at panic time.

### 8.4 Interaction with `lib-observability/assert`

Assertions in `lib-observability/assert` (formerly `lib-commons/commons/assert`,
re-exported via shim for back-compat) return errors — they do not panic. Therefore:

- An assertion failure does **not** trigger runtime recovery.
- The observability of assertions is orthogonal: assertions fire their own trident
  (log + span event `assertion.failed` + `assertion_failed_total` metric).
- This separation is deliberate. Assertions are recoverable (caller decides what to
  do with the returned error); panics are not (the caller's stack is already unwinding).

Both packages share the trident idea, but they operate on different signals. A well-
instrumented service emits both `assertion_failed_total` and `panic_recovered_total`,
and dashboards track them as distinct reliability indicators.

See [ring:using-assert](https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/skills/using-assert/SKILL.md)
for the assertion side of the story.

★ Insight ─────────────────────────────────────
Together, `lib-observability/runtime` and `lib-observability/assert` cover both
invisible-failure modes in Go services: panics (the goroutine dies without emission)
and silent invariant
violations (the function returns an error that no one aggregates). Assertion failures
are expected-but-suppressed-elsewhere bugs; panic recoveries are unexpected bugs.
Tracking both as separate metrics lets you distinguish "we're being defensive
correctly" from "we have a latent bug". A spike in assertions often predicts a spike
in recovered panics because the underlying code is drifting from its invariants.
─────────────────────────────────────────────────

---

## 9. Breaking Changes

No API-breaking changes in the `runtime` package across the lib-commons v4.2.0 → v5.x
window or the migration from lib-commons to lib-observability. Function signatures,
constants, and interface definitions are source-compatible across all three import
paths.

Import-path migrations to expect when sweeping:

| From                                                            | To                                                          |
| --------------------------------------------------------------- | ----------------------------------------------------------- |
| `github.com/LerianStudio/lib-commons/v4/commons/runtime`        | `github.com/LerianStudio/lib-observability/runtime`         |
| `github.com/LerianStudio/lib-commons/v5/commons/runtime` (shim) | `github.com/LerianStudio/lib-observability/runtime`         |

The lib-commons v5 path still compiles (it re-exports every symbol via type aliases and
thin wrappers) but is marked `Deprecated:` in its package docs. New code MUST import
from lib-observability directly; sweeps SHOULD report shim imports as a follow-up
migration finding so they get cleaned up before lib-commons removes the shim.

For the lib-commons v4 → v5 module-path migration (still relevant for any package that
hasn't moved to lib-observability), see
[ring:using-lib-commons Section 15](https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/skills/using-lib-commons/SKILL.md).

New capabilities added in the lib-observability v1.0.0 baseline (carried forward from
lib-commons v5.0.x) that Phase 2 of a sweep will surface if the target is still on v4:

| Version | Addition                                                                      |
| ------- | ----------------------------------------------------------------------------- |
| v5.0.0  | `HandlePanicValue` — structured framework-recovery handler (Angle 5 recommends it) |
| v5.0.0  | Refined `SetProductionMode` behavior — 4096-byte stack cap formalized         |
| v5.0.x  | Documentation and test hardening (no new symbols)                             |
| lib-observability v1.0.0 | Package relocated; API surface unchanged                         |

---

## 10. Cross-References

Explicit pointers rather than duplicated content:

| Topic                                                    | Go To                                                                                       |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Canonical home of `runtime` (parent skill)               | `ring:using-lib-observability`                                                              |
| Full lib-observability package catalog                   | `ring:using-lib-observability` "Package Catalog"                                            |
| Observability overview (logger, tracing, metrics basics) | `ring:using-lib-observability` "Observability"                                              |
| Full lib-commons package catalog (App / Launcher / etc.) | `ring:using-lib-commons` Section 1 "Package Catalog"                                        |
| Full bootstrap sequence snippet (all packages wired)     | `ring:using-lib-commons` Section 2 "Common Initialization Pattern"                          |
| Single-angle panic-handling sweep (higher level)         | `ring:using-lib-commons` Angle 15 "Panic handling DIY"                                      |
| The other half of the invisible-failure story            | `ring:using-assert` (assertion failures, not panics)                                        |
| Goroutine leak detection (companion to panic testing)    | `ring:dev-goroutine-leak-testing`                                                           |
| Overall development cycle that consumes sweep tasks      | `ring:dev-cycle`                                                                            |
| Generic codebase refactoring sweep                       | `ring:dev-refactor`                                                                         |
| Standards for Go code                                    | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md` |

MUST NOT duplicate content from the sources above. When the reader needs that content,
link to it.
