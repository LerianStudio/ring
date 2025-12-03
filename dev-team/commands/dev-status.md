Check the status of the current development cycle.

## Usage

```
/ring-dev-team:dev-status
```

## Output

Displays:
- Current cycle ID and start time
- Tasks: total, completed, in progress, pending
- Current task and gate being executed
- Assertiveness score (if tasks completed)
- Elapsed time

## Example Output

```
📊 Development Cycle Status

Cycle ID: 2024-01-15-143000
Started: 2024-01-15 14:30:00
Status: in_progress

Tasks:
  ✅ Completed: 2/5
  🔄 In Progress: 1/5 (AUTH-003)
  ⏳ Pending: 2/5

Current:
  Task: AUTH-003 - Implementar refresh token
  Gate: 5/8 (dev-testing)
  Iterations: 1

Metrics (completed tasks):
  Average Assertiveness: 89%
  Total Duration: 1h 45m

State file: dev-team/state/current-cycle.json
```

## When No Cycle is Running

```
ℹ️ No development cycle in progress.

Start a new cycle with:
  /ring-dev-team:dev-cycle docs/tasks/your-tasks.md

Or resume an interrupted cycle:
  /ring-dev-team:dev-cycle --resume
```

## Related Commands

| Command | Description |
|---------|-------------|
| `/ring-dev-team:dev-cycle` | Start or resume cycle |
| `/ring-dev-team:dev-cancel` | Cancel running cycle |
| `/ring-dev-team:dev-report` | View feedback report |

---

Now checking cycle status...

Read state from: `dev-team/state/current-cycle.json`
