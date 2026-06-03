## Consolidated Report Template (Thorough)

<report-template-mandate>
MANDATORY: This template MUST be followed exactly as written. every section is REQUIRED — do not abbreviate, summarize, condense, or skip any section. The report MUST provide exhaustive detail for each dimension, with every issue fully documented including file location, code evidence, impact analysis, and remediation guidance. Omitting sections or reducing detail is FORBIDDEN regardless of the number of findings.
</report-template-mandate>

After all explorers complete, generate this report:

```markdown
# Production Readiness Audit Report

> **THOROUGH AUDIT** — This report provides exhaustive findings across all audited dimensions.
> every issue is documented with file location, evidence, impact analysis, and remediation guidance.

**Date:** {YYYY-MM-DDTHH:MM:SS}
**Codebase:** {project-name}
**Auditor:** Claude Code (Production Readiness Skill v3.0)
**Report Type:** Thorough

---

## Dashboard

| Overall Score | Classification | Critical | High | Medium | Low | HARD GATE Violations |
|:-------------:|:--------------:|:--------:|:----:|:------:|:---:|:--------------------:|
| **{score}/{dynamic_max} ({pct}%)** | **{classification}** | **{n}** | **{n}** | **{n}** | **{n}** | **{n}** |

### Readiness Classification

| Score Range | Classification | Deployment Recommendation |
|:-----------:|:--------------:|:-------------------------:|
| 90%+ | **Production Ready** | Clear to deploy |
| 75-89% | **Ready with Minor Remediation** | Deploy after addressing HIGH issues |
| 50-74% | **Needs Significant Work** | Do not deploy until CRITICAL/HIGH resolved |
| Below 50% | **Not Production Ready** | Major remediation required |

> **Current Status:** {classification} — {one-sentence summary of overall production readiness posture}

---

## Audit Configuration

| Property | Value |
|----------|-------|
| **Detected Stack** | {Go / TypeScript / Frontend / Mixed} |
| **Standards Loaded** | {list of loaded standards files} |
| **Active Dimensions** | {43 base + 1 conditional (max 44)} |
| **Max Possible Score** | {dynamic_max: 430 or 440} |
| **Conditional: Multi-Tenant** | {Active / Inactive} |

---

## Category Scoreboard

| Category | Score | % | Critical | High | Medium | Low | Status |
|:---------|------:|--:|:--------:|:----:|:------:|:---:|:------:|
| **A: Code Structure & Patterns** | {x}/110 | {pct}% | {n} | {n} | {n} | {n} | {PASS/NEEDS WORK/FAIL} |
| **B: Security & Access Control** | {x}/{90 or 100} | {pct}% | {n} | {n} | {n} | {n} | {PASS/NEEDS WORK/FAIL} |
| **C: Operational Readiness** | {x}/70 | {pct}% | {n} | {n} | {n} | {n} | {PASS/NEEDS WORK/FAIL} |
| **D: Quality & Maintainability** | {x}/100 | {pct}% | {n} | {n} | {n} | {n} | {PASS/NEEDS WORK/FAIL} |
| **E: Infrastructure & Hardening** | {x}/60 | {pct}% | {n} | {n} | {n} | {n} | {PASS/NEEDS WORK/FAIL} |
| **TOTAL** | **{x}/{dynamic_max}** | **{pct}%** | **{n}** | **{n}** | **{n}** | **{n}** | — |

Category status: PASS (>=70%), NEEDS WORK (40-69%), FAIL (<40%)

### Dimension Scores at a Glance

| # | Dimension | Score | Status | # | Dimension | Score | Status |
|---|-----------|:-----:|:------:|---|-----------|:-----:|:------:|
| 1 | Pagination Standards | {x}/10 | {icon} | 18 | Technical Debt | {x}/10 | {icon} |
| 2 | Error Framework | {x}/10 | {icon} | 19 | Testing Coverage | {x}/10 | {icon} |
| 3 | Route Organization | {x}/10 | {icon} | 20 | Dependency Mgmt | {x}/10 | {icon} |
| 4 | Bootstrap & Init | {x}/10 | {icon} | 21 | Performance | {x}/10 | {icon} |
| 5 | Runtime Safety | {x}/10 | {icon} | 22 | Concurrency | {x}/10 | {icon} |
| 6 | Auth Protection | {x}/10 | {icon} | 23 | Migrations | {x}/10 | {icon} |
| 7 | IDOR Protection | {x}/10 | {icon} | 24 | Container Security | {x}/10 | {icon} |
| 8 | SQL Safety | {x}/10 | {icon} | 25 | HTTP Hardening | {x}/10 | {icon} |
| 9 | Input Validation | {x}/10 | {icon} | 26 | CI/CD Pipeline | {x}/10 | {icon} |
| 11 | Telemetry | {x}/10 | {icon} | 28 | Core Dependencies | {x}/10 | {icon} |
| 12 | Health Checks | {x}/10 | {icon} | 29 | Naming Conventions | {x}/10 | {icon} |
| 13 | Configuration | {x}/10 | {icon} | 30 | Domain Modeling | {x}/10 | {icon} |
| 14 | Connections | {x}/10 | {icon} | 31 | Linting & Quality | {x}/10 | {icon} |
| 15 | Logging & PII | {x}/10 | {icon} | 32 | Makefile & Tooling | {x}/10 | {icon} |
| 16 | Idempotency | {x}/10 | {icon} | 33* | Multi-Tenant | {x}/10 | {icon} |
| 17 | API Documentation | {x}/10 | {icon} | 34 | License Headers | {x}/10 | {icon} |
| 35 | Nil/Null Safety | {x}/10 | {icon} | 36 | Resilience Patterns | {x}/10 | {icon} |
| 37 | Secret Scanning | {x}/10 | {icon} | 38 | API Versioning | {x}/10 | {icon} |
| 39 | Graceful Degradation | {x}/10 | {icon} | 40 | Caching Patterns | {x}/10 | {icon} |
| 41 | Data Encryption | {x}/10 | {icon} | 42 | Resource Leaks | {x}/10 | {icon} |
| 43 | Rate Limiting | {x}/10 | {icon} | 44 | CORS Configuration | {x}/10 | {icon} |

Status icons: PASS (>=7), WARN (4-6), FAIL (<4), N/A (conditional not active)
*33 = conditional dimension (Multi-Tenant) — included only if multi-tenant indicators detected*

---

## HARD GATE Violations

> HARD GATE violations are non-negotiable Ring standards failures that MUST be resolved before any deployment consideration. These represent structural non-compliance, not just quality gaps.

{If no violations: "No HARD GATE violations detected."}

{If violations exist:}

| # | Dimension | Violation | Location | Standards Reference |
|---|-----------|-----------|----------|---------------------|
| 1 | {dimension name} | {description of standards violation} | `{file:line}` | {standards-file.md} § {section} |

---

## Critical Blockers (Must Fix Before Production)

> These issues represent immediate risks to production safety, security, or data integrity. Deployment MUST NOT proceed until all CRITICAL issues are resolved.

{If no critical issues: "No critical blockers identified. All dimensions passed critical-level checks."}

{For each CRITICAL issue — MUST include all fields:}

### CB-{n}: {Short descriptive issue title}

| Property | Value |
|----------|-------|
| **Dimension** | #{num}. {Dimension Name} |
| **Category** | {A/B/C/D/E}: {Category Name} |
| **Severity** | CRITICAL |
| **Location** | `{file:line}` |
| **Standards Reference** | {standards-file.md} § {section name} |
| **HARD GATE Violation** | {Yes / No} |

**Description:**
{Detailed explanation of the issue — what is wrong and why it matters. Minimum 2-3 sentences.}

**Evidence:**
```{language}
// {file}:{line}
{relevant code snippet showing the problem — include enough context to understand the issue}
```

**Impact:**
{What could go wrong in production if this is not fixed. Be specific about failure modes, data risks, or security implications.}

**Recommended Fix:**
```{language}
// {file}:{line} — suggested change
{code showing the corrected approach aligned with Ring standards}
```

---

## High Priority Issues

> These issues represent significant risks or standards non-compliance. Address before production deployment or within the current sprint.

{If no high issues: "No high priority issues identified."}

{For each HIGH issue — MUST include all fields:}

### HP-{n}: {Short descriptive issue title}

| Property | Value |
|----------|-------|
| **Dimension** | #{num}. {Dimension Name} |
| **Category** | {A/B/C/D/E}: {Category Name} |
| **Severity** | HIGH |
| **Location** | `{file:line}` |
| **Standards Reference** | {standards-file.md} § {section name} |

**Description:**
{Detailed explanation of the issue. Minimum 2-3 sentences.}

**Evidence:**
```{language}
// {file}:{line}
{relevant code snippet showing the problem}
```

**Impact:**
{Production impact if not addressed.}

**Recommended Fix:**
```{language}
// {file}:{line} — suggested change
{code showing the corrected approach}
```

---

## Detailed Findings by Category

> This section provides exhaustive per-dimension findings. every dimension MUST include: a score breakdown, all issues organized by severity (CRITICAL first, then HIGH, MEDIUM, LOW), and code evidence for each issue. Do not skip any dimension.

---

### Category A: Code Structure & Patterns ({x}/110)

---

#### Dimension 1: Pagination Standards

| Property | Value |
|----------|-------|
| **Score** | **{x}/10** |
| **Status** | {PASS (>=7) / WARN (4-6) / FAIL (<4)} |
| **Standards Source** | api-patterns.md § Pagination Patterns |
| **Issues Found** | {n} Critical, {n} High, {n} Medium, {n} Low |

**Summary:**
{2-3 sentence summary of the dimension's overall compliance. Describe what was checked, what the predominant pattern is, and the key gap (if any).}

{For each severity level that has issues, in order CRITICAL → HIGH → MEDIUM → LOW. Omit empty severity sections.}

##### CRITICAL Issues

| # | Location | Issue | HARD GATE | Standards Ref |
|---|----------|-------|:---------:|---------------|
| C1 | `{file:line}` | {brief description} | {Yes/No} | {section ref} |

**C1: {Issue title}**

- **Description:** {What is wrong and why it violates standards}
- **Evidence:**
  ```{language}
  // {file}:{line}
  {code showing the problem}
  ```
- **Impact:** {Production risk}
- **Recommended Fix:**
  ```{language}
  {corrected code}
  ```

##### HIGH Issues

| # | Location | Issue | Standards Ref |
|---|----------|-------|---------------|
| H1 | `{file:line}` | {brief description} | {section ref} |

**H1: {Issue title}**

- **Description:** {What is wrong}
- **Evidence:**
  ```{language}
  // {file}:{line}
  {code showing the problem}
  ```
- **Impact:** {Risk if not addressed}
- **Recommended Fix:**
  ```{language}
  {corrected code}
  ```

##### MEDIUM Issues

| # | Location | Issue | Standards Ref |
|---|----------|-------|---------------|
| M1 | `{file:line}` | {brief description} | {section ref} |

**M1: {Issue title}**
- **Description:** {What is wrong}
- **Evidence:** `{file}:{line}` — {brief code reference or description}
- **Recommended Fix:** {Brief guidance on how to align with standards}

##### LOW Issues

| # | Location | Issue |
|---|----------|-------|
| L1 | `{file:line}` | {brief description} |

- **L1:** {One-line description with fix guidance}

#### Dimension 2: Error Framework

{SAME structure as Dimension 1 — property table, summary, severity-grouped issues}

---

#### Dimension 3: Route Organization

{SAME structure}

---

#### Dimension 4: Bootstrap & Initialization

{SAME structure}

---

#### Dimension 5: Runtime Safety

{SAME structure}

---

#### Dimension 28: Core Dependencies & Frameworks

{SAME structure}

---

#### Dimension 29: Naming Conventions

{SAME structure}

---

#### Dimension 30: Domain Modeling

{SAME structure}

---

#### Dimension 35: Nil/Null Safety

{SAME structure as Dimension 1}

---

#### Dimension 38: API Versioning

{SAME structure as Dimension 1}

---

#### Dimension 42: Resource Leak Prevention

{SAME structure as Dimension 1}

---

### Category B: Security & Access Control ({x}/{90 or 100})

---

#### Dimension 6: Auth Protection

{SAME structure as Dimension 1}

---

#### Dimension 7: IDOR & Access Control

{SAME structure}

---

#### Dimension 8: SQL Safety

{SAME structure}

---

#### Dimension 9: Input Validation

{SAME structure}

---

#### Dimension 37: Secret Scanning

{SAME structure as Dimension 1}

---

#### Dimension 41: Data Encryption at Rest

{SAME structure as Dimension 1}

---

#### Dimension 43: Rate Limiting

{SAME structure as Dimension 1}

---

#### Dimension 44: CORS Configuration

{SAME structure as Dimension 1}

---

#### Dimension 33: Multi-Tenant Patterns *(CONDITIONAL)*

{If MULTI_TENANT=false: "**Dimension not activated** — No multi-tenant indicators detected in this codebase. Score excluded from total."}

{If MULTI_TENANT=true: SAME structure as Dimension 1}

---

### Category C: Operational Readiness ({x}/70)

---

#### Dimension 11: Telemetry & Observability

{SAME structure as Dimension 1}

---

#### Dimension 12: Health Checks

{SAME structure}

---

#### Dimension 13: Configuration Management

{SAME structure}

---

#### Dimension 14: Connection Management

{SAME structure}

---

#### Dimension 15: Logging & PII Safety

{SAME structure}

---

#### Dimension 36: Resilience Patterns

{SAME structure as Dimension 1}

---

#### Dimension 39: Graceful Degradation

{SAME structure as Dimension 1}

---

### Category D: Quality & Maintainability ({x}/100)

---

#### Dimension 16: Idempotency

{SAME structure as Dimension 1}

---

#### Dimension 17: API Documentation

{SAME structure}

---

#### Dimension 18: Technical Debt

{SAME structure}

---

#### Dimension 19: Testing Coverage

{SAME structure}

---

#### Dimension 20: Dependency Management

{SAME structure}

---

#### Dimension 21: Performance Patterns

{SAME structure}

---

#### Dimension 22: Concurrency Safety

{SAME structure}

---

#### Dimension 23: Migration Safety

{SAME structure}

---

#### Dimension 31: Linting & Code Quality

{SAME structure}

---

#### Dimension 40: Caching Patterns

{SAME structure as Dimension 1}

---

### Category E: Infrastructure & Hardening ({x}/60)

---

#### Dimension 24: Container Security

{SAME structure as Dimension 1}

---

#### Dimension 25: HTTP Hardening

{SAME structure}

---

#### Dimension 26: CI/CD Pipeline

{SAME structure}

---

#### Dimension 27: Async Reliability

{SAME structure}

---

#### Dimension 32: Makefile & Dev Tooling

{SAME structure}

---

#### Dimension 34: License Headers

{SAME structure as Dimension 1 — if no LICENSE file exists, all items reported as N/A with evidence}

---

## Standards Compliance Cross-Reference

| # | Dimension | Standards Source | Section | Status | Score |
|---|-----------|----------------|---------|:------:|------:|
| 1 | Pagination Standards | api-patterns.md | Pagination Patterns | {PASS/FAIL} | {x}/10 |
| 2 | Error Framework | domain.md | Error Codes, Error Handling | {PASS/FAIL} | {x}/10 |
| 3 | Route Organization | architecture.md | Architecture Patterns, Directory Structure | {PASS/FAIL} | {x}/10 |
| 4 | Bootstrap & Initialization | bootstrap.md | Bootstrap | {PASS/FAIL} | {x}/10 |
| 5 | Runtime Safety | (generic) | — | {PASS/FAIL} | {x}/10 |
| 6 | Auth Protection | security.md | Access Manager Integration | {PASS/FAIL} | {x}/10 |
| 7 | IDOR & Access Control | (generic) | — | {PASS/FAIL} | {x}/10 |
| 8 | SQL Safety | (generic) | — | {PASS/FAIL} | {x}/10 |
| 9 | Input Validation | core.md | Frameworks & Libraries | {PASS/FAIL} | {x}/10 |
| 11 | Telemetry & Observability | bootstrap.md + sre.md | Observability, OpenTelemetry | {PASS/FAIL} | {x}/10 |
| 12 | Health Checks | sre.md | Health Checks | {PASS/FAIL} | {x}/10 |
| 13 | Configuration Management | core.md | Configuration | {PASS/FAIL} | {x}/10 |
| 14 | Connection Management | core.md | Core Dependency: lib-commons | {PASS/FAIL} | {x}/10 |
| 15 | Logging & PII Safety | quality.md | Logging | {PASS/FAIL} | {x}/10 |
| 16 | Idempotency | idempotency.md | Full module | {PASS/FAIL} | {x}/10 |
| 17 | API Documentation | api-patterns.md | OpenAPI (Swaggo) | {PASS/FAIL} | {x}/10 |
| 18 | Technical Debt | (generic) | — | {PASS/FAIL} | {x}/10 |
| 19 | Testing Coverage | quality.md | Testing | {PASS/FAIL} | {x}/10 |
| 20 | Dependency Management | core.md | Frameworks & Libraries | {PASS/FAIL} | {x}/10 |
| 21 | Performance Patterns | (generic) | — | {PASS/FAIL} | {x}/10 |
| 22 | Concurrency Safety | architecture.md | Concurrency Patterns | {PASS/FAIL} | {x}/10 |
| 23 | Migration Safety | core.md | Database patterns | {PASS/FAIL} | {x}/10 |
| 24 | Container Security | devops.md | Containers | {PASS/FAIL} | {x}/10 |
| 25 | HTTP Hardening | (generic) | — | {PASS/FAIL} | {x}/10 |
| 26 | CI/CD Pipeline | devops.md | CI section | {PASS/FAIL} | {x}/10 |
| 27 | Async Reliability | messaging.md | RabbitMQ Worker Pattern | {PASS/FAIL} | {x}/10 |
| 28 | Core Dependencies | core.md | lib-commons, Frameworks | {PASS/FAIL} | {x}/10 |
| 29 | Naming Conventions | core.md + api-patterns.md | Naming conventions | {PASS/FAIL} | {x}/10 |
| 30 | Domain Modeling | domain.md + domain-modeling.md | ToEntity, Always-Valid | {PASS/FAIL} | {x}/10 |
| 31 | Linting & Code Quality | quality.md | Linting | {PASS/FAIL} | {x}/10 |
| 32 | Makefile & Dev Tooling | devops.md | Makefile Standards | {PASS/FAIL} | {x}/10 |
| 35 | Nil/Null Safety | (nil-safety-reviewer) | Nil Patterns | {PASS/FAIL} | {x}/10 |
| 36 | Resilience Patterns | (generic) | Resilience Patterns | {PASS/FAIL} | {x}/10 |
| 37 | Secret Scanning | (generic) | Secret Detection | {PASS/FAIL} | {x}/10 |
| 38 | API Versioning | api-patterns.md | API Versioning | {PASS/FAIL} | {x}/10 |
| 39 | Graceful Degradation | (generic) | Degradation Patterns | {PASS/FAIL} | {x}/10 |
| 40 | Caching Patterns | (generic) | Cache Management | {PASS/FAIL} | {x}/10 |
| 41 | Data Encryption | security.md | Encryption at Rest | {PASS/FAIL} | {x}/10 |
| 42 | Resource Leaks | (generic) | Resource Lifecycle | {PASS/FAIL} | {x}/10 |
| 43 | Rate Limiting | security.md | Rate Limiting | {PASS/FAIL} | {x}/10 |
| 44 | CORS Configuration | security.md | CORS Configuration | {PASS/FAIL} | {x}/10 |
| 33 | Multi-Tenant Patterns | multi-tenant.md | Full module | {PASS/FAIL/N/A} | {x}/10 |
| 34 | License Headers | core.md | License section | {PASS/FAIL/N/A} | {x}/10 |

*Dimension 33 is conditional — excluded from scoring when MULTI_TENANT=false*

---

## Issue Index by Severity

> Complete cross-cutting index of all issues found across all dimensions, grouped by severity. Use this for quick reference and remediation tracking.

### All CRITICAL Issues ({total_count})

| # | ID | Dimension | Category | Location | Issue | HARD GATE |
|---|----|-----------|----------|----------|-------|:---------:|
| 1 | CB-1 | {dimension} | {cat} | `{file:line}` | {description} | {Yes/No} |

### All HIGH Issues ({total_count})

| # | ID | Dimension | Category | Location | Issue |
|---|----|-----------|----------|----------|-------|
| 1 | HP-1 | {dimension} | {cat} | `{file:line}` | {description} |

### All MEDIUM Issues ({total_count})

| # | Dimension | Category | Location | Issue |
|---|-----------|----------|----------|-------|
| 1 | {dimension} | {cat} | `{file:line}` | {description} |

### All LOW Issues ({total_count})

| # | Dimension | Category | Location | Issue |
|---|-----------|----------|----------|-------|
| 1 | {dimension} | {cat} | `{file:line}` | {description} |

---

## Remediation Roadmap

> Prioritized action plan organized by urgency. Each phase includes estimated effort to help with sprint planning.

### Phase 1: Immediate (before any deployment)

> Blocking issues that MUST be resolved before production. These are CRITICAL severity items and HARD GATE violations.

| Priority | ID | Dimension | Issue | Estimated Effort |
|:--------:|----|-----------|-------|:----------------:|
| 1 | CB-{n} | {dimension} | {short description} | {hours}h |

**Phase 1 Total Estimated Effort:** {X} hours

### Phase 2: Short-term (within 1 sprint)

> HIGH severity items to address in the current or next sprint before considering the system production-stable.

| Priority | ID | Dimension | Issue | Estimated Effort |
|:--------:|----|-----------|-------|:----------------:|
| 1 | HP-{n} | {dimension} | {short description} | {hours}h |

**Phase 2 Total Estimated Effort:** {X} hours

### Phase 3: Medium-term (within 1 quarter)

> MEDIUM severity improvements to plan for upcoming sprints. These improve compliance and reduce technical debt.

| Priority | Dimension | Issue | Estimated Effort |
|:--------:|-----------|-------|:----------------:|
| 1 | {dimension} | {short description} | {hours}h |

**Phase 3 Total Estimated Effort:** {X} hours

### Phase 4: Backlog (track but do not block deployment)

> LOW severity enhancements. Create tickets in issue tracker for future consideration.

| Dimension | Issue |
|-----------|-------|
| {dimension} | {short description} |

---

## Appendix A: Files Audited

| # | File Path | Lines | Dimensions That Examined It |
|---|-----------|------:|:---------------------------|
| 1 | `{file path}` | {n} | {comma-separated dimension numbers} |

**Total:** {n} files, {n} lines of code audited

---

## Appendix B: Audit Metadata

| Property | Value |
|----------|-------|
| **Audit Date** | {YYYY-MM-DD HH:MM} |
| **Audit Duration** | {X} minutes |
| **Explorers Launched** | {43 or 44} |
| **Files Examined** | {X} |
| **Lines of Code** | {X} |
| **Skill Version** | 3.0 |
| **Report Type** | Thorough |
| **Standards Source** | Ring Development Standards (GitHub) |
| **Standards Files Loaded** | {list} |
| **Stack Detected** | {Go / TypeScript / Frontend / Mixed} |
| **Dimensions** | {43 + conditional count} |

---

## CONDITIONAL DIMENSION (Multi-Tenant)

### Agent 33: Multi-Tenant Patterns Auditor *(CONDITIONAL)*

```prompt
CONDITIONAL: Only run this agent if MULTI_TENANT=true was detected during stack detection. If the project does not use multi-tenancy (no tenant config, no pool manager, no tenant middleware), SKIP this agent entirely and report: "Dimension 33 skipped — single-tenant project (no multi-tenant indicators detected)."

If multi-tenant IS detected, audit multi-tenant architecture patterns for production readiness against the COMPLETE canonical model defined in multi-tenant.md.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: Full multi-tenant.md standard}
---END STANDARDS---

**Search Patterns:**
- Files: `**/tenant*.go`, `**/pool*.go`, `**/middleware*.go`, `**/context*.go`
- Keywords: `tenantID`, `TenantManager`, `TenantContext`, `schema`, `search_path`
- Also search: `**/jwt*.go`, `**/auth*.go` for tenant extraction
- Config files: `**/config.go`, `**/bootstrap/*.go` for env var declarations
- Routes: `**/routes.go`, `**/router*.go` for middleware ordering
- Redis: `**/redis*.go`, `**/*redis*` for key prefixing (including Lua scripts)
- S3/Storage: `**/storage*.go`, `**/s3*.go` for object key prefixing
- RabbitMQ: `**/rabbitmq*.go`, `**/producer*.go`, `**/consumer*.go` for isolation layers
- Tests: `**/*_test.go` for backward compatibility test
- Non-canonical: source implementation files that define custom tenant resolvers/middleware/pool managers outside canonical lib-commons integration paths (exclude docs, tests, fixtures, vendored code)
- go.mod: lib-commons version, lib-auth version
- M2M: `**/m2m*.go`, `**/credential*.go`, `**/secret*.go` for M2M credential handling

**Reference Implementation (GOOD):**
```go
// Canonical env vars in config.go (15 MANDATORY — APPLICATION_NAME + 14 MULTI_TENANT_*)
ApplicationName                        string `env:"APPLICATION_NAME"`
MultiTenantEnabled                     bool   `env:"MULTI_TENANT_ENABLED" default:"false"`
MultiTenantURL                         string `env:"MULTI_TENANT_URL"`
MultiTenantRedisHost                   string `env:"MULTI_TENANT_REDIS_HOST"`
MultiTenantRedisPort                   string `env:"MULTI_TENANT_REDIS_PORT" default:"6379"`
MultiTenantRedisPassword               string `env:"MULTI_TENANT_REDIS_PASSWORD"`
MultiTenantRedisTLS                    bool   `env:"MULTI_TENANT_REDIS_TLS"`
MultiTenantRedisCACert                 string `env:"MULTI_TENANT_REDIS_CA_CERT"` // OPTIONAL base64-encoded PEM; required when MULTI_TENANT_REDIS_TLS=true and the cluster CA isn't in system trust
MultiTenantMaxTenantPools              int    `env:"MULTI_TENANT_MAX_TENANT_POOLS" default:"100"`
MultiTenantIdleTimeoutSec              int    `env:"MULTI_TENANT_IDLE_TIMEOUT_SEC" default:"300"`
MultiTenantTimeout                     int    `env:"MULTI_TENANT_TIMEOUT" default:"30"`
MultiTenantCircuitBreakerThreshold     int    `env:"MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD" default:"5"`
MultiTenantCircuitBreakerTimeoutSec    int    `env:"MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC" default:"30"`
MultiTenantServiceAPIKey               string `env:"MULTI_TENANT_SERVICE_API_KEY"`
MultiTenantCacheTTLSec                 int    `env:"MULTI_TENANT_CACHE_TTL_SEC" default:"120"`
MultiTenantConnectionsCheckIntervalSec int    `env:"MULTI_TENANT_CONNECTIONS_CHECK_INTERVAL_SEC" default:"30"`

// TenantMiddleware with multi-module WithPG/WithMB options from lib-commons v5
import tmmiddleware "github.com/LerianStudio/lib-commons/v5/commons/tenant-manager/middleware"

ttMiddleware := tmmiddleware.NewTenantMiddleware(
    tmmiddleware.WithPG(pgOnboardingManager, constant.ModuleOnboarding),
    tmmiddleware.WithPG(pgTransactionManager, constant.ModuleTransaction),
    tmmiddleware.WithMB(mbOnboardingManager, constant.ModuleOnboarding),
    tmmiddleware.WithMB(mbTransactionManager, constant.ModuleTransaction),
    tmmiddleware.WithTenantCache(tenantCache),
    tmmiddleware.WithTenantLoader(tenantClient),
)

// Per-route auth-before-tenant ordering (MANDATORY)
// Auth validates JWT BEFORE tenant middleware calls Tenant Manager API
f.Get("/v1/organizations/:id", auth.Authorize(...), WhenEnabled(ttHandler), handler)

// Circuit breaker on Tenant Manager client (MANDATORY)
clientOpts = append(clientOpts,
    client.WithCircuitBreaker(cfg.MultiTenantCircuitBreakerThreshold, timeout),
    client.WithServiceAPIKey(cfg.MultiTenantServiceAPIKey),
)

// Module-specific connection from context
db := tmcore.GetPGContext(ctx, constant.ModuleOnboarding)
// Single-module alternative:
db := tmcore.GetPGContext(ctx)
// MongoDB:
mongoDB := tmcore.GetMBContext(ctx, constant.ModuleOnboarding)

// Redis key prefixing — ALL operations including Lua scripts
key := valkey.GetKeyContext(ctx, "cache-key")
// Lua scripts: prefix ALL KEYS[] and ARGV[] before execution
prefixedKey := valkey.GetKeyContext(ctx, transactionKey)
result, err := script.Run(ctx, rds, []string{prefixedKey}, finalArgs...).Result()

// S3 key prefixing — ALL object operations
key := s3.GetS3KeyStorageContext(ctx, originalKey)

// RabbitMQ: Layer 1 (vhost isolation) + Layer 2 (X-Tenant-ID header)
ch, err := tmrabbitmq.Manager.GetChannel(ctx, tenantID) // Layer 1: vhost
headers["X-Tenant-ID"] = tenantID                        // Layer 2: audit header

// Repository using tenant-routed database connection
func (r *Repo) Find(ctx context.Context, id uuid.UUID) (*Entity, error) {
    db := tmcore.GetPGContext(ctx, constant.ModuleTransaction)
    if db == nil {
        return nil, fmt.Errorf("tenant postgres connection missing from context for module %s", constant.ModuleTransaction)
    }
    find := squirrel.Select(columnList...).
        From(r.tableName).
        Where(squirrel.Expr("id = ?", id)).
        PlaceholderFormat(squirrel.Dollar)
    // ...
}

// Error handling with sentinel errors
case errors.Is(err, core.ErrTenantNotFound):     // → 404
case errors.Is(err, core.ErrManagerClosed):       // → 503
case errors.Is(err, core.ErrServiceNotConfigured): // → 503
case core.IsTenantNotProvisionedError(err):       // → 422
case errors.Is(err, core.ErrCircuitBreakerOpen):  // → 503

// Backward compatibility test (MANDATORY)
func TestMultiTenant_BackwardCompatibility(t *testing.T) {
    if h.IsMultiTenantEnabled() {
        t.Skip("Skipping backward compatibility test - multi-tenant mode is enabled")
    }
    // Create resources WITHOUT tenant context — MUST work in single-tenant mode
}

// Mandatory metrics (no-op in single-tenant mode)
// tenant_connections_total, tenant_connection_errors_total,
// tenant_consumers_active, tenant_messages_processed_total

// M2M credentials (ONLY if service has targetServices)
// L1 (sync.Map, 30s) → L2 (Redis, 300s) → AWS Secrets Manager
// Cache-bust on 401: delete L2 → delete L1 → re-fetch
m2mProvider = m2m.NewM2MCredentialProvider(redisConn, awsClient, logger, metrics)
```

**Reference Implementation (BAD):**
```go
// BAD: Non-canonical env var names
TenantManagerURL string `env:"TENANT_MANAGER_URL"`     // WRONG: must be MULTI_TENANT_URL
TenantEnabled    bool   `env:"TENANT_ENABLED"`          // WRONG: must be MULTI_TENANT_ENABLED

// BAD: Query using static connection instead of tenant-routed context
func (r *Repo) FindByID(ctx context.Context, id uuid.UUID) (*Entity, error) {
    return r.db.QueryRowContext(ctx, "SELECT * FROM entities WHERE id = $1", id)
    // WRONG: must use tmcore.GetPGContext(ctx, module) for tenant database routing
}

// BAD: Tenant ID from request header (can be spoofed)
func GetTenantID(c *fiber.Ctx) string {
    return c.Get("X-Tenant-ID")  // User-controlled!
}

// BAD: Global middleware (bypasses auth-first ordering)
app.Use(tenantMiddleware)  // WRONG: must use per-route WhenEnabled composition

// BAD: Using GetPGContext without module in multi-module service
db := tmcore.GetPGContext(ctx)  // WRONG: use GetPGContext(ctx, module) for multi-module services

// BAD: Missing circuit breaker on Tenant Manager client
tmClient := client.New(cfg.MultiTenantURL)  // WRONG: must use WithCircuitBreaker + WithServiceAPIKey

// BAD: Unprefixed Redis key in multi-tenant mode
rds.Set(ctx, "cache-key", value, ttl)  // WRONG: must use valkey.GetKeyContext(ctx, "cache-key")

// BAD: Unprefixed S3 key in multi-tenant mode
s3Client.PutObject(ctx, "bucket", "object-key", body)  // WRONG: must use s3.GetS3KeyStorageContext

// BAD: Non-canonical custom files (MUST be removed from source paths)
// internal/tenant/resolver.go          ← FORBIDDEN
// internal/middleware/tenant_middleware.go ← FORBIDDEN
// pkg/multitenancy/pool.go             ← FORBIDDEN

// BAD: lib-commons v2/v3/v4 imports
import tenantmanager "github.com/LerianStudio/lib-commons/v2/..."  // WRONG: must be v5

// BAD: RabbitMQ with only X-Tenant-ID header (no vhost isolation)
headers["X-Tenant-ID"] = tenantID  // Audit only, NOT isolation — must also use tmrabbitmq.Manager

// BAD: Using deprecated functions — NON-COMPLIANT, MUST migrate to current API
// WithPostgresManager, WithMongoManager, WithModule, GetMongoFromContext,
// GetKeyFromContext, GetPGConnectionFromContext, GetPGConnectionContext,
// GetMongoContext, ResolvePostgres, ResolveMongo, ResolveModuleDB,
// SetTenantIDInContext, GetPostgresForTenant, GetMongoForTenant,
// ContextWithPGConnection, ContextWithMongo, ContextWithModulePGConnection,
// GetModulePostgresForTenant, MultiPoolMiddleware, DualPoolMiddleware,
// SettingsWatcher, NewSettingsWatcher
```

**Check Against Ring Standards For:**

HARD GATES (Score = 0 if any fails):
1. (HARD GATE) Tenant ID extracted from JWT claims (not user-controlled headers/params) per multi-tenant.md
2. (HARD GATE) All database queries use tenant-routed connections via tmcore.GetPGContext/tmcore.GetMBContext (not static connections or package-level singletons)
3. (HARD GATE) TenantMiddleware with WithPG/WithMB from lib-commons v5 injects tenant into request context with module-specific connections
4. (HARD GATE) lib-commons v5 (not v2/v3/v4) for all dispatch layer sub-package imports — deprecated functions (WithPostgresManager, MultiPoolMiddleware, DualPoolMiddleware, ResolvePostgres, ResolveModuleDB, etc.) are NON-COMPLIANT

WARNINGS (does not zero the score, but flagged as HIGH):
5. (WARNING) Non-canonical source implementation files detected: custom tenant resolvers, manual pool managers, or wrapper middleware in source paths (internal/, pkg/, cmd/) outside canonical lib-commons integration paths. Excludes docs, tests, fixtures, vendored code.

Canonical Environment Variables:
6. APPLICATION_NAME always required (used for Tenant Manager settings resolution regardless of mode). When MULTI_TENANT_ENABLED=true, all 14 required MULTI_TENANT_* env vars must also be declared in the config struct with exact names: MULTI_TENANT_ENABLED, MULTI_TENANT_URL, MULTI_TENANT_REDIS_HOST, MULTI_TENANT_REDIS_PORT, MULTI_TENANT_REDIS_PASSWORD, MULTI_TENANT_REDIS_TLS, MULTI_TENANT_MAX_TENANT_POOLS, MULTI_TENANT_IDLE_TIMEOUT_SEC, MULTI_TENANT_TIMEOUT, MULTI_TENANT_CIRCUIT_BREAKER_THRESHOLD, MULTI_TENANT_CIRCUIT_BREAKER_TIMEOUT_SEC, MULTI_TENANT_SERVICE_API_KEY, MULTI_TENANT_CACHE_TTL_SEC, MULTI_TENANT_CONNECTIONS_CHECK_INTERVAL_SEC. A 15th OPTIONAL env var, MULTI_TENANT_REDIS_CA_CERT (base64-encoded PEM bundle threaded through `TenantPubSubRedisConfig.CACertBase64`), is required when MULTI_TENANT_REDIS_TLS=true AND the tenant Pub/Sub Redis cluster's CA isn't in the runtime image's system trust pool (managed AWS/GCP/Azure issuers, macOS dev workstations) — see multi-tenant.md §28 §`MULTI_TENANT_REDIS_CA_CERT`. Single-tenant mode (MULTI_TENANT_ENABLED=false or absent) must work without any MULTI_TENANT_* vars set.
7. No non-canonical env var names for tenant configuration (e.g., TENANT_MANAGER_URL, TENANT_ENABLED, MULTI_TENANT_ENVIRONMENT are violations — APPLICATION_NAME is valid)

Middleware & Routing:
8. Auth-before-tenant ordering: auth.Authorize() MUST run before WhenEnabled(ttHandler) on every route (SECURITY CRITICAL)
9. Per-route composition via WhenEnabled helper (not global app.Use(tenantMiddleware))
10. TenantMiddleware with WithPG/WithMB options for module-specific connection injection
11. Tenant middleware passed as nil when MULTI_TENANT_ENABLED=false (WhenEnabled handles nil → c.Next())

Connection Management:
12. TenantConnectionManager (PostgresManager/MongoManager) for database-per-tenant isolation
13. Correct resolution function: tmcore.GetPGContext(ctx) (single-module) or tmcore.GetPGContext(ctx, module) (multi-module) or tmcore.GetMBContext(ctx, module) (MongoDB)
14. Cross-module connection injection (both modules in context for multi-module services)
15. WithConnectionsCheckInterval on pgManager for async settings revalidation (PostgreSQL only)

Client Configuration:
16. Circuit breaker configured on Tenant Manager HTTP client (client.WithCircuitBreaker)
17. Service API key authentication configured (client.WithServiceAPIKey)

Data Isolation:
18. Tenant-scoped Redis cache keys via valkey.GetKeyContext for ALL operations (including Lua script KEYS[] and ARGV[])
19. Tenant-scoped S3 object keys via s3.GetS3KeyStorageContext for ALL operations
20. No cross-tenant data leakage in list/search operations

RabbitMQ (if detected):
21. Layer 1: vhost isolation via tmrabbitmq.Manager.GetChannel
22. Layer 2: X-Tenant-ID header injection on all messages (both layers MANDATORY)
23. Multi-tenant consumer via tmconsumer.MultiTenantConsumer (on-demand initialization)

Error Handling:
24. Sentinel error mapping: ErrTenantNotFound→404, *TenantSuspendedError→403, ErrManagerClosed→503, ErrServiceNotConfigured→503, IsTenantNotProvisionedError→422, ErrCircuitBreakerOpen→503
25. ErrTenantContextRequired in repositories when tenant context is missing

Backward Compatibility:
26. Service works with MULTI_TENANT_ENABLED=false (default) — no MULTI_TENANT_* vars required
27. TestMultiTenant_BackwardCompatibility test exists and validates single-tenant mode
28. Service starts without Tenant Manager running

Metrics:
29. All 4 core metrics present: tenant_connections_total, tenant_connection_errors_total, tenant_consumers_active, tenant_messages_processed_total
30. Metrics are no-op in single-tenant mode (zero overhead)

Graceful Shutdown:
31. Connection managers closed during shutdown (manager.Close() in shutdown hooks)

Event-Driven Discovery:
32. EventListener configured (Redis Pub/Sub subscription for tenant lifecycle events)
33. NewTenantPubSubRedisClient used for Redis client (not manual libRedis.Config)
34. NewTenantEventListener wired with PubSub Redis client
35. TenantCache + TenantLoader wired to TenantMiddleware
36. TenantLoader.SetOnTenantLoaded callback configured (starts consumer after lazy-load)
37. OnTenantAdded callback: invalidates cache + starts consumer for new tenant
38. OnTenantRemoved callback: stops consumer + closes connections + invalidates cache
39. StopConsumer called before CloseConnection on tenant removal (ordering matters)

M2M Credentials (CONDITIONAL — activation criteria below):
Activation rule: M2M checks apply ONLY when BOTH conditions are met:
  (a) Service declares a non-empty `targetServices` in typed config/DTO/module wiring, AND
  (b) Outbound service-to-service credential provider usage is detected in code paths (e.g., secretsmanager.GetM2MCredentials, m2m.NewM2MCredentialProvider).
If either condition is missing, mark M2M section as N/A and do not deduct score.
40. M2M credential provider with two-level cache: L1 (sync.Map, 30s) → L2 (Redis) → AWS Secrets Manager
41. Cache-bust on 401: invalidate L2 → L1 → re-fetch
42. 6 M2M metrics: m2m_credential_l1_cache_hits, m2m_credential_l2_cache_hits, m2m_credential_cache_misses, m2m_credential_fetch_errors, m2m_credential_fetch_duration_seconds, m2m_credential_invalidations
43. Credentials MUST NOT be logged or stored in environment variables
44. Redis key for credentials uses valkey.GetKeyContext with pattern: tenant:{tenantOrgID}:m2m:{targetService}:credentials

**Severity Ratings:**
- CRITICAL: Queries using static connections instead of tenant-routed tmcore.GetPGContext/GetMBContext (HARD GATE violation)
- CRITICAL: Tenant ID from user-controlled input (HARD GATE violation)
- CRITICAL: Missing TenantMiddleware with WithPG/WithMB from lib-commons v5 (HARD GATE violation)
- CRITICAL: Using deprecated functions (WithPostgresManager, MultiPoolMiddleware, DualPoolMiddleware, ResolvePostgres, ResolveModuleDB, etc.) — NON-COMPLIANT, MUST migrate to current API
- CRITICAL: lib-commons v2/v3/v4 imports instead of v5 (HARD GATE violation)
- CRITICAL: Auth-after-tenant ordering — JWT not validated before Tenant Manager API call (security vulnerability)
- CRITICAL: Global app.Use(tenantMiddleware) instead of per-route WhenEnabled composition (bypasses auth ordering)
- HIGH: Non-canonical env var names (e.g., TENANT_MANAGER_URL instead of MULTI_TENANT_URL)
- HIGH: Non-canonical source files detected — custom tenant resolvers/middleware/pool managers in source paths
- HIGH: Missing circuit breaker on Tenant Manager client (cascading failure risk across all tenants)
- HIGH: Missing service API key authentication (Tenant Manager calls unauthenticated)
- HIGH: No TenantConnectionManager for connection management
- HIGH: Cache keys not tenant-scoped (Redis or S3)
- HIGH: Missing cross-module connection injection
- HIGH: Missing backward compatibility test (TestMultiTenant_BackwardCompatibility)
- HIGH: RabbitMQ missing vhost isolation (Layer 2 header alone is NOT compliant)
- HIGH: M2M credentials logged or stored in env vars (if targetServices detected)
- MEDIUM: Inconsistent tenant extraction across modules
- MEDIUM: Missing sentinel error handling (ErrManagerClosed, ErrCircuitBreakerOpen, *TenantSuspendedError, etc.)
- MEDIUM: Missing graceful shutdown of connection managers
- MEDIUM: Metrics not present or not no-op in single-tenant mode
- MEDIUM: Redis Lua script keys not prefixed with valkey.GetKeyContext
- LOW: Missing tenant validation in non-critical paths

**Output Format:**
```
## Multi-Tenant Patterns Audit Findings

### Summary
- Multi-tenant detection: Yes/No/N/A
- lib-commons version: v5 / v4 / v3 / v2 / Missing
- Tenant extraction: JWT / Header / Missing
- TenantMiddleware (WithPG/WithMB): Yes / No / Custom / Missing
- Auth-before-tenant ordering: Yes / No / Inconsistent
- Route composition: Per-route WhenEnabled / Global app.Use / Mixed
- APPLICATION_NAME: Present / Missing
- Canonical MULTI_TENANT_* env vars (when MT enabled): X/14 present with correct names
- Non-canonical env vars detected: [list or "None"]
- Non-canonical source files detected: [list or "None"]
- Circuit breaker on TM client: Yes / No
- Service API key configured: Yes / No
- Connection resolution: tmcore.GetPGContext(ctx, module) / tmcore.GetPGContext(ctx) / tmcore.GetMBContext / Custom / Missing
- Redis key prefixing: Yes / Partial / No (Lua scripts: Yes/No)
- S3 key prefixing: Yes / No / N/A
- RabbitMQ isolation: Both layers / Header only / Missing / N/A
- Event-driven discovery: NewTenantPubSubRedisClient + NewTenantEventListener + TenantCache + TenantLoader + SetOnTenantLoaded / Partial / Missing
- Backward compatibility test: Yes / No
- Backward compatibility mode: Works without MT vars / Requires MT vars
- Mandatory metrics: X/4 present (no-op in ST: Yes/No)
- Graceful shutdown: Manager.Close() called / Missing
- M2M credentials: Compliant / Non-compliant / N/A (no targetServices detected)

### HARD GATE Violations
[file:line] - Description (HARD GATE: Score = 0)

### Critical Issues
[file:line] - Description

### High Issues
[file:line] - Description

### Medium Issues
[file:line] - Description

### Recommendations
1. ...
```
```
