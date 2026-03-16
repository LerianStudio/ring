---
name: dev-multi-tenant
description: |
  Multi-tenant development cycle orchestrator following Ring Standards.
  Auto-detects the service stack (PostgreSQL, MongoDB, Redis, RabbitMQ, S3)
  and service type (plugin vs product),
  then executes a gate-based implementation using tenantId from JWT
  for database-per-tenant isolation via lib-commons v3 dispatch layer sub-packages (postgres.Manager, mongo.Manager).
  For plugins: includes mandatory M2M credential retrieval from AWS Secrets Manager
  via lib-commons v3 secretsmanager package (per-tenant authentication with product APIs).
  MUST update lib-commons v3 first; lib-auth v2 depends on it. Both are required dependencies.
  Each gate dispatches ring:backend-engineer-golang with context and section references.
  The agent loads multi-tenant.md via WebFetch and has all code examples.
metadata:
  NOT_skip_when: |
    - "organization_id already exists" → organization_id is NOT multi-tenant. tenantId via JWT is required.
    - "Just need to connect the wiring" → Multi-tenant requires lib-commons v3 dispatch layer sub-packages.
    - "lib-commons v3 upgrade is too risky" → REQUIRES lib-commons v3 dispatch layer sub-packages. No v3 = no multi-tenant.
    - "Service already has multi-tenant" → Existence ≠ compliance. MUST replace non-standard implementations with Ring canonical model.
    - "Multi-tenant is already done" → Every gate verifies compliance. MUST fix non-compliant code — it is wrong, not done.
  examples:
  - name: Add multi-tenant to a service
    invocation: /ring:dev-multi-tenant
    expected_flow: |-
      1. Gate 0: Auto-detect stack + service type (plugin vs product)
      2. Gate 1: Analyze codebase (build implementation roadmap)
      3. Gate 1.5: Visual implementation preview (HTML report for developer approval)
      4. Gates 2-5: Implementation (agent loads multi-tenant.md, follows roadmap)
      5. Gate 5.5: M2M Secret Manager for plugin auth (if plugin)
      6. Gate 6: RabbitMQ multi-tenant (if RabbitMQ detected)
      7. Gate 7: Metrics & Backward compatibility
      8. Gate 8: Tests
      9. Gate 9: Code review
      10. Gate 10: User validation
      11. Gate 11: Activation guide
  input_schema:
    description: |
      When invoked from ring:dev-cycle (post-cycle step), receives structured handoff context.
      When invoked standalone (direct user request), these fields are auto-detected in Gate 0.
    fields:
    - name: execution_mode
      type: string
      enum:
      - FULL
      - SCOPED
      description: FULL = complete 12-gate cycle. SCOPED = only adapt new files (when existing MT is compliant).
      required: false
      default: FULL
    - name: files_changed
      type: array
      items: string
      description: File paths changed during dev-cycle (only in SCOPED mode). Used to limit Gate 5 scope.
      required: false
    - name: multi_tenant_exists
      type: boolean
      description: Whether multi-tenant code was detected by dev-cycle Step 1.5.
      required: false
    - name: multi_tenant_compliant
      type: boolean
      description: Whether existing MT code passed compliance audit in dev-cycle Step 1.5.
      required: false
    - name: detected_dependencies
      type: object
      properties:
        postgresql: boolean
        mongodb: boolean
        redis: boolean
        rabbitmq: boolean
        s3: boolean
      description: Stack detection from dev-cycle. Each key indicates whether that technology was detected.
      required: false
    - name: skip_gates
      type: array
      items: string
      description: Gate identifiers to skip (e.g., '0', '1.5', '5.5'). Set by dev-cycle based on execution_mode.
      required: false
  output_schema:
    format: markdown
    required_sections:
    - name: Multi-Tenant Cycle Summary
      pattern: ^## Multi-Tenant Cycle Summary
      required: true
    - name: Stack Detection
      pattern: ^## Stack Detection
      required: true
    - name: Gate Results
      pattern: ^## Gate Results
      required: true
    - name: Verification
      pattern: ^## Verification
      required: true
    metrics:
    - name: gates_passed
      type: integer
    - name: gates_failed
      type: integer
    - name: total_files_changed
      type: integer
  prerequisite: |
    - Go service with existing single-tenant functionality
  related:
    complementary:
    - ring:dev-cycle
    - ring:dev-implementation
    - ring:dev-devops
    - ring:dev-unit-testing
    - ring:requesting-code-review
    - ring:dev-validation
  sequence:
    after:
    - ring:dev-devops
  slug: dev-multi-tenant
  trigger: |
    - User requests multi-tenant implementation for a Go service
    - User asks to add tenant isolation to an existing service
    - Task mentions "multi-tenant", "tenant isolation", "dispatch layer", "postgres.Manager", "MultiPoolMiddleware"
  type: skill
  version: 2.0.0
---

# Multi-Tenant Development Cycle

<cannot_skip>

## CRITICAL: This Skill ORCHESTRATES. Agents IMPLEMENT.

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Detect stack, determine gates, pass context to agent, verify outputs, enforce order |
| **ring:backend-engineer-golang** | Load multi-tenant.md via WebFetch, implement following the standards |
| **7 reviewers** | Review at Gate 9 |

**CANNOT change scope:** the skill defines WHAT to implement. The agent implements HOW.

**FORBIDDEN: Orchestrator MUST NOT use Edit, Write, or Bash tools to modify source code files.**
All code changes MUST go through `Task(subagent_type="ring:backend-engineer-golang")`.
The orchestrator only verifies outputs (grep, go build, go test) — MUST NOT write implementation code.

**MANDATORY: TDD for all implementation gates (Gates 2-6).** MUST follow RED → GREEN → REFACTOR: write a failing test first, then implement to make it pass, then refactor for clarity/performance. MUST include in every dispatch: "Follow TDD: write failing test (RED), implement to make it pass (GREEN), then refactor for clarity/performance (REFACTOR)."

</cannot_skip>

---

## Multi-Tenant Architecture

Multi-tenant isolation is 100% based on `tenantId` from JWT → dispatch layer middleware → database-per-tenant. Connection managers (`postgres.Manager`, `mongo.Manager`, `rabbitmq.Manager`) resolve tenant-specific credentials via the Tenant Manager API. `organization_id` is NOT part of multi-tenant.

**Standards reference:** All code examples and implementation patterns are in [multi-tenant.md](../../docs/standards/golang/multi-tenant.md). MUST load via WebFetch before implementing any gate.

**WebFetch URL:** `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/multi-tenant.md`

### MANDATORY: Canonical Environment Variables

See [multi-tenant.md § Environment Variables](../../docs/standards/golang/multi-tenant.md#environment-variables) for the complete table of 8 canonical `MULTI_TENANT_*` env vars with descriptions, defaults, and required status.

MUST NOT use any other names (e.g., `TENANT_MANAGER_ADDRESS` is WRONG — the correct name is `MULTI_TENANT_URL`).

HARD GATE: Any env var outside that table is non-compliant. Agent MUST NOT invent or accept alternative names.

### MANDATORY: Canonical Metrics

See [multi-tenant.md § Multi-Tenant Metrics](../../docs/standards/golang/multi-tenant.md#multi-tenant-metrics) for the 4 required metrics. All 4 are MANDATORY.

When `MULTI_TENANT_ENABLED=false`, metrics MUST use no-op implementations (zero overhead in single-tenant mode).

### MANDATORY: Circuit Breaker

See [multi-tenant.md § Environment Variables](../../docs/standards/golang/multi-tenant.md#environment-variables) for circuit breaker env vars (`MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD`, `MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC`).

The Tenant Manager HTTP client MUST enable `WithCircuitBreaker`. MUST NOT create the client without it.

HARD GATE: A client without circuit breaker can cascade failures across all tenants.

### MANDATORY: Service API Key

See [multi-tenant.md § Service Authentication](../../docs/standards/golang/multi-tenant.md#service-authentication-mandatory) for the authentication flow.

The Tenant Manager HTTP client MUST be configured with `client.WithServiceAPIKey(cfg.MultiTenantServiceAPIKey)`. Without this, the Tenant Manager rejects requests to the `/settings` endpoint with `401 Unauthorized`.

HARD GATE: A client without `WithServiceAPIKey` cannot resolve tenant connections.

### MANDATORY: Sub-Package Import Reference

Agents must use these exact import paths. Include this table in every gate dispatch to prevent hallucinated or outdated imports.

| Alias | Import Path | Purpose |
|-------|-------------|---------|
| `client` | `github.com/LerianStudio/lib-commons/v3/commons/dispatch layer/client` | Tenant Manager HTTP client with circuit breaker |
| `core` | `github.com/LerianStudio/lib-commons/v3/commons/dispatch layer/core` | Context helpers, resolvers, errors, types |
| `tmmiddleware` | `github.com/LerianStudio/lib-commons/v3/commons/dispatch layer/middleware` | TenantMiddleware, MultiPoolMiddleware, ConsumerTrigger |
| `tmpostgres` | `github.com/LerianStudio/lib-commons/v3/commons/dispatch layer/postgres` | PostgresManager (per-tenant PG pools) |
| `tmmongo` | `github.com/LerianStudio/lib-commons/v3/commons/dispatch layer/mongo` | MongoManager (per-tenant Mongo pools) |
| `tmrabbitmq` | `github.com/LerianStudio/lib-commons/v3/commons/dispatch layer/rabbitmq` | RabbitMQ Manager (per-tenant vhosts) |
| `tmconsumer` | `github.com/LerianStudio/lib-commons/v3/commons/dispatch layer/consumer` | MultiTenantConsumer (lazy mode) |
| `valkey` | `github.com/LerianStudio/lib-commons/v3/commons/dispatch layer/valkey` | Redis key prefixing (GetKeyFromContext) |
| `s3` | `github.com/LerianStudio/lib-commons/v3/commons/dispatch layer/s3` | S3 key prefixing (GetObjectStorageKeyForTenant) |
| `secretsmanager` | `github.com/LerianStudio/lib-commons/v3/commons/secretsmanager` | M2M credential retrieval (plugin only) |

**⛔ HARD GATE:** Agent must not use v2 import paths or invent sub-package paths. If WebFetch truncates, this table is the authoritative reference.

### MANDATORY: Isolation Modes

The Tenant Manager determines the isolation mode per tenant. Agents MUST handle both:

| Mode | Database | Schema | Connection String Modifier | When |
|------|----------|--------|---------------------------|------|
| `isolated` (default) | Separate DB per tenant | Default `public` | None | Strong isolation, recommended |
| `schema` | Shared DB | Schema per tenant | `options=-csearch_path="{schema}"` | Cost optimization |

The agent does not choose the mode — lib-commons `postgres.Manager` reads `TenantConfig.IsolationMode` from the Tenant Manager API and resolves the connection accordingly. The agent's responsibility is to use `core.ResolvePostgres`/`core.ResolveModuleDB` which handles both modes transparently.

### ConnectionSettings Override

Connection managers support per-tenant pool overrides via `TenantConfig.Databases[module].ConnectionSettings`:
- `MaxOpenConns` and `MaxIdleConns` per tenant
- When present, these override global defaults on `PostgresManager`/`MongoManager`
- When nil (older tenant associations), global defaults apply
- Managers call `ApplyConnectionSettings()` automatically after resolving a connection

Agents must not hardcode pool sizes — the Tenant Manager controls per-tenant pool tuning.

### MANDATORY: Agent Instruction (include in EVERY gate dispatch)

MUST include these instructions in every dispatch to `ring:backend-engineer-golang`:

> **STANDARDS: WebFetch `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/multi-tenant.md` and follow the sections referenced below. All code examples, patterns, and implementation details are in that document. Use them as-is.**
>
> **SUB-PACKAGES: Use the import table from the skill — see "Sub-Package Import Reference" above. Do NOT invent import paths.**
>
> **TDD: For implementation gates (2-6), follow TDD methodology — write a failing test first (RED), then implement to make it pass (GREEN). MUST have test coverage for every change.**

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Cross-tenant data leak, security vulnerability | Tenant A sees Tenant B data, missing tenant validation, hardcoded creds |
| **HIGH** | Missing tenant isolation, wrong env vars | No TenantMiddleware, TENANT_MANAGER_ADDRESS instead of MULTI_TENANT_URL |
| **MEDIUM** | Configuration gaps, partial implementation | Missing circuit breaker, incomplete metrics |
| **LOW** | Documentation, optimization | Missing env var comments, pool tuning |

MUST report all severities. CRITICAL: STOP immediately (security breach). HIGH: Fix before gate pass. MEDIUM: Fix in iteration. LOW: Document.

---

## Pressure Resistance

| User Says | This Is | Response |
|-----------|---------|----------|
| "It already has multi-tenant, skip this gate" | COMPLIANCE_BYPASS | "Existence ≠ compliance. MUST run compliance audit. If it doesn't match the Ring canonical model exactly, it is non-compliant and MUST be replaced." |
| "Multi-tenant is done, just review it" | COMPLIANCE_BYPASS | "CANNOT skip gates. Every gate verifies compliance OR implements. Non-standard implementations are not 'done' — they are wrong." |
| "Our custom approach works the same way" | COMPLIANCE_BYPASS | "Working ≠ compliant. Only lib-commons v3 dispatch layer sub-packages are valid. Custom implementations create drift and block upgrades." |
| "Skip the lib-commons upgrade" | QUALITY_BYPASS | "CANNOT proceed without lib-commons v3. Tenant-manager sub-packages do not exist in v2." |
| "Just do the happy path, skip backward compat" | SCOPE_REDUCTION | "Backward compatibility is NON-NEGOTIABLE. Single-tenant deployments depend on it." |
| "organization_id is our tenant identifier" | AUTHORITY_OVERRIDE | "STOP. organization_id is NOT multi-tenant. tenantId from JWT is the only mechanism." |
| "Skip code review, we tested it" | QUALITY_BYPASS | "MANDATORY: 7 reviewers. One security mistake = cross-tenant data leak." |
| "We don't need RabbitMQ multi-tenant" | SCOPE_REDUCTION | "MUST execute Gate 6 if RabbitMQ was detected. CANNOT skip detected stack." |
| "I'll make a quick edit directly" | CODE_BYPASS | "FORBIDDEN: All code changes go through ring:backend-engineer-golang. Dispatch the agent." |
| "It's just one line, no need for an agent" | CODE_BYPASS | "FORBIDDEN: Even single-line changes MUST be dispatched. Agent ensures standards compliance." |
| "Agent is slow, I'll edit faster" | CODE_BYPASS | "FORBIDDEN: Speed is not a justification. Agent applies TDD and standards checks." |
| "This plugin doesn't need Secret Manager" | SCOPE_REDUCTION | "If it's a plugin with MULTI_TENANT_ENABLED=true that calls product APIs, M2M via Secret Manager is MANDATORY." |
| "We can use env vars for M2M credentials" | SECURITY_BYPASS | "Env vars are shared across tenants. M2M credentials are PER-TENANT. MUST use Secrets Manager." |
| "Caching M2M credentials is optional" | QUALITY_BYPASS | "Every request to AWS adds ~50-100ms latency + cost. Caching is MANDATORY from day one." |

---

## Gate Overview

| Gate | Name | Condition | Agent |
|------|------|-----------|-------|
| 0 | Stack Detection + Compliance Audit | Always | Orchestrator |
| 1 | Codebase Analysis (multi-tenant focus) | Always | ring:codebase-explorer |
| 1.5 | Implementation Preview (visual report) | Always | Orchestrator (ring:visual-explainer) |
| 2 | lib-commons v3 + lib-auth v2 Upgrade | Skip only if `go.mod` contains `lib-commons/v3` AND `lib-auth/v2` (verified via grep) | ring:backend-engineer-golang |
| 3 | Multi-Tenant Configuration | Always — verify compliance or implement/fix | ring:backend-engineer-golang |
| 4 | Tenant Middleware (TenantMiddleware or MultiPoolMiddleware) | Always — verify compliance or implement/fix | ring:backend-engineer-golang |
| 5 | Repository Adaptation | Always per detected DB/storage — verify compliance or implement/fix | ring:backend-engineer-golang |
| 5.5 | M2M Secret Manager (Plugin Auth) | Skip if NOT a plugin | ring:backend-engineer-golang |
| 6 | RabbitMQ Multi-Tenant | Skip if no RabbitMQ | ring:backend-engineer-golang |
| 7 | Metrics & Backward Compat | Always | ring:backend-engineer-golang |
| 8 | Tests | Always | ring:backend-engineer-golang |
| 9 | Code Review | Always | 7 parallel reviewers |
| 10 | User Validation | Always | User |
| 11 | Activation Guide | Always | Orchestrator |

MUST execute gates sequentially. CANNOT skip or reorder.

### Input Validation (when invoked from dev-cycle)

If this skill receives structured input from ring:dev-cycle (post-cycle handoff):

```text
VALIDATE input:
1. execution_mode MUST be "FULL" or "SCOPED"
2. If execution_mode == "SCOPED":
   - files_changed MUST be non-empty (otherwise there's nothing to adapt)
   - multi_tenant_exists MUST be true
   - multi_tenant_compliant MUST be true
   - skip_gates MUST include ["0", "1.5", "2", "3", "4", "10", "11"]
3. If execution_mode == "FULL":
   - Core gates always execute (0, 1, 1.5, 2, 3, 4, 5, 7, 8, 9)
   - Conditional gates may be in skip_gates based on stack detection:
     - "5.5" may be skipped if service is NOT a plugin
     - "6" may be skipped if RabbitMQ was NOT detected
     - "10", "11" may be skipped when invoked from dev-cycle
   - skip_gates MUST NOT contain core gates (0-5, 7-9)
4. detected_dependencies (if provided) is used to pre-populate Gate 0 stack detection
   — still MUST verify with grep commands (trust but verify)

If invoked standalone (no input_schema fields):
   - Default to execution_mode = "FULL"
   - Run full Gate 0 stack detection
```

<cannot_skip>

### HARD GATE: Existence ≠ Compliance

**"The service already has multi-tenant code" is NOT a reason to skip any gate.**

MUST replace existing multi-tenant code that does not follow the Ring canonical model — it is **non-compliant**. The only valid reason to skip a gate is when the existing implementation has been **verified** to match the exact patterns defined in [multi-tenant.md](../../docs/standards/golang/multi-tenant.md).

**Compliance verification requires EVIDENCE, not assumption.** See [multi-tenant.md § HARD GATE: Canonical Model Compliance](../../docs/standards/golang/multi-tenant.md#hard-gate-canonical-model-compliance) for the canonical list of compliant patterns. The Gate 0 Phase 2 compliance audit (A1-A8 grep checks) verifies each component against those patterns.

**If ANY audit check is NON-COMPLIANT → the corresponding gate MUST execute to fix it. CANNOT skip.**

</cannot_skip>

---

## Gate 0: Stack Detection + Compliance Audit

**Orchestrator executes directly. No agent dispatch.**

**This gate has TWO phases: detection AND compliance audit.**

### Phase 1: Stack Detection

```text
DETECT (run in parallel):

1. lib-commons version:  grep "lib-commons" go.mod
1b. lib-auth v2:         grep "lib-auth" go.mod
2. PostgreSQL:           grep -rn "postgresql\|pgx\|squirrel" internal/ go.mod
3. MongoDB:              grep -rn "mongodb\|mongo" internal/ go.mod
4. Redis:                grep -rn "redis\|valkey" internal/ go.mod
5. RabbitMQ:             grep -rn "rabbitmq\|amqp" internal/ go.mod
6. S3/Object Storage:    grep -rn "s3\|ObjectStorage\|PutObject\|GetObject\|Upload.*storage\|Download.*storage" internal/ pkg/ go.mod
7. Existing multi-tenant:
   - Config:     grep -rn "MULTI_TENANT_ENABLED" internal/
   - Middleware: grep -rn "dispatch layer/middleware\|WithTenantDB\|MultiPoolMiddleware" internal/
   - Context:    grep -rn "dispatch layer/core\|ResolveMongo\|ResolvePostgres\|ResolveModuleDB" internal/
   - S3 keys:    grep -rn "dispatch layer/s3\|GetObjectStorageKeyForTenant" internal/
   - RMQ:        grep -rn "X-Tenant-ID" internal/
8. Service type (plugin vs product):
   - Plugin:     grep -rn "plugin-\|Plugin" go.mod cmd/ internal/bootstrap/
   - M2M client: grep -rn "client_credentials\|M2M\|secretsmanager\|GetM2MCredentials" internal/ pkg/
   - Product API calls: grep -rn "ledger.*client\|midaz.*client\|product.*client" internal/
```

### Phase 2: Compliance Audit (MANDATORY if any multi-tenant code detected)

If Phase 1 detects any existing multi-tenant code (step 7 returns results), MUST run a compliance audit. MUST replace existing code that does not match the Ring canonical model — it is not "partially done", it is **wrong**.

```text
AUDIT (run in parallel — only if step 7 found existing multi-tenant code):

NOTE: A1 is a NEGATIVE check (presence of wrong names = NON-COMPLIANT).
      A2-A8 are POSITIVE checks (absence of canonical patterns = NON-COMPLIANT).

A1. Config compliance:
    - grep -rn "TENANT_MANAGER_ADDRESS\|TENANT_URL\|TENANT_MANAGER_URL" internal/
    - (any match = NON-COMPLIANT config var names → Gate 3 MUST fix)

A2. Middleware compliance:
    - grep -rn "tmmiddleware.NewTenantMiddleware\|tmmiddleware.NewMultiPoolMiddleware" internal/
    - (no match but other tenant middleware exists = NON-COMPLIANT → Gate 4 MUST fix)

A3. Repository compliance:
    - grep -rn "core.ResolvePostgres\|core.ResolveMongo\|core.ResolveModuleDB" internal/
    - (repositories use static connections or custom pool lookup = NON-COMPLIANT → Gate 5 MUST fix)

A4. Redis compliance (if Redis detected):
    - grep -rn "valkey.GetKeyFromContext" internal/
    - (Redis operations without GetKeyFromContext = NON-COMPLIANT → Gate 5 MUST fix)

A5. S3 compliance (if S3 detected):
    - grep -rn "s3.GetObjectStorageKeyForTenant" internal/
    - (S3 operations without GetObjectStorageKeyForTenant = NON-COMPLIANT → Gate 5 MUST fix)

A6. RabbitMQ compliance (if RabbitMQ detected):
    - grep -rn "tmrabbitmq.NewManager\|tmrabbitmq.Manager" internal/
    - (RabbitMQ multi-tenant without tmrabbitmq.Manager = NON-COMPLIANT → Gate 6 MUST fix)

A7. Circuit breaker compliance:
    - grep -rn "WithCircuitBreaker" internal/
    - (Tenant Manager client without circuit breaker = NON-COMPLIANT → Gate 4 MUST fix)

A8. Backward compatibility compliance:
    - grep -rn "TestMultiTenant_BackwardCompatibility" internal/
    - (no backward compat test = NON-COMPLIANT → Gate 7 MUST fix)

A9. Service API key compliance:
    - grep -rn "MULTI_TENANT_SERVICE_API_KEY" internal/
    - grep -rn "WithServiceAPIKey" internal/
    - (MULTI_TENANT_SERVICE_API_KEY missing from config OR WithServiceAPIKey not called on client = NON-COMPLIANT → Gate 3/4 MUST fix)
```

**Output format for compliance audit:**

```text
COMPLIANCE AUDIT RESULTS:
| Component | Status | Evidence | Gate Action |
|-----------|--------|----------|-------------|
| Config vars | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 3: SKIP / MUST FIX |
| Middleware | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 4: SKIP / MUST FIX |
| Repositories | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 5: SKIP / MUST FIX |
| Redis keys | COMPLIANT / NON-COMPLIANT / N/A | {grep results} | Gate 5: SKIP / MUST FIX |
| S3 keys | COMPLIANT / NON-COMPLIANT / N/A | {grep results} | Gate 5: SKIP / MUST FIX |
| RabbitMQ | COMPLIANT / NON-COMPLIANT / N/A | {grep results} | Gate 6: SKIP / MUST FIX |
| Circuit breaker | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 4: SKIP / MUST FIX |
| Backward compat test | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 7: SKIP / MUST FIX |
| Service API key | COMPLIANT / NON-COMPLIANT | {grep results} | Gate 3/4: SKIP / MUST FIX |
```

**HARD GATE: A gate can only be marked as SKIP when ALL its compliance checks are COMPLIANT with evidence. One NON-COMPLIANT row → gate MUST execute.**

### Phase 3: Non-Canonical File Detection (MANDATORY)

MUST scan for multi-tenant logic in files outside the canonical file map. See [multi-tenant.md § Canonical File Map](../../docs/standards/golang/multi-tenant.md#canonical-file-map) for the complete list of valid files.

```text
DETECT non-canonical multi-tenant files:

N1. Custom tenant middleware:
    grep -rn "tenant" internal/middleware/ pkg/middleware/ --include="*.go" | grep -v "_test.go"
    (any match = NON-CANONICAL file → MUST be removed and replaced with lib-commons middleware)

N2. Custom tenant resolvers/managers:
    grep -rln "tenant" internal/tenant/ internal/multitenancy/ pkg/tenant/ pkg/multitenancy/ --include="*.go" 2>/dev/null
    (any match = NON-CANONICAL file → MUST be removed)

N3. Custom pool managers:
    grep -rln "pool.*tenant\|tenant.*pool" internal/ pkg/ --include="*.go" | grep -v "dispatch layer"
    (any match outside lib-commons = NON-CANONICAL → MUST be removed)
```

**If non-canonical files are found:** report them in the compliance audit as `NON-CANONICAL FILES DETECTED`. The implementing agent MUST remove these files and replace their functionality with the canonical lib-commons v3 sub-packages during the appropriate gate.

**Service type classification:**

| Signal | Classification |
|--------|---------------|
| Module name contains `plugin-` (in go.mod) | **Plugin** → Gate 5.5 MANDATORY |
| Service calls product APIs (ledger, midaz, etc.) | **Plugin** → Gate 5.5 MANDATORY |
| No product API calls, serves own data | **Product** → Gate 5.5 SKIP |

MUST confirm with user: "Is this service a **plugin** (calls product APIs like ledger/midaz) or a **product** (serves its own data)?"

MUST confirm: user explicitly approves detection results before proceeding.

---

## Gate 1: Codebase Analysis (Multi-Tenant Focus)

**Always executes. This gate builds the implementation roadmap for all subsequent gates.**

**Dispatch `ring:codebase-explorer` with multi-tenant-focused context:**

> TASK: Analyze this codebase exclusively under the multi-tenant perspective.
> DETECTED STACK: {databases and messaging from Gate 0}
>
> CRITICAL: Multi-tenant is ONLY about tenantId from JWT → dispatch layer middleware → database-per-tenant.
> IGNORE organization_id completely — it is NOT multi-tenant. A tenant can have multiple organizations inside its database. organization_id is a domain entity, not a tenant identifier.
>
> FOCUS AREAS (explore ONLY these — ignore everything else):
>
> 1. **Service name, modules, and components**: What is the service called? (Look for `const ApplicationName`.) How many components/modules does it have? Each module needs a constant (e.g., `const ModuleManager = "manager"`). Identify: service name (ApplicationName), module names per component, and whether constants exist or need to be created. Hierarchy: Service → Module → Resource.
> 2. **Bootstrap/initialization**: Where does the service start? Where are database connections created? Where is the middleware chain registered? Identify the exact insertion point for TenantMiddleware.
> 3. **Database connections**: How do repositories get their DB connection today? Static field in struct? Constructor injection? Context? List EVERY repository file with file:line showing where the connection is obtained.
> 4. **Middleware chain**: What middleware exists and in what order? Where would TenantMiddleware fit (after auth, before handlers)?
> 5. **Config struct**: Where is the Config struct? What fields exist? Where is it loaded? Identify exact location for MULTI_TENANT_ENABLED vars.
> 6. **RabbitMQ** (if detected): Where are producers? Where are consumers? How are messages published? Where would X-Tenant-ID header be injected? Are producer and consumer in the SAME process or SEPARATE components? Is there already a config split? Are there dual constructors? Is there a RabbitMQManager pool? Does the service struct have both consumer types?
> 7. **Redis** (if detected): Where are Redis operations? Any Lua scripts? Where would GetKeyFromContext be needed?
> 8. **S3/Object Storage** (if detected): Where are Upload/Download/Delete operations? How are object keys constructed? List every file:line that builds an S3 key. What bucket env var is used?
> 9. **Existing multi-tenant code**: Any dispatch layer sub-package imports (`dispatch layer/core`, `dispatch layer/middleware`, `dispatch layer/postgres`, etc.)? TenantMiddleware or MultiPoolMiddleware? `core.ResolvePostgres`/`core.ResolveMongo`/`core.ResolveModuleDB`/`s3.GetObjectStorageKeyForTenant` calls? MULTI_TENANT_ENABLED config? (NOTE: organization_id is NOT related to multi-tenant — ignore it completely)
> 10. **M2M / Plugin authentication** (if service is a plugin): Does the service call product APIs (ledger, midaz, CRM)? How does it authenticate today (static token, env var, hardcoded)? Where is the HTTP client that calls the product? Is there an existing M2M or `client_credentials` flow? Any `secretsmanager` imports? List every file:line where product API calls are made and where authentication credentials are injected.
>
> OUTPUT FORMAT: Structured report with file:line references for every point above.
> DO NOT write code. Analysis only.

**The explorer produces a gap summary.** For the full checklist of required items, see [multi-tenant.md § Checklist](../../docs/standards/golang/multi-tenant.md).

**This report becomes the CONTEXT for all subsequent gates.**

<block_condition>
HARD GATE: MUST complete the analysis report before proceeding. All subsequent gates use this report to know exactly what to change.
</block_condition>

MUST ensure backward compatibility context: the analysis MUST identify how the service works today in single-tenant mode, so subsequent gates preserve this behavior when `MULTI_TENANT_ENABLED=false`.

---

## Gate 1.5: Implementation Preview (Visual Report)

**Always executes. This gate generates a visual HTML report showing exactly what will change before any code is written.**

**Uses the `ring:visual-explainer` skill to produce a self-contained HTML page.**

The report is built from Gate 0 (stack detection) and Gate 1 (codebase analysis). It shows the developer a complete preview of every change that will be made across all subsequent gates, with backward compatibility analysis.

**Orchestrator generates the report using `ring:visual-explainer` with this content:**

The HTML page MUST include these sections:

### 1. Current Architecture (Before)
- Mermaid diagram showing current request flow (how connections work today in single-tenant mode)
- Table of all files that will be modified, with current line counts
- How repositories get DB connections today (static field, constructor injection, etc.)

### 2. Target Architecture (After)
- Mermaid diagram showing the multi-tenant request flow (JWT → middleware → tenant pool → handler)
- Which middleware will be used: `TenantMiddleware` (single-module) or `MultiPoolMiddleware` (multi-module)
- How repositories will get DB connections (context-based: `core.ResolvePostgres(ctx, fallback)`)

### 3. Change Map (per gate)
Table with columns: Gate, File, Current Code, New Code, Lines Changed. One row per file that will be modified. Example:

| Gate | File | What Changes | Impact |
|------|------|-------------|--------|
| 2 | `go.mod` | lib-commons v2 → v3 + lib-auth v2, import paths | All files |
| 3 | `config.go` | Add the 8 canonical MULTI_TENANT_* env vars (see "Canonical Environment Variables" table above) to Config struct | ~20 lines added |
| 4 | `config.go` | Add TenantMiddleware/MultiPoolMiddleware setup | ~30 lines added |
| 4 | `routes.go` | Register middleware in Fiber chain | ~5 lines added |
| 5 | `organization.postgresql.go` | `c.connection.GetDB()` → `core.ResolveModuleDB(ctx, module, r.connection)` | ~3 lines per method |
| 5 | `metadata.mongodb.go` | Static mongo → `core.ResolveMongo(ctx, r.connection, r.dbName)` | ~2 lines per method |
| 5 | `consumer.redis.go` | Key prefixing with `valkey.GetKeyFromContext(ctx, key)` | ~1 line per operation |
| 5 | `storage.go` | S3 key prefixing with `s3.GetObjectStorageKeyForTenant(ctx, key)` | ~1 line per operation |
| 5.5 | `m2m/provider.go` | New file: M2MCredentialProvider with credential caching (plugin only) | ~80 lines |
| 5.5 | `config.go` | Add M2M_TARGET_SERVICE, cache TTL, AWS_REGION env vars (plugin only) | ~10 lines added |
| 5.5 | `bootstrap.go` | Conditional M2M wiring when multi-tenant + plugin (plugin only) | ~20 lines added |
| 6 | `producer.rabbitmq.go` | Dual constructor (single-tenant + multi-tenant) | ~20 lines added |
| 6 | `rabbitmq.server.go` | MultiTenantConsumer setup with lazy mode | ~40 lines added |
| 7 | `config.go` | Backward compat validation | ~10 lines added |

**MANDATORY: Below the summary table, show per-file code diff panels for every file that will be modified.**

For each file in the change map, generate a before/after diff panel showing:
- **Before:** The exact current code from the codebase (sourced from the Gate 1 analysis)
- **After:** The exact code that will be written (following multi-tenant.md patterns)
- Use syntax highlighting and line numbers (read `default/skills/visual-explainer/templates/code-diff.html` for patterns)

Example diff panel for a repository file:

```go
// BEFORE: organization.postgresql.go
func (r *OrganizationPostgreSQLRepository) Create(ctx context.Context, org *Organization) error {
    db := r.connection.GetDB()
    result := db.Model(&OrganizationPostgreSQLModel{}).Create(toModel(org))
    // ...
}

// AFTER: organization.postgresql.go
func (r *OrganizationPostgreSQLRepository) Create(ctx context.Context, org *Organization) error {
    db, err := core.ResolveModuleDB(ctx, "organization", r.connection)
    if err != nil {
        return fmt.Errorf("getting tenant db for organization: %w", err)
    }
    result := db.Model(&OrganizationPostgreSQLModel{}).Create(toModel(org))
    // ...
}
```

The developer MUST be able to see the exact code that will be implemented to approve it. High-level descriptions alone are not sufficient for approval.

**When many files have identical changes** (e.g., 10+ repository files all changing `r.connection.GetDB()` to `core.ResolvePostgres(ctx, r.connection)`): show one representative diff panel, then list the remaining files with "Same pattern applied to: [file list]."

### 4. Backward Compatibility Analysis

**MANDATORY: Show complete conditional initialization code, not just the if/else skeleton.**

For each component (PostgreSQL, MongoDB, Redis, RabbitMQ, S3), show:
1. **Current initialization code** (exact lines from codebase, sourced from Gate 1)
2. **New initialization code** with the `if cfg.MultiTenantEnabled` branch
3. **Explicit callout:** "When MULTI_TENANT_ENABLED=false, execution follows the ELSE branch which is IDENTICAL to current behavior"

Side-by-side comparison showing:
- **MULTI_TENANT_ENABLED=false (default):** Exact current behavior preserved. No JWT parsing, no Tenant Manager calls, no pool routing. Middleware calls `c.Next()` immediately.
- **MULTI_TENANT_ENABLED=true:** New behavior with tenant isolation.

Code diff showing the complete conditional initialization (not skeleton):
```go
if cfg.MultiTenantEnabled && cfg.MultiTenantURL != "" {
    // Multi-tenant path (NEW)
    tmClient := client.NewClient(cfg.MultiTenantURL, logger, clientOpts...)
    pgManager := postgres.NewManager(tmClient, logger)
    // ... show complete initialization
} else {
    // Single-tenant path (UNCHANGED — exactly how it works today)
    // Show the exact same constructor calls that exist in the current codebase
    logger.Info("Running in SINGLE-TENANT MODE")
}
```

Show the middleware bypass explicitly:
```go
// When MULTI_TENANT_ENABLED=false, TenantMiddleware is NOT registered.
// Requests flow directly to handlers without any JWT parsing or tenant resolution.
```

The developer MUST understand that:
- No new code paths execute in single-tenant mode
- The `else` branch preserves the exact current constructor calls
- No additional dependencies are loaded when disabled
- No performance impact when disabled (middleware calls c.Next() immediately)

### 5. New Dependencies
Table showing what gets added to go.mod and which sub-packages are imported:
- `dispatch layer/core` — types, errors, context helpers
- `dispatch layer/client` — Tenant Manager HTTP client
- `dispatch layer/middleware` — TenantMiddleware or MultiPoolMiddleware
- `dispatch layer/postgres` — PostgresManager (if PG detected)
- `dispatch layer/mongo` — MongoManager (if Mongo detected)
- etc.

### 6. Environment Variables
The exact 8 canonical env vars from the "Canonical Environment Variables" table in [multi-tenant.md](../../docs/standards/golang/multi-tenant.md#environment-variables). MUST NOT use alternative names. MUST NOT duplicate the list inline — reference the canonical table.

### 7. Risk Assessment
Table with: Risk, Mitigation, Verification. Examples:
- Single-tenant regression → Backward compat gate (Gate 7) → `MULTI_TENANT_ENABLED=false go test ./...`
- Cross-tenant data leak → Context-based isolation → Tenant isolation integration tests (Gate 8)
- Startup performance → Lazy consumer mode → `consumer.Run(ctx)` returns in <1s

### 8. Retro Compatibility Guarantee

Explicit explanation of backward compatibility strategy:

**Method:** Feature flag with `MULTI_TENANT_ENABLED` environment variable (default: `false`).

**Guarantee:** When `MULTI_TENANT_ENABLED=false`:
- No tenant middleware is registered in the HTTP chain
- No JWT parsing or tenant resolution occurs
- All database connections use the original static constructors
- All Redis keys are unprefixed (original behavior)
- All S3 keys are unprefixed (original behavior)
- RabbitMQ connects directly at startup (original behavior)
- `go test ./...` passes with zero changes to existing tests

**Verification (Gate 7):** The agent MUST run `MULTI_TENANT_ENABLED=false go test ./...` and verify all existing tests pass unchanged.

**Output:** Save the HTML report to `docs/multi-tenant-preview.html` in the project root.

**Open in browser** for the developer to review.

<block_condition>
HARD GATE: Developer MUST explicitly approve the implementation preview before any code changes begin. This prevents wasted effort on misunderstood requirements or incorrect architectural decisions.
</block_condition>

**If the developer requests changes to the preview, regenerate the report and re-confirm.**

---

## Gate 2: lib-commons v3 + lib-auth v2 Upgrade

**SKIP only if:** `go.mod` contains `lib-commons/v3` AND `lib-auth/v2` (verified via grep, not assumed). If the service uses lib-commons v2 or lib-auth v1, this gate is MANDATORY.

**Dispatch `ring:backend-engineer-golang` with context:**

> TASK: Upgrade lib-commons to v3 first, then update lib-auth to v2 (lib-auth v2 depends on lib-commons v3).
> For both libraries, fetch the latest tag (may be beta/rc in dev).
> Check latest tags: `git ls-remote --tags https://github.com/LerianStudio/lib-commons.git | tail -5` and `git ls-remote --tags https://github.com/LerianStudio/lib-auth.git | tail -5`
> Run in order:
> 1. `go get github.com/LerianStudio/lib-commons/v3@{latest-tag}`
> 2. `go get github.com/LerianStudio/lib-auth/v2@{latest-tag}`
> Update go.mod and all import paths from v2 to v3 for lib-commons.
> Follow multi-tenant.md section "Required lib-commons Version".
> DO NOT implement multi-tenant code yet — only upgrade the dependencies.
> Verify: go build ./... and go test ./... MUST pass.

**Verification:** `grep "lib-commons/v3" go.mod` + `grep "lib-auth/v2" go.mod` + `go build ./...` + `go test ./...`

<block_condition>
HARD GATE: MUST pass build and tests before proceeding.
</block_condition>

---

## Gate 3: Multi-Tenant Configuration

**Always executes.** If config already has `MULTI_TENANT_ENABLED`, this gate VERIFIES that all 8 canonical env vars are present with correct names, types, and defaults where applicable. Non-compliant config (wrong names like `TENANT_MANAGER_ADDRESS`, missing vars, wrong defaults) MUST be fixed. Compliance audit from Gate 0 determines whether this is implement or fix.

**Dispatch `ring:backend-engineer-golang` with context from Gate 1 analysis:**

> TASK: Verify and ensure all 8 canonical multi-tenant environment variables exist in the Config struct with correct names and defaults. If any are missing, misnamed, or have wrong defaults — fix them.
> CONTEXT FROM GATE 1: {Config struct location and current fields from analysis report}
> Follow multi-tenant.md sections "Environment Variables", "Configuration", and "Conditional Initialization".
>
> The EXACT env vars to add (no alternatives allowed):
> - MULTI_TENANT_ENABLED (bool, default false)
> - MULTI_TENANT_URL (string, required when enabled)
> - MULTI_TENANT_ENVIRONMENT (string, default "staging", only if RabbitMQ)
> - MULTI_TENANT_MAX_TENANT_POOLS (int, default 100)
> - MULTI_TENANT_IDLE_TIMEOUT_SEC (int, default 300)
> - MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD (int, default 5)
> - MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC (int, default 30)
> - MULTI_TENANT_SERVICE_API_KEY (string, required — API key for dispatch layer /settings endpoint)
>
> MUST NOT use alternative names (e.g., TENANT_MANAGER_ADDRESS, TENANT_MANAGER_URL are WRONG).
> Add conditional log: "Multi-tenant mode enabled" vs "Running in SINGLE-TENANT MODE".
> DO NOT implement TenantMiddleware yet — only configuration.

**Verification:** `grep "MULTI_TENANT_ENABLED" internal/bootstrap/config.go` + `grep "MULTI_TENANT_SERVICE_API_KEY" internal/bootstrap/config.go` + `go build ./...`

**HARD GATE: `.env.example` compliance.** If the project has a `.env.example` file, MUST verify it includes `MULTI_TENANT_SERVICE_API_KEY`. If missing, add it.

---

## Gate 4: TenantMiddleware (Core)

**Always executes.** If middleware already exists, this gate VERIFIES it uses the canonical lib-commons v3 dispatch layer sub-packages (`tmmiddleware.NewTenantMiddleware` or `tmmiddleware.NewMultiPoolMiddleware`). Custom middleware, inline JWT parsing, or any non-lib-commons implementation is NON-COMPLIANT and MUST be replaced. Compliance audit from Gate 0 determines whether this is implement or fix.

**This is the CORE gate. Without compliant TenantMiddleware, there is no tenant isolation.**

**Dispatch `ring:backend-engineer-golang` with context from Gate 1 analysis:**

> TASK: Implement tenant middleware using lib-commons/v3 dispatch layer sub-packages.
> DETECTED DATABASES: {postgresql: Y/N, mongodb: Y/N} (from Gate 0)
> SERVICE ARCHITECTURE: {single-module OR multi-module} (from Gate 1)
> CONTEXT FROM GATE 1: {Bootstrap location, middleware chain insertion point, service init from analysis report}
>
> **For single-module services:** Follow multi-tenant.md § "Generic TenantMiddleware (Standard Pattern)" for imports, constructor, and options.
> **For multi-module services:** Follow multi-tenant.md § "Multi-module middleware (MultiPoolMiddleware)" for WithRoute/WithDefaultRoute pattern.
> **For sub-package import aliases:** See multi-tenant.md § sub-package import table.
>
> Follow multi-tenant.md § "JWT Tenant Extraction" for tenantId claim handling.
> Follow multi-tenant.md § "Conditional Initialization" for the bootstrap pattern.
>
> MUST define constants for service name and module names — never pass raw strings.
> Create connection managers ONLY for detected databases.
> Public endpoints (/health, /version, /swagger) MUST bypass tenant middleware.
> When MULTI_TENANT_ENABLED=false, middleware calls c.Next() immediately (single-tenant passthrough).
>
> **Service API Key Authentication (MANDATORY):** The Tenant Manager HTTP client MUST be configured with `client.WithServiceAPIKey(cfg.MultiTenantServiceAPIKey)` so that `X-API-Key` header is sent in requests to the `/settings` endpoint. Follow multi-tenant.md § "Service Authentication (MANDATORY)".
>
> **IF RabbitMQ DETECTED:** Follow multi-tenant.md § "ConsumerTrigger interface" for the wiring pattern.

**Verification:** `grep "tmmiddleware.NewTenantMiddleware\|tmmiddleware.NewMultiPoolMiddleware" internal/bootstrap/` + `grep "WithServiceAPIKey" internal/bootstrap/` + `go build ./...`

<block_condition>
HARD GATE: CANNOT proceed without TenantMiddleware.
</block_condition>

---

## Gate 5: Repository Adaptation

**Always executes per detected DB/storage.** If repositories already use context-based connections, this gate VERIFIES they use the canonical lib-commons v3 functions (`core.ResolvePostgres`, `core.ResolveMongo`, `core.ResolveModuleDB`, `valkey.GetKeyFromContext`, `s3.GetObjectStorageKeyForTenant`). Custom pool lookups, manual DB switching, or any non-lib-commons resolution is NON-COMPLIANT and MUST be replaced. Compliance audit from Gate 0 determines whether this is implement or fix.

**Dispatch `ring:backend-engineer-golang` with context from Gate 1 analysis:**

> TASK: Adapt all repository implementations to get database connections from tenant context instead of static connections. Also adapt S3/object storage operations to prefix keys with tenant ID.
> DETECTED STACK: {postgresql: Y/N, mongodb: Y/N, redis: Y/N, s3: Y/N} (from Gate 0)
> CONTEXT FROM GATE 1: {List of ALL repository files and storage operations with file:line from analysis report}
>
> Follow multi-tenant.md sections:
> - "Database Connection in Repositories" (PostgreSQL)
> - "MongoDB Multi-Tenant Repository" (MongoDB)
> - "Redis Key Prefixing" and "Redis Key Prefixing for Lua Scripts" (Redis)
> - "S3/Object Storage Key Prefixing" (S3)
>
> MUST work in both modes: multi-tenant (prefixed keys / context connections) and single-tenant (unchanged keys / default connections).

**Verification:** grep for `core.ResolvePostgres` / `core.ResolveMongo` / `core.ResolveModuleDB` (multi-module) / `valkey.GetKeyFromContext` / `s3.GetObjectStorageKeyForTenant` in `internal/` + `go build ./...`

---

## Gate 5.5: M2M Secret Manager (Plugin Auth)

**SKIP IF:** service is NOT a plugin (i.e., it is a product or infrastructure service).

**This gate is MANDATORY for plugins** that need to authenticate with product APIs (e.g., ledger, midaz) in multi-tenant mode. Each tenant has its own M2M credentials stored in AWS Secrets Manager.

**Dispatch `ring:backend-engineer-golang` with context from Gate 0/1 analysis:**

> TASK: Implement M2M credential retrieval from AWS Secrets Manager with per-tenant caching.
> SERVICE TYPE: Plugin (confirmed in Gate 0)
> APPLICATION NAME: {ApplicationName constant from codebase, e.g., "plugin-pix"}
> TARGET SERVICE: {product the plugin calls, e.g., "ledger", "midaz"}
>
> Follow multi-tenant.md section "M2M Credentials via Secret Manager (Plugin-Only)" for all implementation patterns.
>
> **What to implement:**
>
> 1. **M2M Authenticator struct** with credential caching (`sync.Map`) and token caching.
>    Use `secretsmanager.GetM2MCredentials()` from `github.com/LerianStudio/lib-commons/v3/commons/secretsmanager`.
>    The function signature is:
>    ```go
>    secretsmanager.GetM2MCredentials(ctx, smClient, env, tenantOrgID, applicationName, targetService) (*M2MCredentials, error)
>    ```
>    It returns `*M2MCredentials{ClientID, ClientSecret}` fetched from path:
>    `tenants/{env}/{tenantOrgID}/{applicationName}/m2m/{targetService}/credentials`
>
> 2. **Credential cache** with configurable TTL (default 300s). MUST NOT hit AWS on every request.
>
> 3. **Bootstrap wiring** — conditional on `cfg.MultiTenantEnabled`:
>    ```go
>    if cfg.MultiTenantEnabled {
>        awsCfg, _ := awsconfig.LoadDefaultConfig(ctx)
>        smClient := awssm.NewFromConfig(awsCfg)
>        m2mProvider := m2m.NewM2MCredentialProvider(smClient, cfg.MultiTenantEnvironment,
>            constant.ApplicationName, cfg.M2MTargetService,
>            time.Duration(cfg.M2MCredentialCacheTTLSec)*time.Second)
>        productClient = product.NewClient(cfg.ProductURL, m2mProvider)
>    } else {
>        productClient = product.NewClient(cfg.ProductURL, nil) // single-tenant: static auth
>    }
>    ```
>
> 4. **Config env vars** — add to Config struct:
>    - `M2M_TARGET_SERVICE` (string, required for plugins)
>    - `M2M_CREDENTIAL_CACHE_TTL_SEC` (int, default 300)
>    - `AWS_REGION` (string, required for plugins)
>
> 6. **Error handling** using sentinel errors from lib-commons:
>    - `secretsmanager.ErrM2MCredentialsNotFound` → tenant not provisioned
>    - `secretsmanager.ErrM2MVaultAccessDenied` → IAM issue, alert ops
>    - `secretsmanager.ErrM2MInvalidCredentials` → secret malformed, alert ops
>
> **SECURITY:**
> - MUST NOT log clientId or clientSecret values
> - MUST NOT store credentials in environment variables (fetch from Secrets Manager at runtime)
> - MUST cache locally to avoid per-request AWS API calls
> - MUST handle credential rotation via cache TTL expiry

**Verification:** `grep "secretsmanager.GetM2MCredentials\|M2MAuthenticator\|NewM2MAuthenticator" internal/` + `go build ./...`

<block_condition>
HARD GATE: If service is a plugin and MULTI_TENANT_ENABLED=true, M2M Secret Manager integration is NON-NEGOTIABLE. The plugin cannot authenticate with product APIs without it.
</block_condition>

---

## Gate 6: RabbitMQ Multi-Tenant

**SKIP IF:** no RabbitMQ detected.

MANDATORY: RabbitMQ multi-tenant requires **TWO complementary layers** — both are required. See [multi-tenant.md § RabbitMQ Multi-Tenant: Two-Layer Isolation Model](../../docs/standards/golang/multi-tenant.md#rabbitmq-multi-tenant-two-layer-isolation-model) for the canonical reference.

**Summary:**
- **Layer 1 (Isolation):** `tmrabbitmq.Manager` → `GetChannel(ctx, tenantID)` for per-tenant vhosts
- **Layer 2 (Audit):** `X-Tenant-ID` AMQP header for tracing and context propagation

**⛔ CRITICAL DISTINCTION:**
- FORBIDDEN: Using `X-Tenant-ID` header as an isolation mechanism — it is metadata for audit/tracing only
- REQUIRED: `tmrabbitmq.Manager` with per-tenant vhosts as the only acceptable isolation mechanism
- FORBIDDEN: A service that only propagates `X-Tenant-ID` headers on a shared connection — this is not multi-tenant compliant

**Dispatch `ring:backend-engineer-golang` with context from Gate 1 analysis:**

> TASK: Implement RabbitMQ multi-tenant with TWO mandatory layers:
>
> **Layer 1 — Vhost Isolation (MANDATORY):**
> - MUST use `tmrabbitmq.Manager` for per-tenant vhost connections with LRU eviction
> - MUST call `tmrabbitmq.Manager.GetChannel(ctx, tenantID)` for tenant-specific channel (Producer)
> - MUST use `tmconsumer.MultiTenantConsumer` with lazy initialization — no startup connections (Consumer)
> - MUST branch on `cfg.MultiTenantEnabled` in bootstrap (CONFIG SPLIT with dual constructors)
> - MUST keep existing single-tenant code path untouched
>
> **Layer 2 — X-Tenant-ID Header (MANDATORY):**
> - MUST inject `headers["X-Tenant-ID"] = tenantID` in all published messages (Producer)
> - MUST extract `X-Tenant-ID` from AMQP headers for log correlation and tracing (Consumer)
> - Header is audit trail ONLY — isolation comes from Layer 1
>
> CONTEXT FROM GATE 1: {Producer and consumer file:line locations from analysis report}
> DETECTED ARCHITECTURE: {Are producer and consumer in the same process or separate components?}
>
> Follow multi-tenant.md sections:
> - "RabbitMQ Multi-Tenant Producer" for dual constructor pattern with both layers
> - "Multi-Tenant Message Queue Consumers (Lazy Mode)" for lazy initialization
> - "ConsumerTrigger Interface" for the trigger wiring
>
> Gate-specific constraints:
> 1. MANDATORY: CONFIG SPLIT — branch on `cfg.MultiTenantEnabled` for both producer and consumer in bootstrap
> 2. MUST keep the existing single-tenant code path untouched
> 3. MUST NOT connect directly to RabbitMQ at startup in multi-tenant mode
> 4. MUST use X-Tenant-ID in AMQP headers for audit — NOT as isolation mechanism
> 5. MUST implement both layers together — one without the other is non-compliant

**Verification:**
1. `grep "tmrabbitmq.Manager\|NewProducerMultiTenant\|EnsureConsumerStarted\|tmmiddleware.ConsumerTrigger" internal/` + `go build ./...`
2. **Vhost isolation (Layer 1):** `grep -rn "tmrabbitmq.NewManager\|tmrabbitmq.Manager" internal/` MUST return results.
3. **X-Tenant-ID header (Layer 2):** `grep -rn "X-Tenant-ID" internal/` MUST return results in both producer AND consumer.
4. **Shared connection rejection:** If RabbitMQ multi-tenant uses a shared connection with only `X-Tenant-ID` headers (no `tmrabbitmq.Manager`), this gate FAILS.

<block_condition>
HARD GATE: RabbitMQ multi-tenant requires BOTH layers:
1. `tmrabbitmq.Manager` for per-tenant vhost isolation (Layer 1 — ISOLATION)
2. `X-Tenant-ID` AMQP header for audit trail and context propagation (Layer 2 — OBSERVABILITY)

Layer 2 alone (shared connection + X-Tenant-ID header) is NOT multi-tenant compliant — it provides traceability but ZERO isolation between tenants.
Layer 1 alone (vhosts without header) provides isolation but loses audit trail and cross-service context propagation.
Both layers MUST be implemented together. MUST NOT connect directly to RabbitMQ at startup in multi-tenant mode.
</block_condition>

#### RabbitMQ Multi-Tenant Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "X-Tenant-ID header is enough for isolation" | Headers are metadata for audit/tracing, NOT isolation. All tenants share the same queues and vhost. A consumer bug or poison message affects ALL tenants. | **MUST implement Layer 1: `tmrabbitmq.Manager` with per-tenant vhosts** |
| "Vhosts are enough, we don't need the header" | Vhosts isolate but don't propagate tenant context for logging, tracing, and downstream DB resolution. Header is required for observability. | **MUST implement Layer 2: `X-Tenant-ID` header in all messages** |
| "Shared connection is simpler" | Simplicity ≠ isolation. One tenant's traffic spike blocks all others. No per-tenant rate limiting or queue policies possible. | **MUST use per-tenant vhosts via `tmrabbitmq.Manager`** |
| "We'll migrate to vhosts later" | Later = never. This is a HARD GATE. | **MUST implement NOW** |
| "Our service has low RabbitMQ traffic" | Traffic volume ≠ exemption. Isolation is a platform requirement. | **MUST use `tmrabbitmq.Manager` + `X-Tenant-ID` header** |

---

## Gate 7: Metrics & Backward Compatibility

**Dispatch `ring:backend-engineer-golang` with context:**

> TASK: Add multi-tenant metrics and validate backward compatibility.
>
> Follow multi-tenant.md sections "Multi-Tenant Metrics" and "Single-Tenant Backward Compatibility Validation (MANDATORY)".
>
> The EXACT metrics to implement (no alternatives allowed):
> - `tenant_connections_total` (Counter) — Total tenant connections created
> - `tenant_connection_errors_total` (Counter) — Connection failures per tenant
> - `tenant_consumers_active` (Gauge) — Active message consumers
> - `tenant_messages_processed_total` (Counter) — Messages processed per tenant
>
> All 4 metrics are MANDATORY. When MULTI_TENANT_ENABLED=false, metrics MUST use no-op implementations (zero overhead).
>
> BACKWARD COMPATIBILITY IS NON-NEGOTIABLE:
> - MUST start without any MULTI_TENANT_* env vars
> - MUST start without Tenant Manager running
> - MUST pass all existing tests with MULTI_TENANT_ENABLED=false
> - Health/version endpoints MUST work without tenant context
>
> Write TestMultiTenant_BackwardCompatibility integration test.

**Verification:** `MULTI_TENANT_ENABLED=false go test ./...` MUST pass.

<block_condition>
HARD GATE: Backward compatibility MUST pass.
</block_condition>

---

## Gate 8: Tests

**Dispatch `ring:backend-engineer-golang` with context:**

> TASK: Write multi-tenant tests.
> DETECTED STACK: {postgresql: Y/N, mongodb: Y/N, redis: Y/N, s3: Y/N, rabbitmq: Y/N} (from Gate 0)
>
> Follow multi-tenant.md section "Testing Multi-Tenant Code" (all subsections).
>
> Required tests: unit tests with mock tenant context, tenant isolation tests (two tenants, data separation), error case tests (missing JWT, tenant not found), plus RabbitMQ, Redis, and S3 tests if detected.

**Verification:** `go test ./... -v -count=1` + `go test ./... -cover`

---

## Gate 9: Code Review

**Dispatch 7 parallel reviewers (same pattern as ring:requesting-code-review).**

MUST include this context in ALL 7 reviewer dispatches:

> **MULTI-TENANT REVIEW CONTEXT:**
> - Multi-tenant isolation is based on `tenantId` from JWT → dispatch layer middleware (TenantMiddleware or MultiPoolMiddleware) → database-per-tenant.
> - `organization_id` is NOT a tenant identifier. It is a business filter within the tenant's database. A single tenant can have multiple organizations. Do NOT flag organization_id as a multi-tenant issue.
> - Backward compatibility is required: when `MULTI_TENANT_ENABLED=false`, the service MUST work exactly as before (single-tenant mode, no tenant context needed).

| Reviewer | Focus |
|----------|-------|
| ring:code-reviewer | Architecture, lib-commons v3 usage, TenantMiddleware/MultiPoolMiddleware placement, sub-package usage |
| ring:business-logic-reviewer | Tenant context propagation via tenantId (NOT organization_id) |
| ring:security-reviewer | Cross-tenant DB isolation, JWT tenantId validation, no data leaks between tenant databases |
| ring:test-reviewer | Coverage, isolation tests between two tenants, backward compat tests |
| ring:nil-safety-reviewer | Nil risks in tenant context extraction from JWT and context getters |
| ring:consequences-reviewer | Impact on single-tenant paths, backward compat when MULTI_TENANT_ENABLED=false |
| ring:dead-code-reviewer | Orphaned code from tenant changes, dead tenant-specific helpers |

MUST pass all 7 reviewers. Critical findings → fix and re-review.

---

## Gate 10: User Validation

MUST approve: present checklist for explicit user approval.

```markdown
## Multi-Tenant Implementation Complete

- [ ] lib-commons v3
- [ ] MULTI_TENANT_ENABLED config
- [ ] Tenant middleware (TenantMiddleware or MultiPoolMiddleware for multi-module services)
- [ ] Repositories use context-based connections
- [ ] S3 keys prefixed with tenantId (if applicable)
- [ ] RabbitMQ X-Tenant-ID (if applicable)
- [ ] M2M Secret Manager with credential + token caching (if plugin)
- [ ] Backward compat (MULTI_TENANT_ENABLED=false works)
- [ ] Tests pass
- [ ] Code review passed
```

---

## Gate 11: Activation Guide

**MUST generate `docs/multi-tenant-guide.md` in the project root.** Direct, concise, no filler text.

The file is built from Gate 0 (stack) and Gate 1 (analysis). See [multi-tenant.md § Checklist](../../docs/standards/golang/multi-tenant.md) for the canonical env var list and requirements.

<!-- Template: values filled from Gate 0/1 results. Canonical source: multi-tenant.md -->

The guide MUST include:
1. **Components table**: Component name, Service const, Module const, Resources, what was adapted
2. **Environment variables**: the 8 canonical MULTI_TENANT_* vars (MULTI_TENANT_ENABLED, MULTI_TENANT_URL, MULTI_TENANT_ENVIRONMENT, MULTI_TENANT_MAX_TENANT_POOLS, MULTI_TENANT_IDLE_TIMEOUT_SEC, MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD, MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC, MULTI_TENANT_SERVICE_API_KEY) with required/default/description
3. **M2M environment variables (plugin only)**: If the service is a plugin, include M2M_TARGET_SERVICE, M2M_CREDENTIAL_CACHE_TTL_SEC, AWS_REGION
4. **How to activate**: set envs + start alongside Tenant Manager (+ AWS credentials for plugins)
5. **How to verify**: check logs, test with JWT tenantId (+ verify M2M credential retrieval for plugins)
6. **How to deactivate**: set MULTI_TENANT_ENABLED=false
7. **Common errors**: see [multi-tenant.md § Error Handling](../../docs/standards/golang/multi-tenant.md)

---

## State Persistence

Save to `docs/ring-dev-multi-tenant/current-cycle.json` for resume support:

```json
{
  "cycle": "multi-tenant",
  "service_type": "plugin",
  "stack": {"postgresql": false, "mongodb": true, "redis": true, "rabbitmq": true, "s3": true},
  "gates": {"0": "PASS", "1": "PASS", "1.5": "PASS", "2": "IN_PROGRESS", "3": "PENDING", "5.5": "PENDING"},
  "current_gate": 2
}
```

---

## Anti-Rationalization Table

See [multi-tenant.md](../../docs/standards/golang/multi-tenant.md) for the canonical anti-rationalization tables on tenantId vs organization_id.

**Skill-specific rationalizations:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Service already has multi-tenant code" | Existence ≠ compliance. Code that doesn't follow the Ring canonical model is WRONG and must be replaced. | **STOP. Run compliance audit (Gate 0 Phase 2). Fix every NON-COMPLIANT component.** |
| "Multi-tenant is already implemented, just needs tweaks" | Partial or non-standard implementation is not "almost done" — it is non-compliant. Every component must match the canonical model exactly. | **STOP. Execute every gate. Verify or fix each one.** |
| "Skipping this gate because something similar exists" | "Similar" is not "compliant". Only exact matches to lib-commons v3 dispatch layer sub-packages are valid. | **STOP. Verify with grep evidence. If it doesn't match the canonical pattern → gate MUST execute.** |
| "The current approach works fine, no need to change" | Working ≠ compliant. A custom solution that works today creates drift, blocks upgrades, and prevents standardized tooling. | **STOP. Replace with canonical implementation.** |
| "We have a custom tenant package that handles this" | Custom packages are non-canonical. Only lib-commons v3 dispatch layer sub-packages are valid. Custom files MUST be removed. | **STOP. Remove custom files. Use lib-commons v3 sub-packages.** |
| "This extra file just wraps lib-commons" | Wrappers add indirection that breaks compliance verification and creates maintenance burden. MUST use lib-commons directly. | **STOP. Remove wrapper. Call lib-commons directly from bootstrap/adapters.** |
| "Agent says out of scope" | Skill defines scope, not agent. | **Re-dispatch with gate context** |
| "Skip tests" | Gate 8 proves isolation works. | **MANDATORY** |
| "Skip review" | Security implications. One mistake = data leak. | **MANDATORY** |
| "Using TENANT_MANAGER_ADDRESS instead" | Non-standard name. Only the 8 canonical MULTI_TENANT_* vars are valid. | **STOP. Use MULTI_TENANT_URL** |
| "The service already uses a different env name" | Legacy names are non-compliant. Rename to canonical names. | **Replace with canonical env vars** |
| "Plugin doesn't need Secret Manager for M2M" | If multi-tenant is active, each tenant has different credentials. Env vars can't hold per-tenant secrets. | **MUST use Secret Manager for per-tenant M2M** |
| "We'll add M2M caching later" | Without caching, every request hits AWS (~50-100ms + cost). This is a production blocker. | **MUST implement caching from day one** |
| "Hardcoded credentials work for now" | Hardcoded creds don't scale across tenants and are a security risk. | **MUST fetch from Secrets Manager per tenant** |
