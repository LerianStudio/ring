# Go Standards - Index

> **⚠️ MAINTENANCE:** This directory is indexed in `dev-team/skills/shared-patterns/standards-coverage-table.md`.
> When adding/removing sections, follow FOUR-FILE UPDATE RULE in CLAUDE.md.

This directory contains modular Go standards for Lerian Studio. Load only the modules you need.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Quick Reference - Which File for What](#quick-reference---which-file-for-what) | Task-based file selection guide |
| 2 | [Module Index](#module-index) | All 20 modules with section counts and descriptions |
| 3 | [Section Index (Full)](#section-index-full) | Complete section index with anchors |
| 4 | [Dependency Graph](#dependency-graph) | Module dependency relationships |
| 5 | [WebFetch URLs](#webfetch-urls) | Raw GitHub URLs for agent loading |

---

## Quick Reference - Which File for What

| Task | Load These Files |
|------|------------------|
| **New feature (full)** | core.md → bootstrap.md → domain.md → quality.md |
| **Auth implementation** | core.md → security.md |
| **Rate limiting** | security.md |
| **CORS configuration** | security.md |
| **Add tracing/observability** | bootstrap.md |
| **Unit testing (Gate 3)** | testing-unit.md |
| **Fuzz testing (Gate 4)** | testing-fuzz.md |
| **Property-based testing (Gate 5)** | testing-property.md |
| **Integration testing (Gate 6)** | testing-integration.md |
| **Chaos testing (Gate 7)** | testing-chaos.md |
| **Benchmark testing (optional)** | testing-benchmark.md |
| **Idempotency** | idempotency.md (+ domain.md for error codes) |
| **Multi-tenant** | multi-tenant.md (+ bootstrap.md for context) |
| **Caching strategy** | caching.md |
| **CQRS pattern** | architecture.md (+ domain-modeling.md for command side) |
| **Database migration** | migration-safety.md (+ core.md for golang-migrate) |
| **Compliance check** | ALL modules |

---

## Module Index

| # | Module | Sections | Lines | Description |
|---|--------|----------|-------|-------------|
| 1 | [core.md](core.md) | 9 | ~1100 | Version, lib-commons, Frameworks, Configuration, DB Naming, Migrations, License, MongoDB, Dependency Management |
| 2 | [bootstrap.md](bootstrap.md) | 5 | ~1050 | Observability, Bootstrap, Graceful Shutdown, Health Checks, Connection Management |
| 3 | [security.md](security.md) | 7 | ~1700 | Access Manager, License Manager, Secret Redaction, SQL Safety, HTTP Security Headers, Rate Limiting (with Trusted Proxy), CORS Configuration |
| 4 | [domain.md](domain.md) | 5 | ~255 | ToEntity/FromEntity, Error Codes, Error Handling, Exit/Fatal Rules, Function Design |
| 5 | [api-patterns.md](api-patterns.md) | 6 | ~900 | JSON Naming, Pagination, HTTP Status Codes, OpenAPI/Swaggo, Handler Constructor, Input Validation |
| 6 | [quality.md](quality.md) | 4 | ~900 | Logging, Linting, Config Validation, Container Security |
| 7 | [architecture.md](architecture.md) | 8 | ~1000 | Architecture, Directory, Concurrency, Goroutine Recovery, Goroutine Leak Detection (goleak), N+1 Detection, Performance, CQRS |
| 8 | [messaging.md](messaging.md) | 2 | ~650 | RabbitMQ Worker Pattern, Reconnection Strategy |
| 9 | [domain-modeling.md](domain-modeling.md) | 4 | ~290 | Always-Valid Domain Model, Constructor Patterns, ToEntity Integration |
| 10 | [idempotency.md](idempotency.md) | 1 | ~510 | Idempotency Patterns (Redis SetNX, hash fallback) |
| 11 | [multi-tenant.md](multi-tenant.md) | 2 | ~2240 | Multi-Tenant Patterns (Tenant Manager, JWT), Auth-Before-Tenant Ordering |
| 12 | [compliance.md](compliance.md) | Meta | ~125 | Standards Compliance Output Format, Checklist |
| 13 | [testing-unit.md](testing-unit.md) | 11 | ~600 | Unit Testing (Gate 3): Table-driven, t.Parallel, loop capture, assertions, mocks, t.Setenv, testutils, scope boundaries |
| 14 | [testing-fuzz.md](testing-fuzz.md) | 5 | ~300 | Fuzz Testing (Gate 4): Native Go fuzz, seed corpus |
| 15 | [testing-property.md](testing-property.md) | 5 | ~350 | Property-Based Testing (Gate 5): testing/quick.Check, invariants |
| 16 | [testing-integration.md](testing-integration.md) | 10 | ~500 | Integration Testing (Gate 6): Testcontainers, fixtures, stubs |
| 17 | [testing-chaos.md](testing-chaos.md) | 5 | ~350 | Chaos Testing (Gate 7): Toxiproxy, failure injection |
| 18 | [testing-benchmark.md](testing-benchmark.md) | 4 | ~250 | Benchmark Testing (optional): b.Loop(), performance |
| 19 | [migration-safety.md](migration-safety.md) | 5 | ~350 | Migration Safety (Gate 0.5D): Dangerous ops detection, expand-contract, multi-tenant idempotency |
| 20 | [caching.md](caching.md) | 2 | ~350 | Caching Strategy Patterns (Cache-Aside, Write-Through, Write-Behind), Cache Compliance Detection |

**Total:** 20 modules with testing split into 6 specialized files

---

## Section Index (Full)

### Core Foundation (core.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Version | [#version](core.md#version) |
| 2 | Core Dependency: lib-commons (MANDATORY) | [#core-dependency-lib-commons-mandatory](core.md#core-dependency-lib-commons-mandatory) |
| 3 | Frameworks & Libraries | [#frameworks--libraries](core.md#frameworks--libraries) |
| 4 | Configuration | [#configuration](core.md#configuration) |
| 5 | Database Naming Convention (snake_case) (MANDATORY) | [#database-naming-convention-snake-case-mandatory](core.md#database-naming-convention-snake-case-mandatory) |
| 6 | Database Migrations (MANDATORY) | [#database-migrations-mandatory](core.md#database-migrations-mandatory) |
| 7 | License Headers (CONDITIONAL) | [#license-headers-conditional](core.md#license-headers-conditional) |
| 8 | MongoDB Patterns (MANDATORY) | [#mongodb-patterns-mandatory](core.md#mongodb-patterns-mandatory) |

### Bootstrap & Observability (bootstrap.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Observability | [#observability](bootstrap.md#observability) |
| 2 | Bootstrap | [#bootstrap](bootstrap.md#bootstrap) |
| 3 | Graceful Shutdown Patterns (MANDATORY) | [#graceful-shutdown-patterns-mandatory](bootstrap.md#graceful-shutdown-patterns-mandatory) |
| 4 | Health Checks (MANDATORY) | [#health-checks-mandatory](bootstrap.md#health-checks-mandatory) |
| 5 | Connection Management (MANDATORY) | [#connection-management-mandatory](bootstrap.md#connection-management-mandatory) |

### Security (security.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Access Manager Integration (MANDATORY) | [#access-manager-integration-mandatory](security.md#access-manager-integration-mandatory) |
| 2 | License Manager Integration (MANDATORY) | [#license-manager-integration-mandatory](security.md#license-manager-integration-mandatory) |
| 3 | Secret Redaction Patterns (MANDATORY) | [#secret-redaction-patterns-mandatory](security.md#secret-redaction-patterns-mandatory) |
| 4 | SQL Safety (MANDATORY) | [#sql-safety-mandatory](security.md#sql-safety-mandatory) |
| 5 | HTTP Security Headers (MANDATORY) | [#http-security-headers-mandatory](security.md#http-security-headers-mandatory) |
| 6 | Rate Limiting (MANDATORY) | [#rate-limiting-mandatory](security.md#rate-limiting-mandatory) |
| 7 | CORS Configuration (MANDATORY) | [#cors-configuration-mandatory](security.md#cors-configuration-mandatory) |

### Domain Patterns (domain.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Data Transformation: ToEntity/FromEntity (MANDATORY) | [#data-transformation-toentityfromentity-mandatory](domain.md#data-transformation-toentityfromentity-mandatory) |
| 2 | Error Codes Convention (MANDATORY) | [#error-codes-convention-mandatory](domain.md#error-codes-convention-mandatory) |
| 3 | Error Handling | [#error-handling](domain.md#error-handling) |
| 4 | Exit/Fatal Location Rules (MANDATORY) | [#exitfatal-location-rules-mandatory](domain.md#exitfatal-location-rules-mandatory) |
| 5 | Function Design (MANDATORY) | [#function-design-mandatory](domain.md#function-design-mandatory) |

### API Patterns (api-patterns.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | JSON Naming Convention (camelCase) (MANDATORY) | [#json-naming-convention-camelcase-mandatory](api-patterns.md#json-naming-convention-camelcase-mandatory) |
| 2 | Pagination Patterns (Offset & Cursor) | [#pagination-patterns](api-patterns.md#pagination-patterns) |
| 3 | HTTP Status Code Consistency (MANDATORY) | [#http-status-code-consistency-mandatory](api-patterns.md#http-status-code-consistency-mandatory) |
| 4 | OpenAPI Documentation (Swaggo) (MANDATORY) | [#openapi-documentation-swaggo-mandatory](api-patterns.md#openapi-documentation-swaggo-mandatory) |
| 5 | Handler Constructor Pattern (MANDATORY) | [#handler-constructor-pattern-mandatory](api-patterns.md#handler-constructor-pattern-mandatory) |

### Quality (quality.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Logging | [#logging](quality.md#logging) |
| 2 | Linting | [#linting](quality.md#linting) |
| 3 | Production Config Validation (MANDATORY) | [#production-config-validation-mandatory](quality.md#production-config-validation-mandatory) |
| 4 | Container Security (CONDITIONAL) | [#container-security-conditional](quality.md#container-security-conditional) |

### Architecture (architecture.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Architecture Patterns | [#architecture-patterns](architecture.md#architecture-patterns) |
| 2 | Directory Structure | [#directory-structure](architecture.md#directory-structure) |
| 3 | Concurrency Patterns | [#concurrency-patterns](architecture.md#concurrency-patterns) |
| 4 | Goroutine Recovery Patterns (MANDATORY) | [#goroutine-recovery-patterns-mandatory](architecture.md#goroutine-recovery-patterns-mandatory) |
| 5 | Goroutine Leak Detection (MANDATORY) | [#goroutine-leak-detection-mandatory](architecture.md#goroutine-leak-detection-mandatory) |
| 6 | N+1 Query Detection (MANDATORY) | [#n1-query-detection-mandatory](architecture.md#n1-query-detection-mandatory) |
| 7 | Performance Patterns (MANDATORY) | [#performance-patterns-mandatory](architecture.md#performance-patterns-mandatory) |
| 8 | CQRS Pattern (CONDITIONAL) | [#cqrs-pattern-conditional](architecture.md#cqrs-pattern-conditional) |

### Messaging (messaging.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | RabbitMQ Worker Pattern | [#rabbitmq-worker-pattern](messaging.md#rabbitmq-worker-pattern) |
| 2 | RabbitMQ Reconnection Strategy (MANDATORY) | [#rabbitmq-reconnection-strategy-mandatory](messaging.md#rabbitmq-reconnection-strategy-mandatory) |

### Domain Modeling (domain-modeling.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Always-Valid Domain Model (MANDATORY) | [#always-valid-domain-model-mandatory](domain-modeling.md#always-valid-domain-model-mandatory) |
| 2 | Constructor Validation Patterns (MANDATORY) | [#constructor-validation-patterns-mandatory](domain-modeling.md#constructor-validation-patterns-mandatory) |
| 3 | ToEntity/FromEntity Integration (MANDATORY) | [#toentityfromentity-integration-mandatory](domain-modeling.md#toentityfromentity-integration-mandatory) |
| 4 | Integration with HTTP Layer | [#integration-with-http-layer](domain-modeling.md#integration-with-http-layer) |

### Idempotency (idempotency.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Idempotency Patterns (MANDATORY for Transaction APIs) | [#idempotency-patterns-mandatory-for-transaction-apis](idempotency.md#idempotency-patterns-mandatory-for-transaction-apis) |

### Multi-Tenant (multi-tenant.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Multi-Tenant Patterns (CONDITIONAL) | [#multi-tenant-patterns-conditional](multi-tenant.md#multi-tenant-patterns-conditional) |
| 2 | Route-Level Auth-Before-Tenant Ordering (MANDATORY) | [#route-level-auth-before-tenant-ordering-mandatory](multi-tenant.md#route-level-auth-before-tenant-ordering-mandatory) |

### Unit Testing (testing-unit.md) - Gate 3

| # | Section | Anchor |
|---|---------|--------|
| 1 | Table-Driven Tests (MANDATORY) | [#table-driven-tests-mandatory](testing-unit.md#table-driven-tests-mandatory) |
| 2 | Test Naming Convention (MANDATORY) | [#test-naming-convention-mandatory](testing-unit.md#test-naming-convention-mandatory) |
| 3 | Parallel Test Execution (MANDATORY) | [#parallel-test-execution-mandatory](testing-unit.md#parallel-test-execution-mandatory) |
| 4 | Loop Variable Capture (MANDATORY) | [#loop-variable-capture-mandatory](testing-unit.md#loop-variable-capture-mandatory) |
| 5 | Edge Case Coverage (MANDATORY) | [#edge-case-coverage-mandatory](testing-unit.md#edge-case-coverage-mandatory) |
| 6 | Assertion Requirements (MANDATORY) | [#assertion-requirements-mandatory](testing-unit.md#assertion-requirements-mandatory) |
| 7 | Mock Generation (MANDATORY) | [#mock-generation-mandatory](testing-unit.md#mock-generation-mandatory) |
| 8 | Environment Variables in Tests (MANDATORY) | [#environment-variables-in-tests-mandatory](testing-unit.md#environment-variables-in-tests-mandatory) |
| 9 | Shared Test Utilities (MANDATORY) | [#shared-test-utilities-mandatory](testing-unit.md#shared-test-utilities-mandatory) |
| 10 | Unit Test Scope & Boundaries (MANDATORY) | [#unit-test-scope--boundaries-mandatory](testing-unit.md#unit-test-scope--boundaries-mandatory) |
| 11 | Unit Test Quality Gate (MANDATORY) | [#unit-test-quality-gate-mandatory](testing-unit.md#unit-test-quality-gate-mandatory) |

### Fuzz Testing (testing-fuzz.md) - Gate 4

| # | Section | Anchor |
|---|---------|--------|
| 1 | What Is Fuzz Testing | [#what-is-fuzz-testing](testing-fuzz.md#what-is-fuzz-testing) |
| 2 | Fuzz Function Pattern (MANDATORY) | [#fuzz-function-pattern-mandatory](testing-fuzz.md#fuzz-function-pattern-mandatory) |
| 3 | Seed Corpus (MANDATORY) | [#seed-corpus-mandatory](testing-fuzz.md#seed-corpus-mandatory) |
| 4 | Input Types | [#input-types](testing-fuzz.md#input-types) |
| 5 | Fuzz Test Quality Gate (MANDATORY) | [#fuzz-test-quality-gate-mandatory](testing-fuzz.md#fuzz-test-quality-gate-mandatory) |

### Property-Based Testing (testing-property.md) - Gate 5

| # | Section | Anchor |
|---|---------|--------|
| 1 | What Is Property-Based Testing | [#what-is-property-based-testing](testing-property.md#what-is-property-based-testing) |
| 2 | Property Function Pattern (MANDATORY) | [#property-function-pattern-mandatory](testing-property.md#property-function-pattern-mandatory) |
| 3 | Common Properties | [#common-properties](testing-property.md#common-properties) |
| 4 | Integration vs Unit Properties | [#integration-vs-unit-properties](testing-property.md#integration-vs-unit-properties) |
| 5 | Property Test Quality Gate (MANDATORY) | [#property-test-quality-gate-mandatory](testing-property.md#property-test-quality-gate-mandatory) |

### Integration Testing (testing-integration.md) - Gate 6

| # | Section | Anchor |
|---|---------|--------|
| 1 | Test Pyramid | [#test-pyramid](testing-integration.md#test-pyramid) |
| 2 | File Naming Convention (MANDATORY) | [#file-naming-convention-mandatory](testing-integration.md#file-naming-convention-mandatory) |
| 3 | Function Naming Convention (MANDATORY) | [#function-naming-convention-mandatory](testing-integration.md#function-naming-convention-mandatory) |
| 4 | Build Tags (MANDATORY) | [#build-tags-mandatory](testing-integration.md#build-tags-mandatory) |
| 5 | Testcontainers Patterns (MANDATORY) | [#testcontainers-patterns-mandatory](testing-integration.md#testcontainers-patterns-mandatory) |
| 6 | Parallel Test Prohibition (MANDATORY) | [#parallel-test-prohibition-mandatory](testing-integration.md#parallel-test-prohibition-mandatory) |
| 7 | Fixture Centralization (MANDATORY) | [#fixture-centralization-mandatory](testing-integration.md#fixture-centralization-mandatory) |
| 8 | Stub Centralization (MANDATORY) | [#stub-centralization-mandatory](testing-integration.md#stub-centralization-mandatory) |
| 9 | Guardrails (11 Anti-Patterns) (MANDATORY) | [#guardrails-11-anti-patterns-mandatory](testing-integration.md#guardrails-11-anti-patterns-mandatory) |
| 10 | Test Failure Analysis | [#test-failure-analysis-no-greenwashing](testing-integration.md#test-failure-analysis-no-greenwashing) |

### Chaos Testing (testing-chaos.md) - Gate 7

| # | Section | Anchor |
|---|---------|--------|
| 1 | What Is Chaos Testing | [#what-is-chaos-testing](testing-chaos.md#what-is-chaos-testing) |
| 2 | Chaos Test Pattern (MANDATORY) | [#chaos-test-pattern-mandatory](testing-chaos.md#chaos-test-pattern-mandatory) |
| 3 | Failure Scenarios | [#failure-scenarios](testing-chaos.md#failure-scenarios) |
| 4 | Infrastructure Setup | [#infrastructure-setup](testing-chaos.md#infrastructure-setup) |
| 5 | Chaos Test Quality Gate (MANDATORY) | [#chaos-test-quality-gate-mandatory](testing-chaos.md#chaos-test-quality-gate-mandatory) |

### Benchmark Testing (testing-benchmark.md) - Optional

| # | Section | Anchor |
|---|---------|--------|
| 1 | What Is Benchmark Testing | [#what-is-benchmark-testing](testing-benchmark.md#what-is-benchmark-testing) |
| 2 | Benchmark Function Pattern (MANDATORY for Go 1.24+) | [#benchmark-function-pattern-mandatory-for-go-124](testing-benchmark.md#benchmark-function-pattern-mandatory-for-go-124) |
| 3 | Common Patterns | [#common-patterns](testing-benchmark.md#common-patterns) |
| 4 | Running Benchmarks | [#running-benchmarks](testing-benchmark.md#running-benchmarks) |

### Caching (caching.md)

| # | Section | Anchor |
|---|---------|--------|
| 1 | Caching Strategy Patterns (MANDATORY) | [#caching-strategy-patterns-mandatory](caching.md#caching-strategy-patterns-mandatory) |
| 2 | Cache Compliance Detection | [#cache-compliance-detection](caching.md#cache-compliance-detection) |

---

## Dependency Graph

```
core.md (foundation - load first)
    │
    ├── bootstrap.md (depends on core.md)
    │   └── Initializes: Observability, Logger, Telemetry
    │
    ├── security.md (depends on core.md, bootstrap.md)
    │   └── Access Manager, License Manager
    │
    ├── domain.md (depends on core.md)
    │   └── ToEntity/FromEntity, Error Codes, Error Handling
    │
    ├── api-patterns.md (depends on domain.md)
    │   └── Pagination (uses error handling)
    │
    ├── quality.md (depends on core.md, bootstrap.md)
    │   └── Logging, Linting (uses telemetry context)
    │
    ├── testing-unit.md (depends on quality.md) - Gate 3
    │   └── Unit Testing: Table-driven, mocks, edge cases
    │
    ├── testing-fuzz.md (depends on testing-unit.md) - Gate 4
    │   └── Fuzz Testing: Native Go fuzz, seed corpus
    │
    ├── testing-property.md (depends on testing-unit.md) - Gate 5
    │   └── Property-Based: testing/quick.Check, invariants
    │
    ├── testing-integration.md (depends on quality.md) - Gate 6
    │   └── Integration Testing: Testcontainers, fixtures
    │
    ├── testing-chaos.md (depends on testing-integration.md) - Gate 7
    │   └── Chaos Testing: Toxiproxy, failure injection
    │
    ├── testing-benchmark.md (depends on testing-unit.md) - Optional
    │   └── Benchmark Testing: b.Loop(), performance
    │
    ├── architecture.md (depends on core.md)
    │   └── Hexagonal, Directory Structure, Concurrency
    │
    ├── messaging.md (depends on bootstrap.md, architecture.md)
    │   └── RabbitMQ (uses concurrency patterns)
    │
    ├── domain-modeling.md (depends on domain.md)
    │   └── Always-Valid Domain Model (uses error codes)
    │
    ├── idempotency.md (depends on domain.md, multi-tenant.md)
    │   └── Idempotency (uses error codes, tenant prefix)
    │
    ├── multi-tenant.md (depends on bootstrap.md, security.md)
    │   └── Tenant Manager, JWT extraction, Context injection
    │
    └── caching.md (depends on core.md, multi-tenant.md)
        └── Caching Strategy (uses Redis, tenant-aware keys)
```

---

## WebFetch URLs

For agents loading standards via WebFetch:

| Module | URL |
|--------|-----|
| **index.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/index.md` |
| core.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/core.md` |
| bootstrap.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/bootstrap.md` |
| security.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/security.md` |
| domain.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/domain.md` |
| api-patterns.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/api-patterns.md` |
| quality.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/quality.md` |
| architecture.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/architecture.md` |
| messaging.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/messaging.md` |
| domain-modeling.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/domain-modeling.md` |
| idempotency.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/idempotency.md` |
| multi-tenant.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/multi-tenant.md` |
| compliance.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/compliance.md` |
| testing-unit.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-unit.md` |
| testing-fuzz.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-fuzz.md` |
| testing-property.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-property.md` |
| testing-integration.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-integration.md` |
| testing-chaos.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-chaos.md` |
| testing-benchmark.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/testing-benchmark.md` |
| migration-safety.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/migration-safety.md` |
| caching.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/caching.md` |
