---
name: pre-dev-delivery-planning
description: |
  Gate 9 (Full Track) / Gate 4 (Small Track): Delivery roadmap and timeline planning.
  Transforms tasks into realistic delivery schedule with critical path analysis,
  resource allocation, and delivery breakdown. MANDATORY gate for both workflows.
metadata:
  sequence:
    after:
    - ring:pre-dev-task-breakdown
    - ring:pre-dev-subtask-creation
    before:
    - ring:executing-plans
    - ring:dev-cycle
  skip_when: |
    - Tasks not validated → complete task breakdown first
    - Proof-of-concept without delivery commitment
    - Research/exploration work without delivery deadline
  trigger: |
    - Tasks passed Gate 7 validation (Full Track) OR Gate 3 (Small Track)
    - Need realistic delivery timeline with dates
    - Ready to convert tasks into delivery schedule
    - Team composition known or determinable
---

# Delivery Planning - Realistic Roadmap with Critical Path

## Foundational Principle

**Every roadmap must be grounded in reality, not optimism.**

Creating unrealistic timelines creates:
- Broken promises to stakeholders
- Team burnout from impossible deadlines
- Loss of credibility when dates slip
- Hidden dependencies discovered during execution

**Roadmaps answer**: When will working software be delivered to users?
**Roadmaps never answer**: How fast could we go if everything goes perfectly (that's fantasy).

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Input Gathering** | Load tasks.md, ask user for start date + team composition + delivery cadence + period configuration + velocity multiplier |
| **2. Dependency Analysis** | Build dependency graph, identify critical path, find parallelization opportunities |
| **3. Capacity Planning** | Calculate team velocity (custom multiplier), allocate resources, identify bottlenecks |
| **4. Delivery Breakdown** | Group tasks by cadence (sprint/cycle/continuous), calculate period boundaries, identify spill overs, map parallel streams |
| **5. Risk Analysis** | Identify critical dependencies, flag high-risk milestones, define contingencies |
| **6. Gate Validation** | Verify all tasks scheduled, critical path correct, resources realistic, dates achievable, period boundaries respected |

## Explicit Rules

### ✅ DO Include in Roadmap

Start/end dates (YYYY-MM-DD format), team composition (N devs, roles), velocity multiplier (custom or default), critical path (longest dependency chain), parallel streams (independent task groups), delivery goals (what ships each period), period boundaries (sprint/cycle start/end dates), spill over identification (tasks crossing period boundaries), resource allocation (who works on what), risk milestones (high-impact dependencies), contingency buffer (10-20% for unknowns), Definition of Done per delivery period

### ❌ NEVER Include in Roadmap

Best-case scenarios ("if everything goes perfectly"), optimistic estimates ("assuming no blockers"), undefined capacity ("we'll figure it out"), missing dependencies ("tasks are independent"), unrealistic parallelization ("everyone works on everything"), no buffer time ("ship on last day"), vague milestones ("feature mostly done"), assumed availability ("team always at 100%"), fixed cadence without asking user, period boundaries ignored (tasks don't respect sprint/cycle limits)

## Rationalization Table

| Excuse | Reality | Required Action |
|--------|---------|-----------------|
| "Team composition doesn't matter, estimate anyway" | Capacity = reality. Without team size, timeline is fantasy. | **STOP. Ask user for team composition.** |
| "Dependencies are obvious, skip the graph" | Obvious to you ≠ validated. Hidden deps surface during execution. | **MUST build dependency graph. Verify critical path.** |
| "Parallel streams will emerge naturally" | Natural emergence = chaos. Define streams upfront. | **MUST identify independent task groups explicitly.** |
| "Default velocity multiplier is fine for everyone" | Teams vary. AI adoption varies. Experience varies. | **MUST ask user: use default or custom velocity.** |
| "Assume sprint cadence, everyone uses sprints" | Cadence = team culture. Scrum ≠ Kanban ≠ Shape Up. | **MUST ask user for their delivery cadence.** |
| "Period start date doesn't matter" | Period boundaries determine task allocation. Without start, can't calculate fit. | **MUST ask period start date if sprint/cycle chosen.** |
| "Tasks will fit naturally into periods" | Tasks don't respect arbitrary boundaries. Calculate fit explicitly. | **MUST check if task fits period, identify spill overs.** |
| "Buffer is pessimistic, ship dates tight" | Tight dates = guaranteed slippage. Buffer absorbs reality. | **MUST add 10-20% contingency buffer.** |
| "User knows priorities, skip asking" | Assumptions break. Priorities affect sequencing. | **ASK user for priority if ambiguous.** |
| "Critical path is longest task" | Critical path = longest dependency chain, not task. | **MUST trace full dependency chains.** |
| "Resource allocation will sort itself out" | Sorting out = thrashing. Allocate explicitly. | **MUST assign tasks to roles upfront.** |
| "Risk analysis is overkill for small features" | Small features have risks too. Identify them. | **MUST flag high-risk dependencies.** |
| "Delivery goals are just task lists" | Task lists ≠ goals. Goals define what ships. | **MUST define measurable delivery outcomes.** |

## Red Flags - STOP

If you catch yourself doing any of these, **STOP and ask the user**:

- Estimating without knowing team size
- Assuming all developers are equally skilled
- Ignoring task dependencies when building timeline
- Using fixed cadence without asking (sprint/cycle/continuous)
- Missing period start date when user chose sprint/cycle
- Missing period duration when user chose sprint/cycle
- Scheduling tasks without checking blockers
- Assuming 100% capacity (no meetings, no interruptions)
- Using velocity multiplier without offering customization
- Using round numbers for dates ("exactly 4 weeks")
- Missing contingency buffer
- Not checking if tasks fit within period boundaries
- No clear definition of "done" per delivery period
- Ambiguous priorities (which task first if both ready?)

**When you catch yourself**: Use AskUserQuestion to resolve ambiguity with the user.

## Mandatory User Questions

**Use AskUserQuestion tool to gather these REQUIRED inputs:**

### Question 1: Start Date
- **Header:** "Start Date"
- **Question:** "When will the team start working on this feature?"
- **Format:** YYYY-MM-DD (e.g., 2026-03-01)
- **Why:** Determines all subsequent dates in the roadmap

### Question 2: Team Composition
- **Header:** "Team Size"
- **Question:** "How many developers will work on this feature?"
- **Options:**
  - "1 developer (solo)" - Single developer
  - "2 developers (pair)" - Small team
  - "3-4 developers (squad)" - Full squad
  - "5+ developers (large team)" - Large team
- **Why:** Determines parallelization capacity and resource allocation

### Question 3: Delivery Cadence
- **Header:** "Delivery Cadence"
- **Question:** "How does your team organize delivery cycles?"
- **Options:**
  - "Sprints (1-2 weeks)" - Scrum-style fixed iterations
  - "Cycles (1-3 months)" - Shape Up-style longer cycles
  - "Continuous (no fixed intervals)" - Kanban-style continuous delivery
- **Why:** Determines how to group tasks and define delivery milestones

### Question 4 (CONDITIONAL): Sprint/Cycle Configuration
- **When to ask:** If user chose "Sprints" or "Cycles" in Question 3
- **Part A - Duration:**
  - **Header:** "Period Duration"
  - **Question (if Sprints):** "What is your sprint duration?"
    - Options: "1 week", "2 weeks"
  - **Question (if Cycles):** "What is your cycle duration?"
    - Options: "1 month (4 weeks)", "2 months (8 weeks)", "3 months (12 weeks)"
  - **Why:** Determines period boundaries for task allocation
- **Part B - Start Date:**
  - **Header:** "Period Start"
  - **Question (if Sprints):** "When does Sprint 1 start?" (format: YYYY-MM-DD)
  - **Question (if Cycles):** "When does Cycle 1 start?" (format: YYYY-MM-DD)
  - **Why:** Establishes period boundaries to check if tasks fit completely or spill over
- **Note:** If user chose "Continuous", skip this question (no fixed periods)

### Question 5: Human Validation Overhead

**Context:**
- Baseline: AI Agent implements via ring:dev-cycle
- AI handles: coding, TDD, automated review, SRE validation, DevOps
- AI Estimate: X AI-agent-hours (from tasks.md)

**Question:** "What overhead for human validation and adjustments?"

**Options:**

1. **"1.2x - Minimal validation (20% overhead)"**
   - AI generates consistently high-quality code
   - Quick review, minimal adjustments
   - Example: 4h AI → 4.8h adjusted → 5.3h calendar

2. **"1.5x - Standard validation (50% overhead)"** ← RECOMMENDED
   - Normal review process with some adjustments
   - Re-run tests after changes
   - Standard manual QA
   - Example: 4h AI → 6h adjusted → 6.67h calendar

3. **"2.0x - Deep validation (100% overhead)"**
   - Critical review with multiple rounds
   - Significant refactoring requested
   - Extensive manual testing
   - Example: 4h AI → 8h adjusted → 8.89h calendar

4. **"2.5x - Heavy rework (150% overhead)"**
   - AI code needs major changes
   - Multiple iteration cycles
   - Complex stakeholder feedback
   - Example: 4h AI → 10h adjusted → 11.11h calendar

5. **"Custom multiplier"**
   - Specify value based on historical data
   - Example: 1.7x, 1.8x, etc.

**Multiplier accounts for:**
- Human code review time (validation, not execution)
- Requested adjustments and refactoring
- Manual exploratory testing
- Stakeholder demos and feedback
- Documentation review
- Deployment validation

**Historical data (update after tasks):**
After completing tasks, track actual multipliers:
- Task T-001: Planned 1.5x, Actual 1.6x (close)
- Task T-002: Planned 1.5x, Actual 2.1x (underestimated)
- Average: 1.7x → Adjust future estimates

### Question 6 (CONDITIONAL): Priority Clarification
- **When to ask:** If multiple tasks have same dependencies and could start simultaneously
- **Header:** "Task Priority"
- **Question:** "Tasks T-XXX and T-YYY are both ready. Which should start first?"
- **Options:** [List the competing tasks with their descriptions]
- **Why:** Prevents arbitrary sequencing decisions

### Question 7 (CONDITIONAL): Capacity Confirmation
- **When to ask:** If team size seems insufficient for parallelization opportunities
- **Header:** "Capacity Constraint"
- **Question:** "Critical path is X weeks, but with N more devs we could parallelize and finish in Y weeks. Do you want to:"
- **Options:**
  - "Keep current team (X weeks)" - Accept longer timeline
  - "Add resources (Y weeks)" - Shorten timeline with more people
- **Why:** User decides cost vs. speed tradeoff

## Gate 9/4 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Input Completeness** | Start date confirmed; team composition known; delivery cadence selected; period configuration set (if sprint/cycle); velocity multiplier validated (default or custom); all tasks loaded from tasks.md |
| **Dependency Analysis** | Dependency graph built; critical path identified; parallel streams defined; no circular dependencies |
| **Capacity Planning** | Velocity calculated (custom or default multiplier); resources allocated to tasks; bottlenecks identified; realistic capacity (70-80% utilization) |
| **Delivery Breakdown** | Periods match chosen cadence; period boundaries calculated (if sprint/cycle); tasks allocated to periods; spill overs identified; delivery goals measurable; parallel streams mapped; handoffs minimized |
| **Risk Management** | High-risk dependencies flagged; contingency buffer added (10-20%); mitigation strategies defined; spill over risks documented |
| **Timeline Realism** | No best-case assumptions; critical path validated; dates achievable with given capacity; period boundaries respected; user approved |

**Gate Result:** ✅ PASS → Ready for execution | ⚠️ CONDITIONAL (adjust capacity/dates) | ❌ FAIL (unrealistic, rework)

## Velocity Calibration (Lerian Standard)

**See [shared-patterns/ai-agent-baseline.md](../shared-patterns/ai-agent-baseline.md) for baseline definition.**

**Baseline:** AI Agent via ring:dev-cycle
**Capacity:** 90% (hardcoded)
**Multiplier:** User-defined (human validation overhead)

### Calculation Formula

```
adjusted_hours = ai_estimate × multiplier
calendar_hours = adjusted_hours ÷ 0.90
calendar_days = calendar_hours ÷ 8 ÷ team_size

Where:
- ai_estimate = from tasks.md (AI-agent-hours)
- multiplier = human validation overhead (typically 1.2x - 2.5x)
- 0.90 = capacity utilization (90%)
- 8 = hours per working day
- team_size = number of developers
```

### Capacity Utilization: 90% (Fixed)

**See [shared-patterns/ai-agent-baseline.md](../shared-patterns/ai-agent-baseline.md#capacity-90-fixed) for detailed capacity breakdown.**

**Summary:** AI Agent has 90% capacity (10% overhead from API limits, context loading, tool execution).

### Multiplier: Human Validation Overhead

**User selects multiplier to account for:**
- ✅ Human code review and validation time
- ✅ Requested adjustments and refactoring
- ✅ Re-running tests after changes
- ✅ Manual exploratory testing (beyond automated)
- ✅ Stakeholder demos and feedback cycles
- ✅ Deployment validation and monitoring setup
- ✅ Integration issues found in staging/production

**Does NOT account for (already done by AI):**
- ❌ Initial code implementation
- ❌ Unit/integration test writing (TDD)
- ❌ Automated code review (ring:code-reviewer)
- ❌ SRE validation (ring:sre)
- ❌ DevOps setup (ring:devops-engineer)

### Example Calculation

**Task T-001: "User Management CRUD API"**

```
Step 1: AI Estimation (Gate 7)
AI Estimate: 4.5 AI-agent-hours

Step 2: Apply Multiplier (Gate 9)
User selects: 1.5x (standard validation)
Adjusted Hours: 4.5h × 1.5 = 6.75h

Step 3: Apply Capacity (hardcoded)
Calendar Hours: 6.75h ÷ 0.90 = 7.5h

Step 4: Convert to Days
Calendar Days: 7.5h ÷ 8h/day = 0.94 developer-days

Step 5: Account for Team Size
With 1 dev: 0.94 ÷ 1 = 0.94 calendar days ≈ 1 day
With 2 devs: 0.94 ÷ 2 = 0.47 calendar days ≈ 0.5 day (4 hours)
```

**Breakdown of 7.5h total:**
- AI implementation: 4.5h (60%)
- Human validation: 2.25h (30%) ← multiplier overhead
- Technical overhead: 0.75h (10%) ← capacity overhead

## Period Boundary Calculation

**For Sprints/Cycles:**

1. **Define period boundaries:**
   ```
   Sprint 1: Start date to (Start date + Duration)
   Sprint 2: (Sprint 1 End + 1 day) to (Sprint 1 End + Duration + 1 day)
   ...
   ```

2. **Check task fit:**
   ```
   Task T-001:
     Start: 2026-03-01 (based on dependencies)
     Duration: 10 calendar days
     End: 2026-03-10

   Sprint 1: 2026-03-01 to 2026-03-14 (2 weeks)

   Fit check: T-001 end (2026-03-10) <= Sprint 1 end (2026-03-14)
   Result: ✅ Fits completely in Sprint 1
   ```

3. **Identify spill overs:**
   ```
   Task T-002:
     Start: 2026-03-10 (depends on T-001)
     Duration: 12 calendar days
     End: 2026-03-22

   Sprint 1: 2026-03-01 to 2026-03-14
   Sprint 2: 2026-03-15 to 2026-03-28

   Fit check: T-002 end (2026-03-22) > Sprint 1 end (2026-03-14)
   Result: ⚠️ Spill over (starts Sprint 1, ends Sprint 2)

   Allocation:
     - Sprint 1: 4 days of work (2026-03-10 to 2026-03-14)
     - Sprint 2: 8 days of work (2026-03-15 to 2026-03-22)
   ```

**For Continuous Delivery:**
- No period boundaries to check
- Tasks scheduled based purely on dependencies and capacity
- Milestones defined by task completion, not time boxes

## Critical Path Analysis

**Definition:** The longest chain of dependent tasks from start to finish.

**How to Calculate:**
1. Build dependency graph from tasks.md
2. For each task, calculate: Earliest Start Date (ESD) based on dependencies
3. For each task, calculate: Latest Start Date (LSD) without delaying project
4. Tasks where ESD = LSD are on critical path (zero slack)
5. Sum durations of critical path tasks = minimum project duration

**Example:**
```
Dependency Chain:
T-001 (Foundation, 2 weeks)
  → T-002 (API Layer, 1 week)
  → T-007 (Integration, 2 weeks)

Critical Path Duration: 2 + 1 + 2 = 5 weeks (minimum possible)

Parallel Stream (not on critical path):
T-005 (Frontend, 2 weeks) - can run parallel to T-001/T-002
```

## Parallelization Analysis

**Identify Independent Streams:**
1. Tasks with no shared dependencies can run in parallel
2. Tasks requiring different skill sets can run in parallel
3. Tasks on different components can run in parallel

**Constraints:**
- Team size limits parallel streams (2 devs = max 2 parallel tasks)
- Skill requirements limit parallelization (backend vs. frontend)
- Integration points require synchronization (streams merge)

**Example:**
```
Stream A (Backend):  T-001 → T-002 → T-007
Stream B (Frontend): T-005 → T-006 (runs parallel to A)
Stream C (Infra):    T-009 (blocks both A and B, must run first)

With 3 devs: Can run A, B, C in parallel (optimal)
With 2 devs: Must sequence B after A (sub-optimal)
With 1 dev:  Fully sequential (slowest)
```

## Roadmap Template Structure

**Output to:** See [Output & After Approval](#output--after-approval) for dual output paths (MD + JSON).

### Section 1: Executive Summary
```markdown
# Delivery Roadmap: {Feature Name}

## Executive Summary

| Metric | Value |
|--------|-------|
| **Start Date** | YYYY-MM-DD |
| **End Date** | YYYY-MM-DD |
| **Total Duration** | X weeks |
| **Critical Path** | T-001 → T-003 → T-007 (Y weeks) |
| **Parallel Streams** | N streams identified |
| **Team Composition** | N developers (roles) |
| **Development Mode** | AI Agent via ring:dev-cycle |
| **Human Validation Multiplier** | Xx (e.g., 1.5x = 50% overhead for validation) |
| **Multiplier Source** | Default (1.5x) / Custom (user-validated) |
| **Capacity Utilization** | 90% (AI Agent standard) |
| **Formula** | ai_estimate × multiplier ÷ 0.90 |
| **Delivery Cadence** | Sprints (1-2w) / Cycles (1-3m) / Continuous |
| **Period Duration** | {X} weeks/months (if sprint/cycle) |
| **First Period Starts** | YYYY-MM-DD (if sprint/cycle) |
| **Contingency Buffer** | Z% (A days) |
| **Confidence Level** | High / Medium / Low |
```

### Section 2: Delivery Breakdown (Adaptive Based on Cadence)

**If user chose "Sprints (1-2 weeks)":**
```markdown
## Sprint Breakdown

### Sprint 1: {Sprint Goal} (2026-03-01 to 2026-03-14)
**Deliverable:** {What ships to users}

| Task | Type | Effort | Start | End | Fits Sprint? | Dependencies | Assignee | Status |
|------|------|--------|-------|-----|--------------|--------------|----------|--------|
| T-001 | Foundation | L (13pts) | 03-01 | 03-10 | ✅ Complete | - | Backend | 🟢 Ready |
| T-002 | Feature | M (8pts) | 03-10 | 03-22 | ⚠️ Spill over | T-001 | Backend | ⏸️ Blocked |
| T-005 | Feature | M (8pts) | 03-01 | 03-05 | ✅ Complete | - | Frontend | 🟢 Ready |

**Sprint 1 Scope:**
- Complete tasks: T-001, T-005
- Partial tasks: T-002 (4 days in Sprint 1, 8 days in Sprint 2)

**Parallel Streams:**
- Stream A: T-001 (Backend, Dev 1)
- Stream B: T-005 (Frontend, Dev 2)

**Definition of Done:**
- [ ] T-001 and T-005 fully deployed to staging
- [ ] T-002 progressed 4/12 days (33% complete)
- [ ] Code reviewed and merged
- [ ] Sprint demo shows T-001 + T-005 working
```

**If user chose "Cycles (1-3 months)":**
```markdown
## Cycle Breakdown

### Cycle 1: {Cycle Goal} (2026-03-01 to 2026-04-30, 8 weeks)
**Deliverable:** {What ships to users}

| Task | Type | Effort | Start | End | Fits Cycle? | Dependencies | Assignee | Status |
|------|------|--------|-------|-----|-------------|--------------|----------|--------|
| T-001 | Foundation | L (13pts) | 03-01 | 03-15 | ✅ Complete | - | Backend | 🟢 Ready |
| T-002 | Feature | M (8pts) | 03-15 | 03-25 | ✅ Complete | T-001 | Backend | ⏸️ Blocked |
| T-005 | Feature | M (8pts) | 03-01 | 03-10 | ✅ Complete | - | Frontend | 🟢 Ready |

**Cycle 1 Scope:**
- Complete tasks: T-001, T-002, T-005, T-006, T-007
- All features integrated and deployed

**Parallel Streams:**
- Stream A: T-001 → T-002 → T-003 (Backend)
- Stream B: T-005 → T-006 (Frontend, parallel)

**Definition of Done:**
- [ ] All cycle tasks completed
- [ ] Integration testing passed
- [ ] Deployed to production
- [ ] User feedback collected
- [ ] Post-cycle retrospective completed
```

**If user chose "Continuous (no fixed intervals)":**
```markdown
## Delivery Milestones

### Milestone 1: {Milestone Goal} (Week 2, 2026-03-10)
**Deliverable:** {What ships to users}

| Task | Type | Effort | Start | End | Dependencies | Assignee | Status |
|------|------|--------|-------|-----|--------------|----------|--------|
| T-001 | Foundation | L (13pts) | 03-01 | 03-10 | - | Backend | 🟢 Ready |

**Completion Criteria:**
- [ ] Task T-001 deployed to production
- [ ] Monitoring configured
- [ ] User acceptance confirmed
- [ ] No blockers for T-002

### Milestone 2: {Milestone Goal} (Week 4, 2026-03-25)
**Deliverable:** {What ships to users}

| Task | Type | Effort | Start | End | Dependencies | Assignee | Status |
|------|------|--------|-------|-----|--------------|----------|--------|
| T-002 | Feature | M (8pts) | 03-10 | 03-18 | T-001 | Backend | ⏸️ Blocked |
| T-005 | Feature | M (8pts) | 03-01 | 03-08 | - | Frontend | 🟢 Ready |

**Completion Criteria:**
- [ ] Tasks T-002 and T-005 deployed
- [ ] Integration verified
- [ ] No regressions detected
- [ ] Performance SLAs met
```

### Section 3: Critical Path Analysis
```markdown
## Critical Path Analysis

**Path:** T-001 → T-002 → T-007

| Task | Duration | Cumulative | Slack | On Critical Path? |
|------|----------|------------|-------|-------------------|
| T-001 | 2 weeks | 2 weeks | 0 days | ✅ Yes |
| T-002 | 1.5 weeks | 3.5 weeks | 0 days | ✅ Yes |
| T-007 | 2 weeks | 5.5 weeks | 0 days | ✅ Yes |
| T-005 | 1 week | 1 week | 2 weeks | ❌ No (parallel) |

**Minimum Project Duration:** 5.5 weeks (critical path)
**With Parallelization:** 5.5 weeks (no impact, T-005 has slack)
**Risk:** Any delay on critical path tasks delays entire project

**Spill Over Impact (for Sprint/Cycle cadences):**
- T-002 spills from Sprint 1 to Sprint 2 (4 days + 8 days)
- This affects Sprint 1 velocity reporting (partial completion)
```

### Section 4: Resource Allocation
```markdown
## Resource Allocation

| Role | Count | Utilization | Assigned Tasks |
|------|-------|-------------|----------------|
| Backend Engineer | 2 | 75% | T-001, T-002, T-003, T-007 |
| Frontend Engineer | 1 | 70% | T-005, T-006 |
| DevOps Engineer | 1 | 50% (part-time) | T-009 (infra setup) |
| QA Analyst | 1 | 60% (from Week 3) | Testing from Week 3 onwards |

**Bottlenecks:**
- Backend heavy: 4 tasks require backend skills (T-001, T-002, T-003, T-007)
- Frontend light: 2 tasks require frontend skills (T-005, T-006)

**Recommendations:**
- Consider cross-training if backend becomes bottleneck
- QA can start test planning during Week 1-2
- Frontend can assist with integration testing during T-007
```

### Section 5: Risk Milestones
```markdown
## Risk Milestones

| Milestone | Date | Risk Level | Impact | Mitigation |
|-----------|------|------------|--------|------------|
| Database Foundation (T-001) | Week 2 | 🔴 HIGH | Blocks T-002, T-003, T-007 (entire backend) | Start T-001 immediately, daily progress checks |
| API Integration (T-007) | Week 5.5 | 🟡 MEDIUM | Blocks deployment, but frontend can continue | Buffer time added, fallback: mock API |
| Sprint 1 Spill Over (T-002) | Sprint 1 end | 🟡 MEDIUM | Affects Sprint 1 velocity, team morale | Communicate spill over upfront, adjust Sprint 2 capacity |
| External Dependency (T-009) | Week 1 | 🟡 MEDIUM | Blocks deployment setup | Contact vendor early, have backup provider |

**Contingency Plan:**
- If T-001 slips by >2 days → Escalate to stakeholders, consider adding resource
- If T-007 blocked → Deploy frontend with mock backend, continue integration in next period
- If spill overs accumulate → Re-plan delivery cadence (extend sprint/cycle duration)
```

### Section 6: Gantt-Style Timeline
```markdown
## Timeline Visualization

\`\`\`
Week 1-2:  [████████ T-001: Foundation ████████]
           [██ T-005: Frontend ██][T-006]

Week 3-4:  [████ T-002 (cont.) ████][████ T-003: Logic ████]
           [██ T-006: UI ██][── idle──]

Week 5-6:  [████████ T-007: Integration ████████]
           [████ T-008: Polish ████][── idle──]

Period Boundaries (if Sprint/Cycle):
  Sprint 1: Week 1-2 (ends 2026-03-14)
  Sprint 2: Week 3-4 (ends 2026-03-28)
  Sprint 3: Week 5-6 (ends 2026-04-11)

Legend:
  [████] = Active work
  [──] = Idle/Buffer
  ⚠️ = Spill over (task crosses period boundary)
\`\`\`
```

### Section 7: Assumptions and Constraints
```markdown
## Assumptions

1. **Team Availability:** All developers available full-time (no vacations, no split focus)
2. **Dependency Resolution:** All external dependencies (APIs, credentials) available on time
3. **Scope Stability:** No scope changes during execution (new requirements = new planning)
4. **Infrastructure Ready:** Development/staging environments available Day 1
5. **Capacity Utilization:** 90% (AI Agent via ring:dev-cycle, 10% overhead for API/technical)
6. **Multiplier Accuracy:** Custom multiplier ({X}x) validated against historical validation overhead OR using default multiplier (1.5x)
7. **Period Boundaries:** Sprint/Cycle boundaries do not shift (dates fixed)
8. **Baseline Execution:** All implementation via ring:dev-cycle (AI Agent with automated gates)

## Constraints

1. **Team Size:** N developers (cannot increase mid-project without re-planning)
2. **Fixed Scope:** All tasks from tasks.md must be completed (no cutting features)
3. **Quality Gates:** All ring:dev-cycle gates must pass (cannot skip review/testing)
4. **Critical Path:** Cannot compress critical path without adding resources or cutting scope
5. **Delivery Cadence:** {Sprint/Cycle/Continuous} rhythm cannot change mid-project
6. **Spill Over Management:** Tasks crossing period boundaries must be tracked explicitly
```

## Common Violations

| Violation | Wrong | Correct |
|-----------|-------|---------|
| **Optimistic Timelines** | "5-week critical path, let's commit to 4 weeks" (no buffer) | "5-week critical path + 10% buffer = 5.5 weeks commitment" |
| **Ignoring Dependencies** | "All tasks 2 weeks, finish in 2 weeks" (assumes parallelization) | "Critical path 5 weeks (T-001→T-002→T-007), other tasks parallel" |
| **100% Capacity** | "2 devs × 2 weeks × 5 days = 20 dev-days" (unrealistic) | "2 devs × 2 weeks × 5 days × 0.75 capacity = 15 dev-days" |
| **Fixed Cadence Assumption** | "Everyone works in 2-week sprints" | "Ask user: sprint/cycle/continuous delivery?" |
| **Ignoring Period Boundaries** | "Task T-002 starts in Sprint 1, wherever it ends is fine" | "T-002 starts Sprint 1, ends Sprint 2 → spill over, track explicitly" |
| **Default Multiplier Always** | "Use 1.5x always" | "Ask user: default (1.5x) or custom based on historical validation overhead?" |

## Confidence Scoring

| Factor | Points | Criteria |
|--------|--------|----------|
| **Dependency Clarity** | 0-30 | All dependencies mapped: 30, Most clear: 20, Ambiguous: 10 |
| **Capacity Realism** | 0-25 | Realistic utilization (70-80%): 25, Optimistic (90%+): 10, Undefined: 0 |
| **Critical Path Validated** | 0-25 | Full dependency graph: 25, Partial: 15, Assumptions: 5 |
| **Risk Mitigation** | 0-20 | All high-risk flagged + mitigations: 20, Some identified: 10, None: 0 |

**Total Score Interpretation:**
- **80-100 points:** HIGH confidence - Roadmap is realistic and achievable
- **50-79 points:** MEDIUM confidence - Some assumptions, monitor closely
- **0-49 points:** LOW confidence - Significant unknowns, high risk of slippage

**Action Based on Score:**
- HIGH (80+): Proceed with execution, communicate dates to stakeholders
- MEDIUM (50-79): Present roadmap with caveats, identify assumptions to validate early
- LOW (<50): DO NOT commit to dates, resolve unknowns first via AskUserQuestion

## Output & After Approval

**Output to:**
- `docs/pre-dev/{feature-name}/delivery-roadmap.md` — Human-readable roadmap (existing behavior)
- `docs/pre-dev/{feature-name}/delivery-roadmap.json` — Machine-readable structured data (see [JSON Output Schema](#json-output-schema-mandatory))

**MUST generate both files.** The MD is for humans to read; the JSON is for programmatic consumption by tools (e.g., lerian-map). The JSON MUST be generated alongside the MD every time — it is not optional.

**Topology-aware output paths:**

| Structure | Files Generated |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/delivery-roadmap.md` + `docs/pre-dev/{feature}/delivery-roadmap.json` |
| monorepo | Index files + `{module.path}/docs/pre-dev/{feature}/delivery-roadmap.md` + `{module.path}/docs/pre-dev/{feature}/delivery-roadmap.json` per module |
| multi-repo | `{repo.path}/docs/pre-dev/{feature}/delivery-roadmap.md` + `{repo.path}/docs/pre-dev/{feature}/delivery-roadmap.json` per repo |

**After user approves roadmap:**

1. ✅ Roadmap becomes execution baseline
2. 📊 Track progress against delivery goals (not individual subtasks)
3. 🚨 Flag slippage early (daily standup: on track vs. critical path?)
4. 🔄 Re-plan if major assumptions break (scope change, resource loss, dependency block)
5. 📈 Update roadmap when tasks complete (mark done, adjust future periods)
6. ⚠️ Monitor spill overs (if sprint/cycle): communicate impact to stakeholders

**Integration with dev-team:**
- Use `/ring:worktree` to create isolated workspace
- Use `/ring:dev-cycle` to execute tasks with AI-assisted gates
- Use roadmap to prioritize which tasks to pull next

## JSON Output Schema (MANDATORY)

**MUST generate `delivery-roadmap.json` with this EXACT schema every time a delivery roadmap is created.**

The JSON provides a stable, predictable contract for programmatic consumers. Unlike the MD (which has flexible formatting for human readability), the JSON MUST follow this schema exactly — field names, types, and structure are non-negotiable.

### Schema Definition

```json
{
  "version": "1.0.0",
  "gate": 9,
  "feature": "{feature-name}",
  "generatedAt": "ISO-8601 timestamp (e.g., 2026-03-10T14:30:00Z)",
  "dates": {
    "startDate": "YYYY-MM-DD",
    "endDate": "YYYY-MM-DD",
    "mvpEndDate": "YYYY-MM-DD or null",
    "totalDuration": "5.5 weeks"
  },
  "velocity": {
    "teamSize": 2,
    "utilizationRate": 0.9,
    "humanValidationMultiplier": 1.5,
    "multiplierSource": "default | custom"
  },
  "deliveryCadence": {
    "type": "sprint | cycle | continuous",
    "periodDuration": "2 weeks | 1 month | null (if continuous)",
    "periodStartDate": "YYYY-MM-DD or null (if continuous)"
  },
  "tasks": [
    {
      "id": "T-001",
      "description": "Task description from tasks.md",
      "aiEstimate": "2h",
      "adjusted": "3.0h",
      "calendar": "3.3h",
      "days": "0.4d",
      "dependencies": ["T-002"],
      "assignee": "Backend | Frontend | DevOps | QA",
      "status": "ready | blocked | in_progress | completed",
      "onCriticalPath": true
    }
  ],
  "milestones": [
    {
      "name": "Milestone or Sprint/Cycle name",
      "type": "sprint | cycle | milestone",
      "startDate": "YYYY-MM-DD",
      "targetDate": "YYYY-MM-DD",
      "taskIds": ["T-001", "T-002"],
      "deliverable": "What ships to users",
      "spillOvers": ["T-003"]
    }
  ],
  "criticalPath": {
    "taskIds": ["T-001", "T-002", "T-007"],
    "totalDuration": "5.5 weeks",
    "minimumProjectDuration": "5.5 weeks"
  },
  "risks": [
    {
      "taskIds": ["T-001"],
      "level": "high | medium | low",
      "impact": "Blocks T-002, T-003, T-007",
      "mitigation": "Start immediately, daily progress checks"
    }
  ],
  "contingencyBuffer": {
    "percentage": 15,
    "days": 4
  },
  "confidenceScore": 85
}
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | yes | Schema version for forward compatibility. Currently `"1.0.0"` |
| `gate` | number | yes | Gate number (9 for Full Track, 4 for Small Track) |
| `feature` | string | yes | Feature name matching the pre-dev folder name |
| `generatedAt` | string | yes | ISO-8601 timestamp of generation |
| `dates.startDate` | string | yes | Project start date (YYYY-MM-DD) |
| `dates.endDate` | string | yes | Project end date including buffer (YYYY-MM-DD) |
| `dates.mvpEndDate` | string | no | MVP end date if different from full end date |
| `dates.totalDuration` | string | yes | Total project duration in working weeks (e.g., "5.5 weeks") |
| `velocity.teamSize` | number | yes | Number of developers |
| `velocity.utilizationRate` | number | yes | Capacity utilization (always 0.9 for AI Agent) |
| `velocity.humanValidationMultiplier` | number | yes | User-selected multiplier (1.2x to 2.5x) |
| `velocity.multiplierSource` | string | yes | `"default"` or `"custom"` |
| `deliveryCadence.type` | string | yes | `"sprint"`, `"cycle"`, or `"continuous"` |
| `deliveryCadence.periodDuration` | string | no | Period duration (null if continuous) |
| `deliveryCadence.periodStartDate` | string | no | First period start date (null if continuous) |
| `tasks[]` | array | yes | all tasks from tasks.md with calculated estimates |
| `tasks[].id` | string | yes | Task ID matching tasks.md (e.g., `"T-001"`) |
| `tasks[].description` | string | yes | Task description/title |
| `tasks[].aiEstimate` | string | yes | Original AI estimate from tasks.md. Format: `{number}h` (e.g., `"2h"`, `"4.5h"`) |
| `tasks[].adjusted` | string | yes | After applying human validation multiplier. Format: `{number}h` (e.g., `"3.0h"`, `"6.75h"`) |
| `tasks[].calendar` | string | yes | After applying capacity utilization. Format: `{number}h` (e.g., `"3.3h"`, `"7.5h"`) |
| `tasks[].days` | string | yes | Calendar days (accounting for team size). Format: `{number}d` (e.g., `"0.4d"`, `"1.1d"`) |
| `tasks[].dependencies` | array | yes | Task IDs this task depends on (empty array if none) |
| `tasks[].assignee` | string | yes | Role assigned to this task |
| `tasks[].status` | string | yes | Current status |
| `tasks[].onCriticalPath` | boolean | yes | Whether task is on the critical path |
| `milestones[]` | array | yes | Delivery milestones (sprints, cycles, or milestones) |
| `milestones[].name` | string | yes | Sprint/Cycle/Milestone name |
| `milestones[].type` | string | yes | `"sprint"`, `"cycle"`, or `"milestone"` |
| `milestones[].startDate` | string | yes | Period start date |
| `milestones[].targetDate` | string | yes | Period end date |
| `milestones[].taskIds` | array | yes | Tasks allocated to this period |
| `milestones[].deliverable` | string | yes | What ships to users in this period |
| `milestones[].spillOvers` | array | yes | Task IDs that spill over from/into this period |
| `criticalPath.taskIds` | array | yes | Ordered list of tasks on critical path |
| `criticalPath.totalDuration` | string | yes | Total critical path duration |
| `criticalPath.minimumProjectDuration` | string | yes | Minimum possible project duration |
| `risks[]` | array | yes | Risk items (empty array if none) |
| `risks[].taskIds` | array | yes | Task IDs affected by this risk |
| `contingencyBuffer.percentage` | number | yes | Buffer percentage (10-20) |
| `contingencyBuffer.days` | number | yes | Buffer in calendar days |
| `confidenceScore` | number | yes | Confidence score (0-100) from scoring rubric |

### Validation Rules

MUST validate the JSON before writing:

1. **`dates.startDate` and `dates.endDate` are REQUIRED** — MUST NOT be empty or null
2. **`tasks` array MUST have at least 1 item** — empty roadmap is invalid
3. **Every task MUST have `id`, `description`, `aiEstimate`, `adjusted`, `calendar`, `days`** — these fields match lerian-map's `RoadmapTask` interface exactly
4. **`confidenceScore` MUST be 0-100** — matches the scoring rubric in this skill
5. **`milestones` array MUST have at least 1 item** — every roadmap has at least one delivery milestone
6. **`criticalPath.taskIds` MUST reference valid task IDs** — all IDs must exist in `tasks[]`
7. **`version` MUST be `"1.0.0"`** — update when schema changes
8. **`milestones[].taskIds` MUST reference valid task IDs** from `tasks[]`
9. **`milestones[].spillOvers` MUST reference valid task IDs** from `tasks[]`
10. **`risks[].taskIds` MUST reference valid task IDs** from `tasks[]`
11. **`velocity.teamSize` MUST be greater than 0** — zero team size causes division-by-zero

### Continuous Cadence Rules

When `deliveryCadence.type` is `"continuous"`, the following rules apply:

- `deliveryCadence.periodDuration` MUST be `null`
- `deliveryCadence.periodStartDate` MUST be `null`
- `milestones[].type` MUST be `"milestone"` (not `"sprint"` or `"cycle"`)
- `milestones[].startDate` MUST be the earliest start date of any task in that milestone's `taskIds`
- `milestones[].targetDate` MUST be the latest end date of any task in that milestone's `taskIds`
- `milestones[].spillOvers` MUST be an empty array `[]` (no period boundaries to spill over)

### Anti-Rationalization (JSON Output)

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "JSON is redundant, MD has the same data" | MD format varies per generation; JSON is the stable contract | **MUST generate both files** |
| "I'll generate the JSON later" | Later = never. Generate alongside MD | **MUST generate in the same step as the MD** |
| "Schema is too detailed, I'll simplify" | Consumers depend on exact field names | **MUST follow schema exactly as defined** |
| "Some fields are optional, I'll skip them" | Only `mvpEndDate` and cadence fields are nullable | **MUST include all required fields** |
| "The MD is enough for this small feature" | Feature size is irrelevant. Contract is universal | **MUST generate JSON for every roadmap** |

## Pressure Resistance Scenarios

### Scenario 1: User Pushes for Faster Timeline

| User Says | Your Response |
|-----------|---------------|
| "Can't we finish in 3 weeks instead of 5?" | "Critical path is 5 weeks (T-001→T-002→T-007). To compress:<br>1. Add more developers (parallelization)<br>2. Cut scope (remove tasks)<br>3. Reduce quality (skip gates - NOT RECOMMENDED)<br><br>Which option aligns with your goals?" |

### Scenario 2: User Provides Incomplete Team Info

| User Says | Your Response |
|-----------|---------------|
| "Just estimate with 'a team'" | "Cannot create realistic roadmap without team size. Timeline varies dramatically:<br>- 1 dev: 8 weeks sequential<br>- 2 devs: 5 weeks (some parallelization)<br>- 4 devs: 4 weeks (max parallelization)<br><br>How many developers will work on this?" |

### Scenario 3: User Wants Default Velocity Without Validation

| User Says | Your Response |
|-----------|---------------|
| "Just use the default, I don't have historical data" | "Understood. Using default multipliers:<br>- AI-assisted: 0.6x (40% faster)<br>- Traditional: 1.0x (baseline)<br><br>Note: These are industry averages. Your team's actual velocity may vary. Recommend tracking actuals and updating multiplier after first period." |

### Scenario 4: User Disagrees with Critical Path

| User Says | Your Response |
|-----------|---------------|
| "T-005 should be on critical path, not T-001" | "Let me verify the dependency chain:<br><br>T-001 (Foundation) blocks:<br>  → T-002 (API Layer)<br>  → T-007 (Integration)<br><br>T-005 (Frontend) has no blockers, can run parallel.<br><br>Critical path = longest dependency chain. If T-005 should block something, please clarify the dependency." |

### Scenario 5: User Uncertain About Cadence

| User Says | Your Response |
|-----------|---------------|
| "I don't know, what do you recommend?" | "Cannot recommend without context. Cadence depends on:<br>- Team culture (Scrum/Kanban/Shape Up)<br>- Release process (deploy daily vs. every 2 weeks)<br>- Stakeholder expectations (regular demos vs. continuous feedback)<br><br>How does your team currently organize work?" |

### Scenario 6: User Concerned About Spill Overs

| User Says | Your Response |
|-----------|---------------|
| "Too many spill overs, this looks bad" | "Spill overs are reality, not failure. They occur when:<br>- Task duration doesn't align with period length<br>- Dependencies cause mid-period starts<br><br>Options to reduce spill overs:<br>1. Adjust period duration (e.g., 1 week → 2 weeks)<br>2. Switch to continuous delivery (no fixed periods)<br>3. Accept spill overs and communicate transparently<br><br>Which approach fits your team culture?" |

## The Bottom Line

**If you created a roadmap without asking about team composition, delivery cadence, period configuration, or velocity multiplier, delete it and start over.**

Roadmaps are not educated guesses. Roadmaps are calculated schedules based on:
- Validated dependency chains (critical path analysis)
- Realistic team capacity (size × utilization × custom velocity)
- Explicit parallelization opportunities (independent task streams)
- Risk-adjusted timelines (contingency buffer for unknowns)
- Team-specific delivery rhythm (sprint/cycle/continuous)
- Period boundary awareness (tasks fit or spill over)

"We'll figure it out as we go" is not a roadmap. It's hope.

**Questions that must be answered before committing dates:**
1. When do we start? (start date)
2. Who is working on this? (team composition)
3. How do they work? (AI-assisted or traditional, default or custom velocity)
4. What rhythm do they follow? (sprint/cycle/continuous)
5. When do periods start? (if sprint/cycle: period start date + duration)
6. What must happen first? (critical path)
7. What can happen in parallel? (parallelization)
8. Where are the risks? (high-impact dependencies)
9. Which tasks cross period boundaries? (spill overs)

If any question is unanswered, **STOP and ask the user.**

**Deliver realistic roadmaps. Respect team capacity. Respect period boundaries. Build trust through accuracy.**

---

## Standards Loading (MANDATORY)

This skill is a delivery planning skill and does NOT require WebFetch of language-specific standards.

**Purpose:** Delivery Planning transforms tasks into realistic schedules. Technical standards are irrelevant at this stage—they apply during implementation via `ring:dev-cycle`.

**However**, MUST load tasks.md (Gate 7) to access AI estimates, dependencies, and scope definitions.

---

## Blocker Criteria - STOP and Report

| Condition | Action | Severity |
|-----------|--------|----------|
| Tasks (Gate 7) not validated | STOP and complete Gate 7 first | CRITICAL |
| Team composition unknown | STOP and ask user for team size | CRITICAL |
| Start date not provided | STOP and ask user for start date | CRITICAL |
| Delivery cadence not selected | STOP and ask user for cadence preference | HIGH |
| Critical path forms circular dependency | STOP and resolve dependency cycle | HIGH |
| All questions not answered | STOP and gather missing inputs | HIGH |

---

## Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST gather ALL mandatory user questions before creating roadmap
- MUST NOT create roadmap without team composition
- MUST NOT assume delivery cadence (must ask user)
- MUST include contingency buffer (10-20%)
- MUST calculate critical path from dependency graph
- MUST identify and document spill overs for sprint/cycle cadences
- MUST use AI estimates from tasks.md (no manual guessing)
- CANNOT commit to dates without capacity analysis

---

## Severity Calibration

| Severity | Definition | Example |
|----------|------------|---------|
| **CRITICAL** | Cannot create roadmap | Tasks not validated, no team composition |
| **HIGH** | Roadmap missing essential elements | No buffer, no critical path, cadence assumed |
| **MEDIUM** | Roadmap incomplete but usable | Missing one risk milestone |
| **LOW** | Minor documentation gaps | Spill over impact not fully detailed |

---

## When This Skill Is Not Needed

- Tasks (Gate 7) not validated → complete task breakdown first
- Proof-of-concept without delivery commitment
- Research/exploration work without deadline
- Planning phase only (no execution planned yet)
- Roadmap already exists and dates are still valid
