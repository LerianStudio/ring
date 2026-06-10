---
name: ring:mapping-feature-relationships
description: "Mapping how features relate and phasing the work: categorizing PRD features, grouping them into domains, charting cross-feature journeys, dependencies, and integration points, and defining the binding Phases that plan.md mirrors one-to-one at Gate 7. Gate 2 of ring:planning-large-features; runs after ring:writing-prds, before ring:writing-trds. Use for Large Track features with multiple interacting parts. Skip for Small Track or a single simple feature."
---

# Feature Map Creation — Relationships and Phasing

## When to use

- PRD passed Gate 1 validation
- Multiple features with complex interactions
- Need to understand feature scope, relationships, and delivery phasing
- Large Track workflow (2+ day features)

## Skip when

- Small Track workflow (<2 days) → skip to TRD
- Single simple feature → TRD directly
- PRD not validated → complete Gate 1 first

## Sequence

**Runs before:** ring:writing-trds
**Runs after:** ring:writing-prds

Maps HOW features relate, group, and interact at a business level before architectural decisions — and defines the phasing of the work. **This is the main document where the squad validates the PHASING:** each phase defined here becomes, one-to-one, a phase in `plan.md` at Gate 7 (ring:writing-plans consumes the `## Phases` section as the binding phase structure).

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Feature Analysis** | Load approved PRD (Gate 1); extract all features; identify user journeys; map feature interactions |
| **2. Feature Mapping** | Categorize (Core/Supporting/Enhancement/Integration); group into domains; map user journeys; identify integration points and dependencies; define boundaries; prioritize by value |
| **3. Phasing** | Slice features into delivery phases; name each phase and its milestone; assign every feature, relationship, and integration point to exactly one phase; order phases by dependency (no phase depends on a later phase) |
| **4. Gate 2 Validation** | All PRD features mapped AND assigned to a phase; categories defined; domains logical; journeys complete; integration points identified; phase ordering respects dependencies; no technical details |

## Categorization Rules

| Category | Criteria |
|----------|---------|
| **Core** | Must have for MVP; blocks other features |
| **Supporting** | Enables core features; medium priority |
| **Enhancement** | Improves existing; nice-to-have |
| **Integration** | Connects to external systems |

## Domain Grouping Rules

- Group by business capability (not technical layer)
- Each domain = cohesive related features
- Minimize cross-domain dependencies
- Name by business function: "User Management", "Payment Processing"

## Phasing Rules

- Every feature, relationship, and integration point lands in exactly one phase
- A phase ships a coherent, verifiable milestone — not an arbitrary slice
- Dependencies flow forward only: a phase may depend on earlier phases, never later ones
- Phase names and order are **binding**: ring:writing-plans (Gate 7) creates exactly one plan phase per feature-map phase, same names, same order
- Changing phasing after Gate 2 means updating feature-map.md first, then regenerating downstream artifacts

## Include in Feature Map

- Feature list (from PRD) with categories
- Domain groupings (business areas)
- User journey maps (cross-feature flows)
- Feature interactions, dependencies, and integration points
- Feature boundaries and priorities
- `## Phases` section (binding phase structure for plan.md)

## Never Include

- Technical architecture or components
- Technology choices or frameworks
- Database schemas or API specifications
- Code structure, protocols, data formats
- Infrastructure or deployment details

## Output Format

**File:** `docs/pre-dev/{feature}/feature-map.md`

```markdown
# Feature Map: {Feature Name}

## Feature Categories

| Feature | Category | Domain | Priority | Dependencies |
|---------|----------|--------|----------|--------------|
| User Login | Core | Identity | P0 | — |
| Dashboard | Core | Analytics | P0 | User Login |
| Export PDF | Enhancement | Reporting | P2 | Dashboard |

## Domain Map

### Identity Domain
Features: User Login, Registration, Password Reset
Interactions: → Analytics (user context), → Reporting (audit trail)

### Analytics Domain
Features: Dashboard, Metrics View
Interactions: → Reporting (export), ← Identity (auth context)

## User Journeys

### Journey: New User Onboarding
Registration → Email Verification → Dashboard → First Transaction

### Journey: Power User Export
Dashboard → Filter Data → Export PDF → Download

## Integration Points

| Feature | Integrates With | Direction | Purpose |
|---------|----------------|-----------|---------|
| Dashboard | Analytics API | IN | Fetch aggregated metrics |
| Export PDF | File Storage | OUT | Upload generated report |

## Phases

### Phase 1: {Phase Name}
**Milestone:** {What is demonstrably working when this phase ships}
**Features:** User Login, Registration
**Relationships:** Identity → Analytics (user context)
**Integration Points:** —

### Phase 2: {Phase Name}
**Milestone:** {Verifiable milestone}
**Features:** Dashboard, Metrics View
**Relationships:** Analytics ← Identity (auth context)
**Integration Points:** Dashboard ← Analytics API

### Phase 3: {Phase Name}
**Milestone:** {Verifiable milestone}
**Features:** Export PDF
**Relationships:** Analytics → Reporting (export)
**Integration Points:** Export PDF → File Storage
```

**Phases contract:** each `### Phase N:` block carries a phase name, a milestone, and the features/relationships/integration points landing in it. ring:writing-plans (Gate 7) consumes this section as the binding phase structure — one plan phase per feature-map phase, one-to-one, same names and order.

## Gate 2 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Feature Completeness** | All PRD features included; categories assigned; none missing |
| **Grouping Clarity** | Domains logically cohesive; clear boundaries; named by business function |
| **Journey Coverage** | All major user journeys mapped; cross-feature flows complete |
| **Integration Points** | All external touchpoints identified; direction specified |
| **Phasing Completeness** | Every feature, relationship, and integration point assigned to exactly one phase; each phase has a name and milestone; ordering respects dependencies |
| **No Technical Details** | Zero technology names; zero component names; zero implementation details |

**Gate Result:** ✅ PASS → TRD (Gate 3) | ❌ FAIL (technical details, missing features, or incomplete phasing)
