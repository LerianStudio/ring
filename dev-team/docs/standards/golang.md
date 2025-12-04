# Go Standards

This file defines the specific standards for Go development.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Version

- Go 1.21+ (preferível 1.22+)

---

## Frameworks & Libraries

### HTTP

| Library | Use Case |
|---------|----------|
| Fiber | High-performance APIs |
| Gin | General purpose, popular |
| Echo | Minimalist, fast |
| Chi | Composable router |
| gRPC-Go | Service-to-service |

### Database

| Library | Use Case |
|---------|----------|
| pgx/v5 | PostgreSQL (recommended) |
| sqlc | Type-safe SQL queries |
| GORM | ORM (when needed) |
| go-redis/v9 | Redis client |
| mongo-go-driver | MongoDB |

### Testing

| Library | Use Case |
|---------|----------|
| testify | Assertions, mocks |
| GoMock | Interface mocking |
| SQLMock | Database mocking |
| testcontainers-go | Integration tests |

### Observability

| Library | Use Case |
|---------|----------|
| log/slog | Structured logging (stdlib) |
| zerolog | High-performance logging |
| zap | Uber's logging |
| OpenTelemetry | Tracing & metrics |

---

## Error Handling

### Rules

```go
// ALWAYS check errors
if err != nil {
    return fmt.Errorf("context: %w", err)
}

// ALWAYS wrap errors with context
if err != nil {
    return fmt.Errorf("failed to create user %s: %w", userID, err)
}

// Use custom error types for domain errors
var ErrUserNotFound = errors.New("user not found")

// Check specific errors with errors.Is
if errors.Is(err, ErrUserNotFound) {
    return nil, status.Error(codes.NotFound, "user not found")
}
```

### Forbidden

```go
// NEVER use panic for business logic
panic(err) // FORBIDDEN

// NEVER ignore errors
result, _ := doSomething() // FORBIDDEN

// NEVER return nil error without checking
return nil, nil // SUSPICIOUS - check if error is possible
```

---

## Testing Patterns

### Table-Driven Tests (MANDATORY)

```go
func TestCreateUser(t *testing.T) {
    tests := []struct {
        name    string
        input   CreateUserInput
        want    *User
        wantErr error
    }{
        {
            name:  "valid user",
            input: CreateUserInput{Name: "John", Email: "john@example.com"},
            want:  &User{Name: "John", Email: "john@example.com"},
        },
        {
            name:    "invalid email",
            input:   CreateUserInput{Name: "John", Email: "invalid"},
            wantErr: ErrInvalidEmail,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CreateUser(tt.input)

            if tt.wantErr != nil {
                require.ErrorIs(t, err, tt.wantErr)
                return
            }

            require.NoError(t, err)
            assert.Equal(t, tt.want.Name, got.Name)
        })
    }
}
```

### Test Naming Convention

```text
Test{Unit}_{Scenario}_{ExpectedResult}

Examples:
- TestOrderService_CreateOrder_WithValidItems_ReturnsOrder
- TestOrderService_CreateOrder_WithEmptyItems_ReturnsError
- TestMoney_Add_SameCurrency_ReturnsSum
```

### Mock Generation

```go
// Using mockery
//go:generate mockery --name=OrderRepository --output=mocks --outpkg=mocks

// Using GoMock
//go:generate mockgen -source=repository.go -destination=mocks/mock_repository.go -package=mocks
```

---

## Logging Standards

### Structured Logging with slog

```go
import "log/slog"

// Create logger with context
logger := slog.With(
    "request_id", requestID,
    "user_id", userID,
)

// Log levels
logger.Debug("processing request", "payload_size", len(payload))
logger.Info("user created", "user_id", user.ID)
logger.Warn("rate limit approaching", "current", current, "limit", limit)
logger.Error("failed to save user", "error", err)
```

### What NOT to Log

```go
// FORBIDDEN - sensitive data
logger.Info("user login", "password", password)  // NEVER
logger.Info("payment", "card_number", card)      // NEVER
logger.Info("auth", "token", token)              // NEVER
logger.Info("user", "cpf", cpf)                  // NEVER (PII)
```

---

## Linting

### golangci-lint Configuration

```yaml
# .golangci.yml
linters:
  enable:
    - errcheck      # Check error handling
    - govet         # Go vet
    - staticcheck   # Static analysis
    - gosimple      # Simplify code
    - ineffassign   # Unused assignments
    - unused        # Unused code
    - gofmt         # Formatting
    - goimports     # Import ordering
    - misspell      # Spelling
    - goconst       # Repeated strings
    - gosec         # Security issues
    - nilerr        # Return nil with non-nil error
```

### Format Commands

```bash
# Format code
gofmt -w .
goimports -w .

# Run linter
golangci-lint run ./...
```

---

## Architecture Patterns

### Hexagonal Architecture (Ports & Adapters)

```text
/internal
  /domain          # Business entities (no dependencies)
    user.go
    errors.go
  /service         # Application/Business logic
    user_service.go
  /repository      # Data access interfaces (ports)
    user_repository.go
  /adapter         # Implementations (adapters)
    /postgres
      user_repository.go
    /redis
      cache_repository.go
  /handler         # HTTP handlers
    user_handler.go
```

### Interface-Based Abstractions

```go
// Define interface in the package that USES it (not implements)
// /internal/service/user_service.go

type UserRepository interface {
    FindByID(ctx context.Context, id UserID) (*User, error)
    Save(ctx context.Context, user *User) error
}

type UserService struct {
    repo UserRepository  // Depend on interface
}
```

### Repository Pattern

```go
// Interface (port)
type OrderRepository interface {
    FindByID(ctx context.Context, id OrderID) (*Order, error)
    FindByCustomer(ctx context.Context, customerID CustomerID) ([]*Order, error)
    Save(ctx context.Context, order *Order) error
    Delete(ctx context.Context, id OrderID) error
}

// Implementation (adapter)
type PostgresOrderRepository struct {
    db *pgxpool.Pool
}

func (r *PostgresOrderRepository) Save(ctx context.Context, order *Order) error {
    tx, err := r.db.Begin(ctx)
    if err != nil {
        return fmt.Errorf("begin transaction: %w", err)
    }
    defer tx.Rollback(ctx)

    // ... save logic ...

    return tx.Commit(ctx)
}
```

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

---

## DDD Patterns (Go Implementation)

### Entity

```go
type User struct {
    ID        UserID    // Value object for identity
    Email     Email     // Value object
    Name      string
    CreatedAt time.Time
    UpdatedAt time.Time
}

func (u User) Equals(other User) bool {
    return u.ID == other.ID
}
```

### Value Object

```go
type Money struct {
    amount   int64  // cents to avoid float issues
    currency string
}

func NewMoney(amount int64, currency string) (Money, error) {
    if currency == "" {
        return Money{}, errors.New("currency is required")
    }
    return Money{amount: amount, currency: currency}, nil
}

func (m Money) Add(other Money) (Money, error) {
    if m.currency != other.currency {
        return Money{}, ErrCurrencyMismatch
    }
    return Money{amount: m.amount + other.amount, currency: m.currency}, nil
}
```

### Aggregate Root

```go
type Order struct {
    ID         OrderID
    CustomerID CustomerID
    Items      []OrderItem
    Status     OrderStatus
    events     []DomainEvent
}

func (o *Order) AddItem(product Product, quantity int) error {
    if o.Status != OrderStatusDraft {
        return ErrOrderNotModifiable
    }

    o.Items = append(o.Items, OrderItem{...})
    o.events = append(o.events, OrderItemAdded{...})
    return nil
}

func (o *Order) PullEvents() []DomainEvent {
    events := o.events
    o.events = nil
    return events
}
```

---

## Directory Structure

```text
/cmd
  /api                 # Main application entry
    main.go
/internal
  /domain              # Business entities
  /service             # Business logic
  /repository          # Data access interfaces + implementations
    postgres/
    redis/
  /handler             # HTTP handlers
  /middleware          # HTTP middleware
/pkg
  /errors              # Custom error types (exported)
  /validator           # Custom validators (exported)
/migrations            # Database migrations
/config
  config.go
  config.yaml
```

---

## Checklist

Before submitting Go code, verify:

- [ ] All errors are checked and wrapped with context
- [ ] No `panic()` outside of `main.go`
- [ ] Tests use table-driven pattern
- [ ] Interfaces defined where they're used
- [ ] No global mutable state
- [ ] Context propagated through all calls
- [ ] Sensitive data not logged
- [ ] golangci-lint passes
