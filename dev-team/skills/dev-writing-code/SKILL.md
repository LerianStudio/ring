---
name: dev-writing-code
description: |
  Developer agent selection matrix - helps identify the best developer specialist
  based on technology stack, domain, and requirements.

trigger: |
  - Starting implementation work
  - Need to choose between multiple developer agents
  - Technology stack determines agent choice

skip_when: |
  - Already know which agent to use → dispatch directly
  - Not implementation work → use other skills
---

# Writing Code - Developer Agent Selection

## Purpose

This skill helps you identify and dispatch the most appropriate developer agent from the ring-dev-team plugin based on the task requirements.

## Available Developer Agents

| Agent | Specialization | Best For |
|-------|----------------|----------|
| `ring-dev-team:backend-engineer` | Language-agnostic backend (adapts to any language) | Unknown stack, polyglot systems, API design across languages |
| `ring-dev-team:backend-engineer-golang` | Go, APIs, microservices, databases, message queues | Go backend services, REST/gRPC APIs, database design, multi-tenancy |
| `ring-dev-team:backend-engineer-typescript` | TypeScript/Node.js, Express, Fastify, Prisma | Node.js backend, TypeScript APIs, full-stack TypeScript projects |
| `ring-dev-team:backend-engineer-python` | Python, FastAPI, Django, SQLAlchemy, Celery | Python backend, ML services, data pipelines, FastAPI/Django APIs |
| `ring-dev-team:frontend-engineer` | React, Next.js, TypeScript, state management | UI components, dashboards, forms, client-side logic |
| `ring-dev-team:frontend-engineer-typescript` | TypeScript-first React/Next.js, type-safe state | Type-heavy frontends, complex state, full-stack TypeScript |
| `ring-dev-team:frontend-designer` | Visual design, typography, UI aesthetics | Landing pages, marketing sites, design systems, distinctive interfaces |
| `ring-dev-team:devops-engineer` | CI/CD, Docker, Kubernetes, Terraform, IaC | Pipelines, containerization, infrastructure, deployment |
| `ring-dev-team:qa-analyst` | Test strategy, E2E, performance testing | Test plans, automation frameworks, quality gates |
| `ring-dev-team:sre` | Monitoring, observability, reliability | Alerting, SLOs, incident response, performance |

## Decision Matrix

### By Technology Stack

```
Backend work?
├── Go/Golang code?
│   └── Yes → ring-dev-team:backend-engineer-golang
├── TypeScript/Node.js backend?
│   └── Yes → ring-dev-team:backend-engineer-typescript
├── Python backend (FastAPI/Django)?
│   └── Yes → ring-dev-team:backend-engineer-python
├── Unknown/multiple languages?
│   └── Yes → ring-dev-team:backend-engineer (language-agnostic)
└── Frontend work?
    ├── React/Next.js?
    │   ├── TypeScript-heavy with complex state?
    │   │   └── Yes → ring-dev-team:frontend-engineer-typescript
    │   ├── Visual design/UI aesthetics focus?
    │   │   └── Yes → ring-dev-team:frontend-designer
    │   └── Component logic/functionality focus?
    │       └── Yes → ring-dev-team:frontend-engineer
    ├── Infrastructure/CI-CD/Docker?
    │   └── Yes → ring-dev-team:devops-engineer
    ├── Testing/QA/Automation?
    │   └── Yes → ring-dev-team:qa-analyst
    └── Monitoring/Reliability/Performance?
        └── Yes → ring-dev-team:sre
```

### By Task Type

| Task | Primary Agent | Supporting Agent |
|------|---------------|------------------|
| Build REST API (Go) | `ring-dev-team:backend-engineer-golang` | `ring-dev-team:qa-analyst` (tests) |
| Build REST API (TypeScript) | `ring-dev-team:backend-engineer-typescript` | `ring-dev-team:qa-analyst` (tests) |
| Build REST API (Python) | `ring-dev-team:backend-engineer-python` | `ring-dev-team:qa-analyst` (tests) |
| Build REST API (unknown language) | `ring-dev-team:backend-engineer` | `ring-dev-team:qa-analyst` (tests) |
| Create UI component | `ring-dev-team:frontend-engineer` | `ring-dev-team:qa-analyst` (E2E) |
| Create type-safe UI component | `ring-dev-team:frontend-engineer-typescript` | `ring-dev-team:qa-analyst` (E2E) |
| Design landing page | `ring-dev-team:frontend-designer` | `ring-dev-team:frontend-engineer` (implementation) |
| Full-stack TypeScript feature | `ring-dev-team:backend-engineer-typescript` | `ring-dev-team:frontend-engineer-typescript` |
| Set up CI/CD | `ring-dev-team:devops-engineer` | `ring-dev-team:sre` (monitoring) |
| Write test suite | `ring-dev-team:qa-analyst` | - |
| Add monitoring | `ring-dev-team:sre` | `ring-dev-team:devops-engineer` (infra) |
| Database schema (Go) | `ring-dev-team:backend-engineer-golang` | - |
| Database schema (TypeScript) | `ring-dev-team:backend-engineer-typescript` | - |
| Database schema (Python) | `ring-dev-team:backend-engineer-python` | - |
| Deploy to K8s | `ring-dev-team:devops-engineer` | `ring-dev-team:sre` (observability) |
| Performance optimization | `ring-dev-team:sre` | `ring-dev-team:backend-engineer-*` |

## Agent Dispatch Pattern

### Single Agent Task

```
Task tool:
  subagent_type: "ring-dev-team:backend-engineer-golang"
  prompt: "Design and implement a REST API for user authentication with JWT tokens"
```

### Multi-Agent Workflow

For complex features requiring multiple specialists:

```
Step 1: Backend API
  Task tool → ring-dev-team:backend-engineer-golang
  "Implement the user service with CRUD operations"

Step 2: Frontend Integration
  Task tool → ring-dev-team:frontend-engineer
  "Create React components to consume the user API"

Step 3: Testing
  Task tool → ring-dev-team:qa-analyst
  "Write E2E tests for the user registration flow"

Step 4: Deployment
  Task tool → ring-dev-team:devops-engineer
  "Create Kubernetes manifests and CI/CD pipeline"

Step 5: Observability
  Task tool → ring-dev-team:sre
  "Add monitoring, alerting, and SLO definitions"
```

## Agent Capabilities Detail

### backend-engineer

**Technologies:**
- Language-agnostic (adapts to Go, TypeScript, Python, Java, Rust, etc.)
- RESTful API design principles
- Database design (SQL and NoSQL)
- Message queues and event streaming
- Authentication and authorization patterns

**Patterns:**
- Clean Architecture / Hexagonal
- Repository pattern
- Dependency injection
- SOLID principles
- API design best practices

**Best practices:**
- Language-appropriate error handling
- Security best practices (OWASP)
- Scalability and performance
- Testing strategies
- Documentation standards

**When to use:**
- Codebase uses unknown or multiple languages
- Need language-agnostic architecture advice
- Polyglot systems requiring consistency
- Initial API design before language selection

### backend-engineer-golang

**Technologies:**
- Go (Fiber, Gin, Echo frameworks)
- PostgreSQL, MongoDB, Redis
- RabbitMQ, Kafka
- gRPC, REST
- OAuth2, JWT, WorkOS

**Patterns:**
- Clean Architecture / Hexagonal
- Repository pattern
- Dependency injection
- Multi-tenancy (schema-per-tenant, row-level)

**Best practices:**
- Error handling (no panic in production)
- Context propagation
- Graceful shutdown
- Connection pooling

### backend-engineer-typescript

**Technologies:**
- TypeScript, Node.js
- Express, Fastify, NestJS
- Prisma, TypeORM, Sequelize
- PostgreSQL, MongoDB, Redis
- Bull, BullMQ (job queues)
- JWT, Passport.js, OAuth2

**Patterns:**
- Layered architecture
- Dependency injection (NestJS, tsyringe)
- Repository pattern
- DTO validation (class-validator, Zod)
- Middleware patterns

**Best practices:**
- Strict TypeScript configuration
- Async/await error handling
- Type-safe database queries
- Request validation
- Graceful shutdown
- Logging and observability

### backend-engineer-python

**Technologies:**
- Python 3.10+
- FastAPI, Django, Flask
- SQLAlchemy, Django ORM
- PostgreSQL, MongoDB, Redis
- Celery, RQ (task queues)
- Pydantic (validation)
- pytest, unittest

**Patterns:**
- MVC / MVT (Django)
- Dependency injection (FastAPI)
- Repository pattern
- Service layer pattern
- Type hints and validation

**Best practices:**
- Type hints everywhere
- Exception handling
- Virtual environments
- Async/await (asyncio)
- Database migrations (Alembic)
- API documentation (OpenAPI)

### frontend-engineer

**Technologies:**
- React 18+, Next.js 14+
- TypeScript
- Tailwind CSS, Styled Components
- React Query, Zustand, Redux
- Jest, React Testing Library, Playwright

**Patterns:**
- Component composition
- Custom hooks
- Server components (Next.js)
- Optimistic updates

**Best practices:**
- Accessibility (WCAG 2.1)
- Performance (Core Web Vitals)
- Type safety
- Error boundaries

### frontend-engineer-typescript

**Technologies:**
- TypeScript (strict mode)
- React 18+, Next.js 14+
- Zod, io-ts (runtime validation)
- tRPC (end-to-end type safety)
- TanStack Query (React Query)
- Zustand, Jotai (type-safe state)
- Vitest, Jest with type coverage

**Patterns:**
- Type-driven development
- Generic components with type constraints
- Discriminated unions for state
- Type-safe API clients
- Schema-driven forms

**Best practices:**
- No `any` types (strict mode)
- Type guards and narrowing
- Exhaustive switch statements
- Runtime validation at boundaries
- Type-safe routing
- Inference over explicit types

### frontend-designer

**Technologies:**
- Figma, Sketch design systems
- Tailwind CSS, CSS-in-JS
- Typography systems (Google Fonts, custom fonts)
- Animation libraries (Framer Motion, GSAP)
- Color theory and accessibility tools

**Patterns:**
- Visual hierarchy
- Responsive design principles
- Design tokens
- Component variants

**Best practices:**
- Accessible color contrast (WCAG AA/AAA)
- Responsive typography scales
- Consistent spacing systems
- Performance-optimized assets
- Brand consistency

### devops-engineer

**Technologies:**
- Docker, Docker Compose
- Kubernetes, Helm
- Terraform, Pulumi
- GitHub Actions, GitLab CI
- AWS, GCP, Azure

**Patterns:**
- GitOps
- Infrastructure as Code
- Blue-green / Canary deployments
- Secret management

**Best practices:**
- Immutable infrastructure
- Least privilege
- Automated rollbacks
- Cost optimization

### qa-analyst

**Technologies:**
- Jest, Vitest, Go testing
- Playwright, Cypress
- k6, Artillery (load testing)
- Postman, Newman

**Patterns:**
- Test pyramid
- Page Object Model
- Data-driven testing
- Contract testing

**Best practices:**
- Shift-left testing
- Test isolation
- Deterministic tests
- CI integration

### sre

**Technologies:**
- Prometheus, Grafana
- Datadog, New Relic
- PagerDuty, OpsGenie
- Jaeger, OpenTelemetry

**Patterns:**
- SLI/SLO/SLA definitions
- Error budgets
- Incident management
- Chaos engineering

**Best practices:**
- Alerting hygiene
- Runbooks
- Post-mortems
- Capacity planning

## When NOT to Use Developer Agents

- **Code review** → Use `ring-default:code-reviewer` (parallel with business-logic and security)
- **Planning/Design** → Use `ring-default:brainstorming` or `ring-default:write-plan`
- **Debugging** → Use `ring-default:systematic-debugging` skill
- **Architecture exploration** → Use `ring-default:codebase-explorer`

## Integration with Ring Workflows

### With TDD (test-driven-development)

```
1. Use `ring-dev-team:qa-analyst` to design test cases
2. Use appropriate developer agent to implement
3. Use `ring-dev-team:qa-analyst` to verify test coverage
```

### With Code Review (requesting-code-review)

```
1. Use developer agent to implement
2. Use ring-default reviewers (parallel) to review
3. Use developer agent to address findings
```

### With Pre-Dev Planning

```
1. Use pm-team skills for planning (PRD, TRD)
2. Use ring-default:write-plan for implementation plan
3. Use this skill to identify developer agents for each task
4. Dispatch agents per task with code review between
```

## Remember

1. **Match agent to task** - Don't use backend agent for frontend work
2. **Combine agents for full-stack** - Complex features need multiple specialists
3. **Always review** - Use code reviewers after implementation
4. **Follow skill workflows** - TDD, systematic debugging, verification
5. **Document decisions** - Agents can explain their choices
