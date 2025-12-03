Execute the development cycle for tasks in a markdown file.

## Usage

```
/ring-dev-team:dev-cycle [tasks-file] [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `tasks-file` | Yes* | Path to markdown file with tasks (e.g., `docs/tasks/sprint-001.md`) |

*Can be omitted if `docs/tasks/current.md` exists.

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--task ID` | Execute only specific task | `--task PROJ-123` |
| `--skip-gates` | Skip specific gates | `--skip-gates devops,review` |
| `--dry-run` | Validate tasks without executing | `--dry-run` |
| `--resume` | Resume interrupted cycle | `--resume` |

## Examples

```bash
# Execute all tasks from a file
/ring-dev-team:dev-cycle docs/tasks/sprint-001.md

# Execute single task
/ring-dev-team:dev-cycle docs/tasks/sprint-001.md --task AUTH-001

# Skip DevOps setup (infrastructure already exists)
/ring-dev-team:dev-cycle docs/tasks/sprint-001.md --skip-gates devops

# Validate tasks without executing
/ring-dev-team:dev-cycle docs/tasks/sprint-001.md --dry-run

# Resume interrupted cycle
/ring-dev-team:dev-cycle --resume
```

## Prerequisites

1. **Task file**: Markdown file following the format in `dev-team/templates/task-input.md`
2. **Project standards** (optional but recommended): `docs/STANDARDS.md` with project conventions
3. **PRD/TRD** (optional): If exists in `docs/pre-dev/{feature}/`, will be used in design phase

## Gates Executed

| Gate | Skill | Description |
|------|-------|-------------|
| 0 | `dev-import-tasks` | Parse and validate tasks |
| 1 | `dev-analysis` | Analyze codebase context |
| 2 | `dev-design` | Create technical design |
| 3 | `dev-implementation` | Implement code |
| 4 | `dev-devops-setup` | Create Docker/compose |
| 5 | `dev-testing` | Write and run tests |
| 6 | `dev-review` | Code review (3 reviewers) |
| 7 | `dev-validation` | Manual validation |

After all tasks: `dev-feedback-loop` generates metrics report.

## Output

- **State file**: `dev-team/state/current-cycle.json`
- **Feedback report**: `docs/feedback/cycle-YYYY-MM-DD.md`

## Related Commands

| Command | Description |
|---------|-------------|
| `/ring-dev-team:dev-status` | Check current cycle status |
| `/ring-dev-team:dev-cancel` | Cancel running cycle |
| `/ring-dev-team:dev-report` | View feedback report |

---

Now loading the `development-cycle` skill to execute...

Use skill: `ring-dev-team:development-cycle`

Provide the task file path or use `--resume` to continue an interrupted cycle.
