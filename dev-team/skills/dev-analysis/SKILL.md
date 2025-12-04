---
name: dev-analysis
description: |
  Analyzes existing codebase against project STANDARDS.md to identify gaps in architecture,
  code quality, testing, and DevOps. Generates a refactoring tasks.md file compatible with dev-cycle.

trigger: |
  - User wants to refactor existing project to follow standards
  - User runs /ring-dev-team:dev-refactor command
  - Legacy codebase needs modernization
  - Project audit requested

skip_when: |
  - Greenfield project → Use /ring-pm-team:pre-dev-* instead
  - Single file fix → Use dev-cycle directly
  - No STANDARDS.md exists → Create standards first

sequence:
  before: [dev-cycle]

related:
  similar: [ring-pm-team:pre-dev-research]
  complementary: [dev-cycle, dev-implementation]
---

# Dev Analysis Skill

This skill analyzes an existing codebase to identify gaps between current implementation and project standards, then generates a structured refactoring plan compatible with the dev-cycle workflow.

## What This Skill Does

1. **Scans codebase** against `docs/STANDARDS.md` (or `dev-team/docs/STANDARDS.md` as reference)
2. **Identifies gaps** in 4 dimensions: Architecture, Code, Testing, DevOps
3. **Prioritizes findings** by impact and effort
4. **Generates tasks.md** in the same format as PM Team output
5. **User approves** the plan before execution via dev-cycle

## Prerequisites

Before starting analysis:

1. **Project root identified**: Know where the codebase lives
2. **Standards available**: Either project has `docs/STANDARDS.md` or will use dev-team defaults
3. **Scope defined**: Full project or specific directories

## Analysis Dimensions

### 1. Architecture Analysis

```
Checks:
├── DDD Patterns (if enabled in STANDARDS.md)
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
    ├── Matches STANDARDS.md layout
    ├── Separation of concerns
    └── No circular dependencies
```

### 2. Code Quality Analysis

```
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

```
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

```
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

## Step 1: Load Standards

First, identify which standards to use:

```
Check order:
1. Project's docs/STANDARDS.md → Use if exists
2. Project's docs/standards/{language}.md → Use for language-specific
3. Fall back to dev-team/docs/STANDARDS.md → Use as reference template

If no standards exist:
→ STOP
→ Ask user: "No STANDARDS.md found. Create one first?"
→ Offer to copy template from dev-team/docs/STANDARDS.md
```

## Step 2: Scan Codebase

Dispatch parallel agents to analyze each dimension:

```
Task tool (parallel):

┌─────────────────────┬─────────────────────┬─────────────────────┬─────────────────────┐
│ Architecture Agent  │ Code Quality Agent  │ Testing Agent       │ DevOps Agent        │
│                     │                     │                     │                     │
│ subagent: Explore   │ subagent: Explore   │ subagent: Explore   │ subagent: Explore   │
│                     │                     │                     │                     │
│ Analyze:            │ Analyze:            │ Analyze:            │ Analyze:            │
│ - Directory layout  │ - Naming patterns   │ - Test coverage     │ - Dockerfile        │
│ - DDD patterns      │ - Error handling    │ - Test patterns     │ - docker-compose    │
│ - Dependencies      │ - Forbidden code    │ - Test naming       │ - CI/CD config      │
│ - Layer separation  │ - Security issues   │ - Missing tests     │ - Env management    │
└─────────────────────┴─────────────────────┴─────────────────────┴─────────────────────┘
```

## Step 3: Compile Findings

Merge results from all agents into a structured report:

```markdown
# Analysis Report: {project-name}

**Generated:** {date}
**Standards:** {path to STANDARDS.md used}
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

## Step 4: Prioritize and Group

Group related issues into logical refactoring tasks:

```
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

## Step 5: Generate tasks.md

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
- Pattern: See STANDARDS.md → Hexagonal Architecture section
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
- See STANDARDS.md → Error Handling section

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

## Step 6: User Approval

Present the generated plan and ask for approval:

```
AskUserQuestion:
  question: "Review the refactoring plan. How do you want to proceed?"
  options:
    - "Approve all" → Save tasks.md, proceed to dev-cycle
    - "Approve with changes" → Let user edit tasks.md, then proceed
    - "Critical only" → Filter to only Critical/High priority tasks
    - "Cancel" → Abort, keep analysis report only
```

## Step 7: Save Artifacts

Save analysis report and tasks to project:

```
docs/refactor/{timestamp}/
├── analysis-report.md    # Full analysis with all findings
├── tasks.md              # Approved refactoring tasks
└── original-standards.md # Snapshot of standards used
```

## Step 8: Handoff to dev-cycle

If approved, the workflow continues:

```bash
# Automatic handoff
/ring-dev-team:dev-cycle docs/refactor/{timestamp}/tasks.md
```

This executes each refactoring task through the standard 5-gate process:
- Gate 0: Implementation (TDD)
- Gate 1: DevOps Setup
- Gate 2: Testing
- Gate 3: Review (3 parallel reviewers)
- Gate 4: Validation (user approval)

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
/ring-dev-team:dev-refactor --standards path/to/STANDARDS.md

# Analysis only (no execution)
/ring-dev-team:dev-refactor --analyze-only
```

## Integration with dev-cycle

```
┌─────────────────────────────────────────────────────────────┐
│                 /ring-dev-team:dev-refactor                     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      dev-analysis                           │
│                                                             │
│  1. Load STANDARDS.md                                       │
│  2. Scan codebase (4 parallel agents)                       │
│  3. Compile findings                                        │
│  4. Prioritize and group                                    │
│  5. Generate tasks.md                                       │
│  6. User approval                                           │
│  7. Save artifacts                                          │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼ (if approved)
┌─────────────────────────────────────────────────────────────┐
│              /ring-dev-team:dev-cycle                       │
│              docs/refactor/{timestamp}/tasks.md             │
│                                                             │
│  For each REFACTOR-XXX task:                                │
│    Gate 0: Implementation (TDD)                             │
│    Gate 1: DevOps Setup                                     │
│    Gate 2: Testing                                          │
│    Gate 3: Review (3 reviewers)                             │
│    Gate 4: Validation                                       │
└─────────────────────────────────────────────────────────────┘
```

## Key Principles

1. **Same workflow**: Refactoring uses the same dev-cycle as new features
2. **Standards-driven**: All analysis is based on project STANDARDS.md
3. **Traceable**: Every task links back to specific issues found
4. **Incremental**: Can approve subset of tasks (critical only, etc.)
5. **Reversible**: Original analysis preserved for reference
