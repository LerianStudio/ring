---
description: Lightweight 3-gate pre-dev workflow for small features (<2 days)
argument-hint: "[feature-name]"
---

I'm running the **Small Track** pre-development workflow (3 gates) for your feature.

**This track is for features that:**
- ✅ Take <2 days to implement
- ✅ Use existing architecture patterns
- ✅ Don't add new external dependencies
- ✅ Don't create new data models/entities
- ✅ Don't require multi-service integration
- ✅ Can be completed by a single developer

**If any of the above are false, use `/pre-dev-full` instead.**

## Document Organization

All artifacts will be saved to: `docs/pre-dev/<feature-name>/`

**First, let me ask you about your feature:**

Use the AskUserQuestion tool to gather:

**Question 1:** "What is the name of your feature?"
- Header: "Feature Name"
- This will be used for the directory name
- Use kebab-case (e.g., "user-logout", "email-validation", "rate-limiting")

After getting the feature name, create the directory structure and run the 3-gate workflow:

```bash
mkdir -p docs/pre-dev/<feature-name>
```

## Gate 1: PRD Creation

**Skill:** ring:pre-dev-prd-creation

1. Ask user to describe the feature (what problem does it solve, who are the users, what's the business value)
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

## Gate 2: TRD Creation (Skipping Feature Map)

**Skill:** ring:pre-dev-trd-creation

1. Load PRD from `docs/pre-dev/<feature-name>/prd.md`
2. Note: No Feature Map exists (small track) - map PRD features directly to components
3. Create TRD document with:
   - Architecture style (pattern names, not products)
   - Component design (technology-agnostic)
   - Data architecture (conceptual)
   - Integration patterns
   - Security architecture
   - **NO specific tech products** (use "Relational Database" not "PostgreSQL")
4. Save to: `docs/pre-dev/<feature-name>/trd.md`
5. Run Gate 3 validation checklist
6. Get human approval before proceeding

**Gate 3 Pass Criteria:**
- [ ] All PRD features mapped to components
- [ ] Component boundaries are clear
- [ ] Interfaces are technology-agnostic
- [ ] No specific products named

## Gate 3: Task Breakdown (Skipping API/Data/Deps)

**Skill:** ring:pre-dev-task-breakdown

1. Load PRD from `docs/pre-dev/<feature-name>/prd.md`
2. Load TRD from `docs/pre-dev/<feature-name>/trd.md`
3. Note: No Feature Map, API Design, Data Model, or Dependency Map exist (small track)
4. Create task breakdown document with:
   - Value-driven decomposition
   - Each task delivers working software
   - Maximum task size: 2 weeks
   - Dependencies mapped
   - Testing strategy per task
5. Save to: `docs/pre-dev/<feature-name>/tasks.md`
6. Run Gate 7 validation checklist
7. Get human approval

**Gate 7 Pass Criteria:**
- [ ] Every task delivers user value
- [ ] No task larger than 2 weeks
- [ ] Dependencies are clear
- [ ] Testing approach defined

## After Completion

Report to human:

```
✅ Small Track (3 gates) complete for <feature-name>

Artifacts created:
- docs/pre-dev/<feature-name>/prd.md (Gate 1)
- docs/pre-dev/<feature-name>/trd.md (Gate 3)
- docs/pre-dev/<feature-name>/tasks.md (Gate 7)

Skipped gates (small track):
- Gate 2: Feature Map (features simple enough to map directly)
- Gate 4: API Design (no new APIs)
- Gate 5: Data Model (no new data structures)
- Gate 6: Dependency Map (no new dependencies)
- Gate 8: Subtask Creation (tasks small enough already)

Next steps:
1. Review artifacts in docs/pre-dev/<feature-name>/
2. Use /ring:worktree to create isolated workspace
3. Use /ring:write-plan to create implementation plan
4. Execute the plan
```

## Remember

- This is the **Small Track** - lightweight and fast
- If feature grows during planning, switch to `/pre-dev-full`
- All documents saved to `docs/pre-dev/<feature-name>/`
- Get human approval at each gate
- Technology decisions happen later in Dependency Map (not in this track)
