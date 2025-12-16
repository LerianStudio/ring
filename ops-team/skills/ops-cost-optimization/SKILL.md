---
name: ops-cost-optimization
description: |
  Structured workflow for cloud cost analysis and optimization including
  rightsizing, reserved capacity planning, and FinOps practices.

trigger: |
  - Monthly/quarterly cost reviews
  - Cost anomaly investigation
  - Budget overrun alerts
  - Reserved instance planning

skip_when: |
  - Capacity planning focus -> use ops-capacity-planning
  - One-time cost question -> direct query
  - Application performance -> use ring-dev-team specialists

related:
  similar: [ops-capacity-planning]
  uses: [cloud-cost-optimizer]
---

# Cost Optimization Workflow

This skill defines the structured process for cloud cost optimization. Use it for systematic cost analysis and data-driven optimization.

---

## Cost Optimization Phases

| Phase | Focus | Output |
|-------|-------|--------|
| **1. Cost Visibility** | Understand current spend | Cost breakdown |
| **2. Anomaly Detection** | Identify unusual spend | Anomaly report |
| **3. Optimization Analysis** | Find savings opportunities | Opportunities list |
| **4. Risk Assessment** | Evaluate optimization risks | Risk matrix |
| **5. Implementation** | Execute optimizations | Cost reduction |
| **6. Monitoring** | Track savings | Savings report |

---

## Phase 1: Cost Visibility

### Cost Breakdown Dimensions

Analyze costs across multiple dimensions:

| Dimension | Purpose | Tool |
|-----------|---------|------|
| **Service** | Which AWS services cost most | Cost Explorer |
| **Account** | Which accounts spend most | Cost Explorer |
| **Tag** | Cost by team/project/environment | Cost Allocation Tags |
| **Resource** | Individual resource costs | Cost Explorer |
| **Time** | Cost trends over time | Cost Explorer |

### Cost Visibility Template

```markdown
## Cost Visibility Report

**Period:** [Month YYYY]
**Total Spend:** $XX,XXX
**Budget:** $XX,XXX
**Variance:** [+/-X%]

### Cost by Service

| Service | Cost | % of Total | MoM Change |
|---------|------|------------|------------|
| EC2 | $X,XXX | XX% | +X% |
| RDS | $X,XXX | XX% | +X% |
| S3 | $X,XXX | XX% | +X% |
| Data Transfer | $X,XXX | XX% | +X% |
| Other | $X,XXX | XX% | +X% |

### Cost by Environment

| Environment | Cost | % of Total |
|-------------|------|------------|
| Production | $X,XXX | XX% |
| Staging | $X,XXX | XX% |
| Development | $X,XXX | XX% |

### Cost by Team

| Team | Cost | % of Total |
|------|------|------------|
| Platform | $X,XXX | XX% |
| API | $X,XXX | XX% |
| Data | $X,XXX | XX% |
```

### Tagging Requirements

**Minimum required tags for cost allocation:**

| Tag | Purpose | Example |
|-----|---------|---------|
| `Environment` | Env separation | prod, staging, dev |
| `Team` | Cost ownership | platform, api, data |
| `Service` | Service identification | api-gateway, auth |
| `CostCenter` | Financial allocation | CC-1234 |

---

## Phase 2: Anomaly Detection

### Anomaly Detection Rules

| Rule | Threshold | Alert |
|------|-----------|-------|
| Daily spend spike | >20% vs 7-day avg | Warning |
| Service cost jump | >50% vs last month | Critical |
| New service appears | Any new service >$100/day | Info |
| Tag coverage drop | <95% coverage | Warning |

### Anomaly Investigation

When anomaly detected:

1. **Identify the spike:**
   - Which service/resource?
   - When did it start?
   - What changed?

2. **Check common causes:**
   - New deployment
   - Traffic increase
   - Data growth
   - Misconfiguration
   - Forgotten resources

3. **Validate intentionality:**
   - Expected growth?
   - Approved change?
   - One-time vs recurring?

### Anomaly Report Template

```markdown
## Cost Anomaly Report

**Detected:** YYYY-MM-DD HH:MM
**Severity:** [Critical/Warning/Info]

### Anomaly Details

| Metric | Expected | Actual | Delta |
|--------|----------|--------|-------|
| Daily spend | $X,XXX | $X,XXX | +XX% |

### Investigation

**Root Cause:** [description]

**Contributing Factors:**
1. [Factor 1]
2. [Factor 2]

**Intentional:** [Yes/No]

### Action Required

- [ ] [Action if remediation needed]
- [ ] [Update budget if expected]
```

---

## Phase 3: Optimization Analysis

### Optimization Categories

| Category | Typical Savings | Effort | Risk |
|----------|-----------------|--------|------|
| **Rightsizing** | 20-40% | Low | Low |
| **Reserved Capacity** | 30-70% | Medium | Low-Medium |
| **Spot Instances** | 60-90% | Medium | Medium |
| **Storage Tiering** | 20-50% | Low | Low |
| **Idle Resources** | 100% | Low | None |
| **Data Transfer** | 10-30% | Medium | Low |

### Rightsizing Analysis

```markdown
## Rightsizing Opportunities

### Underutilized Instances

| Instance | Type | Avg CPU | Avg Mem | Recommendation | Savings |
|----------|------|---------|---------|----------------|---------|
| api-prod-1 | m5.xlarge | 15% | 25% | m5.large | $70/mo |
| worker-2 | c5.2xlarge | 30% | 20% | c5.xlarge | $140/mo |

### Criteria Used

- CPU avg <40% over 14 days -> downsize candidate
- Memory avg <50% over 14 days -> downsize candidate
- Excluded: ASG instances (handled by ASG sizing)
```

### Reserved Instance Analysis

```markdown
## Reserved Instance Coverage

### Current Coverage

| Service | On-Demand | Reserved | Coverage |
|---------|-----------|----------|----------|
| EC2 | $5,000 | $3,000 | 38% |
| RDS | $2,000 | $0 | 0% |
| ElastiCache | $500 | $500 | 50% |

### RI Recommendations

| Resource Type | Term | Payment | Monthly Savings | Break-even |
|---------------|------|---------|-----------------|------------|
| 10x m5.large | 1 year | No upfront | $350 | 0 months |
| db.r5.xlarge | 1 year | Partial | $180 | 4 months |

### RI Purchase Criteria

- Stable workload for >80% of term
- Usage predictable for commitment period
- Consider convertible RIs for flexibility
```

### Idle Resource Detection

```markdown
## Idle Resources

### Unattached EBS Volumes

| Volume ID | Size | Cost/Month | Last Attached |
|-----------|------|------------|---------------|
| vol-xxx | 100GB | $10 | 90 days ago |
| vol-yyy | 500GB | $50 | Never |

### Unused Elastic IPs

| IP | Allocation ID | Associated | Cost/Month |
|----|---------------|------------|------------|
| x.x.x.x | eipalloc-xxx | No | $3.60 |

### Idle Load Balancers

| LB Name | Target Groups | Requests/Day | Cost/Month |
|---------|---------------|--------------|------------|
| old-api | 0 | 0 | $16.50 |
```

---

## Phase 4: Risk Assessment

### Optimization Risk Matrix

| Optimization | Risk Level | Potential Impact | Mitigation |
|--------------|------------|------------------|------------|
| Downsize instance | Low | Performance degradation | Monitor, quick rollback |
| Purchase RI | Low-Medium | Unused commitment | Convertible RIs |
| Spot instances | Medium | Instance interruption | Diversify, checkpointing |
| Delete idle | None-Low | Lost data (if EBS) | Snapshot first |
| Storage tiering | Low | Retrieval latency | Test access patterns |

### Risk Assessment Checklist

- [ ] Rollback plan documented
- [ ] Performance baseline captured
- [ ] Monitoring in place
- [ ] Stakeholders informed
- [ ] Timeline appropriate (not during peak)

---

## Phase 5: Implementation

### Implementation Priority

| Priority | Criteria | Examples |
|----------|----------|----------|
| **Quick Wins** | Low effort, no risk, immediate savings | Delete idle resources |
| **High Impact** | Significant savings, manageable risk | RI purchases |
| **Medium Impact** | Moderate savings, requires planning | Rightsizing |
| **Long-term** | Architectural changes | Spot migration |

### Implementation Checklist

- [ ] Change request approved
- [ ] Scheduled during low-traffic period
- [ ] Rollback plan ready
- [ ] Monitoring dashboards open
- [ ] Communication sent to stakeholders

---

## Phase 6: Monitoring

### Savings Tracking

```markdown
## Savings Report

**Period:** [Month YYYY]
**Target Savings:** $X,XXX
**Actual Savings:** $X,XXX
**Achievement:** XX%

### Savings by Category

| Category | Target | Actual | Status |
|----------|--------|--------|--------|
| Rightsizing | $500 | $450 | 90% |
| Reserved Instances | $2,000 | $2,100 | 105% |
| Idle Resources | $200 | $200 | 100% |

### Monthly Trend

| Month | Spend | Savings | Cumulative |
|-------|-------|---------|------------|
| Jan | $50,000 | $0 | $0 |
| Feb | $48,000 | $2,000 | $2,000 |
| Mar | $47,500 | $2,500 | $4,500 |
```

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Small savings not worth it" | Small savings compound | **Evaluate ALL opportunities** |
| "RIs are too risky" | RI risk is manageable | **Analyze stable workloads** |
| "Dev doesn't need optimization" | Dev is often 30%+ of cost | **Optimize ALL environments** |
| "Can't predict future usage" | Historical data helps | **Use data-driven forecasting** |
| "Optimization takes too much time" | ROI on optimization is high | **Invest in systematic process** |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just cut costs by 30%" | "Cannot proceed without analysis. Blind cuts cause outages. Will provide data-driven recommendations." |
| "Skip the analysis, buy RIs" | "RI purchases require usage analysis. Wrong RIs waste money. Analysis required first." |
| "Dev environment is fine as-is" | "Dev costs are significant. Optimization applies to all environments." |

---

## Dispatch Specialist

For cost optimization tasks, dispatch:

```
Task tool:
  subagent_type: "cloud-cost-optimizer"
  model: "opus"
  prompt: |
    COST ANALYSIS REQUEST
    Scope: [accounts/services to analyze]
    Period: [time range]
    Focus: [rightsizing/RI/general optimization]
    Constraints: [budget targets, risk tolerance]
```
