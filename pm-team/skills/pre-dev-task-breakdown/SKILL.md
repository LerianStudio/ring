---
name: pre-dev-task-breakdown
description: |
  Gate 7: Implementation tasks - value-driven decomposition into working increments
  that deliver measurable user value.

trigger: |
  - PRD passed Gate 1 (required)
  - TRD passed Gate 3 (required)
  - All Large Track gates passed (if applicable)
  - Ready to create sprint/iteration tasks

skip_when: |
  - PRD or TRD not validated → complete earlier gates
  - Tasks already exist → proceed to Subtask Creation
  - Trivial change → direct implementation

sequence:
  after: [pre-dev-trd-creation, pre-dev-dependency-map]
  before: [pre-dev-subtask-creation, executing-plans]
---

# Task Breakdown - Value-Driven Decomposition

## Foundational Principle

**Every task must deliver working software that provides measurable user value.**

Creating technical-only or oversized tasks creates:
- Work that doesn't ship until "everything is done"
- Teams working on pieces that don't integrate
- No early validation of value or technical approach
- Waterfall development disguised as iterative process

**Tasks answer**: What working increment will be delivered?
**Tasks never answer**: How to implement that increment (that's Subtasks).

## When to Use This Skill

Use this skill when:
- PRD has passed Gate 1 validation (REQUIRED)
- TRD has passed Gate 3 validation (REQUIRED)
- Feature Map has passed Gate 2 validation (OPTIONAL - use if exists)
- API Design has passed Gate 4 validation (OPTIONAL - use if exists)
- Data Model has passed Gate 5 validation (OPTIONAL - use if exists)
- Dependency Map has passed Gate 6 validation (OPTIONAL - use if exists)
- About to break down work for sprints/iterations
- Tempted to create "Setup Infrastructure" as a task
- Asked to estimate or plan implementation work
- Before creating subtasks

## Mandatory Workflow

### Phase 1: Task Identification (Inputs Required)

**Required Inputs:**
1. **Approved PRD** (Gate 1 passed) - business requirements and priorities (REQUIRED - check `docs/pre-dev/<feature-name>/prd.md`)
2. **Approved TRD** (Gate 3 passed) - architecture patterns documented (REQUIRED - check `docs/pre-dev/<feature-name>/trd.md`)

**Optional Inputs (use if exists for richer context):**
3. **Approved Feature Map** (Gate 2 passed) - feature relationships mapped (check `docs/pre-dev/<feature-name>/feature-map.md`)
4. **Approved API Design** (Gate 4 passed) - contracts specified (check `docs/pre-dev/<feature-name>/api-design.md`)
5. **Approved Data Model** (Gate 5 passed) - data structures defined (check `docs/pre-dev/<feature-name>/data-model.md`)
6. **Approved Dependency Map** (Gate 6 passed) - tech stack locked (check `docs/pre-dev/<feature-name>/dependency-map.md`)

**Analysis:**
7. **Identify value streams** - what delivers user value first?

### Phase 2: Decomposition
For each TRD component or PRD feature:
1. **Define deliverable** - what working software ships?
2. **Set success criteria** - how do we know it's done?
3. **Map dependencies** - what must exist first?
4. **Estimate effort** - T-shirt size (S/M/L/XL, max is XL = 2 weeks)
5. **Plan testing** - how will we verify it works?
6. **Identify risks** - what could go wrong?

### Phase 3: Gate 7 Validation
**MANDATORY CHECKPOINT** - Must pass before proceeding to Subtasks:
- [ ] All TRD components covered by tasks
- [ ] Every task delivers working software
- [ ] Each task has measurable success criteria
- [ ] Dependencies are correctly mapped
- [ ] No task exceeds 2 weeks effort (XL max)
- [ ] Testing strategy defined for each task
- [ ] Risks identified with mitigations
- [ ] Delivery sequence optimizes value

## Explicit Rules

### ✅ DO Include in Tasks
- Task ID, title, type (Foundation/Feature/Integration/Polish)
- Deliverable: What working software ships?
- User value: What can users do after this?
- Technical value: What does this enable?
- Success criteria (testable, measurable)
- Dependencies (blocks/requires/optional)
- Effort estimate (S/M/L/XL with points)
- Testing strategy (unit/integration/e2e)
- Risk identification with mitigations
- Definition of Done checklist

### ❌ NEVER Include in Tasks
- Implementation details (file paths, code examples)
- Step-by-step instructions (those go in subtasks)
- Technical-only tasks with no user value
- Tasks exceeding 2 weeks effort (break them down)
- Vague success criteria ("improve performance")
- Missing dependency information
- Undefined testing approach

### Task Sizing Rules
1. **Small (S)**: 1-3 points, 1-3 days, single component
2. **Medium (M)**: 5-8 points, 3-5 days, few dependencies
3. **Large (L)**: 13 points, 1-2 weeks, multiple components
4. **XL (over 2 weeks)**: BREAK IT DOWN - too large to be atomic

### Value Delivery Rules
1. **Foundation tasks** enable other work (database setup, core services)
2. **Feature tasks** deliver user-facing capabilities
3. **Integration tasks** connect to external systems
4. **Polish tasks** optimize or enhance (nice-to-have)

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "This 3-week task is fine" | Tasks >2 weeks hide complexity. Break it down. |
| "Setup tasks don't need value" | Setup enables value. Define what it enables. |
| "Success criteria are obvious" | Obvious to you ≠ testable. Document explicitly. |
| "Dependencies will be clear later" | Later is too late. Map them now. |
| "We don't need detailed estimates" | Without estimates, no planning possible. Size them. |
| "Technical tasks can skip user value" | Even infrastructure enables users. Define the connection. |
| "Testing strategy can be decided during" | Testing affects design. Plan it upfront. |
| "Risks aren't relevant at task level" | Risks compound across tasks. Identify them early. |
| "DoD is the same for all tasks" | Different tasks need different criteria. Specify. |
| "We can combine multiple features" | Combining hides value delivery. Keep tasks focused. |

## Red Flags - STOP

If you catch yourself writing any of these in a task, **STOP**:

- Task estimates over 2 weeks
- Tasks named "Setup X" without defining what X enables
- Success criteria like "works" or "complete" (not measurable)
- No dependencies listed (every task depends on something)
- No testing strategy (how will you verify?)
- "Technical debt" as a task type (debt reduction must deliver value)
- Vague deliverables ("improve", "optimize", "refactor")
- Missing Definition of Done

**When you catch yourself**: Refine the task until it's concrete, valuable, and testable.

## Gate 7 Validation Checklist

Before proceeding to Subtasks, verify:

**Task Completeness**:
- [ ] All TRD components have tasks covering them
- [ ] All PRD features have tasks delivering them
- [ ] Each task is appropriately sized (no XL+)
- [ ] Task boundaries are clear and logical

**Delivery Value**:
- [ ] Every task delivers working software
- [ ] User value is explicit (even for foundation)
- [ ] Technical value is clear (what it enables)
- [ ] Sequence optimizes value delivery

**Technical Clarity**:
- [ ] Success criteria are measurable and testable
- [ ] Dependencies are correctly mapped (blocks/requires)
- [ ] Testing approach is defined (unit/integration/e2e)
- [ ] Definition of Done is comprehensive

**Team Readiness**:
- [ ] Skills required match team capabilities
- [ ] Effort estimates are realistic (validated by similar past work)
- [ ] Capacity is available or planned
- [ ] Handoffs are minimized

**Risk Management**:
- [ ] Risks identified for each task
- [ ] Mitigations are defined
- [ ] High-risk tasks scheduled early
- [ ] Fallback plans exist

**Gate Result**:
- ✅ **PASS**: All checkboxes checked → Proceed to Subtasks (`pre-dev-subtask-creation`)
- ⚠️ **CONDITIONAL**: Refine oversized/vague tasks → Re-validate
- ❌ **FAIL**: Too many issues → Re-decompose

## Common Violations and Fixes

### Violation 1: Technical-Only Tasks
❌ **Wrong**:
```markdown
## T-001: Setup PostgreSQL Database
- Install PostgreSQL 16
- Configure connection pooling
- Create initial schema
```

✅ **Correct**:
```markdown
## T-001: User Data Persistence Foundation

### Deliverable
Working database layer that persists user accounts and supports authentication queries with <100ms latency.

### User Value
Enables user registration and login (T-002, T-003 depend on this).

### Technical Value
- Foundation for all data persistence
- Multi-tenant isolation strategy implemented
- Performance baseline established

### Success Criteria
- [ ] Users table created with multi-tenant schema
- [ ] Connection pooling configured (min 5, max 50 connections)
- [ ] Query performance <100ms for auth queries (verified with test data)
- [ ] Migrations framework operational
- [ ] Rollback procedures tested

### Dependencies
- **Blocks**: T-002 (Registration), T-003 (Login), T-004 (Permissions)
- **Requires**: Infrastructure (networking, compute)
- **Optional**: None

### Effort: Medium (M) - 5 points, 3-5 days
### Testing: Integration tests for queries, performance benchmarks
```

### Violation 2: Oversized Tasks
❌ **Wrong**:
```markdown
## T-005: Complete User Management System
- Registration, login, logout
- Profile management
- Password reset
- Email verification
- Two-factor authentication
- Session management
- Permissions system

Estimate: 6 weeks
```

✅ **Correct** (broken into multiple tasks):
```markdown
## T-005: Basic Authentication (Register + Login)
- Deliverable: Users can create accounts and log in with JWT tokens
- User Value: Access to personalized features
- Effort: Large (L) - 13 points, 1-2 weeks
- Dependencies: Requires T-001 (Database)

## T-006: Password Management (Reset + Email)
- Deliverable: Users can reset forgotten passwords via email
- User Value: Account recovery without support tickets
- Effort: Medium (M) - 8 points, 3-5 days
- Dependencies: Requires T-005, Email service configured

## T-007: Two-Factor Authentication
- Deliverable: Users can enable 2FA with TOTP
- User Value: Enhanced account security
- Effort: Medium (M) - 8 points, 3-5 days
- Dependencies: Requires T-005

## T-008: Permissions System
- Deliverable: Role-based access control operational
- User Value: Admin can assign roles, users have appropriate access
- Effort: Large (L) - 13 points, 1-2 weeks
- Dependencies: Requires T-005
```

### Violation 3: Vague Success Criteria
❌ **Wrong**:
```markdown
Success Criteria:
- [ ] Feature works
- [ ] Tests pass
- [ ] Code reviewed
```

✅ **Correct**:
```markdown
Success Criteria:
Functional:
- [ ] Users can upload files up to 100MB
- [ ] Supported formats: JPEG, PNG, PDF, DOCX
- [ ] Files stored with unique IDs, retrievable via API
- [ ] Upload progress shown to user

Technical:
- [ ] API response time <2s for uploads <10MB
- [ ] Files encrypted at rest with KMS
- [ ] Virus scanning completes before storage

Operational:
- [ ] Monitoring: Upload success rate >99.5%
- [ ] Logging: All upload attempts logged with user_id
- [ ] Alerts: Notify if success rate drops below 95%

Quality:
- [ ] Unit tests: 90%+ coverage for upload logic
- [ ] Integration tests: End-to-end upload scenarios
- [ ] Security: OWASP file upload best practices followed
```

## Task Template

Use this template for every task:

```markdown
## T-[XXX]: [Task Title - What It Delivers]

### Deliverable
[One sentence: What working software ships?]

### Scope
**Includes**:
- [Specific capability 1]
- [Specific capability 2]
- [Specific capability 3]

**Excludes** (future tasks):
- [Out of scope item 1] (T-YYY)
- [Out of scope item 2] (T-ZZZ)

### Success Criteria
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]
- [ ] [Testable criterion 3]

### User Value
[What can users do after this that they couldn't before?]

### Technical Value
[What does this enable? What other tasks does this unblock?]

### Technical Components
From TRD:
- [Component 1]
- [Component 2]

From Dependencies:
- [Package/service 1]
- [Package/service 2]

### Dependencies
- **Blocks**: [Tasks that need this] (T-AAA, T-BBB)
- **Requires**: [Tasks that must complete first] (T-CCC)
- **Optional**: [Nice-to-haves] (T-DDD)

### Effort Estimate
- **Size**: [S/M/L/XL]
- **Points**: [1-3 / 5-8 / 13 / 21]
- **Duration**: [1-3 days / 3-5 days / 1-2 weeks]
- **Team**: [Backend / Frontend / Full-stack / etc.]

### Risks
**Risk 1: [Description]**
- Impact: [High/Medium/Low]
- Probability: [High/Medium/Low]
- Mitigation: [How we'll address it]
- Fallback: [Plan B if mitigation fails]

### Testing Strategy
- **Unit Tests**: [What logic to test]
- **Integration Tests**: [What APIs/components to test together]
- **E2E Tests**: [What user flows to test]
- **Performance Tests**: [What to benchmark]
- **Security Tests**: [What threats to validate against]

### Definition of Done
- [ ] Code complete and peer reviewed
- [ ] All tests passing (unit + integration + e2e)
- [ ] Documentation updated (API docs, README, etc.)
- [ ] Security scan clean (no high/critical issues)
- [ ] Performance targets met (benchmarks run)
- [ ] Deployed to staging environment
- [ ] Product owner acceptance received
- [ ] Monitoring/logging configured
```

## Delivery Sequencing

Optimize task order for value:

```yaml
Sprint 1 - Foundation:
  Goal: Enable core workflows
  Tasks:
    - T-001: Database foundation (blocks all)
    - T-002: Auth foundation (start, high value)

Sprint 2 - Core Features:
  Goal: Ship minimum viable feature
  Tasks:
    - T-002: Auth foundation (complete)
    - T-005: User dashboard (depends on T-002)
    - T-010: Basic API endpoints (high value)

Sprint 3 - Enhancements:
  Goal: Polish and extend
  Tasks:
    - T-006: Password reset (medium value)
    - T-011: Advanced search (nice-to-have)
    - T-015: Performance optimization (polish)

Critical Path: T-001 → T-002 → T-005 → T-010
Parallel Work: After T-001, T-003 and T-004 can run parallel to T-002
```

## Anti-Patterns to Avoid

❌ **Technical Debt Tasks**: "Refactor authentication" (no user value)
❌ **Giant Tasks**: 3+ week efforts (break them down)
❌ **Vague Tasks**: "Improve performance" (not measurable)
❌ **Sequential Bottlenecks**: Everything depends on one task
❌ **Missing Value**: Tasks that don't ship working software

✅ **Good Task Names**:
- "Users can register and log in with email" (clear value)
- "API responds in <500ms for 95th percentile" (measurable)
- "Admin dashboard shows real-time metrics" (working software)

## Confidence Scoring

Use this to adjust your interaction with the user:

```yaml
Confidence Factors:
  Task Decomposition: [0-30]
    - All tasks appropriately sized: 30
    - Most tasks well-scoped: 20
    - Tasks too large or vague: 10

  Value Clarity: [0-25]
    - Every task delivers working software: 25
    - Most tasks have clear value: 15
    - Value connections unclear: 5

  Dependency Mapping: [0-25]
    - All dependencies documented: 25
    - Most dependencies clear: 15
    - Dependencies ambiguous: 5

  Estimation Quality: [0-20]
    - Estimates based on past work: 20
    - Reasonable educated guesses: 12
    - Wild speculation: 5

Total: [0-100]

Action:
  80+: Generate complete task breakdown autonomously
  50-79: Present sizing options and sequences
  <50: Ask about team velocity and complexity
```

## Output Location

**Always output to**: `docs/pre-development/tasks/tasks-[feature-name].md`

## After Task Breakdown Approval

1. ✅ Tasks become sprint backlog
2. 🎯 Use tasks as input for atomic subtasks (next phase: `pre-dev-subtask-creation`)
3. 📊 Track progress per task (not per subtask)
4. 🚫 No implementation yet - that's in subtasks

## Quality Self-Check

Before declaring task breakdown complete, verify:
- [ ] Every task delivers working software (not just "progress")
- [ ] All tasks have measurable success criteria
- [ ] Dependencies are mapped (blocks/requires/optional)
- [ ] Effort estimates are realistic (S/M/L/XL, no >2 weeks)
- [ ] Testing strategy defined for each task
- [ ] Risks identified with mitigations
- [ ] Definition of Done is comprehensive for each
- [ ] Delivery sequence optimizes value (high-value tasks early)
- [ ] No technical-only tasks without user connection
- [ ] Gate 7 validation checklist 100% complete

## The Bottom Line

**If you created tasks that don't deliver working software, rewrite them.**

Tasks are not technical activities. Tasks are working increments.

"Setup database" is not a task. "User data persists correctly" is a task.
"Implement OAuth" is not a task. "Users can log in with Google" is a task.
"Write tests" is not a task. Tests are part of Definition of Done for other tasks.

Every task must answer: **"What working software can I demo to users?"**

If you can't demo it, it's not a task. It's subtask implementation detail.

**Deliver value. Ship working software. Make tasks demoable.**
