# Ring for Factory AI

Factory AI uses **droids** instead of agents. Ring transforms agent definitions to droid format during installation.

## Installation

```bash
# Interactive installer
./installer/install-ring.sh

# Direct install
./installer/install-ring.sh install --platforms factory

# Multiple platforms
./installer/install-ring.sh install --platforms claude,factory
```

## Installation Path

Ring installs to: `~/.factory/`

```
~/.factory/
├── droids/                      # Transformed from agents/
│   ├── code-reviewer.md
│   ├── business-logic-reviewer.md
│   ├── security-reviewer.md
│   ├── backend-engineer-golang.md
│   └── ... (20 droids)
├── commands/                    # Slash commands
├── skills/                      # Skills (unchanged)
└── .ring-manifest.json          # Installation tracking
```

## Transformations

### Agents → Droids

Ring automatically transforms:

| Claude Code | Factory AI |
|-------------|------------|
| `agents/` | `droids/` |
| `subagent_type` | `droid_type` |
| "agent" references | "droid" references |

**Example transformation:**

Claude Code (original):
```markdown
---
name: code-reviewer
description: Foundation review agent
---
Use this agent for code quality review...
```

Factory AI (transformed):
```markdown
---
name: code-reviewer
description: Foundation review droid
---
Use this droid for code quality review...
```

### Skills (Unchanged)

Skills transfer directly without transformation. The workflow logic, triggers, and content remain identical.

### Commands (Minor adjustments)

Commands receive terminology updates:
- "dispatch agent" → "dispatch droid"
- "subagent" → "subdroid"

## Usage in Factory AI

### Invoking Droids

```
Task tool with droid_type="code-reviewer"
Task tool with droid_type="backend-engineer-golang"
```

### Using Skills

```
Skill tool: "test-driven-development"
Skill tool: "systematic-debugging"
```

### Running Commands

Commands work the same as Claude Code:
```
/codereview
/brainstorm
```

## Feature Parity

| Feature | Claude Code | Factory AI |
|---------|-------------|------------|
| Skills | 46 | 46 |
| Agents/Droids | 20 | 20 |
| Commands | 14 | 14 |
| Hooks | Full | Limited |
| Auto-discovery | Yes | Yes |

**Note**: Factory AI hook support may vary. Check Factory AI documentation for hook compatibility.

## Updating

```bash
# Check for updates
./installer/install-ring.sh check

# Update Factory AI installation
./installer/install-ring.sh update --platforms factory
```

## Uninstalling

```bash
./installer/install-ring.sh uninstall --platforms factory
```

## Troubleshooting

### Droid not found
1. Verify installation: `./installer/install-ring.sh list`
2. Check droids directory: `ls ~/.factory/droids/`
3. Use fully qualified name: `backend-engineer-golang`

### Terminology mismatch
If you see "agent" where "droid" is expected, re-run the installer:
```bash
./installer/install-ring.sh install --platforms factory --force
```

## Dual Installation

You can install Ring to both Claude Code and Factory AI:

```bash
./installer/install-ring.sh install --platforms claude,factory
```

Each platform maintains its own manifest and installation. Updates are platform-independent.
