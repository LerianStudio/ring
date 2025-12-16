# Ring for Cline

Cline uses **prompts** for workflow guidance. Ring transforms skills, agents, and commands into structured prompts during installation.

## Installation

```bash
# Interactive installer
./installer/install-ring.sh

# Direct install
./installer/install-ring.sh install --platforms cline

# Multiple platforms
./installer/install-ring.sh install --platforms claude,cline
```

## Installation Path

Ring installs to: `~/.cline/`

```
~/.cline/
├── prompts/                     # All content as prompts
│   ├── skills/                  # Skill prompts
│   │   ├── test-driven-development.md
│   │   ├── systematic-debugging.md
│   │   └── ...
│   ├── workflows/               # Agent-derived workflows
│   │   ├── code-review.md
│   │   ├── backend-development.md
│   │   └── ...
│   └── commands/                # Command prompts
│       ├── codereview.md
│       ├── brainstorm.md
│       └── ...
└── .ring-manifest.json          # Installation tracking
```

## Transformations

### Skills → Skill Prompts

Skills become prompt files optimized for Cline's prompt system:

**Claude Code (SKILL.md with frontmatter):**
```yaml
---
name: test-driven-development
description: RED-GREEN-REFACTOR cycle
trigger:
  - When writing new code
  - When fixing bugs
---

# Test-Driven Development
...detailed content...
```

**Cline (prompt file):**
```markdown
# Test-Driven Development

## When to Use
- When writing new code
- When fixing bugs

## Process

### RED Phase
1. Write a test that describes expected behavior
2. Run the test - it MUST fail
3. If test passes, your test is wrong

### GREEN Phase
1. Write minimal code to pass the test
2. Run the test - it MUST pass
3. No extra code, no "future-proofing"

### REFACTOR Phase
1. Clean up while tests stay green
2. Extract methods, rename variables
3. Run tests after each change

## Checklist
- [ ] Test written before code
- [ ] Test failed initially
- [ ] Minimal code written
- [ ] Test passes
- [ ] Code refactored (optional)
```

### Agents → Workflow Prompts

Agent definitions become workflow guidance prompts:

| Agent | Prompt |
|-------|--------|
| `code-reviewer` | `prompts/workflows/code-review.md` |
| `backend-engineer-golang` | `prompts/workflows/go-backend.md` |
| `security-reviewer` | `prompts/workflows/security-review.md` |

> **Note:** Agent names shown without prefix. When invoking in Claude Code, use fully qualified names: `code-reviewer`, `backend-engineer-golang`, etc.

**Example workflow prompt:**
```markdown
# Code Review Workflow

## Role
You are a code reviewer focusing on architecture, design patterns, and code quality.

## Review Checklist
1. Architecture alignment
2. Design pattern usage
3. Code organization
4. Error handling
5. Test coverage

## Output Format
## VERDICT: [PASS|FAIL|NEEDS_DISCUSSION]

## Summary
[2-3 sentences]

## Issues Found
### Critical
- [issue]

### High
- [issue]

## What Was Done Well
- [positive point]
```

### Commands → Command Prompts

Slash commands become prompt files you can reference:

```markdown
# /codereview Command Prompt

## Usage
Reference this prompt to initiate a code review.

## Process
1. Identify files to review
2. Apply code-review workflow
3. Apply business-logic-review workflow
4. Apply security-review workflow
5. Aggregate findings
6. Address by severity
```

## Usage in Cline

### Loading Prompts

Reference prompts when starting tasks:

```
"Load the test-driven-development prompt for this feature"
"Follow the prompts/workflows/code-review.md workflow"
```

### Prompt Discovery

List available prompts:
```bash
ls ~/.cline/prompts/skills/
ls ~/.cline/prompts/workflows/
ls ~/.cline/prompts/commands/
```

### Combining Prompts

Use multiple prompts together:
```
"For this feature:
1. Use test-driven-development prompt
2. Use verification-before-completion prompt
3. Follow go-backend workflow"
```

## Feature Mapping

| Ring Feature | Cline Equivalent |
|--------------|------------------|
| Skills | Skill prompts |
| Agents | Workflow prompts |
| Commands | Command prompts |
| Hooks | Not supported |

**Limitations:**
- No automatic prompt loading
- No hook execution
- Manual prompt reference required

## Prompt Categories

### Skill Prompts (46)
Development methodologies and best practices:
- `test-driven-development.md` - TDD workflow
- `systematic-debugging.md` - 4-phase debugging
- `verification-before-completion.md` - Evidence requirements
- `brainstorming.md` - Design refinement
- ...and 42 more

### Workflow Prompts (20)
Role-based workflows from agents:
- `code-review.md` - Quality review
- `security-review.md` - Security analysis
- `go-backend.md` - Go development
- `typescript-backend.md` - TypeScript development
- ...and 16 more

### Command Prompts (14)
Quick-reference command guides:
- `codereview.md` - Review orchestration
- `brainstorm.md` - Design sessions
- `pre-dev-full.md` - Planning workflow
- ...and 11 more

## Updating

```bash
# Check for updates
./installer/install-ring.sh check

# Update Cline installation
./installer/install-ring.sh update --platforms cline

# Force regenerate all prompts
./installer/install-ring.sh install --platforms cline --force
```

## Uninstalling

```bash
./installer/install-ring.sh uninstall --platforms cline
```

This removes:
- `prompts/` directory
- `.ring-manifest.json`

## Troubleshooting

### Prompts not found
1. Verify installation: `./installer/install-ring.sh list`
2. Check directory: `ls ~/.cline/prompts/`
3. Re-run installer if missing

### Outdated prompts
```bash
./installer/install-ring.sh sync --platforms cline
```

### Prompt format issues
If prompts aren't working well:
1. Check Cline's prompt documentation
2. Prompts may need manual adjustment for your Cline version

## Best Practices for Cline

1. **Reference prompts explicitly**: Start messages with prompt references
2. **Combine related prompts**: Use skill + workflow prompts together
3. **Create shortcuts**: Save common prompt combinations
4. **Update regularly**: Sync to get latest prompt improvements
5. **Customize if needed**: Prompts can be edited for your workflow
