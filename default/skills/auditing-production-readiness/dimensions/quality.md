# Audit Dimensions: Category D — Quality & Maintainability

These are the 10 explorer agent prompts for Quality dimensions.
Inject Ring standards and detected stack before dispatching.

### Agent 16: Idempotency Auditor

```prompt
Audit idempotency implementation for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Full module content from idempotency.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/idempotency*.go`, `**/value_objects/*.go`, `**/redis/*.go`
- Keywords: `IdempotencyKey`, `TryAcquire`, `MarkComplete`, `SetNX`, `idempotent`
- Standards-specific: `IdempotencyRepository`, `idempotency middleware`

**Reference Implementation (GOOD):**
```go
// Idempotency key value object
type IdempotencyKey string

const (
    idempotencyKeyMaxLength = 128
    idempotencyKeyPattern   = `^[A-Za-z0-9:_-]+$`
)

func (key IdempotencyKey) IsValid() bool {
    s := string(key)
    if s == "" || len(s) > idempotencyKeyMaxLength {
        return false
    }
    return regexp.MustCompile(idempotencyKeyPattern).MatchString(s)
}

// Redis-backed idempotency
type IdempotencyRepository struct {
    client *redis.Client
    ttl    time.Duration  // e.g., 7 days
}

func (r *IdempotencyRepository) TryAcquire(ctx context.Context, key IdempotencyKey) (bool, error) {
    // SetNX is atomic - only first caller wins
    result, err := r.client.SetNX(ctx, r.keyName(key), "acquired", r.ttl).Result()
    return result, err
}

func (r *IdempotencyRepository) MarkComplete(ctx context.Context, key IdempotencyKey) error {
    return r.client.Set(ctx, r.keyName(key), "complete", r.ttl).Err()
}

// Usage in handler
func (h *Handler) ProcessCallback(c *fiber.Ctx) error {
    key := extractIdempotencyKey(c)

    acquired, err := h.idempotency.TryAcquire(ctx, key)
    if err != nil {
        return internalError(c, "idempotency check failed", err)
    }
    if !acquired {
        return c.Status(200).JSON(fiber.Map{"status": "already_processed"})
    }

    // Process...

    h.idempotency.MarkComplete(ctx, key)
    return c.JSON(result)
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) Idempotency keys for financial/critical operations per idempotency.md
2. (HARD GATE) Atomic acquire mechanism (SetNX or similar)
3. TTL to prevent unbounded storage
4. Key validation (format, length) per Ring idempotency patterns
5. Proper state transitions (acquired -> complete/failed)
6. Retry-safe (failed operations can be retried)
7. Idempotency for webhook callbacks
8. Idempotency for payment operations

**Severity Ratings:**
- CRITICAL: No idempotency for financial operations (HARD GATE violation per Ring standards)
- HIGH: Non-atomic acquire (race conditions)
- HIGH: No TTL (memory leak)
- MEDIUM: Missing key validation
- LOW: No failed state handling

**Output Format:**
```
## Idempotency Audit Findings

### Summary
- Idempotency implemented: Yes/No
- Operations covered: [list]
- Storage backend: Redis/DB/Memory
- TTL configured: X days

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 17: API Documentation Auditor

```prompt
Audit API documentation (Swagger/OpenAPI) for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Swaggo/OpenAPI subsection from "Pagination Patterns" in api-patterns.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/main.go`, `**/handlers.go`, `**/dto.go`, `**/swagger/*`
- Keywords: `@Summary`, `@Router`, `@Param`, `@Success`, `@Failure`, `@Security`
- Standards-specific: `swaggo`, `swag init`, `docs/swagger.json`

**Reference Implementation (GOOD):**
```go
// Main entry with API metadata
// @title           My API
// @version         v1.0.0
// @description     API description
// @BasePath        /
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization

// Handler with full documentation
// @Summary      Create a resource
// @Description  Creates a new resource with the given parameters
// @Tags         resources
// @Accept       json
// @Produce      json
// @Param        request body CreateRequest true "Resource to create"
// @Success      201 {object} ResourceResponse
// @Failure      400 {object} ErrorResponse "Invalid input"
// @Failure      401 {object} ErrorResponse "Unauthorized"
// @Failure      403 {object} ErrorResponse "Forbidden"
// @Failure      500 {object} ErrorResponse "Internal error"
// @Security     BearerAuth
// @Router       /v1/resources [post]
func (h *Handler) Create(c *fiber.Ctx) error { ... }

// DTO with documentation
type CreateRequest struct {
    Name   string `json:"name" example:"my-resource" validate:"required"`
    Type   string `json:"type" example:"TYPE_A" enums:"TYPE_A,TYPE_B"`
    Amount int    `json:"amount" example:"100" minimum:"0" maximum:"1000000"`
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) Swaggo annotations present per Ring api-patterns.md
2. API title, version, description in main.go
3. Security definitions (Bearer token)
4. All endpoints have @Router annotation
5. Request/response types documented
6. All error codes documented (@Failure)
7. Examples in DTOs (example: tag)
8. Enums documented (enums: tag)
9. Parameter constraints documented (minimum, maximum)
10. Tags organize endpoints logically
11. Swagger UI accessible

**Severity Ratings:**
- HIGH: No Swagger annotations at all (HARD GATE violation per Ring standards)
- HIGH: Missing security definitions
- MEDIUM: Endpoints without documentation
- MEDIUM: Error responses not documented
- LOW: Missing examples in DTOs
- LOW: Inconsistent tag usage

**Output Format:**
```
## API Documentation Audit Findings

### Summary
- Swagger annotations: Yes/No
- Documented endpoints: X/Y
- Security definitions: Yes/No
- Error responses documented: X/Y

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 18: Technical Debt Auditor

```prompt
Audit technical debt indicators for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Search Patterns (with context):**
- `TODO` - Planned work
- `FIXME` - Known bugs
- `HACK` - Workarounds
- `XXX` - Danger zones
- `deprecated` (case-insensitive)
- `"in a real implementation"` or `"real implementation"`
- `"temporary"` or `"temp fix"`
- `"workaround"`
- `panic("not implemented")`

**Risk Assessment Criteria:**

**Implement Now (High Risk):**
- Security-related TODOs (auth, validation, encryption)
- Error handling TODOs in critical paths
- Data integrity issues
- "FIXME" in production code paths

**Monitor (Medium Risk):**
- Performance optimization TODOs
- Incomplete logging
- "deprecated" usage without migration plan

**Acceptable Debt (Low Risk):**
- Future feature ideas
- Code style improvements
- Test coverage expansion
- Documentation improvements

**Output Format:**
```
## Technical Debt Audit Findings

### Summary
- Total TODOs: X
- Total FIXMEs: Y
- Deprecated usage: Z
- "Real implementation" markers: N

### HIGH RISK - Implement Now
| File:Line | Type | Description | Risk |
|-----------|------|-------------|------|
| path:123 | TODO | Auth bypass for testing | Security |

### MEDIUM RISK - Monitor
| File:Line | Type | Description | Risk |
|-----------|------|-------------|------|

### LOW RISK - Acceptable Debt
| File:Line | Type | Description | Risk |
|-----------|------|-------------|------|

### Recommendations
1. ...
```
```

### Agent 19: Testing Coverage Auditor

```prompt
Audit test coverage and testing patterns for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Testing" section from quality.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/*_test.go`, `**/mocks/**/*.go`, `tests/**/*.go`
- Keywords: `func Test`, `t.Run`, `mock.Mock`, `assert.`, `require.`
- Standards-specific: `mockgen`, `testify`, `testcontainers`

**Reference Implementation (GOOD):**
```go
// Co-located test file
// file: handler_test.go (next to handler.go)

func TestHandler_Create(t *testing.T) {
    // Arrange
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()

    mockRepo := mocks.NewMockRepository(ctrl)
    mockRepo.EXPECT().Save(gomock.Any(), gomock.Any()).Return(nil)

    handler := NewHandler(mockRepo)

    // Act
    result, err := handler.Create(ctx, input)

    // Assert
    require.NoError(t, err)
    assert.Equal(t, expected, result)
}

// Table-driven tests for multiple cases
func TestValidation(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"valid input", "test", false},
        {"empty input", "", true},
        {"too long", strings.Repeat("a", 300), true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := Validate(tt.input)
            if tt.wantErr {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}

// Integration test with testcontainers
func TestIntegration_CreateResource(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }
    // Setup container...
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) Test files co-located with source (*_test.go) per quality.md testing section
2. (HARD GATE) Mocks generated via mockgen (not hand-written) per Ring standards
3. (HARD GATE) Assertions use testify (assert/require) per Ring standards
4. Table-driven tests for multiple cases
5. Integration tests in separate directory or with build tags
6. Test helpers/fixtures organized
7. Parallel tests where appropriate (t.Parallel())
8. Test cleanup with t.Cleanup() or defer

**Severity Ratings:**
- HIGH: Critical paths without tests (HARD GATE violation per Ring standards)
- HIGH: Hand-written mocks (should use mockgen per Ring standards)
- MEDIUM: Missing table-driven tests for validators
- MEDIUM: No integration tests
- LOW: Tests not running in parallel
- LOW: Missing edge case coverage

**Output Format:**
```
## Testing Coverage Audit Findings

### Summary
- Test files found: X
- Modules with tests: X/Y
- Mock generation: mockgen / hand-written
- Integration tests: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 20: Dependency Management Auditor

```prompt
Audit dependency management for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Frameworks & Libraries" section from core.md — specifically the version table}
---END STANDARDS---

**Search Patterns:**
- Files: `go.mod`, `go.sum`, `**/vendor/**`
- Commands: Run `go list -m -u all` mentally based on go.mod
- Standards-specific: Check for required Ring dependencies in go.mod

**Reference Implementation (GOOD):**
```go
// go.mod with pinned versions
module github.com/company/project

go 1.24

require (
    github.com/gofiber/fiber/v2 v2.52.10  // Pinned, not "latest"
    github.com/lib/pq v1.10.9
    go.opentelemetry.io/otel v1.39.0
)

// Indirect deps managed automatically
require (
    github.com/valyala/fasthttp v1.52.0 // indirect
)
```

**Reference Implementation (BAD):**
```go
// BAD: Using replace for production
replace github.com/some/lib => ../local-lib

// BAD: Unpinned versions
require github.com/some/lib latest

// BAD: Very old versions with known CVEs
require github.com/dgrijalva/jwt-go v3.2.0  // Has CVE, use golang-jwt
```

**Check Against Ring Standards For:**
1. (HARD GATE) Required Ring framework dependencies present in go.mod per core.md version table
2. All dependencies pinned (no "latest")
3. No local replace directives in production
4. Known vulnerable packages identified
5. Unused dependencies (not imported anywhere)
6. Major version mismatches
7. Deprecated packages (e.g., dgrijalva/jwt-go -> golang-jwt)
8. go.sum exists and is committed
9. Framework versions meet Ring minimum requirements (Go 1.24+, Fiber v2, etc.)

**Known Vulnerable Packages to Flag:**
- github.com/dgrijalva/jwt-go (use golang-jwt/jwt)
- github.com/pkg/sftp < v1.13.5
- golang.org/x/crypto < recent
- golang.org/x/net < recent

**Severity Ratings:**
- CRITICAL: Known CVE in dependency
- CRITICAL: HARD GATE violation — required Ring framework dependency missing from go.mod
- HIGH: Local replace directive
- HIGH: Deprecated package with security issues
- MEDIUM: Significantly outdated dependencies
- MEDIUM: Framework versions below Ring minimum requirements
- LOW: Minor version behind

**Output Format:**
```
## Dependency Audit Findings

### Summary
- Total dependencies: X
- Direct dependencies: Y
- Potentially outdated: Z
- Known vulnerabilities: N

### Critical Issues
[package] - Description

### Recommendations
1. ...
```
```

### Agent 21: Performance Patterns Auditor

```prompt
Audit performance patterns for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Search Patterns:**
- Files: `**/*.go`
- Keywords: `for.*range`, `append(`, `make(`, `sync.Pool`, `SELECT *`, `N+1`

**Reference Implementation (GOOD):**
```go
// Pre-allocate slices when size is known
items := make([]Item, 0, len(input))  // Capacity hint

// Use sync.Pool for frequently allocated objects
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

// Batch database operations
func (r *Repo) CreateBatch(ctx context.Context, items []Item) error {
    return r.db.WithContext(ctx).CreateInBatches(items, 100).Error
}

// Select only needed columns
func (r *Repo) List(ctx context.Context) ([]Item, error) {
    return r.db.WithContext(ctx).
        Select("id", "name", "status").  // Not SELECT *
        Find(&items).Error
}

// Avoid N+1 with preloading
func (r *Repo) GetWithRelations(ctx context.Context, id uuid.UUID) (*Item, error) {
    return r.db.WithContext(ctx).
        Preload("Children").
        First(&item, id).Error
}
```

**Reference Implementation (BAD):**
```go
// BAD: SELECT * fetches unnecessary data
db.Find(&items)

// BAD: N+1 query pattern
for _, item := range items {
    db.Where("parent_id = ?", item.ID).Find(&children)  // Query per item!
}

// BAD: Growing slice without capacity
var items []Item
for _, input := range inputs {
    items = append(items, transform(input))  // Reallocates repeatedly
}

// BAD: Large allocations in hot path without pooling
func handleRequest() {
    buf := make([]byte, 1<<20)  // 1MB allocation per request
}
```

**Check For:**
1. SELECT * avoided (explicit column selection)
2. N+1 queries prevented (use Preload/joins)
3. Slice pre-allocation when size known
4. sync.Pool for frequent allocations
5. Batch operations for bulk inserts/updates
6. Indexes exist for filtered/sorted columns
7. Connection pooling configured
8. Context timeouts on DB operations

**Severity Ratings:**
- HIGH: N+1 query pattern in production code
- HIGH: SELECT * on large tables
- MEDIUM: Missing slice pre-allocation
- MEDIUM: No batch operations for bulk data
- LOW: Missing sync.Pool optimization
- LOW: Minor inefficiencies

**Output Format:**
```
## Performance Audit Findings

### Summary
- N+1 patterns found: X
- SELECT * usage: Y
- Missing pre-allocations: Z

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 22: Concurrency Safety Auditor

```prompt
Audit concurrency patterns for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Concurrency Patterns" section from architecture.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/*.go`
- Keywords: `go func`, `sync.Mutex`, `sync.RWMutex`, `chan`, `select {`, `sync.WaitGroup`
- Standards-specific: `errgroup`, `semaphore`, `worker pool`

**Reference Implementation (GOOD):**
```go
// Mutex protecting shared state
type Cache struct {
    mu    sync.RWMutex
    items map[string]Item
}

func (c *Cache) Get(key string) (Item, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    item, ok := c.items[key]
    return item, ok
}

func (c *Cache) Set(key string, item Item) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.items[key] = item
}

// WaitGroup for goroutine coordination
func processAll(items []Item) error {
    var wg sync.WaitGroup
    errCh := make(chan error, len(items))

    for _, item := range items {
        wg.Add(1)
        go func(i Item) {
            defer wg.Done()
            if err := process(i); err != nil {
                errCh <- err
            }
        }(item)  // Pass item to avoid closure capture
    }

    wg.Wait()
    close(errCh)

    // Collect errors
    for err := range errCh {
        return err
    }
    return nil
}

// Context for cancellation
func worker(ctx context.Context) {
    for {
        select {
        case <-ctx.Done():
            return
        case item := <-workCh:
            process(item)
        }
    }
}
```

**Reference Implementation (BAD):**
```go
// BAD: Race condition - map access without lock
var cache = make(map[string]Item)
func Get(key string) Item { return cache[key] }  // Concurrent read/write!

// BAD: Goroutine leak - no way to stop
go func() {
    for {
        process()  // Runs forever, no context check
    }
}()

// BAD: Closure captures loop variable
for _, item := range items {
    go func() {
        process(item)  // All goroutines see last item!
    }()
}

// BAD: Unbounded goroutine spawning
for _, item := range millionItems {
    go process(item)  // 1M goroutines!
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) Maps protected by mutex when shared per architecture.md concurrency patterns
2. Loop variables not captured in closures
3. Goroutines have cancellation (context)
4. WaitGroup used for coordination
5. Bounded concurrency (worker pools) per Ring patterns
6. Channels closed by sender
7. Select with default for non-blocking
8. No goroutine leaks (all paths exit)

**Severity Ratings:**
- CRITICAL: Race condition on shared map (HARD GATE violation per Ring standards)
- CRITICAL: Goroutine leak (no exit path)
- HIGH: Loop variable capture bug
- HIGH: Unbounded goroutine spawning
- MEDIUM: Missing context cancellation
- LOW: Inefficient locking patterns

**Output Format:**
```
## Concurrency Audit Findings

### Summary
- Goroutine spawns: X locations
- Mutex usage: Y locations
- Potential race conditions: Z

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 23: Migration Safety Auditor

```prompt
Audit database migration safety for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Core Dependency: lib-commons" section from core.md — database migration patterns}
---END STANDARDS---

**Search Patterns:**
- Files: `migrations/*.sql`, `migrations/*.go`
- Keywords: `DROP`, `ALTER`, `RENAME`, `NOT NULL`, `CREATE INDEX`
- Standards-specific: `golang-migrate`, `lib-commons migration`

**Reference Implementation (GOOD):**
```sql
-- 000001_create_users.up.sql
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);

-- 000001_create_users.down.sql
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;

-- Adding nullable column (safe)
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(50);

-- Adding NOT NULL with default (safe)
ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'active';
```

**Reference Implementation (BAD):**
```sql
-- BAD: Adding NOT NULL without default (locks table, fails if data exists)
ALTER TABLE users ADD COLUMN role VARCHAR(50) NOT NULL;

-- BAD: Non-concurrent index (locks table)
CREATE INDEX idx_users_email ON users(email);

-- BAD: Destructive without IF EXISTS
DROP TABLE users;
DROP COLUMN email;

-- BAD: Renaming column (breaks application)
ALTER TABLE users RENAME COLUMN email TO user_email;
```

**Reference Implementation (GOOD — Constraints & Data Migrations):**
```sql
-- GOOD: NOT NULL ADD COLUMN with DEFAULT (no table rewrite lock)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'pending';

-- GOOD: CHECK constraint for domain validation at DB level
ALTER TABLE orders ADD CONSTRAINT chk_order_status
    CHECK (status IN ('pending', 'processing', 'completed', 'cancelled', 'refunded'));

-- GOOD: Foreign key with explicit cascading behavior and matching types
ALTER TABLE order_items ADD CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- GOOD: Enum type at database level
CREATE TYPE account_status AS ENUM ('active', 'inactive', 'suspended', 'deleted');
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS status account_status NOT NULL DEFAULT 'active';

-- GOOD: Separate data migration file (000005_backfill_status.up.sql)
-- This is a DATA migration, separate from schema changes
UPDATE orders SET status = 'completed' WHERE legacy_status = 1 AND status IS NULL;
UPDATE orders SET status = 'cancelled' WHERE legacy_status = 2 AND status IS NULL;
```

**Reference Implementation (BAD — Constraints & Data Migrations):**
```sql
-- BAD: NOT NULL ADD COLUMN without DEFAULT (full table rewrite — locks table)
ALTER TABLE orders ADD COLUMN priority INTEGER NOT NULL;
-- On a table with 10M rows, this locks the table for minutes

-- BAD: No CHECK constraint — application validates but DB accepts anything
ALTER TABLE orders ADD COLUMN status VARCHAR(20);
-- Application code checks status in ('pending', 'completed') but DB allows 'banana'

-- BAD: Foreign key with mismatched types
ALTER TABLE order_items ADD CONSTRAINT fk_order
    FOREIGN KEY (order_id) REFERENCES orders(id);

-- BAD: Foreign key without cascading behavior
ALTER TABLE order_items ADD CONSTRAINT fk_order
    FOREIGN KEY (order_id) REFERENCES orders(id);
-- Default NO ACTION — DELETE FROM orders fails if order_items exist (unexpected 500s)

-- BAD: Data migration mixed with schema migration in same file
ALTER TABLE orders ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending';
UPDATE orders SET status = 'completed' WHERE completed_at IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_orders_status ON orders(status);
-- CONCURRENTLY cannot run inside a transaction — this file cannot execute atomically
```

**Check Against Ring Standards For:**
1. (HARD GATE) All migrations have up AND down files per Ring migration patterns
2. (HARD GATE) CREATE INDEX uses CONCURRENTLY
3. New NOT NULL columns have DEFAULT
4. DROP/ALTER use IF EXISTS
5. No column renames (add new, migrate data, drop old)
6. No destructive operations in up migrations
7. Migrations are additive (safe rollback)
8. Sequential numbering (no gaps)
9. Migration tool matches Ring standard (golang-migrate or lib-commons)
10. MUST: NOT NULL columns have DEFAULT values in ADD COLUMN migrations — adding a NOT NULL column without DEFAULT requires a full table rewrite lock on existing data, causing downtime on large tables
11. MUST: Add CHECK constraints for domain-specific validation at database level — values validated only in application code must also have database-level CHECK constraints as a safety net
12. MUST: Ensure foreign key consistency — foreign keys must have matching column types and must define explicit cascading behavior (ON DELETE/ON UPDATE) rather than relying on database defaults
13. MUST: Enforce enum validation at database level — domain enums must be enforced via CHECK constraint or PostgreSQL enum type, not just application-level validation
14. MUST: Keep data migration scripts separate from schema migrations — mixing data transformations with schema changes in the same migration file makes rollback unsafe

**Severity Ratings:**
- CRITICAL: NOT NULL without default (HARD GATE violation per Ring standards)
- CRITICAL: Missing down migration (HARD GATE violation)
- CRITICAL: NOT NULL ADD COLUMN without DEFAULT (locks entire table for rewrite on large datasets — causes production downtime)
- HIGH: Non-concurrent index creation
- HIGH: Column rename (breaking change)
- HIGH: No CHECK constraints for domain values validated only in application code (database accepts any value — data corruption if application validation is bypassed)
- MEDIUM: DROP without IF EXISTS
- MEDIUM: Foreign keys without explicit cascading behavior (relies on database default `NO ACTION` — may cause unexpected constraint violations on DELETE)
- MEDIUM: Enum values validated only in application code (database allows invalid values — data integrity depends entirely on application correctness)
- LOW: Migration naming inconsistency
- LOW: Data migrations mixed with schema migrations in same file (harder to rollback, debug, and review independently)

**Output Format:**
```
## Migration Safety Audit Findings

### Summary
- Total migrations: X
- Up migrations: Y
- Down migrations: Z
- Potentially unsafe: N

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 31: Linting & Code Quality Auditor

```prompt
Audit linting configuration and code quality patterns for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Linting" section 16 from quality.md}
---END STANDARDS---

**Search Patterns:**
- Files: `.golangci.yml`, `.golangci.yaml`, `**/*.go`
- Keywords: `//nolint`, `golangci-lint`, import grouping patterns
- Also search: Magic numbers in business logic code

**Reference Implementation (GOOD):**
```go
// Import ordering: 3 groups (stdlib, external, internal)
import (
    "context"
    "fmt"
    "time"

    "github.com/gofiber/fiber/v2"
    "github.com/google/uuid"
    "go.opentelemetry.io/otel"

    "github.com/company/project/internal/domain"
)

// Named constants instead of magic numbers
const (
    maxRetries       = 3
    defaultTimeout   = 30 * time.Second
    maxPageSize      = 100
    minPasswordLen   = 8
)

// Using named constants in logic
if retryCount >= maxRetries {
    return ErrMaxRetriesExceeded
}
```

**Reference Implementation (BAD):**
```go
// BAD: Import ordering not following convention
import (
    "github.com/company/project/internal/domain"
    "fmt"
    "github.com/gofiber/fiber/v2"
    "context"
)

// BAD: Magic numbers in business logic
if retryCount >= 3 {           // What is 3?
    time.Sleep(30 * time.Second) // What is 30?
}
if len(password) < 8 {          // What is 8?
    return errors.New("too short")
}
if pageSize > 100 {             // What is 100?
    pageSize = 100
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) golangci-lint configuration exists per quality.md linting section
2. Import ordering follows 3-group convention (stdlib, external, internal)
3. Magic numbers replaced with named constants in business logic
4. Required linters enabled in golangci-lint config
5. No blanket //nolint without specific linter name
6. Consistent code formatting (gofmt/goimports applied)

**Severity Ratings:**
- HIGH: No golangci-lint configuration (HARD GATE violation per Ring standards)
- MEDIUM: Magic numbers in business logic
- MEDIUM: Import ordering not following 3-group convention
- MEDIUM: Blanket //nolint without justification
- LOW: Minor style inconsistencies

**Output Format:**
```
## Linting & Code Quality Audit Findings

### Summary
- golangci-lint config: Yes/No
- Import ordering violations: X files
- Magic numbers found: Y locations
- Blanket //nolint usage: Z locations

### Issues
#### golangci-lint Configuration
[config status and missing linters]

#### Import Ordering
[file:line] - Imports not following 3-group convention

#### Magic Numbers
[file:line] - Magic number N used (suggest: named constant)

### Recommendations
1. ...
```
```

### Agent 40: Caching Patterns Auditor

```prompt
Audit caching patterns, invalidation strategies, and cache safety for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Caching patterns — no dedicated standards file; patterns derived from quality and maintainability best practices}
---END STANDARDS---

**Search Patterns:**
- Go files: `**/*.go` — search for cache operations, singleflight, TTL configuration, Redis clients, in-memory caches
- TypeScript files: `**/*.ts`, `**/*.tsx` — search for cache-aside patterns, LRU cache, ioredis, node-cache
- Config files: `**/*.yaml`, `**/*.yml`, `**/*.env*` — search for cache TTL, Redis connection, eviction settings
- Keywords (Go): `singleflight`, `go-cache`, `bigcache`, `freecache`, `ristretto`, `redis.Set`, `redis.Get`, `cache.Set`, `cache.Get`, `TTL`, `Expiration`, `SetEX`, `SetNX`
- Keywords (TS): `node-cache`, `ioredis`, `createClient`, `cache.set`, `cache.get`, `lru-cache`, `LRUCache`, `cache.del`, `invalidate`, `Redis`, `ttl`

**Go Caching Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| Unbounded cache growth | CRITICAL | Cache `Set` without TTL or max-size — leads to OOM under load |
| No invalidation on writes | HIGH | Data mutated in DB but cache not invalidated — stale data served indefinitely |
| Cache stampede vulnerability | HIGH | Multiple goroutines hit cache miss simultaneously — all hit DB. Check for `singleflight` |
| Non-tenant-scoped keys | HIGH | Cache keys like `user:{id}` without tenant prefix in multi-tenant system — data leak |
| Inconsistent TTL values | MEDIUM | Similar data types cached with wildly different TTLs — unpredictable staleness |
| No cache warming | MEDIUM | Cold start after deploy/restart causes thundering herd to DB |
| Missing cache metrics | LOW | No hit/miss/eviction counters — impossible to tune cache |
| No cache versioning | LOW | Schema changes break cached data — no version prefix in keys |

**TypeScript Caching Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| Unbounded cache growth | CRITICAL | In-memory cache with no `max` or `maxSize` — leads to OOM |
| No invalidation on writes | HIGH | Mutation endpoints don't clear related cache entries |
| Cache stampede vulnerability | HIGH | No locking or coalescing on concurrent cache misses |
| Non-tenant-scoped keys | HIGH | Cache keys without tenant context in multi-tenant system |
| No TTL on Redis keys | MEDIUM | `redis.set(key, value)` without `EX` — keys persist forever |
| Inconsistent TTL strategy | MEDIUM | Random TTL values scattered across codebase |
| Missing error handling for cache | MEDIUM | Cache failure crashes request instead of falling through to source |
| No cache hit/miss metrics | LOW | Cannot measure cache effectiveness |

**Cache Safety Methodology (MANDATORY — do not skip):**
1. **Inventory caches**: Find all cache instances (in-memory, Redis, CDN) and their usage
2. **Check bounds**: Verify every cache has TTL, max-size, or eviction policy — no unbounded growth
3. **Check invalidation**: For every write/mutation path, verify the corresponding cache entry is invalidated
4. **Check stampede protection**: Verify singleflight, distributed locks, or request coalescing on cache miss paths
5. **Check tenant isolation**: In multi-tenant systems, verify all cache keys include tenant context
6. **Check consistency**: Verify TTL values are consistent for similar data types

**Reference Implementation (GOOD — Go):**
```go
// GOOD: singleflight prevents cache stampede
var group singleflight.Group

func (s *Service) GetProduct(ctx context.Context, id string) (*Product, error) {
    key := fmt.Sprintf("tenant:%s:product:%s", tenant.FromContext(ctx), id)

    // Check cache first
    if cached, err := s.cache.Get(ctx, key); err == nil {
        return cached.(*Product), nil
    }

    // singleflight: only one goroutine fetches from DB
    result, err, _ := group.Do(key, func() (interface{}, error) {
        product, err := s.repo.FindByID(ctx, id)
        if err != nil {
            return nil, err
        }
        // Set with TTL
        _ = s.cache.Set(ctx, key, product, 5*time.Minute)
        return product, nil
    })
    if err != nil {
        return nil, err
    }
    return result.(*Product), nil
}

// GOOD: Invalidate cache on write
func (s *Service) UpdateProduct(ctx context.Context, id string, update *ProductUpdate) error {
    if err := s.repo.Update(ctx, id, update); err != nil {
        return err
    }
    key := fmt.Sprintf("tenant:%s:product:%s", tenant.FromContext(ctx), id)
    _ = s.cache.Delete(ctx, key)
    return nil
}

// GOOD: Bounded in-memory cache with TTL
cache := ristretto.NewCache(&ristretto.Config{
    NumCounters: 1e7,     // 10M counters
    MaxCost:     1 << 30, // 1GB max
    BufferItems: 64,
})
```

**Reference Implementation (BAD — Go):**
```go
// BAD: No singleflight — cache stampede under load
func (s *Service) GetProduct(ctx context.Context, id string) (*Product, error) {
    if cached, err := s.cache.Get(ctx, id); err == nil { // no tenant prefix!
        return cached.(*Product), nil
    }
    // Every concurrent request hits DB on cache miss
    product, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }
    s.cache.Set(ctx, id, product, 0) // no TTL — lives forever
    return product, nil
}

// BAD: No invalidation on write — stale data served
func (s *Service) UpdateProduct(ctx context.Context, id string, update *ProductUpdate) error {
    return s.repo.Update(ctx, id, update) // cache not invalidated
}

// BAD: Unbounded in-memory map as cache — OOM risk
var cache = make(map[string]interface{}) // grows forever, never evicted
```

**Reference Implementation (GOOD — TypeScript):**
```typescript
// GOOD: Bounded LRU cache with TTL
import { LRUCache } from 'lru-cache';

const cache = new LRUCache<string, Product>({
    max: 500,           // max entries
    ttl: 1000 * 60 * 5, // 5 minute TTL
});

// GOOD: Tenant-scoped cache key with invalidation on write
async function updateProduct(tenantId: string, id: string, data: ProductUpdate): Promise<void> {
    await db.products.update(id, data);
    cache.delete(`${tenantId}:product:${id}`);
}

// GOOD: Cache failure falls through to source
async function getProduct(tenantId: string, id: string): Promise<Product> {
    const key = `${tenantId}:product:${id}`;
    try {
        const cached = await redis.get(key);
        if (cached) return JSON.parse(cached);
    } catch {
        // Cache failure — fall through to DB
    }
    const product = await db.products.findById(id);
    try {
        await redis.set(key, JSON.stringify(product), 'EX', 300);
    } catch {
        // Cache write failure — non-fatal
    }
    return product;
}
```

**Reference Implementation (BAD — TypeScript):**
```typescript
// BAD: Unbounded cache — no max, no TTL
const cache = new Map<string, any>(); // grows forever

// BAD: No tenant prefix — data leak in multi-tenant system
cache.set(`product:${id}`, product); // missing tenant context

// BAD: Cache failure crashes request
async function getProduct(id: string): Promise<Product> {
    const cached = await redis.get(`product:${id}`); // throws if Redis down
    if (cached) return JSON.parse(cached);
    return db.products.findById(id);
}

// BAD: No invalidation — write to DB but cache still has old data
async function updateProduct(id: string, data: ProductUpdate): Promise<void> {
    await db.products.update(id, data);
    // cache still has stale product data
}
```

**Check Against Standards For:**
1. (CRITICAL) All caches have TTL, max-size, or eviction policy — no unbounded growth
2. (HIGH) Cache entries are invalidated when underlying data is mutated
3. (HIGH) Cache stampede protection exists (singleflight, distributed locks, request coalescing)
4. (HIGH) Cache keys are tenant-scoped in multi-tenant systems
5. (MEDIUM) TTL values are consistent for similar data types across codebase
6. (MEDIUM) Cache failures do not crash requests (graceful fallthrough to source)
7. (MEDIUM) Cache warming strategy exists for cold-start scenarios
8. (LOW) Cache hit/miss/eviction metrics are tracked
9. (LOW) Cache keys include version prefix for schema change safety

**Severity Ratings:**
- CRITICAL: Unbounded cache growth (no TTL, no eviction, no max-size) — OOM risk in production
- HIGH: No cache invalidation on writes (stale data served indefinitely), cache stampede vulnerability (thundering herd to DB), non-tenant-scoped keys in multi-tenant system (data leak)
- MEDIUM: Inconsistent TTL values, cache failure crashes request, no cache warming for cold-start, no TTL on Redis keys
- LOW: Missing cache hit/miss metrics, no cache key versioning strategy

**Output Format:**
```
## Caching Patterns Audit Findings

### Summary
- Cache instances found: X (in-memory: Y, Redis: Z, CDN: W)
- Caches with TTL/eviction: Y/X
- Stampede protection: Yes/No (mechanism: singleflight / locks / none)
- Multi-tenant key scoping: Yes/No/N/A
- Invalidation on writes: Y/Z write paths
- Cache metrics instrumented: Yes/No

### Critical Issues
[file:line] - Description (pattern: {pattern name})

### High Issues
[file:line] - Description (pattern: {pattern name})

### Medium Issues
[file:line] - Description

### Low Issues
[file:line] - Description

### Cache Inventory
| Cache | Type | Max Size | TTL | Eviction | Stampede Protection | Tenant-Scoped |
|-------|------|----------|-----|----------|---------------------|---------------|
| ... | ... | ... | ... | ... | ... | ... |

### Recommendations
1. ...
```
```

