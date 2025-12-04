# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Ring is a comprehensive skills library and workflow system for AI agents that enforces proven software engineering practices through mandatory workflows, parallel code review, and systematic pre-development planning. Currently implemented as a Claude Code plugin marketplace with **6 active plugins**, the skills are agent-agnostic and reusable across different AI systems.

**Active Plugins:**
- **ring-default**: 21 core skills, 7 slash commands, 5 specialized agents
- **ring-dev-team**: 10 development skills, 5 slash commands, 9 developer agents (Backend [generic], Backend Go, Backend TypeScript, DevOps, Frontend [generic], Frontend TypeScript, Frontend Designer, QA, SRE)
- **ring-finops-team**: 6 regulatory skills, 2 FinOps agents
- **ring-pm-team**: 10 product planning skills, 3 research agents, 2 slash commands
- **ralph-wiggum**: 1 skill for iterative AI development loops using Stop hooks
- **ring-tw-team**: 7 technical writing skills, 3 slash commands, 3 documentation agents (Functional Writer, API Writer, Docs Reviewer)

**Note:** Plugin versions are managed in `.claude-plugin/marketplace.json`

**Total: 55 skills (21 + 10 + 6 + 10 + 1 + 7) across 6 plugins**

The architecture uses markdown-based skill definitions with YAML frontmatter, auto-discovered at session start via hooks, and executed through Claude Code's native Skill/Task tools.

## Installation

Ring supports multiple AI platforms. The installer auto-detects installed platforms and transforms content appropriately.

### Supported Platforms

| Platform | Install Path | Format | Components |
|----------|-------------|--------|------------|
| Claude Code | `~/.claude/` | Native | skills, agents, commands, hooks |
| Factory AI | `~/.factory/` | Transformed | skills, droids, commands |
| Cursor | `~/.cursor/` | Transformed | .cursorrules, workflows |
| Cline | `~/.cline/` | Transformed | prompts |

### Quick Install

```bash
# Interactive installer (Linux/macOS/Git Bash)
curl -fsSL https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.sh | bash

# Interactive installer (Windows PowerShell)
irm https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.ps1 | iex

# Or clone and run locally
git clone https://github.com/lerianstudio/ring.git ~/ring
cd ~/ring
./installer/install-ring.sh
```

### Platform-Specific Installation

```bash
# Install to specific platform
./installer/install-ring.sh install --platforms claude
./installer/install-ring.sh install --platforms factory
./installer/install-ring.sh install --platforms cursor
./installer/install-ring.sh install --platforms cline

# Install to multiple platforms
./installer/install-ring.sh install --platforms claude,cursor,cline

# Auto-detect and install all
./installer/install-ring.sh install --platforms auto
```

### Installer Commands

```bash
./installer/install-ring.sh install   # Install to platforms
./installer/install-ring.sh update    # Update existing installation
./installer/install-ring.sh sync      # Sync only changed files
./installer/install-ring.sh list      # List installed platforms
./installer/install-ring.sh check     # Check for updates
./installer/install-ring.sh uninstall # Remove from platforms
./installer/install-ring.sh detect    # Detect available platforms
```

See `docs/platforms/` for platform-specific guides.

## Architecture

**Monorepo Structure** - Marketplace with multiple plugin collections:

```
ring/                                  # Monorepo root
├── .claude-plugin/
│   └── marketplace.json              # Multi-plugin marketplace config (7 active plugins)
├── default/                          # Core Ring plugin (ring-default)
│   ├── skills/                       # 21 core skills
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
│   ├── commands/                    # 7 slash commands
│   │   ├── codereview.md           # /ring-default:codereview - dispatch 3 parallel reviewers
│   │   ├── brainstorm.md           # /ring-default:brainstorm - interactive design
│   │   └── codify.md               # /ring-default:codify - document solved problems
│   ├── hooks/                      # Session lifecycle
│   │   ├── hooks.json             # SessionStart, UserPromptSubmit config
│   │   ├── session-start.sh       # Load skills quick reference
│   │   ├── generate-skills-ref.py # Parse SKILL.md frontmatter
│   │   └── claude-md-reminder.sh  # CLAUDE.md reminder on prompt submit
│   └── docs/                      # Documentation
├── dev-team/                      # Developer Agents plugin (ring-dev-team)
│   ├── skills/                    # 1 developer skill
│   │   └── using-dev-team/        # Plugin introduction
│   └── agents/                    # 9 specialized developer agents
│       ├── backend-engineer.md             # Backend specialist (language agnostic)
│       ├── backend-engineer-golang.md      # Go backend specialist
│       ├── backend-engineer-typescript.md  # TypeScript/Node.js backend specialist
│       ├── devops-engineer.md              # DevOps infrastructure specialist
│       ├── frontend-engineer.md            # Frontend specialist (language agnostic)
│       ├── frontend-engineer-typescript.md # TypeScript/React/Next.js specialist
│       ├── frontend-designer.md            # Visual design specialist
│       ├── qa-analyst.md                   # Quality assurance specialist
│       └── sre.md                          # Site reliability engineer
├── finops-team/                   # FinOps plugin (ring-finops-team)
│   ├── skills/                    # 6 regulatory compliance skills
│   │   └── regulatory-templates*/ # Brazilian regulatory compliance (BACEN, RFB)
│   ├── agents/                    # 2 FinOps agents
│   │   ├── finops-analyzer.md    # Financial operations analysis
│   │   └── finops-automation.md  # FinOps automation
│   └── docs/
│       └── regulatory/           # Brazilian regulatory documentation
├── pm-team/                       # Product Planning plugin (ring-pm-team)
│   ├── commands/                  # 2 slash commands
│   │   ├── pre-dev-feature.md    # /ring-pm-team:pre-dev-feature - 4-gate workflow
│   │   └── pre-dev-full.md       # /ring-pm-team:pre-dev-full - 9-gate workflow
│   ├── agents/                    # 3 research agents
│   │   ├── repo-research-analyst.md      # Codebase pattern research
│   │   ├── best-practices-researcher.md  # Web/Context7 research
│   │   └── framework-docs-researcher.md  # Tech stack documentation
│   └── skills/                    # 10 pre-dev workflow skills
│       └── pre-dev-*/            # Research→PRD→TRD→API→Data→Tasks
├── ralph-wiggum/                  # Iterative AI loops plugin (ralph-wiggum)
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
├── tw-team/                       # Technical Writing plugin (ring-tw-team)
│   ├── skills/                    # 7 documentation skills
│   │   ├── using-tw-team/        # Plugin introduction
│   │   ├── writing-functional-docs/ # Functional doc patterns
│   │   ├── writing-api-docs/     # API reference patterns
│   │   ├── documentation-structure/ # Doc hierarchy
│   │   ├── voice-and-tone/       # Voice/tone guidelines
│   │   ├── documentation-review/ # Quality checklist
│   │   └── api-field-descriptions/ # Field description patterns
│   ├── agents/                    # 3 technical writing agents
│   │   ├── functional-writer.md  # Guides, tutorials, conceptual docs
│   │   ├── api-writer.md         # API reference documentation
│   │   └── docs-reviewer.md      # Documentation quality review
│   ├── commands/                  # 3 slash commands
│   │   ├── write-guide.md        # /ring-tw-team:write-guide
│   │   ├── write-api.md          # /ring-tw-team:write-api
│   │   └── review-docs.md        # /ring-tw-team:review-docs
│   └── hooks/                     # Session lifecycle
│       ├── hooks.json            # Hook configuration
│       └── session-start.sh      # Context injection
├── installer/                     # Multi-platform installer
│   ├── ring_installer/           # Python package
│   │   ├── adapters/             # Platform adapters (claude, factory, cursor, cline)
│   │   ├── transformers/         # Content transformers
│   │   ├── utils/                # Utilities (fs, version, platform_detect)
│   │   └── core.py               # Installation logic
│   ├── tests/                    # Test suite
│   ├── install-ring.sh           # Bash entry point
│   └── install-ring.ps1          # PowerShell entry point
├── docs/
│   ├── plans/                    # Implementation plans
│   └── platforms/                # Platform-specific guides
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
Skill tool: "ring-default:test-driven-development"  # Enforce TDD workflow
Skill tool: "ring-default:systematic-debugging"     # Debug with 4-phase analysis
Skill tool: "ring-default:using-ring"              # Load mandatory workflows

# Slash commands
/ring-default:codereview          # Dispatch 3 parallel reviewers
/ring-default:brainstorm          # Socratic design refinement
/ring-pm-team:pre-dev-feature     # <2 day features (4 gates)
/ring-pm-team:pre-dev-full        # ≥2 day features (9 gates)
/ring-default:execute-plan        # Batch execution with checkpoints
/ring-default:worktree            # Create isolated development branch

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
3. Test with `Skill tool: "ring-default:testing-skills-with-subagents"`
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
- `using-dev-team` → 9 specialist developer agents
- Auto-loads when ring-dev-team plugin is enabled
- Located: `dev-team/skills/using-dev-team/SKILL.md`
- Agents (invoke as `ring-dev-team:{agent-name}`): backend-engineer, backend-engineer-golang, backend-engineer-typescript, devops-engineer, frontend-engineer, frontend-engineer-typescript, frontend-designer, qa-analyst, sre

**Ring FinOps Team Plugin:**
- `using-finops-team` → 2 FinOps agents for Brazilian compliance
- Auto-loads when ring-finops-team plugin is enabled
- Located: `finops-team/skills/using-finops-team/SKILL.md`
- Agents (invoke as `ring-finops-team:{agent-name}`): finops-analyzer (compliance analysis), finops-automation (template generation)

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

**Ring TW Team Plugin:**
- `using-tw-team` → 3 technical writing agents for documentation
- Auto-loads when ring-tw-team plugin is enabled
- Located: `tw-team/skills/using-tw-team/SKILL.md`
- Agents (invoke as `ring-tw-team:{agent-name}`): functional-writer (guides), api-writer (API reference), docs-reviewer (quality review)
- Commands: write-guide, write-api, review-docs

**Hook Configuration:**
- Each plugin has: `{plugin}/hooks/hooks.json` + `{plugin}/hooks/session-start.sh`
- SessionStart hook executes, outputs additionalContext with skill reference
- Only plugins in marketplace.json get loaded (conditional)

### Creating Review Agents
1. Add to `default/agents/your-reviewer.md` with output_schema
2. Reference in `default/skills/requesting-code-review/SKILL.md:85`
3. Dispatch via Task tool with `subagent_type="ring-default:your-reviewer"`
4. Must run in parallel with other reviewers (single message, multiple Tasks)

### Pre-Dev Workflow
```
Simple (<2 days): /ring-pm-team:pre-dev-feature
├── Gate 0: pm-team/skills/pre-dev-research → docs/pre-dev/feature/research.md (parallel agents)
├── Gate 1: pm-team/skills/pre-dev-prd-creation → docs/pre-dev/feature/PRD.md
├── Gate 2: pm-team/skills/pre-dev-trd-creation → docs/pre-dev/feature/TRD.md
└── Gate 3: pm-team/skills/pre-dev-task-breakdown → docs/pre-dev/feature/tasks.md

Complex (≥2 days): /ring-pm-team:pre-dev-full
├── Gate 0: Research Phase (3 parallel agents: repo-research, best-practices, framework-docs)
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
review1 = Task("ring-default:code-reviewer")      # 20 min
review2 = Task("ring-default:business-logic-reviewer")     # 20 min
review3 = Task("ring-default:security-reviewer")  # 20 min

# Run parallel (20 min total):
Task.parallel([
    ("ring-default:code-reviewer", prompt),
    ("ring-default:business-logic-reviewer", prompt),
    ("ring-default:security-reviewer", prompt)
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
- Commands: `/ring-{plugin}:{action}` format (e.g., `/ring-default:brainstorm`, `/ring-pm-team:pre-dev-feature`)
- Hooks: `{event}-{purpose}.sh` format

#### Agent/Skill/Command Invocation
- **ALWAYS use fully qualified names**: `ring-{plugin}:{component}`
- **Examples:**
  - ✅ Correct: `ring-default:code-reviewer`
  - ✅ Correct: `ring-dev-team:backend-engineer-golang`
  - ❌ Wrong: `ring:code-reviewer` (ambiguous shorthand)
  - ❌ Wrong: `backend-engineer-golang` (missing plugin prefix)
- **Rationale:** Prevents ambiguity in multi-plugin environments

### Agent Output Schema Archetypes

Agents use standard output schema patterns based on their purpose:

**Implementation Schema** (for agents that write code/configs):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "Summary"
      pattern: "^## Summary"
      required: true
    - name: "Implementation"
      pattern: "^## Implementation"
      required: true
    - name: "Files Changed"
      pattern: "^## Files Changed"
      required: true
    - name: "Testing"
      pattern: "^## Testing"
      required: true
    - name: "Next Steps"
      pattern: "^## Next Steps"
      required: true
```

**Used by:** All backend engineers (`ring-dev-team:backend-engineer`, `ring-dev-team:backend-engineer-golang`, `ring-dev-team:backend-engineer-typescript`), all frontend engineers except designer (`ring-dev-team:frontend-engineer`, `ring-dev-team:frontend-engineer-typescript`), `ring-dev-team:devops-engineer`, `ring-dev-team:qa-analyst`, `ring-dev-team:sre`, `ring-finops-team:finops-automation`

**Analysis Schema** (for agents that analyze and recommend):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "Analysis"
      pattern: "^## Analysis"
      required: true
    - name: "Findings"
      pattern: "^## Findings"
      required: true
    - name: "Recommendations"
      pattern: "^## Recommendations"
      required: true
    - name: "Next Steps"
      pattern: "^## Next Steps"
      required: true
```

**Used by:** `ring-dev-team:frontend-designer`, `ring-finops-team:finops-analyzer`

**Reviewer Schema** (for code review agents):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "VERDICT"
      pattern: "^## VERDICT: (PASS|FAIL|NEEDS_DISCUSSION)$"
      required: true
    - name: "Summary"
      pattern: "^## Summary"
      required: true
    - name: "Issues Found"
      pattern: "^## Issues Found"
      required: true
    - name: "Categorized Issues"
      pattern: "^### (Critical|High|Medium|Low)"
      required: false
    - name: "What Was Done Well"
      pattern: "^## What Was Done Well"
      required: true
    - name: "Next Steps"
      pattern: "^## Next Steps"
      required: true
```

**Used by:** `ring-default:code-reviewer`, `ring-default:business-logic-reviewer`, `ring-default:security-reviewer`

**Note:** `ring-default:business-logic-reviewer` and `ring-default:security-reviewer` extend the base Reviewer Schema with additional domain-specific required sections:
- `ring-default:business-logic-reviewer` adds: "Mental Execution Analysis", "Business Requirements Coverage", "Edge Cases Analysis"
- `ring-default:security-reviewer` adds: "OWASP Top 10 Coverage", "Compliance Status"

**Exploration Schema** (for deep codebase analysis):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "EXPLORATION SUMMARY"
      pattern: "^## EXPLORATION SUMMARY$"
      required: true
    - name: "KEY FINDINGS"
      pattern: "^## KEY FINDINGS$"
      required: true
    - name: "ARCHITECTURE INSIGHTS"
      pattern: "^## ARCHITECTURE INSIGHTS$"
      required: true
    - name: "RELEVANT FILES"
      pattern: "^## RELEVANT FILES$"
      required: true
    - name: "RECOMMENDATIONS"
      pattern: "^## RECOMMENDATIONS$"
      required: true
```

**Used by:** `ring-default:codebase-explorer`

**Planning Schema** (for implementation planning):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "Goal"
      pattern: "^\\*\\*Goal:\\*\\*"
      required: true
    - name: "Architecture"
      pattern: "^\\*\\*Architecture:\\*\\*"
      required: true
    - name: "Tech Stack"
      pattern: "^\\*\\*Tech Stack:\\*\\*"
      required: true
    - name: "Global Prerequisites"
      pattern: "^\\*\\*Global Prerequisites:\\*\\*"
      required: true
    - name: "Task"
      pattern: "^### Task \\d+:"
      required: true
```

**Used by:** `ring-default:write-plan`

### Anti-Patterns to Avoid
1. **Never skip using-ring** - It's mandatory, not optional
2. **Never run reviewers sequentially** - Always dispatch in parallel
3. **Never modify generated skill reference** - Auto-generated from frontmatter
4. **Never skip TDD's RED phase** - Test must fail before implementation
5. **Never ignore skill when applicable** - "Simple task" is not an excuse
6. **Never use panic() in Go** - Error handling required
7. **Never commit incomplete code** - No "TODO: implement" comments
8. **Never commit manually** - Always use `/ring-default:commit` command

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

# Commit compliance (default/commands/commit.md)
- ALWAYS use /ring-default:commit for all commits
- Never write git commit commands manually
- Command enforces: conventional commits, trailers, no emoji signatures
```

### Session Context
The system loads at SessionStart (from `default/` plugin):
1. `default/hooks/session-start.sh` - Loads skill quick reference via `generate-skills-ref.py`
2. `using-ring` skill - Injected as mandatory workflow
3. `default/hooks/claude-md-reminder.sh` - Reminds about CLAUDE.md on prompt submit

**Monorepo Context:**
- Repository: Monorepo marketplace with multiple plugin collections
- Active plugins: 6 (`ring-default`, `ring-dev-team`, `ring-finops-team`, `ring-pm-team`, `ralph-wiggum`, `ring-tw-team`)
- Plugin versions: See `.claude-plugin/marketplace.json`
- Core plugin: `default/` (21 skills, 5 agents, 7 commands)
- Developer agents plugin: `dev-team/` (10 skills, 9 agents, 5 commands)
- FinOps plugin: `finops-team/` (6 skills, 2 agents)
- Product planning plugin: `pm-team/` (10 skills, 3 research agents, 2 commands)
- Ralph plugin: `ralph-wiggum/` (1 skill, 3 commands, Stop hook)
- Technical writing plugin: `tw-team/` (7 skills, 3 agents, 3 commands)
- Reserved plugins: `ops-team/`, `pmm-team/` (2 directories)
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
├── dev-team/hooks/session-start.sh       # Developer agents
├── finops-team/hooks/session-start.sh    # FinOps agents
├── pm-team/hooks/session-start.sh        # Pre-dev skills
├── ralph-wiggum/hooks/session-start.sh   # Ralph loop commands
└── tw-team/hooks/session-start.sh        # Technical writing agents

Using-* Skills (plugin introductions):
├── default/skills/using-ring/SKILL.md           # Core workflow + agent list
├── dev-team/skills/using-dev-team/SKILL.md      # Developer agents guide
├── finops-team/skills/using-finops-team/SKILL.md # FinOps guide
├── pm-team/skills/using-pm-team/SKILL.md        # Pre-dev workflow
├── ralph-wiggum/skills/using-ralph-wiggum/SKILL.md # Ralph loops guide
└── tw-team/skills/using-tw-team/SKILL.md        # Technical writing guide

Agent Cross-References:
└── default/agents/write-plan.md          # References reviewers
```

**Checklist when adding/modifying:**
- [ ] Agent added? Update hooks, using-* skills, MANUAL.md, README.md
- [ ] Skill added? Update CLAUDE.md architecture, hooks if plugin-specific
- [ ] Command added? Update MANUAL.md, README.md
- [ ] Plugin added? Create hooks/, using-* skill, update marketplace.json
- [ ] Names changed? Search repo for old names: `grep -r "old-name" --include="*.md" --include="*.sh"`

**Naming Convention Enforcement:**
- [ ] All agent invocations use `ring-{plugin}:agent-name` format
- [ ] All skill invocations use `ring-{plugin}:skill-name` format
- [ ] All command invocations use `/ring-{plugin}:command-name` format
- [ ] No `ring:` shorthand used (except in historical examples with context)
- [ ] No bare agent/skill names in invocation contexts

**Always use fully qualified names:** `ring-{plugin}:{component}` (e.g., `ring-default:code-reviewer`)
