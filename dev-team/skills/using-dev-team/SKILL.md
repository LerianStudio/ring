---
name: ring:using-dev-team
description: |
  Specialist developer agents for backend (Go/TypeScript), frontend,
  design, Helm charts, UI implementation, frontend QA, and prompt quality review.
  Dispatch when you need deep technology expertise.
---

# Using Ring Developer Specialists

## When to use
- Need deep expertise for specific technology (Go, TypeScript)
- Backend local runtime / docker-compose → ring:backend-engineer-golang or ring:backend-engineer-typescript
- Frontend with design focus → ring:frontend-designer
- Frontend UI development (React/Next.js) → ring:frontend-engineer
- Frontend from product-designer specs → ring:ui-engineer
- Helm chart creation/maintenance → ring:helm-engineer
- Backend tests / coverage / TDD → ring:backend-engineer-golang or ring:backend-engineer-typescript
- Frontend test strategy → ring:qa-analyst-frontend
- Backend health/logging/tracing → ring:backend-engineer-golang or ring:backend-engineer-typescript
- Agent/prompt quality evaluation → ring:prompt-quality-reviewer
- Migrating deprecated lib-commons observability shims to lib-observability → ring:migrate-observability

## Skip when
- General code review → use `ring:codereview` with dev-team reviewer agents
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
| `ring:backend-engineer-golang` | Go microservices, PostgreSQL/MongoDB, RabbitMQ, OAuth2/JWT, gRPC, concurrency | Go services, DB optimization, auth/authz, concurrency |
| `ring:backend-engineer-typescript` | TypeScript/Node.js, Express/Fastify/NestJS, Prisma/TypeORM, Jest/Vitest | TS backends, NestJS design, JS→TS migration |
| `ring:frontend-bff-engineer-typescript` | Next.js BFF, Clean/Hexagonal Architecture, DDD patterns, Inversify DI | BFF layer, Clean Architecture, DDD domains, API orchestration |
| `ring:frontend-designer` | Bold typography, color systems, animations, unexpected layouts | Landing pages, portfolios, design systems |
| `ring:frontend-engineer` | React/Next.js, App Router, Server Components, accessibility, performance | Financial dashboards, enterprise apps, modern React |
| `ring:helm-engineer` | Helm charts, Lerian conventions, chart structure, security, operational patterns | Creating/maintaining Helm charts, platform deployments |
| `ring:ui-engineer` | Wireframe-to-code, Design System compliance, UI states implementation | Implementing from product-designer specs |
| `ring:prompt-quality-reviewer` | Agent quality analysis, prompt deficiency detection, quality scoring | Evaluating agent executions, identifying prompt gaps |
| `ring:qa-analyst-frontend` | Vitest, Testing Library, axe-core, Playwright, Lighthouse, snapshot testing | Frontend test planning, accessibility, E2E, performance |

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
| Visual aesthetics, design specs (no code) | `ring:frontend-designer` |
| React/Next.js UI development | `ring:frontend-engineer` |
| Business logic, BFF, Clean Architecture | `ring:frontend-bff-engineer-typescript` |
| Implementing from wireframes/ux-criteria | `ring:ui-engineer` |

## Parallelization

When tasks are independent, dispatch multiple agents in ONE message:

```yaml
# All in one Task call block
Task 1: ring:backend-engineer-golang - implement X with TDD, coverage, and local runtime
Task 2: ring:backend-engineer-typescript - implement Y with TDD, coverage, and local runtime
Task 3: ring:helm-engineer - update Helm chart
```

Sequential dispatch triples execution time for the same cost.

## Example

```yaml
Task:
  subagent_type: "ring:backend-engineer-golang"
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
