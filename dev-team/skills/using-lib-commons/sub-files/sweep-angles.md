## Explorer Angle Specifications

MANDATORY: All 22 angles run on every sweep. The catalog below is the source of truth
for what each explorer looks for. MUST NOT edit angle specs at dispatch time — copy
verbatim into the explorer prompt.

---

#### Angle 1: Bootstrap & lifecycle

**Severity:** MEDIUM

**DIY Patterns to Detect:**
- `signal.Notify(` with `os.Interrupt` or `syscall.SIGTERM` in `main.go` or `cmd/*/main.go`
- Manual `go func()` launches without panic recovery
- Custom `sync.WaitGroup` orchestration for shutdown
- Hand-rolled "start N goroutines, wait for signal, cancel context, wait for all" patterns
- `context.WithCancel(context.Background())` in `main()` wired manually through app layers

**lib-commons Replacement:**
- `commons.Launcher` — standard app lifecycle (start, run, shutdown, signal handling)
- `commons/server.ServerManager` — HTTP/gRPC server lifecycle with graceful drain

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
func main() {
    ctx, cancel := context.WithCancel(context.Background())
    sigCh := make(chan os.Signal, 1)
    signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)

    var wg sync.WaitGroup
    wg.Add(1)
    go func() {
        defer wg.Done()
        runServer(ctx)
    }()

    <-sigCh
    cancel()
    wg.Wait()
}

// lib-commons (AFTER):
func main() {
    launcher := commons.NewLauncher(
        commons.WithServer(server.NewServerManager(cfg)),
        commons.WithLogger(logger),
    )
    if err := launcher.Run(context.Background()); err != nil {
        logger.Fatal("launcher failed", err)
    }
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for service bootstrap DIY. Search `main.go`, `cmd/*/main.go`, and
> any `internal/app/` or `internal/bootstrap/` packages. MUST flag manual
> `signal.Notify(os.Interrupt)` handlers, raw `go func()` launches in main, custom
> `sync.WaitGroup` shutdown orchestration, and hand-wired `context.WithCancel` +
> cancel-on-signal patterns. For each finding record file:line, the specific pattern, and
> whether the fix requires `commons.Launcher` (app-level) or `commons/server.ServerManager`
> (HTTP/gRPC only). Severity MEDIUM — these patterns work, but miss observability and
> graceful-drain integration.

---

#### Angle 2: PostgreSQL DIY

**Severity:** HIGH

**DIY Patterns to Detect:**
- `sql.Open("postgres"` or `sql.Open("pgx"` in any file
- `pgx.Connect(`, `pgxpool.New(`, `pgxpool.Connect(`
- Manual `SetMaxOpenConns` / `SetMaxIdleConns` / `SetConnMaxLifetime` tuning
- Hand-rolled migration runners (walking a directory, executing `.sql` files)
- Custom primary/replica routing logic
- Connection structs wrapping `*sql.DB` or `*pgxpool.Pool` without using `commons/postgres`

**lib-commons Replacement:**
- `commons/postgres.New(cfg)` — primary/replica pools, lazy connect, pool tuning defaults
- `commons/postgres.Connection` — exposes `Primary()`, `Replica()`, health checks
- Built-in migration runner

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
db, err := sql.Open("postgres", cfg.PostgresURL)
if err != nil {
    return nil, err
}
db.SetMaxOpenConns(25)
db.SetMaxIdleConns(5)
db.SetConnMaxLifetime(5 * time.Minute)
if err := db.PingContext(ctx); err != nil {
    return nil, err
}

// lib-commons (AFTER):
pg, err := postgres.New(postgres.Config{
    PrimaryURL: cfg.PostgresPrimaryURL,
    ReplicaURL: cfg.PostgresReplicaURL,
    MaxOpen:    25,
})
if err != nil {
    return nil, err
}
// pg.Primary() and pg.Replica() return tuned pools
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for PostgreSQL DIY. Search for `sql.Open(`, `pgx.Connect(`,
> `pgxpool.New(`, `pgxpool.Connect(`, and any struct that embeds `*sql.DB` or
> `*pgxpool.Pool` directly (as opposed to going through `commons/postgres.Connection`).
> MUST flag manual pool tuning calls (`SetMaxOpenConns`, `SetMaxIdleConns`,
> `SetConnMaxLifetime`) and hand-rolled migration runners. For each finding record
> file:line, whether the code reads from replicas (and does so correctly), and whether
> migrations are handled. Severity HIGH — DIY here costs pool health, replica offload, and
> observability hooks.

---

#### Angle 3: MongoDB DIY

**Severity:** HIGH

**DIY Patterns to Detect:**
- `mongo.Connect(` without a wrapper that handles lazy reconnect
- `client.Database(...).Collection(...)` calls without index guarantees
- Hand-rolled `EnsureIndexes` equivalents (creating indexes without idempotent check-and-create)
- Missing `client.Ping()` before usage
- Custom reconnect loops using `time.Sleep`

**lib-commons Replacement:**
- `commons/mongo.NewClient(cfg)` — double-checked locking for lazy reconnect, idempotent
  `EnsureIndexes`, built-in health checks
- `commons/mongo.Client.Database()` / `Collection()` helpers

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
client, err := mongo.Connect(ctx, options.Client().ApplyURI(cfg.MongoURL))
if err != nil {
    return nil, err
}
coll := client.Database("app").Collection("users")
_, _ = coll.Indexes().CreateOne(ctx, mongo.IndexModel{
    Keys: bson.M{"email": 1},
    Options: options.Index().SetUnique(true),
})

// lib-commons (AFTER):
mc, err := mongo.NewClient(mongo.Config{URI: cfg.MongoURL, Database: "app"})
if err != nil {
    return nil, err
}
if err := mc.EnsureIndexes(ctx, "users", []mongo.IndexSpec{
    {Keys: bson.M{"email": 1}, Unique: true},
}); err != nil {
    return nil, err
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for MongoDB DIY. Search for `mongo.Connect(`, direct
> `client.Database().Collection()` access outside a `commons/mongo` wrapper, and any
> index creation that isn't idempotent (missing `EnsureIndexes` pattern). MUST flag
> custom reconnect loops (`time.Sleep` + retry) and missing `Ping` before first use. For
> each finding record file:line, the collection being accessed, and whether indexes are
> enforced. Severity HIGH — DIY here costs reconnection safety and index drift detection.

---

#### Angle 4: Redis DIY

**Severity:** HIGH

**DIY Patterns to Detect:**
- `redis.NewClient(` (standalone) without topology abstraction
- `redis.NewFailoverClient(` with manual sentinel config
- `redis.NewClusterClient(` with manual node list
- Custom Redlock implementations (multi-node lock acquisition)
- Hand-rolled distributed locks using `SET NX EX` without safety primitives (no lock
  token, no unlock-by-token Lua script)

**lib-commons Replacement:**
- `commons/redis.New(cfg)` — single entry point for standalone/sentinel/cluster
- `commons/redis.RedisLockManager` — safe distributed locks with token-based unlock

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
client := redis.NewClient(&redis.Options{
    Addr:     cfg.RedisAddr,
    Password: cfg.RedisPassword,
    DB:       0,
})
ok, err := client.SetNX(ctx, "lock:tx:123", "held", 30*time.Second).Result()
if err != nil || !ok {
    return errors.New("lock not acquired")
}
defer client.Del(ctx, "lock:tx:123") // unsafe — no token check

// lib-commons (AFTER):
r, err := redis.New(redis.Config{Topology: redis.Standalone, Addr: cfg.RedisAddr})
if err != nil {
    return err
}
locks := redis.NewLockManager(r)
lock, err := locks.Acquire(ctx, "tx:123", 30*time.Second)
if err != nil {
    return err
}
defer lock.Release(ctx) // token-based, safe against expired-then-reacquired
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for Redis DIY. Search for `redis.NewClient(`,
> `redis.NewFailoverClient(`, `redis.NewClusterClient(`, and custom Redlock or
> `SetNX`-based lock implementations. MUST flag any `defer client.Del(ctx, lockKey)`
> pattern that doesn't validate a lock token (unsafe unlock — can release another
> process's lock after expiry). For each finding record file:line, the topology in use,
> and whether distributed locks are token-safe. Severity HIGH — unsafe locks corrupt
> state under contention.

---

#### Angle 5: RabbitMQ DIY

**Severity:** HIGH

**DIY Patterns to Detect:**
- `amqp.Dial(` or `amqp091.Dial(` without a reconnect-capable wrapper
- Publishers without `channel.Confirm()` (fire-and-forget, message loss on broker crash)
- Consumer loops that don't re-establish channel on connection errors
- Manual exchange/queue declarations scattered across handlers
- DLQ topology absent or hand-rolled (no `x-dead-letter-exchange` header, no retry queue
  with TTL-based re-enqueue)

**lib-commons Replacement:**
- `commons/rabbitmq.RabbitMQConnection` — managed reconnect, channel pool
- `commons/rabbitmq.ConfirmablePublisher` — publisher with `Confirm()` mode enabled
- `commons/rabbitmq.SetupDLQTopology` — declares exchange, main queue, DLX, DLQ, retry
  queue with TTL-based republish

**Migration Complexity:** complex

**Example Transformation:**

```go
// DIY (BEFORE):
conn, err := amqp.Dial(cfg.RabbitMQURL)
if err != nil {
    return err
}
ch, err := conn.Channel()
if err != nil {
    return err
}
// no Confirm mode — silent message loss if broker crashes mid-publish
err = ch.PublishWithContext(ctx, "", "events", false, false, amqp.Publishing{
    Body: payload,
})

// lib-commons (AFTER):
rmq, err := rabbitmq.New(rabbitmq.Config{URL: cfg.RabbitMQURL})
if err != nil {
    return err
}
if err := rmq.SetupDLQTopology(ctx, "events"); err != nil {
    return err
}
pub := rmq.ConfirmablePublisher("events")
if err := pub.Publish(ctx, payload); err != nil {
    return err // confirmed — broker ack'd or error returned
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for RabbitMQ DIY. Search for `amqp.Dial(`, `amqp091.Dial(`,
> direct `conn.Channel()` usage outside a reconnect-capable wrapper, and publishers that
> don't call `Confirm()`. MUST flag consumer goroutines that don't handle connection loss
> (no reconnect loop). MUST flag manual exchange/queue declarations scattered through
> handler code instead of centralized topology setup. MUST flag any queue that lacks DLQ
> wiring (no `x-dead-letter-exchange` argument). For each finding record file:line, the
> queue/exchange name, and whether confirms are enabled. Severity HIGH — the failure
> modes here cause silent message loss, which is worse than outage.

---

#### Angle 6: HTTP middleware DIY

**Severity:** MEDIUM

**DIY Patterns to Detect:**
- Custom Fiber (or gin/chi/echo) middleware implementing CORS, request logging, or
  OpenTelemetry tracing
- Inline `c.Set("Access-Control-Allow-Origin", ...)` scattered across handlers
- Hand-rolled request ID / correlation ID propagation
- Manual `otel.Tracer(...).Start(...)` wrapping handler logic

**lib-commons + lib-observability Replacement:**
- `commons/net/http.WithCORS` — configurable CORS with safe defaults
- `lib-observability/middleware.WithHTTPLogging` — structured request logging via `lib-observability/zap`
- `lib-observability/middleware.NewTelemetryMiddleware` — OTel span per request + metrics emission

**Migration Complexity:** trivial

**Example Transformation:**

```go
// DIY (BEFORE):
app.Use(func(c *fiber.Ctx) error {
    c.Set("Access-Control-Allow-Origin", "*")
    c.Set("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE")
    return c.Next()
})
app.Use(func(c *fiber.Ctx) error {
    start := time.Now()
    err := c.Next()
    log.Printf("%s %s %d %dms", c.Method(), c.Path(), c.Response().StatusCode(), time.Since(start).Milliseconds())
    return err
})

// lib-commons + lib-observability (AFTER):
app.Use(http.WithCORS(http.CORSConfig{AllowedOrigins: cfg.AllowedOrigins}))
app.Use(middleware.WithHTTPLogging(middleware.WithCustomLogger(logger)))
app.Use(middleware.NewTelemetryMiddleware(tl).WithTelemetry(tl))
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for HTTP middleware DIY. Search for `app.Use(func(c *fiber.Ctx)`
> (and gin/chi/echo equivalents) where the middleware implements CORS headers, request
> logging, tracing, or correlation ID propagation. MUST flag inline CORS header setting
> in handlers. For each finding record file:line and which concern the DIY middleware
> covers. Severity MEDIUM — the DIY usually works, but misses structured logging fields
> and OTel attribute conventions.

---

#### Angle 7: Rate limiting DIY

**Severity:** HIGH

**DIY Patterns to Detect:**
- In-memory counter maps (`map[string]int` with a mutex) used as rate limiters
- `time.Ticker`-based token buckets without shared state
- `golang.org/x/time/rate.Limiter` instantiated per-process (not distributed)
- Rate-limit logic that doesn't survive across replicas

**lib-commons Replacement:**
- `commons/net/http/ratelimit` — Redis-backed sliding window, atomic Lua `INCR + PEXPIRE`,
  shared state across replicas

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
var (
    mu      sync.Mutex
    counts  = map[string]int{}
    windows = map[string]time.Time{}
)

func rateLimit(key string, limit int, window time.Duration) bool {
    mu.Lock()
    defer mu.Unlock()
    now := time.Now()
    if now.Sub(windows[key]) > window {
        counts[key] = 0
        windows[key] = now
    }
    counts[key]++
    return counts[key] <= limit
}

// lib-commons (AFTER):
limiter := ratelimit.New(redisClient, ratelimit.Config{
    Limit:  100,
    Window: time.Minute,
})
app.Use(limiter.Middleware(func(c *fiber.Ctx) string {
    return c.IP() // key function
}))
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for rate-limiting DIY. Search for in-memory counter patterns
> (`map[string]int` + mutex used for throttling), `time.Ticker`-based limiters, and
> per-process `rate.Limiter` instances used in HTTP handlers. MUST flag any rate limit
> that claims to protect a multi-replica service without Redis or another shared store.
> For each finding record file:line and what's being rate-limited (IP, user, tenant).
> Severity HIGH — per-process limiters silently multiply allowed traffic by replica
> count.

---

#### Angle 8: Idempotency DIY

**Severity:** MEDIUM

**DIY Patterns to Detect:**
- Custom `idempotency_keys` table with hand-written dedupe logic
- `Idempotency-Key` header handling without response replay (returns generic "duplicate"
  instead of original response)
- Idempotency keys not scoped by tenant (cross-tenant key collision risk)
- DB-backed idempotency when Redis is already available (wrong substrate)

**lib-commons Replacement:**
- `commons/net/http/idempotency` — Redis `SetNX`-based, tenant-scoped keys, faithful
  response replay (same status + body + headers)

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
func handler(c *fiber.Ctx) error {
    key := c.Get("Idempotency-Key")
    if key == "" {
        return c.Status(400).JSON(fiber.Map{"error": "missing key"})
    }
    var exists bool
    _ = db.QueryRow("SELECT EXISTS(SELECT 1 FROM idem_keys WHERE key=$1)", key).Scan(&exists)
    if exists {
        return c.Status(409).JSON(fiber.Map{"error": "duplicate"}) // wrong — should replay
    }
    _, _ = db.Exec("INSERT INTO idem_keys(key) VALUES($1)", key)
    return processRequest(c)
}

// lib-commons (AFTER):
app.Use(idempotency.Middleware(idempotency.Config{
    Redis:    redisClient,
    TTL:      24 * time.Hour,
    TenantFn: func(c *fiber.Ctx) string { return c.Locals("tenantId").(string) },
}))
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for idempotency DIY. Search for `Idempotency-Key` header handling,
> `idempotency_keys` table references, and custom dedupe tables. MUST flag implementations
> that return "duplicate" errors instead of replaying the original response. MUST flag
> keys stored without tenant scoping in multi-tenant services. For each finding record
> file:line and the substrate (DB vs Redis). Severity MEDIUM — correctness issue when
> clients retry after network errors.

---

#### Angle 9: Pagination DIY

**Severity:** LOW

**DIY Patterns to Detect:**
- Hand-rolled offset pagination (`LIMIT ? OFFSET ?` with manual `page` + `per_page`
  params)
- Custom cursor encoding (base64 of JSON blob) without standard format
- Inconsistent link header formats across endpoints
- Missing `next`/`prev` cursor tokens on list responses

**lib-commons Replacement:**
- `commons/net/http` pagination helpers: offset pagination, UUID cursor, timestamp
  cursor, sort cursor — all with consistent link format

**Migration Complexity:** trivial

**Example Transformation:**

```go
// DIY (BEFORE):
page, _ := strconv.Atoi(c.Query("page", "1"))
perPage, _ := strconv.Atoi(c.Query("per_page", "20"))
offset := (page - 1) * perPage
rows, _ := db.Query("SELECT ... LIMIT $1 OFFSET $2", perPage, offset)

// lib-commons (AFTER):
pg := http.ParseOffsetPagination(c)
rows, _ := db.Query("SELECT ... LIMIT $1 OFFSET $2", pg.Limit, pg.Offset)
return http.Respond(c, http.PaginatedResponse{Data: items, Pagination: pg.Response(totalCount)})
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for pagination DIY. Search for inline `LIMIT ? OFFSET ?` SQL with
> `page`/`per_page` query param parsing, custom base64 cursor encoding, and inconsistent
> list-response shapes. MUST flag endpoints returning arrays without pagination metadata.
> For each finding record file:line and the pagination mode (offset vs cursor). Severity
> LOW — mostly ergonomic, but consistency matters for API consumers.

---

#### Angle 10: Validation DIY

**Severity:** LOW

**DIY Patterns to Detect:**
- Inline `validator.New().Struct(x)` calls scattered across handlers
- Custom `validator.RegisterValidation(` calls for financial types (`positive_decimal`,
  `nonnegative_amount`, currency codes)
- Hand-rolled body parsing + validation (`c.BodyParser(&req); if err := validate.Struct(req)`)

**lib-commons Replacement:**
- `commons/net/http.ParseBodyAndValidate` — single call parses body + validates
- `commons/net/http.ValidateStruct` — standalone validation
- Pre-registered financial tags: `positive_decimal`, `nonnegative_amount`, `currency`,
  `iso_country`, etc.

**Migration Complexity:** trivial

**Example Transformation:**

```go
// DIY (BEFORE):
var req CreateTransactionRequest
if err := c.BodyParser(&req); err != nil {
    return c.Status(400).JSON(fiber.Map{"error": err.Error()})
}
validate := validator.New()
if err := validate.Struct(req); err != nil {
    return c.Status(400).JSON(fiber.Map{"error": err.Error()})
}

// lib-commons (AFTER):
var req CreateTransactionRequest
if err := http.ParseBodyAndValidate(c, &req); err != nil {
    return http.RenderError(c, err)
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for validation DIY. Search for `validator.New()`,
> `validator.RegisterValidation(`, and inline `BodyParser + Struct` two-step patterns. MUST
> flag custom validator tags that duplicate lib-commons financial tags (positive_decimal,
> nonnegative_amount, currency, iso_country). For each finding record file:line and the
> validated struct. Severity LOW — ergonomic, but inconsistent validator config causes
> subtle bugs (e.g., required-vs-optional mismatches).

---

#### Angle 11: Response helpers DIY

**Severity:** LOW

**DIY Patterns to Detect:**
- Scattered `c.Status(status).JSON(body)` calls without a response helper
- Inconsistent error response shapes (some `{"error": msg}`, some `{"message": msg}`,
  some `{"code": X, "detail": Y}`)
- Missing standard fields (no `traceId`, no `timestamp`, no `errorCode`)

**lib-commons Replacement:**
- `commons/net/http.Respond(c, body)` — standard success shape
- `commons/net/http.RespondError(c, err)` — standard error shape with trace ID
- `commons/net/http.RespondStatus(c, status, body)` — explicit status
- `commons/net/http.RenderError(c, err)` — error with correct HTTP status inference

**Migration Complexity:** trivial

**Example Transformation:**

```go
// DIY (BEFORE):
if err != nil {
    return c.Status(500).JSON(fiber.Map{"error": err.Error()})
}
return c.Status(200).JSON(result)

// lib-commons (AFTER):
if err != nil {
    return http.RenderError(c, err)
}
return http.Respond(c, result)
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for response helper DIY. Search for `c.Status(...).JSON(` and
> `c.JSON(` calls in HTTP handlers that don't route through `commons/net/http.Respond`,
> `RespondError`, `RespondStatus`, or `RenderError`. MUST flag inconsistent error shapes
> across handlers. For each finding record file:line and the response shape in use.
> Severity LOW — consistency for API consumers.

---

#### Angle 12: JWT DIY

**Severity:** CRITICAL

**DIY Patterns to Detect:**
- Direct imports of `github.com/golang-jwt/jwt` (any version) in application code
- `jwt.Parse(` or `jwt.ParseWithClaims(` without an algorithm allowlist in the keyfunc
  (algorithm confusion vulnerability — accepts `none` or swaps HS/RS)
- HMAC signature comparison using `==` or `bytes.Equal` (timing attack) instead of
  `hmac.Equal`
- Token signing with hardcoded secrets or secrets read directly from env without
  `commons/jwt`

**lib-commons Replacement:**
- `commons/jwt.ParseAndValidate(token, key, opts)` — enforced HS256/384/512 allowlist,
  constant-time HMAC comparison
- `commons/jwt.Sign(claims, key, alg)` — sign with vetted algorithms only

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
token, err := jwt.Parse(raw, func(t *jwt.Token) (interface{}, error) {
    return []byte(os.Getenv("JWT_SECRET")), nil
})
// Missing alg check — accepts "none" algorithm and bypasses signature

// lib-commons (AFTER):
claims, err := jwt.ParseAndValidate(raw, key, jwt.Options{
    AllowedAlgs: []string{jwt.HS256},
})
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for JWT DIY. Search for imports of `github.com/golang-jwt/jwt`
> (v4 or v5) in non-lib-commons code, `jwt.Parse(`, `jwt.ParseWithClaims(`, and any HMAC
> comparison that doesn't use `hmac.Equal` (constant-time). MUST flag any keyfunc that
> doesn't verify `token.Method.Alg()` against an allowlist — this is the algorithm
> confusion vulnerability (CVE-class). For each finding record file:line, the parse
> pattern, and whether `none` algorithm would be accepted. Severity CRITICAL — these are
> auth bypass vulnerabilities.

---

#### Angle 13: Crypto DIY

**Severity:** CRITICAL

**DIY Patterns to Detect:**
- Raw `aes.NewCipher(` usage with CBC mode (missing authenticated encryption — malleable
  ciphertext)
- `cipher.NewGCM(` used correctly but without HMAC wrapping for associated data integrity
- Hand-rolled HMAC-SHA256 implementations instead of `crypto/hmac`
- Hardcoded encryption keys in source
- Error messages that include plaintext or key material (`fmt.Errorf("decrypt failed for
  key %s", keyMaterial)`)

**lib-commons Replacement:**
- `commons/crypto.Crypto` — AES-256-GCM + HMAC-SHA256 envelope, constant-time verification,
  credential redaction in error paths

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
block, _ := aes.NewCipher(key)
mode := cipher.NewCBCEncrypter(block, iv) // CBC — malleable
ciphertext := make([]byte, len(plaintext))
mode.CryptBlocks(ciphertext, plaintext)

// lib-commons (AFTER):
c, err := crypto.New(crypto.Config{Key: key})
if err != nil {
    return err
}
ciphertext, err := c.Encrypt(plaintext) // GCM + HMAC
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for crypto DIY. Search for `aes.NewCipher(`, `cipher.NewCBC*`,
> `cipher.NewGCM(`, raw `hmac.New(`, and any hardcoded byte slice or string literal used
> as an encryption key. MUST flag CBC mode usage (malleable ciphertext — use GCM). MUST
> flag error messages that may leak plaintext or key material. For each finding record
> file:line, the cipher mode, and key provenance (env, config, hardcoded). Severity
> CRITICAL — crypto bugs are silent until exploited.

---

#### Angle 14: Observability setup DIY *(canonical home: lib-observability)*

**Severity:** HIGH

**Scope note:** The observability layer moved to `lib-observability` v1.0.0. This angle still runs in the lib-commons sweep, but its detection logic now flags **both** raw DIY **and** continued use of the deprecated lib-commons shim paths. The replacement target is `lib-observability/{log,zap,tracing,metrics}`. For deep audits, prefer `ring:using-lib-observability` and `ring:using-tracing` over this single-angle breadth pass.

**DIY Patterns to Detect:**
- Custom `zap.NewProduction()` / `zap.NewDevelopment()` without a Lerian wrapper
- Manual `otel.Tracer(...)` / `otel.Meter(...)` creation without centralized factory
- Hardcoded OTLP exporter endpoints in app code
- Metrics created ad-hoc (`meter.Int64Counter(...)`) without a `MetricsFactory`
- No trace context propagation between services
- **Deprecated shim imports**: `github.com/LerianStudio/lib-commons/v5/commons/{log,zap,opentelemetry,opentelemetry/metrics}` — these still compile via shims but new code MUST use `lib-observability` instead

**Replacement (lib-observability):**
- `lib-observability/zap.New(cfg)` — structured logger with standard fields
- `lib-observability/tracing.NewTelemetry(cfg)` — tracer + meter + propagator setup
- `lib-observability/metrics` — `MetricsFactory` with pre-registered metric builders and standard labels

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
logger, _ := zap.NewProduction()
exp, _ := otlptracegrpc.New(ctx, otlptracegrpc.WithEndpoint("localhost:4317"))
tp := sdktrace.NewTracerProvider(sdktrace.WithBatcher(exp))
otel.SetTracerProvider(tp)
tracer := otel.Tracer("my-service")

// lib-observability (AFTER):
import (
    "github.com/LerianStudio/lib-observability/zap"
    "github.com/LerianStudio/lib-observability/tracing"
)

logger := zap.New(zap.Config{ServiceName: "my-service", Env: cfg.Env})
tl, err := tracing.NewTelemetry(tracing.Config{
    ServiceName: "my-service",
    OTLPEndpoint: cfg.OTLPEndpoint,
})
if err != nil {
    return err
}
tracer := tl.Tracer()
metrics := tl.MetricsFactory()
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for observability DIY. Search for `zap.NewProduction()`,
> `zap.NewDevelopment()`, `otel.Tracer(`, `otel.Meter(`, direct OTLP exporter setup, and
> ad-hoc metric creation without a factory. MUST flag hardcoded exporter endpoints. MUST
> also flag any import of `github.com/LerianStudio/lib-commons/v5/commons/{log,zap,opentelemetry,opentelemetry/metrics}` — these are deprecated shims; the canonical home is `github.com/LerianStudio/lib-observability/{log,zap,tracing,metrics}`. For each finding record file:line, the instrumentation component (logger, tracer, meter, exporter), and whether the issue is raw DIY or a deprecated shim import. Severity HIGH — inconsistent instrumentation cripples observability in production.

> **Scope note:** This is the breadth-first single-angle sweep. For a dedicated deep audit of the observability stack, dispatch `ring:using-lib-observability` (top-level) or `ring:using-tracing` (TracerProvider lifecycle specifically). Those produce richer findings than this single-angle pass.

---

#### Angle 15: Panic handling DIY *(canonical home: lib-observability/runtime)*

**Severity:** CRITICAL

**Scope note:** The `runtime` panic-recovery package moved to `lib-observability/runtime` v1.0.0. This angle still runs in the lib-commons sweep, but its detection logic now flags **both** raw DIY **and** continued use of the deprecated `commons/runtime` shim. The replacement target is `lib-observability/runtime`. For a 6-angle deep audit, dispatch `ring:using-runtime` instead of relying on this single-angle pass.

**DIY Patterns to Detect:**
- Raw `defer func() { if r := recover(); r != nil { ... } }()` without emitting a metric,
  a log, or a trace span
- Goroutines launched with `go func()` or `go someFunction()` without any panic recovery
  (silent crashes — goroutine dies, process keeps running, work is lost)
- Goroutine launches inside hot paths (HTTP handlers, message consumers) without
  `SafeGo` equivalent
- **Deprecated shim imports**: `github.com/LerianStudio/lib-commons/v5/commons/runtime` — still compiles but the canonical path is `github.com/LerianStudio/lib-observability/runtime`

**Replacement (lib-observability/runtime):**
- `runtime.SafeGo(fn)` — wraps goroutine with recovery + observability
- `runtime.SafeGoWithContextAndComponent(ctx, component, fn)` — attaches contextual metadata to panic reports
- `runtime.RecoverWithPolicyAndContext(ctx, policy)` — deferred recovery inside existing functions with policy-driven response

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
go func() {
    for msg := range consumer.Messages() {
        process(msg) // panic here silently kills this goroutine
    }
}()

// lib-observability (AFTER):
import "github.com/LerianStudio/lib-observability/runtime"

runtime.SafeGoWithContextAndComponent(ctx, "msg-consumer", func(ctx context.Context) {
    for msg := range consumer.Messages() {
        process(ctx, msg) // panic → recovered, logged, metric emitted, traced
    }
})
```

★ Insight ─────────────────────────────────────
This is the highest-leverage angle in the sweep. Naked `go func()` is the single most
common cause of silent production failures in Go services — a goroutine panics, dies, the
work it was responsible for stops happening, and nothing surfaces in metrics or logs.
Services appear healthy while silently failing. `SafeGo` is not an optimization; it's a
reliability baseline.
─────────────────────────────────────────────────

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for panic-handling DIY. MUST find every `go func()` and
> `go someFunction(...)` in the codebase that isn't wrapped by a `SafeGo` equivalent.
> MUST find every `defer recover()` that lacks observability emission (metric, log, span).
> MUST also flag any import of `github.com/LerianStudio/lib-commons/v5/commons/runtime` —
> that path is a deprecated shim; the canonical home is `github.com/LerianStudio/lib-observability/runtime`.
> For each finding record file:line, whether the goroutine is long-lived (consumer loop, worker) or short-lived (request fan-out), and whether the issue is raw DIY or a deprecated shim import. Severity CRITICAL — silent goroutine crashes are the highest-signal reliability defect this sweep catches.

> **Scope note:** This is the breadth-first single-angle sweep. For a dedicated 6-angle deep audit of the runtime package (naked goroutines, unobservable recover, missing InitPanicMetrics, production mode, framework integration, policy mismatch), dispatch `ring:using-runtime` in Sweep Mode.

---

#### Angle 16: Assertions DIY *(canonical home: lib-observability/assert)*

**Severity:** HIGH

**Scope note:** The `assert` package moved to `lib-observability/assert` v1.0.0. This angle still runs in the lib-commons sweep, but its detection logic now flags **both** raw DIY **and** continued use of the deprecated `commons/assert` shim. The replacement target is `lib-observability/assert`. For a 6-angle deep audit, dispatch `ring:using-assert` instead of relying on this single-angle pass.

**DIY Patterns to Detect:**
- Inline `if x == nil { return errors.New("nil x") }` defensive checks without metric
  emission
- `panic()` or `log.Fatal()` on invariant violations (zero-panic policy violation —
  forbidden in Lerian code)
- Invalid-state propagation (function returns silently when invariant is broken, caller
  proceeds with corrupt state)
- Hand-rolled domain predicates (`func isPositiveDecimal(d decimal.Decimal) bool`)
- **Deprecated shim imports**: `github.com/LerianStudio/lib-commons/v5/commons/assert` — still compiles but the canonical path is `github.com/LerianStudio/lib-observability/assert`

**Replacement (lib-observability/assert):**
- `assert.New(logger, metrics)` — assertion handler with observability
- Domain predicates: `PositiveDecimal`, `NonNegativeDecimal`, `DebitsEqualCredits`,
  `ValidTransactionStatus`, `NotEmpty`, etc.

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
if amount.IsNegative() {
    panic("amount must be positive") // forbidden — zero-panic policy
}
if debits != credits {
    return errors.New("unbalanced") // no metric, no trace, silent in dashboards
}

// lib-observability (AFTER):
import "github.com/LerianStudio/lib-observability/assert"

a := assert.New(logger, metrics)
if err := a.PositiveDecimal(ctx, "amount", amount); err != nil {
    return err
}
if err := a.DebitsEqualCredits(ctx, debits, credits); err != nil {
    return err
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for assertion DIY. MUST find every `panic(`, `log.Fatal(`,
> `log.Panic(`, and `.Must*(` helper call in non-test code (zero-panic policy violation —
> only `regexp.MustCompile` with compile-time constants is allowed). MUST find inline
> invariant checks that return errors without metric emission. MUST also flag any import
> of `github.com/LerianStudio/lib-commons/v5/commons/assert` — that path is a deprecated
> shim; the canonical home is `github.com/LerianStudio/lib-observability/assert`.
> For each finding record file:line, the invariant being checked, and whether the issue
> is raw DIY or a deprecated shim import. Severity HIGH — panics crash services, silent
> invariant violations corrupt state.

> **Scope note:** This is the breadth-first single-angle sweep. For a dedicated 6-angle deep audit of the assert package (panic in non-test code, defensive checks without metrics, hand-rolled predicates, missing InitAssertionMetrics, test-only invariants, AssertionError unwrapping), dispatch `ring:using-assert` in Sweep Mode.

---

#### Angle 17: Resilience DIY

**Severity:** MEDIUM

**DIY Patterns to Detect:**
- Custom retry loops using `time.Sleep(time.Duration(attempt) * time.Second)` (linear
  backoff, no jitter)
- Inline exponential backoff math (`time.Sleep(time.Duration(math.Pow(2, float64(i))) * time.Second)`)
- Hand-rolled circuit breakers (state machines tracking success/failure ratios)
- `sync.WaitGroup` + error channel patterns for parallel fan-out without cancellation on
  first error

**lib-commons Replacement:**
- `commons/backoff.ExponentialWithJitter(cfg)` — vetted backoff with jitter
- `commons/circuitbreaker.Manager` — named breakers with shared config
- `commons/errgroup.New(ctx)` — errgroup with telemetry and cancellation

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
for i := 0; i < 5; i++ {
    err := call()
    if err == nil {
        break
    }
    time.Sleep(time.Duration(1<<i) * time.Second) // no jitter — thundering herd
}

// lib-commons (AFTER):
b := backoff.ExponentialWithJitter(backoff.Config{MaxAttempts: 5, BaseDelay: time.Second})
err := b.Retry(ctx, call)
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for resilience DIY. Search for retry loops using `time.Sleep` with
> fixed or exponential durations, inline `math.Pow(2, ...)` backoff math, and hand-rolled
> circuit breaker state machines. MUST flag retries without jitter (thundering herd risk
> when multiple replicas retry in lockstep). For each finding record file:line and the
> backoff strategy in use. Severity MEDIUM — works until it doesn't, and when it doesn't
> it tends to take the downstream with it.

---

#### Angle 18: Multi-tenancy DIY

**Severity:** CRITICAL (security)

**DIY Patterns to Detect:**
- Manual `tenantId` extraction from request context in handlers (instead of middleware)
- Per-tenant DB pools managed via `map[string]*sql.DB` + mutex
- Ad-hoc cache key namespacing (`fmt.Sprintf("%s:user:%s", tenantID, userID)`) without
  a central key-scoping mechanism
- Tenant lookup via direct DB query on every request (instead of event-driven cache)
- RabbitMQ consumers that don't filter by tenant or don't route to per-tenant exchanges
- MongoDB collection access without per-tenant database routing

**lib-commons Replacement:**
- `commons/tenant-manager/client` — tenant metadata client
- `commons/tenant-manager/postgres` — per-tenant PostgreSQL routing
- `commons/tenant-manager/mongo` — per-tenant MongoDB routing
- `commons/tenant-manager/rabbitmq` — per-tenant queue routing
- `commons/tenant-manager/middleware` — HTTP middleware extracting `tenantId` from JWT
- `commons/tenant-manager/consumer` — tenant-aware consumer wrapper
- `commons/tenant-manager/event-listener` — event-driven tenant discovery via Redis
  Pub/Sub
- `commons/tenant-manager/cache` — tenant metadata cache with invalidation
- `commons/tenant-manager/log` — tenant-scoped log wrapper

**Migration Complexity:** complex

**Example Transformation:**

```go
// DIY (BEFORE):
func handler(c *fiber.Ctx) error {
    tenantID := c.Get("X-Tenant-ID") // trusting client header — IDOR risk
    db := pools[tenantID]             // map access, no lock, panics on miss
    rows, _ := db.Query("SELECT ...") // no tenant scoping inside query either
    return c.JSON(rows)
}

// lib-commons (AFTER):
app.Use(tenantmw.WithPG(tenantManager)) // extracts tenantId from JWT, attaches scoped DB
func handler(c *fiber.Ctx) error {
    db := tenantmw.DB(c) // tenant-scoped pool, safe
    rows, _ := db.Query("SELECT ...")
    return http.Respond(c, rows)
}
```

★ Insight ─────────────────────────────────────
Multi-tenancy DIY is the angle where the cost of being wrong is unbounded — cross-tenant
data leaks are regulatory, legal, and reputational all at once. Unlike most other angles
where "DIY works, lib-commons is nicer", here DIY is frequently outright unsafe (trusting
client-supplied tenant headers, mutex-less tenant pool maps, ad-hoc key namespacing).
Treat any finding here as a stop-the-presses concern.
─────────────────────────────────────────────────

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for multi-tenancy DIY. MUST search for any `tenantId` /
> `tenant_id` / `X-Tenant-ID` extraction in handler code (middleware is the only correct
> location). MUST flag tenant identity sourced from client headers (only JWT claims are
> trustworthy). MUST flag per-tenant DB pool maps (`map[string]*sql.DB`) without central
> tenant-manager wrapping. MUST flag cache keys built via `fmt.Sprintf` with tenantID
> (should be central key-scoping). MUST flag RabbitMQ consumers that don't use
> `commons/tenant-manager/consumer`. For each finding record file:line, the isolation
> mechanism (or lack thereof), and the data plane affected (DB, cache, queue). Severity
> CRITICAL — security.

---

#### Angle 19: Webhook delivery DIY

**Severity:** CRITICAL (security)

**DIY Patterns to Detect:**
- `http.Post(` or `http.Client.Do(` to URLs sourced from user/tenant input without SSRF
  validation
- Missing DNS rebinding defense (lookup once, connect, rely on lookup — attacker can
  respond with public IP on lookup, private IP on connect)
- No HMAC signing on outbound webhook body (receivers can't verify origin)
- Credentials embedded in webhook URLs (`https://user:pass@host/path`) that leak into
  logs
- No retry with exponential backoff on 5xx / transient failures

**lib-commons Replacement:**
- `commons/webhook.Deliverer` — two-layer SSRF defense (pre-connect URL validation + dial
  hook that rechecks resolved IP), HMAC-SHA256 v0/v1 signing, retry with exponential
  backoff, credential scrubbing in logs and errors

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
req, _ := http.NewRequestWithContext(ctx, "POST", tenant.WebhookURL, bytes.NewReader(body))
req.Header.Set("Content-Type", "application/json")
_, err := http.DefaultClient.Do(req) // no SSRF check, no signature, no retry

// lib-commons (AFTER):
deliverer := webhook.NewDeliverer(webhook.Config{
    HMACSecret: tenant.WebhookSecret,
    SSRF:       webhook.DefaultSSRFPolicy(), // blocks 127.0.0.0/8, 10/8, 172.16/12, 169.254/16
})
if err := deliverer.Deliver(ctx, tenant.WebhookURL, body); err != nil {
    return err
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for webhook delivery DIY. MUST search for `http.Post(`,
> `http.Client.Do(`, and any request construction where the URL is sourced from
> user/tenant input (tenant config, webhook subscription, user preference). MUST flag any
> such call that doesn't route through `commons/webhook.Deliverer`. MUST flag missing
> HMAC signing on outbound webhooks. MUST flag credentials in URL (`user:pass@host`
> format). For each finding record file:line, the URL source (which table/field), and the
> SSRF protections (or lack thereof). Severity CRITICAL — webhook delivery is the single
> easiest SSRF vector in a service.

---

#### Angle 20: DLQ DIY

**Severity:** MEDIUM

**DIY Patterns to Detect:**
- Custom "failed messages" tables in PostgreSQL/MongoDB for retry tracking
- Manual retry state machines (status columns like `pending`, `failed`, `abandoned` with
  worker polling)
- DLQ keys not scoped by tenant (cross-tenant retry collision)
- Missing or absent exponential backoff between retries
- Retry floor below 5s (tight-loop retries hammer downstream)

**lib-commons Replacement:**
- `commons/dlq.Handler` — push failed work to DLQ with tenant scoping
- `commons/dlq.Consumer` — poll DLQ with exponential backoff, 5s floor, max-attempts
  bound

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
_, _ = db.Exec(`INSERT INTO failed_messages (queue, payload, attempts, next_retry)
                VALUES ($1, $2, 0, NOW() + interval '1 second')`, queue, payload)
// separate worker polls this table — but no tenant scoping, no backoff floor

// lib-commons (AFTER):
dlqHandler := dlq.New(redisClient, dlq.Config{
    MaxAttempts: 10,
    MinBackoff:  5 * time.Second,
    TenantFn:    tenantFromCtx,
})
if err := dlqHandler.Push(ctx, "events", payload, reason); err != nil {
    return err
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for DLQ DIY. Search for tables/collections named `failed_*`,
> `dlq_*`, `retry_*`, or similar, and worker loops that poll them. MUST flag DLQ keys or
> table rows that aren't tenant-scoped. MUST flag retry loops with backoff below 5
> seconds (5s floor is a correctness requirement — faster retries hammer downstreams).
> For each finding record file:line, the substrate (DB, Redis, queue), and the backoff
> policy. Severity MEDIUM — DIY DLQs work until load spikes, then they amplify outages.

---

#### Angle 21: TLS certificate DIY

**Severity:** HIGH

**DIY Patterns to Detect:**
- `tls.LoadX509KeyPair(` called once at startup with no hot-reload path
- `cert, _ := tls.LoadX509KeyPair(...)` assignment to a package variable
- `x509.ParseCertificate(` without `x509.ParsePKCS8PrivateKey` / `ParsePKCS1PrivateKey` /
  EC-specific parsers to cover all key formats
- No expiry monitoring (no metric emission for `NotAfter - time.Now()`)
- Service requires restart to pick up rotated certificates

**lib-commons Replacement:**
- `commons/certificate.Manager` — zero-downtime `Rotate(newCertPEM, newKeyPEM)`,
  PKCS#8/PKCS#1/EC key format support, `GetCertificateFunc` wired into `tls.Config`,
  `DaysUntilExpiry()` for metric emission

**Migration Complexity:** moderate

**Example Transformation:**

```go
// DIY (BEFORE):
cert, err := tls.LoadX509KeyPair(cfg.CertFile, cfg.KeyFile)
if err != nil {
    return err
}
tlsConfig := &tls.Config{Certificates: []tls.Certificate{cert}}
// rotation requires restart

// lib-commons (AFTER):
cm, err := certificate.NewManager(cfg.CertFile, cfg.KeyFile)
if err != nil {
    return err
}
tlsConfig := &tls.Config{GetCertificate: cm.GetCertificateFunc()}
// rotate hot: cm.Rotate(newCertPEM, newKeyPEM) — no restart
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for TLS certificate DIY. Search for `tls.LoadX509KeyPair(`,
> `x509.ParseCertificate(`, raw `tls.Config{Certificates: ...}` assignment, and any
> comment or code implying "restart to rotate certs". MUST flag missing expiry metric
> emission. For each finding record file:line and the rotation strategy (none, restart,
> hot). Severity HIGH — expired certs cause hard outages that scale with fleet size.

---

#### Angle 22: Utility DIY

**Severity:** LOW

**DIY Patterns to Detect:**
- `uuid.New()` / `uuid.NewV4()` — v4 UUIDs are random, not time-ordered, cause index
  locality problems in PostgreSQL/MongoDB
- `uuid.NewUUID()` — v1 UUIDs leak MAC address
- Custom env var parsing (`os.Getenv` + `strconv.Atoi` + default fallback scattered through
  config struct initialization)
- Hand-rolled `ToSnakeCase` / `ToCamelCase` / `RemoveAccents` / `Slugify` helpers

**lib-commons Replacement:**
- `commons.GenerateUUIDv7()` — time-ordered UUIDs (good index locality)
- `commons.GetenvOrDefault(key, default)` — typed env reader
- `commons.SetConfigFromEnvVars(&cfg)` — reflection-based struct-tag-driven env loader
- `commons.ToSnakeCase(s)` / `commons.ToCamelCase(s)` / `commons.RemoveAccents(s)`

**Migration Complexity:** trivial

**Example Transformation:**

```go
// DIY (BEFORE):
id := uuid.New().String() // v4 — random, bad index locality
port, _ := strconv.Atoi(os.Getenv("PORT"))
if port == 0 {
    port = 8080
}
snake := strings.ToLower(regexp.MustCompile(`([a-z])([A-Z])`).ReplaceAllString(s, "${1}_${2}"))

// lib-commons (AFTER):
id := commons.GenerateUUIDv7()
port := commons.GetenvOrDefault("PORT", 8080)
snake := commons.ToSnakeCase(s)
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for utility DIY. Search for `uuid.New()`, `uuid.NewV4()`,
> `uuid.NewUUID()`, scattered `os.Getenv` + `strconv.Atoi` + default patterns, and
> hand-rolled case-conversion or accent-removal helpers. MUST flag UUID v4 usage on
> columns used as primary keys or indexed fields (v7 has better index locality). For
> each finding record file:line and the utility category (UUID, env, string). Severity
> LOW — ergonomic and consistency, except UUID-v4-as-pk which has measurable DB impact.

---

## Report Template

MANDATORY: The synthesizer MUST produce `/tmp/libcommons-sweep-report.md` following this
exact structure. MUST NOT add sections. MUST NOT reorder sections. MUST populate every
section even if empty (use "None detected" placeholders).

```markdown
# lib-commons Sweep Report

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

**Assessment:** <one-paragraph narrative — "project is 2 patch releases behind,
straightforward `go get -u` upgrade" or "project pinned to v4.2.0, v5 migration required
before adopting recommendations below">

---

## Unadopted Features

Features added to lib-commons between the pinned version and latest stable that the
target has not yet adopted:

| Version | Feature                     | Classification  | Relevant Finding Angle |
| ------- | --------------------------- | --------------- | ---------------------- |
| v5.0.0  | commons/webhook             | new-package     | Angle 19               |
| v5.0.0  | commons/dlq                 | new-package     | Angle 20               |
| v5.0.1  | commons/certificate.Rotate  | new-api         | Angle 21               |

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

| Angle                       | Severity  | File                        | Line | DIY Pattern                                | Replacement                      | Complexity |
| --------------------------- | --------- | --------------------------- | ---- | ------------------------------------------ | -------------------------------- | ---------- |
| 12 JWT DIY                  | CRITICAL  | internal/auth/parser.go     | 47   | jwt.Parse w/o alg allowlist                | commons/jwt.ParseAndValidate     | moderate   |
| 18 Multi-tenancy DIY        | CRITICAL  | internal/http/handler.go    | 89   | tenantId from X-Tenant-ID header           | tenant-manager middleware        | complex    |
| 15 Panic handling DIY       | CRITICAL  | internal/worker/consumer.go | 34   | go func() w/o SafeGo                       | runtime.SafeGoWithContext...     | moderate   |
| ...                         | ...       | ...                         | ...  | ...                                        | ...                              | ...        |

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

`ring:dev-cycle` consuming `/tmp/libcommons-sweep-tasks.json` — N tasks generated,
grouped by severity, CRITICAL first.
```

---

## Task Generation for ring:dev-cycle

MANDATORY: The synthesizer MUST also emit `/tmp/libcommons-sweep-tasks.json` — a JSON
array of tasks shaped for `ring:dev-cycle` consumption. The format matches what
`ring:dev-refactor` produces.

**Task grouping rules:**

1. MUST group findings by severity — CRITICAL first, then HIGH, MEDIUM, LOW.
2. Within a severity tier, MUST group findings from the same file or tightly-related
   files into a single task (avoid one-task-per-line fragmentation).
3. CRITICAL findings MUST be standalone tasks (no batching across concerns) — each gets
   its own dev-cycle pass.
4. MUST include dependency references when one task's correctness depends on another
   (e.g., "Switch to tenant-manager middleware" depends on "Upgrade lib-commons to v5").

**Task schema:**

```json
{
  "id": "libcommons-sweep-001",
  "title": "Replace DIY JWT parsing with commons/jwt",
  "severity": "CRITICAL",
  "description": "Target service uses raw github.com/golang-jwt/jwt without an algorithm allowlist in the keyfunc, creating an algorithm confusion vulnerability (accepts 'none' algorithm and bypasses signature verification). Replace with commons/jwt.ParseAndValidate which enforces an HS256/384/512 allowlist and uses constant-time HMAC comparison. This eliminates a CVE-class auth bypass.",
  "files_affected": [
    "internal/auth/parser.go:47",
    "internal/auth/middleware.go:22",
    "internal/auth/refresh.go:61"
  ],
  "acceptance_criteria": [
    "All jwt.Parse / jwt.ParseWithClaims calls replaced with commons/jwt.ParseAndValidate",
    "No direct imports of github.com/golang-jwt/jwt in application code",
    "Algorithm allowlist explicitly passed as HS256 (or HS384/512 if service uses longer keys)",
    "Existing auth integration tests pass unchanged",
    "New test: malformed token with alg=none is rejected"
  ],
  "estimated_complexity": "moderate",
  "depends_on": [],
  "angle": 12,
  "replacement_api": "commons/jwt.ParseAndValidate"
}
```

**Task emission verbatim example:**

```json
[
  {
    "id": "libcommons-sweep-001",
    "title": "Upgrade lib-commons from v4.2.0 to latest v5.x",
    "severity": "HIGH",
    "description": "Target service pins github.com/LerianStudio/lib-commons/v4 at v4.2.0. Resolve latest v5.x tag via `gh api repos/LerianStudio/lib-commons/releases/latest --jq .tag_name`. Module path changes to v5 require go.mod update and import path rewrites. v5 introduces commons/webhook, commons/dlq, commons/certificate.Rotate, and tenant-manager subsystem — all unavailable in v4. This task MUST complete before any other sweep task lands (all recommendations below assume v5 APIs).",
    "files_affected": ["go.mod", "go.sum", "<all Go files importing lib-commons>"],
    "acceptance_criteria": [
      "go.mod declares github.com/LerianStudio/lib-commons/v5 at latest v5.x tag",
      "All imports updated from /v4 to /v5",
      "go build ./... passes",
      "go test ./... passes",
      "No reference to removed v4 APIs remains"
    ],
    "estimated_complexity": "complex",
    "depends_on": [],
    "angle": "version",
    "replacement_api": "lib-commons/v5"
  },
  {
    "id": "libcommons-sweep-002",
    "title": "Replace DIY JWT parsing with commons/jwt",
    "severity": "CRITICAL",
    "description": "<as above>",
    "files_affected": ["internal/auth/parser.go:47", "..."],
    "acceptance_criteria": ["..."],
    "estimated_complexity": "moderate",
    "depends_on": ["libcommons-sweep-001"],
    "angle": 12,
    "replacement_api": "commons/jwt.ParseAndValidate"
  }
]
```

**Handoff message template** (orchestrator surfaces to user after Phase 4):

```
Sweep complete. Findings: <N> across <M> angles.
- CRITICAL: <N>   HIGH: <N>   MEDIUM: <N>   LOW: <N>

Report: /tmp/libcommons-sweep-report.md
Tasks:  /tmp/libcommons-sweep-tasks.json (<N> tasks)

Next: Invoke ring:dev-cycle with the task file to execute fixes. CRITICAL tasks
(especially multi-tenancy, JWT, webhook, crypto, panic handling) MUST be addressed
before the HIGH/MEDIUM/LOW tier.
```

---
