# Standards Coverage Table Pattern

This file defines the MANDATORY output format for agents comparing codebases against Ring standards. It ensures every section in the standards is explicitly checked and reported.

---

## ⛔ CRITICAL: All Sections Are Required

**This is NON-NEGOTIABLE. Every section listed in the Agent → Standards Section Index below MUST be checked.**

| Rule                                          | Enforcement                                                                         |
| --------------------------------------------- | ----------------------------------------------------------------------------------- |
| **Every section MUST be checked**             | No exceptions. No skipping.                                                         |
| **Every section MUST appear in output table** | Missing row = INCOMPLETE output                                                     |
| **Subsections are INCLUDED**                  | If "Containers" is listed, all content (Dockerfile, Docker Compose) MUST be checked |
| **N/A requires explicit reason**              | Cannot mark N/A without justification                                               |

**If you skip any section → Your output is REJECTED. Start over.**

**If you invent section names → Your output is REJECTED. Start over.**

---

## ⛔ CRITICAL: Section Names Are Not Negotiable

**You MUST use the EXACT section names from this file. You CANNOT:**

| FORBIDDEN         | Example                                     | Why Wrong              |
| ----------------- | ------------------------------------------- | ---------------------- |
| Invent names      | "Security", "Code Quality"                  | Not in coverage table  |
| Rename sections   | "Config" instead of "Configuration Loading" | Breaks traceability    |
| Merge sections    | "Error Handling & Logging"                  | Each section = one row |
| Use abbreviations | "Bootstrap" instead of "Bootstrap Pattern"  | Must match exactly     |
| Skip sections     | Omitting "RabbitMQ Worker Pattern"          | Mark N/A instead       |

**Your output table section names MUST match the "Section to Check" column below EXACTLY.**

---

## Why This Pattern Exists

**Problem:** Agents might skip sections from standards files, either by:

- Only checking "main" sections
- Assuming some sections don't apply
- Not enumerating all sections systematically
- Skipping subsections (e.g., checking Dockerfile but skipping Docker Compose)

**Solution:** Require a completeness table that MUST list every section from the WebFetch result with explicit status. All content within each section MUST be evaluated.

---

## MANDATORY: Standards Coverage Table

### ⛔ HARD GATE: Before Outputting Findings

**You MUST output a Standards Coverage Table that enumerates every section from the WebFetch result.**

**REQUIRED: When checking a section, you MUST check all subsections and patterns within it.**

| Section                | What MUST Be Checked                                            |
| ---------------------- | --------------------------------------------------------------- |
| Containers             | Dockerfile patterns and Docker Compose patterns                 |
| Infrastructure as Code | Terraform structure and state management and modules            |
| Observability          | Logging and Tracing (structured JSON logs, OpenTelemetry spans) |
| Security               | Secrets management and Network policies                         |

### Process

1. **Parse the WebFetch result** - Extract all `## Section` headers from the standards file
2. **Count sections** - Record total number of sections found
3. **For each section** - Determine status and evidence
4. **Output table** - MUST have one row per section
5. **Verify completeness** - Table row count MUST equal section count

### Output Format

```markdown
## Standards Coverage Table

**Standards File:** {filename}.md (from WebFetch)
**Total Sections Found:** {N}
**Table Rows:** {N} (MUST match)

| #   | Section (from WebFetch) | Status       | Evidence            |
| --- | ----------------------- | ------------ | ------------------- |
| 1   | {Section 1 header}      | ✅/⚠️/❌/N/A | file:line or reason |
| 2   | {Section 2 header}      | ✅/⚠️/❌/N/A | file:line or reason |
| ... | ...                     | ...          | ...                 |
| N   | {Section N header}      | ✅/⚠️/❌/N/A | file:line or reason |

**Completeness Verification:**

- Sections in standards: {N}
- Rows in table: {N}
- Status: ✅ Complete / ❌ Incomplete
```

### Status Legend

| Status           | Meaning                            | When to Use                          |
| ---------------- | ---------------------------------- | ------------------------------------ |
| ✅ Compliant     | Codebase follows this standard     | Code matches expected pattern        |
| ⚠️ Partial       | Some compliance, needs improvement | Partially implemented or minor gaps  |
| ❌ Non-Compliant | Does not follow standard           | Missing or incorrect implementation  |
| N/A              | Not applicable to this codebase    | Standard doesn't apply (with reason) |

---

## ⛔ CRITICAL: Standards Boundary Enforcement

**You MUST check only what the standards file explicitly defines. Never invent requirements.**

See [shared-patterns/standards-boundary-enforcement.md](standards-boundary-enforcement.md) for:

- Complete list of what IS and IS not required per agent
- Agent-specific requirement boundaries
- Self-verification checklist

**⛔ HARD GATE:** Before flagging any item as non-compliant:

1. Verify the requirement EXISTS in the WebFetch result
2. Quote the EXACT standard that requires it
3. If you cannot quote it → Do not flag it

---

## Anti-Rationalization Table

| Rationalization                                | Why It's WRONG                                                      | Required Action                                   |
| ---------------------------------------------- | ------------------------------------------------------------------- | ------------------------------------------------- |
| "I checked the important sections"             | You don't decide importance. All sections MUST be checked.          | **List every section in table**                   |
| "Some sections obviously don't apply"          | Report them as N/A with reason. Never skip silently.                | **Include in table with N/A status**              |
| "The table would be too long"                  | Completeness > brevity. Every section MUST be visible.              | **Output full table regardless of length**        |
| "I already mentioned these in findings"        | Findings ≠ Coverage table. Both are REQUIRED.                       | **Output table BEFORE detailed findings**         |
| "WebFetch result was unclear"                  | Parse all `## ` headers. If truly unclear, STOP and report blocker. | **Report blocker or parse all headers**           |
| "I checked Dockerfile, that covers Containers" | Containers = Dockerfile + Docker Compose. Partial ≠ Complete.       | **Check all subsections within each section**     |
| "Project doesn't use Docker Compose"           | Report as N/A with evidence. Never assume. VERIFY first.            | **Search for docker-compose.yml, report finding** |
| "Only checking what exists in codebase"        | Standards define what SHOULD exist. Missing = Non-Compliant.        | **Report missing patterns as ❌ Non-Compliant**   |
| "My section name is clearer"                   | Consistency > clarity. Coverage table names are the contract.       | **Use EXACT names from coverage table**           |
| "I combined related sections for brevity"      | Each section = one row. Merging loses traceability.                 | **One row per section, no merging**               |
| "I added a useful section like 'Security'"     | You don't decide sections. Coverage table does.                     | **Only output sections from coverage table**      |
| "'Logging' is the same as 'Logging Standards'" | Names must match EXACTLY. Variations break automation.              | **Use exact string from coverage table**          |

---

## Completeness Check (SELF-VERIFICATION)

**Before submitting output, verify:**

```text
1. Did I extract all ## headers from WebFetch result?     [ ]
2. Does my table have exactly that many rows?             [ ]
3. Does every row have a status (✅/⚠️/❌/N/A)?           [ ]
4. Does every ⚠️/❌ have evidence (file:line)?           [ ]
5. Does every N/A have a reason?                         [ ]

If any checkbox is unchecked → FIX before submitting.
```

---

## Integration with Findings

**Order of output:**

1. **Standards Coverage Table** (this pattern) - Shows completeness
2. **Detailed Findings** - Only for ⚠️ Partial and ❌ Non-Compliant items

The Coverage Table ensures nothing is skipped. The Detailed Findings provide actionable information for gaps.

---

## Example Output

```markdown
## Standards Coverage Table

**Standards File:** golang.md (from WebFetch)
**Total Sections Found:** 21
**Table Rows:** 21 (MUST match)

| #   | Section (from WebFetch)      | Status | Evidence                               |
| --- | ---------------------------- | ------ | -------------------------------------- |
| 1   | Version                      | ✅     | go.mod:3 (Go 1.24)                     |
| 2   | Core Dependency: lib-commons | ✅     | go.mod:5                               |
| 3   | Frameworks & Libraries       | ✅     | Fiber v2, pgx/v5 in go.mod             |
| 4   | Configuration Loading        | ⚠️     | internal/config/config.go:12           |
| 5   | Telemetry & Observability    | ❌     | Not implemented                        |
| 6   | Bootstrap Pattern            | ✅     | cmd/server/main.go:15                  |
| 7   | Access Manager Integration   | ✅     | internal/middleware/auth.go:25         |
| 8   | License Manager Integration  | N/A    | Not a licensed project                 |
| 9   | Data Transformation          | ✅     | internal/adapters/postgres/mapper.go:8 |
| 10  | Error Codes Convention       | ⚠️     | Uses generic codes                     |
| 11  | Error Handling               | ✅     | Consistent pattern                     |
| 12  | Function Design              | ✅     | Small functions, clear names           |
| 13  | Pagination Patterns          | N/A    | No list endpoints                      |
| 14  | Testing Patterns             | ❌     | No tests found                         |
| 15  | Logging Standards            | ⚠️     | Missing structured fields              |
| 16  | Linting                      | ✅     | .golangci.yml present                  |
| 17  | Architecture Patterns        | ✅     | Hexagonal structure                    |
| 18  | Directory Structure          | ✅     | Follows Lerian pattern                 |
| 19  | Concurrency Patterns         | N/A    | No concurrent code                     |
| 20  | RabbitMQ Worker Pattern      | N/A    | No message queue                       |

**Completeness Verification:**

- Sections in standards: 20
- Rows in table: 20
- Status: ✅ Complete
```

---

## How Agents Reference This Pattern

Agents MUST include this in their Standards Compliance section:

```markdown
## Standards Compliance Output (Conditional)

**Detection:** Prompt contains `**MODE: ANALYSIS only**`

**When triggered, you MUST:**

1. Output Standards Coverage Table per [shared-patterns/standards-coverage-table.md](../skills/shared-patterns/standards-coverage-table.md)
2. Then output detailed findings for ⚠️/❌ items

See [shared-patterns/standards-coverage-table.md](../skills/shared-patterns/standards-coverage-table.md) for:

- Table format
- Status legend
- Anti-rationalization rules
- Completeness verification checklist
```

---

## Agent → Standards Section Index

**IMPORTANT:** When updating a standards file, you MUST also update the corresponding section index below.

**Meta-sections (EXCLUDED from agent checks):**
Standards files may contain these meta-sections that are not counted in section indexes:

- `## Checklist` - Self-verification checklist for developers
- `## Standards Compliance` - Output format examples for agents
- `## Standards Compliance Output Format` - Output templates

These sections describe HOW to use the standards, not WHAT the standards are.

### ring:backend-engineer-golang → golang/

**Modular Structure:** Standards are split into focused modules. Load index.md first, then required modules.

| # | Section to Check | File | Anchor | Key Subsections |
|---|------------------|------|--------|-----------------|
| 1 | Version | core.md | `#version` | Go 1.24+ |
| 2 | Core Dependency: lib-commons | core.md | `#core-dependency-lib-commons-mandatory` | **HARD GATE:** No duplicate utils/helpers - use lib-commons |
| 3 | Frameworks & Libraries | core.md | `#frameworks--libraries` | lib-commons v2, Fiber v2, pgx/v5, OpenTelemetry, zap, testify, gomock, **validator v10 migration (MANDATORY)** |
| 4 | Configuration | core.md | `#configuration` | Environment variable handling |
| 5 | Database Naming Convention (snake_case) | core.md | `#database-naming-convention-snake-case-mandatory` | Table and column naming |
| 6 | Database Migrations | core.md | `#database-migrations-mandatory` | golang-migrate requirement |
| 7 | License Headers | core.md | `#license-headers-mandatory` | **MANDATORY** - All source files require license headers |
| 8 | MongoDB Patterns | core.md | `#mongodb-patterns-mandatory` | **Injection prevention (CRITICAL)**, connection pooling, index management, deprecated API removal |
| 9 | Dependency Management | core.md | `#dependency-management-mandatory` | **Version pinning (MANDATORY)**, go.sum, security updates, govulncheck, detection commands |
| 10 | Observability | bootstrap.md | `#observability` | OpenTelemetry integration, **Span Naming Conventions (MANDATORY)**: layer.domain.operation pattern, detection commands |
| 11 | Bootstrap | bootstrap.md | `#bootstrap` | Application initialization |
| 12 | Graceful Shutdown Patterns | bootstrap.md | `#graceful-shutdown-patterns-mandatory` | **Signal handling (MANDATORY)**, shutdown order, resource cleanup, detection commands |
| 13 | Health Checks | bootstrap.md | `#health-checks-mandatory` | **/health vs /ready (MANDATORY)**, Kubernetes probes, dependency checks |
| 14 | Connection Management | bootstrap.md | `#connection-management-mandatory` | **Pool configuration (MANDATORY)**, timeouts, graceful shutdown, detection commands |
| 15 | Access Manager Integration | security.md | `#access-manager-integration-mandatory` | **CONDITIONAL** - Check if project has auth |
| 16 | License Manager Integration | security.md | `#license-manager-integration-mandatory` | **CONDITIONAL** - Check if project is licensed |
| 17 | Secret Redaction Patterns | security.md | `#secret-redaction-patterns-mandatory` | **Credential leak prevention (MANDATORY)**, connection string redaction, detection commands |
| 18 | SQL Safety | security.md | `#sql-safety-mandatory` | **Parameterized queries (MANDATORY)**, SQL injection prevention, whitelist pattern, detection commands |
| 19 | HTTP Security Headers | security.md | `#http-security-headers-mandatory` | **X-Content-Type-Options: nosniff (MANDATORY)**, **X-Frame-Options: DENY (MANDATORY)** |
| 20 | Data Transformation | domain.md | `#data-transformation-toentityfromentity-mandatory` | ToEntity/FromEntity patterns |
| 21 | Error Codes Convention | domain.md | `#error-codes-convention-mandatory` | Service-prefixed codes |
| 22 | Error Handling | domain.md | `#error-handling` | **Sentinel errors (MANDATORY)**, error wrapping |
| 23 | Exit/Fatal Location Rules | domain.md | `#exitfatal-location-rules-mandatory` | **panic() Detection Checklist (MANDATORY)**, **log.Fatal() Location Rules (MANDATORY)**, Anti-Rationalization Table |
| 24 | Function Design | domain.md | `#function-design-mandatory` | Single responsibility |
| 25 | File Organization | domain.md | `#file-organization-mandatory` | File-level SRP, max 200-300 lines |
| 26 | JSON Naming Convention (camelCase) | api-patterns.md | `#json-naming-convention-camelcase-mandatory` | API response field naming |
| 27 | Pagination Patterns | api-patterns.md | `#pagination-patterns` | **Offset & cursor strategies**, limit validation, response structure, lib-commons utilities |
| 28 | HTTP Status Code Consistency | api-patterns.md | `#http-status-code-consistency-mandatory` | **201 for creation, 200 for update (MANDATORY)**, lib-commons response methods, detection commands |
| 29 | OpenAPI Documentation (Swaggo) | api-patterns.md | `#openapi-documentation-swaggo-mandatory` | Annotations as source of truth |
| 30 | Handler Constructor Pattern | api-patterns.md | `#handler-constructor-pattern-mandatory` | **Dependency injection via constructor (MANDATORY)**, validation at startup, detection commands |
| 31 | Input Validation | api-patterns.md | `#input-validation-mandatory` | **Defense in depth (MANDATORY)**, validator v10 tags, **numeric query param validation**, error translation |
| 32 | Testing | quality.md | `#testing` | Table-driven tests, edge cases, **t.Setenv (MANDATORY)**, **b.Loop (MANDATORY)** |
| 33 | Logging | quality.md | `#logging` | Structured logging with lib-commons |
| 34 | Linting | quality.md | `#linting` | **Import ordering (MANDATORY)**, **Post-implementation linting (MANDATORY)**, **.golangci.yml requirement (MANDATORY)**, **14 mandatory linters**, magic numbers (mnd) |
| 35 | Migration Guidance for Mandatory Linter Promotion | quality.md | `#migration-guidance-for-mandatory-linter-promotion` | **Phased rollout (MANDATORY)**, per-linter common violations, batch fix commands |
| 36 | Production Config Validation | quality.md | `#production-config-validation-mandatory` | **Startup validation (MANDATORY)**, fail-fast, detailed error messages |
| 37 | Container Security | quality.md | `#container-security-conditional` | **⚠️ CONDITIONAL** - Non-root user, image pinning (if Dockerfile exists) |
| 38 | Architecture Patterns | architecture.md | `#architecture-patterns` | Hexagonal architecture |
| 39 | Directory Structure | architecture.md | `#directory-structure` | Lerian pattern |
| 40 | Concurrency Patterns | architecture.md | `#concurrency-patterns` | Goroutines, channels, errgroup, **Map mutex (MANDATORY)**, loop variable capture, detection commands |
| 41 | Goroutine Recovery Patterns | architecture.md | `#goroutine-recovery-patterns-mandatory` | **Panic recovery (MANDATORY)**, recovery wrapper, detection commands |
| 42 | Goroutine Leak Detection | architecture.md | `#goroutine-leak-detection-mandatory` | **goleak framework (MANDATORY)**: When implementing goroutines, MUST create goleak leak tests. TestMain pattern, per-test VerifyNone, goroutine leak patterns, detection commands |
| 43 | N+1 Query Detection | architecture.md | `#n1-query-detection-mandatory` | **Batch loading (MANDATORY)**, JOIN patterns, detection commands |
| 44 | Performance Patterns | architecture.md | `#performance-patterns-mandatory` | **SELECT * avoidance (MANDATORY)**, sync.Pool, memory allocation, detection commands |
| 45 | RabbitMQ Worker Pattern | messaging.md | `#rabbitmq-worker-pattern` | Async message processing, **Exponential Backoff with Jitter (MANDATORY)**, **Error Classification (MANDATORY)** |
| 46 | RabbitMQ Reconnection Strategy | messaging.md | `#rabbitmq-reconnection-strategy-mandatory` | **MANDATORY: Consumer Reconnection Loop**, **MANDATORY: Producer Per-Publish Retry**, **MANDATORY: Health Check Integration**, **MANDATORY: Deadlock Prevention** |
| 47 | Always-Valid Domain Model | domain-modeling.md | `#always-valid-domain-model-mandatory` | **MANDATORY: Constructor Validation Patterns**: NewEntity/NewEntityFromDTO/ReconstructEntity conventions, invariant protection, ToEntity/FromEntity integration, detection commands |
| 48 | Idempotency Patterns | idempotency.md | `#idempotency-patterns-mandatory-for-transaction-apis` | Redis SetNX, hash fallback, async caching |
| 49 | Multi-Tenant Patterns | multi-tenant.md | `#multi-tenant-patterns-mandatory` | **MANDATORY: Both single-tenant and multi-tenant modes with backward compatibility.** See [multi-tenant.md](../../docs/standards/golang/multi-tenant.md) for full standard. |
| 50 | Route-Level Auth-Before-Tenant Ordering | multi-tenant.md | `#route-level-auth-before-tenant-ordering-mandatory` | **MANDATORY: Auth MUST validate JWT before tenant middleware calls TM API.** WithTenantRoute per-route composition, DoS prevention, detection commands |
| 51 | Rate Limiting | security.md | `#rate-limiting-mandatory` | **Three-tier strategy (MANDATORY)**: Global/Export/Dispatch, **Trusted Proxy (MANDATORY)**: EnableTrustedProxyCheck + TrustedProxies (Fiber v2) / TrustProxy + TrustProxyConfig (Fiber v3) for real client IP, Redis-backed storage (in-memory fallback on Redis outage), key priority (UserID > TenantID+IP > IP), **production force-enable (MANDATORY)**, Retry-After header, detection commands |
| 52 | CORS Configuration | security.md | `#cors-configuration-mandatory` | **Configuration-driven (MANDATORY)**, production validation (no wildcard, no empty), middleware ordering (before Helmet), Helmet integration, detection commands |
| 53 | Service Authentication | multi-tenant.md | `#service-authentication-mandatory` | **MANDATORY: API key authentication for dispatch layer /settings endpoint.** `MULTI_TENANT_SERVICE_API_KEY` env var, `client.WithServiceAPIKey()`, `X-API-Key` header, key rotation via service catalog |
| 54 | Settings Revalidation | multi-tenant.md | N/A (pgManager internal) | **pgManager handles internally via `WithConnectionsCheckInterval`.** No separate watcher needed. Pass option when creating PostgreSQL manager. Detects maxOpenConns/maxIdleConns/statementTimeout changes |

**Module Loading Guide:**

| Task Type | Required Modules |
|-----------|------------------|
| New feature (full) | core.md → bootstrap.md → domain.md → quality.md |
| Auth implementation | core.md → security.md |
| Rate limiting | security.md |
| CORS configuration | security.md |
| Add tracing | bootstrap.md |
| Testing | quality.md |
| API endpoints | api-patterns.md (pagination + swaggo) |
| Idempotency | idempotency.md + domain.md |
| Multi-tenant | multi-tenant.md + bootstrap.md |
| Full compliance check | all modules |

---

### ring:backend-engineer-typescript → typescript.md

| #   | Section to Check              | Anchor                                 | Key Subsections                               |
| --- | ----------------------------- | -------------------------------------- | --------------------------------------------- |
| 1   | Version                       | `#version`                             | TypeScript 5.0+, Node.js 20+                  |
| 2   | Strict Configuration          | `#strict-configuration-mandatory`      | tsconfig.json strict mode                     |
| 3   | Frameworks & Libraries        | `#frameworks--libraries`               | Express, Fastify, NestJS, Prisma, Zod, Vitest |
| 4   | Type Safety                   | `#type-safety`                         | No any, branded types, discriminated unions   |
| 5   | Zod Validation Patterns       | `#zod-validation-patterns`             | Schema validation                             |
| 6   | Dependency Injection          | `#dependency-injection`                | TSyringe patterns                             |
| 7   | AsyncLocalStorage for Context | `#asynclocalstorage-for-context`       | Request context propagation                   |
| 8   | Testing                       | `#testing`                             | Type-safe mocks, fixtures, edge cases         |
| 9   | Error Handling                | `#error-handling`                      | Custom error classes                          |
| 10  | Function Design               | `#function-design-mandatory`           | Single responsibility                         |
| 11  | File Organization             | `#file-organization-mandatory`         | File-level SRP, max 200-300 lines             |
| 12  | Naming Conventions            | `#naming-conventions`                  | Files, interfaces, types                      |
| 13  | Directory Structure           | `#directory-structure`                 | Lerian pattern                                |
| 14  | RabbitMQ Worker Pattern       | `#rabbitmq-worker-pattern`             | Async message processing                      |
| 15  | Always-Valid Domain Model     | `#always-valid-domain-model-mandatory` | Constructor validation, invariant protection  |

---

### ring:frontend-bff-engineer-typescript → typescript.md

**Includes all backend-engineer-typescript sections PLUS 6 BFF-specific sections (21 total).**

| #   | Section to Check              | Anchor                                 | Key Subsections                                                            |
| --- | ----------------------------- | -------------------------------------- | -------------------------------------------------------------------------- |
| 1   | Version                       | `#version`                             | TypeScript 5.0+, Node.js 20+                                               |
| 2   | Strict Configuration          | `#strict-configuration-mandatory`      | tsconfig.json strict mode                                                  |
| 3   | Frameworks & Libraries        | `#frameworks--libraries`               | Express, Fastify, NestJS, Prisma, Zod, Vitest                              |
| 4   | Type Safety                   | `#type-safety`                         | No any, branded types, discriminated unions                                |
| 5   | Zod Validation Patterns       | `#zod-validation-patterns`             | Schema validation                                                          |
| 6   | Dependency Injection          | `#dependency-injection`                | TSyringe/Inversify patterns                                                |
| 7   | AsyncLocalStorage for Context | `#asynclocalstorage-for-context`       | Request context propagation                                                |
| 8   | Testing                       | `#testing`                             | Type-safe mocks, fixtures, edge cases                                      |
| 9   | Error Handling                | `#error-handling`                      | Custom error classes                                                       |
| 10  | Function Design               | `#function-design-mandatory`           | Single responsibility                                                      |
| 11  | File Organization             | `#file-organization-mandatory`         | File-level SRP, max 200-300 lines                                          |
| 12  | Naming Conventions            | `#naming-conventions`                  | Files, interfaces, types                                                   |
| 13  | Directory Structure           | `#directory-structure`                 | Lerian pattern                                                             |
| 14  | RabbitMQ Worker Pattern       | `#rabbitmq-worker-pattern`             | Async message processing                                                   |
| 15  | Always-Valid Domain Model     | `#always-valid-domain-model-mandatory` | Constructor validation                                                     |
| 16  | BFF Architecture Pattern      | `#bff-architecture-pattern-mandatory`  | **HARD GATE:** Clean Architecture, dual-mode (sindarian-server vs vanilla) |
| 17  | Three-Layer DTO Mapping       | `#three-layer-dto-mapping-mandatory`   | **HARD GATE:** HTTP ↔ Domain ↔ External DTOs, mappers                      |
| 18  | HttpService Lifecycle         | `#httpservice-lifecycle`               | createDefaults, onBeforeFetch, onAfterFetch, catch hooks                   |
| 19  | API Routes Pattern            | `#api-routes-pattern-mandatory`        | **⛔ FORBIDDEN:** Server Actions. MUST use Next.js API Routes              |
| 20  | Exception Hierarchy           | `#exception-hierarchy`                 | ApiException, GlobalExceptionFilter, typed exceptions                      |
| 21  | Cross-Cutting Decorators      | `#cross-cutting-decorators`            | LogOperation, Cached, Retry decorators                                     |

**⛔ HARD GATES for BFF Engineer:**

- Section 16: BFF is MANDATORY for all dynamic data
- Section 17: Three-layer mapping is MANDATORY, no pass-through
- Section 19: Server Actions are FORBIDDEN, API Routes only

---

### ring:frontend-engineer → frontend.md

| #   | Section to Check                | Anchor                             | Key Subsections                                                         |
| --- | ------------------------------- | ---------------------------------- | ----------------------------------------------------------------------- |
| 1   | Framework                       | `#framework`                       | React 18+, Next.js version policy                                       |
| 2   | Libraries & Tools               | `#libraries--tools`                | Core, state, forms, UI, styling, testing                                |
| 3   | State Management Patterns       | `#state-management-patterns`       | TanStack Query, Zustand                                                 |
| 4   | Form Patterns                   | `#form-patterns`                   | React Hook Form + Zod                                                   |
| 5   | Styling Standards               | `#styling-standards`               | TailwindCSS, CSS variables                                              |
| 6   | Typography Standards            | `#typography-standards`            | Font selection and pairing                                              |
| 7   | Animation Standards             | `#animation-standards`             | CSS transitions, Framer Motion                                          |
| 8   | Component Patterns              | `#component-patterns`              | Compound components, error boundaries                                   |
| 9   | File Organization               | `#file-organization-mandatory`     | File-level SRP, max 200 lines per component                            |
| 10  | Accessibility                   | `#accessibility`                   | WCAG 2.1 AA compliance                                                  |
| 11  | Performance                     | `#performance`                     | Code splitting, image optimization                                      |
| 12  | Directory Structure             | `#directory-structure`             | Next.js App Router layout                                               |
| 13  | Forbidden Patterns              | `#forbidden-patterns`              | Anti-patterns to avoid                                                  |
| 14  | Standards Compliance Categories | `#standards-compliance-categories` | Categories for ring:dev-refactor                                        |
| 15  | Form Field Abstraction Layer    | `#form-field-abstraction-layer`    | **HARD GATE:** Field wrappers, dual-mode (sindarian-ui vs vanilla)      |
| 16  | Provider Composition Pattern    | `#provider-composition-pattern`    | Nested providers order, feature providers                               |
| 17  | Custom Hooks Patterns           | `#custom-hooks-patterns`           | **HARD GATE:** usePagination, useCursorPagination, useCreateUpdateSheet |
| 18  | Core five Utilities Pattern       | `#fetcher-utilities-pattern`       | getCore five, postCore five, patchCore five, deleteCore five                    |
| 19  | Client-Side Error Handling      | `#client-side-error-handling`      | **HARD GATE:** ErrorBoundary, API error helpers, toast                  |
| 20  | Data Table Pattern              | `#data-table-pattern`              | TanStack Table, server-side pagination                                  |

**⛔ HARD GATES for Frontend Engineer:**

- Section 15: Form field abstraction is MANDATORY, direct input usage FORBIDDEN
- Section 17: Custom hooks MANDATORY for pagination and CRUD sheets
- Section 19: ErrorBoundary and API error handling MANDATORY

---

### ring:frontend-designer → frontend.md

**Same sections as ring:frontend-engineer (20 sections).** See above.

---

### ring:ui-engineer → frontend.md

**Same sections as ring:frontend-engineer (20 sections).** See above.

**Additional ui-engineer requirements:**
The ring:ui-engineer MUST also validate against product-designer outputs:

| #   | Additional Check         | Source              | Required                       |
| --- | ------------------------ | ------------------- | ------------------------------ |
| 1   | UX Criteria Compliance   | `ux-criteria.md`    | All criteria satisfied         |
| 2   | User Flow Implementation | `user-flows.md`     | All flows implemented          |
| 3   | Wireframe Adherence      | `wireframes/*.yaml` | All specs implemented          |
| 4   | UI States Coverage       | `ux-criteria.md`    | Loading, error, empty, success |

**Output Format for ring:ui-engineer:**
In addition to the standard Coverage Table, ring:ui-engineer MUST output:

```markdown
## UX Criteria Compliance

| Criterion             | Status | Evidence  |
| --------------------- | ------ | --------- |
| [From ux-criteria.md] | ✅/❌  | file:line |
```

---

### ring:devops-engineer → devops.md

| #   | Section to Check                   | Subsections (all REQUIRED)                                                                 |
| --- | ---------------------------------- | ------------------------------------------------------------------------------------------ |
| 1   | Cloud Provider (MANDATORY)         | Provider table                                                                             |
| 2   | Infrastructure as Code (MANDATORY) | Terraform structure, State management, Module pattern, Best practices                      |
| 3   | Containers (MANDATORY)             | **Dockerfile patterns, Docker Compose (Local Dev), .env file**, Image guidelines           |
| 4   | Helm (MANDATORY)                   | General chart structure, Chart.yaml, values.yaml, [Lerian Helm Standards](../../docs/standards/helm/index.md) (delegate to ring:helm-engineer) |
| 5   | Observability (MANDATORY)          | Logging (Structured JSON), Tracing (OpenTelemetry)                                         |
| 6   | Security (MANDATORY)               | Secrets management, Network policies                                                       |
| 7   | Makefile Standards (MANDATORY)     | Required commands (build, lint, test, cover, up, down, etc.), Component delegation pattern |
| 8   | CI/CD Pipeline (MANDATORY)         | Pipeline stages (lint, test, security, build), branch protection, required checks          |

**⛔ HARD GATE:** When checking "Containers", you MUST verify BOTH Dockerfile and Docker Compose patterns. Checking only one = INCOMPLETE.

**⛔ HARD GATE:** When checking "Makefile Standards", you MUST verify all required commands exist: `build`, `lint`, `test`, `cover`, `up`, `down`, `start`, `stop`, `restart`, `rebuild-up`, `set-env`, `generate-docs`.

---

### ring:sre → sre.md

| #   | Section to Check                      | Anchor                                                            |
| --- | ------------------------------------- | ----------------------------------------------------------------- |
| 1   | Observability                         | `#observability`                                                  |
| 2   | Logging                               | `#logging`                                                        |
| 3   | Tracing                               | `#tracing`                                                        |
| 4   | OpenTelemetry with lib-commons        | `#opentelemetry-with-lib-commons-mandatory-for-go`                |
| 5   | Structured Logging with lib-common-js | `#structured-logging-with-lib-common-js-mandatory-for-typescript` |
| 6   | Health Checks                         | `#health-checks`                                                  |

---

### ring:qa-analyst → testing-unit.md (Unit Mode - Gate 3)

**Mode Detection:** `test_mode: unit` passed when invoking `Task(subagent_type="ring:qa-analyst", test_mode="unit")`

**For Go projects (Unit Mode):**
| # | Section to Check | Anchor |
|---|------------------|--------|
| UNIT-1 | Table-Driven Tests (MANDATORY) | `#table-driven-tests-mandatory` |
| UNIT-2 | Test Naming Convention (MANDATORY) | `#test-naming-convention-mandatory` |
| UNIT-3 | Parallel Test Execution (MANDATORY) | `#parallel-test-execution-mandatory` |
| UNIT-4 | Loop Variable Capture (MANDATORY) | `#loop-variable-capture-mandatory` |
| UNIT-5 | Edge Case Coverage (MANDATORY) | `#edge-case-coverage-mandatory` |
| UNIT-6 | Assertion Requirements (MANDATORY) | `#assertion-requirements-mandatory` |
| UNIT-7 | Mock Generation (MANDATORY) | `#mock-generation-mandatory` |
| UNIT-8 | Environment Variables in Tests (MANDATORY) | `#environment-variables-in-tests-mandatory` |
| UNIT-9 | Shared Test Utilities (MANDATORY) | `#shared-test-utilities-mandatory` |
| UNIT-10 | Unit Test Scope & Boundaries (MANDATORY) | `#unit-test-scope--boundaries-mandatory` |
| UNIT-11 | Unit Test Quality Gate (MANDATORY) | `#unit-test-quality-gate-mandatory` |

**For TypeScript projects (Unit Mode):**
| # | Section to Check |
|---|------------------|
| 1 | Testing Patterns (MANDATORY) |
| 2 | Edge Case Coverage (MANDATORY) |
| 3 | Type Safety Rules (MANDATORY) |

**Unit Test Quality Gate Checks (Gate 3 Exit - all REQUIRED):**
| # | Check | Detection |
|---|-------|-----------|
| 1 | Table-driven pattern | All tests use `tests := []struct` pattern |
| 2 | t.Parallel() | `grep "t.Parallel()"` at function and subtest level |
| 3 | Loop variable capture | `tt := tt` before each `t.Run()` |
| 4 | Strong error assertions | No empty `errContains` fields |
| 5 | Response type verification | `assert.IsType()` for success cases |
| 6 | GoMock usage | No hand-written mocks |
| 7 | t.Setenv | No `os.Setenv` in test files |
| 8 | Shared utilities | No local `Ptr` or duplicate helpers |
| 9 | Edge cases | ≥3 per acceptance criterion |
| 10 | No flaky tests | 3x consecutive pass |

---

### ring:qa-analyst → testing-fuzz.md (Fuzz Mode - Gate 4)

**Mode Detection:** `test_mode: fuzz` passed when invoking `Task(subagent_type="ring:qa-analyst", test_mode="fuzz")`

**For Go projects (Fuzz Mode):**
| # | Section to Check | Anchor |
|---|------------------|--------|
| FUZZ-1 | What Is Fuzz Testing | `#what-is-fuzz-testing` |
| FUZZ-2 | Fuzz Function Pattern (MANDATORY) | `#fuzz-function-pattern-mandatory` |
| FUZZ-3 | Seed Corpus (MANDATORY) | `#seed-corpus-mandatory` |
| FUZZ-4 | Input Types | `#input-types` |
| FUZZ-5 | Fuzz Test Quality Gate (MANDATORY) | `#fuzz-test-quality-gate-mandatory` |

**Fuzz Test Quality Gate Checks (Gate 4 Exit - all REQUIRED):**
| # | Check | Detection |
|---|-------|-----------|
| 1 | Naming convention | `func FuzzXxx(f *testing.F)` format |
| 2 | Seed corpus | `f.Add()` with ≥5 entries |
| 3 | Test passes | `go test -fuzz=. -fuzztime=30s` |

---

### ring:qa-analyst → testing-property.md (Property Mode - Gate 5)

**Mode Detection:** `test_mode: property` passed when invoking `Task(subagent_type="ring:qa-analyst", test_mode="property")`

**For Go projects (Property Mode):**
| # | Section to Check | Anchor |
|---|------------------|--------|
| PROP-1 | What Is Property-Based Testing | `#what-is-property-based-testing` |
| PROP-2 | Property Function Pattern (MANDATORY) | `#property-function-pattern-mandatory` |
| PROP-3 | Common Properties | `#common-properties` |
| PROP-4 | Integration with Unit Tests | `#integration-with-unit-tests` |
| PROP-5 | Property Test Quality Gate (MANDATORY) | `#property-test-quality-gate-mandatory` |

**Property Test Quality Gate Checks (Gate 5 Exit - all REQUIRED):**
| # | Check | Detection |
|---|-------|-----------|
| 1 | Naming convention | `TestProperty_{Subject}_{Property}` format |
| 2 | quick.Check usage | `testing/quick.Check` imported and used |
| 3 | Domain invariants | At least 1 property per domain entity |

---

### ring:qa-analyst → testing-integration.md (Integration Mode - Gate 6)

**Mode Detection:** `test_mode: integration` passed when invoking `Task(subagent_type="ring:qa-analyst", test_mode="integration")`

**For Go projects (Integration Mode):**
| # | Section to Check | Anchor |
|---|------------------|--------|
| INT-1 | Test Pyramid | `#test-pyramid` |
| INT-2 | File Naming Convention (MANDATORY) | `#file-naming-convention-mandatory` |
| INT-3 | Function Naming Convention (MANDATORY) | `#function-naming-convention-mandatory` |
| INT-4 | Build Tags (MANDATORY) | `#build-tags-mandatory` |
| INT-5 | Testcontainers Patterns (MANDATORY) | `#testcontainers-patterns-mandatory` |
| INT-6 | Parallel Test Prohibition (MANDATORY) | `#parallel-test-prohibition-mandatory` |
| INT-7 | Fixture Centralization (MANDATORY) | `#fixture-centralization-mandatory` |
| INT-8 | Stub Centralization (MANDATORY) | `#stub-centralization-mandatory` |
| INT-9 | Guardrails (11 Anti-Patterns) (MANDATORY) | `#guardrails-11-anti-patterns-mandatory` |
| INT-10 | Test Failure Analysis (No Greenwashing) | `#test-failure-analysis-no-greenwashing` |

**Integration Test Quality Gate Checks (Gate 6 Exit - all REQUIRED):**
| # | Check | Detection |
|---|-------|-----------|
| 1 | Build tag present | `//go:build integration` at top of file |
| 2 | No hardcoded ports | `grep ":5432\|:6379"` = 0 |
| 3 | Testcontainers used | import check for testcontainers |
| 4 | No t.Parallel() | `grep "t.Parallel()"` in integration tests = 0 |
| 5 | Cleanup present | `t.Cleanup()` for all containers |
| 6 | No flaky tests | 3x consecutive pass |

---

### ring:qa-analyst → testing-chaos.md (Chaos Mode - Gate 7)

**Mode Detection:** `test_mode: chaos` passed when invoking `Task(subagent_type="ring:qa-analyst", test_mode="chaos")`

**For Go projects (Chaos Mode):**
| # | Section to Check | Anchor |
|---|------------------|--------|
| CHAOS-1 | What Is Chaos Testing | `#what-is-chaos-testing` |
| CHAOS-2 | Chaos Test Pattern (MANDATORY) | `#chaos-test-pattern-mandatory` |
| CHAOS-3 | Failure Scenarios | `#failure-scenarios` |
| CHAOS-4 | Infrastructure Setup | `#infrastructure-setup` |
| CHAOS-5 | Chaos Test Quality Gate (MANDATORY) | `#chaos-test-quality-gate-mandatory` |

**Chaos Test Quality Gate Checks (Gate 7 Exit - all REQUIRED):**
| # | Check | Detection |
|---|-------|-----------|
| 1 | Dual-gate pattern | `CHAOS=1` env check + `testing.Short()` |
| 2 | Naming convention | `TestIntegration_Chaos_{Component}_{Scenario}` |
| 3 | 5-phase structure | Normal → Inject → Verify → Restore → Recovery |
| 4 | Toxiproxy usage | `tests/utils/chaos/` infrastructure |
| 5 | All deps covered | Chaos test for each external dependency |

---

### ring:qa-analyst-frontend → frontend/testing-*.md

**Mode Detection:** `test_mode` parameter determines which standards to load.

| # | Section to Check | Mode | File |
|---|------------------|------|------|
| ACC-1 | axe-core Integration | accessibility | testing-accessibility.md |
| ACC-2 | Semantic HTML Verification | accessibility | testing-accessibility.md |
| ACC-3 | Keyboard Navigation | accessibility | testing-accessibility.md |
| ACC-4 | Focus Management | accessibility | testing-accessibility.md |
| ACC-5 | Color Contrast | accessibility | testing-accessibility.md |
| VIS-1 | Snapshot Testing Patterns | visual | testing-visual.md |
| VIS-2 | States Coverage | visual | testing-visual.md |
| VIS-3 | Responsive Snapshots | visual | testing-visual.md |
| VIS-4 | Component Duplication Check | visual | testing-visual.md |
| E2E-1 | User Flow Consumption | e2e | testing-e2e.md |
| E2E-2 | Error Path Testing | e2e | testing-e2e.md |
| E2E-3 | Cross-Browser Testing | e2e | testing-e2e.md |
| E2E-4 | Responsive E2E | e2e | testing-e2e.md |
| E2E-5 | Selector Strategy | e2e | testing-e2e.md |
| PERF-1 | Core Web Vitals | performance | testing-performance.md |
| PERF-2 | Lighthouse Score | performance | testing-performance.md |
| PERF-3 | Bundle Analysis | performance | testing-performance.md |
| PERF-4 | Server Component Audit | performance | testing-performance.md |
| PERF-5 | Anti-Pattern Detection | performance | testing-performance.md |

---

## Maintenance Instructions

**When you add/modify a section in a standards file:**

1. Edit `dev-team/docs/standards/{file}.md` - Add your new `## Section Name`
2. Edit THIS file - Add the section to the corresponding agent table above
3. Verify row count matches section count

**Anti-Rationalization:**

| Rationalization                   | Why It's WRONG                                     | Required Action                      |
| --------------------------------- | -------------------------------------------------- | ------------------------------------ |
| "I'll update the index later"     | Later = never. Sync drift causes missed checks.    | **Update BOTH files in same commit** |
| "The section is minor"            | Minor ≠ optional. All sections must be indexed.    | **Add to index regardless of size**  |
| "Agents parse dynamically anyway" | Index is the explicit contract. Dynamic is backup. | **Index is source of truth**         |
