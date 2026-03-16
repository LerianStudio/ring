# Go Standards - Messaging

> **Module:** messaging.md | **Sections:** §21 | **Parent:** [index.md](index.md)

This module covers RabbitMQ worker patterns for async message processing and reconnection strategies.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [RabbitMQ Worker Pattern](#rabbitmq-worker-pattern) | Async message processing with RabbitMQ |
| 2 | [RabbitMQ Reconnection Strategy (MANDATORY)](#rabbitmq-reconnection-strategy-mandatory) | Two-layer reconnection for consumer and producer resilience |

**Subsections:** Application Types, Architecture Overview, Core Components, Worker Configuration, Handler Registration, Handler Implementation, Message Acknowledgment, Worker Lifecycle, **Exponential Backoff with Jitter (MANDATORY)**, **Error Classification (MANDATORY)**, Producer Implementation, Message Format, Service Bootstrap, Directory Structure, Worker Checklist, **Consumer Reconnection Loop (MANDATORY)**, **Producer Per-Publish Retry (MANDATORY)**, **Health Check Integration (MANDATORY)**, **Deadlock Prevention (MANDATORY)**.

---

## RabbitMQ Worker Pattern

When the application includes async processing (API+Worker or Worker Only), follow this pattern.

### Application Types

| Type | Characteristics | Components |
|------|----------------|------------|
| **API Only** | HTTP endpoints, no async processing | Handlers, Services, Repositories |
| **API + Worker** | HTTP endpoints + async message processing | All above + Consumers, Producers |
| **Worker Only** | No HTTP, only message processing | Consumers, Services, Repositories |

### Architecture Overview

```text
┌─────────────────────────────────────────────────────────────┐
│  Service Bootstrap                                          │
│  ├── HTTP Server (Fiber)         ← API endpoints           │
│  ├── RabbitMQ Consumer           ← Event-driven workers    │
│  └── Redis Consumer (optional)   ← Scheduled polling       │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

```go
// ConsumerRoutes - Multi-queue consumer manager
type ConsumerRoutes struct {
    conn              *RabbitMQConnection
    routes            map[string]QueueHandlerFunc  // Queue name → Handler
    NumbersOfWorkers  int                          // Workers per queue (default: 5)
    NumbersOfPrefetch int                          // QoS prefetch (default: 10)
    Logger
    Telemetry
}

// Handler function signature
type QueueHandlerFunc func(ctx context.Context, body []byte) error
```

### Worker Configuration

| Config | Default | Purpose |
|--------|---------|---------|
| `RABBITMQ_NUMBERS_OF_WORKERS` | 5 | Concurrent workers per queue |
| `RABBITMQ_NUMBERS_OF_PREFETCH` | 10 | Messages buffered per worker |
| `RABBITMQ_CONSUMER_USER` | - | Separate credentials for consumer |
| `RABBITMQ_{QUEUE}_QUEUE` | - | Queue name per handler |

**Formula:** `Total buffered = Workers × Prefetch` (e.g., 5 × 10 = 50 messages)

### Handler Registration

```go
// Register handlers per queue
func (mq *MultiQueueConsumer) RegisterRoutes(routes *ConsumerRoutes) {
    routes.Register(os.Getenv("RABBITMQ_BALANCE_CREATE_QUEUE"), mq.handleBalanceCreate)
    routes.Register(os.Getenv("RABBITMQ_TRANSACTION_QUEUE"), mq.handleTransaction)
}
```

### Handler Implementation

```go
func (mq *MultiQueueConsumer) handleBalanceCreate(ctx context.Context, body []byte) error {
    // 1. Deserialize message
    var message QueueMessage
    if err := json.Unmarshal(body, &message); err != nil {
        return fmt.Errorf("unmarshal message: %w", err)
    }

    // 2. Execute business logic
    if err := mq.UseCase.CreateBalance(ctx, message); err != nil {
        return fmt.Errorf("create balance: %w", err)
    }

    // 3. Success → Ack automatically
    return nil
}
```

### Message Acknowledgment

| Result | Action | Effect |
|--------|--------|--------|
| `return nil` | `msg.Ack(false)` | Message removed from queue |
| `return err` | `msg.Nack(false, true)` | Message requeued |

### Worker Lifecycle

```text
RunConsumers()
├── For each registered queue:
│   ├── EnsureChannel(ctx) with exponential backoff
│   ├── Set QoS (prefetch)
│   ├── Start Consume()
│   └── Spawn N worker goroutines
│       └── startWorker(workerID, queue, handler, messages)

startWorker():
├── for msg := range messages:
│   ├── Extract/generate TraceID from headers
│   ├── Create context with HeaderID
│   ├── Start OpenTelemetry span
│   ├── Call handler(ctx, msg.Body)
│   ├── On success: msg.Ack(false)
│   └── On error: log + msg.Nack(false, true)
```

### Exponential Backoff with Jitter (MANDATORY)

RabbitMQ retries without backoff cause message storms and connection exhaustion.

**⛔ HARD GATE:** All RabbitMQ consumers MUST implement exponential backoff with jitter for retry logic.

#### Why Exponential Backoff Is MANDATORY

| Issue | Without Backoff | With Backoff |
|-------|-----------------|--------------|
| Failing message | Immediate retry loop | Progressive delay |
| Connection loss | Reconnect spam | Gradual recovery |
| Downstream outage | Thundering herd | Distributed retry |
| Resource usage | CPU spike, memory | Controlled load |

#### Retry Constants (REQUIRED)

```go
const (
    MaxRetries     = 5                        // Maximum retry attempts before DLQ
    InitialBackoff = 500 * time.Millisecond   // First retry delay
    MaxBackoff     = 30 * time.Second         // Cap to prevent excessive delays
    BackoffFactor  = 2.0                      // Exponential multiplier
)
```

#### Backoff Calculation Formula

```text
backoff = min(InitialBackoff * (BackoffFactor ^ attempt), MaxBackoff)

Attempt | Base Backoff | With Full Jitter (0 to base)
--------|--------------|-----------------------------
1       | 500ms        | 0-500ms
2       | 1s           | 0-1s
3       | 2s           | 0-2s
4       | 4s           | 0-4s
5       | 8s           | 0-8s (capped at MaxBackoff if exceeded)
```

#### Full Jitter Implementation (REQUIRED)

```go
// Full jitter: random delay in [0, baseDelay]
// Prevents thundering herd when multiple consumers retry simultaneously
func FullJitter(baseDelay time.Duration) time.Duration {
    jitter := time.Duration(rand.Float64() * float64(baseDelay))
    if jitter > MaxBackoff {
        return MaxBackoff
    }
    return jitter
}

// Calculate exponential backoff with jitter
func CalculateBackoff(attempt int) time.Duration {
    if attempt < 1 {
        attempt = 1
    }

    base := InitialBackoff * time.Duration(math.Pow(BackoffFactor, float64(attempt-1)))
    if base > MaxBackoff {
        base = MaxBackoff
    }

    return FullJitter(base)
}
```

#### Retry Pattern in Handler

```go
func (mq *MultiQueueConsumer) handleWithRetry(ctx context.Context, body []byte) error {
    var lastErr error

    for attempt := 1; attempt <= MaxRetries; attempt++ {
        err := mq.processMessage(ctx, body)
        if err == nil {
            return nil  // Success
        }

        lastErr = err

        // Check if error is retryable
        if !isRetryable(err) {
            return fmt.Errorf("non-retryable error: %w", err)
        }

        // Calculate backoff with jitter
        backoff := CalculateBackoff(attempt)
        mq.logger.Warnf("Attempt %d/%d failed, retrying in %v: %v",
            attempt, MaxRetries, backoff, err)

        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-time.After(backoff):
            // Continue to next attempt
        }
    }

    return fmt.Errorf("max retries exceeded: %w", lastErr)
}
```

#### Error Classification (MANDATORY)

`handleWithRetry` MUST use an `isRetryable(err error)` function to decide whether to retry or fail fast. Implement and use the following classification.

**Non-retryable (return `false`):**

| Category | Examples | Reason |
|----------|----------|--------|
| Context cancellation | `context.Canceled`, `context.DeadlineExceeded` | Retrying would ignore user/timeout intent |
| Business / validation | `ErrInvalidInput`, `ErrDuplicateKey`, domain validation errors | Same input will fail again |
| Authorization | Auth/permission errors | No point retrying without different credentials |

**Retryable (return `true`):**

| Category | Examples | Reason |
|----------|----------|--------|
| Transient network | `syscall.ECONNREFUSED`, `syscall.ETIMEDOUT`, `syscall.ECONNRESET` | Temporary connectivity issues |
| Temporary downstream | Temporary 5xx responses, DB connection pool exhausted | May succeed on retry |
| Unknown errors | Unclassified errors | Default to retry so transient issues can recover; use DLQ after max retries |

**Required implementation:**

```go
// isRetryable classifies errors for handleWithRetry. Non-retryable errors fail fast; retryable errors use backoff.
// NOTE: ErrInvalidInput and ErrDuplicateKey below are placeholder sentinel errors for domain-specific validation/
// business rules. Teams MUST define these in their codebase (or import from a shared package) and replace with
// their project's own sentinel errors so readers aren't left searching for undefined symbols.
func isRetryable(err error) bool {
    if err == nil {
        return false
    }
    // Context cancellation: do not retry
    if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
        return false
    }
    // Known non-retryable business/validation errors (define ErrInvalidInput, ErrDuplicateKey in your project)
    if errors.Is(err, ErrInvalidInput) || errors.Is(err, ErrDuplicateKey) {
        return false
    }
    // Add other sentinel business/auth errors your domain uses
    // Transient network errors: retry
    var errno syscall.Errno
    if errors.As(err, &errno) {
        switch errno {
        case syscall.ECONNREFUSED, syscall.ETIMEDOUT, syscall.ECONNRESET:
            return true
        }
    }
    // Temporary 5xx / downstream unavailable: retry (if wrapped with 5xx or temporary marker)
    // Default: unknown errors are retryable; DLQ handles repeated failures after MaxRetries
    return true
}
```

#### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR that modifies RabbitMQ consumers
grep -rn "Retry\|Backoff\|Jitter" internal/adapters/rabbitmq --include="*.go"

# Expected: Backoff implementation found
# If missing: BLOCKER - Add exponential backoff before proceeding

# Check for immediate retry patterns (FORBIDDEN)
grep -rn "Nack.*true" internal/adapters/rabbitmq --include="*.go"

# Review each match - ensure backoff is applied before Nack with requeue
```

#### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Immediate retry without backoff
if err != nil {
    msg.Nack(false, true)  // WRONG: Immediate requeue = message storm
    return
}

// ❌ FORBIDDEN: Fixed delay retry
time.Sleep(1 * time.Second)  // WRONG: No backoff = no load distribution
msg.Nack(false, true)

// ❌ FORBIDDEN: No retry limit
for {  // WRONG: Infinite retry = stuck message
    if err := process(); err == nil {
        break
    }
}
```

#### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Messages are fast, no backoff needed" | Fast processing + failure = fast retry = storm. | **Add backoff** |
| "Fixed delay is simpler" | Fixed delay = synchronized retries = thundering herd. | **Use jitter** |
| "Downstream will recover" | Downstream under load + immediate retries = longer outage. | **Add backoff** |
| "We handle few messages" | Few messages * fast retries = many retries. | **Add backoff** |
| "Retry limit is business logic" | Retry limit is infrastructure protection. Always required. | **Add MaxRetries** |

### Producer Implementation

```go
func (p *ProducerRepository) Publish(ctx context.Context, exchange, routingKey string, message []byte) error {
    if err := p.EnsureChannel(ctx); err != nil {
        return fmt.Errorf("ensure channel: %w", err)
    }

    headers := amqp.Table{
        "HeaderID": GetRequestID(ctx),
    }
    InjectTraceHeaders(ctx, &headers)

    return p.channel.Publish(
        exchange,
        routingKey,
        false,
        false,
        amqp.Publishing{
            ContentType:  "application/json",
            DeliveryMode: amqp.Persistent,
            Headers:      headers,
            Body:         message,
        },
    )
}
```

### Message Format

```go
type QueueMessage struct {
    OrganizationID uuid.UUID   `json:"organizationId"`
    LedgerID       uuid.UUID   `json:"ledgerId"`
    AuditID        uuid.UUID   `json:"auditId"`
    Data           []QueueData `json:"data"`
}

type QueueData struct {
    ID    uuid.UUID       `json:"id"`
    Value json.RawMessage `json:"value"`
}
```

### Service Bootstrap (API + Worker)

```go
type Service struct {
    *Server              // HTTP server (Fiber)
    *MultiQueueConsumer  // RabbitMQ consumer
    Logger
}

func (s *Service) Run() {
    launcher := libCommons.NewLauncher(
        libCommons.WithLogger(s.Logger),
        libCommons.RunApp("HTTP Server", s.Server),
        libCommons.RunApp("RabbitMQ Consumer", s.MultiQueueConsumer),
    )
    launcher.Run() // All components run concurrently
}
```

### Directory Structure for Workers

```text
/internal
  /adapters
    /rabbitmq
      consumer.go      # ConsumerRoutes, worker pool
      producer.go      # ProducerRepository
      connection.go    # Connection management
  /bootstrap
    rabbitmq.server.go # MultiQueueConsumer, handler registration
    service.go         # Service orchestration
/pkg
  /utils
    jitter.go          # Backoff utilities
```

### Worker Checklist

- [ ] Handlers are idempotent (safe to process duplicates)
- [ ] Manual Ack enabled (`autoAck: false`)
- [ ] Error handling returns error (triggers Nack)
- [ ] Context propagation with HeaderID
- [ ] OpenTelemetry spans for tracing
- [ ] Exponential backoff for connection recovery
- [ ] Graceful shutdown respects context cancellation
- [ ] Separate credentials for consumer vs producer

---

## RabbitMQ Reconnection Strategy (MANDATORY)

Services that use RabbitMQ MUST implement automatic reconnection at both the consumer and producer layers. Without reconnection, a broker restart or network partition leaves the service permanently disconnected.

**⛔ HARD GATE:** All RabbitMQ services MUST implement two-layer reconnection using `EnsureChannel(ctx)` from lib-commons.

### Reconnection Architecture

| Layer | Mechanism | Trigger |
|-------|-----------|---------|
| **Consumer** | Infinite loop + `NotifyClose` channel | Channel closure detected automatically |
| **Producer** | `EnsureChannel(ctx)` + retry loop per publish | Connection failure on publish attempt |

Both layers use the same exponential backoff with full jitter strategy defined in [Exponential Backoff with Jitter](#exponential-backoff-with-jitter-mandatory).

### Consumer Reconnection Loop (MANDATORY)

The consumer MUST run an infinite goroutine per queue that automatically restarts on any channel closure.

```go
func (cr *ConsumerRoutes) RunConsumers(ctx context.Context) error {
    for queueName, handler := range cr.routes {
        go func(queueName string, handler QueueHandlerFunc) {
            attempt := 0

            for {
                attempt++

                // 1. Ensure channel is open (with retries)
                if err := cr.conn.EnsureChannel(ctx); err != nil {
                    select {
                    case <-ctx.Done():
                        return
                    case <-time.After(CalculateBackoff(attempt)):
                    }
                    continue
                }

                // 2. Set QoS
                if err := cr.conn.Channel.Qos(
                    cr.NumbersOfPrefetch, 0, false,
                ); err != nil {
                    select {
                    case <-ctx.Done():
                        return
                    case <-time.After(CalculateBackoff(attempt)):
                    }
                    continue
                }

                // 3. Start consuming
                messages, err := cr.conn.Channel.Consume(
                    queueName,
                    "",    // consumer tag (auto-generated)
                    false, // auto-ack
                    false, // exclusive
                    false, // no-local
                    false, // no-wait
                    nil,   // args
                )
                if err != nil {
                    select {
                    case <-ctx.Done():
                        return
                    case <-time.After(CalculateBackoff(attempt)):
                    }
                    continue
                }

                attempt = 0 // Reset on success

                // 4. Monitor channel closure (KEY MECHANISM)
                notifyClose := make(chan *amqp.Error, 1)
                cr.conn.Channel.NotifyClose(notifyClose)

                // 5. Start workers
                for i := 0; i < cr.NumbersOfWorkers; i++ {
                    go cr.startWorker(i, queueName, handler, messages)
                }

                // 6. Block until channel closes or context cancels
                select {
                case errClose := <-notifyClose:
                    if errClose != nil {
                        cr.Logger.Warnf("[Consumer %s] channel closed: %v", queueName, errClose)
                    }
                case <-ctx.Done():
                    return
                }

                // Loop restarts automatically
            }
        }(queueName, handler)
    }
    return nil
}
```

#### How It Works

1. `EnsureChannel(ctx)` creates a new AMQP channel if the current one is nil or closed
2. If channel creation, Qos, or Consume fails, wait with `CalculateBackoff(attempt)` and retry
3. All waits honor `ctx.Done()` so the goroutine exits cleanly on shutdown
4. Once consuming starts, `NotifyClose` blocks until the channel dies
5. When the channel dies (broker restart, network failure), the loop restarts
6. Attempt counter resets to 0 on every successful connection

### Producer Per-Publish Retry (MANDATORY)

The producer MUST call `EnsureChannel(ctx)` before every publish and retry with exponential backoff on failure.

```go
func (p *ProducerRepository) PublishWithRetry(
    ctx context.Context, exchange, routingKey string, message []byte,
) error {
    for attempt := 1; attempt <= MaxRetries; attempt++ {
        // 1. Ensure channel is available
        if err := p.conn.EnsureChannel(ctx); err != nil {
            select {
            case <-ctx.Done():
                return ctx.Err()
            case <-time.After(CalculateBackoff(attempt)):
            }
            continue
        }

        // 2. Build headers with trace propagation
        headers := amqp.Table{
            "HeaderID": GetRequestID(ctx),
        }
        InjectTraceHeaders(ctx, &headers)

        // 3. Attempt publish
        err := p.conn.Channel.Publish(
            exchange,
            routingKey,
            false, // mandatory
            false, // immediate
            amqp.Publishing{
                ContentType:  "application/json",
                DeliveryMode: amqp.Persistent,
                Headers:      headers,
                Body:         message,
            },
        )

        // 4. Success - return immediately
        if err == nil {
            return nil
        }

        // 5. Failure - backoff and retry
        if attempt == MaxRetries {
            return fmt.Errorf("publish failed after %d retries: %w", MaxRetries, err)
        }

        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-time.After(CalculateBackoff(attempt)):
        }
    }

    return fmt.Errorf("publish failed: exhausted retries")
}
```

#### Key Detail: `EnsureChannel(ctx)`

This is the critical function from `lib-commons`. It takes a `context.Context` parameter, which allows the caller to control cancellation and timeouts during reconnection. It:

- Checks if the current channel is nil or closed
- If so, calls `GetConnection()` to re-establish the AMQP connection
- Creates a new channel on the fresh connection
- Updates `conn.Connected` to `true` (which makes `/ready` return 200)

### Health Check Integration (MANDATORY)

Health checks MUST delegate to `lib-commons` `RabbitMQConnection.HealthCheck()`:

```go
func (p *ProducerRepository) CheckRabbitMQHealth() bool {
    return p.conn.HealthCheck()
}
```

`HealthCheck()` verifies:

- `conn.Connected == true`
- `conn.Connection != nil`
- `!conn.Connection.IsClosed()`

A background goroutine MUST periodically call `EnsureChannel(ctx)` to keep the health status accurate. Without this, the service enters a deadlock state where `/ready` reports unhealthy but nothing triggers reconnection (see [Deadlock Prevention](#deadlock-prevention-mandatory)).

### Deadlock Prevention (MANDATORY)

**⛔ HARD GATE:** Producer-only services and services with separate consumer/producer connections MUST implement background periodic reconnection.

#### The Deadlock Scenario

When the broker restarts or a network partition occurs, services without active background reconnection enter a deadlock:

```text
1. Broker restarts → connection dies
2. /ready returns 503 (connection is closed)
3. No background process calls EnsureChannel(ctx) to reconnect
4. Connection only recovers when a publish is attempted
5. No publish happens because upstream sees 503 from /ready
6. Deadlock: nothing triggers reconnection
```

Consumer-based services with the background loop from [Consumer Reconnection Loop](#consumer-reconnection-loop-mandatory) naturally recover because the consumer loop calls `EnsureChannel(ctx)` continuously.

#### The Fix: Background Periodic Reconnection (REQUIRED)

Add a background goroutine during service bootstrap that periodically calls `EnsureChannel(ctx)`:

```go
func startReconnectionMonitor(ctx context.Context, conn *libRabbitmq.RabbitMQConnection, interval time.Duration) {
    go func() {
        ticker := time.NewTicker(interval)
        defer ticker.Stop()

        for {
            select {
            case <-ctx.Done():
                return
            case <-ticker.C:
                if err := conn.EnsureChannel(ctx); err != nil {
                    log.Warnf("background reconnection attempt failed: %v", err)
                }
            }
        }
    }()
}
```

Call in service bootstrap:

```go
// REQUIRED: Prevents deadlock after broker restart
startReconnectionMonitor(ctx, rabbitMQConnection, 10*time.Second)
```

#### Detection Commands (MANDATORY)

```bash
# MANDATORY: Verify reconnection pattern exists
grep -rn "EnsureChannel" internal/adapters/rabbitmq --include="*.go"

# Expected: EnsureChannel called in both consumer and producer
# If missing in producer: BLOCKER - Add EnsureChannel(ctx) + retry before publish

# Check for background reconnection monitor
grep -rn "startReconnectionMonitor\|NewTicker.*EnsureChannel" internal/ --include="*.go"

# Expected: Background monitor present in bootstrap
# If missing: BLOCKER for producer-only services - Add periodic EnsureChannel(ctx)
```

#### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Single publish attempt without retry
func (p *Producer) Publish(ctx context.Context, msg []byte) error {
    return p.conn.Channel.Publish(...)  // WRONG: No EnsureChannel(ctx), no retry
}

// ❌ FORBIDDEN: EnsureChannel(ctx) without retry loop
func (p *Producer) Publish(ctx context.Context, msg []byte) error {
    p.conn.EnsureChannel(ctx)  // WRONG: If EnsureChannel fails, publish fails permanently
    return p.conn.Channel.Publish(...)
}

// ❌ FORBIDDEN: No background reconnection in producer-only service
func main() {
    conn := rabbitmq.NewConnection(...)
    producer := rabbitmq.NewProducer(conn)
    // WRONG: No startReconnectionMonitor → deadlock after broker restart
    server.Start()
}
```

#### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Consumer reconnects, producer is fine" | Consumer and producer may use separate connections. Producer needs its own reconnection. | **Add EnsureChannel(ctx) + retry to producer** |
| "Broker rarely restarts" | Rare ≠ never. When it happens, service is stuck until pod restart. | **Add reconnection to both layers** |
| "Kubernetes will restart the pod" | Pod restart = downtime + message loss. Self-healing is faster and lossless. | **Add background reconnection** |
| "Health check will catch it" | Health check reports the problem but does not fix it. That's the deadlock. | **Add startReconnectionMonitor** |
| "We only have a consumer, no producer" | Consumer loop handles itself. But verify NotifyClose is used, not just range. | **Verify NotifyClose pattern** |
| "Single EnsureChannel(ctx) before publish is enough" | If EnsureChannel fails, publish fails permanently with no retry. | **Wrap in retry loop with backoff** |

### Reconnection Checklist

- [ ] Consumer uses infinite loop with `EnsureChannel(ctx)` + `NotifyClose`
- [ ] Consumer resets backoff to `InitialBackoff` on successful connection
- [ ] Producer calls `EnsureChannel(ctx)` before every publish
- [ ] Producer wraps publish in retry loop with exponential backoff
- [ ] Health check delegates to `lib-commons` `HealthCheck()`
- [ ] Background `startReconnectionMonitor` present for producer-only services
- [ ] Backoff uses `FullJitter` to prevent thundering herd

---

