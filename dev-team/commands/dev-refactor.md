---
name: dev-refactor
description: Analyze existing codebase against standards and execute refactoring through dev-cycle
argument-hint: "[path]"
---

Analyze existing codebase against standards and execute refactoring through dev-cycle.

## ⛔ PRE-EXECUTION CHECK (EXECUTE FIRST)

**Before loading the skill, you MUST check:**

```
Does docs/PROJECT_RULES.md exist in the target project?
├── YES → Load skill: dev-refactor
└── NO  → Output blocker below and STOP
```

**If file does NOT exist, output this EXACT response:**

```markdown
## ⛔ HARD BLOCK: PROJECT_RULES.md Not Found

**Status:** BLOCKED - Cannot proceed

### Required Action
Create `docs/PROJECT_RULES.md` with your project's:
- Architecture patterns
- Code conventions
- Testing requirements
- DevOps standards

Then re-run `/dev-refactor`.
```

**DO NOT:**
- Use "default" or "industry" standards
- Infer standards from existing code
- Proceed with partial analysis
- Offer to create the file

---

## Usage

```
/dev-refactor [path] [options]
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
/dev-refactor

# Analyze specific directory
/dev-refactor src/domain

# Analysis only (no execution)
/dev-refactor --analyze-only

# Only fix critical issues
/dev-refactor --critical-only

# Use custom standards
/dev-refactor --standards docs/team-standards.md
```

## Workflow

**See skill `dev-refactor` for the complete 13-step workflow with TodoWrite template.**

The skill defines all steps including: stack detection, codebase-explorer dispatch, individual agent reports, finding mapping, and artifact generation.

## Analysis Dimensions

| Dimension | What's Checked |
|-----------|----------------|
| **Architecture** | DDD patterns, layer separation, dependency direction, directory structure |
| **Code Quality** | Naming conventions, error handling, forbidden practices, security |
| **Testing** | Coverage percentage, test patterns, naming, missing tests |
| **DevOps** | Dockerfile, docker-compose, env management, Helm charts |

## Output

**Analysis Report** (`docs/refactor/{timestamp}/analysis-report.md`):
- Summary table with issue counts by severity
- Detailed findings grouped by dimension
- Specific file locations and line numbers

**Tasks File** (`docs/refactor/{timestamp}/tasks.md`):
- Grouped refactoring tasks (REFACTOR-001, REFACTOR-002, etc.)
- Same format as PM Team output
- Compatible with dev-cycle execution

## Severity Levels (ALL ARE MANDATORY)

| Level | Description | Priority | Tracking |
|-------|-------------|----------|----------|
| **Critical** | Security vulnerabilities, data loss risk | Fix immediately | **MANDATORY** |
| **High** | Architecture violations, major code smells | Fix in current sprint | **MANDATORY** |
| **Medium** | Convention violations, moderate gaps | Fix in next sprint | **MANDATORY** |
| **Low** | Style issues, minor gaps | Fix when capacity | **MANDATORY** |

**⛔ ALL severities are MANDATORY to track and fix. Low ≠ Optional. Low = Lower priority, still required.**

## Prerequisites

1. **⛔ PROJECT_RULES.md (MANDATORY)**: `docs/PROJECT_RULES.md` MUST exist - no defaults, no fallback
2. **Git repository**: Project should be under version control
3. **Readable codebase**: Access to source files

**If PROJECT_RULES.md does not exist:** This command will output a blocker message and terminate. The project owner must create the file first.

## Related Commands

| Command | Description |
|---------|-------------|
| `/dev-cycle` | Execute development cycle (used after analysis) |
| `/pre-dev-feature` | Plan new features (use instead for greenfield) |
| `/codereview` | Manual code review (dev-cycle includes this) |

---

## ⛔ MANDATORY: Load Full Skill

**After PROJECT_RULES.md check passes, load the skill:**

```
Use Skill tool: dev-refactor
```

The skill contains the complete analysis workflow with:
- Anti-rationalization tables for codebase exploration
- Mandatory use of `codebase-explorer` (NOT Bash/Explore)
- Standards coverage table requirements
- Finding → Task mapping gates
- Full agent dispatch prompts with `**MODE: ANALYSIS ONLY**`

## Execution Context

Pass the following context to the skill:

| Parameter | Value |
|-----------|-------|
| `path` | `$1` (first argument, default: project root) |
| `--standards` | If provided, custom standards file path |
| `--analyze-only` | If provided, skip dev-cycle execution |
| `--critical-only` | If provided, filter to Critical/High only |
| `--dry-run` | If provided, show what would be analyzed |

## User Approval (MANDATORY)

**Before executing dev-cycle, you MUST ask:**

```yaml
AskUserQuestion:
  questions:
    - question: "Review refactoring plan. How to proceed?"
      header: "Approval"
      options:
        - label: "Approve all"
          description: "Proceed to dev-cycle execution"
        - label: "Critical only"
          description: "Execute only Critical/High tasks"
        - label: "Cancel"
          description: "Keep analysis, skip execution"
```

## Quick Reference

See skill `dev-refactor` for full details. Key rules:

- **All agents dispatch in parallel** - Single message, multiple Task calls
- **Specify model: "opus"** - All agents need opus for comprehensive analysis
- **MODE: ANALYSIS ONLY** - Agents analyze, they do NOT implement
- **Save artifacts** to `docs/refactor/{timestamp}/`
- **Get user approval** before executing dev-cycle
- **Handoff**: `/dev-cycle docs/refactor/{timestamp}/tasks.md`
