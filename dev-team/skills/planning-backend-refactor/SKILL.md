---
name: ring:dev-refactor
description: Analyzes backend codebase (Go/TypeScript) against standards and generates refactoring tasks for ring:dev-cycle. For frontend projects, use ring:dev-refactor-frontend instead.
---

# Dev Refactor Skill

## When to use
- User wants to refactor existing project to follow standards
- Legacy codebase needs modernization
- Project audit requested

## Skip when
- Greenfield project → Use /pre-dev-* instead
- Single file fix → Use ring:dev-cycle directly
- Frontend project → Use ring:dev-refactor-frontend


Analyzes existing backend codebase against Ring/Lerian standards and generates refactoring tasks for ring:dev-cycle.

You orchestrate. Agents analyze. NEVER run Bash/Grep/Read to analyze code directly — dispatch agents.

## Gap Principle

Every divergence from Ring standards = a mandatory gap to implement. No exceptions.

All divergences → FINDING-XXX → REFACTOR-XXX task → ring:dev-cycle input.

## Architecture Pattern Applicability

| Service Type | Apply Hexagonal/Lerian Pattern? |
|---|---|
| CRUD API | ✅ YES |
| Complex business logic | ✅ YES |
| Event-driven systems | ✅ YES |
| CLI tools / scripts | ❌ NO |
| Workers / background jobs | ❌ NO |
| Simple lambdas | ❌ NO |

## Execution Steps

### Step 1: Validate Prerequisites

- Check `docs/PROJECT_RULES.md` exists → STOP if missing
- Detect stack: `go.mod` → Go; `package.json` + Express/Fastify/NestJS (no React) → TypeScript
- If `package.json` + React/Next.js → STOP: use `ring:dev-refactor-frontend`

### Step 2: Generate Codebase Report

Dispatch `ring:codebase-explorer`:

```
Generate comprehensive codebase report: project structure, architecture pattern,
tech stack, code patterns (config, database, handlers, errors, telemetry, testing),
key files inventory with file:line references, code snippets.
Output: docs/ring:dev-refactor/{timestamp}/codebase-report.md
```

### Step 3: Dispatch Specialist Agents (parallel)

Verify `codebase-report.md` exists before dispatching.

**For Go projects — dispatch backend analysis:**

```yaml
Task 1: ring:backend-engineer-golang (MODE: ANALYSIS only)
  - Load golang.md via WebFetch
  - Check all sections per shared-patterns/standards-coverage-table.md
  - Flag framework/library mismatches vs standards
  - File size enforcement: >1000 lines = ISSUE-XXX (HIGH), >1500 = CRITICAL
  - Multi-tenant analysis per shared-patterns/multi-tenant-analysis.md
  - Check tests, coverage, docker-compose/local runtime, and observability as backend-owned responsibilities
  - Output: Standards Coverage Table + ISSUE-XXX per finding
```

**For TypeScript projects:**
Use `ring:backend-engineer-typescript` with the same analysis contract.

### Step 4: Map Findings → Tasks

After all agents complete:

1. Save individual agent reports to `docs/ring:dev-refactor/{timestamp}/`
2. Map each ISSUE-XXX → FINDING-XXX (normalize severity, add file:line, current vs expected)
3. Generate `docs/ring:dev-refactor/{timestamp}/findings.md`
4. Map each FINDING-XXX → one REFACTOR-XXX task (1:1 mapping)
5. Generate `docs/ring:dev-refactor/{timestamp}/tasks.md` (ring:dev-cycle compatible)

**Findings template:**
```markdown
# {project-name} Refactor Findings

## FINDING-001: {Pattern Name} in {file_path}
- **Severity:** CRITICAL | HIGH | MEDIUM | LOW
- **File:** {path}:{line}
- **Current:** {code or description}
- **Expected:** {Ring standard}
- **Standard Reference:** {standards doc section}
```

**Tasks template:**
```markdown
# {project-name} Refactor Tasks

## REFACTOR-001: {Pattern Name} in {file_path}
- **Finding:** FINDING-001
- **Estimated Complexity:** trivial | moderate | complex
- **Acceptance Criteria:**
  - [ ] {specific, testable criteria}
```

### Step 5: Visual Change Report + User Approval

Generate visual HTML summary of KILL/CHANGE/ADD operations → dispatch `ring:visualize`.

Present to user for approval. Wait for explicit APPROVED.

### Step 6: Save + Handoff

Save all artifacts to `docs/ring:dev-refactor/{timestamp}/`.

Handoff to `ring:dev-cycle`: feed tasks.md as input.

## Agent Analysis Report Template

```markdown
# {Agent Name} Analysis Report

## EXPLORATION SUMMARY
High-level architecture assessment

## KEY FINDINGS
ISSUE-XXX list with file:line, current, expected

## ARCHITECTURE INSIGHTS
Patterns detected, notable deviations

## RELEVANT FILES
Files most impacted by findings

## RECOMMENDATIONS
Priority order for refactoring
```
