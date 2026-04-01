# Go Standards - Security

> **Module:** security.md | **Sections:** 7 | **Parent:** [index.md](index.md)

This module covers authentication, licensing, and secret protection.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Access Manager Integration](#access-manager-integration-mandatory) | lib-auth integration for authn/authz |
| 2 | [License Manager Integration](#license-manager-integration-mandatory) | lib-license-go for license validation |
| 3 | [Secret Redaction Patterns](#secret-redaction-patterns-mandatory) | Preventing credential leaks in logs |
| 4 | [SQL Safety](#sql-safety-mandatory) | SQL injection prevention and parameterized queries |
| 5 | [HTTP Security Headers](#http-security-headers-mandatory) | X-Content-Type-Options, X-Frame-Options |
| 6 | [Rate Limiting](#rate-limiting-mandatory) | Three-tier rate limiting with Redis-backed storage, Trusted Proxy configuration |
| 7 | [CORS Configuration](#cors-configuration-mandatory) | Cross-Origin Resource Sharing setup and production validation |

---

## Access Manager Integration (MANDATORY)

All services **MUST** integrate with the Access Manager system for authentication and authorization. Services use `lib-auth` to communicate with `plugin-auth`, which handles token validation and permission enforcement.

### Architecture Overview

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         ACCESS MANAGER                               │
├─────────────────────────────────┬───────────────────────────────────┤
│  identity                       │  plugin-auth                      │
│  (CRUD: users, apps, groups,    │  (authn + authz)                  │
│   permissions)                  │                                   │
└─────────────────────────────────┴───────────────────────────────────┘
                                    ▲
                                    │ HTTP API
                                    │
┌───────────────────────────────────┴───────────────────────────────────┐
│                              lib-auth                                  │
│  (Go library - Fiber middleware for authorization)                     │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ import
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│  Consumer Services (midaz, plugin-fees, reporter, etc.)               │
└───────────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- **identity**: Manages Users, Applications, Groups, and Permissions (CRUD operations)
- **plugin-auth**: Handles authentication (authn) and authorization (authz) via token validation
- **lib-auth**: Go library that services import to integrate with plugin-auth

### Required Import

```go
import (
    authMiddleware "github.com/LerianStudio/lib-auth/v2/auth/middleware"
)
```

### Required Environment Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `PLUGIN_AUTH_ADDRESS` | string | URL of plugin-auth service | `http://plugin-auth:4000` |
| `PLUGIN_AUTH_ENABLED` | bool | Enable/disable auth checks | `true` |

**For service-to-service authentication (optional):**

| Variable | Type | Description |
|----------|------|-------------|
| `CLIENT_ID` | string | OAuth2 client ID for this service |
| `CLIENT_SECRET` | string | OAuth2 client secret for this service |

### Configuration Struct

```go
// bootstrap/config.go
type Config struct {
    // ... other fields ...

    // Access Manager
    AuthAddress string `env:"PLUGIN_AUTH_ADDRESS"`
    AuthEnabled bool   `env:"PLUGIN_AUTH_ENABLED"`

    // Service-to-Service Auth (optional)
    ClientID     string `env:"CLIENT_ID"`
    ClientSecret string `env:"CLIENT_SECRET"`
}
```

### Bootstrap Integration

```go
// bootstrap/config.go
func InitServers() (*Service, error) {
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        return nil, fmt.Errorf("failed to load config: %w", err)
    }

    logger := libZap.InitializeLogger()

    // ... telemetry, database initialization ...

    // Initialize Access Manager client
    auth := authMiddleware.NewAuthClient(cfg.AuthAddress, cfg.AuthEnabled, &logger)

    // Pass auth client to router
    httpApp := httpin.NewRouter(logger, telemetry, auth, handlers...)

    // ... rest of initialization ...
}
```

### Router Setup with Auth Middleware

```go
// adapters/http/in/routes.go
import (
    authMiddleware "github.com/LerianStudio/lib-auth/v2/auth/middleware"
)

const applicationName = "your-service-name"

func NewRouter(
    lg libLog.Logger,
    tl *libOpentelemetry.Telemetry,
    auth *authMiddleware.AuthClient,
    handler *YourHandler,
) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler:          libHTTP.HandleFiberError,
    })

    // Middleware setup
    tlMid := libHTTP.NewTelemetryMiddleware(tl)
    f.Use(tlMid.WithTelemetry(tl))
    f.Use(recover.New())

    // Protected routes with authorization
    f.Post("/v1/resources", auth.Authorize(applicationName, "resources", "post"), handler.Create)
    f.Get("/v1/resources", auth.Authorize(applicationName, "resources", "get"), handler.List)
    f.Get("/v1/resources/:id", auth.Authorize(applicationName, "resources", "get"), handler.Get)
    f.Patch("/v1/resources/:id", auth.Authorize(applicationName, "resources", "patch"), handler.Update)
    f.Delete("/v1/resources/:id", auth.Authorize(applicationName, "resources", "delete"), handler.Delete)

    // Health and version (no auth required)
    f.Get("/health", libHTTP.Health)
    f.Get("/version", libHTTP.Version)

    f.Use(tlMid.EndTracingSpans)

    return f
}
```

### Authorize Middleware Parameters

```go
auth.Authorize(applicationName, resource, action)
```

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `applicationName` | string | Service identifier (must match identity registration) | `"midaz"`, `"plugin-fees"` |
| `resource` | string | Resource being accessed | `"ledgers"`, `"transactions"`, `"packages"` |
| `action` | string | HTTP method (lowercase) | `"get"`, `"post"`, `"patch"`, `"delete"` |

### Middleware Behavior

| Scenario | HTTP Response |
|----------|---------------|
| Auth disabled (`PLUGIN_AUTH_ENABLED=false`) | Skips check, calls `next()` |
| Missing Authorization header | `401 Unauthorized` |
| Token invalid or expired | `401 Unauthorized` |
| User lacks permission | `403 Forbidden` |
| User authorized | Calls `next()` |

### Service-to-Service Authentication

When a service needs to call another service (e.g., plugin-fees calling midaz), use `GetApplicationToken`:

```go
// pkg/net/http/external_service.go
import (
    "context"
    "os"
    authMiddleware "github.com/LerianStudio/lib-auth/v2/auth/middleware"
)

type ExternalServiceClient struct {
    authClient *authMiddleware.AuthClient
    baseURL    string
}

func (c *ExternalServiceClient) CallExternalService(ctx context.Context) (*Response, error) {
    // Get application token using client credentials flow
    token, err := c.authClient.GetApplicationToken(
        ctx,
        os.Getenv("CLIENT_ID"),
        os.Getenv("CLIENT_SECRET"),
    )
    if err != nil {
        return nil, fmt.Errorf("failed to get application token: %w", err)
    }

    // Create request with token
    req, _ := http.NewRequestWithContext(ctx, "GET", c.baseURL+"/v1/resource", nil)
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Content-Type", "application/json")

    // Inject trace context for distributed tracing
    libOpentelemetry.InjectHTTPContext(&req.Header, ctx)

    resp, err := c.httpClient.Do(req)
    // ... handle response
}
```

### Common Headers

| Header | Purpose | Example |
|--------|---------|---------|
| `Authorization` | Bearer token for authentication | `Bearer eyJhbG...` |
| `X-Organization-Id` | Organization context for multi-tenancy | UUID |
| `X-Ledger-Id` | Ledger context (when applicable) | UUID |

### Organization ID Middleware Pattern

```go
// adapters/http/in/middlewares.go
const OrgIDHeaderParameter = "X-Organization-Id"

func ParseHeaderParameters(c *fiber.Ctx) error {
    headerParam := c.Get(OrgIDHeaderParameter)
    if headerParam == "" {
        return libHTTP.WithError(c, ErrMissingOrganizationID)
    }

    parsedUUID, err := uuid.Parse(headerParam)
    if err != nil {
        return libHTTP.WithError(c, ErrInvalidOrganizationID)
    }

    c.Locals(OrgIDHeaderParameter, parsedUUID)
    return c.Next()
}
```

### Complete Route Example with Headers

```go
// Route with auth + header parsing
f.Post("/v1/packages",
    auth.Authorize(applicationName, "packages", "post"),
    ParseHeaderParameters,
    handler.CreatePackage)
```

### What not to Do

```go
// FORBIDDEN: Hardcoded tokens
req.Header.Set("Authorization", "Bearer hardcoded-token-here")  // never

// FORBIDDEN: Skipping auth on protected endpoints
f.Post("/v1/sensitive-data", handler.Create)  // Missing auth.Authorize

// FORBIDDEN: Using wrong application name
auth.Authorize("wrong-app-name", "resource", "post")  // Must match identity registration

// FORBIDDEN: Direct calls to plugin-auth API
http.Post("http://plugin-auth:4000/v1/authorize", ...)  // Use lib-auth instead

// CORRECT: Always use lib-auth for auth operations
auth.Authorize(applicationName, "resource", "post")
token, _ := auth.GetApplicationToken(ctx, clientID, clientSecret)
```

### Testing with Auth Disabled

For local development and testing, disable auth via environment:

```bash
PLUGIN_AUTH_ENABLED=false
```

When disabled, `auth.Authorize()` middleware calls `next()` without validation.

---

## License Manager Integration (MANDATORY)

All licensed plugins/products **MUST** integrate with the License Manager system for license validation. Services use `lib-license-go` to validate licenses against the Lerian backend, with support for both global and multi-organization modes.

### Architecture Overview

```text
┌─────────────────────────────────────────────────────────────────────┐
│                       LICENSE MANAGER                               │
├─────────────────────────────────────────────────────────────────────┤
│  Lerian License Backend (AWS API Gateway)                           │
│  - Validates license keys                                           │
│  - Returns plugin entitlements                                      │
│  - Supports global and per-organization licenses                    │
└─────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ HTTPS API
                                    │
┌───────────────────────────────────┴───────────────────────────────────┐
│                           lib-license-go                              │
│  (Go library - Fiber middleware + gRPC interceptors)                  │
│  - Ristretto in-memory cache                                          │
│  - Weekly background refresh                                          │
│  - Startup validation (fail-fast)                                     │
└───────────────────────────────────┬───────────────────────────────────┘
                                    │ import
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│  Licensed Services (plugin-fees, reporter, etc.)                      │
└───────────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- **Global Mode**: Single license key validates entire plugin (use `ORGANIZATION_IDS=global`)
- **Multi-Org Mode**: Per-organization license validation via `X-Organization-Id` header
- **Fail-Fast**: Service returns error at startup if no valid license found (caller decides termination)

### Required Import

```go
import (
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)
```

### Required Environment Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `LICENSE_KEY` | string | License key for this plugin | `lic_xxxxxxxxxxxx` |
| `ORGANIZATION_IDS` | string | Comma-separated org IDs or "global" | `org1,org2` or `global` |

### Configuration Struct

```go
// bootstrap/config.go
type Config struct {
    // ... other fields ...

    // License Manager
    LicenseKey      string `env:"LICENSE_KEY"`
    OrganizationIDs string `env:"ORGANIZATION_IDS"`
}
```

### Bootstrap Integration

```go
// bootstrap/config.go
import (
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)

func InitServers() (*Service, error) {
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        return nil, fmt.Errorf("failed to load config: %w", err)
    }

    logger := libZap.InitializeLogger()

    // ... telemetry, database initialization ...

    // Initialize License Manager client
    licenseClient := libLicense.NewLicenseClient(
        constant.ApplicationName,  // e.g., "plugin-fees"
        cfg.LicenseKey,
        cfg.OrganizationIDs,
        &logger,
    )

    // Pass license client to router and server
    httpApp := httpin.NewRouter(logger, telemetry, auth, licenseClient, handlers...)
    serverAPI := NewServer(cfg, httpApp, logger, telemetry, licenseClient)

    // ... rest of initialization ...
}
```

### Router Setup with License Middleware

```go
// adapters/http/in/routes.go
import (
    libHTTP "github.com/LerianStudio/lib-commons/v2/commons/net/http"
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)

func NewRoutes(lg log.Logger, tl *opentelemetry.Telemetry, handler *YourHandler, lc *libLicense.LicenseClient) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler: func(ctx *fiber.Ctx, err error) error {
            return libHTTP.HandleFiberError(ctx, err)
        },
    })
    tlMid := libHTTP.NewTelemetryMiddleware(tl)

    // License middleware - applies GLOBALLY (must be early in chain)
    f.Use(lc.Middleware())

    // Other middleware
    f.Use(tlMid.WithTelemetry(tl))
    f.Use(libHTTP.WithHTTPLogging(libHTTP.WithCustomLogger(lg)))

    // Routes
    v1 := f.Group("/v1")
    v1.Post("/resources", handler.Create)
    v1.Get("/resources", handler.List)

    // Health and version (automatically skipped by license middleware)
    f.Get("/health", libHTTP.Ping)
    f.Get("/version", libHTTP.Version)

    f.Use(tlMid.EndTracingSpans)

    return f
}
```

**Note:** License middleware should be applied early in the middleware chain. It automatically skips `/health`, `/version`, and `/swagger/` paths.

### Server Integration with Graceful Shutdown

```go
// bootstrap/server.go
import (
    libCommonsLicense "github.com/LerianStudio/lib-commons/v2/commons/license"
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)

type Server struct {
    app           *fiber.App
    serverAddress string
    license       *libCommonsLicense.ManagerShutdown
    logger        libLog.Logger
    telemetry     libOpentelemetry.Telemetry
}

func NewServer(cfg *Config, app *fiber.App, logger libLog.Logger, telemetry *libOpentelemetry.Telemetry, licenseClient *libLicense.LicenseClient) *Server {
    return &Server{
        app:           app,
        serverAddress: cfg.ServerAddress,
        license:       licenseClient.GetLicenseManagerShutdown(),
        logger:        logger,
        telemetry:     *telemetry,
    }
}

func (s *Server) Run(l *libCommons.Launcher) error {
    // License manager integrated into graceful shutdown
    libCommonsServer.NewServerManager(s.license, &s.telemetry, s.logger).
        WithHTTPServer(s.app, s.serverAddress).
        StartWithGracefulShutdown()

    return nil
}
```

### Default Skip Paths

The license middleware automatically skips validation for:

| Path | Reason |
|------|--------|
| `/health` | Health checks must always respond |
| `/version` | Version endpoint is public |
| `/swagger/` | API documentation is public |

### gRPC Integration (If Applicable)

```go
// For gRPC services
import (
    "google.golang.org/grpc"
    libLicense "github.com/LerianStudio/lib-license-go/v2/middleware"
)

func NewGRPCServer(licenseClient *libLicense.LicenseClient) *grpc.Server {
    server := grpc.NewServer(
        grpc.UnaryInterceptor(licenseClient.UnaryServerInterceptor()),
        grpc.StreamInterceptor(licenseClient.StreamServerInterceptor()),
    )

    // Register your services
    pb.RegisterYourServiceServer(server, &yourServiceImpl{})

    return server
}
```

### Middleware Behavior

| Mode | Startup | Per-Request |
|------|---------|-------------|
| Global (`ORGANIZATION_IDS=global`) | Validates license, returns error if invalid | Skips validation, calls `next()` |
| Multi-Org | Validates all orgs, returns error if none valid | Validates `X-Organization-Id` header |

### Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `LCS-0001` | 500 | Internal server error during validation |
| `LCS-0002` | 400 | No organization IDs configured |
| `LCS-0003` | 403 | No valid licenses found for any organization |
| `LCS-0010` | 400 | Missing `X-Organization-Id` header |
| `LCS-0011` | 400 | Unknown organization ID |
| `LCS-0012` | 403 | Failed to validate organization license |
| `LCS-0013` | 403 | Organization license is invalid or expired |

### What not to Do

```go
// FORBIDDEN: Hardcoded license keys
licenseClient := libLicense.NewLicenseClient(appName, "hardcoded-key", orgIDs, &logger)  // never

// FORBIDDEN: Skipping license middleware on licensed routes
f.Post("/v1/paid-feature", handler.Create)  // Missing lc.Middleware()

// FORBIDDEN: Not integrating shutdown manager
libCommonsServer.NewServerManager(nil, &s.telemetry, s.logger)  // Missing license shutdown

// CORRECT: Always use environment variables and integrate shutdown
licenseClient := libLicense.NewLicenseClient(appName, cfg.LicenseKey, cfg.OrganizationIDs, &logger)
libCommonsServer.NewServerManager(s.license, &s.telemetry, s.logger)
```

### Testing with License Disabled

For local development without license validation, you can omit the license client initialization or use a mock. The service will return an error at startup if `LICENSE_KEY` is set but invalid (the caller decides whether to terminate).

**Tip:** For development, either:
1. Use a valid development license key
2. Comment out the license middleware during local development
3. Use the development license server: `IS_DEVELOPMENT=true`

---

## Secret Redaction Patterns (MANDATORY)

**⛔ HARD GATE:** Credentials, connection strings, API keys, and tokens MUST NOT appear in logs. Exposing AMQP, database DSNs, or API credentials in logs creates security vulnerabilities.

### FORBIDDEN Patterns (CRITICAL)

```go
// ❌ FORBIDDEN: Logging connection strings
logger.Infof("Connecting to: %s", amqpURI)  // EXPOSES: amqp://user:password@host:5672

// ❌ FORBIDDEN: Logging DSN/connection strings
logger.Infof("Database: %s", databaseDSN)  // EXPOSES: postgres://user:password@host/db

// ❌ FORBIDDEN: Logging environment variables with secrets
for k, v := range os.Environ() {
    logger.Infof("%s=%s", k, v)  // EXPOSES: DB_PASSWORD, API_KEY, etc.
}

// ❌ FORBIDDEN: Logging config struct with secrets
logger.Infof("Config: %+v", cfg)  // EXPOSES: all fields including passwords

// ❌ FORBIDDEN: Logging HTTP headers with auth
logger.Infof("Headers: %v", req.Header)  // EXPOSES: Authorization header

// ❌ FORBIDDEN: Using fmt.Printf for connection strings
fmt.Printf("AMQP: %s\n", amqpURI)  // EXPOSES: credentials to stdout
```

### Correct Patterns (REQUIRED)

```go
// ✅ CORRECT: Redact connection strings before logging
func redactConnectionString(uri string) string {
    // amqp://user:password@host:5672 → amqp://***:***@host:5672
    u, err := url.Parse(uri)
    if err != nil {
        return "[invalid-uri]"
    }
    if u.User != nil {
        u.User = url.UserPassword("***", "***")
    }
    return u.String()
}

logger.Infof("Connecting to: %s", redactConnectionString(amqpURI))

// ✅ CORRECT: Log only safe portions
logger.Infof("Connecting to RabbitMQ at %s:%s", cfg.RabbitMQHost, cfg.RabbitMQPort)

// ✅ CORRECT: Redact config before logging
type SafeConfig struct {
    Host     string `json:"host"`
    Port     string `json:"port"`
    Database string `json:"database"`
    // Password omitted
}
logger.Infof("Config: %+v", SafeConfig{Host: cfg.Host, Port: cfg.Port, Database: cfg.Database})

// ✅ CORRECT: Use lib-commons logger (automatically redacts sensitive patterns)
logger.Infof("Service started on %s", cfg.ServerAddress)  // No secrets in this field
```

### Secrets that MUST NOT be Logged

| Secret Type | Example Pattern | Detection Regex |
|-------------|-----------------|-----------------|
| AMQP URI | `amqp://user:pass@host` | `amqp://[^:]+:[^@]+@` |
| Postgres DSN | `postgres://user:pass@host/db` | `postgres://[^:]+:[^@]+@` |
| MongoDB URI | `mongodb://user:pass@host` | `mongodb://[^:]+:[^@]+@` |
| Redis URI | `redis://user:pass@host` | `redis://[^:]+:[^@]+@` |
| API Keys | `sk_live_xxxxx`, `api_key=xxxxx` | `(sk_|api[_-]?key)` (use with `grep -E`) |
| Bearer Tokens | `Authorization: Bearer xxx` | `Bearer\s+[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+` |
| AWS Credentials | `AKIA...`, `aws_secret_access_key` | `AKIA[A-Z0-9]{16}` |

### Detection Commands (MANDATORY)

Use **extended regex** for the API Keys pattern: run `grep -E` with pattern `(sk_|api[_-]?key)`. For basic grep (no `-E`), escape alternation and quantifiers: `sk_\|api[_-]\?key`. Prefer `grep -E '(sk_|api[_-]?key)'` for clarity. See table above for the exact pattern and this section for which form to use.

```bash
# MANDATORY: Run before every PR that touches config or logging

# Find direct connection string logging
grep -rn "log.*amqp://\|fmt.Print.*amqp://\|logger.*amqp://" --include="*.go"
grep -rn "log.*postgres://\|fmt.Print.*postgres://\|logger.*postgres://" --include="*.go"
grep -rn "log.*mongodb://\|fmt.Print.*mongodb://\|logger.*mongodb://" --include="*.go"

# Find password logging
grep -rn "password.*log\|log.*password" --include="*.go" -i

# Find config struct logging (review each match)
grep -rn 'Infof.*%\+v.*cfg\|Printf.*%\+v.*config' --include="*.go"

# Find environment variable dumps
grep -rn "os.Environ\(\)" --include="*.go"

# Expected: 0 matches for connection strings with credentials
# If any match found: STOP. Fix before proceeding.
```

### lib-commons Logger Configuration

When using lib-commons logger, configure secret redaction:

```go
// lib-commons/v2 automatically redacts certain patterns
// But you MUST NOT pass secrets to the logger in the first place

// ❌ Still FORBIDDEN even with lib-commons:
logger.Infof("Config: %+v", cfg)  // May contain secrets

// ✅ CORRECT: Only log safe fields
logger.Infof("Server starting on %s", cfg.ServerAddress)
```

### Environment Variable Handling

```go
// ❌ FORBIDDEN: Iterating and logging all env vars
for _, env := range os.Environ() {
    log.Println(env)
}

// ✅ CORRECT: Log only specific, safe env vars
logger.Infof("Environment: %s, Server: %s", os.Getenv("ENV_NAME"), os.Getenv("SERVER_ADDRESS"))

// ✅ CORRECT: Use structured config loading (lib-commons)
func loadConfig() (*Config, error) {
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        return nil, fmt.Errorf("load config: %w", err)
    }
    return cfg, nil
}
```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We need connection strings for debugging" | Logs are stored and shared. Secrets leak to CloudWatch, Grafana, S3. | **Log redacted strings only** |
| "Only developers see logs" | Logs go to centralized systems accessible by many. | **Redact all secrets** |
| "It's just the dev environment" | Dev logs train bad habits. Same code goes to prod. | **Redact in all environments** |
| "The password is rotated anyway" | Rotation doesn't help if old password is in logs. | **Never log secrets** |
| "I'm just debugging locally" | Local debugging code gets committed. | **Remove debug logging before commit** |
| "lib-commons handles it" | lib-commons can't redact what you pass to it. | **Don't pass secrets to logger** |

### Verification Checklist (Before PR)

```text
Before submitting PR that adds logging:

[ ] Did I search for connection string patterns in my changes?
[ ] Did I verify no passwords are logged (even in debug statements)?
[ ] Did I avoid logging entire config structs (%+v)?
[ ] Did I avoid logging HTTP headers that may contain Authorization?
[ ] Did I run the detection commands above?

If any checkbox is unchecked → FIX before submitting.
```

---

## SQL Safety (MANDATORY)

**⛔ HARD GATE:** All database queries MUST use parameterized queries. String concatenation in SQL is FORBIDDEN and creates injection vulnerabilities.

### FORBIDDEN Patterns (CRITICAL)

```go
// ❌ FORBIDDEN: String concatenation in SQL
query := "SELECT * FROM users WHERE id = '" + userID + "'"
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)
query := "DELETE FROM orders WHERE status = " + status

// ❌ FORBIDDEN: Building WHERE clauses with user input
whereClause := "name LIKE '%" + searchTerm + "%'"
query := "SELECT * FROM products WHERE " + whereClause

// ❌ FORBIDDEN: Dynamic table/column names from user input
tableName := req.Query("table")
query := fmt.Sprintf("SELECT * FROM %s", tableName)

// ❌ FORBIDDEN: Raw queries with string interpolation
db.Raw("SELECT * FROM users WHERE role = '" + role + "'")
```

### Correct Patterns (REQUIRED)

```go
// ✅ CORRECT: Parameterized queries with pgx
row := conn.QueryRow(ctx,
    "SELECT id, name, email FROM users WHERE id = $1",
    userID,
)

// ✅ CORRECT: Multiple parameters
rows, err := conn.Query(ctx,
    "SELECT * FROM orders WHERE user_id = $1 AND status = $2 AND created_at > $3",
    userID, status, startDate,
)

// ✅ CORRECT: IN clause with pgx.Array
rows, err := conn.Query(ctx,
    "SELECT * FROM products WHERE id = ANY($1)",
    pgx.Array(productIDs),
)

// ✅ CORRECT: LIKE with parameterized pattern
searchPattern := "%" + sanitizeSearchTerm(term) + "%"
rows, err := conn.Query(ctx,
    "SELECT * FROM products WHERE name ILIKE $1",
    searchPattern,
)

// ✅ CORRECT: Using query builders (squirrel)
query, args, err := sq.Select("id", "name").
    From("users").
    Where(sq.Eq{"status": status}).
    Where(sq.Like{"email": "%" + domain}).
    ToSql()
rows, err := conn.Query(ctx, query, args...)

// ✅ CORRECT: Dynamic columns with whitelist
allowedColumns := map[string]bool{"name": true, "email": true, "created_at": true}
if !allowedColumns[sortColumn] {
    sortColumn = "created_at" // Default to safe column
}
query := fmt.Sprintf("SELECT * FROM users ORDER BY %s", sortColumn)
```

### pgx Parameterization Reference

| Pattern | Syntax | Example |
|---------|--------|---------|
| Single value | `$1` | `WHERE id = $1` |
| Multiple values | `$1, $2, $3` | `WHERE a = $1 AND b = $2` |
| Array/IN clause | `ANY($1)` with `pgx.Array()` | `WHERE id = ANY($1)` |
| NULL check | `$1 IS NULL OR col = $1` | Optional filters |

### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR that touches database code

# Find string concatenation in SQL contexts
grep -rn 'Sprintf.*SELECT\|Sprintf.*INSERT\|Sprintf.*UPDATE\|Sprintf.*DELETE' --include="*.go"
grep -rn 'SELECT.*" \+ \|INSERT.*" \+ \|UPDATE.*" \+ \|DELETE.*" \+ ' --include="*.go"

# Find Raw() with string interpolation
grep -rn 'Raw(".*" \+\|Raw(fmt.Sprintf' --include="*.go"

# Find fmt in SQL files
grep -rn 'fmt.Sprintf.*FROM\|fmt.Sprintf.*WHERE' --include="*.go"

# Expected: 0 matches
# If any match found: STOP. Fix before proceeding.
```

### Whitelist Pattern for Dynamic Identifiers

```go
// When table/column names must be dynamic (e.g., multi-tenant schemas)
// ALWAYS use explicit whitelists

var allowedTables = map[string]bool{
    "users":    true,
    "orders":   true,
    "products": true,
}

func queryTable(ctx context.Context, conn *pgx.Conn, table string, id string) (*Row, error) {
    // ✅ CORRECT: Whitelist validation before any SQL
    if !allowedTables[table] {
        return nil, fmt.Errorf("invalid table: %s", table)
    }

    // Table name is safe (from whitelist), ID is parameterized
    query := fmt.Sprintf("SELECT * FROM %s WHERE id = $1", table)
    return conn.QueryRow(ctx, query, id), nil
}
```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Input is validated elsewhere" | Defense in depth. SQL injection at query level is catastrophic. | **Always parameterize** |
| "Only internal services call this" | Internal services can be compromised. Assume hostile input. | **Always parameterize** |
| "The value is a UUID/integer" | Type coercion can fail. Attacker controls types. | **Always parameterize** |
| "Performance is better with string concat" | False. Prepared statements are often faster. Security > micro-optimization. | **Always parameterize** |
| "It's just a read query" | SQL injection enables data exfiltration, not just writes. | **Always parameterize** |
| "Query builder handles it" | Verify the builder parameterizes. Some don't. | **Check generated SQL** |

### Verification Checklist (Before PR)

```text
Before submitting PR that touches database queries:

[ ] Did I use parameterized queries for all user input?
[ ] Did I run the detection commands above?
[ ] Did I whitelist any dynamic table/column names?
[ ] Did I avoid string concatenation in SQL strings?
[ ] Did I verify query builders generate parameterized output?

If any checkbox is unchecked → FIX before submitting.
```

---

## HTTP Security Headers (MANDATORY)

**⛔ HARD GATE:** All HTTP services MUST set security headers to prevent common web vulnerabilities. Missing headers expose the application to clickjacking, MIME sniffing, and other attacks.

### Required Headers

| Header | Required Value | Purpose |
|--------|----------------|---------|
| `X-Content-Type-Options` | `nosniff` | Prevents MIME type sniffing attacks |
| `X-Frame-Options` | `DENY` | Prevents clickjacking via iframe embedding |

### Implementation Pattern (Fiber)

```go
// internal/adapters/http/in/middleware.go

func SecurityHeaders() fiber.Handler {
    return func(c *fiber.Ctx) error {
        // MANDATORY: Prevent MIME sniffing
        c.Set("X-Content-Type-Options", "nosniff")

        // MANDATORY: Prevent clickjacking
        c.Set("X-Frame-Options", "DENY")

        return c.Next()
    }
}

// Apply in router setup
func NewRouter(app *fiber.App) {
    app.Use(SecurityHeaders())
    // ... other middleware and routes
}
```

### Alternative: lib-commons Integration

If using lib-commons server setup, headers can be configured at server level:

```go
// bootstrap/fiber.server.go
serverConfig := libServer.Config{
    // ... other config
    SecurityHeaders: libServer.SecurityHeaders{
        XContentTypeOptions: "nosniff",
        XFrameOptions:       "DENY",
    },
}
```

### Detection Commands

```bash
# Find if security headers are set
grep -rn "X-Content-Type-Options\|X-Frame-Options" --include="*.go" ./internal

# Verify middleware registration
grep -rn "SecurityHeaders\|security.*middleware" --include="*.go" ./internal

# Expected: At least one match for each header
```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We're behind a reverse proxy" | Defense in depth. App should protect itself. | **Add headers** |
| "It's just an internal API" | Internal APIs can be accessed by compromised services. | **Add headers** |
| "Headers don't affect JSON APIs" | MIME sniffing affects all responses. Clickjacking targets browsers. | **Add headers** |
| "We'll add it later" | Later = security incident. Add now. | **Add headers immediately** |

---

## Rate Limiting (MANDATORY)

**⛔ HARD GATE:** All public APIs MUST implement rate limiting to prevent abuse, protect against DoS attacks, and ensure fair resource allocation across tenants.

### Why Rate Limiting Matters

Without rate limiting, a single-client can exhaust server resources, degrade performance for all users, and create cascading failures. Rate limiting is a fundamental security control that MUST be present before any service goes to production.

### Trusted Proxy Configuration (Prerequisite)

**⛔ HARD GATE:** Services deployed behind reverse proxies or load balancers MUST configure Fiber's trusted proxy check (`EnableTrustedProxyCheck` in v2, `TrustProxy` in v3) to obtain the real client IP. Without this, `c.IP()` returns the proxy IP, and the rate limiter treats all clients as a single source.

> **Version Note:** Examples below use Fiber v2 (current project standard per `core.md`).
> A v2 ↔ v3 field mapping table is provided for projects migrating to Fiber v3.
> MUST verify your Fiber version before implementing: `grep "gofiber/fiber" go.mod`

#### Why Trusted Proxy Is Required for Rate Limiting

| Scenario | Without TrustProxy | With TrustProxy |
|----------|-------------------|-----------------|
| Rate limiting by IP | Limits the proxy (all clients share one limit) | Limits each client individually |
| Audit logging | Logs proxy IP (useless for investigation) | Logs real client IP |
| Abuse detection | Cannot identify abusive client | Identifies real source |
| Geo-restrictions | Resolves to proxy location | Resolves to client location |

#### How Fiber Resolves `c.IP()`

```text
Request arrives → Is EnableTrustedProxyCheck enabled? (v2) / Is TrustProxy enabled? (v3)
                  │
                  ├── NO → c.IP() = TCP RemoteAddr (proxy IP behind LB)
                  │
                  └── YES → Is RemoteAddr in TrustedProxies list? (v2) / TrustProxyConfig.Proxies? (v3)
                            │
                            ├── YES → c.IP() = ProxyHeader value (real client IP)
                            │
                            └── NO → c.IP() = TCP RemoteAddr (untrusted, ignores headers)
```

#### Required Environment Variable

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `TRUSTED_PROXIES` | string | `""` | Comma-separated IPs/CIDRs of trusted proxies (e.g., `10.0.0.1,172.16.0.0/12`) |

#### Configuration Struct

```go
// internal/bootstrap/config.go

type ServerConfig struct {
    Address        string `env:"SERVER_ADDRESS"       envDefault:":8080"`
    TrustedProxies string `env:"TRUSTED_PROXIES"`
    // ... other fields ...
}
```

#### Implementation Pattern (Fiber)

```go
// internal/bootstrap/fiber_server.go

import (
    "strings"

    "github.com/gofiber/fiber/v2"
)

func NewFiberApp(cfg *Config) *fiber.App {
    fiberCfg := fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler:          libHTTP.HandleFiberError,
    }

    // Configure trusted proxies when behind a reverse proxy / load balancer
    if proxies := strings.TrimSpace(cfg.Server.TrustedProxies); proxies != "" {
        proxyList := strings.Split(proxies, ",")
        for i := range proxyList {
            proxyList[i] = strings.TrimSpace(proxyList[i])
        }

        fiberCfg.EnableTrustedProxyCheck = true
        fiberCfg.TrustedProxies = proxyList
        fiberCfg.ProxyHeader = fiber.HeaderXForwardedFor
        fiberCfg.EnableIPValidation = true
    }

    return fiber.New(fiberCfg)
}
```

#### App-Level Configuration (Not Middleware)

Trusted proxy is a `fiber.Config` field, not a middleware. It affects all calls to `c.IP()`, `c.IPs()`, `c.Protocol()`, and `c.Hostname()` globally. The rate limiter, audit logging, and any code that uses `c.IP()` automatically benefits from the correct client IP.

#### Fiber v2 ↔ v3 Field Mapping

| Purpose | Fiber v2 (current standard) | Fiber v3 |
|---|---|---|
| Enable proxy trust | `EnableTrustedProxyCheck: true` | `TrustProxy: true` |
| List of trusted proxies | `TrustedProxies: []string{...}` | `TrustProxyConfig: fiber.TrustProxyConfig{Proxies: []string{...}}` |
| Header to read client IP | `ProxyHeader: fiber.HeaderXForwardedFor` | *(automatic when TrustProxy is enabled)* |
| Validate IP format | `EnableIPValidation: true` | `EnableIPValidation: true` |

**Detection by version:**

```bash
# Check which version your project uses
grep "gofiber/fiber" go.mod
# fiber/v2 → use EnableTrustedProxyCheck, TrustedProxies, ProxyHeader
# fiber/v3 → use TrustProxy, TrustProxyConfig
```

#### Production Validation (MANDATORY)

**⛔ HARD GATE:** Services deployed behind proxies in production MUST have `TRUSTED_PROXIES` configured:

```go
// internal/bootstrap/config.go

func enforceProductionDefaults(cfg *Config, logger log.Logger) {
    // ... existing rate limit enforcement ...

    // Warn if TRUSTED_PROXIES is empty in production
    if cfg.App.EnvName == "production" && cfg.Server.TrustedProxies == "" {
        logger.Fatalf("SECURITY: TRUSTED_PROXIES is empty in production. " +
            "c.IP() will return the load balancer IP instead of the real client IP. " +
            "Rate limiting and audit logging will not work correctly. env=%s", cfg.App.EnvName)
    }
}
```

#### Configuration Examples

```bash
# Development (no proxy)
TRUSTED_PROXIES=

# Development with local proxy (e.g., nginx, traefik)
TRUSTED_PROXIES=127.0.0.1

# Production - single load balancer
TRUSTED_PROXIES=10.0.0.1

# Production - multiple proxies (LB + WAF)
TRUSTED_PROXIES=10.0.0.1,10.0.0.2

# Production - CIDR range (Kubernetes internal network)
TRUSTED_PROXIES=10.0.0.0/8,172.16.0.0/12

# Production - AWS ALB (use VPC CIDR)
TRUSTED_PROXIES=10.0.0.0/16
```

#### FORBIDDEN Trusted Proxy Patterns

```go
// ❌ FORBIDDEN: ProxyHeader without EnableTrustedProxyCheck (any client can forge the header)
fiber.Config{
    ProxyHeader: fiber.HeaderXForwardedFor,  // WRONG: trusts ALL requests, not just proxies
}

// ❌ FORBIDDEN: EnableTrustedProxyCheck without TrustedProxies list (trusts nobody, proxy headers ignored)
fiber.Config{
    EnableTrustedProxyCheck: true,
    // Missing TrustedProxies → empty list means no proxy is trusted, headers are ignored
}

// ❌ FORBIDDEN: Wildcard CIDR (equivalent to trusting everyone)
fiber.Config{
    EnableTrustedProxyCheck: true,
    TrustedProxies:          []string{"0.0.0.0/0"},  // WRONG: trusts entire internet
    ProxyHeader:             fiber.HeaderXForwardedFor,
}

// ❌ FORBIDDEN: Hardcoded proxy IPs (must use config)
fiber.Config{
    EnableTrustedProxyCheck: true,
    TrustedProxies:          []string{"10.0.0.1"},  // WRONG: use TRUSTED_PROXIES env var
    ProxyHeader:             fiber.HeaderXForwardedFor,
}

// ✅ CORRECT (Fiber v2): Configuration-driven, validated
proxyList := strings.Split(cfg.Server.TrustedProxies, ",")
fiber.Config{
    EnableTrustedProxyCheck: true,
    TrustedProxies:          proxyList,
    ProxyHeader:             fiber.HeaderXForwardedFor,
    EnableIPValidation:      true,
}
```

#### Trusted Proxy Detection Commands

```bash
# PREREQUISITE: Verify Fiber version
grep "gofiber/fiber" go.mod
# If fiber/v2 → use EnableTrustedProxyCheck, TrustedProxies, ProxyHeader (this section)
# If fiber/v3 → use TrustProxy, TrustProxyConfig (see v2 ↔ v3 mapping table above)

# Find trusted proxy configuration (Fiber v2)
grep -rn "EnableTrustedProxyCheck\|TrustedProxies" --include="*.go" ./internal
# Expected: At least 1 match in fiber_server.go or init.go

# Find standalone ProxyHeader usage (should be paired with EnableTrustedProxyCheck)
grep -rn "ProxyHeader" --include="*.go" ./internal
# Review: every ProxyHeader must have EnableTrustedProxyCheck = true

# Find c.IP() usage to verify all callers benefit from trusted proxy config
grep -rn "\.IP()" --include="*.go" ./internal
# Review: all should be behind trusted-proxy-configured Fiber app
```

#### Trusted Proxy Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We're on an internal network" | Internal networks don't prevent X-Forwarded-For header spoofing. | **Configure EnableTrustedProxyCheck with explicit proxy IPs** |
| "The load balancer already validates" | Defense in depth. The app MUST NOT trust headers from untrusted sources. | **Configure EnableTrustedProxyCheck** |
| "We only use UserID in the rate limiter" | UserID is the primary key, but IP is the fallback. Audit logs also need real IPs. | **Configure EnableTrustedProxyCheck** |
| "ProxyHeader is simpler" | Simpler and insecure. Any client can forge X-Forwarded-For. | **Use EnableTrustedProxyCheck + TrustedProxies + ProxyHeader** |
| "TRUSTED_PROXIES is hard to maintain" | Proxy IPs rarely change. Use CIDR ranges for flexibility. | **Use CIDR notation** |
| "We'll add it when we go to production" | Misconfigured c.IP() in dev hides bugs. | **Configure from day one** |

### Three-tier Rate Limiting Strategy

Services MUST implement tiered rate limiting based on endpoint sensitivity:

| Tier | Purpose | Default Limit | Applied To |
|------|---------|---------------|------------|
| **Global** | General API protection | 100 req/60s | All protected routes |
| **Export** | Resource-intensive operations | 10 req/60s | Report exports, bulk operations |
| **Dispatch** | External integration protection | 50 req/60s | Webhook dispatch, external calls |

### Required Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `RATE_LIMIT_ENABLED` | bool | `true` | Enable/disable rate limiting |
| `RATE_LIMIT_MAX` | int | `100` | Global max requests per window |
| `RATE_LIMIT_EXPIRY_SEC` | int | `60` | Global window duration in seconds |
| `EXPORT_RATE_LIMIT_MAX` | int | `10` | Export max requests per window |
| `EXPORT_RATE_LIMIT_EXPIRY_SEC` | int | `60` | Export window duration in seconds |
| `DISPATCH_RATE_LIMIT_MAX` | int | `50` | Dispatch max requests per window |
| `DISPATCH_RATE_LIMIT_EXPIRY_SEC` | int | `60` | Dispatch window duration in seconds |

### Configuration Struct

```go
// internal/bootstrap/config.go

type RateLimitConfig struct {
    Enabled           bool `env:"RATE_LIMIT_ENABLED"             envDefault:"true"`
    Max               int  `env:"RATE_LIMIT_MAX"                 envDefault:"100"`
    ExpirySec         int  `env:"RATE_LIMIT_EXPIRY_SEC"          envDefault:"60"`
    ExportMax         int  `env:"EXPORT_RATE_LIMIT_MAX"          envDefault:"10"`
    ExportExpirySec   int  `env:"EXPORT_RATE_LIMIT_EXPIRY_SEC"   envDefault:"60"`
    DispatchMax       int  `env:"DISPATCH_RATE_LIMIT_MAX"        envDefault:"50"`
    DispatchExpirySec int  `env:"DISPATCH_RATE_LIMIT_EXPIRY_SEC" envDefault:"60"`
}
```

### Redis-Backed Distributed Storage

Rate limiting MUST use Redis for distributed state across multiple instances. The storage layer implements Fiber's `fiber.Storage` interface:

```go
// pkg/http/ratelimit/redis_storage.go

package ratelimit

import (
    "context"
    "errors"
    "time"

    "github.com/redis/go-redis/v9"

    libRedis "github.com/LerianStudio/lib-commons/v2/commons/redis"
)

const (
    keyPrefix     = "ratelimit:"
    scanBatchSize = 100
)

// Sentinel errors for rate limit storage operations.
var (
    ErrRedisClientUnavailable = errors.New("redis client unavailable")
    ErrRedisGet               = errors.New("redis get failed")
    ErrRedisSet               = errors.New("redis set failed")
    ErrRedisDelete            = errors.New("redis delete failed")
    ErrRedisScan              = errors.New("redis scan failed")
    ErrRedisBatchDelete       = errors.New("redis batch delete failed")
)

// RedisStorage implements fiber.Storage interface using lib-commons Redis connection.
// This enables distributed rate limiting across multiple application instances.
type RedisStorage struct {
    conn *libRedis.RedisConnection
}

// NewRedisStorage creates a new Redis-backed storage for Fiber rate limiting.
// Returns nil if the Redis connection is nil.
func NewRedisStorage(conn *libRedis.RedisConnection) *RedisStorage {
    if conn == nil {
        return nil
    }

    return &RedisStorage{conn: conn}
}

// Get retrieves the value for the given key.
// Returns nil, nil when the key does not exist.
func (storage *RedisStorage) Get(key string) ([]byte, error) {
    if storage == nil || storage.conn == nil {
        return nil, nil
    }

    ctx := context.Background()

    client, err := storage.conn.GetClient(ctx)
    if err != nil {
        return nil, ErrRedisClientUnavailable
    }

    val, err := client.Get(ctx, keyPrefix+key).Bytes()
    if errors.Is(err, redis.Nil) {
        return nil, nil
    }

    if err != nil {
        return nil, ErrRedisGet
    }

    return val, nil
}

// Set stores the given value for the given key with an expiration.
// 0 expiration means no expiration. Empty key or value will be ignored.
func (storage *RedisStorage) Set(key string, val []byte, exp time.Duration) error {
    if storage == nil || storage.conn == nil {
        return nil
    }

    if key == "" || len(val) == 0 {
        return nil
    }

    ctx := context.Background()

    client, err := storage.conn.GetClient(ctx)
    if err != nil {
        return ErrRedisClientUnavailable
    }

    if err := client.Set(ctx, keyPrefix+key, val, exp).Err(); err != nil {
        return ErrRedisSet
    }

    return nil
}

// Delete removes the value for the given key.
// Returns no error if the key does not exist.
func (storage *RedisStorage) Delete(key string) error {
    if storage == nil || storage.conn == nil {
        return nil
    }

    ctx := context.Background()

    client, err := storage.conn.GetClient(ctx)
    if err != nil {
        return ErrRedisClientUnavailable
    }

    if err := client.Del(ctx, keyPrefix+key).Err(); err != nil {
        return ErrRedisDelete
    }

    return nil
}

// Reset clears all rate limit keys from the storage.
// This uses SCAN to find and delete keys with the rate limit prefix.
func (storage *RedisStorage) Reset() error {
    if storage == nil || storage.conn == nil {
        return nil
    }

    ctx := context.Background()

    client, err := storage.conn.GetClient(ctx)
    if err != nil {
        return ErrRedisClientUnavailable
    }

    var cursor uint64

    for {
        keys, nextCursor, err := client.Scan(ctx, cursor, keyPrefix+"*", scanBatchSize).Result()
        if err != nil {
            return ErrRedisScan
        }

        if len(keys) > 0 {
            if err := client.Del(ctx, keys...).Err(); err != nil {
                return ErrRedisBatchDelete
            }
        }

        cursor = nextCursor
        if cursor == 0 {
            break
        }
    }

    return nil
}

// Close is a no-op as the Redis connection is managed by the application lifecycle.
func (*RedisStorage) Close() error {
    return nil
}
```

### Key Generation Pattern (MANDATORY)

Rate limiter keys MUST follow this priority to ensure per-user fairness:

```text
Priority: UserID → (TenantID + IP) → IP

Example Keys:
- "user-123"                              (authenticated user)
- "tenant-456:192.168.1.1"               (tenant with IP fallback)
- "192.168.1.1"                          (unauthenticated, IP only)
- "export:user-123"                      (export tier)
- "dispatch:tenant-456:192.168.1.1"      (dispatch tier)
```

### Implementation Pattern (Fiber)

```go
// internal/bootstrap/fiber_server.go

import (
    "strconv"
    "time"

    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/limiter"
)

// NewRateLimiter creates a rate limiter middleware that uses UserID/TenantID from context.
// This middleware MUST be applied AFTER auth middleware to access user context.
// Order: Auth → RateLimiter → Handlers
// If storage is provided, uses it for distributed rate limiting across multiple instances.
// Returns a no-op middleware if rate limiting is disabled via RateLimitEnabled config.
//
// IMPORTANT: fiberCtx.IP() depends on Trusted Proxy configuration.
// See "Trusted Proxy Configuration" section. Without TrustProxy, c.IP() returns
// the proxy/load balancer IP, and rate limiting by IP will not work correctly.
func NewRateLimiter(cfg *Config, storage fiber.Storage) fiber.Handler {
    if !cfg.RateLimit.Enabled {
        return func(c *fiber.Ctx) error {
            return c.Next()
        }
    }

    limiterCfg := limiter.Config{
        Max:        cfg.RateLimit.Max,
        Expiration: time.Duration(cfg.RateLimit.ExpirySec) * time.Second,
        KeyGenerator: func(fiberCtx *fiber.Ctx) string {
            ctx := fiberCtx.UserContext()
            if ctx != nil {
                if userID, ok := ctx.Value(auth.UserIDKey).(string); ok && userID != "" {
                    return userID
                }

                if tenantID, ok := ctx.Value(auth.TenantIDKey).(string); ok && tenantID != "" {
                    return tenantID + ":" + fiberCtx.IP()
                }
            }

            return fiberCtx.IP()
        },
        LimitReached: func(fiberCtx *fiber.Ctx) error {
            fiberCtx.Set("Retry-After", strconv.Itoa(cfg.RateLimit.ExpirySec))

            return sharedhttp.WriteError(
                fiberCtx,
                fiber.StatusTooManyRequests,
                "rate_limit_exceeded",
                "rate limit exceeded",
            )
        },
    }

    if storage != nil {
        limiterCfg.Storage = storage
    }

    return limiter.New(limiterCfg)
}

// NewExportRateLimiter creates a rate limiter middleware for export endpoints.
// It applies stricter limits than the global rate limiter to protect resource-intensive
// report generation operations.
// If storage is provided, uses it for distributed rate limiting across multiple instances.
// Returns a no-op middleware if rate limiting is disabled via RateLimitEnabled config.
func NewExportRateLimiter(cfg *Config, storage fiber.Storage) fiber.Handler {
    if !cfg.RateLimit.Enabled {
        return func(c *fiber.Ctx) error {
            return c.Next()
        }
    }

    limiterCfg := limiter.Config{
        Max:        cfg.RateLimit.ExportMax,
        Expiration: time.Duration(cfg.RateLimit.ExportExpirySec) * time.Second,
        KeyGenerator: func(fiberCtx *fiber.Ctx) string {
            ctx := fiberCtx.UserContext()
            if ctx != nil {
                if userID, ok := ctx.Value(auth.UserIDKey).(string); ok && userID != "" {
                    return "export:" + userID
                }

                if tenantID, ok := ctx.Value(auth.TenantIDKey).(string); ok && tenantID != "" {
                    return "export:" + tenantID + ":" + fiberCtx.IP()
                }
            }

            return "export:" + fiberCtx.IP()
        },
        LimitReached: func(fiberCtx *fiber.Ctx) error {
            fiberCtx.Set("Retry-After", strconv.Itoa(cfg.RateLimit.ExportExpirySec))

            return sharedhttp.WriteError(
                fiberCtx,
                fiber.StatusTooManyRequests,
                "export_rate_limit_exceeded",
                "too many export requests, please try again later",
            )
        },
    }

    if storage != nil {
        limiterCfg.Storage = storage
    }

    return limiter.New(limiterCfg)
}

// NewDispatchRateLimiter creates a rate limiter middleware for exception dispatch endpoints.
// It applies moderate limits to protect external system integrations from overload.
// If storage is provided, uses it for distributed rate limiting across multiple instances.
// Returns a no-op middleware if rate limiting is disabled via RateLimitEnabled config.
func NewDispatchRateLimiter(cfg *Config, storage fiber.Storage) fiber.Handler {
    if !cfg.RateLimit.Enabled {
        return func(c *fiber.Ctx) error {
            return c.Next()
        }
    }

    limiterCfg := limiter.Config{
        Max:        cfg.RateLimit.DispatchMax,
        Expiration: time.Duration(cfg.RateLimit.DispatchExpirySec) * time.Second,
        KeyGenerator: func(fiberCtx *fiber.Ctx) string {
            ctx := fiberCtx.UserContext()
            if ctx != nil {
                if userID, ok := ctx.Value(auth.UserIDKey).(string); ok && userID != "" {
                    return "dispatch:" + userID
                }

                if tenantID, ok := ctx.Value(auth.TenantIDKey).(string); ok && tenantID != "" {
                    return "dispatch:" + tenantID + ":" + fiberCtx.IP()
                }
            }

            return "dispatch:" + fiberCtx.IP()
        },
        LimitReached: func(fiberCtx *fiber.Ctx) error {
            fiberCtx.Set("Retry-After", strconv.Itoa(cfg.RateLimit.DispatchExpirySec))

            return sharedhttp.WriteError(
                fiberCtx,
                fiber.StatusTooManyRequests,
                "dispatch_rate_limit_exceeded",
                "too many dispatch requests, please try again later",
            )
        },
    }

    if storage != nil {
        limiterCfg.Storage = storage
    }

    return limiter.New(limiterCfg)
}
```

### Bootstrap Integration

```go
// internal/bootstrap/init.go

// Create Redis storage for distributed rate limiting
rateLimitStorage := ratelimit.NewRedisStorage(redisConnection)

// Create rate limiters
globalLimiter := NewRateLimiter(cfg, rateLimitStorage)
exportLimiter := NewExportRateLimiter(cfg, rateLimitStorage)
dispatchLimiter := NewDispatchRateLimiter(cfg, rateLimitStorage)

// Apply global limiter to all protected routes
protected := func(resource, action string) fiber.Router {
    return auth.ProtectedGroupWithMiddleware(
        app, authClient, tenantExtractor,
        resource, action,
        idempotencyMiddleware,
        globalLimiter,
    )
}

// Apply tier-specific limiters to specific routes
exportRoutes.Use(exportLimiter)
dispatchRoutes.Use(dispatchLimiter)
```

### Middleware Ordering

```text
Auth → TenantExtraction → Idempotency → Rate Limiter → Handler
```

Rate limiter MUST be placed AFTER auth middleware so that user/tenant context is available for key generation.

### Production Safety (MANDATORY)

**⛔ HARD GATE:** Rate limiting CANNOT be disabled in production. The bootstrap MUST enforce this:

```go
// internal/bootstrap/config.go

func enforceProductionDefaults(cfg *Config, logger log.Logger) {
    if cfg.App.EnvName == "production" && !cfg.RateLimit.Enabled {
        logger.Warnf("SECURITY: RATE_LIMIT_ENABLED=false is not allowed in production. "+
            "Forcing rate limiting to enabled. env=%s", cfg.App.EnvName)
        cfg.RateLimit.Enabled = true
    }
}
```

### Graceful Degradation

| Scenario | Behavior |
|----------|----------|
| Redis available | Distributed rate limiting across all instances |
| Redis unavailable (temporary) | Falls back to in-memory (per-instance) limiting with warning log |
| Rate limit disabled (non-prod) | No-op middleware, all requests pass through |
| Rate limit disabled (production) | Force-enabled, cannot be disabled |

> **Note:** In-memory fallback during temporary Redis outage is acceptable to prevent total service unavailability. This is distinct from deploying without Redis storage entirely (which is FORBIDDEN in production — see below). The fallback MUST log a warning so operators are alerted to restore Redis connectivity.

### Error Response Format

All rate limit violations MUST return:

```json
{
  "code": "429",
  "title": "rate_limit_exceeded",
  "message": "rate limit exceeded"
}
```

With headers:
- **Status:** `429 Too Many Requests`
- **Retry-After:** `<seconds>` (window duration)

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Deploying rate limiting without Redis storage configured in production
// (In-memory fallback during temporary Redis outage is acceptable — see Graceful Degradation)
limiter.New(limiter.Config{Max: 100})  // No Storage field = permanent in-memory only = no distribution

// ❌ FORBIDDEN: Using IP-only keys for authenticated endpoints
KeyGenerator: func(c *fiber.Ctx) string {
    return c.IP()  // Ignores user/tenant context
}

// ❌ FORBIDDEN: Using c.IP() without Trusted Proxy configuration behind a proxy
// c.IP() returns proxy IP, not client IP — rate limiting applies to the proxy as a whole
// See "Trusted Proxy Configuration" section

// ❌ FORBIDDEN: Hardcoded rate limits (must be configurable)
limiter.Config{Max: 100, Expiration: time.Minute}  // Use config struct

// ❌ FORBIDDEN: Rate limiter before auth middleware
app.Use(rateLimiter)  // Before auth = no user context for keys
app.Use(authMiddleware)

// ❌ FORBIDDEN: Missing Retry-After header
LimitReached: func(c *fiber.Ctx) error {
    return c.SendStatus(429)  // Missing Retry-After header
}

// ❌ FORBIDDEN: Allowing rate limit disable in production
if !cfg.RateLimit.Enabled {
    return  // Must force-enable in production
}
```

### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR that touches middleware or routing

# Find rate limiter registration
grep -rn "limiter.New\|NewRateLimiter" --include="*.go" ./internal
# Expected: At least one match per tier (global, export, dispatch)

# Verify production enforcement exists
grep -rn "RATE_LIMIT_ENABLED.*production\|Forcing rate limiting" --include="*.go" ./internal
# Expected: At least 1 match

# Find rate limiter without storage (in-memory only)
grep -rn "limiter.New" --include="*.go" ./internal | grep -v "Storage"
# Expected: 0 matches (all limiters must use storage)

# Find KeyGenerator that only uses IP
grep -A 3 "KeyGenerator" --include="*.go" ./internal | grep "return.*IP()" | grep -v "tenantID\|userID"
# Expected: 0 matches (must use user/tenant context)

# Find missing Retry-After header
grep -A 5 "LimitReached" --include="*.go" ./internal | grep -v "Retry-After"
# Review matches: all LimitReached handlers must set Retry-After
```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We're behind a load balancer with rate limiting" | Defense in depth. App-level limits protect per-user fairness. | **Implement app-level rate limiting** |
| "Rate limiting slows development" | Rate limiting prevents cascade failures. Configure generous limits for dev. | **Configure appropriate limits per environment** |
| "We don't need rate limiting yet" | By the time you need it, you're already under attack. | **Implement before production** |
| "In-memory rate limiting is sufficient" | In-memory = per-instance only. Multi-instance deployments bypass limits. | **Use Redis-backed storage** |
| "IP-based limiting is enough" | Multiple users share IPs (NAT, VPN). Users behind same IP get unfairly limited. | **Use UserID/TenantID key priority** |
| "Rate limiting can be disabled for trusted clients" | Trusted clients can be compromised. Limits protect the service. | **Apply to all clients** |

### Verification Checklist (Before PR)

```text
Before submitting PR that adds rate limiting:

[ ] Did I implement all three tiers (global, export, dispatch)?
[ ] Did I use Redis-backed storage?
[ ] Did I implement key generation with UserID > TenantID+IP > IP priority?
[ ] Did I enforce rate limiting in production (cannot be disabled)?
[ ] Did I include Retry-After header in 429 responses?
[ ] Did I place rate limiter AFTER auth middleware?
[ ] Did I run the detection commands above?

If any checkbox is unchecked → FIX before submitting.
```

---

## CORS Configuration (MANDATORY)

**⛔ HARD GATE:** All HTTP services MUST configure CORS to control cross-origin access. Wildcard origins are FORBIDDEN in production.

### Why CORS Configuration Matters

Without proper CORS configuration, browsers block legitimate cross-origin requests (breaking frontends), or worse, overly permissive CORS allows malicious sites to make authenticated requests on behalf of users. CORS MUST be explicitly configured, not left to defaults.

### Required Environment Variables

| Variable | Type | Default | Production Rule |
|----------|------|---------|-----------------|
| `CORS_ALLOWED_ORIGINS` | string | `http://localhost:3000` | MUST be explicit (no `*`) |
| `CORS_ALLOWED_METHODS` | string | `GET,POST,PUT,PATCH,DELETE,OPTIONS` | — |
| `CORS_ALLOWED_HEADERS` | string | `Origin,Content-Type,Accept,Authorization,X-Request-ID` | — |

### Configuration Struct

```go
// internal/bootstrap/config.go

// ServerConfig configures the HTTP server and middleware.
type ServerConfig struct {
    Address               string `env:"SERVER_ADDRESS"          envDefault:":8080"`
    BodyLimitBytes        int    `env:"HTTP_BODY_LIMIT_BYTES"   envDefault:"104857600"`
    CORSAllowedOrigins    string `env:"CORS_ALLOWED_ORIGINS"    envDefault:"http://localhost:3000"`
    CORSAllowedMethods    string `env:"CORS_ALLOWED_METHODS"    envDefault:"GET,POST,PUT,PATCH,DELETE,OPTIONS"`
    CORSAllowedHeaders    string `env:"CORS_ALLOWED_HEADERS"    envDefault:"Origin,Content-Type,Accept,Authorization,X-Request-ID"`
    TLSCertFile           string `env:"SERVER_TLS_CERT_FILE"`
    TLSKeyFile            string `env:"SERVER_TLS_KEY_FILE"`
    TLSTerminatedUpstream bool   `env:"TLS_TERMINATED_UPSTREAM" envDefault:"false"`
}
```

### Implementation Pattern (Fiber)

```go
// internal/bootstrap/fiber_server.go

import (
    "github.com/gofiber/fiber/v2/middleware/cors"
)

// Apply CORS middleware globally (must be early in middleware chain)
app.Use(cors.New(cors.Config{
    AllowOrigins: cfg.Server.CORSAllowedOrigins,
    AllowMethods: cfg.Server.CORSAllowedMethods,
    AllowHeaders: cfg.Server.CORSAllowedHeaders,
}))
```

### Middleware Ordering (MANDATORY)

CORS MUST be placed early in the middleware chain, before security headers and business logic:

```text
Recover → Request ID → CORS → Helmet (Security Headers) → Telemetry → Rate Limiter → Handler
```

**Why before Helmet:** CORS preflight (OPTIONS) must be handled before other middleware adds headers or rejects the request.

### Production Validation (MANDATORY)

**⛔ HARD GATE:** Production MUST reject wildcard and empty CORS origins:

```go
// internal/bootstrap/config.go

// Sentinel errors for CORS production validation.
var (
    ErrCORSOriginsEmpty    = errors.New("CORS_ALLOWED_ORIGINS must be set in production")
    ErrCORSOriginsWildcard = errors.New("CORS_ALLOWED_ORIGINS must not contain wildcard (*) in production")
)

func validateProductionConfig(cfg *Config) error {
    if cfg.App.EnvName != "production" {
        return nil
    }

    origins := strings.TrimSpace(cfg.Server.CORSAllowedOrigins)

    // MANDATORY: Origins must not be empty
    if origins == "" {
        return ErrCORSOriginsEmpty
    }

    // MANDATORY: Wildcard is forbidden
    if strings.Contains(origins, "*") {
        return ErrCORSOriginsWildcard
    }

    return nil
}
```

### Production Safety Rules

| Rule | Enforcement |
|------|-------------|
| No wildcard origins in production | `*` is FORBIDDEN; must list explicit origins |
| No empty origins in production | MUST specify at least one origin |
| Origins must use HTTPS in production | `http://` origins are only for development |
| Multiple origins are comma-separated | `https://app.example.com,https://admin.example.com` |

### Integration with Helmet Security Headers

CORS middleware works alongside Helmet for comprehensive cross-origin protection:

```go
// internal/bootstrap/fiber_server.go

import (
    "github.com/gofiber/fiber/v2/middleware/helmet"
)

helmetCfg := helmet.Config{
    XSSProtection:             "1; mode=block",
    ContentTypeNosniff:        "nosniff",
    XFrameOptions:             "DENY",
    ReferrerPolicy:            "strict-origin-when-cross-origin",
    CrossOriginEmbedderPolicy: "require-corp",
    CrossOriginOpenerPolicy:   "same-origin",
    CrossOriginResourcePolicy: "same-origin",
    PermissionPolicy:          "geolocation=(), microphone=(), camera=()",
    ContentSecurityPolicy:     "default-src 'self'; script-src 'self' 'unsafe-inline'; " +
        "style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; " +
        "connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; " +
        "form-action 'self'; object-src 'none'",
}

// Enable HSTS when TLS is configured
if strings.TrimSpace(cfg.Server.TLSCertFile) != "" || cfg.Server.TLSTerminatedUpstream {
    helmetCfg.HSTSMaxAge = 31536000
    helmetCfg.HSTSPreloadEnabled = true
    helmetCfg.HSTSExcludeSubdomains = false
}

app.Use(helmet.New(helmetCfg))
```

| Header | Purpose | Set By |
|--------|---------|--------|
| `Access-Control-Allow-Origin` | Allowed origins | CORS middleware |
| `Access-Control-Allow-Methods` | Allowed methods | CORS middleware |
| `Access-Control-Allow-Headers` | Allowed headers | CORS middleware |
| `Cross-Origin-Embedder-Policy` | Embedding policy | Helmet middleware |
| `Cross-Origin-Opener-Policy` | Window opener policy | Helmet middleware |
| `Cross-Origin-Resource-Policy` | Resource access policy | Helmet middleware |

### Configuration Examples

```bash
# Development
CORS_ALLOWED_ORIGINS=http://localhost:3000
CORS_ALLOWED_METHODS=GET,POST,PUT,PATCH,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Origin,Content-Type,Accept,Authorization,X-Request-ID

# Production (explicit origins, HTTPS only)
CORS_ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com
CORS_ALLOWED_METHODS=GET,POST,PUT,PATCH,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Origin,Content-Type,Accept,Authorization,X-Request-ID
```

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: Wildcard origins in production
cors.Config{AllowOrigins: "*"}

// ❌ FORBIDDEN: Hardcoded origins (must use config)
cors.Config{AllowOrigins: "https://app.example.com"}

// ❌ FORBIDDEN: No CORS middleware at all
// (browsers will block cross-origin requests)

// ❌ FORBIDDEN: CORS after business logic middleware
app.Use(authMiddleware)
app.Use(rateLimiter)
app.Use(cors.New(corsCfg))  // Too late - preflight fails

// ❌ FORBIDDEN: Reflecting request Origin without validation
cors.Config{
    AllowOriginsFunc: func(origin string) bool {
        return true  // Effectively same as wildcard
    },
}

// ✅ CORRECT: Configuration-driven, validated
cors.Config{
    AllowOrigins: cfg.Server.CORSAllowedOrigins,  // From env vars
    AllowMethods: cfg.Server.CORSAllowedMethods,
    AllowHeaders: cfg.Server.CORSAllowedHeaders,
}
```

### Detection Commands (MANDATORY)

```bash
# MANDATORY: Run before every PR that touches middleware or server setup

# Find CORS middleware registration
grep -rn "cors.New\|cors.Config" --include="*.go" ./internal
# Expected: At least 1 match

# Check for wildcard origins in code
grep -rn 'AllowOrigins.*"\*"' --include="*.go" ./internal
# Expected: 0 matches

# Verify CORS config comes from environment
grep -rn "CORS_ALLOWED" --include="*.go" ./internal
# Expected: At least 3 matches (Origins, Methods, Headers)

# Find production validation for CORS
grep -rn "CORS.*production\|wildcard.*CORS\|CORS.*wildcard" --include="*.go" ./internal
# Expected: At least 1 match

# Verify middleware ordering (CORS before helmet)
grep -n "cors.New\|helmet.New\|limiter.New" --include="*.go" ./internal/bootstrap/fiber_server.go
# Expected: cors line number < helmet line number < limiter line number
```

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We don't have a frontend yet" | CORS must be configured before any client integrates. Retrofit is harder. | **Configure CORS from the start** |
| "Wildcard is easier for development" | Wildcard in dev trains bad habits. Use `localhost:3000` default. | **Use explicit origins even in dev** |
| "Reverse proxy handles CORS" | Defense in depth. App must protect itself regardless of proxy. | **Configure CORS at app level** |
| "We only have one frontend" | More frontends will come. Configuration is easy to update. | **Use env var configuration** |
| "CORS doesn't affect API-to-API calls" | Correct, but browsers enforce CORS. Any browser-based client needs it. | **Configure for browser clients** |
| "We'll validate origins later" | Later = production with wildcard. Validate from day one. | **Add production validation immediately** |

### Verification Checklist (Before PR)

```text
Before submitting PR that configures CORS:

[ ] Did I use environment variables for all CORS settings?
[ ] Did I add production validation (no wildcard, no empty)?
[ ] Did I place CORS middleware early in the chain (before helmet)?
[ ] Did I include all required headers (Origin, Content-Type, Accept, Authorization, X-Request-ID)?
[ ] Did I test with both development and production configurations?
[ ] Did I run the detection commands above?

If any checkbox is unchecked → FIX before submitting.
```

---

