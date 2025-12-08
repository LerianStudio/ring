---
name: dev-refactor
description: |
  Analyzes existing codebase against standards to identify gaps in architecture, code quality,
  testing, and DevOps. Auto-detects project language and uses appropriate agent standards
  (Go, TypeScript, Frontend, DevOps, SRE). Generates refactoring tasks.md compatible with dev-cycle.

trigger: |
  - User wants to refactor existing project to follow standards
  - User runs /ring-dev-team:dev-refactor command
  - Legacy codebase needs modernization
  - Project audit requested

skip_when: |
  - Greenfield project → Use /ring-pm-team:pre-dev-* instead
  - Single file fix → Use ring-dev-team:dev-cycle directly
  - Unknown language (no go.mod, package.json, etc.) → Specify language manually

sequence:
  before: [ring-dev-team:dev-cycle]

related:
  similar: [ring-pm-team:pre-dev-research]
  complementary: [ring-dev-team:dev-cycle, ring-dev-team:dev-implementation]
---

# Dev Refactor Skill

This skill analyzes an existing codebase to identify gaps between current implementation and project standards, then generates a structured refactoring plan compatible with the dev-cycle workflow.

## What This Skill Does

1. **Detects project language** (Go, TypeScript, Python) from manifest files
2. **Reads PROJECT_RULES.md** (project-specific standards - MANDATORY)
3. **Dispatches specialized agents** that load their own Ring standards via WebFetch
4. **Compiles agent findings** into structured analysis report
5. **Generates tasks.md** in the same format as PM Team output
6. **User approves** the plan before execution via dev-cycle

## Foundational Principle

**REFACTORING ANALYSIS IS NOT OPTIONAL FOR CODEBASES WITH TECHNICAL DEBT**

When user requests refactoring or improvement:
1. **NEVER** skip analysis because "code works"
2. **ALWAYS** analyze all 4 dimensions
3. **DOCUMENT** all findings, not just critical
4. **PRESERVE** full analysis even if user filters later

**Cost comparison:**
- Cost of refactoring now: Known, bounded
- Cost of compounding debt: Unknown, unbounded

**Analysis now saves 10x effort later.**

## Pressure Resistance

**Codebase analysis is MANDATORY when requested. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Works Fine** | "Code works, skip analysis" | "Working ≠ maintainable. Analysis reveals hidden technical debt." |
| **Time** | "No time for full analysis" | "Partial analysis = partial picture. Technical debt compounds daily." |
| **Legacy** | "Standards don't apply to legacy" | "Legacy code needs analysis MOST. Document gaps for improvement." |
| **Critical Only** | "Only fix critical issues" | "Medium issues become critical. Document all, prioritize later." |

**Non-negotiable principle:** If user requests refactoring analysis, complete ALL 4 dimensions (Architecture, Code, Testing, DevOps).

## Common Rationalizations - REJECTED

| Excuse | Reality |
|--------|---------|
| "Code works fine" | Working ≠ maintainable. Analysis finds hidden debt. |
| "Too time-consuming" | Cost of analysis < cost of compounding debt. |
| "Standards don't fit us" | Then document YOUR standards. Analysis still reveals gaps. |
| "Only critical matters" | Today's medium = tomorrow's critical. Document all. |
| "Legacy gets a pass" | Legacy sets precedent. Analysis shows what to improve. |
| "Team has their own way" | Document "their way" as standards. Analyze against it. |
| "ROI of refactoring is low" | ROI calculation requires analysis. You can't calculate without data. |
| "Partial analysis is enough" | Partial analysis = partial picture. Hidden debt in skipped areas. |
| "3 years without bugs = stable" | No bugs ≠ no debt. Time doesn't validate architecture. |
| "Analysis is overkill" | Analysis is the MINIMUM. Refactoring without analysis is guessing. |
| "Code smells ≠ problems" | Code smells ARE problems. They slow development and cause bugs. |
| "No specific problem motivating" | Technical debt IS the problem. Analysis quantifies it. |
| "Analysis complete, user can decide" | Analysis without action guidance is incomplete. Provide tasks.md. |
| "Findings documented, my job done" | Findings → Tasks → Execution. Documentation alone changes nothing. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "Code works, no need to analyze"
- "This is too time-consuming"
- "Standards don't apply here"
- "Only critical issues matter"
- "Legacy code is exempt"
- "That's just how we do it here"
- "ROI doesn't justify full analysis"
- "Partial analysis is sufficient"
- "3+ years stable = no debt"
- "Analysis is overkill"
- "Code smells aren't real problems"
- "No specific problem to solve"
- "Analysis is done, user decides next"
- "Documented findings, job complete"

**All of these indicate analysis violation. Complete full 4-dimension analysis.**

## Analysis-to-Action Pipeline - MANDATORY

**Analysis without action guidance is incomplete:**

| Deliverable | Required? | Purpose |
|-------------|----------|---------|
| analysis-report.md | ✅ YES | Document findings |
| tasks.md | ✅ YES | Convert findings to actionable tasks |
| User approval prompt | ✅ YES | Get explicit decision on execution |

**Analysis completion checklist:**
- [ ] All 4 dimensions analyzed
- [ ] Findings categorized by severity
- [ ] Findings converted to REFACTOR-XXX tasks
- [ ] tasks.md generated in PM Team format
- [ ] User presented with approval options

**"Analysis complete" means tasks.md exists and user has been asked to approve.**

**If analysis ends without tasks.md:**
1. Analysis is NOT complete
2. Step 6 (Generate tasks.md) was skipped
3. Return to Step 6 before declaring completion

## Analysis Dimensions - ALL REQUIRED

**Every analysis MUST cover all 4 dimensions:**

| Dimension | What It Checks | Skip Allowed? |
|-----------|---------------|---------------|
| Architecture | Patterns, structure, dependencies | ❌ NO |
| Code Quality | Standards compliance, complexity, naming | ❌ NO |
| Testing | Coverage, test quality, TDD compliance | ❌ NO |
| DevOps | Containerization, CI/CD, infrastructure | ❌ NO |

**If user says "only check X":**
- Check X thoroughly
- Check other dimensions briefly
- Report: "Full analysis recommended for dimensions: [Y, Z]"

**NEVER produce partial analysis without noting gaps.**

## Cancellation Documentation - MANDATORY

**If user cancels analysis at approval step:**

1. **ASK:** "Why is analysis being cancelled?"
2. **DOCUMENT:** Save reason to `docs/refactor/{timestamp}/cancelled-reason.md`
3. **PRESERVE:** Keep partial analysis artifacts
4. **NOTE:** "Analysis cancelled by user: [reason]. Partial findings preserved."

**Cancellation without documentation is NOT allowed.**

## Prerequisites

Before starting analysis:

1. **Project root identified**: Know where the codebase lives
2. **Language detectable**: Project has go.mod, package.json, or similar manifest
3. **Scope defined**: Full project or specific directories
4. **PROJECT_RULES.md exists**: MANDATORY - analysis cannot proceed without it

### PROJECT_RULES.md is MANDATORY

**This is a HARD GATE. Do NOT proceed without PROJECT_RULES.md.**

```text
Check sequence:
1. Look for: docs/PROJECT_RULES.md
2. If not found: Look for docs/STANDARDS.md (legacy name)
3. If not found: STOP - Cannot analyze without project standards

BLOCKER response if missing:
"Cannot proceed with refactoring analysis.

REQUIRED: docs/PROJECT_RULES.md must exist.

Why is this mandatory?
- Agent defaults are GENERIC, not tailored to YOUR project
- Analysis without project standards = incomplete findings
- Refactoring must target YOUR conventions, not generic ones

**Common Rationalizations - REJECTED:**

| Excuse | Reality |
|--------|---------|
| "Agent defaults are fine" | Defaults are generic. YOUR project has specific conventions. |
| "We'll add it later" | Analysis now with wrong standards = rework later. |
| "It's a small project" | Small projects need standards too. Start right. |
| "Just use best practices" | "Best" varies by context. YOUR rules define YOUR best. |

**Note:** After PROJECT_RULES.md check passes, specialized agents are dispatched. Each agent loads its own Ring standards via WebFetch (e.g., devops-engineer loads devops.md, sre loads sre.md). The dev-refactor skill only reads PROJECT_RULES.md locally - it does NOT do WebFetch itself.

## Analysis Dimensions

### 1. Architecture Analysis

```text
Checks:
├── DDD Patterns (if enabled in PROJECT_RULES.md)
│   ├── Entities have identity comparison
│   ├── Value Objects are immutable
│   ├── Aggregates enforce invariants
│   ├── Repositories are interface-based
│   └── Domain events for state changes
│
├── Clean Architecture / Hexagonal
│   ├── Dependency direction (inward only)
│   ├── Domain has no external dependencies
│   ├── Ports defined as interfaces
│   └── Adapters implement ports
│
└── Directory Structure
    ├── Matches PROJECT_RULES.md layout
    ├── Separation of concerns
    └── No circular dependencies
```

### 2. Code Quality Analysis

```text
Checks:
├── Naming Conventions
│   ├── Files match pattern (snake_case, kebab-case, etc.)
│   ├── Functions/methods follow convention
│   └── Constants are UPPER_SNAKE
│
├── Error Handling
│   ├── No ignored errors (_, err := ...)
│   ├── Errors wrapped with context
│   ├── No panic() for business logic
│   └── Custom error types for domain
│
├── Forbidden Practices
│   ├── No global mutable state
│   ├── No magic numbers/strings
│   ├── No commented-out code
│   ├── No TODO without issue reference
│   └── No `any` type (TypeScript)
│
└── Security
    ├── Input validation at boundaries
    ├── Parameterized queries (no SQL injection)
    ├── Sensitive data not logged
    └── Secrets not hardcoded
```

### 3. Testing Analysis

```text
Checks:
├── Test Coverage
│   ├── Current coverage percentage
│   ├── Gap to minimum (80%)
│   └── Critical paths covered
│
├── Test Patterns
│   ├── Table-driven tests (Go)
│   ├── Arrange-Act-Assert structure
│   ├── Mocks for external dependencies
│   └── No test pollution (global state)
│
├── Test Naming
│   ├── Follows Test{Unit}_{Scenario}_{Expected}
│   └── Descriptive test names
│
└── Test Types
    ├── Unit tests exist
    ├── Integration tests exist
    └── Test fixtures/factories
```

### 4. DevOps Analysis

```text
Checks:
├── Containerization
│   ├── Dockerfile exists
│   ├── Multi-stage build
│   ├── Non-root user
│   └── Health check defined
│
├── Local Development
│   ├── docker-compose.yml exists
│   ├── All services defined
│   └── Volumes for hot reload
│
├── Environment
│   ├── .env.example exists
│   ├── All env vars documented
│   └── No secrets in repo
│
└── CI/CD
    ├── Pipeline exists
    ├── Tests run in CI
    └── Linting enforced
```

## Step 0: Verify PROJECT_RULES.md Exists (HARD GATE)

**This step is NON-NEGOTIABLE. Analysis CANNOT proceed without project standards.**

```text
Check sequence:
1. Check: docs/PROJECT_RULES.md
2. Check: docs/STANDARDS.md (legacy name)
3. Check: --standards argument (if provided)

Decision:
├── Found → Proceed to Step 1
└── NOT Found → STOP with blocker
```

**If PROJECT_RULES.md is missing:**

```yaml
# STOP - Do not proceed. Report blocker:
Blocker:
  type: "missing_prerequisite"
  message: |
    Cannot proceed with refactoring analysis.

    REQUIRED: docs/PROJECT_RULES.md must exist.

    Why is this mandatory?
    - Agent defaults are GENERIC, not tailored to YOUR project
    - Analysis without project standards = incomplete findings
    - Refactoring must target YOUR conventions, not generic ones
```

**Pressure Resistance for Step 0:**

| Pressure | Response |
|----------|----------|
| "Just use defaults" | "Defaults are generic. YOUR project needs YOUR rules. Create PROJECT_RULES.md." |
| "We don't have standards" | "Then this is the perfect time to define them. Use the template as starting point." |
| "Skip this, analyze anyway" | "Cannot skip. Analysis without target = meaningless findings." |

---

## Step 1: Detect Project Language

After PROJECT_RULES.md is verified, identify the primary language(s) of the project:

```text
Language Detection:
├── go.mod exists → Go project
│   └── Standards: backend-engineer-golang.md
│
├── package.json exists
│   ├── Has "react" or "next" dependency → Frontend TypeScript
│   │   └── Standards: frontend-bff-engineer-typescript.md
│   ├── Has backend deps (express, fastify, nestjs) → Backend TypeScript
│   │   └── Standards: backend-engineer-typescript.md
│   └── Otherwise → Generic TypeScript
│       └── Standards: Check for frontend/backend patterns
│
├── Dockerfile exists → Check for DevOps standards
│   └── Standards: devops-engineer.md
│
└── Multiple languages detected → Use all applicable standards

Output:
- Primary language: {Go/TypeScript/Python/etc.}
- Project type: {Backend API/Frontend/Full-stack/CLI}
- Agent standards to use: {list of agent files}
```

## Step 2: Read PROJECT_RULES.md

**Read the project-specific standards file:**

```text
Action: Use Read tool to load docs/PROJECT_RULES.md

This file contains:
- Project-specific conventions
- Technology stack decisions
- Architecture patterns chosen for THIS project
- Team-specific coding standards
```

**What dev-refactor does NOT do:**
- Does NOT call WebFetch for Ring standards
- Does NOT load golang.md, typescript.md, devops.md, sre.md directly

**Why?** Each specialized agent (devops-engineer, sre, qa-analyst, backend-engineer-*) has its own WebFetch instructions in its agent definition. They load their own standards when dispatched. This avoids duplication and keeps responsibilities clear:

| Component | Responsibility |
|-----------|---------------|
| **dev-refactor** | Reads PROJECT_RULES.md (local), dispatches agents, compiles findings |
| **Agents** | Load Ring standards via WebFetch, analyze their dimension, return findings |

**Output of this step:**
- PROJECT_RULES.md content loaded and understood
- Ready to dispatch agents with project context

## Step 3: Scan Codebase

All analysis uses specialized Lerian agents that load Ring standards via WebFetch. This ensures analysis is done by the same agents that will implement fixes, providing consistency and domain expertise.

### Agent Selection Based on Language Detection

Select the appropriate code analysis agent based on Step 1 language detection:

| Language/Project Type | Code Analysis Agent |
|-----------------------|---------------------|
| Go (`go.mod` exists) | `ring-dev-team:backend-engineer-golang` |
| TypeScript Backend (express, fastify, nestjs) | `ring-dev-team:backend-engineer-typescript` |
| TypeScript Frontend (react, next) | `ring-dev-team:frontend-bff-engineer-typescript` |
| Frontend Design/CSS | `ring-dev-team:frontend-designer` |
| Mixed/Multiple | Dispatch multiple code agents in parallel |

### Parallel Analysis Dispatch (Single Message, 4-5 Task Tools)

**IMPORTANT:** All agents MUST be dispatched in a SINGLE message with multiple Task tool calls. This is a parallel dispatch, NOT sequential.

Each agent will:
1. Read `docs/PROJECT_RULES.md` automatically (per Standards Loading section)
2. Load its Ring standards via WebFetch (as defined in agent definition)
3. Return dimension-specific findings

```yaml
# Task 1: Code & Architecture Analysis (language-specific)
# Select based on language detection from Step 1:

# For Go projects:
Task tool:
  subagent_type: "ring-dev-team:backend-engineer-golang"
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY** (do not implement, only report findings)

    Analyze this Go codebase for refactoring opportunities.

    Focus on:
    - Directory structure compliance with PROJECT_RULES.md
    - DDD patterns (Entities, Value Objects, Aggregates, Repositories)
    - Clean/Hexagonal Architecture (dependency direction)
    - Error handling patterns (no ignored errors, proper wrapping)
    - Naming conventions (files, functions, constants)
    - Anti-patterns and technical debt
    - Security issues (input validation, SQL injection, secrets)

    Return findings with severity (Critical/High/Medium/Low), location (file:line), issue, and recommendation.

# For TypeScript Backend projects:
Task tool:
  subagent_type: "ring-dev-team:backend-engineer-typescript"
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY** (do not implement, only report findings)

    Analyze this TypeScript backend codebase for refactoring opportunities.

    Focus on:
    - Directory structure compliance with PROJECT_RULES.md
    - Clean Architecture patterns
    - Type safety (no `any`, proper interfaces)
    - Error handling patterns
    - Async/await patterns
    - Security issues

    Return findings with severity, location, issue, and recommendation.

# For TypeScript Frontend/BFF projects:
Task tool:
  subagent_type: "ring-dev-team:frontend-bff-engineer-typescript"
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY** (do not implement, only report findings)

    Analyze this TypeScript frontend/BFF codebase for refactoring opportunities.

    Focus on:
    - Component structure and patterns
    - State management
    - API layer architecture
    - Type safety
    - Performance patterns

    Return findings with severity, location, issue, and recommendation.

# Task 2: Testing Analysis (ALWAYS included)
Task tool:
  subagent_type: "ring-dev-team:qa-analyst"
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY** (do not implement, only report findings)

    Analyze test coverage and patterns for refactoring.

    Check:
    - Test coverage percentage (minimum 80% required)
    - Test patterns (table-driven for Go, AAA structure)
    - TDD compliance indicators
    - Missing test cases for critical paths
    - Test naming conventions
    - Mock usage and test isolation

    Return findings with severity and specific file locations.

# Task 3: DevOps Analysis (ALWAYS included)
Task tool:
  subagent_type: "ring-dev-team:devops-engineer"
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY** (do not implement, only report findings)

    Analyze infrastructure setup for refactoring.

    Check:
    - Dockerfile exists and follows best practices (multi-stage, non-root, health check)
    - docker-compose.yml configuration (services, volumes, depends_on)
    - Environment management (.env.example with all vars documented)

    Return findings with severity and specific file locations.

# Task 4: SRE Analysis (ALWAYS included)
Task tool:
  subagent_type: "ring-dev-team:sre"
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY** (do not implement, only report findings)

    Analyze observability setup for refactoring.

    Check:
    - Health check endpoints (/health liveness, /ready readiness)
    - Structured JSON logging with correlation IDs
    - Tracing setup per Ring standards

    Return findings with severity and specific file locations.
```

**Note:** Each agent reads `docs/PROJECT_RULES.md` and loads Ring standards automatically. The `**MODE: ANALYSIS ONLY**` prefix ensures they report findings without implementing changes.

**Output:** Dimension-specific findings with severities to compile in Step 4.

## Step 4: Compile Findings

**Collect outputs from all dispatched agents and merge into structured report.**

Each agent returns findings in their output. The dev-refactor skill must:
1. **Collect** all agent outputs (backend-engineer-*, qa-analyst, devops-engineer, sre)
2. **Parse** findings from each output (severity, location, issue, recommendation)
3. **Deduplicate** overlapping findings
4. **Categorize** by dimension (Architecture, Code Quality, Testing, DevOps)
5. **Sort** by severity (Critical → High → Medium → Low)

**Merge results into structured report:**

```markdown
# Analysis Report: {project-name}

**Generated:** {date}
**Standards:** {path to PROJECT_RULES.md used}
**Scope:** {directories analyzed}

## Summary

| Dimension    | Issues | Critical | High | Medium | Low |
|--------------|--------|----------|------|--------|-----|
| Architecture | 12     | 2        | 4    | 4      | 2   |
| Code Quality | 23     | 1        | 8    | 10     | 4   |
| Testing      | 8      | 3        | 3    | 2      | 0   |
| DevOps       | 5      | 0        | 2    | 2      | 1   |
| **Total**    | **48** | **6**    | **17**| **18**| **7**|

## Critical Issues (Fix Immediately)

### ARCH-001: Domain depends on infrastructure
**Location:** `src/domain/user.go:15`
**Issue:** Domain entity imports database package
**Standard:** Domain layer must have zero external dependencies
**Fix:** Extract repository interface, inject via constructor

### CODE-001: SQL injection vulnerability
**Location:** `src/handler/search.go:42`
**Issue:** User input concatenated into SQL query
**Standard:** Always use parameterized queries
**Fix:** Use query builder or prepared statements

...

## High Priority Issues
...

## Medium Priority Issues
...

## Low Priority Issues
...
```

## Step 5: Prioritize and Group

Group related issues into logical refactoring tasks:

```text
Grouping Strategy:
1. By bounded context / module
2. By dependency order (fix dependencies first)
3. By risk (critical security first)

Example grouping:
├── REFACTOR-001: Fix domain layer isolation
│   ├── ARCH-001: Remove infra imports from domain
│   ├── ARCH-003: Extract repository interfaces
│   └── ARCH-005: Move domain events to domain layer
│
├── REFACTOR-002: Implement proper error handling
│   ├── CODE-002: Wrap errors with context (15 locations)
│   ├── CODE-007: Replace panic with error returns
│   └── CODE-012: Add custom domain error types
│
├── REFACTOR-003: Add missing test coverage
│   ├── TEST-001: User service unit tests
│   ├── TEST-002: Order handler tests
│   └── TEST-003: Repository integration tests
│
└── REFACTOR-004: Containerization improvements
    ├── DEVOPS-001: Add multi-stage Dockerfile
    └── DEVOPS-002: Create docker-compose.yml
```

## Step 6: Generate tasks.md

Create refactoring tasks in the same format as PM Team output:

```markdown
# Refactoring Tasks: {project-name}

**Source:** Analysis Report {date}
**Total Tasks:** {count}
**Estimated Effort:** {total hours}

---

## REFACTOR-001: Fix domain layer isolation

**Type:** backend
**Effort:** 4h
**Priority:** Critical
**Dependencies:** none

### Description
Remove infrastructure dependencies from domain layer and establish proper
port/adapter boundaries following hexagonal architecture.

### Acceptance Criteria
- [ ] AC-1: Domain package has zero imports from infrastructure
- [ ] AC-2: Repository interfaces defined in domain layer
- [ ] AC-3: All domain entities use dependency injection
- [ ] AC-4: Existing tests still pass

### Technical Notes
- Files to modify: src/domain/*.go
- Pattern: See PROJECT_RULES.md → Hexagonal Architecture section
- Related issues: ARCH-001, ARCH-003, ARCH-005

### Issues Addressed
| ID | Description | Location |
|----|-------------|----------|
| ARCH-001 | Domain imports database | src/domain/user.go:15 |
| ARCH-003 | No repository interface | src/domain/ |
| ARCH-005 | Events in wrong layer | src/infrastructure/events.go |

---

## REFACTOR-002: Implement proper error handling

**Type:** backend
**Effort:** 3h
**Priority:** High
**Dependencies:** REFACTOR-001

### Description
Standardize error handling across the codebase following Go idioms
and project standards.

### Acceptance Criteria
- [ ] AC-1: All errors wrapped with context using fmt.Errorf
- [ ] AC-2: No panic() outside of main.go
- [ ] AC-3: Custom error types for domain errors
- [ ] AC-4: Error handling tests added

### Technical Notes
- Use errors.Is/As for error checking
- See PROJECT_RULES.md → Error Handling section

### Issues Addressed
| ID | Description | Location |
|----|-------------|----------|
| CODE-002 | Unwrapped errors | 15 locations |
| CODE-007 | panic in business logic | src/service/order.go:78 |
| CODE-012 | No domain error types | src/domain/ |

---

## REFACTOR-003: Add missing test coverage
...

---

## REFACTOR-004: Containerization improvements
...
```

## Step 7: User Approval

Present the generated plan and ask for approval using AskUserQuestion tool:

```yaml
AskUserQuestion:
  questions:
    - question: "Review the refactoring plan. How do you want to proceed?"
      header: "Approval"
      multiSelect: false
      options:
        - label: "Approve all"
          description: "Save tasks.md, proceed to dev-cycle execution"
        - label: "Approve with changes"
          description: "Let user edit tasks.md first, then proceed"
        - label: "Critical only"
          description: "Filter to only Critical/High priority tasks"
        - label: "Cancel"
          description: "Abort execution, keep analysis report only"
```

## Step 8: Save Artifacts

Save analysis report and tasks to project:

```text
docs/refactor/{timestamp}/
├── analysis-report.md    # Full analysis with all findings
├── tasks.md              # Approved refactoring tasks
└── project-rules-used.md # Copy of PROJECT_RULES.md at time of analysis
```

**Note:** Ring standards are not saved as they are loaded dynamically by agents via WebFetch. Only the project-specific rules are preserved for reference.

## Step 9: Handoff to dev-cycle

If approved, the workflow continues:

```bash
# Automatic handoff
/ring-dev-team:dev-cycle docs/refactor/{timestamp}/tasks.md
```

This executes each refactoring task through the standard 6-gate process:
- Gate 0: Implementation (TDD)
- Gate 1: DevOps Setup
- Gate 2: SRE (Observability)
- Gate 3: Testing
- Gate 4: Review (3 parallel reviewers)
- Gate 5: Validation (user approval)

## Output Schema

```yaml
output_schema:
  format: "markdown"
  artifacts:
    - name: "analysis-report.md"
      location: "docs/refactor/{timestamp}/"
      required: true
    - name: "tasks.md"
      location: "docs/refactor/{timestamp}/"
      required: true
  required_sections:
    - name: "Summary"
      pattern: "^## Summary"
      required: true
    - name: "Critical Issues"
      pattern: "^## Critical Issues"
      required: true
    - name: "Tasks Generated"
      pattern: "^## REFACTOR-"
      required: true
```

## Example Usage

```bash
# Full project analysis
/ring-dev-team:dev-refactor

# Analyze specific directory
/ring-dev-team:dev-refactor src/domain

# Analyze with custom standards
/ring-dev-team:dev-refactor --standards path/to/PROJECT_RULES.md

# Analysis only (no execution)
/ring-dev-team:dev-refactor --analyze-only
```

## Related Skills

| Skill | Purpose |
|-------|---------|
| `ring-dev-team:dev-cycle` | Executes refactoring tasks through 6 gates (after approval) |

## Key Principles

1. **Same workflow**: Refactoring uses the same dev-cycle as new features
2. **Separation of concerns**: dev-refactor reads PROJECT_RULES.md locally; agents load Ring standards via WebFetch
3. **Standards-driven**: Analysis combines project-specific rules (PROJECT_RULES.md) + Ring standards (loaded by agents)
4. **Traceable**: Every task links back to specific issues found
5. **Incremental**: Can approve subset of tasks (critical only, etc.)
6. **Reversible**: Original analysis preserved for reference
