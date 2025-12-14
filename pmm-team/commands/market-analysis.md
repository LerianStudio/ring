---
name: market-analysis
description: Comprehensive market analysis workflow for TAM/SAM/SOM, segmentation, and trends
argument-hint: "[market-or-product-name]"
---

I'm running the **Market Analysis** workflow to provide comprehensive market intelligence.

**This workflow produces:**
- Total Addressable Market (TAM) sizing
- Serviceable Addressable Market (SAM) sizing
- Serviceable Obtainable Market (SOM) estimation
- Market segmentation analysis
- Trend analysis (drivers and headwinds)
- Ideal Customer Profile (ICP)
- Buyer personas

## Document Organization

All artifacts will be saved to: `docs/pmm/<market-or-product-name>/`

**First, let me gather information about your market:**

Use the AskUserQuestion tool to gather:

**Question 1:** "What market or product do you want to analyze?"
- Header: "Market/Product Name"
- This will be used for the directory name
- Use kebab-case (e.g., "fintech-b2b", "developer-tools", "saas-analytics")

**Question 2:** "What is the product/feature context for this analysis?"
- Header: "Product Context"
- What product or feature will compete in this market?
- What value does it provide?

**Question 3:** "What geographic scope should we analyze?"
- Header: "Geographic Scope"
- Options: Global, North America, EMEA, APAC, specific countries
- Default: Global

**Question 4:** "What specific market questions do you need answered?"
- Header: "Specific Questions"
- Optional: Any particular aspects to focus on
- Examples: "Who are the early adopters?", "What's the growth rate?"

After gathering inputs, create the directory structure:

```bash
mkdir -p docs/pmm/<market-name>
```

## Phase 1: Market Definition

**Skill:** ring-pmm-team:market-analysis

1. Define market boundaries:
   - What's included in scope
   - What's explicitly excluded
   - Adjacent markets to consider

2. Document in: `docs/pmm/<market-name>/market-analysis.md`

**Phase 1 Pass Criteria:**
- [ ] Market boundaries clearly defined
- [ ] Inclusions and exclusions documented
- [ ] Geographic scope specified

## Phase 2: Market Sizing

**Agent:** ring-pmm-team:market-researcher (model: opus)

Dispatch the market-researcher agent to calculate:

1. **TAM (Total Addressable Market)**
   - Use top-down or bottom-up methodology
   - Document calculation with sources
   - Provide confidence level

2. **SAM (Serviceable Addressable Market)**
   - Apply geographic limitations
   - Apply technical limitations
   - Apply go-to-market limitations

3. **SOM (Serviceable Obtainable Market)**
   - Realistic market share assumptions
   - 1-3 year projection
   - Document assumptions

**Phase 2 Pass Criteria:**
- [ ] TAM calculated with methodology
- [ ] SAM derived with clear limitations
- [ ] SOM projected with assumptions
- [ ] All calculations sourced

## Phase 3: Segmentation

1. Identify distinct market segments
2. Size each segment
3. Assess segment attractiveness:
   - Market size
   - Growth rate
   - Competition intensity
   - Fit with product
4. Prioritize segments (PRIMARY/SECONDARY/TERTIARY)

**Phase 3 Pass Criteria:**
- [ ] At least 3 segments identified
- [ ] Segments sized
- [ ] Attractiveness assessed
- [ ] Priorities assigned

## Phase 4: Trend Analysis

1. Identify growth drivers:
   - Technology trends
   - Market trends
   - Regulatory changes

2. Identify headwinds:
   - Challenges
   - Risks
   - Uncertainties

3. Assess impact and timeline for each

**Phase 4 Pass Criteria:**
- [ ] Growth drivers identified with impact assessment
- [ ] Headwinds identified with mitigation
- [ ] Timeline perspective (near/mid/long-term)

## Phase 5: Customer Analysis

1. Define Ideal Customer Profile (ICP):
   - Company characteristics
   - Behavioral indicators
   - Fit criteria

2. Develop buyer personas:
   - Primary buyer
   - Economic buyer
   - Technical evaluator

**Phase 5 Pass Criteria:**
- [ ] ICP documented with specifics
- [ ] At least 2 buyer personas defined
- [ ] Pain points and goals documented

## After Completion

Report to human:

```
Market Analysis Complete for <market-name>

Artifacts created:
- docs/pmm/<market-name>/market-analysis.md

Key Findings:
- TAM: $X billion
- SAM: $X million
- SOM: $X million (X% market share)
- Primary Segment: [Name] ($X million)
- Growth Rate: X% CAGR

Recommendations:
1. [Primary opportunity]
2. [Target segment recommendation]
3. [Key risk to monitor]

Next steps:
1. Run /ring-pmm-team:competitive-intel for competitive landscape
2. Run ring-pmm-team:positioning-development for positioning strategy
3. Validate findings with customer research
```

## Remember

- **All claims must have sources** - no unsourced estimates
- **Methodology must be documented** - others need to verify
- **Confidence levels are required** - acknowledge uncertainty
- **Assumptions must be explicit** - no hidden assumptions
- Market analysis is foundational - don't rush

## Integration with Other PMM Skills

| After Market Analysis | Use For |
|-----------------------|---------|
| ring-pmm-team:competitive-intelligence | Understand competitive landscape |
| ring-pmm-team:positioning-development | Create positioning strategy |
| ring-pmm-team:pricing-strategy | Inform pricing decisions |
| ring-pmm-team:gtm-planning | Plan go-to-market |
