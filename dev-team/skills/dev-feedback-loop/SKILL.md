---
name: dev-feedback-loop
description: |
  Development cycle feedback system - calculates assertiveness scores, analyzes prompt
  quality for all agents executed, aggregates cycle metrics, performs root cause analysis
  on failures, and generates improvement reports to docs/feedbacks/cycle-{date}/.

trigger: |
  - After task completion (any gate outcome)
  - After validation approval or rejection
  - At end of development cycle
  - When assertiveness drops below threshold

skip_when: |
  - Task still in progress -> wait for completion
  - Feedback already recorded for this task -> proceed

NOT_skip_when: |
  - "Exploratory/spike work" → ALL work produces learnings. Track metrics for spikes too.
  - "Just experimenting" → Experiments need metrics to measure success. No exceptions.

sequence:
  after: [dev-validation]

related:
  complementary: [dev-cycle, dev-validation]
---

# Dev Feedback Loop

## Overview

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) for canonical validation and gate requirements. This skill collects metrics and generates improvement reports.

Continuous improvement system that tracks development cycle effectiveness through assertiveness scores, identifies recurring failure patterns, and generates actionable improvement suggestions.

**Core principle:** What gets measured gets improved. Track every gate transition to identify systemic issues.

## Step 0: TodoWrite Tracking (MANDATORY FIRST ACTION)

**⛔ HARD GATE: Before ANY other action, you MUST add feedback-loop to todo list.**

**Execute this TodoWrite call IMMEDIATELY when this skill starts:**

```yaml
TodoWrite tool:
  todos:
    - id: "feedback-loop-execution"
      content: "Execute dev-feedback-loop: collect metrics, calculate scores, write report"
      status: "in_progress"
      priority: "high"
```

**Why this is mandatory:**
- TodoWrite creates visible tracking of feedback-loop execution
- Prevents skill from being "forgotten" mid-execution
- Creates audit trail that feedback was collected
- Hook enforcer checks for this todo item

**After completing ALL feedback-loop steps, mark as completed:**

```yaml
TodoWrite tool:
  todos:
    - id: "feedback-loop-execution"
      content: "Execute dev-feedback-loop: collect metrics, calculate scores, write report"
      status: "completed"
      priority: "high"
```

**Anti-Rationalization:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "TodoWrite slows things down" | 1 tool call = 2 seconds. Not an excuse. | **Execute TodoWrite NOW** |
| "I'll remember to complete it" | Memory is unreliable. Todo is proof. | **Execute TodoWrite NOW** |
| "Skill is simple, no tracking needed" | Simple ≠ optional. ALL skills get tracked. | **Execute TodoWrite NOW** |

**You CANNOT proceed to Step 1 without executing TodoWrite above.**

---

## Pressure Resistance

See [shared-patterns/shared-pressure-resistance.md](../shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios.

**Feedback-specific note:** Feedback MUST be collected for EVERY completed task, regardless of outcome or complexity. "Simple tasks" and "perfect scores" still need tracking.

## Common Rationalizations - REJECTED

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

**Feedback-specific rationalizations:**

| Excuse | Reality |
|--------|---------|
| "It was just a spike/experiment" | Spikes produce learnings. Track what worked and what didn't. |
| "Perfect score, no insights" | Perfect scores reveal what works. Document for replication. |
| "Reporting my own failures reflects badly" | Unreported failures compound. Self-reporting is professional. |
| "Round up to passing threshold" | Rounding is falsification. Report exact score. |

## Red Flags - STOP

See [shared-patterns/shared-red-flags.md](../shared-patterns/shared-red-flags.md) for universal red flags.

If you catch yourself thinking ANY of those patterns, STOP immediately. Collect metrics for EVERY task.

## Self-Preservation Bias Prevention

**Agents must report accurately, even when scores are low:**

| Bias Pattern | Why It's Wrong | Correct Behavior |
|-------------|----------------|------------------|
| "Round up score" | Falsifies data, masks trends | Report exact: 68, not 70 |
| "Skip failed task" | Selection bias, incomplete picture | Report ALL tasks |
| "Blame external factors" | Avoids actionable insights | Document factors + still log score |
| "Report only successes" | Survivorship bias | Success AND failure needed |

**Reporting protocol:**
1. Calculate score using exact formula (no rounding)
2. Report score regardless of value
3. If score < 70, mandatory root cause analysis
4. Document honestly - "I made this mistake" not "mistake was made"
5. Patterns in low scores = improvement opportunities, not blame

**Self-interest check:** If you're tempted to adjust a score, ask: "Would I report this score if someone else achieved it?" If yes, report as-is.

## Mandatory Feedback Collection

**Non-negotiable:** Feedback MUST be collected for EVERY completed task, regardless of:

| Factor | Still Collect? | Reason |
|--------|---------------|--------|
| Task complexity | ✅ YES | Simple tasks reveal patterns |
| Outcome quality | ✅ YES | 100-score tasks need tracking |
| User satisfaction | ✅ YES | Approval ≠ process quality |
| Time pressure | ✅ YES | Metrics take <5 min |
| "Nothing to report" | ✅ YES | Absence of issues is data |

**Consequence:** Skipping feedback breaks continuous improvement loop and masks systemic issues.

## Repeated Feedback Detection

**When the same feedback appears multiple times:**

| Repetition | Classification | Action |
|------------|----------------|--------|
| 2nd occurrence | RECURRING | Flag as recurring issue. Add to patterns. |
| 3rd occurrence | UNRESOLVED | Escalate. Stop current work. Report blocker. |

**Recurring feedback indicates systemic issue not being addressed.**

**Escalation format:**
```markdown
## RECURRING ISSUE - Escalation Required

**Issue:** [Description]
**Occurrences:** [Count] times across [N] tasks
**Pattern:** [What triggers this issue]
**Previous Responses:** [What was tried]

**Recommendation:** [Systemic fix needed]
**Awaiting:** User decision on root cause resolution
```

## Threshold Alerts - MANDATORY RESPONSE

**When thresholds are breached, response is REQUIRED:**

| Alert | Threshold | Required Action |
|-------|-----------|-----------------|
| Task score | < 70 | Document what went wrong. Identify root cause. |
| Gate iterations | > 3 | STOP. Request human intervention. Document blocker. |
| Cycle average | < 80 | Deep analysis required. Pattern identification mandatory. |

**You CANNOT proceed past threshold without documented response.**

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Decision Type | Examples | Action |
|--------------|----------|--------|
| **Score interpretation** | "Is 65 acceptable?" | STOP. Follow interpretation table. |
| **Threshold override** | "Skip analysis for this task" | STOP. Analysis is MANDATORY for low scores. |
| **Pattern judgment** | "Is this pattern significant?" | STOP. Document pattern, let user decide significance. |
| **Improvement priority** | "Which fix first?" | STOP. Report all findings, let user prioritize. |

**Before skipping ANY feedback collection:**
1. Check if task is complete (feedback required for ALL completed tasks)
2. Check threshold status (alerts are mandatory)
3. If in doubt → STOP and report blocker

**You CANNOT skip feedback collection. Period.**

## Assertiveness Score Calculation

Base score of 100 points, with deductions for inefficiencies:

### Penalty Matrix

| Event | Penalty | Max Penalty | Rationale |
|-------|---------|-------------|-----------|
| Extra iteration (beyond 1) | -10 per iteration | -30 | Each iteration = rework |
| Review FAIL verdict | -20 | -20 | Critical/High issues found |
| Review NEEDS_DISCUSSION | -10 | -10 | Uncertainty in implementation |
| Unmet criterion at validation | -10 per criterion | -40 | Requirements gap |
| User REJECTED validation | -100 (score = 0) | -100 | Complete failure |

### Score Calculation Formula

`score = 100 - min(30, extra_iterations*10) - review_fail*20 - needs_discussion*10 - min(40, unmet_criteria*10)` | User rejected → score = 0

### Score Interpretation

| Score Range | Rating | Action Required |
|-------------|--------|-----------------|
| 90-100 | Excellent | No action needed |
| 80-89 | Good | Minor improvements possible |
| 70-79 | Acceptable | Review patterns, optimize |
| 60-69 | Needs Improvement | Root cause analysis required |
| < 60 | Poor | Mandatory deep analysis |
| 0 | Failed | Full post-mortem required |

## Step 1: Collect Cycle Metrics

**MANDATORY: Execute this step for ALL tasks, regardless of:**
- Score value (even 100%)
- User satisfaction (even immediate approval)
- Outcome quality (even perfect)

**Anti-exemption check:**
If you're thinking "perfect outcome, skip metrics" → STOP. This is Red Flag at line 75 ("Perfect outcome, skip the metrics").

**After task completion, gather:** Gate transitions (gate, iterations, duration, outcome for each Gate 0-5), Review findings (per reviewer verdict + issues), Validation outcome (criteria verified, decision, notes)

## Step 2: Calculate Assertiveness Score

**Apply formula:** Base 100 - deductions (extra iterations, review failures, unmet criteria) = Final Score / 100. Map to rating per interpretation table.

## Step 3: Analyze Prompt Quality (Agents Only)

After calculating assertiveness, analyze prompt quality for all **agents** that executed in the task.

### 3.1 Load Agent Outputs

Read `agent_outputs` from `docs/refactor/current-cycle.json`:

```text
Agents to analyze (if executed, not null):
  - implementation: backend-engineer-golang | backend-engineer-typescript
  - devops: devops-engineer
  - sre: sre
  - testing: qa-analyst
  - review: code-reviewer, business-logic-reviewer, security-reviewer
```

### 3.2 Dispatch Prompt Quality Reviewer

```text
Task tool:
  subagent_type: "prompt-quality-reviewer"
  prompt: |
    Analyze prompt quality for agents in task [task_id].

    Agent outputs from state:
    [agent_outputs]

    For each agent:
    1. Load definition from dev-team/agents/ or default/agents/
    2. Extract rules: MUST, MUST NOT, ask_when, output_schema
    3. Compare output vs rules
    4. Calculate score
    5. Identify gaps with evidence
    6. Generate improvements

    Return structured analysis per agent.
```

### 3.3 Write Feedback Files

**Directory:** `docs/feedbacks/cycle-YYYY-MM-DD/`

**One file per agent**, accumulating all tasks that used that agent.

**File:** `docs/feedbacks/cycle-YYYY-MM-DD/{agent-name}.md`

```markdown
# Prompt Feedback: {agent-name}

**Cycle:** YYYY-MM-DD
**Total Executions:** N
**Average Score:** XX%

---

## Task T-001 (Gate X)

**Score:** XX/100
**Rating:** {rating}

### Gaps Found

| Category | Rule | Evidence | Impact |
|----------|------|----------|--------|
| MUST | [rule text] | [quote from output] | -X |

### What Went Well

- [positive observation]

---

## Task T-002 (Gate X)

**Score:** XX/100
...

---

## Consolidated Improvements

### Priority 1: [Title]

**Occurrences:** X/Y tasks
**Impact:** +X points expected
**File:** dev-team/agents/{agent}.md

**Current text (line ~N):**
```
[existing prompt]
```

**Suggested addition:**
```markdown
[new prompt text]
```

### Priority 2: [Title]
...
```

### 3.4 Append to Existing File

If file already exists (from previous task in same cycle), **append** the new task section before "## Consolidated Improvements" and update:
- Total Executions count
- Average Score
- Consolidated Improvements (re-analyze patterns)

## Step 4: Threshold Alerts

| Alert | Trigger | Action | Report Contents |
|-------|---------|--------|-----------------|
| **Score < 70** | Individual task assertiveness < 70 | Mandatory root cause analysis | Failure events, "5 Whys" per event, Corrective actions, Prevention measures |
| **Iterations > 3** | Any gate exceeds 3 iterations | STOP + human intervention | Iteration history, Recurring issue, Options: [Continue/Reassign/Descope/Cancel] |
| **Avg < 80** | Cycle average below 80 | Deep analysis report | Score distribution, Failure patterns (freq/cause/fix), Improvement plan |

**Report formats:** RCA = Score → Failure Events → 5 Whys → Root cause → Corrective action | Gate Blocked = History → Issue → BLOCKED UNTIL human decision | Deep Analysis = Distribution → Patterns → Improvement Plan

## Step 5: Write Feedback Report

**Location:** `.ring/dev-team/feedback/cycle-YYYY-MM-DD.md`

**Required sections:**

| Section | Content |
|---------|---------|
| **Header** | Date, Tasks Completed, Average Assertiveness |
| **Task Summary** | Table: Task ID, Score, Rating, Key Issue |
| **By Gate** | Table: Gate, Avg Iterations, Avg Duration, Pass Rate |
| **By Penalty** | Table: Penalty type, Occurrences, Points Lost |
| **Patterns** | Positive patterns (what works) + Negative patterns (what needs improvement) |
| **Recommendations** | Immediate (this sprint), Short-term (this month), Long-term (this quarter) |
| **Next Review** | Date, Target assertiveness, Focus areas |

## Step 6: Generate Improvement Suggestions

**Improvement types based on pattern analysis:**

| Target | When to Suggest | Format |
|--------|-----------------|--------|
| **Agents** | Same issue type recurring in reviews | Agent name → Issue → Suggestion → Specific addition to prompt |
| **Skills** | Gate consistently needs iterations | Skill name → Issue → Suggestion → Specific change to skill |
| **Process** | Pattern spans multiple tasks | Process area → Issue → Suggestion → Implementation |

## Step 7: Complete TodoWrite Tracking (MANDATORY FINAL ACTION)

**⛔ HARD GATE: After ALL steps complete, you MUST mark feedback-loop todo as completed.**

**Execute this TodoWrite call to finalize:**

```yaml
TodoWrite tool:
  todos:
    - id: "feedback-loop-execution"
      content: "Execute dev-feedback-loop: collect metrics, calculate scores, write report"
      status: "completed"
      priority: "high"
```

**Verification before marking complete:**
- [ ] Step 1: Metrics collected from state file
- [ ] Step 2: Assertiveness score calculated
- [ ] Step 3: Prompt quality analyzed (if agents executed)
- [ ] Step 4: Threshold alerts checked
- [ ] Step 5: Feedback report written to `.ring/dev-team/feedback/`
- [ ] Step 6: Improvement suggestions generated

**You CANNOT mark todo as completed until ALL steps above are done.**

---

## Execution Report

| Metric | Value |
|--------|-------|
| Tasks Analyzed | N |
| Average Assertiveness | XX.X% |
| Threshold Alerts | X |
| Root Cause Analyses | Y |
| Improvement Suggestions | Z |
| Report Location | .ring/dev-team/feedback/cycle-YYYY-MM-DD.md |

## Anti-Patterns

**Never:**
- Skip feedback collection for "simple" tasks
- Ignore threshold alerts
- Accept low scores without analysis
- Generate suggestions without data
- Blame individuals instead of process

**Always:**
- Track every gate transition
- Calculate score for every task
- Investigate scores < 70
- Document root causes
- Generate actionable improvements
- Review trends over time

## Feedback Loop Integration

| Integration | Process |
|-------------|---------|
| **Retrospectives** | Share metrics → Discuss trends → Prioritize improvements → Assign actions |
| **Skill Updates** | Document gap → Update skill → Track improvement → Iterate |
| **Agent Updates** | Identify behavior → Update prompt → Track change → Validate |
