# Execution Report Format for PMM

This file defines the standard execution report format for all product marketing gates.

## Standard Report Structure

Every gate skill MUST produce an execution report with these base metrics:

| Metric | Value | Description |
|--------|-------|-------------|
| Duration | Xm Ys | Time spent executing the gate |
| Iterations | N | Number of retry attempts |
| Result | PASS/FAIL/PARTIAL | Gate outcome |

## How to Use This File

Skills should reference this format and add gate-specific metrics:

```markdown
## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Gate-Specific Details
[Add gate-specific metrics here]
```

## Gate-Specific Metric Examples

### Market Analysis Gate
- markets_analyzed: N
- competitors_profiled: N
- sources_referenced: N
- tam_calculated: YES/NO
- segments_identified: N

### Positioning Gate
- differentiators_identified: N
- alternatives_analyzed: N
- positioning_statements: N (draft/final)
- validation_status: PENDING/VALIDATED

### Messaging Gate
- personas_covered: N
- value_props_created: N
- proof_points_per_claim: N
- tone_consistency: PASS/FAIL

### GTM Planning Gate
- channels_evaluated: N
- tactics_planned: N
- milestones_defined: N
- budget_allocated: YES/NO
- timeline_created: YES/NO

### Launch Gate
- checklist_items: X/Y completed
- stakeholders_aligned: YES/NO
- materials_ready: X/Y
- go/no-go_decision: PENDING/GO/NO-GO

### Pricing Gate
- models_evaluated: N
- competitor_prices_analyzed: N
- willingness_to_pay_assessed: YES/NO
- recommendation_confidence: HIGH/MEDIUM/LOW

### Competitive Intelligence Gate
- competitors_tracked: N
- intel_sources: N
- battlecards_created: N
- update_frequency: DEFINED/UNDEFINED
