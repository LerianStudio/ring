---
name: launch-execution
description: |
  Launch coordination skill for managing launch checklists, stakeholder alignment,
  and day-of execution for product and feature launches.

trigger: |
  - GTM plan complete, ready to execute
  - Launch date approaching
  - User requests "launch checklist" or "launch coordination"

skip_when: |
  - GTM planning not done → complete gtm-planning first
  - Still in strategy phase → use gtm-planning
  - Post-launch analysis → different skill
---

# Launch Execution

Launch coordination including checklists, stakeholder alignment, and day-of execution management.

## Purpose

Launch execution ensures smooth transition from planning to market:
- Coordinates all stakeholders and dependencies
- Manages pre-launch checklist completion
- Orchestrates day-of activities
- Establishes post-launch monitoring

**HARD GATE:** GTM plan MUST be completed before launch execution.

## Process

### Phase 1: Launch Readiness Assessment

Evaluate launch prerequisites:

```markdown
## Launch Readiness Assessment

### GTM Prerequisites
| Prerequisite | Status | Owner | Notes |
|--------------|--------|-------|-------|
| Market Analysis Complete | DONE/IN PROGRESS/NOT STARTED | [Owner] | [Link] |
| Positioning Approved | DONE/IN PROGRESS/NOT STARTED | [Owner] | [Link] |
| Messaging Framework Final | DONE/IN PROGRESS/NOT STARTED | [Owner] | [Link] |
| Pricing Approved | DONE/IN PROGRESS/NOT STARTED | [Owner] | [Link] |
| GTM Plan Approved | DONE/IN PROGRESS/NOT STARTED | [Owner] | [Link] |

### Product Prerequisites
| Prerequisite | Status | Owner | Notes |
|--------------|--------|-------|-------|
| Product/Feature Ready | DONE/IN PROGRESS/NOT STARTED | [Owner] | [Version] |
| QA Complete | DONE/IN PROGRESS/NOT STARTED | [Owner] | [Sign-off] |
| Documentation Ready | DONE/IN PROGRESS/NOT STARTED | [Owner] | [Link] |
| Support Trained | DONE/IN PROGRESS/NOT STARTED | [Owner] | [Date] |

### Readiness Score
| Category | Score | Threshold | Status |
|----------|-------|-----------|--------|
| GTM Readiness | X/Y | Y | GO/NO-GO |
| Product Readiness | X/Y | Y | GO/NO-GO |
| Sales Readiness | X/Y | Y | GO/NO-GO |
| Ops Readiness | X/Y | Y | GO/NO-GO |
| **OVERALL** | **X/Y** | **Y** | **GO/NO-GO** |
```

### Phase 2: Pre-Launch Checklist

Complete checklist by category:

```markdown
## Pre-Launch Checklist

### Marketing Assets (Due: T-14 days)
- [ ] Website updates staged
- [ ] Landing pages live (in stealth if needed)
- [ ] Email sequences loaded
- [ ] Social media posts scheduled
- [ ] Press release approved
- [ ] Blog posts drafted
- [ ] Paid media campaigns created
- [ ] Launch video/demo complete

### Sales Enablement (Due: T-7 days)
- [ ] Sales deck updated
- [ ] Product demo environment ready
- [ ] Pricing sheet updated
- [ ] FAQ document complete
- [ ] Competitive battlecards updated
- [ ] Sales team briefed
- [ ] First-call script updated
- [ ] Commission/compensation updated (if applicable)

### Customer Success (Due: T-7 days)
- [ ] Support documentation updated
- [ ] Knowledge base articles published
- [ ] Support team trained
- [ ] Escalation paths defined
- [ ] Customer communication drafted
- [ ] Onboarding materials updated

### Technical (Due: T-3 days)
- [ ] Feature flags configured
- [ ] Monitoring dashboards ready
- [ ] Rollback plan documented
- [ ] Performance baseline established
- [ ] Security review complete

### Legal/Compliance (Due: T-7 days)
- [ ] Terms of service updated (if needed)
- [ ] Privacy policy updated (if needed)
- [ ] Compliance requirements met
- [ ] Contract templates updated

### Communications (Due: T-1 day)
- [ ] Internal announcement drafted
- [ ] Customer announcement drafted
- [ ] Partner notification drafted
- [ ] Press contacts briefed
- [ ] Social media team briefed
```

### Phase 3: Stakeholder Alignment

Ensure all stakeholders are aligned:

```markdown
## Stakeholder Alignment

### RACI Matrix
| Activity | Responsible | Accountable | Consulted | Informed |
|----------|-------------|-------------|-----------|----------|
| Go/No-Go Decision | [Name] | [Name] | [Names] | [Names] |
| Launch Day Execution | [Name] | [Name] | [Names] | [Names] |
| Customer Communications | [Name] | [Name] | [Names] | [Names] |
| Escalation Response | [Name] | [Name] | [Names] | [Names] |

### Communication Plan
| Audience | Message | Channel | Timing | Owner |
|----------|---------|---------|--------|-------|
| Internal Team | [Key points] | [Channel] | [When] | [Owner] |
| Sales Team | [Key points] | [Channel] | [When] | [Owner] |
| Customers | [Key points] | [Channel] | [When] | [Owner] |
| Partners | [Key points] | [Channel] | [When] | [Owner] |
| Press | [Key points] | [Channel] | [When] | [Owner] |

### Escalation Matrix
| Issue Type | Level 1 | Level 2 | Level 3 |
|------------|---------|---------|---------|
| Technical | [Name] | [Name] | [Name] |
| Customer | [Name] | [Name] | [Name] |
| PR/Comms | [Name] | [Name] | [Name] |
| Executive | [Name] | [Name] | [Name] |
```

### Phase 4: Day-of Execution Plan

Orchestrate launch day:

```markdown
## Day-of Execution Plan

### Launch Day Timeline
| Time | Activity | Owner | Status |
|------|----------|-------|--------|
| 06:00 | [Pre-launch check] | [Owner] | PENDING |
| 07:00 | [Activity] | [Owner] | PENDING |
| 08:00 | [Feature flip] | [Owner] | PENDING |
| 09:00 | [Public announcement] | [Owner] | PENDING |
| 10:00 | [PR embargo lifts] | [Owner] | PENDING |
| 12:00 | [Social media push] | [Owner] | PENDING |
| 14:00 | [Check-in meeting] | [Owner] | PENDING |
| 17:00 | [End-of-day review] | [Owner] | PENDING |

### War Room Setup
**Location/Channel:** [Physical room or Slack channel]
**Participants:**
- [Name]: [Role]
- [Name]: [Role]
- [Name]: [Role]

**Communication Cadence:**
- Hourly status updates
- Immediate escalation for blockers
- EOD summary

### Rollback Triggers
| Trigger | Threshold | Action |
|---------|-----------|--------|
| Error rate | >X% | [Specific rollback action] |
| Customer complaints | >X in Y minutes | [Escalation action] |
| System down | Any duration | [Immediate action] |

### Success Metrics (Day 1)
| Metric | Target | Tracking Location |
|--------|--------|-------------------|
| [Metric 1] | [Target] | [Dashboard/Tool] |
| [Metric 2] | [Target] | [Dashboard/Tool] |
| [Metric 3] | [Target] | [Dashboard/Tool] |
```

### Phase 5: Post-Launch Monitoring

Establish monitoring cadence:

```markdown
## Post-Launch Monitoring

### Monitoring Schedule
| Timeframe | Focus | Meeting/Review | Owner |
|-----------|-------|----------------|-------|
| Day 1 | Issues, initial metrics | War room | [Owner] |
| Day 2-3 | Stabilization, feedback | Daily standup | [Owner] |
| Week 1 | Early adoption, bugs | Weekly review | [Owner] |
| Week 2-4 | Trends, optimization | Weekly review | [Owner] |
| 30-Day | Launch retrospective | Full review | [Owner] |

### Metrics Dashboard
| Metric | Target | Day 1 | Day 7 | Day 30 |
|--------|--------|-------|-------|--------|
| [Metric 1] | [Target] | [Actual] | [Actual] | [Actual] |
| [Metric 2] | [Target] | [Actual] | [Actual] | [Actual] |
| [Metric 3] | [Target] | [Actual] | [Actual] | [Actual] |

### Feedback Collection
| Source | Method | Owner | Frequency |
|--------|--------|-------|-----------|
| Sales | [Feedback channel] | [Owner] | [Cadence] |
| Support | [Feedback channel] | [Owner] | [Cadence] |
| Customers | [Survey/interviews] | [Owner] | [Cadence] |
| Social | [Monitoring tool] | [Owner] | [Cadence] |

### Retrospective Questions
1. What went well?
2. What didn't go well?
3. What should we do differently next time?
4. What surprised us?
5. What would we repeat?
```

## Output Format

```markdown
# Launch Plan: [Product/Feature]

## Executive Summary
- **Launch Date:** [Date]
- **Launch Type:** [Tier 1/2/3]
- **Go/No-Go Status:** [GO/NO-GO/PENDING]
- **Launch Owner:** [Name]

## Readiness Assessment
[Phase 1 output]

## Pre-Launch Checklist
[Phase 2 output]

## Stakeholder Alignment
[Phase 3 output]

## Day-of Execution
[Phase 4 output]

## Post-Launch Monitoring
[Phase 5 output]

## Dependencies
- GTM Plan: [Link to gtm-plan.md]
- Messaging: [Link to messaging-framework.md]
- Product Release: [Link or version]
```

## Blocker Criteria

| Blocker | Action |
|---------|--------|
| GTM plan not approved | STOP. Cannot execute without approved plan. |
| Product not ready | STOP. Escalate to product team. |
| Readiness score below threshold | STOP. Address gaps before proceeding. |
| Key stakeholder unavailable | STOP. Reschedule or delegate authority. |

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Gate-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We can skip the checklist" | Skipped items cause launch failures | **Complete every checklist item** |
| "Everyone knows their role" | Assumptions cause coordination failures | **Document RACI explicitly** |
| "We'll handle issues as they come" | Reactive handling causes escalation | **Pre-define escalation paths** |
| "Rollback won't be needed" | Every launch needs rollback plan | **Document rollback triggers** |

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Gate-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Launch with checklist gaps" | "We can fix it post-launch" | "Gaps cause launch failures. Completing checklist or delaying." |
| "Skip the war room" | "It's overkill for this launch" | "War room enables rapid response. Setting up coordination." |
| "We don't need rollback" | "We tested thoroughly" | "Testing ≠ zero issues. Documenting rollback plan." |

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Gate-Specific Details
- checklist_items_complete: X/Y
- stakeholders_aligned: YES/NO
- go_nogo_decision: GO/NO-GO/PENDING
- materials_ready: X/Y
- rollback_plan_documented: YES/NO
