Cancel the current development cycle.

## Usage

```
/ring-dev-team:dev-cancel [--force]
```

## Options

| Option | Description |
|--------|-------------|
| `--force` | Cancel without confirmation |

## Behavior

1. **Confirmation**: Asks for confirmation before canceling (unless `--force`)
2. **State preservation**: Saves current state for potential resume
3. **Cleanup**: Marks cycle as `cancelled` in state file
4. **Report**: Generates partial feedback report with completed tasks

## Example

```
⚠️ Cancel Development Cycle?

Cycle ID: 2024-01-15-143000
Progress: 3/5 tasks completed

This will:
- Stop the current cycle
- Save state for potential resume
- Generate partial feedback report

[Confirm Cancel] [Keep Running]
```

After confirmation:

```
🛑 Cycle Cancelled

Cycle ID: 2024-01-15-143000
Status: cancelled
Completed: 3/5 tasks

State saved to: dev-team/state/current-cycle.json
Partial report: docs/feedback/cycle-2024-01-15-partial.md

To resume later:
  /ring-dev-team:dev-cycle --resume
```

## When No Cycle is Running

```
ℹ️ No development cycle to cancel.

Check status with:
  /ring-dev-team:dev-status
```

## Related Commands

| Command | Description |
|---------|-------------|
| `/ring-dev-team:dev-cycle` | Start or resume cycle |
| `/ring-dev-team:dev-status` | Check current status |
| `/ring-dev-team:dev-report` | View feedback report |

---

Now checking for active cycle to cancel...

Read state from: `dev-team/state/current-cycle.json`
