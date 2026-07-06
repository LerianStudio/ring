## Step 12: Cycle Completion

⛔ **Entry condition:** Step 12 runs ONCE, only after the LAST phase has completed its phase boundary (Step 11.5) — i.e. every phase in `state.phases[]` has status `complete` and there is no further phase to elaborate. Reaching the approval of the last epic alone does NOT enter Step 12; the phase boundary for the final phase runs first (it has no "next phase" to elaborate, so it falls straight through to here per gates/phase-boundary.md step 3).

### Step 12.0: Cycle Exit Verification

Iterate `state.epics` once and assert both cycle-exit invariants. Both are HARD GATES; neither implements or adapts code.

```text
1. Final test confirmation — for every Gate 0 handoff: passing tests, coverage ≥ threshold,
   and docker-compose/local runtime verification when required.
   → Any missing/failed quality check: HARD BLOCK, return to Gate 0 for the affected unit.

2. Multi-tenant dual-mode — verified at Gate 0 as delivery-verification check (G); confirm it held:
   for each unit: if epics[i].tasks[j].gate_progress.implementation.delivery_verified != true
   → HARD BLOCK: "Unit [unit_id] failed Gate 0 delivery verification (includes multi-tenant dual-mode, check G)"

3. Display to user:
   ┌─────────────────────────────────────────────────┐
   │ ✓ CYCLE EXIT VERIFIED                          │
   ├─────────────────────────────────────────────────┤
   │ Gate 0 quality:        PASS for all units       │
   │ Multi-tenant dual-mode: PASS for all units      │
   │ Resources Covered: [PG/Mongo/Redis/RMQ/S3]      │
   └─────────────────────────────────────────────────┘

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

**Note:** The standalone `ring:adding-multi-tenancy` skill converts whole single-tenant codebases to dual-mode. dev-cycle handles multi-tenant compliance inline at Gate 0 (implementation plus delivery-verification check G).

### Step 12.0 Anti-Rationalization

See [shared-patterns/shared-anti-rationalization.md](../../shared-patterns/shared-anti-rationalization.md) for universal rationalizations. These are specific to cycle completion:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Gate 0 said PASS but coverage is missing" | Gate 0 is incomplete without coverage evidence. | **Return to Gate 0** |
| "docker-compose can wait" | Backend owns local runtime in this flow. | **Return to Gate 0 if local dependencies exist** |
| "CI will catch it" | CI is backup, not replacement. Verify locally first. | **Return to Gate 0** |

---

### Step 12.0.5b: Gate 0.5D — Migration Safety Verification (Conditional, Post-Cycle)

**CADENCE:** Post-cycle, conditional. Runs ONCE per cycle if SQL migration files are detected in the cycle diff.

**Purpose:** Static analysis on SQL migration files introduced by the cycle, per [migration-safety.md](../../../docs/standards/golang/migration-safety.md) and [shared-patterns/migration-safety-checks.md](../../shared-patterns/migration-safety-checks.md). SQL schema evolution safety is orthogonal to the multi-tenant dual-mode check (Step 12.0): different domains, both required.

**Trigger detection:**

```bash
MIGRATION_FILES=$(git diff --name-only origin/main...HEAD -- '**/migrations/*.sql' '**/*.sql' 2>/dev/null | grep -v "_test")
if [ -z "$MIGRATION_FILES" ]:
  → Log: "No SQL migration files detected in cycle diff — Gate 0.5D skipped"
  → Write state.gate_progress.migration_safety_verification = {status: "skipped", reason: "no_migration_files"}
  → Proceed to Step 12.1 Final Commit
else:
  → Proceed to Gate 0.5D checks below
```

**Check categories (from [migration-safety.md § Dangerous Operations](../../../docs/standards/golang/migration-safety.md#dangerous-operations-detection) + [shared-patterns/migration-safety-checks.md](../../shared-patterns/migration-safety-checks.md)):**

1. **BLOCKING** — `ADD COLUMN ... NOT NULL` without `DEFAULT` (ACCESS EXCLUSIVE lock, table rewrite)
2. **BLOCKING** — `DROP COLUMN` (breaks services still reading; requires expand-contract)
3. **BLOCKING** — `DROP TABLE` / `TRUNCATE TABLE` (data loss)
4. **BLOCKING** — `CREATE INDEX` without `CONCURRENTLY` (SHARE lock blocks writes)
5. **BLOCKING** — `ALTER COLUMN TYPE` (table rewrite)
6. **BLOCKING** — Missing or empty `.down.sql` rollback migration
7. **WARN** — DDL without `IF NOT EXISTS` / `IF EXISTS` (not idempotent for multi-tenant re-runs)
8. **WARN** — Large `UPDATE` without batching (extended row locks)
9. **ACKNOWLEDGE** — Intentional `DROP COLUMN` that is the contract phase of a prior expand-contract sequence (author must confirm expand phase was already deployed)
10. **ACKNOWLEDGE** — `ALTER TYPE` on tables documented as > 100k rows (author must confirm maintenance plan)

**Execution (inline, mirrors verification commands in [migration-safety.md § Verification Commands](../../../docs/standards/golang/migration-safety.md#verification-commands)):**

```text
1. Record gate start timestamp.

2. For each file in MIGRATION_FILES:
   a. Run BLOCKING checks (steps 1–6 above). Collect findings with {file, line, pattern, severity: "BLOCKING"}.
   b. Run WARN checks (steps 7–8 above). Collect findings with severity: "WARN".
   c. Scan file for magic markers ("-- EXPAND-CONTRACT: contract phase" or "-- ACKNOWLEDGE: <rationale>") indicating an intentional breaking change. Reclassify matching BLOCKING findings → "ACKNOWLEDGE".

3. Verify paired DOWN migration:
   For each *.up.sql in MIGRATION_FILES:
     → Expect *.down.sql in same directory, non-empty.
     → Missing/empty → BLOCKING finding.

4. Aggregate counts: {BLOCKING: N, WARN: N, ACKNOWLEDGE: N}.
```

**Decision logic:**

- **ANY BLOCKING finding** → HARD BLOCK: "Gate 0.5D failed: BLOCKING migration safety violation(s) in [files]. Cycle CANNOT proceed to Final Commit. Fix violation and re-run dev-cycle from the affected task, or mark as intentional via '-- ACKNOWLEDGE: <rationale>' inline comment if the operation is truly required (e.g., contract phase of a deployed expand-contract)."
- **ANY ACKNOWLEDGE finding** → Pause cycle at checkpoint. Display each finding with its `-- ACKNOWLEDGE:` rationale. Require user to respond with the exact phrase: "I acknowledge this breaking change and have verified the expand phase deployment." Any other response → HARD BLOCK.
- **Only WARN findings** → Log warnings in cycle summary, proceed to Final Commit.
- **Zero findings** → Log "Gate 0.5D PASSED — all migration files safe" and proceed.

**Report to user:**

```text
┌─────────────────────────────────────────────────┐
│ ✓ MIGRATION SAFETY VERIFIED (Gate 0.5D)        │
├─────────────────────────────────────────────────┤
│ Files Checked: [count]                          │
│ BLOCKING: 0    WARN: N    ACKNOWLEDGE: N        │
│ Standard: docs/standards/golang/migration-safety│
└─────────────────────────────────────────────────┘
```

**State persistence:**

```json
state.gate_progress.migration_safety_verification = {
  "status": "completed" | "skipped" | "blocked" | "acknowledged",
  "files_checked": ["path/to/migration.up.sql", ...],
  "findings": {
    "BLOCKING": [{"file": "...", "line": N, "pattern": "DROP COLUMN"}, ...],
    "WARN":     [{"file": "...", "line": N, "pattern": "..."}, ...],
    "ACKNOWLEDGE": [{"file": "...", "line": N, "pattern": "...", "rationale": "..."}, ...]
  },
  "user_acknowledgment": "string | null",
  "started_at": "ISO-8601",
  "completed_at": "ISO-8601"
}
```

**MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**

### Step 12.0.5b Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This migration looks simple, skip the check" | Simple migrations cause incidents too. Gate 0.5D only fires on BLOCKING patterns — if it fires, it's not simple. | **MUST run whenever migration files present in cycle diff.** |
| "ACKNOWLEDGE findings are informational, just log them" | ACKNOWLEDGE means the author MUST confirm intent. Silent acknowledgment is not acknowledgment. | **MUST pause cycle and require explicit user phrase.** |
| "Migration safety duplicates the multi-tenant check" | Different domains: multi-tenant dual-mode = Go code safety (Gate 0 check G); migration safety = SQL schema evolution. Orthogonal. | **Both run; they check different properties.** |
| "Delivery-verification already covers migrations at Gate 0" | Gate 0's delivery verification is per-task on application code, not cycle-wide SQL. Cycle-level diff can only be assessed post-cycle. | **MUST run 0.5D post-cycle on the full cycle diff.** |
| "Migration was in an early task, already committed per-task" | 0.5D inspects cumulative cycle diff vs origin/main. Per-task commits don't exempt cycle-level safety. | **MUST check against origin/main, not per-task boundary.** |
| "BLOCKING will cause rework, let's downgrade to WARN" | Severity is set by migration-safety.md. Downgrading violates the standard. | **MUST HARD BLOCK on BLOCKING; use ACKNOWLEDGE only for documented expand-contract.** |

---

### Step 12.1: Cycle Report + Final Commit

1. **Calculate metrics:** total_duration_ms, average gate durations, review iterations, pass/fail ratio.

2. **⛔ MANDATORY: Run ring:writing-dev-reports skill (the ONE AND ONLY dispatch).**

   ring:writing-dev-reports reads `accumulated_metrics` from ALL epics in state and writes aggregate feedback to `docs/feedbacks/cycle-YYYY-MM-DD/`. It manages its own TodoWrite tracking.

   ```yaml
   Skill tool:
     skill: "ring:writing-dev-reports"
   ```

   After it completes, set `feedback_loop_completed = true` at cycle level.

   **⛔ HARD GATE: cycle incomplete until the feedback-loop executes.**

   | Rationalization | Why It's WRONG | Required Action |
   |-----------------|----------------|-----------------|
   | "Cycle done, feedback is extra" | Feedback IS part of cycle completion | **Execute Skill tool** |
   | "Will run feedback next session" | Next session = never. Run NOW. | **Execute Skill tool** |
   | "All tasks passed, no insights" | Pass patterns need documentation too | **Execute Skill tool** |

3. **Finalize state:** `status = "completed"`, `completed_at = timestamp`. Save state.

4. **FINAL COMMIT** (runs regardless of `commit_timing` — the cycle-metadata commit captures the dev-report feedback and finalized state, so nothing is left dangling):
   - `commit_timing == "at_end"`: include all changed files from the entire cycle (feature code + dev-report feedback + final state).
   - `commit_timing == "per_epic"` / `"per_task"`: feature code already committed; this commit captures the cycle-end artifacts (dev-report feedback, finalized state).
   - Execute `/ring:committing-changes` with message: `feat({cycle_id}): complete dev cycle for {feature_name}`.

5. **Report:** "Cycle completed. Phases X/X, Epics X/X, Tasks Y, Time Xh Xm, Review iterations X."

### Step 12.2: Operational Risk Review (optional, opt-in)

**OPTIONAL and opt-in — never automatic, never blocking.** After the cycle report is printed, offer a review of the flows just built for operational recovery gaps:

```text
Offer once, after Step 12.1:
  "This cycle built <N> flow(s). Run ring:reviewing-operational-risk (Mode B) to
   map stuck-state failure modes and produce runbooks / gap specs? (y/n)"

- y → Skill("ring:reviewing-operational-risk") in plan-context mode (reads this cycle's
      plan.md + epic artifacts; no full-repo exploration needed).
- n → done. The cycle is already complete; this offer adds nothing to gate state.
```

Declining has zero effect on cycle completion — Step 12.1 already finished the cycle. Do NOT gate, block, or re-prompt.
