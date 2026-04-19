# Go Standards - Architecture

> **Module:** architecture.md | **Sections:** §23-30 | **Parent:** [index.md](index.md)

This module covers architecture patterns, directory structure, concurrency, goroutine recovery, and query optimization.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Architecture Patterns](#architecture-patterns) | Hexagonal architecture and interface-based abstractions |
| 2 | [Directory Structure](#directory-structure) | Lerian pattern directory layout |
| 3 | [Concurrency Patterns](#concurrency-patterns) | Goroutines with context and channel patterns |
| 4 | [Goroutine Recovery Patterns](#goroutine-recovery-patterns-mandatory) | Panic recovery for background goroutines |
| 5 | [Goroutine Leak Detection](#goroutine-leak-detection-mandatory) | goleak framework for detecting goroutine leaks |
| 6 | [N+1 Query Detection](#n1-query-detection-mandatory) | Avoiding N+1 queries in collection processing |
| 7 | [Performance Patterns](#performance-patterns-mandatory) | SELECT * avoidance, sync.Pool, memory optimization |
| 8 | [CQRS Pattern (CONDITIONAL)](#cqrs-pattern-conditional) | Command/Query separation, when to apply, Ring pattern integration |

---

## Architecture Patterns

### Hexagonal Architecture (Ports & Adapters)

```text
/internal
  /bootstrap         # Application initialization
    config.go
    fiber.server.go
  /domain            # Business entities (no dependencies)
    user.go
    errors.go
  /services          # Application/Business logic
    /command         # Write operations
    /query           # Read operations
  /adapters          # Implementations (adapters)
    /http/in         # HTTP handlers + routes
    /grpc/in         # gRPC handlers
    /postgres        # PostgreSQL repositories
    /mongodb         # MongoDB repositories
    /redis           # Redis repositories
```

### Interface-Based Abstractions

```go
// Define interface in the package that USES it (not implements)
// /internal/services/command/usecase.go

type UserRepository interface {
    FindByID(ctx context.Context, id uuid.UUID) (*domain.User, error)
    Save(ctx context.Context, user *domain.User) error
}

type UseCase struct {
    UserRepo UserRepository  // Depend on interface
}
```

---

## Directory Structure

The directory structure follows the **Lerian pattern** - a simplified hexagonal architecture without explicit DDD folders.

```text
/cmd
  /app                   # Main application entry
    main.go
/internal
  /bootstrap             # Initialization (config, servers)
    config.go
    fiber.server.go
    grpc.server.go       # (if service uses gRPC)
    rabbitmq.server.go   # (if service uses RabbitMQ)
    service.go
  /services              # Business logic
    /command             # Write operations (use cases)
    /query               # Read operations (use cases)
  /adapters              # Infrastructure implementations
    /http/in             # HTTP handlers + routes
    /grpc/in             # gRPC handlers
    /grpc/out            # gRPC clients
    /postgres            # PostgreSQL repositories
    /mongodb             # MongoDB repositories
    /redis               # Redis repositories
    /rabbitmq            # RabbitMQ producers/consumers
/pkg
  /constant              # Constants and error codes
  /mmodel                # Shared models
  /net/http              # HTTP utilities
/api                     # OpenAPI/Swagger specs
/migrations              # Database migrations
```

**Key differences from traditional DDD:**
- **No `/internal/domain` folder** - Business entities live in `/pkg/mmodel` or within service files
- **Services are the core** - `/internal/services` contains all business logic (command/query pattern)
- **Adapters are flat** - Database repositories are organized by technology, not by domain

---

## Concurrency Patterns

### Goroutines with Context

```go
func processItems(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)

    for _, item := range items {
        item := item // capture variable
        g.Go(func() error {
            select {
            case <-ctx.Done():
                return ctx.Err()
            default:
                return processItem(ctx, item)
            }
        })
    }

    return g.Wait()
}
```

### Channel Patterns

```go
// Worker pool
func workerPool(ctx context.Context, jobs <-chan Job, results chan<- Result) {
    for {
        select {
        case <-ctx.Done():
            return
        case job, ok := <-jobs:
            if !ok {
                return
            }
            results <- process(job)
        }
    }
}
```

### Concurrent Map Access (MANDATORY)

**⛔ HARD GATE:** Go maps are NOT safe for concurrent access. Concurrent read/write causes runtime panic.

```go
// ❌ FORBIDDEN: Concurrent map access without synchronization
var cache = make(map[string]Value)

func Get(key string) Value {
    return cache[key] // PANIC if concurrent write
}

func Set(key, value string) {
    cache[key] = value // PANIC if concurrent read
}
```

**Option 1: sync.RWMutex (RECOMMENDED for read-heavy workloads)**

```go
// ✅ CORRECT: Protected map with RWMutex
type SafeCache struct {
    mu    sync.RWMutex
    cache map[string]Value
}

func NewSafeCache() *SafeCache {
    return &SafeCache{
        cache: make(map[string]Value),
    }
}

func (c *SafeCache) Get(key string) (Value, bool) {
    c.mu.RLock() // Read lock allows concurrent reads
    defer c.mu.RUnlock()
    val, ok := c.cache[key]
    return val, ok
}

func (c *SafeCache) Set(key string, value Value) {
    c.mu.Lock() // Write lock is exclusive
    defer c.mu.Unlock()
    c.cache[key] = value
}
```

**Option 2: sync.Map (for specialized use cases)**

```go
// ✅ CORRECT: sync.Map for specific patterns
// Use when: (1) keys are mostly written once, read many times
//           (2) multiple goroutines read/write disjoint key sets
var cache sync.Map

func Get(key string) (Value, bool) {
    val, ok := cache.Load(key)
    if !ok {
        return Value{}, false
    }
    return val.(Value), true
}

func Set(key string, value Value) {
    cache.Store(key, value)
}
```

**When to Use Which:**

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| `sync.RWMutex` | Read-heavy workloads, need iteration, clear map | Simple store/load only |
| `sync.Map` | Write-once/read-many, disjoint goroutine keys | Need iteration, complex operations |

### Loop Variable Capture (Go 1.22+ Behavior)

**Note:** Go 1.22+ changed loop variable semantics. Each iteration creates a new variable.

```go
// Go 1.21 and earlier: REQUIRED explicit capture
for _, item := range items {
    item := item // REQUIRED: capture variable for goroutine
    go func() {
        process(item) // Without capture, all goroutines see last item
    }()
}

// Go 1.22+: Automatic per-iteration variables (capture still works)
for _, item := range items {
    go func() {
        process(item) // Safe: each iteration has its own `item`
    }()
}
```

**Best Practice:** Continue using explicit capture (`item := item`) for clarity and backward compatibility, even in Go 1.22+.

### Detection Commands (Concurrency)

```bash
# Find maps that may need protection
grep -rn "= make(map\|map\[" --include="*.go" | grep -v "_test.go" | head -20

# Find goroutines without recovery wrapper
grep -rn "go func()" --include="*.go" | grep -v "recovery.Go\|test"

# Find sync.Map usage (review if appropriate)
grep -rn "sync.Map" --include="*.go"

# Find potential race conditions (requires race detector)
go test -race ./...
```

---

## Goroutine Recovery Patterns (MANDATORY)

Goroutines without recovery kill the entire process when they panic. Recovery middleware is needed for all background goroutines.

**⛔ HARD GATE:** All goroutines started with `go` keyword MUST have panic recovery. Unrecovered panics in goroutines crash the entire process.

### Why Recovery Is MANDATORY

| Scenario | Without Recovery | With Recovery |
|----------|------------------|---------------|
| Panic in goroutine | Process crashes | Error logged, goroutine terminates gracefully |
| nil pointer | Pod restart loop | Error captured, other goroutines unaffected |
| Divide by zero | Service down | Incident logged, service continues |

### Recovery Wrapper Pattern (REQUIRED)

```go
// pkg/recovery/recovery.go
package recovery

import (
    "context"
    "fmt"
    "runtime/debug"

    libCommons "github.com/LerianStudio/lib-commons/v5/commons"
)

// Go wraps a goroutine with panic recovery
// MUST use this instead of bare `go func()` for all background goroutines
func Go(ctx context.Context, fn func()) {
    logger, _, _, _ := libCommons.NewTrackingFromContext(ctx)

    go func() {
        defer func() {
            if r := recover(); r != nil {
                stack := string(debug.Stack())
                logger.Errorf("Goroutine panic recovered: %v\nStack: %s", r, stack)
                // Optional: Send to error tracking (Sentry, etc.)
            }
        }()
        fn()
    }()
}

// GoWithError wraps a goroutine that returns an error
func GoWithError(ctx context.Context, fn func() error, errChan chan<- error) {
    logger, _, _, _ := libCommons.NewTrackingFromContext(ctx)

    go func() {
        defer func() {
            if r := recover(); r != nil {
                stack := string(debug.Stack())
                logger.Errorf("Goroutine panic recovered: %v\nStack: %s", r, stack)
                errChan <- fmt.Errorf("goroutine panicked: %v", r)
            }
        }()

        if err := fn(); err != nil {
            errChan <- err
        }
    }()
}
```

### Usage Pattern

```go
// ✅ CORRECT: Using recovery wrapper
recovery.Go(ctx, func() {
    processBackgroundTask(ctx, item)
})

// ✅ CORRECT: With error handling
errChan := make(chan error, 1)
recovery.GoWithError(ctx, func() error {
    return processItem(ctx, item)
}, errChan)

// ✅ CORRECT: Inline recovery for simple cases
go func() {
    defer func() {
        if r := recover(); r != nil {
            logger.Errorf("Panic in goroutine: %v", r)
        }
    }()
    doWork()
}()
```

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Bare goroutine without recovery
go processBackgroundTask(ctx, item)  // WRONG: no recovery

// ❌ FORBIDDEN: Fire-and-forget goroutine
go func() {
    result := heavyComputation()  // WRONG: panic crashes process
    sendResult(result)
}()

// ❌ FORBIDDEN: Assuming "it won't panic"
go handleWebhook(payload)  // WRONG: any nil pointer kills the process
```

### Detection Commands

```bash
# Find bare goroutines without recovery
grep -rn "^\s*go func\|^\s*go [a-zA-Z]" internal/ pkg/ --include="*.go" | grep -v "_test.go"

# Review each match - ensure recovery wrapper or inline defer/recover exists
# Expected: All goroutines use recovery.Go() or have explicit defer recover()
```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Goroutines won't panic" | All code can panic. nil pointer, slice bounds, map access. | **Add recovery wrapper** |
| "Main goroutine will catch it" | Panics in goroutines don't propagate to main. | **Add recovery per goroutine** |
| "Process will restart" | Restart = downtime + lost in-flight work. | **Recover and log instead** |
| "It's just a background task" | Background task crash = process crash. | **Add recovery wrapper** |
| "Recovery adds overhead" | Overhead is negligible vs process crash cost. | **Add recovery wrapper** |

---

## Goroutine Leak Detection (MANDATORY)

Goroutine leaks cause memory exhaustion, increased latency, and eventual process crashes. When implementing goroutines, you MUST create leak tests using the goleak framework.

**⛔ HARD GATE:** When implementing goroutines, MUST create goleak leak tests using the goleak framework. This is NON-NEGOTIABLE.

### Why Goroutine Leak Detection Is MANDATORY

| Scenario | Without Detection | With goleak |
|----------|-------------------|-------------|
| Leaked goroutine | Silent memory growth | Test fails immediately |
| Channel not closed | Goroutine hangs forever | Detected in test |
| Missing context cancellation | Resources not released | Caught before deploy |
| Worker pool not shutdown | Goroutines accumulate | Fails quality gate |

### goleak Installation

```bash
go get -u go.uber.org/goleak
```

### TestMain Pattern (RECOMMENDED for packages with goroutines)

```go
// pkg/worker/worker_test.go
package worker

import (
    "testing"

    "go.uber.org/goleak"
)

// TestMain ensures no goroutine leaks across all tests in this package
func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}
```

**When to use TestMain:**
- Package creates goroutines (workers, consumers, background tasks)
- Package manages channels or connection pools
- Package has async operations

### Per-Test Pattern (For specific tests)

```go
func TestWorker_ProcessMessage(t *testing.T) {
    defer goleak.VerifyNone(t)
    
    worker := NewWorker()
    worker.Start()
    
    // ... test logic ...
    
    worker.Stop() // Must properly shutdown
}
```

### Ignoring Known Goroutines

Some external libraries create background goroutines. Ignore them explicitly:

```go
func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m,
        // OpenTelemetry background exporters
        goleak.IgnoreTopFunction("go.opentelemetry.io/otel/sdk/trace.(*batchSpanProcessor).processQueue"),
        // gRPC keepalive
        goleak.IgnoreTopFunction("google.golang.org/grpc.(*addrConn).resetTransport"),
        // Database connection pool maintenance
        goleak.IgnoreTopFunction("database/sql.(*DB).connectionOpener"),
    )
}
```

### Common Leak Patterns and Fixes

#### Pattern 1: Unbounded Channel Send

```go
// ❌ LEAK: Sender blocked forever if receiver exits
func process(items []Item) {
    results := make(chan Result)
    for _, item := range items {
        go func(i Item) {
            results <- processItem(i) // BLOCKS if no receiver
        }(item)
    }
    // If we return early, goroutines leak
}

// ✅ CORRECT: Use buffered channel or context
func process(ctx context.Context, items []Item) {
    results := make(chan Result, len(items)) // Buffered
    for _, item := range items {
        go func(i Item) {
            select {
            case results <- processItem(i):
            case <-ctx.Done():
                return // Clean exit
            }
        }(item)
    }
}
```

#### Pattern 2: Missing Cleanup

```go
// ❌ LEAK: Worker goroutine never stops
type Service struct {
    done chan struct{}
}

func (s *Service) Start() {
    go func() {
        for {
            // Background work
        }
    }()
}

// ✅ CORRECT: Implement proper shutdown
func (s *Service) Start() {
    s.done = make(chan struct{})
    go func() {
        for {
            select {
            case <-s.done:
                return // Clean exit
            default:
                // Background work
            }
        }
    }()
}

func (s *Service) Stop() {
    close(s.done)
}
```

#### Pattern 3: Context Not Honored

```go
// ❌ LEAK: Ignores context cancellation
func worker(ctx context.Context, jobs <-chan Job) {
    for job := range jobs {
        processJob(job) // Continues even if ctx cancelled
    }
}

// ✅ CORRECT: Check context in loop
func worker(ctx context.Context, jobs <-chan Job) {
    for {
        select {
        case <-ctx.Done():
            return
        case job, ok := <-jobs:
            if !ok {
                return
            }
            processJob(job)
        }
    }
}
```

### Detection Commands (MANDATORY)

```bash
# Find goroutines that may leak (review each)
grep -rn "go func()" --include="*.go" | grep -v "_test.go"

# Find channels without close
grep -rn "make(chan" --include="*.go" | grep -v "_test.go"

# Check for goleak in test files
grep -rn "goleak" --include="*_test.go"

# Run tests with leak detection
go test -v ./... 2>&1 | grep -i "leak"
```

### Quality Gate Requirements

| Check | Detection | PASS Criteria |
|-------|-----------|---------------|
| goleak in TestMain | `grep "goleak.VerifyTestMain"` | Present in packages with goroutines |
| All tests pass with goleak | `go test ./...` | 0 leaked goroutines |
| Proper shutdown | Code review | All workers have Stop/Close |
| Context honored | Code review | All goroutines check ctx.Done() |

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Goroutine will exit eventually" | Eventually = memory leak until then. | **Add proper shutdown** |
| "It's just one goroutine" | One leak × thousands of requests = OOM. | **Add goleak test** |
| "Process restarts clean it" | Restart = downtime. Prevent leaks instead. | **Add goleak test** |
| "Too complex to test" | goleak makes it simple. One line in TestMain. | **Add goleak.VerifyTestMain** |
| "External lib leaks, not my code" | Use goleak.IgnoreTopFunction for known libs. | **Ignore known, catch yours** |
| "Performance overhead" | goleak only runs in tests, not production. | **No production overhead** |

---

## N+1 Query Detection (MANDATORY)

N+1 queries cause database connection exhaustion and latency spikes under load.

**⛔ HARD GATE:** Queries inside loops are FORBIDDEN. MUST use batch loading, eager loading, or JOINs.

### What Is N+1 Problem

```text
N+1 = 1 query to get list + N queries for each item

Example: Get 100 orders with customer names
- BAD: 1 query for orders + 100 queries for customers = 101 queries
- GOOD: 1 query for orders + 1 query for customers (batch) = 2 queries
```

### FORBIDDEN Pattern

```go
// ❌ FORBIDDEN: Query inside loop (N+1)
func (r *OrderRepository) GetOrdersWithCustomers(ctx context.Context) ([]OrderWithCustomer, error) {
    orders, err := r.db.Query(ctx, "SELECT * FROM orders LIMIT 100")
    if err != nil {
        return nil, err
    }

    var results []OrderWithCustomer
    for _, order := range orders {
        // WRONG: This executes 100 times (N+1)
        customer, err := r.db.QueryRow(ctx, "SELECT * FROM customers WHERE id = $1", order.CustomerID)
        if err != nil {
            return nil, err
        }
        results = append(results, OrderWithCustomer{Order: order, Customer: customer})
    }
    return results, nil
}
```

### Correct Patterns (REQUIRED)

#### Option 1: JOIN Query

```go
// ✅ CORRECT: Single query with JOIN
func (r *OrderRepository) GetOrdersWithCustomers(ctx context.Context) ([]OrderWithCustomer, error) {
    query := `
        SELECT o.id, o.total, o.created_at, c.id, c.name, c.email
        FROM orders o
        JOIN customers c ON o.customer_id = c.id
        LIMIT 100
    `
    rows, err := r.db.Query(ctx, query)
    // ... scan results
}
```

#### Option 2: Batch Loading

```go
// ✅ CORRECT: Batch load with IN clause
func (r *OrderRepository) GetOrdersWithCustomers(ctx context.Context) ([]OrderWithCustomer, error) {
    // Step 1: Get orders
    orders, err := r.db.Query(ctx, "SELECT * FROM orders LIMIT 100")
    if err != nil {
        return nil, err
    }

    // Step 2: Collect unique customer IDs
    customerIDs := make([]uuid.UUID, 0, len(orders))
    for _, o := range orders {
        customerIDs = append(customerIDs, o.CustomerID)
    }

    // Step 3: Batch load customers (1 query, not N)
    customers, err := r.db.Query(ctx, "SELECT * FROM customers WHERE id = ANY($1)", customerIDs)
    if err != nil {
        return nil, err
    }

    // Step 4: Build lookup map
    customerMap := make(map[uuid.UUID]Customer)
    for _, c := range customers {
        customerMap[c.ID] = c
    }

    // Step 5: Combine results
    var results []OrderWithCustomer
    for _, o := range orders {
        results = append(results, OrderWithCustomer{
            Order:    o,
            Customer: customerMap[o.CustomerID],
        })
    }
    return results, nil
}
```

### Detection Commands

```bash
# Find potential N+1 patterns (queries inside loops)
grep -rn "for.*range" internal/adapters/postgres --include="*.go" -A 10 | grep -E "Query|Exec|Select"

# Find loop + query combinations
grep -rn "for.*{" internal/adapters --include="*.go" -A 15 | grep -E "\.Query\(|\.Exec\(|\.Get\(|\.Select\("

# Review each match - if query is inside loop: VIOLATION
```

### Query Count Guidelines

| Collection Size | Max Queries | Strategy |
|-----------------|-------------|----------|
| 1-10 items | 2 | Batch or JOIN |
| 10-100 items | 2 | Batch with IN clause |
| 100+ items | 2 | Batch with pagination |
| Any size | Never N+1 | JOIN or batch always |

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Only a few records" | Few now = many later. N+1 scales poorly. | **Use batch/JOIN** |
| "Query is fast" | 1ms * 1000 = 1s. Latency compounds. | **Use batch/JOIN** |
| "Database handles it" | DB connection pool exhausts under load. | **Use batch/JOIN** |
| "ORM optimizes it" | ORMs don't auto-optimize N+1. You must. | **Explicit batch/JOIN** |
| "Caching helps" | Cache miss = N+1. Cold start = N+1. | **Use batch/JOIN** |

---

## Performance Patterns (MANDATORY)

This section covers performance anti-patterns that cause production issues: excessive memory allocation, unbounded queries, and inefficient object reuse.

### SELECT * Avoidance (MANDATORY)

**⛔ HARD GATE:** Using `SELECT *` in production queries is FORBIDDEN. Always specify exact columns needed.

```go
// ❌ FORBIDDEN: SELECT * fetches all columns including BLOBs, unused fields
query := "SELECT * FROM users WHERE id = $1"
rows, _ := db.Query(ctx, query, id)

// ❌ FORBIDDEN: ORM without field selection
db.Find(&users) // Fetches all columns
```

```go
// ✅ CORRECT: Explicit column selection
query := "SELECT id, name, email, created_at FROM users WHERE id = $1"
rows, _ := db.Query(ctx, query, id)

// ✅ CORRECT: ORM with explicit fields
db.Select("id", "name", "email", "created_at").Find(&users)

// ✅ CORRECT: Squirrel query builder
sq.Select("id", "name", "email", "created_at").
    From("users").
    Where(sq.Eq{"id": id})
```

**Why SELECT * Is Harmful:**

| Problem | Impact |
|---------|--------|
| Fetches unused columns | Wasted memory and bandwidth |
| Includes BLOB/TEXT | Large data transfer for small queries |
| Schema changes break code | Adding column changes result set |
| No query optimization | DB can't use covering indexes |

### sync.Pool for Frequent Allocations

**Use sync.Pool when:**
- Creating many short-lived objects of the same type
- Object creation is expensive (buffers, parsers)
- High-throughput scenarios (HTTP handlers, message processing)

```go
// ✅ CORRECT: sync.Pool for buffer reuse
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

func ProcessRequest(data []byte) []byte {
    // Get buffer from pool
    buf := bufferPool.Get().(*bytes.Buffer)
    buf.Reset() // Always reset before use

    // Use buffer
    buf.Write(data)
    result := processData(buf)

    // Return to pool
    bufferPool.Put(buf)

    return result
}
```

**sync.Pool Rules:**

| Rule | Rationale |
|------|-----------|
| Always Reset() before use | Previous data may remain |
| Don't store pointers to pooled objects | Object may be reused |
| Don't assume object identity | Pool may return different object |
| Put() after use, not in defer | Defer adds overhead in hot paths |

### Memory Allocation Patterns

```go
// ❌ FORBIDDEN: Allocation in hot loop
for _, item := range items {
    buf := make([]byte, 1024) // New allocation each iteration
    process(buf, item)
}

// ✅ CORRECT: Reuse allocation
buf := make([]byte, 1024)
for _, item := range items {
    buf = buf[:0] // Reset slice, keep capacity
    process(buf, item)
}

// ✅ CORRECT: Pre-allocate slices when size is known
results := make([]Result, 0, len(items)) // Pre-allocate capacity
for _, item := range items {
    results = append(results, process(item))
}
```

### String Concatenation

```go
// ❌ FORBIDDEN: String concatenation in loop (O(n²))
var result string
for _, s := range strings {
    result += s // Creates new string each iteration
}

// ✅ CORRECT: strings.Builder (O(n))
var builder strings.Builder
builder.Grow(estimatedSize) // Pre-allocate if size known
for _, s := range strings {
    builder.WriteString(s)
}
result := builder.String()
```

### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR with query changes

# Find SELECT * usage
grep -rn "SELECT \*" --include="*.go" | grep -v "_test.go"

# Find ORM queries without Select()
grep -rn "\.Find(&\|\.First(&" --include="*.go" | grep -v "\.Select("

# Find string concatenation in loops
grep -rn "for.*{" --include="*.go" -A 5 | grep "+="

# Find allocations in loops (review each)
grep -rn "for.*{" --include="*.go" -A 5 | grep "make("

# Expected: 0 SELECT * in production code
# If found: Specify explicit columns
```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "SELECT * is more flexible" | Flexibility = wasted resources + schema fragility. | **Specify columns** |
| "Table only has few columns" | Few now = many later. Think ahead. | **Specify columns** |
| "sync.Pool is premature optimization" | For hot paths, it's necessary optimization. | **Profile, then decide** |
| "Allocations are cheap in Go" | Cheap ≠ free. GC pauses affect latency. | **Reuse when possible** |
| "I'll optimize later" | Later = production incident. Design right first. | **Optimize during design** |
| "Builder is verbose" | Verbose > quadratic complexity. | **Use strings.Builder** |

---

## CQRS Pattern (CONDITIONAL)

**CONDITIONAL:** Only applies when the service has separate read and write models, or when read/write ratio exceeds 10:1.

### When to Use CQRS

| Scenario | Use CQRS? | Rationale |
|----------|-----------|-----------|
| Read/write ratio > 10:1 | Yes | Optimize read model independently |
| Different read formats needed (API + reports + dashboards) | Yes | Each consumer gets its own denormalized model |
| Financial systems with audit trail + query views | Yes | Write model captures events, read model serves queries |
| Simple CRUD with 1:1 read/write | No | Overhead without benefit |
| Small service with < 5 endpoints | No | Over-engineering |

### Pattern Structure

```text
/internal
  /services
    /command        # Write operations — validate, persist, return minimal
      create_entity.go
      update_entity.go
    /query          # Read operations — denormalized, return rich
      get_entity.go
      list_entities.go
  /domain           # Rich domain model (used by command side)
    entity.go
  /projection       # Read models (used by query side)
    entity_view.go
```

### Command Side (Write)

Command handlers validate business rules using the Always-Valid Domain Model and persist via repositories.

```go
// internal/services/command/create_account.go

type CreateAccountCommand struct {
    OrgID     uuid.UUID
    Name      string
    Currency  string
}

type CreateAccountHandler struct {
    repo ports.AccountRepository
}

func (h *CreateAccountHandler) Handle(ctx context.Context, cmd CreateAccountCommand) (*entity.Account, error) {
    // Domain validation via constructor (Always-Valid Domain Model)
    account, err := entity.NewAccount(cmd.OrgID, cmd.Name, cmd.Currency)
    if err != nil {
        return nil, err
    }

    if err := h.repo.Create(ctx, account); err != nil {
        return nil, err
    }

    return account, nil
}
```

### Query Side (Read)

Query handlers return denormalized views optimized for the consumer. No business logic.

```go
// internal/services/query/get_account_summary.go

type AccountSummaryView struct {
    ID            uuid.UUID `json:"id"`
    Name          string    `json:"name"`
    Currency      string    `json:"currency"`
    Balance       int64     `json:"balance"`
    LastTxDate    time.Time `json:"lastTransactionDate"`
    TxCount       int       `json:"transactionCount"`
}

type GetAccountSummaryHandler struct {
    queryRepo ports.AccountQueryRepository  // reads from denormalized view/table
}

func (h *GetAccountSummaryHandler) Handle(ctx context.Context, id uuid.UUID) (*AccountSummaryView, error) {
    return h.queryRepo.GetSummary(ctx, id)
}
```

### Integration with Ring Patterns

| Ring Pattern | Command Side | Query Side |
|-------------|-------------|-----------|
| Always-Valid Domain Model | MUST use `entity.New*` constructors with validation | Not needed — views are read-only DTOs |
| Repository Pattern | Standard write repository (`Create`, `Update`, `Delete`) | Separate query repository (`GetSummary`, `ListByFilter`) |
| Idempotency (idempotency.md) | MUST apply to command handlers that create resources | Not applicable (reads are idempotent by nature) |
| Caching (caching.md) | Invalidate cache on command execution | Cache query results (Cache-Aside recommended) |

### Detection Commands (for dev-refactor)

```bash
# Detect CQRS pattern: separate command/query directories
find internal/services -type d -name "command" -o -name "query" 2>/dev/null
# If both exist → CQRS detected

# Detect separate read models (projection/view types)
grep -rn "View\}\|Summary\}\|Projection\}" internal/ --include="*.go" | grep "type.*struct" | grep -v "_test.go"
# If present alongside domain entities → CQRS detected

# Detect mixed read/write in same handler (anti-pattern when CQRS should apply)
# Look for handlers that both query and mutate
grep -rn "func.*Handler.*Handle" internal/services/ --include="*.go" | grep -v "_test.go"
```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "CQRS is over-engineering for our service" | If read/write ratio is < 10:1 and models are identical, you're right — skip CQRS. But if you have separate views, reports, or dashboards, you already need it. | **Evaluate read/write ratio before deciding** |
| "We can add CQRS later" | Retrofitting CQRS into a mixed read/write codebase is a rewrite. Design the separation early. | **Separate command/query from the start if criteria met** |
| "One repository handles both reads and writes" | Mixed repositories grow into god objects. Command repos need transactions; query repos need JOINs and denormalization. | **Separate repositories for command and query** |
| "Views are just DTOs, no need for separate models" | Views often need JOINs, aggregations, and computed fields that don't belong in the domain model. | **Use dedicated view types for query side** |

