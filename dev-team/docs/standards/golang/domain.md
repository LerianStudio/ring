# Go Standards - Domain Patterns

> **Module:** domain.md | **Sections:** §9-12 | **Parent:** [index.md](index.md)

This module covers data transformation, error handling, and function design.

---

## Table of Contents

| #   | Section                                                                                       | Description                                |
| --- | --------------------------------------------------------------------------------------------- | ------------------------------------------ |
| 1   | [Data Transformation: ToEntity/FromEntity](#data-transformation-toentityfromentity-mandatory) | Database model to domain entity conversion |
| 2   | [Error Codes Convention](#error-codes-convention-mandatory)                                   | Service-prefixed error codes               |
| 3   | [Error Handling](#error-handling)                                                             | Error wrapping and checking rules          |
| 4   | [Exit/Fatal Location Rules](#exitfatal-location-rules-mandatory)                              | Where exit/fatal/panic is allowed          |
| 5   | [Function Design](#function-design-mandatory)                                                 | Single responsibility principle            |
| 6   | [File Organization](#file-organization-mandatory)                                             | File-level single responsibility           |

---

## Data Transformation: ToEntity/FromEntity (MANDATORY)

All database models **MUST** implement transformation methods to/from domain entities.

### Pattern

```go
// internal/adapters/postgres/user/user.postgresql.go

// UserPostgreSQLModel is the database representation
type UserPostgreSQLModel struct {
    ID        string         `db:"id"`
    Email     string         `db:"email"`
    Name      string         `db:"name"`
    Status    string         `db:"status"`
    CreatedAt time.Time      `db:"created_at"`
    UpdatedAt time.Time      `db:"updated_at"`
    DeletedAt sql.NullTime   `db:"deleted_at"`
}

// ToEntity converts database model to domain entity
func (m *UserPostgreSQLModel) ToEntity() *domain.User {
    var deletedAt *time.Time
    if m.DeletedAt.Valid {
        deletedAt = &m.DeletedAt.Time
    }

    return &domain.User{
        ID:        domain.UserID(m.ID),
        Email:     domain.Email(m.Email),
        Name:      m.Name,
        Status:    domain.UserStatus(m.Status),
        CreatedAt: m.CreatedAt,
        UpdatedAt: m.UpdatedAt,
        DeletedAt: deletedAt,
    }
}

// FromEntity converts domain entity to database model
func (m *UserPostgreSQLModel) FromEntity(u *domain.User) {
    m.ID = string(u.ID)
    m.Email = string(u.Email)
    m.Name = u.Name
    m.Status = string(u.Status)
    m.CreatedAt = u.CreatedAt
    m.UpdatedAt = u.UpdatedAt
    if u.DeletedAt != nil {
        m.DeletedAt = sql.NullTime{Time: *u.DeletedAt, Valid: true}
    }
}
```

### Why This Matters

- **Layer isolation**: Domain doesn't know about database concerns
- **Testability**: Domain entities can be tested without database
- **Flexibility**: Database schema can change without affecting domain
- **Type safety**: Explicit conversions prevent accidental mixing

---

## Error Codes Convention (MANDATORY)

Each service **MUST** define error codes with a service-specific prefix.

### Service Prefixes

| Service     | Prefix | Example  |
| ----------- | ------ | -------- |
| Lerian      | LRN    | LRN-0001 |
| Plugin-Fees | FEE    | FEE-0001 |
| Plugin-Auth | AUT    | AUT-0001 |
| Platform    | PLT    | PLT-0001 |

### Error Code Structure

```go
// pkg/constant/errors.go
package constant

const (
    ErrCodeInvalidInput     = "PLT-0001"
    ErrCodeNotFound         = "PLT-0002"
    ErrCodeUnauthorized     = "PLT-0003"
    ErrCodeForbidden        = "PLT-0004"
    ErrCodeConflict         = "PLT-0005"
    ErrCodeInternalError    = "PLT-0006"
    ErrCodeValidationFailed = "PLT-0007"
)

// Error definitions with messages
var (
    ErrInvalidInput = &BusinessError{
        Code:    ErrCodeInvalidInput,
        Message: "Invalid input provided",
    }
    ErrNotFound = &BusinessError{
        Code:    ErrCodeNotFound,
        Message: "Resource not found",
    }
)
```

### Business Error Type

```go
// pkg/errors.go
type BusinessError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details any    `json:"details,omitempty"`
}

func (e *BusinessError) Error() string {
    return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func ValidateBusinessError(err *BusinessError, entityType string, args ...any) error {
    // Format error with entity context
    return &BusinessError{
        Code:    err.Code,
        Message: fmt.Sprintf(err.Message, args...),
        Details: map[string]string{"entity": entityType},
    }
}
```

---

## Error Handling

### Sentinel Errors (MANDATORY)

**HARD GATE:** All domain/business errors MUST be defined as sentinel errors (package-level variables). Creating errors inline with `errors.New()` or `fmt.Errorf()` for known error conditions is FORBIDDEN.

#### Why Sentinel Errors Are MANDATORY

| Benefit           | Explanation                                                        |
| ----------------- | ------------------------------------------------------------------ |
| **Comparability** | Callers can use `errors.Is(err, ErrNotFound)` for precise handling |
| **Documentation** | All possible errors are visible in one place                       |
| **Type safety**   | IDE autocomplete, refactoring support                              |
| **Testing**       | Tests can assert exact error types                                 |
| **API contracts** | Errors are part of the public API                                  |

#### Correct Pattern (REQUIRED)

```go
// pkg/errors/errors.go - Define all sentinel errors
package errors

import "errors"

// Domain errors - sentinel values
var (
    ErrNotFound          = errors.New("resource not found")
    ErrAlreadyExists     = errors.New("resource already exists")
    ErrInvalidInput      = errors.New("invalid input")
    ErrUnauthorized      = errors.New("unauthorized")
    ErrForbidden         = errors.New("forbidden")
    ErrInsufficientFunds = errors.New("insufficient funds")
    ErrExpired           = errors.New("resource expired")
)

// Service-specific errors
var (
    ErrUserNotFound      = errors.New("user not found")
    ErrUserAlreadyExists = errors.New("user already exists")
    ErrInvalidEmail      = errors.New("invalid email format")
    ErrEmailTaken        = errors.New("email already taken")
)
```

```go
// internal/service/user.go - Use sentinel errors
package service

import (
    "errors"
    "fmt"

    pkgErrors "github.com/your-org/your-service/pkg/errors"
)

func (s *UserService) GetUser(ctx context.Context, id string) (*User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, pkgErrors.ErrUserNotFound  // ✅ Return sentinel
        }
        return nil, fmt.Errorf("failed to get user: %w", err)  // ✅ Wrap unknown errors
    }
    return user, nil
}
```

```go
// Caller can check specific errors
user, err := userService.GetUser(ctx, id)
if err != nil {
    if errors.Is(err, pkgErrors.ErrUserNotFound) {
        return c.Status(404).JSON(fiber.Map{"error": "user not found"})
    }
    return c.Status(500).JSON(fiber.Map{"error": "internal error"})
}
```

#### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Inline error creation for known conditions
func (s *UserService) GetUser(ctx context.Context, id string) (*User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, errors.New("user not found")  // WRONG: cannot compare with errors.Is
        }
        return nil, err
    }
    return user, nil
}

// ❌ FORBIDDEN: fmt.Errorf for known error types
func (s *UserService) CreateUser(ctx context.Context, input CreateUserInput) (*User, error) {
    existing, _ := s.repo.FindByEmail(ctx, input.Email)
    if existing != nil {
        return nil, fmt.Errorf("email %s already taken", input.Email)  // WRONG: not a sentinel
    }
    // ...
}

// ❌ FORBIDDEN: String comparison for errors
if err.Error() == "user not found" {  // WRONG: brittle, breaks on message change
    // handle
}
```

#### When fmt.Errorf IS Allowed

```go
// ✅ ALLOWED: Wrapping errors with context (unknown/external errors)
if err != nil {
    return fmt.Errorf("failed to connect to database: %w", err)
}

// ✅ ALLOWED: Adding context to sentinel errors
return fmt.Errorf("user %s: %w", userID, pkgErrors.ErrNotFound)

// ✅ ALLOWED: Truly unexpected errors with dynamic context
return fmt.Errorf("unexpected response from API: status=%d, body=%s", status, body)
```

#### Anti-Rationalization Table

| Rationalization                             | Why It's WRONG                                              | Required Action                |
| ------------------------------------------- | ----------------------------------------------------------- | ------------------------------ |
| "The error message is descriptive enough"   | Descriptive ≠ comparable. Callers cannot use `errors.Is()`. | **Define sentinel error**      |
| "No one needs to check this specific error" | You don't know future callers. Make errors checkable.       | **Define sentinel error**      |
| "It's just a validation error"              | Validation errors are domain errors. Define them.           | **Define sentinel error**      |
| "I'm wrapping with context anyway"          | Wrap sentinels: `fmt.Errorf("context: %w", ErrNotFound)`    | **Define sentinel, then wrap** |
| "Too many error variables"                  | Explicit > implicit. All errors documented in one place.    | **Define all sentinels**       |

### Error Wrapping Rules

```go
// always check errors
if err != nil {
    return fmt.Errorf("context: %w", err)
}

// always wrap errors with context
if err != nil {
    return fmt.Errorf("failed to create user %s: %w", userID, err)
}

// Check specific errors with errors.Is
if errors.Is(err, ErrUserNotFound) {
    return nil, status.Error(codes.NotFound, "user not found")
}
```

### Forbidden

```go
// never use panic for business logic
panic(err) // FORBIDDEN

// never ignore errors
result, _ := doSomething() // FORBIDDEN

// never return nil error without checking
return nil, nil // SUSPICIOUS - check if error is possible
```

---

## Exit/Fatal Location Rules (MANDATORY)

**⛔ HARD GATE — ZERO PANIC POLICY:** `panic()` and `log.Fatal()` are FORBIDDEN in all code. `os.Exit()` is allowed only inside `main()` as a last resort after proper error handling.

### panic() Detection Checklist (MANDATORY)

**MUST scan entire codebase for `panic()` calls. Every occurrence MUST be removed.**

| Location | panic() | log.Fatal() | os.Exit() | Required Pattern |
|----------|---------|-------------|-----------|-----------------|
| `main()` | **FORBIDDEN** | **FORBIDDEN** | Allowed (last resort) | `if err != nil { os.Exit(1) }` |
| Bootstrap / `InitServers()` | **FORBIDDEN** | **FORBIDDEN** | **FORBIDDEN** | Return `(*Service, error)` |
| Test helpers | Use `t.Fatal()` | Use `t.Fatal()` | **FORBIDDEN** | `t.Fatal()` only |
| Business logic | **FORBIDDEN** | **FORBIDDEN** | **FORBIDDEN** | Return error |
| HTTP handlers | **FORBIDDEN** | **FORBIDDEN** | **FORBIDDEN** | Return error response |
| Repository / adapter | **FORBIDDEN** | **FORBIDDEN** | **FORBIDDEN** | Return error |
| Must* helpers | **FORBIDDEN** | — | — | Return `(T, error)` instead |

**Only exception:** `regexp.MustCompile()` with compile-time constant strings.

**Detection Commands:**

```bash
# Find all panic() calls in non-test files
grep -rn "panic(" --include="*.go" --exclude="*_test.go" .

# Find all panic() calls (including tests, for audit)
grep -rn "panic(" --include="*.go" .
```

### log.Fatal() Location Rules (MANDATORY)

`log.Fatal()` calls `os.Exit(1)` internally, bypassing deferred functions. It is **FORBIDDEN** everywhere.

| Location | Allowed? | Reason |
|----------|----------|--------|
| `main()` before server start | **FORBIDDEN** | Use `os.Exit(1)` after cleanup instead |
| `init()` functions | **FORBIDDEN** | Avoid fallible startup in `init()`; move to explicit bootstrap functions that return `error` |
| Service/handler/repo code | **FORBIDDEN** | MUST return error to caller |
| Goroutines | **FORBIDDEN** | Kills entire process, skips defer |

**Correct Pattern:**

```go
// ✅ ALLOWED: main() exits after error from bootstrap
func main() {
    svc, err := bootstrap.InitServers()
    if err != nil {
        fmt.Fprintf(os.Stderr, "failed to start: %v\n", err)
        os.Exit(1)
    }
    // ... start server
}

// ✅ CORRECT: Service returns error (caller decides)
func (s *UserService) CreateUser(ctx context.Context, input CreateUserInput) (*User, error) {
    if input.Email == "" {
        return nil, ErrInvalidEmail  // Return error, don't panic/fatal
    }
    // ...
}
```

**FORBIDDEN Pattern:**

```go
// ❌ FORBIDDEN: log.Fatal in service code
func (s *UserService) CreateUser(ctx context.Context, input CreateUserInput) (*User, error) {
    user, err := s.repo.Save(ctx, input)
    if err != nil {
        log.Fatal("failed to save user: ", err)  // KILLS process, skips defer
    }
    return user, nil
}

// ❌ FORBIDDEN: panic in handler
func (h *UserHandler) Create(c *fiber.Ctx) error {
    if c.Body() == nil {
        panic("empty body")  // Crashes server
    }
    // ...
}
```

**Detection Commands:**

```bash
# Find log.Fatal outside main.go
grep -rn "log.Fatal" --include="*.go" --exclude="main.go" .

# Find os.Exit outside main.go and test files
grep -rn "os.Exit" --include="*.go" --exclude="main.go" --exclude="*_test.go" .
```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "panic simplifies error handling" | panic crashes the process. Errors are recoverable, panics are not. | **Return error instead** |
| "log.Fatal ensures we notice failures" | log.Fatal calls os.Exit(1), skipping all deferred cleanup (DB connections, telemetry flush). | **Return error to caller** |
| "It's only called during startup" | If it's not in main(), a future refactor may call it at runtime. | **Move to main() or return error** |
| "The goroutine recovery will catch it" | Recovery only works in the same goroutine. Cross-goroutine panics kill the process. | **Return error instead** |
| "This error should never happen" | "Should never" ≠ "will never". Handle it gracefully. | **Return error with context** |
| "panic is ok in bootstrap/init" | panic() crashes without cleanup. Bootstrap errors are recoverable by the caller. | **Return error, let main() decide** |
| "Must* helper is a Go convention" | Must* hides errors behind panic. Lerian services must be recoverable at all layers. | **Return (T, error), never Must\*** |

---

## Function Design (MANDATORY)

**Single Responsibility Principle (SRP):** Each function MUST have exactly ONE responsibility.

### Rules

| Rule                                | Description                                             |
| ----------------------------------- | ------------------------------------------------------- |
| **One responsibility per function** | A function should do ONE thing and do it well           |
| **Max 20-30 lines**                 | If longer, break into smaller functions                 |
| **One level of abstraction**        | Don't mix high-level and low-level operations           |
| **Descriptive names**               | Function name should describe its single responsibility |

### Examples

```go
// ❌ BAD - Multiple responsibilities
func ProcessOrder(order Order) error {
    // Validate order
    if order.Items == nil {
        return errors.New("no items")
    }
    // Calculate total
    total := 0.0
    for _, item := range order.Items {
        total += item.Price * float64(item.Quantity)
    }
    // Apply discount
    if order.CouponCode != "" {
        total = total * 0.9
    }
    // Save to database
    db.Save(&order)
    // Send email
    sendEmail(order.CustomerEmail, "Order confirmed")
    return nil
}

// ✅ GOOD - Single responsibility per function
func ProcessOrder(order Order) error {
    if err := validateOrder(order); err != nil {
        return err
    }
    total := calculateTotal(order.Items)
    total = applyDiscount(total, order.CouponCode)
    if err := saveOrder(order, total); err != nil {
        return err
    }
    return notifyCustomer(order.CustomerEmail)
}

func validateOrder(order Order) error {
    if order.Items == nil || len(order.Items) == 0 {
        return errors.New("order must have items")
    }
    return nil
}

func calculateTotal(items []Item) float64 {
    total := 0.0
    for _, item := range items {
        total += item.Price * float64(item.Quantity)
    }
    return total
}

func applyDiscount(total float64, couponCode string) float64 {
    if couponCode != "" {
        return total * 0.9
    }
    return total
}
```

### Signs a Function Has Multiple Responsibilities

| Sign                                    | Action                                 |
| --------------------------------------- | -------------------------------------- |
| Multiple `// section` comments          | Split at comment boundaries            |
| "and" in function name                  | Split into separate functions          |
| More than 3 parameters                  | Consider parameter object or splitting |
| Nested conditionals > 2 levels          | Extract inner logic to functions       |
| Function does validation and processing | Separate validation function           |

---

## File Organization (MANDATORY)

**Single Responsibility per File:** Each file MUST represent ONE cohesive concept.

### Rules

| Rule                              | Description                                                   |
| --------------------------------- | ------------------------------------------------------------- |
| **One concept per file**          | A file groups functions/types for a single domain concept     |
| **Max 200-300 lines**             | If longer, split by responsibility boundaries                 |
| **File name = content**           | `order_validator.go` MUST only contain order validation logic |
| **Test file mirrors source file** | `order_service.go` → `order_service_test.go`                  |

### Examples

```go
// ❌ BAD - account_service.go (450 lines, multiple concerns)
package services

type AccountService struct {
    repo AccountRepository
    log  *zap.Logger
}

// CRUD operations
func (s *AccountService) CreateAccount(ctx context.Context, input CreateAccountInput) (*Account, error) { ... }
func (s *AccountService) UpdateAccount(ctx context.Context, id string, input UpdateAccountInput) (*Account, error) { ... }
func (s *AccountService) DeleteAccount(ctx context.Context, id string) error { ... }
func (s *AccountService) GetAccount(ctx context.Context, id string) (*Account, error) { ... }
func (s *AccountService) ListAccounts(ctx context.Context, filter AccountFilter) ([]*Account, error) { ... }

// Validation (different concern)
func (s *AccountService) ValidateAccountName(name string) error { ... }
func (s *AccountService) ValidateAccountType(t string) error { ... }
func (s *AccountService) ValidateAccountStatus(status string) error { ... }

// Balance operations (different concern)
func (s *AccountService) CalculateAccountBalance(ctx context.Context, id string) (float64, error) { ... }
func (s *AccountService) ReconcileAccount(ctx context.Context, id string) error { ... }

// Export operations (different concern)
func (s *AccountService) GenerateAccountStatement(ctx context.Context, id string, period Period) (*Statement, error) { ... }
func (s *AccountService) ExportAccountToCSV(ctx context.Context, id string) ([]byte, error) { ... }
```

```go
// ✅ GOOD - Split by responsibility

// account_command.go (~80 lines) - Write operations
package services

type AccountCommandService struct {
    repo AccountRepository
    log  *zap.Logger
}

func (s *AccountCommandService) CreateAccount(ctx context.Context, input CreateAccountInput) (*Account, error) { ... }
func (s *AccountCommandService) UpdateAccount(ctx context.Context, id string, input UpdateAccountInput) (*Account, error) { ... }
func (s *AccountCommandService) DeleteAccount(ctx context.Context, id string) error { ... }

// account_query.go (~70 lines) - Read operations
package services

type AccountQueryService struct {
    repo AccountRepository
    log  *zap.Logger
}

func (s *AccountQueryService) GetAccount(ctx context.Context, id string) (*Account, error) { ... }
func (s *AccountQueryService) ListAccounts(ctx context.Context, filter AccountFilter) ([]*Account, error) { ... }

// account_validator.go (~60 lines) - Validation rules
package services

func ValidateAccountName(name string) error { ... }
func ValidateAccountType(t string) error { ... }
func ValidateAccountStatus(status string) error { ... }

// account_balance.go (~90 lines) - Balance operations
package services

type AccountBalanceService struct {
    repo AccountRepository
    log  *zap.Logger
}

func (s *AccountBalanceService) CalculateBalance(ctx context.Context, id string) (float64, error) { ... }
func (s *AccountBalanceService) Reconcile(ctx context.Context, id string) error { ... }

// account_export.go (~70 lines) - Reporting/export
package services

func GenerateStatement(ctx context.Context, id string, period Period) (*Statement, error) { ... }
func ExportToCSV(ctx context.Context, id string) ([]byte, error) { ... }
```

### Signs a File Needs Splitting

| Sign                                         | Action                                             |
| -------------------------------------------- | -------------------------------------------------- |
| File exceeds 300 lines                       | Split at responsibility boundaries                 |
| Multiple struct types with their own methods | One file per struct                                |
| `// ===== Section =====` separator comments  | Each section becomes its own file                  |
| Mix of CRUD + validation + business logic    | Separate into command, query, validation files     |
| File name requires "and" to describe content | Split into separate files                          |
| Unrelated imports at the top                 | Different import groups suggest different concerns  |

---
