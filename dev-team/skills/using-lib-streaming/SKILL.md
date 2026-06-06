---
name: ring:using-lib-streaming
description: "Using lib-streaming, Lerian's producer-only event publication library (Kafka/SQS/RabbitMQ/EventBridge), in two modes. Sweep Mode detects DIY publishers (franz-go, sarama, amqp091, watermill, raw AWS SDK) and re-rolled manifests/breakers. Reference Mode catalogs the Builder/Emitter/Catalog facade. Companion to ring:instrumenting-streaming-events. Go-only. Skip for non-Go or consumer-only."
---

# ring:using-lib-streaming

## When to use

Sweep mode:
- "Sweep this service for lib-streaming adoption opportunities"
- "Find every DIY Kafka / SQS / RabbitMQ publisher that should use lib-streaming"
- "Audit our event publishing layer against lib-streaming"
- "We have raw franz-go / sarama / watermill — what should move to lib-streaming?"
- "Identify ad-hoc manifest or per-service circuit breakers around event publishing"

Reference mode:
- Need to understand what lib-streaming provides at the public facade
- Looking for the right `Builder` setter, `Destination` helper, or sentinel
- Setting up a new service that emits CloudEvents-framed domain events
- Wiring multi-transport fan-out (Kafka primary + SQS shadow, etc.)
- Writing unit tests that depend on `streamingtest.MockEmitter`
- Need the canonical CloudEvents binary-mode Kafka header bytes for an interop layer
- Need to map a runtime `*EmitError` / `*MultiEmitError` to an operator response

## Skip when

- Working on non-Go services (lib-streaming is Go-only)
- Working on frontend code
- Service is consumer-only with no outbound business event surface — there is nothing for lib-streaming to instrument
- Service publishes only internal command queue messages — those stay on `github.com/LerianStudio/lib-commons/v5/commons/rabbitmq`; lib-streaming is for past-tense business events to external subscribers

## Related

- **ring:instrumenting-streaming-events** — end-to-end 13-gate orchestration that *implements* lib-streaming in a target service. Use that after `ring:mapping-streaming-events` has produced a validated `docs/streaming/instrumentation-map.json`. This skill is the **adoption/reference** counterpart — it does not own the implementation cycle.
- **ring:mapping-streaming-events** — PM-side identification of eventable points; produces the catalog and instrumentation map this skill's REFERENCE MODE consumes.
- **ring:using-lib-commons** — lib-streaming depends on lib-commons for circuit breaker, outbox repository, App lifecycle, runtime panic instrumentation, and assertions. The CB / outbox / runtime / assert API surface lives there.
- **`ring:using-outbox`** — `OutboxWriter`, `TransactionalOutboxWriter`, `WithOutboxTx`, and route-aware envelope replay live in the outbox skill. This skill points at the boundary but does NOT duplicate the writer / dispatcher API.
- **`ring:using-lib-observability`** — `log.Logger`, `metrics.MetricsFactory`, and `trace.Tracer` are owned there. Builder setters consume those types; this skill links rather than re-documents.

## Distinction: adoption/reference vs end-to-end implementation

`ring:using-lib-streaming` is the **adoption and reference** skill. It answers two questions:

1. *Where in this codebase are we doing event publication the wrong way?* (Sweep Mode)
2. *What is the right lib-streaming API for the thing I am building right now?* (Reference Mode)

`ring:instrumenting-streaming-events` is the **end-to-end implementation orchestrator** — it consumes a validated instrumentation map, walks a 13-gate cycle (catalog, producer bootstrap, emit instrumentation, outbox wiring, HTTP manifest, NoopEmitter fallback, integration + chaos tests, 9 default reviewers plus triggered specialists), and never lets the caller skip TDD. The two are complementary, not overlapping:

- **Sweep finds the work.** Outputs are file:line replacement candidates and a task backlog.
- **Implementation does the work.** Consumes the catalog + map, drives gates, owns the agent dispatch.

If the user asks for a sweep, use this skill. If the user already has the map and wants emission wired into a service, hand off to `ring:instrumenting-streaming-events`.

## Mode Selection

| Request shape | Mode |
|---|---|
| "Sweep / audit / find opportunities / migrate publishers to lib-streaming" | **Sweep** |
| "Replace our DIY franz-go producer with lib-streaming" | **Sweep** |
| "What does lib-streaming provide for X?" | **Reference** |
| "How do I initialize Y from lib-streaming?" | **Reference** |
| "Which `Destination` helper for EventBridge?" | **Reference** |
| "Show me the Builder chain end-to-end" | **Reference** |

---

# SWEEP MODE

Orchestrate a 4-phase sweep. Each phase has a hard gate — do not proceed until the current phase produces its artifact.

```
Phase 1: Version Reconnaissance    -> version-report.json
Phase 2: CHANGELOG Delta Analysis  -> delta-report.json
Phase 3: Multi-Angle DIY Sweep     -> 8 x libstreaming-sweep-{N}-{angle}.json
Phase 4: Consolidated Report       -> libstreaming-sweep-report.md + tasks.json
```

## Phase 1: Version Reconnaissance

1. Read `go.mod` — extract pinned version of `github.com/LerianStudio/lib-streaming` (if absent, flag as `not-adopted`).
2. WebFetch `https://api.github.com/repos/LerianStudio/lib-streaming/releases/latest` — extract `tag_name`.
3. Classify drift: `not-adopted` / `up-to-date` / `minor-drift` / `moderate-drift` / `pre-release-only`.
4. Cross-check lib-commons pin: lib-streaming requires `github.com/LerianStudio/lib-commons/v5 v5.2.0-beta.11` (or newer compatible). If lib-commons is v4.x or absent, add a major upgrade advisory flag — adoption is blocked until lib-commons is on v5.
5. Emit `version-report.json`: `{pinned_version, latest_version, drift_classification, lib_commons_version, lib_commons_compatible, blocked_by_lib_commons, module_path}`.

## Phase 2: CHANGELOG Delta Analysis

1. WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-streaming/main/CHANGELOG.md`.
2. Extract entries between pinned_version (exclusive) and latest_version (inclusive). When `not-adopted`, summarise the **current public facade** instead of a delta.
3. Classify each entry: `new-transport` / `new-api` / `breaking-change` / `security-fix` / `performance` / `bugfix`.
4. Emit `delta-report.json` with classified entries plus a `producer_only_reminder` flag (true if any entry touches the consumer surface — lib-streaming has no consumer surface, so any such entry is wrong CHANGELOG content, not a migration item).

## Phase 3: Multi-Angle DIY Sweep

Dispatch all 8 explorer angles in **2 batches** (4+4). Wait for each batch before next.

| Batch | Angles | Focus |
|---|---|---|
| 1 | 1-4 | Raw transport SDKs (franz-go / sarama / amqp091 / watermill) |
| 2 | 5-8 | Cross-cutting concerns (AWS SDKs / circuit breakers / manifests / CloudEvents headers) |

### ⛔ STOP-CHECK BEFORE DISPATCH (each batch)

Before emitting any Task call in a batch, count the explorers you intend to launch in this turn.
- Count MUST equal 4 (each batch is 4 explorers).
- If count < 4 → STOP. Do not partial-dispatch. Reconcile against the batch row above and try again.
- No substitutions, no omissions within a batch.

### ⛔ MUST NOT trickle-dispatch within a batch

All 4 explorers in a batch leave in the SAME TURN, before reading any explorer output.

Forbidden sequences:
- Dispatch explorer 1 → read result → dispatch explorer 2
- Dispatch a subset of the batch → wait → dispatch the rest
- Dispatch follow-up explorers conditioned on partial output
- Loop sequentially over the batch's angle list

If you find yourself about to dispatch an explorer in a turn AFTER any explorer in the SAME batch has already returned a result → STOP. You violated parallel dispatch. Report the violation and mark the batch INCOMPLETE rather than completing the trickle. (Sequential batch ordering is intentional; trickle within a batch is not.)

### Self-verify after dispatch

After each batch's dispatch turn, verify all 4 Task calls were emitted in that single turn. If fewer than 4 went out, the batch did NOT execute correctly. Mark INCOMPLETE and surface the dispatch failure — do NOT silently continue with a partial batch.

### Parallel dispatch — atomic batch (within this batch)

Emit all 4 Task calls for THIS BATCH in a SINGLE TURN, as one atomic batch. (Batches themselves remain sequential — do not dispatch batch N+1 until batch N has fully returned.)

**If your runtime exposes a `multi_tool_use.parallel` wrapper**, use it to dispatch the complete batch in one wrapped invocation. This is the canonical fan-out mechanism on OpenAI-style tool envelopes and on certain Anthropic SDK consumers — naming it explicitly activates parallel emission on runtimes where trickle-dispatch is the default behavior.

**If your runtime emits parallel tool_use blocks natively** (Claude Code with Claude models), `multi_tool_use.parallel` may not be needed — but naming it is harmless and serves as an enforcement anchor.

The STOP-CHECK, anti-trickle, and self-verify guards above remain binding regardless of which mechanism your runtime uses.

**Per-explorer dispatch** (`subagent_type: ring:codebase-explorer`):

```
## Target
<absolute path to target repo root>

## Your Angle
<angle number + name>

## Severity Calibration / DIY Patterns / Replacement / Migration Complexity
<verbatim from the angle table below>

## Output
Write findings to: /tmp/libstreaming-sweep-{N}-{angle-slug}.json
Schema: {
  angle_number, angle_name, severity, migration_complexity,
  findings: [{file, line, diy_pattern, replacement, evidence_snippet, notes}],
  summary, requires_lib_commons_v5
}
If no findings: write file with empty findings array and summary "No DIY patterns detected for this angle".
```

### Angle Catalogue

| # | Angle | Severity | Replacement |
|---|---|---|---|
| 1 | Raw `github.com/twmb/franz-go/pkg/kgo` producer (`kgo.NewClient`, `ProduceSync`, manual `RecordHeader` building) used to publish business events | HIGH if used for past-tense domain facts; MEDIUM if used solely for internal command dispatch (out of scope but worth noting) | `streaming.NewBuilder().Catalog(...).Routes(streaming.RouteDefinition{Destination: streaming.KafkaTopic(...)}).Target(streaming.TargetConfig{Kind: streaming.TransportKafkaLike, Brokers: ...}).Build(ctx)` and `streaming.BuildCloudEventsHeaders(event)` |
| 2 | `github.com/Shopify/sarama` or `github.com/IBM/sarama` producer publishing events | HIGH | Same Builder + Kafka target wiring as angle 1. Note: lib-streaming is franz-go-backed; sarama is replaced wholesale, not adapted |
| 3 | `github.com/rabbitmq/amqp091-go` direct `PublishWithContext` for **events** (past-tense, durable, tenant-scoped, external-subscriber) — NOT for internal command queues | HIGH | `streaming.NewBuilder().RabbitMQTarget(name, publisher).Routes(... Destination: streaming.RabbitMQRoute(exchange, routingKey) ...)`. The caller still owns the `amqp.Channel.PublishWithContext` wrapper; lib-streaming consumes it via the `streaming.RabbitMQPublisher` interface |
| 4 | `github.com/ThreeDotsLabs/watermill` event bus (`PubSub`, `EventBus`, marshallers) used to publish CloudEvents-shaped domain facts | HIGH | Builder + `Destination` per transport. lib-streaming is CloudEvents-1.0-binary-native; watermill's middleware stack is replaced by lib-streaming's circuit-breaker + outbox + DLQ wiring |
| 5 | Raw AWS SDK calls (`sqs.SendMessage`, `eventbridge.PutEvents`) without tenant tracking, manifest, or DLQ wiring | HIGH | `Builder.SQSTarget(name, client, defaultQueueURL)` / `Builder.EventBridgeTarget(name, client)` plus a `RouteDefinition` per logical destination. Caller owns the SDK client, lib-streaming owns the message envelope |
| 6 | Per-service circuit breaker re-implementations wrapped around publishers (custom `sync/atomic` counters, hand-rolled `gobreaker.Settings`) | HIGH | lib-streaming's per-target breaker is automatic via `Builder.CircuitBreakerManager(cbManager)` from `lib-commons/v5/commons/circuitbreaker`. With a `TenantAwareManager` the breaker is `(tenant, target)`-scoped — one tenant's outage does not reject neighbours. Tune via `Builder.CBFailureRatio / CBMinRequests / CBTimeout` |
| 7 | Ad-hoc manifest generation: hand-rolled JSON describing event taxonomy, schema versions, topic lists; hand-mounted `/streaming/manifest` handlers; YAML catalogs serialised manually | MEDIUM-HIGH | `streaming.BuildManifest(descriptor, catalog, routes)` + `streaming.NewStreamingHandler(descriptor, catalog, streaming.WithManifestRoutes(routes))`. `streaming.ManifestVersion` is the wire-version constant; deterministic JSON ordering is library-owned |
| 8 | Missing or hand-rolled CloudEvents header serialisation — services writing `ce-id`, `ce-source`, `ce-type`, `ce-tenantid` directly into Kafka `RecordHeader` slices or HTTP headers | MEDIUM | `streaming.BuildCloudEventsHeaders(event)` for emit-path interop; `streaming.ParseCloudEventsHeaders(headers)` for inbound interop. Producer path gets the canonical bytes automatically through `Emit` |

### Severity calibration rules

- **HIGH** = correctness or operability risk if left in place. A DIY franz-go path bypasses circuit breakers, outbox fallback, tenant-aware partitioning, DLQ routing, and manifest exposure; a sarama path additionally pins the service to a maintained-by-others client.
- **MEDIUM** = behaviour is roughly correct but the service ships a non-uniform operator experience (custom manifest URL, hand-rolled CB metrics, raw CE headers that drift from the canonical codec).
- **LOW** = strictly internal command-queue usage that should NOT migrate; record as `out_of_scope` with a one-line rationale.

### Out-of-scope reminders for the explorer

- Internal command queues on `lib-commons/v5/commons/rabbitmq` are NOT in scope. lib-streaming and the commons RabbitMQ primitive are orthogonal; neither deprecates the other.
- Pure consumers (cloudevents-sdk-go + franz-go consumer groups) are NOT in scope — lib-streaming is producer-only.
- Outbox writer / `WithOutboxTx` / `RegisterOutboxRelay` findings belong in the `ring:using-outbox` sweep, not here. Flag them as `cross-skill: using-outbox` rather than including them in the angle output.

## Phase 4: Consolidated Report

Dispatch synthesizer (`subagent_type: ring:codebase-explorer`):

```
Read /tmp/version-report.json, /tmp/delta-report.json, /tmp/libstreaming-sweep-*.json (8 files).
Emit:
1. /tmp/libstreaming-sweep-report.md  — aggregate findings by severity, group by file
2. /tmp/libstreaming-sweep-tasks.json — one task per DIY pattern cluster (same file/package = one task)

MUST NOT invent findings. MUST NOT omit explorer findings. MUST NOT reclassify severity without justification.
MUST NOT merge cross-skill outbox findings into this report — surface them as a separate "Cross-skill handoff" section pointing to `ring:using-outbox`.
```

Surface report path + task count to the user; if adoption is feasible (lib-commons v5 already pinned, target service has a real business-event surface), offer handoff to `ring:instrumenting-streaming-events`. If the service has no validated instrumentation map yet, the handoff is to `ring:mapping-streaming-events` first.

---

# REFERENCE MODE

The public facade lives at the root package `github.com/LerianStudio/lib-streaming`. Everything else is `internal/` — do not import it. This section catalogs the facade organised by the producer lifecycle: **Bootstrap -> Build -> Emit -> Test -> Manifest**.

## Quick Navigation

| Stage | What you'll find |
|---|---|
| [Bootstrap](#bootstrap) | `LoadConfig`, `NewCatalog`, `NoopEmitter`, panic + assertion metric init |
| [Build](#build) | `NewBuilder`, every chainable setter, multi-transport target helpers, custom transport registration, TLS / SASL hardening |
| [Emit](#emit) | `Emitter` interface, `*Producer` lifecycle, `EmitRequest` shape, delivery-policy precedence |
| [Test](#test) | `streamingtest.MockEmitter`, `Assert*` helpers, `WaitForEvent` |
| [Manifest](#manifest) | `BuildManifest`, `NewStreamingHandler`, `NewPublisherDescriptor`, `WithManifestRoutes` |
| [CloudEvents codec](#cloudevents-codec) | `BuildCloudEventsHeaders`, `ParseCloudEventsHeaders` |
| [Errors](#errors) | Sentinels, `*EmitError`, `*MultiEmitError`, `IsCallerError`, the eight `ErrorClass` values |
| [End-to-end builder example](#end-to-end-builder-example) | Full Bootstrap-to-Manifest reference |

## Bootstrap

`LoadConfig()` reads `STREAMING_*` environment variables and returns `(Config, warnings []string, error)`. Print warnings — they carry forward-compat migration notes that the validator did not classify as failures.

```go
cfg, warnings, err := streaming.LoadConfig()
if err != nil { return err }
for _, w := range warnings { logger.Log(ctx, log.LevelWarn, w) }
```

| Env var | Type | Default | Purpose |
|---|---|---|---|
| `STREAMING_ENABLED` | bool | `false` | Master kill switch. When false or `STREAMING_BROKERS` is empty, callers MUST use `streaming.NewNoopEmitter()` instead of constructing a Builder |
| `STREAMING_BROKERS` | csv | `localhost:9092` | Redpanda / Kafka bootstrap list |
| `STREAMING_CLIENT_ID` | string | `""` | Kafka `client.id` for broker-side diagnostics |
| `STREAMING_BATCH_LINGER_MS` | int | `5` | franz-go `ProducerLinger` (ms) |
| `STREAMING_BATCH_MAX_BYTES` | int | `1048576` | `ProducerBatchMaxBytes` (1 MiB) |
| `STREAMING_MAX_BUFFERED_RECORDS` | int | `10000` | In-flight backpressure ceiling |
| `STREAMING_COMPRESSION` | string | `lz4` | One of `snappy`, `lz4`, `zstd`, `gzip`, `none` |
| `STREAMING_RECORD_RETRIES` | int | `10` | Per-record retry budget inside franz-go |
| `STREAMING_RECORD_DELIVERY_TIMEOUT_S` | int(s) | `30` | Per-record delivery cap |
| `STREAMING_REQUIRED_ACKS` | string | `all` | One of `all`, `leader`, `none` |
| `STREAMING_CB_FAILURE_RATIO` | float | `0.5` | Circuit-breaker trip ratio in (0.0, 1.0] |
| `STREAMING_CB_MIN_REQUESTS` | int | `10` | Minimum observations before the CB evaluates the ratio |
| `STREAMING_CB_TIMEOUT_S` | int(s) | `30` | Open -> half-open probe delay |
| `STREAMING_CLOSE_TIMEOUT_S` | int(s) | `30` | Max drain+flush window on Close |
| `STREAMING_CLOUDEVENTS_SOURCE` | string | `""` | Default `ce-source` (required when Enabled=true) |
| `STREAMING_EVENT_POLICIES` | string | `""` | `event.key.enabled=true,event.key.outbox=always,...` policy overrides |

Multi-transport (multiple Kafka clusters, SQS / RabbitMQ / EventBridge fan-out) is wired **programmatically** through `Builder`, not via `STREAMING_*` — non-Kafka destinations such as SQS queue URLs and EventBridge bus names typically live in the consuming service's own config layer.

### Catalog construction

```go
catalog, err := streaming.NewCatalog(
    streaming.EventDefinition{
        Key:           "transaction.created",
        ResourceType:  "transaction",
        EventType:     "created",
        SchemaVersion: "1.0.0",
        Description:   "A transaction was durably committed.",
    },
    streaming.EventDefinition{
        Key:           "transaction.posted",
        ResourceType:  "transaction",
        EventType:     "posted",
        SchemaVersion: "1.0.0",
    },
)
if err != nil { return err }
```

`Catalog` is immutable. Duplicate keys, malformed schema versions, and missing required fields fail at construction. Topics are derived as `lerian.streaming.<resource>.<event>` with a `.v<major>` suffix for `SchemaVersion >= 2`.

### Panic + assertion metric wiring

lib-streaming uses `lib-commons/v5/commons/runtime` and `lib-observability/assert` internally. Without these init calls the metric counters stay at zero (logs + span events still fire). Wire **after** telemetry is initialised and **before** Builder construction:

```go
runtime.InitPanicMetrics(metricsFactory)
assert.InitAssertionMetrics(metricsFactory)
runtime.SetProductionMode(cfg.Env == "production")
```

`SetProductionMode(true)` scrubs panic value strings and truncates stack traces before they hit log fields, span events, and `ErrorReporter` payloads. Without it, arbitrary panic arguments flow verbatim into telemetry — a PII risk in financial workloads.

### Disabled feature-flag fallback

```go
if !cfg.Enabled || len(cfg.Brokers) == 0 {
    emitter := streaming.NewNoopEmitter()
    // inject emitter into services; skip launcher.Add for the no-op path
    return inject(emitter)
}
```

`NewNoopEmitter()` returns a concurrency-safe `Emitter` whose three methods (`Emit`, `Close`, `Healthy`) are unconditional no-ops. Service constructors depend on the `Emitter` interface, so the rest of the code is unchanged.

## Build

`streaming.NewBuilder()` is the only constructor. All chainable setters return `*Builder` and are nil-receiver safe. Call `Build(ctx)` last — it returns `(Emitter, error)` and is the only step that performs I/O (target adapter construction, SSRF resolution for SQS routes).

### Required setters

| Setter | Argument | Purpose |
|---|---|---|
| `Source(string)` | CloudEvents source URI (e.g. `svc://ledger`) | Sets `ce-source` for every emitted event. Required when `Enabled=true`; missing source -> `ErrMissingSource` |
| `Catalog(Catalog)` | Result of `streaming.NewCatalog(...)` | Immutable event registry. Missing or empty catalog -> `ErrInvalidEventDefinition` |
| `Routes(...RouteDefinition)` | Variadic. One route per `(definition, target, destination)` | At least one route is required for a non-trivial Build. Duplicate routes -> `ErrDuplicateRouteDefinition` |
| `Target(TargetConfig)` | One per logical transport runtime | `TargetConfig{Name, Kind, Brokers, ClientID}`. Multiple `Target` calls register multiple targets |

### Observability setters

| Setter | Argument | Purpose |
|---|---|---|
| `Logger(log.Logger)` | lib-observability logger | Used by producer runtime AND forwarded to per-target transport factories via `TransportAdapterOptions.Logger`. Persisted directly on the Builder so it survives factory dispatch |
| `MetricsFactory(*metrics.MetricsFactory)` | lib-observability factory | Registers `streaming_emitted_total`, `streaming_emit_duration_ms`, `streaming_dlq_total`, `streaming_dlq_publish_failed_total`, `streaming_outbox_routed_total`, `streaming_circuit_state` |
| `Tracer(trace.Tracer)` | OpenTelemetry tracer | Per-Emit spans carry `target.name`, `target.cb_state`, and `tenant.id` attributes; tenant is on spans, **not** metric labels |

### Resilience setters

| Setter | Argument | Default fallback | Purpose |
|---|---|---|---|
| `CircuitBreakerManager(circuitbreaker.Manager)` | lib-commons CB manager | none — required for tenant-aware breakers | Shares a process-level CB manager. When it satisfies `circuitbreaker.TenantAwareManager`, non-system events use `(tenant, target)`-scoped breakers |
| `CBFailureRatio(float64)` | trip ratio in (0.0, 1.0] | lib-commons HTTP preset (0.5) | Failure ratio that trips OPEN once `CBMinRequests` is reached |
| `CBMinRequests(int)` | min requests | lib-commons HTTP preset (10) | Minimum observations before the CB evaluates the ratio |
| `CBTimeout(time.Duration)` | OPEN dwell time | lib-commons HTTP preset (30s) | OPEN-state dwell AND tick interval for the CB recovery goroutine. Max recovery latency after broker recovery is bounded at `CBTimeout + 5s` |
| `CloseTimeout(time.Duration)` | drain budget | 30s | Caps producer Close drain+flush |

### Security setters

| Setter | Argument | Behaviour |
|---|---|---|
| `TLSConfig(*tls.Config)` | TLS config | Clone-and-store. `MinVersion` defaults to TLS 1.2; `InsecureSkipVerify=true` or explicit TLS 1.0/1.1 is rejected with `ErrInvalidTLSConfig`. Caller-set TLS 1.2 `CipherSuites` must be approved AEAD/ECDHE suites |
| `SASL(sasl.Mechanism)` | franz-go SASL mechanism | Requires TLS by default. Missing TLS -> `ErrPlaintextSASLNotAllowed` at Build time, before any broker I/O |
| `AllowPlaintextSASL()` | none | Opt-in **unsafe** override for local/dev brokers. Sends SASL credentials in cleartext — MUST NOT be used in production |
| `AllowSystemEvents()` | none | Opts the producer into accepting `SystemEvent=true` definitions. System events use `system:<eventType>` partition keys and skip tenant-scoped breakers |

### Outbox setters (boundary only)

| Setter | Argument | Notes |
|---|---|---|
| `OutboxRepository(outbox.OutboxRepository)` | lib-commons outbox repo | Most common path. Adapts the lib-commons outbox surface to lib-streaming's writer boundary |
| `OutboxWriter(OutboxWriter)` | custom writer | Last-call-wins with `OutboxRepository` |

The outbox semantics, transactional writer, envelope schema, and replay path are documented in **`ring:using-outbox`** — that skill is the canonical source. This skill only flags the Builder boundary.

### Partition key override

```go
b.PartitionKey(func(e streaming.Event) string {
    return e.TenantID + ":" + e.ResourceID
})
```

Nil `fn` is a no-op — the producer falls back to `Event.PartitionKey()`. Default tenant-scoped partitioning is appropriate for >95% of services; override only when you have a measured cardinality or ordering problem.

### Multi-transport target helpers

The library does **not** bundle AWS or AMQP SDKs. Each helper takes a caller-supplied client and registers both the target and its transport adapter factory in one call.

| Helper | Caller interface | Caller responsibility |
|---|---|---|
| `Builder.SQSTarget(name, client, defaultQueueURL)` | `SQSPublisherClient` (`SendMessage(ctx, queueURL, body, attributes) error`) | Adapt `aws-sdk-go-v2/service/sqs` (or any other SDK) into the small interface |
| `Builder.RabbitMQTarget(name, publisher)` | `RabbitMQPublisher` (`Publish(ctx, exchange, routingKey, contentType, body, headers) error`) | Wrap `amqp091-go` channel publish-with-confirm. Events-only — internal commands stay on `lib-commons/v5/commons/rabbitmq` |
| `Builder.EventBridgeTarget(name, client)` | `EventBridgePutEventsClient` (`PutEvents(ctx, entries) error`) | Adapt `aws-sdk-go-v2/service/eventbridge` |

Each interface optionally implements `Ping(ctx) error` — if present, `Adapter.Healthy` delegates to it. SQS and EventBridge adapters reject payloads larger than 256 KiB with `ErrPayloadTooLarge` before issuing any network call.

**Operational note (SQS):** `NewRouteDefinition` and `NewRouteTable` validate every SQS `Destination` via `ssrf.ResolveAndValidate`, which performs a synchronous DNS lookup at construction. A DNS outage at boot fails `Builder.Build`. Deploy with a healthy resolver in the pod/container network namespace.

### Custom transports

For SDK shapes not covered (Kinesis, Pub/Sub, NATS, ...), declare `streaming.TransportCustom` on the route `Destination` and register the adapter via `Builder.RegisterTransport(streaming.TransportCustom, factory)`. The factory receives `TransportAdapterOptions{Name, Brokers, Logger, Extra}` — `Extra` is the caller-typed payload from `Builder.TargetExtra(name, value)`.

### Destination helpers

| Helper | Returns |
|---|---|
| `streaming.KafkaTopic(topic)` | `Destination{Kind: TransportKafkaLike, Name: topic}` |
| `streaming.SQSQueueURL(queueURL)` | `Destination{Kind: TransportSQS, Address: queueURL}` |
| `streaming.RabbitMQRoute(exchange, routingKey)` | `Destination{Kind: TransportRabbitMQ, Name: exchange, Address: routingKey}` |
| `streaming.EventBridgeBus(busName)` | `Destination{Kind: TransportEventBridge, Name: busName}` |

### Route requirements

- `streaming.RouteRequired` — must succeed (or fall back to outbox) for `Emit` to return nil.
- `streaming.RouteOptional` — best-effort. Failures never propagate; surfaced via metrics and (when the route declares DLQ) the DLQ destination.

## Emit

The `Emitter` interface (alias for `contract.Emitter`) is three methods:

```go
type Emitter interface {
    Emit(ctx context.Context, request EmitRequest) error
    Close() error
    Healthy(ctx context.Context) error
}
```

Service code MUST depend on this interface. The Builder returns it from `Build(ctx)`. Three implementations satisfy it:

| Implementation | When | Construction |
|---|---|---|
| `*streaming.Producer` (returned as `Emitter`) | `STREAMING_ENABLED=true` | `Build(ctx)` |
| `*streaming.NoopEmitter` (returned as `Emitter`) | `STREAMING_ENABLED=false` or no brokers | `streaming.NewNoopEmitter()` |
| `*streamingtest.MockEmitter` | Unit tests | `streamingtest.NewMockEmitter()` |

### `EmitRequest` shape

```go
type EmitRequest struct {
    DefinitionKey  string                 // catalog key, e.g. "transaction.created"
    TenantID       string                 // becomes ce-tenantid; required for non-system events
    Subject        string                 // becomes ce-subject; aggregate ID is conventional
    EventID        string                 // optional; auto-generated UUIDv7 when empty
    Timestamp      time.Time              // optional; defaults to time.Now() at emit
    Payload        json.RawMessage        // body. Must be valid JSON; max 1 MiB
    PolicyOverride DeliveryPolicyOverride // optional per-call override
}
```

Emit example:

```go
err := emitter.Emit(ctx, streaming.EmitRequest{
    DefinitionKey: "transaction.created",
    TenantID:      tmcore.GetTenantIDContext(ctx),
    Subject:       tx.ID,
    Payload:       payloadBytes,
})
```

Service handlers MUST pull `TenantID` from the request context (e.g. `tmcore.GetTenantIDContext`), never hardcode.

### `*Producer` lifecycle

`*Producer` implements `lib-commons/v5/commons.App`. The consuming service's `main.go` wires it via `launcher.Add` / `launcher.RunApp`; the Launcher owns startup and shutdown. Service methods receive the `Emitter` interface and MUST NOT call `Close` — the Launcher does on shutdown.

Methods reachable only via type-assertion to `*streaming.Producer`:

| Method | When to call |
|---|---|
| `Run(launcher *commons.Launcher) error` | Bootstrap `main.go`; blocks until Launcher shutdown |
| `RunContext(ctx context.Context, launcher *commons.Launcher) error` | Bootstrap with caller-owned ctx |
| `CloseContext(ctx context.Context) error` | Initiates shutdown even when caller ctx is already canceled; flush + transport close run under fresh producer-owned deadlines |
| `Healthy(ctx context.Context) error` | Readiness probe |
| `RegisterOutboxRelay(registry *outbox.HandlerRegistry) error` | Wire the route-aware outbox replay handler — see `ring:using-outbox` |
| `Descriptor(base PublisherDescriptor) (PublisherDescriptor, error)` | Returns the validated descriptor with the per-process `ProducerID` populated. Feed into `BuildManifest` |

`Close` is idempotent: first call drains every registered target adapter under `STREAMING_CLOSE_TIMEOUT_S`; subsequent calls return nil. After Close, `Emit` returns `ErrEmitterClosed` synchronously before any I/O.

### Delivery policy precedence

```
definition default -> config override (STREAMING_EVENT_POLICIES) -> per-call PolicyOverride
```

Resolution lives in `streaming.ResolveDeliveryPolicy(definition, configOverride, callOverride)`. Three delivery modes compose:

| Type | Values | Effect |
|---|---|---|
| `DirectMode` | `DirectModeDirect`, `DirectModeSkip` | Whether the emit attempts direct broker publish |
| `OutboxMode` | `OutboxModeNever`, `OutboxModeFallbackOnCircuitOpen`, `OutboxModeAlways` | When to write the outbox envelope. `OutboxModeAlways` skips the broker entirely; `OutboxModeFallbackOnCircuitOpen` only writes when the breaker is OPEN AND an outbox writer is wired |
| `DLQMode` | `DLQModeNever`, `DLQModeOnRoutableFailure` | Whether failures route to the per-route DLQ. `DLQModeOnRoutableFailure` covers every `ErrorClass` except `ClassValidation` and `ClassContextCanceled` |

Three idiomatic postures match `ring:mapping-streaming-events` taxonomy:

| Posture | Direct | Outbox | DLQ | Use when |
|---|---|---|---|---|
| CRITICAL | `skip` | `always` | `on_routable_failure` | Loss is a correctness or compliance breach |
| IMPORTANT | `direct` | `fallback_on_circuit_open` | `on_routable_failure` | Direct normally; survives broker outage |
| OBSERVATIONAL | `direct` | `never` | `never` | Analytics-grade; loss acceptable |

### Multi-target fan-out semantics

A single `Emit` fanned out across N routes:

- Every `RouteRequired` route must succeed (or fall back to outbox) for `Emit` to return nil.
- Required-route failures aggregate into `*MultiEmitError`. `errors.Is` walks each `RouteError.Cause`; `errors.As` captures the first `*EmitError` in the chain.
- `IsCallerError` on `*MultiEmitError` returns true only when **every** required failure is itself caller-correctable. A single infrastructure-class failure flips the answer to false.
- `RouteOptional` failures never propagate. They surface via the metric counters and (when the route declares DLQ) the route's DLQ destination.

`streaming_emitted_total` increments **N times** per Emit fanned across N routes — one per route attempt. Dashboards computing "logical Emits per second" must aggregate per-Emit attempts via trace spans, not by summing per-route counters.

## Test

`github.com/LerianStudio/lib-streaming/streamingtest` is the public test-only helper package. `MockEmitter` is the only test double — concurrency-safe, deep-copying captured events on Emit so post-hoc caller mutation does not change the captured slice.

```go
mock := streamingtest.NewMockEmitter()
svc := NewTransactionService(mock)

if err := svc.Create(ctx, input); err != nil { t.Fatal(err) }

streamingtest.AssertEventEmitted(t, mock, "transaction.created")
streamingtest.AssertTenantID(t, mock, "t-abc")
streamingtest.AssertEventCount(t, mock, "transaction.created", 1)
streamingtest.AssertNoEvents(t, mock) // when expecting silence
```

### MockEmitter surface

| Method | Purpose |
|---|---|
| `Emit(ctx, EmitRequest) error` | Captures a deep copy; returns the injected error when one is set |
| `Requests() []EmitRequest` | Returns a deep-copied snapshot in emission order |
| `SetError(err error)` | Subsequent `Emit` calls return err without capturing |
| `Reset()` | Clears captured buffer and injected error |
| `Close() error` / `Healthy(ctx) error` | Idempotent no-ops |

### Assertion helpers

| Helper | Fails when |
|---|---|
| `AssertEventEmitted(t, m, key)` | No captured request has the given definition key |
| `AssertEventCount(t, m, key, n)` | Count of captured events matching key != n |
| `AssertTenantID(t, m, tenantID)` | No captured event carries the tenant ID |
| `AssertNoEvents(t, m)` | Any event was captured |
| `WaitForEvent(t, ctx, m, matcher, timeout)` | Matcher does not return true on a captured request within timeout |

`WaitForEvent` polls at 1ms — fast wall-clock convergence and fully deterministic under `testing/synctest`. Nil matcher fails the test cleanly instead of panicking mid-loop.

Mocks and real `*Producer` and `NoopEmitter` all satisfy the same three-method `Emitter` interface — write services against the interface, swap implementations in tests.

## Manifest

```go
descriptor, err := streaming.NewPublisherDescriptor(streaming.PublisherDescriptor{
    Service:   "ledger",
    Version:   buildinfo.Version,
    Repo:      "github.com/LerianStudio/ledger",
})
if err != nil { return err }

doc, err := streaming.BuildManifest(descriptor, catalog, routeTable)
// doc.Routes is populated and JSON-stable when len(routeTable) > 0;
// pass an empty RouteTable for a catalog-only document.

handler, err := streaming.NewStreamingHandler(
    descriptor,
    catalog,
    streaming.WithManifestRoutes(routeTable),
)
if err != nil { return err }
mux.Handle("/streaming/manifest", authMiddleware(handler))
```

| Helper | Purpose |
|---|---|
| `streaming.NewPublisherDescriptor(d)` | Validates service / version / repo / contact metadata |
| `streaming.BuildManifest(descriptor, catalog, routes)` | Returns a JSON-serializable `ManifestDocument`. Routes are deterministically ordered (definition key, then route key) for byte-stable output |
| `streaming.NewStreamingHandler(descriptor, catalog, opts ...HandlerOption)` | Returns a stdlib `http.Handler` serving the manifest. Pre-marshals at construction; serves cached bytes |
| `streaming.WithManifestRoutes(routes)` | Attaches a route table to the handler. Without it, the handler serves a catalog-only manifest |
| `streaming.ManifestVersion` | Wire-version constant |
| `(*Producer).Descriptor(base)` | Returns descriptor with per-process `ProducerID` populated |

**SECURITY:** the manifest exposes event taxonomy, schema versions, service metadata, producer IDs, and (when routes are advertised) target names, transport kinds, sanitized broker URLs, and DLQ destinations. Callers MUST wrap the handler in their app's auth middleware before mounting it publicly. The library does not enforce authentication.

Handler-shipped hardening (independent of the caller's auth chain):

- `Cache-Control: no-store`
- `Content-Type: application/json`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- HTTP method allowlist (GET, HEAD only)

## CloudEvents codec

For interop layers that consume from non-lib-streaming producers or need to roundtrip an `Event` through Kafka headers:

```go
headers := streaming.BuildCloudEventsHeaders(event)
// headers = []kgo.RecordHeader, 8-13 entries depending on optional fields

event, err := streaming.ParseCloudEventsHeaders(headers)
// errors.Is(err, streaming.ErrMissingRequiredHeader) for missing context attrs
// errors.Is(err, streaming.ErrUnsupportedSpecVersion) for non-1.0 ce-specversion
```

The producer path gets canonical bytes automatically through `Emit`. Use these helpers only when you have a direct CloudEvents Kafka interop need outside the lib-streaming hot path. `ce-resourcetype` and `ce-eventtype` are accepted as optional extensions on parse so non-lib-streaming producers can still be parsed (they are populated from the `ce-type` breakdown when absent).

## Errors

### Sentinels (29 total)

Use `errors.Is(err, sentinel)` for branch logic and `IsCallerError(err)` for the broad caller-vs-infrastructure split.

**Caller-side validation (synchronous, no I/O — `IsCallerError` returns true):**

`ErrMissingTenantID`, `ErrSystemEventsNotAllowed`, `ErrMissingSource`, `ErrMissingResourceType`, `ErrMissingEventType`, `ErrInvalidTenantID`, `ErrInvalidResourceType`, `ErrInvalidEventType`, `ErrInvalidSource`, `ErrInvalidSubject`, `ErrInvalidEventID`, `ErrInvalidSchemaVersion`, `ErrInvalidDataContentType`, `ErrInvalidDataSchema`, `ErrPayloadTooLarge`, `ErrNotJSON`, `ErrEventDisabled`, `ErrInvalidEventDefinition`, `ErrInvalidOutboxEnvelope`, `ErrDuplicateEventDefinition`, `ErrUnknownEventDefinition`, `ErrInvalidDeliveryPolicy`, `ErrInvalidPublisherDescriptor`, `ErrInvalidRouteDefinition`, `ErrInvalidDestination`, `ErrDuplicateRouteDefinition`, `ErrNoRoutesConfigured`, `ErrMissingTarget`, `ErrMultiTransportRuntimeNotConfigured`, `ErrInvalidTLSConfig`, `ErrPlaintextSASLNotAllowed`.

**Config validation (`LoadConfig`):**

`ErrMissingBrokers`, `ErrMissingSource`, `ErrInvalidCompression`, `ErrInvalidAcks`, `ErrInvalidConfigField`.

**Lifecycle / wiring (NOT caller errors — `IsCallerError` returns false):**

`ErrEmitterClosed`, `ErrNilProducer`, `ErrCircuitOpen`, `ErrOutboxNotConfigured`, `ErrOutboxTxUnsupported`, `ErrNilOutboxRegistry`.

**CloudEvents codec:**

`ErrMissingRequiredHeader`, `ErrUnsupportedSpecVersion`.

### Error classes

Runtime publish failures surface as `*EmitError` with one of eight `ErrorClass` values:

| Class | DLQ routed | Caller-correctable |
|---|---|---|
| `ClassSerialization` | yes | yes |
| `ClassValidation` | no | yes |
| `ClassAuth` | yes | yes (deployment config fault) |
| `ClassTopicNotFound` | yes | no |
| `ClassBrokerUnavailable` | yes | no |
| `ClassNetworkTimeout` | yes | no |
| `ClassContextCanceled` | no | no |
| `ClassBrokerOverloaded` | yes | no |

### `IsCallerError(err) bool`

The single decision function. Returns true for caller-correctable faults — empty tenant ID, malformed payload, missing source, etc. Returns false for broker unavailability, circuit open, network timeout, lifecycle violations.

For `*MultiEmitError`: returns true only when **every** Required-route failure is itself caller-correctable. A single infrastructure-class failure in the Required set flips the answer to false.

Recommended response shape in handlers:

```go
if err := emitter.Emit(ctx, request); err != nil {
    if streaming.IsCallerError(err) {
        return badRequest(err) // 4xx
    }
    return internalError(err)  // 5xx, alertable
}
```

## End-to-end Builder example

The canonical bootstrap reference. Mirror the order; the only optional setters are the resilience / security / outbox lines — the rest are required for a non-trivial Build.

```go
cfg, warnings, err := streaming.LoadConfig()
if err != nil { return err }
for _, w := range warnings { logger.Log(ctx, log.LevelWarn, w) }

// 1. Panic + assertion metrics, production-mode scrubbing.
runtime.InitPanicMetrics(metricsFactory)
assert.InitAssertionMetrics(metricsFactory)
runtime.SetProductionMode(cfg.Env == "production")

// 2. Immutable catalog.
catalog, err := streaming.NewCatalog(
    streaming.EventDefinition{
        Key: "transaction.created", ResourceType: "transaction", EventType: "created",
        SchemaVersion: "1.0.0",
    },
    streaming.EventDefinition{
        Key: "transaction.posted", ResourceType: "transaction", EventType: "posted",
        SchemaVersion: "1.0.0",
    },
)
if err != nil { return err }

// 3. Disabled-feature-flag fallback BEFORE Builder construction.
if !cfg.Enabled || len(cfg.Brokers) == 0 {
    return inject(streaming.NewNoopEmitter())
}

// 4. Builder chain. Setters are nil-receiver safe and chainable.
emitter, err := streaming.NewBuilder().
    Source(cfg.CloudEventsSource).
    Catalog(catalog).
    Routes(
        streaming.RouteDefinition{
            Key:           "transaction.created.kafka.primary",
            DefinitionKey: "transaction.created",
            Target:        "kafka-primary",
            Destination:   streaming.KafkaTopic("lerian.streaming.transaction.created"),
            Requirement:   streaming.RouteRequired,
        },
        streaming.RouteDefinition{
            Key:           "transaction.created.sqs.shadow",
            DefinitionKey: "transaction.created",
            Target:        "sqs-shadow",
            Destination:   streaming.SQSQueueURL("https://sqs.us-east-1.amazonaws.com/123/q"),
            Requirement:   streaming.RouteOptional,
        },
    ).
    Target(streaming.TargetConfig{
        Name:    "kafka-primary",
        Kind:    streaming.TransportKafkaLike,
        Brokers: cfg.Brokers,
    }).
    SQSTarget("sqs-shadow", sqsClient, "https://sqs.us-east-1.amazonaws.com/123/q").
    Logger(logger).
    MetricsFactory(metricsFactory).
    Tracer(tracer).
    CircuitBreakerManager(cbManager).
    CBFailureRatio(0.5).
    CBMinRequests(10).
    CBTimeout(30 * time.Second).
    TLSConfig(tlsCfg).
    SASL(saslMechanism).
    OutboxRepository(outboxRepo).
    CloseTimeout(30 * time.Second).
    Build(ctx)
if err != nil { return err }

// 5. Lifecycle hand-off. Type-assert ONLY here, not in service code.
producer := emitter.(*streaming.Producer)
if err := producer.RegisterOutboxRelay(outboxRegistry); err != nil { return err }
if err := launcher.Add("streaming", producer); err != nil { return err }

// 6. Manifest HTTP mount, wrapped in the app's auth middleware.
descriptor, err := producer.Descriptor(streaming.PublisherDescriptor{
    Service: "ledger", Version: buildinfo.Version, Repo: "github.com/LerianStudio/ledger",
})
if err != nil { return err }

handler, err := streaming.NewStreamingHandler(
    descriptor,
    catalog,
    streaming.WithManifestRoutes(routeTable),
)
if err != nil { return err }
mux.Handle("/streaming/manifest", authMiddleware(handler))

// 7. Inject the interface, NOT the concrete *Producer, into services.
return inject(emitter)
```

Service code stays unaware of the wiring:

```go
func NewTransactionService(emitter streaming.Emitter) *TransactionService {
    return &TransactionService{emitter: emitter}
}

func (s *TransactionService) Create(ctx context.Context, input CreateTransactionInput) error {
    // ... domain logic, durable commit ...
    payload, err := json.Marshal(transactionEvent(tx))
    if err != nil { return err }

    return s.emitter.Emit(ctx, streaming.EmitRequest{
        DefinitionKey: "transaction.created",
        TenantID:      tmcore.GetTenantIDContext(ctx),
        Subject:       tx.ID,
        Payload:       payload,
    })
}
```
