---
name: ring-pmm-team:competitive-intel
description: Competitive intelligence workflow for landscape analysis and battlecards
argument-hint: "[market-or-competitor-name]"
---

I'm running the **Competitive Intelligence** workflow to analyze the competitive landscape.

**This workflow produces:**
- Competitive landscape mapping
- Competitor profiles
- Feature comparison matrix
- Win/loss analysis framework
- Sales battlecards
- Ongoing tracking plan

## Document Organization

All artifacts will be saved to: `docs/pmm/<market-name>/` or `docs/pmm/competitive/`

**First, let me gather information:**

Use the AskUserQuestion tool to gather:

**Question 1:** "What market or specific competitors do you want to analyze?"
- Header: "Analysis Scope"
- Options: "Full market landscape" or "Specific competitor(s)"
- If specific, list competitor names

**Question 2:** "What is your product context?"
- Header: "Your Product"
- What do you sell that competes with these alternatives?
- Brief value proposition

**Question 3:** "What is the primary use case for this competitive intel?"
- Header: "Use Case"
- Options: "Sales enablement", "Strategic planning", "Positioning", "All of the above"

**Question 4:** "Do you have existing win/loss data?"
- Header: "Win/Loss Data"
- If yes, provide summary or location
- If no, will create framework for future collection

After gathering inputs, create the directory structure:

```bash
mkdir -p docs/pmm/<market-name>
# or
mkdir -p docs/pmm/competitive
```

## Phase 1: Competitive Landscape Mapping

**Skill:** competitive-intelligence

1. Categorize competitors:
   - **Direct:** Same product category, same buyer
   - **Indirect:** Different product, same problem
   - **Potential:** Could enter market

2. Create initial competitor list with basic info

3. Document in: `docs/pmm/<market-name>/competitive-intel.md`

**Phase 1 Pass Criteria:**
- [ ] Direct competitors identified (at least 3)
- [ ] Indirect alternatives identified
- [ ] Potential threats assessed

## Phase 2: Competitor Profiling

For each major competitor (top 3-5):

1. **Company Overview:**
   - Founded, funding, size, HQ
   - Recent news and announcements

2. **Product Analysis:**
   - Core offering
   - Key features
   - Technology (if known)
   - Integrations

3. **Market Position:**
   - Target segment
   - Positioning
   - Pricing model
   - Market share estimate

4. **Strengths and Weaknesses:**
   - Top 3 strengths
   - Top 3 weaknesses
   - Recent activity

**Phase 2 Pass Criteria:**
- [ ] At least 3 competitors profiled
- [ ] Strengths/weaknesses documented
- [ ] Pricing information captured

## Phase 3: Feature Comparison

1. Create feature matrix:
   - List feature categories
   - Compare your product vs. competitors
   - Mark: YES / NO / PARTIAL / SUPERIOR

2. Identify:
   - **Your unique features:** What you have that they don't
   - **Their unique features:** What they have that you don't
   - **Table stakes:** What everyone has

3. Document competitive gaps and advantages

**Phase 3 Pass Criteria:**
- [ ] Feature matrix complete
- [ ] Unique features identified (both ways)
- [ ] Gaps documented

## Phase 4: Win/Loss Analysis Framework

1. Define win scenarios:
   - Where do you typically win?
   - What proof points support wins?

2. Define loss scenarios:
   - Where do you typically lose?
   - What improvements would change outcomes?

3. Create competitive triggers:
   - When to engage (signals of opportunity)
   - When to walk away (signals of poor fit)

**Phase 4 Pass Criteria:**
- [ ] Win scenarios documented
- [ ] Loss scenarios documented
- [ ] Triggers defined

## Phase 5: Sales Battlecards

For each major competitor, create battlecard:

1. **Quick Facts:** Company, HQ, funding, pricing
2. **Their Positioning:** What they claim
3. **Their Strengths:** What they'll emphasize
4. **Their Weaknesses:** What they won't mention
5. **Objection Handling:** Their claims → Your responses
6. **Landmines:** Questions to ask that expose their weaknesses
7. **Trap Questions:** Questions they'll ask and how to respond
8. **Win Strategy:** Step-by-step approach

Save battlecards to: `docs/pmm/<market-name>/battlecards/`

**Phase 5 Pass Criteria:**
- [ ] Battlecard created for top 3 competitors
- [ ] Objection handling documented
- [ ] Landmines and trap questions included

## Phase 6: Tracking Plan

1. Define monitoring sources:
   - News, social, product updates
   - Assign ownership and frequency

2. Define alert triggers:
   - Funding announcements
   - Feature launches
   - Pricing changes
   - Key hires

3. Set update cadence:
   - Battlecards: Monthly
   - Feature matrix: Quarterly
   - Full review: Bi-annually

**Phase 6 Pass Criteria:**
- [ ] Sources identified
- [ ] Alert triggers defined
- [ ] Update cadence set

## After Completion

Report to human:

```
Competitive Intelligence Complete

Artifacts created:
- docs/pmm/<market-name>/competitive-intel.md
- docs/pmm/<market-name>/battlecards/[competitor-1].md
- docs/pmm/<market-name>/battlecards/[competitor-2].md
- docs/pmm/<market-name>/battlecards/[competitor-3].md

Key Findings:
- Primary Competitors: [List]
- Your Key Advantage: [Summary]
- Your Key Gap: [Summary]
- Win Rate Drivers: [Summary]

Recommendations:
1. [Positioning implication]
2. [Product gap to address]
3. [Sales enablement priority]

Tracking Plan:
- Battlecard refresh: Monthly
- Full review: [Next date]
- Owner: [To be assigned]

Next steps:
1. Review battlecards with sales team
2. Validate win/loss analysis with recent deals
3. Address identified product gaps
4. Use insights for positioning-development
```

## Remember

- **Systematic analysis required** - don't rely on assumptions
- **Include indirect alternatives** - customers often do nothing or DIY
- **Battlecards need specifics** - generic responses don't win deals
- **Competitive intel is perishable** - plan for regular updates
- **Sales feedback is essential** - validate with real deal data

## Integration with Other PMM Skills

| Competitive Intel Feeds | Use For |
|-------------------------|---------|
| positioning-development | Differentiation strategy |
| messaging-creation | Competitive responses |
| pricing-strategy | Price positioning |
| gtm-planning | Channel decisions |

## Quick Competitive Intel (Alternative)

For urgent competitive needs, use the skill directly:

```
Skill tool: "competitive-intelligence"
```

This provides the analysis framework without the full command workflow.
