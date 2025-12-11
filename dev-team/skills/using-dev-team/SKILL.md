---
name: using-dev-team
description: |
  7 specialist developer agents for backend (Go/TypeScript), DevOps, frontend,
  design, QA, and SRE. Dispatch when you need deep technology expertise.

trigger: |
  - Need deep expertise for specific technology (Go, TypeScript)
  - Building infrastructure/CI-CD → devops-engineer
  - Frontend with design focus → frontend-designer
  - Test strategy needed → qa-analyst
  - Reliability/monitoring → sre

skip_when: |
  - General code review → use default plugin reviewers
  - Planning/design → use brainstorming
  - Debugging → use systematic-debugging

related:
  similar: [ring-default:using-ring]
---

# Using Ring Developer Specialists

The ring-dev-team plugin provides 7 specialized developer agents. Use them via `Task tool with subagent_type:`.

See [CLAUDE.md](../../../CLAUDE.md) and [ring-default:using-ring](../../../default/skills/using-ring/SKILL.md) for canonical workflow requirements and ORCHESTRATOR principle. This skill introduces dev-team-specific agents.

**Remember:** Follow the **ORCHESTRATOR principle** from `ring-default:using-ring`. Dispatch agents to handle complexity; don't operate tools directly.

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Decision Type | Examples | Action |
|--------------|----------|--------|
| **Technology Stack** | Go vs TypeScript for new service | STOP. Check existing patterns. Ask user. |
| **Architecture** | Monolith vs microservices | STOP. This is a business decision. Ask user. |
| **Infrastructure** | K8s vs Docker Compose | STOP. Check scale requirements. Ask user. |
| **Testing Strategy** | Unit vs E2E vs both | STOP. Check QA requirements. Ask user. |

**You CANNOT make technology decisions autonomously. STOP and ask.**

---

## Common Misconceptions - REJECTED

| Misconception | Reality |
|--------------|---------|
| "I can handle this myself" | ORCHESTRATOR principle: dispatch specialists, don't implement directly. This is NON-NEGOTIABLE. |
| "Overhead of dispatching not worth it" | Specialist quality > self-implementation. Dispatch is investment, not cost. MANDATORY dispatch. |
| "Simple task, no specialist needed" | Simplicity is NOT your judgment. Follow dispatch guidelines. NO EXCEPTIONS. |
| "I know Go/TypeScript well enough" | Specialists have standards loading. You don't. MUST dispatch. |
| "Faster if I do it myself" | Faster ≠ better. Specialist output follows Ring standards. DISPATCH is REQUIRED. |

**Self-sufficiency bias check:** If you're tempted to implement directly, ask:
1. Is there a specialist for this? (Check the 7 specialists below)
2. Would a specialist follow standards I might miss?
3. Am I avoiding dispatch because it feels like "overhead"?

**If ANY answer is yes → You MUST DISPATCH the specialist. This is NON-NEGOTIABLE.**

---

## Anti-Rationalization Table

**If you catch yourself thinking ANY of these, STOP:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is a small task, no need for specialist" | Size doesn't determine complexity. Standards always apply. | **DISPATCH specialist** |
| "I already know how to do this" | Your knowledge ≠ Ring standards loaded by specialist. | **DISPATCH specialist** |
| "Dispatching takes too long" | Quality > speed. Specialist follows full standards. | **DISPATCH specialist** |
| "I'll just fix this one thing quickly" | Quick fixes bypass TDD, testing, review. | **DISPATCH specialist** |
| "The specialist will just do what I would do" | Specialists have domain-specific anti-rationalization. You don't. | **DISPATCH specialist** |
| "This doesn't need the full dev-cycle" | ALL implementation needs dev-cycle. No exceptions. | **Follow 6-gate cycle** |
| "I've already implemented 80% without specialist" | Past mistakes don't justify continuing wrong approach. Dispatch specialist, discard non-compliant work if needed. | **STOP. DISPATCH specialist. Accept sunk cost.** |
| "Prototyping first, dispatch later" | Prototyping without standards = technical debt seed. | **DISPATCH specialist BEFORE any code** |

---

## Cannot Be Overridden

**These requirements are NON-NEGOTIABLE:**

| Requirement | Why It Cannot Be Waived |
|-------------|------------------------|
| **Dispatch to specialist** | Specialists have standards loading, you don't |
| **6-gate development cycle** | Gates prevent quality regressions |
| **Parallel reviewer dispatch** | Sequential review = 3x slower, same cost |
| **TDD in Gate 0** | Test-first ensures testability |
| **User approval in Gate 5** | Only users can approve completion |

**User cannot override these. Time pressure cannot override these. "Simple task" cannot override these.**

---

## Pressure Resistance

**When facing pressure to bypass specialist dispatch:**

| User Says | Your Response |
|-----------|---------------|
| "Production is down, no time for specialist dispatch" | "I understand the urgency. However, specialists prevent introducing new bugs during incidents. I'll dispatch with URGENT context. This takes 5-10 minutes, not hours." |
| "You've already done 80% of this, just finish it yourself" | "Sunk cost doesn't justify wrong approach. The 80% may not meet Ring standards. I MUST dispatch the specialist to verify compliance. I cannot proceed without specialist review." |
| "Our senior dev said you don't need the specialist for this" | "I respect the senior dev's experience, but Ring standards require specialist dispatch. Specialists have loaded standards that even experienced developers might miss. This is NON-NEGOTIABLE." |
| "This is a 2-line change, specialist is overkill" | "Line count doesn't determine complexity. Every change MUST follow TDD and standards. I CANNOT make code changes without specialist dispatch. This is a HARD GATE." |
| "Dispatch both at once seems risky, do them sequentially" | "Sequential dispatch doubles execution time. Specialists work independently with provided context. Parallel dispatch is REQUIRED. I'll dispatch both now." |
| "Just copy our existing Docker setup, don't bother the DevOps agent" | "Copying patterns without standards verification creates technical debt. The `devops-engineer` ensures the copy follows current Ring standards. I MUST dispatch the specialist." |

**Critical Reminder:**
- **Urgency ≠ Permission to bypass** - Emergencies require MORE care, not less
- **Authority ≠ Permission to bypass** - Ring standards override human preferences
- **Sunk Cost ≠ Permission to bypass** - Wrong approach stays wrong at 80% completion

---

## Emergency Response Protocol

**Production incidents DO NOT bypass specialist dispatch. Here's why:**

| Scenario | Wrong Approach | Correct Approach |
|----------|----------------|------------------|
| Service down, CEO watching | "No time, fix directly" | Dispatch specialist with URGENT flag + incident context |
| 2-line obvious fix | "Just patch it quickly" | Dispatch + TDD even for 2 lines (prevents new bugs) |
| Rollback needed | "Revert manually" | Dispatch DevOps engineer for safe rollback |

**Emergency Dispatch Template:**
```
Task tool:
  subagent_type: "ring-dev-team:backend-engineer-golang"
  model: "opus"
  prompt: "URGENT PRODUCTION INCIDENT: [brief context]. [Your specific request]"
```

**IMPORTANT:**
- Specialist dispatch takes 5-10 minutes, NOT hours
- Rushed direct fixes often introduce NEW bugs (compounding the incident)
- Specialists ensure incident fixes don't violate standards
- This is NON-NEGOTIABLE even under CEO pressure

---

## Combined Pressure Scenarios

| Pressure Combination | Request | Agent Response |
|---------------------|---------|----------------|
| **Production + CEO + Exhaustion + Small Fix** | "3am, CEO watching, 2-line fix, just do it directly" | "I understand the extreme pressure. Specialist dispatch takes 5-10 minutes. Direct fixes at 3am often introduce new bugs. Dispatching specialist with URGENT context now." |
| **Sunk Cost + Deadline + Authority** | "80% done, demo tomorrow, tech lead says finish yourself" | "Sunk cost and authority don't override Ring standards. Dispatching specialist to verify the 80% and complete correctly." |
| **All Pressures Combined** | "Production down + CEO + 3am + 80% done + tech lead says hurry" | "Maximum pressure doesn't change requirements. Specialist dispatch is MANDATORY. Proceeding with URGENT dispatch now." |

---

## 7 Developer Specialists

| Agent | Specializations | Use When |
|-------|-----------------|----------|
| **`ring-dev-team:backend-engineer-golang`** | Go microservices, PostgreSQL/MongoDB, Kafka/RabbitMQ, OAuth2/JWT, gRPC, concurrency | Go services, DB optimization, auth/authz, concurrency issues |
| **`ring-dev-team:backend-engineer-typescript`** | TypeScript/Node.js, Express/Fastify/NestJS, Prisma/TypeORM, async patterns, Jest/Vitest | TS backends, JS→TS migration, NestJS design, full-stack TS |
| **`ring-dev-team:devops-engineer`** | GitHub Actions/GitLab CI, Docker/Compose, Kubernetes, Terraform/Helm, cloud infra | CI/CD pipelines, containerization, K8s, IaC provisioning |
| **`ring-dev-team:frontend-bff-engineer-typescript`** | Next.js API Routes BFF, Clean/Hexagonal Architecture, DDD patterns, Inversify DI, repository pattern | BFF layer, Clean Architecture, DDD domains, API orchestration |
| **`ring-dev-team:frontend-designer`** | Bold typography, color systems, animations, unexpected layouts, textures/gradients | Landing pages, portfolios, distinctive dashboards, design systems |
| **`ring-dev-team:qa-analyst`** | Test strategy, Cypress/Playwright E2E, coverage analysis, API testing, performance | Test planning, E2E suites, coverage gaps, quality gates |
| **`ring-dev-team:sre`** | Monitoring/logging/tracing, SLOs/alerting, incident response, scalability | Observability setup, alerts, incident planning, reliability |

**Dispatch template:**
```
Task tool:
  subagent_type: "ring-dev-team:{agent-name}"
  model: "opus"
  prompt: "{Your specific request with context}"
```

**Note:** `frontend-designer` = visual aesthetics. `frontend-bff-engineer-typescript` = business logic/architecture.

---

## When to Use Developer Specialists vs General Review

### Use Developer Specialists for:
- ✅ **Deep technical expertise needed** – Architecture decisions, complex implementations
- ✅ **Technology-specific guidance** – "How do I optimize this Go service?"
- ✅ **Specialized domains** – Infrastructure, SRE, testing strategy
- ✅ **Building from scratch** – New service, new pipeline, new testing framework

### Use General Review Agents for:
- ✅ **Code quality assessment** – Architecture, patterns, maintainability
- ✅ **Correctness & edge cases** – Business logic verification
- ✅ **Security review** – OWASP, auth, validation
- ✅ **Post-implementation** – Before merging existing code

**Both can be used together:** Get developer specialist guidance during design, then run general reviewers before merge.

---

## Dispatching Multiple Specialists

If you need multiple specialists (e.g., backend engineer + DevOps engineer), dispatch in **parallel** (single message, multiple Task calls):

```
✅ CORRECT:
Task #1: ring-dev-team:backend-engineer-golang
Task #2: ring-dev-team:devops-engineer
(Both run in parallel)

❌ WRONG:
Task #1: ring-dev-team:backend-engineer-golang
(Wait for response)
Task #2: ring-dev-team:devops-engineer
(Sequential = 2x slower)
```

---

## ORCHESTRATOR Principle

Remember:
- **You're the orchestrator** – Dispatch specialists, don't implement directly
- **Don't read specialist docs yourself** – Dispatch to specialist, they know their domain
- **Combine with using-ring principle** – Skills + Specialists = complete workflow

### Good Example (ORCHESTRATOR):
> "I need a Go service. Let me dispatch `ring-dev-team:backend-engineer-golang` to design it."

### Bad Example (OPERATOR):
> "I'll manually read Go best practices and design the service myself."

---

## Available in This Plugin

**Agents:** See "7 Developer Specialists" table above.

**Skills:** `using-dev-team` (this), `dev-cycle` (6-gate workflow), `dev-refactor` (codebase analysis)

**Commands:** `/ring-dev-team:dev-cycle` (execute tasks), `/ring-dev-team:dev-refactor` (analyze codebase)

**Note:** Missing agents? Check `.claude-plugin/marketplace.json` for ring-dev-team plugin.

---

## Development Workflows

All workflows converge to the 6-gate development cycle:

| Workflow | Entry Point | Output | Then |
|----------|-------------|--------|------|
| **New Feature** | `/ring-pm-team:pre-dev-feature "description"` | `docs/pre-dev/{feature}/tasks.md` | → `/ring-dev-team:dev-cycle tasks.md` |
| **Direct Tasks** | `/ring-dev-team:dev-cycle tasks.md` | — | Execute 6 gates directly |
| **Refactoring** | `/ring-dev-team:dev-refactor` | `docs/refactor/{timestamp}/tasks.md` | → `/ring-dev-team:dev-cycle tasks.md` |

**6-Gate Development Cycle:**

| Gate | Focus | Agent(s) |
|------|-------|----------|
| **0: Implementation** | TDD: RED→GREEN→REFACTOR | `backend-engineer-*`, `frontend-bff-engineer-typescript` |
| **1: DevOps** | Dockerfile, docker-compose, .env | `devops-engineer` |
| **2: SRE** | Health checks, logging, metrics | `sre` |
| **3: Testing** | Unit tests, coverage ≥85% | `qa-analyst` |
| **4: Review** | 3 reviewers IN PARALLEL | `code-reviewer`, `business-logic`, `security` |
| **5: Validation** | User approval: APPROVED/REJECTED | User decision |

**Key Principle:** All development follows the same 6-gate process.

---

## Integration with Other Plugins

- **using-ring** (default) – ORCHESTRATOR principle for ALL agents
- **using-finops-team** – Financial/regulatory agents
- **using-pm-team** – Pre-dev workflow agents

Dispatch based on your need:
- General code review → default plugin agents
- Specific domain expertise → ring-dev-team agents
- Regulatory compliance → ring-finops-team agents
- Feature planning → ring-pm-team agents
