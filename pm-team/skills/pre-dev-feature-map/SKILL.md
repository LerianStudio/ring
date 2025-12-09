---
name: pre-dev-feature-map
description: |
  Gate 2: Feature relationship map - visualizes feature landscape, groupings,
  and interactions at business level before technical architecture.

trigger: |
  - PRD passed Gate 1 validation
  - Multiple features with complex interactions
  - Need to understand feature scope and relationships
  - Large Track workflow (2+ day features)

skip_when: |
  - Small Track workflow (<2 days) → skip to TRD
  - Single simple feature → TRD directly
  - PRD not validated → complete Gate 1 first

sequence:
  after: [pre-dev-prd-creation]
  before: [pre-dev-trd-creation]
---

# Feature Map Creation - Understanding the Feature Landscape

## Foundational Principle

**Feature relationships and boundaries must be mapped before architectural decisions.**

Jumping from PRD to TRD without mapping creates:
- Architectures that don't match feature interaction patterns
- Missing integration points discovered late
- Poor module boundaries that cross feature concerns

**The Feature Map answers**: How do features relate, group, and interact at a business level?
**The Feature Map never answers**: How we'll technically implement those features (that's TRD).

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Feature Analysis** | Load approved PRD (Gate 1); extract all features; identify user journeys; map feature interactions and dependencies |
| **2. Feature Mapping** | Categorize (Core/Supporting/Enhancement/Integration); group into domains; map user journeys; identify integration points; define boundaries; visualize relationships; prioritize by value |
| **3. Gate 2 Validation** | All PRD features mapped; categories defined; domains logical; journeys complete; integration points identified; boundaries clear; priorities support phased delivery; no technical details |

## Explicit Rules

### ✅ DO Include
Feature list (from PRD), categories (Core/Supporting/Enhancement/Integration), domain groupings (business areas), user journey maps, feature interactions, integration points, feature boundaries, priority levels, scope visualization

### ❌ NEVER Include
Technical architecture/components, technology choices/frameworks, database schemas/API specs, implementation approaches, infrastructure/deployment, code structure, protocols/data formats

### Categorization Rules
- **Core**: Must have for MVP, blocks other features
- **Supporting**: Enables core features, medium priority
- **Enhancement**: Improves existing features, nice-to-have
- **Integration**: Connects to external systems

### Domain Grouping Rules
- Group by business capability (not technical layer)
- Each domain = cohesive related features
- Minimize cross-domain dependencies
- Name by business function (User Management, Payment Processing)

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Feature relationships are obvious" | Obvious to you ≠ documented for team. Map them. |
| "We can figure out groupings during TRD" | TRD architecture follows feature structure. Define it first. |
| "This feels like extra work" | Skipping this causes rework when architecture mismatches features. |
| "The PRD already has this info" | PRD lists features; map shows relationships. Different views. |
| "I'll just mention the components" | Components are technical (TRD). This is business groupings only. |
| "User journeys are in the PRD" | PRD has stories; map shows cross-feature flows. Different levels. |
| "Integration points are technical" | Points WHERE features interact = business. HOW = technical (TRD). |
| "Priorities can be set later" | Priority affects architecture decisions. Set them before TRD. |
| "Boundaries will be clear in code" | Code structure follows feature boundaries. Define them first. |
| "This is just a simple feature" | Even simple features have interactions. Map them. |

## Red Flags - STOP

If you catch yourself writing any of these in a Feature Map, **STOP**:

- Technology names (APIs, databases, frameworks)
- Component names (AuthService, PaymentProcessor)
- Technical terms (microservices, endpoints, schemas)
- Implementation details (how data flows technically)
- Architecture diagrams (system components)
- Code organization (packages, modules, files)
- Protocol specifications (REST, GraphQL, gRPC)

**When you catch yourself**: Remove the technical detail. Focus on WHAT features do and HOW they relate at a business level.

## Gate 2 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Feature Completeness** | All PRD features included; clear descriptions; categories assigned; none missing |
| **Grouping Clarity** | Domains logically cohesive; clear boundaries; cross-domain deps minimized; business function names |
| **Journey Mapping** | Primary journeys documented (start to finish); features touched shown; happy/error paths; handoffs identified |
| **Integration Points** | All interactions identified; data/event exchange points marked; directional deps clear; circular deps resolved |
| **Priority & Phasing** | MVP features identified; rationale documented; incremental value delivery; deps don't block MVP |

**Gate Result:** ✅ PASS → TRD | ⚠️ CONDITIONAL (clarify boundaries) | ❌ FAIL (poor groupings/missing features)

## Feature Map Template Structure

Output to `docs/pre-dev/{feature-name}/feature-map.md` with these sections:

| Section | Content |
|---------|---------|
| **Overview** | PRD reference, status, last updated |
| **Feature Inventory** | Tables by category (Core/Supporting/Enhancement/Integration): Feature ID, Name, Description, User Value, Dependencies |
| **Domain Groupings** | Per domain: Purpose, Features list, Boundaries (Owns/Consumes/Provides), Integration Points (→/←) |
| **User Journeys** | Per journey: User Type, Goal, Path (steps with features, integrations, success/failure), Cross-Domain Interactions |
| **Feature Interaction Map** | ASCII/text diagram with relationships, Dependency Matrix table (Feature, Depends On, Blocks, Optional) |
| **Phasing Strategy** | Per phase: Goal, Timeline, Features, User Value, Success Criteria, Triggers for next phase |
| **Scope Boundaries** | In Scope, Out of Scope (with rationale), Assumptions, Constraints |
| **Risk Assessment** | Feature Complexity Risks table, Integration Risks table |
| **Gate 2 Validation** | Date, validator, checklist, approval, next step |

## Common Violations

| Violation | Wrong | Correct |
|-----------|-------|---------|
| **Tech in Features** | `F-001: JWT-based auth with PostgreSQL sessions, Deps: Database, Redis cache` | `F-001: Users can create accounts and log in, User Value: Access personalized features, Deps: None (foundational), Blocks: F-002, F-003` |
| **Tech in Domains** | `Domain: Auth Services with AuthService, TokenValidator, SessionManager components` | `Domain: User Identity - Purpose: Managing user accounts and sessions. Features: Registration, Login, Session Mgmt, Password Recovery. Owns: credentials, session state. Provides: identity verification` |
| **Tech in Integration** | `User Auth → Profile: REST API call to /api/profile with JWT` | `User Auth → Profile: Provides verified user identity` |

## Confidence Scoring

| Factor | Points | Criteria |
|--------|--------|----------|
| Feature Coverage | 0-25 | All mapped: 25, Most: 15, Some missing: 5 |
| Relationship Clarity | 0-25 | All documented: 25, Most clear: 15, Unclear: 5 |
| Domain Cohesion | 0-25 | Logically cohesive: 25, Mostly: 15, Poor boundaries: 5 |
| Journey Completeness | 0-25 | All paths: 25, Primary: 15, Incomplete: 5 |

**Action:** 80+ proceed to TRD | 50-79 address gaps | <50 rework groupings

## Output & After Approval

**Output to:** `docs/pre-dev/{feature-name}/feature-map.md`

1. ✅ Lock Feature Map - scope and relationships are now reference
2. 🎯 Use as input for TRD (next phase)
3. 🚫 Never add technical architecture retroactively
4. 📋 Keep business features separate from technical components

## The Bottom Line

**If you wrote a Feature Map with technical architecture details, remove them.**

The Feature Map is business-level feature relationships only. Period. No components. No APIs. No databases.

Technical architecture goes in TRD. That's the next phase. Wait for it.

**Map the features. Understand relationships. Then architect in TRD.**
