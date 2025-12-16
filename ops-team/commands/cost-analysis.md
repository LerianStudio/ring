---
name: cost-analysis
description: Execute cloud cost analysis and optimization workflow
argument-hint: "[scope: full|service|account] [focus: general|rightsizing|ri|anomaly]"
---

# Cost Analysis Command

This command initiates structured cloud cost analysis following the ops-cost-optimization workflow.

## Usage

```
/cost-analysis full general
/cost-analysis service:payment-api rightsizing
/cost-analysis account:production ri
```

## Workflow

### Step 1: Define Analysis Scope

Parse scope and focus from arguments.

**Scope options:**
- `full` - All accounts and services
- `service:[name]` - Specific service
- `account:[name]` - Specific AWS account
- `tag:[key=value]` - Resources with specific tag

**Focus options:**
- `general` - Comprehensive cost review
- `rightsizing` - Compute optimization focus
- `ri` - Reserved instance analysis
- `anomaly` - Cost anomaly investigation
- `waste` - Idle/unused resource detection

**If not provided, ask:**
- What scope should be analyzed?
- What is the primary focus?

### Step 2: Dispatch Cloud Cost Optimizer

```
Task tool:
  subagent_type: "cloud-cost-optimizer"
  model: "opus"
  prompt: |
    COST ANALYSIS REQUEST

    **Scope:** [scope]
    **Focus:** [focus area]
    **Period:** Last 30 days (with 90-day trends)

    Please analyze:
    1. Cost breakdown by the requested scope
    2. Trend analysis (MoM, YoY if available)
    3. [Focus-specific analysis - see below]
    4. Optimization opportunities
    5. ROI calculations for recommendations

    Focus-specific requirements:
    - General: Full cost visibility + top opportunities
    - Rightsizing: Compute utilization + downsize candidates
    - RI: Coverage analysis + purchase recommendations
    - Anomaly: Unusual spend patterns + root cause
    - Waste: Idle resources + cleanup recommendations

    Output required:
    - Cost summary
    - Detailed analysis
    - Prioritized recommendations
    - Implementation roadmap
```

### Step 3: Generate Report

Format findings into actionable report with clear recommendations.

## Output Format

```markdown
# Cost Analysis Report

**Scope:** [scope]
**Focus:** [focus]
**Analysis Period:** YYYY-MM-DD to YYYY-MM-DD
**Generated:** YYYY-MM-DD

## Cost Summary

**Total Spend:** $XX,XXX
**Budget:** $XX,XXX
**Variance:** [+/-X%]
**Optimization Potential:** $X,XXX/month ([X]%)

### Cost by Category

| Category | Spend | % of Total | MoM Change |
|----------|-------|------------|------------|
| [category] | $X,XXX | XX% | +X% |

## Analysis Findings

### [Focus Area] Analysis

[Detailed findings based on focus area]

## Optimization Opportunities

### Quick Wins (This Week)

| Opportunity | Savings/Month | Effort | Risk |
|-------------|---------------|--------|------|
| [opportunity] | $XXX | Low | Low |

### High Impact (This Month)

| Opportunity | Savings/Month | Effort | Risk |
|-------------|---------------|--------|------|
| [opportunity] | $X,XXX | Medium | Low |

### Strategic (This Quarter)

| Opportunity | Savings/Month | Effort | Risk |
|-------------|---------------|--------|------|
| [opportunity] | $X,XXX | High | Medium |

## ROI Analysis

| Recommendation | Monthly Savings | Implementation Cost | Payback Period |
|----------------|-----------------|---------------------|----------------|
| [rec] | $X,XXX | $X,XXX | X months |

## Implementation Roadmap

### Week 1
- [ ] [Action 1]
- [ ] [Action 2]

### Week 2-4
- [ ] [Action 3]
- [ ] [Action 4]

## Next Steps

1. Review and approve recommendations
2. Create implementation tickets
3. Schedule follow-up analysis
```

## Focus-Specific Templates

### Rightsizing Focus

Additional output:
```markdown
## Rightsizing Candidates

| Instance | Current | Recommended | CPU Avg | Mem Avg | Savings |
|----------|---------|-------------|---------|---------|---------|
| [id] | [type] | [type] | XX% | XX% | $XXX/mo |

### Criteria Used
- CPU avg <40% over 14 days
- Memory avg <50% over 14 days
- No seasonal patterns requiring headroom
```

### RI Focus

Additional output:
```markdown
## Reserved Instance Analysis

### Current Coverage

| Service | On-Demand | Reserved | Coverage |
|---------|-----------|----------|----------|
| EC2 | $X,XXX | $X,XXX | XX% |

### Purchase Recommendations

| Instance Type | Quantity | Term | Payment | Savings | Break-even |
|---------------|----------|------|---------|---------|------------|
| [type] | X | 1yr | No upfront | $X,XXX/yr | Immediate |
```

### Anomaly Focus

Additional output:
```markdown
## Anomaly Investigation

### Detected Anomalies

| Date | Service | Expected | Actual | Delta | Cause |
|------|---------|----------|--------|-------|-------|
| [date] | [svc] | $XXX | $XXX | +XX% | [cause] |

### Root Cause Analysis
[Detailed investigation findings]
```

## Related Skills

- `ops-cost-optimization` - Full cost optimization workflow
- `ops-capacity-planning` - Capacity planning (cost component)

## Anti-Rationalization

| Rationalization | Required Action |
|-----------------|-----------------|
| "Small savings not worth it" | **All savings compound over time** |
| "Can optimize later" | **Later = never. Optimize now.** |
| "Too risky to change" | **Data-driven changes are low risk** |
