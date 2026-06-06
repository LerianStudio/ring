---
name: ring:instrumenting-streaming-events
description: "Instrumenting streaming events: wires lib-streaming event emission end-to-end into a Lerian Go service via a 13-gate cycle (catalog, Builder bootstrap, Emit sites, outbox, HTTP manifest, NoopEmitter fallback, integration and chaos tests), dispatching ring:backend-go under TDD. Consumes the validated instrumentation-map.json from ring:mapping-streaming-events. Use after that map exists. Skip for non-Go or when no map is present."
---

# Streaming Instrumentation (lib-streaming)

## When to use
- User requests streaming instrumentation for a Go service with a validated docs/streaming/instrumentation-map.json from ring:mapping-streaming-events
- Task mentions "wire lib-streaming", "instrument streaming events", "implement event emission", "add streaming.NewBuilder", "Emit business events", "lib-streaming bootstrap"

## Skip when
- Service is not a Go project
- No instrumentation-map.json present (run ring:mapping-streaming-events first)


You orchestrate. Agents implement. NEVER use Edit/Write/Bash on Go source files.
All code changes go through `Task(subagent_type="ring:backend-go")`.
TDD mandatory for all implementation gates (RED → GREEN → REFACTOR).

## Streaming Architecture

lib-streaming: producer-only event-emission library. Three-step lifecycle:

1. `streaming.NewCatalog(definitions ...EventDefinition) (Catalog, error)` — declare every event up-front (immutable)
2. `streaming.NewBuilder().Source(...).Catalog(catalog).Routes(...).Target(...).Logger(...).MetricsFactory(...).Tracer(...).CircuitBreakerManager(...).OutboxRepository(...).Build(ctx)` — Builder pattern returns `(Emitter, error)`. There is NO `NewProducer` constructor; `*streaming.Producer` is reachable only by type-asserting the `Emitter` returned from `Build(ctx)`, and only when lifecycle methods (`Run`, `RunContext`, `RegisterOutboxRelay`) are needed.
3. `emitter.Emit(ctx, EmitRequest{DefinitionKey, TenantID, Subject, Payload})` from handlers/workers

The `Emitter` interface has THREE methods — `Emit(ctx, EmitRequest) error`, `Close() error`, `Healthy(ctx) error`. Mocks and adapters MUST implement all three.

Wire format: CloudEvents 1.0 binary mode. Each `RouteDefinition` picks a transport: Kafka (topic `lerian.streaming.<resource>.<event>[.vN]`), SQS (queue URL), RabbitMQ (exchange + routing key), EventBridge (bus name), or Custom. Tenant carried on `ce-tenantid` header for CloudEvents-binary transports.

**WebFetch URLs (include in every gate dispatch):**
- `https://raw.githubusercontent.com/LerianStudio/lib-streaming/main/doc.go`
- `https://raw.githubusercontent.com/LerianStudio/lib-streaming/main/AGENTS.md`
- `https://raw.githubusercontent.com/LerianStudio/lib-streaming/main/CHANGELOG.md`

**Three delivery postures:**

| Posture | Direct | Outbox | DLQ | Use when |
|---------|--------|--------|-----|----------|
| CRITICAL | skip | always | on_routable_failure | Loss is correctness/compliance breach |
| IMPORTANT | direct | fallback_on_circuit_open | on_routable_failure | Direct normally; survives broker outage |
| OBSERVATIONAL | direct | never | never | Analytics-grade; loss acceptable |
| CUSTOM | per-event | per-event | per-event | None of the above fits |

**Canonical import paths:**

| Alias | Import Path | Purpose |
|-------|-------------|---------|
| `streaming` | `github.com/LerianStudio/lib-streaming` | Producer, Emitter, NewCatalog, EventDefinition |
| `streamingtest` | `github.com/LerianStudio/lib-streaming/streamingtest` | MockEmitter (test-only) |
| `outbox` | `github.com/LerianStudio/lib-commons/v5/commons/outbox` | Only when Gate 5 active |

**Emitter implementations:**

| Implementation | When | Construction |
|----------------|------|--------------|
| `*streaming.Producer` (returned as `Emitter`) | `STREAMING_ENABLED=true` | `streaming.NewBuilder().Catalog(catalog).Source(src).Routes(routes...).Target(target).Logger(log).MetricsFactory(mf).Tracer(tr).Build(ctx)` |
| NoopEmitter | `STREAMING_ENABLED=false` | `streaming.NewNoopEmitter()` |
| `*streamingtest.MockEmitter` | Tests | `streamingtest.NewMockEmitter()` |

Service code depends on `streaming.Emitter` INTERFACE. MUST NOT type-assert to `*Producer` except in bootstrap to wire `Run(launcher)` / `RunContext(ctx, launcher)` / `RegisterOutboxRelay(registry)`. All three implementations satisfy the full three-method interface (`Emit`, `Close`, `Healthy`).

**Mandatory agent instruction (include in EVERY dispatch):**

> WebFetch `https://raw.githubusercontent.com/LerianStudio/lib-streaming/main/doc.go` and `AGENTS.md`.
> `docs/streaming/instrumentation-map.json` is the canonical contract — every EventDefinition, Emit site, DeliveryPolicy MUST match exactly.
> Tenant from `tmcore.GetTenantIDContext(ctx)` — NEVER hardcode.
> TDD: RED → GREEN → REFACTOR for every gate.

## Gate Overview

| Gate | Name | Condition | Agent |
|------|------|-----------|-------|
| 0 | Stack Detection + JSON Validation + Compliance Audit | Always | Orchestrator |
| 1 | Codebase Analysis | Always | ring:codebase-explorer |
| 1.5 | Visual Implementation Preview | Always; user must approve | ring:visualizing |
| 2 | lib-streaming Dependency + Non-Canonical Removal | Skip only if lib-streaming pinned AND zero non-canonical detected | ring:backend-go |
| 3 | Catalog Construction + Builder Bootstrap | Always | ring:backend-go |
| 4 | Emit Instrumentation per Eventable Point | Always | ring:backend-go |
| 5 | Outbox Wiring | Required if any event has `outbox != "never"` | ring:backend-go |
| 6 | Manifest HTTP Mount | Required unless service has zero HTTP surface | ring:backend-go |
| 7 | Wiring + Lifecycle + Backward Compat | Always — NEVER skippable | ring:backend-go |
| 8 | Tests | Always | ring:backend-go |
| 9 | Code Review | Always | 9 defaults + triggered specialists in parallel |
| 10 | User Validation | Always | User |
| 11 | Activation Guide | Always | Orchestrator |

Gates execute sequentially. Gate 5 skip: only if zero events have outbox != "never". Gate 6 skip: only if service has zero HTTP surface (justify in report).

## Gate 0: Stack Detection

Orchestrator executes directly. Runs 3 phases:

**Phase 1: Stack Detection**
```bash
grep "lib-streaming" go.mod
grep "lib-commons" go.mod
grep -rn "postgresql\|pgx" internal/ go.mod
grep -rn "outbox" go.mod
grep -rn "fiber\|gin\|echo\|net/http" internal/
# Existing lib-streaming code:
grep -rn "streaming.NewBuilder\|streaming.NewCatalog\|streaming.NewNoopEmitter\|streaming.Emitter\|streaming.Producer" internal/
# Non-canonical (must remove):
grep -rn "sarama\|watermill\|segmentio/kafka-go\|amqp091.Publish\|franz-go" internal/
```

**Phase 2: instrumentation-map.json Validation**
```
Read docs/streaming/instrumentation-map.json
Validate: JSON well-formed, required fields present (service_name, events[])
Each event must have: definition_key, resource, event_type, delivery_policy
delivery_policy must have: direct (bool), outbox (enum), dlq (string)
CRITICAL events must have outbox = "always"
```

**Phase 3: Existing Compliance Audit** (if lib-streaming code detected)
- Construction uses `streaming.NewBuilder()...Build(ctx)` — NOT a hand-rolled `NewProducer` shim
- `.Catalog(catalog)` builder method invoked before `.Build(ctx)`
- `.Source(...)`, `.Routes(...)`, `.Target(...)` configured (Builder fails fast on missing required wiring)
- Target names contain no control characters and are ≤256 bytes (Builder validates; service must construct safe names)
- `STREAMING_ENABLED` feature flag present
- `commons.Launcher.Add` (or `Run`/`RunContext`) lifecycle wiring; `Close()` on shutdown
- `Healthy(ctx)` wired into readiness probe
- No non-canonical alternatives

## State Management

State: `docs/ring:instrumenting-streaming-events/current-cycle.json`

Write state after EVERY gate. If write fails → STOP.

```json
{
  "service_name": "",
  "started_at": "",
  "gates_completed": [],
  "detected": { "lib_streaming_pinned": false, "has_http": false, "outbox_required": false },
  "instrumentation_map_path": "docs/streaming/instrumentation-map.json",
  "tasks": []
}
```

## Severity Reference

| Severity | Criteria |
|----------|----------|
| CRITICAL | Builder without `.Catalog()`; CRITICAL event with `outbox=never`; manifest unauthenticated; pre-commit emission; service code type-asserting `*Producer` outside bootstrap |
| HIGH | No `Launcher.Add` / `Run` / `RunContext`; no `Close()`; `Healthy()` not wired to readiness; non-canonical code present; `STREAMING_ENABLED` missing; target name with control chars or >256 bytes |
| MEDIUM | Missing `.Logger()` / `.Tracer()` / `.MetricsFactory()` on Builder; no MockEmitter unit tests; no chaos coverage when outbox required |
| LOW | Documentation gaps, missing comments |
