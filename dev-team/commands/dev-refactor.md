Analyze existing codebase against standards and execute refactoring through dev-cycle.

## ⛔ PRE-EXECUTION CHECK (EXECUTE FIRST)

**Before loading the skill, you MUST check:**

```
Does docs/PROJECT_RULES.md exist in the target project?
├── YES → Load skill: ring-dev-team:dev-refactor
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

Then re-run `/ring-dev-team:dev-refactor`.
```

**DO NOT:**
- Use "default" or "industry" standards
- Infer standards from existing code
- Proceed with partial analysis
- Offer to create the file

---

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
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  ⛔ HARD GATE: Check PROJECT_RULES.md                       │
│                                                             │
│  Does docs/PROJECT_RULES.md exist?                          │
│  └── YES → Continue                                         │
│  └── NO  → OUTPUT BLOCKER AND TERMINATE                     │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        ▼                                     ▼
┌───────────────────┐                ┌───────────────────┐
│ Load Standards    │                │ Dispatch Agents   │
│                   │                │ (ring-dev-team:*) │
│ PROJECT_RULES.md  │                │                   │
│ (MANDATORY)       │                │ • backend-engineer│
│                   │                │ • qa-analyst      │
└───────────────────┘                │ • devops-engineer │
                                     │ • sre             │
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

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| **Critical** | Security vulnerabilities, data loss risk | Fix immediately |
| **High** | Architecture violations, major code smells | Fix in current sprint |
| **Medium** | Convention violations, minor issues | Fix when touching file |
| **Low** | Style issues, suggestions | Optional improvements |

## Prerequisites

1. **⛔ PROJECT_RULES.md (MANDATORY)**: `docs/PROJECT_RULES.md` MUST exist - no defaults, no fallback
2. **Git repository**: Project should be under version control
3. **Readable codebase**: Access to source files

**If PROJECT_RULES.md does not exist:** This command will output a blocker message and terminate. The project owner must create the file first.

## Related Commands

| Command | Description |
|---------|-------------|
| `/ring-dev-team:dev-cycle` | Execute development cycle (used after analysis) |
| `/ring-pm-team:pre-dev-feature` | Plan new features (use instead for greenfield) |
| `/ring-default:codereview` | Manual code review (dev-cycle includes this) |

---

## Step 0: Validate PROJECT_RULES.md

Check: Does `docs/PROJECT_RULES.md` exist?

- **YES** → Continue to Step 1
- **NO** → Output blocker (see PRE-EXECUTION CHECK above) and TERMINATE

## Step 1: Detect Project Language

Check for manifest files:

| File | Language | Agent |
|------|----------|-------|
| `go.mod` | Go | ring-dev-team:backend-engineer-golang |
| `package.json` | TypeScript | ring-dev-team:backend-engineer-typescript |

If multiple languages detected, dispatch agents for ALL.

## Step 2: Generate Codebase Report

**Skill:** ring-default:codebase-explorer

Dispatch codebase explorer to generate architecture report:

```yaml
Task:
  subagent_type: "ring-default:codebase-explorer"
  model: "opus"
  description: "Generate codebase architecture report"
  prompt: |
    Generate a comprehensive codebase report describing WHAT EXISTS.
    Include: structure, architecture pattern, tech stack, code patterns,
    key files inventory with file:line references.
```

Save output to: `docs/refactor/{timestamp}/codebase-report.md`

## Step 3: Dispatch Specialist Agents

**⛔ HARD GATE:** Verify `codebase-report.md` exists before proceeding.

Dispatch ALL applicable agents in ONE message (parallel):

```yaml
Task 1 (ring-dev-team:backend-engineer-golang or backend-engineer-typescript):
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Compare codebase with Ring standards.
    Input: codebase-report.md, PROJECT_RULES.md
    Output: ISSUE-XXX with severity, location (file:line), current vs expected code

Task 2 (ring-dev-team:qa-analyst):
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Compare test patterns with Ring standards.
    Output: Coverage gaps, pattern violations with file:line

Task 3 (ring-dev-team:devops-engineer):
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Compare DevOps setup with Ring standards.
    Output: Dockerfile, docker-compose, Helm chart gaps

Task 4 (ring-dev-team:sre):
  model: "opus"
  prompt: |
    **MODE: ANALYSIS ONLY**
    Compare observability with Ring standards.
    Output: Logging, tracing, health check gaps
```

## Step 4: Generate Findings

Aggregate all agent outputs into `docs/refactor/{timestamp}/findings.md`:

```markdown
# Findings: {project-name}

## FINDING-001: {Pattern Name}
**Severity:** Critical | High | Medium | Low
**Agent:** {ring-dev-team:agent-name}
**Location:** {file}:{line}

### Current Code
{actual code snippet}

### Expected Code (Ring Standard)
{expected code snippet}
```

## Step 5: Generate Tasks

Group related findings into `docs/refactor/{timestamp}/tasks.md`:

```markdown
# Refactoring Tasks

## REFACTOR-001: {Task Name}
**Priority:** Critical | High | Medium
**Dependencies:** {other tasks or none}

### Findings Addressed
| Finding | Pattern | Severity |
|---------|---------|----------|
| FINDING-001 | {name} | Critical |

### Acceptance Criteria
- [ ] {criteria from finding}
```

## Step 6: User Approval

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

## Step 7: Handoff to dev-cycle (if approved)

Execute: `/ring-dev-team:dev-cycle docs/refactor/{timestamp}/tasks.md`

## Remember

- **All agents dispatch in parallel** - Single message, multiple Task calls
- **Specify model: "opus"** - All agents need opus for comprehensive analysis
- **MODE: ANALYSIS ONLY** - Agents analyze, they do NOT implement
- **Save artifacts** to `docs/refactor/{timestamp}/`
- **Get user approval** before executing dev-cycle
