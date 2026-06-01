# Installing Ring Default for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add `ring-default` to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["ring-default@git+https://github.com/lerianstudio/ring.git#default"]
}
```

Restart OpenCode. The plugin installs through OpenCode's plugin manager and registers all Ring Default skills.

Verify by asking: "Tell me which Ring skills are available."

OpenCode uses its own plugin install. If you also use Claude Code, Codex, or another harness, install Ring Default separately for each one.

## Companion Plugins

`ring-default` provides the foundational `using-ring` bootstrap. The other Lerian plugins assume it is installed:

- `ring-dev-team` — backend/frontend specialist agents and the lean dev cycle
- `ring-pm-team` — pre-dev planning workflows
- `ring-tw-team` — technical writing specialists

Install whichever ones you need alongside `ring-default`:

```json
{
  "plugin": [
    "ring-default@git+https://github.com/lerianstudio/ring.git#default",
    "ring-dev-team@git+https://github.com/lerianstudio/ring.git#dev-team"
  ]
}
```

## Usage

Use OpenCode's native `skill` tool:

```
use skill tool to list skills
use skill tool to load ring:using-ring
```

## Updating

OpenCode installs Ring Default through a git-backed package spec. Some OpenCode and Bun versions pin the resolved git dependency in a lockfile or cache, so a restart may not pick up the newest commit. If updates do not appear, clear OpenCode's package cache or reinstall the plugin.

To pin a specific version:

```json
{
  "plugin": ["ring-default@git+https://github.com/lerianstudio/ring.git#v1.32.2"]
}
```

## Troubleshooting

### Plugin not loading

1. Check logs: `opencode run --print-logs "hello" 2>&1 | grep -i ring`
2. Verify the plugin line in your `opencode.json`
3. Make sure you're running a recent version of OpenCode

### Windows install issues

Some Windows OpenCode builds have upstream installer issues with git-backed plugin specs. If OpenCode cannot install the plugin, try installing with system npm and pointing OpenCode at the local package:

```powershell
npm install ring-default@git+https://github.com/lerianstudio/ring.git#default --prefix "$HOME\.config\opencode"
```

Then use the installed package path in `opencode.json`:

```json
{
  "plugin": ["~/.config/opencode/node_modules/ring-default"]
}
```

### Skills not found

1. Use `skill` tool to list what's discovered
2. Check that the plugin is loading (see above)
3. Verify `using-ring` is loadable: `use skill tool to load ring:using-ring`

### Tool mapping

When Ring skills reference Claude Code tools, OpenCode equivalents are auto-substituted:

- `TodoWrite` → `todowrite`
- `Task` (with subagents) → OpenCode's `@mention` syntax
- `Skill` tool → OpenCode's native `skill` tool
- `Read`, `Write`, `Edit`, `Bash` → native OpenCode tools

## Getting Help

- Report issues: https://github.com/lerianstudio/ring/issues
- Full documentation: https://github.com/lerianstudio/ring/tree/default
