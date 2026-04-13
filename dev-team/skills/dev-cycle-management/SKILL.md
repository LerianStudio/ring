---
name: ring:dev-cycle-management
description: Development cycle state management — status reporting and cycle cancellation
trigger: |
  - User wants to check the status of a running development cycle
  - User wants to cancel an active development cycle
  - Invoked with mode=status or mode=cancel
skip_when: |
  - No development cycle is active or was recently started
  - User is asking about general project status (not cycle-specific)
---

# Cycle Management

Unified skill for managing development cycle state. Provides two modes: **status** (read-only inspection) and **cancel** (state mutation with confirmation).

## Mode Selection

This skill provides two modes selected by the `mode` parameter:

| Mode | Purpose |
|------|---------|
| `status` | Read-only — display cycle metrics |
| `cancel` | Mutating — cancel the active cycle |

If no mode is provided, default to `status`.

---

## Shared: State File Discovery

Both modes read from the same state files. Check for an active cycle in this order:

1. `docs/ring:dev-cycle/current-cycle.json`
2. `docs/ring:dev-refactor/current-cycle.json`

If neither file exists or both contain a terminal status (`completed`, `cancelled`), report that no cycle is active and exit with the appropriate "no cycle" message for the current mode.

---

## Mode: Status

Display the current development cycle status.

### Output

Displays:
- Current cycle ID and start time
- Tasks: total, completed, in progress, pending
- Current task and gate being executed
- Assertiveness score (if tasks completed)
- Elapsed time

### Example Output

```
Development Cycle Status

Cycle ID: 2024-01-15-143000
Started: 2024-01-15 14:30:00
Status: in_progress

Tasks:
  Completed: 2/5
  In Progress: 1/5 (AUTH-003)
  Pending: 2/5

Current:
  Task: AUTH-003 - Implementar refresh token
  Gate: 3/10 (ring:dev-unit-testing)
  Iterations: 1

Metrics (completed tasks):
  Average Assertiveness: 89%
  Total Duration: 1h 45m

State file: docs/ring:dev-cycle/current-cycle.json (or docs/ring:dev-refactor/current-cycle.json)
```

### When No Cycle is Running (Status Mode)

```
No development cycle in progress.

Start a new cycle with:
  /ring:dev-cycle docs/tasks/your-tasks.md

Or resume an interrupted cycle:
  /ring:dev-cycle --resume
```

### Execution Steps (Status)

1. **Discover state file** — check both paths per "Shared: State File Discovery" above
2. **Read JSON** — parse `current-cycle.json`
3. **Extract fields** — cycle ID, start time, status, task list, current task/gate, iterations
4. **Compute metrics** — count completed/in-progress/pending tasks, calculate elapsed time, average assertiveness score across completed tasks
5. **Display** — format and present the output as shown above

---

## Mode: Cancel

Cancel the current development cycle with state preservation.

### Options

| Option | Description |
|--------|-------------|
| `--force` | Cancel without confirmation |

### Behavior

1. **Confirmation**: Asks for confirmation before canceling (unless `--force`)
2. **State preservation**: Saves current state for potential resume
3. **Cleanup**: Marks cycle as `cancelled` in state file
4. **Report**: Generates partial feedback report with completed tasks

### Confirmation Prompt

Unless `--force` is specified, display:

```
Cancel Development Cycle?

Cycle ID: 2024-01-15-143000
Progress: 3/5 tasks completed

This will:
- Stop the current cycle
- Save state for potential resume
- Generate partial feedback report

[Confirm Cancel] [Keep Running]
```

### After Confirmation (or --force)

```
Cycle Cancelled

Cycle ID: 2024-01-15-143000
Status: cancelled
Completed: 3/5 tasks

State saved to: docs/ring:dev-cycle/current-cycle.json (or docs/ring:dev-refactor/current-cycle.json)
Partial report: docs/dev-team/feedback/cycle-2024-01-15-partial.md

To resume later:
  /ring:dev-cycle --resume
```

### When No Cycle is Running (Cancel Mode)

```
No development cycle to cancel.

Check status with:
  ring:dev-cycle-management (mode=status)
```

### Execution Steps (Cancel)

1. **Discover state file** — check both paths per "Shared: State File Discovery" above
2. **Read JSON** — parse `current-cycle.json`
3. **Validate** — confirm the cycle is in a non-terminal status (`in_progress` or similar)
4. **Confirm** — unless `--force`, use AskUserQuestion to get explicit user confirmation; if declined, abort
5. **Preserve state** — the existing JSON already contains the full state for potential resume
6. **Mark cancelled** — update the `status` field in `current-cycle.json` to `cancelled` and write back
7. **Generate partial report** — create a feedback file at `docs/dev-team/feedback/cycle-{id}-partial.md` summarizing completed tasks, current progress, and reason (user-cancelled)
8. **Display** — format and present the cancellation confirmation as shown above

---

## Related Skills

| Skill | Description |
|-------|-------------|
| `ring:dev-cycle` | Start or resume cycle |
| `ring:dev-cycle-management` (mode=cancel) | Cancel running cycle |
| `ring:dev-cycle-management` (mode=status) | Check current status |
| `ring:dev-report` | View feedback report |

---

Now executing the requested mode...

Read state from: `docs/ring:dev-cycle/current-cycle.json` or `docs/ring:dev-refactor/current-cycle.json`
