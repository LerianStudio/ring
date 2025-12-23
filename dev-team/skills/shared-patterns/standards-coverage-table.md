# Standards Coverage Table Pattern

This file defines the MANDATORY output format for agents comparing codebases against Ring standards. It ensures EVERY section in the standards is explicitly checked and reported.

---

## ⛔ CRITICAL: ALL Sections Are REQUIRED

**This is NON-NEGOTIABLE. Every section listed in the Agent → Standards Section Index below MUST be checked.**

| Rule | Enforcement |
|------|-------------|
| **EVERY section MUST be checked** | No exceptions. No skipping. |
| **EVERY section MUST appear in output table** | Missing row = INCOMPLETE output |
| **Subsections are INCLUDED** | If "Containers" is listed, ALL content (Dockerfile, Docker Compose) MUST be checked |
| **N/A requires explicit reason** | Cannot mark N/A without justification |

**If you skip ANY section → Your output is REJECTED. Start over.**

**If you invent section names → Your output is REJECTED. Start over.**

---

## ⛔ CRITICAL: Section Names Are NOT Negotiable

**You MUST use the EXACT section names from this file. You CANNOT:**

| FORBIDDEN | Example | Why Wrong |
|-----------|---------|-----------|
| Invent names | "Security", "Code Quality" | Not in coverage table |
| Rename sections | "Config" instead of "Configuration Loading" | Breaks traceability |
| Merge sections | "Error Handling & Logging" | Each section = one row |
| Use abbreviations | "Bootstrap" instead of "Bootstrap Pattern" | Must match exactly |
| Skip sections | Omitting "RabbitMQ Worker Pattern" | Mark N/A instead |

**Your output table section names MUST match the "Section to Check" column below EXACTLY.**

---

## Why This Pattern Exists

**Problem:** Agents might skip sections from standards files, either by:
- Only checking "main" sections
- Assuming some sections don't apply
- Not enumerating all sections systematically
- Skipping subsections (e.g., checking Dockerfile but skipping Docker Compose)

**Solution:** Require a completeness table that MUST list every section from the WebFetch result with explicit status. ALL content within each section MUST be evaluated.

---

## MANDATORY: Standards Coverage Table

### ⛔ HARD GATE: Before Outputting Findings

**You MUST output a Standards Coverage Table that enumerates EVERY section from the WebFetch result.**

**REQUIRED: When checking a section, you MUST check ALL subsections and patterns within it.**

| Section | What MUST Be Checked |
|---------|---------------------|
| Containers | Dockerfile patterns AND Docker Compose patterns |
| Infrastructure as Code | Terraform structure AND state management AND modules |
| Observability | Logging AND Tracing (structured JSON logs, OpenTelemetry spans) |
| Security | Secrets management AND Network policies |

### Process

1. **Parse the WebFetch result** - Extract ALL `## Section` headers from the standards file
2. **Count sections** - Record total number of sections found
3. **For EACH section** - Determine status and evidence
4. **Output table** - MUST have one row per section
5. **Verify completeness** - Table row count MUST equal section count

### Output Format

```markdown
## Standards Coverage Table

**Standards File:** {filename}.md (from WebFetch)
**Total Sections Found:** {N}
**Table Rows:** {N} (MUST match)

| # | Section (from WebFetch) | Status | Evidence |
|---|-------------------------|--------|----------|
| 1 | {Section 1 header} | ✅/⚠️/❌/N/A | file:line or reason |
| 2 | {Section 2 header} | ✅/⚠️/❌/N/A | file:line or reason |
| ... | ... | ... | ... |
| N | {Section N header} | ✅/⚠️/❌/N/A | file:line or reason |

**Completeness Verification:**
- Sections in standards: {N}
- Rows in table: {N}
- Status: ✅ Complete / ❌ Incomplete
```

### Status Legend

| Status | Meaning | When to Use |
|--------|---------|-------------|
| ✅ Compliant | Codebase follows this standard | Code matches expected pattern |
| ⚠️ Partial | Some compliance, needs improvement | Partially implemented or minor gaps |
| ❌ Non-Compliant | Does not follow standard | Missing or incorrect implementation |
| N/A | Not applicable to this codebase | Standard doesn't apply (with reason) |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I checked the important sections" | You don't decide importance. ALL sections MUST be checked. | **List EVERY section in table** |
| "Some sections obviously don't apply" | Report them as N/A with reason. Never skip silently. | **Include in table with N/A status** |
| "The table would be too long" | Completeness > brevity. Every section MUST be visible. | **Output full table regardless of length** |
| "I already mentioned these in findings" | Findings ≠ Coverage table. Both are REQUIRED. | **Output table BEFORE detailed findings** |
| "WebFetch result was unclear" | Parse all `## ` headers. If truly unclear, STOP and report blocker. | **Report blocker or parse all headers** |
| "I checked Dockerfile, that covers Containers" | Containers = Dockerfile + Docker Compose. Partial ≠ Complete. | **Check ALL subsections within each section** |
| "Project doesn't use Docker Compose" | Report as N/A with evidence. Never assume. VERIFY first. | **Search for docker-compose.yml, report finding** |
| "Only checking what exists in codebase" | Standards define what SHOULD exist. Missing = Non-Compliant. | **Report missing patterns as ❌ Non-Compliant** |
| "My section name is clearer" | Consistency > clarity. Coverage table names are the contract. | **Use EXACT names from coverage table** |
| "I combined related sections for brevity" | Each section = one row. Merging loses traceability. | **One row per section, no merging** |
| "I added a useful section like 'Security'" | You don't decide sections. Coverage table does. | **Only output sections from coverage table** |
| "'Logging' is the same as 'Logging Standards'" | Names must match EXACTLY. Variations break automation. | **Use exact string from coverage table** |

---

## Completeness Check (SELF-VERIFICATION)

**Before submitting output, verify:**

```text
1. Did I extract ALL ## headers from WebFetch result?     [ ]
2. Does my table have exactly that many rows?             [ ]
3. Does EVERY row have a status (✅/⚠️/❌/N/A)?           [ ]
4. Does EVERY ⚠️/❌ have evidence (file:line)?           [ ]
5. Does EVERY N/A have a reason?                         [ ]

If ANY checkbox is unchecked → FIX before submitting.
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

| # | Section (from WebFetch) | Status | Evidence |
|---|-------------------------|--------|----------|
| 1 | Version | ✅ | go.mod:3 (Go 1.24) |
| 2 | Core Dependency: lib-commons | ✅ | go.mod:5 |
| 3 | Frameworks & Libraries | ✅ | Fiber v2, pgx/v5 in go.mod |
| 4 | Configuration Loading | ⚠️ | internal/config/config.go:12 |
| 5 | Telemetry & Observability | ❌ | Not implemented |
| 6 | Bootstrap Pattern | ✅ | cmd/server/main.go:15 |
| 7 | Access Manager Integration | ✅ | internal/middleware/auth.go:25 |
| 8 | License Manager Integration | N/A | Not a licensed project |
| 9 | Data Transformation | ✅ | internal/adapters/postgres/mapper.go:8 |
| 10 | Error Codes Convention | ⚠️ | Uses generic codes |
| 11 | Error Handling | ✅ | Consistent pattern |
| 12 | Function Design | ✅ | Small functions, clear names |
| 13 | Pagination Patterns | N/A | No list endpoints |
| 14 | Testing Patterns | ❌ | No tests found |
| 15 | Logging Standards | ⚠️ | Missing structured fields |
| 16 | Linting | ✅ | .golangci.yml present |
| 17 | Architecture Patterns | ✅ | Hexagonal structure |
| 18 | Directory Structure | ✅ | Follows Lerian pattern |
| 19 | Concurrency Patterns | N/A | No concurrent code |
| 20 | RabbitMQ Worker Pattern | N/A | No message queue |

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

**Detection:** Prompt contains `**MODE: ANALYSIS ONLY**`

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
Standards files may contain these meta-sections that are NOT counted in section indexes:
- `## Checklist` - Self-verification checklist for developers
- `## Standards Compliance` - Output format examples for agents
- `## Standards Compliance Output Format` - Output templates

These sections describe HOW to use the standards, not WHAT the standards are.

### backend-engineer-golang → golang.md

| # | Section to Check | Anchor | Key Subsections |
|---|------------------|--------|-----------------|
| 1 | Version | `#version` | Go 1.24+ |
| 2 | Core Dependency: lib-commons | `#core-dependency-lib-commons-mandatory` | |
| 3 | Frameworks & Libraries | `#frameworks--libraries` | lib-commons v2, Fiber v2, pgx/v5, OpenTelemetry, zap, testify, mockery |
| 4 | Configuration | `#configuration` | Environment variable handling |
| 5 | Observability | `#observability` | OpenTelemetry integration |
| 6 | Bootstrap | `#bootstrap` | Application initialization |
| 7 | Access Manager Integration | `#access-manager-integration-mandatory` | **CONDITIONAL** - Check if project has auth |
| 8 | License Manager Integration | `#license-manager-integration-mandatory` | **CONDITIONAL** - Check if project is licensed |
| 9 | Data Transformation | `#data-transformation-toentityfromentity-mandatory` | ToEntity/FromEntity patterns |
| 10 | Error Codes Convention | `#error-codes-convention-mandatory` | Service-prefixed codes |
| 11 | Error Handling | `#error-handling` | Error wrapping and checking |
| 12 | Function Design | `#function-design-mandatory` | Single responsibility |
| 13 | Pagination Patterns | `#pagination-patterns` | Cursor and page-based |
| 14 | Testing | `#testing` | Table-driven tests, edge cases |
| 15 | Logging | `#logging` | Structured logging with lib-commons |
| 16 | Linting | `#linting` | golangci-lint configuration |
| 17 | Architecture Patterns | `#architecture-patterns` | Hexagonal architecture |
| 18 | Directory Structure | `#directory-structure` | Lerian pattern |
| 19 | Concurrency Patterns | `#concurrency-patterns` | Goroutines, channels, errgroup |
| 20 | RabbitMQ Worker Pattern | `#rabbitmq-worker-pattern` | Async message processing |

---

### backend-engineer-typescript → typescript.md

| # | Section to Check | Anchor | Key Subsections |
|---|------------------|--------|-----------------|
| 1 | Version | `#version` | TypeScript 5.0+, Node.js 20+ |
| 2 | Strict Configuration | `#strict-configuration-mandatory` | tsconfig.json strict mode |
| 3 | Frameworks & Libraries | `#frameworks--libraries` | Express, Fastify, NestJS, Prisma, Zod, Vitest |
| 4 | Type Safety | `#type-safety` | No any, branded types, discriminated unions |
| 5 | Zod Validation Patterns | `#zod-validation-patterns` | Schema validation |
| 6 | Dependency Injection | `#dependency-injection` | TSyringe patterns |
| 7 | AsyncLocalStorage for Context | `#asynclocalstorage-for-context` | Request context propagation |
| 8 | Testing | `#testing` | Type-safe mocks, fixtures, edge cases |
| 9 | Error Handling | `#error-handling` | Custom error classes |
| 10 | Function Design | `#function-design-mandatory` | Single responsibility |
| 11 | Naming Conventions | `#naming-conventions` | Files, interfaces, types |
| 12 | Directory Structure | `#directory-structure` | Lerian pattern |
| 13 | RabbitMQ Worker Pattern | `#rabbitmq-worker-pattern` | Async message processing |

---

### frontend-bff-engineer-typescript → typescript.md

**Same sections as backend-engineer-typescript (13 sections).** See above.

---

### frontend-engineer → frontend.md

| # | Section to Check | Anchor |
|---|------------------|--------|
| 1 | Framework | `#framework` |
| 2 | Libraries & Tools | `#libraries--tools` |
| 3 | State Management Patterns | `#state-management-patterns` |
| 4 | Form Patterns | `#form-patterns` |
| 5 | Styling Standards | `#styling-standards` |
| 6 | Typography Standards | `#typography-standards` |
| 7 | Animation Standards | `#animation-standards` |
| 8 | Component Patterns | `#component-patterns` |
| 9 | Accessibility | `#accessibility` |
| 10 | Performance | `#performance` |
| 11 | Directory Structure | `#directory-structure` |
| 12 | Forbidden Patterns | `#forbidden-patterns` |
| 13 | Standards Compliance Categories | `#standards-compliance-categories` |

---

### frontend-designer → frontend.md

**Same sections as frontend-engineer (13 sections).** See above.

---

### devops-engineer → devops.md

| # | Section to Check | Subsections (ALL REQUIRED) |
|---|------------------|---------------------------|
| 1 | Cloud Provider (MANDATORY) | Provider table |
| 2 | Infrastructure as Code (MANDATORY) | Terraform structure, State management, Module pattern, Best practices |
| 3 | Containers (MANDATORY) | **Dockerfile patterns, Docker Compose (Local Dev), .env file**, Image guidelines |
| 4 | Helm (MANDATORY) | Chart structure, Chart.yaml, values.yaml |
| 5 | Observability (MANDATORY) | Logging (Structured JSON), Tracing (OpenTelemetry) |
| 6 | Security (MANDATORY) | Secrets management, Network policies |
| 7 | Makefile Standards (MANDATORY) | Required commands (build, lint, test, cover, up, down, etc.), Component delegation pattern |

**⛔ HARD GATE:** When checking "Containers", you MUST verify BOTH Dockerfile AND Docker Compose patterns. Checking only one = INCOMPLETE.

**⛔ HARD GATE:** When checking "Makefile Standards", you MUST verify ALL required commands exist: `build`, `lint`, `test`, `cover`, `up`, `down`, `start`, `stop`, `restart`, `rebuild-up`, `set-env`, `generate-docs`.

---

### sre → sre.md

| # | Section to Check | Anchor |
|---|------------------|--------|
| 1 | Observability | `#observability` |
| 2 | Logging | `#logging` |
| 3 | Tracing | `#tracing` |
| 4 | OpenTelemetry with lib-commons | `#opentelemetry-with-lib-commons-mandatory-for-go` |
| 5 | Structured Logging with lib-common-js | `#structured-logging-with-lib-common-js-mandatory-for-typescript` |
| 6 | Health Checks | `#health-checks` |

---

### qa-analyst → golang.md OR typescript.md

**Note:** qa-analyst checks testing-related sections based on project language.

**For Go projects:**
| # | Section to Check |
|---|------------------|
| 1 | Testing Patterns (MANDATORY) |
| 2 | Edge Case Coverage (MANDATORY) |
| 3 | Test Naming Convention (MANDATORY) |
| 4 | Linting (MANDATORY) |

**For TypeScript projects:**
| # | Section to Check |
|---|------------------|
| 1 | Testing Patterns (MANDATORY) |
| 2 | Edge Case Coverage (MANDATORY) |
| 3 | Type Safety Rules (MANDATORY) |

**Test Quality Gate Checks (Gate 3 Exit - ALL REQUIRED):**
| # | Check | Detection |
|---|-------|-----------|
| 1 | Skipped tests | `grep -rn "\.skip\|\.todo\|xit"` = 0 |
| 2 | Assertion-less tests | All tests have expect/assert |
| 3 | Shared state | No beforeAll DB/state mutation |
| 4 | Edge cases | ≥2 per acceptance criterion |
| 5 | TDD evidence | RED phase captured |
| 6 | Test isolation | No order dependency |

---

## Maintenance Instructions

**When you add/modify a section in a standards file:**

1. Edit `dev-team/docs/standards/{file}.md` - Add your new `## Section Name`
2. Edit THIS file - Add the section to the corresponding agent table above
3. Verify row count matches section count

**Anti-Rationalization:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll update the index later" | Later = never. Sync drift causes missed checks. | **Update BOTH files in same commit** |
| "The section is minor" | Minor ≠ optional. All sections must be indexed. | **Add to index regardless of size** |
| "Agents parse dynamically anyway" | Index is the explicit contract. Dynamic is backup. | **Index is source of truth** |
