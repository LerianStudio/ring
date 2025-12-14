---
name: messaging-creation
description: |
  Messaging framework skill for developing value propositions, proof points,
  and consistent messaging across audiences and channels.

trigger: |
  - Positioning complete, need messaging
  - Launching new product/feature
  - User requests "messaging" or "value proposition"

skip_when: |
  - Positioning not done → complete positioning-development first
  - Market analysis needed → complete market-analysis first
  - Pure competitive analysis → use competitive-intelligence
---

# Messaging Creation

Develop comprehensive messaging framework with value propositions, proof points, and channel-specific messaging.

## Purpose

Messaging translates positioning into customer-facing communication:
- Value propositions explain why customers should care
- Proof points make claims credible
- Messaging framework ensures consistency across all touchpoints

**HARD GATE:** Positioning MUST be completed before messaging creation.

## Process

### Phase 1: Messaging Foundation

Build from positioning:

```markdown
## Messaging Foundation

### Positioning Recap
**Positioning Statement:** [From positioning-development]
**Primary Differentiation:** [From positioning-development]
**Target Segment:** [From market-analysis]

### Messaging Pillars
| Pillar | Positioning Basis | Messaging Theme |
|--------|------------------|-----------------|
| [Pillar 1] | [From positioning] | [Messaging angle] |
| [Pillar 2] | [From positioning] | [Messaging angle] |
| [Pillar 3] | [From positioning] | [Messaging angle] |

### Voice and Tone
**Brand Voice:** [Authoritative/Friendly/Technical/etc.]
**Tone Attributes:**
- [Attribute 1]: [How to express]
- [Attribute 2]: [How to express]
- [Attribute 3]: [How to express]

**Words to Use:** [List]
**Words to Avoid:** [List]
```

### Phase 2: Value Propositions

Create layered value propositions:

```markdown
## Value Propositions

### Primary Value Proposition
**One Sentence:** [Headline-level statement]
**One Paragraph:** [Expanded explanation]

### Supporting Value Propositions
| Value Prop | Claim | Benefit | Evidence |
|------------|-------|---------|----------|
| [VP 1] | [What we claim] | [Why customer cares] | [Proof] |
| [VP 2] | [What we claim] | [Why customer cares] | [Proof] |
| [VP 3] | [What we claim] | [Why customer cares] | [Proof] |

### Value Proposition by Persona
**[Primary Buyer Title]:**
- Pain point: [Their pain]
- Value prop: [How we address]
- Key message: [What to say]

**[Economic Buyer Title]:**
- Pain point: [Their pain]
- Value prop: [How we address]
- Key message: [What to say]

**[Technical Evaluator Title]:**
- Pain point: [Their pain]
- Value prop: [How we address]
- Key message: [What to say]
```

### Phase 3: Proof Points

Build credibility:

```markdown
## Proof Points

### Types of Proof
| Type | Example | Status |
|------|---------|--------|
| Customer Results | [X% improvement in Y] | AVAILABLE/NEEDED |
| Third-Party Validation | [Analyst report, award] | AVAILABLE/NEEDED |
| Technical Proof | [Benchmark, certification] | AVAILABLE/NEEDED |
| Social Proof | [Logos, testimonials] | AVAILABLE/NEEDED |

### Proof Point Matrix
| Claim | Proof Type | Proof Statement | Source |
|-------|-----------|-----------------|--------|
| [Claim 1] | Customer Result | [Specific proof] | [Source] |
| [Claim 2] | Technical | [Specific proof] | [Source] |
| [Claim 3] | Third-Party | [Specific proof] | [Source] |

### Proof Gaps
| Claim | Missing Proof | Plan to Obtain |
|-------|---------------|----------------|
| [Claim 1] | [What's missing] | [How to get it] |
```

### Phase 4: Messaging Framework

Create complete framework:

```markdown
## Messaging Framework

### Elevator Pitch (30 seconds)
[Complete pitch]

### Boilerplate (Company Description)
**Short (25 words):**
[Description]

**Medium (50 words):**
[Description]

**Long (100 words):**
[Description]

### Key Messages
| Message | When to Use | Supporting Points |
|---------|-------------|-------------------|
| [Message 1] | [Context] | [3 supporting points] |
| [Message 2] | [Context] | [3 supporting points] |
| [Message 3] | [Context] | [3 supporting points] |

### Objection Handling
| Objection | Response | Proof |
|-----------|----------|-------|
| "[Common objection 1]" | [How to address] | [Supporting evidence] |
| "[Common objection 2]" | [How to address] | [Supporting evidence] |
| "[Common objection 3]" | [How to address] | [Supporting evidence] |

### Competitive Responses
| Competitor | Their Claim | Our Response |
|------------|-------------|--------------|
| [Competitor 1] | [What they say] | [How we counter] |
| [Competitor 2] | [What they say] | [How we counter] |
```

### Phase 5: Channel Adaptation

Adapt messaging by channel:

```markdown
## Channel-Specific Messaging

### Website
**Homepage Headline:** [Headline]
**Homepage Subhead:** [Subhead]
**Product Page Headline:** [Headline]
**CTA:** [Primary call to action]

### Email
**Subject Line Templates:**
- [Template 1]
- [Template 2]
**Email Body Opening:** [Opening line]

### Social Media
**LinkedIn:** [Tone and sample post]
**Twitter/X:** [Tone and sample post]

### Sales Materials
**One-Liner:** [Sales opener]
**Discovery Questions:**
1. [Question 1]
2. [Question 2]
3. [Question 3]

### Advertising
**Headline Options:**
- [Option 1]
- [Option 2]
- [Option 3]
**Body Copy Direction:** [Guidance]
```

## Output Format

```markdown
# Messaging Framework: [Product/Feature]

## Executive Summary
- **Primary Value Prop:** [One sentence]
- **Messaging Pillars:** [3 pillars]
- **Target Personas:** [From positioning]
- **Messaging Status:** DRAFT/FINAL

## Messaging Foundation
[Phase 1 output]

## Value Propositions
[Phase 2 output]

## Proof Points
[Phase 3 output]

## Messaging Framework
[Phase 4 output]

## Channel Adaptation
[Phase 5 output]

## Next Steps
1. **Stakeholder Review:** [Who needs to approve]
2. **Proof Point Collection:** [What's needed]
3. **Message Testing:** [Recommended validation]

## Dependencies
- Positioning: [Link to positioning.md]
- Market Analysis: [Link to market-analysis.md]
```

## Blocker Criteria

| Blocker | Action |
|---------|--------|
| No positioning | STOP. Complete positioning-development first. |
| No proof points available | STOP. Document proof gaps. Cannot make claims without evidence. |
| Conflicting brand guidelines | STOP. Align on voice/tone before messaging. |
| Unclear personas | STOP. Cannot tailor messaging without persona clarity. |

## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Gate-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Messaging is just copywriting" | Messaging is strategy, copywriting is execution | **Build strategic framework first** |
| "We'll find proof points later" | Claims without proof damage credibility | **Document proof gaps, don't make unfounded claims** |
| "One message works for everyone" | Different personas have different pain points | **Tailor messaging by persona** |
| "Voice/tone is subjective" | Inconsistent voice confuses market | **Define and document voice guidelines** |

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Gate-Specific Pressures

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| "Just write the copy" | "Skip the framework, write website copy" | "Copy without framework creates inconsistency. Building framework first." |
| "Make bigger claims" | "Competitors say X, we should say X+1" | "Unsubstantiated claims damage credibility. Claims must have proof." |
| "Everyone does feature messaging" | "List features like competitors" | "Benefit messaging outperforms feature messaging. Leading with benefits." |

## Execution Report

Base metrics per [shared-patterns/execution-report.md](../shared-patterns/execution-report.md):

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Gate-Specific Details
- value_props_created: N
- personas_covered: N
- proof_points_documented: N
- proof_gaps_identified: N
- channels_adapted: N
- tone_consistency: PASS/FAIL
