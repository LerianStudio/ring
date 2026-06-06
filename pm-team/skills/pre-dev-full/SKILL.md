---
name: ring:pre-dev-full
description: |
  Complete 10-gate pre-dev workflow for large features (>=2 days).
  Orchestrates topology discovery, research, PRD, feature map, design validation,
  TRD, API design, data model, dependency map, phases and epics, task creation,
  and delivery planning in a sequential gated process with human approval at each gate.
---

# Full Track Pre-Dev Workflow (10 Gates)

## When to use

- Feature takes >=2 days to implement
- Adds new external dependencies (APIs, databases, libraries)
- Creates new data models or entities
- Requires multi-service integration
- Uses new architecture patterns
- Requires team collaboration

## Skip when

- Feature is simple (<2 days, existing patterns) - use ring:pre-dev-feature instead
- No new dependencies, data models, or architecture patterns needed

## Sequence

**Runs before:** ring:writing-plans, ring:dev-cycle

## Related

**Complementary:** ring:pre-dev-feature, ring:writing-plans, ring:worktree
**Skills orchestrated:**
- ring:pre-dev-research
- ring:pre-dev-prd-creation
- ring:pre-dev-feature-map
- ring:pre-dev-design-validation
- ring:pre-dev-trd-creation
- ring:pre-dev-api-design
- ring:pre-dev-data-model
- ring:pre-dev-dependency-map
- ring:pre-dev-phases-and-epics
- ring:pre-dev-task-creation
- ring:pre-dev-delivery-planning


Running the **Full Track** pre-development workflow for features that take ≥2 days, add new external dependencies, create new data models, require multi-service integration, use new architecture patterns, or require team collaboration.

For simple features (<2 days, existing patterns), use `ring:pre-dev-feature` instead.

## Gate Map

| Gate | Skill | Output | Track |
|------|-------|--------|-------|
| 0 | ring:pre-dev-research | research.md | Full |
| 1 | ring:pre-dev-prd-creation | prd.md | Full |
| 1.5 | ring:pre-dev-design-validation | design-validation.md | Full (if UI) |
| 2 | ring:pre-dev-feature-map | feature-map.md | Full |
| 2.5 | ring:pre-dev-design-validation | design-validation.md | Full (if UI, Large) |
| 3 | ring:pre-dev-trd-creation | trd.md | Full |
| 4 | ring:pre-dev-api-design | api-design.md | Full |
| 5 | ring:pre-dev-data-model | data-model.md | Full |
| 6 | ring:pre-dev-dependency-map | dependencies.md | Full |
| 7 | ring:pre-dev-phases-and-epics | tasks.md (phased plan: phases + epics) | Full |
| 8 | ring:pre-dev-task-creation | Phase 1 tasks written into tasks.md | Full |
| 9 | ring:pre-dev-delivery-planning | delivery-roadmap.md + .json | Full |

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
- Gate 1.5 / 2.5 (Design Validation): only if Q4=Yes
- Gate 2 (Feature Map): always for Full Track
- Gates 4-6 (API Design, Data Model, Dependency Map): always for Full Track
- Gate 8 (Task Creation): always for Full Track

## Gate Progress Tracking

Save state to `docs/pre-dev/{feature}/workflow-state.json`:
```json
{
  "track": "full",
  "feature": "{feature-name}",
  "currentGate": 0,
  "gates": {
    "0": "PENDING", "1": "PENDING", "1.5": "SKIP|PENDING",
    "2": "PENDING", "2.5": "SKIP|PENDING", "3": "PENDING",
    "4": "PENDING", "5": "PENDING", "6": "PENDING",
    "7": "PENDING", "8": "PENDING", "9": "PENDING"
  },
  "topology": {},
  "inputs": {"hasUI": false, "authRequired": false, "licenseRequired": false, "uiLibrary": null, "styling": null}
}
```

## Execution Mode

AskUserQuestion at start: "Execution mode?"
- **Automatic** — all gates execute, pause only on failure
- **Manual** — checkpoint and wait for approval after each gate

## Completion

After Gate 9 approved: artifacts are the execution baseline. Use `ring:dev-cycle` to execute.
