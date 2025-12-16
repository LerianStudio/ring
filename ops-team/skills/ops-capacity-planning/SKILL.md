---
name: ops-capacity-planning
description: |
  Structured workflow for infrastructure capacity planning including growth
  forecasting, scaling strategy, and resource provisioning decisions.

trigger: |
  - Quarterly capacity reviews
  - Pre-launch capacity assessment
  - Performance degradation investigation
  - Budget planning for infrastructure

skip_when: |
  - Application performance optimization -> use ring-dev-team specialists
  - Cost-only analysis -> use ops-cost-optimization skill
  - One-time resource adjustment -> standard change management

related:
  similar: [ops-cost-optimization]
  uses: [infrastructure-architect, cloud-cost-optimizer]
---

# Capacity Planning Workflow

This skill defines the structured process for infrastructure capacity planning. Use it for proactive capacity management and growth forecasting.

---

## Capacity Planning Phases

| Phase | Focus | Output |
|-------|-------|--------|
| **1. Current State** | Document existing capacity | Capacity baseline |
| **2. Usage Analysis** | Analyze utilization patterns | Utilization report |
| **3. Growth Forecast** | Project future requirements | Growth model |
| **4. Gap Analysis** | Identify capacity gaps | Gap report |
| **5. Recommendations** | Scaling strategy | Capacity plan |
| **6. Implementation** | Execute capacity changes | Updated infrastructure |

---

## Phase 1: Current State Assessment

### Data Collection

Gather the following for each service tier:

| Metric | Compute | Database | Storage | Network |
|--------|---------|----------|---------|---------|
| Provisioned | Instance count/size | Instance class | Total GB | Bandwidth |
| Peak utilization | CPU/Memory % | Connections/IOPS | Usage % | Throughput |
| Average utilization | CPU/Memory % | Connections/IOPS | Growth rate | Latency |
| Cost | Monthly $ | Monthly $ | Monthly $ | Monthly $ |

### Data Sources

```bash
# AWS CLI examples
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization
aws rds describe-db-instances
aws s3api list-buckets
aws ce get-cost-and-usage
```

### Current State Template

```markdown
## Current Capacity Baseline

**Assessment Date:** YYYY-MM-DD
**Scope:** [production/staging/all]

### Compute Resources

| Service | Instance Type | Count | Avg CPU | Avg Memory | Cost/Month |
|---------|--------------|-------|---------|------------|------------|
| api | m5.xlarge | 10 | 45% | 60% | $2,400 |
| worker | c5.2xlarge | 5 | 70% | 40% | $1,800 |

### Database Resources

| Database | Instance Class | Storage | Avg Connections | Avg IOPS | Cost/Month |
|----------|---------------|---------|-----------------|----------|------------|
| primary | db.r5.2xlarge | 500GB | 150 | 5000 | $1,800 |

### Storage Resources

| Bucket/Volume | Type | Size | Growth Rate | Cost/Month |
|---------------|------|------|-------------|------------|
| logs | S3 Standard | 2TB | 100GB/month | $46 |
```

---

## Phase 2: Usage Analysis

### Utilization Patterns

Identify patterns in resource usage:

| Pattern | Description | Scaling Strategy |
|---------|-------------|------------------|
| **Steady** | Consistent load | Reserved capacity |
| **Cyclical** | Predictable peaks | Scheduled scaling |
| **Spiky** | Unpredictable bursts | Auto-scaling |
| **Growing** | Steady increase | Proactive provisioning |

### Analysis Questions

1. What is peak vs average utilization?
2. When do peaks occur? (time of day, day of week)
3. What triggers traffic spikes? (campaigns, events)
4. What is the headroom at peak? (safety margin)
5. Are there correlated resources? (if A scales, B must scale)

### Utilization Thresholds

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| CPU | <70% | 70-85% | >85% |
| Memory | <75% | 75-90% | >90% |
| Storage | <70% | 70-85% | >85% |
| DB Connections | <70% | 70-85% | >85% |

---

## Phase 3: Growth Forecasting

### Forecasting Methods

| Method | Best For | Accuracy |
|--------|----------|----------|
| **Linear extrapolation** | Steady growth | Moderate |
| **Seasonal decomposition** | Cyclical patterns | High |
| **Business-driven** | New product launches | Varies |
| **Historical comparison** | Similar past events | Moderate |

### Growth Forecast Template

```markdown
## Growth Forecast

**Forecast Period:** [Q1 2024 / 6 months / etc.]
**Methodology:** [method used]
**Confidence:** [High/Medium/Low]

### Traffic Projections

| Metric | Current | +3 Months | +6 Months | +12 Months |
|--------|---------|-----------|-----------|------------|
| Requests/sec | 1,000 | 1,200 | 1,500 | 2,000 |
| DAU | 50,000 | 60,000 | 75,000 | 100,000 |
| Data volume | 500GB | 600GB | 750GB | 1TB |

### Key Assumptions

1. [Assumption 1 - e.g., no major product launches]
2. [Assumption 2 - e.g., 20% YoY growth continues]
3. [Assumption 3 - e.g., no seasonal events]

### Risk Factors

| Factor | Impact | Likelihood | Mitigation |
|--------|--------|------------|------------|
| Viral growth | +200% traffic | Low | Auto-scaling limits |
| Marketing campaign | +50% traffic | Medium | Pre-scale before launch |
```

---

## Phase 4: Gap Analysis

### Capacity Gap Identification

Compare current capacity against forecast requirements:

```markdown
## Gap Analysis

### Compute Gaps

| Service | Current Capacity | Needed (+6mo) | Gap | Severity |
|---------|------------------|---------------|-----|----------|
| api | 10 x m5.xlarge | 15 x m5.xlarge | +5 | Medium |
| worker | 5 x c5.2xlarge | 8 x c5.2xlarge | +3 | High |

### Database Gaps

| Database | Current | Needed | Gap | Notes |
|----------|---------|--------|-----|-------|
| primary | db.r5.2xlarge | db.r5.4xlarge | Upgrade | Vertical scale |
| replica | 1 replica | 2 replicas | +1 | Read scaling |

### Storage Gaps

| Storage | Current | Needed (+6mo) | Gap |
|---------|---------|---------------|-----|
| logs | 2TB | 3.6TB | +1.6TB |
| backups | 1TB | 1.5TB | +0.5TB |
```

### Gap Severity Matrix

| Severity | Criteria | Action Timeline |
|----------|----------|-----------------|
| Critical | <2 weeks to capacity | Immediate |
| High | 2-4 weeks to capacity | This sprint |
| Medium | 1-3 months to capacity | This quarter |
| Low | >3 months to capacity | Next quarter |

---

## Phase 5: Recommendations

### Scaling Strategy Options

| Strategy | Best For | Lead Time | Cost Impact |
|----------|----------|-----------|-------------|
| **Vertical** | DB, stateful | Hours-days | Immediate increase |
| **Horizontal** | Stateless compute | Minutes | Linear increase |
| **Reserved** | Predictable load | Immediate | 30-70% savings |
| **Spot** | Batch workloads | Variable | 60-90% savings |
| **Auto-scaling** | Variable load | Real-time | Pay for use |

### Recommendation Template

```markdown
## Capacity Recommendations

### Immediate Actions (This Sprint)

| Resource | Action | Effort | Cost Impact |
|----------|--------|--------|-------------|
| api ASG | Increase max from 10 to 15 | Low | +$600/mo max |
| worker ASG | Add 3 instances | Low | +$1,080/mo |

### Short-term Actions (This Quarter)

| Resource | Action | Effort | Cost Impact |
|----------|--------|--------|-------------|
| primary DB | Upgrade to r5.4xlarge | Medium | +$900/mo |
| Add read replica | Provision in us-east-1b | Medium | +$900/mo |

### Long-term Considerations (Next Quarter)

| Consideration | Rationale | Next Step |
|---------------|-----------|-----------|
| Sharding strategy | Single DB approaching limits | Architecture review |
| Multi-region | DR + latency benefits | Infrastructure-architect review |

### Cost Summary

| Timeframe | Current | Recommended | Delta |
|-----------|---------|-------------|-------|
| Monthly | $8,000 | $10,980 | +$2,980 |
| Annual | $96,000 | $131,760 | +$35,760 |
```

---

## Phase 6: Implementation

### Implementation Checklist

- [ ] Recommendations approved by stakeholders
- [ ] Change requests created
- [ ] Implementation scheduled (avoid peak hours)
- [ ] Rollback plan documented
- [ ] Monitoring dashboards ready
- [ ] Alert thresholds updated

### Post-Implementation Verification

- [ ] New capacity provisioned successfully
- [ ] Performance metrics improved/stable
- [ ] No unexpected errors
- [ ] Cost tracking updated
- [ ] Documentation updated

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We'll scale when we need to" | Reactive scaling causes outages | **Proactive capacity planning** |
| "Auto-scaling handles everything" | Auto-scaling has limits and lag | **Set appropriate limits** |
| "Current capacity is fine" | Fine today ≠ fine tomorrow | **Forecast growth** |
| "Too expensive to over-provision" | Outage cost > over-provisioning cost | **Maintain safety margin** |

---

## Dispatch Specialists

For capacity planning tasks, dispatch:

```
Task tool:
  subagent_type: "infrastructure-architect"
  model: "opus"
  prompt: |
    CAPACITY PLANNING: [scope]
    CURRENT STATE: [baseline]
    GROWTH FORECAST: [projection]
    REQUEST: [specific analysis needed]
```

For cost analysis of capacity options:

```
Task tool:
  subagent_type: "cloud-cost-optimizer"
  model: "opus"
  prompt: |
    CAPACITY OPTIONS: [options to evaluate]
    CONSTRAINTS: [budget, performance requirements]
    REQUEST: Cost-benefit analysis
```
