---
name: ring:using-dev-team
description: "Selecting and dispatching the right Ring developer specialist agent (backend Go/TS, frontend, UI designer/engineer, Helm, frontend QA, prompt reviewer) for a technology task. Use when you need deep stack expertise and must decide which agent to invoke via the Task tool, including parallel dispatch of independent work. Skip for general code review (use ring:reviewing-code)."
---

# Using Ring Developer Specialists

## When to use
- Need deep expertise for specific technology (Go, TypeScript)
- Backend local runtime / docker-compose → ring:backend-go or ring:backend-ts
- Frontend with design focus → ring:ui-designer
- Frontend UI development (React/Next.js) → ring:frontend
- Frontend from product-designer specs → ring:ui-engineer
- Helm chart creation/maintenance → ring:helm
- Backend tests / coverage / TDD → ring:backend-go or ring:backend-ts
- Frontend test strategy → ring:qa-frontend
- Backend health/logging/tracing → ring:backend-go or ring:backend-ts
- Agent/prompt quality evaluation → ring:prompt-reviewer
- Migrating deprecated lib-commons observability shims to lib-observability → ring:migrating-to-lib-observability

## Skip when
- General code review → use `ring:reviewing-code` with dev-team reviewer agents
- Debugging → trace from logs / metrics / telemetry

## Related
**Similar:** ring:using-ring


Developer specialist agents. Dispatch via `Task tool with subagent_type:`.

## Runtime Version Resolution

Always resolve lib-commons to latest v5.x at runtime:
```bash
gh api repos/LerianStudio/lib-commons/releases/latest --jq '.tag_name'
```
Do NOT hardcode specific patch versions.

## Specialists

| Agent | Specializations | Use When |
|-------|----------------|----------|
| `ring:backend-go` | Go microservices, PostgreSQL/MongoDB, RabbitMQ, OAuth2/JWT, gRPC, concurrency | Go services, DB optimization, auth/authz, concurrency |
| `ring:backend-ts` | TypeScript/Node.js, Express/Fastify/NestJS, Prisma/TypeORM, Jest/Vitest | TS backends, NestJS design, JS→TS migration |
| `ring:bff-ts` | Next.js BFF, Clean/Hexagonal Architecture, DDD patterns, Inversify DI | BFF layer, Clean Architecture, DDD domains, API orchestration |
| `ring:ui-designer` | Bold typography, color systems, animations, unexpected layouts | Landing pages, portfolios, design systems |
| `ring:frontend` | React/Next.js, App Router, Server Components, accessibility, performance | Financial dashboards, enterprise apps, modern React |
| `ring:helm` | Helm charts, Lerian conventions, chart structure, security, operational patterns | Creating/maintaining Helm charts, platform deployments |
| `ring:ui-engineer` | Wireframe-to-code, Design System compliance, UI states implementation | Implementing from product-designer specs |
| `ring:prompt-reviewer` | Agent quality analysis, prompt deficiency detection, quality scoring | Evaluating agent executions, identifying prompt gaps |
| `ring:qa-frontend` | Vitest, Testing Library, axe-core, Playwright, Lighthouse, snapshot testing | Frontend test planning, accessibility, E2E, performance |

## Dispatch Template

```yaml
Task:
  subagent_type: "ring:{agent-name}"
  description: "{Brief task description}"
  prompt: |
    {Your specific request with full context}
```

## Frontend Agent Selection Guide

| Need | Agent |
|------|-------|
| Visual aesthetics, design specs (no code) | `ring:ui-designer` |
| React/Next.js UI development | `ring:frontend` |
| Business logic, BFF, Clean Architecture | `ring:bff-ts` |
| Implementing from wireframes/ux-criteria | `ring:ui-engineer` |

## Parallelization

When tasks are independent, dispatch multiple agents in ONE message:

```yaml
# All in one Task call block
Task 1: ring:backend-go - implement X with TDD, coverage, and local runtime
Task 2: ring:backend-ts - implement Y with TDD, coverage, and local runtime
Task 3: ring:helm - update Helm chart
```

Sequential dispatch triples execution time for the same cost.

## Example

```yaml
Task:
  subagent_type: "ring:backend-go"
  description: "Implement multi-tenant repository for accounts"
  prompt: |
    Implement a multi-tenant PostgreSQL repository for the accounts domain.
    
    Standards: Load golang.md and multi-tenant.md via WebFetch.
    Project rules: docs/PROJECT_RULES.md
    
    Requirements:
    - Use tmcore.GetPGContext(ctx) for tenant context resolution
    - Table: accounts, tenant isolation via schema-per-tenant
    - TDD: write failing test first, then implement
    
    Output: files created, test results, acceptance criteria checklist
```
