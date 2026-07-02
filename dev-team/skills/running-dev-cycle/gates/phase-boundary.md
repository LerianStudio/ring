## Step 11.5: Phase Boundary (Phase Cadence)

⛔ **CADENCE:** Phase-level. Runs ONCE per phase, AFTER Step 11.1 approves the LAST epic of `state.current_phase`. "Last epic of the phase" = the next epic in plan order belongs to a different phase, or there is no next epic. This gate closes the finished phase, runs the phase checkpoint, and rolling-wave elaborates the next phase's epics into dispatch-ready tasks against the codebase **as it now exists**.

This is the rolling-wave hinge: detail is produced one phase ahead of nothing — the next phase is elaborated only when its predecessor has actually landed. Pre-written detail for a not-yet-built phase is stale by construction.

### Step 11.5.1: Close the Finished Phase

1. **Plan Phase Overview sync:** Set the finished phase's Status cell → `Complete` (Edit on `state.source_file`; if no `## Phase Overview` table — FALLBACK single-phase plan — skip silently).
2. **State:** `state.phases[]` entry for `current_phase` → status `complete`.
3. **Record deviations** — write a `## Deviations` section in the plan (create if absent; append under it otherwise) capturing every place where an epic's implementation diverged from its plan in a way that affects later phases. Source: the just-completed phase's epics' `agent_outputs` (implementation/review notes where the delivered contract, file layout, or approach changed). One bullet per deviation: `- Epic N.M: <what changed> → affects <later epic(s) / contract>`. If no material deviations → write `- None.` These deviations are MANDATORY input to elaboration (step 11.5.4).
4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**

### Step 11.5.2: Phase Checkpoint

Depends on `state.phase_checkpoint`:

- **`manual` (default):**
  1. Set cycle `status = "paused_for_phase_review"`, save state.
  2. Present: phase number + phase name (from the plan's Phase heading — Phases are internal rolling-wave structure only), epics completed (ids + titles), key metrics (total duration, review iterations, issues by severity aggregated across the phase's epics), and the recorded deviations.
  3. **AskUserQuestion:** "Phase [N] ([phase name]) complete. How to proceed?"
     - (a) **Continue** — elaborate the next phase and resume the epic loop
     - (b) **Pause** — stop here; resume later with `/ring:running-dev-cycle --resume` (re-enters this checkpoint)
     - (c) **Adjust plan first** — stop here so the user can edit the plan (reorder/add/drop later-phase epics or rename phases) before elaboration; resume re-enters this checkpoint and re-reads the (now edited) plan
  4. Handle: **Continue** → proceed to step 11.5.3. **Pause** → leave `status = "paused_for_phase_review"`, STOP, output resume command. **Adjust plan first** → leave `status = "paused_for_phase_review"`, STOP, output: `Cycle paused at phase boundary for plan adjustment. Edit the plan file, then resume with /ring:running-dev-cycle --resume`.

- **`auto`:** Log the same summary (phase, epics completed, metrics, deviations) to the cycle output, set `status = "in_progress"`, and continue directly to step 11.5.3. No pause.

### Step 11.5.3: No Next Phase → Cycle Completion

Determine the next phase: the lowest `phases[]` entry with status `epic-level` (or `detailed`, if init left more than one detailed). If **none** remains:

→ The cycle's work is done. Do NOT elaborate. Leave `current_phase` as-is, set `status = "in_progress"`, and fall through to **Step 12 (Cycle Completion)** — read `gates/cycle-completion.md`. (This is the ONLY path into Step 12.)

If a next phase exists → proceed to step 11.5.4.

### Step 11.5.4: Elaborate the Next Phase (Rolling Wave)

Dispatch **ONE** planning agent in **ANALYSIS / PLANNING mode — NO code changes, NO commits.** The agent writes tasks into the plan and returns a summary; it does not implement.

**Agent selection** — per the next phase's epics:
- If the epics carry an optional `**Target:**` line (multi-module topologies): `backend` → `ring:backend-go` or `ring:backend-ts` by the repo's language; `frontend` → `ring:frontend`.
- If absent (plain ring:writing-plans format): infer from the epics' `**Scope:**` paths and repo manifests (go.mod → `ring:backend-go`; package.json backend → `ring:backend-ts`; frontend app → `ring:frontend`).
- Mixed or ambiguous → `ring:codebase-explorer`.

**Dispatch prompt MUST include:**

```text
MODE: ANALYSIS / PLANNING ONLY. Do NOT write, edit, or run application code.
Do NOT commit. Your deliverable is dispatch-ready tasks written into the plan.

Plan path: {state.source_file}
Phase to elaborate: Phase {next_phase} — {phase name}
Epic blocks to break down (the next phase's `### Epic N.M:` sections, verbatim):
  {the next phase's epic blocks verbatim}
Recorded deviations from completed phases (these changed the codebase vs the original plan):
  {the ## Deviations section content}

TASK-AUTHORING BAR (from the ring:writing-plans Task Format — non-negotiable):
- Break each epic into dispatch-ready `#### Task N.M.T:` blocks (N = phase, M = epic
  sequence, T = task sequence), each opening with its `- [ ] Done` checkbox immediately
  under the heading.
- Each task carries: **Context** (with `file.go:42`-style refs into the codebase AS IT
  NOW EXISTS — read the real code, not the original plan's assumptions),
  **Implementation vision** (the approach + decisions already made + named edge cases),
  **Files** (exact Create/Modify/Test paths), **Verification** (command + expected outcome),
  **Done when** (acceptance criteria).
- An implementer with zero context could start each task within a minute of reading it.
- NO code snippets unless a public contract other epics depend on demands it
  (API signature, event schema, migration DDL) — prose decisions, not code.
- NO "TBD" / "TODO" / "figure out during implementation" — the detailed wave admits no deferrals.
- Touch ONLY Phase {next_phase}'s epic blocks. Do NOT detail any later phase.

RETURN: a summary of tasks written per epic, AND flag any epic whose scope no longer
matches the codebase reality (deviations made it redundant, larger, smaller, or wrong).
```

### Step 11.5.5: Validate Elaboration (Orchestrator)

After the agent returns, the orchestrator verifies (this is the elaboration's quality gate — the orchestrator does NOT read/write code, it inspects the plan's structure and the agent's report):

1. **Coverage** — every next-phase epic is fully broken into tasks (no epic left task-less).
2. **Scope mapping** — every Scope item of each epic maps to at least one task.
3. **No vague tasks** — no "TBD"/"handle edge cases"/vision-restates-the-name; each task has Context with file:line refs, Implementation vision, Files, Verification, Done when.
4. **Wave discipline** — later phases (> next_phase) remain untouched / epic-level.
5. **Scope divergence** — if the agent flagged any epic whose scope no longer matches reality → surface it to the user BEFORE continuing (even when `phase_checkpoint == "auto"` — a scope mismatch is a plan-correctness signal, not a routine pause). Let the user accept the agent's adjusted scope, edit the plan, or drop the epic.

If any check fails → re-dispatch the planning agent with the specific gap, or (for scope divergence) resolve with the user. Do NOT enter Gate 0 on an incompletely elaborated phase.

### Step 11.5.6: Update State and Resume the Epic Loop

1. **Plan Phase Overview sync:** next phase's Status cell → `Detailed`.
2. **State:**
   - `state.phases[]` entry for the next phase → status `detailed`.
   - Load the newly-written tasks into the corresponding `state.epics[].tasks[]` (parse the `#### Task N.M.T:` blocks under each elaborated epic; build the implementation gate_progress skeleton per task).
   - `state.current_phase += 1`.
   - `state.current_epic_index` = index of the first epic of the new phase (plan order); `state.current_task_index = 0`; `state.current_gate = 0`.
   - `state.status = "in_progress"`.
3. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
4. Resume the epic loop at **Gate 0** for the first epic of the new phase (read `gates/gate-0-implementation.md`).

### Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Let me elaborate Phase N+1 and N+2 while I'm here" | Two phases ahead = rolling-wave defeated; N+2's detail is stale before N+1 lands. | **Elaborate ONLY the immediate next phase.** |
| "phase_checkpoint is manual but the user clearly wants to continue" | Manual means ASK. The orchestrator never advances a phase on the user's behalf. | **AskUserQuestion at the boundary; do not self-approve.** |
| "I'll elaborate against the original plan, it's faster" | The plan's codebase assumptions are stale after earlier phases landed. Tasks must reference the code as it NOW exists. | **Elaborate against the real codebase + recorded deviations.** |
| "No deviations worth recording, skip the Deviations section" | Absence is itself signal; the elaboration agent needs to know nothing changed. | **Write `- None.` explicitly.** |
| "Agent flagged a scope mismatch but auto mode means continue" | Scope divergence is plan correctness, not a routine pause — it can invalidate the next phase. | **Surface scope divergence to the user even in auto mode.** |
| "The phase had one epic, skip the boundary" | The boundary is per-phase, not per-epic-count. Closing + elaboration still apply. | **Run Step 11.5 at every phase boundary.** |
| "Let the implementation agent write the tasks while it codes" | Elaboration is ANALYSIS-only and precedes Gate 0. Mixing planning into implementation skips the quality bar. | **Dispatch a planning agent in ANALYSIS mode; no code.** |

---
