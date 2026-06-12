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

**Vocabulary:** Phase = independently verifiable milestone. Epic (Epic N.M) = value-driven increment, the UNIT this cycle iterates. Task (Task N.M.T) = dispatch-ready unit, the Gate 0 execution unit.

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
| **Local plan + Map sync** | `"plan_file_synced"` | plan.md is the source; status is pushed to the board at the existing hooks (exactly the `## Lerian Map Sync (optional)` behavior). Set `state.lerian_map_sync.enabled = true`, then ask the Testing-gate question, and run the discovery handshake before the first Gate 0. |
| **Lerian Map (board is the source)** | `"lerian_map"` | The Lerian Map board IS the task source — see `## Lerian Map as Task Source (optional)`. Also set `state.lerian_map_sync.enabled = true` (source mode implies status sync) and ask the Testing-gate question. |

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

**Hard rule:** the synced status follows the **real board columns exactly** — no invented stand-in statuses. Column enum strings are **read from the board at runtime via Gandalf, never hardcoded**.

### Discovery handshake (run once, after the cycle-init questions, before the first Gate 0)

When `state.lerian_map_sync.enabled`, run a one-time handshake (each Gandalf ask is a fresh, self-contained session carrying the full discovery payload):

1. **Fetch board tasks via Gandalf** for this repo's product. Discovery is **repo-driven**: map the local git remote to a product via the Map's native **`repositoryUrl`** field on `GET /products` (no manual `productId`/`teamId`/`milestoneId`). Normalize the remote first (`git@github.com:org/repo.git` → `https://github.com/org/repo`).
2. **Match board cards ↔ local plan units.** Features are matched **by NAME** (e.g. `"E-1.1 …"` / the epic title) — Map features have **no `slug` field**, so name is the feature key (the `docs/pre-dev/{feature}/` path slug has no API equivalent and is only a weak hint). The deterministic per-task matching key is the **`[map:#<board_task_id>]` tag** embedded in the plan/task block; when a tag is present Gandalf skips fuzzy matching entirely. **Title-matching is the fallback** when no tag is present.
3. **Preview + confirm.** Show a preview table (local ↔ board, with each card's current column) and ask the user to confirm the match before any write.
4. **Auto-inject tags (with confirmation).** After the first successful discovery, offer to **auto-inject** the resolved `[map:#<board_task_id>]` tags into the plan so future runs are deterministic and rename-proof.
5. **Persist** the mapping + the board's real status enum into `state.lerian_map_sync` (see `gates/state-schema.md`). In the same ask, instruct Gandalf to set each matched feature's `repositoryPath` to the repo URL — set-if-empty, best-effort, once per cycle (see `### Evidence & enrichment (comments, feature status, repositoryPath)`).

**Discovery path that works (validated):** `repo → /products(repositoryUrl) → /features?productId(name) → /tasks?featureId`.

### Status mapping (dev-cycle stage → real board column)

| Dev-cycle event | Board column | Notes |
|-----------------|--------------|-------|
| Unit loaded, not started | `To do` | baseline; only set if currently in `Backlog` |
| Gate 0 begins (coding/TDD) — each task's Gate 0 begin (per-task cadence) | `In Progress` | unit is actively being built; the card moves only if currently `Backlog`/`To do`, evaluated per task card |
| All gates passed (incl. Gate 8 review + Gate 9), awaiting user manual test | `Testing` | the "Em Teste" the user actually tests; STAYS here through approval. Gate 8 is an INTERNAL dev-cycle review — it does NOT get its own board column. |
| User approved → PR opened, awaiting human merge-review | `To Review` | matches the board order `Testing → To Review → Done` |
| PR merged → committed AND pushed to repo (≥ `develop`) | `Done` | ⭐ the **ONLY** trigger for `Done` — the push-to-develop / PR-merge event, **NOT Gate 9** |
| A gate fails hard / external blocker | `Blocked` | off-path |
| Cycle parked for non-blocking reasons | `On Hold` | off-path / optional / manual |
| Unit dropped | `Canceled` | off-path / optional / manual |

**Lifecycle (monotonic, matches board column order):** `To do → In Progress → Testing → To Review → Done`, with `Blocked`/`On Hold`/`Canceled` off-path.

The `Testing → To Review` hop depends on the **Testing gate** (cycle-init question 4):
- **`gate` (wait):** card parks in `Testing`; the cycle waits for the user's OK, then opens the PR → `To Review`. (SLC rule — human tests the epic before the PR.)
- **`bypass`:** the card still passes *through* `Testing` (status is set) but the cycle does not block; it auto-opens the PR → `To Review`. **Gate 9 acceptance still applies** — bypass only relaxes the manual-test wait, never Gate 9.

### Gandalf integration mechanics

All Map I/O goes **through the Gandalf webhook** (`default/skills/gandalf-webhook`) — never a direct Map API call from dev-cycle. This keeps the dev-team plugin free of Map credentials / instance coupling and works for any Map instance. **No new agent and no new credential** are introduced; the existing webhook is reused.

- **Self-contained prompts:** every ask is a fresh Gandalf session — each message carries the discovery payload (repo, feature name, task ids/titles, board ids) and the **absolute target column**.
- **Fetch + enum read:** the first ask returns both the matched cards AND the list of valid status values for that board (so column strings are never hardcoded).
- **Status push — ASYNC FIRE-AND-FORGET (never blocks dev):** at each checkpoint the dev-cycle sends ONE webhook POST and immediately gets back a `task_id`; Gandalf's **background worker** performs the actual board update. The dev-cycle **does NOT poll or wait** — it records the dispatch and continues to the next gate/task. The slow work lives on Gandalf's side, off the critical path.
- **Visible dispatch log line:** when the hook fires, log a line so the user sees it working in the background, e.g.
  `🔄 Lerian Map Sync: dispatched Task 1.1.1 → In Progress (gandalf task a1b2c3, background)`
  and record `{task_id, dispatched_at, state: "dispatched"}` in `current-cycle.json`.

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
4. **Drain pending:** at the same triggers, retry `pending` transitions (oldest → newest). A Gandalf that comes back mid- or post-cycle gets the board caught up automatically; when nothing is `pending`, clear `degraded`. Rules 3–4's triggers cover `matches[].body_dispatch` records (task-body pushes, when present — see `gates/state-schema.md`) identically — outstanding body pushes are verified and drained in the same batched pass.
5. **Idempotent pushes:** each push sets an **absolute column** (status = X), never a relative move — safe to replay even if a partial update landed.
6. **End-of-cycle report:** print outstanding items at Step 12.1, e.g.
   `⚠️ Lerian Map Sync: 2 dispatched (awaiting confirmation), 1 pending (Gandalf was down)`.

### Checkpoint hooks (where the async push fires)

When `state.lerian_map_sync.enabled`, the orchestrator fires the async, fire-and-forget board push at these existing checkpoints (each is non-blocking and never gates execution):

| Cycle event | Hook location | Absolute column pushed |
|-------------|---------------|------------------------|
| Task start (each task's Gate 0 begin) | `gates/gate-0-implementation.md` Pre-Dispatch checkpoint (fires per task) | `in_progress` |
| Epic validated, awaiting user test (Gate 9 pass → Step 11.1) | `gates/gate-9-validation.md` Step 11.1 | `testing` (stays here through approval) |
| User approved → PR opened | Step 11.1 advance (and end-of-cycle / PR-open path) | `to_review` (gated by `testing_gate`) |
| Push to repo ≥ `develop` (PR merge) | `gates/cycle-completion.md` Step 12.1 (Final Commit / push) | `done` — ONLY trigger for `done`, NOT Gate 9 |
| Task commit moment (per `commit_timing`) | `gates/gate-0-implementation.md` Gate 0 completion (`per_task`) / `gates/gate-9-validation.md` Step 11.1 epic commit (`per_epic`) / `gates/cycle-completion.md` `done` push (`at_end`) | — none (comment-only ask: the task evidence comment POST — see `### Evidence & enrichment`) |
| Hard block at any gate | Blocker Handling | `blocked` |

The `in_progress` and `done` pushes also stamp start/end dates and carry the enrichment instructions — see `### Date stamping (start/end)` and `### Evidence & enrichment (comments, feature status, repositoryPath)` below.

### Date stamping (start/end)

The Map UI has INÍCIO (start) and FIM (end) date columns for features and tasks. When sync is enabled (BOTH `plan_file_synced` and `lerian_map` — the hooks are shared), the existing pushes also stamp these dates so the board reflects real execution timing. Dates ride INSIDE the existing pushes — same Gandalf ask, same fire-and-forget posture, same degradation/reconciliation rules: **no new push types, no new strict points, no impact on never-block**. A failed push retries dates together with the status via the existing reconciliation. The date value is captured when the transition is first queued/dispatched and carried in the push payload — a retried push stamps the original event date, never "today at retry time" (a payload field on the queued transition, not a new dispatch record). Task fields are `startDate` / `endDate` (date `YYYY-MM-DD`, nullable — validated via live Gandalf probe); for features, instruct Gandalf to "set the feature's start/end date" — the exact feature field names are resolved by Gandalf at push time, never guessed here.

| Date | Riding push | Rule |
|------|-------------|------|
| Task `startDate` | `in_progress` (each task's Gate 0 begin) | Set to the event date ONLY if currently null/empty. NEVER overwrite a manually set date. |
| Task `endDate` | `done` (push-to-develop) | Set if empty or future; keep existing past dates. |
| Feature start date | EVERY `in_progress` push (same Gandalf ask) carries the set-if-empty instruction — idempotent; "first" is an outcome, not a tracked condition | Set only if empty. `lerian_map` mode knows `feature.id` from the init fetch; `plan_file_synced` mode may not — then instruct Gandalf to resolve the card's parent feature and stamp it, best-effort. |
| Feature end date | `done` (push-to-develop / PR-merge — Step 12.1 or the later PR-merge event; NOT epic completion) | Set only if empty. Instruct Gandalf, in the same ask, to stamp the feature end date only if all of that feature's board tasks are terminal (`done`/`canceled`) — Gandalf evaluates against the live board at push time. Any open task (e.g. a `blocked`/skipped task from the Map Body Hard Gate) → not stamped — a later cycle or a human stamps it. |

**No new state:** date stamping is idempotent by construction (set-if-empty), so it does NOT need its own dispatch record — do NOT invent one. The status `dispatch` and `body_dispatch` records (`gates/state-schema.md`) remain the only sync-state tracked.

### Evidence & enrichment (comments, feature status, repositoryPath)

Beyond columns and dates, the pushes also fill everything else the Map API supports today. API facts (live Gandalf probe): task comments exist (`POST /tasks/{id}/comments`, markdown body ≤ 10,000 chars, CRUD); features carry a `status` enum (`backlog|planned|in_progress|completed|delayed`), a `description` (≤ 500 chars), and a `repositoryPath`; `iterationId` is REQUIRED when feature status is `in_progress`/`completed`/`delayed`. **Features do NOT have comments — only tasks do.** Everything below rides the existing pushes/asks (fire-and-forget, existing degradation; comments excepted from retry — see the rule below): **no new STATUS push types — the single addition is one comment-only ask at each task's commit moment — no new strict points, no new state records**.

**Evidence comments — max ONE comment per card per event (no spam):**

| Event | Card | Comment content |
|-------|------|-----------------|
| Task completed — POSTs ONCE, at the task's COMMIT moment per `commit_timing`: `per_task` → Gate 0 completion (after delivery verification + commit); `per_epic` → the Step 11.1 epic commit; `at_end` → the `done` push (full evidence posted then). Commit SHAs therefore always exist at POST time. | Task card | ONE consolidated comment: commit SHA(s), TDD evidence (tests added, coverage % vs threshold), verification command + outcome, PR link when available (in `lerian_map` mode tasks are the cards, so the PR ref lands here). A still-pending PR link is filled in at the `to_review` push (when the PR opens) via comment UPDATE; the `done` push re-asserts it idempotently — never a second comment. Template below. |
| Epic approved (Gate 9 pass → Step 11.1) | The epic's matched card — ONLY when it is a TASK-type card | ONE comment: review summary (reviewers passed, findings fixed), aggregated criteria PASS, PR link. If the epic matched a FEATURE (normal in `plan_file_synced` name-matching) → post NOTHING (features have no comments) — the per-task comments carry the evidence. In `lerian_map` mode this event posts NO extra comment either (cards are tasks; their per-task comments already carry it). |
| Task skipped by the Map Body Hard Gate (`gates/gate-0-implementation.md` Step 2.1.5 option b) | Task card | ONE comment alongside the existing `blocked` push: "skipped: no implementation contract (empty/insufficient body)". |

Task-completed comment template (compact markdown, ~10 lines max):

```text
**✅ Task completed by dev-cycle**
- Commits: <sha1>, <sha2>
- Tests: <N added>, coverage <X%> (threshold <Y%>)
- Verification: `<command>` → <outcome>
- PR: <link | pending>
```

**Idempotency/retry rule (comments only):** comments are best-effort fire-and-forget and are NOT retried by the reconciliation — a retried push MUST NOT double-post a comment. Dates and status retry as already documented; comments don't.

**UPDATE, never re-POST:** after the initial POST, every later touch is a comment UPDATE — instruct Gandalf to locate the existing comment via the card's comment list. The lifecycle: POST once at the task's commit moment (table above) → a Gate 0 re-entry (Gate 9 criterion FAIL → rebuild) UPDATEs the existing evidence comment with the new evidence → the `to_review` push fills the pending PR link (into the task evidence comments AND the epic-approved comment when one exists) → the `done` push re-asserts the link idempotently. Max ONE comment per card per event holds in every path.

**Feature status sync** (set in the SAME asks that stamp the feature dates — see `### Date stamping (start/end)`):

- With the feature start-date instruction: also move feature `status` → `in_progress` ONLY if currently `backlog`/`planned`.
- With the feature end-date instruction: also move feature `status` → `completed` — same guard as the end date (Gandalf evaluates all-tasks-terminal against the live board at push time).
- `iterationId` caveat: REQUIRED for `in_progress`/`completed`/`delayed` — instruct Gandalf to resolve/keep the feature's current iteration best-effort; if it cannot, skip the status change, log a warning, NEVER block.

**`repositoryPath`:** during the discovery handshake persist step (step 5), instruct Gandalf to set the feature's `repositoryPath` to the repo URL — set-if-empty, best-effort, once per cycle (in `lerian_map` mode this rides the first ask after the init step 2 fetch).

### Validated facts (live Gandalf test, 2026-06-11, `br-slc`)

- **Product discovery:** `GET /products` exposes a native **`repositoryUrl`** field. `https://github.com/LerianStudio/br-slc` → `productId=13` (SLC), `teamId=5`. Exact match, no ambiguity.
- **Feature discovery:** `GET /features?productId=13` → matched **by name** `"E-1.1 …"` → `featureId=245` (status `backlog`, `iterationId: null`). **No `slug` field exists.**
- **Tasks:** `GET /tasks?featureId=245` → 4 cards, matched 4/4 to local T-1.1.1–T-1.1.4 → board ids **1222, 1223, 1224, 1225**, all `todo`, milestone `Desenvolvimento` (id=433).
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

- **Known frictions:** no feature slug (match by name — fragile → use `[map:#id]` tags); `iterationId` can be `null`; `GET /teams` currently returns 500 (use `teamId` from the tasks payload instead).
- **Discovery path:** `repo → /products(repositoryUrl) → /features?productId(name) → /tasks?featureId`.

## Lerian Map as Task Source (optional)

**OPTIONAL.** Active only when `state.task_source == "lerian_map"` (cycle-init question 3 = `Lerian Map (board is the source)`). In this mode the Lerian Map board — not a local plan.md — is the source of truth for WHAT to build and for STATUS. The cycle materializes a derived plan from the board at init, then runs every existing gate unchanged against it. Reuses the discovery handshake, Gandalf transport, status mapping, checkpoint hooks, and degradation rules from `## Lerian Map Sync (optional)` — none of that is duplicated here.

⛔ **Invariant: a Map task with only a title is NOT executable. The `body` is the implementation contract — no body, no Gate 0.** Enforced at init (step 3 below) and again as a ⛔ HARD BLOCK at every Gate 0 dispatch (`gates/gate-0-implementation.md` Step 2.1.5 — Map Body Hard Gate).

**Hierarchy mapping (Map → plan):**

| Lerian Map | Plan (canonical ring:writing-plans format) |
|------------|--------------------------------------------|
| `milestone` | Phase (`## Phase N:` section + Phase Overview row) |
| `feature` | Epic (`### Epic N.M:`) |
| `task` | Task (`#### Task N.M.T:`) |
| `task.body` (markdown, ≤ 20,000 chars) | The dispatch-ready task block: Context (with file:line refs), Implementation vision, Files, Verification, Done when |

### Init flow (source = lerian_map; runs once, instead of loading a local plan)

1. **Discover the board** — run the discovery handshake from `## Lerian Map Sync (optional)` SCOPED for source mode: execute handshake step 1 (repo-driven product discovery) and step 5 (persist into state); SKIP handshake steps 2–4 (card ↔ plan matching, preview, tag auto-injection — there is no local plan to match). Additionally resolve the **milestone** to execute: candidates are milestones that are not fully `done`/`canceled`, lowest `order` first; if more than one candidate exists, AskUserQuestion to pick one. Persist the milestone identity into `state.lerian_map_source` (canonical — see `gates/state-schema.md`).
2. **Fetch the source data via Gandalf** (`action: ask`, self-contained prompt): milestone → features → tasks, requesting for each task: `id`, `title`, `body`, `status`, `priority`, `feature.{id,name}`, `milestone.{id,name,order}`. After the fetch, populate `state.lerian_map_sync.matches[]` from the resolved milestone's tasks: every unit is board-born, so it is matched by construction.
3. **⛔ Body hygiene validation (current milestone ONLY — MANDATORY):** a current-milestone task without a sufficient `body` CANNOT enter the cycle — no exceptions; the context MUST be given. Sufficiency = the Step 11.5.5 validation bar (`gates/phase-boundary.md`): no "TBD"/vague deferrals; Context with file:line refs; Implementation vision; Files; Verification; Done when. For any current-milestone task with an empty/insufficient body → AskUserQuestion:
   - **(a) Elaborate now** — dispatch ONE planning agent in ANALYSIS mode (same mechanism as Step 11.5.4 in `gates/phase-boundary.md`) to produce the dispatch-ready block, then push it to the Map task `body` via Gandalf. The push is SYNCHRONOUS — init is the strict point and the body must land before the source is trusted; mid-cycle body pushes stay fire-and-forget — EXCEPT the Step 2.1.5 hard-gate remediation (`gates/gate-0-implementation.md`), which is synchronous when the Map is reachable (degraded fallback: queue + proceed).
   - **(b) Abort init** — stop so the user fills the board first.

   Future-milestone tasks are EXPECTED to have empty bodies — that is the rolling wave; they get elaborated at phase boundaries (Step 11.5). The body-sufficiency rule is enforced AGAIN as a ⛔ HARD BLOCK at every Gate 0 dispatch (`gates/gate-0-implementation.md` Step 2.1.5 — Map Body Hard Gate), catching drift after init.
4. **Materialize the derived plan** — write `docs/ring:running-dev-cycle/plan-from-map.md` in the canonical ring:writing-plans format, generated from the fetched board data: `## Phase Overview` table from milestones, `### Epic N.M:` sections from features, `#### Task N.M.T:` blocks from task bodies. Phases are renumbered 1..N from the milestones sorted by `milestone.order` (orders need not be contiguous). Phase Overview Status cells: milestones earlier than the resolved one → `Complete`; the resolved milestone → `Detailed`; later ones → `Epic-level`. Tag EVERY epic and task heading with the `[map:#<id>]` convention (the deterministic matching key — see `## Lerian Map Sync (optional)`). Future-milestone tasks ARE materialized as tagged `#### Task N.M.T: … [map:#<id>]` headings with EMPTY bodies — they already exist on the board and carry ids; the init parser ignores them (`gates/state-schema.md`: their epics load with `tasks: []`) until their phase is elaborated at its boundary. Map each fetched board status into the plan `**Status:**` word:

   | Fetched board status | Plan `**Status:**` word |
   |----------------------|-------------------------|
   | `done` | `Done` |
   | `in_progress` / `testing` / `to_review` | `Doing` |
   | anything else (`backlog`, `todo`, `on_hold`, `blocked`, `canceled`) | `Pending` |

   The table maps per-TASK board statuses, but in the canonical plan format the `**Status:**` line exists per-EPIC (task blocks carry `- [ ] Done` checkboxes, not Status lines). Apply it as follows:
   - **Epic aggregation:** derive each epic's `**Status:**` word by aggregating its tasks' mapped words: all `Done` → `Done`; any `Doing` → `Doing`; otherwise `Pending`.
   - **Checkbox materialization:** each `done` board task is materialized with its checkbox checked (`- [x] Done`) so completion is visible in the derived plan.
   - **Gate 0 implication:** tasks materialized as `- [x] Done` are already complete and are NOT re-executed at Gate 0 — skip them; a mid-flight milestone resumes from the first unchecked task.

   Set `state.source_file` to this derived plan. From here on, ALL existing gates (0 / 8 / 9 / 11.5 / 12.x) run unchanged against it.
5. **Source-of-truth rule:** the derived plan is an internal, regenerable execution artifact; the board remains the source of truth for WHAT and STATUS. Manual edits to the derived plan that change task content MUST be pushed back to the corresponding Map task `body` (matched via the `[map:#<id>]` tag — see write-back rules below).

**Resume rule:** on `--resume` with `task_source == "lerian_map"` and the derived plan missing from disk, re-run init steps 2 + 4 (fetch + materialize) before resuming the gates — state indices stay authoritative. If the Map is unreachable during this regeneration → treat it as the INIT degradation case below (Retry / fall back / Abort).

### During the cycle

- **Status:** flows to the board via the existing checkpoint hooks (`## Lerian Map Sync (optional)` → Checkpoint hooks). No changes — source mode implies status sync.
- **Body write-back:** when Gate 8/9 outcomes cause a documented deviation from a task's plan block (the block's content changes), push the updated block to that task's Map `body` — async fire-and-forget, same `pending → dispatched → synced` degradation rules as status pushes. NEVER blocks a gate.

### Phase boundary (Step 11.5)

After the planning agent elaborates the next phase's tasks into the derived plan, push each elaborated task block to the matching Map task `body` (match by `[map:#<id>]`). **Reconciliation:** board/local mismatches are surfaced to the user — never silently created or deleted; the full rule (and its best-effort board fetch) lives in `gates/phase-boundary.md` Step 11.5.5b. This is the rolling-wave behavior: future milestones start with empty bodies and get filled as development reaches them.

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
