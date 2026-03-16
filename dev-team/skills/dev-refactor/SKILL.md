---
name: dev-refactor
description: Analyzes backend codebase (Go/TypeScript) against standards and generates refactoring tasks for ring:dev-cycle. For frontend projects, use ring:dev-refactor-frontend instead.
metadata:
  skip_when: |-
    - Greenfield project → Use /pre-dev-* instead
    - Single file fix → Use ring:dev-cycle directly
  trigger: |
    - User wants to refactor existing project to follow standards
    - Legacy codebase needs modernization
    - Project audit requested
---

# Dev Refactor Skill

Analyzes existing codebase against Ring/Lerian standards and generates refactoring tasks compatible with ring:dev-cycle.

---

## ⛔ MANDATORY GAP PRINCIPLE (NON-NEGOTIABLE)

**any divergence from Ring standards = MANDATORY gap to implement.**

<cannot_skip>
- All divergences are gaps - Every difference MUST be tracked as FINDING-XXX
- Severity affects PRIORITY, not TRACKING - Low severity = lower priority, not "optional"
- No filtering allowed - You CANNOT decide which divergences "matter"
- No alternative patterns accepted - Different approach = STILL A GAP
- No cosmetic exceptions - Naming, formatting, structure differences = GAPS
</cannot_skip>

Non-negotiable, not open to interpretation—a HARD RULE.

### Anti-Rationalization: Mandatory Gap Principle

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for:
- **Refactor Gap Tracking** section (mandatory gap principle rationalizations)
- **Gate Execution** section (workflow skip rationalizations)
- **TDD** section (test-first rationalizations)
- **Universal** section (general anti-patterns)

### Verification Rule

```
COUNT(non-✅ items in all Standards Coverage Tables) == COUNT(FINDING-XXX entries)

If counts don't match → SKILL FAILURE. Go back and add missing findings.
```

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Security risk, data corruption, production blocker | Exposed credentials, SQL injection, missing auth |
| **HIGH** | Major standards violation, architecture issue | Missing hexagonal architecture, wrong library usage |
| **MEDIUM** | Code quality, maintainability issues | Incomplete observability, naming conventions |
| **LOW** | Best practices, documentation | Missing comments, minor refactoring |

**MANDATORY:** Track all severities. Severity affects priority of execution, not whether to track.

---

## ⛔ Architecture Pattern Applicability

**Not all architecture patterns apply to all services.** Before flagging gaps, verify the pattern is applicable.

| Service Type | Hexagonal/Clean Architecture | Directory Structure |
|--------------|------------------------------|---------------------|
| CRUD API (with services, adapters) | ✅ APPLY | ✅ APPLY (Lerian pattern) |
| Complex business logic | ✅ APPLY | ✅ APPLY |
| Multiple bounded contexts | ✅ APPLY | ✅ APPLY |
| Event-driven systems | ✅ APPLY | ✅ APPLY |
| Simple scripts/utilities | ❌ not APPLICABLE | ❌ not APPLICABLE |
| CLI tools | ❌ not APPLICABLE | ❌ not APPLICABLE |
| Workers/background jobs | ❌ not APPLICABLE | ❌ not APPLICABLE |
| Simple lambda/functions | ❌ not APPLICABLE | ❌ not APPLICABLE |

### Detection Criteria

**CRUD API (Hexagonal/Lerian Pattern APPLICABLE):**
- Service exposes API endpoints (REST, gRPC, GraphQL)
- Contains business logic and models
- Has CRUD operations (Create, Read, Update, Delete)
- Uses repositories for data access
- → **MUST follow Hexagonal Architecture and Lerian directory pattern**

**Simple Service (Hexagonal/Lerian not applicable):**
- CLI tools and scripts
- Workers and background jobs
- Simple utility functions
- Lambda functions with single responsibility
- No business logic layer

### Agent Instruction

When dispatching specialist agents, include:

```
⛔ ARCHITECTURE APPLICABILITY CHECK:
1. If service is an API with CRUD operations → APPLY Hexagonal/Lerian standards
2. If service is CLI tool, script, or simple utility → Do not flag Hexagonal/Lerian gaps

CRUD APIs MUST follow Hexagonal Architecture (ports/adapters) and Lerian directory pattern.
```

---

## ⛔ MANDATORY: Initialize Todo List FIRST

**Before any other action, create the todo list with all steps:**

```yaml
TodoWrite:
  todos:
    - content: "Validate PROJECT_RULES.md exists"
      status: "pending"
      activeForm: "Validating PROJECT_RULES.md exists"
    - content: "Detect project stack (Go/TypeScript backend only)"
      status: "pending"
      activeForm: "Detecting project stack"
    - content: "Read PROJECT_RULES.md for context"
      status: "pending"
      activeForm: "Reading PROJECT_RULES.md"
    - content: "Generate codebase report via ring:codebase-explorer"
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
    - content: "Handoff to ring:dev-cycle"
      status: "pending"
      activeForm: "Handing off to ring:dev-cycle"
```

**This is NON-NEGOTIABLE. Do not skip creating the todo list.**

---

## ⛔ CRITICAL: Specialized Agents Perform All Tasks

See [shared-patterns/shared-orchestrator-principle.md](../shared-patterns/shared-orchestrator-principle.md) for full ORCHESTRATOR principle, role separation, forbidden/required actions, step-to-agent mapping, and anti-rationalization table.

**Summary:** You orchestrate. Agents execute. If using Bash/Grep/Read to analyze code → STOP. Dispatch agent.

---

## Step 1: Validate PROJECT_RULES.md

**TodoWrite:** Mark "Validate PROJECT_RULES.md exists" as `in_progress`

<block_condition>
- docs/PROJECT_RULES.md does not exist
</block_condition>

If condition is true, output blocker and TERMINATE. Otherwise continue to Step 1.

**Check:** Does `docs/PROJECT_RULES.md` exist?

- **YES** → Mark todo as `completed`, continue to Step 1
- **no** → Output blocker and TERMINATE:

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

**TodoWrite:** Mark "Detect project stack (Go/TypeScript)" as `in_progress`

**⛔ SCOPE: BACKEND CODE ONLY.** This skill analyzes backend code exclusively. MUST use `ring:dev-refactor-frontend` for frontend code (React, Next.js, Vue, Angular).

Check for backend manifest files:

| File/Pattern | Stack | Agent |
|--------------|-------|-------|
| `go.mod` | Go Backend | ring:backend-engineer-golang |
| `package.json` + Express/Fastify/NestJS (no React/Next.js) | TypeScript Backend | ring:backend-engineer-typescript |

**Detection Logic:**
- `go.mod` exists → Add Go backend agent
- `package.json` exists + Express/Fastify/NestJS in dependencies (NO React/Next.js) → Add TypeScript backend agent
- `package.json` exists + React/Next.js in dependencies → **STOP: This is a frontend project. Use `ring:dev-refactor-frontend` instead.**

**⛔ FORBIDDEN:** Dispatching `ring:frontend-engineer`, `ring:frontend-designer`, `ring:ui-engineer`, `ring:qa-analyst-frontend`, or `ring:frontend-bff-engineer-typescript` from this skill. These are frontend agents and belong to `ring:dev-refactor-frontend`.

**TodoWrite:** Mark "Detect project stack (Go/TypeScript)" as `completed`

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

### ⛔ MANDATORY: Use Task Tool with ring:codebase-explorer

<dispatch_required agent="ring:codebase-explorer">
Generate a comprehensive codebase report describing WHAT EXISTS.

Include:
- Project structure and directory layout
- Architecture pattern (hexagonal, clean, etc.)
- Technology stack from manifests
- Code patterns: config, database, handlers, errors, telemetry, testing
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
- Bash(command="find ... -name '*.go'") → SKILL FAILURE
- Bash(command="ls -la ...") → SKILL FAILURE
- Bash(command="tree ...") → SKILL FAILURE
- Task(subagent_type="Explore", ...) → SKILL FAILURE
- Task(subagent_type="general-purpose", ...) → SKILL FAILURE
- Task(subagent_type="Plan", ...) → SKILL FAILURE
</forbidden>

Any of these = IMMEDIATE SKILL FAILURE.

### REQUIRED Action for Step 3

```
✅ Task(subagent_type="ring:codebase-explorer", ...)
```

**Timestamp format:** `{timestamp}` = `YYYY-MM-DDTHH:MM:SS` (e.g., `2026-02-07T22:30:45`). Generate once at start, reuse for all artifacts.

**After Task completes, save with Write tool:**

```
Write tool:
  file_path: "docs/ring:dev-refactor/{timestamp}/codebase-report.md"
  content: [Task output]
```

**TodoWrite:** Mark "Generate codebase report via ring:codebase-explorer" as `completed`

---

## Step 4: Dispatch Specialist Agents

**TodoWrite:** Mark "Dispatch specialist agents in parallel" as `in_progress`

### ⛔ File Size Enforcement (MANDATORY)

See [shared-patterns/file-size-enforcement.md](../shared-patterns/file-size-enforcement.md) for thresholds and agent instructions.

**All analysis agents MUST flag files exceeding 300 lines as ISSUE-XXX** (converted to FINDING-XXX during Step 4.1 mapping, like all other agent issues). Files > 500 lines are CRITICAL severity. Files > 1000 lines are CRITICAL with mandatory decomposition plan included in the finding. Each oversized file = one ISSUE-XXX (not grouped). **Test files are included** — large test files are equally hard to maintain.

### ⛔ HARD GATE: Verify codebase-report.md Exists

**BEFORE dispatching any specialist agent, verify:**

```
Check 1: Does docs/ring:dev-refactor/{timestamp}/codebase-report.md exist?
  - YES → Continue to dispatch agents
  - no  → STOP. Go back to Step 3.

Check 2: Was codebase-report.md created by ring:codebase-explorer?
  - YES → Continue
  - no (created by Bash output) → DELETE IT. Go back to Step 3. Use correct agent.
```

**If you skipped Step 3 or used Bash instead of Task tool → You MUST go back and redo Step 3 correctly.**

**Dispatch all applicable agents in ONE message (parallel):**

### ⛔ MANDATORY: Reference Standards Coverage Table

**All agents MUST follow [shared-patterns/standards-coverage-table.md](../shared-patterns/standards-coverage-table.md) which defines:**
- all sections to check per agent (including DDD)
- Required output format (Standards Coverage Table)
- Anti-rationalization rules
- Completeness verification

**Section indexes are pre-defined in shared-patterns. Agents MUST check all sections listed.**

---

### For Go projects:

<parallel_dispatch agents="ring:backend-engineer-golang, ring:qa-analyst, ring:qa-analyst[goroutine-leak], ring:devops-engineer, ring:sre">
MUST dispatch all five agents in parallel via Task tool.
Input: codebase-report.md, PROJECT_RULES.md
</parallel_dispatch>

```yaml
Task tool 1:
  subagent_type: "ring:backend-engineer-golang"
  description: "Go standards analysis"
  prompt: |
    **MODE: ANALYSIS only**

    ⛔ MANDATORY: Check all sections in golang.md per shared-patterns/standards-coverage-table.md

    ⛔ FRAMEWORKS & LIBRARIES DETECTION (MANDATORY):
    1. Read go.mod to extract all dependencies used in codebase
    2. Load golang.md standards via WebFetch → extract all listed frameworks/libraries
    3. For each category in standards (HTTP, Database, Validation, Testing, etc.):
       - Compare codebase dependency vs standards requirement
       - If codebase uses DIFFERENT library than standards → ISSUE-XXX
       - If codebase is MISSING required library → ISSUE-XXX
    4. any library not in standards that serves same purpose = ISSUE-XXX

    ⛔ FILE SIZE ENFORCEMENT (MANDATORY):
    - Any source file > 300 lines (including test files, excluding auto-generated: *.pb.go, */generated/*, */mocks*) MUST be flagged as ISSUE-XXX
    - 301-500 lines: severity HIGH
    - > 500 lines: severity CRITICAL
    - > 1000 lines: severity CRITICAL with explicit decomposition plan
    - Include current line count and proposed split strategy in each finding
    - See shared-patterns/file-size-enforcement.md for split patterns
    - Reference: golang/domain.md → File Organization (MANDATORY)

    Input:
    - Ring Standards: Load via WebFetch (golang.md)
    - Section Index: See shared-patterns/standards-coverage-table.md → "ring:backend-engineer-golang"
    - Codebase Report: docs/ring:dev-refactor/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    ⛔ MULTI-TENANT ANALYSIS (MANDATORY):
    See [shared-patterns/multi-tenant-analysis.md](../shared-patterns/multi-tenant-analysis.md) for the full checklist.

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. ISSUE-XXX for each ⚠️/❌ finding with: Pattern name, Severity, file:line, Current Code, Expected Code

Task tool 2:
  subagent_type: "ring:qa-analyst"
  description: "Test coverage analysis"
  prompt: |
    **MODE: ANALYSIS only**
    Check all testing sections per shared-patterns/standards-coverage-table.md → "ring:qa-analyst"
    Input: codebase-report.md, PROJECT_RULES.md
    Output: Standards Coverage Table + ISSUE-XXX for gaps

Task tool 3:
  subagent_type: "ring:devops-engineer"
  description: "DevOps analysis"
  prompt: |
    **MODE: ANALYSIS only**
    Check all 8 sections per shared-patterns/standards-coverage-table.md → "ring:devops-engineer"
    ⛔ "Containers" means BOTH Dockerfile and Docker Compose
    ⛔ "Makefile Standards" means all required commands: build, lint, test, cover, up, down, etc.
    Input: codebase-report.md, PROJECT_RULES.md
    Output: Standards Coverage Table + ISSUE-XXX for gaps

Task tool 4:
  subagent_type: "ring:sre"
  description: "Observability analysis"
  prompt: |
    **MODE: ANALYSIS only**
    Check all 6 sections per shared-patterns/standards-coverage-table.md → "ring:sre"
    Input: codebase-report.md, PROJECT_RULES.md
    Output: Standards Coverage Table + ISSUE-XXX for gaps

Task tool 5 (Go only):
  subagent_type: "ring:qa-analyst"
  description: "Goroutine leak analysis"
  prompt: |
    **MODE: ANALYSIS only**
    **test_mode: goroutine-leak**

    ⛔ GOROUTINE LEAK DETECTION MODE

    ## Standards Reference
    https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/architecture.md
    Focus on: Goroutine Leak Detection (MANDATORY) section

    ## Analysis Steps

    ### 1. Detect Goroutine Usage
    Scan all Go files for:
    - `go func()` patterns (anonymous goroutines)
    - `go methodCall()` patterns (direct calls)
    - Channel consumers (`for range channel`)
    - Worker pools and background services

    ### 2. Verify goleak Coverage
    For each package with goroutines:
    - Check for `goleak.VerifyTestMain(m)` in TestMain
    - Check for `defer goleak.VerifyNone(t)` in relevant tests
    - Verify go.uber.org/goleak is in go.mod

    ### 3. Identify Gaps
    Create ISSUE-XXX for:
    - Packages with goroutines but no goleak tests
    - Missing goleak.VerifyTestMain in packages with workers
    - Missing goleak.VerifyNone in specific tests

    Input:
    - Codebase Report: docs/ring:dev-refactor/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    ## Goroutine Detection Summary
    | File | Line | Pattern | Package |
    |------|------|---------|---------|
    
    ## goleak Coverage
    | Package | Goroutine Files | goleak Present | Status |
    |---------|-----------------|----------------|--------|
    
    ## Issues Found
    ISSUE-XXX for each gap (missing goleak, missing TestMain, etc.)
```

### For TypeScript Backend projects:

<parallel_dispatch agents="ring:backend-engineer-typescript, ring:qa-analyst, ring:devops-engineer, ring:sre">
All four agents MUST be dispatched in parallel via Task tool.
Input: codebase-report.md, PROJECT_RULES.md
</parallel_dispatch>

```yaml
Task tool 1:
  subagent_type: "ring:backend-engineer-typescript"
  description: "TypeScript backend standards analysis"
  prompt: |
    **MODE: ANALYSIS only**

    ⛔ MANDATORY: Check all sections in typescript.md per shared-patterns/standards-coverage-table.md

    ⛔ FRAMEWORKS & LIBRARIES DETECTION (MANDATORY):
    1. Read package.json to extract all dependencies used in codebase
    2. Load typescript.md standards via WebFetch → extract all listed frameworks/libraries
    3. For each category in standards (Backend Framework, ORM, Validation, Testing, etc.):
       - Compare codebase dependency vs standards requirement
       - If codebase uses DIFFERENT library than standards → ISSUE-XXX
       - If codebase is MISSING required library → ISSUE-XXX
    4. any library not in standards that serves same purpose = ISSUE-XXX

    ⛔ FILE SIZE ENFORCEMENT (MANDATORY):
    - Any source file > 300 lines (including test files, excluding auto-generated: *.d.ts, *.gen.ts, *.generated.ts, */generated/*, */__generated__/*) MUST be flagged as ISSUE-XXX
    - 301-500 lines: severity HIGH
    - > 500 lines: severity CRITICAL
    - > 1000 lines: severity CRITICAL with explicit decomposition plan
    - Include current line count and proposed split strategy in each finding
    - See shared-patterns/file-size-enforcement.md for split patterns
    - Reference: typescript.md → File Organization (MANDATORY)

    ⛔ MULTI-TENANT ANALYSIS (MANDATORY):
    See [shared-patterns/multi-tenant-analysis.md](../shared-patterns/multi-tenant-analysis.md) for the full checklist.

    Input:
    - Ring Standards: Load via WebFetch (typescript.md)
    - Section Index: See shared-patterns/standards-coverage-table.md → "ring:backend-engineer-typescript"
    - Codebase Report: docs/ring:dev-refactor/{timestamp}/codebase-report.md
    - Project Rules: docs/PROJECT_RULES.md

    Output:
    1. Standards Coverage Table (per shared-patterns format)
    2. ISSUE-XXX for each ⚠️/❌ finding with: Pattern name, Severity, file:line, Current Code, Expected Code
```

### Agent Dispatch Summary

| Stack Detected | Agents to Dispatch |
|----------------|-------------------|
| Go only | Task 1 (Go) + Task 2-4 + Task 5 (goroutine-leak) |
| TypeScript Backend only | Task 1 (TS Backend) + Task 2-4 |

**⛔ MUST use `ring:dev-refactor-frontend` for frontend/BFF projects.** This skill does not dispatch frontend agents.

**Note:** Task 5 (goroutine-leak) is Go-specific. It detects goroutine usage and verifies goleak test coverage.

**TodoWrite:** Mark "Dispatch specialist agents in parallel" as `completed`

---

## Step 4.5: Save Individual Agent Reports

**TodoWrite:** Mark "Save individual agent reports" as `in_progress`

**⛔ MANDATORY: Each agent's output MUST be saved as an individual report file.**

After all parallel agent tasks complete, save each agent's output to a separate file:

```
docs/ring:dev-refactor/{timestamp}/reports/
├── ring:backend-engineer-golang-report.md     (if Go project)
├── ring:backend-engineer-typescript-report.md (if TypeScript Backend)
├── ring:qa-analyst-report.md                  (always)
├── ring:qa-analyst-goroutine-leak-report.md   (if Go project)
├── ring:devops-engineer-report.md             (always)
└── ring:sre-report.md                         (always)
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
*Report generated by ring:dev-refactor skill*
```

### Agent Report Mapping

| Agent Dispatched | Report File Name |
|------------------|------------------|
| ring:backend-engineer-golang | `ring:backend-engineer-golang-report.md` |
| ring:backend-engineer-typescript | `ring:backend-engineer-typescript-report.md` |
| ring:qa-analyst | `ring:qa-analyst-report.md` |
| ring:qa-analyst (goroutine-leak) | `ring:qa-analyst-goroutine-leak-report.md` |
| ring:devops-engineer | `ring:devops-engineer-report.md` |
| ring:sre | `ring:sre-report.md` |

### Anti-Rationalization Table for Step 4.5

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll combine all reports into one file" | Individual reports enable targeted re-runs and tracking | **Save each agent to SEPARATE file** |
| "Agent output is already visible in chat" | Chat history is ephemeral; files are artifacts | **MUST persist as files** |
| "Only saving reports with issues" | Empty reports prove compliance was checked | **Save all dispatched agent reports** |
| "findings.md already captures everything" | findings.md is processed; reports are raw agent output | **Save BOTH raw reports and findings.md** |

### REQUIRED Action for Step 4.5

```
Write tool:
  file_path: "docs/ring:dev-refactor/{timestamp}/reports/{agent-name}-report.md"
  content: [Agent Task output formatted per template above]
```

**Repeat for each agent dispatched in Step 4.**

**TodoWrite:** Mark "Save individual agent reports" as `completed`

---

## Step 4.1: Agent Report → Findings Mapping (HARD GATE)

**TodoWrite:** Mark "Map agent findings to FINDING-XXX entries" as `in_progress`

**⛔ MANDATORY: all agent-reported issues MUST become findings.**

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

---

### Anti-Rationalization Table for Step 4.1

**⛔ See also: "Anti-Rationalization: Mandatory Gap Principle" at top of this skill.**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Multiple similar issues can be one finding" | Distinct file:line = distinct finding. Merging loses traceability. | **One issue = One FINDING-XXX** |
| "Agent report didn't use ISSUE-XXX format" | Format varies; presence matters. Every gap = one finding. | **Extract all gaps into findings** |
| "I'll consolidate to reduce noise" | Consolidation = data loss. Noise is signal. | **Preserve all individual issues** |
| "Some findings are duplicates across agents" | Different agents = different perspectives. Keep both. | **Create separate findings per agent** |
| "Team has approved this deviation" | Team approval ≠ standards compliance. Document the gap. | **Create FINDING-XXX, note team decision** |
| "Fixing this would break existing code" | Breaking risk = implementation concern, not tracking concern. | **Create FINDING-XXX, note risk in description** |

### ⛔ MANDATORY GAP RULE FOR STEP 4.1

**Per the Mandatory Gap Principle (see top of skill): any divergence from Ring standards = FINDING-XXX.**

This means:
- ✅ items in Standards Coverage Table = No finding needed
- ⚠️ items = MUST create FINDING-XXX (partial compliance is a gap)
- ❌ items = MUST create FINDING-XXX (non-compliance is a gap)
- Different pattern = MUST create FINDING-XXX (alternative is still a gap)

**Verification:** Use formula from "Mandatory Gap Principle → Verification Rule" section.

### ⛔ Gate Escape Detection (Anti-Duplication)

**When mapping findings, identify which gate SHOULD have caught the issue:**

| Finding Category | Should Be Caught In | Flag |
|------------------|---------------------|------|
| Missing edge case tests | Gate 3 (Testing) | `🚨 GATE 3 ESCAPE` |
| Test isolation issues | Gate 3 (Testing) | `🚨 GATE 3 ESCAPE` |
| Skipped/assertion-less tests | Gate 3 (Testing) | `🚨 GATE 3 ESCAPE` |
| Test naming convention | Gate 3 (Testing) | `🚨 GATE 3 ESCAPE` |
| Missing test coverage | Gate 3 (Testing) | `🚨 GATE 3 ESCAPE` |
| TDD RED phase missing | Gate 3 (Testing) | `🚨 GATE 3 ESCAPE` |
| Implementation pattern gaps | Gate 0 (Implementation) | Normal finding |
| Standards compliance gaps | Gate 0 (Implementation) | Normal finding |
| Observability gaps | Gate 2 (SRE) | `🚨 GATE 2 ESCAPE` |
| Docker/DevOps gaps | Gate 1 (DevOps) | `🚨 GATE 1 ESCAPE` |

**Gate Escape Output Format:**

```markdown
### FINDING-XXX: [Issue Title] 🚨 GATE 3 ESCAPE

**Escaped From:** Gate 3 (Testing)
**Why It Escaped:** [Quality Gate check that should have caught this]
**Prevention:** [Specific check to add to Gate 3 exit criteria]

[Rest of finding format...]
```

**Purpose:** Track which issues escape which gates. If many `GATE 3 ESCAPE` findings occur, the Quality Gate checks need strengthening.

---

**Summary Table (MANDATORY at end of findings.md):**

```markdown
## Gate Escape Summary

| Gate | Escaped Issues | Most Common Type |
|------|----------------|------------------|
| Gate 0 (Implementation) | N | [type] |
| Gate 1 (DevOps) | N | [type] |
| Gate 2 (SRE) | N | [type] |
| Gate 3 (Testing) | N | [type] |

**Action Required:** If any gate has >2 escapes, review that gate's exit criteria.
```

**TodoWrite:** Mark "Map agent findings to FINDING-XXX entries" as `completed`

---

## Step 5: Generate findings.md

**TodoWrite:** Mark "Generate findings.md" as `in_progress`

### ⛔ HARD GATE: Verify All Issues Are Mapped

**BEFORE creating findings.md, apply the Verification Rule from "Mandatory Gap Principle" section.**

If counts don't match → STOP. Go back to Step 4.1. Map missing issues.

### FORBIDDEN Actions for Step 5

```
❌ Creating findings.md with fewer entries than agent issues  → SKILL FAILURE
❌ Omitting file:line references from findings                → SKILL FAILURE
❌ Using vague descriptions instead of specific code excerpts → SKILL FAILURE
❌ Skipping "Why This Matters" section for any finding        → SKILL FAILURE
❌ Generating findings.md without reading all agent reports   → SKILL FAILURE
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
| "I'll add details later during implementation" | findings.md is the source of truth. Incomplete = useless. | **Complete all sections for every finding** |
| "Code snippet is too long to include" | Truncate to relevant lines, but never omit. Context is required. | **Include code with file:line reference** |
| "Standard URL is obvious, skip it" | Agents and humans need direct links. Nothing is obvious. | **Include full URL for every standard** |
| "Why This Matters is redundant" | It explains business impact. Standards alone don't convey urgency. | **Write Problem/Standard/Impact for all** |
| "Some findings are self-explanatory" | Self-explanatory to you ≠ clear to implementer. | **Complete all sections without exception** |
| "I'll group small findings together" | Each finding = one task in Step 6. findings.md = atomic issues. | **One finding = one FINDING-XXX entry** |

**Use Write tool to create findings.md:**

**⛔ CRITICAL: Every issue reported by agents in Step 4 MUST appear here as a FINDING-XXX entry.**

```markdown
# Findings: {project-name}

**Generated:** {timestamp}
**Total Findings:** {count}

## ⛔ Mandatory Gap Principle Applied

**all divergences from Ring standards are tracked below. No filtering applied.**

| Metric | Count |
|--------|-------|
| Total non-✅ items from agent reports | {X} |
| Total FINDING-XXX entries below | {X} |
| **Counts match?** | ✅ YES (REQUIRED) |

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
**Category:** {lib-commons | architecture | testing | devops}
**Agent:** {agent-name}
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

## Step 6: Map Findings to Tasks (1:1)

**TodoWrite:** Mark "Map findings 1:1 to REFACTOR-XXX tasks" as `in_progress`

**⛔ HARD GATE: One FINDING-XXX = One REFACTOR-XXX task. No grouping.**

Each finding becomes its own task. This prevents findings from being lost inside grouped tasks.

**1:1 Mapping Rule:**
- FINDING-001 → REFACTOR-001
- FINDING-002 → REFACTOR-002
- FINDING-NNN → REFACTOR-NNN

**Ordering:** Sort tasks by severity (Critical first), then by dependency order.

**Mapping Verification:**
```
Before proceeding to Step 7, verify:
- Total FINDING-XXX in findings.md: X
- Total REFACTOR-XXX in tasks.md: X (MUST MATCH exactly)
- Orphan findings (not mapped): 0 (MUST BE ZERO)
- Grouped tasks (multiple findings): 0 (MUST BE ZERO)
```

**If counts don't match → STOP. Every finding MUST have its own task.**

### Anti-Rationalization Table for Step 6

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "These findings are in the same file, I'll group them" | Grouping hides findings. One fix may be done, others forgotten. | **One finding = One task. No exceptions.** |
| "Grouping reduces task count and is easier to manage" | Fewer tasks = less visibility. Each finding needs independent tracking. | **Create one REFACTOR-XXX per FINDING-XXX** |
| "These are related and should be fixed together" | Related ≠ same task. Dev-cycle can execute them sequentially. | **Separate tasks, use Dependencies field to link** |
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

## ⛔ Mandatory 1:1 Mapping Verification

**Every FINDING-XXX has exactly one REFACTOR-XXX. No grouping.**

| Metric | Count |
|--------|-------|
| Total FINDING-XXX in findings.md | {X} |
| Total REFACTOR-XXX in tasks.md | {X} |
| **Counts match exactly?** | ✅ YES (REQUIRED) |
| Grouped tasks (multiple findings) | 0 (REQUIRED) |

**Priority affects execution order, not whether to include:**
- Critical/High tasks: Execute first
- Medium tasks: Execute in current cycle
- Low tasks: Execute when capacity - STILL MANDATORY TO COMPLETE

---

## REFACTOR-001: {Finding Pattern Name}

**Finding:** FINDING-001
**Severity:** Critical | High | Medium | Low (all ARE MANDATORY)
**Category:** {lib-commons | architecture | testing | devops}
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
- [ ] Code follows {standard}.md → {section} pattern
- [ ] No {anti-pattern} usage remains
- [ ] Tests pass after refactoring
```

**TodoWrite:** Mark "Generate tasks.md" as `completed`

---

## Step 7.5: Visual Change Report

**TodoWrite:** Mark "Generate visual change report" as `in_progress`

**MANDATORY:** Invoke `Skill("ring:visual-explainer")` to produce a self-contained HTML page showing all planned refactoring changes. This replaces reading raw findings.md / tasks.md markdown for approval decisions.

**Read the code-diff template first:** Read `default/skills/visual-explainer/templates/code-diff.html` to absorb the patterns before generating.

**Generate the HTML report with these sections:**

### 1. Summary Dashboard
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

**Output:** Save to `docs/ring:dev-refactor/{timestamp}/change-report.html`

**Open in browser:**
```text
macOS: open docs/ring:dev-refactor/{timestamp}/change-report.html
Linux: xdg-open docs/ring:dev-refactor/{timestamp}/change-report.html
```

**Tell the user** the file path. The report opens before the approval question so the user can review changes visually.

See [shared-patterns/anti-rationalization-visual-report.md](../shared-patterns/anti-rationalization-visual-report.md) for anti-rationalization table.

**TodoWrite:** Mark "Generate visual change report" as `completed`

---

## Step 8: User Approval

**TodoWrite:** Mark "Get user approval" as `in_progress`

<user_decision>
MUST wait for explicit user response before proceeding.
Options: Approve all | Critical only | Cancel
</user_decision>

```yaml
AskUserQuestion:
  questions:
    - question: "Review refactoring plan. How to proceed?"
      header: "Approval"
      options:
        - label: "Approve all"
          description: "Proceed to ring:dev-cycle execution"
        - label: "Critical only"
          description: "Execute only Critical/High tasks"
        - label: "Cancel"
          description: "Keep analysis, skip execution"
```

CANNOT proceed without explicit user selection.

**TodoWrite:** Mark "Get user approval" as `completed`

---

## Step 9: Save Artifacts

**TodoWrite:** Mark "Save all artifacts" as `in_progress`

```
docs/ring:dev-refactor/{timestamp}/
├── codebase-report.md  (Step 3)
├── reports/            (Step 4.5)
│   ├── ring:backend-engineer-golang-report.md
│   ├── ring:qa-analyst-report.md
│   ├── ring:devops-engineer-report.md
│   └── ring:sre-report.md
├── findings.md         (Step 5)
├── tasks.md           (Step 7)
└── change-report.html (Step 7.5)
```

**TodoWrite:** Mark "Save all artifacts" as `completed`

---

## Step 10: Handoff to ring:dev-cycle

**TodoWrite:** Mark "Handoff to ring:dev-cycle" as `in_progress`

**If user approved, use Skill tool to invoke ring:dev-cycle directly:**

```yaml
Skill tool:
  skill: "ring:dev-cycle"
```

**⛔ CRITICAL: Pass tasks file path in context:**

After invoking the skill, provide:
- Tasks file: `docs/ring:dev-refactor/{timestamp}/tasks.md`

```yaml
Context for ring:dev-cycle:
  tasks-file: "docs/ring:dev-refactor/{timestamp}/tasks.md"
```

Where `{timestamp}` format is `YYYY-MM-DDTHH:MM:SS` (e.g., `2026-02-07T22:30:45`). Use the same timestamp across all artifacts in a single run.

### Anti-Rationalization: Skill Invocation

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "SlashCommand is equivalent to Skill tool" | SlashCommand is a hint; Skill tool guarantees skill loading | **Use Skill tool, not SlashCommand** |
| "User can run /ring:dev-cycle manually" | Manual run risks skill not being loaded | **Invoke Skill tool directly** |
| "ring:dev-cycle will auto-discover tasks" | Explicit path ensures correct file is used | **Pass explicit tasks path** |
| "User approved, I can skip ring:dev-cycle" | Approval = permission to proceed, not skip execution | **Invoke Skill tool** |
| "Tasks are saved, job is done" | Saved tasks without execution = incomplete workflow | **Invoke Skill tool** |

**⛔ HARD GATE: You CANNOT complete ring:dev-refactor without invoking `Skill tool: ring:dev-cycle`.**

If user approved execution, you MUST:
1. Invoke `Skill tool: ring:dev-cycle`
2. Pass tasks file path: `docs/ring:dev-refactor/{timestamp}/tasks.md`
3. Wait for ring:dev-cycle to complete all 10 gates

**Skipping this step = SKILL FAILURE.**

ring:dev-cycle executes each REFACTOR-XXX task through 10-gate process. After all tasks complete, ring:dev-multi-tenant runs as a post-cycle step to adapt all implemented code for multi-tenant support.

**TodoWrite:** Mark "Handoff to ring:dev-cycle" as `completed`

---

## Execution Report

Base metrics per [shared-patterns/output-execution-report.md](../shared-patterns/output-execution-report.md).

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Refactor-Specific Metrics
| Metric | Value |
|--------|-------|
| Agents Dispatched | N |
| Findings Generated | N |
| Tasks Created | N |
| Artifacts Location | docs/ring:dev-refactor/{date}/ |

## Output Schema

```yaml
artifacts:
  - codebase-report.md (Step 3)
  - reports/{agent-name}-report.md (Step 4.5)
  - findings.md (Step 5)
  - tasks.md (Step 7)
  - change-report.html (Step 7.5)

traceability:
  Ring Standard → Agent Report → FINDING-XXX → REFACTOR-XXX → Implementation
```


