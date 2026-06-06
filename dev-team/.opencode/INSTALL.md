# Installing Ring Dev Team for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- `ring-default` installed — provides the `using-ring` bootstrap that orients agent behavior. See [../../default/.opencode/INSTALL.md](../../default/.opencode/INSTALL.md).

## Installation

Add `ring-dev-team` to the `plugin` array in your `opencode.json`, alongside `ring-default`:

```json
{
  "plugin": [
    "ring-default@git+https://github.com/lerianstudio/ring.git#default",
    "ring-dev-team@git+https://github.com/lerianstudio/ring.git#dev-team"
  ]
}
```

Restart OpenCode. The plugin registers Ring Dev Team's skills and agents.

Verify by asking: "Which Ring backend specialists are available?"

## What This Plugin Adds

- **24 specialist agents** organized by role:
  - **Backend (2):** backend-go, backend-ts
  - **Frontend (4):** frontend, bff-ts, ui-engineer, ui-designer
  - **Infrastructure (3):** devops, helm, sre
  - **QA (2 × modes):** qa (6 modes: unit, fuzz, property, integration, chaos, goroutine-leak), qa-frontend (5 modes: unit, accessibility, visual, e2e, performance)
  - **Code review pool (13):** code-reviewer, logic-reviewer, security-reviewer, test-reviewer, nil-reviewer, dead-code-reviewer, perf-reviewer, tenancy-reviewer, commons-reviewer, obs-reviewer, streaming-reviewer, systemplane-reviewer, prompt-reviewer
- **33 dev-cycle skills:** lean backend cycle (Gate 0/8/9), lean frontend cycle (Gate 0/7/8) with quality checks, refactoring, simplification, delivery verification, observability migration, lib-streaming instrumentation, lib-systemplane migration, security audits

## Usage

Use OpenCode's native `skill` and agent mention syntax:

```
use skill tool to load ring:running-dev-cycle
@ring:backend-go implement the user repository
```

## Updating

```json
{
  "plugin": ["ring-dev-team@git+https://github.com/lerianstudio/ring.git#v1.71.2"]
}
```

## Troubleshooting

### Skills not auto-triggering

`ring-dev-team` relies on the `using-ring` bootstrap from `ring-default`. If skills aren't auto-triggering, confirm `ring-default` is installed and its plugin is loading. See its [INSTALL.md](../../default/.opencode/INSTALL.md#troubleshooting).

### Agents not found

1. Use `skill` tool to list discovered skills
2. Verify plugin loading: `opencode run --print-logs "hello" 2>&1 | grep -i ring`
3. Confirm `ring-default` is also installed (required peer)

## Getting Help

- Report issues: https://github.com/lerianstudio/ring/issues
- Full documentation: https://github.com/lerianstudio/ring/tree/dev-team
