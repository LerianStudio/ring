# Instruction Files Reminder Hook

## Purpose

Combats **context drift** in long-running Claude Code sessions by periodically re-injecting instruction files. This ensures project-specific rules and standards remain "fresh" throughout extended conversations.

**Supported files:** CLAUDE.md, AGENTS.md, RULES.md

## How It Works

### Discovery
The hook automatically finds and injects ALL instruction files in your environment:

**For each file type (CLAUDE.md, AGENTS.md, RULES.md):**

1. **Global**: `~/.claude/{FILE}` (your personal standards)
   - `~/.claude/CLAUDE.md` - General coding standards
   - `~/.claude/AGENTS.md` - Agent behavior configuration
   - `~/.claude/RULES.md` - Custom rules and conventions

2. **Project Root**: `${CLAUDE_PROJECT_DIR}/{FILE}` (project-specific instructions)
   - `CLAUDE.md` - Project coding standards
   - `AGENTS.md` - Project agent configuration
   - `RULES.md` - Project-specific rules

3. **Subdirectories**: Any instruction file in the project tree
   - `services/api/CLAUDE.md` - API service standards
   - `services/api/AGENTS.md` - API agent config
   - `packages/shared/RULES.md` - Shared package rules

### Throttling
- **Trigger**: Every 1 user prompt by default (configurable via `THROTTLE_INTERVAL`)
- **State Tracking**: Uses `hooks/.instruction-files-reminder-state` to count prompts
- **Performance**: Excludes common ignore patterns (node_modules, .venv, dist, etc.)

### File Loading
- **Full files**: Entire file contents are loaded (no line limits)
- **Responsibility**: Keep instruction files concise to avoid context bloat
- **Best practice**: Keep each file under ~500 lines for optimal performance

### Injection Format
```
<instruction-files-reminder>
Re-reading instruction files to combat context drift (prompt 1):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ~/.claude/CLAUDE.md (global)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Complete CLAUDE.md content]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 ~/.claude/AGENTS.md (global)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Complete AGENTS.md content]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 RULES.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Complete RULES.md content]

</instruction-files-reminder>
```

**File type emojis:**
- 📋 CLAUDE.md
- 🤖 AGENTS.md
- 📜 RULES.md

## Configuration

### Adjust Throttle Interval

Edit `hooks/claude-md-reminder.sh`:

```bash
THROTTLE_INTERVAL=1  # Change to desired prompt count
```

Examples:
- `THROTTLE_INTERVAL=1` - Every prompt (current default)
- `THROTTLE_INTERVAL=3` - Every 3 prompts
- `THROTTLE_INTERVAL=5` - Every 5 prompts
- `THROTTLE_INTERVAL=10` - Less frequent (every 10 prompts)

### Add More File Types

Edit the `INSTRUCTION_FILES` array in `hooks/claude-md-reminder.sh`:

```bash
INSTRUCTION_FILES=("CLAUDE.md" "AGENTS.md" "RULES.md" "STANDARDS.md")
```

Any file names added here will be automatically discovered in:
- `~/.claude/{FILENAME}`
- Project root
- All subdirectories

### Reset State

If you want to reset the prompt counter:

```bash
rm hooks/.instruction-files-reminder-state
```

### Disable Temporarily

Comment out the hook in `hooks/hooks.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          // {
          //   "type": "command",
          //   "command": "${CLAUDE_PLUGIN_ROOT}/hooks/claude-md-reminder.sh"
          // }
        ]
      }
    ]
  }
}
```

## Use Cases

### Monorepo Services

```
project/
├── CLAUDE.md                    # Project-wide coding standards
├── AGENTS.md                    # Project-wide agent config
├── RULES.md                     # Project-wide rules
├── services/
│   ├── api/
│   │   ├── CLAUDE.md           # API service specific standards
│   │   └── AGENTS.md           # API service agent config
│   └── frontend/
│       ├── CLAUDE.md           # Frontend specific standards
│       └── RULES.md            # Frontend specific rules
└── packages/
    └── shared/
        ├── CLAUDE.md           # Shared package conventions
        └── RULES.md            # Shared package rules
```

All instruction files will be discovered and injected periodically.

### Multiple Environments

```
~/.claude/
├── CLAUDE.md                    # Personal coding standards (all projects)
├── AGENTS.md                    # Personal agent behavior (all projects)
└── RULES.md                     # Personal conventions (all projects)

/work/project-a/
├── CLAUDE.md                    # Project A specific standards
├── AGENTS.md                    # Project A agent config
└── RULES.md                     # Project A rules

/work/project-b/
├── CLAUDE.md                    # Project B specific standards
└── AGENTS.md                    # Project B agent config
```

When working in project-a, both global files and project-a files are injected.

## Troubleshooting

### Hook Not Firing

Check that hooks.json is valid JSON:
```bash
cat hooks/hooks.json | jq .
```

Verify hook is executable:
```bash
ls -l hooks/claude-md-reminder.sh
```

### Instruction Files Not Found

Test discovery manually:
```bash
CLAUDE_PROJECT_DIR=$(pwd) ./hooks/claude-md-reminder.sh
```

Check find command output for each file type:
```bash
# Check CLAUDE.md discovery
find . -type f -name "CLAUDE.md" ! -path "*/\.*" ! -path "*/node_modules/*"

# Check AGENTS.md discovery
find . -type f -name "AGENTS.md" ! -path "*/\.*" ! -path "*/node_modules/*"

# Check RULES.md discovery
find . -type f -name "RULES.md" ! -path "*/\.*" ! -path "*/node_modules/*"
```

### Context Too Large

If injections are consuming too much context:
1. **Increase throttle interval**: Change `THROTTLE_INTERVAL` to higher number (e.g., 5, 10)
2. **Reduce file sizes**: Keep instruction files concise (~500 lines each max)
3. **Split content**: Separate concerns across CLAUDE.md, AGENTS.md, RULES.md
4. **Remove files**: Temporarily remove file types from `INSTRUCTION_FILES` array

## Performance

**Typical impact:**
- File discovery: ~50-200ms (depending on project size)
- File reading: ~10-50ms per file
- Context added per injection: Variable (depends on total file sizes)
  - Typical: ~2000-10000 tokens per injection
  - Large projects: Can exceed 20000 tokens if files are verbose

**Optimizations:**
- Excludes common ignore patterns (node_modules, .venv, dist, build)
- Loads entire files (no truncation)
- Uses throttle interval to control frequency

**Best practices:**
- Keep each instruction file under ~500 lines
- Separate concerns (CLAUDE.md for code standards, AGENTS.md for behavior, RULES.md for conventions)
- Use subdirectory files sparingly (only when service-specific rules needed)

## Example Output

When the hook fires (every prompt by default), Claude receives this in context:

```
<instruction-files-reminder>
Re-reading instruction files to combat context drift (prompt 1):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ~/.claude/CLAUDE.md (global)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# AGENT STANDARDS
## CORE BEHAVIOR
**STYLE:** Concise technical analysis. Do what's asked - nothing more, nothing less.
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 ~/.claude/AGENTS.md (global)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# AGENT CONFIGURATION
Review agents configuration and behavior...
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 CLAUDE.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Ring Project Guidelines
This file provides guidance to Claude Code when working in this repository.
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 RULES.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# PROJECT RULES
Coding conventions and rules specific to this project...
[Complete file content - no truncation]

</instruction-files-reminder>
```

This ensures all project instructions remain visible and "fresh" throughout long sessions.

**Note**: Since entire files are loaded, keep instruction files concise to avoid excessive context usage.
