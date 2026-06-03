---
name: ring:pre-dev-feature
description: |
  Lightweight 5-gate pre-dev workflow for small features (<2 days).
  Orchestrates topology discovery, research, PRD with UX validation,
  design validation, TRD, task breakdown, and delivery planning
  in a sequential gated process with human approval at each gate.
---

# Small Track Pre-Dev Workflow (5 Gates)

## When to use

- Feature takes <2 days to implement
- Uses existing architecture patterns
- Doesn't add new external dependencies
- Doesn't create new data models/entities
- Doesn't require multi-service integration
- Can be completed by a single developer

## Skip when

- Feature is complex (>=2 days) - use ring:pre-dev-full instead
- Adds new dependencies, data models, or architecture patterns

## Sequence

**Runs before:** ring:writing-plans, ring:dev-cycle

## Related

**Complementary:** ring:pre-dev-full, ring:writing-plans, ring:worktree
**Skills orchestrated:**
- ring:pre-dev-research
- ring:pre-dev-prd-creation
- ring:pre-dev-design-validation
- ring:pre-dev-trd-creation
- ring:pre-dev-task-breakdown
- ring:pre-dev-delivery-planning


Running the **Small Track** pre-development workflow for features that take <2 days, use existing patterns, add no new external dependencies, create no new data models, require no multi-service integration, and can be completed by a single developer.

For complex features (any of the above false), use `ring:pre-dev-full` instead.

## Gate Map

| Gate | Skill | Output |
|------|-------|--------|
| 0 | ring:pre-dev-research | research.md |
| 1 | ring:pre-dev-prd-creation | prd.md |
| 1.5 | ring:pre-dev-design-validation | design-validation.md (if UI) |
| 2 | ring:pre-dev-trd-creation | trd.md |
| 3 | ring:pre-dev-task-breakdown | tasks.md |
| 4 | ring:pre-dev-delivery-planning | delivery-roadmap.md + .json |

All artifacts saved to: `docs/pre-dev/<feature-name>/`

## Step 1: Gather Feature Name

AskUserQuestion: "What is the name of your feature?" (kebab-case, e.g., "user-logout", "email-validation")

## Step 2: Topology Discovery (MANDATORY)

Execute topology discovery per [shared-patterns/topology-discovery.md](../shared-patterns/topology-discovery.md). Store as `TopologyConfig` for all subsequent gates.

## Step 3: Gather Feature-Specific Inputs

**Q2 (CONDITIONAL):** Auth requirements — auto-detect from `go.mod` (`lib-auth` present → skip). Options: None, User only, User + permissions, Service-to-service, Full.

**Q3 (CONDITIONAL):** License requirements — auto-detect from `go.mod` (`lib-license-go` present → skip). Options: No, Yes.

**Q4 (MANDATORY):** Has UI? Options: Yes, No. Always ask — do not assume.

**Q5 (if Q4=Yes):** UI component library — auto-detect from package.json, confirm with user.

**Q6 (if Q4=Yes):** Styling approach — auto-detect from package.json, confirm with user.

## Step 4: Execute Gates Sequentially

| Gate | Condition |
|------|-----------|
| Gate 0 | Always |
| Gate 1 | Always |
| Gate 1.5 | Only if Q4=Yes (feature has UI) |
| Gate 2 | Always |
| Gate 3 | Always |
| Gate 4 | Always |

Human approval required at each gate before proceeding.

## Gate Progress Tracking

Save state to `docs/pre-dev/{feature}/workflow-state.json`:
```json
{
  "track": "small",
  "feature": "{feature-name}",
  "currentGate": 0,
  "gates": {"0": "PENDING", "1": "PENDING", "1.5": "SKIP|PENDING", "2": "PENDING", "3": "PENDING", "4": "PENDING"},
  "topology": {},
  "inputs": {"hasUI": false, "authRequired": false, "licenseRequired": false, "uiLibrary": null, "styling": null}
}
```

## Execution Mode

AskUserQuestion at start: "Execution mode?" Options: Automatic (pause only on failure), Manual (checkpoint after each gate).

## Completion

After Gate 4 approved: use `ring:dev-cycle` to execute tasks.
