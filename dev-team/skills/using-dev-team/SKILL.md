---
name: using-dev-team
description: |
  9 specialist developer agents for backend (Go/TypeScript), DevOps, frontend,
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

The ring-dev-team plugin provides 9 specialized developer agents. Use them via `Task tool with subagent_type:`.

**Remember:** Follow the **ORCHESTRATOR principle** from `ring-default:using-ring`. Dispatch agents to handle complexity; don't operate tools directly.

---

## 9 Developer Specialists

### 1. Backend Engineer (Language-Agnostic)
**`ring-dev-team:backend-engineer`**

**Specializations:**
- Language-agnostic backend design (adapts to Go/TypeScript/Python/Java/Rust)
- Microservices architecture patterns
- API design (REST, GraphQL, gRPC)
- Database modeling & optimization
- Authentication & authorization
- Message queues & event-driven systems
- Caching strategies

**Use When:**
- You need backend expertise without language commitment
- Designing multi-language systems
- Comparing backend approaches across languages
- Architecture that might use multiple languages
- Language choice is not yet decided

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-dev-team:backend-engineer"
  model: "opus"
  prompt: "Design a user authentication service, recommend the best language and explain trade-offs"
```

---

### 2. Backend Engineer (Go)
**`ring-dev-team:backend-engineer-golang`**

**Specializations:**
- Go microservices & API design
- Database optimization (PostgreSQL, MongoDB)
- Message queues (Kafka, RabbitMQ)
- OAuth2, JWT, API security
- gRPC and performance optimization

**Use When:**
- Designing Go services from scratch
- Optimizing database queries
- Implementing authentication/authorization
- Troubleshooting concurrency issues
- Reviewing Go backend architecture

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-dev-team:backend-engineer-golang"
  model: "opus"
  prompt: "Design a Go service for user authentication with JWT and OAuth2 support"
```

---

### 3. Backend Engineer (TypeScript/Node.js)
**`ring-dev-team:backend-engineer-typescript`**

**Specializations:**
- TypeScript/Node.js backend services
- Express, Fastify, NestJS frameworks
- TypeScript type safety & ORM (Prisma, TypeORM)
- Node.js performance optimization
- Async/await patterns & error handling
- REST & GraphQL APIs
- Testing with Jest/Vitest

**Use When:**
- Building TypeScript/Node.js backends
- Migrating from JavaScript to TypeScript
- NestJS or Express service design
- Node.js-specific optimization
- Full-stack TypeScript projects

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-dev-team:backend-engineer-typescript"
  model: "opus"
  prompt: "Design a NestJS service with Prisma ORM for user management"
```

---

### 4. DevOps Engineer
**`ring-dev-team:devops-engineer`**

**Specializations:**
- CI/CD pipelines (GitHub Actions, GitLab CI)
- Containerization (Docker, Docker Compose)
- Kubernetes deployment & scaling
- Infrastructure as Code (Terraform, Helm)
- Cloud infrastructure setup

**Use When:**
- Setting up deployment pipelines
- Containerizing applications
- Managing Kubernetes clusters
- Infrastructure provisioning
- Automating infrastructure changes

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-dev-team:devops-engineer"
  model: "opus"
  prompt: "Create a GitHub Actions CI/CD pipeline for Go service deployment to Kubernetes"
```

---

### 5. Frontend Engineer
**`ring-dev-team:frontend-engineer`**

**Specializations:**
- React/Next.js application architecture
- TypeScript for type safety
- State management (Redux, Zustand, Context)
- Component design patterns
- Form handling and validation
- CSS-in-JS and styling solutions

**Use When:**
- Building React/Next.js applications
- Implementing complex UI components
- State management design
- Performance optimization for frontend
- Accessibility improvements

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-dev-team:frontend-engineer"
  model: "opus"
  prompt: "Design a React dashboard with real-time data updates and TypeScript"
```

---

### 6. Frontend Engineer (TypeScript)
**`ring-dev-team:frontend-engineer-typescript`**

**Specializations:**
- TypeScript-first React/Next.js architecture
- Advanced TypeScript patterns (generics, utilities, branded types)
- Type-safe state management (Zustand, Redux Toolkit)
- Type-safe API integration (tRPC, React Query)
- Component library with strict TypeScript
- Server Components with TypeScript (Next.js App Router)
- Type-safe routing & form validation

**Use When:**
- Building TypeScript-first frontend projects
- Requiring advanced type safety (e.g., branded types, strict inference)
- Type-safe full-stack integration (tRPC)
- Migrating JavaScript frontend to TypeScript
- Complex TypeScript patterns (conditional types, mapped types)

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-dev-team:frontend-engineer-typescript"
  model: "opus"
  prompt: "Design a type-safe React dashboard with tRPC, Zod validation, and branded types"
```

---

### 7. Frontend Designer
**`ring-dev-team:frontend-designer`**

**Specializations:**
- Distinctive, production-grade UI with high visual design quality
- Bold typography with characterful, non-generic fonts
- Cohesive color systems with dominant colors and sharp accents
- High-impact animations and micro-interactions
- Unexpected layouts with asymmetry, overlap, and spatial tension
- Atmosphere through textures, gradients, shadows, and visual depth

**Use When:**
- Building interfaces where aesthetics matter (landing pages, portfolios, marketing)
- Creating memorable, visually striking user experiences
- Designing dashboards with distinctive visual identity
- Implementing creative motion and interaction design
- Establishing distinctive visual languages and design systems

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-dev-team:frontend-designer"
  model: "opus"
  prompt: "Create a brutalist landing page for a tech startup with bold typography and unexpected layouts"
```

**Note:** Use `ring-dev-team:frontend-designer` for visual aesthetics and design excellence. Use `ring-dev-team:frontend-engineer` for complex state management, business logic, and application architecture.

---

### 8. QA Analyst
**`ring-dev-team:qa-analyst`**

**Specializations:**
- Test strategy & planning
- E2E test automation (Cypress, Playwright)
- Unit test coverage analysis
- API testing strategies
- Performance testing
- Compliance validation

**Use When:**
- Planning testing strategy for features
- Setting up E2E test suites
- Improving test coverage
- API testing and validation
- Quality gate design

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-dev-team:qa-analyst"
  model: "opus"
  prompt: "Create a comprehensive E2E test strategy for user authentication flow"
```

---

### 9. Site Reliability Engineer (SRE)
**`ring-dev-team:sre`**

**Specializations:**
- Observability (monitoring, logging, tracing)
- Alerting strategies & SLOs
- Incident response automation
- Performance optimization
- Scalability analysis
- System reliability patterns

**Use When:**
- Designing monitoring/observability systems
- Setting up alerts and SLOs
- Incident response planning
- Performance bottleneck analysis
- Reliability engineering

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-dev-team:sre"
  model: "opus"
  prompt: "Design monitoring and alerting for a Go microservice with 99.9% SLO"
```

---

## Decision Matrix: Which Specialist?

| Need | Specialist | Use Case |
|------|-----------|----------|
| Backend (language-agnostic, multi-language) | Backend Engineer | Architecture without language commitment |
| Go API, database, concurrency | Backend Engineer (Go) | Go-specific service architecture |
| TypeScript/Node.js backend, NestJS, Express | Backend Engineer (TypeScript) | TypeScript backend services |
| CI/CD, Docker, Kubernetes, IaC | DevOps Engineer | Deployment pipelines, infrastructure |
| React, TypeScript, components, state | Frontend Engineer | General UI development, performance |
| Advanced TypeScript, type-safe frontend, tRPC | Frontend Engineer (TypeScript) | Type-safe React/Next.js projects |
| Visual design, typography, motion, aesthetics | Frontend Designer | Distinctive UI, design systems |
| Test strategy, E2E, coverage | QA Analyst | Testing architecture, automation |
| Monitoring, SLOs, performance, reliability | SRE | Observability, incident response |

---

## Choosing Between Generalist and Specialist Agents

### Backend Engineers

**Use `ring-dev-team:backend-engineer` (language-agnostic) when:**
- Language hasn't been decided yet
- Comparing multiple language options
- Multi-language system architecture
- You want recommendations on language choice

**Use language-specific engineers when:**
- Language is already decided
- You need framework-specific guidance (NestJS, FastAPI, etc.)
- Performance optimization for specific runtime
- Language-specific patterns and idioms

**Example decision:**
- "Should I use Go or TypeScript?" → **`ring-dev-team:backend-engineer`** (agnostic)
- "How do I optimize this Go service?" → **`ring-dev-team:backend-engineer-golang`**

### Frontend Engineers

**Use `ring-dev-team:frontend-engineer` (general) when:**
- Standard React/Next.js projects
- TypeScript is used but not central concern
- Focus on component design, state, architecture
- General frontend best practices

**Use `ring-dev-team:frontend-engineer-typescript` when:**
- TypeScript is central to project success
- Need advanced type patterns (branded types, generics)
- Type-safe API integration (tRPC, Zod)
- Migrating JavaScript to TypeScript
- Strict type safety requirements

**Example decision:**
- "Build a React dashboard" → **`ring-dev-team:frontend-engineer`**
- "Build type-safe full-stack with tRPC" → **`ring-dev-team:frontend-engineer-typescript`**

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

**Agents:**
- backend-engineer (language-agnostic)
- backend-engineer-golang
- backend-engineer-typescript
- devops-engineer
- frontend-engineer
- frontend-engineer-typescript
- frontend-designer
- qa-analyst
- sre

**Skills:**
- ring-dev-team:using-dev-team: Plugin introduction and agent selection guide
- ring-dev-team:dev-cycle: 6-gate development workflow (Implementation → DevOps → SRE → Testing → Review → Validation)
- ring-dev-team:dev-analysis: Analyze codebase against STANDARDS.md, generate refactoring tasks

**Commands:**
- `/ring-dev-team:dev-cycle` – Execute development cycle for tasks
- `/ring-dev-team:dev-refactor` – Analyze and refactor existing codebase

**Note:** If a skill documents a developer agent but you can't find it, you may not have ring-dev-team enabled. Check `.claude-plugin/marketplace.json` or install ring-dev-team plugin.

---

## Development Workflows

The dev-team plugin provides three unified workflows that all use the same 6-gate development cycle:

### 1. New Project / Feature (via PM Team)

```text
/ring-pm-team:pre-dev-feature "Add user authentication"
                    │
                    ▼
         docs/pre-dev/auth/tasks.md
                    │
                    ▼
/ring-dev-team:dev-cycle docs/pre-dev/auth/tasks.md
                    │
                    ▼
         6-Gate Development Cycle
```

### 2. Direct Task Execution

```text
/ring-dev-team:dev-cycle docs/tasks/sprint-001.md
                    │
                    ▼
         6-Gate Development Cycle
```

### 3. Refactoring Existing Code

```text
/ring-dev-team:dev-refactor
        │
        ▼
┌─────────────────────────────┐
│      dev-analysis           │
│                             │
│  • Scan codebase            │
│  • Compare vs STANDARDS.md  │
│  • Identify gaps            │
│  • Generate tasks.md        │
│  • User approval            │
└─────────────────────────────┘
        │
        ▼
docs/refactor/{timestamp}/tasks.md
        │
        ▼
/ring-dev-team:dev-cycle docs/refactor/{timestamp}/tasks.md
        │
        ▼
         6-Gate Development Cycle
```

### The 6-Gate Development Cycle

All workflows converge to the same execution process:

```text
┌─────────────────────────────────────────────────────────────┐
│                   6-GATE DEVELOPMENT CYCLE                  │
├─────────────────────────────────────────────────────────────┤
│ Gate 0: Implementation                                      │
│         • TDD: RED → GREEN → REFACTOR                       │
│         • Agents: backend-engineer-*, frontend-engineer-*   │
├─────────────────────────────────────────────────────────────┤
│ Gate 1: DevOps Setup                                        │
│         • Dockerfile, docker-compose.yml, .env.example      │
│         • Agent: devops-engineer                            │
├─────────────────────────────────────────────────────────────┤
│ Gate 2: SRE Validation                                      │
│         • Metrics, health checks, structured logging        │
│         • Agent: sre                                        │
├─────────────────────────────────────────────────────────────┤
│ Gate 3: Testing                                             │
│         • Unit tests, coverage ≥ 80%                        │
│         • Agent: qa-analyst                                 │
├─────────────────────────────────────────────────────────────┤
│ Gate 4: Review                                              │
│         • 3 reviewers IN PARALLEL                           │
│         • code-reviewer, business-logic, security           │
├─────────────────────────────────────────────────────────────┤
│ Gate 5: Validation                                          │
│         • User approval: APPROVED / REJECTED                │
│         • Evidence for each acceptance criterion            │
└─────────────────────────────────────────────────────────────┘
```

### Workflow Summary

| Scenario | Command | Input | Process |
|----------|---------|-------|---------|
| New feature | `/ring-pm-team:pre-dev-*` → `/ring-dev-team:dev-cycle` | User request | PM creates tasks → Dev executes |
| Direct tasks | `/ring-dev-team:dev-cycle` | tasks.md | Execute 6 gates |
| Refactoring | `/ring-dev-team:dev-refactor` | Existing codebase | Analyze → Generate tasks → Execute 6 gates |

**Key Principle:** All development follows the same standardized 6-gate process, whether it's a new feature, a bug fix, or a refactoring effort.

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
