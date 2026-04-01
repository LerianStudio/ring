# Code Example Standards Pattern

This file defines MANDATORY rules for code examples in pre-dev documents (PRDs, TRDs, task breakdowns, subtasks).

---

## ⛔ HARD GATE: lib-commons First (Go Projects)

MUST use lib-commons instead of creating custom utilities when generating Go code examples.

### What lib-commons Already Provides (do not recreate)

| Category | lib-commons Package | What It Provides |
|----------|---------------------|------------------|
| **Logging** | `libLog "github.com/LerianStudio/lib-commons/v2/commons/log"` | Logger interface for all logging |
| **Logger Init** | `libZap "github.com/LerianStudio/lib-commons/v2/commons/zap"` | Logger initialization (bootstrap only) |
| **Telemetry** | `libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"` | Tracing, spans, metrics |
| **Config** | `libCommons "github.com/LerianStudio/lib-commons/v2/commons"` | `SetConfigFromEnvVars()` |
| **HTTP** | `libHTTP "github.com/LerianStudio/lib-commons/v2/commons/net/http"` | Router, middleware, responses |
| **PostgreSQL** | `libPostgres "github.com/LerianStudio/lib-commons/v2/commons/postgres"` | Connection, pagination |
| **MongoDB** | `libMongo "github.com/LerianStudio/lib-commons/v2/commons/mongo"` | Connection management |
| **Redis** | `libRedis "github.com/LerianStudio/lib-commons/v2/commons/redis"` | Connection management |
| **Server** | `libServer "github.com/LerianStudio/lib-commons/v2/commons/server"` | Lifecycle, graceful shutdown |
| **Context** | `libCommons.TrackingContext` | Request context propagation |

### Verification Before Writing Code Examples

```text
Before writing any Go code example in subtasks:

[ ] 1. Does this example need logging?        → Use libLog.Logger
[ ] 2. Does this example need config loading? → Use libCommons.SetConfigFromEnvVars()
[ ] 3. Does this example need HTTP handling?  → Use libHTTP helpers
[ ] 4. Does this example need DB connection?  → Use libPostgres/libMongo/libRedis
[ ] 5. Does this example need telemetry?      → Use libOpentelemetry
[ ] 6. Does this example need server setup?   → Use libServer

If yes to any → Use lib-commons. Do not create custom helpers.
```

---

## ⛔ FORBIDDEN Patterns in Code Examples

### ❌ NEVER Create Custom Loggers

```go
// ❌ FORBIDDEN in code examples
package utils

import "go.uber.org/zap"

func NewLogger() *zap.Logger {
    logger, _ := zap.NewProduction()
    return logger
}

// ❌ FORBIDDEN: Custom log wrapper
func LogInfo(msg string, fields ...zap.Field) {
    logger.Info(msg, fields...)
}
```

**✅ CORRECT: Use lib-commons**

```go
import (
    libZap "github.com/LerianStudio/lib-commons/v2/commons/zap"
    libLog "github.com/LerianStudio/lib-commons/v2/commons/log"
)

// Bootstrap only
logger := libZap.NewLogger()

// In services/handlers - use the interface
func NewService(logger libLog.Logger) *Service {
    return &Service{logger: logger}
}
```

### ❌ NEVER Create Custom Config Loaders

```go
// ❌ FORBIDDEN in code examples
package config

import "os"

func LoadConfig() *Config {
    return &Config{
        DBHost: os.Getenv("DB_HOST"),
        DBPort: os.Getenv("DB_PORT"),
    }
}
```

**✅ CORRECT: Use lib-commons**

```go
import libCommons "github.com/LerianStudio/lib-commons/v2/commons"

type Config struct {
    DBHost string `env:"DB_HOST"`
    DBPort string `env:"DB_PORT"`
}

cfg := &Config{}
if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
    return nil, fmt.Errorf("failed to load config: %w", err)
}
```

### ❌ NEVER Create Custom HTTP Helpers

```go
// ❌ FORBIDDEN in code examples
package utils

func JSONResponse(c *fiber.Ctx, status int, data interface{}) error {
    return c.Status(status).JSON(data)
}

func ErrorResponse(c *fiber.Ctx, err error) error {
    return c.Status(500).JSON(map[string]string{"error": err.Error()})
}
```

**✅ CORRECT: Use lib-commons HTTP utilities**

```go
import libHTTP "github.com/LerianStudio/lib-commons/v2/commons/net/http"

// Use lib-commons response helpers and middleware
```

### ❌ NEVER Create Custom Telemetry Wrappers

```go
// ❌ FORBIDDEN in code examples
package telemetry

import "go.opentelemetry.io/otel/trace"

func StartSpan(ctx context.Context, name string) (context.Context, trace.Span) {
    tracer := otel.GetCore threeProvider().Core three("my-service")
    return tracer.Start(ctx, name)
}
```

**✅ CORRECT: Use lib-commons**

```go
import libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"

// Initialize in bootstrap
provider := libOpentelemetry.NewCore threeProvider(/* config */)

// Use standard otel APIs with lib-commons provider
```

---

## When Custom Code IS Allowed in Examples

| Scenario | Allowed? | Condition |
|----------|----------|-----------|
| Infrastructure utilities (logging, config, HTTP, DB) | ❌ NO | Use lib-commons |
| Domain-specific business logic | ✅ YES | Business rules are project-specific |
| Service layer code | ✅ YES | Uses lib-commons for infrastructure |
| Repository implementations | ✅ YES | Uses libPostgres/libMongo for connections |
| API handlers | ✅ YES | Uses libHTTP for middleware |
| Validation logic | ✅ YES | Domain validation is project-specific |
| Data transformation (ToEntity/FromEntity) | ✅ YES | Domain mapping is project-specific |

---

## Anti-Rationalization Table

| Rationalization | Why it's wrong | Required Action |
|-----------------|----------------|-----------------|
| "Custom helper is simpler for this example" | Examples teach patterns. Teach the right pattern (lib-commons). | **Use lib-commons** in example |
| "lib-commons import is too verbose" | Verbosity is intentional for clarity. Don't hide dependencies. | **Show full lib-commons imports** |
| "I don't know if lib-commons has this" | Check before writing. See table above. | **Verify lib-commons first** |
| "The example is just pseudocode" | Pseudocode with custom helpers trains wrong patterns. | **Use real lib-commons calls** |
| "Engineers will replace with lib-commons later" | Later = never. Show correct pattern from start. | **Use lib-commons now** |
| "This is just a quick example" | Quick examples become production code. Do it right. | **Use lib-commons** |
| "Custom utils are easier to understand" | Understanding wrong patterns is worse than not understanding. | **Use lib-commons** |

---

## Integration with Subtask Creation

When creating subtasks with code examples (Gate 8), apply these rules:

1. **Step 1 (Write failing test)**: Tests can use custom test helpers
2. **Step 3 (Write implementation)**: Implementation MUST use lib-commons for infrastructure
3. **Imports**: Always show complete lib-commons imports with `lib` prefix aliases

**Example subtask code block:**

```go
// Step 3: Implement the service

// internal/service/user_service.go
package service

import (
    "context"

    libLog "github.com/LerianStudio/lib-commons/v2/commons/log"

    "github.com/your-org/your-service/internal/domain"
    "github.com/your-org/your-service/internal/repository"
)

type UserService struct {
    repo   repository.UserRepository
    logger libLog.Logger  // ✅ lib-commons logger interface
}

func NewUserService(repo repository.UserRepository, logger libLog.Logger) *UserService {
    return &UserService{
        repo:   repo,
        logger: logger,
    }
}

func (s *UserService) CreateUser(ctx context.Context, input domain.CreateUserInput) (*domain.User, error) {
    s.logger.Info("Creating user", "email", input.Email)  // ✅ Using lib-commons logger
    // ... implementation
}
```

---

## Checklist for Code Example Review

Before finalizing any document with Go code examples:

```text
[ ] 1. No custom logger creation (use libLog/libZap)
[ ] 2. No custom config loader (use libCommons.SetConfigFromEnvVars)
[ ] 3. No custom HTTP helpers (use libHTTP)
[ ] 4. No custom telemetry wrapper (use libOpentelemetry)
[ ] 5. No custom DB connection helpers (use libPostgres/libMongo/libRedis)
[ ] 6. No custom server lifecycle (use libServer)
[ ] 7. All imports show full lib-commons paths with lib prefix

If any checkbox is unchecked → Fix code example before publishing.
```
