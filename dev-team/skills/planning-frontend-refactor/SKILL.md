---
name: ring:dev-refactor-frontend
description: |
  Analyzes frontend codebase against Ring standards and generates refactoring tasks
  for ring:dev-cycle-frontend. Dispatches frontend-specific agents in ANALYSIS mode.
---

# Dev Refactor Frontend

## When to use
- User wants to refactor existing frontend project to follow standards
- Legacy React/Next.js codebase needs modernization
- Frontend project audit requested

## Skip when
- Greenfield project → Use /ring:pre-dev-* instead
- Single file fix → Use ring:dev-cycle-frontend directly
- Backend-only project → Use ring:dev-refactor instead

## Sequence
**Runs before:** ring:dev-cycle-frontend


Analyzes existing frontend codebase against Ring/Lerian standards and generates refactoring tasks for ring:dev-cycle-frontend.

You orchestrate. Agents analyze. NEVER use Bash/Grep/Read to analyze code — dispatch agents.

## Gap Principle

Every divergence from Ring standards = a mandatory gap. No exceptions.

All divergences → FINDING-XXX → REFACTOR-XXX task → ring:dev-cycle-frontend input.

## Architecture Pattern Applicability

| Project Type | Apply Frontend Standards? |
|---|---|
| Full React/Next.js App | ✅ YES — all frontend.md sections |
| Design System Library | ✅ YES |
| Landing page / static | ⚡ PARTIAL — directory + styling only |
| Utility / config package | ❌ NO |

## Standards Loading

Pre-fetch before any step:
```
WebFetch: https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md
WebFetch: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md
WebFetch: testing-accessibility.md, testing-visual.md, testing-e2e.md, testing-performance.md
```
STOP if any fetch fails.

## Execution Steps

### Step 1: Validate Prerequisites

- Check `docs/PROJECT_RULES.md` exists → STOP if missing
- Detect UI library mode: read `package.json`
  - `@lerianstudio/sindarian-ui` → `sindarian-ui`
  - Otherwise → `fallback-only`
- If `go.mod` and no React → STOP: use `ring:dev-refactor`

### Step 2: Generate Codebase Report

Dispatch `ring:codebase-explorer`:

```
Generate comprehensive codebase report: project structure, React/Next.js patterns,
component architecture, state management, forms, styling, testing approach,
package.json dependencies. Output: docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md
```

### Step 3: Dispatch Frontend Specialist Agents (parallel)

Verify `codebase-report.md` exists before dispatching.

**Dispatch all 3 in ONE message:**

```yaml
Task 1: ring:frontend-engineer (MODE: ANALYSIS only)
  - Load frontend.md via WebFetch
  - Check all 19 sections per standards-coverage-table.md
  - Flag framework/library mismatches vs standards
  - File size enforcement: >1000 lines = ISSUE-XXX
  - UI Library Mode: {ui_library_mode}
  - Output: Standards Coverage Table + ISSUE-XXX per finding

Task 2: ring:qa-analyst-frontend (MODE: ANALYSIS only)
  - Check all 19 testing sections (ACC, VIS, E2E, PERF)
  - UI Library Mode: {ui_library_mode}
  - Output: Standards Coverage Table + ISSUE-XXX for gaps

Task 3: ring:ui-engineer (MODE: ANALYSIS only)
  - Check Sindarian UI component usage compliance
  - If ui_library_mode = "fallback-only", check custom component WCAG 2.1 AA accessibility, responsive/layout fallback behavior, and design-token/theme fallback usage
  - For fallback-only mode, output ISSUE-XXX per violation plus a short note that frontend-engineer and qa-analyst-frontend own baseline implementation/testing coverage
  - Output: ISSUE-XXX for non-compliant usage
```

### Step 4: Map Findings → Tasks

After all agents complete:

1. Save reports to `docs/ring:dev-refactor-frontend/{timestamp}/`
2. Map each ISSUE-XXX → FINDING-XXX
3. Generate `findings.md`
4. Map each FINDING-XXX → REFACTOR-XXX (1:1)
5. Generate `tasks.md` (ring:dev-cycle-frontend compatible)

**Findings template:**
```markdown
## FINDING-001: {Pattern Name} in {file_path}
- **Severity:** CRITICAL | HIGH | MEDIUM | LOW
- **File:** {path}:{line}
- **Current:** {code or description}
- **Expected:** {Ring standard}
```

### Step 5: Visual Report + User Approval

Generate visual HTML summary → `ring:visualize`.
Present to user. Wait for explicit APPROVED.

### Step 6: Save + Handoff

Save all artifacts. Handoff to `ring:dev-cycle-frontend`.

## Severity Reference

| Severity | Criteria |
|---|---|
| CRITICAL | Security risk, WCAG legal issue, build broken |
| HIGH | Missing server components, Lighthouse < 80, wrong pattern |
| MEDIUM | Client component overuse, missing snapshots |
| LOW | Naming conventions, file organization |
