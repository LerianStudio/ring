Analyze existing codebase against standards and execute refactoring through dev-cycle.

## Usage

```
/ring-dev-team:dev-refactor [path] [options]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `path` | No | Directory to analyze (default: current project root) |

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--standards PATH` | Custom standards file | `--standards docs/MY_PROJECT_RULES.md` |
| `--analyze-only` | Generate report without executing | `--analyze-only` |
| `--critical-only` | Only Critical and High priority issues | `--critical-only` |
| `--dry-run` | Show what would be analyzed | `--dry-run` |

## Examples

```bash
# Analyze entire project and refactor
/ring-dev-team:dev-refactor

# Analyze specific directory
/ring-dev-team:dev-refactor src/domain

# Analysis only (no execution)
/ring-dev-team:dev-refactor --analyze-only

# Only fix critical issues
/ring-dev-team:dev-refactor --critical-only

# Use custom standards
/ring-dev-team:dev-refactor --standards docs/team-standards.md
```

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                 /ring-dev-team:dev-refactor                     │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        ▼                                     ▼
┌───────────────────┐                ┌───────────────────┐
│ Load Standards    │                │ Scan Codebase     │
│                   │                │ (4 dimensions)    │
│ 1. Project's      │                │                   │
│    PROJECT_RULES.md   │                │ • Architecture    │
│ 2. Or dev-team    │                │ • Code Quality    │
│    defaults       │                │ • Testing         │
└───────────────────┘                │ • DevOps          │
                                     └───────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Generate Report                           │
│                                                             │
│  docs/refactor/{timestamp}/                                 │
│  ├── analysis-report.md   (all findings)                    │
│  └── tasks.md             (grouped refactoring tasks)       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   User Approval                             │
│                                                             │
│  Options:                                                   │
│  • Approve all → Execute all tasks                          │
│  • Approve with changes → Edit tasks.md first               │
│  • Critical only → Filter to Critical/High                  │
│  • Cancel → Keep report, no execution                       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼ (if approved)
┌─────────────────────────────────────────────────────────────┐
│              /ring-dev-team:dev-cycle                       │
│              docs/refactor/{timestamp}/tasks.md             │
│                                                             │
│  Standard 6-gate process for each task:                     │
│  • Gate 0: Implementation (TDD)                             │
│  • Gate 1: DevOps Setup                                     │
│  • Gate 2: SRE (Observability)                              │
│  • Gate 3: Testing                                          │
│  • Gate 4: Review (3 parallel reviewers)                    │
│  • Gate 5: Validation                                       │
└─────────────────────────────────────────────────────────────┘
```

## Analysis Dimensions

| Dimension | What's Checked |
|-----------|----------------|
| **Architecture** | DDD patterns, layer separation, dependency direction, directory structure |
| **Code Quality** | Naming conventions, error handling, forbidden practices, security |
| **Testing** | Coverage percentage, test patterns, naming, missing tests |
| **DevOps** | Dockerfile, docker-compose, env management, CI/CD |

## Output

**Analysis Report** (`docs/refactor/{timestamp}/analysis-report.md`):
- Summary table with issue counts by severity
- Detailed findings grouped by dimension
- Specific file locations and line numbers

**Tasks File** (`docs/refactor/{timestamp}/tasks.md`):
- Grouped refactoring tasks (REFACTOR-001, REFACTOR-002, etc.)
- Same format as PM Team output
- Compatible with dev-cycle execution

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| **Critical** | Security vulnerabilities, data loss risk | Fix immediately |
| **High** | Architecture violations, major code smells | Fix in current sprint |
| **Medium** | Convention violations, minor issues | Fix when touching file |
| **Low** | Style issues, suggestions | Optional improvements |

## Prerequisites

1. **Standards file**: Either `docs/PROJECT_RULES.md` in project or use dev-team defaults
2. **Git repository**: Project should be under version control
3. **Readable codebase**: Access to source files

## Related Commands

| Command | Description |
|---------|-------------|
| `/ring-dev-team:dev-cycle` | Execute development cycle (used after analysis) |
| `/ring-pm-team:pre-dev-feature` | Plan new features (use instead for greenfield) |
| `/ring-default:codereview` | Manual code review (dev-cycle includes this) |

---

Now loading the `ring-dev-team:dev-analysis` skill to analyze your codebase...

Use skill: `ring-dev-team:dev-analysis`
