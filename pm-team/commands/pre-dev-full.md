---
name: pre-dev-full
description: Complete 9-gate pre-dev workflow for large features (≥2 days)
argument-hint: "[feature-name]"
---

I'm running the **Full Track** pre-development workflow (9 gates) for your feature.

**This track is for features that have ANY of:**
- ❌ Take ≥2 days to implement
- ❌ Add new external dependencies (APIs, databases, libraries)
- ❌ Create new data models or entities
- ❌ Require multi-service integration
- ❌ Use new architecture patterns
- ❌ Require team collaboration

**If feature is simple (<2 days, existing patterns), use `/pre-dev-feature` instead.**

## Document Organization

All artifacts will be saved to: `docs/pre-dev/<feature-name>/`

**First, let me ask you about your feature:**

Use the AskUserQuestion tool to gather:

**Question 1:** "What is the name of your feature?"
- Header: "Feature Name"
- This will be used for the directory name
- Use kebab-case (e.g., "auth-system", "payment-processing", "file-upload")

After getting the feature name, create the directory structure and run the 9-gate workflow:

```bash
mkdir -p docs/pre-dev/<feature-name>
```

## Gate 0: Research Phase (NEW)

**Skill:** ring-pm-team:pre-dev-research

1. Determine research mode by asking user or inferring from context:
   - **greenfield**: New capability, no existing patterns
   - **modification**: Extending existing functionality
   - **integration**: Connecting external systems

2. Dispatch 3 research agents in PARALLEL:
   - ring-pm-team:repo-research-analyst (codebase patterns, file:line refs)
   - ring-pm-team:best-practices-researcher (web search, Context7)
   - ring-pm-team:framework-docs-researcher (tech stack, versions)

3. Aggregate findings into research document
4. Save to: `docs/pre-dev/<feature-name>/research.md`
5. Run Gate 0 validation checklist
6. Get human approval before proceeding

**Gate 0 Pass Criteria:**
- [ ] Research mode determined and documented
- [ ] All 3 agents dispatched and returned
- [ ] At least one file:line reference (if modification mode)
- [ ] At least one external URL (if greenfield mode)
- [ ] docs/solutions/ knowledge base searched
- [ ] Tech stack versions documented

## Gate 1: PRD Creation

**Skill:** ring-pm-team:pre-dev-prd-creation

1. Ask user to describe the feature (problem, users, business value)
2. Create PRD document with:
   - Problem statement
   - User stories
   - Acceptance criteria
   - Success metrics
   - Out of scope
3. Save to: `docs/pre-dev/<feature-name>/prd.md`
4. Run Gate 1 validation checklist
5. Get human approval before proceeding

**Gate 1 Pass Criteria:**
- [ ] Problem is clearly defined
- [ ] User value is measurable
- [ ] Acceptance criteria are testable
- [ ] Scope is explicitly bounded

## Gate 2: Feature Map Creation

**Skill:** ring-pm-team:pre-dev-feature-map

1. Load PRD from `docs/pre-dev/<feature-name>/prd.md`
2. Create feature map document with:
   - Feature relationships and dependencies
   - Domain boundaries
   - Integration points
   - Scope visualization
3. Save to: `docs/pre-dev/<feature-name>/feature-map.md`
4. Run Gate 2 validation checklist
5. Get human approval before proceeding

**Gate 2 Pass Criteria:**
- [ ] All features from PRD mapped
- [ ] Relationships are clear
- [ ] Domain boundaries defined
- [ ] Feature interactions documented

## Gate 3: TRD Creation

**Skill:** ring-pm-team:pre-dev-trd-creation

1. Load PRD from `docs/pre-dev/<feature-name>/prd.md`
2. Load Feature Map from `docs/pre-dev/<feature-name>/feature-map.md`
3. Map Feature Map domains to architectural components
4. Create TRD document with:
   - Architecture style (pattern names, not products)
   - Component design (technology-agnostic)
   - Data architecture (conceptual)
   - Integration patterns
   - Security architecture
   - **NO specific tech products**
5. Save to: `docs/pre-dev/<feature-name>/trd.md`
6. Run Gate 3 validation checklist
7. Get human approval before proceeding

**Gate 3 Pass Criteria:**
- [ ] All Feature Map domains mapped to components
- [ ] All PRD features mapped to components
- [ ] Component boundaries are clear
- [ ] Interfaces are technology-agnostic
- [ ] No specific products named

## Gate 4: API Design

**Skill:** ring-pm-team:pre-dev-api-design

1. Load previous artifacts (PRD, Feature Map, TRD)
2. Create API design document with:
   - Component contracts and interfaces
   - Request/response formats
   - Error handling patterns
   - Integration specifications
3. Save to: `docs/pre-dev/<feature-name>/api-design.md`
4. Run Gate 4 validation checklist
5. Get human approval before proceeding

**Gate 4 Pass Criteria:**
- [ ] All component interfaces defined
- [ ] Contracts are clear and complete
- [ ] Error cases covered
- [ ] Protocol-agnostic (no REST/gRPC specifics yet)

## Gate 5: Data Model

**Skill:** ring-pm-team:pre-dev-data-model

1. Load previous artifacts
2. Create data model document with:
   - Entity relationships and schemas
   - Data ownership boundaries
   - Access patterns
   - Migration strategy
3. Save to: `docs/pre-dev/<feature-name>/data-model.md`
4. Run Gate 5 validation checklist
5. Get human approval before proceeding

**Gate 5 Pass Criteria:**
- [ ] All entities defined with relationships
- [ ] Data ownership is clear
- [ ] Access patterns documented
- [ ] Database-agnostic (no PostgreSQL/MongoDB specifics yet)

## Gate 6: Dependency Map

**Skill:** ring-pm-team:pre-dev-dependency-map

1. Load previous artifacts
2. Create dependency map document with:
   - **NOW we select specific technologies**
   - Concrete versions and packages
   - Rationale for each choice
   - Alternative evaluations
3. Save to: `docs/pre-dev/<feature-name>/dependency-map.md`
4. Run Gate 6 validation checklist
5. Get human approval before proceeding

**Gate 6 Pass Criteria:**
- [ ] All technologies selected with rationale
- [ ] Versions pinned (no "latest")
- [ ] Alternatives evaluated
- [ ] Tech stack is complete

## Gate 7: Task Breakdown

**Skill:** ring-pm-team:pre-dev-task-breakdown

1. Load all previous artifacts (PRD, Feature Map, TRD, API Design, Data Model, Dependency Map)
2. Create task breakdown document with:
   - Value-driven decomposition
   - Each task delivers working software
   - Maximum task size: 2 weeks
   - Dependencies mapped
   - Testing strategy per task
3. Save to: `docs/pre-dev/<feature-name>/tasks.md`
4. Run Gate 7 validation checklist
5. Get human approval before proceeding

**Gate 7 Pass Criteria:**
- [ ] Every task delivers user value
- [ ] No task larger than 2 weeks
- [ ] Dependencies are clear
- [ ] Testing approach defined

## Gate 8: Subtask Creation

**Skill:** ring-pm-team:pre-dev-subtask-creation

1. Load tasks from `docs/pre-dev/<feature-name>/tasks.md`
2. Create subtask breakdown document with:
   - Bite-sized steps (2-5 minutes each)
   - TDD-based implementation steps
   - Complete code (no placeholders)
   - Zero-context executable
3. Save to: `docs/pre-dev/<feature-name>/subtasks.md`
4. Run Gate 8 validation checklist
5. Get human approval

**Gate 8 Pass Criteria:**
- [ ] Every subtask is 2-5 minutes
- [ ] TDD cycle enforced (test first)
- [ ] Complete code provided
- [ ] Zero-context test passes

## After Completion

Report to human:

```
✅ Full Track (9 gates) complete for <feature-name>

Artifacts created:
- docs/pre-dev/<feature-name>/research.md (Gate 0) ← NEW
- docs/pre-dev/<feature-name>/prd.md (Gate 1)
- docs/pre-dev/<feature-name>/feature-map.md (Gate 2)
- docs/pre-dev/<feature-name>/trd.md (Gate 3)
- docs/pre-dev/<feature-name>/api-design.md (Gate 4)
- docs/pre-dev/<feature-name>/data-model.md (Gate 5)
- docs/pre-dev/<feature-name>/dependency-map.md (Gate 6)
- docs/pre-dev/<feature-name>/tasks.md (Gate 7)
- docs/pre-dev/<feature-name>/subtasks.md (Gate 8)

Planning time: 2-4 hours (comprehensive)

Next steps:
1. Review artifacts in docs/pre-dev/<feature-name>/
2. Use /worktree to create isolated workspace
3. Use /write-plan to create implementation plan
4. Execute the plan
```

## Remember

- This is the **Full Track** - comprehensive and thorough
- All 9 gates provide maximum planning depth
- **Gate 0 (Research) runs 3 agents in parallel** for codebase, best practices, and framework docs
- Technology decisions happen at Gate 6 (Dependency Map)
- All documents saved to `docs/pre-dev/<feature-name>/`
- Get human approval at each gate before proceeding
- Planning investment (2-4 hours) pays off during implementation
