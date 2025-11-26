# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Ring is a comprehensive skills library and workflow system for AI agents that enforces proven software engineering practices through mandatory workflows, parallel code review, and systematic pre-development planning. Currently implemented as a Claude Code plugin marketplace with **5 active plugins**, the skills are agent-agnostic and reusable across different AI systems.

**Active Plugins:**
- **ring-default** (v0.7.6): 20 core skills, 8 slash commands, 5 specialized agents
- **ring-dev-team** (v0.1.1): 2 developer skills, 10 specialized developer agents (Backend [generic], Backend Go, Backend TypeScript, Backend Python, DevOps, Frontend [generic], Frontend TypeScript, Frontend Designer, QA, SRE)
- **ring-finops-team** (v0.2.1): 6 regulatory skills, 2 FinOps agents
- **ring-pm-team** (v0.1.1): 9 product planning skills
- **ralph-wiggum** (v0.1.0): 1 skill for iterative AI development loops using Stop hooks

**Total: 38 skills (20 + 2 + 6 + 9 + 1) across 5 plugins**

The architecture uses markdown-based skill definitions with YAML frontmatter, auto-discovered at session start via hooks, and executed through Claude Code's native Skill/Task tools.

## Installation

```bash
# Quick install via script (Linux/macOS/Git Bash)
curl -fsSL https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.sh | bash

# Quick install via script (Windows PowerShell)
irm https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.ps1 | iex

# Or manual clone (marketplace with multiple plugins)
git clone https://github.com/lerianstudio/ring.git ~/ring
```

## Architecture

**Monorepo Structure** - Marketplace with multiple plugin collections:

```
ring/                                  # Monorepo root
├── .claude-plugin/
│   └── marketplace.json              # Multi-plugin marketplace config (5 active plugins)
├── default/                          # Core Ring plugin (ring-default v0.7.6)
│   ├── skills/                       # 20 core skills
│   │   ├── brainstorming/            # Socratic design refinement
│   │   ├── test-driven-development/  # RED-GREEN-REFACTOR cycle enforcement
│   │   ├── systematic-debugging/     # 4-phase root cause analysis
│   │   ├── using-ring/              # MANDATORY skill discovery (non-negotiable)
│   │   └── shared-patterns/         # Reusable: state-tracking, failure-recovery
│   ├── agents/                      # 5 specialized agents
│   │   ├── code-reviewer.md         # Foundation review (architecture, patterns)
│   │   ├── business-logic-reviewer.md # Correctness (requirements, edge cases)
│   │   ├── security-reviewer.md     # Safety (OWASP, auth, validation)
│   │   ├── write-plan.md            # Implementation planning
│   │   └── codebase-explorer.md     # Deep architecture analysis (Opus)
│   ├── commands/                    # 8 slash commands
│   │   ├── review.md               # /ring:review - dispatch 3 parallel reviewers
│   │   ├── brainstorm.md           # /ring:brainstorm - interactive design
│   │   └── pre-dev-*.md            # /ring:pre-dev-feature or pre-dev-full
│   ├── hooks/                      # Session lifecycle
│   │   ├── hooks.json             # SessionStart, UserPromptSubmit config
│   │   ├── session-start.sh       # Load skills quick reference
│   │   ├── generate-skills-ref.py # Parse SKILL.md frontmatter
│   │   └── claude-md-reminder.sh  # CLAUDE.md reminder on prompt submit
│   └── docs/                      # Documentation
├── dev-team/                      # Developer Agents plugin (ring-dev-team v0.1.1)
│   ├── skills/                    # 2 developer skills
│   │   ├── using-dev-team/        # Plugin introduction
│   │   └── writing-code/          # Developer agent selection
│   └── agents/                    # 10 specialized developer agents
│       ├── backend-engineer.md             # Backend specialist (language agnostic)
│       ├── backend-engineer-golang.md      # Go backend specialist
│       ├── backend-engineer-typescript.md  # TypeScript/Node.js backend specialist
│       ├── backend-engineer-python.md      # Python backend specialist
│       ├── devops-engineer.md              # DevOps infrastructure specialist
│       ├── frontend-engineer.md            # Frontend specialist (language agnostic)
│       ├── frontend-engineer-typescript.md # TypeScript/React/Next.js specialist
│       ├── frontend-designer.md            # Visual design specialist
│       ├── qa-analyst.md                   # Quality assurance specialist
│       └── sre.md                          # Site reliability engineer
├── finops-team/                   # FinOps plugin (ring-finops-team v0.2.1)
│   ├── skills/                    # 6 regulatory compliance skills
│   │   └── regulatory-templates*/ # Brazilian regulatory compliance (BACEN, RFB)
│   ├── agents/                    # 2 FinOps agents
│   │   ├── finops-analyzer.md    # Financial operations analysis
│   │   └── finops-automation.md  # FinOps automation
│   └── docs/
│       └── regulatory/           # Brazilian regulatory documentation
├── pm-team/                  # Product Planning plugin (ring-pm-team v0.1.1)
│   └── skills/                    # 9 pre-dev workflow skills
│       └── pre-dev-*/            # PRD→TRD→API→Data→Tasks
├── ralph-wiggum/                  # Iterative AI loops plugin (ralph-wiggum v0.1.0)
│   ├── commands/                  # 3 slash commands
│   │   ├── ralph-loop.md         # Start iterative loop
│   │   ├── cancel-ralph.md       # Cancel active loop
│   │   └── help.md               # Technique guide
│   ├── hooks/                     # Session and Stop hooks
│   │   ├── hooks.json            # Hook configuration
│   │   ├── session-start.sh      # Context injection
│   │   └── stop-hook.sh          # Loop control via Stop hook
│   ├── scripts/                   # Setup utilities
│   │   └── setup-ralph-loop.sh   # State file creation
│   └── skills/                    # Plugin skill
│       └── using-ralph-wiggum/   # Ralph technique guide
├── ops-team/                      # Team-specific skills (reserved)
└── pmm-team/                      # Team-specific skills (reserved)
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

# Hook validation (from default plugin)
bash default/hooks/session-start.sh      # Test skill loading
python default/hooks/generate-skills-ref.py # Generate skill overview
```

## Key Workflows

### Adding a New Skill

**For core Ring skills:**
1. Create directory: `mkdir default/skills/your-skill-name/`
2. Write `default/skills/your-skill-name/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: your-skill-name
   description: |
     Brief description of WHAT the skill does (method/technique).

   trigger: |
     - Specific condition that mandates this skill
     - Another trigger condition

   skip_when: |
     - When NOT to use → alternative skill
     - Another exclusion

   sequence:
     after: [prerequisite-skill]   # Optional: ordering
     before: [following-skill]

   related:
     similar: [differentiate-from]      # Optional: disambiguation
     complementary: [pairs-well-with]
   ---
   ```
3. Test with `Skill tool: "ring:testing-skills-with-subagents"`
4. Skill auto-loads next SessionStart via `default/hooks/generate-skills-ref.py`

**For product/team-specific skills:**
1. Create plugin directory: `mkdir -p product-xyz/{skills,agents,commands,hooks}`
2. Add to `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "ring-product-xyz",
     "description": "Product XYZ specific skills",
     "version": "0.1.0",
     "source": "./product-xyz"
   }
   ```
3. Follow same skill structure as default plugin

### Modifying Hooks
1. Edit `default/hooks/hooks.json` for trigger configuration
2. Scripts in `default/hooks/`: `session-start.sh`, `claude-md-bootstrap.sh`
3. Test: `bash default/hooks/session-start.sh` outputs JSON with additionalContext
4. SessionStart hooks run on `startup|resume` and `clear|compact`
5. Note: `${CLAUDE_PLUGIN_ROOT}` resolves to plugin root (`default/` for core plugin)

### Plugin-Specific Using-* Skills

Each plugin auto-loads a `using-{plugin}` skill via SessionStart hook to introduce available agents and capabilities:

**Default Plugin:**
- `using-ring` → ORCHESTRATOR principle, mandatory workflow
- Always injected, always mandatory
- Located: `default/skills/using-ring/SKILL.md`

**Ring Dev Team Plugin:**
- `using-dev-team` → 10 specialist developer agents
- Auto-loads when ring-dev-team plugin is enabled
- Located: `dev-team/skills/using-dev-team/SKILL.md`
- Agents: backend-engineer, backend-engineer-golang, backend-engineer-typescript, backend-engineer-python, devops-engineer, frontend-engineer, frontend-engineer-typescript, frontend-designer, qa-analyst, sre

**Ring FinOps Team Plugin:**
- `using-finops-team` → 2 FinOps agents for Brazilian compliance
- Auto-loads when ring-finops-team plugin is enabled
- Located: `finops-team/skills/using-finops-team/SKILL.md`
- Agents: finops-analyzer (compliance analysis), finops-automation (template generation)

**Ring PM Team Plugin:**
- `using-pm-team` → Pre-dev workflow skills (8 gates)
- Auto-loads when ring-pm-team plugin is enabled
- Located: `pm-team/skills/using-pm-team/SKILL.md`
- Skills: 8 pre-dev gates for feature planning

**Ralph Wiggum Plugin:**
- `using-ralph-wiggum` → Iterative AI development loops
- Auto-loads when ralph-wiggum plugin is enabled
- Located: `ralph-wiggum/skills/using-ralph-wiggum/SKILL.md`
- Commands: ralph-loop, cancel-ralph, help

**Hook Configuration:**
- Each plugin has: `{plugin}/hooks/hooks.json` + `{plugin}/hooks/session-start.sh`
- SessionStart hook executes, outputs additionalContext with skill reference
- Only plugins in marketplace.json get loaded (conditional)

### Creating Review Agents
1. Add to `default/agents/your-reviewer.md` with output_schema
2. Reference in `default/skills/requesting-code-review/SKILL.md:85`
3. Dispatch via Task tool with `subagent_type="ring:your-reviewer"`
4. Must run in parallel with other reviewers (single message, multiple Tasks)

### Pre-Dev Workflow
```
Simple (<2 days): /ring:pre-dev-feature
├── Gate 1: pm-team/skills/pre-dev-prd-creation → docs/pre-dev/feature/PRD.md
├── Gate 2: pm-team/skills/pre-dev-trd-creation → docs/pre-dev/feature/TRD.md
└── Gate 3: pm-team/skills/pre-dev-task-breakdown → docs/pre-dev/feature/tasks.md

Complex (≥2 days): /ring:pre-dev-full
├── Gates 1-3: Same as above
├── Gate 4: pm-team/skills/pre-dev-api-design → docs/pre-dev/feature/API.md
├── Gate 5: pm-team/skills/pre-dev-data-model → docs/pre-dev/feature/data-model.md
├── Gate 6: pm-team/skills/pre-dev-dependency-map → docs/pre-dev/feature/dependencies.md
├── Gate 7: pm-team/skills/pre-dev-task-breakdown → docs/pre-dev/feature/tasks.md
└── Gate 8: pm-team/skills/pre-dev-subtask-creation → docs/pre-dev/feature/subtasks.md
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
- **Skill Structure**: `default/skills/{name}/SKILL.md` with YAML frontmatter
- **Agent Output**: Required markdown sections per `default/agents/*.md:output_schema`
- **Hook Scripts**: Must output JSON with success/error fields
- **Shared Patterns**: Reference via `default/skills/shared-patterns/*.md`
- **Documentation**: Artifacts in `docs/pre-dev/{feature}/*.md`
- **Monorepo Layout**: Each plugin (`default/`, `team-*/`, `dev-team/`, `ralph-wiggum/`) is self-contained

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
# TDD compliance (default/skills/test-driven-development/SKILL.md:638)
- Test file must exist before implementation
- Test must produce failure output (RED)
- Only then write implementation (GREEN)

# Review compliance (default/skills/requesting-code-review/SKILL.md:188)
- All 3 reviewers must pass
- Critical findings = immediate fix required
- Re-run all reviewers after fixes

# Skill compliance (default/skills/using-ring/SKILL.md:222)
- Check for applicable skills before ANY task
- If skill exists for task → MUST use it
- Announce non-obvious skill usage
```

### Session Context
The system loads at SessionStart (from `default/` plugin):
1. `default/hooks/session-start.sh` - Loads skill quick reference via `generate-skills-ref.py`
2. `using-ring` skill - Injected as mandatory workflow
3. `default/hooks/claude-md-reminder.sh` - Reminds about CLAUDE.md on prompt submit

**Monorepo Context:**
- Repository: Monorepo marketplace with multiple plugin collections
- Active plugins: 5 (`ring-default` v0.7.6, `ring-dev-team` v0.1.1, `ring-finops-team` v0.2.1, `ring-pm-team` v0.1.1, `ralph-wiggum` v0.1.0)
- Core plugin: `default/` (20 skills, 5 agents, 8 commands)
- Developer agents plugin: `dev-team/` (10 specialized developer agents)
- FinOps plugin: `finops-team/` (6 skills, 2 agents)
- Product planning plugin: `pm-team/` (9 skills)
- Ralph plugin: `ralph-wiggum/` (1 skill, 3 commands, Stop hook)
- Reserved plugins: `team-*/` (2 directories)
- Current git branch: `main`
- Remote: `github.com/LerianStudio/ring`

### Documentation Sync Checklist

**IMPORTANT:** When modifying agents, skills, commands, or hooks, check ALL these files for consistency:

```
Root Documentation:
├── CLAUDE.md              # Project instructions (this file)
├── MANUAL.md              # Team quick reference guide
├── README.md              # Public documentation
└── ARCHITECTURE.md        # Architecture diagrams

Plugin Hooks (inject context at session start):
├── default/hooks/session-start.sh        # Skills reference
├── default/hooks/claude-md-reminder.sh   # Agent reminder table
├── dev-team/hooks/session-start.sh     # Developer agents
├── finops-team/hooks/session-start.sh    # FinOps agents
├── pm-team/hooks/session-start.sh   # Pre-dev skills
└── ralph-wiggum/hooks/session-start.sh   # Ralph loop commands

Using-* Skills (plugin introductions):
├── default/skills/using-ring/SKILL.md           # Core workflow + agent list
├── dev-team/skills/using-dev-team/SKILL.md  # Developer agents guide
├── finops-team/skills/using-finops-team/SKILL.md # FinOps guide
├── pm-team/skills/using-pm-team/SKILL.md # Pre-dev workflow
└── ralph-wiggum/skills/using-ralph-wiggum/SKILL.md # Ralph loops guide

Agent Cross-References:
└── default/agents/write-plan.md          # References reviewers
```

**Checklist when adding/modifying:**
- [ ] Agent added? Update hooks, using-* skills, MANUAL.md, README.md
- [ ] Skill added? Update CLAUDE.md architecture, hooks if plugin-specific
- [ ] Command added? Update MANUAL.md, README.md
- [ ] Plugin added? Create hooks/, using-* skill, update marketplace.json
- [ ] Names changed? Search repo for old names: `grep -r "old-name" --include="*.md" --include="*.sh"`

**Always use fully qualified names:** `ring-{plugin}:{component}` (e.g., `ring-default:code-reviewer`)