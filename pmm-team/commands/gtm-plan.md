---
name: ring-pmm-team:gtm-plan
description: Full go-to-market planning workflow from positioning through launch
argument-hint: "[product-or-feature-name]"
---

I'm running the **GTM Planning** workflow to create a comprehensive go-to-market plan.

**This workflow produces:**
- Market analysis summary
- Competitive intelligence
- Positioning strategy
- Messaging framework
- Pricing strategy (if needed)
- GTM plan with channels and tactics
- Launch coordination plan

## Prerequisites Check

**Before starting, verify:**
- [ ] Product/feature is defined
- [ ] Launch date is known (or estimated)
- [ ] Budget range is known (or can be determined)

**If prerequisites not met, gather them first.**

## Document Organization

All artifacts will be saved to: `docs/pmm/<product-name>/`

**First, let me gather information:**

Use the AskUserQuestion tool to gather:

**Question 1:** "What product or feature are you planning GTM for?"
- Header: "Product/Feature Name"
- Use kebab-case for directory (e.g., "new-analytics-feature", "enterprise-plan")

**Question 2:** "What is the target launch date?"
- Header: "Launch Date"
- Specific date or timeframe (e.g., "Q1 2025", "March 15, 2025")

**Question 3:** "What is the launch tier?"
- Header: "Launch Tier"
- Tier 1: Major launch, maximum resources
- Tier 2: Significant launch, moderate resources
- Tier 3: Minor launch, minimal resources

**Question 4:** "What is the approximate marketing budget?"
- Header: "Budget"
- Range is acceptable (e.g., "$10K-$50K", "$100K+")
- Or "TBD - need to determine"

**Question 5:** "What existing GTM assets do you have?"
- Header: "Existing Assets"
- Market analysis, positioning, messaging, etc.
- "None" is acceptable

After gathering inputs, create the directory structure:

```bash
mkdir -p docs/pmm/<product-name>
```

## Gate 0: Market Analysis (if needed)

**Skill:** market-analysis
**Agent:** market-researcher (model: opus)

Skip if: Recent market analysis exists (<6 months old)

1. Run market analysis workflow
2. Save to: `docs/pmm/<product-name>/market-analysis.md`
3. Get human approval before proceeding

**Gate 0 Pass Criteria:**
- [ ] Market sized (TAM/SAM/SOM)
- [ ] Segments identified
- [ ] ICP defined

## Gate 1: Competitive Intelligence

**Skill:** competitive-intelligence

Skip if: Recent competitive intel exists (<3 months old)

1. Map competitive landscape
2. Create feature comparison
3. Develop initial battlecards
4. Save to: `docs/pmm/<product-name>/competitive-intel.md`
5. Get human approval before proceeding

**Gate 1 Pass Criteria:**
- [ ] Key competitors identified
- [ ] Competitive strengths/weaknesses mapped
- [ ] Differentiation opportunities identified

## Gate 2: Positioning Development

**Skill:** positioning-development
**Agent:** positioning-strategist (model: opus)

1. Define category strategy
2. Identify differentiation
3. Create positioning statement
4. Develop positioning pillars
5. Save to: `docs/pmm/<product-name>/positioning.md`
6. Get human approval before proceeding

**Gate 2 Pass Criteria:**
- [ ] Category decision made
- [ ] Differentiation validated
- [ ] Positioning statement complete
- [ ] Positioning pillars defined

## Gate 3: Messaging Creation

**Skill:** messaging-creation
**Agent:** messaging-specialist (model: opus)

1. Create value propositions
2. Develop proof points
3. Build messaging framework
4. Adapt for channels
5. Save to: `docs/pmm/<product-name>/messaging-framework.md`
6. Get human approval before proceeding

**Gate 3 Pass Criteria:**
- [ ] Value props by persona
- [ ] Proof points documented
- [ ] Messaging framework complete
- [ ] Channel adaptations created

## Gate 4: Pricing Strategy (if applicable)

**Skill:** pricing-strategy
**Agent:** pricing-analyst (model: opus)

Skip if: Pricing already determined or not applicable

1. Analyze pricing models
2. Review competitive pricing
3. Develop pricing recommendation
4. Save to: `docs/pmm/<product-name>/pricing-strategy.md`
5. Get human approval before proceeding

**Gate 4 Pass Criteria:**
- [ ] Pricing model selected
- [ ] Price points recommended
- [ ] Competitive context documented

## Gate 5: GTM Planning

**Skill:** gtm-planning
**Agent:** gtm-planner (model: opus)

1. Define GTM strategy
2. Select and prioritize channels
3. Create tactical plan
4. Build timeline and milestones
5. Allocate budget
6. Save to: `docs/pmm/<product-name>/gtm-plan.md`
7. Get human approval before proceeding

**Gate 5 Pass Criteria:**
- [ ] GTM model defined
- [ ] Channels selected and prioritized
- [ ] Tactics planned
- [ ] Timeline created
- [ ] Budget allocated

## Gate 6: Launch Coordination

**Skill:** launch-execution
**Agent:** launch-coordinator (model: opus)

1. Assess launch readiness
2. Create pre-launch checklist
3. Define RACI and escalation
4. Plan day-of execution
5. Set up monitoring
6. Save to: `docs/pmm/<product-name>/launch-plan.md`
7. Get human approval

**Gate 6 Pass Criteria:**
- [ ] Readiness assessed
- [ ] Checklist complete
- [ ] RACI defined
- [ ] Day-of plan ready
- [ ] Monitoring set up

## After Completion

Report to human:

```
GTM Planning Complete for <product-name>

Artifacts created:
- docs/pmm/<product-name>/market-analysis.md (Gate 0)
- docs/pmm/<product-name>/competitive-intel.md (Gate 1)
- docs/pmm/<product-name>/positioning.md (Gate 2)
- docs/pmm/<product-name>/messaging-framework.md (Gate 3)
- docs/pmm/<product-name>/pricing-strategy.md (Gate 4) [if applicable]
- docs/pmm/<product-name>/gtm-plan.md (Gate 5)
- docs/pmm/<product-name>/launch-plan.md (Gate 6)

Launch Summary:
- Launch Date: [Date]
- Launch Tier: [1/2/3]
- Primary Channels: [List]
- Budget: $[Amount]
- Primary KPI: [Metric]

Next steps:
1. Review all artifacts in docs/pmm/<product-name>/
2. Get stakeholder approval on positioning and messaging
3. Begin content creation per GTM plan
4. Activate launch checklist T-14 days
5. Schedule launch retrospective for T+7 days
```

## Remember

- **This is a gated workflow** - get approval at each gate
- **Positioning before messaging** - don't skip the order
- **Budget clarity is required** - tactics without budget are wishes
- **Timeline is fixed** - scope can flex, date cannot
- All agents use **model: opus** - do not use sonnet

## Quick Reference

| Gate | Skill | Agent | Output |
|------|-------|-------|--------|
| 0 | market-analysis | market-researcher | market-analysis.md |
| 1 | competitive-intelligence | - | competitive-intel.md |
| 2 | positioning-development | positioning-strategist | positioning.md |
| 3 | messaging-creation | messaging-specialist | messaging-framework.md |
| 4 | pricing-strategy | pricing-analyst | pricing-strategy.md |
| 5 | gtm-planning | gtm-planner | gtm-plan.md |
| 6 | launch-execution | launch-coordinator | launch-plan.md |
