---
name: ring:planning-small-features
description: "Planning the lightweight 4-gate Small Track pre-dev workflow (research, PRD, TRD, plan) with human approval and state tracking at each gate. Use for features under 2 days that reuse existing patterns and add no new dependencies, data models, or services. Skip for larger or complex features — use ring:planning-large-features instead. Plans only — no edits."
---

# Small Track Pre-Dev Workflow (4 Gates)

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

**Runs before:** ring:running-dev-cycle, ring:executing-plans

## Related

**Complementary:** ring:planning-large-features, ring:creating-worktrees, ring:product-designer + ring:validating-ux-completeness (standalone UX step, recommended when feature has UI)
**Skills orchestrated:**
- ring:researching-features
- ring:writing-prds
- ring:writing-trds
- ring:writing-plans


Running the **Small Track** pre-development workflow for features that take <2 days, use existing patterns, add no new external dependencies, create no new data models, require no multi-service integration, and can be completed by a single developer.

For complex features (any of the above false), use `ring:planning-large-features` instead.

## Gate Map

| Gate | Skill | Output |
|------|-------|--------|
| 0 | ring:researching-features | research.md |
| 1 | ring:writing-prds | prd.md |
| 2 | ring:writing-trds | trd.md |
| 3 | ring:writing-plans | plan.md |

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

All gates (0-3) always run. Human approval required at each gate before proceeding.

**Gate 3 (Plan):** invoke `ring:writing-plans` with trd.md as the spec input (no feature-map on Small Track), passing `TopologyConfig`. Output path: `docs/pre-dev/{feature}/plan.md` (overrides the writing-plans default). plan.md is always a SINGLE document per feature. **Topology clause:** when `TopologyConfig` structure is monorepo or multi-repo, each epic carries one line `**Target:** backend | frontend | infra` (placed right before `**Status:**`); for multi-repo, the orchestrator copies plan.md into each repo and the local dev-cycle executes only epics whose Target matches that repo. No per-module plan splits.

**Standalone UX step (if Q4=Yes):** after Gate 1 approval, RECOMMEND running `ring:product-designer` + `ring:validating-ux-completeness` before Gate 2 (TRD). It is optional, not a gate, and not tracked in workflow-state.json. If design-validation.md exists when Gate 2 runs, the TRD honors its verdict; if absent, proceed and note the UX risk.

## Gate Progress Tracking

Save state to `docs/pre-dev/{feature}/workflow-state.json`:
```json
{
  "track": "small",
  "feature": "{feature-name}",
  "currentGate": 0,
  "gates": {"0": "PENDING", "1": "PENDING", "2": "PENDING", "3": "PENDING"},
  "topology": {},
  "inputs": {"hasUI": false, "authRequired": false, "licenseRequired": false, "uiLibrary": null, "styling": null}
}
```

## Execution Mode

AskUserQuestion at start: "Execution mode?" Options: Automatic (pause only on failure), Manual (checkpoint after each gate).

## Completion

After Gate 3 approved: `docs/pre-dev/{feature}/plan.md` is the single execution document. Execute with `ring:running-dev-cycle` (subagent orchestration) or `ring:executing-plans` (inline).
