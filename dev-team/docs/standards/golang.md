# Go Standards

This file defines the specific standards for Go development at Lerian Studio.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Version

- **Minimum**: Go 1.23
- **Recommended**: Latest stable release

---

## Core Dependency: lib-commons (MANDATORY)

All Lerian Studio Go projects **MUST** use `lib-commons/v2` as the foundation library. This ensures consistency across all services.

### Required Import

```go
import (
    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
    libLog "github.com/LerianStudio/lib-commons/v2/commons/log"
    libZap "github.com/LerianStudio/lib-commons/v2/commons/zap"
    libPostgres "github.com/LerianStudio/lib-commons/v2/commons/postgres"
    libMongo "github.com/LerianStudio/lib-commons/v2/commons/mongo"
    libRedis "github.com/LerianStudio/lib-commons/v2/commons/redis"
    libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"
    libHTTP "github.com/LerianStudio/lib-commons/v2/commons/net/http"
    libServer "github.com/LerianStudio/lib-commons/v2/commons/server"
)
```

### What lib-commons Provides

| Package | Purpose |
|---------|---------|
| `commons` | Core utilities, config loading, tracking context |
| `commons/zap` | Logger initialization (Zap-based) |
| `commons/log` | Logger interface |
| `commons/postgres` | PostgreSQL connection management, pagination |
| `commons/mongo` | MongoDB connection management |
| `commons/redis` | Redis connection management |
| `commons/opentelemetry` | OpenTelemetry initialization and helpers |
| `commons/net/http` | HTTP utilities, telemetry middleware, cursor pagination |
| `commons/server` | Server lifecycle management with graceful shutdown |

---

## Frameworks & Libraries

### Required Versions (Minimum)

| Library | Minimum Version | Purpose |
|---------|-----------------|---------|
| `lib-commons` | v2.0.0 | Core infrastructure |
| `fiber/v2` | v2.52.0 | HTTP framework |
| `pgx/v5` | v5.7.0 | PostgreSQL driver |
| `go.opentelemetry.io/otel` | v1.38.0 | Telemetry |
| `zap` | v1.27.0 | Logging (via lib-commons) |
| `testify` | v1.10.0 | Testing |
| `mockery` | v2.50.0 | Mock generation |
| `mongo-driver` | v1.17.0 | MongoDB driver |
| `go-redis/v9` | v9.7.0 | Redis client |
| `validator/v10` | v10.26.0 | Input validation |

### HTTP Framework

| Library | Use Case |
|---------|----------|
| **Fiber v2** | **Primary choice** - High-performance APIs |
| gRPC-Go | Service-to-service communication |

### Database

| Library | Use Case |
|---------|----------|
| **pgx/v5** | PostgreSQL (recommended) |
| sqlc | Type-safe SQL queries |
| GORM | ORM (when needed) |
| **go-redis/v9** | Redis client |
| **mongo-go-driver** | MongoDB |

### Testing

| Library | Use Case |
|---------|----------|
| testify | Assertions, mocks |
| GoMock | Interface mocking (check if lib-commons already has a mock) |
| SQLMock | Database mocking |
| testcontainers-go | Integration tests |

---

## Configuration Loading (MANDATORY)

All services **MUST** use `libCommons.SetConfigFromEnvVars` for configuration loading.

### 1. Define Configuration Struct

```go
// bootstrap/config.go
package bootstrap

const ApplicationName = "your-service-name"

// Config is the top level configuration struct for the entire application.
type Config struct {
    // Application
    EnvName       string `env:"ENV_NAME"`
    LogLevel      string `env:"LOG_LEVEL"`
    ServerAddress string `env:"SERVER_ADDRESS"`

    // Database - Primary
    PrimaryDBHost     string `env:"DB_HOST"`
    PrimaryDBUser     string `env:"DB_USER"`
    PrimaryDBPassword string `env:"DB_PASSWORD"`
    PrimaryDBName     string `env:"DB_NAME"`
    PrimaryDBPort     string `env:"DB_PORT"`
    PrimaryDBSSLMode  string `env:"DB_SSLMODE"`

    // Database - Replica (for read scaling)
    ReplicaDBHost     string `env:"DB_REPLICA_HOST"`
    ReplicaDBUser     string `env:"DB_REPLICA_USER"`
    ReplicaDBPassword string `env:"DB_REPLICA_PASSWORD"`
    ReplicaDBName     string `env:"DB_REPLICA_NAME"`
    ReplicaDBPort     string `env:"DB_REPLICA_PORT"`
    ReplicaDBSSLMode  string `env:"DB_REPLICA_SSLMODE"`

    // Database - Connection Pool
    MaxOpenConnections int `env:"DB_MAX_OPEN_CONNS"`
    MaxIdleConnections int `env:"DB_MAX_IDLE_CONNS"`

    // MongoDB (if needed)
    MongoDBHost       string `env:"MONGO_HOST"`
    MongoDBName       string `env:"MONGO_NAME"`
    MongoDBUser       string `env:"MONGO_USER"`
    MongoDBPassword   string `env:"MONGO_PASSWORD"`
    MongoDBPort       string `env:"MONGO_PORT"`
    MongoDBParameters string `env:"MONGO_PARAMETERS"`
    MaxPoolSize       int    `env:"MONGO_MAX_POOL_SIZE"`

    // Redis
    RedisHost     string `env:"REDIS_HOST"`
    RedisPassword string `env:"REDIS_PASSWORD"`
    RedisDB       int    `env:"REDIS_DB"`
    RedisPoolSize int    `env:"REDIS_POOL_SIZE"`

    // OpenTelemetry
    OtelServiceName         string `env:"OTEL_RESOURCE_SERVICE_NAME"`
    OtelLibraryName         string `env:"OTEL_LIBRARY_NAME"`
    OtelServiceVersion      string `env:"OTEL_RESOURCE_SERVICE_VERSION"`
    OtelDeploymentEnv       string `env:"OTEL_RESOURCE_DEPLOYMENT_ENVIRONMENT"`
    OtelColExporterEndpoint string `env:"OTEL_EXPORTER_OTLP_ENDPOINT"`
    EnableTelemetry         bool   `env:"ENABLE_TELEMETRY"`

    // Auth
    AuthEnabled bool   `env:"PLUGIN_AUTH_ENABLED"`
    AuthHost    string `env:"PLUGIN_AUTH_HOST"`

    // External Services (gRPC)
    ExternalServiceAddress string `env:"EXTERNAL_SERVICE_GRPC_ADDRESS"`
    ExternalServicePort    string `env:"EXTERNAL_SERVICE_GRPC_PORT"`
}
```

### 2. Load Configuration

```go
// bootstrap/config.go
func InitServers() *Service {
    cfg := &Config{}

    // Load all environment variables into config struct
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        panic(err)
    }

    // Validate required fields
    if cfg.PrimaryDBHost == "" || cfg.PrimaryDBName == "" {
        panic("DB_HOST and DB_NAME must be configured")
    }

    // Continue with initialization...
}
```

### Supported Types

| Go Type | Default Value | Example |
|---------|---------------|---------|
| `string` | `""` | `ServerAddress string \`env:"SERVER_ADDRESS"\`` |
| `bool` | `false` | `EnableTelemetry bool \`env:"ENABLE_TELEMETRY"\`` |
| `int`, `int8`, `int16`, `int32`, `int64` | `0` | `MaxPoolSize int \`env:"MONGO_MAX_POOL_SIZE"\`` |

### Environment Variable Naming Convention

| Category | Prefix | Example |
|----------|--------|---------|
| Application | None | `ENV_NAME`, `LOG_LEVEL`, `SERVER_ADDRESS` |
| PostgreSQL | `DB_` | `DB_HOST`, `DB_USER`, `DB_PASSWORD` |
| PostgreSQL Replica | `DB_REPLICA_` | `DB_REPLICA_HOST`, `DB_REPLICA_USER` |
| MongoDB | `MONGO_` | `MONGO_HOST`, `MONGO_NAME` |
| Redis | `REDIS_` | `REDIS_HOST`, `REDIS_PASSWORD` |
| OpenTelemetry | `OTEL_` | `OTEL_RESOURCE_SERVICE_NAME` |
| Auth Plugin | `PLUGIN_AUTH_` | `PLUGIN_AUTH_ENABLED`, `PLUGIN_AUTH_HOST` |
| gRPC Services | `{SERVICE}_GRPC_` | `TRANSACTION_GRPC_ADDRESS` |

### What NOT to Do

```go
// FORBIDDEN: Manual os.Getenv calls scattered across code
host := os.Getenv("DB_HOST")  // DON'T do this

// FORBIDDEN: Configuration outside bootstrap
func NewService() *Service {
    dbHost := os.Getenv("DB_HOST")  // DON'T do this
}

// CORRECT: All configuration in Config struct, loaded once in bootstrap
type Config struct {
    PrimaryDBHost string `env:"DB_HOST"`  // Centralized
}
```

---

## Telemetry & Observability (MANDATORY)

All services **MUST** integrate OpenTelemetry using lib-commons.

### Complete Telemetry Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. BOOTSTRAP (config.go)                                        │
│    telemetry := libOpentelemetry.InitializeTelemetry(&config)   │
│    → Creates OpenTelemetry provider once at startup             │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. ROUTER (routes.go)                                           │
│    tlMid := libHTTP.NewTelemetryMiddleware(tl)                  │
│    f.Use(tlMid.WithTelemetry(tl))      ← Injects into context   │
│    ...routes...                                                  │
│    f.Use(tlMid.EndTracingSpans)        ← Closes root spans      │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. ANY LAYER (handlers, services, repositories)                 │
│    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)│
│    ctx, span := tracer.Start(ctx, "operation_name")             │
│    defer span.End()                                              │
│    logger.Infof("Processing...")   ← Logger from same context   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. SERVER LIFECYCLE (fiber.server.go)                           │
│    libServer.NewServerManager(nil, &s.telemetry, s.logger)      │
│        .WithHTTPServer(s.app, s.serverAddress)                  │
│        .StartWithGracefulShutdown()                             │
│    → Handles signal trapping + telemetry flush + clean shutdown │
└─────────────────────────────────────────────────────────────────┘
```

### 1. Bootstrap Initialization

```go
// bootstrap/config.go
func InitServers() *Service {
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        panic(err)
    }

    // Initialize logger FIRST
    logger := libZap.InitializeLogger()

    // Initialize telemetry with config
    telemetry := libOpentelemetry.InitializeTelemetry(&libOpentelemetry.TelemetryConfig{
        LibraryName:               cfg.OtelLibraryName,
        ServiceName:               cfg.OtelServiceName,
        ServiceVersion:            cfg.OtelServiceVersion,
        DeploymentEnv:             cfg.OtelDeploymentEnv,
        CollectorExporterEndpoint: cfg.OtelColExporterEndpoint,
        EnableTelemetry:           cfg.EnableTelemetry,
        Logger:                    logger,
    })

    // Pass telemetry to router...
}
```

### 2. Router Middleware Setup

```go
// adapters/http/in/routes.go
func NewRouter(lg libLog.Logger, tl *libOpentelemetry.Telemetry, ...) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler: func(ctx *fiber.Ctx, err error) error {
            return libHTTP.HandleFiberError(ctx, err)
        },
    })

    // Create telemetry middleware
    tlMid := libHTTP.NewTelemetryMiddleware(tl)

    // MUST be first middleware - injects tracer+logger into context
    f.Use(tlMid.WithTelemetry(tl))
    f.Use(cors.New())
    f.Use(libHTTP.WithHTTPLogging(libHTTP.WithCustomLogger(lg)))

    // ... define routes ...

    // Health & Version endpoints
    f.Get("/health", libHTTP.Ping)
    f.Get("/version", libHTTP.Version)

    // MUST be last middleware - closes root spans
    f.Use(tlMid.EndTracingSpans)

    return f
}
```

### 3. Recovering Logger & Tracer (Any Layer)

```go
// ANY file in ANY layer (handler, service, repository)
func (s *Service) ProcessEntity(ctx context.Context, id string) error {
    // Single call recovers BOTH logger AND tracer from context
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    // Create child span for this operation
    ctx, span := tracer.Start(ctx, "service.process_entity")
    defer span.End()

    // Logger is automatically correlated with trace
    logger.Infof("Processing entity: %s", id)

    // Pass ctx to downstream calls - trace propagates automatically
    return s.repo.Update(ctx, id)
}
```

### 4. Error Handling with Spans

```go
// For technical errors (unexpected failures)
if err != nil {
    libOpentelemetry.HandleSpanError(&span, "Failed to connect database", err)
    logger.Errorf("Database error: %v", err)
    return nil, err
}

// For business errors (expected validation failures)
if err != nil {
    libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Validation failed", err)
    logger.Warnf("Validation error: %v", err)
    return nil, err
}
```

### 5. Server Lifecycle with Graceful Shutdown

```go
// bootstrap/fiber.server.go
type Server struct {
    app           *fiber.App
    serverAddress string
    logger        libLog.Logger
    telemetry     libOpentelemetry.Telemetry
}

func (s *Server) Run(l *libCommons.Launcher) error {
    libServer.NewServerManager(nil, &s.telemetry, s.logger).
        WithHTTPServer(s.app, s.serverAddress).
        StartWithGracefulShutdown()  // Handles: SIGINT/SIGTERM, telemetry flush, connections close
    return nil
}
```

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `OTEL_RESOURCE_SERVICE_NAME` | Service name in traces | `midaz-onboarding` |
| `OTEL_LIBRARY_NAME` | Library identifier | `midaz` |
| `OTEL_RESOURCE_SERVICE_VERSION` | Service version | `1.0.0` |
| `OTEL_RESOURCE_DEPLOYMENT_ENVIRONMENT` | Environment | `production` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Collector endpoint | `http://otel-collector:4317` |
| `ENABLE_TELEMETRY` | Enable/disable | `true` |

---

## Bootstrap Pattern (MANDATORY)

All services **MUST** follow the bootstrap pattern for initialization.

### Directory Structure

```text
/internal
  /bootstrap
    config.go          # Config struct + InitServers()
    fiber.server.go    # HTTP server with graceful shutdown
    grpc.server.go     # gRPC server (if needed)
    service.go         # Service struct wrapping servers
```

### Complete Bootstrap Example

```go
// bootstrap/config.go
package bootstrap

const ApplicationName = "your-service"

type Config struct {
    // ... config fields with env tags
}

func InitServers() *Service {
    // 1. Load configuration
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        panic(err)
    }

    // 2. Initialize logger
    logger := libZap.InitializeLogger()

    // 3. Initialize telemetry
    telemetry := libOpentelemetry.InitializeTelemetry(&libOpentelemetry.TelemetryConfig{...})

    // 4. Initialize database connections
    postgresConnection := &libPostgres.PostgresConnection{...}
    mongoConnection := &libMongo.MongoConnection{...}
    redisConnection := &libRedis.RedisConnection{...}

    // 5. Initialize repositories (adapters)
    userRepo := postgres.NewUserRepository(postgresConnection)
    cacheRepo := redis.NewCacheRepository(redisConnection)

    // 6. Initialize use cases (services)
    commandUseCase := &command.UseCase{
        UserRepo:  userRepo,
        CacheRepo: cacheRepo,
    }
    queryUseCase := &query.UseCase{
        UserRepo: userRepo,
    }

    // 7. Initialize handlers
    userHandler := &httpin.UserHandler{
        Command: commandUseCase,
        Query:   queryUseCase,
    }

    // 8. Initialize router with middleware
    httpApp := httpin.NewRouter(logger, telemetry, userHandler)

    // 9. Create server
    serverAPI := NewServer(cfg, httpApp, logger, telemetry)

    return &Service{
        Server: serverAPI,
        Logger: logger,
    }
}
```

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

| Service | Prefix | Example |
|---------|--------|---------|
| Midaz | MDZ | MDZ-0001 |
| Plugin-Fees | FEE | FEE-0001 |
| Plugin-Auth | AUT | AUT-0001 |
| Platform | PLT | PLT-0001 |

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

## Pagination Patterns

Lerian Studio supports multiple pagination patterns. This section provides **implementation details** for each pattern.

> **Note**: The pagination strategy should be decided during the **TRD (Technical Requirements Document)** phase, not during implementation. See the `pre-dev-trd-creation` skill for the decision workflow. If no TRD exists, consult with the user before implementing.

### Quick Reference

| Pattern | Best For | Query Params | Response Fields |
|---------|----------|--------------|-----------------|
| Cursor-Based | High-volume data, real-time | `cursor`, `limit`, `sort_order` | `next_cursor`, `prev_cursor` |
| Page-Based | Low-volume data | `page`, `limit`, `sort_order` | `page`, `limit` |
| Page-Based + Total | UI needs "Page X of Y" | `page`, `limit`, `sort_order` | `page`, `limit`, `total` |

### Decision Guide (Reference Only)

```
Is this a high-volume entity (>10k records typical)?
├── YES → Use Cursor-Based Pagination
└── NO  → Use Page-Based Pagination

Does the user need to jump to arbitrary pages?
├── YES → Use Page-Based Pagination
└── NO  → Cursor-Based is fine

Does the UI need to show total count (e.g., "Page 1 of 10")?
├── YES → Use Page-Based with Total Count
└── NO  → Standard Page-Based is sufficient
```

---

### Pattern 1: Cursor-Based Pagination (PREFERRED for high-volume)

Use for: Transactions, Operations, Balances, Audit logs, Events

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cursor` | string | (none) | Base64-encoded cursor from previous response |
| `limit` | int | 10 | Items per page (max: 100) |
| `sort_order` | string | "asc" | Sort direction: "asc" or "desc" |
| `start_date` | datetime | (calculated) | Filter start date |
| `end_date` | datetime | now | Filter end date |

**Response Structure:**

```json
{
  "items": [...],
  "limit": 10,
  "next_cursor": "eyJpZCI6IjEyMzQ1Njc4Li4uIiwicG9pbnRzX25leHQiOnRydWV9",
  "prev_cursor": "eyJpZCI6IjEyMzQ1Njc4Li4uIiwicG9pbnRzX25leHQiOmZhbHNlfQ=="
}
```

**Handler Implementation:**

```go
func (h *Handler) GetAllTransactions(c *fiber.Ctx) error {
    ctx := c.UserContext()
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "handler.get_all_transactions")
    defer span.End()

    // Parse and validate query parameters
    headerParams, err := http.ValidateParameters(c.Queries())
    if err != nil {
        libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Invalid parameters", err)
        return http.WithError(c, err)
    }

    // Build pagination request (cursor-based)
    pagination := libPostgres.Pagination{
        Limit:     headerParams.Limit,
        SortOrder: headerParams.SortOrder,
        StartDate: headerParams.StartDate,
        EndDate:   headerParams.EndDate,
    }

    // Query with cursor pagination
    items, cursor, err := h.Query.GetAllTransactions(ctx, orgID, ledgerID, *headerParams)
    if err != nil {
        libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Query failed", err)
        return http.WithError(c, err)
    }

    // Set response with cursor
    pagination.SetItems(items)
    pagination.SetCursor(cursor.Next, cursor.Prev)

    return http.OK(c, pagination)
}
```

**Repository Implementation:**

```go
func (r *Repository) FindAll(ctx context.Context, filter http.Pagination) ([]Entity, libHTTP.CursorPagination, error) {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "postgres.find_all")
    defer span.End()

    // Decode cursor if provided
    var decodedCursor libHTTP.Cursor
    isFirstPage := true

    if filter.Cursor != "" {
        isFirstPage = false
        decodedCursor, _ = libHTTP.DecodeCursor(filter.Cursor)
    }

    // Build query with cursor pagination
    query := squirrel.Select("*").From("table_name")
    query, orderUsed := libHTTP.ApplyCursorPagination(
        query,
        decodedCursor,
        strings.ToUpper(filter.SortOrder),
        filter.Limit,
    )

    // Execute query...
    rows, err := query.RunWith(db).QueryContext(ctx)
    // ... scan rows into items ...

    // Check if there are more items
    hasPagination := len(items) > filter.Limit

    // Paginate records (trim to limit, handle direction)
    items = libHTTP.PaginateRecords(
        isFirstPage,
        hasPagination,
        decodedCursor.PointsNext || isFirstPage,
        items,
        filter.Limit,
        orderUsed,
    )

    // Calculate cursors for response
    var firstID, lastID string
    if len(items) > 0 {
        firstID = items[0].ID
        lastID = items[len(items)-1].ID
    }

    cursor, _ := libHTTP.CalculateCursor(
        isFirstPage,
        hasPagination,
        decodedCursor.PointsNext || isFirstPage,
        firstID,
        lastID,
    )

    return items, cursor, nil
}
```

---

### Pattern 2: Page-Based (Offset) Pagination

Use for: Organizations, Ledgers, Assets, Portfolios, Accounts

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | int | 1 | Page number (1-indexed) |
| `limit` | int | 10 | Items per page (max: 100) |
| `sort_order` | string | "asc" | Sort direction |
| `start_date` | datetime | (calculated) | Filter start date |
| `end_date` | datetime | now | Filter end date |

**Response Structure:**

```json
{
  "items": [...],
  "page": 1,
  "limit": 10
}
```

**Handler Implementation:**

```go
func (h *Handler) GetAllOrganizations(c *fiber.Ctx) error {
    ctx := c.UserContext()
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    ctx, span := tracer.Start(ctx, "handler.get_all_organizations")
    defer span.End()

    headerParams, err := http.ValidateParameters(c.Queries())
    if err != nil {
        return http.WithError(c, err)
    }

    // Build page-based pagination
    pagination := libPostgres.Pagination{
        Limit:     headerParams.Limit,
        Page:      headerParams.Page,
        SortOrder: headerParams.SortOrder,
        StartDate: headerParams.StartDate,
        EndDate:   headerParams.EndDate,
    }

    // Query with offset pagination (uses ToOffsetPagination())
    items, err := h.Query.GetAllOrganizations(ctx, headerParams.ToOffsetPagination())
    if err != nil {
        return http.WithError(c, err)
    }

    pagination.SetItems(items)

    return http.OK(c, pagination)
}
```

**Repository Implementation:**

```go
func (r *Repository) FindAll(ctx context.Context, pagination http.Pagination) ([]Entity, error) {
    offset := (pagination.Page - 1) * pagination.Limit

    query := squirrel.Select("*").
        From("table_name").
        OrderBy("id " + pagination.SortOrder).
        Limit(uint64(pagination.Limit)).
        Offset(uint64(offset))

    // Execute query...
    return items, nil
}
```

---

### Pattern 3: Page-Based with Total Count

Use when: Client needs total count for pagination UI (showing "Page 1 of 10")

**Response Structure:**

```json
{
  "items": [...],
  "page": 1,
  "limit": 10,
  "total": 100
}
```

**Note:** Adds a COUNT query overhead. Only use if total is required.

---

### Shared Utilities from lib-commons

| Utility | Package | Purpose |
|---------|---------|---------|
| `Pagination` struct | `lib-commons/commons/postgres` | Unified response structure |
| `Cursor` struct | `lib-commons/commons/net/http` | Cursor encoding |
| `DecodeCursor` | `lib-commons/commons/net/http` | Parse cursor from request |
| `ApplyCursorPagination` | `lib-commons/commons/net/http` | Add cursor to SQL query |
| `PaginateRecords` | `lib-commons/commons/net/http` | Trim results, handle direction |
| `CalculateCursor` | `lib-commons/commons/net/http` | Generate next/prev cursors |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_PAGINATION_LIMIT` | 100 | Maximum allowed limit per request |
| `MAX_PAGINATION_MONTH_DATE_RANGE` | 1 | Default date range in months |

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

### Using lib-commons Logger

```go
// Recover logger from context (PREFERRED)
logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

// Log with context correlation
logger.Infof("Processing entity: %s", entityID)
logger.Warnf("Rate limit approaching: %d/%d", current, limit)
logger.Errorf("Failed to save entity: %v", err)
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

```text
/cmd
  /app                   # Main application entry
    main.go
/internal
  /bootstrap             # Initialization (config, servers)
    config.go
    fiber.server.go
    service.go
  /domain                # Business entities
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
/pkg
  /constant              # Constants and error codes
  /mmodel                # Shared models
  /net/http              # HTTP utilities
/api                     # OpenAPI/Swagger specs
/migrations              # Database migrations
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

## Checklist

Before submitting Go code, verify:

- [ ] Using lib-commons v2 for infrastructure
- [ ] Configuration loaded via `SetConfigFromEnvVars`
- [ ] Telemetry initialized and middleware configured
- [ ] Logger/tracer recovered from context via `NewTrackingFromContext`
- [ ] All errors are checked and wrapped with context
- [ ] Error codes use service prefix (e.g., PLT-0001)
- [ ] No `panic()` outside of `main.go` or `InitServers`
- [ ] Tests use table-driven pattern
- [ ] Database models have ToEntity/FromEntity methods
- [ ] Interfaces defined where they're used
- [ ] No global mutable state
- [ ] Context propagated through all calls
- [ ] Sensitive data not logged
- [ ] golangci-lint passes
- [ ] Pagination strategy defined in TRD (or confirmed with user if no TRD)
