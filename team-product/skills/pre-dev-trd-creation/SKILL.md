---
name: pre-dev-trd-creation
description: Use when translating business requirements to architecture, before selecting technologies, when tempted to specify frameworks/tools, after PRD is complete
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

## Mandatory Workflow

### Phase 1: Technical Analysis (Inputs Required)
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

**Always output to**: `docs/pre-development/trd/trd-[feature-name].md`

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
