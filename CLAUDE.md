# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Ring is a comprehensive skills library and workflow system for Claude Code that enforces proven software engineering practices through mandatory workflows, parallel code review, and systematic pre-development planning. Built as a Claude Code plugin (v0.6.0), it contains 27 core skills, 7 slash commands, and 4 specialized review agents that run in parallel for 3x faster reviews. The architecture uses markdown-based skill definitions with YAML frontmatter, auto-discovered at session start via hooks, and executed through Claude Code's native Skill/Task tools.

## Architecture

```
ring/
├── skills/                     # 27 core skills (8,722 lines total)
│   ├── brainstorming/          # Socratic design refinement
│   ├── test-driven-development/# RED-GREEN-REFACTOR cycle enforcement
│   ├── systematic-debugging/   # 4-phase root cause analysis
│   ├── pre-dev-*/             # 8-gate workflow (PRD→TRD→API→Data→Tasks)
│   ├── using-ring/            # MANDATORY skill discovery (non-negotiable)
│   └── shared-patterns/       # Reusable: state-tracking, failure-recovery
├── agents/                    # Parallel review system (3x faster)
│   ├── code-reviewer.md       # Foundation review (architecture, patterns)
│   ├── business-logic-reviewer.md # Correctness (requirements, edge cases)
│   └── security-reviewer.md   # Safety (OWASP, auth, validation)
├── commands/                  # 7 slash commands
│   ├── review.md             # /ring:review - dispatch 3 parallel reviewers
│   ├── brainstorm.md         # /ring:brainstorm - interactive design
│   └── pre-dev-*.md          # /ring:pre-dev-feature or pre-dev-full
├── hooks/                    # Session lifecycle
│   ├── hooks.json           # SessionStart, UserPromptSubmit config
│   ├── session-start.sh     # Load skills quick reference
│   ├── generate-skills-ref.py # Parse SKILL.md frontmatter
│   └── claude-md-bootstrap.sh # Auto-generate CLAUDE.md for repos
└── lib/                     # Infrastructure utilities
    ├── preflight-checker.sh # Validate prerequisites
    └── compliance-validator.sh # Check skill adherence
```

## Common Commands

```bash
# Git operations (no build system - this is a plugin)
git status                          # Check current branch (main)
git log --oneline -20              # Recent commits show hook development
git worktree list                  # Check isolated development branches

# Skill invocation (via Claude Code)
Skill tool: "ring:test-driven-development"  # Enforce TDD workflow
Skill tool: "ring:systematic-debugging"     # Debug with 4-phase analysis
Skill tool: "ring:using-ring"              # Load mandatory workflows

# Slash commands
/ring:review                       # Dispatch 3 parallel reviewers
/ring:brainstorm                  # Socratic design refinement
/ring:pre-dev-feature             # <2 day features (3 gates)
/ring:pre-dev-full               # ≥2 day features (8 gates)
/ring:execute-plan               # Batch execution with checkpoints
/ring:worktree                   # Create isolated development branch

# Hook validation
bash hooks/session-start.sh      # Test skill loading
python hooks/generate-skills-ref.py # Generate skill overview
bash lib/preflight-checker.sh    # Validate prerequisites
```

## Key Workflows

### Adding a New Skill
1. Create directory: `mkdir skills/your-skill-name/`
2. Write `skills/your-skill-name/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: your-skill-name
   description: Brief description for quick reference
   when_to_use: Specific triggers that mandate this skill
   ---
   ```
3. Test with `Skill tool: "ring:testing-skills-with-subagents"`
4. Skill auto-loads next SessionStart via `hooks/generate-skills-ref.py`

### Modifying Hooks
1. Edit `hooks/hooks.json` for trigger configuration
2. Scripts in `hooks/`: `session-start.sh`, `claude-md-bootstrap.sh`
3. Test: `bash hooks/session-start.sh` outputs JSON with additionalContext
4. SessionStart hooks run on `startup|resume` and `clear|compact`

### Creating Review Agents
1. Add to `agents/your-reviewer.md` with output_schema
2. Reference in `skills/requesting-code-review/SKILL.md:85`
3. Dispatch via Task tool with `subagent_type="ring:your-reviewer"`
4. Must run in parallel with other reviewers (single message, multiple Tasks)

### Pre-Dev Workflow
```
Simple (<2 days): /ring:pre-dev-feature
├── Gate 1: pre-dev-prd-creation → docs/pre-dev/feature/PRD.md
├── Gate 2: pre-dev-trd-creation → docs/pre-dev/feature/TRD.md
└── Gate 3: pre-dev-task-breakdown → docs/pre-dev/feature/tasks.md

Complex (≥2 days): /ring:pre-dev-full
├── Gates 1-3: Same as above
├── Gate 4: pre-dev-api-design → docs/pre-dev/feature/API.md
├── Gate 5: pre-dev-data-model → docs/pre-dev/feature/data-model.md
├── Gate 6: pre-dev-dependency-map → docs/pre-dev/feature/dependencies.md
├── Gate 7: pre-dev-task-breakdown → docs/pre-dev/feature/tasks.md
└── Gate 8: pre-dev-subtask-creation → docs/pre-dev/feature/subtasks.md
```

### Parallel Code Review
```python
# Instead of sequential (60 min):
review1 = Task("ring:code-reviewer")      # 20 min
review2 = Task("ring:business-logic")     # 20 min  
review3 = Task("ring:security-reviewer")  # 20 min

# Run parallel (20 min total):
Task.parallel([
    ("ring:code-reviewer", prompt),
    ("ring:business-logic-reviewer", prompt),
    ("ring:security-reviewer", prompt)
])  # Single message, 3 tool calls
```

## Important Patterns

### Code Organization
- **Skill Structure**: `skills/{name}/SKILL.md` with YAML frontmatter
- **Agent Output**: Required markdown sections per `agents/*.md:output_schema`
- **Hook Scripts**: Must output JSON with success/error fields
- **Shared Patterns**: Reference via `skills/shared-patterns/*.md`
- **Documentation**: Artifacts in `docs/pre-dev/{feature}/*.md`

### Naming Conventions
- Skills: `kebab-case` matching directory name
- Agents: `{domain}-reviewer.md` format
- Commands: `/ring:{action}` prefix
- Hooks: `{event}-{purpose}.sh` format

### Anti-Patterns to Avoid
1. **Never skip using-ring** - It's mandatory, not optional
2. **Never run reviewers sequentially** - Always dispatch in parallel
3. **Never modify generated skill reference** - Auto-generated from frontmatter
4. **Never skip TDD's RED phase** - Test must fail before implementation
5. **Never ignore skill when applicable** - "Simple task" is not an excuse
6. **Never use panic() in Go** - Error handling required
7. **Never commit incomplete code** - No "TODO: implement" comments

### Compliance Rules
```bash
# TDD compliance (skills/test-driven-development/SKILL.md:638)
- Test file must exist before implementation
- Test must produce failure output (RED)
- Only then write implementation (GREEN)

# Review compliance (skills/requesting-code-review/SKILL.md:188)  
- All 3 reviewers must pass
- Critical findings = immediate fix required
- Re-run all reviewers after fixes

# Skill compliance (skills/using-ring/SKILL.md:222)
- Check for applicable skills before ANY task
- If skill exists for task → MUST use it
- Announce non-obvious skill usage
```

### Session Context
The system loads at SessionStart:
1. `claude-md-bootstrap.sh` - Generates this CLAUDE.md if missing (45-60s)
2. `session-start.sh` - Loads skill quick reference via `generate-skills-ref.py`
3. `using-ring` skill - Injected as mandatory workflow

Current git status: `main` branch, remote `github.com/LerianStudio/ring`