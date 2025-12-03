# Project Standards Template

Este template define os padrões técnicos do projeto. Copie para `docs/STANDARDS.md` no seu projeto e customize.

O ciclo de desenvolvimento (`/ring-dev-team:dev-cycle`) lê este arquivo no Gate 1 (analysis) para garantir que o código gerado siga os padrões do projeto.

---

## Stack

| Componente | Tecnologia | Versão |
|------------|------------|--------|
| Language | Go | 1.22+ |
| Framework | Gin | 1.9+ |
| Database | PostgreSQL | 15+ |
| Cache | Redis | 7+ |
| ORM/Query | sqlc | 1.25+ |
| Migrations | golang-migrate | 4.x |
| Frontend | React | 18+ |
| UI Framework | Next.js | 14+ |
| State | Zustand | 4+ |
| Styling | Tailwind CSS | 3+ |

---

## Methodologies

### Design Methodology

| Methodology | Enabled | Description |
|-------------|---------|-------------|
| **DDD** | Yes | Domain-Driven Design - model domain before code |
| Clean Architecture | Yes | Dependency inversion, domain at center |
| CQRS | No | Command Query Responsibility Segregation |
| Event Sourcing | No | Store events instead of state |

### DDD Configuration (if enabled)

```yaml
ddd:
  enabled: true

  # Strategic patterns
  bounded_contexts:
    - name: User
      responsibility: User authentication and profile management
      entities: [User, Profile, Credentials]
    - name: Order
      responsibility: Order lifecycle management
      entities: [Order, LineItem, OrderStatus]

  # Tactical patterns to use
  patterns:
    aggregates: true        # Use aggregate roots
    value_objects: true     # Use value objects for immutable data
    domain_events: true     # Emit domain events
    repositories: true      # Repository per aggregate
    domain_services: true   # For cross-aggregate operations
    factories: false        # Only if complex creation logic

  # Naming conventions
  naming:
    entities: PascalCase           # User, Order
    value_objects: PascalCase      # Money, Email, Address
    repositories: "{Entity}Repository"  # UserRepository
    services: "{Domain}Service"    # OrderService
    events: "{Entity}{Action}"     # OrderCreated, UserRegistered
```

### Testing Methodology

| Methodology | Enabled | Description |
|-------------|---------|-------------|
| **TDD** | Yes | Test-Driven Development - test first, then code |
| BDD | No | Behavior-Driven Development |

### TDD Configuration (if enabled)

```yaml
tdd:
  enabled: true

  # TDD cycle enforcement
  cycle:
    red: true      # Must write failing test first
    green: true    # Write minimal code to pass
    refactor: true # Refactor with tests passing

  # Test focus
  test_type: unit       # Focus on unit tests in development cycle
  # Note: Integration and E2E tests are handled separately (CI/CD, QA)

  # Coverage requirements
  coverage:
    minimum: 80%        # Fail if below this
    target: 90%         # Ideal coverage
    exclude:            # Exclude from coverage
      - "**/*_test.go"
      - "**/mocks/**"
      - "**/testdata/**"

  # Test naming pattern
  naming:
    pattern: "Test{Unit}_{Scenario}_{ExpectedResult}"
    examples:
      - "TestOrderService_CreateOrder_WithValidItems_ReturnsOrder"
      - "TestOrderService_CreateOrder_WithEmptyItems_ReturnsError"
```

---

## DDD Implementation Patterns (Go)

If DDD is enabled, use these patterns for implementation.

### Entity Pattern

```go
// Entity - object with identity that persists over time
type User struct {
    ID        UserID    // Identity (value object)
    Email     Email     // Value Object
    Name      string
    CreatedAt time.Time
    UpdatedAt time.Time
}

// Identity comparison - entities are equal if IDs match
func (u User) Equals(other User) bool {
    return u.ID == other.ID
}
```

### Value Object Pattern

```go
// Value Object - immutable, defined by attributes, no identity
type Money struct {
    amount   int64  // private: use cents to avoid float issues
    currency string
}

// Constructor with validation
func NewMoney(amount int64, currency string) (Money, error) {
    if currency == "" {
        return Money{}, errors.New("currency is required")
    }
    return Money{amount: amount, currency: currency}, nil
}

// Operations return new instances (immutable)
func (m Money) Add(other Money) (Money, error) {
    if m.currency != other.currency {
        return Money{}, ErrCurrencyMismatch
    }
    return Money{amount: m.amount + other.amount, currency: m.currency}, nil
}

// Value comparison - equal if all attributes match
func (m Money) Equals(other Money) bool {
    return m.amount == other.amount && m.currency == other.currency
}
```

### Aggregate Pattern

```go
// Aggregate Root - entry point for cluster of entities
type Order struct {
    ID         OrderID
    CustomerID CustomerID
    Items      []OrderItem  // Child entities
    Status     OrderStatus  // Value Object
    Total      Money        // Value Object
    events     []DomainEvent
}

// All modifications through Aggregate Root
func (o *Order) AddItem(product Product, quantity int) error {
    // Enforce invariants
    if o.Status != OrderStatusDraft {
        return ErrOrderNotModifiable
    }

    item := OrderItem{
        ID:        NewOrderItemID(),
        ProductID: product.ID,
        Price:     product.Price,
        Quantity:  quantity,
    }
    o.Items = append(o.Items, item)
    o.recalculateTotal()

    // Emit domain event
    o.events = append(o.events, OrderItemAdded{
        OrderID:   o.ID,
        ProductID: product.ID,
        Quantity:  quantity,
    })
    return nil
}

// Invariant enforcement
func (o *Order) Submit() error {
    if len(o.Items) == 0 {
        return ErrOrderEmpty
    }
    if o.Status != OrderStatusDraft {
        return ErrOrderAlreadySubmitted
    }

    o.Status = OrderStatusSubmitted
    o.events = append(o.events, OrderSubmitted{OrderID: o.ID})
    return nil
}

// Get pending events for publishing
func (o *Order) PullEvents() []DomainEvent {
    events := o.events
    o.events = nil
    return events
}
```

### Domain Event Pattern

```go
// Domain Event - record of something that happened (past tense)
type OrderSubmitted struct {
    OrderID    OrderID
    CustomerID CustomerID
    Total      Money
    OccurredAt time.Time
}

func (e OrderSubmitted) EventName() string {
    return "order.submitted"
}

// Event Publisher interface
type EventPublisher interface {
    Publish(ctx context.Context, events ...DomainEvent) error
}
```

### Repository Pattern

```go
// Repository interface (port) - collection-like API
type OrderRepository interface {
    FindByID(ctx context.Context, id OrderID) (*Order, error)
    FindByCustomer(ctx context.Context, customerID CustomerID) ([]*Order, error)
    Save(ctx context.Context, order *Order) error
    Delete(ctx context.Context, id OrderID) error
}

// PostgreSQL implementation (adapter)
type PostgresOrderRepository struct {
    db        *pgxpool.Pool
    publisher EventPublisher
}

func (r *PostgresOrderRepository) Save(ctx context.Context, order *Order) error {
    tx, err := r.db.Begin(ctx)
    if err != nil {
        return fmt.Errorf("begin transaction: %w", err)
    }
    defer tx.Rollback(ctx)

    // Save aggregate root and child entities
    if err := r.saveOrder(ctx, tx, order); err != nil {
        return err
    }

    // Publish domain events
    events := order.PullEvents()
    if err := r.publisher.Publish(ctx, events...); err != nil {
        return fmt.Errorf("publish events: %w", err)
    }

    return tx.Commit(ctx)
}
```

### Domain Service Pattern

```go
// Domain Service - business logic that doesn't fit in entities
type PricingService struct {
    discountRepo DiscountRepository
    taxService   TaxService
}

// Cross-aggregate operation
func (s *PricingService) CalculateOrderTotal(
    ctx context.Context,
    items []OrderItem,
    customerID CustomerID,
) (Money, error) {
    subtotal := s.calculateSubtotal(items)

    discount, err := s.discountRepo.FindForCustomer(ctx, customerID)
    if err != nil {
        return Money{}, fmt.Errorf("find discount: %w", err)
    }

    withDiscount, err := subtotal.Subtract(discount.Amount)
    if err != nil {
        return Money{}, fmt.Errorf("apply discount: %w", err)
    }

    tax, err := s.taxService.Calculate(ctx, withDiscount)
    if err != nil {
        return Money{}, fmt.Errorf("calculate tax: %w", err)
    }

    return withDiscount.Add(tax)
}
```

---

## TDD Implementation Patterns (Go)

If TDD is enabled, follow these patterns.

### TDD Cycle Example

```go
// STEP 1: RED - Write failing test first
func TestOrderService_CreateOrder_WithValidItems_ReturnsOrder(t *testing.T) {
    // Arrange
    repo := mocks.NewMockOrderRepository(t)
    service := NewOrderService(repo)

    input := CreateOrderInput{
        CustomerID: "cust-123",
        Items: []OrderItemInput{
            {ProductID: "prod-1", Quantity: 2},
        },
    }

    repo.EXPECT().
        Save(mock.Anything, mock.Anything).
        Return(nil)

    // Act
    order, err := service.CreateOrder(context.Background(), input)

    // Assert
    require.NoError(t, err)
    assert.NotEmpty(t, order.ID)
    assert.Equal(t, "cust-123", string(order.CustomerID))
    assert.Len(t, order.Items, 1)
}

// STEP 2: GREEN - Write minimal code to pass
func (s *OrderService) CreateOrder(ctx context.Context, input CreateOrderInput) (*Order, error) {
    order := &Order{
        ID:         NewOrderID(),
        CustomerID: CustomerID(input.CustomerID),
        Items:      make([]OrderItem, 0, len(input.Items)),
        Status:     OrderStatusDraft,
    }

    for _, item := range input.Items {
        order.Items = append(order.Items, OrderItem{
            ProductID: ProductID(item.ProductID),
            Quantity:  item.Quantity,
        })
    }

    if err := s.repo.Save(ctx, order); err != nil {
        return nil, fmt.Errorf("save order: %w", err)
    }

    return order, nil
}

// STEP 3: REFACTOR - Improve while keeping tests green
func (s *OrderService) CreateOrder(ctx context.Context, input CreateOrderInput) (*Order, error) {
    if err := input.Validate(); err != nil {
        return nil, fmt.Errorf("invalid input: %w", err)
    }

    order := s.buildOrder(input)

    if err := s.repo.Save(ctx, order); err != nil {
        return nil, fmt.Errorf("save order: %w", err)
    }

    return order, nil
}
```

### Table-Driven Tests Pattern

```go
func TestMoney_Add(t *testing.T) {
    tests := []struct {
        name    string
        a       Money
        b       Money
        want    Money
        wantErr error
    }{
        {
            name: "same currency adds correctly",
            a:    Money{amount: 100, currency: "USD"},
            b:    Money{amount: 50, currency: "USD"},
            want: Money{amount: 150, currency: "USD"},
        },
        {
            name:    "different currencies returns error",
            a:       Money{amount: 100, currency: "USD"},
            b:       Money{amount: 50, currency: "EUR"},
            wantErr: ErrCurrencyMismatch,
        },
        {
            name: "zero amount works",
            a:    Money{amount: 0, currency: "USD"},
            b:    Money{amount: 100, currency: "USD"},
            want: Money{amount: 100, currency: "USD"},
        },
        {
            name: "negative amount works",
            a:    Money{amount: 100, currency: "USD"},
            b:    Money{amount: -30, currency: "USD"},
            want: Money{amount: 70, currency: "USD"},
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := tt.a.Add(tt.b)

            if tt.wantErr != nil {
                require.ErrorIs(t, err, tt.wantErr)
                return
            }

            require.NoError(t, err)
            assert.True(t, tt.want.Equals(got))
        })
    }
}
```

### Mock Generation

```go
// Generate mocks with mockery
//go:generate mockery --name=OrderRepository --output=mocks --outpkg=mocks

// Or use GoMock
//go:generate mockgen -source=repository.go -destination=mocks/mock_repository.go -package=mocks
```

---

## Architecture

```
Pattern: Hexagonal Architecture (Ports & Adapters)

┌─────────────────────────────────────────┐
│             HTTP Handlers               │  ← Adapters (Primary)
├─────────────────────────────────────────┤
│              Services                   │  ← Application Core
├─────────────────────────────────────────┤
│            Repositories                 │  ← Ports (Secondary)
├─────────────────────────────────────────┤
│     PostgreSQL │ Redis │ External APIs  │  ← Adapters (Secondary)
└─────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Dependencies |
|-------|---------------|--------------|
| Handler | HTTP parsing, validation, response formatting | Service |
| Service | Business logic, orchestration | Repository, External |
| Repository | Data access, queries | Database |
| External | Third-party integrations | External APIs |

---

## Required Libraries

### Backend (Go)

```go
// Core
"github.com/gin-gonic/gin"              // HTTP framework
"github.com/jackc/pgx/v5"               // PostgreSQL driver
"github.com/redis/go-redis/v9"          // Redis client

// Validation & Config
"github.com/go-playground/validator/v10" // Struct validation
"github.com/spf13/viper"                 // Configuration

// Observability
"go.opentelemetry.io/otel"              // Tracing
"log/slog"                               // Structured logging (stdlib)

// Testing
"github.com/stretchr/testify"           // Assertions
"github.com/testcontainers/testcontainers-go" // Integration tests
```

### Frontend (TypeScript/React)

```typescript
// Core
"react": "^18.0.0"
"next": "^14.0.0"
"typescript": "^5.0.0"

// State & Data
"zustand": "^4.0.0"
"@tanstack/react-query": "^5.0.0"
"zod": "^3.0.0"

// UI
"tailwindcss": "^3.0.0"
"@radix-ui/react-*": "latest"
"lucide-react": "latest"

// Forms
"react-hook-form": "^7.0.0"
"@hookform/resolvers": "^3.0.0"

// Testing
"vitest": "^1.0.0"
"@testing-library/react": "^14.0.0"
"playwright": "^1.40.0"
```

---

## Code Conventions

### Naming

| Element | Convention | Example |
|---------|------------|---------|
| Go files | snake_case | `user_repository.go` |
| Go packages | lowercase | `repository`, `handler` |
| Go interfaces | -er suffix | `UserReader`, `TokenValidator` |
| Go mocks | mock_ prefix | `mock_user_repository.go` |
| TS files | kebab-case | `user-service.ts` |
| TS components | PascalCase | `UserProfile.tsx` |
| TS hooks | use prefix | `useUserData.ts` |

### Go Error Handling

```go
// ✅ CORRECT: Always wrap errors with context
if err != nil {
    return fmt.Errorf("failed to create user %s: %w", userID, err)
}

// ✅ CORRECT: Custom error types for domain errors
var ErrUserNotFound = errors.New("user not found")

if user == nil {
    return nil, ErrUserNotFound
}

// ❌ FORBIDDEN: Never use panic for errors
panic(err) // NEVER DO THIS

// ❌ FORBIDDEN: Never ignore errors
result, _ := doSomething() // NEVER DO THIS
```

### Go Testing

```go
// ✅ CORRECT: Table-driven tests
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

### TypeScript Patterns

```typescript
// ✅ CORRECT: Strict types, no `any`
interface User {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
}

// ✅ CORRECT: Zod for runtime validation
const userSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
});

// ✅ CORRECT: Error boundaries for components
function UserProfile({ userId }: { userId: string }) {
  const { data, error, isLoading } = useUser(userId);

  if (isLoading) return <Skeleton />;
  if (error) return <ErrorMessage error={error} />;
  if (!data) return <NotFound />;

  return <UserCard user={data} />;
}

// ❌ FORBIDDEN: Never use `any`
const data: any = fetchData(); // NEVER DO THIS

// ❌ FORBIDDEN: Never suppress TypeScript errors
// @ts-ignore // NEVER DO THIS
```

---

## Forbidden Practices

| Practice | Reason | Alternative |
|----------|--------|-------------|
| `panic()` for errors | Crashes application | Return error |
| Global variables | Hard to test | Dependency injection |
| `init()` functions | Hidden side effects | Explicit initialization |
| `interface{}` / `any` | Loses type safety | Generics or concrete types |
| Nested if > 3 levels | Hard to read | Early returns, extract functions |
| Magic numbers/strings | Unclear meaning | Named constants |
| Commented-out code | Clutters codebase | Delete it (git has history) |
| TODO without issue | Never gets done | Create issue, reference it |

---

## Directory Structure

### Backend (Go)

```
/cmd
  /api                 # Main application entry
    main.go
/internal
  /domain              # Business entities (no dependencies)
    user.go
    errors.go
  /service             # Business logic
    user_service.go
    user_service_test.go
  /repository          # Data access interfaces + implementations
    user_repository.go
    postgres/
      user_repository.go
  /handler             # HTTP handlers
    user_handler.go
    user_handler_test.go
  /middleware          # HTTP middleware
    auth.go
    logging.go
/pkg
  /errors              # Custom error types (exported)
  /validator           # Custom validators (exported)
/migrations            # Database migrations
  000001_create_users.up.sql
  000001_create_users.down.sql
/config
  config.go
  config.yaml
```

### Frontend (Next.js)

```
/src
  /app                 # Next.js App Router
    /api               # API routes
    /(auth)            # Auth route group
    /(dashboard)       # Dashboard route group
    layout.tsx
    page.tsx
  /components
    /ui                # Primitive UI components
    /features          # Feature-specific components
      /user
        UserProfile.tsx
        UserList.tsx
  /hooks               # Custom hooks
    useUser.ts
  /lib                 # Utilities
    api.ts
    utils.ts
  /stores              # Zustand stores
    userStore.ts
  /types               # TypeScript types
    user.ts
/public                # Static assets
/tests
  /e2e                 # Playwright tests
  /unit                # Vitest tests
```

---

## API Conventions

### REST Endpoints

```
GET    /api/v1/users          # List users
POST   /api/v1/users          # Create user
GET    /api/v1/users/:id      # Get user by ID
PUT    /api/v1/users/:id      # Update user
DELETE /api/v1/users/:id      # Delete user

GET    /api/v1/users/:id/posts    # List user's posts (nested resource)
```

### Response Format

```json
// Success
{
  "data": { ... },
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 100
  }
}

// Error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": [
      { "field": "email", "message": "must be a valid email" }
    ]
  }
}
```

### HTTP Status Codes

| Code | Use Case |
|------|----------|
| 200 | Success (GET, PUT) |
| 201 | Created (POST) |
| 204 | No Content (DELETE) |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (not authenticated) |
| 403 | Forbidden (not authorized) |
| 404 | Not Found |
| 409 | Conflict (duplicate) |
| 422 | Unprocessable Entity (business rule violation) |
| 500 | Internal Server Error |

---

## Git Conventions

### Branch Names

```
feature/AUTH-123-oauth-google
bugfix/AUTH-456-token-expiry
hotfix/AUTH-789-security-patch
refactor/AUTH-000-cleanup-handlers
```

### Commit Messages

```
feat(auth): add Google OAuth2 login

- Implement OAuth2 flow with golang.org/x/oauth2
- Add token storage in Redis + PostgreSQL
- Create login/callback handlers

Closes #123
```

Prefixes: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`

---

## Environment Variables

```bash
# Required
DATABASE_URL=postgres://user:pass@localhost:5432/db
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key

# Optional (with defaults)
PORT=8080
LOG_LEVEL=info
ENVIRONMENT=development

# OAuth (if using)
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...
```

---

## Checklist for New Code

Before submitting code, verify:

- [ ] Follows naming conventions
- [ ] No forbidden practices
- [ ] Error handling is complete (no ignored errors)
- [ ] Tests exist for new functionality
- [ ] No `any` types in TypeScript
- [ ] No `panic()` in Go (except main.go for startup)
- [ ] Environment variables documented
- [ ] API follows REST conventions
- [ ] Migrations are reversible (up + down)
