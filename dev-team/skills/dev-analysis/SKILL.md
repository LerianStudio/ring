---
name: dev-analysis
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

# Dev Analysis Skill

This skill analyzes an existing codebase to identify gaps between current implementation and project standards, then generates a structured refactoring plan compatible with the dev-cycle workflow.

## What This Skill Does

1. **Detects project language** (Go, TypeScript, Python) from manifest files
2. **Loads appropriate standards** from agent definitions (golang.md, typescript.md, etc.)
3. **Scans codebase** against standards in 4 dimensions: Architecture, Code, Testing, DevOps
4. **Identifies gaps** and prioritizes findings by impact and effort
5. **Generates tasks.md** in the same format as PM Team output
6. **User approves** the plan before execution via dev-cycle

## Prerequisites

Before starting analysis:

1. **Project root identified**: Know where the codebase lives
2. **Language detectable**: Project has go.mod, package.json, or similar manifest
3. **Scope defined**: Full project or specific directories

**Note:** Standards are auto-loaded from agent definitions based on detected language. Project-specific `docs/PROJECT_RULES.md` overrides defaults if present.

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

## Step 1: Detect Project Language

First, identify the primary language(s) of the project:

```text
Language Detection:
├── go.mod exists → Go project
│   └── Standards: backend-engineer-golang.md
│
├── package.json exists
│   ├── Has "react" or "next" dependency → Frontend TypeScript
│   │   └── Standards: frontend-engineer-typescript.md
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

## Step 2: Load Standards

Load standards from multiple sources based on detected language:

```text
Standards Loading Order:
1. Project-specific standards (if exist):
   - docs/PROJECT_RULES.md → Project conventions
   - docs/standards/{language}.md → Language overrides

2. Ring agent standards (embedded in agents):
   ┌─────────────────────────────────────────────────────────────┐
   │ Language/Domain    │ Agent with Standards                   │
   ├────────────────────┼────────────────────────────────────────┤
   │ Go                 │ dev-team/agents/backend-engineer-golang.md     │
   │ TypeScript Backend │ dev-team/agents/backend-engineer-typescript.md │
   │ Frontend JS/TS     │ dev-team/agents/frontend-engineer.md           │
   │ Frontend TS        │ dev-team/agents/frontend-engineer-typescript.md│
   │ DevOps/Infra       │ dev-team/agents/devops-engineer.md             │
   │ SRE/Observability  │ dev-team/agents/sre.md                         │
   │ Testing/QA         │ dev-team/agents/qa-analyst.md                  │
   └────────────────────┴────────────────────────────────────────┘

3. Merge strategy:
   - Project standards override agent defaults
   - Agent standards provide comprehensive baseline
   - Report which standards are being used

If no project standards AND language unknown:
→ Ask user: "Detected languages: {list}. Which standards should I use?"
→ Options: [Go, TypeScript Backend, TypeScript Frontend, DevOps, All]
```

## Step 3: Scan Codebase

Two-phase analysis using specialized agents:

### Phase 1: Architecture Analysis

**Dispatch:** `ring-default:codebase-explorer` (Opus)

```yaml
Task tool:
  subagent_type: "ring-default:codebase-explorer"
  model: "opus"
  prompt: |
    Analyze this {language} codebase against these standards: {standards_file}

    Focus on:
    - Directory structure compliance
    - DDD patterns (Entities, Value Objects, Aggregates, Repositories)
    - Clean/Hexagonal Architecture (dependency direction)
    - Anti-patterns and technical debt
    - Naming conventions
```

**Output:** Architectural insights, patterns found, anti-patterns detected.

### Phase 2: Specialized Dimension Analysis (Parallel)

Dispatch 3 agents in parallel (single message, 3 Task tool calls) to analyze specific dimensions:

```yaml
# Task 1: Testing Analysis
Task tool:
  subagent_type: "ring-dev-team:qa-analyst"
  model: "opus"
  prompt: |
    Analyze test coverage and patterns:
    - Test coverage percentage
    - Test patterns (table-driven, AAA)
    - TDD compliance
    - Missing test cases

# Task 2: DevOps Analysis
Task tool:
  subagent_type: "ring-dev-team:devops-engineer"
  model: "opus"
  prompt: |
    Analyze infrastructure setup:
    - Dockerfile exists and follows best practices
    - docker-compose.yml configuration
    - CI/CD pipeline presence
    - Environment management (.env.example)

# Task 3: SRE Analysis
Task tool:
  subagent_type: "ring-dev-team:sre"
  model: "opus"
  prompt: |
    Analyze observability setup:
    - Metrics endpoint (/metrics)
    - Health check endpoints (/health, /ready)
    - Structured logging
    - Tracing setup
```

**Output:** Dimension-specific findings to merge with exploration_results.

## Step 4: Compile Findings

Merge results from all agents into a structured report:

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
└── original-standards.md # Snapshot of standards used
```

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
2. **Standards-driven**: All analysis is based on project PROJECT_RULES.md
3. **Traceable**: Every task links back to specific issues found
4. **Incremental**: Can approve subset of tasks (critical only, etc.)
5. **Reversible**: Original analysis preserved for reference
