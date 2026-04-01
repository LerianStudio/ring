# Go Standards - Core Foundation

> **Module:** core.md | **Sections:** §1-9 | **Parent:** [index.md](index.md)

This module covers the foundational requirements for all Go projects.

---

## Table of Contents

| #   | Section                                                                                     | Description                                     |
| --- | ------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| 1   | [Version](#version)                                                                         | Go version requirements                         |
| 2   | [Core Dependency: lib-commons](#core-dependency-lib-commons-mandatory)                      | Required lib-commons v2 integration             |
| 3   | [Frameworks & Libraries](#frameworks--libraries)                                            | Required versions, validator v10 migration      |
| 4   | [Configuration](#configuration)                                                             | Environment variable handling                   |
| 5   | [Database Naming Convention (snake_case)](#database-naming-convention-snake-case-mandatory) | Table and column naming                         |
| 6   | [Database Migrations](#database-migrations-mandatory)                                       | golang-migrate requirement                      |
| 7   | [License Headers](#license-headers-mandatory)                                               | Copyright headers in source files               |
| 8   | [MongoDB Patterns](#mongodb-patterns-mandatory)                                             | Injection prevention, pooling, index management |
| 9   | [Dependency Management](#dependency-management-mandatory)                                   | Go modules, version pinning, security updates   |

---

## Version

- **Minimum**: Go 1.24
- **Recommended**: Latest stable release

---

## Core Dependency: lib-commons (MANDATORY)

All Lerian Studio Go projects **MUST** use `lib-commons/v2` as the foundation library. This ensures consistency across all services.

### Required Import (lib-commons v2)

```go
import (
    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
    libZap "github.com/LerianStudio/lib-commons/v2/commons/zap"           // Logger initialization (config/bootstrap only)
    libLog "github.com/LerianStudio/lib-commons/v2/commons/log"           // Logger interface (services, routes, consumers)
    libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"
    libServer "github.com/LerianStudio/lib-commons/v2/commons/server"
    libHTTP "github.com/LerianStudio/lib-commons/v2/commons/net/http"
    libPostgres "github.com/LerianStudio/lib-commons/v2/commons/postgres"
    libMongo "github.com/LerianStudio/lib-commons/v2/commons/mongo"
    libRedis "github.com/LerianStudio/lib-commons/v2/commons/redis"
)
```

> **Note:** v2 uses `lib` prefix aliases (e.g., `libCommons`, `libZap`, `libLog`) to distinguish lib-commons packages from standard library and other imports.

### What lib-commons Provides

| Package                 | Purpose                                                | Where Used                            |
| ----------------------- | ------------------------------------------------------ | ------------------------------------- |
| `commons`               | Core utilities, config loading, tracking context       | Everywhere                            |
| `commons/zap`           | Logger initialization/configuration                    | **Config/bootstrap files only**       |
| `commons/log`           | Logger interface (`log.Logger`) for logging operations | Services, routes, consumers, handlers |
| `commons/postgres`      | PostgreSQL connection management, pagination           | Bootstrap, repositories               |
| `commons/mongo`         | MongoDB connection management                          | Bootstrap, repositories               |
| `commons/redis`         | Redis connection management                            | Bootstrap, repositories               |
| `commons/opentelemetry` | OpenTelemetry initialization and helpers               | Bootstrap, middleware                 |
| `commons/net/http`      | HTTP utilities, telemetry middleware, pagination       | Routes, handlers                      |
| `commons/server`        | Server lifecycle with graceful shutdown                | Bootstrap                             |

### ⛔ FORBIDDEN: Custom Utilities That Duplicate lib-commons (HARD GATE)

**HARD GATE:** You CANNOT create custom helpers, utilities, or wrappers that duplicate functionality already provided by lib-commons. This is NON-NEGOTIABLE.

#### What lib-commons Already Provides (DO NOT RECREATE)

| Category       | lib-commons Provides                                 | FORBIDDEN to Create                    |
| -------------- | ---------------------------------------------------- | -------------------------------------- |
| **Logging**    | `libLog.Logger`, `libZap.NewLogger()`                | Custom logger, log wrapper, log helper |
| **Telemetry**  | `libOpentelemetry.NewCore threeProvider()`, span helpers | Custom tracer, telemetry wrapper       |
| **HTTP**       | `libHTTP.NewRouter()`, middleware, response helpers  | Custom HTTP utils, response formatters |
| **Config**     | `libCommons.SetConfigFromEnvVars()`                  | Custom config loader, env parser       |
| **Server**     | `libServer.NewServer()`, graceful shutdown           | Custom server lifecycle                |
| **PostgreSQL** | `libPostgres.Connect()`, pagination, query builders  | Custom DB helpers, pagination utils    |
| **MongoDB**    | `libMongo.Connect()`                                 | Custom Mongo wrapper                   |
| **Redis**      | `libRedis.Connect()`                                 | Custom Redis wrapper                   |
| **Context**    | `libCommons.TrackingContext`                         | Custom context propagation             |
| **Errors**     | Error wrapping utilities                             | Custom error helpers                   |

#### Detection Commands (Run Before Creating Any Utility)

```bash
# BEFORE creating any utility, search lib-commons first
# Clone or browse: https://github.com/LerianStudio/lib-commons

# Search for existing functionality
grep -rn "func.*Logger" ./vendor/github.com/LerianStudio/lib-commons/
grep -rn "func.*Trace" ./vendor/github.com/LerianStudio/lib-commons/
grep -rn "func.*Config" ./vendor/github.com/LerianStudio/lib-commons/
```

#### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Custom logger wrapper
package utils

func NewLogger() *zap.Logger {
    // DON'T DO THIS - use libZap.NewLogger()
}

// ❌ FORBIDDEN: Custom telemetry helper
package helpers

func StartSpan(ctx context.Context, name string) (context.Context, trace.Span) {
    // DON'T DO THIS - use libOpentelemetry helpers
}

// ❌ FORBIDDEN: Custom config loader
package config

func LoadFromEnv(cfg interface{}) error {
    // DON'T DO THIS - use libCommons.SetConfigFromEnvVars()
}

// ❌ FORBIDDEN: Custom HTTP response helper
package utils

func JSONResponse(c *fiber.Ctx, status int, data interface{}) error {
    // DON'T DO THIS - use libHTTP response helpers
}

// ❌ FORBIDDEN: Custom pagination utility
package helpers

func Paginate(page, pageSize int) (offset, limit int) {
    // DON'T DO THIS - use libPostgres or libHTTP pagination
}
```

#### When Custom Utilities ARE Allowed

| Scenario                            | Allowed? | Condition                                           |
| ----------------------------------- | -------- | --------------------------------------------------- |
| Functionality exists in lib-commons | ❌ NO    | Use lib-commons instead                             |
| Domain-specific business logic      | ✅ YES   | Not infrastructure-level                            |
| lib-commons lacks the feature       | ✅ YES   | Document why, consider contributing to lib-commons  |
| Thin wrapper for testing            | ⚠️ MAYBE | Only if it improves testability without duplicating |

#### Verification Checklist (MANDATORY Before Creating Any Utility)

```text
Before creating any file in utils/, helpers/, pkg/common/, or similar:

[ ] 1. Did I search lib-commons for this functionality?
[ ] 2. Does lib-commons have a package that does this?
[ ] 3. If lib-commons has it → USE IT, do not create custom
[ ] 4. If lib-commons lacks it → Is this infrastructure or domain logic?
[ ] 5. If infrastructure → Consider contributing to lib-commons instead

If you checked YES to #2 or #3 → STOP. Use lib-commons.
```

#### Anti-Rationalization Table

| Rationalization                           | Why It's WRONG                                                  | Required Action              |
| ----------------------------------------- | --------------------------------------------------------------- | ---------------------------- |
| "My wrapper is simpler"                   | Simpler ≠ better. Consistency > convenience.                    | **Use lib-commons**          |
| "lib-commons is too complex for this"     | Complexity exists for good reasons (telemetry, error handling). | **Use lib-commons**          |
| "I need a slightly different interface"   | Adapt your code to lib-commons, not the other way around.       | **Use lib-commons**          |
| "It's just a small helper"                | Small helpers grow. Today's helper is tomorrow's tech debt.     | **Use lib-commons**          |
| "I'll migrate to lib-commons later"       | Later = never. Start with lib-commons.                          | **Use lib-commons now**      |
| "The project doesn't use lib-commons yet" | That's the first problem to fix. Add lib-commons dependency.    | **Add lib-commons first**    |
| "I didn't know lib-commons had this"      | Ignorance ≠ excuse. Always search lib-commons before creating.  | **Search lib-commons first** |
| "lib-commons version is outdated"         | Update lib-commons, don't fork functionality.                   | **Update dependency**        |

---

## Frameworks & Libraries

### Required Versions (Minimum)

| Library                    | Minimum Version | Purpose                                          |
| -------------------------- | --------------- | ------------------------------------------------ |
| `lib-commons`              | v2.0.0          | Core infrastructure                              |
| `fiber/v2`                 | v2.52.0         | HTTP framework                                   |
| `pgx/v5`                   | v5.7.0          | PostgreSQL driver                                |
| `go.opentelemetry.io/otel` | v1.38.0         | Telemetry                                        |
| `zap`                      | v1.27.0         | Logging implementation (internal to lib-commons) |
| `testify`                  | v1.10.0         | Testing                                          |
| `gomock`                   | v0.5.0          | Mock generation                                  |
| `mongo-driver`             | v1.17.0         | MongoDB driver                                   |
| `go-redis/v9`              | v9.7.0          | Redis client                                     |
| `validator/v10`            | v10.26.0        | Input validation                                 |

### Validator Migration: v9 to v10 (MANDATORY)

Projects using `go-playground/validator/v9` have unmaintained dependencies with known security issues.

**⛔ HARD GATE:** All projects MUST use `validator/v10`. Version v9 is FORBIDDEN and MUST be migrated.

#### Why v10 Is MANDATORY

| Issue                | v9                               | v10                              |
| -------------------- | -------------------------------- | -------------------------------- |
| **Maintenance**      | ❌ Unmaintained since 2020       | ✅ Actively maintained           |
| **Security**         | ❌ Known CVEs unpatched          | ✅ Security patches applied      |
| **Features**         | ❌ Missing modern validations    | ✅ New validators, better errors |
| **Go compatibility** | ❌ Issues with Go 1.18+ generics | ✅ Full Go 1.24 support          |

#### Detection Commands (MANDATORY)

```bash
# MUST: Check for v9 usage (should return 0 matches)
grep -rn "go-playground/validator/v9" go.mod go.sum

# If found: BLOCKER - Migrate to v10 before proceeding

# Check current validator version
grep "go-playground/validator" go.mod

# Expected: github.com/go-playground/validator/v10 v10.x.x
```

#### Migration Steps

**1. Update go.mod:**

```bash
# Remove v9
go mod edit -droprequire github.com/go-playground/validator/v9

# Add v10
go get github.com/go-playground/validator/v10@latest
```

**2. Update imports in code:**

```go
// ❌ BEFORE: v9 import
import "github.com/go-playground/validator/v9"

// ✅ AFTER: v10 import
import "github.com/go-playground/validator/v10"
```

**3. Handle API changes:**

```go
// ❌ v9: validator.New()
v := validator.New()

// ✅ v10: Same API, new features available
v := validator.New(validator.WithRequiredStructEnabled())
```

**4. Update custom validators:**

```go
// ❌ v9: Old registration pattern
v.RegisterValidation("custom", customValidator)

// ✅ v10: Same pattern, use new error types
v.RegisterValidation("custom", customValidator)
// Access improved error details via v10.ValidationErrors
```

#### Common Migration Issues

| Issue                     | Solution                                        |
| ------------------------- | ----------------------------------------------- |
| `FieldError` type changed | Use `validator.ValidationErrors` type assertion |
| `StructLevel` changes     | Update to `validator.StructLevel` interface     |
| Tag format changes        | Some tags renamed (check release notes)         |
| Custom validators         | Re-register with v10 API                        |

#### Anti-Rationalization Table

| Rationalization             | Why It's WRONG                                             | Required Action             |
| --------------------------- | ---------------------------------------------------------- | --------------------------- |
| "v9 still works"            | Works ≠ maintained. Security vulnerabilities accumulate.   | **Migrate to v10**          |
| "Migration is risky"        | Risk of not migrating is higher (security, compatibility). | **Migrate to v10**          |
| "We have custom validators" | Custom validators work with v10. API is compatible.        | **Migrate to v10**          |
| "Dependencies use v9"       | Update dependencies too. Transitive v9 is also vulnerable. | **Update all dependencies** |
| "We'll migrate later"       | Later = never. Migrate now while context is fresh.         | **Migrate NOW**             |

---

### HTTP Framework

| Library      | Use Case                                   |
| ------------ | ------------------------------------------ |
| **Fiber v2** | **Primary choice** - High-performance APIs |
| gRPC-Go      | Service-to-service communication           |

### Database

| Library             | Use Case                 |
| ------------------- | ------------------------ |
| **pgx/v5**          | PostgreSQL (recommended) |
| sqlc                | Type-safe SQL queries    |
| GORM                | ORM (when needed)        |
| **go-redis/v9**     | Redis client             |
| **mongo-go-driver** | MongoDB                  |

### Testing

| Library           | Use Case                                    |
| ----------------- | ------------------------------------------- |
| testify           | Assertions                                  |
| GoMock            | Interface mocking (MANDATORY for all mocks) |
| SQLMock           | Database mocking                            |
| testcontainers-go | Integration tests                           |

---

## Configuration

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
func InitServers() (*Service, error) {
    cfg := &Config{}

    // Load all environment variables into config struct
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        return nil, fmt.Errorf("failed to load config: %w", err)
    }

    // Validate required fields
    if cfg.PrimaryDBHost == "" || cfg.PrimaryDBName == "" {
        return nil, fmt.Errorf("DB_HOST and DB_NAME must be configured")
    }

    // Continue with initialization...
}
```

### Supported Types

| Go Type                                  | Default Value | Example                                           |
| ---------------------------------------- | ------------- | ------------------------------------------------- |
| `string`                                 | `""`          | `ServerAddress string \`env:"SERVER_ADDRESS"\``   |
| `bool`                                   | `false`       | `EnableTelemetry bool \`env:"ENABLE_TELEMETRY"\`` |
| `int`, `int8`, `int16`, `int32`, `int64` | `0`           | `MaxPoolSize int \`env:"MONGO_MAX_POOL_SIZE"\``   |

### Environment Variable Naming Convention

| Category           | Prefix            | Example                                   |
| ------------------ | ----------------- | ----------------------------------------- |
| Application        | None              | `ENV_NAME`, `LOG_LEVEL`, `SERVER_ADDRESS` |
| PostgreSQL         | `DB_`             | `DB_HOST`, `DB_USER`, `DB_PASSWORD`       |
| PostgreSQL Replica | `DB_REPLICA_`     | `DB_REPLICA_HOST`, `DB_REPLICA_USER`      |
| MongoDB            | `MONGO_`          | `MONGO_HOST`, `MONGO_NAME`                |
| Redis              | `REDIS_`          | `REDIS_HOST`, `REDIS_PASSWORD`            |
| OpenTelemetry      | `OTEL_`           | `OTEL_RESOURCE_SERVICE_NAME`              |
| Auth Plugin        | `PLUGIN_AUTH_`    | `PLUGIN_AUTH_ENABLED`, `PLUGIN_AUTH_HOST`                      |
| Idempotency        | `IDEMPOTENCY_`    | `IDEMPOTENCY_ENABLED`, `IDEMPOTENCY_DEFAULT_TTL_SEC`          |
| gRPC Services      | `{SERVICE}_GRPC_` | `TRANSACTION_GRPC_ADDRESS`                                     |

### What not to Do

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

// Load with: libCommons.SetConfigFromEnvVars(&cfg)
```

---

## Database Naming Convention (snake_case) (MANDATORY)

**HARD GATE:** All database tables and columns MUST use `snake_case` naming. This is NON-NEGOTIABLE.

### Naming Rules

| Element                | Convention                       | Example                                        |
| ---------------------- | -------------------------------- | ---------------------------------------------- |
| **Tables**             | `snake_case`, plural             | `users`, `user_preferences`, `order_items`     |
| **Columns**            | `snake_case`                     | `user_id`, `created_at`, `email_address`       |
| **Primary keys**       | `id`                             | `id UUID PRIMARY KEY`                          |
| **Foreign keys**       | `{referenced_table_singular}_id` | `user_id`, `organization_id`                   |
| **Indexes**            | `idx_{table}_{column(s)}`        | `idx_users_email`, `idx_orders_user_id_status` |
| **Unique constraints** | `uq_{table}_{column(s)}`         | `uq_users_email`, `uq_preferences_user`        |
| **Check constraints**  | `chk_{table}_{description}`      | `chk_orders_positive_amount`                   |

### Layer Separation

**CRITICAL:** Different naming conventions apply at different layers:

| Layer           | Convention   | Example                                  |
| --------------- | ------------ | ---------------------------------------- |
| **Database**    | `snake_case` | `user_id`, `created_at`, `email_address` |
| **Go structs**  | `PascalCase` | `UserID`, `CreatedAt`, `EmailAddress`    |
| **JSON output** | `camelCase`  | `userId`, `createdAt`, `emailAddress`    |

### Correct Examples

#### SQL Migration

```sql
-- ✅ CORRECT: All identifiers use snake_case
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    theme_name VARCHAR(50) DEFAULT 'light',
    notification_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);
ALTER TABLE user_preferences ADD CONSTRAINT uq_user_preferences_user UNIQUE (user_id);
```

#### Go Model with Database Tags

```go
// ✅ CORRECT: Go uses PascalCase, db tags use snake_case, json tags use camelCase
type UserPreference struct {
    ID                  string    `json:"id" db:"id"`
    UserID              string    `json:"userId" db:"user_id"`
    ThemeName           string    `json:"themeName" db:"theme_name"`
    NotificationEnabled bool      `json:"notificationEnabled" db:"notification_enabled"`
    CreatedAt           time.Time `json:"createdAt" db:"created_at"`
    UpdatedAt           time.Time `json:"updatedAt" db:"updated_at"`
}
```

### FORBIDDEN Patterns

```sql
-- ❌ FORBIDDEN: camelCase in database
CREATE TABLE userPreferences (
    id UUID PRIMARY KEY,
    userId UUID NOT NULL,          -- WRONG: should be user_id
    themeName VARCHAR(50),         -- WRONG: should be theme_name
    createdAt TIMESTAMP            -- WRONG: should be created_at
);

-- ❌ FORBIDDEN: PascalCase in database
CREATE TABLE UserPreferences (
    ID UUID PRIMARY KEY,
    UserID UUID NOT NULL,          -- WRONG: should be user_id
    ThemeName VARCHAR(50)          -- WRONG: should be theme_name
);

-- ❌ FORBIDDEN: Mixed conventions
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY,
    userId UUID NOT NULL,          -- WRONG: inconsistent with table naming
    theme_name VARCHAR(50),        -- OK
    CreatedAt TIMESTAMP            -- WRONG: PascalCase
);
```

```go
// ❌ FORBIDDEN: Database tags not using snake_case
type UserPreference struct {
    UserID    string `json:"userId" db:"userId"`       // WRONG: db tag should be "user_id"
    ThemeName string `json:"themeName" db:"themeName"` // WRONG: db tag should be "theme_name"
}
```

### Detection Commands

```bash
# Detect camelCase in SQL migrations (should return 0 matches for compliant code)
grep -rn "[a-z][A-Z]" --include="*.sql" ./migrations | grep -v "^--"

# Detect PascalCase column definitions (should return 0 matches)
grep -rn "^\s*[A-Z][a-z]*[A-Z]" --include="*.sql" ./migrations

# Detect incorrect db tags in Go files (should return 0 matches)
grep -rn 'db:"[a-z]*[A-Z]' --include="*.go" ./internal
```

### Why snake_case for Databases

| Reason                  | Explanation                                                                   |
| ----------------------- | ----------------------------------------------------------------------------- |
| **PostgreSQL standard** | PostgreSQL folds unquoted identifiers to lowercase; snake_case avoids quoting |
| **Readability**         | `user_id` is clearer than `userid` or `UserID` in SQL queries                 |
| **SQL convention**      | Industry standard for relational databases                                    |
| **Tool compatibility**  | Most DB tools expect snake_case                                               |
| **Cross-platform**      | Works consistently across PostgreSQL, MySQL, SQLite                           |

### Anti-Rationalization Table

| Rationalization                          | Why It's WRONG                                                     | Required Action                          |
| ---------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------- |
| "camelCase matches our Go code"          | DB layer ≠ Go layer. Different conventions for different contexts. | **Use snake_case in DB**                 |
| "PostgreSQL accepts camelCase in quotes" | Requiring quotes everywhere is error-prone and non-standard.       | **Use snake_case without quotes**        |
| "ORM handles the mapping"                | Explicit > implicit. Clear db tags prevent surprises.              | **Use explicit db tags with snake_case** |
| "It's just an internal database"         | Internal ≠ exempt from standards. Consistency matters everywhere.  | **Use snake_case**                       |
| "The existing table uses camelCase"      | Legacy debt must be migrated. New code cannot perpetuate mistakes. | **Create migration to fix naming**       |

---

## Database Migrations (MANDATORY)

**HARD GATE:** All database migrations MUST use `golang-migrate`. Creating custom migration runners is FORBIDDEN.

### Required Tool

| Tool                     | Version | Purpose                    |
| ------------------------ | ------- | -------------------------- |
| `golang-migrate/migrate` | v4.x    | Database schema migrations |

```bash
# Installation
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

### Why golang-migrate Is Mandatory

| Benefit            | Description                             |
| ------------------ | --------------------------------------- |
| **Battle-tested**  | Used by thousands of production systems |
| **Atomic**         | Migrations run in transactions          |
| **Bi-directional** | Supports up/down migrations             |
| **Driver support** | PostgreSQL, MySQL, MongoDB, etc.        |
| **CI/CD friendly** | Easy to integrate with pipelines        |

### FORBIDDEN: Custom Migration Systems

```go
// ❌ FORBIDDEN: Creating custom version tracking table
func initMigrations(db *sql.DB) {
    db.Exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
        version INT PRIMARY KEY,
        applied_at TIMESTAMP
    )`)
}

// ❌ FORBIDDEN: Manual version checking
func runMigrations(db *sql.DB) {
    var currentVersion int
    db.QueryRow("SELECT MAX(version) FROM schema_migrations").Scan(&currentVersion)
    // ... apply migrations manually
}

// ❌ FORBIDDEN: Embedding migrations in application code
func applyMigration001(db *sql.DB) error {
    return db.Exec("CREATE TABLE users (...)")
}
```

**Why this is wrong:**

- Reinvents what golang-migrate already does
- Lacks transaction safety
- No rollback support
- Inconsistent across projects
- Harder to debug and maintain

### Correct Pattern: golang-migrate

#### Migration File Structure

```text
/migrations
  000001_create_users_table.up.sql
  000001_create_users_table.down.sql
  000002_add_email_column.up.sql
  000002_add_email_column.down.sql
  000003_create_orders_table.up.sql
  000003_create_orders_table.down.sql
```

#### Naming Convention

```text
{version}_{description}.{direction}.sql

version:     6-digit zero-padded number (000001, 000002, ...)
description: snake_case description of the change
direction:   up (apply) or down (rollback)
```

#### Migration Granularity (MANDATORY)

**RULE: One migration per feature/release. NOT one migration per alteration.**

| Approach                        | Atomicity                  | Rollback                        | Status        |
| ------------------------------- | -------------------------- | ------------------------------- | ------------- |
| One migration per feature       | ✅ Atomic (all-or-nothing) | `migrate down 1`                | **CORRECT**   |
| Multiple migrations per feature | ❌ Non-atomic              | `migrate down N` (manual count) | **FORBIDDEN** |

**Why this matters:**

- **Atomicity:** A single migration runs in a transaction - it either fully succeeds or fully rolls back
- **Simple rollback:** One feature = one migration = `migrate down 1` to undo
- **Release alignment:** Migrations map 1:1 to features/releases for traceability

**FORBIDDEN: Multiple migrations for one feature**

```text
# ❌ WRONG: 5 migrations for "add user preferences" feature
/migrations
  000005_create_preferences_table.up.sql
  000006_add_theme_column.up.sql
  000007_add_language_column.up.sql
  000008_add_timezone_column.up.sql
  000009_add_preferences_index.up.sql

# Problem: To rollback this feature, you need "migrate down 5"
# If you forget and do "migrate down 1", feature is partially rolled back
```

**CORRECT: One migration for one feature**

```text
# ✅ CORRECT: 1 migration for "add user preferences" feature
/migrations
  000005_add_user_preferences.up.sql
  000005_add_user_preferences.down.sql

# Rollback: "migrate down 1" undoes the entire feature
```

**What goes in a single migration:**

```sql
-- 000005_add_user_preferences.up.sql
-- All changes for "user preferences" feature in ONE file

-- 1. Create table
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    theme VARCHAR(50) DEFAULT 'light',
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add index
CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);

-- 3. Add constraint
ALTER TABLE user_preferences ADD CONSTRAINT uq_user_preferences_user UNIQUE (user_id);
```

```sql
-- 000005_add_user_preferences.down.sql
-- Reverse ALL changes in ONE file (reverse order)

ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS uq_user_preferences_user;
DROP INDEX IF EXISTS idx_user_preferences_user_id;
DROP TABLE IF EXISTS user_preferences;
```

**Migration Granularity Decision Table:**

| Scenario                             | Migrations          | Example                           |
| ------------------------------------ | ------------------- | --------------------------------- |
| New feature with table + indexes     | 1 migration         | `000005_add_user_preferences.sql` |
| Bug fix requiring schema change      | 1 migration         | `000006_fix_email_constraint.sql` |
| Refactor with multiple table changes | 1 migration         | `000007_normalize_addresses.sql`  |
| Unrelated changes in same release    | Separate migrations | Each gets own migration           |

**Anti-Rationalization:**

| Rationalization                                | Why It's WRONG                                                      | Required Action                |
| ---------------------------------------------- | ------------------------------------------------------------------- | ------------------------------ |
| "Smaller migrations are safer"                 | Atomicity makes single migration safer. Partial state is dangerous. | **Combine into one migration** |
| "I want to track each change separately"       | Use comments inside the migration file. Git tracks file history.    | **Combine into one migration** |
| "Rollback granularity is better with multiple" | Partial rollback = broken state. All-or-nothing is correct.         | **Combine into one migration** |
| "The migration file would be too long"         | Long but atomic > short but fragmented. Use comments for sections.  | **Combine into one migration** |

#### Migration File Examples

```sql
-- 000001_create_users_table.up.sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

```sql
-- 000001_create_users_table.down.sql
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;
```

### Makefile Commands (REQUIRED)

**See [devops.md - Database Migration Commands](../devops.md#database-migration-commands-mandatory)** for the complete Makefile implementation.

**Quick reference:**

| Command                        | Purpose                                |
| ------------------------------ | -------------------------------------- |
| `make migrate-up`              | Apply all pending migrations           |
| `make migrate-down`            | Rollback last migration                |
| `make migrate-create NAME=xxx` | Create new migration                   |
| `make migrate-version`         | Show current version                   |
| `make dev-setup`               | Install golang-migrate and other tools |

### Docker Compose Integration

```yaml
# docker-compose.yml
services:
  migrate:
    image: migrate/migrate:v4.17.0
    volumes:
      - ./migrations:/migrations
    command:
      [
        "-path",
        "/migrations",
        "-database",
        "postgres://user:pass@db:5432/dbname?sslmode=disable",
        "up",
      ]
    depends_on:
      db:
        condition: service_healthy
```

### Anti-Patterns (Detection Commands)

```bash
# Detect custom migration tables (should return 0 matches)
grep -rn "schema_migrations\|migration_version\|db_version" --include="*.go" ./internal

# Detect manual migration tracking (should return 0 matches)
grep -rn "CREATE TABLE.*migration" --include="*.go" ./internal

# Detect embedded SQL DDL in Go code (review each match)
grep -rn "CREATE TABLE\|ALTER TABLE\|DROP TABLE" --include="*.go" ./internal
```

### Anti-Rationalization Table

| Rationalization                               | Why It's WRONG                                                              | Required Action                       |
| --------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------- |
| "golang-migrate is overkill for this project" | Consistency > simplicity. All projects use the same tool.                   | **Use golang-migrate**                |
| "I need custom logic before/after migrations" | Use golang-migrate hooks or run scripts separately.                         | **Use golang-migrate**                |
| "Embedding migrations is more portable"       | SQL files are portable. Custom Go code is not.                              | **Use golang-migrate with SQL files** |
| "My migration table is simpler"               | Simpler ≠ better. golang-migrate handles edge cases you haven't thought of. | **Use golang-migrate**                |
| "This is just a small schema change"          | Small changes grow. Start with the right tool.                              | **Use golang-migrate**                |

---

## License Headers (MANDATORY)

**⛔ HARD GATE:** All `.go` source files MUST include a license header. Missing license headers indicate incomplete compliance and must be fixed before production deployment.

### Why License Headers Are MANDATORY

| Without Headers           | With Headers                  |
| ------------------------- | ----------------------------- |
| IP ownership unclear      | Clear copyright attribution   |
| Legal exposure in copies  | Protected when code is shared |
| Compliance audit failures | Audit-ready codebase          |
| Inconsistent attribution  | Uniform legal protection      |

### Required Format (Elastic License 2.0)

```go
// Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
// or more contributor license agreements. Licensed under the Elastic License 2.0;
// you may not use this file except in compliance with the Elastic License 2.0.

package yourpackage
```

### Header Components

| Component         | Value                 | Notes                                     |
| ----------------- | --------------------- | ----------------------------------------- |
| Copyright holder  | `Elasticsearch B.V.`  | Fixed for all projects                    |
| License reference | `Elastic License 2.0` | Or as specified in LICENSE file           |
| LICENSE location  | Inline in header      | No separate LICENSE file reference needed |

### Files That MUST Have Headers

| File Type                | Required | Notes                      |
| ------------------------ | -------- | -------------------------- |
| `*.go` (source files)    | ✅ YES   | All source code            |
| `*_test.go` (test files) | ✅ YES   | Tests are also source code |
| `cmd/**/*.go`            | ✅ YES   | Entry points               |
| `internal/**/*.go`       | ✅ YES   | Internal packages          |
| `pkg/**/*.go`            | ✅ YES   | Public packages            |

### Files That MAY Skip Headers

| File Type                   | Required    | Reason                    |
| --------------------------- | ----------- | ------------------------- |
| Generated files (`*.pb.go`) | ⚠️ OPTIONAL | Auto-generated by protoc  |
| Mock files (`mock_*.go`)    | ⚠️ OPTIONAL | Auto-generated by mockgen |
| Vendor files (`vendor/**`)  | ❌ NO       | Third-party code          |

### Correct Examples

```go
// Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
// or more contributor license agreements. Licensed under the Elastic License 2.0;
// you may not use this file except in compliance with the Elastic License 2.0.

package bootstrap

import (
    "context"
    "fmt"
)
```

```go
// Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
// or more contributor license agreements. Licensed under the Elastic License 2.0;
// you may not use this file except in compliance with the Elastic License 2.0.

package bootstrap_test

import (
    "testing"
)
```

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Missing header entirely
package model

import "time"

// ❌ FORBIDDEN: Wrong format (missing full license text)
// Copyright Elasticsearch B.V.
// Licensed under Elastic License 2.0
package model

// ❌ FORBIDDEN: Header after package declaration
package model

// Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
// or more contributor license agreements. Licensed under the Elastic License 2.0;
// you may not use this file except in compliance with the Elastic License 2.0.

import "time"
```

### Verification Commands

```bash
# Find .go files without license header (should return 0 for compliant projects)
find . -name "*.go" -not -path "./vendor/*" -not -name "*.pb.go" -not -name "mock_*.go" \
    -exec sh -c 'head -1 "$1" | grep -q "^// Copyright" || echo "$1"' _ {} \;

# Count files with correct header
grep -rl "Copyright (c).*Lerian Studio" --include="*.go" . | wc -l

# Count total .go files (excluding vendor/generated)
find . -name "*.go" -not -path "./vendor/*" -not -name "*.pb.go" -not -name "mock_*.go" | wc -l
```

### Adding Headers to Existing Files

For projects adopting this standard, use this script to add headers:

```bash
#!/bin/bash
# add-license-headers.sh

HEADER='// Copyright (c) 2024 Lerian Studio. All rights reserved.
// Use of this source code is governed by the Elastic License 2.0
// that can be found in the LICENSE file.

'

find . -name "*.go" -not -path "./vendor/*" -not -name "*.pb.go" -not -name "mock_*.go" | while read file; do
    if ! head -1 "$file" | grep -q "^// Copyright"; then
        echo "Adding header to: $file"
        echo "$HEADER$(cat "$file")" > "$file"
    fi
done
```

### Anti-Rationalization Table

| Rationalization                | Why It's WRONG                                                               | Required Action              |
| ------------------------------ | ---------------------------------------------------------------------------- | ---------------------------- |
| "It's just internal code"      | Internal code is still copyrighted. Headers protect IP.                      | **Add header to all files**  |
| "Tests don't need headers"     | Tests are source code. Same rules apply.                                     | **Add header to test files** |
| "I'll add them later"          | Later = never. Add headers when creating files.                              | **Add header immediately**   |
| "The LICENSE file is enough"   | Per-file headers provide clear attribution in copies.                        | **Add header to all files**  |
| "Generated files are excluded" | Only truly auto-generated (protobuf, mocks). Hand-written = header required. | **Check if truly generated** |

---

## MongoDB Patterns (MANDATORY)

Common MongoDB issues include $regex injection vectors, unconfigured MaxPoolSize, blocking index creation, and deprecated SetBackground calls.

**⛔ HARD GATE:** All MongoDB operations MUST follow these patterns to prevent injection, ensure performance, and avoid deprecated APIs.

### Injection Prevention (CRITICAL)

Using `$regex` operators with unvalidated user input allows NoSQL injection attacks.

**⛔ FORBIDDEN: Unescaped $regex with User Input**

```go
// ❌ FORBIDDEN: User input directly in $regex
filter := bson.M{
    "name": bson.M{"$regex": userInput},  // INJECTION VECTOR
}
cursor, _ := collection.Find(ctx, filter)

// Attack example: userInput = ".*" returns all documents
// Attack example: userInput = "admin|" matches "admin" or empty
```

**✅ CORRECT: Use $eq or Escape Special Characters**

```go
// ✅ CORRECT: Use $eq for exact matches (preferred)
filter := bson.M{
    "name": bson.M{"$eq": userInput},
}

// ✅ CORRECT: Use $text search (requires text index)
filter := bson.M{
    "$text": bson.M{"$search": userInput},
}

// ✅ CORRECT: Escape regex special characters if $regex is required
import "regexp"

func escapeRegex(s string) string {
    return regexp.QuoteMeta(s)
}

filter := bson.M{
    "name": bson.M{
        "$regex":   "^" + escapeRegex(userInput),  // Escaped
        "$options": "i",
    },
}
```

**Detection Commands:**

```bash
# MANDATORY: Run before every PR that touches MongoDB code
grep -rn '\$regex' internal/adapters/mongodb --include="*.go"

# Review each match - if userInput is used without escaping: VIOLATION
# Expected: All $regex uses have escapeRegex() or validated input
```

### Connection Pooling (MANDATORY)

MongoDB connections without MaxPoolSize configuration cause connection exhaustion under load.

**⛔ FORBIDDEN: Default Pool Configuration**

```go
// ❌ FORBIDDEN: No MaxPoolSize configured
client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))

// ❌ FORBIDDEN: MaxPoolSize too high or too low
opts := options.Client().SetMaxPoolSize(1000)  // Too high - memory issues
opts := options.Client().SetMaxPoolSize(1)     // Too low - contention
```

**✅ CORRECT: Configure Pool Size Based on Load**

```go
// ✅ CORRECT: Configure MaxPoolSize in connection options
clientOpts := options.Client().
    ApplyURI(mongoURI).
    SetMaxPoolSize(uint64(cfg.MongoMaxPoolSize)).  // From environment
    SetMinPoolSize(10).                             // Maintain baseline
    SetMaxConnIdleTime(30 * time.Second)           // Release idle connections

client, err := mongo.Connect(ctx, clientOpts)
if err != nil {
    return nil, fmt.Errorf("failed to connect to MongoDB: %w", err)
}

// ✅ CORRECT: Verify connection
if err := client.Ping(ctx, nil); err != nil {
    return nil, fmt.Errorf("failed to ping MongoDB: %w", err)
}
```

**Pool Size Guidelines:**

| Workload             | MaxPoolSize | MinPoolSize | Rationale                |
| -------------------- | ----------- | ----------- | ------------------------ |
| Low (< 100 RPS)      | 50          | 5           | Conservative, low memory |
| Medium (100-500 RPS) | 100         | 10          | Balanced                 |
| High (> 500 RPS)     | 200         | 20          | High throughput          |

**Detection Commands:**

```bash
# Find MongoDB connection setup
grep -rn "mongo.Connect\|SetMaxPoolSize\|MaxPoolSize" internal/bootstrap --include="*.go"

# Expected: MaxPoolSize is set via configuration, not hardcoded or missing
```

### Index Management (MANDATORY)

Blocking index creation and deprecated SetBackground calls cause production issues.

**⛔ FORBIDDEN: Blocking Index Creation and Deprecated APIs**

```go
// ❌ FORBIDDEN: SetBackground (deprecated in MongoDB 4.2+)
indexModel := mongo.IndexModel{
    Keys: bson.D{{Key: "email", Value: 1}},
}
opts := options.CreateIndexes().SetBackground(true)  // DEPRECATED
collection.Indexes().CreateOne(ctx, indexModel, opts)

// ❌ FORBIDDEN: Blocking index creation on large collections
// (No background/non-blocking option specified)
collection.Indexes().CreateOne(ctx, indexModel)  // BLOCKS WRITES
```

**✅ CORRECT: Use CreateIndexes with Batch Operations**

```go
// ✅ CORRECT: Use CreateIndexes (plural) for batch index creation
// MongoDB 4.2+ creates indexes in background automatically for replica sets
indexModels := []mongo.IndexModel{
    {
        Keys:    bson.D{{Key: "email", Value: 1}},
        Options: options.Index().SetUnique(true),
    },
    {
        Keys:    bson.D{{Key: "created_at", Value: -1}},
        Options: options.Index().SetName("idx_created_at_desc"),
    },
}

// CreateIndexes (not CreateIndex) is non-blocking on replica sets
names, err := collection.Indexes().CreateMany(ctx, indexModels)
if err != nil {
    return fmt.Errorf("failed to create indexes: %w", err)
}
logger.Infof("Created indexes: %v", names)
```

**Index Creation Best Practices:**

| Method              | Blocking?         | Use Case                      |
| ------------------- | ----------------- | ----------------------------- |
| `CreateMany()`      | No (replica sets) | Production - multiple indexes |
| `CreateOne()`       | No (replica sets) | Production - single index     |
| SetBackground(true) | N/A - DEPRECATED  | **NEVER USE**                 |

**Detection Commands:**

```bash
# Find deprecated SetBackground usage
grep -rn "SetBackground" internal/adapters/mongodb --include="*.go"

# Expected: 0 matches (SetBackground is deprecated)

# Find index creation patterns
grep -rn "CreateIndex\|CreateMany\|CreateOne" internal/adapters/mongodb --include="*.go"

# Review: Ensure no blocking operations on large collections
```

### Anti-Rationalization Table

| Rationalization                         | Why It's WRONG                                           | Required Action             |
| --------------------------------------- | -------------------------------------------------------- | --------------------------- |
| "$regex is convenient for search"       | $regex with user input = injection. Use $text or escape. | **Use $eq or escape input** |
| "Default pool size works fine"          | Works until load spikes. Then connections exhaust.       | **Configure MaxPoolSize**   |
| "We have few documents, blocking is OK" | Few now = many later. Non-blocking is always safer.      | **Use CreateMany**          |
| "SetBackground still works"             | Deprecated = will be removed. Code breaks on upgrade.    | **Remove SetBackground**    |
| "MongoDB handles injection"             | MongoDB executes operators. $regex is an operator.       | **Escape or avoid $regex**  |
| "Connection pool is internal detail"    | Internal detail that causes production outages.          | **Configure explicitly**    |

### Complete MongoDB Connection Example

```go
// internal/bootstrap/config.go

type Config struct {
    // MongoDB
    MongoURI          string `env:"MONGO_URI" default:"mongodb"`
    MongoDBHost       string `env:"MONGO_HOST"`
    MongoDBName       string `env:"MONGO_NAME"`
    MongoDBUser       string `env:"MONGO_USER"`
    MongoDBPassword   string `env:"MONGO_PASSWORD"`
    MongoDBPort       string `env:"MONGO_PORT"`
    MongoDBParameters string `env:"MONGO_PARAMETERS"`
    MongoMaxPoolSize  int    `env:"MONGO_MAX_POOL_SIZE" default:"100"`
    MongoMinPoolSize  int    `env:"MONGO_MIN_POOL_SIZE" default:"10"`
}

func connectMongoDB(cfg *Config, logger libLog.Logger) (*mongo.Client, error) {
    // Build connection string
    mongoSource := fmt.Sprintf("%s://%s:%s@%s:%s/",
        cfg.MongoURI, cfg.MongoDBUser, cfg.MongoDBPassword,
        cfg.MongoDBHost, cfg.MongoDBPort)

    if cfg.MongoDBParameters != "" {
        mongoSource += "?" + cfg.MongoDBParameters
    }

    // Configure client options
    clientOpts := options.Client().
        ApplyURI(mongoSource).
        SetMaxPoolSize(uint64(cfg.MongoMaxPoolSize)).
        SetMinPoolSize(uint64(cfg.MongoMinPoolSize)).
        SetMaxConnIdleTime(30 * time.Second)

    // Connect
    client, err := mongo.Connect(context.Background(), clientOpts)
    if err != nil {
        return nil, fmt.Errorf("failed to connect to MongoDB: %w", err)
    }

    // Verify connection
    if err := client.Ping(context.Background(), nil); err != nil {
        return nil, fmt.Errorf("failed to ping MongoDB: %w", err)
    }

    logger.Infof("Connected to MongoDB at %s:%s", cfg.MongoDBHost, cfg.MongoDBPort)
    return client, nil
}
```

---

## Dependency Management (MANDATORY)

**⛔ HARD GATE:** All Go projects MUST use Go modules with explicit version pinning. Floating versions and vendoring without go.mod are FORBIDDEN.

### go.mod Requirements (MANDATORY)

```go
// ✅ CORRECT: Explicit Go version and module path
module github.com/LerianStudio/your-service

go 1.24

require (
    github.com/LerianStudio/lib-commons/v2 v2.4.0
    github.com/gofiber/fiber/v2 v2.52.0
    github.com/jackc/pgx/v5 v5.5.0
)
```

### Version Pinning Rules

| Type                  | Pattern           | Example                  | Required?    |
| --------------------- | ----------------- | ------------------------ | ------------ |
| Direct dependencies   | Exact version     | `v2.4.0`                 | ✅ MANDATORY |
| Indirect dependencies | Managed by go mod | `// indirect`            | Auto-managed |
| Pre-release           | Explicit commit   | `v0.0.0-20240101-abc123` | When needed  |

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Latest/floating versions
require (
    github.com/some/package v0.0.0 // WRONG: Not a real version
)

// ❌ FORBIDDEN: Missing go.sum
// go.sum MUST be committed to version control

// ❌ FORBIDDEN: Replacing with local paths in committed go.mod
replace github.com/LerianStudio/lib-commons => ../lib-commons // Development only
```

### Security Updates (MANDATORY)

**Run weekly or before each release:**

```bash
# Check for vulnerabilities
go list -m -json all | go run golang.org/x/vuln/cmd/govulncheck@latest

# Update dependencies (review changes before committing)
go get -u ./...
go mod tidy

# Verify no breaking changes
go build ./...
go test ./...
```

### Dependency Review Checklist

```text
Before adding a new dependency:

[ ] Is it actively maintained? (commits within last 6 months)
[ ] Does it have a license compatible with Apache 2.0?
[ ] Is the version stable (not v0.x.x for production)?
[ ] Does it duplicate functionality already in lib-commons?
[ ] Is the transitive dependency count acceptable?

If any checkbox fails → Reconsider or document exception.
```

### Private Modules (GOPRIVATE)

```bash
# For Lerian private repos
export GOPRIVATE=github.com/LerianStudio/*

# In ~/.gitconfig
[url "ssh://git@github.com/"]
    insteadOf = https://github.com/
```

### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR with dependency changes

# Check for missing go.sum entries
go mod verify

# Check for unused dependencies
go mod tidy -v

# List outdated dependencies
go list -m -u all

# Scan for vulnerabilities
govulncheck ./...

# Expected: go.sum is complete, no vulnerabilities, no unused deps
```

### Anti-Rationalization Table

| Rationalization                    | Why It's WRONG                                    | Required Action           |
| ---------------------------------- | ------------------------------------------------- | ------------------------- |
| "Latest is always best"            | Latest can have breaking changes or new bugs.     | **Pin explicit versions** |
| "go.sum is auto-generated"         | go.sum is a security artifact. Must be committed. | **Commit go.sum**         |
| "I'll update deps later"           | Later = security vulnerabilities accumulate.      | **Update regularly**      |
| "Small package, no license needed" | All OSS has licenses. Verify compatibility.       | **Check license**         |
| "Vendor folder is safer"           | Vendor without go.mod is unmaintainable.          | **Use go.mod + go.sum**   |
| "Replace directive for debugging"  | Replace directives break reproducible builds.     | **Remove before commit**  |

---
