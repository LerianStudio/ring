---
name: dev-refactor-frontend
description: |
  Analyzes frontend codebase against Ring standards and generates refactoring tasks
  for ring:dev-cycle-frontend. Dispatches frontend-specific agents in ANALYSIS mode.
metadata:
  input_schema:
    required: []
    optional:
    - name: project_path
      type: string
      description: 'Path to frontend project root (default: current directory)'
    - name: prompt
      type: string
      description: Direct instruction for refactoring focus
    - name: standards_path
      type: string
      description: 'Custom standards file path (default: Ring standards via WebFetch)'
    - name: analyze_only
      type: boolean
      description: Generate report without executing ring:dev-cycle-frontend
    - name: critical_only
      type: boolean
      description: Limit execution to Critical and High severity (analysis still tracks all)
    - name: dry_run
      type: boolean
      description: Show what would be analyzed without executing
  output_schema:
    format: markdown
    artifacts:
    - name: codebase-report.md
      description: Codebase analysis from ring:codebase-explorer
    - name: reports/{agent-name}-report.md
      description: Individual agent analysis reports
    - name: findings.md
      description: All findings mapped from agent reports
    - name: tasks.md
      description: 1:1 mapped REFACTOR-XXX tasks from findings
    - name: change-report.html
      description: Visual HTML change report from ring:visual-explainer
    traceability: Ring Standard -> Agent Report -> FINDING-XXX -> REFACTOR-XXX -> Implementation
  related:
    complementary:
    - ring:dev-refactor
    - ring:dev-cycle-frontend
    - ring:using-dev-team
  sequence:
    before:
    - ring:dev-cycle-frontend
  skip_when: |
    - Greenfield project -> Use /ring:pre-dev-* instead
    - Single file fix -> Use ring:dev-cycle-frontend directly
    - Backend-only project -> Use ring:dev-refactor instead
  trigger: |
    - User wants to refactor existing frontend project to follow standards
    - Legacy React/Next.js codebase needs modernization
    - Frontend project audit requested
---

# Dev Refactor Frontend Skill

Analyzes existing frontend codebase against Ring/Lerian standards and generates refactoring tasks compatible with ring:dev-cycle-frontend.

---

## Standards Loading (MANDATORY)

**Before any step execution, you MUST load Ring standards.**

### Standards Source Resolution

```text
if standards_path is provided:
  → Read tool: {standards_path}
  → If file not found or empty: STOP and report blocker
  → Use loaded content as frontend standards
else:
  → WebFetch the default Ring standards (see URLs below)
```

**Default URLs (used when `standards_path` is not provided):**

<fetch_required>
https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md
</fetch_required>

Fetch URLs above and extract: Agent Modification Verification requirements, Anti-Rationalization Tables requirements, Critical Rules, and Frontend Standards.

<block_condition>
- standards_path provided but file not found or empty
- standards_path not provided AND WebFetch fails or returns empty
- CLAUDE.md not accessible
</block_condition>

If any condition is true, STOP and report blocker. Cannot proceed without Ring standards.

---

## MANDATORY GAP PRINCIPLE (NON-NEGOTIABLE)

**any divergence from Ring standards = MANDATORY gap to implement.**

<cannot_skip>
- All divergences are gaps - Every difference MUST be tracked as FINDING-XXX
- Severity affects PRIORITY, not TRACKING - Low severity = lower priority, not "optional"
- No filtering allowed - You CANNOT decide which divergences "matter"
- No alternative patterns accepted - Different approach = STILL A GAP
- No cosmetic exceptions - Naming, formatting, structure differences = GAPS
</cannot_skip>

Non-negotiable, not open to interpretation - a HARD RULE.

### Anti-Rationalization: Mandatory Gap Principle

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for:
- **Refactor Gap Tracking** section (mandatory gap principle rationalizations)
- **Gate Execution** section (workflow skip rationalizations)
- **TDD** section (test-first rationalizations)
- **Universal** section (general anti-patterns)

### Verification Rule

```
COUNT(non-checkmark items in all Standards Coverage Tables) == COUNT(FINDING-XXX entries)

If counts don't match -> SKILL FAILURE. Go back and add missing findings.
```

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Security risk, accessibility legal issue, production blocker | XSS vulnerability, WCAG violation blocking users, build broken |
| **HIGH** | Major standards violation, performance regression | Missing server components, Lighthouse < 80, wrong pattern |
| **MEDIUM** | Code quality, component structure issues | Client component overuse, missing snapshots |
| **LOW** | Best practices, documentation | Naming conventions, file organization |

**All severities are MANDATORY to track.** Severity affects PRIORITY of execution, NOT whether to track.

---

## Architecture Pattern Applicability

**Not all architecture patterns apply to all frontend projects.** Before flagging gaps, verify the pattern is applicable.

| Service Type | Component Architecture | Directory Structure |
|--------------|------------------------|---------------------|
| Full React/Next.js App | APPLY (App Router, Server/Client components) | APPLY (frontend.md section 11) |
| Design System Library | APPLY | APPLY |
| Landing Page / Static | PARTIAL | APPLY |
| Utility / Config Package | NOT APPLICABLE | NOT APPLICABLE |

### Detection Criteria

**Full React/Next.js App (Frontend Standards APPLICABLE):**
- Project uses React/Next.js as framework
- Contains components, pages, and state management
- Uses App Router or Pages Router
- Has frontend routing and navigation
- -> **MUST follow frontend.md standards**

**Simple Frontend (Partial applicability):**
- Landing pages with minimal interactivity
- Static site generators (no dynamic data)
- -> Apply directory structure and styling; skip state management, BFF patterns

### Agent Instruction

When dispatching specialist agents, include:

```
ARCHITECTURE APPLICABILITY CHECK:
1. If project is a full React/Next.js app -> APPLY all frontend.md sections
2. If project is a static/landing page -> APPLY directory structure and styling only
3. If project is a utility package -> Do not flag frontend-specific gaps
```

---

## MANDATORY: Initialize Todo List FIRST

**Before any other action, create the todo list with all steps:**

```yaml
TodoWrite:
  todos:
    - content: "Validate PROJECT_RULES.md exists"
      status: "pending"
      activeForm: "Validating PROJECT_RULES.md exists"
    - content: "Detect frontend stack and UI library mode"
      status: "pending"
      activeForm: "Detecting frontend stack"
    - content: "Read PROJECT_RULES.md for context"
      status: "pending"
      activeForm: "Reading PROJECT_RULES.md"
    - content: "Generate codebase report via ring:codebase-explorer"
      status: "pending"
      activeForm: "Generating codebase report"
    - content: "Dispatch frontend specialist agents in parallel"
      status: "pending"
      activeForm: "Dispatching frontend specialist agents"
    - content: "Save individual agent reports"
      status: "pending"
      activeForm: "Saving agent reports"
    - content: "Map agent findings to FINDING-XXX entries"
      status: "pending"
      activeForm: "Mapping agent findings"
    - content: "Generate findings.md"
      status: "pending"
      activeForm: "Generating findings.md"
    - content: "Map findings 1:1 to REFACTOR-XXX tasks"
      status: "pending"
      activeForm: "Mapping findings to tasks (1:1)"
    - content: "Generate tasks.md"
      status: "pending"
      activeForm: "Generating tasks.md"
    - content: "Generate visual change report"
      status: "pending"
      activeForm: "Generating visual change report"
    - content: "Get user approval"
      status: "pending"
      activeForm: "Getting user approval"
    - content: "Save all artifacts"
      status: "pending"
      activeForm: "Saving artifacts"
    - content: "Handoff to ring:dev-cycle-frontend"
      status: "pending"
      activeForm: "Handing off to ring:dev-cycle-frontend"
```

**This is NON-NEGOTIABLE. Do not skip creating the todo list.**

---

## Input Flags: Early Exit Check

```text
if dry_run == true:
  → Execute Step 1 (Validate PROJECT_RULES.md) and Step 1b (Detect Frontend Stack)
  → Output dry-run summary:
      - Project path: {project_path or current directory}
      - Standards source: {standards_path or "Ring defaults via WebFetch"}
      - Frontend stack detected: {React/Next.js version}
      - UI library mode: {sindarian-ui / fallback-only}
      - Agents that would be dispatched: {list of 5-7 agents}
      - Conditional agents: {BFF if detected, UI Engineer if ux-criteria.md exists}
      - Artifact path: docs/ring:dev-refactor-frontend/{timestamp}/
  → Mark all remaining todos as `completed` (skipped - dry run)
  → TERMINATE with "Dry run complete. Re-run without --dry-run to execute."
```

**If `dry_run` is not true, continue to next section.**

---

## CRITICAL: Specialized Agents Perform All Tasks

See [shared-patterns/shared-orchestrator-principle.md](../shared-patterns/shared-orchestrator-principle.md) for full ORCHESTRATOR principle, role separation, forbidden/required actions, step-to-agent mapping, and anti-rationalization table.

**Summary:** You orchestrate. Agents execute. If using Bash/Grep/Read to analyze code, STOP. Dispatch agent.

---

## Step 1: Validate PROJECT_RULES.md

**TodoWrite:** Mark "Validate PROJECT_RULES.md exists" as `in_progress`

<block_condition>
- docs/PROJECT_RULES.md does not exist
</block_condition>

If condition is true, output blocker and TERMINATE. Otherwise continue to Step 1b.

**Check:** Does `docs/PROJECT_RULES.md` exist?

- **YES** -> Mark todo as `completed`, continue to Step 1b
- **NO** -> Output blocker and TERMINATE:

```markdown
## BLOCKED: PROJECT_RULES.md Not Found

Cannot proceed without project standards baseline.

**Required Action:** Create `docs/PROJECT_RULES.md` with:
- Architecture patterns
- Code conventions
- Testing requirements
- Technology stack decisions

Re-run after file exists.
```

---

## Step 1b: Detect Frontend Stack

**TodoWrite:** Mark "Detect frontend stack and UI library mode" as `in_progress`

**⛔ SCOPE: FRONTEND AND BFF CODE ONLY.** This skill analyzes frontend code (React, Next.js) and BFF layers exclusively. MUST use `ring:dev-refactor` for backend code (Go, pure TypeScript backend with Express/Fastify/NestJS without React).

**⛔ FORBIDDEN:** Dispatching `ring:backend-engineer-golang` or `ring:backend-engineer-typescript` from this skill. These are backend agents and belong to `ring:dev-refactor`.

**MANDATORY: Verify this is a frontend project. If not, redirect.**

Check for frontend indicators:

| Check | Detection | Result |
|-------|-----------|--------|
| `package.json` exists | Glob for `package.json` | Required |
| React/Next.js in deps | `react`, `next` in dependencies | Required for frontend |
| `@lerianstudio/sindarian-ui` in deps | Check dependencies/devDependencies | Store `ui_library_mode` |
| BFF layer detected | `/api/` routes, Express/Fastify in deps | Add `ring:frontend-bff-engineer-typescript` |
| `ux-criteria.md` exists | `docs/pre-dev/*/ux-criteria.md` | Add `ring:ui-engineer` |

**Detection Logic:**

```text
1. package.json exists?
   NO  -> STOP: "Not a Node.js project. Use ring:dev-refactor instead."
   YES -> Continue

2. React or Next.js in dependencies?
   NO  -> STOP: "Not a frontend project. Use ring:dev-refactor instead."
   YES -> Continue

3. @lerianstudio/sindarian-ui in dependencies?
   YES -> ui_library_mode = "sindarian-ui"
   NO  -> ui_library_mode = "fallback-only"

4. BFF layer detected? (/api/ routes, Express/Fastify in deps)
   YES -> dispatch_bff = true
   NO  -> dispatch_bff = false

5. ux-criteria.md exists?
   YES -> dispatch_ui_engineer = true
   NO  -> dispatch_ui_engineer = false
```

**TodoWrite:** Mark "Detect frontend stack and UI library mode" as `completed`

---

## Step 2: Read PROJECT_RULES.md

**TodoWrite:** Mark "Read PROJECT_RULES.md for context" as `in_progress`

```
Read tool: docs/PROJECT_RULES.md
```

Extract project-specific conventions for agent context.

**TodoWrite:** Mark "Read PROJECT_RULES.md for context" as `completed`

---

## Step 3: Generate Codebase Report

**TodoWrite:** Mark "Generate codebase report via ring:codebase-explorer" as `in_progress`

### MANDATORY: Use Task Tool with ring:codebase-explorer

<dispatch_required agent="ring:codebase-explorer">
Generate a comprehensive frontend codebase report describing WHAT EXISTS.

Include:
- Project structure and directory layout
- React/Next.js architecture (App Router vs Pages Router, Server vs Client components)
- UI library usage (sindarian-ui, shadcn/ui, custom components)
- State management patterns (TanStack Query, Zustand, Context)
- Form handling patterns (React Hook Form, Zod)
- Styling approach (TailwindCSS, CSS Modules, styled-components)
- Testing setup (Vitest, Playwright, Testing Library)
- Performance configuration (next.config, image optimization)
- Key files inventory with file:line references
- Code snippets showing current implementation patterns
</dispatch_required>

<output_required>
## EXPLORATION SUMMARY
[Your summary here]

## KEY FINDINGS
[Your findings here]

## ARCHITECTURE INSIGHTS
[Your insights here]

## RELEVANT FILES
[Your file inventory here]

## RECOMMENDATIONS
[Your recommendations here]
</output_required>

Do not complete without outputting full report in the format above.

### Anti-Rationalization Table for Step 3

See [shared-patterns/anti-rationalization-codebase-explorer.md](../shared-patterns/anti-rationalization-codebase-explorer.md) for the ring:codebase-explorer dispatch anti-rationalization table.

### FORBIDDEN Actions for Step 3

<forbidden>
- Bash(command="find ... -name '*.tsx'") -> SKILL FAILURE
- Bash(command="ls -la ...") -> SKILL FAILURE
- Bash(command="tree ...") -> SKILL FAILURE
- Task(subagent_type="Explore", ...) -> SKILL FAILURE
- Task(subagent_type="general-purpose", ...) -> SKILL FAILURE
- Task(subagent_type="Plan", ...) -> SKILL FAILURE
</forbidden>

Any of these = IMMEDIATE SKILL FAILURE.

### REQUIRED Action for Step 3

```
Task(subagent_type="ring:codebase-explorer", ...)
```

**Timestamp format:** `{timestamp}` = `YYYY-MM-DDTHH:MM:SS` (e.g., `2026-02-10T15:30:00`). Generate once at start, reuse for all artifacts.

**After Task completes, save with Write tool:**

```
Write tool:
  file_path: "docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md"
  content: [Task output]
```

**TodoWrite:** Mark "Generate codebase report via ring:codebase-explorer" as `completed`

---

## Step 4: Dispatch Frontend Specialist Agents

**TodoWrite:** Mark "Dispatch frontend specialist agents in parallel" as `in_progress`

### HARD GATE: Verify codebase-report.md Exists

**BEFORE dispatching any specialist agent, verify:**

```
Check 1: Does docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md exist?
  - YES -> Continue to dispatch agents
  - NO  -> STOP. Go back to Step 3.

Check 2: Was codebase-report.md created by ring:codebase-explorer?
  - YES -> Continue
  - NO (created by Bash output) -> DELETE IT. Go back to Step 3. Use correct agent.
```

**If you skipped Step 3 or used Bash instead of Task tool, you MUST go back and redo Step 3 correctly.**

### MANDATORY: Reference Standards Coverage Table

**All agents MUST follow [shared-patterns/standards-coverage-table.md](../shared-patterns/standards-coverage-table.md) which defines:**
- All sections to check per agent
- Required output format (Standards Coverage Table)
- Anti-rationalization rules
- Completeness verification

**Section indexes are pre-defined in shared-patterns. Agents MUST check all sections listed.**

---

### Always Dispatched (5 agents in parallel)

**Dispatch all 5 agents in ONE message (parallel):**

```yaml
Task tool 1:
  subagent_type: "ring:frontend-engineer"
  description: "Frontend standards analysis"
  prompt: |
    **MODE: ANALYSIS only**

    MANDATORY: Check all 19 sections in frontend.md per shared-patterns/standards-coverage-table.md

    FRAMEWORKS & LIBRARIES DETECTION (MANDATORY):
    1. Read package.json to extract all dependencies used in codebase
    2. Load frontend.md standards via WebFetch -> extract all listed frameworks/libraries
    3. For each category in standards (Framework, State, Forms, UI, Styling, Testing, etc.):
       - Compare codebase dependency vs standards requirement
       - If codebase uses DIFFERENT library than standards -> ISSUE-XXX
       - If codebase is MISSING required library -> ISSUE-XXX
    4. any library not in standards that serves same purpose = ISSUE-XXX

    UI Library Mode: {ui_library_mode}

    Input:
    - Ring Standards: Load via WebFetch (frontend.md)
    - Section Index: See shared-patterns/standards-coverage-table.md -> "ring:frontend-engineer"
    - Codebase Report: docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. ISSUE-XXX for each non-compliant finding with: Pattern name, Severity, file:line, Current Code, Expected Code

Task tool 2:
  subagent_type: "ring:qa-analyst-frontend"
  description: "Frontend testing analysis"
  prompt: |
    **MODE: ANALYSIS only**

    MANDATORY: Check all 19 testing sections per shared-patterns/standards-coverage-table.md -> "ring:qa-analyst-frontend"

    Analyze ALL testing dimensions:
    - Accessibility (ACC-1 to ACC-5): axe-core, semantic HTML, keyboard nav, focus, color contrast
    - Visual (VIS-1 to VIS-4): snapshots, state coverage, responsive, component duplication
    - E2E (E2E-1 to E2E-5): user flows, error paths, cross-browser, responsive, selectors
    - Performance (PERF-1 to PERF-5): Core Web Vitals, Lighthouse, bundle, server components, anti-patterns

    UI Library Mode: {ui_library_mode}

    Input:
    - Ring Standards: Load via WebFetch (frontend/testing-accessibility.md, testing-visual.md, testing-e2e.md, testing-performance.md)
    - Section Index: See shared-patterns/standards-coverage-table.md -> "ring:qa-analyst-frontend"
    - Codebase Report: docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format) for ALL 19 sections
    2. ISSUE-XXX for each non-compliant finding

Task tool 3:
  subagent_type: "ring:frontend-designer"
  description: "Frontend design analysis"
  prompt: |
    **MODE: ANALYSIS only**

    MANDATORY: Check all 19 sections in frontend.md per shared-patterns/standards-coverage-table.md -> "ring:frontend-designer"

    Focus on design perspective:
    - Typography standards (font selection, pairing, hierarchy)
    - Styling standards (TailwindCSS, CSS variables, design tokens)
    - Animation standards (transitions, Framer Motion usage)
    - Component patterns (compound components, design system compliance)
    - Accessibility UX (color contrast, focus indicators, motion preferences)

    UI Library Mode: {ui_library_mode}

    Input:
    - Ring Standards: Load via WebFetch (frontend.md)
    - Section Index: See shared-patterns/standards-coverage-table.md -> "ring:frontend-designer"
    - Codebase Report: docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. ISSUE-XXX for each non-compliant finding

Task tool 4:
  subagent_type: "ring:devops-engineer"
  description: "DevOps analysis"
  prompt: |
    **MODE: ANALYSIS only**
    Check all 8 sections per shared-patterns/standards-coverage-table.md -> "ring:devops-engineer"

    Frontend-specific DevOps focus:
    - Dockerfile for SSR/SSG Next.js app
    - Docker Compose for local development
    - Nginx configuration for static assets/reverse proxy
    - .env management for frontend environment variables
    - Makefile with frontend commands (dev, build, lint, test, e2e)
    - CI/CD pipeline for frontend build/test/deploy

    "Containers" means BOTH Dockerfile and Docker Compose
    "Makefile Standards" means all required commands

    Input:
    - Ring Standards: Load via WebFetch (devops.md)
    - Codebase Report: docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output: Standards Coverage Table + ISSUE-XXX for gaps

Task tool 5:
  subagent_type: "ring:sre"
  description: "Observability analysis"
  prompt: |
    **MODE: ANALYSIS only**
    Check all 6 sections per shared-patterns/standards-coverage-table.md -> "ring:sre"

    Frontend-specific observability focus:
    - Error tracking (error boundaries, global error handlers)
    - Health check endpoints (if SSR)
    - Real User Monitoring (RUM) / Core Web Vitals reporting
    - Structured client-side logging
    - Distributed tracing for BFF/API calls

    Input:
    - Ring Standards: Load via WebFetch (sre.md)
    - Codebase Report: docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output: Standards Coverage Table + ISSUE-XXX for gaps
```

### Conditionally Dispatched

**Add to the parallel dispatch if conditions from Step 1b are met:**

```yaml
Task tool 6 (if dispatch_bff == true):
  subagent_type: "ring:frontend-bff-engineer-typescript"
  description: "BFF TypeScript standards analysis"
  prompt: |
    **MODE: ANALYSIS only**

    MANDATORY: Check all 20 sections in typescript.md per shared-patterns/standards-coverage-table.md -> "frontend-bff-engineer-typescript"

    FRAMEWORKS & LIBRARIES DETECTION (MANDATORY):
    1. Read package.json to extract all dependencies used in codebase
    2. Load typescript.md standards via WebFetch -> extract all listed frameworks/libraries
    3. For each category in standards (Backend Framework, ORM, Validation, Testing, etc.):
       - Compare codebase dependency vs standards requirement
       - If codebase uses DIFFERENT library than standards -> ISSUE-XXX
       - If codebase is MISSING required library -> ISSUE-XXX
    4. any library not in standards that serves same purpose = ISSUE-XXX

    UI Library Mode: {ui_library_mode}

    Input:
    - Ring Standards: Load via WebFetch (typescript.md)
    - Section Index: See shared-patterns/standards-coverage-table.md -> "frontend-bff-engineer-typescript"
    - Codebase Report: docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. ISSUE-XXX for each non-compliant finding

Task tool 7 (if dispatch_ui_engineer == true):
  subagent_type: "ring:ui-engineer"
  description: "UI engineer standards analysis"
  prompt: |
    **MODE: ANALYSIS only**

    MANDATORY: Check all 19 sections in frontend.md per shared-patterns/standards-coverage-table.md -> "ring:ui-engineer"

    Additionally verify against product-designer outputs:
    - UX criteria compliance (ux-criteria.md)
    - User flow implementation (user-flows.md)
    - Wireframe adherence (wireframes/*.yaml)
    - UI states coverage (loading, error, empty, success)

    UI Library Mode: {ui_library_mode}

    Input:
    - Ring Standards: Load via WebFetch (frontend.md)
    - Section Index: See shared-patterns/standards-coverage-table.md -> "ring:ui-engineer"
    - UX Criteria: docs/pre-dev/{feature}/ux-criteria.md
    - Codebase Report: docs/ring:dev-refactor-frontend/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. UX Criteria Compliance table
    3. ISSUE-XXX for each non-compliant finding
```

### Agent Dispatch Summary

| Condition | Agents to Dispatch |
|-----------|-------------------|
| Always | Tasks 1-5 (Frontend Engineer + QA Frontend + Designer + DevOps + SRE) |
| BFF layer detected | + Task 6 (BFF Engineer) |
| ux-criteria.md exists | + Task 7 (UI Engineer) |

**TodoWrite:** Mark "Dispatch frontend specialist agents in parallel" as `completed`

---

## Step 4.5: Agent Report -> Findings Mapping (HARD GATE)

**TodoWrite:** Mark "Map agent findings to FINDING-XXX entries" as `in_progress`

**MANDATORY: all agent-reported issues MUST become findings.**

| Agent Report | Action |
|--------------|--------|
| Any difference between current code and Ring standard | -> Create FINDING-XXX |
| Any missing pattern from Ring standards | -> Create FINDING-XXX |
| Any deprecated pattern usage | -> Create FINDING-XXX |
| Any accessibility gap | -> Create FINDING-XXX |
| Any testing gap | -> Create FINDING-XXX |
| Any performance issue | -> Create FINDING-XXX |

### FORBIDDEN Actions for Step 4.5

```
Ignoring agent-reported issues because they seem "minor"  -> SKILL FAILURE
Filtering out issues based on personal judgment            -> SKILL FAILURE
Summarizing multiple issues into one finding               -> SKILL FAILURE
Skipping issues without ISSUE-XXX format from agent        -> SKILL FAILURE
Creating findings only for "interesting" gaps              -> SKILL FAILURE
```

### REQUIRED Actions for Step 4.5

```
Every line item from agent reports becomes a FINDING-XXX entry
Preserve agent's severity assessment exactly as reported
Include exact file:line references from agent report
Every non-compliant item in Standards Coverage Table = one FINDING-XXX
Count findings in Step 5 MUST equal total issues from all agent reports
```

---

### Anti-Rationalization Table for Step 4.5

**See also: "Anti-Rationalization: Mandatory Gap Principle" at top of this skill.**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Multiple similar issues can be one finding" | Distinct file:line = distinct finding. Merging loses traceability. | **One issue = One FINDING-XXX** |
| "Agent report didn't use ISSUE-XXX format" | Format varies; presence matters. Every gap = one finding. | **Extract all gaps into findings** |
| "I'll consolidate to reduce noise" | Consolidation = data loss. Noise is signal. | **Preserve all individual issues** |
| "Some findings are duplicates across agents" | Different agents = different perspectives. Keep both. | **Create separate findings per agent** |
| "Team has approved this deviation" | Team approval is not standards compliance. Document the gap. | **Create FINDING-XXX, note team decision** |
| "Fixing this would break existing code" | Breaking risk = implementation concern, not tracking concern. | **Create FINDING-XXX, note risk in description** |

### MANDATORY GAP RULE FOR STEP 4.5

**Per the Mandatory Gap Principle (see top of skill): any divergence from Ring standards = FINDING-XXX.**

This means:
- Compliant items in Standards Coverage Table = No finding needed
- Partial items = MUST create FINDING-XXX (partial compliance is a gap)
- Non-compliant items = MUST create FINDING-XXX (non-compliance is a gap)
- Different pattern = MUST create FINDING-XXX (alternative is still a gap)

**Verification:** Use formula from "Mandatory Gap Principle -> Verification Rule" section.

### Gate Escape Detection (Frontend 9-Gate Cycle)

**When mapping findings, identify which gate SHOULD have caught the issue:**

| Finding Category | Should Be Caught In | Flag |
|------------------|---------------------|------|
| Implementation pattern gaps | Gate 0 (Implementation) | Normal finding |
| React/Next.js architectural issues | Gate 0 (Implementation) | Normal finding |
| Docker/DevOps gaps | Gate 1 (DevOps) | GATE 1 ESCAPE |
| WCAG violations, keyboard nav, ARIA | Gate 2 (Accessibility) | GATE 2 ESCAPE |
| Semantic HTML, focus management | Gate 2 (Accessibility) | GATE 2 ESCAPE |
| Unit test gaps, coverage <85% | Gate 3 (Unit Testing) | GATE 3 ESCAPE |
| Test isolation issues | Gate 3 (Unit Testing) | GATE 3 ESCAPE |
| Missing snapshot tests | Gate 4 (Visual) | GATE 4 ESCAPE |
| Missing state/responsive coverage | Gate 4 (Visual) | GATE 4 ESCAPE |
| sindarian-ui component duplication | Gate 4 (Visual) | GATE 4 ESCAPE |
| Untested user flows | Gate 5 (E2E) | GATE 5 ESCAPE |
| Cross-browser issues | Gate 5 (E2E) | GATE 5 ESCAPE |
| Flaky tests | Gate 5 (E2E) | GATE 5 ESCAPE |
| CWV violations (LCP > 2.5s, CLS > 0.1, INP > 200ms) | Gate 6 (Performance) | GATE 6 ESCAPE |
| Lighthouse < 90 | Gate 6 (Performance) | GATE 6 ESCAPE |
| Bundle size bloat | Gate 6 (Performance) | GATE 6 ESCAPE |
| Bare `<img>` tags (not next/image) | Gate 6 (Performance) | GATE 6 ESCAPE |
| Code quality (reviewer-catchable) | Gate 7 (Review) | GATE 7 ESCAPE |

**Gate Escape Output Format:**

```markdown
### FINDING-XXX: [Issue Title] GATE N ESCAPE

**Escaped From:** Gate N ({Gate Name})
**Why It Escaped:** [Quality Gate check that should have caught this]
**Prevention:** [Specific check to add to Gate N exit criteria]

[Rest of finding format...]
```

**Purpose:** Track which issues escape which gates. If many escapes occur at a gate, that gate's exit criteria need strengthening.

---

**Summary Table (MANDATORY at end of findings.md):**

```markdown
## Gate Escape Summary

| Gate | Escaped Issues | Most Common Type |
|------|----------------|------------------|
| Gate 0 (Implementation) | N | [type] |
| Gate 1 (DevOps) | N | [type] |
| Gate 2 (Accessibility) | N | [type] |
| Gate 3 (Unit Testing) | N | [type] |
| Gate 4 (Visual) | N | [type] |
| Gate 5 (E2E) | N | [type] |
| Gate 6 (Performance) | N | [type] |
| Gate 7 (Review) | N | [type] |

**Action Required:** If any gate has >2 escapes, review that gate's exit criteria.
```

**TodoWrite:** Mark "Map agent findings to FINDING-XXX entries" as `completed`

---

## Step 4.6: Save Individual Agent Reports

**TodoWrite:** Mark "Save individual agent reports" as `in_progress`

**MANDATORY: Each agent's output MUST be saved as an individual report file.**

After all parallel agent tasks complete, save each agent's output to a separate file:

```
docs/ring:dev-refactor-frontend/{timestamp}/reports/
+-- ring:frontend-engineer-report.md           (always)
+-- ring:qa-analyst-frontend-report.md         (always)
+-- ring:frontend-designer-report.md           (always)
+-- ring:devops-engineer-report.md             (always)
+-- ring:sre-report.md                         (always)
+-- ring:frontend-bff-engineer-typescript-report.md       (if BFF detected)
+-- ring:ui-engineer-report.md                 (if ux-criteria.md exists)
```

### Report File Format

**Use Write tool for each agent report:**

```markdown
# {Agent Name} Analysis Report

**Generated:** {timestamp}
**Agent:** {agent-name}
**Mode:** ANALYSIS only

## Standards Coverage Table

{Copy agent's Standards Coverage Table output here}

## Issues Found

{Copy all ISSUE-XXX entries from agent output}

## Summary

- **Total Issues:** {count}
- **Critical:** {count}
- **High:** {count}
- **Medium:** {count}
- **Low:** {count}

---
*Report generated by ring:dev-refactor-frontend skill*
```

### Anti-Rationalization Table for Step 4.6

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll combine all reports into one file" | Individual reports enable targeted re-runs and tracking | **Save each agent to SEPARATE file** |
| "Agent output is already visible in chat" | Chat history is ephemeral; files are artifacts | **MUST persist as files** |
| "Only saving reports with issues" | Empty reports prove compliance was checked | **Save all dispatched agent reports** |
| "findings.md already captures everything" | findings.md is processed; reports are raw agent output | **Save BOTH raw reports and findings.md** |

### REQUIRED Action for Step 4.6

```
Write tool:
  file_path: "docs/ring:dev-refactor-frontend/{timestamp}/reports/{agent-name}-report.md"
  content: [Agent Task output formatted per template above]
```

**Repeat for each agent dispatched in Step 4.**

**TodoWrite:** Mark "Save individual agent reports" as `completed`

---

## Step 5: Generate findings.md

**TodoWrite:** Mark "Generate findings.md" as `in_progress`

### HARD GATE: Verify All Issues Are Mapped

**BEFORE creating findings.md, apply the Verification Rule from "Mandatory Gap Principle" section.**

If counts don't match, STOP. Go back to Step 4.5. Map missing issues.

### FORBIDDEN Actions for Step 5

```
Creating findings.md with fewer entries than agent issues  -> SKILL FAILURE
Omitting file:line references from findings                -> SKILL FAILURE
Using vague descriptions instead of specific code excerpts -> SKILL FAILURE
Skipping "Why This Matters" section for any finding        -> SKILL FAILURE
Generating findings.md without reading all agent reports   -> SKILL FAILURE
```

### REQUIRED Actions for Step 5

```
Every FINDING-XXX includes: Severity, Category, Agent, Standard reference
Every FINDING-XXX includes: Current Code with exact file:line
Every FINDING-XXX includes: Ring Standard Reference with URL
Every FINDING-XXX includes: Required Changes as numbered actions
Every FINDING-XXX includes: Why This Matters with Problem/Standard/Impact
Total finding count MUST match total issues from Step 4.5
```

### Anti-Rationalization Table for Step 5

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll add details later during implementation" | findings.md is the source of truth. Incomplete = useless. | **Complete all sections for every finding** |
| "Code snippet is too long to include" | Truncate to relevant lines, but never omit. Context is required. | **Include code with file:line reference** |
| "Standard URL is obvious, skip it" | Agents and humans need direct links. Nothing is obvious. | **Include full URL for every standard** |
| "Why This Matters is redundant" | It explains business impact. Standards alone don't convey urgency. | **Write Problem/Standard/Impact for all** |
| "Some findings are self-explanatory" | Self-explanatory to you is not clear to implementer. | **Complete all sections without exception** |
| "I'll group small findings together" | Each finding = one task in Step 6. findings.md = atomic issues. | **One finding = one FINDING-XXX entry** |

**Use Write tool to create findings.md:**

**CRITICAL: Every issue reported by agents in Step 4 MUST appear here as a FINDING-XXX entry.**

```markdown
# Findings: {project-name}

**Generated:** {timestamp}
**Total Findings:** {count}
**UI Library Mode:** {ui_library_mode}

## Mandatory Gap Principle Applied

**all divergences from Ring standards are tracked below. No filtering applied.**

| Metric | Count |
|--------|-------|
| Total non-compliant items from agent reports | {X} |
| Total FINDING-XXX entries below | {X} |
| **Counts match?** | YES (REQUIRED) |

**Severity does not affect tracking - all gaps are mandatory:**
| Severity | Count | Priority | Tracking |
|----------|-------|----------|----------|
| Critical | {N} | Execute first | **MANDATORY** |
| High | {N} | Execute in current sprint | **MANDATORY** |
| Medium | {N} | Execute in next sprint | **MANDATORY** |
| Low | {N} | Execute when capacity | **MANDATORY** |

---

## FINDING-001: {Pattern Name}

**Severity:** Critical | High | Medium | Low (all MANDATORY)
**Category:** {component-architecture | ui-library | styling | accessibility | testing | performance | devops}
**Agent:** {agent-name}
**Standard:** {file}.md:{section}

### Current Code
```{lang}
// file: {path}:{lines}
{actual code}
```

### Ring Standard Reference
**Standard:** {standards-file}.md -> Section: {section-name}
**Pattern:** {pattern-name}
**URL:** https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/{file}.md

### Required Changes
1. {action item 1 - what to change}
2. {action item 2 - what to add/remove}
3. {action item 3 - pattern to follow}

### Why This Matters
- **Problem:** {what is wrong with current code}
- **Standard Violated:** {specific section from Ring standards}
- **Impact:** {business/technical impact if not fixed}

---

## FINDING-002: ...
```

**TodoWrite:** Mark "Generate findings.md" as `completed`

---

## Step 6: Map Findings to Tasks (1:1)

**TodoWrite:** Mark "Map findings 1:1 to REFACTOR-XXX tasks" as `in_progress`

**HARD GATE: One FINDING-XXX = One REFACTOR-XXX task. No grouping.**

Each finding becomes its own task. This prevents findings from being lost inside grouped tasks.

**1:1 Mapping Rule:**
- FINDING-001 -> REFACTOR-001
- FINDING-002 -> REFACTOR-002
- FINDING-NNN -> REFACTOR-NNN

**Ordering:** Sort tasks by severity (Critical first), then by dependency order.

**Mapping Verification:**
```
Before proceeding to Step 7, verify:
- Total FINDING-XXX in findings.md: X
- Total REFACTOR-XXX in tasks.md: X (MUST MATCH exactly)
- Orphan findings (not mapped): 0 (MUST BE ZERO)
- Grouped tasks (multiple findings): 0 (MUST BE ZERO)
```

**If counts don't match, STOP. Every finding MUST have its own task.**

### Anti-Rationalization Table for Step 6

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "These findings are in the same file, I'll group them" | Grouping hides findings. One fix may be done, others forgotten. | **One finding = One task. No exceptions.** |
| "Grouping reduces task count and is easier to manage" | Fewer tasks = less visibility. Each finding needs independent tracking. | **Create one REFACTOR-XXX per FINDING-XXX** |
| "These are related and should be fixed together" | Related is not same task. ring:dev-cycle-frontend can execute them sequentially. | **Separate tasks, use Dependencies field to link** |
| "Too many tasks will overwhelm the developer" | Missing fixes overwhelms production. Completeness > convenience. | **Create all tasks. Priority handles ordering.** |

**TodoWrite:** Mark "Map findings 1:1 to REFACTOR-XXX tasks" as `completed`

---

## Step 7: Generate tasks.md

**TodoWrite:** Mark "Generate tasks.md" as `in_progress`

**Use Write tool to create tasks.md:**

```markdown
# Refactoring Tasks: {project-name}

**Source:** findings.md
**Total Tasks:** {count}
**UI Library Mode:** {ui_library_mode}

## Mandatory 1:1 Mapping Verification

**Every FINDING-XXX has exactly one REFACTOR-XXX. No grouping.**

| Metric | Count |
|--------|-------|
| Total FINDING-XXX in findings.md | {X} |
| Total REFACTOR-XXX in tasks.md | {X} |
| **Counts match exactly?** | YES (REQUIRED) |
| Grouped tasks (multiple findings) | 0 (REQUIRED) |

**Priority affects execution order, not whether to include:**
- Critical/High tasks: Execute first
- Medium tasks: Execute in current cycle
- Low tasks: Execute when capacity - STILL MANDATORY TO COMPLETE

---

## REFACTOR-001: {Finding Pattern Name}

**Finding:** FINDING-001
**Severity:** Critical | High | Medium | Low (all ARE MANDATORY)
**Category:** {component-architecture | ui-library | styling | accessibility | testing | performance | devops}
**Agent:** {agent-name}
**Effort:** {hours}h
**Dependencies:** {other REFACTOR-XXX tasks or none}

### Current Code
```{lang}
// file: {path}:{lines}
{actual code from FINDING-001}
```

### Ring Standard Reference
| Standard File | Section | URL |
|---------------|---------|-----|
| {file}.md | {section} | [Link](https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/{file}.md) |

### Required Actions
1. [ ] {action 1 - specific change to make}
2. [ ] {action 2 - pattern to implement}

### Acceptance Criteria
- [ ] Code follows {standard}.md -> {section} pattern
- [ ] No {anti-pattern} usage remains
- [ ] Tests pass after refactoring
```

**TodoWrite:** Mark "Generate tasks.md" as `completed`

---

## Step 7.5: Visual Change Report

**TodoWrite:** Mark "Generate visual change report" as `in_progress`

**MANDATORY:** Invoke `Skill("ring:visual-explainer")` to produce a self-contained HTML page showing all planned frontend refactoring changes. This replaces reading raw findings.md / tasks.md markdown for approval decisions.

**Read the code-diff template first:** Read `default/skills/visual-explainer/templates/code-diff.html` to absorb the patterns before generating.

**Generate the HTML report with these sections:**

### 1. Summary Dashboard
- UI Library Mode (from findings.md header)
- Total FINDING-XXX count with severity breakdown (Critical / High / Medium / Low)
- Total files affected (unique file paths from all findings)
- Horizontal severity breakdown bar

### 2. Per-Finding Diff Panels (one section per FINDING-XXX)
For each FINDING-XXX in findings.md:
- **Header:** Finding ID, severity badge, category, agent that reported it
- **Before panel:** Current Code block from findings.md (with file:line reference, syntax highlighted via Highlight.js)
- **After panel:** Ring Standard pattern from Required Changes section (syntax highlighted)
- **Collapsible "Why This Matters":** Problem / Standard Violated / Impact from findings.md

### 3. Task Mapping Table
Table showing: FINDING-XXX → REFACTOR-XXX → Severity → Category → Estimated Effort

**Output:** Save to `docs/ring:dev-refactor-frontend/{timestamp}/change-report.html`

**Open in browser:**
```text
macOS: open docs/ring:dev-refactor-frontend/{timestamp}/change-report.html
Linux: xdg-open docs/ring:dev-refactor-frontend/{timestamp}/change-report.html
```

**Tell the user** the file path. The report opens before the approval question so the user can review changes visually.

See [shared-patterns/anti-rationalization-visual-report.md](../shared-patterns/anti-rationalization-visual-report.md) for anti-rationalization table.

**TodoWrite:** Mark "Generate visual change report" as `completed`

---

## Step 8: User Approval

**TodoWrite:** Mark "Get user approval" as `in_progress`

### Auto-Resolution via Input Flags

```text
if analyze_only == true:
  → Auto-select "Cancel" (analysis complete, skip execution)
  → Output: "analyze_only=true — analysis artifacts saved, skipping ring:dev-cycle-frontend."
  → Skip to Step 9 (Save Artifacts), then TERMINATE after Step 9.

if critical_only == true:
  → Auto-select "Critical only" (no user prompt needed)
  → Output: "critical_only=true — auto-selecting Critical/High tasks only."
  → Continue to Step 9, then Step 10 with Critical/High tasks.
```

### Interactive Approval (when no auto-resolution flags are set)

<user_decision>
MUST wait for explicit user response before proceeding.
Options: Approve all | Critical only | Cancel
</user_decision>

```yaml
AskUserQuestion:
  questions:
    - question: "Review frontend refactoring plan. How to proceed?"
      header: "Approval"
      options:
        - label: "Approve all"
          description: "Proceed to ring:dev-cycle-frontend execution"
        - label: "Critical only"
          description: "Execute only Critical/High tasks"
        - label: "Cancel"
          description: "Keep analysis, skip execution"
```

CANNOT proceed without explicit user selection (or an auto-resolution flag).

**TodoWrite:** Mark "Get user approval" as `completed`

---

## Step 9: Save Artifacts

**TodoWrite:** Mark "Save all artifacts" as `in_progress`

```
docs/ring:dev-refactor-frontend/{timestamp}/
+-- codebase-report.md  (Step 3)
+-- reports/            (Step 4.6)
|   +-- ring:frontend-engineer-report.md
|   +-- ring:qa-analyst-frontend-report.md
|   +-- ring:frontend-designer-report.md
|   +-- ring:devops-engineer-report.md
|   +-- ring:sre-report.md
|   +-- ring:frontend-bff-engineer-typescript-report.md    (conditional)
|   +-- ring:ui-engineer-report.md              (conditional)
+-- findings.md         (Step 5)
+-- tasks.md           (Step 7)
+-- change-report.html (Step 7.5)
```

**TodoWrite:** Mark "Save all artifacts" as `completed`

---

## Step 10: Handoff to ring:dev-cycle-frontend

**TodoWrite:** Mark "Handoff to ring:dev-cycle-frontend" as `in_progress`

### Skip Conditions

```text
if analyze_only == true:
  → Output: "analyze_only=true — skipping handoff. Artifacts saved at docs/ring:dev-refactor-frontend/{timestamp}/."
  → Mark todo as `completed`
  → TERMINATE.

if dry_run == true:
  → This step is unreachable (dry_run exits after Step 1b).

if user selected "Cancel" in Step 8:
  → Output: "User cancelled execution. Artifacts saved at docs/ring:dev-refactor-frontend/{timestamp}/."
  → Mark todo as `completed`
  → TERMINATE.
```

### Execution (when user approved or critical_only resolved)

**Use Skill tool to invoke ring:dev-cycle-frontend directly:**

```yaml
Skill tool:
  skill: "ring:dev-cycle-frontend"
```

**CRITICAL: Pass tasks file path in context:**

After invoking the skill, provide:
- Tasks file: `docs/ring:dev-refactor-frontend/{timestamp}/tasks.md`

```yaml
Context for ring:dev-cycle-frontend:
  tasks-file: "docs/ring:dev-refactor-frontend/{timestamp}/tasks.md"
```

Where `{timestamp}` format is `YYYY-MM-DDTHH:MM:SS`. Use the same timestamp across all artifacts in a single run.

### Anti-Rationalization: Skill Invocation

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "SlashCommand is equivalent to Skill tool" | SlashCommand is a hint; Skill tool guarantees skill loading | **Use Skill tool, not SlashCommand** |
| "User can run /ring:dev-cycle-frontend manually" | Manual run risks skill not being loaded | **Invoke Skill tool directly** |
| "ring:dev-cycle-frontend will auto-discover tasks" | Explicit path ensures correct file is used | **Pass explicit tasks path** |
| "User approved, I can skip ring:dev-cycle-frontend" | Approval = permission to proceed, not skip execution | **Invoke Skill tool** |
| "Tasks are saved, job is done" | Saved tasks without execution = incomplete workflow | **Invoke Skill tool** |
| "analyze_only was not set but I'll skip anyway" | Only analyze_only, dry_run, or user "Cancel" can skip this step | **Invoke Skill tool** |

**HARD GATE: When execution is approved (user selected "Approve all" or "Critical only", or critical_only auto-resolved), you CANNOT complete ring:dev-refactor-frontend without invoking `Skill tool: ring:dev-cycle-frontend`.**

If execution is approved, you MUST:
1. Invoke `Skill tool: ring:dev-cycle-frontend`
2. Pass tasks file path: `docs/ring:dev-refactor-frontend/{timestamp}/tasks.md`
3. Wait for ring:dev-cycle-frontend to complete all 9 gates

**Skipping this step when execution is approved = SKILL FAILURE.**

ring:dev-cycle-frontend executes each REFACTOR-XXX task through the 9-gate frontend process.

**TodoWrite:** Mark "Handoff to ring:dev-cycle-frontend" as `completed`

---

## Execution Report

Base metrics per [shared-patterns/output-execution-report.md](../shared-patterns/output-execution-report.md).

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Refactor-Frontend-Specific Metrics
| Metric | Value |
|--------|-------|
| Agents Dispatched | N (5-7) |
| UI Library Mode | sindarian-ui / fallback-only |
| Findings Generated | N |
| Tasks Created | N |
| Gate Escapes Detected | N |
| Artifacts Location | docs/ring:dev-refactor-frontend/{timestamp}/ |

## Output Schema

```yaml
artifacts:
  - codebase-report.md (Step 3)
  - reports/{agent-name}-report.md (Step 4.6)
  - findings.md (Step 5)
  - tasks.md (Step 7)
  - change-report.html (Step 7.5)

traceability:
  Ring Standard -> Agent Report -> FINDING-XXX -> REFACTOR-XXX -> Implementation
```
