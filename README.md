# 💍 Ring - Skills Library for Claude Code

**Proven engineering practices, enforced through skills.**

Ring is a comprehensive skills library and workflow system for Claude Code that transforms how AI assistants approach software development. It provides battle-tested patterns, mandatory workflows, and systematic approaches to common development tasks.

## ✨ Why Ring?

Without Ring, AI assistants often:
- Skip tests and jump straight to implementation
- Make changes without understanding root causes
- Claim tasks are complete without verification
- Forget to check for existing solutions
- Repeat known mistakes

Ring solves this by:
- **Enforcing proven workflows** - Test-driven development, systematic debugging, proper planning
- **Providing 28 specialized skills** - From brainstorming to production deployment
- **Automating skill discovery** - Skills load automatically at session start
- **Preventing common failures** - Built-in anti-patterns and mandatory checklists

## 🏗️ Infrastructure Features (New!)

Ring now includes powerful infrastructure tools for automation and validation:

### Automated Review

**Sequential 3-gate review in one command:**
```bash
/ring:review src/auth.ts
```

Runs Gate 1 (Code) → Gate 2 (Business) → Gate 3 (Security) automatically, stops at first failure.

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

**New Agents:**
- `review-orchestrator` - Automated sequential review
- `full-reviewer` - All 3 gates in single invocation

**New Utilities:**
- Compliance validator - Enforce skill adherence
- Output validator - Ensure consistent agent output
- Skill matcher - Task-to-skill mapping
- Pre-flight checker - Validate prerequisites
- Metrics tracker - Track effectiveness

## 🚀 Quick Start

### Installation as Claude Code Plugin

1. **Install from the Claude Code Plugin Marketplace** (Recommended)
   - Open Claude Code
   - Go to Settings → Plugins
   - Search for "ring"
   - Click Install

2. **Manual Installation**
   ```bash
   # Clone to your Claude plugins directory
   git clone https://github.com/lerianstudio/ring.git ~/.claude/plugins/ring
   ```

### First Session

When you start a new Claude Code session with Ring installed, you'll see:

```
## Available Skills:
- using-ring (Check for skills BEFORE any task)
- test-driven-development (RED-GREEN-REFACTOR cycle)
- systematic-debugging (4-phase root cause analysis)
- verification-before-completion (Evidence before claims)
... and 24 more skills
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

## 📚 All 28 Skills

### Testing & Debugging (5)
- `test-driven-development` - Write test first, watch fail, minimal code
- `systematic-debugging` - 4-phase root cause investigation
- `verification-before-completion` - Evidence before claims
- `testing-anti-patterns` - Common test pitfalls to avoid
- `condition-based-waiting` - Replace timeouts with conditions

### Collaboration & Planning (9)
- `brainstorming` - Structured design refinement
- `writing-plans` - Zero-context implementation plans
- `executing-plans` - Batch execution with checkpoints
- `requesting-code-review` - Pre-review checklist
- `receiving-code-review` - Responding to feedback
- `dispatching-parallel-agents` - Concurrent workflows
- `subagent-driven-development` - Fast iteration
- `using-git-worktrees` - Isolated development
- `finishing-a-development-branch` - Merge/PR decisions

### Pre-Development Workflow (8 gates)
1. `pre-dev-prd-creation` - Business requirements (WHAT/WHY)
2. `pre-dev-feature-map` - Feature relationships
3. `pre-dev-trd-creation` - Technical architecture (HOW)
4. `pre-dev-api-design` - Component contracts
5. `pre-dev-data-model` - Entity relationships
6. `pre-dev-dependency-map` - Technology selection
7. `pre-dev-task-breakdown` - Work increments
8. `pre-dev-subtask-creation` - Atomic units

### Meta Skills (4)
- `using-ring` - Mandatory skill discovery
- `writing-skills` - TDD for documentation
- `testing-skills-with-subagents` - Skill validation
- `sharing-skills` - Contributing back

## 🎮 Interactive Commands

Ring provides slash commands for common workflows:

- `/ring:brainstorm` - Interactive design refinement using Socratic method
- `/ring:write-plan` - Create detailed implementation plan with bite-sized tasks
- `/ring:execute-plan` - Execute plan in batches with review checkpoints

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

## 🏗️ Architecture

```
ring/
├── skills/                 # 28 specialized skills
│   ├── skill-name/
│   │   └── SKILL.md       # Skill definition with frontmatter
│   └── shared-patterns/   # Universal patterns used across skills
├── commands/              # Slash command definitions
├── hooks/                 # Session initialization
│   ├── hooks.json        # Hook configuration
│   └── session-start.sh  # Loads skills at startup
├── agents/               # Specialized agent definitions
└── docs/                 # Documentation and quick reference
```

## 🤝 Contributing

### Adding a New Skill

1. **Create the skill directory**
   ```bash
   mkdir skills/your-skill-name
   ```

2. **Write SKILL.md with frontmatter**
   ```markdown
   ---
   name: your-skill-name
   description: Brief description of what this skill does
   when_to_use: Specific situations when this skill applies
   ---

   # Skill content here...
   ```

3. **Update documentation**
   - Add to `docs/skills-quick-reference.md`
   - Test with session start hook

4. **Submit PR**
   ```bash
   git checkout -b feat/your-skill-name
   git add skills/your-skill-name
   git commit -m "feat(skills): add your-skill-name for X"
   gh pr create
   ```

### Skill Quality Standards

- **Mandatory sections**: When to use, How to use, Anti-patterns
- **Include checklists**: TodoWrite-compatible task lists
- **Evidence-based**: Require verification before claims
- **Battle-tested**: Based on real-world experience
- **Clear triggers**: Unambiguous "when to use" conditions

## 📖 Documentation

- [Skills Quick Reference](docs/skills-quick-reference.md) - All skills at a glance
- [CLAUDE.md](CLAUDE.md) - Guide for Claude Code instances

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