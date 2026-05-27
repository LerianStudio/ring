# Installing Ring TW Team for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- `ring-default` installed — provides the `using-ring` bootstrap that orients agent behavior. See [../../default/.opencode/INSTALL.md](../../default/.opencode/INSTALL.md).

## Installation

Add `ring-tw-team` to the `plugin` array in your `opencode.json`, alongside `ring-default`:

```json
{
  "plugin": [
    "ring-default@git+https://github.com/lerianstudio/ring.git#default",
    "ring-tw-team@git+https://github.com/lerianstudio/ring.git#tw-team"
  ]
}
```

Restart OpenCode. The plugin registers Ring TW Team's skills and agents.

Verify by asking: "Which Ring technical writing skills are available?"

## What This Plugin Adds

- **3 specialist agents:** functional-writer, api-writer, docs-reviewer
- **6 documentation skills:** write-guide, write-api, voice-and-tone, documentation-structure, review-docs, using-tw-team

## Usage

Use OpenCode's native `skill` tool:

```
use skill tool to load ring:write-guide
use skill tool to load ring:write-api
```

## Updating

```json
{
  "plugin": ["ring-tw-team@git+https://github.com/lerianstudio/ring.git#v0.4.7"]
}
```

## Troubleshooting

### Skills not auto-triggering

`ring-tw-team` relies on the `using-ring` bootstrap from `ring-default`. If skills aren't auto-triggering, confirm `ring-default` is installed and its plugin is loading. See its [INSTALL.md](../../default/.opencode/INSTALL.md#troubleshooting).

### Skills not found

1. Use `skill` tool to list discovered skills
2. Verify plugin loading: `opencode run --print-logs "hello" 2>&1 | grep -i ring`
3. Confirm `ring-default` is also installed (required peer)

## Getting Help

- Report issues: https://github.com/lerianstudio/ring/issues
- Full documentation: https://github.com/lerianstudio/ring/tree/tw-team
