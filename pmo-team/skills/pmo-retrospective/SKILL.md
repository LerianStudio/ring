---
name: pmo-retrospective
description: |
  Portfolio retrospective skill for capturing lessons learned, process improvements,
  and organizational learning across completed projects.

trigger: |
  - Project closure requiring retrospective
  - Portfolio period review (quarterly/annual)
  - Process improvement initiative
  - Pattern of issues recurring

skip_when: |
  - Sprint retrospective → team-level, not PMO
  - Technical post-mortem → use ring-dev-team
  - Single incident analysis → handle in project scope

related:
  complementary: [portfolio-planning, project-health-check]
---

# PMO Retrospective Skill

Systematic capture and application of lessons learned at portfolio level.

## Purpose

This skill provides a framework for:
- Lessons learned capture
- Pattern identification
- Process improvement
- Organizational learning
- Knowledge transfer

---

## Retrospective Types

### Type 1: Project Closure Retrospective

**Trigger:** Project completion or termination
**Scope:** Single project
**Participants:** Project team, sponsor, key stakeholders

---

### Type 2: Portfolio Period Review

**Trigger:** Quarterly or annual review
**Scope:** All projects in period
**Participants:** PMO, project managers, executives

---

### Type 3: Thematic Retrospective

**Trigger:** Recurring pattern observed
**Scope:** Projects sharing the pattern
**Participants:** Affected project managers, PMO, subject matter experts

---

## Retrospective Gates

### Gate 1: Context Setting

**Objective:** Establish retrospective scope and participants

**Actions:**
1. Define retrospective type and scope
2. Identify participants
3. Gather project data
4. Schedule sessions

**Context Template:**

| Element | Value |
|---------|-------|
| Type | Project/Portfolio/Thematic |
| Scope | [Projects/Period] |
| Participants | [List] |
| Data Sources | [List] |

**Output:** `docs/pmo/{date}/retro-context.md`

---

### Gate 2: Data Collection

**Objective:** Gather objective data about performance

**Actions:**
1. Collect final project metrics
2. Gather variance explanations
3. Document scope changes
4. Compile risk/issue history

**Data Points:**

| Category | Data |
|----------|------|
| Schedule | Planned vs actual duration |
| Cost | Budget vs actual spend |
| Scope | Baseline vs final scope |
| Quality | Defects, rework |
| Risks | Risks that materialized |
| Changes | Number and impact |

**Output:** `docs/pmo/{date}/retro-data.md`

---

### Gate 3: Reflection

**Objective:** Identify what worked, what didn't, and why

**Actions:**
1. Conduct retrospective session
2. Identify successes to repeat
3. Identify failures to prevent
4. Analyze root causes

**Reflection Framework:**

| Category | Question |
|----------|----------|
| **What went well?** | What should we keep doing? |
| **What didn't go well?** | What should we stop doing? |
| **What was confusing?** | What needs clarification? |
| **What was missing?** | What should we start doing? |
| **What surprised us?** | What assumptions were wrong? |

**Output:** `docs/pmo/{date}/retro-reflection.md`

---

### Gate 4: Pattern Analysis

**Objective:** Identify patterns across projects/time

**Actions:**
1. Compare with previous retrospectives
2. Identify recurring themes
3. Assess systemic vs isolated issues
4. Prioritize improvement areas

**Pattern Types:**

| Type | Indicator | Action |
|------|-----------|--------|
| **Systemic** | Same issue in 3+ projects | Process change required |
| **Capability** | Same team struggle repeating | Training/hiring needed |
| **Tool** | Tool-related friction | Tool improvement/replacement |
| **Communication** | Stakeholder issues recurring | Communication improvement |
| **Estimation** | Consistent over/under estimation | Estimation process improvement |

**Output:** `docs/pmo/{date}/retro-patterns.md`

---

### Gate 5: Action Planning

**Objective:** Create actionable improvement plan

**Actions:**
1. Define specific improvements
2. Assign owners
3. Set timelines
4. Define success criteria

**Action Template:**

| Improvement | Owner | Timeline | Success Criteria | Status |
|-------------|-------|----------|------------------|--------|
| [Improvement] | [Owner] | [Date] | [Criteria] | [Status] |

**Priority Framework:**

| Impact / Effort | Low Effort | High Effort |
|-----------------|------------|-------------|
| **High Impact** | Do First | Plan Carefully |
| **Low Impact** | Quick Wins | Don't Do |

**Output:** `docs/pmo/{date}/retro-actions.md`

---

### Gate 6: Knowledge Sharing

**Objective:** Distribute lessons to organization

**Actions:**
1. Document lessons learned
2. Update PMO knowledge base
3. Present to relevant teams
4. Update templates/processes

**Knowledge Sharing Channels:**

| Channel | Audience | Content |
|---------|----------|---------|
| PMO Wiki | All PMs | Full lessons |
| Newsletter | Organization | Summary |
| Training | New PMs | Incorporated |
| Templates | All projects | Updated |
| Playbooks | Specific scenarios | Detailed guidance |

**Output:** `docs/pmo/{date}/lessons-learned.md`

---

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Retrospective-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We're too busy for retrospectives" | Learning gaps cost more than retrospective time. | **Schedule and conduct retrospective** |
| "We know what went wrong" | Assumptions miss root causes. | **Formal analysis required** |
| "It was a unique situation" | Patterns hide in "unique" situations. | **Document and compare** |
| "People will be defensive" | Blame-free culture enables learning. | **Focus on process, not people** |
| "Lessons will be ignored anyway" | Track action completion to ensure learning. | **Follow up on actions** |

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Retrospective-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Skip retro, team already on next project" | "Learning before moving on prevents repeating mistakes. Conducting abbreviated retrospective." |
| "Don't document that failure" | "Failures are learning opportunities. Documenting with constructive framing." |
| "Just move on, it's in the past" | "Past informs future. Retrospective protects future projects." |

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Situation | Required Action |
|-----------|-----------------|
| Key participants unavailable | STOP. Incomplete retrospective misses perspectives. Reschedule. |
| Data unavailable | STOP. Data-free retrospective is opinion session. Get data. |
| Blame culture emerging | STOP. Reset to blameless framework. Not about individuals. |
| No action ownership | STOP. Lessons without owners become forgotten. Assign owners. |

---

## Output Format

### Lessons Learned Report

```markdown
# Lessons Learned - [Project/Period] - [Date]

## Context

| Element | Value |
|---------|-------|
| Scope | [Project(s)/Period] |
| Participants | [List] |
| Facilitator | [Name] |

## Performance Summary

| Metric | Target | Actual | Variance |
|--------|--------|--------|----------|
| Duration | X months | X months | +/- X% |
| Budget | $X | $X | +/- X% |
| Scope | X features | X features | +/- X |
| Quality | X defects | X defects | +/- X |

## What Went Well

| Success | Why It Worked | How to Repeat |
|---------|---------------|---------------|
| [Success] | [Root cause] | [Action to sustain] |

## What Didn't Go Well

| Issue | Root Cause | How to Prevent |
|-------|------------|----------------|
| [Issue] | [Root cause] | [Action to prevent] |

## Patterns Identified

| Pattern | Frequency | Systemic? | Action |
|---------|-----------|-----------|--------|
| [Pattern] | X occurrences | Yes/No | [Action] |

## Improvement Actions

| # | Improvement | Owner | Due | Status |
|---|-------------|-------|-----|--------|
| 1 | [Improvement] | [Owner] | [Date] | [Status] |

## Key Lessons (Top 5)

1. **[Lesson Title]:** [Description and application guidance]
2. **[Lesson Title]:** [Description and application guidance]
3. **[Lesson Title]:** [Description and application guidance]
4. **[Lesson Title]:** [Description and application guidance]
5. **[Lesson Title]:** [Description and application guidance]

## Knowledge Sharing Plan

| Audience | Channel | Date | Owner |
|----------|---------|------|-------|
| [Audience] | [Channel] | [Date] | [Owner] |
```

---

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Analysis Date | YYYY-MM-DD |
| Scope | [Project(s)/Period] |
| Duration | Xh Ym |
| Result | COMPLETE/PARTIAL/BLOCKED |

### Retrospective-Specific Details

| Metric | Value |
|--------|-------|
| period_covered | [Description] |
| projects_completed | N |
| lessons_captured | N |
| process_improvements | N |
