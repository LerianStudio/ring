---
name: market-analysis
description: |
  Systematic market analysis skill for understanding market size, segmentation,
  trends, and opportunities. Produces quantified market intelligence.

trigger: |
  - New product/feature market sizing
  - Market opportunity validation
  - User requests "market analysis" or "TAM/SAM/SOM"

skip_when: |
  - Competitive analysis only → use competitive-intelligence
  - Internal product requirements → use pm-team
  - Pure positioning → use positioning-development
---

# Market Analysis

Systematic market analysis to understand size, segmentation, trends, and opportunities.

## Purpose

Market analysis provides the foundation for ALL subsequent PMM activities:
- Positioning requires understanding market context
- Messaging requires understanding customer segments
- GTM requires understanding market dynamics
- Pricing requires understanding market expectations

**HARD GATE:** Do NOT proceed to positioning or messaging without market analysis.

## Process

### Phase 1: Market Definition

Define the market boundaries:

```markdown
## Market Definition

**Product/Feature:** [What you're analyzing]
**Market Category:** [Existing category or new category creation]
**Geographic Scope:** [Global, regional, specific countries]
**Time Horizon:** [Current, 1-3 years, 5+ years]

### Market Boundaries
- **Included:** [What's in scope]
- **Excluded:** [What's explicitly out of scope]
- **Adjacent Markets:** [Related but distinct markets]
```

### Phase 2: Market Sizing (TAM/SAM/SOM)

Quantify the market opportunity:

```markdown
## Market Sizing

### Total Addressable Market (TAM)
**Definition:** Total market demand if 100% market share
**Size:** $X billion
**Calculation Method:** [Top-down/Bottom-up/Value theory]
**Sources:** [List data sources]

### Serviceable Addressable Market (SAM)
**Definition:** Portion of TAM you can actually serve
**Size:** $X million
**Limiting Factors:**
- Geographic: [Regions you can serve]
- Technical: [Segments your product can address]
- Go-to-market: [Segments you can reach]

### Serviceable Obtainable Market (SOM)
**Definition:** Realistic market share in 1-3 years
**Size:** $X million
**Assumptions:**
- Market share: X%
- Growth rate: X%
- Competitive dynamics: [Key assumptions]
```

### Phase 3: Market Segmentation

Identify distinct market segments:

```markdown
## Market Segmentation

### Segment 1: [Name]
**Size:** $X million (X% of SAM)
**Characteristics:**
- Company size: [Range]
- Industry: [Verticals]
- Pain points: [Top 3 pain points]
- Buying behavior: [How they buy]
**Attractiveness:** HIGH/MEDIUM/LOW
**Fit Score:** X/10
**Priority:** PRIMARY/SECONDARY/TERTIARY

### Segment 2: [Name]
[Repeat structure]
```

### Phase 4: Market Trends

Analyze market dynamics:

```markdown
## Market Trends

### Growth Drivers
| Driver | Impact | Timeline | Confidence |
|--------|--------|----------|------------|
| [Trend 1] | HIGH/MEDIUM/LOW | Near/Mid/Long | HIGH/MEDIUM/LOW |
| [Trend 2] | ... | ... | ... |

### Headwinds
| Challenge | Impact | Mitigation |
|-----------|--------|------------|
| [Challenge 1] | HIGH/MEDIUM/LOW | [How to address] |
| [Challenge 2] | ... | ... |

### Technology Trends
- [Emerging tech affecting market]
- [Adoption curves]
- [Disruption potential]

### Regulatory Trends
- [Current regulations]
- [Expected changes]
- [Compliance requirements]
```

### Phase 5: Customer Analysis

Understand the target customer:

```markdown
## Customer Analysis

### Ideal Customer Profile (ICP)
**Company Characteristics:**
- Size: [Employee count, revenue]
- Industry: [Verticals]
- Geography: [Regions]
- Tech stack: [Required technologies]
- Maturity: [Growth stage]

**Behavioral Indicators:**
- [Signal that indicates fit]
- [Signal that indicates readiness to buy]

### Buyer Personas
**Primary Buyer: [Title]**
- Role: [Responsibilities]
- Goals: [What they want to achieve]
- Pain points: [What keeps them up at night]
- Success metrics: [How they're measured]
- Objections: [Common concerns]

**Economic Buyer: [Title]**
[Repeat structure]

**Technical Evaluator: [Title]**
[Repeat structure]
```

## Output Format

```markdown
# Market Analysis: [Product/Feature]

## Executive Summary
- **Market Size:** $X SAM, $X SOM
- **Growth Rate:** X% CAGR
- **Key Segments:** [Top 3 segments]
- **Primary Opportunity:** [One sentence]
- **Key Risk:** [One sentence]

## Market Definition
[Phase 1 output]

## Market Sizing
[Phase 2 output]

## Segmentation
[Phase 3 output]

## Trends
[Phase 4 output]

## Customer Analysis
[Phase 5 output]

## Recommendations
1. **Target Segment:** [Primary segment to pursue]
2. **Positioning Implications:** [What this means for positioning]
3. **GTM Implications:** [What this means for go-to-market]
4. **Risks to Monitor:** [Key uncertainties]

## Sources
- [Source 1]
- [Source 2]
```

## Blocker Criteria

| Blocker | Action |
|---------|--------|
| No TAM data available | STOP. Define methodology and assumptions. Request validation. |
| Market definition unclear | STOP. Clarify boundaries before sizing. |
| Conflicting market data | STOP. Document sources. Recommend reconciliation approach. |
| No ICP definition | STOP. Cannot proceed without target customer clarity. |

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Gate-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "TAM is just a big number game" | TAM informs investment decisions and positioning scope | **Calculate with methodology and sources** |
| "Segmentation is obvious" | Obvious segments miss nuanced opportunities | **Analyze systematically** |
| "User knows their market" | User knowledge + analysis > either alone | **Augment with structured research** |
| "Market data is stale" | Stale data + analysis > no data | **Document recency, proceed with caveats** |

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Gate-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Skip to positioning" | "We know the market, just position" | "Positioning without market analysis is guessing. Completing market analysis." |
| "Use competitor's TAM" | "Just use what [competitor] published" | "Competitor TAM serves their narrative. Calculating independent estimate." |
| "Rough estimate is fine" | "Just ballpark it" | "Ballpark estimates cause bad decisions. Providing methodology-backed estimate." |

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Gate-Specific Details
- markets_defined: N
- tam_calculated: YES/NO
- segments_identified: N
- sources_referenced: N
- confidence_level: HIGH/MEDIUM/LOW
