---
name: positioning-development
description: |
  Strategic positioning skill for developing differentiated market position,
  positioning statements, and competitive framing.

trigger: |
  - New product positioning needed
  - Repositioning existing product
  - User requests "positioning" or "differentiation"

skip_when: |
  - Market analysis not done → complete market-analysis first
  - Pure messaging work → use messaging-creation
  - Competitive analysis only → use competitive-intelligence
---

# Positioning Development

Strategic positioning to establish differentiated market position and competitive framing.

## Purpose

Positioning defines HOW you want the market to perceive your product:
- What category you compete in
- How you're different from alternatives
- Why customers should choose you
- What makes you credible

**HARD GATE:** Market analysis MUST be completed before positioning development.

## Process

### Phase 1: Category Strategy

Define your competitive frame:

```markdown
## Category Strategy

### Current Category Landscape
**Existing Categories:**
| Category | Leaders | Positioning |
|----------|---------|-------------|
| [Category 1] | [Top 3 players] | [How they position] |
| [Category 2] | [Top 3 players] | [How they position] |

### Category Decision

**Option A: Compete in Existing Category**
- Category: [Name]
- Rationale: [Why this category]
- Risk: Established competition
- Benefit: Market education not required

**Option B: Create New Category**
- Category Name: [Proposed name]
- Definition: [What this category is]
- Rationale: [Why create vs compete]
- Risk: Market education required
- Benefit: No direct comparison

**RECOMMENDATION:** [Option A or B with reasoning]
```

### Phase 2: Competitive Alternatives

Map what customers would do without you:

```markdown
## Competitive Alternatives

### Direct Competitors
| Competitor | Positioning | Strengths | Weaknesses |
|------------|-------------|-----------|------------|
| [Competitor 1] | [Their claim] | [Top 3] | [Top 3] |
| [Competitor 2] | ... | ... | ... |

### Indirect Alternatives
| Alternative | When Chosen | Why Chosen |
|-------------|-------------|------------|
| DIY/Build | [Scenario] | [Reason] |
| Status Quo | [Scenario] | [Reason] |
| [Other solution] | [Scenario] | [Reason] |

### Competitive Battleground
**Where we win:**
- [Scenario 1]: [Why we win here]
- [Scenario 2]: [Why we win here]

**Where we lose:**
- [Scenario 1]: [Why we lose here]
- [Scenario 2]: [Why we lose here]

**Toss-ups:**
- [Scenario 1]: [What determines winner]
```

### Phase 3: Differentiation

Identify defensible differentiators:

```markdown
## Differentiation Analysis

### Potential Differentiators
| Differentiator | Unique? | Valuable? | Defensible? | Score |
|----------------|---------|-----------|-------------|-------|
| [Feature/Capability 1] | YES/NO | HIGH/MED/LOW | YES/NO | X/10 |
| [Feature/Capability 2] | ... | ... | ... | ... |
| [Approach 1] | ... | ... | ... | ... |
| [Team/Background] | ... | ... | ... | ... |

### Differentiation Hierarchy
**Must-Have Differentiators (to compete):**
- [Differentiator 1]: Why it's table stakes

**Nice-to-Have Differentiators (to win):**
- [Differentiator 2]: Why it creates preference

**Unique Differentiators (to dominate):**
- [Differentiator 3]: Why it's defensible

### Primary Differentiation Theme
**Selected Theme:** [One overarching theme]
**Rationale:** [Why this theme]
**Supporting Evidence:**
1. [Proof point 1]
2. [Proof point 2]
3. [Proof point 3]
```

### Phase 4: Positioning Statement

Create the positioning framework:

```markdown
## Positioning Statement

### Classic Positioning Template
FOR [target customer]
WHO [statement of need or opportunity]
[Product name] IS A [product category]
THAT [key benefit]
UNLIKE [competitive alternative]
[Product name] [primary differentiation]

### Completed Statement
FOR [specific ICP from market analysis]
WHO [specific pain point]
[Product name] IS A [category decision]
THAT [primary benefit]
UNLIKE [main competitor/alternative]
[Product name] [unique differentiator]

### Positioning Pillars
| Pillar | Claim | Evidence |
|--------|-------|----------|
| [Pillar 1] | [What we claim] | [How we prove it] |
| [Pillar 2] | [What we claim] | [How we prove it] |
| [Pillar 3] | [What we claim] | [How we prove it] |
```

### Phase 5: Positioning Validation

Test positioning viability:

```markdown
## Positioning Validation

### Internal Validation
| Criterion | Status | Notes |
|-----------|--------|-------|
| Authentic (we can deliver) | PASS/FAIL | [Evidence] |
| Unique (competitors can't claim) | PASS/FAIL | [Evidence] |
| Valuable (customers care) | PASS/FAIL | [Evidence] |
| Defensible (sustainable advantage) | PASS/FAIL | [Evidence] |

### Market Validation Recommendations
- [ ] Customer interviews (N=X)
- [ ] Win/loss analysis
- [ ] Competitive testing
- [ ] Message testing

### Risks and Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | HIGH/MED/LOW | HIGH/MED/LOW | [How to address] |
| [Risk 2] | ... | ... | ... |
```

## Output Format

```markdown
# Positioning: [Product/Feature]

## Executive Summary
- **Category:** [Category decision]
- **Primary Differentiation:** [One sentence]
- **Target Segment:** [From market analysis]
- **Positioning Confidence:** HIGH/MEDIUM/LOW

## Category Strategy
[Phase 1 output]

## Competitive Analysis
[Phase 2 output]

## Differentiation
[Phase 3 output]

## Positioning Statement
[Phase 4 output]

## Validation
[Phase 5 output]

## Next Steps
1. **Messaging Development:** Use messaging-creation
2. **Validation Activities:** [Recommended validation]
3. **Stakeholder Alignment:** [Who needs to approve]

## Dependencies
- Market Analysis: [Link to market-analysis.md]
- Competitive Intel: [Link to competitive-intel.md if available]
```

## Blocker Criteria

| Blocker | Action |
|---------|--------|
| No market analysis | STOP. Complete market-analysis first. |
| Conflicting stakeholder visions | STOP. Facilitate alignment before proceeding. |
| No clear differentiator | STOP. Cannot position without differentiation. |
| Differentiation not defensible | STOP. Identify alternative differentiators. |

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Gate-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Our differentiation is obvious" | Obvious to you ≠ obvious to market | **Document and validate** |
| "We're better at everything" | No product wins everywhere. Find specific battlegrounds. | **Identify specific win scenarios** |
| "Category doesn't matter" | Category determines competitive set and expectations | **Make explicit category decision** |
| "Positioning is just words" | Positioning guides all GTM decisions | **Treat as strategic foundation** |

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Gate-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Position against all competitors" | "We beat everyone at everything" | "Claiming everything dilutes positioning. Focusing on defensible differentiation." |
| "Use competitor's positioning" | "Just say we're like X but better" | "Derivative positioning cedes thought leadership. Creating unique position." |
| "Skip validation" | "We know this resonates" | "Unvalidated positioning risks GTM failure. Recommending validation approach." |

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Gate-Specific Details
- alternatives_analyzed: N
- differentiators_identified: N
- positioning_statements: N
- validation_criteria_passed: X/Y
- confidence_level: HIGH/MEDIUM/LOW
