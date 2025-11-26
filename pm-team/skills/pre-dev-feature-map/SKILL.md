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
- Difficulty prioritizing work without understanding dependencies

**The Feature Map answers**: How do features relate, group, and interact at a business level?
**The Feature Map never answers**: How we'll technically implement those features (that's TRD).

## When to Use This Skill

Use this skill when:
- PRD has passed Gate 1 validation
- About to start technical architecture (TRD)
- Need to understand feature scope and relationships
- Multiple features have complex interactions
- Unclear how to group or prioritize features

## Mandatory Workflow

### Phase 1: Feature Analysis (Inputs Required)
1. **Approved PRD** (Gate 1 passed) - business requirements locked
2. **Extract all features** from PRD
3. **Identify user journeys** across features
4. **Map feature interactions** and dependencies

### Phase 2: Feature Mapping
1. **Categorize features** (Core/Supporting/Enhancement/Integration)
2. **Group into domains** (logical business groupings)
3. **Map user journeys** (how users flow through features)
4. **Identify integration points** (where features interact)
5. **Define boundaries** (what each feature owns)
6. **Visualize relationships** (diagrams or structured text)
7. **Prioritize by value** (core vs. nice-to-have)

### Phase 3: Gate 2 Validation
**MANDATORY CHECKPOINT** - Must pass before proceeding to TRD:
- [ ] All PRD features are mapped
- [ ] Feature categories are clearly defined
- [ ] Domain groupings are logical and cohesive
- [ ] User journeys are complete (start to finish)
- [ ] Integration points are identified
- [ ] Feature boundaries are clear (no overlap)
- [ ] Priority levels support phased delivery
- [ ] No technical implementation details included

## Explicit Rules

### ✅ DO Include in Feature Map
- Feature list (extracted from PRD)
- Feature categories (Core/Supporting/Enhancement/Integration)
- Domain groupings (logical business areas)
- User journey maps (how users move through features)
- Feature interactions (which features depend on/trigger others)
- Integration points (where features exchange data/events)
- Feature boundaries (what each feature owns)
- Priority levels (MVP vs. future phases)
- Scope visualization (what's in/out of each phase)

### ❌ NEVER Include in Feature Map
- Technical architecture or component design
- Technology choices or framework decisions
- Database schemas or API specifications
- Implementation approaches or algorithms
- Infrastructure or deployment concerns
- Code structure or file organization
- Protocol choices or data formats

### Feature Categorization Rules
1. **Core**: Must have for MVP, blocks other features
2. **Supporting**: Enables core features, medium priority
3. **Enhancement**: Improves existing features, nice-to-have
4. **Integration**: Connects to external systems, varies by need

### Domain Grouping Rules
1. Group features by business capability (not technical layer)
2. Each domain should have cohesive, related features
3. Minimize cross-domain dependencies
4. Name domains by business function (User Management, Payment Processing)

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

Before proceeding to TRD, verify:

**Feature Completeness**:
- [ ] All PRD features are included in map
- [ ] Each feature has clear description and purpose
- [ ] Feature categories are assigned (Core/Supporting/Enhancement/Integration)
- [ ] No features are missing or overlooked

**Grouping Clarity**:
- [ ] Domains are logically cohesive (related business capabilities)
- [ ] Domain boundaries are clear (no overlapping responsibilities)
- [ ] Cross-domain dependencies are minimized
- [ ] Domain names reflect business function (not technical layer)

**Journey Mapping**:
- [ ] Primary user journeys are documented (start to finish)
- [ ] Journeys show which features users touch
- [ ] Happy path and error scenarios covered
- [ ] Handoff points between features identified

**Integration Points**:
- [ ] All feature interactions are identified
- [ ] Data/event exchange points are marked
- [ ] Directional dependencies are clear (A depends on B)
- [ ] Circular dependencies are flagged and resolved

**Priority & Phasing**:
- [ ] MVP features clearly identified
- [ ] Priority rationale is documented
- [ ] Phasing supports incremental value delivery
- [ ] Dependencies don't block MVP delivery

**Gate Result**:
- ✅ **PASS**: All checkboxes checked → Proceed to TRD
- ⚠️ **CONDITIONAL**: Clarify ambiguous boundaries → Re-validate
- ❌ **FAIL**: Features poorly grouped or missing → Rework

## Feature Map Template

Use this structure:

```markdown
# Feature Map: [Project/Feature Name]

## Overview
- **PRD Reference**: [Link to approved PRD]
- **Last Updated**: [Date]
- **Status**: Draft / Under Review / Approved

## Feature Inventory

### Core Features (MVP)
| Feature ID | Feature Name | Description | User Value | Dependencies |
|------------|--------------|-------------|------------|--------------|
| F-001 | [Name] | [Brief description] | [What users gain] | [Other features] |
| F-002 | [Name] | [Brief description] | [What users gain] | [Other features] |

### Supporting Features
| Feature ID | Feature Name | Description | User Value | Dependencies |
|------------|--------------|-------------|------------|--------------|
| F-101 | [Name] | [Brief description] | [What users gain] | [Other features] |

### Enhancement Features (Post-MVP)
| Feature ID | Feature Name | Description | User Value | Dependencies |
|------------|--------------|-------------|------------|--------------|
| F-201 | [Name] | [Brief description] | [What users gain] | [Other features] |

### Integration Features
| Feature ID | Feature Name | Description | User Value | Dependencies |
|------------|--------------|-------------|------------|--------------|
| F-301 | [Name] | [Brief description] | [What users gain] | [Other features] |

## Domain Groupings

### Domain 1: [Business Domain Name]
**Purpose**: [What business capability this domain provides]

**Features**:
- F-001: [Feature name]
- F-002: [Feature name]
- F-101: [Feature name]

**Boundaries**:
- **Owns**: [What data/processes this domain is responsible for]
- **Consumes**: [What it needs from other domains]
- **Provides**: [What it offers to other domains]

**Integration Points**:
- → Domain 2: [What/why they interact]
- ← Domain 3: [What/why they interact]

### Domain 2: [Business Domain Name]
[Same structure as Domain 1]

## User Journeys

### Journey 1: [Journey Name]
**User Type**: [Primary persona from PRD]
**Goal**: [What user wants to accomplish]

**Path**:
1. **[Feature F-001]**: [User action and feature response]
   - Integration: [If interacts with another feature]
2. **[Feature F-002]**: [User action and feature response]
3. **[Feature F-003]**: [User action and feature response]
   - Success: [What happens on success]
   - Failure: [What happens on failure, which feature handles]

**Cross-Domain Interactions**:
- Domain 1 → Domain 2: [What data/event passes between]
- Domain 2 → Domain 3: [What data/event passes between]

### Journey 2: [Journey Name]
[Same structure]

## Feature Interaction Map

### High-Level Relationships
```
[Visual or structured text showing feature relationships]

Example:
┌─────────────────┐
│  User Auth      │ (Core)
│  F-001          │
└────────┬────────┘
         │ provides identity to
         ↓
┌─────────────────┐     ┌──────────────────┐
│ User Profile    │────→│ File Upload      │
│ F-002           │     │ F-003            │
└─────────────────┘     └──────────────────┘
   (Core)                  (Supporting)
         │
         │ triggers
         ↓
┌─────────────────┐
│ Notifications   │
│ F-101           │
└─────────────────┘
   (Supporting)
```

### Dependency Matrix
| Feature | Depends On | Blocks | Optional |
|---------|-----------|--------|----------|
| F-001 | None | F-002, F-003 | - |
| F-002 | F-001 | F-101 | F-003 |
| F-003 | F-001 | None | F-002 |
| F-101 | F-002 | None | - |

## Phasing Strategy

### Phase 1 - MVP (Core Features)
**Goal**: [Minimum viable product goal]
**Timeline**: [Estimated timeframe]

**Features**:
- F-001: User Auth
- F-002: User Profile
- F-003: File Upload

**User Value**: [What users can do after Phase 1]
**Success Criteria**: [How we measure Phase 1 success]

### Phase 2 - Enhancement
**Goal**: [Enhancement goal]
**Triggers**: [What conditions trigger Phase 2]

**Features**:
- F-101: Notifications
- F-102: Advanced Search
- F-201: Social Sharing

**User Value**: [What users gain in Phase 2]

### Phase 3 - Integration
**Goal**: [Integration goal]

**Features**:
- F-301: External Payment Gateway
- F-302: Third-party Analytics

**User Value**: [What users gain in Phase 3]

## Scope Boundaries

### In Scope (This Feature Map)
- [Feature area 1]
- [Feature area 2]
- [Feature area 3]

### Out of Scope (Future / Other Projects)
- [Feature area X] - Rationale: [Why out of scope]
- [Feature area Y] - Rationale: [Why out of scope]

### Assumptions
- [Assumption 1 about features or interactions]
- [Assumption 2]

### Constraints
- [Business constraint 1 that affects feature scope]
- [Business constraint 2]

## Risk Assessment

### Feature Complexity Risks
| Feature | Complexity | Risk | Mitigation |
|---------|-----------|------|------------|
| F-001 | High | User adoption | [How to mitigate] |
| F-003 | Medium | Scope creep | [How to mitigate] |

### Integration Risks
| Integration Point | Risk | Impact | Mitigation |
|-------------------|------|--------|------------|
| F-001 → F-002 | [Risk description] | High | [Mitigation] |
| F-002 → F-101 | [Risk description] | Medium | [Mitigation] |

## Gate 2 Validation

**Validation Date**: [Date]
**Validated By**: [Person/team]

- [ ] All PRD features mapped
- [ ] Domain groupings are logical
- [ ] User journeys are complete
- [ ] Integration points identified
- [ ] Priorities support phased delivery
- [ ] No technical details included
- [ ] Ready for TRD architecture design

**Approval**: ☐ Approved | ☐ Needs Revision | ☐ Rejected
**Next Step**: Proceed to TRD Creation (pre-dev-trd-creation)
```

## Common Violations and Fixes

### Violation 1: Technical Details in Feature Descriptions
❌ **Wrong**:
```markdown
### F-001: User Authentication
- Description: JWT-based auth with PostgreSQL session storage
- Dependencies: Database, Redis cache, OAuth2 service
```

✅ **Correct**:
```markdown
### F-001: User Authentication
- Description: Users can create accounts and securely log in
- User Value: Access to personalized features
- Dependencies: None (foundational)
- Blocks: F-002 (Profile), F-003 (Upload)
```

### Violation 2: Technical Components in Domain Groupings
❌ **Wrong**:
```markdown
### Domain: Auth Services
- AuthService component
- TokenValidator component
- SessionManager component
```

✅ **Correct**:
```markdown
### Domain: User Identity
**Purpose**: Managing user accounts, authentication, and session lifecycle

**Features**:
- F-001: User Registration
- F-002: User Login
- F-003: Session Management
- F-004: Password Recovery

**Boundaries**:
- **Owns**: User credentials, session state, login history
- **Provides**: Identity verification to all other domains
- **Consumes**: Email service for notifications
```

### Violation 3: Implementation in Integration Points
❌ **Wrong**:
```markdown
### Integration Points
- User Auth → Profile: REST API call to /api/profile with JWT
- Profile → Storage: S3 upload via pre-signed URL
```

✅ **Correct**:
```markdown
### Integration Points
- User Auth → Profile: Provides verified user identity
- Profile → File Storage: Requests secure file storage for user uploads
- File Storage → Notifications: Triggers notification when upload completes
```

## Confidence Scoring

```yaml
Confidence Factors:
  Feature Coverage: [0-25]
    - All PRD features mapped: 25
    - Most features mapped: 15
    - Some features missing: 5

  Relationship Clarity: [0-25]
    - All interactions documented: 25
    - Most interactions clear: 15
    - Relationships unclear: 5

  Domain Cohesion: [0-25]
    - Domains are logically cohesive: 25
    - Domains mostly cohesive: 15
    - Poor domain boundaries: 5

  Journey Completeness: [0-25]
    - All user paths mapped: 25
    - Primary paths mapped: 15
    - Journeys incomplete: 5

Total: [0-100]

Action:
  80+: Feature map complete, proceed to TRD
  50-79: Address gaps, re-validate
  <50: Rework groupings and relationships
```

## Output Location

**Always output to**: `docs/pre-development/feature-map/feature-map-[feature-name].md`

## After Feature Map Approval

1. ✅ Lock the Feature Map - feature scope and relationships are now reference
2. 🎯 Use Feature Map as input for TRD (next phase)
3. 🚫 Never add technical architecture to Feature Map retroactively
4. 📋 Keep business features separate from technical components

## Quality Self-Check

Before declaring Feature Map complete, verify:
- [ ] All PRD features are included and categorized
- [ ] Domain groupings are cohesive and logical
- [ ] User journeys show cross-feature flows
- [ ] Integration points are identified (WHAT interacts, not HOW)
- [ ] Feature boundaries are clear (no overlap)
- [ ] Priority levels support phased delivery
- [ ] Dependencies don't create circular blocks
- [ ] Zero technical implementation details present
- [ ] Gate 2 validation checklist 100% complete

## The Bottom Line

**If you wrote a Feature Map with technical architecture details, remove them.**

The Feature Map is business-level feature relationships only. Period. No components. No APIs. No databases.

Technical architecture goes in TRD. That's the next phase. Wait for it.

Violating this separation means:
- You're constraining architecture before understanding feature interactions
- Feature groupings become coupled to technical layers
- You can't objectively design architecture that matches business needs
- Boundaries become technical instead of business-driven

**Map the features. Understand relationships. Then architect in TRD.**
