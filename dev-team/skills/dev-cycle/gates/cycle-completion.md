## Step 12: Cycle Completion

### Step 12.0: Final Test Confirmation

```text
1. Confirm every Gate 0 handoff includes passing tests, coverage >= threshold,
   and docker-compose/local runtime verification when required.

2. if any required Gate 0 quality check is missing or failed:
   → HARD BLOCK. Cannot complete cycle.
   → Return to Gate 0 for the affected unit.

3. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 12.0 Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Gate 0 said PASS but coverage is missing" | Gate 0 is incomplete without coverage evidence. | **Return to Gate 0** |
| "docker-compose can wait" | Backend owns local runtime in this flow. | **Return to Gate 0 if local dependencies exist** |
| "CI will catch it" | CI is backup, not replacement. Verify locally first. | **Return to Gate 0** |

### Step 12.0.5: Multi-Tenant Verification (Post-Cycle — Verification Only)

**Multi-tenant dual-mode is now implemented during Gate 0 and verified at Gate 0.5G.** This post-cycle step is a final sanity check only — it does NOT implement or adapt any code.

```text
1. Verify Gate 0.5G passed for ALL units:
   for each task in state.tasks:
     for each unit in task.units:
       if unit.gate_progress.delivery_verification.mt_dualmode != "PASS":
         → HARD BLOCK: "Unit [unit_id] failed MT dual-mode verification at Gate 0.5G"
         → This should never happen (Gate 0.5G blocks progression)

2. Display to user:
   ┌─────────────────────────────────────────────────┐
   │ ✓ MULTI-TENANT DUAL-MODE VERIFIED              │
   ├─────────────────────────────────────────────────┤
   │ Mode: Dual-mode (implemented at Gate 0)         │
   │ Verification: Gate 0.5G PASS for all units      │
   │ Resources Covered: [PG/Mongo/Redis/RMQ/S3]      │
   │ Backward Compat: Resolvers handle single-tenant │
   └─────────────────────────────────────────────────┘

3. MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]
```

**Note:** The full ring:dev-multi-tenant skill (12 gates) targets legacy single-tenant codebases being migrated to dual-mode. For new development via dev-cycle, multi-tenant compliance is handled inline by Gate 0 (implementation) + Gate 0.5G (verification).

---

### Step 12.0.5b: Gate 0.5D — Migration Safety Verification (Conditional, Post-Cycle)

**CADENCE:** Post-cycle, conditional. Runs ONCE per cycle if SQL migration files are detected in the cycle diff. Parallel to Gate 0.5G.

**Purpose:** Static analysis on SQL migration files introduced by the cycle, per [migration-safety.md](../../docs/standards/golang/migration-safety.md) and [shared-patterns/migration-safety-checks.md](../shared-patterns/migration-safety-checks.md). Gate 0.5D is orthogonal to Gate 0.5G — 0.5G checks multi-tenant Go code safety; 0.5D checks SQL schema evolution safety.

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

**Check categories (from [migration-safety.md § Dangerous Operations](../../docs/standards/golang/migration-safety.md#dangerous-operations-detection) + [shared-patterns/migration-safety-checks.md](../shared-patterns/migration-safety-checks.md)):**

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

**Execution (inline, mirrors verification commands in [migration-safety.md § Verification Commands](../../docs/standards/golang/migration-safety.md#verification-commands)):**

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
| "Gate 0.5D and Gate 0.5G are redundant" | Different domains: 0.5G = multi-tenant Go code safety; 0.5D = SQL schema evolution safety. Orthogonal. | **MUST run both gates; they check different properties.** |
| "Delivery-verification already covers migrations at Gate 0" | Gate 0's delivery verification is per-subtask on application code, not cycle-wide SQL. Cycle-level diff can only be assessed post-cycle. | **MUST run 0.5D post-cycle on the full cycle diff.** |
| "Migration was in an early task, already committed per-task" | 0.5D inspects cumulative cycle diff vs origin/main. Per-task commits don't exempt cycle-level safety. | **MUST check against origin/main, not per-task boundary.** |
| "BLOCKING will cause rework, let's downgrade to WARN" | Severity is set by migration-safety.md. Downgrading violates the standard. | **MUST HARD BLOCK on BLOCKING; use ACKNOWLEDGE only for documented expand-contract.** |

---

### Step 12.1: Final Commit

0. **FINAL COMMIT CHECK (before completion):**
   - if `commit_timing == "at_end"`:
     - Execute `/ring:commit` command with message: `feat({cycle_id}): complete dev cycle for {feature_name}`
     - Include all changed files from the entire cycle
   - else: Already committed per subtask or per task

1. **Calculate metrics:** total_duration_ms, average gate durations, review iterations, pass/fail ratio
2. **Update state:** `status = "completed"`, `completed_at = timestamp`
3. **Generate report:** Task | Subtasks | Duration | Review Iterations | Status | Commit Status

4. **⛔ MANDATORY: Run ring:dev-report skill for cycle metrics**

   **IMPORTANT:** This is the ONE AND ONLY ring:dev-report dispatch in the cycle. ring:dev-report reads `accumulated_metrics` from ALL tasks in state and generates aggregate analysis.

   ```yaml
   Skill tool:
     skill: "ring:dev-report"
   ```

   **Note:** ring:dev-report manages its own TodoWrite tracking internally.

   **After feedback-loop completes, update state:**
   - Set `feedback_loop_completed = true` at cycle level in state file

   **⛔ HARD GATE: Cycle incomplete until feedback-loop executes.**

   | Rationalization | Why It's WRONG | Required Action |
   |-----------------|----------------|-----------------|
   | "Cycle done, feedback is extra" | Feedback IS part of cycle completion | **Execute Skill tool** |
   | "Will run feedback next session" | Next session = never. Run NOW. | **Execute Skill tool** |
   | "All tasks passed, no insights" | Pass patterns need documentation too | **Execute Skill tool** |

5. **Report:** "Cycle completed. Tasks X/X, Subtasks Y, Time Xh Xm, Review iterations X"
