---
name: ring:writing-trds
description: "Writing a Technical Requirements Document that designs the technical architecture of the system or feature: components and boundaries, data flow, integration points, failure modes, and the mandatory program structure (DDD/hexagonal source tree) — in technology-agnostic patterns (code structure excepted), plus auth/pagination and BFF contracts for fullstack. Gate 3 of ring:planning-large-features (after ring:mapping-feature-relationships, before ring:designing-api-contracts) and Gate 2 of ring:planning-small-features (after ring:writing-prds, before ring:writing-plans). Use when the PRD passed validation. Skip when the PRD is unvalidated or the architecture is already documented."
---

# TRD Creation — Architecture Before Implementation

## When to use

- PRD passed Gate 1
- Feature Map passed Gate 2 (Large Track only)
- About to design technical architecture

## Skip when

- PRD not validated → complete Gate 1 first
- Architecture already documented → proceed to API Design (Large) or plan (Small)
- Pure business requirement change → update PRD

## Sequence

**Runs before:** ring:designing-api-contracts (Large Track) / ring:writing-plans (Small Track)
**Runs after:** ring:mapping-feature-relationships (Large Track) / ring:writing-prds (Small Track)

The TRD designs the technical architecture of the system or feature: components and their boundaries, data flow between them, integration points, and failure modes — using technology-agnostic patterns before concrete technology choices.

## Handling Missing Information

When specific details are not provided (tech stack, architecture, team size, deployment model, etc.):
- Infer from project name, context, existing codebase patterns, and git history
- Document assumptions explicitly in a `## Assumptions` section at the top of the TRD
- **NEVER block execution to ask clarifying questions — assume and proceed**
- Flag assumptions that carry high risk for the reader to validate (mark as `⚠️ Assumption:`)
- The only valid exception: tech stack ambiguity in Step 0 when auto-detection fails and no codebase files exist to infer from

## Step -1: Design Validation Check (UI Features Only, Conditional)

Read PRD and detect UI indicators (user stories with "see", "view", "click", "page", "screen", "button", "form"; features involving login, dashboard, settings, reports, notifications).

**If feature has UI:**
- Check `docs/pre-dev/{feature}/design-validation.md` (produced by a standalone ring:validating-ux-completeness run, if one happened)
- If present → honor its verdict: "DESIGN VALIDATED" proceeds; any other verdict means fix the listed design gaps before (or alongside) the TRD
- If absent → **proceed** and add to `## Assumptions`: `⚠️ UX risk: no design validation ran for this UI feature — consider a standalone ring:validating-ux-completeness pass`

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
Check: `docs/PROJECT_RULES.md` → `docs/STANDARDS.md` (legacy) → if neither exists, note the absence and proceed with Ring standards.

### Step 0.4: Analyze PRD and Suggest Technologies
Read PRD, extract requirements, suggest technologies per category, confirm with user.

**AskUserQuestion:** "What deployment model?" Options: Cloud, On-Premise, Hybrid

### Step 0.5: Document in TRD Metadata
TRD header must include: `feature`, `gate: 3` (Large) / `gate: 2` (Small), `deployment.model`, `tech_stack.primary`, `tech_stack.standards_loaded[]`, `project_technologies[]` (category, prd_requirement, choice, rationale per decision). On Large Track this flows to Gates 4–6.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Analysis** | PRD (required); Feature Map (Large Track); identify NFRs (performance, security, scalability); map domains to components |
| **2. Architecture Definition** | Choose style (Microservices, Modular Monolith, Serverless); design components with explicit boundaries; define interfaces; model data flow end-to-end; plan integration points and patterns; design security; produce **Program Design** — bounded contexts (vertical slices) + source tree (see section below) |
| **3. Failure Modes** | For each component and integration point: what fails, how it is detected, how the system degrades or recovers (timeout/retry/circuit-break/fallback); consistency under partial failure |
| **4. Gate Validation** | All domains mapped; component boundaries clear; interfaces technology-agnostic; data ownership explicit; failure modes covered; quality attributes achievable; no specific products named |

## Program Design (Code Structure — MANDATORY)

Every TRD MUST include a `## Program Design` section with **two mandatory parts**: (1) the **bounded contexts / vertical slices** the feature creates or touches, and (2) the **source tree** for each. This anchors implementation to Lerian's mandatory modeling — **Modular Monolith + DDD + Hexagonal (ports & adapters) + CQRS-light** — as shipped in the canonical `go-boilerplate-ddd`. It is the one place a TRD is concrete about *code structure*; it stays silent on *product* choices (see exception note under Technology Abstraction Rules).

### Part 1 — Bounded Contexts (Vertical Slices) [MANDATORY]

In the Lerian model a **vertical slice = bounded context = one `internal/{context}/` module** that owns its full stack top to bottom (adapters → ports → services → domain). Identifying them is the highest-leverage modeling decision and the most expensive to get wrong, so the TRD MUST make it explicit before any code is written.

Enumerate every context the feature creates or touches:

| Context | New / Existing | Responsibility (ubiquitous language) | Owns (entities / tables) | Talks to (via port) |
|---------|----------------|--------------------------------------|--------------------------|---------------------|
| `{context}` | New | one-line bounded responsibility | entities + tables it owns | other contexts / external capabilities |

**Slicing rules:**
- **Fewest contexts that hold.** Extend an existing context by default; create a new one ONLY when the feature introduces a genuinely distinct ubiquitous language / ownership boundary. No speculative contexts.
- **One context owns its data.** Cross-context access goes through `ports/`, never by reaching into another context's tables.
- **Large Track:** contexts MUST be consistent with `feature-map.md` `## Phases` — a phase may deliver one or more contexts; a context never straddles unrelated phases. **Small Track:** this table is the first place contexts are defined.

### Part 2 — Source Tree [MANDATORY]

**When `tech_stack.primary` is Go:** render EACH context from Part 1 using the canonical slice layout. Replace `{context}` with the real bounded-context name (never ship `example` — that is the boilerplate's teaching scaffold).

```text
internal/{context}/
├── adapters/
│   ├── http/          # driving adapter — thin Huma/HTTP handlers (parse, validate, call service)
│   ├── m2m/           # driving adapter — machine-to-machine (only if service-to-service auth)
│   └── postgres/      # driven adapter — persistence via lib-commons (libPostgres); no raw sql.Open
├── domain/
│   └── entities/      # entities + value objects; pure domain, imports no infrastructure
├── ports/             # interfaces only — driving (service contracts) + driven (repos / gateways)
├── services/
│   ├── command/       # CQRS write side — use cases that mutate state
│   └── query/         # CQRS read side — use cases that read state
├── streaming/         # event producers / consumers (Event-Driven profile only)
└── mocks/             # generated mocks for the ports
```

Shared/platform code lives OUTSIDE the slice — reference only what the feature touches:

| Path | Role — and the slice's constraint |
|------|-----------------------------------|
| `cmd/app/main.go` | process entry point — slice does not touch it |
| `internal/bootstrap/` | composition root (config, telemetry, DB, auth, route wiring, lifecycle) — register routes/wiring here; a slice NEVER bootstraps its own logger/DB/telemetry |
| `internal/shared/` | service-specific shared code — reuse, but never duplicate `lib-commons`/`lib-observability`/`lib-systemplane`/`lib-streaming` features |
| `migrations/` | SQL migrations (golang-migrate) — add the feature's migration here |
| `docs/openapi.yaml` | committed OAS 3.1 spec (generated) — regenerate after any API-surface change |

**Modeling rules to state alongside the tree:**
- Dependencies point inward: `adapters → ports ← services → domain`. `domain` imports no infrastructure.
- Interfaces in `ports/`, implementations in `adapters/`.
- Keep handlers thin; infrastructure concerns stay in `bootstrap`, never in the slice.
- `tenantId` derives from validated request identity — never from JSON payload or path params.

**When `tech_stack.primary` is not Go:** mirror the project's equivalent canonical layout (or the existing module structure detected in the repo) and state the same context boundaries, dependency direction, and ports/adapters split. Do not invent a structure the codebase does not already use.

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

**Exception — Program Design:** the `## Program Design` section IS concrete about code structure (layer and adapter folder names that mirror the mandatory boilerplate). Those names describe *modeling slots*, not product couplings — `adapters/postgres/` is the persistence-adapter slot, not a PostgreSQL-version dependency. The abstraction rules above govern *product/capability* choices (DB engine, broker, cache); they never apply to the code-modeling tree.

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

Auto-detect from package.json: `@your-org/design-system` (your design-system package, if any), `@radix-ui/*`, `@shadcn/ui`, `@chakra-ui/*`, `@mui/material`, etc.

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

## Gate Validation Checklist (Gate 3 Large / Gate 2 Small)

| Category | Requirements |
|----------|--------------|
| **Architecture Completeness** | All PRD features mapped; DDD boundaries; clear responsibilities; stable interfaces |
| **Program Design** | Bounded contexts (vertical slices) enumerated (new vs existing); source tree present per context, mirroring DDD+Hexagonal+CQRS boilerplate; `{context}` named (never `example`); dependency direction stated; ports/adapters split correct; Large Track consistent with feature-map Phases |
| **Data Design** | Ownership explicit; models support PRD; consistency strategy; flows documented end-to-end |
| **Failure Modes** | Each component and integration point has failure behavior defined: detection, degradation, recovery |
| **Quality Attributes** | Performance targets set; security addressed; scalability path clear |
| **Integration Readiness** | External deps identified (by capability); patterns selected; errors considered |
| **Technology Agnostic** | Zero product names (Program Design code-structure names excepted); capabilities abstract; can swap tech without redesign |
| **Design System** (UI) | Library specified; CSS framework; theme variables; component matrix; variant mapping |

**Gate Result:** ✅ PASS → API Design / Gate 4 (Large) or plan / Gate 3 (Small) | ⚠️ CONDITIONAL (remove product names) | ❌ FAIL (too coupled or failure modes missing)

## Document Placement

| Structure | trd.md Location |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/trd.md` |
| monorepo | `docs/pre-dev/{feature}/trd.md` (root) |
| multi-repo | Both repos: `{backend.path}/docs/pre-dev/{feature}/trd.md` AND `{frontend.path}/...` |
