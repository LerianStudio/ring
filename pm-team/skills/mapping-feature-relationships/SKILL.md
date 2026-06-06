---
name: ring:pre-dev-feature-map
description: |
  Gate 2: Feature relationship map - visualizes feature landscape, groupings,
  and interactions at business level before technical architecture.
---

# Feature Map Creation — Understanding the Feature Landscape

## When to use

- PRD passed Gate 1 validation
- Multiple features with complex interactions
- Need to understand feature scope and relationships
- Large Track workflow (2+ day features)

## Skip when

- Small Track workflow (<2 days) → skip to TRD
- Single simple feature → TRD directly
- PRD not validated → complete Gate 1 first

## Sequence

**Runs before:** ring:pre-dev-trd-creation
**Runs after:** ring:pre-dev-prd-creation


Maps HOW features relate, group, and interact at a business level before architectural decisions.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Feature Analysis** | Load approved PRD (Gate 1) and ux-criteria.md; extract all features; identify user journeys; map feature interactions |
| **2. Feature Mapping** | Categorize (Core/Supporting/Enhancement/Integration); group into domains; map user journeys; identify integration points; define boundaries; prioritize by value |
| **3. Gate 2 Validation** | All PRD features mapped; categories defined; domains logical; journeys complete; integration points identified; boundaries clear; no technical details |
| **4. UX Design** | Dispatch `product-designer` to create detailed user flows (Mermaid) and wireframe specifications (YAML) |

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

## Include in Feature Map

- Feature list (from PRD) with categories
- Domain groupings (business areas)
- User journey maps (cross-feature flows)
- Feature interactions and integration points
- Feature boundaries and priorities
- Scope visualization

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
```

## Gate 2 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Feature Completeness** | All PRD features included; categories assigned; none missing |
| **Grouping Clarity** | Domains logically cohesive; clear boundaries; named by business function |
| **Journey Coverage** | All major user journeys mapped; cross-feature flows complete |
| **Integration Points** | All external touchpoints identified; direction specified |
| **No Technical Details** | Zero technology names; zero component names; zero implementation details |

**Gate Result:** ✅ PASS → Design Validation (if UI) or TRD | ❌ FAIL (technical details or missing features)

After Gate 2 passes: dispatch `product-designer` with feature-map.md + ux-criteria.md to create detailed wireframes and user flows.
