# Go Standards - Compliance

> **Module:** compliance.md | **Meta-sections** | **Parent:** [index.md](index.md)

This module covers standards compliance output format and self-verification checklist.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| Meta | [Standards Compliance Output Format](#standards-compliance-output-format) | Output format for compliance reports |
| Meta | [Checklist](#checklist) | Self-verification checklist before submitting |

---

## Standards Compliance Output Format

When producing a Standards Compliance report (used by ring:dev-refactor workflow), follow these output formats:

### If all Categories Are Compliant

```markdown
## Standards Compliance

### Lerian/Ring Standards Comparison

#### Bootstrap & Initialization
| Category | Current Pattern | Expected Pattern | Status | Evidence |
|----------|----------------|------------------|--------|----------|
| Config Struct | `Config` struct with `env` tags | Single struct with `env` tags | ✅ Compliant | `internal/bootstrap/config.go:15` |
| Config Loading | `libCommons.SetConfigFromEnvVars(&cfg)` | `libCommons.SetConfigFromEnvVars(&cfg)` | ✅ Compliant | `internal/bootstrap/config.go:42` |
| Logger Init | `libZap.InitializeLogger()` | `libZap.InitializeLogger()` (bootstrap only) | ✅ Compliant | `internal/bootstrap/config.go:45` |
| Telemetry Init | `libOpentelemetry.InitializeTelemetry()` | `libOpentelemetry.InitializeTelemetry()` | ✅ Compliant | `internal/bootstrap/config.go:48` |
| ... | ... | ... | ✅ Compliant | ... |

#### Context & Tracking
| Category | Current Pattern | Expected Pattern | Status | Evidence |
|----------|----------------|------------------|--------|----------|
| ... | ... | ... | ✅ Compliant | ... |

#### Infrastructure
| Category | Current Pattern | Expected Pattern | Status | Evidence |
|----------|----------------|------------------|--------|----------|
| ... | ... | ... | ✅ Compliant | ... |

#### Domain Patterns
| Category | Current Pattern | Expected Pattern | Status | Evidence |
|----------|----------------|------------------|--------|----------|
| ... | ... | ... | ✅ Compliant | ... |

### Verdict: ✅ FULLY COMPLIANT

No migration actions required. All categories verified against Lerian/Ring Go Standards.
```

### If any Category Is Non-Compliant

```markdown
## Standards Compliance

### Lerian/Ring Standards Comparison

#### Bootstrap & Initialization
| Category | Current Pattern | Expected Pattern | Status | File/Location |
|----------|----------------|------------------|--------|---------------|
| Config Struct | Scattered `os.Getenv()` calls | Single struct with `env` tags | ⚠️ Non-Compliant | `cmd/api/main.go` |
| Config Loading | Manual env parsing | `libCommons.SetConfigFromEnvVars(&cfg)` | ⚠️ Non-Compliant | `cmd/api/main.go:25` |
| Logger Init | `libZap.InitializeLogger()` | `libZap.InitializeLogger()` (bootstrap only) | ✅ Compliant | `cmd/api/main.go:30` |
| ... | ... | ... | ... | ... |

#### Context & Tracking
| Category | Current Pattern | Expected Pattern | Status | File/Location |
|----------|----------------|------------------|--------|---------------|
| ... | ... | ... | ... | ... |

### Verdict: ⚠️ NON-COMPLIANT (X of Y categories)

### Required Changes for Compliance

1. **Config Struct Migration**
   - Replace: Direct `os.Getenv()` calls scattered across files
   - With: Single `Config` struct with `env` tags in `/internal/bootstrap/config.go`
   - Import: `libCommons "github.com/LerianStudio/lib-commons/v2/commons"`
   - Usage: `libCommons.SetConfigFromEnvVars(&cfg)`
   - Files affected: `cmd/api/main.go`, `internal/service/user.go`

2. **Logger Migration**
   - Replace: Custom logger or `log.Println()`
   - With: lib-commons structured logger
   - Bootstrap import: `libZap "github.com/LerianStudio/lib-commons/v2/commons/zap"` (initialization)
   - Application import: `libLog "github.com/LerianStudio/lib-commons/v2/commons/log"` (interface for logging calls)
   - Bootstrap usage: `logger := libZap.InitializeLogger()` (returns `libLog.Logger` interface)
   - Application usage: Use `libLog.Logger` interface for all logging calls
   - Files affected: [list files]

3. **Telemetry Migration**
   - Replace: No tracing or custom tracing
   - With: OpenTelemetry integration
   - Import: `libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"`
   - Usage: `telemetry := libOpentelemetry.InitializeTelemetry(&libOpentelemetry.TelemetryConfig{...})`
   - Files affected: [list files]

4. **[Next Category] Migration**
   - Replace: ...
   - With: ...
   - Import: ...
   - Usage: ...
```

**CRITICAL:** The comparison table is not optional. It serves as:
1. **Evidence** that each category was actually checked
2. **Documentation** for the codebase's compliance status
3. **Audit trail** for future refactors

---

## Checklist

Before submitting Go code, verify:

- [ ] Using lib-commons v2 for infrastructure
- [ ] Configuration loaded via `SetConfigFromEnvVars`
- [ ] Telemetry initialized and middleware configured
- [ ] Logger/tracer recovered from context via `NewTrackingFromContext`
- [ ] **No direct imports of `go.opentelemetry.io/otel/*` packages** (use lib-commons wrappers)
- [ ] **No direct Fiber responses** (`c.JSON()`, `c.Send()`) - use `libHTTP.OK()`, `libHTTP.WithError()`
- [ ] All errors are checked and wrapped with context
- [ ] Error codes use service prefix (e.g., PLT-0001)
- [ ] No `panic()` outside `main.go` or `InitServers`
- [ ] Tests use table-driven pattern
- [ ] Database models have ToEntity/FromEntity methods
- [ ] Interfaces defined where they're used
- [ ] No global mutable state
- [ ] Context propagated through all calls
- [ ] Sensitive data not logged
- [ ] golangci-lint passes
- [ ] Pagination strategy defined in TRD (or confirmed with user if no TRD)
- [ ] Domain entities use constructor functions (NewXxx) with validation
- [ ] Constructor functions return `(Entity, error)` - never create invalid state
- [ ] POST endpoints that create resources implement idempotency (Redis SetNX pattern)
- [ ] `IDEMPOTENCY_ENABLED` and `IDEMPOTENCY_DEFAULT_TTL_SEC` defined in Config struct
- [ ] TTL precedence: `X-TTL` header > `IDEMPOTENCY_DEFAULT_TTL_SEC` env > `libRedis.TTL` fallback
- [ ] If multi-tenant: JWT tenant extraction + appropriate context getter (`tmcore.GetPGContext(ctx, module)` for multi-module PG, `tmcore.GetPGContext(ctx)` for single-module PG, `tmcore.GetMBContext(ctx, module)` or `tmcore.GetMBContext(ctx)` for MongoDB)
