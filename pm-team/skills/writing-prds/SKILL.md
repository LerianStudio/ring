---
name: ring:writing-prds
description: "Writing a Product Requirements Document that explains to the squad WHAT is being built and WHY: problem, explicit scope in/out, functional requirements, and testable acceptance criteria. Gate 1 of ring:using-pm-team; runs after ring:researching-features and stays technology-free (no architecture, frameworks, or schemas). Use when starting a new feature or asked to plan or produce requirements. Skip when a validated PRD exists, for pure technical changes, or bug fixes."
---

# PRD Creation — WHAT and WHY Before HOW

## When to use

- Starting new product or major feature
- User asks to "plan", "design", or "architect"
- About to write code without documented requirements
- Asked to create PRD or requirements document

## Skip when

- PRD already exists and validated → proceed to next gate
- Pure technical task without product impact → TRD directly
- Bug fix → systematic-debugging

## Sequence

**Runs after:** ring:researching-features (Gate 0)
**Runs before:** ring:mapping-feature-relationships (Gate 2, Large track) or ring:writing-trds (Gate 2, Small track)


The PRD is a squad-facing explanation of the product/feature being built: what it does, why it exists, what is in and out of scope, and how the squad knows it's done. It never answers HOW to build it (that's TRD) or WHERE components will live.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **0. Load Research** | Check `docs/pre-dev/{feature}/research.md`; reference codebase patterns and findings with `file:line` notation |
| **1. Problem Definition** | State the problem without solution bias; explain why it matters now; cite evidence from research.md |
| **2. Requirements** | Executive summary (3 sentences); functional requirements (WHAT the feature does); testable acceptance criteria per requirement; explicit scope boundaries (in/out) |
| **3. Gate 1 Validation** | Problem articulated; requirements address problem; acceptance criteria testable; scope explicit; zero technology content |

## Include in PRD

- Problem definition and why it matters
- Feature description: what it does, observable behavior
- Functional requirements (WHAT not HOW)
- Acceptance criteria (testable, per requirement)
- Scope boundaries (in/out explicitly)

## Never Include in PRD

- Architecture diagrams or component design
- Technology choices (languages, frameworks, databases)
- Implementation approaches or algorithms
- Database schemas or API specifications
- Code examples or package dependencies
- Infrastructure needs or deployment strategies
- Personas, demographics, market analysis, go-to-market plans
- Adoption/satisfaction KPIs or business metric targets

**Separation rules:**
- Technology name → Dependency Map
- "How to build" → TRD
- Implementation detail → Plan tasks
- System behavior → TRD

## Security Requirements Discovery (Functional Level)

| Question | If Yes → Document |
|----------|-------------------|
| Feature handles user-specific data? | "Users can only access their own [data type]" |
| Different user roles with different permissions? | "Admins can [X], regular users can [Y]" |
| Need to identify who performed an action? | "Audit trail required for [action type]" |
| Integrates with other internal services? | "Service must authenticate to [service name]" |
| Regulatory requirements? | "Must comply with [regulation] for [data type]" |

Include: "Only authenticated users can access", "Users can only view/edit their own records", "Admin approval required for [action]"
Exclude: JWT tokens, Access Manager integration, OAuth2 flow — these go in TRD.

## Operational Dashboard Discovery

For features involving data that accumulates over time (transactions, events, operations), ask:

AskUserQuestion: "Will an operator need a consolidated view of this feature's data to make decisions?"
- "Yes — Operational dashboard needed"
- "No — Infrastructure/backend only"
- "Not sure — Needs discussion"

**If "Yes":** Document in PRD under "Dashboard Requirements": who consumes it, decisions supported, key data shown, refresh cadence.

## Gate 1 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Problem Clarity** | Problem stated without solution; why-now explained; grounded in research.md |
| **Requirements** | Every requirement describes observable behavior; acceptance criteria testable; all requirements trace to the problem |
| **Scope** | In-scope features explicit; out-of-scope stated; boundaries clear |
| **Technology-Free** | Zero technology names; zero implementation details; zero framework mentions |

**Gate Result:** ✅ PASS → next gate | ❌ FAIL (re-work technical content or missing requirements)

## Output

**File:** `docs/pre-dev/{feature}/prd.md`

After Gate 1 passes: Large track → `ring:mapping-feature-relationships` (Gate 2); Small track → `ring:writing-trds` (Gate 2). If the feature has UI, the orchestrator may recommend a standalone product-designer + `ring:validating-ux-completeness` run before the TRD (optional, not a gate).
