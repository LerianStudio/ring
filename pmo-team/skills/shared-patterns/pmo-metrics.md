# PMO Metrics Reference

This file defines standard PMO metrics used across all pmo-team skills and agents.

## Portfolio Health Metrics

### Overall Portfolio Score

| Component | Weight | Calculation |
|-----------|--------|-------------|
| Schedule Performance | 25% | Average SPI across projects |
| Cost Performance | 25% | Average CPI across projects |
| Quality Index | 20% | Defect rates, rework % |
| Risk Exposure | 15% | Weighted risk score |
| Resource Utilization | 15% | Capacity vs allocation |

**Score Interpretation:**
- 90-100: Excellent - Portfolio performing optimally
- 75-89: Good - Minor issues, manageable
- 60-74: Concerning - Intervention needed
- Below 60: Critical - Immediate action required

### Project Status Definitions

| Status | Criteria | Action |
|--------|----------|--------|
| **Green** | On track: SPI/CPI >= 0.95, No critical risks, Stakeholders satisfied | Continue monitoring |
| **Yellow** | At risk: SPI/CPI 0.85-0.94, OR High risks materializing, OR Stakeholder concerns | Increase oversight, develop recovery plan |
| **Red** | Off track: SPI/CPI < 0.85, OR Critical risks materialized, OR Major stakeholder issues | Escalate, immediate intervention |

---

## Resource Metrics

### Utilization Thresholds

| Level | Percentage | Interpretation |
|-------|------------|----------------|
| Under-utilized | < 70% | Capacity available, may indicate scope/priority issues |
| Optimal | 70-85% | Healthy utilization with buffer for issues |
| Fully utilized | 85-95% | High productivity, limited flexibility |
| Over-allocated | > 95% | Unsustainable, burnout risk, quality impact |

### Capacity Planning Horizon

| Horizon | Detail Level | Update Frequency |
|---------|--------------|------------------|
| Current Sprint | Task-level | Daily |
| Next 30 days | Story-level | Weekly |
| Next Quarter | Epic-level | Bi-weekly |
| Next 6 months | Initiative-level | Monthly |
| Annual | Portfolio-level | Quarterly |

---

## Risk Metrics

### Risk Severity Matrix

| Impact / Likelihood | Low (1-2) | Medium (3) | High (4-5) |
|---------------------|-----------|------------|------------|
| **High (4-5)** | Medium | High | Critical |
| **Medium (3)** | Low | Medium | High |
| **Low (1-2)** | Low | Low | Medium |

### Risk Response Types

| Response | When to Use | Example |
|----------|-------------|---------|
| **Avoid** | Risk is unacceptable, can change scope | Remove feature with security risk |
| **Transfer** | Risk better managed by others | Insurance, outsource to specialist |
| **Mitigate** | Reduce probability or impact | Add testing, redundancy |
| **Accept** | Cost of mitigation > risk impact | Document and monitor |

### RAID Log Categories

| Category | Contents | Review Frequency |
|----------|----------|------------------|
| **R**isks | Potential future issues | Weekly |
| **A**ssumptions | Believed true, not verified | At milestones |
| **I**ssues | Current problems requiring action | Daily |
| **D**ependencies | External inputs/outputs | Weekly |

---

## Schedule Metrics

### Earned Value Metrics

| Metric | Formula | Healthy Range |
|--------|---------|---------------|
| **SPI** (Schedule Performance Index) | EV / PV | 0.95 - 1.10 |
| **CPI** (Cost Performance Index) | EV / AC | 0.95 - 1.10 |
| **SV** (Schedule Variance) | EV - PV | >= 0 |
| **CV** (Cost Variance) | EV - AC | >= 0 |
| **EAC** (Estimate at Completion) | BAC / CPI | Within 10% of budget |
| **TCPI** (To-Complete Performance Index) | (BAC - EV) / (BAC - AC) | < 1.10 |

### Milestone Health

| Indicator | Definition |
|-----------|------------|
| On Track | Milestone completion date unchanged or earlier |
| At Risk | Completion date slipped < 10%, recovery plan exists |
| Delayed | Completion date slipped >= 10%, requires rebaselining |
| Missed | Milestone date passed without completion |

---

## Governance Metrics

### Gate Compliance

| Gate | Required Artifacts | Approval Authority |
|------|-------------------|-------------------|
| **Initiation** | Business case, charter | Sponsor |
| **Planning** | Schedule, budget, risk register | PMO + Sponsor |
| **Execution** | Status reports, change requests | PM + PMO |
| **Closure** | Lessons learned, handover docs | PMO + Sponsor |

### Change Control Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Change requests per month | < 5 | > 8 |
| Approval cycle time | < 5 days | > 10 days |
| Approved vs rejected ratio | Document trend | Significant shift |
| Scope creep index | < 10% | > 15% |

---

## How to Reference This File

**For Agents and Skills:**
```markdown
## Metrics Reference

See [shared-patterns/pmo-metrics.md](../shared-patterns/pmo-metrics.md) for:
- Portfolio health scoring
- Resource utilization thresholds
- Risk severity matrix
- Earned value calculations
- Governance metrics

Use these standard definitions in all PMO analysis and reporting.
```
