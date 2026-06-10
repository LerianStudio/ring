# Installing Ring PM Team for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- `ring-default` installed — provides the `using-ring` bootstrap that orients agent behavior. See [../../default/.opencode/INSTALL.md](../../default/.opencode/INSTALL.md).

## Installation

Add `ring-pm-team` to the `plugin` array in your `opencode.json`, alongside `ring-default`:

```json
{
  "plugin": [
    "ring-default@git+https://github.com/lerianstudio/ring.git#default",
    "ring-pm-team@git+https://github.com/lerianstudio/ring.git#pm-team"
  ]
}
```

Restart OpenCode. The plugin registers Ring PM Team's skills and agents.

Verify by asking: "List the Ring pre-dev planning gates."

## What This Plugin Adds

- **4 research agents:** web-researcher, docs-researcher, repo-researcher, product-designer
- **14 skills** organized in three groups:
  - **Orchestrators (2):** `ring:planning-small-features` (4-gate, small features <2 days), `ring:planning-large-features` (8-gate, large features ≥2 days; both tracks end with `ring:writing-plans` from ring-default producing plan.md)
  - **Pre-dev planning gates (7):** `ring:researching-features`, `ring:writing-prds`, `ring:mapping-feature-relationships`, `ring:writing-trds`, `ring:designing-api-contracts`, `ring:designing-data-model`, `ring:pinning-dependency-versions`
  - **Standalone utilities (5):** `ring:mapping-streaming-events`, `ring:validating-ux-completeness`, `ring:creating-grafana-dashboards`, `ring:reconciling-predev-docs`, `ring:using-pm-team`

## Usage

Use OpenCode's native `skill` tool:

```
use skill tool to load ring:planning-small-features
use skill tool to load ring:planning-large-features
```

## Updating

```json
{
  "plugin": ["ring-pm-team@git+https://github.com/lerianstudio/ring.git#v0.29.1"]
}
```

## Troubleshooting

### Pre-dev workflow doesn't auto-trigger

`ring-pm-team` relies on the `using-ring` bootstrap from `ring-default`. If skills aren't auto-triggering, confirm `ring-default` is installed and its plugin is loading. See its [INSTALL.md](../../default/.opencode/INSTALL.md#troubleshooting).

### Skills not found

1. Use `skill` tool to list discovered skills
2. Verify plugin loading: `opencode run --print-logs "hello" 2>&1 | grep -i ring`
3. Confirm `ring-default` is also installed (required peer)

## Getting Help

- Report issues: https://github.com/lerianstudio/ring/issues
- Full documentation: https://github.com/lerianstudio/ring/tree/pm-team
