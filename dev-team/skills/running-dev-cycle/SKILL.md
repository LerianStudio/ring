---
name: ring:running-dev-cycle
description: "Running the backend dev cycle: implements every task in a rolling-wave plan.md (ring:writing-plans format) for a Go/TS service, driving specialist agents through Gate 0 implementation/TDD, Gate 8 parallel review, and Gate 9 validation per epic, elaborating later phases at each phase boundary. Use when starting or resuming a gated backend dev cycle with a plan.md (legacy tasks.md only for cycles already in flight; new cycles need the canonical plan format). Skip for frontend (use ring:running-dev-cycle-frontend) or docs-only work."
---

# Development Cycle Orchestrator

## When to use
- Starting a new development cycle with a phased plan (plan.md from pre-dev or standalone ring:writing-plans)
- Resuming an interrupted development cycle
- Need structured, gate-based epic execution with quality checkpoints and phase cadence

## Skip when
- No plan file exists AND the Lerian Map is not the task source (in `lerian_map` mode no local plan is required — the cycle materializes one from the board)
- Task is documentation-only or planning-only
- Frontend project (use ring:running-dev-cycle-frontend instead)


You orchestrate. Agents execute. You NEVER read, write, or edit source code directly.

## How This Works

Load the phased plan (plan.md, ring:writing-plans canonical format) and execute the lean backend cycle. **Exception — board as source:** when cycle-init question 3 (Task source) = `Lerian Map (board is the source)`, do NOT require a plan path — run the Init flow in `## Lerian Map as Task Source (optional)` to materialize the derived plan first, then proceed identically against it. The plan is rolling-wave phased: a `## Phase Overview` table (phases + milestone + status), phase sections containing `### Epic N.M:` headings (each epic carries a `**Status:**` line: Pending/Doing/Done/Failed), and inline dispatch-ready `#### Task N.M.T:` blocks written under each epic of the currently-detailed wave. Only the active wave is task-detailed; later phases are epic-level and get elaborated at each phase boundary. Backend implementation owns local runtime and quality so the flow does not dispatch separate QA, SRE, or DevOps gates.

**Vocabulary:** Phase = independently verifiable checkpoint (internal rolling-wave structure — NOT a Map milestone). Epic (Epic N.M) = value-driven increment, the UNIT this cycle iterates. Task (Task N.M.T) = dispatch-ready unit, the Gate 0 execution unit.

**Announce at start:** "Using ring:running-dev-cycle lean backend flow (rolling-wave phased plan)."

## Gate Map

| Gate | Skill to Load | Agent to Dispatch | Cadence | Mode |
|------|---------------|-------------------|---------|------|
| 0 | ring:implementing-tasks | ring:backend-go / ring:backend-ts | Per task (Task N.M.T) | Write + Run |
| 8 | ring:reviewing-code | 9 default reviewers + triggered specialists in parallel | Per epic (Epic N.M) | Run |
| 9 | ring:validating-acceptance-criteria | N/A (verification) | Per epic | Run |
| 11.5 | (orchestrator + 1 planning agent) | ring:backend-go / ring:backend-ts / ring:frontend / ring:codebase-explorer (ANALYSIS mode) | Per phase boundary | Plan only |

Gate 0 includes TDD RED/GREEN, coverage threshold enforcement, docker-compose/local runtime updates, basic health/observability verification, and delivery verification. Do not dispatch separate QA, SRE, or DevOps gates as part of this cycle. Step 11.5 (phase cadence) closes the just-finished phase and rolling-wave elaborates the next phase's epics into dispatch-ready tasks — read `gates/phase-boundary.md`.

## Execution Order

```yaml
# INIT: when task_source == "lerian_map", materialize the derived plan from the board first
# (see "## Lerian Map as Task Source (optional)") — every loop below runs unchanged against it

for each phase (current wave; starts at Phase 1, the only detailed phase at init):

  for each epic in this phase (plan order):

    # 1. TASK-LEVEL build (per task Task N.M.T, or epic-itself if no task breakdown)
    for each task:
      Gate 0  # build task
      [checkpoint if manual_per_task mode]

    # 2. EPIC-LEVEL review (once per epic, after all tasks are built)
    Gate 8  # review whole epic — 9 parallel reviewers see cumulative diff

    # 3-4. Fix CRITICAL/HIGH/MEDIUM, then re-review until clean (inside Gate 8)

    # 5. EPIC-LEVEL validation (once per epic, after review passes)
    Gate 9  # validate whole epic — aggregate EVERY task's acceptance criteria + ONE human approval
            # criterion FAIL → back to Gate 0 for that task, then re-review (step 2) → re-validate

    # 6. "Proceed to next epic?" checkpoint (Step 11.1) → next epic in this phase

  # 7. PHASE BOUNDARY (Step 11.5, after the LAST epic of the phase is approved) — read gates/phase-boundary.md
  #    close phase (Phase Overview → Complete, record deviations) →
  #    phase checkpoint (manual: ask Continue/Pause/Adjust | auto: log + continue) →
  #    elaborate next phase's epics into dispatch-ready tasks (1 planning agent, ANALYSIS mode) →
  #    validate elaboration → resume epic loop at Gate 0 for the new phase
  #    (no next phase → fall through to cycle-end)

# 8. CYCLE-END (once, after the LAST phase completes its boundary) — see "Cycle Completion"; read gates/cycle-completion.md
Final Test Confirmation → Multi-Tenant Verify → Migration Safety (Gate 0.5D, conditional) → dev-report → Final Commit
```

## Gate Execution Workflow

For EVERY gate, follow this exact sequence:

```
1. Read gate-specific instructions  → Gate 0: Read("gates/gate-0-implementation.md"); Gate 8: Read("gates/gate-8-review.md"); Gate 9: Read("gates/gate-9-validation.md"); Phase boundary (Step 11.5): Read("gates/phase-boundary.md")
2. Load sub-skill                   → Skill("ring:{sub-skill-name}")
3. Follow sub-skill dispatch rules  → Sub-skill tells you HOW to dispatch
4. Dispatch agent                   → Task(subagent_type="ring:{agent}", ...)
5. Validate agent output            → Per sub-skill validation rules
6. Update state                     → Write to current-cycle.json
7. Next gate or checkpoint
```

Never dispatch an agent without loading the sub-skill first.
Never skip from standards → agent directly. Always: standards → sub-skill → agent.

## Standards Loading

At cycle start (Step 1.5), pre-cache Ring standards:

1. WebFetch the standards index for the project language (e.g., `golang/index.md`)
2. Store cached standards in `state.cached_standards`
3. Pass relevant modules to agents at dispatch time — do NOT re-fetch per gate

## Orchestrator Boundaries

**You CAN:** Read task/state files, write state files, track progress, dispatch agents, ask user questions, WebFetch standards.

**You CANNOT:** Read/write/edit source code (*.go, *.ts, *.tsx), run tests, analyze code directly, make architectural decisions.

If a task involves source code → dispatch specialist agent. No exceptions regardless of file count or simplicity.

## State Management

State lives in `docs/ring:running-dev-cycle/current-cycle.json` (or `docs/ring:planning-backend-refactor/current-cycle.json`).

For state schema, persistence rules, and initialization logic, read `gates/state-schema.md` from this skill directory.

**Critical rule:** Write state after EVERY gate completion. If state write fails → STOP. Never proceed without persisted state.

## PROJECT_RULES.md Check

Before starting any gate execution, verify `docs/PROJECT_RULES.md` exists.

For the full verification process and template creation flow, read `gates/project-rules-check.md` from this skill directory.

If PROJECT_RULES.md doesn't exist → create it using the Ring template before proceeding.

## Cycle Completion

When the epic loop finishes the LAST phase (last epic of the last phase passed all its gates AND that phase's boundary at Step 11.5 found no next phase to elaborate), the cycle is NOT done — a completion phase runs once.

Read `gates/cycle-completion.md` from this skill directory and execute Steps 12.0–12.1 in order:

1. **Step 12.0** — Cycle Exit Verification (HARD GATE: every Gate 0 handoff has passing tests, coverage ≥ threshold, local runtime; plus multi-tenant dual-mode verified for all units)
2. **Step 12.0.5b** — Gate 0.5D Migration Safety (conditional: runs only when SQL migration files appear in the cycle diff vs `origin/main`)
3. **Step 12.1** — the one-and-only `ring:writing-dev-reports` dispatch, then Final Commit (which captures the feedback it generates)

⛔ The cycle is incomplete until Step 12.1 finishes. Do NOT declare the cycle done from the Execution Order summary alone — the detailed, mandatory steps live in `gates/cycle-completion.md`.

## Execution Modes

Ask user at cycle start (independent questions, in the order given at the end of this section):

**1. Execution mode** (epic/task checkpoint cadence):

| Mode | Behavior |
|------|----------|
| `automatic` | All gates execute, pause only on failure |
| `manual_per_epic` | Checkpoint after each epic completes all gates |
| `manual_per_task` | Checkpoint after each task completes task-level gates |

**2. Phase checkpoint** (`state.phase_checkpoint`):

| Value | Behavior |
|-------|----------|
| `manual` (default) | At each phase boundary (Step 11.5), AskUserQuestion: Continue / Pause / Adjust plan first |
| `auto` | At each phase boundary, log a phase summary and continue (still elaborates the next phase) |

Mode and phase_checkpoint affect CHECKPOINTS (user approval pauses), not GATES. All listed gates execute regardless of mode. The phase boundary's elaboration step runs in BOTH phase_checkpoint values — only the pause differs.

**3. Task source** (`state.task_source`; see `## Lerian Map Sync (optional)` and `## Lerian Map as Task Source (optional)`):

Ask AFTER execution mode and BEFORE commit timing (the Map decision — esp. `Done` = push-to-develop — influences how the user thinks about commit cadence). The Map options are opt-in: users who don't use the Map pick `Local plan` and see zero behavior change (zero Gandalf calls, feature fully off).

⛔ **HARD REQUIREMENT: single-select (`multiSelect: false`), exactly ONE option, explicitly selected by the user — NO silent default applied without asking.**

```yaml
AskUserQuestion:
  question: "Where do this cycle's tasks come from?"
  header: "Task source"
  multiSelect: false
  options:
    - label: "Local plan"                        # → task_source = "plan_file"
    - label: "Local plan + Map sync"             # → task_source = "plan_file_synced"
    - label: "Lerian Map (board is the source)"  # → task_source = "lerian_map"
```

| Option | `state.task_source` | Behavior |
|--------|---------------------|----------|
| **Local plan** | `"plan_file"` | plan.md is the source. No board involvement — set `state.lerian_map_sync.enabled = false` (or omit the object), skip the Testing-gate question, **zero Gandalf/Map calls ever**. Today's default behavior. |
| **Local plan + Map sync** | `"plan_file_synced"` | plan.md is the source; Ring PUSHES status + per-task checklist `done` to the board at the existing hooks (exactly the `## Lerian Map Sync (optional)` behavior). Push targets: epic status → the EPIC card; task `done` → the card's checklist item (merge-by-id). This is the core preserved feature. Set `state.lerian_map_sync.enabled = true`, then ask the Testing-gate question, and run the discovery handshake before the first Gate 0. Rolling-wave: the handshake ensures checklist items only for tasks known at init; tasks elaborated in later phases get their checklist items ensured at the phase boundary (`gates/phase-boundary.md` Step 11.5.5b, step 1a) so their `done` flip has a target. |
| **Lerian Map (board is the source)** | `"lerian_map"` | The Lerian Map board IS the task source — see `## Lerian Map as Task Source (optional)`. **DOWNGRADED (structurally forced):** the board no longer holds per-task contracts (a Task is a checklist item — `text` + `done` only), so the cycle materializes a derived plan SKELETON from the feature's `Desenvolvimento` cards (epics ← cards + macro body, tasks ← checklist item names, all under a single Phase 1 — the board has NO phase concept, MUST NOT map milestones to phases) and the rolling wave elaborates the per-task contracts INTO the derived plan; a checklist item already `done=true` = "already complete, skip at Gate 0". Also set `state.lerian_map_sync.enabled = true` (source mode implies status sync) and ask the Testing-gate question. |

**Resume backward compatibility:** if an existing `current-cycle.json` has no `task_source` field, infer `"plan_file_synced"` when `lerian_map_sync.enabled == true`, else `"plan_file"`. NEVER re-ask this question on resume.

**4. Testing gate** (OPTIONAL — only asked when the task source involves the Map (`plan_file_synced` or `lerian_map`); stored in `state.lerian_map_sync.testing_gate`):

```yaml
AskUserQuestion:
  question: "When a card reaches Testing, wait for your explicit OK before opening the PR (→ develop)?"
  header: "Testing gate"
  options:
    - label: "Gate (wait)"   # card parks in Testing; cycle pauses until you test + say OK, THEN opens PR → To Review
    - label: "Bypass"        # after Gate 9, auto-advance: open PR → To Review without waiting for a manual-test OK
```

⚠️ **Does NOT override Gate 9.** Gate 9 (validation/acceptance) is a CRITICAL, non-bypassable gate that always requires explicit user approval per epic (Step 11.1). The Testing gate is a SEPARATE, Map-aware control over the *manual-test wait before PR/develop* — it can only relax that extra Testing wait, never the mandatory Gate 9 acceptance.

**5. Commit timing** (`state.commit_timing ∈ {per_task, per_epic, at_end}`): when commits happen during the cycle — see `## Commit Timing` for what each value commits at which gate.

**Resulting cycle-init question order:** execution mode → phase checkpoint → **Task source** → **Testing gate** (only when the source involves the Map) → commit timing.

## Custom Instructions

If user provides custom context at cycle start, store in `state.custom_prompt` and inject at the top of every agent dispatch:

```
**CUSTOM CONTEXT (from user):**
{state.custom_prompt}

---

**Standard Instructions:**
[... agent prompt ...]
```

## Commit Timing

- Gate 0 (implementation): Commit after GREEN phase, coverage, docker-compose/local runtime, and delivery verification pass (`commit_timing == "per_task"`)
- Gate 8 (review): Commit fixes after all reviewers pass
- Gate 9 (validation): No commit (verification only); epic-level commit at Step 11.1 when `commit_timing == "per_epic"`
- Cycle-end: Final commit with cycle metadata

`commit_timing ∈ {per_task, per_epic, at_end}`. Convention: `feat|fix|test|chore(scope): description` — keep commits atomic per gate.

## Lerian Map Sync (optional)

**OPTIONAL and opt-in.** When enabled (cycle-init question 3 Task source = `Local plan + Map sync`, or implied by `Lerian Map (board is the source)` — see `## Lerian Map as Task Source (optional)`), this feature keeps the Lerian Map kanban board in sync as epics/tasks move through the gates. When off (`Local plan`), the cycle behaves exactly as before — **zero Gandalf calls**. The feature **never blocks gate execution** and **never weakens any mandatory gate** (Gate 9 acceptance still requires explicit user approval per epic, regardless of the Testing-gate setting).

**Mapping:** Epic → Map **task-card** (`tipo: Task`); Task → **checklist item** (`{id, text, done}`) inside that card; card `body` = macro epic overview; checklist item `text` = task name. The epic card attaches to a milestone chosen by epic NATURE — a dev epic → the feature's **`Desenvolvimento`** milestone (resolved BY NAME within the feature). Plan **Phase is internal rolling-wave only — NOT a Map entity** (MUST NOT map Phase → milestone). See `## Lerian Map as Task Source (optional)` → Hierarchy mapping for the full table.

⛔ **Two directions of sync — only ONE is the core feature here:**
- **Ring → Map (PUSH): PRESERVED — the core feature.** During the cycle the dev-cycle automatically updates the EPIC **card status** (`in_progress` at epic start → `testing` → `to_review` → `done` at push-to-develop) and flips each **checklist item `done=true`** as its task completes. Async, fire-and-forget, idempotent. What is preserved is the ASYNC FIRE-AND-FORGET semantics (idempotent, never-block); the TARGETS moved — status now targets the epic `card_id` (not a per-task card), and per-task completion is now a checklist item `done` merge-by-id (not a per-task card update).
- **Map → Ring (board-as-source): DOWNGRADED.** Only the `lerian_map` mode (board-as-source) changes: the board seeds the SKELETON (epic + task names + macro overview); the dispatch-ready contracts come from the derived `plan.md`, NOT from the Map. See `## Lerian Map as Task Source (optional)`.

**Hard rule:** the synced status follows the **real board columns exactly** — no invented stand-in statuses. Column enum strings are **read from the board at runtime via Gandalf, never hardcoded**.

### Discovery handshake (run once, after the cycle-init questions, before the first Gate 0)

When `state.lerian_map_sync.enabled`, run a one-time handshake (each Gandalf ask is a fresh, self-contained session carrying the full discovery payload):

0. **Resolve the acting user (local — no Gandalf call; both Map modes):** the human this cycle's board writes are attributed to. Primary source: `git config user.email` + `git config user.name` in the repo (matches who signs the cycle's commits; per-machine, so a different person running the cycle in their clone is attributed automatically). Fallbacks in order: the session user's email when git config is unset; else unresolved. Store `state.lerian_map_sync.acting_user = {email, name, source, resolved_at}` — or object-level `acting_user = null` when unresolved (no partial record; see `gates/state-schema.md`). Best-effort — an unresolved identity NEVER blocks the cycle (see `### Author attribution (on-behalf-of)`).
1. **Anchor on the Feature, resolve `featureId` + the `Desenvolvimento` milestone.** Discovery is **repo-driven**: map the local git remote to a product via the Map's native **`repositoryUrl`** field on `GET /products` (no manual `productId`/`teamId`/`milestoneId`). Normalize the remote first (`git@github.com:org/repo.git` → `https://github.com/org/repo`). Then resolve WHICH **Feature** (`GET /features` for the product): match by name; if more than one candidate, **AskUserQuestion to pick** among the product's features. Record `featureId`. ⛔ The **HUMAN creates the Feature** (in the Map UI, which copies the fixed milestone template) — the flow MUST NOT create or edit the Feature. From the resolved feature's milestones, resolve the **`Desenvolvimento`** milestone BY NAME → `dev_milestone_id` (+ `dev_milestone_name`). If `Desenvolvimento` cannot be resolved on the feature → STOP and surface to the user — MUST NOT create milestones (they come from the template). Fetch any existing cards under `(featureId, dev_milestone_id)` with each card's `body` (macro overview), `checklist` (`{id, text, done}[]`), and status.
2. **CREATE one task-card per epic** under `(featureId, dev_milestone_id)`, each carrying a checklist of its task names (+ macro body in `lerian_map`; in `plan_file_synced` the body is user-owned, optional). Cards already on the board are MATCHED, not duplicated — the deterministic key is the **`[map:#<card_id>]` tag** embedded at the epic level in the plan; **title-matching by epic name is the fallback** when no tag is present. CREATE only the epics that have no matching card. Each Task maps to a **checklist item** inside its epic's card, by `checklist_item_id` (or item `text` ↔ task name on first match); ensure one checklist item exists per task (merge-by-`checklist_item_id`, create-if-absent keyed by `text` = task name, NEVER array-replace) so every Task has a `done` target. Creating the cards and their checklist items is a Ring → Map PUSH (the preserved write direction) — NOT a contract READ; the Map → Ring downgrade is only about no longer reading dispatch-ready contracts FROM the board.
3. **Preview the create plan ONCE + confirm.** Show ONE preview table of the full create plan — the **N cards** to create + each card's checklist (and, for already-present cards, the matched local epic ↔ card with its current column) — and ask the user OK. Only AFTER the user confirms: create the missing cards/checklist items. Record each `card_id` + `checklist_item_id`. MUST NOT create the Feature or any milestone in this step.
4. **Auto-inject tags (with confirmation).** After the cards exist, inject the resolved `[map:#<card_id>]` tags into the plan at the epic level so future runs are deterministic and rename-proof.
5. **Persist** the mapping (`featureId`, `dev_milestone_id`, `epic_matches[]` + `task_matches[]`) + the board's real status enum into `state.lerian_map_sync` (see `gates/state-schema.md`). In the same ask, instruct Gandalf to set the product/card `repositoryPath` to the repo URL — set-if-empty, best-effort, once per cycle (see `### Evidence & enrichment`).

**Discovery path that works (validated):** `repo → /products(repositoryUrl) → /features (resolve the feature → featureId) → resolve "Desenvolvimento" milestone (by name → dev_milestone_id) → POST/GET /tasks?featureId&milestoneId (epic-cards, create-with-preview, matched by name + [map:#<card_id>] tag) → card.checklist (items)`.

### Status mapping (dev-cycle stage → real board column)

Status pushes target the **EPIC card** (`card_id`). The per-task `done=true` flip targets the **checklist item** (`checklist_item_id`) inside that card.

| Dev-cycle event | Target | Board state | Notes |
|-----------------|--------|-------------|-------|
| Epic loaded, not started | epic card | `To do` | baseline; only set if currently in `Backlog` |
| Epic Gate 0 start (first task of the epic begins) | epic card | `In Progress` | epic is actively being built; the push sends the absolute target column `In Progress`, and the cycle applies a guard so it does not regress a card already further along (only advances from `Backlog`/`To do`). Pushed ONCE per epic — the once-per-epic local guard is tracked via `epic_matches[].status_dispatch` |
| Epic validated (Gate 8 review + Gate 9 pass), awaiting user manual test | epic card | `Testing` | the "Em Teste" the user actually tests; STAYS here through approval. Gate 8 is an INTERNAL dev-cycle review — it does NOT get its own board column. |
| User approved → PR opened, awaiting human merge-review | epic card | `To Review` | matches the board order `Testing → To Review → Done` |
| PR merged → committed AND pushed to repo (≥ `develop`) | epic card | `Done` | ⭐ the **ONLY** trigger for `Done` — the push-to-develop / PR-merge event, **NOT Gate 9** |
| Per-task completion at push-to-develop (≥ `develop`) | checklist item | `done=true` | flip the completed task's checklist item; MERGE-BY-`checklist_item_id` (read-modify-write), NEVER replace the array. Same terminal trigger as the epic `done` status, NOT Gate 9. |
| A gate fails hard / external blocker | epic card | `Blocked` | off-path |
| Cycle parked for non-blocking reasons | epic card | `On Hold` | off-path / optional / manual |
| Epic dropped | epic card | `Canceled` | off-path / optional / manual |

**Lifecycle (monotonic, matches board column order):** `To do → In Progress → Testing → To Review → Done` on the epic card, with `Blocked`/`On Hold`/`Canceled` off-path.

The `Testing → To Review` hop depends on the **Testing gate** (cycle-init question 4):
- **`gate` (wait):** card parks in `Testing`; the cycle waits for the user's OK, then opens the PR → `To Review`. (SLC rule — human tests the epic before the PR.)
- **`bypass`:** the card still passes *through* `Testing` (status is set) but the cycle does not block; it auto-opens the PR → `To Review`. **Gate 9 acceptance still applies** — bypass only relaxes the manual-test wait, never Gate 9.

### Gandalf integration mechanics

All Map I/O goes **through the Gandalf webhook** (`ring:delegating-to-gandalf`) — never a direct Map API call from dev-cycle. This keeps the dev-team plugin free of Map credentials / instance coupling and works for any Map instance. **No new agent and no new credential** are introduced; the existing webhook is reused.

- **Self-contained prompts:** every ask is a fresh Gandalf session — each message carries the discovery payload (repo, epic/card name, task names, card_id, checklist_item_id) and the **absolute target column** (or the checklist item to flip).
- **Fetch + enum read:** the first ask returns both the matched cards AND the list of valid status values for that board (so column strings are never hardcoded).
- **Status push — ASYNC FIRE-AND-FORGET (never blocks dev):** at each checkpoint the dev-cycle sends ONE webhook POST and immediately gets back a `task_id`; Gandalf's **background worker** performs the actual board update. The dev-cycle **does NOT poll or wait** — it records the dispatch and continues to the next gate/task. The slow work lives on Gandalf's side, off the critical path.
- **Checklist push — MERGE-BY-ID (idempotency, MANDATORY):** the per-task `done=true` flip is a **read-modify-write** on the card's `checklist` array — instruct Gandalf to locate the item by `checklist_item_id`, set its `done`, and PATCH the array. ⛔ It MUST NEVER replace the whole array (that would drop sibling items). A retried push re-asserts the same item id safely. Status pushes, by contrast, are absolute-column on the card (status = X).
- **Visible dispatch log line:** when the hook fires, log a line so the user sees it working in the background, e.g.
  `🔄 Lerian Map Sync: dispatched Epic 1.1 → In Progress (card #1222, gandalf task a1b2c3, background)`
  and record `{task_id, dispatched_at, state: "dispatched"}` in `current-cycle.json`.
- **Author attribution:** every write ask carries the acting-user attribution line — see `### Author attribution (on-behalf-of)`.

### Author attribution (on-behalf-of)

Without attribution, every board write shows Gandalf's own Map account as the author instead of the person running the cycle. The Map API supports impersonation (`X-On-Behalf-Of` header + an impersonate-scoped key — validated via live probe) and has user-lookup endpoints to resolve email → userId. **The key/auth is Gandalf's internal concern — Ring never sees or stores any secret.**

**Rule — EVERY write ask** (epic-card status pushes, checklist `done` flips, date stamps, `repositoryPath`, macro-body write-backs, comment POST/UPDATE) includes one line:

> Attribute this write to the user with email {acting_user.email} ({acting_user.name}) — resolve to the Map user and write on their behalf (X-On-Behalf-Of). If impersonation is unavailable, write under your own identity and — for comments only — prepend the first line `_em nome de {name} <{email}>_` yourself.

When `name` is null (session source), omit the parenthesized name and use the email alone — in both the attribution line and the em-nome-de line (`_em nome de <{email}>_`).

Email → Map userId resolution is Gandalf's job at write time — Ring stores NO Map userId, keeping it free of Map user-table coupling. The acting user comes from `state.lerian_map_sync.acting_user`, resolved once at handshake step 0. This rule lives HERE only — the hook sites already say "the same ask/push carries…"; do NOT repeat the attribution line per hook.

**Fallback (never a strict point) — two branches:**

1. **Impersonation unavailable** — handled GANDALF-side via the template line above (Ring never sees write outcomes — pushes are fire-and-forget — so the conditional must run where the outcome is known): the write proceeds under Gandalf's own identity, and comments alone gain the `_em nome de {name} <{email}>_` line, prepended ABOVE the template's first line (the comment cap becomes ~11 lines in fallback mode). Status / date / checklist writes proceed without attribution.
2. **`acting_user` is null** — handled RING-side (no line possible — the user is unknown): omit the attribution line entirely; all writes proceed under Gandalf's identity, with no em-nome-de line.

Neither branch is ever a strict point — NEVER blocks.

**UPDATEs × attribution:** UPDATEs preserve an existing `em nome de` first line verbatim and never add one to an attributed comment; instruct Gandalf to perform the UPDATE under the same identity that authored the comment (falling back to its own identity only if that fails — best-effort).

### Graceful degradation + deferred reconciliation

Map sync **never blocks gate execution**. Each transition moves through **three states**:

```
pending    → the dev-cycle wants this column but hasn't fired the hook yet (or the POST failed)
dispatched → the webhook POST succeeded; Gandalf has a task_id and is updating in background (NOT yet confirmed)
synced     → confirmed applied on the board
```

State tracks, per matched unit, `desired_status` (what the dev-cycle wants) vs `synced_status` (last *confirmed*), the dispatch record (`task_id`, `dispatched_at`, `state`), plus an ordered **pending queue** (`state.lerian_map_sync.pending`) and a `degraded` flag.

Rules:
1. **Fire, don't wait:** at a checkpoint, POST the transition → on a successful POST, mark `dispatched` with the `task_id` and move on immediately (no polling).
2. **POST itself fails** (Gandalf unreachable / off-Tailscale / timeout): keep the transition `pending`, set `degraded: true`, **log a warning, continue the cycle**.
3. **Best-effort verification (non-blocking):** opportunistically — at the *next* checkpoint, on `--resume`, and at end of cycle — do ONE batched read of outstanding `dispatched` task_ids; any that completed flip to `synced`. Never blocks; if the read fails, items stay `dispatched` and are re-checked later.
4. **Drain pending:** at the same triggers, retry `pending` transitions (oldest → newest). A Gandalf that comes back mid- or post-cycle gets the board caught up automatically; when nothing is `pending`, clear `degraded`. Rules 3–4's triggers cover `epic_matches[].body_dispatch` records (macro-overview pushes) and `task_matches[].done_dispatch` records (checklist `done` flips) identically — see `gates/state-schema.md` — outstanding body and done pushes are verified and drained in the same batched pass.
5. **Idempotent pushes:** each STATUS push sets an **absolute column** on the card (status = X), never a relative move — safe to replay even if a partial update landed. Each CHECKLIST `done` push MERGES BY `checklist_item_id` (read-modify-write) and MUST NEVER replace the whole array — also safe to replay.
6. **End-of-cycle report:** print outstanding items at Step 12.1, e.g.
   `⚠️ Lerian Map Sync: 2 dispatched (awaiting confirmation), 1 pending (Gandalf was down)`.

### Checkpoint hooks (where the async push fires)

When `state.lerian_map_sync.enabled`, the orchestrator fires the async, fire-and-forget board push at these existing checkpoints (each is non-blocking and never gates execution):

| Cycle event | Hook location | Target + value pushed |
|-------------|---------------|------------------------|
| Epic start (first task of the epic's Gate 0 begin) | `gates/gate-0-implementation.md` Pre-Dispatch checkpoint (fires ONCE per epic — guard against re-pushing per task) | epic `card_id` → `in_progress` |
| Epic validated, awaiting user test (Gate 9 pass → Step 11.1) | `gates/gate-9-validation.md` Step 11.1 | epic `card_id` → `testing` (stays here through approval) |
| User approved → PR opened | Step 11.1 advance (and end-of-cycle / PR-open path) | epic `card_id` → `to_review` (gated by `testing_gate`) |
| Push to repo ≥ `develop` (PR merge) | `gates/cycle-completion.md` Step 12.1 (Final Commit / push) | epic `card_id` → `done` — ONLY trigger for `done`, NOT Gate 9 |
| Per-task done at push-to-develop | `gates/cycle-completion.md` Step 12.1 (rides the `done` push, per completed task) | each completed task's `checklist_item_id` → `done=true` (MERGE-BY-id, never array-replace) |
| Task commit moment (per `commit_timing`) | `gates/gate-0-implementation.md` Gate 0 completion (`per_task`) / `gates/gate-9-validation.md` Step 11.1 epic commit (`per_epic`) / `gates/cycle-completion.md` `done` push (`at_end`) | — none (comment-only ask: the task evidence comment POST — see `### Evidence & enrichment`) |
| Hard block at any gate | Blocker Handling | epic `card_id` → `blocked` |

The epic-`in_progress` and epic-`done` pushes also stamp start/end dates and carry the enrichment instructions — see `### Date stamping (start/end)` and `### Evidence & enrichment` below.

### Date stamping (start/end)

The Map UI has INÍCIO (start) and FIM (end) date columns on task-cards. Since an Epic IS a task-card, dates are stamped on the **epic card**. Checklist items have NO date fields — there are no per-task dates. When sync is enabled (BOTH `plan_file_synced` and `lerian_map` — the hooks are shared), the existing epic-status pushes also stamp these dates so the board reflects real execution timing. Dates ride INSIDE the existing pushes — same Gandalf ask, same fire-and-forget posture, same degradation/reconciliation rules: **no new push types, no new strict points, no impact on never-block**. A failed push retries dates together with the status via the existing reconciliation. The date value is captured when the transition is first queued/dispatched and carried in the push payload — a retried push stamps the original event date, never "today at retry time" (a payload field on the queued transition, not a new dispatch record). Card fields are `startDate` / `endDate` (date `YYYY-MM-DD`, nullable — validated via live Gandalf probe).

| Date | Riding push | Rule |
|------|-------------|------|
| Epic card `startDate` | epic `in_progress` (epic Gate 0 start, once per epic) | Set to the event date ONLY if currently null/empty. NEVER overwrite a manually set date. |
| Epic card `endDate` | epic `done` (push-to-develop) | Set if empty or future; keep existing past dates. |

**No new state:** date stamping is idempotent by construction (set-if-empty), so it does NOT need its own dispatch record — do NOT invent one. The status `dispatch` and `body_dispatch` records (`gates/state-schema.md`) remain the only sync-state tracked.

### Evidence & enrichment (comments, repositoryPath)

Beyond columns and dates, the pushes also fill everything else the Map API supports today. API facts (live Gandalf probe): task-card comments exist (`POST /tasks/{id}/comments`, markdown body ≤ 10,000 chars, CRUD) and cards carry a `repositoryPath`. Since an Epic IS a task-card, **all evidence comments post on the EPIC card** — there are no separate per-task cards (tasks are checklist items, which have no comments). Per-task evidence is therefore tagged inside the epic card's comments with a `**Task N.M.T:**` prefix. Everything below rides the existing pushes/asks (fire-and-forget, existing degradation; comments excepted from retry — see the rule below): **no new STATUS push types — the single addition is one comment-only ask at each task's commit moment — no new strict points, no new state records**.

**Evidence comments — post on the EPIC card; max ONE comment per epic card per event (no spam):**

| Event | Card | Comment content |
|-------|------|-----------------|
| Task completed — POSTs ONCE, at the task's COMMIT moment per `commit_timing`: `per_task` → Gate 0 completion (after delivery verification + commit); `per_epic` → the Step 11.1 epic commit; `at_end` → the `done` push (full evidence posted then). Commit SHAs therefore always exist at POST time. | Epic card | ONE consolidated comment tagged `**Task N.M.T:**`: commit SHA(s), TDD evidence (tests added, coverage % vs threshold), verification command + outcome, PR link when available. A still-pending PR link is filled in at the `to_review` push (when the PR opens) via comment UPDATE; the `done` push re-asserts it idempotently — never a second comment. Template below. |
| Epic approved (Gate 9 pass → Step 11.1) | Epic card | ONE comment: review summary (reviewers passed, findings fixed), aggregated criteria PASS, PR link. The epic card always holds the per-task comments AND this epic-level approval comment — both on the same card. |
| Task skipped by the Map Body Hard Gate (`gates/gate-0-implementation.md` Step 2.1.5 option b) | Epic card | ONE comment tagged `**Task N.M.T:**` alongside the existing epic `blocked` push (only if the whole epic is blocked): "skipped: no implementation contract (empty/insufficient plan task block)". |

Task-completed comment template (compact markdown, ~10 lines max — `**Task N.M.T:**` tag identifies which task on the shared epic card):

```text
**Task 1.1.1 ✅ completed by dev-cycle**
- Commits: <sha1>, <sha2>
- Tests: <N added>, coverage <X%> (threshold <Y%>)
- Verification: `<command>` → <outcome>
- PR: <link | pending>
```

**Idempotency/retry rule (comments only):** comments are best-effort fire-and-forget and are NOT retried by the reconciliation — a retried push MUST NOT double-post a comment. Dates and status retry as already documented; comments don't.

**UPDATE, never re-POST:** after the initial POST, every later touch is a comment UPDATE — instruct Gandalf to locate the existing comment by its `**Task N.M.T:**` tag in the epic card's comment list. The lifecycle: POST once at the task's commit moment (table above) → a Gate 0 re-entry (Gate 9 criterion FAIL → rebuild) UPDATEs that task's existing evidence comment with the new evidence → the `to_review` push fills the pending PR link (into the per-task evidence comments AND the epic-approved comment) → the `done` push re-asserts the link idempotently. Max ONE comment per epic card per event (per task tag) holds in every path.

**`repositoryPath`:** during the discovery handshake persist step (step 5), instruct Gandalf to set the card/product `repositoryPath` to the repo URL — set-if-empty, best-effort, once per cycle (in `lerian_map` mode this rides the first ask after the init step 2 fetch).

### Validated facts (live Gandalf test, 2026-06-11, `br-slc`)

- **Product discovery:** `GET /products` exposes a native **`repositoryUrl`** field. `https://github.com/LerianStudio/br-slc` → `productId=13` (SLC), `teamId=5`. Exact match, no ambiguity.
- **Feature + milestone resolution:** `GET /features` for the product → resolve the Feature by name (AskUserQuestion if ambiguous) → `featureId`. The Feature is **human-created** and carries the fixed milestone template (`Planejamento, Desenvolvimento, Documentação, Testes Internos, Teste Taura, Release`). Resolve the **`Desenvolvimento`** milestone BY NAME within the feature → `dev_milestone_id` (e.g. id=433). The flow NEVER creates the Feature or milestones.
- **Epic (task-card) discovery + creation:** `GET /tasks?featureId&milestoneId=433` → existing task-cards (`tipo: Task`) matched **by name** + the `[map:#<card_id>]` tag → card ids **1222, 1223, …**. The **flow CREATEs** the missing cards (`POST /tasks` under `(featureId, dev_milestone_id)`, `tipo: Task`) after the one-time preview+confirm; statuses start `todo`.
- **Tasks (checklist items):** each card carries a `checklist` array of `{id, text, done}` — tasks are matched to checklist items by `id` (or item `text` ↔ task name on first match). The checklist PATCH merges by item `id`.
- **Status enum (EXACT API slugs + ids):**

  | id | slug | label | terminal |
  |----|------|-------|----------|
  | 1 | `backlog` | Backlog | no |
  | 2 | `todo` | To do | no |
  | 3 | `in_progress` | In Progress | no |
  | 8 | `testing` | Testing | no |
  | 9 | `to_review` | To Review | no |
  | 5 | `on_hold` | On Hold | no |
  | 6 | `blocked` | Blocked | no |
  | 4 | `done` | Done | **yes** |
  | 7 | `canceled` | Canceled | **yes** |

- **Known frictions:** no card slug (match by name — fragile → use `[map:#<card_id>]` tags at the epic level); the checklist PATCH must merge by item `id` (never array-replace); `GET /teams` currently returns 500 (use `teamId` from the tasks payload instead).
- **Discovery path:** `repo → /products(repositoryUrl) → /features (resolve the feature → featureId) → resolve "Desenvolvimento" milestone (by name → dev_milestone_id) → POST/GET /tasks?featureId&milestoneId (epic-cards, create-with-preview, by name + [map:#<card_id>]) → card.checklist (items)`.

## Lerian Map as Task Source (optional)

**OPTIONAL.** Active only when `state.task_source == "lerian_map"` (cycle-init question 3 = `Lerian Map (board is the source)`). In this mode the Lerian Map board — not a local plan.md — is the source of truth for WHAT to build and for STATUS. The HUMAN has created the **Feature** and (optionally) some epic-cards under its **`Desenvolvimento`** milestone with checklists. **Because a Task is now a checklist item (`text` + `done` only — no per-task body), the board CANNOT hold per-task dispatch-ready contracts.** So the cycle materializes a derived plan **SKELETON** from the `Desenvolvimento` cards at init (epics ← task-cards + their macro body as epic context; tasks ← checklist item names), then the EXISTING rolling-wave elaboration produces the per-task dispatch-ready contracts INTO the derived plan (only the active wave is task-detailed; later phases elaborated at each phase boundary). ⛔ The board has **NO phase concept** — milestones are fixed template stages, NOT phases. MUST NOT materialize milestones as phases; materialize all `Desenvolvimento` cards under a **single Phase 1** (later structure comes from rolling-wave elaboration). From there every existing gate runs unchanged against the derived plan. Reuses the discovery handshake, Gandalf transport, status mapping, checkpoint hooks, and degradation rules from `## Lerian Map Sync (optional)` — none of that is duplicated here.

⛔ **Invariant: a task with only a name is NOT executable. The dispatch-ready contract lives in the derived `plan.md` — no sufficient plan task block, no Gate 0.** The board contributes the SKELETON (epic + task names + macro epic overview); the contract is elaborated into the derived plan by the rolling wave. Enforced at init (step 3 below — sufficiency validated against the derived-plan task block) and again as a ⛔ HARD BLOCK at every Gate 0 dispatch (`gates/gate-0-implementation.md` Step 2.1.5 — Map Body Hard Gate, which validates the plan task block, not the Map body).

**Hierarchy mapping (Map → plan):**

| Lerian Map | Plan (canonical ring:writing-plans format) |
|------------|--------------------------------------------|
| `task-card` (`tipo: Task`, attached to `(featureId, Desenvolvimento milestone)`) | Epic (`### Epic N.M:`) |
| `checklist item` (`{id, text, done}` inside the card) | Task (`#### Task N.M.T:`) |
| card `body` / DESCRIÇÃO (markdown, macro overview) | Epic context: what the epic is + a short, direct summary of each task — NOT the full dispatch-ready contract |
| `checklist item.text` | The task name (`#### Task N.M.T:` heading) |

⛔ Plan **Phase is internal rolling-wave structure ONLY — NOT a Map entity.** The board has no phase concept; milestones are fixed template stages (`Planejamento, Desenvolvimento, Documentação, Testes Internos, Teste Taura, Release`), NOT phases. The epic card attaches to a milestone chosen by epic NATURE (a backend/frontend dev epic → the feature's `Desenvolvimento` milestone, resolved BY NAME). MUST NOT map a Phase to a milestone.

⛔ The full dispatch-ready task block (Context with file:line refs, Implementation vision, Files, Verification, Done when) lives ONLY in the derived `plan.md`, NOT on the Map. The card body is ALWAYS a macro overview. The per-task contracts are produced by the existing rolling-wave elaboration into the derived plan (see Init flow step 3 and Step 11.5).

### Init flow (source = lerian_map; runs once, instead of loading a local plan)

1. **Discover the board** — run the discovery handshake from `## Lerian Map Sync (optional)` SCOPED for source mode: execute handshake step 0 (acting-user resolution — attribution applies in source mode too), step 1 (repo-driven product discovery + **Feature resolution → `featureId`** + **`Desenvolvimento` milestone resolution BY NAME → `dev_milestone_id`**), and step 5 (persist into state); SKIP handshake steps 2–4 (the card-create preview + tag auto-injection — in source mode the human already authored the cards, so the cycle MATCHES them, it does not create from a local plan). ⛔ MUST NOT resolve "lowest-order not-done" milestone (the board has no phase concept) — the source milestone is ALWAYS the feature's `Desenvolvimento`. If `Desenvolvimento` cannot be resolved on the feature → surface to user (do NOT create milestones). Persist the milestone identity into `state.lerian_map_source` (canonical — the `Desenvolvimento` milestone of the feature; see `gates/state-schema.md`).
2. **Fetch the source data via Gandalf** (`action: ask`, self-contained prompt): the `Desenvolvimento` milestone's task-cards → checklist items, requesting for each card: `id`, `title`, `body` (the macro overview), `status`, `priority`, `checklist` (the `{id, text, done}[]` array), `milestone.{id,name}`. After the fetch, populate `state.lerian_map_sync.epic_matches[]` (ONE per task-card) and `state.lerian_map_sync.task_matches[]` (ONE per checklist item, sharing the card's `card_id`) from the `Desenvolvimento` cards: every unit is board-born, so it is matched by construction.
3. **⛔ Skeleton + contract validation (current milestone ONLY — MANDATORY):** the board contributes the SKELETON (epic + checklist task names + macro card body); the dispatch-ready contract is elaborated INTO the derived plan, NOT read from the Map. A current-milestone epic whose derived-plan task blocks are not sufficient CANNOT enter the cycle — no exceptions; the context MUST be given. Sufficiency = the Step 11.5.5 validation bar (`gates/phase-boundary.md`): no "TBD"/vague deferrals; Context with file:line refs; Implementation vision; Files; Verification; Done when. For any current-milestone epic whose derived-plan task blocks are empty/insufficient → AskUserQuestion:
   - **(a) Elaborate now** — dispatch ONE planning agent in ANALYSIS mode (same mechanism as Step 11.5.4 in `gates/phase-boundary.md`), seeded by the card's macro body + checklist task names, to produce the dispatch-ready blocks and write them INTO the derived plan. The macro overview is (re-)pushed to the card `body` and a checklist item is ensured per task via Gandalf. This push is SYNCHRONOUS — init is the strict point and the skeleton must land before the source is trusted; mid-cycle macro-body/checklist pushes stay fire-and-forget — EXCEPT the Step 2.1.5 hard-gate remediation (`gates/gate-0-implementation.md`), which is synchronous when the Map is reachable (degraded fallback: queue + proceed).
   - **(b) Abort init** — stop so the user fills the board first.

   Future-milestone epics are EXPECTED to carry only the macro body + checklist names — that is the rolling wave; their task blocks get elaborated into the derived plan at phase boundaries (Step 11.5). The plan-block-sufficiency rule is enforced AGAIN as a ⛔ HARD BLOCK at every Gate 0 dispatch (`gates/gate-0-implementation.md` Step 2.1.5 — Map Body Hard Gate, which validates the derived-plan task block), catching drift after init.
4. **Materialize the derived plan skeleton** — write `docs/ring:running-dev-cycle/plan-from-map.md` in the canonical ring:writing-plans format, generated from the fetched board data. ⛔ The board has **NO phase concept**, so materialize ALL `Desenvolvimento` cards under a **single Phase 1**: a `## Phase Overview` table with one row (Phase 1, Status `Detailed`), `### Epic N.M:` sections from the task-cards (epic context = the card's macro body), `#### Task N.M.T:` headings from the card's checklist item names. MUST NOT derive phases from milestones. Later phase structure (Phase 2, 3, …) is NOT read from the board — it emerges from rolling-wave elaboration during execution. Tag EVERY epic heading with the `[map:#<card_id>]` convention (the deterministic matching key, at the EPIC level — see `## Lerian Map Sync (optional)`); checklist items are tracked by `checklist_item_id` in `task_matches[]`. The active wave's epics (Phase 1) get their per-task dispatch-ready blocks written in (elaborated per step 3). Map each fetched checklist item `done` into the plan task checkbox and aggregate to the epic `**Status:**` word:

   | Fetched checklist item `done` | Plan task checkbox |
   |-------------------------------|--------------------|
   | `true` | `- [x] Done` |
   | `false` | `- [ ] Done` |

   In the canonical plan format the `**Status:**` line exists per-EPIC (task blocks carry `- [ ] Done` checkboxes, not Status lines). Apply it as follows:
   - **Epic aggregation:** derive each epic's `**Status:**` word from its checklist items:
     - `Done` — all items `done=true`
     - `Doing` — the card's board status is in {`in_progress`, `testing`, `to_review`} OR any item is `done=true` with others still pending
     - `Pending` — otherwise (card in `backlog`/`todo`, no items completed)
   - **Checkbox materialization:** each checklist item with `done=true` is materialized with its checkbox checked (`- [x] Done`) so completion is visible in the derived plan.
   - **Gate 0 implication:** tasks materialized as `- [x] Done` are already complete and are NOT re-executed at Gate 0 — skip them (same as a `done=true` checklist item on the board); a mid-flight milestone resumes from the first unchecked task.

   Set `state.source_file` to this derived plan. From here on, ALL existing gates (0 / 8 / 9 / 11.5 / 12.x) run unchanged against it.
5. **Source-of-truth rule:** the derived plan is an internal, regenerable execution artifact; the board remains the source of truth for WHAT and STATUS. The board holds the SKELETON only (macro card body + checklist task names + status); the dispatch-ready contracts live ONLY in the derived plan. Manual edits to the derived plan that change a card's macro summary or the set of task names MUST be reflected back to the card `body` / checklist via Gandalf (epic matched via the `[map:#<card_id>]` tag — see write-back rules below); per-task contract edits stay local (the Map never holds them).

**Resume rule:** on `--resume` with `task_source == "lerian_map"` and the derived plan missing from disk, re-run init steps 2 + 4 (fetch + materialize) before resuming the gates — state indices stay authoritative. If the Map is unreachable during this regeneration → treat it as the INIT degradation case below (Retry / fall back / Abort).

### During the cycle

- **Status:** the EPIC card status flows to the board via the existing checkpoint hooks (`## Lerian Map Sync (optional)` → Checkpoint hooks); each completed task flips its checklist item `done=true` at push-to-develop. No changes — source mode implies status sync.
- **Macro-body write-back:** when Gate 8/9 outcomes change an epic's macro summary or its set of task names, push the updated macro overview to the epic's card `body` and ensure the checklist items match (merge-by-`checklist_item_id`, never array-replace) — async fire-and-forget, same `pending → dispatched → synced` degradation rules as status pushes. NEVER blocks a gate. The per-task dispatch-ready contract stays in the derived plan and is NOT pushed to the Map.

### Phase boundary (Step 11.5)

After the planning agent elaborates the next phase's epics into dispatch-ready task blocks in the derived plan, **CREATE one new task-card per new epic** under `(featureId, dev_milestone_id)` — the SAME `Desenvolvimento` milestone, NOT a "next milestone" — with a checklist of its task names, push each epic's macro overview to the card `body`, and tag the epic with the new `[map:#<card_id>]`. Cards already present are matched by `[map:#<card_id>]`, not duplicated; ensure one checklist item exists per task (merge-by-`checklist_item_id`, create missing items, never array-replace). Same create path as init, but fire-and-forget (never blocks the gate). The dispatch-ready contracts stay in the derived plan; only the macro skeleton reaches the board. **Reconciliation:** the flow CREATEs the missing cards/items; DELETING cards stays user-only (never silent); the Feature is never created/edited/deleted by the flow. The full rule (and its best-effort board fetch) lives in `gates/phase-boundary.md` Step 11.5.5b. This is the rolling-wave behavior: later-phase epics get their cards created under `Desenvolvimento` as development reaches them.

### Graceful degradation (source mode is stricter than sync mode at init)

- **At INIT:** Gandalf/Map unreachable = the task source itself is unavailable → AskUserQuestion: **Retry** / **Fall back to a local plan** (switch `state.task_source` to `"plan_file"` AND set `state.lerian_map_sync.enabled = false` — or remove the `lerian_map_sync` object entirely, incl. `testing_gate` — so no sync hook ever fires; ask for the plan path; zero further Map calls) / **Abort**.
- **DURING the cycle:** the derived plan already holds everything the gates need, so Map outages degrade exactly like sync mode (`pending` + `degraded`, fire-and-forget reconciliation — see `## Lerian Map Sync (optional)`) and NEVER block gates.

## Blocker Handling

| Blocker | Action |
|---------|--------|
| Gate failure (tests not passing, review failed) | STOP. Cannot proceed to next gate. |
| Missing PROJECT_RULES.md | STOP. Create using template. |
| Agent error | STOP. Diagnose and report. |
| Architectural decision needed | STOP. Present options to user. |

When `state.lerian_map_sync.enabled` and a gate hard-blocks (failure / external blocker), fire the async board push → absolute column `blocked` for the affected unit (non-blocking, fire-and-forget) before stopping. See `## Lerian Map Sync (optional)`.

## Gate Completion Rules

A gate is complete ONLY when ALL components succeed:
- Gate 0 (per task): TDD RED + GREEN + coverage ≥ 85% + all acceptance criteria tested + docker-compose/local runtime verified + delivery verification (all requirements delivered, 0 dead code)
- Gate 8 (per epic): all 9 default reviewers pass, and any triggered conditional specialist also passes.
- Gate 9 (per epic): every task's acceptance criteria aggregated and marked PASS + explicit "APPROVED" from user
- Phase boundary (Step 11.5): phase closed (Phase Overview → Complete, deviations recorded) + next phase elaborated and validated (or no next phase) + checkpoint honored per `phase_checkpoint`

## Severity of Issues

- CRITICAL/HIGH/MEDIUM found in review → Fix NOW, re-run the selected review pool
- LOW → Keep in the review report if actionable; do not add source comments during review
- Cosmetic → Add `FIXME(nitpick):` comment

## Error Recovery

| Scenario | Recovery |
|----------|----------|
| Agent returns error | Retry with clearer instructions (max 3 attempts) |
| State file corrupted | Rebuild from git log + last known state |
| Gate stuck in loop | After 3 iterations, escalate to user |
| Context limit reached | Use `/ring:creating-handoffs` → resume in new session |

## Input Sources

| Source | Path |
|--------|------|
| Plan (pre-dev flow) | `docs/pre-dev/{feature}/plan.md` |
| Plan (standalone ring:writing-plans) | `docs/plans/*.md` |
| Derived plan (Lerian Map as task source) | `docs/ring:running-dev-cycle/plan-from-map.md` — materialized at init when `task_source == "lerian_map"`; see `## Lerian Map as Task Source (optional)` |
| Legacy tasks (in-flight cycles ONLY) | `docs/pre-dev/{feature}/tasks.md` (old `## Summary` table + E-/T- ids) — accepted only when `current-cycle.json` already exists (init is not re-run); new cycles MUST start from the canonical plan format |
| Phase tasks | inside the plan, under each epic (`#### Task N.M.T:` blocks) |
| Refactor tasks | `docs/ring:planning-backend-refactor/*/tasks.md` |

## Frontend Handoff

If frontend tasks are detected in a backend cycle → create a handoff file listing frontend requirements, API contracts, and test expectations. Frontend uses `ring:running-dev-cycle-frontend` separately.
