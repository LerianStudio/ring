# Governance Gates Reference

This file defines the standard governance gates used by all pmo-team agents and skills.

## Project Lifecycle Gates

### Gate 0: Ideation

**Purpose:** Validate project idea has merit for further investigation

| Checkpoint | Required Evidence | Decision |
|------------|------------------|----------|
| Strategic alignment | Link to strategic objective | PASS/FAIL |
| Preliminary feasibility | High-level assessment | PASS/FAIL |
| Sponsor identified | Named executive sponsor | PASS/FAIL |

**Exit Criteria:** All checkpoints PASS → Proceed to Gate 1

---

### Gate 1: Initiation

**Purpose:** Approve project start with defined scope and resources

| Checkpoint | Required Evidence | Decision |
|------------|------------------|----------|
| Business case | ROI, benefits, costs | PASS/CONDITIONAL/FAIL |
| Project charter | Scope, objectives, constraints | PASS/CONDITIONAL/FAIL |
| Stakeholder register | Key stakeholders identified | PASS/FAIL |
| Resource availability | Confirmed resource commitment | PASS/CONDITIONAL/FAIL |
| Initial risk assessment | Top 5 risks identified | PASS/FAIL |

**Exit Criteria:** No FAIL, max 2 CONDITIONAL with remediation plan → Proceed to Gate 2

---

### Gate 2: Planning Complete

**Purpose:** Approve detailed plan before execution begins

| Checkpoint | Required Evidence | Decision |
|------------|------------------|----------|
| Detailed schedule | WBS, milestones, dependencies | PASS/CONDITIONAL/FAIL |
| Budget baseline | Cost breakdown, contingency | PASS/CONDITIONAL/FAIL |
| Quality plan | Quality criteria, testing approach | PASS/CONDITIONAL/FAIL |
| Risk management plan | Risk register, response plans | PASS/CONDITIONAL/FAIL |
| Communication plan | Stakeholder communication matrix | PASS/FAIL |
| Change control process | Defined process and thresholds | PASS/FAIL |

**Exit Criteria:** No FAIL, max 2 CONDITIONAL with remediation plan → Proceed to Execution

---

### Gate 3: Execution Checkpoints (Recurring)

**Purpose:** Validate project remains on track during execution

| Checkpoint | Required Evidence | Frequency |
|------------|------------------|-----------|
| Status report | Schedule, cost, scope, risks | Weekly |
| Milestone review | Deliverable acceptance | At milestone |
| Change request review | Impact analysis, approval | As needed |
| Risk review | Updated register, new risks | Weekly |
| Stakeholder feedback | Satisfaction, concerns | Bi-weekly |

**Escalation Triggers:**
- SPI or CPI < 0.90
- Critical risk materialized
- Scope change > 10%
- Stakeholder escalation

---

### Gate 4: Pre-Closure

**Purpose:** Validate deliverables ready for handover

| Checkpoint | Required Evidence | Decision |
|------------|------------------|----------|
| Deliverable acceptance | Sign-off from stakeholders | PASS/FAIL |
| Quality verification | Test results, defect status | PASS/CONDITIONAL/FAIL |
| Documentation complete | User guides, technical docs | PASS/CONDITIONAL/FAIL |
| Training complete | Training records | PASS/CONDITIONAL/FAIL |
| Support transition | Support plan, handover | PASS/CONDITIONAL/FAIL |

**Exit Criteria:** No FAIL, max 1 CONDITIONAL with timeline → Proceed to Gate 5

---

### Gate 5: Closure

**Purpose:** Formally close project and capture lessons

| Checkpoint | Required Evidence | Decision |
|------------|------------------|----------|
| Financial closure | Final costs, variance analysis | PASS/FAIL |
| Contract closure | Vendor/contractor sign-off | PASS/FAIL |
| Lessons learned | Documented and shared | PASS/FAIL |
| Benefits baseline | Measurement plan for benefits | PASS/CONDITIONAL/FAIL |
| Archive complete | All artifacts archived | PASS/FAIL |

**Exit Criteria:** All PASS or CONDITIONAL addressed → Project CLOSED

---

## Portfolio Governance Gates

### Portfolio Intake

**Purpose:** Evaluate new project requests against portfolio criteria

| Criterion | Weight | Scoring |
|-----------|--------|---------|
| Strategic alignment | 30% | 1-5 scale |
| Resource availability | 25% | 1-5 scale |
| Risk profile | 20% | 1-5 scale |
| Financial viability | 15% | 1-5 scale |
| Dependencies | 10% | 1-5 scale |

**Intake Decision:**
- Score >= 4.0: Approve for planning
- Score 3.0-3.9: Conditional approval, address gaps
- Score < 3.0: Defer or reject

### Portfolio Rebalancing

**Triggers for Portfolio Review:**
- Quarterly scheduled review
- Major strategic change
- Significant resource constraint
- Multiple project escalations
- Budget reallocation needed

**Rebalancing Options:**

| Option | When to Use | Impact |
|--------|-------------|--------|
| **Accelerate** | High strategic value, resources available | Increase investment |
| **Continue** | On track, resources sufficient | Maintain current state |
| **Decelerate** | Lower priority, resource pressure | Reduce investment |
| **Pause** | Temporary constraints, value remains | Hold for later |
| **Terminate** | No longer viable or valuable | Cancel and release resources |

---

## Gate Decision Authority

| Gate Type | Decision Maker | Escalation Path |
|-----------|----------------|-----------------|
| Project initiation | Sponsor + PMO | Executive Committee |
| Planning approval | PMO | Sponsor |
| Execution checkpoint | PM | PMO |
| Scope/budget change < 10% | PM + Sponsor | PMO |
| Scope/budget change >= 10% | PMO + Sponsor | Executive Committee |
| Project closure | PMO + Sponsor | Executive Committee (if disputed) |
| Portfolio rebalancing | PMO | Executive Committee |

---

## How to Reference This File

**For Agents and Skills:**
```markdown
## Governance Gates Reference

See [shared-patterns/governance-gates.md](../shared-patterns/governance-gates.md) for:
- Project lifecycle gates (0-5)
- Portfolio governance gates
- Gate checkpoint requirements
- Decision authority matrix

Use these standard gates in all governance assessments.
```
