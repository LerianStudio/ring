---
name: dev-refactor
description: Analyzes codebase against standards and generates refactoring tasks for dev-cycle.
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

## ⛔ MANDATORY: Initialize Todo List FIRST

**Before ANY other action, create the todo list with ALL steps:**

```yaml
TodoWrite:
  todos:
    - content: "Validate PROJECT_RULES.md exists"
      status: "pending"
      activeForm: "Validating PROJECT_RULES.md exists"
    - content: "Detect project stack (Go/TypeScript/Frontend)"
      status: "pending"
      activeForm: "Detecting project stack"
    - content: "Read PROJECT_RULES.md for context"
      status: "pending"
      activeForm: "Reading PROJECT_RULES.md"
    - content: "Generate codebase report via codebase-explorer"
      status: "pending"
      activeForm: "Generating codebase report"
    - content: "Dispatch specialist agents in parallel"
      status: "pending"
      activeForm: "Dispatching specialist agents"
    - content: "Save individual agent reports"
      status: "pending"
      activeForm: "Saving agent reports"
    - content: "Map agent findings to FINDING-XXX entries"
      status: "pending"
      activeForm: "Mapping agent findings"
    - content: "Generate findings.md"
      status: "pending"
      activeForm: "Generating findings.md"
    - content: "Group findings into REFACTOR-XXX tasks"
      status: "pending"
      activeForm: "Grouping findings into tasks"
    - content: "Generate tasks.md"
      status: "pending"
      activeForm: "Generating tasks.md"
    - content: "Get user approval"
      status: "pending"
      activeForm: "Getting user approval"
    - content: "Save all artifacts"
      status: "pending"
      activeForm: "Saving artifacts"
    - content: "Handoff to dev-cycle"
      status: "pending"
      activeForm: "Handing off to dev-cycle"
```

**This is NON-NEGOTIABLE. Do NOT skip creating the todo list.**

---

## ⛔ CRITICAL: Specialized Agents Perform All Tasks

See [shared-patterns/orchestrator-principle.md](../shared-patterns/orchestrator-principle.md) for full ORCHESTRATOR principle, role separation, forbidden/required actions, step-to-agent mapping, and anti-rationalization table.

**Summary:** You orchestrate. Agents execute. If using Bash/Grep/Read to analyze code → STOP. Dispatch agent.

---

## Step 0: Validate PROJECT_RULES.md

**TodoWrite:** Mark "Validate PROJECT_RULES.md exists" as `in_progress`

**Check:** Does `docs/PROJECT_RULES.md` exist?

- **YES** → Mark todo as `completed`, continue to Step 1
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

## Step 1: Detect Project Stack

**TodoWrite:** Mark "Detect project stack (Go/TypeScript/Frontend)" as `in_progress`

Check for manifest files and frontend indicators:

| File/Pattern | Stack | Agent |
|--------------|-------|-------|
| `go.mod` | Go Backend | ring-dev-team:backend-engineer-golang |
| `package.json` + `src/` (no React) | TypeScript Backend | ring-dev-team:backend-engineer-typescript |
| `package.json` + React/Next.js | Frontend | ring-dev-team:frontend-engineer |
| `package.json` + BFF pattern | TypeScript BFF | ring-dev-team:frontend-bff-engineer-typescript |

**Detection Logic:**
- `go.mod` exists → Add Go backend agent
- `package.json` exists + `next.config.*` or React in dependencies → Add frontend agent
- `package.json` exists + `/api/` routes or Express/Fastify → Add TypeScript backend agent
- `package.json` exists + BFF indicators (`/bff/`, gateway patterns) → Add BFF agent

If multiple stacks detected, dispatch agents for ALL.

**TodoWrite:** Mark "Detect project stack (Go/TypeScript/Frontend)" as `completed`

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

**TodoWrite:** Mark "Generate codebase report via codebase-explorer" as `in_progress`

### ⛔ MANDATORY: Use Task Tool with ring-default:codebase-explorer

**YOU MUST USE THIS EXACT TOOL CALL:**

```yaml
Task:
  subagent_type: "ring-default:codebase-explorer"  # ← EXACT STRING, NOT "Explore"
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

### Anti-Rationalization Table for Step 3

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll use Bash find/ls to quickly explore" | Bash cannot analyze patterns, just lists files. codebase-explorer provides architectural analysis. | **Use Task with subagent_type="ring-default:codebase-explorer"** |
| "The Explore agent is faster" | "Explore" subagent_type ≠ "ring-default:codebase-explorer". Different agents. | **Use exact string: "ring-default:codebase-explorer"** |
| "I already know the structure from find output" | Knowing file paths ≠ understanding architecture. Agent provides analysis. | **Use Task with subagent_type="ring-default:codebase-explorer"** |
| "This is a small codebase, Bash is enough" | Size is irrelevant. The agent provides standardized output format required by Step 4. | **Use Task with subagent_type="ring-default:codebase-explorer"** |
| "I'll explore manually then dispatch agents" | Manual exploration skips the codebase-report.md artifact required for Step 4 gate. | **Use Task with subagent_type="ring-default:codebase-explorer"** |

### FORBIDDEN Actions for Step 3

```
❌ Bash(command="find ... -name '*.go'")     → SKILL FAILURE
❌ Bash(command="ls -la ...")                → SKILL FAILURE
❌ Bash(command="tree ...")                  → SKILL FAILURE
❌ Task(subagent_type="Explore", ...)        → SKILL FAILURE
❌ Task(subagent_type="general-purpose", ...)→ SKILL FAILURE
❌ Task(subagent_type="Plan", ...)           → SKILL FAILURE
```

### REQUIRED Action for Step 3

```
✅ Task(subagent_type="ring-default:codebase-explorer", model="opus", ...)
```

**After Task completes, save with Write tool:**

```
Write tool:
  file_path: "docs/refactor/{timestamp}/codebase-report.md"
  content: [Task output]
```

**TodoWrite:** Mark "Generate codebase report via codebase-explorer" as `completed`

---

## Step 4: Dispatch Specialist Agents

**TodoWrite:** Mark "Dispatch specialist agents in parallel" as `in_progress`

### ⛔ HARD GATE: Verify codebase-report.md Exists

**BEFORE dispatching ANY specialist agent, verify:**

```
Check 1: Does docs/refactor/{timestamp}/codebase-report.md exist?
  - YES → Continue to dispatch agents
  - NO  → STOP. Go back to Step 3.

Check 2: Was codebase-report.md created by ring-default:codebase-explorer?
  - YES → Continue
  - NO (created by Bash output) → DELETE IT. Go back to Step 3. Use correct agent.
```

**If you skipped Step 3 or used Bash instead of Task tool → You MUST go back and redo Step 3 correctly.**

**Dispatch ALL applicable agents in ONE message (parallel):**

### ⛔ MANDATORY: Reference Standards Coverage Table

**All agents MUST follow [shared-patterns/standards-coverage-table.md](../shared-patterns/standards-coverage-table.md) which defines:**
- ALL sections to check per agent (including DDD)
- Required output format (Standards Coverage Table)
- Anti-rationalization rules
- Completeness verification

**Section indexes are pre-defined in shared-patterns. Agents MUST check ALL sections listed.**

---

### For Go projects:

```yaml
Task 1:
  subagent_type: "ring-dev-team:backend-engineer-golang"
  model: "opus"
  description: "Go standards analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**

    ⛔ MANDATORY: Check ALL 17 sections in golang.md per shared-patterns/standards-coverage-table.md
    This includes section 16: DDD Patterns (Go Implementation)

    Input:
    - Ring Standards: Load via WebFetch (golang.md)
    - Section Index: See shared-patterns/standards-coverage-table.md → "backend-engineer-golang"
    - Codebase Report: docs/refactor/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. ISSUE-XXX for each ⚠️/❌ finding with: Pattern name, Severity, file:line, Current Code, Expected Code

Task 2:
  subagent_type: "ring-dev-team:qa-analyst"
  model: "opus"
  description: "Test coverage analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Check ALL testing sections per shared-patterns/standards-coverage-table.md → "qa-analyst"
    Input: codebase-report.md, PROJECT_RULES.md
    Output: Standards Coverage Table + ISSUE-XXX for gaps

Task 3:
  subagent_type: "ring-dev-team:devops-engineer"
  model: "opus"
  description: "DevOps analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Check ALL 6 sections per shared-patterns/standards-coverage-table.md → "devops-engineer"
    ⛔ "Containers" means BOTH Dockerfile AND Docker Compose
    Input: codebase-report.md, PROJECT_RULES.md
    Output: Standards Coverage Table + ISSUE-XXX for gaps

Task 4:
  subagent_type: "ring-dev-team:sre"
  model: "opus"
  description: "Observability analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Check ALL 6 sections per shared-patterns/standards-coverage-table.md → "sre"
    Input: codebase-report.md, PROJECT_RULES.md
    Output: Standards Coverage Table + ISSUE-XXX for gaps
```

### For TypeScript Backend projects:

```yaml
Task 1:
  subagent_type: "ring-dev-team:backend-engineer-typescript"
  model: "opus"
  description: "TypeScript backend standards analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**

    ⛔ MANDATORY: Check ALL 12 sections in typescript.md per shared-patterns/standards-coverage-table.md
    This includes section 9: DDD Patterns (TypeScript Implementation)

    Input:
    - Ring Standards: Load via WebFetch (typescript.md)
    - Section Index: See shared-patterns/standards-coverage-table.md → "backend-engineer-typescript"
    - Codebase Report: docs/refactor/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. ISSUE-XXX for each ⚠️/❌ finding with: Pattern name, Severity, file:line, Current Code, Expected Code
```

### For Frontend projects (React/Next.js):

```yaml
Task 5:
  subagent_type: "ring-dev-team:frontend-engineer"
  model: "opus"
  description: "Frontend standards analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**

    ⛔ MANDATORY: Check ALL 13 sections in frontend.md per shared-patterns/standards-coverage-table.md

    Input:
    - Ring Standards: Load via WebFetch (frontend.md)
    - Section Index: See shared-patterns/standards-coverage-table.md → "frontend-engineer"
    - Codebase Report: docs/refactor/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. ISSUE-XXX for each ⚠️/❌ finding with: Pattern name, Severity, file:line, Current Code, Expected Code
```

### For BFF (Backend-for-Frontend) projects:

```yaml
Task 6:
  subagent_type: "ring-dev-team:frontend-bff-engineer-typescript"
  model: "opus"
  description: "BFF TypeScript standards analysis"
  prompt: |
    **MODE: ANALYSIS ONLY**

    ⛔ MANDATORY: Check ALL 12 sections in typescript.md per shared-patterns/standards-coverage-table.md
    This includes section 9: DDD Patterns (TypeScript Implementation)

    Input:
    - Ring Standards: Load via WebFetch (typescript.md)
    - Section Index: See shared-patterns/standards-coverage-table.md → "frontend-bff-engineer-typescript"
    - Codebase Report: docs/refactor/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. ISSUE-XXX for each ⚠️/❌ finding with: Pattern name, Severity, file:line, Current Code, Expected Code
```

### Agent Dispatch Summary

| Stack Detected | Agents to Dispatch |
|----------------|-------------------|
| Go only | Task 1 (Go) + Task 2-4 |
| TypeScript Backend only | Task 1 (TS Backend) + Task 2-4 |
| Frontend only | Task 5 (Frontend) + Task 2-4 |
| Go + Frontend | Task 1 (Go) + Task 5 (Frontend) + Task 2-4 |
| TypeScript Backend + Frontend | Task 1 (TS Backend) + Task 5 (Frontend) + Task 2-4 |
| BFF detected | Add Task 6 (BFF) to above |

**TodoWrite:** Mark "Dispatch specialist agents in parallel" as `completed`

---

## Step 4.5: Save Individual Agent Reports

**TodoWrite:** Mark "Save individual agent reports" as `in_progress`

**⛔ MANDATORY: Each agent's output MUST be saved as an individual report file.**

After ALL parallel agent tasks complete, save each agent's output to a separate file:

```
docs/refactor/{timestamp}/reports/
├── backend-engineer-golang-report.md     (if Go project)
├── backend-engineer-typescript-report.md (if TypeScript Backend)
├── frontend-engineer-report.md           (if Frontend)
├── frontend-bff-engineer-report.md       (if BFF)
├── qa-analyst-report.md                  (always)
├── devops-engineer-report.md             (always)
└── sre-report.md                         (always)
```

### Report File Format

**Use Write tool for EACH agent report:**

```markdown
# {Agent Name} Analysis Report

**Generated:** {timestamp}
**Agent:** ring-dev-team:{agent-name}
**Mode:** ANALYSIS ONLY

## Standards Coverage Table

{Copy agent's Standards Coverage Table output here}

## Issues Found

{Copy ALL ISSUE-XXX entries from agent output}

## Summary

- **Total Issues:** {count}
- **Critical:** {count}
- **High:** {count}
- **Medium:** {count}
- **Low:** {count}

---
*Report generated by ring-dev-team:dev-refactor skill*
```

### Agent Report Mapping

| Agent Dispatched | Report File Name |
|------------------|------------------|
| ring-dev-team:backend-engineer-golang | `backend-engineer-golang-report.md` |
| ring-dev-team:backend-engineer-typescript | `backend-engineer-typescript-report.md` |
| ring-dev-team:frontend-engineer | `frontend-engineer-report.md` |
| ring-dev-team:frontend-bff-engineer-typescript | `frontend-bff-engineer-report.md` |
| ring-dev-team:qa-analyst | `qa-analyst-report.md` |
| ring-dev-team:devops-engineer | `devops-engineer-report.md` |
| ring-dev-team:sre | `sre-report.md` |

### Anti-Rationalization Table for Step 4.5

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll combine all reports into one file" | Individual reports enable targeted re-runs and tracking | **Save EACH agent to SEPARATE file** |
| "Agent output is already visible in chat" | Chat history is ephemeral; files are artifacts | **MUST persist as files** |
| "Only saving reports with issues" | Empty reports prove compliance was checked | **Save ALL dispatched agent reports** |
| "findings.md already captures everything" | findings.md is processed; reports are raw agent output | **Save BOTH raw reports AND findings.md** |

### REQUIRED Action for Step 4.5

```
Write tool:
  file_path: "docs/refactor/{timestamp}/reports/{agent-name}-report.md"
  content: [Agent Task output formatted per template above]
```

**Repeat for EACH agent dispatched in Step 4.**

**TodoWrite:** Mark "Save individual agent reports" as `completed`

---

## Step 4.1: Agent Report → Findings Mapping (HARD GATE)

**TodoWrite:** Mark "Map agent findings to FINDING-XXX entries" as `in_progress`

**⛔ MANDATORY: ALL agent-reported issues MUST become findings.**

| Agent Report | Action |
|--------------|--------|
| Any difference between current code and Ring standard | → Create FINDING-XXX |
| Any missing pattern from Ring standards | → Create FINDING-XXX |
| Any deprecated pattern usage | → Create FINDING-XXX |
| Any observability gap | → Create FINDING-XXX |

### FORBIDDEN Actions for Step 4.1

```
❌ Ignoring agent-reported issues because they seem "minor"  → SKILL FAILURE
❌ Filtering out issues based on personal judgment           → SKILL FAILURE
❌ Summarizing multiple issues into one finding              → SKILL FAILURE
❌ Skipping issues without ISSUE-XXX format from agent       → SKILL FAILURE
❌ Creating findings only for "interesting" gaps             → SKILL FAILURE
```

### REQUIRED Actions for Step 4.1

```
✅ Every line item from agent reports becomes a FINDING-XXX entry
✅ Preserve agent's severity assessment exactly as reported
✅ Include exact file:line references from agent report
✅ Every non-✅ item in Standards Coverage Table = one FINDING-XXX
✅ Count findings in Step 5 MUST equal total issues from all agent reports
```

### Anti-Rationalization Table for Step 4.1

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This issue is too minor to track" | You don't decide severity. The agent already assessed it. | **Create FINDING-XXX for EVERY issue** |
| "Multiple similar issues can be one finding" | Distinct file:line = distinct finding. Merging loses traceability. | **One issue = One FINDING-XXX** |
| "Agent report didn't use ISSUE-XXX format" | Format varies; presence matters. Every gap = one finding. | **Extract ALL gaps into findings** |
| "Codebase already mostly compliant" | Mostly ≠ fully. Document ALL differences. | **Create findings for ALL non-✅ items** |
| "I'll consolidate to reduce noise" | Consolidation = data loss. Noise is signal. | **Preserve ALL individual issues** |
| "Some findings are duplicates across agents" | Different agents = different perspectives. Keep both. | **Create separate findings per agent** |

**TodoWrite:** Mark "Map agent findings to FINDING-XXX entries" as `completed`

---

## Step 5: Generate findings.md

**TodoWrite:** Mark "Generate findings.md" as `in_progress`

### ⛔ HARD GATE: Verify All Issues Are Mapped

**BEFORE creating findings.md, verify:**

```
Check 1: Count total issues from ALL agent reports in Step 4.5
Check 2: Count total FINDING-XXX entries you will create
Check 3: Count 1 MUST equal Count 2

If counts don't match → STOP. Go back to Step 4.1. Map missing issues.
```

### FORBIDDEN Actions for Step 5

```
❌ Creating findings.md with fewer entries than agent issues  → SKILL FAILURE
❌ Omitting file:line references from findings                → SKILL FAILURE
❌ Using vague descriptions instead of specific code excerpts → SKILL FAILURE
❌ Skipping "Why This Matters" section for any finding        → SKILL FAILURE
❌ Generating findings.md without reading ALL agent reports   → SKILL FAILURE
```

### REQUIRED Actions for Step 5

```
✅ Every FINDING-XXX includes: Severity, Category, Agent, Standard reference
✅ Every FINDING-XXX includes: Current Code with exact file:line
✅ Every FINDING-XXX includes: Ring Standard Reference with URL
✅ Every FINDING-XXX includes: Required Changes as numbered actions
✅ Every FINDING-XXX includes: Why This Matters with Problem/Standard/Impact
✅ Total finding count MUST match total issues from Step 4.1
```

### Anti-Rationalization Table for Step 5

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll add details later during implementation" | findings.md is the source of truth. Incomplete = useless. | **Complete ALL sections for EVERY finding** |
| "Code snippet is too long to include" | Truncate to relevant lines, but NEVER omit. Context is required. | **Include code with file:line reference** |
| "Standard URL is obvious, skip it" | Agents and humans need direct links. Nothing is obvious. | **Include full URL for EVERY standard** |
| "Why This Matters is redundant" | It explains business impact. Standards alone don't convey urgency. | **Write Problem/Standard/Impact for ALL** |
| "Some findings are self-explanatory" | Self-explanatory to you ≠ clear to implementer. | **Complete ALL sections without exception** |
| "I'll group small findings together" | Grouping happens in Step 6 (tasks). findings.md = atomic issues. | **One finding = one FINDING-XXX entry** |

**Use Write tool to create findings.md:**

**⛔ CRITICAL: Every issue reported by agents in Step 4 MUST appear here as a FINDING-XXX entry.**

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

### Ring Standard Reference
**Standard:** {standards-file}.md → Section: {section-name}
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

## Step 6: Group Findings into Tasks

**TodoWrite:** Mark "Group findings into REFACTOR-XXX tasks" as `in_progress`

**⛔ HARD GATE: Every FINDING-XXX MUST appear in at least one REFACTOR-XXX task.**

Group related findings by:
1. Module/bounded context (same file/package = same task)
2. Dependency order (foundational changes first)
3. Severity (critical first)

**Mapping Verification:**
```
Before proceeding to Step 7, verify:
- Total findings in findings.md: X
- Total findings referenced in tasks: X (MUST MATCH)
- Orphan findings (not in any task): 0 (MUST BE ZERO)
```

**If ANY finding is not mapped to a task → STOP. Add missing findings to tasks.**

**TodoWrite:** Mark "Group findings into REFACTOR-XXX tasks" as `completed`

---

## Step 7: Generate tasks.md

**TodoWrite:** Mark "Generate tasks.md" as `in_progress`

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
| Finding | Pattern | Severity | File:Line |
|---------|---------|----------|-----------|
| FINDING-001 | {name} | Critical | src/handler.go:45 |
| FINDING-003 | {name} | High | src/service.go:112 |

### Ring Standards to Follow
| Standard File | Section | URL |
|---------------|---------|-----|
| golang.md | Error Handling | [Link](https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md) |
| sre.md | Structured Logging | [Link](https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md) |

### Required Actions
1. [ ] {action from FINDING-001 - specific change to make}
2. [ ] {action from FINDING-001 - pattern to implement}
3. [ ] {action from FINDING-003 - specific change to make}

### Acceptance Criteria
- [ ] Code follows {standard}.md → {section} pattern
- [ ] No {anti-pattern} usage remains
- [ ] Tests pass after refactoring
- [ ] {additional criteria from findings}
```

**TodoWrite:** Mark "Generate tasks.md" as `completed`

---

## Step 8: User Approval

**TodoWrite:** Mark "Get user approval" as `in_progress`

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

**TodoWrite:** Mark "Get user approval" as `completed`

---

## Step 9: Save Artifacts

**TodoWrite:** Mark "Save all artifacts" as `in_progress`

```
docs/refactor/{timestamp}/
├── codebase-report.md  (Step 3)
├── reports/            (Step 4.5)
│   ├── backend-engineer-golang-report.md
│   ├── qa-analyst-report.md
│   ├── devops-engineer-report.md
│   └── sre-report.md
├── findings.md         (Step 5)
└── tasks.md           (Step 7)
```

**TodoWrite:** Mark "Save all artifacts" as `completed`

---

## Step 10: Handoff to dev-cycle

**TodoWrite:** Mark "Handoff to dev-cycle" as `in_progress`

**If user approved, use SlashCommand tool with tasks path:**

```yaml
SlashCommand:
  command: "/ring-dev-team:dev-cycle docs/refactor/{timestamp}/tasks.md"
```

Where `{timestamp}` is the same timestamp used in Step 9 artifacts.

dev-cycle executes each REFACTOR-XXX task through 6-gate process.

**TodoWrite:** Mark "Handoff to dev-cycle" as `completed`

---

## Output Schema

```yaml
artifacts:
  - codebase-report.md (Step 3)
  - reports/{agent-name}-report.md (Step 4.5)
  - findings.md (Step 5)
  - tasks.md (Step 7)

traceability:
  Ring Standard → Agent Report → FINDING-XXX → REFACTOR-XXX → Implementation
```

---

## ⛔ Critical Rules Summary (READ THIS)

### Rule 1: Codebase Exploration MUST Use Specific Agent

```
✅ CORRECT: Task(subagent_type="ring-default:codebase-explorer", model="opus")
❌ WRONG:   Bash(find/ls/tree)
❌ WRONG:   Task(subagent_type="Explore")
❌ WRONG:   Task(subagent_type="general-purpose")
```

### Rule 2: Todo Items MUST Be Initialized at Start

**MANDATORY:** Use the TodoWrite call from "Initialize Todo List FIRST" section before ANY other action.

Todo items tracked:
1. `Validate PROJECT_RULES.md exists`
2. `Detect project stack (Go/TypeScript/Frontend)`
3. `Read PROJECT_RULES.md for context`
4. `Generate codebase report via codebase-explorer`
5. `Dispatch specialist agents in parallel`
6. `Save individual agent reports`
7. `Map agent findings to FINDING-XXX entries`
8. `Generate findings.md`
9. `Group findings into REFACTOR-XXX tasks`
10. `Generate tasks.md`
11. `Get user approval`
12. `Save all artifacts`
13. `Handoff to dev-cycle`

### Rule 3: Step 3 Blocks Step 5

```
Step 3 (codebase-explorer) → Creates codebase-report.md
                                    ↓
Step 4 (GATE) → Verifies file exists
                                    ↓
Step 5 (specialist agents) → ONLY runs if gate passes
```

### Why These Rules Exist

| Tool | What It Does | Why Wrong for Step 3 |
|------|--------------|---------------------|
| `Bash find/ls` | Lists file paths | No architectural analysis, no pattern detection |
| `Task(Explore)` | Fast codebase search | Different agent, lacks Ring standards context |
| `Task(general-purpose)` | Generic tasks | No specialized codebase analysis output format |
| `ring-default:codebase-explorer` | Deep architecture analysis | ✅ Correct - provides structured report for Step 5 |

### If You Violated These Rules

1. STOP current execution
2. DELETE any codebase-report.md created by wrong method
3. Go back to Step 3
4. Use correct Task tool call with `subagent_type="ring-default:codebase-explorer"`
5. Save output as codebase-report.md
6. Continue from Step 4
