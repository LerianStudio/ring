---
name: ring:planning-large-features
description: "Planning the 8-gate Large Track pre-dev workflow (research, PRD, feature map, TRD, API contract, data model, dependency map, plan) with per-gate human approval. Use for features 2+ days that add dependencies, data models, multi-service integration, or new architecture. Skip for small features (use ring:planning-small-features). Plans only — no edits."
---

# Large Track Pre-Dev Workflow (8 Gates)

## When to use

- Feature takes >=2 days to implement
- Adds new external dependencies (APIs, databases, libraries)
- Creates new data models or entities
- Requires multi-service integration
- Uses new architecture patterns
- Requires team collaboration

## Skip when

- Feature is simple (<2 days, existing patterns) - use ring:planning-small-features instead
- No new dependencies, data models, or architecture patterns needed

## Sequence

**Runs before:** ring:running-dev-cycle, ring:executing-plans

## Related

**Complementary:** ring:planning-small-features, ring:creating-worktrees, ring:product-designer + ring:validating-ux-completeness (standalone UX step, recommended when feature has UI)
**Skills orchestrated:**
- ring:researching-features
- ring:writing-prds
- ring:mapping-feature-relationships
- ring:writing-trds
- ring:designing-api-contracts
- ring:designing-data-model
- ring:pinning-dependency-versions
- ring:writing-plans


Running the **Large Track** pre-development workflow for features that take ≥2 days, add new external dependencies, create new data models, require multi-service integration, use new architecture patterns, or require team collaboration.

For simple features (<2 days, existing patterns), use `ring:planning-small-features` instead.

## Gate Map

| Gate | Skill | Output |
|------|-------|--------|
| 0 | ring:researching-features | research.md |
| 0.5 ◇ | ring:building-personas | personas.md |
| 1 | ring:writing-prds | prd.md |
| 2 | ring:mapping-feature-relationships | feature-map.md |
| 2.5 ◆ | ring:structuring-information + ring:writing-ux-copy + ring:critiquing-designs + ring:applying-design-system → ring:validating-ux-completeness | user-flows.md, wireframes/, ux-criteria.md, design-validation.md |
| 3 | ring:writing-trds | trd.md |
| 4 | ring:designing-api-contracts | openapi.yaml |
| 5 | ring:designing-data-model | schema.sql / schema.prisma (stack-native) |
| 6 | ring:pinning-dependency-versions | dependencies.md |
| 7 | ring:writing-plans | plan.md |

◇ **Gate 0.5** runs when the feature has human users (default for product features; skip for pure infra). ◆ **Gate 2.5 (Design) is REQUIRED when Q4=Yes (has UI)** — see Step 4. Gates 4/5 conditional per execution rules.

All artifacts saved to: `docs/pre-dev/<feature-name>/`

## Step 1: Gather Feature Name

AskUserQuestion: "What is the name of your feature?" (kebab-case, e.g., "auth-system", "payment-processing")

## Step 2: Topology Discovery (MANDATORY)

Execute topology discovery per [shared-patterns/topology-discovery.md](../shared-patterns/topology-discovery.md). Discovers project structure (fullstack/backend-only/frontend-only), repository organization (single-repo/monorepo/multi-repo), module paths, and UI configuration. Store as `TopologyConfig` for all subsequent gates.

## Step 3: Gather Feature-Specific Inputs

**Q2 (CONDITIONAL):** Auth requirements — auto-detect from `go.mod` (`lib-auth` present → skip). Options: None, User only, User + permissions, Service-to-service, Full.

**Q3 (CONDITIONAL):** License requirements — auto-detect from `go.mod` (`lib-license-go` present → skip). Options: No, Yes.

**Q4 (MANDATORY):** Has UI? Options: Yes, No. Always ask — do not assume from feature description.

**Q5 (if Q4=Yes):** UI component library — auto-detect from package.json. Options: shadcn/ui + Radix (recommended), Chakra UI, Headless UI, Material UI, Ant Design, Custom.

**Q6 (if Q4=Yes):** Styling approach — auto-detect from package.json. Options: TailwindCSS (recommended), CSS Modules, Styled Components, Sass/SCSS, Vanilla CSS.

## Step 4: Execute Gates Sequentially

Each gate invokes its sub-skill. Human approval required at each gate before proceeding.

**Gate execution rules:**
- Gates 0-3, 6, and 7 always run for Large Track
- Gate 4 (API contract) runs only if the feature has an API surface; otherwise record it as `"SKIPPED"` in workflow-state.json
- Gate 5 (Data model) runs only if the feature has persistent data; otherwise record it as `"SKIPPED"` in workflow-state.json
- Gate 7 (Plan): invoke `ring:writing-plans` with trd.md as spec input plus feature-map.md, openapi.yaml, the schema file, and dependencies.md as supporting inputs, passing `TopologyConfig`. **Binding constraint:** plan phases mirror feature-map.md `## Phases` one-to-one. Output path: `docs/pre-dev/{feature}/plan.md` (overrides the writing-plans default). plan.md is always a SINGLE document per feature. **Topology clause:** when `TopologyConfig` structure is monorepo or multi-repo, each epic carries one line `**Target:** backend | frontend | infra` (placed right before `**Status:**`); for multi-repo, the orchestrator copies plan.md into each repo and the local dev-cycle executes only epics whose Target matches that repo. No per-module plan splits.

**Gate 0.5 — Personas (if the feature has human users):** after Gate 0, run `ring:building-personas` to produce `personas.md` before the PRD. The PRD (Gate 1) consumes it (functional requirements trace to personas). Skip only for pure-infra features with no human user.

**Gate 2.5 — Design (REQUIRED when Q4=Yes / has UI):** after Gate 2 approval and before Gate 3, run the design phase as a tracked gate, not an optional step:
1. `ring:structuring-information` → information architecture / navigation / `user-flows.md`
2. `ring:product-designer` → wireframes (`wireframes/`)
3. `ring:writing-ux-copy` → in-product microcopy feeding `ux-criteria.md`
4. `ring:applying-design-system` → enforce the locked DS (tokens, Geist, viewports, provider) on the wireframes
5. `ring:critiquing-designs` → structured critique before validation
6. `ring:validating-ux-completeness` → emits `design-validation.md` with a DESIGN VALIDATED / NEEDS REVISION verdict

**Hard gate:** when Q4=Yes, Gate 3 (TRD) MUST NOT proceed unless `design-validation.md` exists with verdict **DESIGN VALIDATED**. A NEEDS REVISION verdict or a missing file blocks Gate 3 — return to the design step. (For Q4=No, skip Gate 2.5 entirely.) Track Gate 2.5 in workflow-state.json like any other gate.

## Gate Progress Tracking

Save state to `docs/pre-dev/{feature}/workflow-state.json`:
```json
{
  "track": "large",
  "feature": "{feature-name}",
  "currentGate": 0,
  "gates": {
    "0": "PENDING", "1": "PENDING", "2": "PENDING", "3": "PENDING",
    "4": "PENDING|SKIPPED", "5": "PENDING|SKIPPED", "6": "PENDING", "7": "PENDING"
  },
  "topology": {},
  "inputs": {"hasUI": false, "authRequired": false, "licenseRequired": false, "uiLibrary": null, "styling": null}
}
```

Legal gate values: `PENDING`, `APPROVED`, `SKIPPED` (gates 4/5 only, per the conditional execution rules above).

## Execution Mode

AskUserQuestion at start: "Execution mode?"
- **Automatic** — all gates execute, pause only on failure
- **Manual** — checkpoint and wait for approval after each gate

## Completion

After Gate 7 approved: `docs/pre-dev/{feature}/plan.md` is the single execution document. Execute with `ring:running-dev-cycle` (subagent orchestration) or `ring:executing-plans` (inline).
