---
name: dev-delivery-verification
description: |
  Delivery Verification Gate — verifies that what was requested is actually delivered
  as reachable, integrated code. Not quality review (Gate 8), not test verification
  (Gate 9) — this gate answers: "Is every requirement from the original task actually
  functioning in the running application?" Applies to ANY task type: features, refactors,
  fixes, infrastructure, API endpoints, middleware, business logic, integrations.
metadata:
  NOT_skip_when: |
    - "Code compiles" → Compilation ≠ integration. Dead code compiles.
    - "Tests pass" → Unit tests on isolated structs pass without wiring.
    - "It's just a struct/interface" → Structs that aren't instantiated are dead code.
    - "Wire will happen in next task" → Each task must deliver complete, reachable code.
    - "Time pressure" → Unwired code is worse than no code — it creates false confidence.
    - "It's a simple task" → Simple tasks still need verification. Partial delivery is not delivery.
  input_schema:
    required:
    - name: unit_id
      type: string
      description: Task or subtask identifier being verified
    - name: requirements
      type: string
      description: Original task requirements or acceptance criteria
    - name: files_changed
      type: array
      items: string
      description: List of files created or modified by Gate 0
    optional:
    - name: gate0_handoff
      type: object
      description: Full handoff from Gate 0 implementation
  output_schema:
    format: markdown
    required_sections:
    - name: Delivery Verification Summary
      pattern: ^## Delivery Verification Summary
      required: true
    - name: Requirement Coverage Matrix
      pattern: ^## Requirement Coverage Matrix
      required: true
    - name: Integration Verification
      pattern: ^## Integration Verification
      required: true
    - name: Dead Code Detection
      pattern: ^## Dead Code Detection
      required: true
    - name: Verdict
      pattern: ^## Verdict
      required: true
    - name: Return to Gate 0
      pattern: ^## Return to Gate 0
      required: true
      description: Mandatory when verdict is PARTIAL or FAIL. Lists specific undelivered requirements with fix instructions for Gate 0.
    metrics:
    - name: result
      type: enum
      values:
      - PASS
      - FAIL
      - PARTIAL
    - name: requirements_total
      type: integer
    - name: requirements_delivered
      type: integer
    - name: requirements_missing
      type: integer
    - name: dead_code_items
      type: integer
    - name: remediation_items
      type: integer
      description: Number of fix instructions returned to Gate 0 (0 when PASS)
  related:
    complementary:
    - ring:dev-cycle
    - ring:dev-implementation
    - ring:verification-before-completion
    - ring:requesting-code-review
  sequence:
    after:
    - ring:dev-implementation
    before:
    - ring:dev-devops
  trigger: |
    - After Gate 0 (implementation) completes, before advancing to Gate 1
    - After any refactoring task claims completion
    - When code is generated/scaffolded and needs integration verification
  version: 1.0.0
---

# Delivery Verification Gate

## The Problem This Solves

Agents generate code that compiles and passes unit tests but doesn't actually deliver what was requested. The code exists in the repo but is never wired, never called, never reachable at runtime. This applies to **any kind of task** — not just infrastructure or observability, but features, API endpoints, business logic, integrations, refactors, everything.

**The pattern is always the same:** agent creates artifacts (structs, functions, handlers, middleware, config, migrations) that look complete in isolation, but are never connected to the application's execution path. The task appears done. It's not.

## The Core Principle

```
REQUESTED ≠ CREATED ≠ DELIVERED

- REQUESTED: What the task/requirement asks for
- CREATED: What files/structs/functions were written
- DELIVERED: What is actually functioning in the running application

Only DELIVERED counts. CREATED without DELIVERED is dead code.
This applies to EVERY task type, not just infrastructure.
```

## The Verification Process

### Step 1: Extract Requirements from the Original Task

Parse the original task (as given to Gate 0) into discrete, verifiable requirements. **Every requirement the task asks for must become a line item.** Don't filter by type — if it was requested, it must be verified.

**Examples across different task types:**

#### Feature task: "Add tenant suspension with email notification"
```
R1: Suspend endpoint accepts tenant ID and reason
R2: Tenant status changes to 'suspended' in database
R3: All active connections for tenant are closed
R4: Email notification sent to tenant admin
R5: Subsequent API calls from suspended tenant return 403
R6: Suspension is logged with audit trail
```

#### Refactor task: "Migrate authentication from custom JWT to lib-auth middleware"
```
R1: lib-auth middleware replaces custom JWT validation
R2: All protected routes use new middleware
R3: Custom JWT code removed (no dead code left)
R4: Token format backward compatible (existing tokens still work)
R5: Authorization checks use lib-auth's Authorize() method
R6: M2M flow uses lib-auth's GetApplicationToken()
```

#### Fix task: "Fix race condition in connection pool during tenant eviction"
```
R1: Mutex protects concurrent access to connections map
R2: Eviction checks connection state before closing
R3: In-flight requests complete before connection is removed
R4: Test reproduces the race condition (fails without fix)
R5: Test passes with the fix applied
```

#### Infrastructure task: "Add Redis caching to tenant config lookups"
```
R1: Cache interface defined with Get/Set/Invalidate
R2: In-memory implementation as default (zero config)
R3: Redis implementation as opt-in
R4: Client uses cache before HTTP fallback
R5: Cache TTL is configurable
R6: Cache invalidation on config change
R7: Cache metrics (hit/miss) recorded
```

**Key insight:** Every task has "code exists" requirements AND "code is integrated" requirements. Agents consistently complete the first and skip the second. This gate catches that gap.

### Step 2: Verify Each Requirement is DELIVERED (not just CREATED)

For each requirement, answer THREE questions:

1. **Does the code exist?** (file, struct, function, migration, config)
2. **Is it connected?** (called, imported, registered, wired, injected)
3. **Is it reachable at runtime?** (trace path from main() or entry point)

```
Example verification:

R1: "Suspend endpoint accepts tenant ID and reason"
  1. Code exists? → handler.go:SuspendTenant() ✅
  2. Connected? → RegisterRoutes() includes DELETE /tenants/:id/suspend? 
     → grep -rn "Suspend" internal/bootstrap/wire*.go internal/adapters/http/
     → Found in RegisterRoutes() ✅
  3. Reachable? → main→InitServers→initHTTPServer→RegisterRoutes→SuspendTenant ✅
  → Status: ✅ DELIVERED

R4: "Email notification sent to tenant admin"
  1. Code exists? → notifier.go:SendSuspensionEmail() ✅
  2. Connected? → Called from SuspendTenant handler?
     → grep -rn "SendSuspensionEmail" internal/ --include="*.go" | grep -v test
     → 0 matches outside tests ❌
  3. Reachable? → N/A (not connected)
  → Status: ❌ CREATED NOT DELIVERED — function exists but never called
```

### Step 3: Integration Verification Checklist

For **every new artifact** created by Gate 0, verify integration based on its type:

#### Structs & Types
```
For each new struct:
  [ ] Is it instantiated somewhere? (grep for NewXxx or &Xxx{})
  [ ] Is the instance stored/used? (not just _ = NewXxx())
  [ ] Is it reachable from main() → bootstrap → wire → handler chain?
```

#### Functions & Methods
```
For each new exported function:
  [ ] Is it called from at least one non-test file?
  [ ] Is the caller itself reachable from main()?
  [ ] If it's a method: is the receiver struct instantiated and used?
```

#### API Endpoints & Routes
```
For each new endpoint:
  [ ] Is the handler function registered in the router?
  [ ] Is the route path correct and matches the spec?
  [ ] Are required middleware applied (auth, validation, telemetry)?
  [ ] Does a request to this endpoint reach the handler? (trace route registration)
```

#### Middleware
```
For each new middleware:
  [ ] Is it registered in the router/fiber middleware chain?
  [ ] Is it registered in the correct ORDER? (e.g., telemetry before auth)
  [ ] Are its dependencies injected? (not nil at runtime)
```

#### Database Changes
```
For each new migration/schema change:
  [ ] Is the migration file created with up AND down?
  [ ] Is the new column/table used by at least one repository method?
  [ ] Is the repository method called by a service?
  [ ] Is the service called by a handler or consumer?
```

#### Interfaces & Implementations
```
For each new interface implementation:
  [ ] Is the concrete type registered/injected via DI/wire?
  [ ] Is the interface actually used at a call site?
  [ ] Is the call site reachable from main()?
```

#### Config & Environment Variables
```
For each new config field:
  [ ] Is it read from environment? (env tag or os.Getenv)
  [ ] Is it passed to the component that uses it?
  [ ] Does the component's behavior change based on the value?
```

#### Event Publishers & Consumers
```
For each new event:
  [ ] Is the publisher called at the right business moment?
  [ ] Is the consumer registered and listening?
  [ ] Is the event schema consistent between publisher and consumer?
```

#### Dependencies (go.mod / package.json)
```
For each new dependency added:
  [ ] Is it imported in at least one non-test file?
  [ ] Is the import used (not just side-effect import)?
```

### Step 3.5: Automated Standards Checks (MANDATORY)

**These checks run on ALL files created/modified by Gate 0. Any failure = PARTIAL verdict.**

#### A. File Size Verification
See [shared-patterns/file-size-enforcement.md](../shared-patterns/file-size-enforcement.md)

**Go** (matches shared-patterns/file-size-enforcement.md):
```bash
find . -name "*.go" \
  ! -name "*_test.go" \
  ! -path "*/docs/*" \
  ! -path "*/mocks*" ! -path "*/generated/*" ! -path "*/gen/*" \
  ! -name "*.pb.go" ! -name "*.gen.go" \
  -exec wc -l {} + | awk '$1 > 300 && $NF != "total" {print}' | sort -rn

# Also check test files separately (same threshold)
find . -name "*_test.go" \
  ! -path "*/mocks*" \
  -exec wc -l {} + | awk '$1 > 300 && $NF != "total" {print}' | sort -rn
```

**TypeScript** (matches shared-patterns/file-size-enforcement.md):
```bash
find . \( -name "*.ts" -o -name "*.tsx" \) \
  ! -path "*/node_modules/*" ! -path "*/dist/*" ! -path "*/build/*" \
  ! -path "*/out/*" ! -path "*/.next/*" \
  ! -path "*/generated/*" ! -path "*/__generated__/*" \
  ! -path "*/__mocks__/*" ! -path "*/mocks/*" \
  ! -name "*.d.ts" ! -name "*.gen.ts" ! -name "*.generated.ts" ! -name "*.mock.ts" \
  -exec wc -l {} + | awk '$1 > 300 && $NF != "total" {print}' | sort -rn
```

- Any modified file > 500 lines → **FAIL** (hard block, return to Gate 0 with split instructions)
- Any modified file > 300 lines → **PARTIAL** (return to Gate 0 with split instructions)
- **This check applies to ALL files in the project, not just files changed by Gate 0.** Existing oversized files are flagged but do not block unless they were modified by Gate 0.

#### B. License Header Verification
**Reference:** core.md → License Headers (MANDATORY)

```bash
# Check all files created/modified by Gate 0 for license headers
# Patterns checked: Copyright, Licensed, SPDX, License (covers Apache, MIT, etc.)
for f in $files_changed; do
  if echo "$f" | grep -qE '\.(go|ts|tsx)$'; then
    if ! head -10 "$f" | grep -qiE 'copyright|licensed|spdx|license'; then
      echo "MISSING LICENSE HEADER: $f"
    fi
  fi
done
```

**Note:** Checks first 10 lines (not 5) to account for build tags, package declarations, or shebang lines that may precede the license block. The pattern is intentionally broad (`copyright|licensed|spdx|license`) to match common formats (Apache, MIT, BSD, SPDX identifiers).

- Any source file missing license header → **PARTIAL** (return to Gate 0: "Add license header per core.md")

#### C. Linting Verification
**Reference:** quality.md → Linting (MANDATORY — 14 linters)

```bash
# Go: Run golangci-lint
if [ -f .golangci.yml ] || [ -f .golangci.yaml ]; then
  golangci-lint run ./...
else
  echo "WARNING: Missing .golangci.yml — quality.md requires it (14 mandatory linters)"
  echo "FLAG: PARTIAL — create .golangci.yml per quality.md → Linting (MANDATORY)"
fi

# TypeScript: Run eslint
if [ -f .eslintrc.js ] || [ -f .eslintrc.json ] || [ -f eslint.config.js ] || [ -f .eslintrc.yaml ] || [ -f .eslintrc.yml ]; then
  npx eslint . --ext .ts,.tsx
else
  echo "WARNING: Missing eslint config — typescript.md requires linting"
  echo "FLAG: PARTIAL — create eslint config per typescript.md standards"
fi
```

- Lint failures → **PARTIAL** (return to Gate 0: "Fix lint issues: [errors]")
- Missing linter config in Go project → **PARTIAL** (quality.md requires .golangci.yml with 14 mandatory linters)
- Missing linter config in TypeScript project → **PARTIAL** (typescript.md requires eslint)

#### D. Migration Safety Verification
**Reference:** [migration-safety.md](../../docs/standards/golang/migration-safety.md) — Dangerous Operations Detection

This check only runs when the current branch contains new or modified SQL migration files.

```bash
# Step D.1: Detect migration files in this branch
# Only match files in migrations/ directories (not arbitrary .sql files like test fixtures)
base_branch=$(git rev-parse --abbrev-ref HEAD@{upstream} 2>/dev/null | sed 's|origin/||' || echo "main")
migration_files=$(git diff --name-only "origin/$base_branch" -- '**/migrations/*.sql' 2>/dev/null | grep -v "_test")

if [ -z "$migration_files" ]; then
  echo "NO_MIGRATIONS — Step 3.5D skipped"
else
  echo "Migration files found: $migration_files"
  blocking=0

  # Step D.2: Check for blocking operations
  for f in $migration_files; do
    # ADD COLUMN ... NOT NULL without DEFAULT (unsafe — table rewrite + lock)
    # Allows: ADD COLUMN ... NOT NULL DEFAULT, ALTER COLUMN SET NOT NULL (constraint-only, safe after backfill)
    if grep -Pin "ADD\s+COLUMN\b.*\bNOT\s+NULL\b" "$f" | grep -Piv "DEFAULT|SET\s+NOT\s+NULL"; then
      echo "⛔ BLOCKING: $f — ADD COLUMN NOT NULL without DEFAULT (table rewrite + lock)"
      blocking=1
    fi
    # DROP COLUMN
    if grep -Pin "DROP\s+COLUMN" "$f"; then
      echo "⛔ BLOCKING: $f — DROP COLUMN (use expand-contract: deprecate first, drop in next release)"
      blocking=1
    fi
    # DROP TABLE without safety
    if grep -Pin "DROP\s+TABLE" "$f" | grep -Piv "IF EXISTS.*deprecated"; then
      echo "⛔ BLOCKING: $f — DROP TABLE (rename to _deprecated first)"
      blocking=1
    fi
    # TRUNCATE
    if grep -Pin "TRUNCATE" "$f"; then
      echo "⛔ BLOCKING: $f — TRUNCATE TABLE (never in production migrations)"
      blocking=1
    fi
    # CREATE INDEX without CONCURRENTLY
    if grep -Pin "CREATE\s+(UNIQUE\s+)?INDEX\b" "$f" | grep -Piv "CONCURRENTLY"; then
      echo "⛔ BLOCKING: $f — CREATE INDEX without CONCURRENTLY (locks writes)"
      blocking=1
    fi
    # ALTER COLUMN TYPE
    if grep -Pin "ALTER\s+COLUMN.*TYPE\b" "$f"; then
      echo "⛔ BLOCKING: $f — ALTER COLUMN TYPE (table rewrite, use add-new-column pattern)"
      blocking=1
    fi
  done

  # Step D.3: Check DOWN migration exists
  for f in $migration_files; do
    base=$(basename "$f")
    dir=$(dirname "$f")
    if echo "$base" | grep -q "\.up\.sql$"; then
      down_file="${base/.up.sql/.down.sql}"
      if [ ! -f "$dir/$down_file" ]; then
        echo "⛔ BLOCKING: $f — Missing DOWN migration ($down_file)"
        blocking=1
      elif [ ! -s "$dir/$down_file" ]; then
        echo "⛔ BLOCKING: $f — DOWN migration is empty ($down_file)"
        blocking=1
      fi
    fi
  done

  # Step D.4: Check idempotency (multi-tenant safety)
  for f in $migration_files; do
    if grep -Pin "CREATE\s+(TABLE|INDEX)" "$f" | grep -Piv "IF NOT EXISTS|CONCURRENTLY"; then
      echo "⚠️ WARNING: $f — DDL without IF NOT EXISTS (not idempotent for multi-tenant re-runs)"
    fi
  done

  if [ "$blocking" -eq 1 ]; then
    echo "MIGRATION_SAFETY: ⛔ FAIL — return to Gate 0 with migration-safety.md"
  else
    echo "MIGRATION_SAFETY: ✅ PASS"
  fi
fi
```

- Any blocking operation → **FAIL** (hard block, return to Gate 0 with `migration-safety.md` reference)
- Missing/empty DOWN migration → **FAIL**
- Non-idempotent DDL → **WARNING** (flags but does not block)
- No migration files in branch → **SKIP** (check does not apply)

#### E. Dependency Vulnerability Scanning
**Reference:** [core.md § Dependency Management](../../docs/standards/golang/core.md)

This check runs on every cycle to detect known vulnerabilities in dependencies.

```bash
# Step E.1: Detect project language
if [ -f "go.mod" ]; then
  lang="go"
elif [ -f "package.json" ]; then
  lang="typescript"
else
  echo "VULN_SCAN: ⚠️ SKIP — no go.mod or package.json found"
  lang="unknown"
fi

# Step E.2: Run vulnerability scanner
if [ "$lang" = "go" ]; then
  # govulncheck scans for known CVEs in Go dependencies
  if command -v govulncheck &>/dev/null; then
    vuln_output=$(govulncheck ./... 2>&1)
    vuln_exit=$?
    if [ $vuln_exit -ne 0 ]; then
      echo "$vuln_output"
      # Parse severity — govulncheck reports all as actionable
      echo "VULN_SCAN: ⛔ FAIL — govulncheck found vulnerabilities"
    else
      echo "VULN_SCAN: ✅ PASS — no known vulnerabilities"
    fi
  else
    echo "VULN_SCAN: ⚠️ WARNING — govulncheck not installed (go install golang.org/x/vuln/cmd/govulncheck@latest)"
  fi

  # Also verify module integrity
  go_verify=$(go mod verify 2>&1)
  if [ $? -ne 0 ]; then
    echo "⛔ BLOCKING: go mod verify failed — module integrity compromised"
    echo "$go_verify"
  fi

elif [ "$lang" = "typescript" ]; then
  # npm audit for Node.js projects
  if [ -f "package-lock.json" ]; then
    audit_output=$(npm audit --audit-level=high 2>&1)
    audit_exit=$?
    if [ $audit_exit -ne 0 ]; then
      echo "$audit_output"
      echo "VULN_SCAN: ⛔ FAIL — npm audit found high/critical vulnerabilities"
    else
      echo "VULN_SCAN: ✅ PASS — no high/critical vulnerabilities"
    fi
  elif [ -f "yarn.lock" ]; then
    audit_output=$(yarn audit --level high 2>&1)
    audit_exit=$?
    if [ $audit_exit -ne 0 ]; then
      echo "$audit_output"
      echo "VULN_SCAN: ⛔ FAIL — yarn audit found high/critical vulnerabilities"
    else
      echo "VULN_SCAN: ✅ PASS"
    fi
  fi
fi
```

- Go: `govulncheck` finds vulnerability → **FAIL** (return to Gate 0: "Update vulnerable dependency or find alternative")
- Go: `go mod verify` fails → **FAIL** (module tampered)
- TypeScript: `npm audit --audit-level=high` finds high/critical → **FAIL**
- Scanner not installed → **WARNING** (does not block, but flags for team to install)

#### F. API Backward Compatibility (oasdiff + swaggo)
**Reference:** [api-patterns.md § OpenAPI Documentation](../../docs/standards/golang/api-patterns.md#openapi-documentation-swaggo-mandatory)

This check only applies to services that have swaggo-generated OpenAPI specs (api/swagger.yaml or api/swagger.json).

```bash
# Step F.1: Check if this is an API service with OpenAPI spec
spec_file=""
if [ -f "api/swagger.yaml" ]; then
  spec_file="api/swagger.yaml"
elif [ -f "api/swagger.json" ]; then
  spec_file="api/swagger.json"
fi

if [ -z "$spec_file" ]; then
  echo "API_COMPAT: ⚠️ SKIP — no OpenAPI spec found (not an API service or swaggo not configured)"
else
  # Step F.2: Regenerate spec from current annotations
  if command -v swag &>/dev/null; then
    swag init -g cmd/api/main.go -o api/ --parseDependency --parseInternal 2>/dev/null
  fi

  # Step F.3: Get the spec from main branch for comparison
  main_spec=$(git show origin/main:$spec_file 2>/dev/null)

  if [ -z "$main_spec" ]; then
    echo "API_COMPAT: ⚠️ SKIP — no spec on main branch (new service, nothing to compare)"
  else
    # Step F.4: Run oasdiff breaking change detection
    if command -v oasdiff &>/dev/null; then
      # Write main spec to temp file for comparison
      tmp_main=$(mktemp)
      echo "$main_spec" > "$tmp_main"

      breaking_output=$(oasdiff breaking "$tmp_main" "$spec_file" 2>&1)
      breaking_exit=$?
      rm -f "$tmp_main"

      if [ $breaking_exit -ne 0 ] || [ -n "$breaking_output" ]; then
        echo "$breaking_output"
        echo ""
        echo "API_COMPAT: ⛔ FAIL — breaking changes detected in API spec"
        echo "Review each change above. If intentional (new API version), document in PR description."
      else
        echo "API_COMPAT: ✅ PASS — no breaking changes in API spec"
      fi
    else
      echo "API_COMPAT: ⚠️ WARNING — oasdiff not installed (go install github.com/tufin/oasdiff@latest)"
    fi
  fi
fi
```

- Breaking change detected → **FAIL** (return to Gate 0: "Breaking API change — use additive-only changes or document version bump")
- No spec file → **SKIP** (not an API service)
- No spec on main → **SKIP** (new service, no baseline)
- oasdiff not installed → **WARNING** (does not block, flags for installation)
- Non-breaking changes (new endpoints, new optional fields) → **PASS**

#### G. Multi-Tenant Dual-Mode Verification (Go backend only)
**Reference:** [multi-tenant.md](../../docs/standards/golang/multi-tenant.md), [dev-multi-tenant SKILL.md § Sub-Package Import Reference](../dev-multi-tenant/SKILL.md)

This check only applies to Go backend services. It verifies that all resource access uses lib-commons v4 resolvers (which work transparently in both single-tenant and multi-tenant mode).

```bash
# Step G.1: Detect if this is a Go project
if [ ! -f "go.mod" ]; then
  echo "MT_DUALMODE: ⚠️ SKIP — not a Go project"
  exit 0
fi

blocking=0

# Step G.2: Check PostgreSQL — must use resolvers, not direct GetDB()
pg_direct=$(grep -rn "\.GetDB()" internal/ pkg/ --include="*.go" 2>/dev/null \
  | grep -v "_test.go" \
  | grep -v "// deprecated\|// legacy\|// TODO" \
  | grep -v "core\.Resolve\|tmpostgres\|Manager")
if [ -n "$pg_direct" ]; then
  echo "⛔ BLOCKING: Direct .GetDB() calls found — must use tmcore.GetPGContext(ctx, module) or tmcore.GetPGContext(ctx)"
  echo "$pg_direct"
  blocking=1
fi

# Step G.3: Check MongoDB — must use resolvers
mongo_direct=$(grep -rn "\.GetDatabase()\|\.Database()" internal/ pkg/ --include="*.go" 2>/dev/null \
  | grep -v "_test.go" \
  | grep -v "core\.Resolve\|tmmongo\|Manager")
if [ -n "$mongo_direct" ]; then
  echo "⛔ BLOCKING: Direct MongoDB access found — must use tmcore.GetMBContext(ctx, module) or tmcore.GetMBContext(ctx)"
  echo "$mongo_direct"
  blocking=1
fi

# Step G.4: Check Redis/Valkey — keys must use GetKeyContext
redis_hardcoded=$(grep -rn '\.Set\(\s*"[^"]*"\s*,' internal/ pkg/ --include="*.go" 2>/dev/null \
  | grep -v "_test.go" \
  | grep -v "GetKeyContext\|valkey\.")
redis_hardcoded2=$(grep -rn '\.Get\(\s*"[^"]*"\s*[,)]' internal/ pkg/ --include="*.go" 2>/dev/null \
  | grep -v "_test.go" \
  | grep -v "GetKeyContext\|valkey\.\|Getenv\|flag\.")
if [ -n "$redis_hardcoded" ] || [ -n "$redis_hardcoded2" ]; then
  echo "⚠️ WARNING: Possible hardcoded Redis keys — verify valkey.GetKeyContext is used"
  echo "$redis_hardcoded"
  echo "$redis_hardcoded2"
fi

# Step G.5: Check S3 — keys must use GetS3KeyStorageContext
s3_hardcoded=$(grep -rn 'PutObject\|GetObject\|DeleteObject' internal/ pkg/ --include="*.go" 2>/dev/null \
  | grep -v "_test.go" \
  | grep -v "GetS3KeyStorageContext\|s3\.")
if [ -n "$s3_hardcoded" ]; then
  echo "⚠️ WARNING: Possible hardcoded S3 keys — verify s3.GetS3KeyStorageContext is used"
  echo "$s3_hardcoded"
fi

# Step G.6: Check RabbitMQ — must use tmrabbitmq.Manager
if grep -rq "rabbitmq\|amqp" go.mod 2>/dev/null; then
  rmq_direct=$(grep -rn "amqp\.Dial\|channel\.Publish\|channel\.Consume" internal/ pkg/ --include="*.go" 2>/dev/null \
    | grep -v "_test.go" \
    | grep -v "tmrabbitmq\|Manager")
  if [ -n "$rmq_direct" ]; then
    echo "⛔ BLOCKING: Direct RabbitMQ access found — must use tmrabbitmq.Manager"
    echo "$rmq_direct"
    blocking=1
  fi
fi

# Step G.7: Check route registration — tenant middleware must use WhenEnabled
if grep -rq "TenantMiddleware\|WithPG\|WithMB" internal/ pkg/ --include="*.go" 2>/dev/null; then
  global_use=$(grep -rn "app\.Use.*[Tt]enant\|app\.Use.*[Mm]ulti[Pp]ool" internal/ pkg/ --include="*.go" 2>/dev/null \
    | grep -v "_test.go")
  if [ -n "$global_use" ]; then
    echo "⛔ BLOCKING: Tenant middleware registered globally (app.Use) — must use per-route WhenEnabled()"
    echo "$global_use"
    blocking=1
  fi
fi

# Step G.8: Check context propagation — all exported methods must accept ctx
no_ctx=$(grep -rn "^func (r \*.*) [A-Z].*(" internal/adapters/ pkg/ --include="*.go" 2>/dev/null \
  | grep -v "_test.go" \
  | grep -v "ctx context\.Context\|Close()\|String()\|Error()")
if [ -n "$no_ctx" ]; then
  echo "⚠️ WARNING: Exported methods without ctx parameter found — needed for MT resolution"
  echo "$no_ctx" | head -10
fi

# Step G.9: Check global DB singletons
global_db=$(grep -rn "^var.*sql\.DB\|^var.*pgx\.Pool\|^var.*mongo\.Client\|^var.*redis\.Client" internal/ pkg/ --include="*.go" 2>/dev/null \
  | grep -v "_test.go")
if [ -n "$global_db" ]; then
  echo "⛔ BLOCKING: Global database singletons found — must use struct fields with constructor injection"
  echo "$global_db"
  blocking=1
fi

if [ "$blocking" -eq 1 ]; then
  echo "MT_DUALMODE: ⛔ FAIL — return to Gate 0 with multi-tenant.md"
else
  echo "MT_DUALMODE: ✅ PASS — all resources use dual-mode resolvers"
fi
```

- Direct `.GetDB()` or `.GetDatabase()` calls → **FAIL** (must use resolvers)
- Direct RabbitMQ channel operations → **FAIL** (must use tmrabbitmq.Manager)
- Global tenant middleware (app.Use) → **FAIL** (must use per-route WhenEnabled)
- Global DB singletons → **FAIL** (must use struct fields)
- Hardcoded Redis/S3 keys → **WARNING** (may be false positive, verify manually)
- Missing ctx on exported methods → **WARNING** (informational)
- Not a Go project → **SKIP**

**Verdict integration:** ALL seven checks (A, B, C, D, E, F, G) must pass for overall PASS. Any FAIL in checks D, E, F, or G → overall verdict is **FAIL** (hard block, return to Gate 0). Any FAIL in checks A, B, C → overall verdict is **PARTIAL** (return to Gate 0 with fix instructions, max 2 retries). SKIP checks do not affect the verdict. WARNING checks are informational.

### Step 4: Dead Code Detection

Identify any code created by Gate 0 that is not reachable:

#### Go
```bash
# Use files_changed from Gate 0 handoff (NOT git diff — avoids drift on stacked/squashed commits)
# files_changed is provided as input to this gate
if [ -z "$files_changed" ]; then
  echo "ERROR: files_changed not provided. Cannot verify delivery."
  exit 1
fi
changed_files=$(echo "$files_changed" | tr ',' '\n' | grep "\.go$" | grep -v "_test.go")
for f in $changed_files; do
  # Extract exported function/method names
  grep -oP 'func (\(.*?\) )?(\K[A-Z]\w+)' "$f" | while read func_name; do
    # Count non-test references across the repo
    refs=$(grep -rn "$func_name" --include="*.go" . | grep -v "_test.go" | grep -v "^$f:" | wc -l)
    if [ "$refs" -eq 0 ]; then
      echo "DEAD: $func_name in $f (defined but never referenced outside tests)"
    fi
  done
done
```

```bash
# For each changed file, check if its package is imported by bootstrap/wire/main
for f in $changed_files; do
  pkg_path=$(dirname "$f")
  importers=$(grep -rn "\".*$pkg_path\"" internal/bootstrap/ cmd/ --include="*.go" | grep -v "_test.go")
  if [ -z "$importers" ]; then
    echo "WARNING: Package $pkg_path not imported by bootstrap/cmd — code may be unreachable"
  fi
done
```

#### TypeScript
```bash
# Use files_changed from Gate 0 handoff
changed_ts_files=$(echo "$files_changed" | tr ',' '\n' | grep "\.ts$" | grep -v "\.test\.\|\.spec\.")
for f in $changed_ts_files; do
  grep -oP 'export (function|class|const|interface) \K\w+' "$f" | while read name; do
    refs=$(grep -rn "import.*$name\|require.*$name" --include="*.ts" src/ | grep -v "$f" | wc -l)
    if [ "$refs" -eq 0 ]; then
      echo "DEAD: $name in $f (exported but never imported)"
    fi
  done
done
```

### Step 5: Requirement Coverage Matrix

Build and output the full matrix — one row per requirement extracted in Step 1:

```markdown
## Requirement Coverage Matrix

| # | Requirement | Created | Connected | Reachable | Status |
|---|-------------|---------|-----------|-----------|--------|
| R1 | [requirement text] | ✅ file:line | ✅ called by X | ✅ main→...→here | ✅ DELIVERED |
| R2 | [requirement text] | ✅ file:line | ❌ never called | ❌ dead code | ❌ NOT DELIVERED |
| R3 | [requirement text] | ❌ not found | — | — | ❌ NOT CREATED |
```

**Every requirement from Step 1 MUST appear in this matrix.** No filtering, no "this one is obvious." If it was requested, it gets a row.

### Step 6: Verdict

```
PASS: ALL requirements have status DELIVERED
      AND dead code count = 0
      AND all integration checks pass
      AND no modified file exceeds 300 lines (file-size-enforcement.md)
      AND all modified source files have license headers (core.md)
      AND linting passes (quality.md)

PARTIAL: Some requirements DELIVERED, some NOT DELIVERED
         → List specific gaps with fix instructions
         → Agent MUST fix before advancing to Gate 1

FAIL: Critical requirements NOT DELIVERED
      OR majority of requirements NOT DELIVERED
      OR significant dead code introduced
      → Return to Gate 0 with explicit instructions
```

**Verdict is based on the original task requirements, not on code quality.** Quality is Gate 8's job. This gate only answers: "Was the requested work actually delivered?"

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "The struct is there, wiring is a separate task" | Unwired struct = dead code. Each task must deliver complete functionality. | **Wire it NOW or mark task as incomplete** |
| "Tests prove it works" | Tests on isolated code prove it works in isolation. Not that it works in the app. | **Verify reachability from main()** |
| "It compiles, so it's integrated" | Compilation doesn't prove integration. Unused code compiles. | **Trace call path from main()** |
| "The next PR will wire it" | The next PR is not guaranteed. Deliver complete or don't deliver. | **Complete integration in this task** |
| "It's just scaffolding" | Scaffolding without integration is dead code with extra steps. | **Either wire it or don't create it** |
| "Review will catch it" | Review catches quality issues, not delivery completeness. Different concerns. | **Verify delivery explicitly** |
| "Go vet would catch unused code" | Go vet catches unused variables, not unused exported types/functions. | **Run integration verification** |
| "The feature works, just missing one small piece" | Partial delivery ≠ delivery. If R4 of 7 requirements is missing, task is incomplete. | **Deliver ALL requirements** |
| "That requirement was implied, not explicit" | If the task says it, verify it. Ambiguity → ask, don't skip. | **Verify or clarify with requester** |
| "I did the hard part, the wiring is trivial" | Trivial ≠ done. If it's trivial, do it now. | **Complete the trivial wiring** |

## Integration with dev-cycle

This gate runs as **Gate 0.5** — after implementation (Gate 0), before DevOps (Gate 1):

```
Gate 0:   Implementation (write code)
Gate 0.5: Delivery Verification (verify ALL requested work is delivered) ← THIS GATE
Gate 1:   DevOps (infrastructure)
Gate 2:   SRE (reliability)
Gate 3:   Unit Testing
...
```

If Gate 0.5 returns PARTIAL or FAIL:
1. List ALL undelivered requirements with specific evidence
2. Return to Gate 0 with explicit instructions: "Deliver the following: [list with file:line references]"
3. Re-run Gate 0.5 after fixes
4. Only advance to Gate 1 when Gate 0.5 returns PASS

**Gate 0.5 is language-agnostic and task-type-agnostic.** It works the same whether the task is a Go API endpoint, a TypeScript frontend component, a database migration, an infrastructure change, or a business logic refactor. The process is always: extract requirements → verify each is delivered → report gaps.
