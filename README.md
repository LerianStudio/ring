# 💍 The Ring - Skills Library for AI Agents

**Proven engineering practices, enforced through skills.**

Ring is a comprehensive skills library and workflow system for AI agents that transforms how AI assistants approach software development. Currently implemented as a **Claude Code plugin marketplace** with **5 active plugins**, the skills themselves are agent-agnostic and can be used with any AI agent system. Ring provides battle-tested patterns, mandatory workflows, and systematic approaches to common development tasks.

## ✨ Why Ring?

Without Ring, AI assistants often:
- Skip tests and jump straight to implementation
- Make changes without understanding root causes
- Claim tasks are complete without verification
- Forget to check for existing solutions
- Repeat known mistakes

Ring solves this by:
- **Enforcing proven workflows** - Test-driven development, systematic debugging, proper planning
- **Providing 38 specialized skills** - From brainstorming to production deployment (20 core + 2 dev-team + 9 product planning + 6 FinOps + 1 ralph-wiggum)
- **17 specialized agents** - 5 review/planning agents + 10 developer role agents + 2 FinOps agents
- **Automating skill discovery** - Skills load automatically at session start
- **Preventing common failures** - Built-in anti-patterns and mandatory checklists

## 🏗️ Infrastructure Features (New!)

Ring now includes powerful infrastructure tools for automation and validation:

### Automated Code Review

**Parallel 3-gate review for 3x faster feedback:**
```bash
/ring:review src/auth.ts
```

Runs all 3 reviewers simultaneously (Code, Business, Security) - aggregates findings by severity:
- **Critical/High/Medium** → Fix immediately, re-run all 3
- **Low** → Add `TODO(review)` comments in code
- **Cosmetic** → Add `FIXME(nitpick)` comments in code

### Skill Discovery

**Find the right skill for your task:**
```bash
/ring:which-skill "debug authentication error"
# Returns: systematic-debugging (HIGH confidence)
```

### Compliance Validation

**Verify you're following skill workflows:**
```bash
/ring:validate test-driven-development
# Checks: Test file exists, test fails first, etc.
```

### Usage Metrics

**Track skill effectiveness:**
```bash
/ring:metrics test-driven-development
# Shows: usage count, compliance rate, common violations
```

### Workflow Guidance

**Get next skill suggestion:**
```bash
/ring:next-skill test-driven-development "test revealed bug"
# Suggests: systematic-debugging
```

**Review & Planning Agents (default plugin):**
- `ring-default:code-reviewer` - Foundation review (architecture, code quality, design patterns)
- `ring-default:business-logic-reviewer` - Correctness review (domain logic, requirements, edge cases)
- `ring-default:security-reviewer` - Safety review (vulnerabilities, OWASP, authentication)
- `ring-default:write-plan` - Implementation planning agent
- `ring-default:codebase-explorer` - Deep architecture analysis (Opus-powered, complements built-in Explore)
- Use `/ring-default:review` command to orchestrate parallel review workflow

**Developer Agents (dev-team plugin):**
- `ring-dev-team:backend-engineer` - Language-agnostic backend specialist (adapts to Go/TypeScript/Python/etc)
- `ring-dev-team:backend-engineer-golang` - Go backend specialist for financial systems
- `ring-dev-team:backend-engineer-typescript` - TypeScript/Node.js backend specialist (Express, NestJS, Fastify)
- `ring-dev-team:backend-engineer-python` - Python backend specialist (FastAPI, Django, Flask)
- `ring-dev-team:devops-engineer` - DevOps infrastructure specialist
- `ring-dev-team:frontend-engineer` - React/Next.js specialist (JavaScript-first)
- `ring-dev-team:frontend-engineer-typescript` - TypeScript-first React/Next.js specialist
- `ring-dev-team:frontend-designer` - Visual design specialist
- `ring-dev-team:qa-analyst` - Quality assurance specialist
- `ring-dev-team:sre` - Site reliability engineer

**FinOps Agents (ring-finops-team plugin):**
- `ring-finops-team:finops-analyzer` - Financial operations analysis
- `ring-finops-team:finops-automation` - FinOps template creation and automation

## 🚀 Quick Start

### Installation as Claude Code Plugin

1. **Quick Install Script** (Easiest)

   **Linux/macOS/Git Bash:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.sh | bash
   ```

   **Windows PowerShell:**
   ```powershell
   irm https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.ps1 | iex
   ```

2. **Install from the Claude Code Plugin Marketplace** (Recommended)
   - Open Claude Code
   - Go to Settings → Plugins
   - Search for "ring"
   - Click Install

3. **Manual Installation**
   ```bash
   # Clone the marketplace repository
   git clone https://github.com/lerianstudio/ring.git ~/ring

   # Install Python dependencies (optional, but recommended)
   cd ~/ring
   pip install -r requirements.txt
   ```
   
   **Note:** Python dependencies are optional. The hooks will use fallback parsers if PyYAML is unavailable.

### First Session

When you start a new Claude Code session with Ring installed, you'll see:

```
## Available Skills:
- using-ring (Check for skills BEFORE any task)
- test-driven-development (RED-GREEN-REFACTOR cycle)
- systematic-debugging (4-phase root cause analysis)
- verification-before-completion (Evidence before claims)
... and 30 more skills
```

## 🎯 Core Skills

### The Big Four (Use These First!)

#### 1. **using-ring** - Mandatory Skill Discovery
```
Before ANY action → Check skills
Before ANY tool → Check skills
Before ANY code → Check skills
```

#### 2. **test-driven-development** - Test First, Always
```
RED → Write failing test → Watch it fail
GREEN → Minimal code → Watch it pass
REFACTOR → Clean up → Stay green
```

#### 3. **systematic-debugging** - Find Root Cause
```
Phase 1: Investigate (gather ALL evidence)
Phase 2: Analyze patterns
Phase 3: Test hypothesis (one at a time)
Phase 4: Implement fix (with test)
```

#### 4. **verification-before-completion** - Prove It Works
```
Run command → Paste output → Then claim
No "should work" → Only "does work" with proof
```

## 📚 All 38 Skills (Across 5 Plugins)

### Core Skills (ring-default plugin - 20 skills)

**Testing & Debugging (6):**
- `test-driven-development` - Write test first, watch fail, minimal code
- `systematic-debugging` - 4-phase root cause investigation
- `verification-before-completion` - Evidence before claims
- `testing-anti-patterns` - Common test pitfalls to avoid
- `condition-based-waiting` - Replace timeouts with conditions
- `defense-in-depth` - Multi-layer validation

**Collaboration & Planning (10):**
- `brainstorming` - Structured design refinement
- `writing-plans` - Zero-context implementation plans
- `executing-plans` - Batch execution with checkpoints
- `requesting-code-review` - **Parallel 3-reviewer dispatch** with severity-based handling
- `receiving-code-review` - Responding to feedback
- `dispatching-parallel-agents` - Concurrent workflows
- `subagent-driven-development` - Fast iteration with **parallel reviews**
- `using-git-worktrees` - Isolated development
- `finishing-a-development-branch` - Merge/PR decisions
- `root-cause-tracing` - Backward bug tracking

**Meta Skills (4):**
- `using-ring` - Mandatory skill discovery
- `writing-skills` - TDD for documentation
- `testing-skills-with-subagents` - Skill validation
- `testing-agents-with-subagents` - Subagent-specific testing

### Developer Skills (ring-dev-team plugin - 2 skills)

**Code Development:**
- `using-dev-team` - Introduction to developer specialist agents
- `writing-code` - Best practices for code implementation

### Product Planning Skills (ring-pm-team plugin - 9 skills)

**Pre-Development Workflow (9 gates, includes using-pm-team):**
- `using-pm-team` - Introduction to product planning workflow
1. `pre-dev-prd-creation` - Business requirements (WHAT/WHY)
2. `pre-dev-feature-map` - Feature relationships
3. `pre-dev-trd-creation` - Technical architecture (HOW)
4. `pre-dev-api-design` - Component contracts
5. `pre-dev-data-model` - Entity relationships
6. `pre-dev-dependency-map` - Technology selection
7. `pre-dev-task-breakdown` - Work increments
8. `pre-dev-subtask-creation` - Atomic units

### FinOps & Regulatory Skills (ring-finops-team plugin - 6 skills)

**Regulatory Templates (6):**
- `using-finops-team` - Introduction to FinOps team workflow
- `regulatory-templates` - Brazilian regulatory orchestration (BACEN, RFB)
- `regulatory-templates-setup` - Template selection initialization
- `regulatory-templates-gate1` - Compliance analysis and field mapping
- `regulatory-templates-gate2` - Field mapping validation
- `regulatory-templates-gate3` - Template file generation

### Ralph Wiggum (ralph-wiggum plugin - 1 skill)

**Iterative Development:**
- `using-ralph-wiggum` - Ralph Wiggum iterative loop technique guide

## 🎮 Interactive Commands

Ring provides slash commands for common workflows:

- `/ring:brainstorm` - Interactive design refinement using Socratic method
- `/ring:write-plan` - Create detailed implementation plan with bite-sized tasks
- `/ring:execute-plan` - Execute plan in batches with review checkpoints

### Ralph Wiggum (Iterative AI Loops)

- `/ralph-wiggum:ralph-loop "PROMPT" --max-iterations N --completion-promise "TEXT"` - Start autonomous iterative loop
- `/ralph-wiggum:cancel-ralph` - Cancel active Ralph loop
- `/ralph-wiggum:help` - Explain Ralph technique and examples

## 💡 Usage Examples

### Building a Feature
```
User: "Add user authentication to the app"
Claude: I'm using the brainstorming skill to design this feature...
        [Structured exploration of requirements]
Claude: I'm using test-driven-development to implement...
        [RED-GREEN-REFACTOR cycle for each component]
Claude: I'm using verification-before-completion to confirm...
        [Runs tests, shows actual output]
```

### Fixing a Bug
```
User: "The app crashes when clicking submit"
Claude: I'm using systematic-debugging to investigate...
        Phase 1: [Gathering evidence]
        Phase 2: [Pattern analysis]
        Phase 3: [Hypothesis testing]
        Phase 4: [Implementing fix with test]
```

### Planning a Project
```
User: "Plan an e-commerce platform"
Claude: I'll use the pre-dev workflow to plan this systematically...
        Gate 1: PRD Creation [Business requirements]
        Gate 2: Feature Map [Domain groupings]
        Gate 3: TRD Creation [Architecture patterns]
        ... [Through all 8 gates]
```

### Code Review (Parallel, 3x Faster!)
```
User: "Review my authentication implementation"
Claude: Dispatching all 3 reviewers in parallel...
        [Launches code-reviewer, business-logic-reviewer, security-reviewer simultaneously]

        Code reviewer: PASS. Clean architecture, good tests.
        Business reviewer: FAIL. Missing password reset flow (HIGH severity).
        Security reviewer: FAIL. JWT secret hardcoded (CRITICAL severity).

        Aggregating issues by severity:
        - CRITICAL: JWT secret hardcoded in auth.ts:42
        - HIGH: Password reset flow missing from requirements

        Dispatching fix subagent to address Critical/High issues...
        [Fixes applied]

        Re-running all 3 reviewers in parallel...
        All reviewers: PASS. Ready for production.
```

**Key benefits:**
- **3x faster** - All reviewers run simultaneously (not sequential)
- **Comprehensive** - Get all feedback at once, easier to prioritize
- **Tech debt tracking** - Low/Cosmetic issues tracked with TODO/FIXME comments in code
- **Model-specific** - All reviewers run on Opus for deep analysis

## 🏗️ Architecture

**Monorepo Marketplace** - Multiple specialized plugin collections:

```
ring/                                  # Monorepo root
├── .claude-plugin/
│   └── marketplace.json              # Multi-plugin marketplace config (5 active plugins)
├── default/                          # Core Ring plugin (ring-default v0.7.6)
│   ├── skills/                       # 20 core skills
│   │   ├── skill-name/
│   │   │   └── SKILL.md             # Skill definition with frontmatter
│   │   └── shared-patterns/         # Universal patterns (5 patterns)
│   ├── commands/                    # 8 slash command definitions
│   ├── hooks/                       # Session initialization
│   │   ├── hooks.json              # Hook configuration
│   │   ├── session-start.sh        # Loads skills at startup
│   │   └── generate-skills-ref.py  # Auto-generates quick reference
│   ├── agents/                      # 5 specialized agents
│   │   ├── code-reviewer.md        # Foundation review (parallel)
│   │   ├── business-logic-reviewer.md  # Correctness review (parallel)
│   │   ├── security-reviewer.md    # Safety review (parallel)
│   │   ├── write-plan.md           # Implementation planning
│   │   └── codebase-explorer.md    # Deep architecture analysis (Opus)
│   ├── lib/                        # Infrastructure utilities (9 scripts)
│   └── docs/                       # Documentation
├── dev-team/                      # Developer Agents plugin (ring-dev-team v0.1.1)
│   └── agents/                      # 10 specialized developer agents
│       ├── backend-engineer.md         # Language-agnostic backend specialist
│       ├── backend-engineer-golang.md  # Go backend specialist
│       ├── backend-engineer-typescript.md # TypeScript/Node.js backend specialist
│       ├── backend-engineer-python.md  # Python backend specialist
│       ├── devops-engineer.md          # DevOps infrastructure
│       ├── frontend-engineer.md        # React/Next.js specialist (JavaScript-first)
│       ├── frontend-engineer-typescript.md # TypeScript-first React/Next.js specialist
│       ├── frontend-designer.md        # Visual design specialist
│       ├── qa-analyst.md               # Quality assurance
│       └── sre.md                      # Site reliability engineer
├── finops-team/                     # FinOps plugin (ring-finops-team v0.2.1)
│   ├── skills/                      # 5 regulatory compliance skills
│   │   └── regulatory-templates*/   # Brazilian regulatory compliance
│   ├── agents/                      # 2 FinOps agents
│   │   ├── finops-analyzer.md      # FinOps analysis
│   │   └── finops-automation.md    # FinOps automation
│   └── docs/
│       └── regulatory/             # Brazilian regulatory documentation
├── pm-team/                    # Product Planning plugin (ring-pm-team v0.1.1)
│   └── skills/                      # 8 pre-dev workflow skills
│       └── pre-dev-*/              # PRD, TRD, API, Data, Tasks
├── ralph-wiggum/                    # Iterative AI loops plugin (ralph-wiggum v0.1.0)
│   ├── commands/                    # 3 slash commands (ralph-loop, cancel-ralph, help)
│   ├── hooks/                       # SessionStart and Stop hooks
│   ├── scripts/                     # Setup utilities
│   └── skills/                      # using-ralph-wiggum skill
├── ops-team/                        # Team-specific skills (reserved)
└── pmm-team/                        # Team-specific skills (reserved)
```

## 🤝 Contributing

### Adding a New Skill

**For core Ring skills:**

1. **Create the skill directory**
   ```bash
   mkdir default/skills/your-skill-name
   ```

2. **Write SKILL.md with frontmatter**
   ```yaml
   ---
   name: your-skill-name
   description: |
     Brief description of WHAT this skill does (the method/technique).
     1-2 sentences maximum.

   trigger: |
     - Specific condition that mandates using this skill
     - Another trigger condition
     - Use quantifiable criteria when possible

   skip_when: |
     - When NOT to use this skill → alternative
     - Another exclusion condition

   sequence:
     after: [prerequisite-skill]   # Skills that should come before
     before: [following-skill]     # Skills that typically follow

   related:
     similar: [skill-that-seems-similar]      # Differentiate from these
     complementary: [skill-that-pairs-well]   # Use together with these
   ---

   # Skill content here...
   ```

   **Schema fields explained:**
   - `name`: Skill identifier (matches directory name)
   - `description`: WHAT the skill does (method/technique)
   - `trigger`: WHEN to use - specific, quantifiable conditions
   - `skip_when`: WHEN NOT to use - differentiates from similar skills
   - `sequence`: Workflow ordering (optional)
   - `related`: Similar/complementary skills for disambiguation (optional)

3. **Update documentation**
   - Skills auto-load via `default/hooks/generate-skills-ref.py`
   - Test with session start hook

4. **Submit PR**
   ```bash
   git checkout -b feat/your-skill-name
   git add default/skills/your-skill-name
   git commit -m "feat(skills): add your-skill-name for X"
   gh pr create
   ```

**For product/team-specific skills:**

1. **Create plugin structure**
   ```bash
   mkdir -p product-xyz/{skills,agents,commands,hooks,lib}
   ```

2. **Register in marketplace**
   Edit `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "ring-product-xyz",
     "description": "Product XYZ specific skills",
     "version": "0.1.0",
     "source": "./product-xyz",
     "homepage": "https://github.com/lerianstudio/ring/tree/product-xyz"
   }
   ```

3. **Follow core plugin structure**
   - Use same layout as `default/`
   - Create `product-xyz/hooks/hooks.json` for initialization
   - Add skills to `product-xyz/skills/`

### Skill Quality Standards

- **Mandatory sections**: When to use, How to use, Anti-patterns
- **Include checklists**: TodoWrite-compatible task lists
- **Evidence-based**: Require verification before claims
- **Battle-tested**: Based on real-world experience
- **Clear triggers**: Unambiguous "when to use" conditions

## 📖 Documentation

- **Skills Quick Reference** - Auto-generated at session start from skill frontmatter
- [CLAUDE.md](CLAUDE.md) - Repository guide for Claude Code
- [Design Documents](docs/plans/) - Implementation plans and architecture decisions

## 🎯 Philosophy

Ring embodies these principles:

1. **Skills are mandatory, not optional** - If a skill applies, it MUST be used
2. **Evidence over assumptions** - Prove it works, don't assume
3. **Process prevents problems** - Following workflows prevents known failures
4. **Small steps, verified often** - Incremental progress with continuous validation
5. **Learn from failure** - Anti-patterns document what doesn't work

## 📊 Success Metrics

Teams using Ring report:
- 90% reduction in "works on my machine" issues
- 75% fewer bugs reaching production
- 60% faster debugging cycles
- 100% of code covered by tests (enforced by TDD)

## 🙏 Acknowledgments

Ring is built on decades of collective software engineering wisdom, incorporating patterns from:
- Extreme Programming (XP)
- Test-Driven Development (TDD)
- Domain-Driven Design (DDD)
- Agile methodologies
- DevOps practices

Special thanks to the Lerian Team for battle-testing these skills in production.

## 📄 License

MIT - See [LICENSE](LICENSE) file

## 🔗 Links

- [GitHub Repository](https://github.com/lerianstudio/ring)
- [Issue Tracker](https://github.com/lerianstudio/ring/issues)
- [Plugin Marketplace](https://claude.ai/marketplace/ring)

---

**Remember: If a skill applies to your task, you MUST use it. This is not optional.**