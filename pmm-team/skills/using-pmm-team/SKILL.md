---
name: using-pmm-team
description: |
  7 product marketing skills + 6 specialist agents for go-to-market strategy,
  positioning, messaging, competitive intelligence, and launch coordination.

trigger: |
  - Starting go-to-market planning
  - Need market positioning or messaging
  - User requests "GTM strategy" or "launch plan"
  - Competitive analysis required

skip_when: |
  - Pure technical implementation → use dev-team
  - Product requirements → use pm-team
  - Financial analysis → use finops-team
---

# Using Ring PMM-Team: Product Marketing Workflow

The ring-pmm-team plugin provides 7 product marketing skills and 6 specialist agents. Use them via `Skill tool: "skill-name"` or via slash commands.

**Remember:** Follow the **ORCHESTRATOR principle** from `using-ring`. Dispatch PMM specialists to handle marketing strategy; don't attempt marketing analysis without structured process.

## PMM Philosophy

**Marketing strategy requires systematic research and validation. Every time.**

PMM workflow ensures:
- Market is understood (size, segments, trends)
- Competition is mapped (strengths, weaknesses, positioning)
- Positioning is differentiated (why you, why now)
- Messaging resonates (proof points, value props)
- GTM is executable (channels, tactics, timeline)
- Launch is coordinated (checklist, stakeholders, materials)
- Pricing is validated (models, willingness to pay)

## Domain Distinction

| Plugin | Focus | Outputs |
|--------|-------|---------|
| **pm-team** | Technical pre-dev planning | PRDs, TRDs, API specs, task breakdown |
| **pmm-team** | Market strategy | Positioning, messaging, GTM plans, launch coordination |

**Use pm-team for WHAT to build. Use pmm-team for HOW to market.**

## Skills Overview

| Skill | Purpose | Output |
|-------|---------|--------|
| `market-analysis` | Market sizing, segmentation, trends | market-analysis.md |
| `positioning-development` | Differentiation, positioning statement | positioning.md |
| `messaging-creation` | Value props, proof points, messaging | messaging-framework.md |
| `gtm-planning` | Channels, tactics, timeline | gtm-plan.md |
| `launch-execution` | Launch checklist, coordination | launch-plan.md |
| `pricing-strategy` | Pricing models, analysis | pricing-strategy.md |
| `competitive-intelligence` | Competitive landscape, battlecards | competitive-intel.md |

## Agents Overview

| Agent | Expertise | Use For |
|-------|-----------|---------|
| `market-researcher` | Market intelligence, sizing, trends | TAM/SAM/SOM, market segmentation |
| `positioning-strategist` | Differentiation, category design | Positioning statements, competitive framing |
| `messaging-specialist` | Copywriting, value propositions | Messaging frameworks, proof points |
| `gtm-planner` | Channel strategy, launch planning | GTM plans, campaign strategy |
| `launch-coordinator` | Launch execution, stakeholder mgmt | Launch checklists, coordination |
| `pricing-analyst` | Pricing models, competitive pricing | Pricing strategy, packaging |

## Recommended Workflow

### Full GTM Planning (New Product/Major Launch)

```
1. Market Analysis        → market-analysis
2. Competitive Intel      → competitive-intelligence
3. Positioning            → positioning-development
4. Messaging              → messaging-creation
5. Pricing                → pricing-strategy
6. GTM Plan               → gtm-planning
7. Launch Coordination    → launch-execution
```

**Planning time:** 4-8 hours depending on market complexity

### Quick Positioning (Feature Launch/Minor Update)

```
1. Competitive Intel      → competitive-intelligence
2. Positioning            → positioning-development
3. Messaging              → messaging-creation
```

**Planning time:** 1-2 hours

### Competitive Response (Urgent)

```
1. Competitive Intel      → competitive-intelligence
2. Positioning Update     → positioning-development
```

**Planning time:** 30-60 minutes

## Using PMM Skills

### Via Slash Commands

```
/market-analysis fintech-b2b    # Full market analysis
/gtm-plan new-feature           # GTM planning
/competitive-intel competitor-x  # Competitive analysis
```

### Via Skills (Manual)

```
Skill tool: "market-analysis"
(Review output)
Skill tool: "positioning-development"
(Review output)
```

## Output Structure

```
docs/pmm/{product-or-feature}/
├── market-analysis.md       # Market sizing, segments
├── competitive-intel.md     # Competitor landscape
├── positioning.md           # Differentiation, positioning
├── messaging-framework.md   # Value props, proof points
├── pricing-strategy.md      # Pricing models, recommendations
├── gtm-plan.md             # Channels, tactics, timeline
└── launch-plan.md          # Checklist, coordination
```

## Integration with Other Plugins

| Plugin | Integration Point |
|--------|------------------|
| pm-team | PRD → PMM validates market opportunity |
| dev-team | Feature specs → PMM creates messaging |
| tw-team | PMM messaging → TW creates docs |
| finops-team | PMM pricing → FinOps validates margins |

**Combined with:**
- `pre-dev-prd-creation` – Business requirements inform market analysis
- `functional-writer` – Turn positioning into documentation
- `brainstorm` – Explore positioning options

## Blocker Criteria

**STOP and escalate when:**

| Blocker Type | Example | Action |
|--------------|---------|--------|
| **Missing Market Data** | No TAM estimates available | STOP. Request data or define assumptions. |
| **Conflicting Positioning** | Stakeholders disagree on differentiation | STOP. Facilitate alignment discussion. |
| **Undefined ICP** | "Everyone is our customer" | STOP. Require specific segment definition. |
| **No Competitive Data** | Can't identify competitors | STOP. Market may not exist or be misunderstood. |
| **Pricing Uncertainty** | No willingness-to-pay data | STOP. Recommend validation approach. |

## Anti-Rationalization

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

**PMM-Specific:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Market is obvious" | Assumptions cause positioning failures | **Quantify with data** |
| "We know our competitors" | Knowledge gaps cause blind spots | **Complete systematic analysis** |
| "Messaging can evolve" | Evolution needs baseline | **Create complete framework first** |

## ORCHESTRATOR Principle

- **You're the orchestrator** – Dispatch PMM skills, don't market manually
- **Don't skip research** – Research prevents positioning failures
- **Don't assume market fit** – Validate systematically
- **Use agents for specialist work** – Dispatch specialists for complex analysis

### Good (ORCHESTRATOR):
> "I need GTM strategy for the new payment feature. Let me run /market-analysis, then dispatch positioning-strategist to define differentiation."

### Bad (OPERATOR):
> "I'll write the positioning based on what I think the market wants."
