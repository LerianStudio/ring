# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Ring is a comprehensive skills library and workflow system for Claude Code, implementing proven software engineering practices through structured skills. It provides:

1. **28 specialized skills** covering testing, debugging, collaboration, and planning
2. **8-gate pre-development workflow** for systematic feature planning
3. **Session hooks** that automatically initialize skills on startup
4. **Commands** for interactive workflows (/ring:brainstorm, /ring:write-plan, /ring:execute-plan)

## Architecture

### Core Components

**Skills System** (`skills/`)
- Each skill is a self-contained directory with `SKILL.md` containing structured instructions
- Skills use YAML frontmatter: `name`, `description`, `when_to_use`
- Skills contain mandatory workflows, checklists, and anti-patterns
- Universal patterns in `skills/shared-patterns/` provide common elements

**Plugin System** (`.claude-plugin/`)
- Integrates with Claude Code as a marketplace plugin
- `plugin.json` defines metadata and version
- `marketplace.json` contains display information

**Session Management** (`hooks/`)
- `hooks.json` configures SessionStart triggers
- `session-start.sh` injects skills context at session start
- Automatically loads `using-ring` skill and quick reference

**Commands** (`commands/`)
- Slash commands for common workflows
- Each `.md` file defines a command template
- Commands map to corresponding skills

**Review Agents** (`agents/`)
- `code-reviewer.md` - Foundation review (architecture, code quality, design patterns)
- `business-logic-reviewer.md` - Correctness review (domain logic, requirements, edge cases)
- `security-reviewer.md` - Safety review (vulnerabilities, OWASP, authentication)
- `prompt-engineer.md` - Prompt enhancement specialist (reviews and improves prompts using best practices)
- All reviewers run on Opus model for comprehensive analysis
- **All 3 code reviewers run in parallel** (not sequentially) for 3x faster feedback
- Use `/ring:review` command to orchestrate parallel review workflow

**Documentation** (`docs/`)
- Skills quick reference is **auto-generated** at session start by `hooks/generate-skills-ref.py`
- `plans/` contains implementation plans and architecture design documents

## Common Commands

### Skill Management
```bash
# List all available skills
ls -la skills/

# Read a specific skill
cat skills/test-driven-development/SKILL.md

# Check skill frontmatter
head -20 skills/brainstorming/SKILL.md
```

### Git Operations
```bash
# Check status (main branch is 'main')
git status

# View recent commits
git log --oneline -10

# Create feature branch
git checkout -b feature/your-feature

# Commit with conventional commits
git commit -m "feat(skills): add new capability"
```

### Plugin Development
```bash
# Test session start hook
./hooks/session-start.sh

# Validate plugin configuration
cat .claude-plugin/plugin.json | jq .

# Check marketplace metadata
cat .claude-plugin/marketplace.json | jq .
```

### Testing Skills
```bash
# Test session start hook (generates skills quick reference)
./hooks/session-start.sh

# Test skills reference generation directly
./hooks/generate-skills-ref.py
```

## Key Workflows

### Adding a New Skill
1. Create directory: `skills/skill-name/`
2. Add `SKILL.md` with frontmatter (name, description) and content
3. Test with session-start hook: `./hooks/session-start.sh`
4. Skills quick reference auto-generates from frontmatter (no manual update needed)

### Modifying Skills
1. Edit `skills/{skill-name}/SKILL.md`
2. Maintain frontmatter structure
3. Follow existing patterns for checklists and warnings
4. Preserve universal pattern references

### Creating Commands
1. Add `.md` file to `commands/`
2. Reference corresponding skill
3. Use clear, actionable language

### Creating or Improving Agents
1. Draft initial agent definition in `agents/`
2. Use `/ring:improve-prompt agents/your-agent.md` to enhance with best practices
3. Test agent with real scenarios
4. Iterate based on results

### Improving Prompts
**Use prompt-engineer agent when:**
- Creating new agent definitions
- Skills produce inconsistent results
- Instructions are unclear or ambiguous
- Need to apply Anthropic best practices
- Want codebase-aware prompt improvements

**The agent will:**
- Analyze prompt for clarity, structure, completeness
- Launch subagents to understand codebase context
- Apply proven prompt engineering techniques
- Provide enhanced version with explanations

## Code Review System (Parallel Execution)

Ring uses a **parallel 3-reviewer system** for comprehensive, fast feedback:

### Review Agents

**All 3 reviewers dispatch simultaneously** (independent, not sequential):
1. **code-reviewer** (Foundation) - Architecture, design patterns, code quality
2. **business-logic-reviewer** (Correctness) - Domain correctness, requirements, edge cases
3. **security-reviewer** (Safety) - Vulnerabilities, OWASP, authentication

**Model requirement:** All reviewers must run on `model: "opus"` for comprehensive analysis

**Key change:** Reviewers are no longer Gates 1→2→3 in sequence. All run in parallel independently.

### Dispatch Pattern

**Single message with 3 Task calls:**
```python
# Launch all 3 reviewers in parallel
Task(ring:code-reviewer, model="opus", ...)
Task(ring:business-logic-reviewer, model="opus", ...)
Task(ring:security-reviewer, model="opus", ...)

# Wait for all to complete, then aggregate by severity
```

### Severity-Based Handling

After all reviewers complete, aggregate findings and handle by severity:

**Critical/High/Medium Issues:**
- Fix immediately via fix subagent
- Re-run all 3 reviewers in parallel after fixes
- Repeat until no Critical/High/Medium issues remain

**Low Issues:**
- Add `TODO(review):` comments in code with reporter, date, severity
- Track tech debt at code location for visibility

**Cosmetic/Nitpick Issues:**
- Add `FIXME(nitpick):` comments in code with reporter, date, severity
- Low-priority improvements tracked inline

### Key Benefits

- **3x faster** - All reviewers run simultaneously (vs. sequential gates)
- **Comprehensive** - Get all feedback at once, easier to prioritize fixes
- **Tech debt visible** - Low/Cosmetic issues tracked in code with TODO/FIXME
- **Fast re-review** - Parallel execution makes verification quick (~3-5 min total)

### Related Skills

- `requesting-code-review` - How to dispatch parallel reviews properly
- `subagent-driven-development` - Uses parallel reviews after each task
- `receiving-code-review` - How to respond to review feedback

## Skill Categories

**Testing & Debugging** (5 skills)
- Focus on TDD, systematic debugging, verification
- Enforce evidence-based practices

**Collaboration & Planning** (9 skills)
- Support team workflows and code review
- Enable parallel execution and isolation

**Pre-Dev Workflow** (8 gates)
- Sequential gates from PRD to implementation
- Each gate validates before proceeding

**Meta Skills** (4 skills)
- Skills about skills (discovery, writing, testing)
- Self-improvement and contribution patterns

## Important Patterns

### Universal Patterns
Located in `skills/shared-patterns/`:
- State tracking and progress management
- Failure recovery and rollback
- Exit criteria and completion validation
- TodoWrite integration

### Mandatory Workflows
- **using-ring**: Check for relevant skills before ANY task
- **test-driven-development**: RED-GREEN-REFACTOR cycle
- **systematic-debugging**: 4-phase investigation
- **verification-before-completion**: Evidence before claims
- **requesting-code-review**: Parallel 3-reviewer dispatch with severity-based handling

### Anti-Patterns to Avoid
- Skipping skill checks before tasks
- Writing code before tests
- Fixing bugs without root cause analysis
- Claiming completion without verification
- Dispatching code reviewers sequentially (use parallel - 3x faster!)
- Proceeding with unfixed Critical/High/Medium review issues
- Forgetting TODO/FIXME comments for Low/Cosmetic issues

## Session Integration

The repository uses a SessionStart hook that:
1. Displays skills quick reference
2. Loads the using-ring skill automatically
3. Provides pre-dev workflow reminder
4. Shows available skills and commands

This ensures every Claude Code session starts with full awareness of available capabilities and mandatory workflows.