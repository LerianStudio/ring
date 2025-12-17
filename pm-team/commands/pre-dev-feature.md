---
name: pre-dev-feature
description: Lightweight 4-gate pre-dev workflow for small features (<2 days)
argument-hint: "[feature-name]"
---

I'm running the **Small Track** pre-development workflow (4 gates) for your feature.

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

**Question 2 (CONDITIONAL):** "Does this feature require authentication or authorization?"
- **Auto-detection:** Before asking, check if `go.mod` contains `github.com/LerianStudio/lib-auth`
  - If **found** → Skip this question. Auth is already integrated at project level.
  - If **not found** → Ask this question (new project or project without auth)
- Header: "Auth Requirements"
- Options:
  - "None" - No authentication needed
  - "User authentication only" - Users must log in but no permission checks
  - "User + permissions" - Full user auth with role-based access control
  - "Service-to-service auth" - Machine-to-machine authentication only
  - "Full (user + service-to-service)" - Both user and service auth
- **Note:** For Go services requiring auth, reference `golang.md` → Access Manager Integration section during TRD creation (Gate 2)

**Question 3 (CONDITIONAL):** "Is this a licensed product/plugin?"
- **Auto-detection:** Before asking, check if `go.mod` contains `github.com/LerianStudio/lib-license-go`
  - If **found** → Skip this question. Licensing is already integrated at project level.
  - If **not found** → Ask this question (new project or project without licensing)
- Header: "License Requirements"
- Options:
  - "No" - Not a licensed product (open source, internal tool, etc.)
  - "Yes" - Licensed product that requires License Manager integration
- **Note:** For Go services requiring license validation, reference `golang.md` → License Manager Integration section during TRD creation (Gate 2)

**Why auto-detection?** Access Manager and License Manager are project-level infrastructure decisions, not feature-level. Once integrated, all features in the project inherit them.

After getting the feature name (and auth/license requirements if applicable), create the directory structure and run the 4-gate workflow:

```bash
mkdir -p docs/pre-dev/<feature-name>
```

## Gate 0: Research Phase (Lightweight)

**Skill:** pre-dev-research

Even small features benefit from quick research:

1. Determine research mode (usually **modification** for small features)
2. Dispatch 3 research agents in PARALLEL (quick mode)
3. Save to: `docs/pre-dev/<feature-name>/research.md`
4. Get human approval before proceeding

**Gate 0 Pass Criteria (Small Track):**
- [ ] Research mode determined
- [ ] Existing patterns identified (if any)
- [ ] No conflicting implementations found

**Note:** For very simple changes, Gate 0 can be abbreviated - focus on checking for existing patterns.

## Gate 1: PRD Creation

**Skill:** pre-dev-prd-creation

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

**Skill:** pre-dev-trd-creation

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
5. Run Gate 2 validation checklist
6. Get human approval before proceeding

**Gate 2 Pass Criteria:**
- [ ] All PRD features mapped to components
- [ ] Component boundaries are clear
- [ ] Interfaces are technology-agnostic
- [ ] No specific products named

## Gate 3: Task Breakdown (Skipping API/Data/Deps)

**Skill:** pre-dev-task-breakdown

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
6. Run Gate 3 validation checklist
7. Get human approval

**Gate 3 Pass Criteria:**
- [ ] Every task delivers user value
- [ ] No task larger than 2 weeks
- [ ] Dependencies are clear
- [ ] Testing approach defined

## After Completion

Report to human:

```
✅ Small Track (4 gates) complete for <feature-name>

Artifacts created:
- docs/pre-dev/<feature-name>/research.md (Gate 0) ← NEW
- docs/pre-dev/<feature-name>/prd.md (Gate 1)
- docs/pre-dev/<feature-name>/trd.md (Gate 2)
- docs/pre-dev/<feature-name>/tasks.md (Gate 3)

Skipped from full workflow:
- Feature Map (features simple enough to map directly)
- API Design (no new APIs)
- Data Model (no new data structures)
- Dependency Map (no new dependencies)
- Subtask Creation (tasks small enough already)

Next steps:
1. Review artifacts in docs/pre-dev/<feature-name>/
2. Use /worktree to create isolated workspace
3. Use /write-plan to create implementation plan
4. Execute the plan
```

## Remember

- This is the **Small Track** - lightweight and fast
- **Gate 0 (Research) checks for existing patterns** even for small features
- If feature grows during planning, switch to `/pre-dev-full`
- All documents saved to `docs/pre-dev/<feature-name>/`
- Get human approval at each gate
- Technology decisions happen later in Dependency Map (not in this track)
