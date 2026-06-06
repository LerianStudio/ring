# Audit Dimensions: Category A — Code Structure & Patterns

These are the 11 explorer agent prompts for Code Structure & Patterns dimensions.
Inject Ring standards and detected stack before dispatching.

### Agent 1: Pagination Standards Auditor

```prompt
Audit pagination implementation across the codebase for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Pagination Patterns" section from api-patterns.md}
---END STANDARDS---

**Key Concept: Core one uses TWO valid pagination strategies:**
- **Offset** for low-volume admin entities (organizations, ledgers, accounts, assets, portfolios, products, segments)
- **Cursor** for high-volume transaction entities (transactions, operations, balances, audit logs, events)

**Search Patterns:**
- Files: `**/pagination*.go`, `**/handlers.go`, `**/dto.go`, `**/httputils.go`, `**/cursor.go`
- Keywords: `limit`, `offset`, `cursor`, `Page`, `NextCursor`, `PrevCursor`, `SetCursor`, `SetItems`
- Standards-specific: `CursorPagination`, `Pagination`, `ValidateParameters`, `QueryHeader`, `MAX_PAGINATION_LIMIT`

**Reference Implementations (GOOD):**

Offset mode (admin entities):
```go
// Handler sets Page field — indicates offset mode
pagination := libPostgres.Pagination{
    Limit:     headerParams.Limit,
    Page:      headerParams.Page,
    SortOrder: headerParams.SortOrder,
}
items, err := h.Query.GetAllOrganizations(ctx, *headerParams)
pagination.SetItems(items)
return libHTTP.OK(c, pagination)

// Repository uses OFFSET = (Page - 1) * Limit
query.Limit(filter.Limit).Offset((filter.Page - 1) * filter.Limit)
```

Cursor mode (transaction entities):
```go
// Handler does NOT set Page — indicates cursor mode
pagination := libPostgres.Pagination{
    Limit:     headerParams.Limit,
    SortOrder: headerParams.SortOrder,
}
items, cursor, err := h.Query.GetAllTransactions(ctx, orgID, ledgerID, *headerParams)
pagination.SetItems(items)
pagination.SetCursor(cursor.Next, cursor.Prev)
return libHTTP.OK(c, pagination)
```

**Check Against Ring Standards For:**
1. (HARD GATE) Consistent pagination response structure matching Ring standards across all list endpoints
2. (HARD GATE) Maximum limit enforcement via `ValidateParameters` (MAX_PAGINATION_LIMIT, default 100)
3. Correct strategy per entity type: offset for admin entities, cursor for transaction entities
4. No mixing of both strategies in the same endpoint (page + cursor in same response is FORBIDDEN)
5. Proper error handling for invalid pagination params
6. Default values when params missing
7. Response field names match Ring API conventions (camelCase JSON)

**Severity Ratings:**
- CRITICAL: No limit validation (allows unlimited queries)
- CRITICAL: HARD GATE violation per Ring standards — pagination response structure missing entirely
- HIGH: Inconsistent pagination structures across endpoints
- HIGH: Missing `ValidateParameters` call on list endpoints
- MEDIUM: Using offset pagination on high-volume transaction tables
- MEDIUM: Mixing both strategies in the same endpoint
- LOW: Using cursor where offset would suffice for admin entities

**Output Format:**
```
## Pagination Audit Findings

### Summary
- Total list endpoints: X
- Using cursor pagination: Y
- Using offset pagination: Z
- Missing pagination entirely: W
- Missing limit validation: N

### Strategy Mapping
| Endpoint | Entity Type | Expected Strategy | Actual Strategy | Match |
|----------|-------------|-------------------|-----------------|-------|

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```


### Agent 2: Error Framework Auditor

```prompt
Audit error handling framework usage for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Error Codes Convention" and "Error Handling" sections from domain.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/error*.go`, `**/handlers.go`
- Keywords: `ErrRepo`, `errors.Is`, `errors.As`, `errors.New`
- Also search: `panic(`, `log.Fatal`
- Standards-specific: `ErrCode`, `DomainError`, `ErrorResponse`

**Reference Implementation (GOOD):**
```go
// Validate with explicit checks and return errors (no panic)
if config == nil {
    return fmt.Errorf("validation: config required")
}

// Domain error types
var (
    ErrNotFound        = errors.New("resource not found")
    ErrInvalidInput    = errors.New("invalid input")
)

// Error mapping in handlers
if errors.Is(err, domain.ErrNotFound) {
    return httputil.NotFoundError(c, span, logger, "resource not found", err)
}
```

**Reference Implementation (BAD):**
```go
// Direct panic in production code
if config == nil {
    panic("config is nil")  // BAD: Return error instead
}

// Swallowing errors
result, _ := doSomething()  // BAD: Ignoring error

// Generic error messages
return errors.New("error")  // BAD: Not descriptive
```

**Reference Implementation (GOOD — RFC 7807 Error Responses):**
```go
// RFC 7807 Problem Details compliant error response
type ProblemDetails struct {
    Type     string `json:"type"`               // URI reference identifying the problem type
    Title    string `json:"title"`              // Short human-readable summary
    Status   int    `json:"status"`             // HTTP status code
    Detail   string `json:"detail"`             // Human-readable explanation specific to this occurrence
    Instance string `json:"instance,omitempty"` // URI reference for the specific occurrence
    Code     string `json:"code"`               // Machine-readable error code for programmatic handling
}

// Consistent error response factory
func NewProblemResponse(c *fiber.Ctx, status int, errCode string, detail string) error {
    return c.Status(status).JSON(ProblemDetails{
        Type:     "https://api.example.com/errors/" + errCode,
        Title:    http.StatusText(status),
        Status:   status,
        Detail:   detail,
        Instance: c.Path(),
        Code:     errCode,
    })
}

// Handler usage — consistent across ALL endpoints
func (h *Handler) Create(c *fiber.Ctx) error {
    // ...
    if errors.Is(err, domain.ErrNotFound) {
        return NewProblemResponse(c, 404, "RESOURCE_NOT_FOUND", "The requested resource does not exist")
    }
    if errors.Is(err, domain.ErrInvalidInput) {
        return NewProblemResponse(c, 422, "VALIDATION_FAILED", err.Error())
    }
    return NewProblemResponse(c, 500, "INTERNAL_ERROR", "An unexpected error occurred")
}

// Swaggo annotation with error response schema documented
// @Failure 404 {object} ProblemDetails "Resource not found"
// @Failure 422 {object} ProblemDetails "Validation failed"
// @Failure 500 {object} ProblemDetails "Internal server error"
```

**Reference Implementation (BAD — Inconsistent Error Responses):**
```go
// BAD: Inconsistent error response formats across endpoints
// Handler A returns:
return c.Status(400).JSON(fiber.Map{"error": "invalid input"})

// Handler B returns a different structure:
return c.Status(400).JSON(fiber.Map{"message": "invalid input", "code": 400})

// Handler C returns yet another structure:
return c.Status(400).JSON(fiber.Map{"errors": []string{"field X is required"}})

// BAD: Free-text error messages only (no machine-readable codes)
return c.Status(422).JSON(fiber.Map{"error": "The email field is required and must be valid"})
// Client cannot programmatically distinguish error types — must parse human text

// BAD: No error response schema in Swaggo annotations
// @Failure 400 "Bad request"   // No response body schema defined
```

**Check Against Ring Standards For:**
1. (HARD GATE) Explicit nil checks with error returns instead of panic for validation per Ring standards
2. (HARD GATE) Named error variables (sentinel errors) per module following Ring error codes convention
3. (HARD GATE) No panic() in non-test production code
4. Proper error wrapping with %w
5. errors.Is/errors.As for error matching
6. No swallowed errors (_, err := ignored)
7. HTTP error responses follow Ring ErrorResponse structure from domain.md
8. RFC 7807 Problem Details format compliance — error responses MUST include: `type`, `title`, `status`, `detail`, `instance` fields
9. Consistent error response schema across all endpoints — every endpoint MUST return the same JSON error structure (no mixed formats)
10. Machine-readable error codes for programmatic client consumption — every error response MUST include a stable, enumerated `code` field (not free-text messages)
11. Error response examples documented in API annotations (Swaggo `@Failure` tags with response schema)

**Severity Ratings:**
- CRITICAL: panic() in production code paths (HARD GATE violation per Ring standards)
- CRITICAL: Swallowed errors in critical paths
- HIGH: Generic error messages without context
- HIGH: Error response format does not match Ring standards
- HIGH: Inconsistent error response format across endpoints (some return `{"error": "msg"}`, others `{"message": "msg", "code": "X"}`)
- MEDIUM: No RFC 7807 Problem Details compliance (error responses lack `type`, `title`, `status`, `detail`, `instance` structure)
- MEDIUM: Error codes not machine-readable (free-text error messages only, no stable enumerated codes for programmatic consumption)
- MEDIUM: Inconsistent error types across modules
- LOW: Missing error wrapping context
- LOW: Missing error response examples in API documentation (Swaggo `@Failure` annotations lack response body schema)

**Output Format:**
```
## Error Framework Audit Findings

### Summary
- Nil checks with error returns: X
- Panic calls in production: Y
- Swallowed errors: Z

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 3: Route Organization Auditor

```prompt
Audit route organization and handler structure for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Architecture Patterns" and "Directory Structure" sections from architecture.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/routes.go`, `**/handlers.go`, `internal/**/adapters/http/*.go`
- Keywords: `RegisterRoutes`, `protected(`, `fiber.Router`, `NewHandler`
- Standards-specific: `internal/{module}/adapters/`, `hexagonal`, `ports`

**Reference Implementation (GOOD):**
```go
// Centralized route registration
func RegisterRoutes(protected func(resource, action string) fiber.Router, handler *Handler) error {
    if handler == nil {
        return errors.New("handler is nil")
    }
    protected("resources", "create").Post("/v1/resources", handler.Create)
    protected("resources", "read").Get("/v1/resources", handler.List)
    protected("resources", "read").Get("/v1/resources/:id", handler.Get)
    return nil
}

// Handler constructor with validation
func NewHandler(deps ...interface{}) (*Handler, error) {
    if dep == nil {
        return nil, ErrNilDependency
    }
    return &Handler{...}, nil
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) Hexagonal structure: `internal/{module}/adapters/http/` per architecture.md
2. (HARD GATE) Centralized route registration per module
3. Handler constructors validate all dependencies
4. Consistent URL patterns (v1, kebab-case, plural resources) per Ring conventions
5. Authorization resource names are plural and match the route collection (for example, `/v1/resources` -> `protected("resources", ...)`)
6. Singular authorization resource names only appear for protected singleton/capability endpoints, with a local comment explaining the exception
7. All routes use protected() wrapper (no public endpoints without explicit exemption)
8. Clear separation: routes.go vs handlers.go per Ring directory structure

**Severity Ratings:**
- CRITICAL: Unprotected routes (missing auth middleware)
- CRITICAL: HARD GATE violation — project does not follow hexagonal architecture per Ring standards
- HIGH: Scattered route definitions
- HIGH: Authorization resource name is singular for a collection route
- MEDIUM: Handler accepts nil dependencies
- LOW: Inconsistent URL naming conventions

**Output Format:**
```
## Route Organization Audit Findings

### Summary
- Modules following hexagonal: X/Y
- Routes with protection: X/Y
- Handlers validating deps: X/Y

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 4: Bootstrap & Initialization Auditor

```prompt
Audit application bootstrap and initialization for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Bootstrap" section from bootstrap.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/main.go`, `**/init.go`, `**/bootstrap/*.go`
- Keywords: `InitServers`, `startupSucceeded`, `defer`, `cleanup`, `graceful`
- Standards-specific: `NewServiceBootstrap`, `staged initialization`

**Reference Implementation (GOOD):**
```go
// Staged initialization with cleanup
func InitServers(opts *Options) (*Service, error) {
    startupSucceeded := false
    defer func() {
        if !startupSucceeded {
            cleanupConnections(...)  // Only cleanup on failure
        }
    }()

    // 1. Load config
    cfg, err := loadConfig()
    if err != nil {
        return nil, fmt.Errorf("config: %w", err)
    }

    // 2. Initialize logger
    logger := initLogger(cfg)

    // 3. Initialize telemetry
    telemetry := initTelemetry(cfg, logger)

    // 4. Connect infrastructure (DB, Redis, MQ)
    db, err := connectDB(cfg)
    if err != nil {
        return nil, fmt.Errorf("database: %w", err)
    }

    // 5. Initialize modules in dependency order
    ...

    startupSucceeded = true
    return &Service{...}, nil
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) Staged initialization order per bootstrap.md (config -> logger -> telemetry -> infra)
2. (HARD GATE) Cleanup handlers for failed startup
3. (HARD GATE) Graceful shutdown support
4. Module initialization in dependency order per Ring bootstrap pattern
5. Error propagation (not just logging and continuing)
6. Production vs development mode handling

**Severity Ratings:**
- CRITICAL: No graceful shutdown (HARD GATE violation per Ring standards)
- CRITICAL: HARD GATE violation — bootstrap does not follow Ring staged initialization pattern
- HIGH: Resources not cleaned up on startup failure
- HIGH: Errors logged but not returned
- MEDIUM: Initialization order issues
- LOW: Missing development mode toggles

**Output Format:**
```
## Bootstrap Audit Findings

### Summary
- Graceful shutdown: Yes/No
- Cleanup on failure: Yes/No
- Staged initialization: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 5: Runtime Safety Auditor

```prompt
Audit pkg/runtime usage and panic handling for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Search Patterns:**
- Files: `**/runtime/*.go`, `**/recover*.go`, `**/*.go`
- Keywords: `RecoverAndLog`, `RecoverWithPolicy`, `InitPanicMetrics`, `SetProductionMode`
- Also search: `panic(`, `recover()` (manual usage)

**Reference Implementation (GOOD):**
```go
// Bootstrap initialization
runtime.InitPanicMetrics(telemetry.MetricsFactory)
if cfg.EnvName == "production" {
    runtime.SetProductionMode(true)
}

// In HTTP handlers
defer runtime.RecoverAndLogWithContext(ctx, logger, "module", "handler_name")

// In worker goroutines
defer runtime.RecoverWithPolicyAndContext(ctx, logger, "module", "worker", runtime.CrashProcess)

// In background jobs (should retry, not crash)
defer runtime.RecoverWithPolicyAndContext(ctx, logger, "module", "job", runtime.LogAndContinue)
```

**Check For:**
1. pkg/runtime initialized at startup
2. Production mode set based on environment
3. All goroutines have panic recovery
4. Appropriate recovery policies per context
5. Panic metrics enabled for alerting
6. No raw recover() without pkg/runtime

**Severity Ratings:**
- CRITICAL: Goroutines without panic recovery
- HIGH: Missing production mode setting
- HIGH: Raw recover() without proper handling
- MEDIUM: Inconsistent recovery policies
- LOW: Missing panic metrics

**Output Format:**
```
## Runtime Safety Audit Findings

### Summary
- Runtime initialized: Yes/No
- Handlers with recovery: X/Y
- Goroutines with recovery: X/Y

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 28: Core Dependencies & Frameworks Auditor

```prompt
Audit core dependency usage and framework compliance for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Sections 2 and 3 from core.md — "Core Dependency: lib-commons" and "Frameworks & Libraries"}
---END STANDARDS---

**Search Patterns:**
- Files: `go.mod`, `go.sum`, `**/utils/*.go`, `**/helpers/*.go`, `**/common/*.go`
- Keywords: `lib-commons`, `github.com/LerianStudio`, `go 1.`, `fiber`, `gorm`, `validator`
- Also search: Custom utility packages that may duplicate lib-commons functionality

**Reference Implementation (GOOD):**
```go
// go.mod with lib-commons v5 and required frameworks
module github.com/company/project

go 1.24

require (
    github.com/LerianStudio/lib-commons/v5 v5.x.y   // lib-commons present (resolve latest v5.x tag)
    github.com/gofiber/fiber/v2 v2.52.x               // Fiber v2
    gorm.io/gorm v1.25.x                              // GORM
    github.com/go-playground/validator/v10 v10.x.x     // Validator
    github.com/stretchr/testify v1.9.x                 // Testify
)
```

**Reference Implementation (BAD):**
```go
// BAD: Custom utilities that duplicate lib-commons
// internal/utils/database.go
func ConnectDB(dsn string) (*sql.DB, error) {
    // Custom connection logic duplicating lib-commons/mpostgres
}

// BAD: Custom telemetry wrapper duplicating lib-observability
// internal/common/tracing.go
func StartSpan(ctx context.Context, name string) (context.Context, trace.Span) {
    // Custom wrapper duplicating lib-observability/NewTrackingFromContext
}

// BAD: Missing lib-commons entirely
// go.mod without github.com/LerianStudio/lib-commons
```

**Check Against Ring Standards For:**
1. (HARD GATE) lib-commons v5 present in go.mod — this is mandatory per Ring standards
2. (HARD GATE) No custom utility packages that duplicate lib-commons functionality (check utils/, helpers/, common/)
3. Go version 1.24+ in go.mod
4. Fiber v2 framework present
5. GORM ORM present
6. go-playground/validator/v10 present
7. testify present for testing
8. No alternative libraries used for functionality already covered by lib-commons

**Severity Ratings:**
- CRITICAL: lib-commons not in go.mod (HARD GATE violation per Ring standards)
- CRITICAL: Custom utilities duplicating lib-commons or lib-observability functionality (HARD GATE violation)
- HIGH: Framework versions below Ring minimum requirements
- MEDIUM: Using alternative libraries for functionality covered by Ring stack
- LOW: Minor version discrepancies

**Output Format:**
```
## Core Dependencies & Frameworks Audit Findings

### Summary
- lib-commons v5 present: Yes/No
- Go version: X (minimum 1.24)
- Required frameworks present: X/Y
- Custom utility packages found: [list]
- lib-commons duplication detected: Yes/No

### Critical Issues
[file:line or go.mod] - Description

### Recommendations
1. ...
```
```

### Agent 29: Naming Conventions Auditor

```prompt
Audit naming conventions across the codebase for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Naming conventions from core.md section 5 (if exists) and JSON naming subsection from api-patterns.md section 1}
---END STANDARDS---

**Search Patterns:**
- Files: `**/*.go` for struct tags, `**/migrations/*.sql` for column names
- Keywords: `json:"`, `db:"`, `gorm:"`, `column:`, `CREATE TABLE`
- Also search: Query parameter handling for naming consistency

**Reference Implementation (GOOD):**
```go
// Go struct with correct naming conventions
type Account struct {
    ID          uuid.UUID `json:"id" gorm:"column:id"`
    DisplayName string    `json:"displayName" gorm:"column:display_name"`  // camelCase JSON, snake_case DB
    AccountType string    `json:"accountType" gorm:"column:account_type"`
    CreatedAt   time.Time `json:"createdAt" gorm:"column:created_at"`
}

// Query parameters use snake_case
// GET /v1/accounts?account_type=savings&created_after=2024-01-01

// SQL migration with snake_case columns
// CREATE TABLE accounts (
//     id UUID PRIMARY KEY,
//     display_name VARCHAR(255),
//     account_type VARCHAR(50),
//     created_at TIMESTAMP WITH TIME ZONE
// );
```

**Reference Implementation (BAD):**
```go
// BAD: Inconsistent JSON naming
type Account struct {
    ID          uuid.UUID `json:"id"`
    DisplayName string    `json:"display_name"`   // snake_case in JSON — wrong! Use camelCase
    AccountType string    `json:"account_type"`   // snake_case in JSON — wrong! Use camelCase
    CreatedAt   time.Time `json:"CreatedAt"`      // PascalCase — wrong!
}

// BAD: Mixed naming in query params
// GET /v1/accounts?accountType=savings&created_after=2024-01-01
```

**Check Against Ring Standards For:**
1. snake_case for database column names in migrations and GORM tags
2. camelCase for JSON response body fields (json:"fieldName")
3. snake_case for query parameters
4. PascalCase for Go exported types and functions
5. camelCase for Go unexported fields and variables
6. Consistent naming convention within each context (no mixing)

**Severity Ratings:**
- HIGH: Inconsistent JSON field naming across response DTOs (mix of conventions)
- MEDIUM: Query params not using snake_case
- MEDIUM: Database columns not using snake_case
- LOW: Minor naming inconsistencies within a single file

**Output Format:**
```
## Naming Conventions Audit Findings

### Summary
- JSON fields audited: X
- Using camelCase JSON: Y/X
- DB columns using snake_case: Y/Z
- Query params using snake_case: Y/Z
- Naming convention violations: N

### Issues by Convention
#### JSON Naming
[file:line] - Field "display_name" should be "displayName"

#### Database Naming
[file:line] - Column "displayName" should be "display_name"

#### Query Parameter Naming
[file:line] - Param "accountType" should be "account_type"

### Recommendations
1. ...
```
```

### Agent 30: Domain Modeling Auditor

```prompt
Audit domain modeling patterns for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "ToEntity/FromEntity" section 9 from domain.md and "Always-Valid Domain Model" section 21 from domain-modeling.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/domain/*.go`, `**/entity/*.go`, `**/model/*.go`, `**/value_objects/*.go`
- Keywords: `ToEntity`, `FromEntity`, `NewXxx`, `IsValid()`, `private fields`
- Also search: `**/adapters/**/*.go` for mapping patterns

**Reference Implementation (GOOD):**
```go
// Always-valid domain model with private fields and constructor
type Account struct {
    id          uuid.UUID   // Private fields
    name        string
    accountType AccountType
    status      Status
    createdAt   time.Time
}

// Constructor enforces invariants
func NewAccount(name string, accountType AccountType) (*Account, error) {
    if name == "" {
        return nil, ErrNameRequired
    }
    if !accountType.IsValid() {
        return nil, ErrInvalidAccountType
    }
    return &Account{
        id:          uuid.New(),
        name:        name,
        accountType: accountType,
        status:      StatusActive,
        createdAt:   time.Now(),
    }, nil
}

// Exported getters (no setters for immutable fields)
func (a *Account) ID() uuid.UUID       { return a.id }
func (a *Account) Name() string        { return a.name }
func (a *Account) Status() Status      { return a.status }

// ToEntity/FromEntity mapping in adapters
func (dto *CreateAccountDTO) ToEntity() (*domain.Account, error) {
    return domain.NewAccount(dto.Name, domain.AccountType(dto.Type))
}

func FromEntity(account *domain.Account) *AccountResponse {
    return &AccountResponse{
        ID:     account.ID().String(),
        Name:   account.Name(),
        Status: string(account.Status()),
    }
}
```

**Reference Implementation (BAD):**
```go
// BAD: Domain model with exported mutable fields and no constructor
type Account struct {
    ID          uuid.UUID `json:"id"`           // Exported + mutable!
    Name        string    `json:"name"`         // Can be set to "" directly
    AccountType string    `json:"account_type"` // No type safety
    Status      string    `json:"status"`       // No validation
}

// BAD: Direct field access without validation
account := &Account{Name: ""}  // Invalid state allowed!

// BAD: No ToEntity/FromEntity — DTOs used directly as domain models
func (h *Handler) Create(c *fiber.Ctx) error {
    var account Account
    c.BodyParser(&account)
    repo.Save(ctx, &account)  // DTO goes straight to persistence!
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) Domain models use private fields with exported getters per domain-modeling.md always-valid pattern
2. (HARD GATE) Constructors (NewXxx) enforce invariants — no invalid domain objects can be created
3. (HARD GATE) ToEntity/FromEntity mapping patterns in adapters per domain.md section 9
4. Value objects have IsValid() methods
5. No direct field access on domain models from outside the package
6. DTOs are separate from domain models (not the same struct)
7. Consistent domain modeling across all bounded contexts

**Severity Ratings:**
- CRITICAL: Domain models with exported mutable fields and no constructor (HARD GATE violation per Ring standards)
- CRITICAL: DTOs used directly as domain models (no ToEntity/FromEntity)
- HIGH: Missing ToEntity/FromEntity in adapters (HARD GATE violation)
- MEDIUM: Inconsistent domain modeling across modules
- MEDIUM: Value objects without IsValid()
- LOW: Minor modeling inconsistencies

**Output Format:**
```
## Domain Modeling Audit Findings

### Summary
- Domain models found: X
- Using always-valid pattern: Y/X
- With constructors (NewXxx): Y/X
- ToEntity/FromEntity present: Y/Z adapters
- Value objects with IsValid: Y/Z

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 35: Nil/Null Safety Auditor

```prompt
Audit nil/null pointer safety and dereference risks across the codebase for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Nil safety patterns — no dedicated standards file; patterns derived from ring:nil-reviewer agent}
---END STANDARDS---

**Search Patterns:**
- Go files: `**/*.go` — search for type assertions, map access, pointer receivers, channel operations, interface checks
- TypeScript files: `**/*.ts`, `**/*.tsx` — search for nullable access, optional chaining, destructuring, Promise handling
- Keywords (Go): `.(*`, `.(type)`, `map[`, `<-`, `func (`, `err != nil`, `if err`, `interface{}`
- Keywords (TS): `?.`, `!.`, `as `, `.find(`, `.get(`, `undefined`, `null`

**Go Nil Safety Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| Type assertion without ok | CRITICAL | `value := x.(Type)` — panics if wrong type. MUST use `value, ok := x.(Type)` |
| Nil map write | CRITICAL | Writing to an uninitialized map panics. Check `make(map[...])` before writes |
| Nil receiver method call | CRITICAL | `ptr.Method()` when ptr could be nil. Trace all pointer receivers |
| Nil channel operations | CRITICAL | Send/receive on nil channel blocks forever. Check channel initialization |
| Nil function call | CRITICAL | Calling a nil function variable panics |
| Unguarded map read | HIGH | `value := m[key]` without `, ok` check — returns zero value silently |
| Nil interface comparison | HIGH | Interface holding nil concrete value is NOT == nil. Check with reflect |
| Error-then-use | HIGH | Using return value when `err != nil` — value may be nil/invalid |
| Nil slice in API response | MEDIUM | `var items []T` serializes as JSON `null`, not `[]`. Use `make([]T, 0)` |
| Nil map in API response | MEDIUM | `var m map[K]V` serializes as JSON `null`, not `{}`. Use `make(map[K]V)` |

**TypeScript Null Safety Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| Missing null/undefined check | HIGH | Accessing properties on potentially null values without guards |
| Object destructuring on nullable | HIGH | `const { a } = maybeNull` — throws if null/undefined |
| Array index without bounds | HIGH | `arr[i]` without checking `arr.length > i` |
| Promise rejection unhandled | HIGH | Missing `.catch()` or try/catch around await |
| Array.find() unchecked | MEDIUM | Returns `undefined` if not found — must check before use |
| Map.get() unchecked | MEDIUM | Returns `undefined` if key missing — must check before use |
| Optional chaining misuse | MEDIUM | `a?.b.c` — protects `a` but not `b`. Should be `a?.b?.c` |
| Non-null assertion abuse | MEDIUM | Excessive non-null assertion operator (!) bypasses TypeScript's null checks |

**Tracing Methodology (MANDATORY — do not skip):**
1. **Identify nil sources**: Function returns that can be nil/null, map lookups, type assertions, interface values, external API responses
2. **Trace forward**: Follow nil-capable values through assignments, function arguments, struct/object fields
3. **Trace backward**: For each dereference point, trace all callers to verify they handle nil returns
4. **Find dereference points**: Method calls, field access, index access, channel operations on potentially nil values

**Reference Implementation (GOOD — Go):**
```go
// GOOD: Type assertion with ok check
value, ok := x.(MyType)
if !ok {
    return fmt.Errorf("unexpected type: %T", x)
}

// GOOD: Map access with ok check
if conn, ok := pools[tenantID]; ok {
    return conn, nil
}

// GOOD: Nil-safe API response
func (s *Service) List(ctx context.Context) ([]Item, error) {
    items := make([]Item, 0) // never nil — serializes as []
    // ...
    return items, nil
}

// GOOD: Error-then-use pattern
result, err := repo.FindByID(ctx, id)
if err != nil {
    return nil, err // do NOT use result
}
// Safe to use result here
```

**Reference Implementation (BAD — Go):**
```go
// BAD: Type assertion without ok — PANICS on wrong type
value := x.(MyType)

// BAD: Nil map write — PANICS
var m map[string]int
m["key"] = 1

// BAD: Error-then-use — result may be nil
result, err := repo.FindByID(ctx, id)
log.Info("found", "name", result.Name) // PANIC if err != nil
if err != nil {
    return nil, err
}

// BAD: Nil slice in response — JSON null instead of []
var items []Item
return items, nil // serializes as null
```

**Reference Implementation (GOOD — TypeScript):**
```typescript
// GOOD: Null check before access
const user = await findUser(id);
if (!user) {
    throw new NotFoundException(`User ${id} not found`);
}
// Safe to access user.name here

// GOOD: Array.find with guard
const item = items.find(i => i.id === targetId);
if (!item) {
    return { error: 'Item not found' };
}

// GOOD: Optional chaining — full chain
const city = user?.address?.city ?? 'Unknown';
```

**Reference Implementation (BAD — TypeScript):**
```typescript
// BAD: No null check — crashes if findUser returns null
const user = await findUser(id);
console.log(user.name); // TypeError if null

// BAD: Partial optional chaining
const city = user?.address.city; // protects user but not address

// BAD: Destructuring nullable
const { name, email } = await findUser(id); // throws if null
```

**Check Against Standards For:**
1. (CRITICAL) All type assertions use the two-value `value, ok` form (Go)
2. (CRITICAL) No writes to uninitialized maps
3. (CRITICAL) All pointer receivers are nil-safe or callers guarantee non-nil
4. (CRITICAL) No nil channel operations
5. (HIGH) All map reads use `, ok` form or have prior existence guarantee
6. (HIGH) Return values are not used after error check fails (error-then-use)
7. (HIGH) Nullable values are checked before property access (TypeScript)
8. (HIGH) Object destructuring only on guaranteed non-null values (TypeScript)
9. (MEDIUM) API responses use initialized slices/maps (Go: `make()`, not `var`)
10. (MEDIUM) Optional chaining covers full property chain (TypeScript)
11. (MEDIUM) `Array.find()` and `Map.get()` results are checked before use (TypeScript)
12. (LOW) Non-null assertion operator (!) is used sparingly with justification (TypeScript)

**Severity Ratings:**
- CRITICAL: Type assertion without ok (panics), nil map write (panics), nil receiver call (panics), nil channel (deadlocks), nil function call (panics)
- HIGH: Unguarded map read (silent wrong data), error-then-use (nil dereference), nullable property access (TypeError), unhandled Promise rejection
- MEDIUM: Nil slice/map in API response (JSON null vs []/{}), partial optional chaining, unchecked find()/get(), non-null assertion abuse
- LOW: Missing nil documentation on exported functions, unnecessary nil checks on guaranteed non-nil values

**Output Format:**
```
## Nil/Null Safety Audit Findings

### Summary
- Language(s) detected: {Go / TypeScript / Both}
- Type assertions (Go): X total, Y unsafe (without ok)
- Map operations (Go): X writes, Y to potentially nil maps
- Pointer receivers (Go): X total, Y without nil safety
- Nullable access (TS): X unguarded property accesses
- API response consistency: X nil slices/maps found

### Critical Issues
[file:line] - Description (pattern: {pattern name})

### High Issues
[file:line] - Description (pattern: {pattern name})

### Medium Issues
[file:line] - Description

### Low Issues
[file:line] - Description

### Nil Risk Trace
{For each CRITICAL/HIGH issue, show the trace: source → assignments → dereference point}

### Recommendations
1. ...
```
```

### Agent 38: API Versioning Auditor

```prompt
Audit API versioning strategy, backward compatibility practices, and deprecation management across the codebase for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: API versioning patterns — no dedicated standards file; patterns derived from REST API design best practices and production-readiness standards}
---END STANDARDS---

**Search Patterns:**
- Route definitions (Go): `**/*.go` — search for router groups, path prefixes, handler registrations
- Route definitions (TS): `**/*.ts`, `**/*.tsx` — search for route decorators, Express/Fastify route registrations, controller paths
- API specs: `**/openapi*.yaml`, `**/openapi*.json`, `**/swagger*.yaml`, `**/swagger*.json`, `**/*.proto`
- Config/Gateway: `**/nginx*.conf`, `**/traefik*.yaml`, `**/gateway*.yaml`, `**/kong*.yaml`
- Keywords (versioning): `/v1/`, `/v2/`, `/v3/`, `/api/v`, `version`, `api-version`, `Accept-Version`, `X-API-Version`
- Keywords (deprecation): `deprecated`, `Deprecated`, `@deprecated`, `Sunset`, `sunset`, `migration`, `breaking`
- Keywords (routing): `Group`, `Router`, `Route`, `Controller`, `@Get`, `@Post`, `@Put`, `@Delete`, `HandleFunc`, `Handle`, `mux`, `chi`, `gin`, `echo`, `fiber`
- Keywords (compatibility): `breaking`, `backward`, `compatible`, `migration`, `changelog`

**API Versioning Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| No versioning strategy | HIGH | API endpoints with no version prefix or header — breaking changes have no migration path |
| Multiple versions without deprecation | HIGH | `/v1/` and `/v2/` both active with no deprecation notice or sunset timeline on v1 |
| Inconsistent versioning | MEDIUM | Some endpoints use `/v1/` prefix, others are unversioned — confusing for consumers |
| No Sunset headers on deprecated endpoints | MEDIUM | Deprecated API versions return responses without `Sunset` or `Deprecation` headers |
| No version documentation | LOW | API version exists but no changelog or migration guide documents the differences |
| No version negotiation | LOW | No mechanism for clients to request specific version via headers |
| Mixed versioning strategies | MEDIUM | Some endpoints use URL versioning (`/v1/`), others use header versioning — inconsistent approach |
| Deprecated code still in main paths | MEDIUM | Code marked `@deprecated` or `// Deprecated` is still in active request handling paths |

**Go-Specific Patterns:**

| Pattern | What to Look For |
|---------|------------------|
| Router group versioning | `r.Group("/v1")`, `chi.Route("/v1/", ...)`, `gin.Group("/v1")` |
| Handler deprecation | Comments `// Deprecated:` on handler functions per Go convention |
| Version constants | `const APIVersion = "v1"`, version in package names |
| gRPC versioning | Package naming: `package api.v1`, `package api.v2` in `.proto` files |

**TypeScript-Specific Patterns:**

| Pattern | What to Look For |
|---------|------------------|
| Controller versioning | `@Controller('v1/users')`, route prefix decorators |
| Express route groups | `app.use('/v1', v1Router)`, `app.use('/v2', v2Router)` |
| Deprecation decorators | `@Deprecated()`, `@ApiDeprecated()`, JSDoc `@deprecated` tags |
| OpenAPI version tags | `info.version` in OpenAPI spec, version tags on operations |

**Versioning Strategy Analysis (MANDATORY — do not skip):**
1. **Identify strategy**: URL path (`/v1/`), header (`Accept-Version`), query param (`?version=1`), content negotiation, or none
2. **Verify consistency**: All endpoints MUST follow the same versioning strategy
3. **Check all routes**: Map all registered routes and categorize as versioned or unversioned
4. **Identify deprecated versions**: Find which versions are marked for deprecation and their sunset timeline
5. **Check backward compatibility**: Look for breaking changes within a single version (field removals, type changes, required field additions)

**Reference Implementation (GOOD — Go):**
```go
// GOOD: Consistent URL path versioning with router groups
func SetupRoutes(r chi.Router) {
    r.Route("/v1", func(r chi.Router) {
        r.Get("/users", v1.ListUsers)
        r.Post("/users", v1.CreateUser)
        r.Get("/users/{id}", v1.GetUser)
    })

    r.Route("/v2", func(r chi.Router) {
        r.Get("/users", v2.ListUsers)     // Enhanced response format
        r.Post("/users", v2.CreateUser)    // New required fields
        r.Get("/users/{id}", v2.GetUser)
    })
}

// GOOD: Sunset header on deprecated version
func V1DeprecationMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Sunset", "Sat, 01 Mar 2025 00:00:00 GMT")
        w.Header().Set("Deprecation", "true")
        w.Header().Set("Link", `</v2/docs>; rel="successor-version"`)
        next.ServeHTTP(w, r)
    })
}

// GOOD: Version constant and documentation
const (
    APIVersionV1 = "v1" // Deprecated: Use v2. Sunset date: 2025-03-01
    APIVersionV2 = "v2" // Current stable version
)
```

**Reference Implementation (BAD — Go):**
```go
// BAD: No versioning — breaking changes have no migration path
func SetupRoutes(r chi.Router) {
    r.Get("/users", ListUsers)       // No version prefix
    r.Post("/users", CreateUser)     // If response format changes, all clients break
    r.Get("/users/{id}", GetUser)
}

// BAD: Mixed versioning — some versioned, some not
func SetupRoutes(r chi.Router) {
    r.Get("/users", ListUsers)           // Unversioned
    r.Get("/v2/users", v2.ListUsers)     // Versioned — inconsistent!
    r.Get("/health", HealthCheck)        // Unversioned (acceptable for infra endpoints)
}

// BAD: Deprecated version with no sunset notice
r.Route("/v1", func(r chi.Router) {
    // No deprecation headers, no documentation, no sunset date
    r.Get("/users", v1.ListUsers)
})
```

**Reference Implementation (GOOD — TypeScript):**
```typescript
// GOOD: Versioned controllers with NestJS
@Controller('v1/users')
export class UsersV1Controller {
  /** @deprecated Use v2/users instead. Sunset: 2025-03-01 */
  @Get()
  @Header('Sunset', 'Sat, 01 Mar 2025 00:00:00 GMT')
  @Header('Deprecation', 'true')
  async listUsers() { /* ... */ }
}

@Controller('v2/users')
export class UsersV2Controller {
  @Get()
  async listUsers() { /* ... */ }
}

// GOOD: Express versioned route groups
app.use('/v1', deprecationMiddleware, v1Router);
app.use('/v2', v2Router);

function deprecationMiddleware(req, res, next) {
  res.set('Sunset', 'Sat, 01 Mar 2025 00:00:00 GMT');
  res.set('Deprecation', 'true');
  next();
}
```

**Reference Implementation (BAD — TypeScript):**
```typescript
// BAD: No versioning
@Controller('users')
export class UsersController {
  @Get()
  async listUsers() { /* ... */ }
}

// BAD: Breaking change in same version (field renamed without new version)
// Before: { "userName": "..." }
// After:  { "name": "..." }  // Clients break!
```

**Check Against Standards For:**
1. (HIGH) A versioning strategy exists and is documented (URL path, header, or content negotiation)
2. (HIGH) Deprecated API versions have sunset dates and deprecation notices
3. (MEDIUM) All API endpoints follow the same versioning strategy consistently
4. (MEDIUM) Deprecated endpoints return `Sunset` and/or `Deprecation` headers
5. (MEDIUM) No mixed versioning approaches (URL vs header) within the same API
6. (MEDIUM) Breaking changes are only introduced in new versions, not within existing versions
7. (LOW) API changelog or migration guide exists for version transitions
8. (LOW) Version negotiation mechanism is available for clients
9. (LOW) Infrastructure endpoints (/health, /ready, /metrics) are excluded from versioning (acceptable)

**Severity Ratings:**
- HIGH: No versioning strategy at all (breaking changes break all consumers with no migration path), multiple active versions with no deprecation or sunset timeline (consumers don't know which to use or when old versions will be removed)
- MEDIUM: Inconsistent versioning across endpoints (confusing API surface), no Sunset/Deprecation headers on deprecated versions (consumers unaware of upcoming removal), mixed versioning strategies (URL and header in same API), breaking changes within a single version (contract violation), deprecated code still actively serving without notice
- LOW: Missing version documentation or changelog (consumers must guess differences), no version negotiation mechanism (reduced client flexibility), infrastructure endpoints not versioned (this is actually acceptable)

**Output Format:**
```
## API Versioning Audit Findings

### Summary
- Versioning strategy detected: {URL path / Header / Query param / Content negotiation / None / Mixed}
- API versions found: {v1, v2, ...} or "No versioning detected"
- Total endpoints: X
- Versioned endpoints: Y/X
- Unversioned endpoints: Z/X (list if infrastructure: /health, /metrics, etc.)
- Deprecated versions: {list with sunset dates, or "none marked"}
- Breaking changes in same version: X found

### Route Map
| Version | Endpoints | Status | Sunset Date |
|---------|-----------|--------|-------------|
| v1 | X endpoints | Deprecated / Active | YYYY-MM-DD / N/A |
| v2 | Y endpoints | Active | N/A |
| unversioned | Z endpoints | Active | N/A |

### High Issues
[file:line] - Description
  Evidence: {code snippet showing the issue}
  Impact: {what happens to API consumers}
  Fix: {specific remediation}

### Medium Issues
[file:line] - Description
  Evidence: {code snippet}
  Fix: {specific remediation}

### Low Issues
[file:line] - Description

### Versioning Consistency Check
- Strategy: {consistent / inconsistent}
- Deviations: {list endpoints that don't follow the primary strategy}

### Recommendations
1. ...
```
```

### Agent 42: Resource Leak Prevention Auditor

```prompt
Audit resource leak risks including unclosed handles, connection leaks, and cleanup failures for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Resource leak patterns — no dedicated standards file; patterns derived from Go/TypeScript runtime behavior and production failure analysis}
---END STANDARDS---

**Search Patterns:**
- Go files: `**/*.go` — search for HTTP response bodies, database rows/connections, file handles, tickers, timers, context cancellation
- TypeScript files: `**/*.ts`, `**/*.tsx` — search for stream cleanup, event listeners, AbortController, finally blocks, using declarations
- Keywords (Go): `resp.Body`, `rows.Close`, `rows.Next`, `tx.Rollback`, `tx.Commit`, `file.Close`, `ticker.Stop`, `timer.Stop`, `context.WithCancel`, `context.WithTimeout`, `defer`, `go func`
- Keywords (TS): `finally`, `addEventListener`, `removeEventListener`, `AbortController`, `.destroy()`, `.close()`, `.end()`, `createReadStream`, `createWriteStream`, `using`, `Symbol.dispose`

**Go Resource Leak Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| HTTP body not closed | CRITICAL | `http.Get`, `client.Do` without `defer resp.Body.Close()` — connection pool exhaustion |
| DB rows not closed | CRITICAL | `db.Query` / `db.QueryContext` without `defer rows.Close()` — connection pool exhaustion |
| DB rows not closed on error | CRITICAL | `rows.Close()` in happy path only — error branch leaks connection |
| File handle not closed | HIGH | `os.Open`, `os.Create` without `defer file.Close()` — fd exhaustion under load |
| Context not propagated | HIGH | `go func()` spawned without parent context — cannot cancel child goroutines |
| Ticker/timer not stopped | HIGH | `time.NewTicker`, `time.NewTimer` in goroutine without `defer ticker.Stop()` — memory leak |
| Transaction not rolled back | HIGH | `db.Begin` without `defer tx.Rollback()` — connection held on error path |
| Defer after error check | MEDIUM | `defer resp.Body.Close()` before checking `err != nil` — panics on nil resp |
| Defer ordering (LIFO) | MEDIUM | Defers execute in LIFO order — wrong order causes cleanup sequence issues |
| Channel not closed | MEDIUM | Producer goroutine exits without closing channel — consumer goroutine leaks |

**TypeScript Resource Leak Patterns to Check:**

| Pattern | Risk Level | What to Look For |
|---------|:----------:|------------------|
| Stream not closed on error | CRITICAL | `createReadStream` / `createWriteStream` without error-path cleanup |
| Connection not closed | CRITICAL | Database/Redis connections opened but not closed in error paths |
| Event listener not removed | MEDIUM | `addEventListener` without corresponding `removeEventListener` on cleanup/unmount |
| AbortController not used | MEDIUM | Long-running fetch/operations without AbortController for cancellation |
| No finally for cleanup | MEDIUM | Resource cleanup in try block only — skipped on exception |
| Interval not cleared | HIGH | `setInterval` without corresponding `clearInterval` — memory leak |
| Missing using declaration | LOW | Resources that implement `Symbol.dispose` not using `using` keyword (TC39 proposal) |

**Resource Leak Tracing Methodology (MANDATORY — do not skip):**
1. **Find resource acquisitions**: Scan for all `open`, `create`, `new`, `begin`, `dial`, `connect` calls
2. **Trace cleanup path**: For each acquisition, verify a corresponding `close`, `stop`, `rollback`, `release` exists
3. **Check error paths**: Verify cleanup happens in error branches, not just happy path
4. **Check goroutine context**: For each `go func()`, verify parent context is passed and cancellation propagates
5. **Check defer placement**: Verify `defer` is called AFTER error check on the acquisition, not before
6. **Check defer ordering**: Verify LIFO ordering does not cause incorrect cleanup sequence

**Reference Implementation (GOOD — Go):**
```go
// GOOD: HTTP response body closed immediately after error check
resp, err := http.Get(url)
if err != nil {
    return nil, fmt.Errorf("fetching %s: %w", url, err)
}
defer resp.Body.Close() // after error check — resp is guaranteed non-nil

// GOOD: Database rows closed with defer
rows, err := db.QueryContext(ctx, query, args...)
if err != nil {
    return nil, fmt.Errorf("querying: %w", err)
}
defer rows.Close() // closed on ALL exit paths

// GOOD: Transaction with deferred rollback (safe even after commit)
tx, err := db.BeginTx(ctx, nil)
if err != nil {
    return err
}
defer tx.Rollback() // no-op after successful commit

if err := tx.Exec(ctx, stmt); err != nil {
    return err // rollback will execute via defer
}
return tx.Commit()

// GOOD: Context propagated to goroutine
ctx, cancel := context.WithCancel(parentCtx)
defer cancel()

go func() {
    select {
    case <-ctx.Done():
        return // goroutine exits when parent cancels
    case msg := <-ch:
        process(msg)
    }
}()

// GOOD: Ticker stopped in goroutine
func (s *Service) StartPolling(ctx context.Context) {
    ticker := time.NewTicker(30 * time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            s.poll(ctx)
        }
    }
}
```

**Reference Implementation (BAD — Go):**
```go
// BAD: HTTP body never closed — connection pool exhaustion
resp, err := http.Get(url)
if err != nil {
    return nil, err
}
// missing: defer resp.Body.Close()
body, _ := io.ReadAll(resp.Body) // body open forever

// BAD: defer before error check — panics on nil resp
resp, err := http.Get(url)
defer resp.Body.Close() // PANIC if err != nil (resp is nil)
if err != nil {
    return nil, err
}

// BAD: rows.Close() only in happy path — leaks on error
rows, err := db.QueryContext(ctx, query)
if err != nil {
    return nil, err
}
for rows.Next() {
    if err := rows.Scan(&item); err != nil {
        return nil, err // rows NOT closed!
    }
    items = append(items, item)
}
rows.Close() // only reached on success

// BAD: Context not propagated — goroutine cannot be cancelled
go func() {
    for {
        data := fetchData() // runs forever, ignores parent context
        process(data)
        time.Sleep(time.Minute)
    }
}()

// BAD: Ticker in goroutine never stopped — memory leak
go func() {
    ticker := time.NewTicker(time.Second)
    // missing: defer ticker.Stop()
    for range ticker.C {
        doWork()
    }
}()
```

**Reference Implementation (GOOD — TypeScript):**
```typescript
// GOOD: finally block ensures cleanup
async function processFile(path: string): Promise<void> {
    const stream = fs.createReadStream(path);
    try {
        await pipeline(stream, transformer, output);
    } finally {
        stream.destroy(); // cleanup regardless of success/failure
    }
}

// GOOD: Event listener removed on unmount
useEffect(() => {
    const handler = (e: Event) => handleResize(e);
    window.addEventListener('resize', handler);
    return () => {
        window.removeEventListener('resize', handler); // cleanup on unmount
    };
}, []);

// GOOD: AbortController for cancellable fetch
async function fetchWithTimeout(url: string, timeoutMs: number): Promise<Response> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);
    try {
        return await fetch(url, { signal: controller.signal });
    } finally {
        clearTimeout(timeout);
    }
}

// GOOD: Interval cleared on cleanup
useEffect(() => {
    const intervalId = setInterval(() => pollData(), 5000);
    return () => clearInterval(intervalId);
}, []);
```

**Reference Implementation (BAD — TypeScript):**
```typescript
// BAD: No finally — stream stays open on error
async function processFile(path: string): Promise<void> {
    const stream = fs.createReadStream(path);
    await pipeline(stream, transformer, output); // if throws, stream leaks
}

// BAD: Event listener never removed — memory leak
useEffect(() => {
    window.addEventListener('resize', handleResize);
    // missing cleanup return
}, []);

// BAD: setInterval never cleared
useEffect(() => {
    setInterval(() => pollData(), 5000);
    // missing clearInterval — runs forever even after unmount
}, []);

// BAD: No AbortController — fetch cannot be cancelled
async function fetchData(url: string): Promise<Response> {
    return fetch(url); // hangs if server is slow, no way to cancel
}
```

**Check Against Standards For:**
1. (CRITICAL) All HTTP response bodies are closed with `defer resp.Body.Close()` after error check (Go)
2. (CRITICAL) All database rows are closed with `defer rows.Close()` — including error paths (Go)
3. (CRITICAL) Streams and connections are closed in error paths (TypeScript)
4. (HIGH) File handles are closed with `defer file.Close()` (Go) or finally/using (TypeScript)
5. (HIGH) Context is propagated to all spawned goroutines (Go)
6. (HIGH) Tickers and timers are stopped with `defer ticker.Stop()` in goroutines (Go)
7. (HIGH) Transactions use `defer tx.Rollback()` before any operations (Go)
8. (HIGH) `setInterval` has corresponding `clearInterval` on cleanup (TypeScript)
9. (MEDIUM) `defer` is placed AFTER error check, not before (Go)
10. (MEDIUM) Event listeners are removed on component unmount (TypeScript)
11. (MEDIUM) AbortController is used for cancellable long-running operations (TypeScript)
12. (MEDIUM) Channel producers close channels when done (Go)
13. (LOW) Defer ordering (LIFO) does not cause incorrect cleanup sequence (Go)

**Severity Ratings:**
- CRITICAL: HTTP response body never closed (connection pool exhaustion), database rows/connections not closed on error paths (connection pool exhaustion), streams not closed on error (fd exhaustion)
- HIGH: File handles not closed (fd exhaustion under load), context not propagated to goroutines (cannot cancel), tickers/timers not stopped (memory leak), transactions without deferred rollback (connection held), intervals not cleared (memory leak)
- MEDIUM: Defer before error check (nil pointer panic), event listeners not removed on unmount (memory leak), no AbortController for fetch (cannot cancel), unclosed channels (goroutine leak)
- LOW: Defer ordering issues (wrong cleanup sequence), redundant defer on auto-closed resources, missing using declaration for disposable resources

**Output Format:**
```
## Resource Leak Prevention Audit Findings

### Summary
- HTTP response bodies: X found, Y properly closed
- Database rows/connections: X queries, Y with defer rows.Close()
- File handles: X opens, Y with defer/finally close
- Goroutine context propagation: X goroutines, Y with parent context
- Tickers/timers: X created, Y with defer Stop()
- Event listeners (TS): X added, Y with cleanup
- Intervals (TS): X set, Y with clearInterval

### Critical Issues
[file:line] - Description (resource type: {type}, leak risk: {description})

### High Issues
[file:line] - Description (resource type: {type})

### Medium Issues
[file:line] - Description

### Low Issues
[file:line] - Description

### Resource Lifecycle Trace
{For each CRITICAL/HIGH issue: acquisition point → expected cleanup → actual cleanup (or missing)}

### Recommendations
1. ...
```
```
