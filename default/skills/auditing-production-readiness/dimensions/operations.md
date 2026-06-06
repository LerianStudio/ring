# Audit Dimensions: Category C — Operational Readiness

These are the 7 explorer agent prompts for Operations dimensions.
Inject Ring standards and detected stack before dispatching.

### Agent 10: Telemetry & Observability Auditor

```prompt
Audit telemetry and observability implementation for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Observability" section from bootstrap.md and "OpenTelemetry with lib-observability" section from sre.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/observability*.go`, `**/telemetry*.go`, `**/handlers.go`
- Keywords: `NewTrackingFromContext`, `tracer.Start`, `span`, `logger`, `metrics`
- Standards-specific: `observability.NewTrackingFromContext`, `otel`, `OpenTelemetry`

**Reference Implementation (GOOD):**
```go
// Handler with proper telemetry
func (h *Handler) DoSomething(c *fiber.Ctx) error {
    ctx := c.UserContext()
    logger, tracer, headerID, _ := observability.NewTrackingFromContext(ctx)
    ctx, span := tracer.Start(ctx, "handler.DoSomething")
    defer span.End()

    span.SetAttributes(attribute.String("request_id", headerID))

    result, err := doOperation(ctx)
    if err != nil {
        span.RecordError(err)
        span.SetStatus(codes.Error, err.Error())
        logger.Errorf("operation failed: %v", err)
        return err
    }

    return c.JSON(result)
}
```

**Reference Implementation (GOOD — Trace Propagation & Sampling):**
```go
// W3C Trace Context propagation in outgoing HTTP requests
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/propagation"
)

func (c *HTTPClient) Do(ctx context.Context, req *http.Request) (*http.Response, error) {
    // Inject trace context into outgoing request headers
    otel.GetTextMapPropagator().Inject(ctx, propagation.HeaderCarrier(req.Header))
    return c.client.Do(req.WithContext(ctx))
}

// Baggage propagation for business context
import "go.opentelemetry.io/otel/baggage"

func InjectBusinessContext(ctx context.Context, tenantID, userID string) context.Context {
    tenantMember, _ := baggage.NewMember("tenantId", tenantID)
    userMember, _ := baggage.NewMember("userId", userID)
    bag, _ := baggage.New(tenantMember, userMember)
    return baggage.ContextWithBaggage(ctx, bag)
}

// Span linking for async flows — consumer side
func (c *Consumer) Handle(msg *Message) error {
    producerCtx := otel.GetTextMapPropagator().Extract(context.Background(), propagation.MapCarrier(msg.Headers))
    producerSpanCtx := trace.SpanContextFromContext(producerCtx)

    ctx, span := c.tracer.Start(context.Background(), "consume."+msg.Type,
        trace.WithLinks(trace.Link{SpanContext: producerSpanCtx}),
    )
    defer span.End()
    return c.process(ctx, msg)
}

// Trace sampling configuration
func initTracerProvider(env string) *trace.TracerProvider {
    var sampler trace.Sampler
    switch env {
    case "production":
        sampler = trace.ParentBased(trace.TraceIDRatioBased(0.1))
    case "staging":
        sampler = trace.ParentBased(trace.TraceIDRatioBased(0.5))
    default:
        sampler = trace.AlwaysSample()
    }
    return trace.NewTracerProvider(trace.WithSampler(sampler))
}

// Custom span attributes for business context
func (h *Handler) CreateOrder(c *fiber.Ctx) error {
    ctx, span := h.tracer.Start(c.UserContext(), "handler.CreateOrder")
    defer span.End()
    span.SetAttributes(
        attribute.String("order.id", order.ID.String()),
        attribute.String("tenant.id", tenantID.String()),
        attribute.Float64("order.amount", order.TotalAmount),
    )
    // ...
}
```

**Reference Implementation (BAD — Trace Propagation):**
```go
// BAD: Outgoing HTTP request without trace context propagation
func (c *HTTPClient) Do(ctx context.Context, req *http.Request) (*http.Response, error) {
    return c.client.Do(req)  // No propagation — downstream sees a new disconnected trace
}

// BAD: Async message consumer starts fresh trace without linking to producer
func (c *Consumer) Handle(msg *Message) error {
    ctx, span := c.tracer.Start(context.Background(), "consume.event")
    defer span.End()
    return c.process(ctx, msg)  // No link to producer span — trace is disconnected
}

// BAD: No sampling configuration (AlwaysSample in production)
func initTracerProvider() *trace.TracerProvider {
    return trace.NewTracerProvider()  // Default: AlwaysSample — 100% of traces stored
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) lib-observability NewTrackingFromContext used for telemetry initialization per Ring standards
2. (HARD GATE) OpenTelemetry integration (not custom tracing) per sre.md
3. All handlers start spans with descriptive names
4. Errors recorded to spans before returning
5. Request IDs propagated through context
6. Metrics initialized at startup per bootstrap.md observability section
7. Structured logging with context (not fmt.Println)
8. Graceful telemetry shutdown
9. Cross-service trace context propagation — outgoing HTTP requests MUST inject W3C Trace Context headers (`traceparent`, `tracestate`) using OpenTelemetry propagators
10. Baggage propagation across service boundaries — business context (e.g., `tenantId`, `userId`, `correlationId`) MUST be propagated via OpenTelemetry Baggage for cross-service observability
11. Span linking for async flows — message producer spans MUST be linked to consumer spans via `trace.WithLinks()` so async flows appear connected in distributed traces
12. Trace sampling configuration — production environments MUST configure sampling rate (not 100% sampling) to control cost; development environments may use `AlwaysSample`
13. Custom span attributes for business-relevant data — spans MUST include domain-specific attributes (e.g., `order.id`, `tenant.id`, `transaction.amount`) for meaningful trace filtering

**Severity Ratings:**
- CRITICAL: No tracing in handlers (HARD GATE violation per Ring standards)
- CRITICAL: HARD GATE violation — not using lib-observability for telemetry
- HIGH: Errors not recorded to spans
- HIGH: No trace context propagation in outgoing HTTP requests (downstream services cannot correlate traces — breaks distributed tracing)
- HIGH: Async message flows break trace continuity (no span links between producer and consumer — message processing appears as disconnected traces)
- MEDIUM: Missing request ID propagation
- MEDIUM: No trace sampling configuration (100% sampling in production = storage cost explosion and performance overhead)
- MEDIUM: Missing baggage propagation for cross-service business context (cannot filter/correlate traces by tenant, user, or business entity)
- LOW: Inconsistent span naming conventions
- LOW: No custom span attributes for business metrics (traces lack domain context for meaningful filtering and alerting)

**Output Format:**
```
## Telemetry Audit Findings

### Summary
- Handlers with tracing: X/Y
- Handlers with error recording: X/Y
- Metrics initialization: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 12: Health Checks Auditor

```prompt
Audit health check endpoints for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Health Checks" section from sre.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/fiber_server.go`, `**/health*.go`, `**/routes.go`
- Keywords: `/health`, `/ready`, `/live`, `healthHandler`, `readinessHandler`
- Standards-specific: `liveness`, `readiness`, `degraded`

**Reference Implementation (GOOD):**
```go
// Liveness probe - always returns healthy if process is running
func healthHandler(c *fiber.Ctx) error {
    return c.SendString("healthy")
}

// Readiness probe - checks all dependencies
func readinessHandler(deps *HealthDependencies) fiber.Handler {
    return func(c *fiber.Ctx) error {
        checks := fiber.Map{}
        status := fiber.StatusOK

        // Required dependency - fails readiness if down
        if err := deps.DB.Ping(c.Context()); err != nil {
            checks["database"] = "unhealthy"
            status = fiber.StatusServiceUnavailable
        } else {
            checks["database"] = "healthy"
        }

        // Optional dependency - reports degraded but doesn't fail
        if deps.Redis != nil {
            if err := deps.Redis.Ping(c.Context()).Err(); err != nil {
                checks["redis"] = "degraded"
            } else {
                checks["redis"] = "healthy"
            }
        }

        return c.Status(status).JSON(fiber.Map{
            "status": statusString(status),
            "checks": checks,
        })
    }
}

// Register without auth middleware
app.Get("/health", healthHandler)
app.Get("/ready", readinessHandler(deps))
```

**Check Against Ring Standards For:**
1. (HARD GATE) /health endpoint exists (liveness) per sre.md
2. (HARD GATE) /ready endpoint exists (readiness) per sre.md
3. Health endpoints bypass auth middleware
4. Database connectivity checked in readiness
5. Message queue connectivity checked
6. Optional deps don't fail readiness (just report degraded) per Ring health check pattern
7. Response includes individual check status
8. Appropriate HTTP status codes (200 vs 503)

**Severity Ratings:**
- CRITICAL: No health endpoints at all (HARD GATE violation per Ring standards)
- HIGH: No readiness probe (only liveness)
- HIGH: Health endpoints require auth
- MEDIUM: Missing dependency checks in readiness
- LOW: No degraded status for optional deps

**Output Format:**
```
## Health Checks Audit Findings

### Summary
- Liveness endpoint: Yes/No (/path)
- Readiness endpoint: Yes/No (/path)
- Dependencies checked: [list]

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 13: Configuration Management Auditor

```prompt
Audit configuration management for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Configuration" section from core.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/config.go`, `**/bootstrap/*.go`, `**/.env*`
- Keywords: `env:`, `envDefault:`, `Validate()`, `LoadConfig`, `production`
- Standards-specific: `envconfig`, `caarlos0/env`

**Reference Implementation (GOOD):**
```go
// Config with validation
type Config struct {
    EnvName    string `env:"ENV_NAME" envDefault:"development"`
    DBPassword string `env:"POSTGRES_PASSWORD"`
    AuthEnabled bool  `env:"AUTH_ENABLED" envDefault:"false"`
}

// Production validation
func (c *Config) Validate() error {
    if c.EnvName == "production" {
        // Require auth in production
        if !c.AuthEnabled {
            return errors.New("AUTH_ENABLED must be true in production")
        }
        // Require DB password in production
        if c.DBPassword == "" {
            return errors.New("POSTGRES_PASSWORD required in production")
        }
        // Require TLS for databases
        if c.PostgresSSLMode == "disable" {
            return errors.New("POSTGRES_SSLMODE cannot be disable in production")
        }
    }
    return nil
}

// Load with validation
func LoadConfig() (*Config, error) {
    cfg := &Config{}
    if err := envconfig.Process("", cfg); err != nil {
        return nil, fmt.Errorf("load env: %w", err)
    }
    if err := cfg.Validate(); err != nil {
        return nil, fmt.Errorf("validate: %w", err)
    }
    return cfg, nil
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) All config loaded from env vars (not hardcoded) per Ring core.md configuration section
2. (HARD GATE) Production-specific validation exists
3. Sensible defaults for non-production
4. Auth required in production
5. TLS/SSL required in production
6. Default credentials rejected in production
8. Secrets not logged during startup
9. Config validation fails fast (at startup)

**Severity Ratings:**
- CRITICAL: Hardcoded secrets in code (HARD GATE violation per Ring standards)
- CRITICAL: No production validation
- HIGH: Auth can be disabled in production
- HIGH: TLS not enforced in production
- MEDIUM: Missing sensible defaults
- LOW: Config not validated at startup

**Output Format:**
```
## Configuration Management Audit Findings

### Summary
- Env vars used: X fields
- Production validation: Yes/No
- Constraints enforced: [list]

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 14: Connection Management Auditor

```prompt
Audit database and cache connection management for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Core Dependency: lib-commons" section from core.md — specifically connection packages}
---END STANDARDS---

**Search Patterns:**
- Files: `**/config.go`, `**/database*.go`, `**/redis*.go`, `**/postgres*.go`
- Keywords: `MaxOpenConns`, `MaxIdleConns`, `PoolSize`, `Timeout`, `SetConnMaxLifetime`
- Standards-specific: `lib-commons`, `mpostgres`, `mredis`, `mmongo`

**Reference Implementation (GOOD):**
```go
// Database pool configuration
type DBConfig struct {
    MaxOpenConnections int `env:"POSTGRES_MAX_OPEN_CONNS" envDefault:"25"`
    MaxIdleConnections int `env:"POSTGRES_MAX_IDLE_CONNS" envDefault:"5"`
    ConnMaxLifetime    int `env:"POSTGRES_CONN_MAX_LIFETIME_MINS" envDefault:"30"`
}

// Apply pool settings
func ConfigurePool(db *sql.DB, cfg *DBConfig) {
    db.SetMaxOpenConns(cfg.MaxOpenConnections)
    db.SetMaxIdleConns(cfg.MaxIdleConnections)
    db.SetConnMaxLifetime(time.Duration(cfg.ConnMaxLifetime) * time.Minute)
}

// Redis pool configuration
type RedisConfig struct {
    PoolSize       int `env:"REDIS_POOL_SIZE" envDefault:"10"`
    MinIdleConns   int `env:"REDIS_MIN_IDLE_CONNS" envDefault:"2"`
    ReadTimeoutMs  int `env:"REDIS_READ_TIMEOUT_MS" envDefault:"3000"`
    WriteTimeoutMs int `env:"REDIS_WRITE_TIMEOUT_MS" envDefault:"3000"`
    DialTimeoutMs  int `env:"REDIS_DIAL_TIMEOUT_MS" envDefault:"5000"`
}

// Primary + Replica support
type DatabaseConnections struct {
    Primary *sql.DB
    Replica *sql.DB  // Falls back to primary if not configured
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) lib-commons connection packages used (mpostgres, mredis, mmongo) per core.md
2. DB connection pool limits configured
3. Redis pool settings configured
4. Connection timeouts set (not infinite)
5. Connection max lifetime set (prevents stale connections)
6. Idle connection limits reasonable
7. Read replica support (for scaling reads)
8. Connection health checks (ping on checkout)
9. Graceful connection shutdown

**Severity Ratings:**
- CRITICAL: No connection pool limits (unbounded connections)
- CRITICAL: HARD GATE violation — not using lib-commons connection packages
- HIGH: No connection timeouts (hang forever)
- HIGH: No max lifetime (stale connections)
- MEDIUM: Missing read replica support
- LOW: Pool sizes not tuned

**Output Format:**
```
## Connection Management Audit Findings

### Summary
- DB pool configured: Yes/No (max: X, idle: Y)
- Redis pool configured: Yes/No (size: X)
- Timeouts configured: Yes/No
- Replica support: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 15: Logging & PII Safety Auditor

```prompt
Audit logging practices and PII protection for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Logging" section from quality.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/*.go`
- Keywords: `logger.`, `log.`, `Errorf`, `Infof`, `WithFields`, `password`, `token`, `secret`
- Also search: `fmt.Print`, `fmt.Println` (should not be used for logging)
- Standards-specific: `zap`, `zerolog`, structured logging library references

**Reference Implementation (GOOD):**
```go
// Structured logging with context
logger, tracer, requestID, _ := observability.NewTrackingFromContext(ctx)
logger.WithFields(
    "request_id", requestID,
    "user_id", userID,
    "action", "create_resource",
).Info("resource created")

// Production-safe error logging
if isProduction {
    // Don't include error details that might leak PII
    logger.Errorf("operation failed: status=%d path=%s", code, path)
} else {
    // Development can have full details
    logger.Errorf("operation failed: error=%v", err)
}

// Config DSN without password
func (c *Config) DSN() string {
    // Returns connection string without logging password
    return fmt.Sprintf("host=%s port=%d user=%s dbname=%s",
        c.Host, c.Port, c.User, c.DBName)
}
```

**Reference Implementation (BAD):**
```go
// BAD: fmt.Println for logging
fmt.Println("User logged in:", userEmail)

// BAD: Logging sensitive data
logger.Infof("Login attempt: email=%s password=%s", email, password)

// BAD: Logging full request body (might contain PII)
logger.Debugf("Request body: %+v", requestBody)

// BAD: Not using structured logging
log.Printf("Error: %v", err)
```

**Check Against Ring Standards For:**
1. (HARD GATE) Structured logging used (not fmt.Print or log.Printf) per quality.md logging section
2. Logger obtained from context (request tracking)
3. No passwords/tokens logged
4. Production mode sanitizes error details
5. Request/response bodies not logged raw
6. Log levels appropriate (not everything at INFO)
7. Request IDs included for tracing
8. No PII in log messages (emails, names, etc.)

**Severity Ratings:**
- CRITICAL: Passwords/tokens logged
- CRITICAL: PII logged in production
- HIGH: fmt.Print used instead of logger (HARD GATE violation per Ring standards)
- HIGH: Full error details in production
- MEDIUM: Missing request ID in logs
- LOW: Inappropriate log levels

**Output Format:**
```
## Logging & PII Safety Audit Findings

### Summary
- Structured logging: Yes/No
- PII protection: Yes/No
- Production mode: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 36: Resilience Patterns Auditor

```prompt
Audit resilience patterns (circuit breakers, retries, timeouts, bulkheads) across the codebase for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Resilience patterns — no dedicated standards file; patterns derived from industry best practices and ring:production-readiness standards}
---END STANDARDS---

**Search Patterns:**
- Go files: `**/*.go` — search for circuit breaker, retry, timeout, backoff, bulkhead, errgroup patterns
- TypeScript files: `**/*.ts`, `**/*.tsx` — search for circuit breaker, retry, timeout, abort, concurrency limiter patterns
- Config files: `**/*.yaml`, `**/*.yml`, `**/*.json`, `**/*.toml` — search for timeout, retry, backoff configuration
- Keywords (Go): `gobreaker`, `CircuitBreaker`, `retry`, `backoff`, `Timeout`, `context.WithTimeout`, `context.WithDeadline`, `http.Client`, `Transport`, `errgroup`, `semaphore`
- Keywords (TS): `CircuitBreaker`, `cockatiel`, `opossum`, `p-retry`, `axios-retry`, `AbortController`, `setTimeout`, `Promise.race`, `semaphore`, `bulkhead`
- Keywords (general): `timeout`, `retry`, `circuit`, `breaker`, `backoff`, `jitter`, `bulkhead`, `resilience`

**Go Resilience Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| HTTP client without timeout | CRITICAL | `http.DefaultClient` or `&http.Client{}` with no `Timeout` set — blocks forever on slow downstream |
| No circuit breaker on critical dependency | CRITICAL | Direct HTTP/gRPC calls to external services without circuit breaker wrapping |
| Retry without backoff | HIGH | Retry loops using fixed delay or no delay — causes thundering herd on recovery |
| Inner timeout >= outer timeout | HIGH | `context.WithTimeout` where child timeout >= parent — cascading failure risk |
| No jitter on backoff | MEDIUM | Exponential backoff without randomization — synchronized retries across instances |
| No bulkhead isolation | MEDIUM | All external calls sharing single connection pool / goroutine pool — one slow dependency exhausts all resources |
| Hardcoded timeout values | LOW | Timeout durations as magic numbers instead of configuration — hard to tune in production |
| No retry on transient errors | LOW | External calls that fail without retry on network/5xx errors — reduced availability |

**TypeScript Resilience Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| HTTP call without timeout | CRITICAL | `fetch()` or `axios()` calls with no timeout or AbortController — hangs indefinitely |
| No circuit breaker on critical dependency | CRITICAL | Direct HTTP calls to external services without circuit breaker protection |
| Retry without backoff | HIGH | Retry logic with fixed delay or immediate retry — thundering herd risk |
| No timeout on Promise chains | HIGH | `await someExternalCall()` with no `Promise.race` timeout wrapper — blocks event loop conceptually forever |
| No jitter on backoff | MEDIUM | Exponential backoff without random jitter — correlated retries |
| No concurrency limiting | MEDIUM | Unbounded `Promise.all()` on external calls — overwhelms downstream services |
| Hardcoded timeout values | LOW | Timeout values as inline numbers instead of configuration constants |

**Timeout Cascading Analysis (MANDATORY — do not skip):**
1. **Map the call chain**: Identify entry point timeout → middleware timeout → downstream call timeouts
2. **Verify ordering**: Outer timeout MUST be greater than inner timeout at every level
3. **Example valid cascade**: API gateway 30s > service handler 25s > database query 10s > cache lookup 2s
4. **Example INVALID cascade**: API gateway 30s > service handler 30s > database query 30s (all same = no cascading)

**Reference Implementation (GOOD — Go):**
```go
// GOOD: Circuit breaker wrapping HTTP client
cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
    Name:        "downstream-api",
    MaxRequests: 3,
    Interval:    10 * time.Second,
    Timeout:     30 * time.Second,
    ReadyToTrip: func(counts gobreaker.Counts) bool {
        return counts.ConsecutiveFailures > 5
    },
})

result, err := cb.Execute(func() (interface{}, error) {
    ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
    defer cancel()
    return client.Do(req.WithContext(ctx))
})

// GOOD: Retry with exponential backoff + jitter
func retryWithBackoff(ctx context.Context, maxRetries int, fn func() error) error {
    for attempt := 0; attempt < maxRetries; attempt++ {
        if err := fn(); err != nil {
            if !isRetryable(err) {
                return err
            }
            base := time.Duration(1<<uint(attempt)) * 100 * time.Millisecond
            jitter := time.Duration(rand.Int63n(int64(base / 2)))
            select {
            case <-time.After(base + jitter):
            case <-ctx.Done():
                return ctx.Err()
            }
            continue
        }
        return nil
    }
    return fmt.Errorf("max retries exceeded")
}

// GOOD: Timeout cascading (outer > inner)
func handler(w http.ResponseWriter, r *http.Request) {
    ctx, cancel := context.WithTimeout(r.Context(), 25*time.Second) // handler: 25s
    defer cancel()

    dbCtx, dbCancel := context.WithTimeout(ctx, 10*time.Second) // db: 10s < 25s
    defer dbCancel()
    data, err := db.QueryContext(dbCtx, query)
}

// GOOD: HTTP client with explicit timeouts
client := &http.Client{
    Timeout: 30 * time.Second,
    Transport: &http.Transport{
        ResponseHeaderTimeout: 10 * time.Second,
        IdleConnTimeout:       90 * time.Second,
        MaxIdleConnsPerHost:   10,
    },
}
```

**Reference Implementation (BAD — Go):**
```go
// BAD: http.DefaultClient — no timeout, blocks forever
resp, err := http.DefaultClient.Do(req)

// BAD: Custom client with no timeout
client := &http.Client{}
resp, err := client.Do(req)

// BAD: Retry without backoff — thundering herd
for i := 0; i < 3; i++ {
    resp, err = client.Do(req)
    if err == nil {
        break
    }
    // No delay between retries!
}

// BAD: Inner timeout >= outer timeout — cascading failure
ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second) // outer: 10s
defer cancel()
dbCtx, dbCancel := context.WithTimeout(ctx, 10*time.Second) // inner: 10s (same!)
defer dbCancel()
```

**Reference Implementation (GOOD — TypeScript):**
```typescript
// GOOD: Circuit breaker with cockatiel
import { CircuitBreakerPolicy, ConsecutiveBreaker, handleAll, retry, wrap } from 'cockatiel';

const circuitBreaker = new CircuitBreakerPolicy(handleAll, {
  halfOpenAfter: 30_000,
  breaker: new ConsecutiveBreaker(5),
});

const retryPolicy = retry(handleAll, {
  maxAttempts: 3,
  backoff: new ExponentialBackoff({ initialDelay: 100, maxDelay: 5000 }),
});

const policy = wrap(retryPolicy, circuitBreaker);
const result = await policy.execute(() => fetchFromDownstream());

// GOOD: Timeout with AbortController
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 10_000);
try {
  const response = await fetch(url, { signal: controller.signal });
} finally {
  clearTimeout(timeout);
}
```

**Reference Implementation (BAD — TypeScript):**
```typescript
// BAD: No timeout on fetch — hangs forever
const response = await fetch(url);

// BAD: Retry in tight loop
for (let i = 0; i < 3; i++) {
  try {
    return await fetch(url);
  } catch {
    continue; // No delay!
  }
}

// BAD: Unbounded concurrent requests — overwhelms downstream
const results = await Promise.all(
  urls.map(url => fetch(url)) // No concurrency limit
);
```

**Check Against Standards For:**
1. (CRITICAL) All external HTTP clients have explicit timeouts configured
2. (CRITICAL) Critical downstream dependencies are wrapped with circuit breakers
3. (HIGH) All retry logic uses exponential backoff (not fixed delay or no delay)
4. (HIGH) Timeout cascading is correct: outer timeout > inner timeout at every level
5. (MEDIUM) Retry backoff includes jitter to prevent synchronized retries
6. (MEDIUM) Bulkhead isolation exists between dependency pools (separate connection pools, bounded concurrency)
7. (MEDIUM) Concurrency is bounded on parallel external calls (errgroup limit in Go, semaphore in TS)
8. (LOW) Timeout and retry values are configurable (not hardcoded magic numbers)
9. (LOW) Transient errors are retried; non-transient errors fail fast

**Severity Ratings:**
- CRITICAL: No timeout on external HTTP calls (service hangs indefinitely), no circuit breaker on critical downstream dependency (cascading failure to all instances)
- HIGH: Retry without backoff (thundering herd on recovery), inner timeout >= outer timeout (timeout cascade violation), no timeout on Promise chains (TypeScript)
- MEDIUM: No jitter on retry backoff (correlated retries), no bulkhead isolation between pools (one slow dependency affects all), unbounded concurrent external calls
- LOW: Hardcoded timeout values (hard to tune), no retry on transient errors (reduced availability), missing resilience documentation

**Output Format:**
```
## Resilience Patterns Audit Findings

### Summary
- Language(s) detected: {Go / TypeScript / Both}
- HTTP clients audited: X total, Y without timeouts
- Circuit breakers found: X (covering Y of Z external dependencies)
- Retry patterns found: X total, Y without backoff, Z without jitter
- Timeout cascade: Valid/Invalid (deepest chain: {description})
- Bulkhead patterns: X isolation boundaries found

### Critical Issues
[file:line] - Description (pattern: {pattern name})
  Evidence: {code snippet}
  Impact: {what happens in production}
  Fix: {specific remediation}

### High Issues
[file:line] - Description (pattern: {pattern name})
  Evidence: {code snippet}
  Fix: {specific remediation}

### Medium Issues
[file:line] - Description

### Low Issues
[file:line] - Description

### Timeout Cascade Map
{Entry point} (Xs) → {middleware} (Ys) → {downstream} (Zs)
Status: Valid/INVALID — {explanation}

### Recommendations
1. ...
```
```

### Agent 39: Graceful Degradation Auditor

```prompt
Audit graceful degradation and fallback behavior when downstream dependencies fail for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Graceful degradation patterns — no dedicated standards file; patterns derived from operational readiness best practices}
---END STANDARDS---

**Search Patterns:**
- Go files: `**/*.go` — search for fallback handlers, circuit breakers, cached responses, feature flags, default values
- TypeScript files: `**/*.ts`, `**/*.tsx` — search for fallback chains, error boundaries, feature flag SDKs, service workers
- Config files: `**/*.yaml`, `**/*.yml`, `**/*.json` — search for feature flag configuration, fallback settings
- Keywords (Go): `fallback`, `circuitbreaker`, `circuit_breaker`, `degrade`, `stale`, `cache.Get`, `default`, `feature`, `toggle`, `killswitch`, `kill_switch`, `singleflight`
- Keywords (TS): `fallback`, `ErrorBoundary`, `errorBoundary`, `featureFlag`, `feature_flag`, `LaunchDarkly`, `unleash`, `serviceWorker`, `caches.match`

**Go Graceful Degradation Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| No fallback for critical paths | CRITICAL | Payment, transaction, or auth endpoints with no fallback when downstream fails |
| Single dependency crash | HIGH | Service panics or returns 500 when any single dependency (Redis, DB, external API) is unavailable |
| No cached response capability | HIGH | Read-heavy endpoints with no cache-aside or stale-serve mechanism |
| No feature flags | MEDIUM | New features deployed without feature flag or kill switch for rollback |
| All-or-nothing responses | MEDIUM | Endpoints return full error instead of partial data with degraded indicator |
| No degradation indicators | LOW | Responses do not signal degraded state to callers (missing headers, status fields) |

**TypeScript Graceful Degradation Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| No fallback for critical paths | CRITICAL | Payment or checkout flows with no fallback when API fails |
| No error boundaries | HIGH | React components without ErrorBoundary wrappers for isolating failures |
| No service worker caching | MEDIUM | Frontend serves blank page when API is unavailable instead of cached content |
| No feature flag integration | MEDIUM | Features shipped without flag SDK (LaunchDarkly, Unleash, custom) |
| Missing retry with fallback | MEDIUM | API calls that retry forever or fail immediately instead of falling back |
| No offline support | LOW | App provides no indication or functionality when network is unavailable |

**Fallback Chain Methodology (MANDATORY — do not skip):**
1. **Identify critical paths**: Map all endpoints/flows that involve payment, authentication, or data mutation
2. **Trace dependencies**: For each critical path, list all downstream dependencies (DB, cache, external APIs, message queues)
3. **Check fallback existence**: For each dependency, verify there is a fallback path when it is unavailable
4. **Verify cache-aside**: For read-heavy endpoints, verify cached/stale data can be served when primary source is down
5. **Check kill switches**: For new or risky features, verify feature flags exist for quick disable

**Reference Implementation (GOOD — Go):**
```go
// GOOD: Fallback to cached data when DB unavailable
func (s *Service) GetProduct(ctx context.Context, id string) (*Product, error) {
    product, err := s.repo.FindByID(ctx, id)
    if err != nil {
        // Fallback to cache
        cached, cacheErr := s.cache.Get(ctx, "product:"+id)
        if cacheErr == nil {
            return cached.(*Product), nil // serve stale data
        }
        return nil, fmt.Errorf("product unavailable: %w", err)
    }
    // Update cache for future fallbacks
    _ = s.cache.Set(ctx, "product:"+id, product, 10*time.Minute)
    return product, nil
}

// GOOD: Circuit breaker with fallback handler
func (s *Service) CallExternalAPI(ctx context.Context, req *Request) (*Response, error) {
    resp, err := s.breaker.Execute(func() (interface{}, error) {
        return s.client.Do(ctx, req)
    })
    if err != nil {
        // Circuit open — return default response
        return s.defaultResponse(req), nil
    }
    return resp.(*Response), nil
}

// GOOD: Feature flag for gradual rollout
func (s *Service) ProcessPayment(ctx context.Context, payment *Payment) error {
    if s.featureFlags.IsEnabled("new-payment-gateway") {
        return s.newGateway.Process(ctx, payment)
    }
    return s.legacyGateway.Process(ctx, payment) // safe fallback
}
```

**Reference Implementation (BAD — Go):**
```go
// BAD: No fallback — entire endpoint fails if Redis is down
func (s *Service) GetProduct(ctx context.Context, id string) (*Product, error) {
    cached, err := s.cache.Get(ctx, "product:"+id)
    if err != nil {
        return nil, fmt.Errorf("cache unavailable: %w", err) // no DB fallback
    }
    return cached.(*Product), nil
}

// BAD: No circuit breaker — hangs or crashes on external API failure
func (s *Service) CallExternalAPI(ctx context.Context, req *Request) (*Response, error) {
    return s.client.Do(ctx, req) // no timeout, no fallback, no breaker
}

// BAD: No kill switch — risky feature deployed with no way to disable
func (s *Service) ProcessPayment(ctx context.Context, payment *Payment) error {
    return s.newGateway.Process(ctx, payment) // no fallback to legacy
}
```

**Reference Implementation (GOOD — TypeScript):**
```typescript
// GOOD: Fallback chain — try primary, secondary, then cached
async function fetchUserProfile(userId: string): Promise<UserProfile> {
    try {
        return await primaryAPI.getUser(userId);
    } catch {
        try {
            return await secondaryAPI.getUser(userId);
        } catch {
            const cached = await cache.get(`user:${userId}`);
            if (cached) return cached;
            throw new ServiceDegradedError('User profile unavailable');
        }
    }
}

// GOOD: Error boundary isolating component failures
function App() {
    return (
        <ErrorBoundary fallback={<FallbackUI />}>
            <Dashboard />
        </ErrorBoundary>
    );
}
```

**Reference Implementation (BAD — TypeScript):**
```typescript
// BAD: No fallback — UI crashes when API fails
async function fetchUserProfile(userId: string): Promise<UserProfile> {
    const response = await fetch(`/api/users/${userId}`);
    return response.json(); // no error handling, no fallback
}

// BAD: No error boundary — one component crash takes down entire app
function App() {
    return <Dashboard />; // if Dashboard throws, entire app white-screens
}
```

**Check Against Standards For:**
1. (CRITICAL) Critical payment/transaction paths have fallback when downstream fails
2. (HIGH) Service does not crash when any single dependency is unavailable
3. (HIGH) Read-heavy endpoints can serve cached/default responses when primary source is down
4. (HIGH) React/frontend apps use error boundaries to isolate component failures
5. (MEDIUM) New or risky features have feature flags or kill switches for quick disable
6. (MEDIUM) Endpoints return partial data with degradation indicators instead of full failure
7. (MEDIUM) Retry logic includes fallback path, not infinite retry
8. (LOW) Responses include degradation status indicators (headers, fields) when serving fallback data
9. (LOW) Frontend provides offline or degraded-mode experience

**Severity Ratings:**
- CRITICAL: No fallback for critical payment/transaction/auth paths — service is fully unavailable when dependency fails
- HIGH: Service crashes (panic/500) when any single dependency (Redis, DB, external API) is unavailable; no cached response capability for read-heavy endpoints; no error boundaries in frontend
- MEDIUM: No feature flags for risky new features; all-or-nothing responses with no partial degradation; retry without fallback
- LOW: No degradation status indicators in responses; no offline support in frontend

**Output Format:**
```
## Graceful Degradation Audit Findings

### Summary
- Critical paths identified: X
- Paths with fallback: Y/X
- Cache-aside patterns: Y (of Z read-heavy endpoints)
- Feature flags present: Yes/No (library: {name})
- Error boundaries (TS): Y/Z components
- Kill switches for new features: Yes/No

### Critical Issues
[file:line] - Description (pattern: {pattern name})

### High Issues
[file:line] - Description (pattern: {pattern name})

### Medium Issues
[file:line] - Description

### Low Issues
[file:line] - Description

### Dependency Failure Impact Map
{For each critical path, show: dependency → failure mode → current behavior → recommended fallback}

### Recommendations
1. ...
```
```

