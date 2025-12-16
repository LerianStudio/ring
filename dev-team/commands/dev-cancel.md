---
name: dev-cancel
description: Cancel the current development cycle
argument-hint: "[--force]"
---

Cancel the current development cycle.

## Usage

```
/dev-cancel [--force]
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

State saved to: docs/refactor/current-cycle.json
Partial report: .ring/dev-team/feedback/cycle-2024-01-15-partial.md

To resume later:
  /dev-cycle --resume
```

## When No Cycle is Running

```
ℹ️ No development cycle to cancel.

Check status with:
  /dev-status
```

## Related Commands

| Command | Description |
|---------|-------------|
| `/dev-cycle` | Start or resume cycle |
| `/dev-status` | Check current status |
| `/dev-report` | View feedback report |

---

Now checking for active cycle to cancel...

Read state from: `docs/refactor/current-cycle.json`
