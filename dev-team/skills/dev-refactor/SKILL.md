---
name: dev-refactor
description: |
  Analyzes codebase against Ring/Lerian standards and generates refactoring tasks.

  EXECUTION SEQUENCE:
  1. Validate docs/PROJECT_RULES.md exists (BLOCKER if missing)
  2. Detect project language (go.mod, package.json)
  3. Dispatch ring-default:codebase-explorer (Task tool, model: opus)
  4. Save codebase-report.md
  5. Dispatch ring-dev-team specialist agents (Task tool, model: opus, parallel)
  6. Generate findings.md with Code Transformation Context
  7. Generate tasks.md referencing findings
  8. Get user approval
  9. Handoff to dev-cycle

  FORBIDDEN: Explore, general-purpose, Plan agents
  REQUIRED: ring-default:codebase-explorer (step 3), ring-dev-team:* (step 5)

trigger: |
  - User wants to refactor existing project to follow standards
  - Legacy codebase needs modernization
  - Project audit requested

skip_when: |
  - Greenfield project → Use /ring-pm-team:pre-dev-* instead
  - Single file fix → Use ring-dev-team:dev-cycle directly
---

# Dev Refactor Skill

Analyzes existing codebase against Ring/Lerian standards and generates refactoring tasks compatible with dev-cycle.

---

## Step 0: Validate PROJECT_RULES.md

**Check:** Does `docs/PROJECT_RULES.md` exist?

- **YES** → Continue to Step 1
- **NO** → Output blocker and TERMINATE:

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

## Step 1: Detect Project Language

Check for manifest files:

| File | Language | Agent |
|------|----------|-------|
| `go.mod` | Go | ring-dev-team:backend-engineer-golang |
| `package.json` | TypeScript | ring-dev-team:backend-engineer-typescript |

If multiple languages detected, dispatch agents for ALL.

---

## Step 2: Read PROJECT_RULES.md

```
Read tool: docs/PROJECT_RULES.md
```

Extract project-specific conventions for agent context.

---

## Step 3: Generate Codebase Report

**Use Task tool with these parameters:**

```yaml
Task:
  subagent_type: "ring-default:codebase-explorer"
  model: "opus"
  description: "Generate codebase architecture report"
  prompt: |
    Generate a comprehensive codebase report describing WHAT EXISTS.

    Include:
    - Project structure and directory layout
    - Architecture pattern (hexagonal, clean, etc.)
    - Technology stack from manifests
    - Code patterns: config, database, handlers, errors, telemetry, testing
    - Key files inventory with file:line references
    - Code snippets showing current implementation patterns

    Output format: EXPLORATION SUMMARY, KEY FINDINGS, ARCHITECTURE INSIGHTS, RELEVANT FILES
```

**After Task completes, save with Write tool:**

```
Write tool:
  file_path: "docs/refactor/{timestamp}/codebase-report.md"
  content: [Task output]
```

---

## Step 4: Dispatch Specialist Agents

**Dispatch ALL applicable agents in ONE message (parallel):**

### For Go projects:

```yaml
Task 1:
  subagent_type: "ring-dev-team:backend-engineer-golang"
  model: "opus"
  description: "Go standards analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**

    Compare codebase with Ring Go standards.

    Input:
    - Ring Standards: Load via WebFetch (golang.md)
    - Codebase Report: docs/refactor/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output for each non-compliant pattern:
    - ISSUE-XXX: Pattern name, Severity, Location (file:line)
    - Current Code (snippet)
    - Expected Code (Ring standard)
    - Standard Reference (file:section:lines)

Task 2:
  subagent_type: "ring-dev-team:qa-analyst"
  model: "opus"
  description: "Test coverage analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Compare test patterns with Ring standards.
    Input: codebase-report.md, PROJECT_RULES.md
    Output: Coverage gaps, pattern violations with file:line

Task 3:
  subagent_type: "ring-dev-team:devops-engineer"
  model: "opus"
  description: "DevOps analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Compare DevOps setup with Ring standards.
    Input: codebase-report.md, PROJECT_RULES.md
    Output: Dockerfile, docker-compose, CI/CD gaps

Task 4:
  subagent_type: "ring-dev-team:sre"
  model: "opus"
  description: "Observability analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Compare observability with Ring standards.
    Input: codebase-report.md, PROJECT_RULES.md
    Output: Logging, tracing, metrics gaps
```

### For TypeScript projects:

Replace Task 1 with `ring-dev-team:backend-engineer-typescript`.

---

## Step 5: Generate findings.md

**Use Write tool to create findings.md:**

```markdown
# Findings: {project-name}

**Generated:** {timestamp}
**Total Findings:** {count}

## FINDING-001: {Pattern Name}

**Severity:** Critical | High | Medium | Low
**Category:** {lib-commons | architecture | testing | devops}
**Agent:** {ring-dev-team:agent-name}
**Standard:** {file}.md:{section}

### Current Code
```{lang}
// file: {path}:{lines}
{actual code}
```

### Expected Code (Ring Standard)
```{lang}
// Ring Standard: {pattern} ({file}:{section})
{expected code}
```

### Why This Matters
- Problem: {issue}
- Standard: {violated}
- Impact: {business impact}

---

## FINDING-002: ...
```

---

## Step 6: Group Findings into Tasks

Group related findings by:
1. Module/bounded context
2. Dependency order
3. Severity (critical first)

---

## Step 7: Generate tasks.md

**Use Write tool to create tasks.md:**

```markdown
# Refactoring Tasks: {project-name}

**Source:** findings.md
**Total Tasks:** {count}

## REFACTOR-001: {Task Name}

**Priority:** Critical | High | Medium
**Effort:** {hours}h
**Dependencies:** {other tasks or none}

### Findings Addressed
| Finding | Pattern | Severity |
|---------|---------|----------|
| FINDING-001 | {name} | Critical |
| FINDING-003 | {name} | High |

### Execution Context
```{lang}
// BEFORE (file:line)
{current code}

// AFTER (Ring Standard)
{expected code}
```

### Acceptance Criteria
- [ ] {criteria from finding}
```

---

## Step 8: User Approval

```yaml
AskUserQuestion:
  questions:
    - question: "Review refactoring plan. How to proceed?"
      header: "Approval"
      options:
        - label: "Approve all"
          description: "Proceed to dev-cycle execution"
        - label: "Critical only"
          description: "Execute only Critical/High tasks"
        - label: "Cancel"
          description: "Keep analysis, skip execution"
```

---

## Step 9: Save Artifacts

```
docs/refactor/{timestamp}/
├── codebase-report.md  (Step 3)
├── findings.md         (Step 5)
└── tasks.md           (Step 7)
```

---

## Step 10: Handoff to dev-cycle

**If user approved, use Skill tool:**

```yaml
Skill:
  skill: "ring-dev-team:dev-cycle"
```

dev-cycle executes each REFACTOR-XXX task through 6-gate process.

---

## Output Schema

```yaml
artifacts:
  - codebase-report.md (Step 3)
  - findings.md (Step 5)
  - tasks.md (Step 7)

traceability:
  Ring Standard → FINDING-XXX → REFACTOR-XXX → Implementation
```
