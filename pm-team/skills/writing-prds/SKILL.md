---
name: ring:pre-dev-prd-creation
description: |
  Gate 1: Business requirements document - defines WHAT/WHY before HOW.
  Creates PRD with problem definition, user stories, success metrics.
---

# PRD Creation — Business Before Technical

## When to use

- Starting new product or major feature
- User asks to "plan", "design", or "architect"
- About to write code without documented requirements
- Asked to create PRD or requirements document

## Skip when

- PRD already exists and validated → proceed to Gate 2
- Pure technical task without business impact → TRD directly
- Bug fix → systematic-debugging

## Sequence

**Runs before:** ring:pre-dev-feature-map, ring:pre-dev-trd-creation


The PRD defines WHAT we're building and WHY it matters to users and business. It never answers HOW we'll build it (that's TRD) or WHERE components will live.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **0. Load Research** | Check `docs/pre-dev/{feature}/research.md`; reference codebase patterns and findings with `file:line` notation |
| **1. Problem Discovery** | Define problem without solution bias; identify specific users; quantify pain with metrics/evidence |
| **2. Business Requirements** | Executive summary (3 sentences); user personas; user stories (As/I want/So that); success metrics (measurable); scope boundaries (in/out) |
| **3. Gate 1 Validation** | Problem articulated; impact quantified; users identified; features address problem; metrics measurable; scope explicit |
| **4. UX Validation** | Dispatch `product-designer` to validate PRD against user needs and create `ux-criteria.md` |

## Include in PRD

- Problem definition and user pain points
- User personas (demographics, goals, frustrations)
- User stories with acceptance criteria
- Feature requirements (WHAT not HOW)
- Success metrics (adoption, satisfaction, KPIs)
- Scope boundaries (in/out explicitly)
- Go-to-market considerations

## Never Include in PRD

- Architecture diagrams or component design
- Technology choices (languages, frameworks, databases)
- Implementation approaches or algorithms
- Database schemas or API specifications
- Code examples or package dependencies
- Infrastructure needs or deployment strategies

**Separation rules:**
- Technology name → Dependency Map
- "How to build" → TRD
- Implementation detail → Tasks/Subtasks
- System behavior → TRD

## Security Requirements Discovery (Business Level)

| Business Question | If Yes → Document |
|-------------------|-------------------|
| Feature handles user-specific data? | "Users can only access their own [data type]" |
| Different user roles with different permissions? | "Admins can [X], regular users can [Y]" |
| Need to identify who performed an action? | "Audit trail required for [action type]" |
| Integrates with other internal services? | "Service must authenticate to [service name]" |
| Regulatory requirements? | "Must comply with [regulation] for [data type]" |

Include: "Only authenticated users can access", "Users can only view/edit their own records", "Admin approval required for [action]"
Exclude: JWT tokens, Access Manager integration, OAuth2 flow — these go in TRD.

## Operational Dashboard Discovery (Business Level)

During PRD creation for features involving data that accumulates over time (transactions, events, operations), ask:

AskUserQuestion: "Will an operator or business manager need a consolidated view of this feature's data to make decisions?"
- "Yes — Business dashboard needed"
- "No — Infrastructure/backend only"
- "Not sure — Needs discussion"

**If "Yes":** Document in PRD under "Dashboard Requirements": consumer persona, decisions supported, key metrics, refresh cadence.

## Gate 1 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Problem Clarity** | Problem stated without solution; specific user identified; pain quantified |
| **Requirements** | User stories follow As/I want/So that; acceptance criteria testable; all PRD features address problem |
| **Metrics** | Success metrics measurable; baseline + target defined; timeframe specified |
| **Scope** | In-scope features explicit; out-of-scope stated; boundaries clear |
| **Technology-Free** | Zero technology names; zero implementation details; zero framework mentions |

**Gate Result:** ✅ PASS → Feature Map or TRD | ❌ FAIL (re-work technical content or missing requirements)

## Output

**File:** `docs/pre-dev/{feature}/prd.md`

After Gate 1 passes: dispatch `ring:product-designer` to validate UX and create `docs/pre-dev/{feature}/ux-criteria.md`.
