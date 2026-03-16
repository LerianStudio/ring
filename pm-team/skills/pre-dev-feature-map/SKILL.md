---
name: pre-dev-feature-map
description: |
  Gate 2: Feature relationship map - visualizes feature landscape, groupings,
  and interactions at business level before technical architecture.
metadata:
  sequence:
    after:
    - ring:pre-dev-prd-creation
    before:
    - ring:pre-dev-trd-creation
  skip_when: |
    - Small Track workflow (<2 days) → skip to TRD
    - Single simple feature → TRD directly
    - PRD not validated → complete Gate 1 first
  trigger: |
    - PRD passed Gate 1 validation
    - Multiple features with complex interactions
    - Need to understand feature scope and relationships
    - Large Track workflow (2+ day features)
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
| **1. Feature Analysis** | Load approved PRD (Gate 1) and ux-criteria.md; extract all features; identify user journeys; map feature interactions and dependencies |
| **2. Feature Mapping** | Categorize (Core/Supporting/Enhancement/Integration); group into domains; map user journeys; identify integration points; define boundaries; visualize relationships; prioritize by value |
| **3. Gate 2 Validation** | All PRD features mapped; categories defined; domains logical; journeys complete; integration points identified; boundaries clear; priorities support phased delivery; no technical details |
| **4. UX Design** | Dispatch `product-designer` to create detailed user flows (Mermaid) and wireframe specifications (YAML) |

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

**Gate Result:** ✅ PASS → UX Design → TRD | ⚠️ CONDITIONAL (clarify boundaries) | ❌ FAIL (poor groupings/missing features)

## Phase 4: UX Design (Large Track Only)

**After Feature Map passes Gate 2 validation, dispatch product-designer for UX design:**

```
Task(
  subagent_type="ring:product-designer",
  prompt="Create detailed UX design based on PRD, ux-criteria.md, and feature-map.md at docs/pre-dev/{feature}/. Mode: ux-design. Create: user-flows.md with Mermaid diagrams for all user journeys (happy path, error paths, edge cases), wireframes/ directory with YAML specs for all screens, UI state documentation for all interactive elements."
)
```

**UX Design Outputs:**
- `docs/pre-dev/{feature}/user-flows.md` - Detailed user flows with Mermaid diagrams
- `docs/pre-dev/{feature}/wireframes/` - Directory with YAML wireframe specs per screen

**UX Design Checklist:**

| Check | Required |
|-------|----------|
| All user journeys from feature-map have flows | Yes |
| Happy path documented for each flow | Yes |
| Error paths documented for each flow | Yes |
| Edge cases identified and documented | Yes |
| Wireframe spec for each unique screen | Yes |
| All UI states defined (loading, error, empty, success) | Yes |
| Responsive behavior documented | Yes |
| Accessibility requirements in specs | Yes |

**If UX Design fails:**
- Missing flow → Add flow for user journey
- Missing state → Add state definition
- Incomplete wireframe → Enhance spec with missing components
- Accessibility gaps → Add a11y requirements

**Note:** This phase is for Large Track only (2+ day features). Small Track skips to TRD directly.

## Feature Map Template Structure

Output to `docs/pre-dev/{feature-name}/feature-map.md` with these sections:

| Section | Content |
|---------|---------|
| **Overview** | PRD reference, status, last updated |
| **Feature Inventory** | Tables by category (Core/Supporting/Enhancement/Integration): Feature ID, Name, Description, User Value, Dependencies |
| **Domain Groupings** | Per domain: Purpose, Features list, Boundaries (Owns/Consumes/Provides), Integration Points (→/←) |
| **User Journeys** | Per journey: User Type, Goal, Path (steps with features, integrations, success/failure), Cross-Domain Interactions |
| **Feature Interaction Map** | ASCII/text diagram with relationships, Dependency Matrix table (Feature, Depends On, Blocks, Optional) |
| **Backend Integration Points** | (Fullstack only) API dependencies per feature, data flow direction, BFF requirements |
| **Phasing Strategy** | Per phase: Goal, Timeline, Features, User Value, Success Criteria, Triggers for next phase |
| **Scope Boundaries** | In Scope, Out of Scope (with rationale), Assumptions, Constraints |
| **Risk Assessment** | Feature Complexity Risks table, Integration Risks table |
| **Gate 2 Validation** | Date, validator, checklist, approval, next step |

## Backend Integration Points (Fullstack Features)

**⛔ MANDATORY:** If `topology.scope: fullstack`, this section MUST be included.

### When This Applies

Check research.md frontmatter:
```yaml
topology:
  scope: fullstack  # ← This triggers backend integration documentation
```

### Backend Integration Documentation

**Add to feature-map.md under `## Backend Integration Points`:**

```markdown
## Backend Integration Points

### Overview
- **Topology:** Fullstack
- **API Pattern:** [direct | bff]
- **Backend Services:** List of backend services this feature depends on

### Per-Feature API Dependencies

| Feature | Backend Dependency | Data Direction | Notes |
|---------|-------------------|----------------|-------|
| F-001: User Dashboard | User Service | Read | Profile data |
| F-001: User Dashboard | Order Service | Read | Recent orders |
| F-002: Create Order | Order Service | Write | New order |
| F-002: Create Order | Inventory Service | Read | Stock check |

### Data Flow Summary

| Frontend Component | → | BFF/API | → | Backend Service |
|-------------------|---|---------|---|-----------------|
| DashboardPage | → | /api/dashboard | → | User + Order Services |
| OrderForm | → | /api/orders | → | Order + Inventory Services |

### BFF Requirements Matrix

| Feature | Needs BFF? | Reason |
|---------|-----------|--------|
| F-001 | Yes | Aggregates 2 services |
| F-002 | Yes | Needs inventory validation |
| F-003 | No | Single service, simple read |
```

### Integration Risk Identification

**Document risks related to backend dependencies:**

```markdown
### Integration Risks

| Feature | Backend Dependency | Risk | Mitigation |
|---------|-------------------|------|------------|
| F-001 | Order Service | Service unavailable | Graceful degradation |
| F-002 | Inventory Service | Stale stock data | Real-time check before submit |
```

### Rationalization Table for Backend Integration

| Excuse | Reality |
|--------|---------|
| "Backend integration is TRD concern" | TRD designs architecture. Feature Map identifies integration POINTS. Different scope. |
| "We'll figure out APIs during implementation" | Late API discovery causes frontend/backend misalignment. Document early. |
| "Feature Map is business only" | Integration points are business-level data flows. WHERE data comes from matters. |
| "API pattern is already in research.md" | Pattern is high-level. Feature Map documents per-feature specifics. |

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

**Outputs:**
- `docs/pre-dev/{feature-name}/feature-map.md` - Feature relationship map
- `docs/pre-dev/{feature-name}/user-flows.md` - Detailed user flows (from product-designer, Large Track only)
- `docs/pre-dev/{feature-name}/wireframes/` - Wireframe specifications (from product-designer, Large Track only)

1. ✅ Lock Feature Map - scope and relationships are now reference
2. ✅ Lock user-flows.md and wireframes/ - UX specs for implementation (Large Track)
3. 🎯 Use all as input for TRD (next phase)
4. 🚫 Never add technical architecture retroactively
5. 📋 Keep business features separate from technical components

## The Bottom Line

**If you wrote a Feature Map with technical architecture details, remove them.**

The Feature Map is business-level feature relationships only. Period. No components. No APIs. No databases.

Technical architecture goes in TRD. That's the next phase. Wait for it.

**Map the features. Understand relationships. Then architect in TRD.**

---

## Standards Loading (MANDATORY)

This skill is a business analysis skill and does NOT require WebFetch of language-specific standards.

**Purpose:** Feature Map defines business-level feature relationships and groupings. Technical standards are irrelevant at this stage—they apply during TRD (Gate 3) and implementation.

**However**, MUST load PRD (Gate 1) and ux-criteria.md to ensure feature map aligns with validated business requirements.

---

## Blocker Criteria - STOP and Report

| Condition | Action | Severity |
|-----------|--------|----------|
| PRD (Gate 1) not validated | STOP and complete Gate 1 first | CRITICAL |
| Technical architecture creeps into map | STOP and remove—keep business level only | HIGH |
| Feature domains have unclear boundaries | STOP and clarify domain ownership | HIGH |
| User journeys cross all domains (no cohesion) | STOP and re-evaluate domain groupings | MEDIUM |
| Backend integration points undefined (fullstack) | STOP and document API dependencies | HIGH |
| Circular feature dependencies detected | STOP and resolve dependency cycle | HIGH |

---

## Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST NOT include technical architecture or components
- MUST NOT include technology choices or frameworks
- MUST NOT include database schemas or API specifications
- MUST map ALL features from PRD (no missing features)
- MUST define feature categories (Core/Supporting/Enhancement/Integration)
- MUST define domain groupings with clear boundaries
- MUST document backend integration points for fullstack features
- MUST dispatch product-designer for UX Design (Large Track only)

---

## Severity Calibration

| Severity | Definition | Example |
|----------|------------|---------|
| **CRITICAL** | Cannot proceed with mapping | PRD not validated, no features to map |
| **HIGH** | Map contains forbidden content | Technical components, API specs |
| **MEDIUM** | Map incomplete but usable | Some journeys not fully documented |
| **LOW** | Minor documentation gaps | Integration point descriptions brief |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Include the component architecture" | "Cannot include components. Feature Map is business-level only. Components go in TRD." |
| "Feature relationships are obvious" | "Cannot assume obvious. Obvious to you ≠ documented for team. I'll map explicitly." |
| "Skip UX Design, we have wireframes" | "Cannot skip UX Design for Large Track. Wireframes need detailed flows and states. I'll dispatch product-designer." |
| "Mention the API dependencies" | "Cannot include API specifics. Document business-level integration points only. 'Feature A uses data from Feature B'." |
| "This feels like extra work" | "Cannot skip mapping. Skipping causes architecture-feature mismatch. 30 minutes now saves days of rework." |

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Feature relationships are obvious" | Obvious to you ≠ documented for team | **Map explicitly** |
| "We can figure out groupings during TRD" | TRD architecture follows feature structure | **Define groupings first** |
| "This feels like extra work" | Skipping causes rework when architecture mismatches features | **Complete the mapping** |
| "PRD already has this info" | PRD lists features; map shows relationships | **Different views, both needed** |
| "I'll just mention the components" | Components are technical (TRD territory) | **Keep business groupings only** |
| "User journeys are in the PRD" | PRD has stories; map shows cross-feature flows | **Different levels** |
| "Integration points are technical" | WHERE features interact = business. HOW = technical | **Document integration points** |

---

## When This Skill Is Not Needed

- Small Track workflow (< 2 days) → skip to TRD
- Single simple feature → TRD directly
- PRD (Gate 1) not validated → complete Gate 1 first
- Feature Map already exists and is validated
- Bug fix with no feature relationship changes
- Documentation-only updates
