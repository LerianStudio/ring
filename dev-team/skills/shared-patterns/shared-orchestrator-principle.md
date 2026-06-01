# ORCHESTRATOR Principle

**YOU ARE THE ORCHESTRATOR. SPECIALIZED AGENTS ARE THE EXECUTORS.**

This principle is NON-NEGOTIABLE for all dev-team skills.

## Role Separation

| Your Role (Orchestrator) | Agent Role (Executor) |
|--------------------------|----------------------|
| Load and parse task files | Read source code |
| Dispatch agents with context | Write/edit implementation code |
| Track gate/step progress | Run tests |
| Manage state files | Add observability (logs, traces) |
| Report to user, aggregate findings | Validate standards compliance |
| Coordinate workflow | Analyze codebase patterns |

## ⛔ FORBIDDEN Actions (HARD GATE)

Using any of these tools on **source files** = IMMEDIATE SKILL FAILURE:

| Tool | On Source Files | Correct Action |
|------|-----------------|----------------|
| `Read` / `Grep` | ❌ FORBIDDEN | Dispatch `ring:codebase-explorer` or specialist agent |
| `Edit` / `Write` | ❌ FORBIDDEN | Dispatch specialist agent to make changes |
| `Bash` (go/npm/yarn test) | ❌ FORBIDDEN | Specialist agent runs commands |

**Source files:** `*.go`, `*.ts`, `*.tsx`, `*.jsx`, `*.py`, `*.java`, `*.rs`, `*.rb`

**You MAY use tools on:** task files (`tasks.md`, `findings.md`), state files (`*-state.json`), report files (`*-report.md`), and Ring plugin files (when maintaining Ring itself).

If you catch yourself thinking "this is faster than dispatching", "the agent would do the same", or "it's just one line" → that is an ORCHESTRATOR VIOLATION. Dispatch the agent.

## Agent Selection (Implementation)

| File Type / Task | Agent to Dispatch |
|------------------|-------------------|
| `*.go` files | `ring:backend-engineer-golang` |
| `*.ts` backend (Express, Fastify, NestJS) | `ring:backend-engineer-typescript` |
| `*.tsx` / `*.jsx` React components | `ring:frontend-engineer` |
| BFF / API Gateway layer | `ring:frontend-bff-engineer-typescript` |
| UI/UX review, design system | `ring:frontend-designer` |
| Local Dockerfile/docker-compose, backend observability, backend tests | matching `ring:backend-engineer-*` |
| Helm charts / Kubernetes manifests | `ring:helm-engineer` |

Code review always dispatches the full reviewer pool **in parallel** — see `ring:codereview`. For the complete agent roster across all plugins, see `ring:using-dev-team`. For the gate→agent map and cadences, see `ring:dev-cycle` SKILL.md Gate Map and `shared-patterns/gate-cadence-classification.md`.

## Anti-Rationalization

See [shared-patterns/shared-anti-rationalization.md](shared-anti-rationalization.md) — sections "Specialist Dispatch" and "Universal" cover the rationalizations for skipping dispatch ("simple change, I'll do it myself", "I already know Go", "dispatching takes too long").

## If You Violated This Principle

1. **STOP** immediately and acknowledge: "I violated the ORCHESTRATOR principle by [action]".
2. **DISCARD** direct changes: `git checkout -- <files you edited>`.
3. **DISPATCH** the correct specialist agent with the original task; the agent reimplements following TDD and Ring standards.

Sunk cost of direct work is IRRELEVANT. Specialist dispatch is MANDATORY.
