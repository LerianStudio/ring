---
name: dev-migrate-v4
description: |
  Analyzes a Go service using lib-commons v2/v3 and generates a visual migration
  report showing every change needed to upgrade to lib-commons v4. Produces an
  interactive HTML page (via ring:visual-explainer) and optionally generates
  refactoring tasks for ring:dev-cycle.
metadata:
  examples:
  - name: Analyze and show visual report
    invocation: /ring:migrate-v4
    expected_flow: Scan → Map → Visual HTML report opened in browser
  - name: Generate tasks for dev-cycle
    invocation: /ring:migrate-v4 --tasks
    expected_flow: Scan → Map → Visual report → migration-v4-tasks.md saved
  - name: Full automatic migration
    invocation: /ring:migrate-v4 --execute
    expected_flow: Scan → Map → Visual report → tasks.md → ring:dev-cycle dispatched through all 10 gates
  - name: Specific repository path
    invocation: /ring:migrate-v4 /path/to/service --execute
    expected_flow: Same as above but targets specific path
  prerequisite: |
    - Go project with go.mod containing lib-commons/v2 or lib-commons/v3
    - docs/PROJECT_RULES.md exists (recommended but not blocking)
  related:
    complementary:
    - ring:dev-cycle
    - ring:dev-refactor
    - ring:codebase-explorer
    - ring:visual-explainer
    - ring:backend-engineer-golang
  sequence:
    after:
    - ring:dev-cycle
  skip_when: |
    - Project already uses lib-commons/v4 → Report compliance status only
    - Project is not Go → Not applicable
    - Project does not use lib-commons → Not applicable
  trigger: |
    - User wants to migrate a Go service from lib-commons v2 or v3 to v4
    - User asks about lib-commons version upgrade
    - User wants to see what needs to change for v4
    - User runs /ring:migrate-v4
  verification:
    automated:
    - command: grep 'lib-commons/v4' go.mod
      description: go.mod declares lib-commons v4
      success_pattern: v4
    - command: grep -rn 'lib-commons/v2\|lib-commons/v3' --include='*.go' . | grep -v indirect | wc -l
      description: Zero v2/v3 direct imports remain
      success_pattern: ^0$
---

# Dev Migrate v4

Scans a Go service for lib-commons v2/v3 usage patterns, compares against the v4 standards defined in `golang.md`, and generates an interactive visual migration report showing every required change.

---

## ⛔ ORCHESTRATOR PRINCIPLE

You orchestrate. Agents execute. Do NOT read source code directly — dispatch `ring:codebase-explorer` and `ring:backend-engineer-golang` for all analysis.

---

## Standards Loading (MANDATORY)

Before analysis, load the v4 standards from the bundled file in this repository:

```yaml
Read:
  path: "platforms/opencode/standards/golang.md"
  extract: "Core Dependency: lib-commons" section — full package table with aliases
```

MUST use the bundled `golang.md` as the source of truth for v4 patterns. This file is versioned alongside the skill, ensuring deterministic migrations. CANNOT rely on hardcoded patterns alone — the bundled file may be updated with new packages or changed aliases.

---

## Blocker Criteria (STOP and Report)

| Condition | Action |
|-----------|--------|
| No `go.mod` found in target path | **STOP** — "Not a Go project. Cannot migrate." |
| `go.mod` does not contain `lib-commons` | **STOP** — "No lib-commons dependency found. Nothing to migrate." |
| Already on v4 with full compliance | **STOP** — "Already on v4 and compliant. No migration needed." Report compliance status only. |
| `golang.md` not found at `platforms/opencode/standards/golang.md` | **STOP** — "Standards file not found. Ensure Ring repository is accessible." |
| Target path is not readable | **STOP** — "Cannot access target path." |

---

## Cannot Be Overridden (NON-NEGOTIABLE)

<cannot_skip>
- MUST scan all 9 categories in Step 2 — no partial scans
- MUST generate visual report for every migration — no report skipping
- MUST use ring:codebase-explorer for scanning — FORBIDDEN to read code directly
- MUST follow task ordering (go.mod → imports → config → logging → bootstrap → telemetry)
- CANNOT generate tasks with placeholder file paths — all file lists MUST be concrete with line numbers
- CANNOT mark a migration complete if `go build ./...` fails
- CANNOT dispatch ring:dev-cycle without user reviewing the visual report first (unless --execute explicitly set)
- CANNOT add new v4 patterns (cassert, cruntime, cmetrics, csafe, ccrypto, cbackoff, coutbox) as migration tasks — migration is DE-PARA ONLY
- CANNOT require patterns the service does not already use — only replace existing v2/v3 patterns with v4 equivalents
</cannot_skip>

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **BREAKING** | Code will not compile without this change | Import paths, `SetConfigFromEnvVars` removal, Logger API signature |
| **MIGRATION** | v2/v3 pattern exists and has a direct v4 replacement | `libZap.InitializeLogger()` → `czap.New(...)`, `libServer.StartWithGracefulShutdown()` → manual lifecycle |
| **OUT OF SCOPE** | New v4 pattern that the service does not currently use | `cassert`, `cruntime`, `cmetrics`, `csafe` — report in visual as "v4 opportunities" but do NOT generate tasks |

> **⛔ CORE PRINCIPLE:** This skill is a **de-para** (find-and-replace) tool. It migrates what EXISTS from v2/v3 to v4. It does NOT add new capabilities. New v4 patterns that the service doesn't already use are reported as informational opportunities in the visual report, but NEVER become migration tasks.

---

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| Target path | Yes | cwd | Path to the Go service repository |
| `--tasks` | No | false | Generate `migration-v4-tasks.md` for `ring:dev-cycle` |
| `--execute` | No | false | Generate tasks AND dispatch `ring:dev-cycle` automatically |
| `--dry-run` | No | false | Show analysis and visual report only, no file generation |

---

## ⛔ MANDATORY: Initialize Todo List FIRST

```yaml
TodoWrite:
  todos:
    - content: "Detect current lib-commons version"
      status: "pending"
      activeForm: "Detecting lib-commons version"
    - content: "Scan all v2/v3 usage patterns"
      status: "pending"
      activeForm: "Scanning v2/v3 patterns"
    - content: "Map each pattern to v4 equivalent"
      status: "pending"
      activeForm: "Mapping v2/v3 → v4 equivalents"
    - content: "Generate visual migration report"
      status: "pending"
      activeForm: "Generating visual migration report"
    - content: "Generate migration-v4-tasks.md (if --tasks or --execute)"
      status: "pending"
      activeForm: "Generating migration tasks for ring:dev-cycle"
    - content: "Dispatch ring:dev-cycle (if --execute)"
      status: "pending"
      activeForm: "Dispatching ring:dev-cycle for migration execution"
    - content: "Present report to user"
      status: "pending"
      activeForm: "Presenting migration report"
```

---

## Partial Migration Detection (Applied in Step 2)

Before generating tasks, the scan MUST detect if any migration step is already done:

| Detection | Pattern | Action |
|-----------|---------|--------|
| v4 imports already present | `grep -r "lib-commons/v4" --include="*.go"` returns results | Tag matched files as `ALREADY_MIGRATED` |
| v4 logging already present | `clog.LevelInfo` or `clog.String` found | Tag logging files as `ALREADY_MIGRATED` |
| v4 bootstrap pattern present | `InitServersWithOptions` or `cruntime.SafeGoWithContextAndComponent` in main.go | Tag bootstrap as `ALREADY_MIGRATED` |
| v4 telemetry present | `cotel.NewTelemetry` found | Tag telemetry as `ALREADY_MIGRATED` |
| Mixed state (v2/v3 AND v4 in same file) | Both old and new patterns coexist | Tag as `PARTIAL_MIGRATION` — generate targeted task for remaining changes only |

**Task Generation Rule:** MUST NOT generate tasks for patterns tagged `ALREADY_MIGRATED`. Only `PARTIAL_MIGRATION` and `NOT_MIGRATED` patterns generate tasks. The visual report shows all patterns with status badges (Migrated / Partial / Pending).

---

## Step 1: Detect Current lib-commons Version

**TodoWrite:** Mark "Detect current lib-commons version" as `in_progress`

Dispatch `ring:codebase-explorer` with:

```
Analyze the Go project at {target_path}. Find:

1. The lib-commons version in go.mod (v2, v3, or v4)
   - grep for "lib-commons" in go.mod
   - Report: DIRECT dependency version and any INDIRECT versions

2. If already on v4:
   - Report: "Project already uses lib-commons v4"
   - Check compliance against golang.md standards
   - STOP migration flow, switch to compliance-only report

3. If on v2 or v3:
   - Report exact version (e.g., v2.9.1, v3.0.0-beta.13)
   - Continue to Step 2
```

**Decision gate:**
- Already v4 → Generate compliance report only (skip to Step 4 with compliance mode)
- v2 or v3 → Continue to Step 2

**TodoWrite:** Mark as `completed`

---

## Step 2: Scan All v2/v3 Usage Patterns

**TodoWrite:** Mark "Scan all v2/v3 usage patterns" as `in_progress`

Dispatch `ring:codebase-explorer` with this EXACT prompt:

```
THOROUGH scan of {target_path} for ALL lib-commons v2/v3 patterns.

For EACH category below, find every occurrence with file:line references:

### Category 1: Import Aliases
Search for these import patterns and count occurrences:
- `libCommons "github.com/LerianStudio/lib-commons/v2/commons"` or v3
- `libZap "...lib-commons/v2/commons/zap"` or v3
- `libLog "...lib-commons/v2/commons/log"` or v3
- `libOpentelemetry "...lib-commons/v2/commons/opentelemetry"` or v3
- `libServer "...lib-commons/v2/commons/server"` or v3
- `libHTTP "...lib-commons/v2/commons/net/http"` or v3
- `libPostgres "...lib-commons/v2/commons/postgres"` or v3
- `libMongo "...lib-commons/v2/commons/mongo"` or v3
- `libRedis "...lib-commons/v2/commons/redis"` or v3

### Category 2: Configuration Loading
- `libCommons.SetConfigFromEnvVars` calls
- Flat Config struct (all env vars in one struct vs nested)
- Missing `envDefault:` tags

### Category 3: Logging API
- `logger.Infof(`, `logger.Errorf(`, `logger.Warnf(`, `logger.Debugf(` (Printf-style)
- `logger.Info(`, `logger.Error(`, `logger.Warn(` (non-Printf but v2-style)
- `logger.WithFields(` (v2 field pattern)
- `logger.Sync()` without context argument

### Category 4: Bootstrap Lifecycle
- `libCommons.NewLauncher(`
- `libCommons.RunApp(`
- `libServer.NewServerManager(`
- `libServer.StartWithGracefulShutdown(`
- `InitServers() *Service` (returns value, not error)
- `bootstrap.InitServers().Run()` in main.go

### Category 5: Context Tracking (BREAKING — highest impact, affects every layer)
- `libCommons.NewTrackingFromContext(ctx)` — count ALL occurrences, this is the core v2 pattern
- `logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)` — the 4-return destructuring
- Logger recovered from context instead of dependency injection
- Structs that DON'T have a `logger` field but call `NewTrackingFromContext` in methods

### Category 6: Telemetry
- `libOpentelemetry.InitializeTelemetry(` (panics on error)
- Missing `ApplyGlobals()` call
- `libOpentelemetry.HandleSpanError(`
- `libOpentelemetry.HandleSpanBusinessErrorEvent(`

### Category 7: HTTP Responses
- `libHTTP.OK(`, `libHTTP.Created(`, `libHTTP.WithError(`
- `libHTTP.HandleFiberError`
- `libHTTP.NewTelemetryMiddleware(`

### Category 8: Database Connections
- `libPostgres.PostgresConnection{` struct usage
- `libRedis.RedisConnection{` struct usage
- `libMongo.MongoConnection{` struct usage
- `.Connect()` + `.GetDB()` pattern

### Category 9: v4 Opportunities (INFORMATIONAL ONLY — do NOT generate tasks)
Scan for v4-only packages that the service does NOT currently use.
Report these as "v4 Opportunities" in the visual report for future consideration.
These are NOT migration tasks — they are suggestions for a future ring:dev-refactor pass.

- No `cassert` usage → could replace panic-based validation
- No `cruntime.SafeGoWithContextAndComponent` → could replace raw `go func(){}()`
- No `cmetrics.Metric` definitions → could replace manual OTel metric creation
- No `csafe` usage → could replace manual decimal division
- No `ccrypto` usage → could replace manual AES/HMAC implementations
- No `cbackoff` usage → could replace manual retry loops
- No `coutbox` usage → could add reliable event publishing
- No `cpointers` usage → could simplify pointer helpers
- No `csecurity` usage → could add sensitive field obfuscation
- No `crabbitmq` usage → could replace manual AMQP connection handling
- No `csm` usage → could add M2M credential management

**⛔ These findings go to the "v4 Opportunities" section of the visual report. They do NOT become MIG-XXX tasks.**

For EACH finding, report:
- Category
- Pattern found (exact code snippet)
- File path and line number
- v4 replacement pattern
- Severity: BREAKING (must change to compile), RECOMMENDED (should change), OPTIONAL (nice to have)
```

**TodoWrite:** Mark as `completed`

---

## Step 3: Map Each Pattern to v4 Equivalent

**TodoWrite:** Mark "Map each pattern to v4 equivalent" as `in_progress`

Using the scan results from Step 2, build a structured migration map:

```markdown
## Migration Map

### Summary
- **Current version:** lib-commons/{version}
- **Target version:** lib-commons/v4
- **Total changes needed:** {count}
- **Breaking changes:** {count} (must change to compile)
- **Recommended changes:** {count} (should change for compliance)
- **Files affected:** {count}

### Changes by Category

#### 1. Import Aliases ({count} files)
| File | Current Import | v4 Import | v4 Alias |
|------|---------------|-----------|----------|
| {file}:{line} | `libCommons "lib-commons/v2/commons"` | `libCommons "lib-commons/v4/commons"` | `libCommons` |
| ... | ... | ... | ... |

#### 2. Configuration Loading ({count} files)
| File | Current Pattern | v4 Pattern |
|------|----------------|------------|
| {file}:{line} | `libCommons.SetConfigFromEnvVars(&cfg)` | `libCommons.InitLocalEnvConfig()` + `env.Parse(&cfg)` |
| ... | ... | ... |

#### 3. Logging API ({count} calls)
| File | Current Call | v4 Call |
|------|-------------|--------|
| {file}:{line} | `logger.Infof("msg: %s", val)` | `s.logger.Log(ctx, clog.LevelInfo, "msg", clog.String("key", val))` |
| ... | ... | ... |

... (repeat for all 9 categories)

#### v4 Opportunities (informational — NOT migration tasks)
| Pattern | Potential Benefit | Action |
|---------|------------------|--------|
| `cassert` | Safe validation (replaces panic) | Suggest in visual report |
| `cruntime` | Safe goroutines with crash policies | Suggest in visual report |
| `cmetrics` | Typed metric definitions | Suggest in visual report |
| `csafe` | Safe decimal math | Suggest in visual report |
| `ccrypto` | AES-GCM encryption | Suggest in visual report |
| ... | (other v4-only patterns) | Future `/ring:dev-refactor` |
```

**TodoWrite:** Mark as `completed`

---

## Step 4: Generate Visual Migration Report

**TodoWrite:** Mark "Generate visual migration report" as `in_progress`

Use `ring:visual-explainer` to create an interactive HTML page. Pass this prompt:

```
Create a professional HTML page titled "lib-commons Migration Report: {service-name}"
with Lerian branding (sunglow accent, Inter font, dark theme).

The page should have:

## Header
- Service name: {service-name}
- Current version: lib-commons/{current-version}
- Target version: lib-commons/v4
- Date: {today}
- Summary stats: {breaking-count} breaking, {recommended-count} recommended, {files-count} files affected

## Summary Dashboard
- Donut/bar chart showing changes by category
- Color coding: red=breaking, orange=recommended, green=already compliant

## Migration Changes (de-para — Categories 1-8)
For EACH category where v2/v3 patterns were found:
- Category title with badge (BREAKING / MIGRATION)
- Count of changes needed
- Side-by-side code comparison (current code on left, v4 replacement on right)
  - Use actual code from the scanned repository (not generic examples)
  - Highlight the exact lines that need to change
- File list with line numbers
- Corresponding MIG-XXX task reference

## v4 Opportunities (informational — Category 9)
Separate section with green/blue styling (NOT red):
- List v4-only packages the service does NOT currently use
- Brief description of what each provides
- Label: "Available after migration via /ring:dev-refactor"
- These are suggestions, NOT requirements

## Migration Checklist
- Checkbox list of all de-para changes organized by file
- Grouped by: go.mod → imports → config → bootstrap → logging → telemetry → database
- Does NOT include v4 opportunities (those are separate)

## Estimated Effort
- Small service (<10 files affected): ~2-4 hours
- Medium service (10-30 files): ~1-2 days
- Large service (30+ files): ~3-5 days

Save to: ~/.agent/diagrams/{service-name}-v4-migration.html
```

Open the HTML in the browser.

**TodoWrite:** Mark as `completed`

---

## Step 5: Generate Migration Tasks (MANDATORY with --tasks or --execute)

**TodoWrite:** Mark "Generate tasks.md (if --tasks)" as `in_progress`

Generate a `tasks.md` file in the **exact format** that `ring:dev-cycle` expects. Each finding from Step 2 MUST map to a task. Tasks are grouped by migration phase to ensure correct execution order.

**⛔ CRITICAL:** The tasks file MUST follow the `## Task: {ID} - {Title}` format with `- [ ]` acceptance criteria. This is the contract with `ring:dev-cycle`.

Save to: `docs/pre-dev/{service-name}/migration-v4-tasks.md`

### Task File Template

```markdown
# Migration Tasks: {service-name} → lib-commons v4

> Generated by ring:dev-migrate-v4 on {date}
> Source: lib-commons/{current-version} → lib-commons/v4
> Findings: {total-findings} across {files-affected} files

---

## Task: MIG-001 - Update go.mod dependencies

Update go.mod to replace lib-commons/v2 (or v3) with lib-commons/v4.
Run `go get github.com/LerianStudio/lib-commons/v4@latest` and `go mod tidy`.

### Acceptance Criteria
- [ ] go.mod declares `github.com/LerianStudio/lib-commons/v4` as direct dependency
- [ ] No `lib-commons/v2` or `lib-commons/v3` as direct dependency (indirect via lib-auth is acceptable)
- [ ] `go build ./...` compiles successfully
- [ ] `go vet ./...` passes

### Files
- go.mod
- go.sum

### Context for Agent
```text
Run: go get github.com/LerianStudio/lib-commons/v4@latest
Run: go mod tidy
Verify: go build ./...
```

---

## Task: MIG-002 - Migrate import aliases to v4 convention

Replace all lib-commons v2/v3 import aliases with v4 `c` prefix convention.

### Acceptance Criteria
- [ ] All import paths changed from `/v2/` or `/v3/` to `/v4/`
- [ ] `libCommons` alias kept for root `commons` package (path changes, alias stays)
- [ ] All `libZap` aliases replaced with `czap`
- [ ] All `libLog` aliases replaced with `clog`
- [ ] All `libOpentelemetry` aliases replaced with `cotel`
- [ ] All `libHTTP` aliases replaced with `chttp`
- [ ] All `libPostgres` aliases replaced with `cpostgres`
- [ ] All `libMongo` aliases replaced with `cmongo`
- [ ] All `libRedis` aliases replaced with `credis`
- [ ] All `libServer` / `libCommonsServer` imports removed (v4 uses manual lifecycle)
- [ ] **Test files (`_test.go`) updated with same import changes**
- [ ] `go build ./...` compiles successfully
- [ ] `go test ./...` passes

### Files
{list every file with lib-commons imports — including _test.go files — with line numbers}

---

## Task: MIG-003 - Migrate configuration loading

Replace `libCommons.SetConfigFromEnvVars` with `libCommons.InitLocalEnvConfig()` and nested config structs.

### Acceptance Criteria
- [ ] `libCommons.InitLocalEnvConfig()` called in main.go (replaces `SetConfigFromEnvVars`)
- [ ] Config struct uses nested pattern (`AppConfig`, `ServerConfig`, `PostgresConfig`, etc.)
- [ ] Nested structs use `envPrefix:` tags
- [ ] All fields have `envDefault:` tags with sensible defaults
- [ ] Config validation returns errors (no panics in config loading)
- [ ] Production-specific validation present (TLS checks, secret strength, etc.)
- [ ] **Config test files (`_test.go`) updated to use v4 patterns**
- [ ] `go test ./internal/bootstrap/...` passes

### Files
{config files — including _test.go}

### Context for Agent
Reference: golang.md §4 Configuration

---

## Task: MIG-004 - Migrate logging and context tracking

Replace Printf-style logging AND `NewTrackingFromContext` pattern with v4 dependency-injected structured logging.

**This is the highest-impact task.** In v2, every service/handler/repository method calls `libCommons.NewTrackingFromContext(ctx)` to get logger+tracer. In v4, logger is a struct field injected at construction. This change affects every layer.

### v2 pattern (REMOVE):
```go
func (s *MyService) DoSomething(ctx context.Context) error {
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)
    ctx, span := tracer.Start(ctx, "service.do_something")
    defer span.End()
    logger.Infof("Processing: %s", id)
}
```

### v4 pattern (REPLACE WITH):
```go
type MyService struct {
    logger clog.Logger  // injected at construction
}

func (s *MyService) DoSomething(ctx context.Context) error {
    s.logger.Log(ctx, clog.LevelInfo, "Processing", clog.String("id", id))
}
```

### Acceptance Criteria
- [ ] **All `libCommons.NewTrackingFromContext(ctx)` calls removed** — this is the core v2→v4 change
- [ ] Logger added as struct field (`logger clog.Logger`) to every service, handler, and repository that used `NewTrackingFromContext`
- [ ] Logger injected via constructor in bootstrap/DI wiring
- [ ] All `logger.Infof("msg: %s", val)` replaced with `s.logger.Log(ctx, clog.LevelInfo, "msg", clog.String("key", val))`
- [ ] All `logger.Errorf("msg: %v", err)` replaced with `s.logger.Log(ctx, clog.LevelError, "msg", clog.Err(err))`
- [ ] All `logger.Warnf(...)` replaced with `s.logger.Log(ctx, clog.LevelWarn, ...)`
- [ ] All `logger.WithFields(...)` calls replaced with typed field constructors
- [ ] `logger.Sync()` replaced with `logger.Sync(ctx)` (takes context)
- [ ] Core three from `NewTrackingFromContext` replaced with global OTel tracer (`otel.Core three(tracerName).Start(ctx, name)`) — set by `cotel.NewTelemetry()` + `tl.ApplyGlobals()` at bootstrap
- [ ] Zero `NewTrackingFromContext` calls remain in codebase
- [ ] Zero `logger.Infof` / `logger.Errorf` calls remain in codebase
- [ ] **Test files updated: mock loggers use `clog.NewNop()`, struct constructors pass logger**
- [ ] `go test ./...` passes

### Files
{every file with `NewTrackingFromContext` OR logging calls — including _test.go — sorted by call count descending}

### Context for Agent
v2 recovery pattern to search for: `logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)`
v4 replacement: add `logger clog.Logger` field to struct, inject in constructor, use `s.logger.Log(ctx, level, msg, fields...)`
Field constructors: `clog.String(k,v)`, `clog.Int(k,v)`, `clog.Err(err)`, `clog.Bool(k,v)`, `clog.Float64(k,v)`, `clog.Duration(k,v)`
Levels: `clog.LevelInfo`, `clog.LevelError`, `clog.LevelWarn`, `clog.LevelDebug`
Test logger: `clog.NewNop()` for unit tests

---

## Task: MIG-005 - Migrate bootstrap lifecycle

Replace Launcher/ServerManager pattern with v4 explicit lifecycle.

### Acceptance Criteria
- [ ] main.go uses `os.Exit(run())` pattern
- [ ] `signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)` for shutdown
- [ ] `cruntime.SafeGoWithContextAndComponent` for server goroutine (CrashProcess policy)
- [ ] `InitServersWithOptions(opts) (*Service, error)` replaces `InitServers() *Service`
- [ ] Bootstrap returns errors instead of panicking
- [ ] `Service.Run(ctx context.Context) error` method for starting
- [ ] `Service.Shutdown(ctx context.Context) error` method with ordered cleanup
- [ ] 30-second graceful shutdown timeout
- [ ] No `libCommons.Launcher`, `libCommons.RunApp`, `libServer.StartWithGracefulShutdown`
- [ ] **Bootstrap test files updated to use v4 initialization pattern**
- [ ] `go test ./internal/bootstrap/...` passes
- [ ] `go test ./cmd/...` passes

### Files
{bootstrap files — including _test.go: main.go, main_test.go, service.go, service_test.go, config.go, config_test.go}

### Context for Agent
Reference: golang.md §6 Bootstrap — complete main.go, service.go, config.go templates

---

## Task: MIG-006 - Migrate telemetry initialization

Replace `InitializeTelemetry` with `NewTelemetry` + `ApplyGlobals`.

### Acceptance Criteria
- [ ] `cotel.NewTelemetry(config)` returns `(*Telemetry, error)` — no panic
- [ ] `tl.ApplyGlobals()` called after creation
- [ ] `InsecureExporter: cfg.App.EnvName != "production"` set
- [ ] `cotel.HandleSpanError` replaces `libOpentelemetry.HandleSpanError`
- [ ] `cotel.HandleSpanBusinessErrorEvent` replaces `libOpentelemetry.HandleSpanBusinessErrorEvent`
- [ ] Telemetry middleware uses `chttp.NewTelemetryMiddleware(tl)`
- [ ] **Test files with span assertions updated to use `cotel` API**
- [ ] `go test ./...` passes

### Files
{telemetry init files + all files with span error handling — including _test.go}

---

## Task: MIG-FINAL - Verify full migration

Run all verification commands to confirm the de-para migration is complete.

### Acceptance Criteria
- [ ] `go build ./...` compiles with zero errors
- [ ] `go vet ./...` passes with zero warnings
- [ ] `go test ./...` passes (all unit tests)
- [ ] `golangci-lint run ./...` passes
- [ ] Zero `lib-commons/v2` or `lib-commons/v3` as direct dependency in go.mod
- [ ] Zero `libCommons.`, `libZap.`, `libLog.`, `libOpentelemetry.`, `libServer.`, `libHTTP.` aliases in code
- [ ] Zero `logger.Infof`, `logger.Errorf`, `logger.Warnf` calls in production code
- [ ] Zero `SetConfigFromEnvVars` calls
- [ ] Zero `NewTrackingFromContext` calls

### Files
- All Go files in repository

### Context for Agent
```text
Run these commands and verify zero issues:
  go build ./...
  go vet ./...
  go test -tags unit ./...
  golangci-lint run ./...
  grep -rn "lib-commons/v2\|lib-commons/v3" --include="*.go" . | grep -v "// indirect"
  grep -rn "libCommons\.\|libZap\.\|libLog\.\|libOpentelemetry\.\|libServer\.\|libHTTP\." --include="*.go" .
  grep -rn "logger\.Infof\|logger\.Errorf\|logger\.Warnf" --include="*.go" ./internal ./cmd
  grep -rn "SetConfigFromEnvVars\|NewTrackingFromContext" --include="*.go" .
```

```

### Task Generation Rules

When generating the actual tasks file for a specific repository:

1. **Only findings from Categories 1-8 generate tasks** — Category 9 (v4 Opportunities) is informational only
2. **Files list MUST be concrete** — actual file paths with line numbers, not placeholders
3. **Files list MUST include `_test.go` files** — test files use the same imports, loggers, and patterns. Migrating production code without tests will break the build.
4. **Acceptance criteria MUST be verifiable** — agent can grep/build to confirm
5. **Task ordering matters** — MIG-001 (go.mod) MUST execute before MIG-002 (imports)
6. **Context for Agent section** — include enough detail for `ring:backend-engineer-golang` to execute without additional codebase exploration
7. **Skip tasks where pattern is not found** — if service has no RabbitMQ, do not generate MIG for RabbitMQ migration
8. **MIG-FINAL is always the last task** — verifies entire migration compiles and passes tests

**TodoWrite:** Mark as `completed`

---

## Step 6: Dispatch ring:dev-cycle (with --execute flag)

**TodoWrite:** Mark "Dispatch ring:dev-cycle" as `in_progress`

If `--execute` flag is set, automatically hand off to `ring:dev-cycle`:

```
Skill tool: ring:dev-cycle
Args: "docs/pre-dev/{service-name}/migration-v4-tasks.md"
```

The DevCycle will execute each migration task through **all 10 gates**:

| Gate | What Happens for Migration |
|------|---------------------------|
| **Gate 0: Implementation** | `ring:backend-engineer-golang` executes the code changes |
| **Gate 0.5: Delivery Verification** | Verifies each task's acceptance criteria are met |
| **Gate 1: DevOps** | Updates Docker/compose if needed (Go version, env vars) |
| **Gate 2: SRE** | Validates observability (telemetry, metrics, health checks) |
| **Gate 3: Unit Testing** | Ensures tests pass with v4 patterns, updates test imports |
| **Gate 4: Fuzz Testing** | Runs fuzz tests against new validation patterns |
| **Gate 5: Property Testing** | Verifies domain invariants still hold |
| **Gate 6: Integration Testing** | Writes/updates integration tests for v4 connections |
| **Gate 7: Chaos Testing** | Writes/updates chaos tests for circuit breakers |
| **Gate 8: Code Review** | 7 parallel reviewers verify migration quality |
| **Gate 9: Validation** | Final user approval |

If `--execute` is NOT set but `--tasks` is, present:

```markdown
## Tasks Generated

Migration tasks saved to: `docs/pre-dev/{service-name}/migration-v4-tasks.md`

**{task-count} tasks** ready for execution.

### To execute:
```bash
/ring:dev-cycle docs/pre-dev/{service-name}/migration-v4-tasks.md
```
```

**TodoWrite:** Mark as `completed`

---

## Step 7: Present Report

**TodoWrite:** Mark "Present report to user" as `in_progress`

Present summary to user:

```markdown
## Migration Report: {service-name}

**Current:** lib-commons/{version} → **Target:** lib-commons/v4

### Migration Tasks (de-para only — what EXISTS gets replaced)
| Category | Changes | Severity | Task |
|----------|---------|----------|------|
| go.mod dependencies | 1 file | BREAKING | MIG-001 |
| Import aliases | {count} files | BREAKING | MIG-002 |
| Configuration | {count} files | BREAKING | MIG-003 |
| Logging API | {count} calls | BREAKING | MIG-004 |
| Bootstrap lifecycle | {count} files | BREAKING | MIG-005 |
| Telemetry init | {count} files | BREAKING | MIG-006 |
| Full verification | all files | VERIFICATION | MIG-FINAL |

### v4 Opportunities (informational — shown in visual report only)
| Opportunity | Description | Status |
|-------------|-------------|--------|
| `cassert` | Safe validation (replaces panic) | Suggestion for future `/ring:dev-refactor` |
| `cruntime` | Safe goroutines with crash policies | Suggestion for future `/ring:dev-refactor` |
| `cmetrics` | Typed metric definitions | Suggestion for future `/ring:dev-refactor` |
| `csafe` | Safe decimal math | Suggestion for future `/ring:dev-refactor` |
| ... | (other v4-only patterns not currently used) | ... |

### Artifacts
- Visual report: `~/.agent/diagrams/{service-name}-v4-migration.html`
- Tasks file: `docs/pre-dev/{service-name}/migration-v4-tasks.md`
- DevCycle: {dispatched / ready to dispatch}
```

**TodoWrite:** Mark as `completed`

---

## V4 Pattern Quick Reference (for agent context)

These are the canonical v4 patterns from `golang.md`. Agents dispatched by this skill MUST use these as the target patterns.

### Import Convention
```go
import (
    // Core
    libCommons "github.com/LerianStudio/lib-commons/v4/commons"
    clog "github.com/LerianStudio/lib-commons/v4/commons/log"
    czap "github.com/LerianStudio/lib-commons/v4/commons/zap"
    cconst "github.com/LerianStudio/lib-commons/v4/commons/constants"
    cpointers "github.com/LerianStudio/lib-commons/v4/commons/pointers"

    // Safety & Validation
    cassert "github.com/LerianStudio/lib-commons/v4/commons/assert"
    cruntime "github.com/LerianStudio/lib-commons/v4/commons/runtime"
    csafe "github.com/LerianStudio/lib-commons/v4/commons/safe"
    ccrypto "github.com/LerianStudio/lib-commons/v4/commons/crypto"

    // Observability
    cotel "github.com/LerianStudio/lib-commons/v4/commons/opentelemetry"
    cmetrics "github.com/LerianStudio/lib-commons/v4/commons/opentelemetry/metrics"

    // HTTP & Networking
    chttp "github.com/LerianStudio/lib-commons/v4/commons/net/http"

    // Infrastructure
    cpostgres "github.com/LerianStudio/lib-commons/v4/commons/postgres"
    cmongo "github.com/LerianStudio/lib-commons/v4/commons/mongo"
    credis "github.com/LerianStudio/lib-commons/v4/commons/redis"
    crabbitmq "github.com/LerianStudio/lib-commons/v4/commons/rabbitmq"

    // Resilience
    ccb "github.com/LerianStudio/lib-commons/v4/commons/circuitbreaker"
    cbackoff "github.com/LerianStudio/lib-commons/v4/commons/backoff"

    // Security & Secrets
    csecurity "github.com/LerianStudio/lib-commons/v4/commons/security"
    csm "github.com/LerianStudio/lib-commons/v4/commons/secretsmanager"

    // Event Publishing
    coutbox "github.com/LerianStudio/lib-commons/v4/commons/outbox"
)
```

### Logging
```go
// Initialization (bootstrap only)
logger, err := czap.New(czap.Config{
    Level:       cfg.App.LogLevel,
    Development: cfg.App.EnvName != "production",
})

// Usage (any layer) — structured fields, context-first
s.logger.Log(ctx, clog.LevelInfo, "Processing transfer",
    clog.String("transferId", id),
    clog.Int("amount", amount))

s.logger.Log(ctx, clog.LevelError, "Failed to process",
    clog.Err(err),
    clog.String("transferId", id))

// Sync (takes context)
logger.Sync(ctx)
```

### Configuration
```go
// main.go
libCommons.InitLocalEnvConfig()

// Nested config structs
type Config struct {
    App       AppConfig       `envPrefix:""`
    Server    ServerConfig    `envPrefix:"SERVER_"`
    Postgres  PostgresConfig  `envPrefix:"POSTGRES_"`
    Redis     RedisConfig     `envPrefix:"REDIS_"`
    Mongo     MongoConfig     `envPrefix:"MONGO_"`
    Auth      AuthConfig      `envPrefix:"PLUGIN_AUTH_"`
    Telemetry TelemetryConfig `envPrefix:"OTEL_"`
}

type AppConfig struct {
    EnvName  string `env:"ENV_NAME"  envDefault:"development"`
    LogLevel string `env:"LOG_LEVEL" envDefault:"info"`
}
```

### Bootstrap
```go
// main.go
func main() { os.Exit(run()) }

func run() int {
    libCommons.InitLocalEnvConfig()
    svc, err := bootstrap.InitServersWithOptions(nil)
    if err != nil { return 1 }

    ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
    defer cancel()

    errChan := make(chan error, 1)
    cruntime.SafeGoWithContextAndComponent(ctx, svc.Logger, "bootstrap", "server-runner",
        cruntime.CrashProcess, func(goCtx context.Context) { errChan <- svc.Run(goCtx) })

    select {
    case <-ctx.Done():
        // shutdown signal
    case err := <-errChan:
        if err != nil { /* log error */ }
    }

    shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    if err := svc.Shutdown(shutdownCtx); err != nil { return 1 }
    return 0
}
```

### Telemetry
```go
tl, err := cotel.NewTelemetry(cotel.TelemetryConfig{
    ServiceName:               cfg.Telemetry.ServiceName,
    ServiceVersion:            cfg.Telemetry.ServiceVersion,
    DeploymentEnv:             cfg.Telemetry.DeploymentEnv,
    CollectorExporterEndpoint: cfg.Telemetry.CollectorEndpoint,
    EnableTelemetry:           cfg.Telemetry.Enabled,
    InsecureExporter:          cfg.App.EnvName != "production",
    Logger:                    logger,
})
if err != nil { return nil, err }
if err = tl.ApplyGlobals(); err != nil { return nil, err }
```

### Safe Goroutines
```go
cruntime.SafeGoWithContextAndComponent(ctx, logger, "component", "name",
    cruntime.CrashProcess, // or cruntime.KeepRunning
    func(goCtx context.Context) { /* body */ })
```

### Assertions
```go
asserter := cassert.New(ctx, nil, constants.ApplicationName, "operation")
if err := asserter.NotNil(ctx, value, "field is required"); err != nil {
    return fmt.Errorf("validation: %w", err)
}
if err := asserter.That(ctx, amount > 0, "amount must be positive"); err != nil {
    return fmt.Errorf("validation: %w", err)
}
```

---

## Anti-Rationalization Table

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalization patterns. The table below covers migration-specific rationalizations:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Only imports changed, quick find-replace" | API signatures changed too (logging, config, telemetry). Find-replace will not compile. | **Full analysis required** |
| "We can migrate incrementally" | v2 and v4 cannot coexist in the same go.mod as direct deps. Must be atomic. | **Single migration, all at once** |
| "Tests still pass with v2" | Tests passing ≠ standards compliant. v4 patterns are mandatory. | **Migrate tests too** |
| "Our custom patterns work fine" | Custom ≠ standard. lib-commons v4 provides the canonical implementation. | **Replace custom with v4** |
| "This service is small, doesn't need all patterns" | Size is irrelevant. All existing v2/v3 patterns MUST be replaced. | **Replace all existing patterns** |
| "Let's also add cassert/cruntime while we're at it" | Migration is de-para only. New patterns are a separate concern for ring:dev-refactor. | **Report as v4 opportunity, do NOT add** |
| "We should add circuit breakers during migration" | If the service doesn't already have circuit breakers, adding them is a new feature, not a migration. | **Out of scope — suggest in visual report** |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|--------------|
| "Just update the imports, skip the rest" | "Import changes alone will not compile — the logging API, config loading, and bootstrap patterns have breaking changes. I need to map all existing patterns for a successful migration." |
| "We don't need the visual report" | "The visual report helps the team review all changes before execution. I'll generate it — it takes 30 seconds." |
| "Add cassert/cruntime/cmetrics too while we're at it" | "Migration is de-para only — we replace what exists. New v4 patterns are shown as opportunities in the report. Use `/ring:dev-refactor` after migration to adopt them." |
| "Can you just do it without the analysis?" | "Blind migration risks compilation errors and missed patterns. The analysis ensures zero surprises." |
| "Also refactor the architecture while migrating" | "Migration scope is strictly v2/v3 → v4 replacement. Architecture changes are a separate `/ring:dev-refactor` concern." |
