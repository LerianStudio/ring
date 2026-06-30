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

## Lerian Map Card Creation (mandatory)

**MANDATORY final step of the planning workflow. Runs automatically AFTER Gate 3 is approved (plan.md validated) — never before.** Because plan.md is the canonical epic list at this point, the Lerian Map cards are created here as part of concluding the planning workflow. Cards are NO LONGER created at the start of `ring:running-dev-cycle` — moving creation here avoids the rework of re-deriving the epics once the dev cycle begins, and makes the board reflect the plan as soon as it is approved.

### Why here

The epic-card creation handshake lives canonically in `ring:running-dev-cycle` (`## Lerian Map Sync (optional)` → `### Discovery handshake`, steps 1–5), where it historically ran before the first Gate 0 — by then planning happened in an earlier session, so the feature was already mapped and the cards were pure rework. Planning now OWNS card creation: it runs that same canonical handshake at the end of the gates (when plan.md just passed Gate 3, epics freshest) and persists the result so the dev cycle reuses it. In `ring:running-dev-cycle` card creation is now an OPTIONAL fallback — see its `### Discovery handshake`.

### Step (after Gate 3 approval — no opt-in question)

1. **Do NOT ask whether to create cards.** Creation is part of the planning completion flow, not an opt-in. Run the canonical discovery handshake; do NOT reimplement it. Execute `ring:running-dev-cycle` → `## Lerian Map Sync (optional)` → `### Discovery handshake` steps 1–5 exactly as written (all Map I/O through `ring:delegating-to-gandalf` — never a direct Map API call):
   - repo → `GET /products(repositoryUrl)` → resolve product
   - `GET /features` → resolve the Feature by name (AskUserQuestion if ambiguous) → `featureId`
   - resolve the feature's **`Desenvolvimento`** milestone BY NAME → `dev_milestone_id` (if it cannot be resolved → STOP and surface to the user; MUST NOT create the Feature or any milestone — they come from the template)
   - build ONE epic-card per epic in plan.md (`tipo: Task`, checklist = that epic's task names), matched by name + `[map:#<card_id>]` tag — CREATE only the missing ones
   - **preview the create plan ONCE + confirm**, then `POST /tasks` for the confirmed cards; record each `card_id` (+ checklist item ids) and auto-inject the `[map:#<card_id>]` tags
   - The only interaction is the create-plan preview+confirm (the user confirms the card SET, not whether to create).
2. **Persist** the result into `docs/pre-dev/{feature}/workflow-state.json` (see below) so `ring:running-dev-cycle` reuses it — persisting `featureId`, `devMilestoneId`, the per-epic `cardId`s and their `checklistItemIds` is the contract the dev cycle relies on to skip re-creation.
3. **Map unreachable (genuine outage only):** if the Map cannot be reached so the cards cannot be created, surface the error to the user. plan.md is already generated (planning's primary deliverable is complete), but record the card creation as not-done (omit the `lerianMap` block, or set `cardsCreated: false`) so `ring:running-dev-cycle` falls back to its own discovery handshake.

### Persisted state (consumed by ring:running-dev-cycle)

When cards are created, extend `docs/pre-dev/{feature}/workflow-state.json` with a `lerianMap` block. **Key naming (one scheme for the contract):** the persisted keys are camelCase end-to-end — `featureId`, `devMilestoneId`, `cardId`, `checklistItemIds` — and those are the canonical names the dev cycle reads. They mirror the Map API's snake_case fields (`card_id`, `dev_milestone_id`); only the `[map:#<card_id>]` plan tag keeps the Map's snake_case form. `checklistItemIds` ARE part of the reuse contract: the dev cycle adopts them directly to flip each checklist item `done` (re-resolving ids from a fetched card only when that card had to be re-created).

```json
"lerianMap": {
  "cardsCreated": true,
  "createdAt": "ISO timestamp",
  "featureId": 77,
  "devMilestoneId": 433,
  "devMilestoneName": "Desenvolvimento",
  "cards": [
    {"epic": "Epic 1.1", "cardId": 1222, "checklistItemIds": {"Task 1.1.1": "uuid"}}
  ]
}
```

`ring:running-dev-cycle`'s discovery handshake checks this block at init: when the `lerianMap` block is present (`cardsCreated == true` with `featureId` + `devMilestoneId` + non-empty `cards[]`), it treats card creation as ALREADY DONE — it SKIPS the create-with-preview handshake (steps 2–4) and only re-validates the recorded `cardId`s against the board via `GET /tasks/{id}` (re-creating only any that no longer exist), and adopts `featureId`/`devMilestoneId`/`cardId`s/`checklistItemIds` as the source of truth (Map sync implicitly enabled, no opt-in re-asked). Only when the block is ABSENT does the dev cycle run the full create handshake itself — backward-compat for features planned before this flow.
