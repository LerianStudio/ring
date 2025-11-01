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

**Documentation** (`docs/`)
- `skills-quick-reference.md` provides rapid skill lookup
- `plans/` contains implementation plans for features

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
# Initialize skills system (for testing)
./lib/initialize-skills.sh

# Check skills quick reference
cat docs/skills-quick-reference.md
```

## Key Workflows

### Adding a New Skill
1. Create directory: `skills/skill-name/`
2. Add `SKILL.md` with frontmatter and content
3. Update `docs/skills-quick-reference.md`
4. Test with session-start hook

### Modifying Skills
1. Edit `skills/{skill-name}/SKILL.md`
2. Maintain frontmatter structure
3. Follow existing patterns for checklists and warnings
4. Preserve universal pattern references

### Creating Commands
1. Add `.md` file to `commands/`
2. Reference corresponding skill
3. Use clear, actionable language

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

### Anti-Patterns to Avoid
- Skipping skill checks before tasks
- Writing code before tests
- Fixing bugs without root cause analysis
- Claiming completion without verification

## Session Integration

The repository uses a SessionStart hook that:
1. Displays skills quick reference
2. Loads the using-ring skill automatically
3. Provides pre-dev workflow reminder
4. Shows available skills and commands

This ensures every Claude Code session starts with full awareness of available capabilities and mandatory workflows.