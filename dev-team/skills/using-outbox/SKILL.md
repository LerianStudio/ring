---
name: ring:using-outbox
description: Dual-mode skill for the transactional outbox pattern across lib-streaming (writer side) and lib-commons/v5/commons/outbox (repository + relay side). Sweep Mode dispatches 6 parallel explorers to find DIY outbox tables, hand-rolled relay loops, send-and-pray emits, missing WithOutboxTx wrapping, synchronous broker calls inside DB transactions, and hand-rolled idempotency keys. Reference Mode catalogs OutboxWriter / TransactionalOutboxWriter / WithOutboxTx / OutboxRepository / OutboxEnvelope plus relay wiring. Skip for non-Go services or services that emit nothing.
---

# ring:using-outbox

## When to use
Sweep mode:
- "Sweep for transactional outbox violations"
- "Find send-and-pray emits"
- "Are we wrapping DB transactions with WithOutboxTx?"
- "Migrate this service from DIY outbox to lib-streaming + lib-commons/outbox"
- "Audit relay loops for hand-rolled poller patterns"

Reference mode:
- "How does the transactional outbox pattern work?"
- "Which writer interface do I implement for X?"
- "What goes in OutboxEnvelope?"
- "How do I wire the relay loop?"
- "How does WithOutboxTx interact with MongoDB sessions?"

## Skip when
- Working on non-Go services
- Service has no events to emit (pure read-side, BFF)
- Working on frontend code

## Related
**Parent surface:** ring:using-lib-streaming (full streaming bus)
**Repository side:** ring:using-lib-commons (lib-commons/outbox dispatcher, repository, handler registry)
**Adjacent:** ring:dev-streaming-instrumentation (eventable-point identification → emit wiring), ring:using-runtime (panic-safe relay loops), ring:using-assert (invariant checks on envelope decode)

---

## The Pattern

The transactional outbox solves one operational invariant: **business state and the event that announces it must commit atomically, or not at all**. Without it, three failure modes are inevitable in production:

1. **Lost event.** Business state commits, the producer calls `broker.Emit`, the broker is down or the network blips — the event vanishes. The ledger now believes a transaction happened that no downstream consumer ever heard about.
2. **Phantom event.** Producer emits successfully, then the DB commit fails. Downstream consumers now act on a transaction that never happened.
3. **Send-and-pray.** Code paths that emit on a best-effort basis "and we'll log it if it fails" — a polite name for systematic data loss under sustained broker outages.

The outbox pattern fixes this by **writing the event to an `outbox` table inside the same database transaction as the business state**. Commit is atomic: either both rows persist or neither does. A separate process — the **relay** (also called dispatcher or poller) — reads pending outbox rows and publishes them to the broker, marking each row `PUBLISHED` on success. Delivery becomes at-least-once: if the relay crashes between publish and mark, the row stays pending and the next cycle retries. Consumers must be idempotent — that is the cost of at-least-once.

In lib-streaming the producer also uses the outbox as a **circuit-breaker fallback**. When a target's circuit is OPEN, `Emit` writes a route-aware `OutboxEnvelope` instead of attempting the broker call. When the breaker closes, the relay drains the backlog through the *originating target's adapter* — bypassing `Emit` itself, so replays cannot re-enter the circuit and cannot re-enqueue themselves. This is what `OutboxModeFallbackOnCircuitOpen` (the default) buys you: a broker outage degrades to a write-ahead log instead of dropped events.

## Mode Selection

| Request Shape | Mode |
|---|---|
| "Sweep / audit / find DIY outbox / send-and-pray" | **Sweep** |
| "How does the pattern work?" | **Reference** |
| "Which interface do I implement?" | **Reference** |
| "How do I wire WithOutboxTx in my repository layer?" | **Reference** |
| "What is the OutboxEnvelope wire format?" | **Reference** |

---

# SWEEP MODE

Dispatch 6 explorers in **one parallel batch**. Each writes its findings JSON; a synthesizer consolidates.

```
Phase 1: Outbox surface reconnaissance → outbox-surface.json
Phase 2: Multi-angle DIY sweep         → 6 × outbox-sweep-{N}-{angle}.json
Phase 3: Consolidated report           → outbox-sweep-report.md + outbox-sweep-tasks.json
```

## Phase 1: Surface Reconnaissance

Before sweeping, determine what the service currently does:

1. Grep for `lib-streaming` and `lib-commons/v5/commons/outbox` imports in `go.mod` / source.
2. Locate broker-publish call sites (any of: `Emit`, `kafka.Produce`, `sqs.SendMessage`, `rabbitmq.Publish`, custom wrappers).
3. Locate DB-transaction boundaries (`db.BeginTx`, `*sql.Tx`, repository transactional helpers).
4. Emit `/tmp/outbox-surface.json`:

```json
{
  "uses_lib_streaming": true,
  "uses_lib_commons_outbox": true,
  "broker_call_sites": [{"file": "...", "line": 0, "kind": "kafka|sqs|rabbitmq|custom"}],
  "tx_boundaries": [{"file": "...", "line": 0}],
  "has_outbox_table_migration": true,
  "has_relay_loop": false
}
```

If `uses_lib_streaming=false` AND `broker_call_sites` is non-empty → flag as high-risk send-and-pray candidate before angle dispatch.

## Phase 2: 6-Angle DIY Sweep

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

Dispatch all 6 in parallel (`subagent_type: ring:codebase-explorer`). Each writes one JSON file.

### Angle 1 — DIY outbox tables without OutboxEnvelope wire format (CRITICAL)

**Look for:**
- Tables named `outbox`, `event_outbox`, `pending_events`, `tx_outbox`, etc. **not** populated through `lib-commons/v5/commons/outbox.OutboxRepository`.
- Custom JSON payload shapes that omit `version`, `route_key`, `definition_key`, `target`, `transport`, `destination`, `aggregate_id`, `requirement`, `policy`, `event` — the canonical `OutboxEnvelope` fields.
- Custom `event_type` strings that are not `"lerian.streaming.publish"` (`StreamingOutboxEventType`).

**Replacement:** Use `outbox.OutboxRepository` for persistence; let lib-streaming build the envelope via `WithOutboxRepository(repo)`. The envelope wire format is the authoritative shape — diverging from it makes the row un-replayable by the canonical relay handler.

**Evidence to capture:** Migration file path + line of the column DDL, and the Go file populating it.

### Angle 2 — Hand-rolled relay loops / pollers (CRITICAL)

**Look for:**
- `for { ... time.Sleep(...) ... SELECT ... FROM outbox WHERE status = 'PENDING' ... }` patterns.
- Hand-rolled `SELECT ... FOR UPDATE SKIP LOCKED` claim queries.
- Custom backoff, retry, batch sizing, and dead-event handling logic outside `outbox.Dispatcher`.
- Goroutines that publish from a pending table without using `outbox.HandlerRegistry`.

**Replacement:** `outbox.NewDispatcher(repo, handlers, logger, tracer, opts...)` with `Producer.RegisterOutboxRelay(handlers)` to bind the `lerian.streaming.publish` handler. Defaults: `DispatchInterval=2s`, `BatchSize=50`, `MaxDispatchAttempts=10`, `RetryWindow=5m`, `ProcessingTimeout=10m`.

**Why it matters:** Hand-rolled relays universally miss one or more of: priority event types, stuck-PROCESSING reclaim, per-tenant fairness, retry classification, observability trident on publish failure. The lib-commons dispatcher gets these right.

### Angle 3 — Send-and-pray emits (CRITICAL)

**Look for:**
- Broker calls (`Emit`, `Produce`, `SendMessage`, `Publish`) inside DB-transactional code paths **without** a preceding `streaming.WithOutboxTx(ctx, tx)` wrap.
- The pattern `tx.Commit(); broker.Emit(...)` — commit succeeds, broker call fails, event lost forever.
- The pattern `broker.Emit(...); tx.Commit()` — broker call succeeds, commit fails, phantom event.
- Comments like `// best effort emit`, `// log if fails`, `// fire and forget`.
- `go func() { broker.Emit(...) }()` after a transactional path.

**Replacement:** Wrap the transaction context: `ctx = streaming.WithOutboxTx(ctx, tx); err := emitter.Emit(ctx, req)`. If the circuit is open, the envelope joins the SQL transaction via `TransactionalOutboxWriter.WriteWithTx`. If the broker is healthy, direct publish proceeds normally — outbox is the fallback path. Either way, atomicity is preserved.

**Severity rationale:** Every send-and-pray site is a confirmed data-loss vector. Mark CRITICAL even if "it has never happened in production" — sample size of one outage produces the bug.

### Angle 4 — Missing WithOutboxTx wrapping (HIGH)

**Look for:**
- Service methods that take `*sql.Tx` (or wrap one) AND call `emitter.Emit` without `streaming.WithOutboxTx(ctx, tx)` first.
- Repository helpers that begin a transaction internally and emit events without exposing the tx to outbox plumbing.
- MongoDB session contexts: the same rule applies — emits inside a `mongo.SessionContext` (v1 driver) ride the session through `Write(ctx, ...)`; emits outside a session lose atomicity. Driver v2 session contexts are **not joined** by the v1 repository path — flag any v2 session passed to emit as an integration gap.

**Replacement:** Standardize transactional code paths to:
```go
err := db.RunInTx(ctx, func(ctx context.Context, tx *sql.Tx) error {
    if err := repo.SaveBusinessState(ctx, tx, state); err != nil { return err }
    ctx = streaming.WithOutboxTx(ctx, tx)
    return emitter.Emit(ctx, streaming.EmitRequest{ ... })
})
```

**Diagnostic:** If `errors.Is(err, streaming.ErrOutboxTxUnsupported)` surfaces in logs, the writer is not a `TransactionalOutboxWriter` — either the wrong writer was wired, or a non-`*sql.Tx` value sat on `txContextKey`. Both are wiring bugs, not runtime failures.

### Angle 5 — Hand-rolled idempotency keys instead of outbox-provided dedup (MEDIUM)

**Look for:**
- Custom `processed_events` / `emitted_events` tables tracking which events have been emitted.
- Code paths that read business state, hash it, and use that hash to skip duplicate emits.
- Application-layer dedup that exists *because* the team did not trust the broker path.

**Replacement:** The outbox row itself is the idempotency key. Once committed in the transaction, it will be published exactly once successfully (the relay marks PUBLISHED on success) and possibly multiple times on consumer side (at-least-once). Consumer-side dedup belongs at the consumer; producer-side dedup tables are usually a workaround for missing outbox.

**Subtlety:** Distinguish from legitimate consumer idempotency (e.g., `commons/idempotency` for HTTP request dedup or `commons/dlq` for retry-queue dedup). Those serve different concerns and are not replaced by the outbox.

### Angle 6 — Synchronous broker calls inside DB transactions (HIGH)

**Look for:**
- `BeginTx` → `broker.Publish(...)` → `Commit()`. The broker call is now inside the transaction; broker latency stretches transaction duration; broker timeout aborts the transaction; broker hang blocks the connection pool slot.
- Custom code that "pre-flights" the broker before committing the tx, on the theory of "if we can't publish, don't commit."

**Replacement:** Never call the broker synchronously inside an open transaction. Either:
- Use `WithOutboxTx` (envelope joins the tx, broker is decoupled), or
- Defer the emit to after `Commit()` and accept the small at-most-once gap (only safe for non-critical events).

**Why it matters:** Synchronous broker-in-tx is the classic distributed-systems anti-pattern — it couples two failure domains that should be independent and inverts the latency profile of both.

## Phase 3: Consolidated Report

Dispatch synthesizer:

```
Read /tmp/outbox-surface.json and /tmp/outbox-sweep-*.json (6 files).
Emit:
1. /tmp/outbox-sweep-report.md — findings grouped by severity (CRITICAL → MEDIUM)
2. /tmp/outbox-sweep-tasks.json — one task per cluster (same file or repository = one task)

MUST NOT invent findings. MUST cite file:line for every finding. MUST preserve
explorer severity unless evidence contradicts it (justify in notes).
```

Surface the report path + task count; offer handoff to `ring:dev-cycle`.

---

# REFERENCE MODE

## API Catalog

### Writer side (`github.com/LerianStudio/lib-streaming`)

```go
// Minimal durable-write boundary. Custom outbox stores adapt this interface.
type OutboxWriter interface {
    Write(ctx context.Context, envelope OutboxEnvelope) error
}

// Joins an ambient *sql.Tx so the envelope persists inside the caller's
// unit of work. lib-streaming's built-in adapter (libCommonsOutboxWriter)
// implements this when wired via WithOutboxRepository against a SQL repo.
type TransactionalOutboxWriter interface {
    OutboxWriter
    WriteWithTx(ctx context.Context, tx *sql.Tx, envelope OutboxEnvelope) error
}

// Stores an ambient *sql.Tx on ctx for transactional outbox writes.
// The publish path strict-asserts the value type: a non-*sql.Tx on
// txContextKey returns ErrOutboxTxUnsupported (wiring bug).
func WithOutboxTx(ctx context.Context, tx *sql.Tx) context.Context

// Producer options (mutually exclusive — last call wins).
// Mixing them is safe only when the custom writer implements
// TransactionalOutboxWriter; otherwise tx-mode emits fail at runtime.
func WithOutboxRepository(repo outbox.OutboxRepository) EmitterOption
func WithOutboxWriter(writer OutboxWriter) EmitterOption

// Producer method — wires the canonical relay handler under the stable
// event type "lerian.streaming.publish".
func (p *Producer) RegisterOutboxRelay(registry *outbox.HandlerRegistry) error
```

### Repository side (`github.com/LerianStudio/lib-commons/v5/commons/outbox`)

```go
type OutboxRepository interface {
    Create(ctx context.Context, event *OutboxEvent) (*OutboxEvent, error)
    CreateWithTx(ctx context.Context, tx *sql.Tx, event *OutboxEvent) (*OutboxEvent, error)
    ListPending(ctx context.Context, limit int) ([]*OutboxEvent, error)
    ListPendingByType(ctx context.Context, eventType string, limit int) ([]*OutboxEvent, error)
    ListTenants(ctx context.Context) ([]string, error)
    GetByID(ctx context.Context, id uuid.UUID) (*OutboxEvent, error)
    MarkPublished(ctx context.Context, id uuid.UUID, publishedAt time.Time) error
    MarkFailed(ctx context.Context, id uuid.UUID, errMsg string, maxAttempts int) error
    ListFailedForRetry(ctx context.Context, limit int, before time.Time, maxAttempts int) ([]*OutboxEvent, error)
    ResetForRetry(ctx context.Context, limit int, before time.Time, maxAttempts int) ([]*OutboxEvent, error)
    ResetStuckProcessing(ctx context.Context, limit int, before time.Time, maxAttempts int) ([]*OutboxEvent, error)
    MarkInvalid(ctx context.Context, id uuid.UUID, errMsg string) error
}

// Built-in implementations:
//   github.com/LerianStudio/lib-commons/v5/commons/outbox/postgres
//   github.com/LerianStudio/lib-commons/v5/commons/outbox/mongo

// Handler dispatch.
type EventHandler func(ctx context.Context, event *OutboxEvent) error

type HandlerRegistry struct { /* ... */ }
func NewHandlerRegistry() *HandlerRegistry
func (r *HandlerRegistry) Register(eventType string, handler EventHandler) error
func (r *HandlerRegistry) Handle(ctx context.Context, event *OutboxEvent) error

// Relay loop.
func NewDispatcher(
    repo OutboxRepository,
    handlers *HandlerRegistry,
    logger libLog.Logger,
    tracer trace.Tracer,
    opts ...DispatcherOption,
) (*Dispatcher, error)

func (d *Dispatcher) Run(launcher *libCommons.Launcher) error
func (d *Dispatcher) RunContext(ctx context.Context, launcher *libCommons.Launcher) error
func (d *Dispatcher) Stop()
func (d *Dispatcher) Shutdown(ctx context.Context) error
func (d *Dispatcher) DispatchOnce(ctx context.Context) int                // testing
func (d *Dispatcher) DispatchOnceResult(ctx context.Context) DispatchResult
```

### Wire format (`OutboxEnvelope`)

```go
const (
    StreamingOutboxEventType = "lerian.streaming.publish"
    OutboxEnvelopeVersion    = 1 // strict equality on decode
)

type OutboxEnvelope struct {
    Version       int              `json:"version"`        // ==1
    RouteKey      string           `json:"route_key"`      // canonical: lower-case dot-delimited
    DefinitionKey string           `json:"definition_key"`
    Target        string           `json:"target"`         // e.g. "kafka-primary"
    Transport     TransportKind    `json:"transport"`      // kafka|sqs|rabbitmq|eventbridge|custom
    Destination   Destination      `json:"destination"`
    AggregateID   uuid.UUID        `json:"aggregate_id"`   // deterministic from event partition key
    Requirement   RouteRequirement `json:"requirement"`    // required|optional
    Policy        DeliveryPolicy   `json:"policy"`
    Event         Event            `json:"event"`
}
```

The envelope is JSON-marshalled into `OutboxEvent.Payload`; `OutboxEvent.EventType` is always `"lerian.streaming.publish"`. The concrete destination lives **inside** the envelope, not in the row's event type — one outbox table serves every route.

`ValidateShape` runs on the producer-side persist path (skips DNS/SSRF checks because the destination came from an already-validated `RouteDefinition`). `Validate` runs on the relay decode path because persisted bytes are effectively untrusted.

## Wiring Recipe

```go
// 1. Build the outbox repository (Postgres example).
outboxRepo, err := outboxpg.NewRepository(db, ...)
if err != nil { return err }

// 2. Build the producer with outbox plumbing.
emitter, err := streaming.NewBuilder().
    Catalog(catalog).
    Routes(routes...).
    Target(streaming.TargetConfig{Name: "kafka-primary", Kind: streaming.TransportKafkaLike, Brokers: cfg.Brokers}).
    Logger(logger).
    Tracer(tracer).
    CircuitBreakerManager(cb).
    OutboxRepository(outboxRepo).   // wires libCommonsOutboxWriter
    Build(ctx)
if err != nil { return err }

// 3. Register the relay handler under the stable event type.
handlers := outbox.NewHandlerRegistry()
producer := emitter.(*streaming.Producer)
if err := producer.RegisterOutboxRelay(handlers); err != nil { return err }

// 4. Start the relay loop.
dispatcher, err := outbox.NewDispatcher(outboxRepo, handlers, logger, tracer)
if err != nil { return err }
if err := launcher.Add("streaming", producer); err != nil { return err }
if err := launcher.Add("outbox-dispatcher", dispatcher); err != nil { return err }
```

## Transactional Emit Pattern

```go
func (s *TransactionService) Post(ctx context.Context, req PostRequest) error {
    return s.db.RunInTx(ctx, func(ctx context.Context, tx *sql.Tx) error {
        // 1. Business state — atomic with the outbox row.
        if err := s.repo.SaveTransaction(ctx, tx, req); err != nil {
            return err
        }

        // 2. Join the SQL tx so circuit-open emits write to outbox under tx.
        ctx = streaming.WithOutboxTx(ctx, tx)

        // 3. Emit. Healthy broker → direct publish (after Commit returns).
        //    Open circuit → envelope persists inside the tx; relay drains later.
        return s.emitter.Emit(ctx, streaming.EmitRequest{
            DefinitionKey: "transaction.posted",
            TenantID:      req.TenantID,
            Subject:       req.TxID,
            Payload:       req.Payload(),
        })
    })
}
```

Three operationally important properties of this pattern:

1. **Atomicity.** Business row and outbox row share a commit fate. No silent divergence.
2. **At-least-once delivery.** The relay re-publishes pending rows on every cycle until `MarkPublished` succeeds. Consumers must dedup.
3. **No re-enqueue under outage.** Relay handlers dispatch to the originating target adapter directly (not through `Emit`), so a sustained circuit-open does not re-add rows to the outbox via the relay path.

## Relay Loop Semantics

The dispatcher's `collectEvents` uses a priority-layered batch (`BatchSize=50` default):

1. **Priority events.** `PriorityEventTypes` ∩ PENDING, up to `PriorityBudget`.
2. **Stuck reclaim.** PROCESSING older than `ProcessingTimeout=10m` → reset to PENDING.
3. **Failed retry.** FAILED older than `RetryWindow=5m` with attempts < `MaxDispatchAttempts=10` → reset to PENDING.
4. **Remaining pending.** Plain FIFO by `created_at`.

Per-event publish runs through `HandlerRegistry.Handle(ctx, event)`, dispatched by `event.EventType`. For streaming outbox rows that means `lerian.streaming.publish` → the producer's `handleOutboxRow`, which decodes the `OutboxEnvelope` (full `Validate` with SSRF/DNS), looks up the route's transport adapter, and publishes directly through it.

Publish failure is classified via `RetryClassifier`:
- Non-retryable → `MarkInvalid` (poison row, no further attempts).
- Retryable → `MarkFailed` with exponential backoff via `RetryWindow`.

Per-tenant dispatch is round-robin; tenant order rotates each cycle to prevent a slow tenant from starving the rest. Set `IncludeTenantMetrics=true` on `DispatcherConfig` only when tenant cardinality is bounded — the dispatcher caps unique labels at `MaxTenantMetricDimensions` with an overflow bucket (`_other`).

## MongoDB Tx Note

`TransactionalOutboxWriter` is defined against `*sql.Tx`. MongoDB transactions flow differently: the v1 driver's `mongo.SessionContext` rides on `ctx` and the `mongo` outbox repository's `Create(ctx, ...)` picks it up automatically. Callers do **not** use `WithOutboxTx` for MongoDB — they invoke `Emit` with a session-bound context, and the regular `Write` path joins the Mongo transaction. Driver v2 session contexts are a different type and are not joined by the v1 repository path; mixing v2 sessions with the v1 outbox repository is a wiring bug.

## Error Surface

| Sentinel | Cause | Action |
|---|---|---|
| `streaming.ErrOutboxNotConfigured` | Policy elected outbox but no writer wired | Wire `WithOutboxRepository` or `WithOutboxWriter` |
| `streaming.ErrOutboxTxUnsupported` | `WithOutboxTx` set, writer is not `TransactionalOutboxWriter` (or non-`*sql.Tx` on context key) | Use a SQL repository, or remove `WithOutboxTx` for non-SQL paths |
| `streaming.ErrInvalidOutboxEnvelope` | Envelope shape rejected on encode or decode | Inspect violation field; usually schema-evolution skew during rolling deploy |
| `outbox.ErrHandlerNotRegistered` | Relay row has unknown `event_type` | Call `RegisterOutboxRelay` before dispatcher starts |
| `outbox.ErrOutboxRepositoryRequired` | Dispatcher built with nil repo | Wire the repository explicitly |

## Decision Tree

| Situation | Use |
|---|---|
| Service emits events from transactional code | `WithOutboxRepository` + `WithOutboxTx` + dispatcher |
| Service emits events outside any DB transaction | `WithOutboxRepository` (no `WithOutboxTx` needed) — outbox still acts as circuit-breaker fallback |
| Custom outbox store (Spanner, DynamoDB) | Implement `OutboxWriter` (and `TransactionalOutboxWriter` if applicable), wire `WithOutboxWriter` |
| Read-side service with no emits | Skip outbox entirely. Use `NoopEmitter` for tests. |
| Internal command queue (request/reply) | NOT outbox. Use `lib-commons/rabbitmq` or `lib-commons/dlq` per request shape. |
| HTTP request idempotency | NOT outbox. Use `lib-commons/idempotency`. |

## Anti-Patterns (closed-form)

- **Outbox tables that store unwrapped event payloads.** Without `OutboxEnvelope` you lose route, target, transport, requirement, and policy — and you cannot use the canonical relay.
- **Relay loops with their own SQL.** Hand-rolled `FOR UPDATE SKIP LOCKED` claim queries that drift from the dispatcher's claim semantics produce stuck rows under load.
- **`MarkPublished` before broker ack.** At-least-once requires marking *after* the adapter confirms. Reversing the order silently downgrades to at-most-once.
- **Mixing `WithOutboxRepository` and `WithOutboxWriter` carelessly.** Last call wins. If the custom writer does not implement `TransactionalOutboxWriter`, every `WithOutboxTx` emit fails until reverted.
- **Outbox row payloads > `DefaultMaxPayloadBytes` (1 MiB).** Large payloads belong in object storage with a reference in the event, not inline.
