---
name: ring-ops-team:capacity-review
description: Execute infrastructure capacity review and planning workflow
argument-hint: "[scope: production|staging|all] [timeframe: quarterly|annual]"
---

# Capacity Review Command

This command initiates a structured capacity review following the ops-capacity-planning workflow.

## Usage

```
/capacity-review production quarterly
```

## Workflow

### Step 1: Define Scope

Parse the scope and timeframe from arguments.

**Scope options:**
- `production` - Production infrastructure only
- `staging` - Staging/pre-production
- `all` - All environments

**Timeframe options:**
- `quarterly` - 3-month forecast
- `annual` - 12-month forecast
- `custom` - User-specified period

**If not provided, ask:**
- Which environments to review?
- How far to forecast?

### Step 2: Dispatch Infrastructure Architect

```
Task tool:
  subagent_type: "infrastructure-architect"
  model: "opus"
  prompt: |
    CAPACITY REVIEW REQUEST

    **Scope:** [environments]
    **Forecast Period:** [timeframe]
    **Date:** [current date]

    Please analyze:
    1. Current capacity baseline for all resources
    2. Utilization patterns and trends
    3. Growth forecast based on historical data
    4. Capacity gaps between current and forecasted needs
    5. Scaling recommendations with cost estimates

    Output required:
    - Current state summary
    - Utilization analysis
    - Growth projections
    - Gap analysis
    - Recommendations with priorities
```

### Step 3: Dispatch Cost Optimizer (Parallel)

```
Task tool:
  subagent_type: "cloud-cost-optimizer"
  model: "opus"
  prompt: |
    CAPACITY COST ANALYSIS

    **Scope:** [environments]
    **Forecast Period:** [timeframe]

    Please analyze:
    1. Current infrastructure costs by category
    2. Cost efficiency of current capacity
    3. Reserved instance coverage and opportunities
    4. Cost projections for capacity recommendations
    5. Cost optimization opportunities

    Output required:
    - Current cost breakdown
    - RI/Savings Plan analysis
    - Cost projections
    - Optimization recommendations
```

### Step 4: Consolidate Reports

Combine findings from both specialists into comprehensive capacity plan.

## Output Format

```markdown
# Capacity Review Report

**Scope:** [environments]
**Period:** [timeframe]
**Date:** YYYY-MM-DD

## Executive Summary

[2-3 sentences summarizing capacity status and key recommendations]

## Current Capacity Baseline

### Compute Resources

| Service | Type | Count | Avg Utilization | Cost/Month |
|---------|------|-------|-----------------|------------|
| [service] | [type] | [n] | [%] | $[X,XXX] |

### Database Resources

| Database | Class | Storage | Avg Utilization | Cost/Month |
|----------|-------|---------|-----------------|------------|
| [db] | [class] | [GB] | [%] | $[X,XXX] |

## Utilization Analysis

[Findings from infrastructure architect]

## Growth Forecast

| Resource | Current | +3mo | +6mo | +12mo |
|----------|---------|------|------|-------|
| [resource] | [value] | [value] | [value] | [value] |

## Gap Analysis

| Gap | Severity | Timeline to Impact |
|-----|----------|-------------------|
| [gap] | [severity] | [when] |

## Recommendations

### Immediate (This Sprint)

| Action | Effort | Cost Impact | Risk |
|--------|--------|-------------|------|
| [action] | [effort] | [impact] | [risk] |

### Short-term (This Quarter)

[Additional recommendations]

### Long-term (Next Quarter+)

[Strategic recommendations]

## Cost Summary

| Timeframe | Current | Recommended | Delta |
|-----------|---------|-------------|-------|
| Monthly | $[X] | $[X] | [+/-]% |
| Annual | $[X] | $[X] | [+/-]% |

## Next Steps

1. [Immediate action]
2. [Follow-up action]
3. [Review schedule]
```

## Related Skills

- `ops-capacity-planning` - Full capacity planning workflow
- `ops-cost-optimization` - Cost optimization workflow

## Anti-Rationalization

| Rationalization | Required Action |
|-----------------|-----------------|
| "Current capacity is fine" | **Verify with data, not assumptions** |
| "We can scale when needed" | **Proactive > reactive** |
| "Too expensive to over-provision" | **Outage cost > over-provision cost** |
