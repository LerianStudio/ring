# Go Standards - Quality

> **Module:** quality.md | **Sections:** 5 | **Parent:** [index.md](index.md)

This module covers logging, linting, configuration validation, and container security standards.

> **Note:** Testing standards have been moved to dedicated modules:
>
> - [testing-unit.md](testing-unit.md) - Unit testing patterns (Gate 3)
> - [testing-fuzz.md](testing-fuzz.md) - Fuzz testing patterns (Gate 4)
> - [testing-property.md](testing-property.md) - Property-based testing patterns (Gate 5)
> - [testing-integration.md](testing-integration.md) - Integration testing patterns (Gate 6)
> - [testing-chaos.md](testing-chaos.md) - Chaos testing patterns (Gate 7)
> - [testing-benchmark.md](testing-benchmark.md) - Benchmark testing patterns (optional)

---

## Table of Contents

| #   | [Section Name](#anchor-link)                                                                            | Description                                               |
| --- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| 1   | [Logging](#logging)                                                                                     | Structured logging with lib-commons                       |
| 2   | [Linting](#linting)                                                                                     | Import ordering, magic numbers, .golangci.yml requirement |
| 3   | [Migration Guidance for Mandatory Linter Promotion](#migration-guidance-for-mandatory-linter-promotion) | Phased rollout and per-linter fix examples                |
| 4   | [Production Config Validation](#production-config-validation-mandatory)                                 | Startup validation and fail-fast                          |
| 5   | [Container Security](#container-security-conditional)                                                   | Non-root user, image pinning                              |

---

## Logging

**HARD GATE:** All Go services MUST use lib-commons structured logging. Unstructured logging is FORBIDDEN.

### FORBIDDEN Logging Patterns (CRITICAL - Automatic FAIL)

| Pattern         | Why FORBIDDEN                                           | Detection Command                         |
| --------------- | ------------------------------------------------------- | ----------------------------------------- |
| `fmt.Println()` | No structure, no trace correlation, unsearchable        | `grep -rn "fmt.Println" --include="*.go"` |
| `fmt.Printf()`  | No structure, no trace correlation, unsearchable        | `grep -rn "fmt.Printf" --include="*.go"`  |
| `log.Println()` | Standard library logger lacks trace correlation         | `grep -rn "log.Println" --include="*.go"` |
| `log.Printf()`  | Standard library logger lacks trace correlation         | `grep -rn "log.Printf" --include="*.go"`  |
| `log.Fatal()`   | Exits without graceful shutdown, breaks telemetry flush | `grep -rn "log.Fatal" --include="*.go"`   |
| `println()`     | Built-in, no structure, debugging only                  | `grep -rn "println(" --include="*.go"`    |

**If any of these patterns are found in production code → REVIEW FAILS. no EXCEPTIONS.**

### Pre-Commit Check (MANDATORY)

Add to `.golangci.yml` or run manually before commit:

```bash
# MUST pass with zero matches before commit
grep -rn "fmt.Println\|fmt.Printf\|log.Println\|log.Printf\|log.Fatal\|println(" --include="*.go" ./internal ./cmd
# Expected output: (nothing - no matches)
```

### Using lib-commons Logger (REQUIRED Pattern)

```go
// CORRECT: Recover logger from context
logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

// CORRECT: Log with context correlation
logger.Infof("Processing entity: %s", entityID)
logger.Warnf("Connection pool low: %d/%d", current, limit)
logger.Errorf("Failed to save entity: %v", err)
```

### Migration Examples

```go
// ❌ FORBIDDEN: fmt.Println
fmt.Println("Starting server...")

// ✅ REQUIRED: lib-commons logger
logger.Info("Starting server")

// ❌ FORBIDDEN: fmt.Printf
fmt.Printf("Processing user: %s\n", userID)

// ✅ REQUIRED: lib-commons logger
logger.Infof("Processing user: %s", userID)

// ❌ FORBIDDEN: log.Printf
log.Printf("[ERROR] Failed to connect: %v", err)

// ✅ REQUIRED: lib-commons logger with span error
logger.Errorf("Failed to connect: %v", err)
libOpentelemetry.HandleSpanError(&span, "Connection failed", err)

// ❌ FORBIDDEN: log.Fatal (breaks graceful shutdown)
log.Fatal("Cannot start without config")

// ❌ FORBIDDEN: panic (crashes process, skips cleanup)
panic(fmt.Errorf("cannot start without config: %w", err))

// ✅ REQUIRED: return error (caller decides how to handle)
return nil, fmt.Errorf("cannot start without config: %w", err)
```

### What not to Log (Sensitive Data)

```go
// FORBIDDEN - sensitive data
logger.Info("user login", "password", password)  // never
logger.Info("payment", "card_number", card)      // never
logger.Info("auth", "token", token)              // never
logger.Info("user", "cpf", cpf)                  // never (PII)
```

### golangci-lint Custom Rule (RECOMMENDED)

Add to `.golangci.yml` to automatically fail CI on forbidden patterns:

```yaml
linters-settings:
  forbidigo:
    forbid:
      - p: ^fmt\.Print.*$
        msg: "FORBIDDEN: Use lib-commons logger instead of fmt.Print*"
      - p: ^log\.(Print|Fatal|Panic).*$
        msg: "FORBIDDEN: Use lib-commons logger instead of standard log package"
      - p: ^print$
        msg: "FORBIDDEN: Use lib-commons logger instead of print builtin"
      - p: ^println$
        msg: "FORBIDDEN: Use lib-commons logger instead of println builtin"

linters:
  enable:
    - forbidigo
```

---

## Linting

### golangci-lint Configuration

```yaml
# .golangci.yml - Minimum required configuration
run:
  timeout: 5m
  go: "1.24"

linters:
  enable:
    # MANDATORY linters (all 14 MUST be enabled)
    - gofmt # Code formatting - enforces canonical Go style
    - goimports # Import organization - groups and sorts imports
    - govet # Go vet analysis - catches common mistakes (shadowing, printf)
    - staticcheck # Static analysis - advanced bug detection (SA* checks)
    - errcheck # Error handling verification - catches ignored errors
    - gosec # Security vulnerability detection - OWASP patterns
    - mnd # Magic number detection - enforces named constants
    - unused # Unused code detection - dead code removal
    - ineffassign # Unused assignment detection - assignments to never-read vars
    - gosimple # Simplify code - suggests simpler constructs (S1* checks)
    - misspell # Spelling errors - typos in comments/strings/identifiers
    - goconst # Repeated strings - extracts string literals to constants
    - nilerr # Return nil with non-nil error - catches "if err != nil { return nil }"
    - forbidigo # Forbidden patterns - blocks fmt.Print*, log.Fatal, panic

linters-settings:
  goimports:
    local-prefixes: github.com/LerianStudio

  mnd:
    checks:
      - argument
      - case
      - condition
      - operation
      - return
      - assign
    ignored-numbers:
      - "0"
      - "1"
      - "-1"
    ignored-functions:
      - '^math\.'
      - '^http\.Status'
      - '^strings\.(SplitN|SplitAfterN)'
    ignored-files:
      - '_test\.go$'

  forbidigo:
    forbid:
      - p: ^fmt\.Print.*$
        msg: "FORBIDDEN: Use lib-commons logger"
      - p: ^log\.(Print|Fatal|Panic).*$
        msg: "FORBIDDEN: Use lib-commons logger"
```

---

### Format Commands

```bash
# Format code
gofmt -w .
goimports -w .

# Run linter
golangci-lint run ./...

# Run only magic number check
golangci-lint run --enable=mnd --disable-all ./...
```

---

---

## Migration Guidance for Mandatory Linter Promotion

**Context:** All 14 linters are now MANDATORY. Projects previously using only the "9 core" linters must adopt the additional 5: `gosimple`, `misspell`, `goconst`, `nilerr`, `forbidigo`.

#### Adoption Timeline

| Phase                       | Duration | Action                                 |
| --------------------------- | -------- | -------------------------------------- |
| **Phase 1: Warning**        | Week 1-2 | Enable linters, treat as warnings only |
| **Phase 2: Blocking (New)** | Week 3-4 | Block CI for new violations only       |
| **Phase 3: Blocking (All)** | Week 5+  | Block CI for all violations            |

#### Phased Rollout Configuration

```yaml
# Phase 1: Enable as warnings (non-blocking)
issues:
  max-issues-per-linter: 0  # Show all issues
  max-same-issues: 0
  new-from-rev: ""          # Check all code
  # Remove 'exclude' rules to see all issues

# Phase 2: Block only new violations
issues:
  new-from-rev: HEAD~10     # Only fail on recent commits

# Phase 3: Full enforcement (final state)
issues:
  new-from-rev: ""          # Check all code, fail on any violation
```

#### Common Violations and Fixes

##### gosimple (Code Simplification)

| S-Code | Common Pattern                    | Fix                             |
| ------ | --------------------------------- | ------------------------------- |
| S1000  | `select { case x := <-ch: ... }`  | Use `x := <-ch` directly        |
| S1002  | `if b == true { ... }`            | Use `if b { ... }`              |
| S1003  | `strings.Index(s, sub) != -1`     | Use `strings.Contains(s, sub)`  |
| S1005  | `for i, _ := range slice`         | Use `for i := range slice`      |
| S1011  | Loop with append to another slice | Use `append(slice1, slice2...)` |

```go
// ❌ gosimple S1003
if strings.Index(name, "test") != -1 { ... }

// ✅ Fixed
if strings.Contains(name, "test") { ... }
```

##### misspell (Spelling Corrections)

| Common Typo  | Correction   |
| ------------ | ------------ |
| `occured`    | `occurred`   |
| `recieved`   | `received`   |
| `seperate`   | `separate`   |
| `sucessful`  | `successful` |
| `definately` | `definitely` |

```go
// ❌ misspell
// Sucessfully processed the recieved data
func ProcessData() { ... }

// ✅ Fixed
// Successfully processed the received data
func ProcessData() { ... }
```

##### goconst (Repeated String Literals)

**Trigger:** String literal appears 3+ times in the same package.

```go
// ❌ goconst: "user_id" repeated 4 times
query1 := db.Where("user_id = ?", id)
query2 := db.Where("user_id = ?", id2)
log.Info("fetching user_id", ...)
validate("user_id", value)

// ✅ Fixed: Extract to constant
const fieldUserID = "user_id"

query1 := db.Where(fieldUserID + " = ?", id)
query2 := db.Where(fieldUserID + " = ?", id2)
log.Info("fetching " + fieldUserID, ...)
validate(fieldUserID, value)
```

##### nilerr (Nil Return with Non-Nil Error)

**Trigger:** Returning `nil` in error path instead of the actual error.

```go
// ❌ nilerr: returning nil instead of err
func GetUser(id string) (*User, error) {
    user, err := repo.Find(id)
    if err != nil {
        return nil, nil  // WRONG: error is lost
    }
    return user, nil
}

// ✅ Fixed: Return the actual error
func GetUser(id string) (*User, error) {
    user, err := repo.Find(id)
    if err != nil {
        return nil, err  // CORRECT: error propagated
    }
    return user, nil
}
```

##### forbidigo (Forbidden Patterns)

**Trigger:** Usage of patterns blocked by `.golangci.yml` configuration.

| Forbidden       | Replacement                        |
| --------------- | ---------------------------------- |
| `fmt.Println()` | `logger.Info()`                    |
| `fmt.Printf()`  | `logger.Infof()`                   |
| `log.Fatal()`   | `return err` + graceful shutdown   |
| `log.Panic()`   | `return err` + recovery middleware |
| `panic()`       | `return err` (except bootstrap)    |

```go
// ❌ forbidigo: fmt.Println forbidden
fmt.Println("Starting server on port", port)

// ✅ Fixed: Use lib-commons logger
logger.Infof("Starting server on port %d", port)
```

#### Batch Fix Commands

```bash
# Fix all gosimple issues automatically where possible
golangci-lint run --fix --enable=gosimple --disable-all ./...

# Fix all misspell issues automatically
golangci-lint run --fix --enable=misspell --disable-all ./...

# List all goconst violations (manual fix required)
golangci-lint run --enable=goconst --disable-all ./...

# List all nilerr violations (manual fix required)
golangci-lint run --enable=nilerr --disable-all ./...

# List all forbidigo violations (manual fix required)
golangci-lint run --enable=forbidigo --disable-all ./...
```

---

## Production Config Validation (MANDATORY)

Services that start with invalid or missing configuration cause runtime failures instead of fail-fast at startup.

**⛔ HARD GATE:** All services MUST validate configuration at startup and fail fast by returning an error if invalid. Silent failures and panic are FORBIDDEN.

### Why Startup Validation Is MANDATORY

| Issue                  | Impact Without Validation                     |
| ---------------------- | --------------------------------------------- |
| Missing required field | Service starts but fails on first request     |
| Invalid format         | Silent misbehavior (wrong DB, wrong endpoint) |
| Wrong environment      | Production config in dev, or vice versa       |
| Connection string typo | Service starts, fails on first DB call        |

### Validation Patterns (REQUIRED)

```go
// internal/bootstrap/config.go

type Config struct {
    // Required fields - MUST have validation
    ServerAddress string `env:"SERVER_ADDRESS"`
    DBHost        string `env:"DB_HOST"`
    DBName        string `env:"DB_NAME"`
    DBUser        string `env:"DB_USER"`
    DBPassword    string `env:"DB_PASSWORD"`

    // Optional with defaults
    DBPort        string `env:"DB_PORT" default:"5432"`
    LogLevel      string `env:"LOG_LEVEL" default:"info"`
    MaxPoolSize   int    `env:"DB_MAX_POOL_SIZE" default:"50"`
}

// Validate checks all required fields and returns a detailed error
func (c *Config) Validate() error {
    var errs []string

    // Required field validation
    if c.ServerAddress == "" {
        errs = append(errs, "SERVER_ADDRESS is required")
    }
    if c.DBHost == "" {
        errs = append(errs, "DB_HOST is required")
    }
    if c.DBName == "" {
        errs = append(errs, "DB_NAME is required")
    }
    if c.DBUser == "" {
        errs = append(errs, "DB_USER is required")
    }
    if c.DBPassword == "" {
        errs = append(errs, "DB_PASSWORD is required")
    }

    // Format validation
    if c.MaxPoolSize < 1 || c.MaxPoolSize > 500 {
        errs = append(errs, "DB_MAX_POOL_SIZE must be between 1 and 500")
    }

    validLogLevels := map[string]bool{"debug": true, "info": true, "warn": true, "error": true}
    if !validLogLevels[c.LogLevel] {
        errs = append(errs, "LOG_LEVEL must be one of: debug, info, warn, error")
    }

    if len(errs) > 0 {
        return fmt.Errorf("configuration validation failed:\n- %s", strings.Join(errs, "\n- "))
    }

    return nil
}

// InitServers MUST validate config and return an error on failure (caller logs and exits non-zero)
func InitServers() (*Service, error) {
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        return nil, fmt.Errorf("failed to load config: %w", err)
    }

    // MANDATORY: Validate before any initialization
    if err := cfg.Validate(); err != nil {
        return nil, err
    }

    // Continue with initialization only after validation passes
    logger := libZap.InitializeLogger()
    logger.Info("Configuration validated successfully")

    // ... rest of initialization
    return &Service{...}, nil
}
```

**Caller (e.g. main) MUST log and exit non-zero on error:**

```go
// cmd/server/main.go
func main() {
    logger := libZap.InitializeLogger()
    svc, err := InitServers()
    if err != nil {
        logger.Errorf("startup failed: %v", err)
        os.Exit(1)
    }
    // run svc...
}
```

### FORBIDDEN Patterns

```go
// ❌ FORBIDDEN: No validation at startup
func InitServers() *Service {
    cfg := &Config{}
    libCommons.SetConfigFromEnvVars(cfg)
    // WRONG: No validation - silent failures later
    return &Service{cfg: cfg}
}

// ❌ FORBIDDEN: Validation that returns nil on invalid config (silent failure)
func (c *Config) Validate() error {
    if c.DBHost == "" {
        log.Printf("Warning: DB_HOST not set")  // WRONG: Must return error
        return nil  // WRONG: Silent failure
    }
    return nil
}
```

---

## Container Security (⚠️ CONDITIONAL)

**⛔ CONDITIONAL:** This section applies ONLY if the service has a Dockerfile. If no Dockerfile exists, mark this section as N/A.

**Detection Question:**

```bash
# Check if Dockerfile exists
ls -la Dockerfile

# If file exists: Apply this section
# If file does not exist: Mark N/A
```

Containers running as root and using untagged images (`latest`) cause security vulnerabilities and deployment inconsistencies.

### Non-Root User (MANDATORY if Dockerfile exists)

**⛔ HARD GATE:** Containers MUST NOT run as root. The `USER` directive is REQUIRED in all Dockerfiles.

#### Why Non-Root Is Required

| Risk                       | Running as Root     | Running as Non-Root  |
| -------------------------- | ------------------- | -------------------- |
| Container escape           | Full host access    | Limited access       |
| File system access         | Can write anywhere  | Only permitted paths |
| Kubernetes policy          | PSP/PSA violations  | Compliant            |
| Vulnerability exploitation | Elevated privileges | Contained damage     |

#### Required Pattern

```dockerfile
# ✅ CORRECT: Multi-stage build with non-root user
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/server

FROM alpine:3.19.1
# Security: Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D appuser

WORKDIR /app
COPY --from=builder /app/server .

# Security: Switch to non-root user
USER appuser:appgroup

EXPOSE 8080
CMD ["./server"]
```

#### FORBIDDEN Pattern

```dockerfile
# ❌ FORBIDDEN: No USER directive (runs as root)
FROM golang:1.24-alpine
WORKDIR /app
COPY . .
RUN go build -o server ./cmd/server
EXPOSE 8080
CMD ["./server"]

# ❌ FORBIDDEN: USER root
FROM alpine:3.19
USER root
CMD ["./server"]
```

### Image Pinning (MANDATORY)

**⛔ HARD GATE:** All base images MUST use specific version tags. The `:latest` tag is FORBIDDEN.

| Tag Type               | Example                    | Status        |
| ---------------------- | -------------------------- | ------------- |
| Exact version          | `golang:1.24.0-alpine3.19` | ✅ REQUIRED   |
| Minor version          | `golang:1.24-alpine`       | ⚠️ Acceptable |
| Latest                 | `golang:latest`            | ❌ FORBIDDEN  |
| None (implicit latest) | `FROM golang`              | ❌ FORBIDDEN  |

#### Why Pinning Is Required

| Problem with :latest    | Impact                               |
| ----------------------- | ------------------------------------ |
| Non-reproducible builds | Works today, breaks tomorrow         |
| Security scan bypass    | Different image in CI vs prod        |
| Debugging nightmare     | "It worked on my machine"            |
| CVE tracking impossible | Which version has the vulnerability? |

#### Detection Commands

```bash
# Find non-root user in Dockerfile
grep -n "^USER" Dockerfile

# Expected: USER directive exists and is NOT root

# Find image tags
grep -n "^FROM" Dockerfile

# Expected: All FROM statements have explicit version tags (not :latest)

# Check for :latest tag
grep -n "FROM.*:latest\|FROM [a-z]*$" Dockerfile

# Expected: 0 matches
```

### Anti-Rationalization Table

| Rationalization                         | Why It's WRONG                                      | Required Action                  |
| --------------------------------------- | --------------------------------------------------- | -------------------------------- |
| "We trust our images"                   | Trust but verify. Least privilege always.           | **Add USER directive**           |
| ":latest is convenient"                 | Convenience causes incidents. Pin versions.         | **Use specific tags**            |
| "Kubernetes securityContext handles it" | Defense in depth. Image should be secure too.       | **Add USER in Dockerfile**       |
| "We rebuild often"                      | Rebuild with same vulnerability. Pin to known-good. | **Pin to specific version**      |
| "It's just internal"                    | Internal ≠ exempt from security.                    | **Follow all security patterns** |

---
