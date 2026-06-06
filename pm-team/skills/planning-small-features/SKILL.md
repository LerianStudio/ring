---
name: ring:planning-small-features
description: "Planning the lightweight 5-gate Small Track pre-dev workflow (research, PRD with design validation, TRD, phases and epics, delivery planning) with human approval and state tracking at each gate. Use for features under 2 days that reuse existing patterns and add no new dependencies, data models, or services. Skip for larger or complex features — use ring:planning-large-features instead. Plans only — no edits."
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

- Feature is complex (>=2 days) - use ring:planning-large-features instead
- Adds new dependencies, data models, or architecture patterns

## Sequence

**Runs before:** ring:writing-plans, ring:running-dev-cycle

## Related

**Complementary:** ring:planning-large-features, ring:writing-plans, ring:creating-worktrees
**Skills orchestrated:**
- ring:researching-features
- ring:writing-prds
- ring:validating-ux-completeness
- ring:writing-trds
- ring:decomposing-phases-and-epics
- ring:planning-delivery


Running the **Small Track** pre-development workflow for features that take <2 days, use existing patterns, add no new external dependencies, create no new data models, require no multi-service integration, and can be completed by a single developer.

For complex features (any of the above false), use `ring:planning-large-features` instead.

## Gate Map

| Gate | Skill | Output |
|------|-------|--------|
| 0 | ring:researching-features | research.md |
| 1 | ring:writing-prds | prd.md |
| 1.5 | ring:validating-ux-completeness | design-validation.md (if UI) |
| 2 | ring:writing-trds | trd.md |
| 3 | ring:decomposing-phases-and-epics | tasks.md (phased plan; Phase 1 detailed inline) |
| 4 | ring:planning-delivery | delivery-roadmap.md + .json |

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

After Gate 4 approved: use `ring:running-dev-cycle` to execute tasks.
