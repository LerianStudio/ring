---
name: ring:pre-dev-trd-creation
description: |
  Gate 3 (Full Track) / Gate 2 (Small Track): Technical architecture document - defines HOW/WHERE with technology-agnostic
  patterns before concrete implementation choices.
---

# TRD Creation — Architecture Before Implementation

## When to use

- PRD passed Gate 1
- Feature Map passed Gate 2 (Full Track only)
- Design Validation passed Gate 1.5 (Small Track) / Gate 2.5 (Full Track) (if feature has UI)
- About to design technical architecture

## Skip when

- PRD not validated → complete Gate 1 first
- Design Validation not passed (for UI features) → complete Gate 1.5/2.5 first
- Architecture already documented → proceed to API Design
- Pure business requirement change → update PRD

## Sequence

**Runs before:** ring:pre-dev-api-design, ring:pre-dev-phases-and-epics
**Runs after:** ring:pre-dev-prd-creation, ring:pre-dev-feature-map, ring:pre-dev-design-validation


The TRD defines HOW to architect the solution and WHERE components will live — using technology-agnostic patterns before concrete technology choices.

## Handling Missing Information

When specific details are not provided (tech stack, architecture, team size, deployment model, etc.):
- Infer from project name, context, existing codebase patterns, and git history
- Document assumptions explicitly in a `## Assumptions` section at the top of the TRD
- **NEVER block execution to ask clarifying questions — assume and proceed**
- Flag assumptions that carry high risk for the reader to validate (mark as `⚠️ Assumption:`)
- The only valid exception: tech stack ambiguity in Step 0 when auto-detection fails and no codebase files exist to infer from

## Step -1: Design Validation Check (UI Features Only)

Read PRD and detect UI indicators (user stories with "see", "view", "click", "page", "screen", "button", "form"; features involving login, dashboard, settings, reports, notifications).

**If feature has UI:**
- Check `docs/pre-dev/{feature}/design-validation.md`
- If missing → STOP: "Run ring:pre-dev-design-validation before TRD"
- If verdict ≠ "DESIGN VALIDATED" → STOP: "Fix design gaps and re-run validation"
- If "DESIGN VALIDATED" → proceed

**If backend-only:** Skip to Step 0.

## Step 0: Tech Stack Definition (HARD GATE)

### Step 0.1: Auto-Detect or Ask
- `go.mod` exists → Go
- `package.json` with react/next → Frontend TS
- `package.json` with express/fastify/nestjs → Backend TS
- Ambiguous → AskUserQuestion: "What is the primary technology stack?"

### Step 0.2: Load Ring Standards via WebFetch

| Tech Stack | Standards to Load |
|------------|-------------------|
| Go Backend | golang/index.md + devops.md + sre.md |
| TypeScript Backend | typescript.md + devops.md + sre.md |
| TypeScript Frontend | frontend.md + devops.md |
| Full-Stack TypeScript | typescript.md + frontend.md + devops.md + sre.md |

WebFetch base URL: `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/`

### Step 0.3: Read PROJECT_RULES.md
Check: `docs/PROJECT_RULES.md` → `docs/STANDARDS.md` (legacy) → note for creation at Gate 6 if not found.

### Step 0.4: Analyze PRD and Suggest Technologies
Read PRD, extract requirements, suggest technologies per category, confirm with user.

**AskUserQuestion:** "What deployment model?" Options: Cloud, On-Premise, Hybrid

### Step 0.5: Document in TRD Metadata
TRD header must include: `feature`, `gate: 3`, `deployment.model`, `tech_stack.primary`, `tech_stack.standards_loaded[]`, `project_technologies[]` (category, prd_requirement, choice, rationale per decision). This flows to Gates 4-6.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Analysis** | PRD (required); Feature Map (optional); identify NFRs (performance, security, scalability); map domains to components |
| **2. Architecture Definition** | Choose style (Microservices, Modular Monolith, Serverless); design components with boundaries; define interfaces; model data architecture; plan integration patterns; design security |
| **3. Gate 3 Validation** | All domains mapped; component boundaries clear; interfaces technology-agnostic; data ownership explicit; quality attributes achievable; no specific products named |

## Technology Abstraction Rules

| Element | Say This (✅) | Not This (❌) |
|---------|--------------|---------------|
| Database | "Relational Database" | "PostgreSQL 16" |
| Cache | "In-Memory Cache" | "Redis" or "Valkey" |
| Message Queue | "Message Broker" | "RabbitMQ" |
| Object Storage | "Blob Storage" | "MinIO" or "S3" |
| Web Framework | "HTTP Router" | "Fiber" or "Express" |
| Auth | "JWT-based Authentication" | "specific library" |

TRD never includes: product names with versions, package manager commands, cloud service names (RDS, Lambda), framework-specific terms, container/orchestration specifics, CI/CD tool names.

## Authentication/Authorization Architecture (If Required)

| Auth Type | TRD Description |
|-----------|----------------|
| User only | "Token-based authentication with stateless validation" |
| User + permissions | "Token-based authentication with role-based access control (RBAC)" |
| Service-to-service | "Machine-to-machine authentication with client credentials" |
| Full | "Dual-layer authentication: user tokens + client credentials for services" |

For Go services: reference `golang/security.md` → Access Manager Integration in TRD so engineers know implementation patterns.

## License Manager Architecture (If Required)

| License Type | TRD Description |
|--------------|----------------|
| Single-org | "Global license validation at service startup with fail-fast behavior" |
| Multi-org | "Per-request license validation with organization context" |

For Go services: reference `golang/security.md` → License Manager Integration.

## Frontend-Backend Integration (If Fullstack)

Read `api_pattern` from research.md frontmatter (`bff` or `none`).

**If `api_pattern: none`:** Document "Static Frontend — no API layer needed."

**If `api_pattern: bff`:** TRD MUST include `## Integration Patterns` section:
- Pattern: BFF (Backend-for-Frontend)
- Frontend calls BFF API routes (Next.js API Routes recommended)
- BFF aggregates data from multiple backend services
- Sensitive API keys stored server-side
- Data Flow: Frontend → BFF API Route → Backend Service(s) → Database(s)

**BFF Contracts section (MANDATORY when `api_pattern: bff`):**
- BFF Route + Frontend Consumer + Request/Response contracts (flat, no `data` envelope)
- Error contracts per BFF route
- Backend API mapping (BFF route → backend APIs called → aggregation logic)
- Task ownership: Frontend Engineer owns BFF (consumer proximity, type safety chain)

**HARD RULE:** Client-side code MUST NEVER call backend APIs directly. `api_pattern: direct` does not exist for dynamic data.

## Design System Configuration (UI Features)

Auto-detect from package.json: `@lerianstudio/sindarian-ui`, `@radix-ui/*`, `@shadcn/ui`, `@chakra-ui/*`, `@mui/material`, etc.

TRD must include `## Design System Configuration` section:
- UI library + version
- CSS framework + config file
- Theme variables (color scale, spacing, component-specific)
- Component availability matrix (table: Component Needed / Available / Notes)
- Variant mapping (Design Intent → Correct Variant → Wrong variant)
- Required CSS imports in globals.css

## Pagination Strategy (Required for List Endpoints)

| Strategy | Best For | Performance |
|----------|----------|-------------|
| Cursor-Based | >10k records, infinite scroll | O(1) |
| Page-Based (Offset) | <10k records, admin interfaces | O(n) |
| Page-Based + Total Count | "Page X of Y" UI | 2 queries |
| No Pagination | Very small bounded sets (<100) | — |

Document in TRD: `API Patterns → Pagination → Strategy + Rationale`

## ADR Template

```markdown
**ADR-00X: [Pattern Name]**
- **Context**: [Problem needing solution]
- **Options**: [List with trade-offs - no products]
- **Decision**: [Selected pattern]
- **Rationale**: [Why this pattern]
- **Consequences**: [Impact of decision]
```

## Gate 3 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Architecture Completeness** | All PRD features mapped; DDD boundaries; clear responsibilities; stable interfaces |
| **Data Design** | Ownership explicit; models support PRD; consistency strategy; flows documented |
| **Quality Attributes** | Performance targets set; security addressed; scalability path clear |
| **Integration Readiness** | External deps identified (by capability); patterns selected; errors considered |
| **Technology Agnostic** | Zero product names; capabilities abstract; can swap tech without redesign |
| **Design System** (UI) | Library specified; CSS framework; theme variables; component matrix; variant mapping |

**Gate Result:** ✅ PASS → API Design | ⚠️ CONDITIONAL (remove product names) | ❌ FAIL (too coupled)

## Document Placement

| Structure | trd.md Location |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/trd.md` |
| monorepo | `docs/pre-dev/{feature}/trd.md` (root) |
| multi-repo | Both repos: `{backend.path}/docs/pre-dev/{feature}/trd.md` AND `{frontend.path}/...` |
