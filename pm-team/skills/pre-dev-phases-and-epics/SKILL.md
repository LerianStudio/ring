---
name: ring:pre-dev-phases-and-epics
description: |
  Gate 7 (Full Track) / Gate 3 (Small Track): Phased plan — rolling-wave decomposition
  into phases (independently verifiable milestones) and epics (value-driven working
  increments). All phases are epic-level at this gate; Phase 1 task detailing happens
  at Gate 8 (Full Track) or inline (Small Track).
---

# Phases & Epics — Rolling-Wave Decomposition

## When to use

- TRD passed Gate 3 (Full Track) / Gate 2 (Small Track)
- Dependency Map passed Gate 6 (Full Track only)
- Ready to decompose the feature into a phased delivery plan

## Skip when

- TRD not validated → complete earlier gates
- Phased plan already exists → proceed to Task Creation
- Trivial change → direct implementation

## Sequence

**Runs before:** ring:pre-dev-task-creation (Full Track), ring:pre-dev-delivery-planning (Small Track)
**Runs after:** ring:pre-dev-dependency-map (Full Track), ring:pre-dev-trd-creation (Small Track)

---

The plan is a **rolling-wave document**: phases and epics for the whole feature, tasks only for the next phase. Epics answer WHAT working increment is delivered, never HOW — the HOW lives in tasks (Task Creation), and only for the current wave. Detail planned far ahead decays; detail elaborated against the real codebase does not.

## Plan Hierarchy

| Level | Granularity | When detailed |
|-------|-------------|---------------|
| **Phase** | Independently verifiable milestone — software works at the end of every phase | This gate |
| **Epic** | Value-driven working increment inside a phase (the unit dev-cycle executes) | This gate |
| **Task** | Dispatch-ready unit: context + implementation vision + verification | Phase 1 at Gate 8 (Full) or inline (Small); later phases during execution |

Rules:
- Every phase ends with working, testable software. No phase ends mid-refactor.
- 2–5 epics per phase. An epic that needs more than a paragraph to describe is two epics.
- Order phases by dependency first, then by risk — front-load whatever invalidates the design if wrong.
- Small features may collapse to a single phase; the plan then has one phase, fully detailed.

## Epic Sizing Rules

| Size | AI-agent-hours | Calendar Duration* | Scope |
|------|----------------|-------------------|-------|
| Small (S) | 1-4h | 1-2 days | Single component |
| Medium (M) | 4-8h | 2-4 days | Few dependencies |
| Large (L) | 8-16h | 1-2 weeks | Multiple components |
| XL (>16h) | BREAK IT DOWN | Too large | Not atomic |

*1.5x multiplier, 90% capacity, 1 developer

## AI-Assisted Estimation

After defining epic scope, dispatch the appropriate specialist agent to estimate AI-agent-hours:

| Project Type | Agent |
|-------------|-------|
| Go | ring:backend-engineer-golang |
| TypeScript Backend | ring:backend-engineer-typescript |
| React/Next.js | ring:frontend-engineer |
| Mixed/Unknown | ring:codebase-explorer |

Agent analyzes: endpoints/schemas/services, complexity, available libraries, test requirements, documentation needs — and returns a detailed breakdown by component.

**Confidence levels:** High (standard patterns + libs available), Medium (some custom logic), Low (novel algorithms or vague scope). Later-phase epics naturally carry lower confidence — that is expected, not a defect; estimates tighten when the phase is elaborated.

**Estimation fallback:** If AI unavailable, use manual estimate with 1.3x buffer, mark as "Estimation Pending", re-estimate when service restored.

## Mandatory Workflow

| Step | Activities |
|------|------------|
| **1. Input Loading** | Load PRD (required), TRD (required); optionally Feature Map, API Design, Data Model, Dependency Map; identify value streams |
| **2. Phase Design** | Draw phase boundaries: each phase a verifiable milestone; order by dependency then risk |
| **3. Epic Decomposition** | Per phase: define epics with deliverable, success criteria, dependencies, effort (max 16 AI-agent-hours), testing strategy, risks |
| **4. Gate Validation** | All TRD components covered by epics; every phase ends in working software; no XL epics; later phases NOT task-detailed |

## Document Structure (tasks.md)

> The artifact keeps the `tasks.md` filename — it is the dev-cycle `source_file` contract and ends life containing the tasks. Content is the phased plan, maintained as a living document throughout execution.

```markdown
# [Feature] — Phased Plan

## Phase Overview
| Phase | Milestone | Epics | Status |
|-------|-----------|-------|--------|
| 1 | [what works at the end] | E-1.1, E-1.2 | Epic-level |
| 2 | [what works at the end] | E-2.1 | Epic-level |

## Summary
| Epic | Title | Phase | Type | Hours | Confidence | Blocks | Status |
|------|-------|-------|------|-------|------------|--------|--------|
| E-1.1 | Project Foundation | 1 | Foundation | 3.0 | High | All | ⏸️ Pending |
|       | **TOTAL** | | | **85.0h** | | | |

## Business Deliverables
| Epic | Deliverable (business view) |
|------|-----------------------------|
| E-1.1 | The team can develop and test locally from day one — **every contributor gets a working environment**. |
```

- **Phase Overview Status lifecycle:** `Epic-level` → `Detailed` (tasks written) → `Complete` (all epics done)
- **Summary Status lifecycle (per epic, dev-cycle contract):** `⏸️ Pending` → `🔄 Doing` (Gate 0 started) → `✅ Done` (Gate 9 approved) → `❌ Failed` (unresolved blocker)
- **Business Deliverables rules:** plain language (no technical jargon), 1-3 sentences, active voice, core value proposition bolded, no file names or architecture terms

Phase sections with epic blocks follow the tables.

## Per-Epic Template

| Section | Content |
|---------|---------|
| **Header** | E-[phase].[seq]: [Epic Title] |
| **Target** | backend \| frontend \| shared (if multi-module) |
| **Working Directory** | Path from topology config (if multi-module) |
| **Agent** | Recommended agent: ring:backend-engineer-* or ring:frontend-*-engineer-* |
| **Deliverable** | One sentence: what working software ships |
| **Scope** | Includes + Excludes (with epic IDs for future work) |
| **Success Criteria** | Testable: Functional, Technical, Operational, Quality |
| **User/Technical Value** | What users can do; what this enables |
| **Technical Components** | From TRD + From Dependencies |
| **Dependencies** | Blocks (E-X.Y), Requires (E-X.Y), Optional (E-X.Y) |
| **Integration Contracts** | Required when epic references external product/plugin |
| **Effort Estimate** | AI hours, confidence, method, team type, breakdown |
| **Risks** | Impact, Probability, Mitigation, Fallback |
| **Testing Strategy** | Unit, Integration, E2E, Performance, Security |
| **Definition of Done** | Code reviewed, tests passing, docs updated, security clean, deployed to staging, PO acceptance |

No code in epic blocks. Epics state WHAT and the decided constraints; implementation shape arrives with tasks.

## Integration Contracts

Required when Deliverable, Technical Components, or Success Criteria references an external product or plugin (plugin-pix, plugin-fees, Core two, etc.).

```markdown
## Integration Contracts
| ID | Product/Plugin | Endpoint/Interface | Method | Request Schema | Response Schema | Version |
|----|---------------|-------------------|--------|---------------|----------------|---------|
| IC-001 | plugin-pix | POST /api/v1/pix/payments | POST | { amount, key, ... } | { id, status, ... } | v1.2.0 |
```

Rules: exact endpoint/interface, all required request fields, fields the implementation will read, exact API version (not `latest`), sourced from actual spec.

## Multi-Module Epic Tagging (if topology is multi-module)

Each epic MUST have `Target:` and `Working Directory:` when topology is monorepo or multi-repo.

| Target | API Pattern | Agent |
|--------|-------------|-------|
| `backend` | any | ring:backend-engineer-golang or ring:backend-engineer-typescript |
| `frontend` | `direct` | ring:frontend-engineer |
| `frontend` | `bff` (API routes) | ring:frontend-bff-engineer-typescript |
| `frontend` | `bff` (UI components) | ring:frontend-engineer |
| `shared` | any | DevOps or general |

**Output paths:**
- single-repo: `docs/pre-dev/{feature}/tasks.md`
- monorepo: Index + `{backend.path}/docs/pre-dev/{feature}/tasks.md` + `{frontend.path}/docs/pre-dev/{feature}/tasks.md`
- multi-repo: `{backend.path}/docs/pre-dev/{feature}/tasks.md` + `{frontend.path}/docs/pre-dev/{feature}/tasks.md`

## Small Track Addendum (Gate 3)

The Small Track has no separate Task Creation gate. After epics validate, detail Phase 1 inline in the same gate, using the Task Format from ring:pre-dev-task-creation. Single-phase features end this gate fully detailed.

## Gate Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Coverage** | All TRD components have epics; all PRD features have epics; no XL+ epics; boundaries clear |
| **Phase Integrity** | Every phase ends in working, verifiable software; phases ordered by dependency then risk; Phase Overview present |
| **Delivery Value** | Every epic delivers working software; user value explicit; technical value clear |
| **Technical Clarity** | Success criteria measurable; dependencies mapped; testing approach defined; DoD comprehensive |
| **Wave Discipline** | Later phases epic-level only — no premature task detail (Full Track) |
| **Multi-Module** | All epics have `Target:` and `Working Directory:` (if multi-module); agent assignments valid |
| **Risk Management** | Risks identified; mitigations defined; high-risk epics scheduled in early phases |

**Gate Result:** ✅ PASS → Task Creation (Full) / Delivery Planning (Small) | ⚠️ CONDITIONAL (refine oversized/vague) | ❌ FAIL (re-decompose)

## Confidence Scoring

| Factor | Points | Criteria |
|--------|--------|----------|
| Phase & Epic Decomposition | 0-30 | Phases verifiable + epics sized: 30, Most: 20, Too large/vague: 10 |
| Value Clarity | 0-25 | Every epic delivers working software: 25, Most: 15, Unclear: 5 |
| Dependency Mapping | 0-25 | All documented: 25, Most: 15, Ambiguous: 5 |
| Estimation Quality | 0-20 | Based on past work: 20, Educated guesses: 12, Speculation: 5 |

80+ → proceed autonomously | 50-79 → present options | <50 → ask about velocity
