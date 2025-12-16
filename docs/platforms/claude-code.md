# Ring for Claude Code

Claude Code is the **native platform** for Ring. All skills, agents, commands, and hooks are designed primarily for Claude Code and require no transformation.

## Installation

```bash
# Interactive installer
./installer/install-ring.sh

# Direct install
./installer/install-ring.sh install --platforms claude

# Via curl (remote)
curl -fsSL https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.sh | bash
```

## Installation Path

Ring installs to: `~/.claude/`

```
~/.claude/
├── plugins/
│   └── ring/                    # Ring marketplace
│       ├── default/             # Core plugin
│       │   ├── skills/          # 20 core skills
│       │   ├── agents/          # 5 specialized agents
│       │   ├── commands/        # 6 slash commands
│       │   └── hooks/           # Session lifecycle hooks
│       ├── dev-team/            # Developer agents plugin
│       ├── pm-team/             # Product planning plugin
│       ├── finops-team/         # FinOps plugin
│       └── tw-team/             # Technical writing plugin
└── .ring-manifest.json          # Installation tracking
```

## Components

### Skills (46 total)

Skills are markdown files with YAML frontmatter that define workflows, processes, and best practices. They auto-load at session start.

**Invocation:**
```
Skill tool: "test-driven-development"
Skill tool: "systematic-debugging"
```

**Structure:**
```yaml
---
name: skill-name
description: |
  What this skill does
trigger: |
  - When to use this skill
skip_when: |
  - When NOT to use
---

# Skill Content
...
```

### Agents (20 total)

Agents are specialized AI personas with defined expertise and output schemas.

**Invocation:**
```
Task tool with subagent_type="code-reviewer"
Task tool with subagent_type="backend-engineer-golang"
```

**Categories** (invoke as `ring-{plugin}:{agent-name}`):
- **Review agents**: code-reviewer, business-logic-reviewer, security-reviewer
- **Planning agents**: write-plan, codebase-explorer
- **Developer agents**: 9 language/role specialists (*)
- **FinOps agents**: finops-analyzer, finops-automation
- **TW agents**: functional-writer, api-writer, docs-reviewer

### Commands (14 total)

Slash commands provide quick access to common workflows.

**Examples:**
```bash
/codereview          # Parallel 3-reviewer dispatch
/brainstorm          # Socratic design refinement
/pre-dev-full        # 8-gate planning workflow
```

### Hooks

Hooks run automatically at session events:
- **SessionStart**: Load skills reference, inject context
- **UserPromptSubmit**: Remind about CLAUDE.md
- **Stop**: Ralph Wiggum loop continuation

## Session Lifecycle

1. **Session Start**: Ring hooks load, skill reference generated
2. **Context Injection**: Plugin introductions (using-ring, using-dev-team, etc.)
3. **Skill Discovery**: Check applicable skills before any task
4. **Workflow Execution**: Use skills, agents, commands as needed
5. **Verification**: Evidence-based completion

## Configuration

No additional configuration required. Ring auto-discovers plugins from `~/.claude/plugins/ring/`.

### Optional: Plugin Selection

To install specific plugins only:

```bash
./installer/install-ring.sh install --platforms claude --plugins default,dev-team
```

### Exclude Plugins

```bash
./installer/install-ring.sh install --platforms claude --exclude finops-team,pm-team
```

## Updating

```bash
# Check for updates
./installer/install-ring.sh check

# Update all plugins
./installer/install-ring.sh update

# Sync only changed files
./installer/install-ring.sh sync
```

## Uninstalling

```bash
./installer/install-ring.sh uninstall --platforms claude
```

## Troubleshooting

### Skills not loading
1. Check hooks are enabled: Settings → Hooks
2. Verify installation: `./installer/install-ring.sh list`
3. Check hook output: Look for "Ring skills loaded" at session start

### Agent not found
1. Ensure plugin is installed that contains the agent
2. Use fully qualified name: `backend-engineer-golang`

### Commands not available
1. Commands require their parent plugin
2. Check `/help` for available commands

## Best Practices

1. **Always check skills first**: Before any task, verify if a skill applies
2. **Use parallel reviews**: Dispatch all 3 reviewers simultaneously
3. **Follow TDD**: Test → Fail → Implement → Pass → Refactor
4. **Evidence before claims**: Run verification, show output
