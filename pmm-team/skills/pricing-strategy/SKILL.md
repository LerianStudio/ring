---
name: ring-pmm-team:pricing-strategy
description: |
  Pricing analysis skill for developing pricing models, competitive pricing analysis,
  and pricing recommendations for products and features.

trigger: |
  - New product pricing needed
  - Pricing optimization required
  - User requests "pricing strategy" or "pricing analysis"

skip_when: |
  - Market analysis not done → complete market-analysis first
  - Pure competitive analysis → use competitive-intelligence
  - Already have validated pricing → proceed to GTM
---

# Pricing Strategy

Comprehensive pricing analysis including pricing models, competitive analysis, and recommendations.

## Purpose

Pricing strategy determines how you capture value:
- Pricing model aligns with customer value perception
- Competitive pricing informs positioning
- Willingness to pay determines price ceiling
- Cost structure determines price floor

**HARD GATE:** Market analysis SHOULD be completed before pricing strategy for context.

## Process

### Phase 1: Pricing Context

Understand the pricing landscape:

```markdown
## Pricing Context

### Product/Feature Overview
**Product:** [Name]
**Value Proposition:** [Primary value prop]
**Target Segment:** [From market analysis]
**Competitive Category:** [From positioning]

### Current State (if applicable)
**Current Pricing:** [Existing pricing if updating]
**Current Revenue:** [Baseline]
**Current Conversion:** [Rate]
**Known Issues:** [Pain points with current pricing]

### Pricing Objectives
| Objective | Priority | Target |
|-----------|----------|--------|
| Revenue maximization | HIGH/MED/LOW | [Target] |
| Market penetration | HIGH/MED/LOW | [Target] |
| Competitive positioning | HIGH/MED/LOW | [Target] |
| Customer acquisition | HIGH/MED/LOW | [Target] |
| Margin optimization | HIGH/MED/LOW | [Target] |
```

### Phase 2: Pricing Model Analysis

Evaluate pricing model options:

```markdown
## Pricing Model Analysis

### Model Evaluation
| Model | Fit | Pros | Cons | Recommendation |
|-------|-----|------|------|----------------|
| Flat Rate | HIGH/MED/LOW | [List] | [List] | CONSIDER/REJECT |
| Tiered | HIGH/MED/LOW | [List] | [List] | CONSIDER/REJECT |
| Usage-Based | HIGH/MED/LOW | [List] | [List] | CONSIDER/REJECT |
| Per-Seat | HIGH/MED/LOW | [List] | [List] | CONSIDER/REJECT |
| Freemium | HIGH/MED/LOW | [List] | [List] | CONSIDER/REJECT |
| Hybrid | HIGH/MED/LOW | [List] | [List] | CONSIDER/REJECT |

### Recommended Model
**Model:** [Selected model]
**Rationale:**
1. [Reason 1]
2. [Reason 2]
3. [Reason 3]

### Model Structure
**Base:** [What's included in base]
**Variable:** [What scales with usage/seats]
**Add-ons:** [Optional extras]

### Packaging
| Tier | Features | Target Segment |
|------|----------|----------------|
| Free/Entry | [Feature list] | [Who it's for] |
| Standard | [Feature list] | [Who it's for] |
| Premium | [Feature list] | [Who it's for] |
| Enterprise | [Feature list] | [Who it's for] |
```

### Phase 3: Competitive Pricing Analysis

Analyze competitor pricing:

```markdown
## Competitive Pricing Analysis

### Competitor Pricing Matrix
| Competitor | Model | Entry Price | Mid Price | Enterprise | Notes |
|------------|-------|-------------|-----------|------------|-------|
| [Comp 1] | [Model] | $X/mo | $X/mo | Custom | [Key difference] |
| [Comp 2] | [Model] | $X/mo | $X/mo | Custom | [Key difference] |
| [Comp 3] | [Model] | $X/mo | $X/mo | Custom | [Key difference] |

### Price Positioning
**Market Range:** $X - $Y
**Average Price:** $X
**Premium Tier:** $X+
**Budget Tier:** <$X

### Positioning Decision
| Strategy | Price Point | Rationale |
|----------|-------------|-----------|
| Premium | Above market | [When appropriate] |
| Value | At market | [When appropriate] |
| Penetration | Below market | [When appropriate] |

**RECOMMENDATION:** [Strategy with rationale]

### Feature-Value Comparison
| Feature | Our Price | Comp A | Comp B | Value Gap |
|---------|-----------|--------|--------|-----------|
| [Feature 1] | $X | $Y | $Z | [Over/Under] |
| [Feature 2] | $X | $Y | $Z | [Over/Under] |
```

### Phase 4: Value-Based Pricing

Determine willingness to pay:

```markdown
## Value-Based Pricing

### Value Drivers
| Value Driver | Customer Impact | Quantification |
|--------------|-----------------|----------------|
| [Time saved] | [Hours/week] | [$X value] |
| [Cost reduced] | [% reduction] | [$X value] |
| [Revenue enabled] | [% increase] | [$X value] |

### Total Value Delivered
**Quantified Value:** $X per [time period]
**Value Capture Ratio:** X% (price / value delivered)
**Price Justification:** [How price relates to value]

### Willingness to Pay Research
**Method:** [Survey, interviews, conjoint analysis, Van Westendorp]
**Sample Size:** N
**Key Findings:**
- Price too cheap: $X
- Acceptable range: $X - $Y
- Price too expensive: $Y
- Maximum willingness: $Z

### Segment Pricing Sensitivity
| Segment | Price Sensitivity | Recommended Price |
|---------|-------------------|-------------------|
| [Segment 1] | HIGH/MED/LOW | $X |
| [Segment 2] | HIGH/MED/LOW | $X |
| [Segment 3] | HIGH/MED/LOW | $X |
```

### Phase 5: Pricing Recommendation

Synthesize into recommendation:

```markdown
## Pricing Recommendation

### Recommended Pricing
| Tier | Price | Billing | Features | Target |
|------|-------|---------|----------|--------|
| Free | $0 | N/A | [List] | [Segment] |
| Starter | $X/mo | Monthly/Annual | [List] | [Segment] |
| Pro | $X/mo | Monthly/Annual | [List] | [Segment] |
| Enterprise | Custom | Annual | [List] | [Segment] |

### Annual Discount
**Discount:** X%
**Rationale:** [Why this discount]

### Price Anchoring
**Anchor Price:** $X (Highest visible tier)
**Target Tier:** [Most recommended tier]
**Value Demonstration:** [How to show value]

### Revenue Projection
| Scenario | Assumptions | Year 1 Revenue |
|----------|-------------|----------------|
| Conservative | [Assumptions] | $X |
| Base | [Assumptions] | $X |
| Optimistic | [Assumptions] | $X |

### Implementation Plan
| Phase | Action | Timeline |
|-------|--------|----------|
| 1 | [Action] | [When] |
| 2 | [Action] | [When] |
| 3 | [Action] | [When] |

### Risks and Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Price too high | HIGH/MED/LOW | HIGH/MED/LOW | [Plan] |
| Price too low | HIGH/MED/LOW | HIGH/MED/LOW | [Plan] |
| Competitor response | HIGH/MED/LOW | HIGH/MED/LOW | [Plan] |
```

## Output Format

```markdown
# Pricing Strategy: [Product/Feature]

## Executive Summary
- **Recommended Model:** [Model type]
- **Price Range:** $X - $Y
- **Primary Tier:** $X/mo
- **Confidence Level:** HIGH/MEDIUM/LOW

## Pricing Context
[Phase 1 output]

## Model Analysis
[Phase 2 output]

## Competitive Analysis
[Phase 3 output]

## Value-Based Pricing
[Phase 4 output]

## Recommendation
[Phase 5 output]

## Next Steps
1. **Validation:** [Recommended validation approach]
2. **Stakeholder Approval:** [Who needs to approve]
3. **Implementation:** [Timeline and steps]

## Dependencies
- Market Analysis: [Link to market-analysis.md]
- Competitive Intel: [Link to competitive-intel.md]
- Positioning: [Link to positioning.md]
```

## Blocker Criteria

| Blocker | Action |
|---------|--------|
| No competitive pricing data | STOP. Research required. |
| Conflicting pricing objectives | STOP. Align stakeholders on priorities. |
| No willingness to pay data | STOP. Recommend research approach. |
| Cost structure unknown | STOP. Cannot set floor without costs. |

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Gate-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Match competitor pricing" | Competitor pricing serves their strategy, not yours | **Develop independent pricing based on your value** |
| "Lower price wins" | Race to bottom destroys value. Differentiate instead. | **Price based on value, not fear** |
| "We'll figure it out later" | Wrong pricing at launch damages brand and revenue | **Validate before launch** |
| "Pricing is just numbers" | Pricing communicates value. It's strategic. | **Treat as strategic decision** |

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Gate-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Just undercut competitors" | "Price 20% below market" | "Undercutting signals low value. Pricing based on differentiation." |
| "Make it free to grow" | "Free tier will drive adoption" | "Free can work but requires strategy. Analyzing freemium viability." |
| "Don't worry about margins" | "Growth first, margins later" | "Unsustainable pricing kills companies. Ensuring viable margins." |

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Gate-Specific Details
- models_evaluated: N
- competitors_analyzed: N
- willingness_to_pay_assessed: YES/NO
- recommendation_confidence: HIGH/MEDIUM/LOW
- validation_status: PENDING/VALIDATED
