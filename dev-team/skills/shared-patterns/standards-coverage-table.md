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
| Observability | Logging AND Tracing |
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
**Total Sections Found:** 15
**Table Rows:** 15 (MUST match)

| # | Section (from WebFetch) | Status | Evidence |
|---|-------------------------|--------|----------|
| 1 | Core Dependency: lib-commons | ✅ | go.mod:5 |
| 2 | Configuration Loading | ⚠️ | internal/config/config.go:12 |
| 3 | Telemetry & Observability | ❌ | Not implemented |
| 4 | Bootstrap Pattern | ✅ | cmd/server/main.go:15 |
| 5 | Data Transformation | ✅ | internal/adapters/postgres/mapper.go:8 |
| 6 | Error Codes Convention | ⚠️ | Uses generic codes |
| 7 | Error Handling | ✅ | Consistent pattern |
| 8 | Pagination Patterns | N/A | No list endpoints |
| 9 | Testing Patterns | ❌ | No tests found |
| 10 | Logging Standards | ⚠️ | Missing structured fields |
| 11 | Linting | ✅ | .golangci.yml present |
| 12 | Architecture Patterns | ✅ | Hexagonal structure |
| 13 | Directory Structure | ✅ | Follows convention |
| 14 | Concurrency Patterns | N/A | No concurrent code |
| 15 | RabbitMQ Worker Pattern | N/A | No message queue |

**Completeness Verification:**
- Sections in standards: 15
- Rows in table: 15
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

### backend-engineer-golang → golang.md

| # | Section to Check |
|---|------------------|
| 1 | Core Dependency: lib-commons (MANDATORY) |
| 2 | Frameworks & Libraries |
| 3 | Configuration Loading (MANDATORY) |
| 4 | Telemetry & Observability (MANDATORY) |
| 5 | Bootstrap Pattern (MANDATORY) |
| 6 | Data Transformation: ToEntity/FromEntity (MANDATORY) |
| 7 | Error Codes Convention (MANDATORY) |
| 8 | Error Handling |
| 9 | Pagination Patterns |
| 10 | Testing Patterns |
| 11 | Logging Standards |
| 12 | Linting |
| 13 | Architecture Patterns |
| 14 | Directory Structure |
| 15 | Concurrency Patterns |
| 16 | DDD Patterns (Go Implementation) |
| 17 | RabbitMQ Worker Pattern |

---

### backend-engineer-typescript → typescript.md

| # | Section to Check |
|---|------------------|
| 1 | Strict Configuration (MANDATORY) |
| 2 | Frameworks & Libraries |
| 3 | Type Safety Rules |
| 4 | Zod Validation Patterns |
| 5 | Dependency Injection |
| 6 | AsyncLocalStorage for Context |
| 7 | Testing Patterns |
| 8 | Error Handling |
| 9 | DDD Patterns (TypeScript Implementation) |
| 10 | Naming Conventions |
| 11 | Directory Structure (Backend) |
| 12 | RabbitMQ Worker Pattern |

---

### frontend-bff-engineer-typescript → typescript.md

| # | Section to Check |
|---|------------------|
| 1 | Strict Configuration (MANDATORY) |
| 2 | Frameworks & Libraries |
| 3 | Type Safety Rules |
| 4 | Zod Validation Patterns |
| 5 | Dependency Injection |
| 6 | AsyncLocalStorage for Context |
| 7 | Testing Patterns |
| 8 | Error Handling |
| 9 | DDD Patterns (TypeScript Implementation) |
| 10 | Naming Conventions |
| 11 | Directory Structure (Backend) |
| 12 | RabbitMQ Worker Pattern |

---

### frontend-engineer → frontend.md

| # | Section to Check |
|---|------------------|
| 1 | Framework |
| 2 | Libraries & Tools |
| 3 | State Management Patterns |
| 4 | Form Patterns |
| 5 | Styling Standards |
| 6 | Typography Standards |
| 7 | Animation Standards |
| 8 | Component Patterns |
| 9 | Accessibility (a11y) |
| 10 | Performance |
| 11 | Directory Structure |
| 12 | FORBIDDEN Patterns |
| 13 | Standards Compliance Categories |

---

### frontend-designer → frontend.md

| # | Section to Check |
|---|------------------|
| 1 | Framework |
| 2 | Libraries & Tools |
| 3 | State Management Patterns |
| 4 | Form Patterns |
| 5 | Styling Standards |
| 6 | Typography Standards |
| 7 | Animation Standards |
| 8 | Component Patterns |
| 9 | Accessibility (a11y) |
| 10 | Performance |
| 11 | Directory Structure |
| 12 | FORBIDDEN Patterns |
| 13 | Standards Compliance Categories |

---

### devops-engineer → devops.md

| # | Section to Check | Subsections (ALL REQUIRED) |
|---|------------------|---------------------------|
| 1 | Cloud Provider | Provider table |
| 2 | Infrastructure as Code | Terraform structure, State management, Module pattern, Best practices |
| 3 | Containers | **Dockerfile patterns, Docker Compose (Local Dev)**, Image guidelines |
| 4 | Helm | Chart structure, Chart.yaml, values.yaml |
| 5 | Observability | Metrics (Prometheus), Logging (Structured JSON), Tracing (OpenTelemetry) |
| 6 | Security | Secrets management, Network policies |

**⛔ HARD GATE:** When checking "Containers", you MUST verify BOTH Dockerfile AND Docker Compose patterns. Checking only one = INCOMPLETE.

---

### sre → sre.md

| # | Section to Check |
|---|------------------|
| 1 | Observability Stack |
| 2 | Logging Standards |
| 3 | Tracing Standards |
| 4 | OpenTelemetry with lib-commons (MANDATORY for Go) |
| 5 | Structured Logging with lib-common-js (MANDATORY for TypeScript) |
| 6 | Health Checks |

---

### qa-analyst → golang.md OR typescript.md

**Note:** qa-analyst checks testing-related sections based on project language.

**For Go projects:**
| # | Section to Check |
|---|------------------|
| 1 | Testing Patterns |
| 2 | Linting |

**For TypeScript projects:**
| # | Section to Check |
|---|------------------|
| 1 | Testing Patterns |
| 2 | Type Safety Rules |

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
