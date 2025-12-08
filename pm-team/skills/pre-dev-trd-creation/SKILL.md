---
name: pre-dev-trd-creation
description: |
  Gate 3: Technical architecture document - defines HOW/WHERE with technology-agnostic
  patterns before concrete implementation choices.

trigger: |
  - PRD passed Gate 1 (required)
  - Feature Map passed Gate 2 (if Large Track)
  - About to design technical architecture
  - Tempted to specify "PostgreSQL" instead of "Relational Database"

skip_when: |
  - PRD not validated → complete Gate 1 first
  - Architecture already documented → proceed to API Design
  - Pure business requirement change → update PRD

sequence:
  after: [pre-dev-prd-creation, pre-dev-feature-map]
  before: [pre-dev-api-design, pre-dev-task-breakdown]
---

# TRD Creation - Architecture Before Implementation

## Foundational Principle

**Architecture decisions (HOW/WHERE) must be technology-agnostic patterns before concrete implementation choices.**

Specifying technologies in TRD creates:
- Vendor lock-in before evaluating alternatives
- Architecture coupled to specific products
- Inability to adapt to better options discovered later
- Technology decisions made without full dependency analysis

**The TRD answers**: HOW we'll architect the solution and WHERE components will live.
**The TRD never answers**: WHAT specific products, frameworks, versions, or packages we'll use.

## When to Use This Skill

Use this skill when:
- PRD has passed Gate 1 validation (REQUIRED)
- Feature Map has passed Gate 2 validation (optional - use if exists)
- About to design technical architecture
- Tempted to specify "PostgreSQL" instead of "Relational Database"
- Asked to create technical design or architecture document
- Before making technology choices

---

## ⛔ HARD BLOCK: Tech Stack Definition (Step 0)

**This is a HARD GATE. Do NOT proceed without defining the tech stack.**

Before designing architecture, you MUST determine the technology stack that will be used for implementation. This decision is made HERE in the TRD so that:
1. Architecture patterns align with chosen stack capabilities
2. Gates 4-6 inherit this decision (no repeated questions)
3. Ring Standards can be loaded to inform architectural patterns

### Step 0.1: Auto-Detect or Ask User

**First, attempt auto-detection:**

```text
Language Detection:
├── go.mod exists → Go project
├── package.json exists
│   ├── Has "react" or "next" → Frontend TypeScript
│   ├── Has backend deps (express, fastify, nestjs) → Backend TypeScript
│   └── Otherwise → Generic TypeScript
└── Multiple languages → Ask user to confirm
```

**If auto-detection fails or is ambiguous, ASK:**

```yaml
AskUserQuestion:
  questions:
    - question: "What is the primary technology stack for this feature?"
      header: "Tech Stack"
      multiSelect: true
      options:
        - label: "Go (Backend)"
          description: "Backend services, APIs, microservices in Go"
        - label: "TypeScript (Backend)"
          description: "Node.js backend with Express, Fastify, or NestJS"
        - label: "TypeScript (Frontend)"
          description: "React, Next.js, or similar frontend frameworks"
        - label: "Full-Stack TypeScript"
          description: "Both frontend and backend in TypeScript"
```

### Step 0.2: Load Ring Standards via WebFetch (MANDATORY)

**Based on tech stack selection, load the corresponding Ring Standards.**

**Available Ring Standards:**

| Standard | URL | Purpose |
|----------|-----|---------|
| **golang.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md` | Go backend patterns, error handling, DDD |
| **typescript.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md` | TypeScript backend patterns, Node.js standards |
| **frontend.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md` | React, Next.js, UI/UX patterns |
| **devops.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md` | Docker, CI/CD, infrastructure patterns |
| **sre.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md` | Observability, health checks, logging, tracing |

**Standards to Load by Tech Stack:**

| Tech Stack | Standards to Load |
|------------|-------------------|
| Go (Backend) | golang.md + devops.md + sre.md |
| TypeScript (Backend) | typescript.md + devops.md + sre.md |
| TypeScript (Frontend) | frontend.md + devops.md |
| Full-Stack TypeScript | typescript.md + frontend.md + devops.md + sre.md |

**WebFetch Commands:**

```yaml
# For Go Backend:
WebFetch:
  url: "https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md"
  prompt: "Extract architectural patterns, directory structure, error handling patterns, and DDD guidelines"

# For TypeScript Backend:
WebFetch:
  url: "https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md"
  prompt: "Extract architectural patterns, type safety requirements, async patterns, and error handling"

# For TypeScript Frontend:
WebFetch:
  url: "https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md"
  prompt: "Extract component patterns, state management, performance patterns, and accessibility requirements"

# ALWAYS load DevOps (all stacks):
WebFetch:
  url: "https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md"
  prompt: "Extract containerization patterns, CI/CD requirements, and infrastructure standards"

# ALWAYS load SRE (for backend stacks):
WebFetch:
  url: "https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md"
  prompt: "Extract health check patterns, logging standards, tracing requirements, and observability guidelines"
```

### Step 0.3: Read PROJECT_RULES.md (MANDATORY)

```text
Check sequence:
1. Look for: docs/PROJECT_RULES.md
2. If not found: Look for docs/STANDARDS.md (legacy name)
3. If not found: STOP - Cannot proceed without project standards
```

### Step 0.4: Analyze PRD and Suggest Project-Specific Technologies

**Read the PRD and suggest technologies/components that best address the solution requirements.**

These suggestions are **project-specific** and will be documented in `docs/PROJECT_RULES.md` (created in Gate 6).

**Ring Standards vs PROJECT_RULES.md:**

| Ring Standards | PROJECT_RULES.md |
|----------------|------------------|
| Coding patterns | Specific technologies |
| Observability standards | Auth provider choice |
| Logging format | Database choice |
| Error handling | Message broker choice |
| Shared across ALL projects | Specific to THIS project |

**Process:**

```text
1. Read docs/pre-dev/{feature-name}/PRD.md
2. Extract product requirements
3. Suggest technologies that address each requirement
4. Present suggestions to user
5. User confirms or modifies
6. Document in TRD metadata → Used by Gate 6 to create PROJECT_RULES.md
```

**AI reads PRD and suggests:**

Based on the PRD requirements, suggest technologies that can best address the solution. Present to user like:

```markdown
## Technology Suggestions Based on PRD

I read the PRD and identified these requirements that need specific technologies:

**[Requirement 1 from PRD]**
→ Suggested: [Technology] because [reason based on PRD context]

**[Requirement 2 from PRD]**
→ Suggested: [Technology] because [reason based on PRD context]

...

Do you agree with these suggestions? You can modify any of them.
```

**Ask user to confirm deployment model and suggestions:**

```yaml
AskUserQuestion:
  questions:
    - question: "What deployment model for this project?"
      header: "Deployment"
      multiSelect: false
      options:
        - label: "Cloud"
          description: "Managed cloud services"
        - label: "On-Premise"
          description: "Self-hosted infrastructure"
        - label: "Hybrid"
          description: "Mix of both"
```

### Step 0.5: Document Tech Stack in TRD Metadata

**The TRD MUST include all decisions. Gate 6 uses this to create PROJECT_RULES.md.**

```yaml
# At the top of docs/pre-dev/{feature}/trd.md

---
feature: {feature-name}
gate: 3

deployment:
  model: Cloud  # or On-Premise, Hybrid

tech_stack:
  primary: Go  # or TypeScript
  standards_loaded:
    - golang.md
    - devops.md
    - sre.md

# Project-specific technology decisions (used to generate PROJECT_RULES.md in Gate 6)
project_technologies:
  # Each entry references what PRD requirement it addresses
  # AI suggested, user confirmed/modified

  # Example entries - actual values come from PRD analysis:
  - category: "Authentication"
    prd_requirement: "[quote from PRD]"
    choice: "[user confirmed technology]"
    rationale: "[why this fits]"

  - category: "Database"
    prd_requirement: "[quote from PRD]"
    choice: "[user confirmed technology]"
    rationale: "[why this fits]"

  - category: "Message Broker"
    prd_requirement: "[quote from PRD]"
    choice: "[user confirmed technology]"
    rationale: "[why this fits]"

  # ... more based on PRD analysis
---
```

**This metadata flows to:**
- Gate 4 (API Design): Protocol patterns
- Gate 5 (Data Model): Storage patterns
- **Gate 6 (Dependency Map): Creates `docs/PROJECT_RULES.md` with concrete versions**

### BLOCKER Response if Step 0 Not Completed

```yaml
Blocker:
  type: "missing_prerequisite"
  message: |
    ⛔ HARD BLOCK: Cannot proceed with TRD.

    REQUIRED before architecture design:
    1. Tech stack defined (auto-detected or user-selected) ❌
    2. Ring Standards loaded via WebFetch ❌
    3. docs/PROJECT_RULES.md exists and read ❌

    Why is this mandatory?
    - Architecture patterns depend on tech stack capabilities
    - Ring Standards inform best practices for chosen stack
    - Gates 4-6 inherit this decision

    Resolution:
    - Answer tech stack question OR verify manifest files exist
    - Retry WebFetch for Ring Standards
    - Create docs/PROJECT_RULES.md if missing
```

### Pressure Resistance for Step 0

| Pressure | Response |
|----------|----------|
| "Tech stack doesn't matter for architecture" | "Architecture patterns vary by language. Go patterns ≠ TypeScript patterns. Define stack first." |
| "We'll decide tech stack later" | "Later = Dependency Map. But architecture NOW needs to know capabilities. Define stack." |
| "Just use generic patterns" | "Generic patterns miss stack-specific best practices. 5 min to define saves rework." |
| "Skip to save time" | "Skipping causes Gates 4-6 to ask again. Define once here, inherit everywhere." |

---

## Mandatory Workflow

### Phase 1: Technical Analysis (After Step 0)
1. **Approved PRD** (Gate 1 passed) - business requirements locked (REQUIRED)
2. **Approved Feature Map** (Gate 2 passed) - feature relationships mapped (OPTIONAL - check `docs/pre-dev/<feature-name>/feature-map.md`)
3. **Identify non-functional requirements** (performance, security, scalability)
4. **Map domains to components**:
   - If Feature Map exists: Map Feature Map domains to architectural components
   - If no Feature Map: Map PRD features directly to architectural components

### Phase 2: Architecture Definition
1. **Choose Architecture Style** (Microservices, Modular Monolith, Serverless)
2. **Design Components** with clear boundaries and responsibilities
3. **Define Interfaces** (inbound/outbound, contracts)
4. **Model Data Architecture** (ownership, flows, relationships)
5. **Plan Integration Patterns** (sync/async, protocols)
6. **Design Security Architecture** (layers, threat model)

### Phase 3: Gate 3 Validation
**MANDATORY CHECKPOINT** - Must pass before proceeding:
- [ ] All Feature Map domains mapped to components (if Feature Map exists)
- [ ] All PRD features mapped to components (REQUIRED)
- [ ] Component boundaries are clear and logical
- [ ] Interfaces are well-defined and technology-agnostic
- [ ] Data ownership is explicit
- [ ] Quality attributes are achievable
- [ ] Integration patterns are selected
- [ ] No specific technology products named

## Explicit Rules

### ✅ DO Include in TRD
- System architecture style (pattern names, not products)
- Component design with responsibilities
- Data architecture (ownership, flows, models - conceptual)
- API design (contracts, not specific protocols)
- Security architecture (layers, threat model)
- Integration patterns (sync/async, not specific tools)
- Performance targets and scalability strategy
- Deployment topology (logical, not specific cloud services)

### ❌ NEVER Include in TRD
- Specific technology products (PostgreSQL, Redis, Kafka, RabbitMQ)
- Framework versions (Fiber v2, React 18, Express 5)
- Programming language specifics (Go 1.24, Node.js 20)
- Cloud provider services (AWS RDS, Azure Functions, GCP Pub/Sub)
- Package/library names (bcrypt, zod, sqlc, prisma)
- Container orchestration specifics (Kubernetes, ECS, Lambda)
- CI/CD pipeline details
- Infrastructure-as-code specifics (Terraform, CloudFormation)

### Technology Abstraction Rules
1. **Database**: Say "Relational Database" not "PostgreSQL 16"
2. **Cache**: Say "In-Memory Cache" not "Redis" or "Valkey"
3. **Message Queue**: Say "Message Broker" not "RabbitMQ"
4. **Object Storage**: Say "Blob Storage" not "MinIO" or "S3"
5. **Web Framework**: Say "HTTP Router" not "Fiber" or "Express"
6. **Auth**: Say "JWT-based Authentication" not "specific library"

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Everyone knows we use PostgreSQL" | Assumptions prevent proper evaluation. Stay abstract. |
| "Just mentioning the tech stack for context" | Context belongs in Dependency Map. Keep TRD abstract. |
| "The team needs to know what we're using" | They'll know in Dependency Map. TRD is patterns only. |
| "It's obvious we need Redis here" | Obvious ≠ documented. Abstract to "cache", decide later. |
| "I'll save time by specifying frameworks now" | You'll waste time when better options emerge. Wait. |
| "But our project template requires X" | Templates are implementation. TRD is architecture. Separate. |
| "The dependency is critical to the design" | Then describe the *capability* needed, not the product. |
| "Stakeholders expect to see technology choices" | Stakeholders see them in Dependency Map. Not here. |
| "Architecture decisions depend on technology X" | Then your architecture is too coupled. Redesign abstractly. |
| "We already decided on the tech stack" | Decisions without analysis are assumptions. Validate later. |

## Red Flags - STOP

If you catch yourself writing any of these in a TRD, **STOP**:

- Specific product names with version numbers
- Package manager commands (npm install, go get, pip install)
- Cloud provider service names (RDS, Lambda, Cloud Run, etc.)
- Framework-specific terms (Fiber middleware, React hooks, Express routers)
- Container/orchestration specifics (Docker, K8s, ECS)
- Programming language version constraints
- Infrastructure service names (CloudFront, Cloudflare, Fastly)
- CI/CD tool names (GitHub Actions, CircleCI, Jenkins)

**When you catch yourself**: Replace the product name with the capability it provides. "PostgreSQL 16" → "Relational Database with ACID guarantees"

## Gate 3 Validation Checklist

Before proceeding to API/Contract Design, verify:

**Architecture Completeness**:
- [ ] All PRD features mapped to architectural components
- [ ] Component boundaries follow domain-driven design
- [ ] Responsibilities are single and clear
- [ ] Interfaces are well-defined and stable

**Data Design**:
- [ ] Data ownership is explicitly assigned to components
- [ ] Data models support all PRD requirements
- [ ] Consistency strategy is defined (eventual vs. strong)
- [ ] Data flows are documented

**Quality Attributes**:
- [ ] Performance targets are set and achievable
- [ ] Security requirements are addressed in architecture
- [ ] Scalability path is clear (horizontal/vertical)
- [ ] Reliability targets are defined

**Integration Readiness**:
- [ ] External dependencies are identified (by capability)
- [ ] Integration patterns are selected (not specific tools)
- [ ] Error scenarios are considered
- [ ] Contract versioning strategy exists

**Technology Agnostic**:
- [ ] Zero specific product names in document
- [ ] All capabilities described abstractly
- [ ] Patterns named, not implementations
- [ ] Can swap technologies without redesign

**Gate Result**:
- ✅ **PASS**: All checkboxes checked → Proceed to API/Contract Design (`pre-dev-api-design`)
- ⚠️ **CONDITIONAL**: Remove product names → Re-validate
- ❌ **FAIL**: Architecture too coupled → Redesign

## Common Violations and Fixes

### Violation 1: Specific Technologies in Architecture
❌ **Wrong**:
```yaml
System Architecture:
  Language: Go 1.24+
  Framework: Fiber v2.52+
  Database: PostgreSQL 16
  Cache: Valkey 8
  Storage: MinIO
```

✅ **Correct**:
```yaml
System Architecture:
  Style: Modular Monolith
  Pattern: Hexagonal Architecture
  Data Tier:
    - Relational database for transactional data
    - Key-value store for session/cache
    - Object storage for files/media
```

### Violation 2: Framework Details in Component Design
❌ **Wrong**:
```markdown
**Auth Component**
- Fiber middleware for JWT validation
- bcrypt for password hashing
- OAuth2 integration with passport.js
```

✅ **Correct**:
```markdown
**Auth Component**
- **Purpose**: User authentication and session management
- **Inbound**: HTTP API endpoints for login/register/logout
- **Outbound**: User data persistence, email notifications
- **Security**: Token-based authentication, password hashing with industry-standard algorithms
```

### Violation 3: Cloud Services in Deployment
❌ **Wrong**:
```yaml
Deployment:
  Compute: AWS ECS Fargate
  Database: AWS RDS PostgreSQL
  Cache: AWS ElastiCache
  Load Balancer: AWS ALB
```

✅ **Correct**:
```yaml
Deployment Topology:
  Compute: Container-based stateless services
  Data Tier: Managed database services with backup
  Performance: Distributed caching layer
  Traffic: Load balanced with health checks
```

## API Pattern Decisions

During TRD creation, certain architectural patterns require explicit decisions. These decisions should be made during the TRD phase, not deferred to implementation.

### Pagination Strategy (REQUIRED for List Endpoints)

If the feature includes **list/browse** functionality, you **MUST** decide the pagination strategy during TRD.

**Decision Prompt for User:**

```
The feature includes list endpoints. I need to determine the pagination strategy.

Based on the entity characteristics, I recommend [RECOMMENDED OPTION].

Which pagination strategy should be used?

A) Cursor-Based Pagination
   - Best for: High-volume data (>10k records), infinite scroll, real-time feeds
   - Trade-off: Cannot jump to arbitrary pages
   - Performance: O(1) - constant time regardless of dataset size

B) Page-Based (Offset) Pagination
   - Best for: Low-volume data, administrative interfaces
   - Trade-off: Performance degrades with large offsets
   - Performance: O(n) - slower as page number increases

C) Page-Based with Total Count
   - Best for: When UI needs "Page X of Y" display
   - Trade-off: Additional COUNT query overhead
   - Performance: Two queries per request

D) No Pagination
   - Best for: Very small, bounded datasets (<100 items always)
   - Trade-off: All data loaded at once

E) Other - Please describe your requirements
   - Use this if you have specific pagination needs not covered above
```

**Decision Criteria:**

| Factor | Cursor-Based | Page-Based |
|--------|--------------|------------|
| Dataset size | >10k records typical | <10k records typical |
| Real-time data | Yes - data changes frequently | No - data is stable |
| Jump to page | Not required | Required |
| Performance | Critical | Not critical |
| UI pattern | Infinite scroll, "Load more" | Traditional page numbers |

**Document the Decision:**

In the TRD, include the pagination decision in the API design section:

```yaml
API Patterns:
  Pagination:
    Strategy: Cursor-Based  # or Page-Based, Page-Based with Total, None
    Rationale: High-volume entity with real-time updates
    Reference: See project standards for implementation details
```

**Implementation Reference:**

After TRD approval, developers should reference:
1. `docs/PROJECT_RULES.md` (local project) - project-specific standards
2. Ring Standards via WebFetch - base technical patterns (e.g., `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md` for Go)

---

## Architecture Decision Records (ADRs)

When making major decisions, document them abstractly:

```markdown
**ADR-001: Hexagonal Architecture Pattern**
- **Context**: Need clear separation between business logic and external dependencies
- **Options Considered**:
  - Layered Architecture: Simple but couples layers
  - Hexagonal: Clear boundaries, testable, flexible
  - Event-Driven: Eventual consistency complexity
- **Decision**: Hexagonal Architecture
- **Rationale**:
  - Business logic independent of frameworks
  - Easy to swap adapters (database, HTTP, etc.)
  - Testable without external dependencies
- **Consequences**:
  - More initial structure needed
  - Team needs to understand ports/adapters
  - Clear boundaries prevent technical debt
```

**Note**: Still no technology products mentioned. Pattern names only.

## Confidence Scoring

```yaml
Component: "[Architecture Element]"
Confidence Factors:
  Pattern Match: [0-40]
    - Exact pattern used before: 40
    - Similar pattern adapted: 25
    - Novel but researched: 10

  Complexity Management: [0-30]
    - Simple, proven approach: 30
    - Moderate complexity: 20
    - High complexity: 10

  Risk Level: [0-30]
    - Low risk, proven path: 30
    - Moderate risk, mitigated: 20
    - High risk, accepted: 10

Total: [0-100]

Action:
  80+: Present architecture autonomously
  50-79: Present multiple options
  <50: Request clarification on requirements
```

## Output Location

**Always output to**: `docs/pre-dev/{feature-name}/trd.md`

## After TRD Approval

1. ✅ Lock the TRD - architecture patterns are now reference
2. 🎯 Use TRD as input for API/Contract Design (next phase: `pre-dev-api-design`)
3. 🚫 Never add specific technologies to TRD retroactively
4. 📋 Keep architecture/implementation strictly separated

## Quality Self-Check

Before declaring TRD complete, verify:
- [ ] All Feature Map domains have architectural representation
- [ ] All PRD requirements have architectural solution
- [ ] Zero product names or versions present
- [ ] All capabilities described abstractly
- [ ] Component boundaries follow DDD principles
- [ ] Interfaces are technology-agnostic
- [ ] Data ownership is explicit and documented
- [ ] Security is designed into architecture (not bolted on)
- [ ] Performance targets are set and achievable
- [ ] Scalability path is clear and logical
- [ ] Gate 3 validation checklist 100% complete

## The Bottom Line

**If you wrote a TRD with specific technology products, delete those sections and rewrite abstractly.**

The TRD is architecture patterns only. Period. No product names. No versions. No frameworks.

Technology choices go in Dependency Map. That's the next phase. Wait for it.

Violating this separation means:
- You're committing to technologies before evaluating alternatives
- Architecture becomes coupled to specific vendors
- You can't objectively compare technology options later
- Costs, licensing, and compatibility aren't analyzed
- Team loses flexibility to adapt

**Stay abstract. Stay flexible. Make technology decisions in the next phase with full analysis.**
