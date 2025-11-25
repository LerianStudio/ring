---
name: pre-dev-prd-creation
description: Use when starting product development, before writing technical specs, when tempted to mix business and technical concerns, or when user asks to "plan a feature"
---

# PRD Creation - Business Before Technical

## Foundational Principle

**Business requirements (WHAT/WHY) must be fully defined before technical decisions (HOW/WHERE).**

Mixing business and technical concerns creates:
- Requirements that serve implementation convenience, not user needs
- Technical constraints that limit product vision
- Inability to evaluate alternatives objectively
- Cascade failures when requirements change

**The PRD answers**: WHAT we're building and WHY it matters to users and business.
**The PRD never answers**: HOW we'll build it or WHERE components will live.

## When to Use This Skill

Use this skill when:
- Starting a new product or major feature
- User asks to "plan", "design", or "architect" something
- About to write code without documented requirements
- Tempted to add technical details to business requirements
- Asked to create a PRD or requirements document

## Mandatory Workflow

### Phase 1: Problem Discovery
1. **Define the problem** without solution bias
2. **Identify users** specifically (not "users" generally)
3. **Quantify pain** with metrics or qualitative evidence

### Phase 2: Business Requirements
1. **Write Executive Summary** (problem + solution + impact in 3 sentences)
2. **Create User Personas** with real goals and frustrations
3. **Write User Stories** in format: "As [persona], I want [action] so that [benefit]"
4. **Define Success Metrics** that are measurable
5. **Set Scope Boundaries** (in/out explicitly)

### Phase 3: Gate 1 Validation
**MANDATORY CHECKPOINT** - Must pass before proceeding to Feature Map:
- [ ] Problem is clearly articulated
- [ ] Impact is quantified or qualified
- [ ] Users are specifically identified
- [ ] Features address core problem
- [ ] Success metrics are measurable
- [ ] In/out of scope is explicit

## Explicit Rules

### ✅ DO Include in PRD
- Problem definition and user pain points
- User personas with demographics, goals, frustrations
- User stories with acceptance criteria
- Feature requirements (WHAT it does, not HOW)
- Success metrics (user adoption, satisfaction, business KPIs)
- Scope boundaries (in/out explicitly)
- Go-to-market considerations

### ❌ NEVER Include in PRD
- Architecture diagrams or component design
- Technology choices (languages, frameworks, databases)
- Implementation approaches or algorithms
- Database schemas or API specifications
- Code examples or package dependencies
- Infrastructure needs or deployment strategies
- System integration patterns

### Separation Rules
1. **If it's a technology name** → Not in PRD (goes in Dependency Map)
2. **If it's a "how to build"** → Not in PRD (goes in TRD)
3. **If it's implementation** → Not in PRD (goes in Tasks/Subtasks)
4. **If it describes system behavior** → Not in PRD (goes in TRD)

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Just a quick technical note won't hurt" | Technical details constrain business thinking. Keep them separate. |
| "Stakeholders need to know it's feasible" | Feasibility comes in TRD after business requirements are locked. |
| "The implementation is obvious" | Obvious to you ≠ obvious to everyone. Separate concerns. |
| "I'll save time by combining PRD and TRD" | You'll waste time rewriting when requirements change. |
| "This is a simple feature, no need for formality" | Simple features still need clear requirements. Follow the process. |
| "I can skip Gate 1, I know it's good" | Gates exist because humans are overconfident. Validate. |
| "The problem is obvious, no need for personas" | Obvious to you ≠ validated with users. Document it. |
| "Success metrics can be defined later" | Defining metrics later means building without targets. Do it now. |
| "I'll just add this one API endpoint detail" | API design is technical architecture. Stop. Keep it in TRD. |
| "But we already decided on PostgreSQL" | Technology decisions come after business requirements. Wait. |
| "CEO/CTO says it's a business constraint" | Authority doesn't change what's technical. Abstract it anyway. |
| "Investors need to see specific vendors/tech" | Show phasing and constraints abstractly. Vendors go in TRD. |
| "This is product scoping, not technical design" | Scope = capabilities. Technology = implementation. Different things. |
| "Mentioning Stripe shows we're being practical" | Mentioning "payment processor" shows the same. Stay abstract. |
| "PRDs can mention tech when it's a constraint" | PRDs mention capabilities needed. TRD maps capabilities to tech. |
| "Context matters - this is for exec review" | Context doesn't override principles. Executives get abstracted version. |

## Red Flags - STOP

If you catch yourself writing or thinking any of these in a PRD, **STOP**:

- Technology product names (PostgreSQL, Redis, Kafka, AWS, etc.)
- Framework or library names (React, Fiber, Express, etc.)
- Words like: "architecture", "component", "service", "endpoint", "schema"
- Phrases like: "we'll use X to do Y" or "the system will store data in Z"
- Code examples or API specifications
- "How we'll implement" or "Technical approach"
- Database table designs or data models
- Integration patterns or protocols

**When you catch yourself**: Move that content to a "technical notes" section to transfer to TRD later. Keep PRD pure business.

## Gate 1 Validation Checklist

Before proceeding to TRD, verify:

**Problem Definition**:
- [ ] Problem is clearly articulated in 1-2 sentences
- [ ] Impact is quantified (metrics) or qualified (evidence)
- [ ] Users are specifically identified (not just "users")
- [ ] Current workarounds are documented

**Solution Value**:
- [ ] Features address the core problem (not feature creep)
- [ ] Success metrics are measurable and specific
- [ ] ROI case is reasonable and documented
- [ ] User value is clear for each feature

**Scope Clarity**:
- [ ] In-scope items are explicitly listed
- [ ] Out-of-scope items are explicitly listed with rationale
- [ ] Assumptions are documented
- [ ] Dependencies are identified (business, not technical)

**Market Fit**:
- [ ] Differentiation from alternatives is clear
- [ ] User value proposition is validated
- [ ] Business case is sound
- [ ] Go-to-market approach outlined

**Gate Result**:
- ✅ **PASS**: All checkboxes checked → Proceed to Feature Map (`pre-dev-feature-map`)
- ⚠️ **CONDITIONAL**: Address specific gaps → Re-validate
- ❌ **FAIL**: Multiple issues → Return to discovery

## Common Violations and Fixes

### Violation 1: Technical Details in Features
❌ **Wrong**:
```markdown
**FR-001: User Authentication**
- Use JWT tokens for session management
- Store passwords with bcrypt
- Implement OAuth2 with Google/GitHub providers
```

✅ **Correct**:
```markdown
**FR-001: User Authentication**
- Description: Users can create accounts and securely log in
- User Value: Access personalized content without re-entering credentials
- Success Criteria: 95% of users successfully authenticate on first attempt
- Priority: Must-have
```

### Violation 2: Implementation in User Stories
❌ **Wrong**:
```markdown
As a user, I want to store my data in PostgreSQL
so that queries are fast.
```

✅ **Correct**:
```markdown
As a user, I want to see my dashboard load in under 2 seconds
so that I can quickly access my information.
```

### Violation 3: Architecture in Problem Definition
❌ **Wrong**:
```markdown
**Problem**: Our microservices architecture doesn't support
real-time notifications, so users miss important updates.
```

✅ **Correct**:
```markdown
**Problem**: Users miss important updates because they must
manually refresh the page. 78% of users report missing
time-sensitive information.
```

### Violation 4: Authority-Based Technical Bypass
❌ **Wrong** (CEO requests):
```markdown
## MVP Scope

MVP (3 months):
- Stripe for payment processing (fastest integration)
- Support EUR, GBP, JPY
- Store conversions in PostgreSQL (we already use it)

Phase 2:
- Maybe switch to Adyen if Stripe doesn't scale
```

✅ **Correct** (abstracted):
```markdown
## MVP Scope

Phase 1 - Market Validation (0-3 months):
- **Payment Processing**: Integrate with existing payment vendor (2-week integration timeline)
- **Currency Support**: EUR, GBP, JPY (covers 65% of international traffic)
- **Data Storage**: Leverage existing database infrastructure (zero operational overhead)
- **Success Criteria**: 100 transactions in 30 days, <5% failure rate

Phase 2 - Scale & Optimize (4-6 months):
- **Trigger**: >1,000 monthly transactions OR processing costs >$50k/month
- **Scope**: Additional currencies based on Phase 1 demand data
- **Optimization**: Re-evaluate payment processor if fees exceed 3% of revenue

**Constraint Rationale**: Phase 1 prioritizes speed-to-market over flexibility.
Technical decisions will be documented in TRD with specific vendor selection.
```

**Key Principle**: Authority figures (CEO, CTO, investors) may REQUEST technical specifics, but your job is to ABSTRACT them. "We'll use Stripe" becomes "existing payment vendor". "PostgreSQL" becomes "existing database infrastructure". The capability is documented; the implementation waits for TRD.

## Confidence Scoring

Use this to adjust your interaction with the user:

```yaml
Confidence Factors:
  Market Validation: [0-25]
    - Direct user feedback: 25
    - Market research: 15
    - Assumptions: 5

  Problem Clarity: [0-25]
    - Quantified pain: 25
    - Qualitative evidence: 15
    - Hypothetical: 5

  Solution Fit: [0-25]
    - Proven pattern: 25
    - Adjacent pattern: 15
    - Novel approach: 5

  Business Value: [0-25]
    - Clear ROI: 25
    - Indirect value: 15
    - Uncertain: 5

Total: [0-100]

Action:
  80+: Generate complete PRD autonomously
  50-79: Present options for user selection
  <50: Ask discovery questions
```

## Output Location

**Always output to**: `docs/pre-development/prd/prd-[feature-name].md`

## After PRD Approval

1. ✅ Lock the PRD - no more changes without formal amendment
2. 🎯 Use PRD as input for Feature Map (next phase: `pre-dev-feature-map`)
3. 🚫 Never add technical details to PRD retroactively
4. 📋 Keep business/technical concerns strictly separated

## Quality Self-Check

Before declaring PRD complete, verify:
- [ ] Zero technical implementation details present
- [ ] All technology names removed
- [ ] User needs clearly articulated
- [ ] Success metrics are measurable and specific
- [ ] Scope boundaries are explicit and justified
- [ ] Business value is clearly justified
- [ ] User journeys are complete (current vs. proposed)
- [ ] Risks are identified with business impact
- [ ] Gate 1 validation checklist 100% complete

## The Bottom Line

**If you wrote a PRD with technical details, delete it and start over.**

The PRD is business-only. Period. No exceptions. No "just this once". No "but it's relevant".

Technical details go in TRD. That's the next phase. Wait for it.

Violating this separation means:
- You're optimizing for technical convenience, not user needs
- Requirements will change and break your technical assumptions
- You can't objectively evaluate technical alternatives
- The business case becomes coupled to implementation choices

**Follow the separation. Your future self will thank you.**
