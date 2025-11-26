---
name: using-developers
description: Specialist developer agents for Go backend, DevOps, frontend, QA, and SRE - dispatch when you need deep expertise
when_to_use: When you need specialized developer expertise beyond general code review - use when implementing complex backend systems, infrastructure, frontend applications, test strategies, or reliability solutions
---

# Using Ring Developer Specialists

The ring-developers plugin provides 5 specialized developer agents. Use them via `Task tool with subagent_type:`.

**Remember:** Follow the **ORCHESTRATOR principle** from `using-ring`. Dispatch agents to handle complexity; don't operate tools directly.

---

## 5 Developer Specialists

### 1. Backend Engineer (Go)
**`ring-developers:backend-engineer-golang`**

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
  subagent_type: "ring-developers:backend-engineer-golang"
  model: "opus"
  prompt: "Design a Go service for user authentication with JWT and OAuth2 support"
```

---

### 2. DevOps Engineer
**`ring-developers:devops-engineer`**

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
  subagent_type: "ring-developers:devops-engineer"
  model: "opus"
  prompt: "Create a GitHub Actions CI/CD pipeline for Go service deployment to Kubernetes"
```

---

### 3. Frontend Engineer
**`ring-developers:frontend-engineer`**

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
  subagent_type: "ring-developers:frontend-engineer"
  model: "opus"
  prompt: "Design a React dashboard with real-time data updates and TypeScript"
```

---

### 4. QA Analyst
**`ring-developers:qa-analyst`**

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
  subagent_type: "ring-developers:qa-analyst"
  model: "opus"
  prompt: "Create a comprehensive E2E test strategy for user authentication flow"
```

---

### 5. Site Reliability Engineer (SRE)
**`ring-developers:sre`**

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
  subagent_type: "ring-developers:sre"
  model: "opus"
  prompt: "Design monitoring and alerting for a Go microservice with 99.9% SLO"
```

---

## Decision Matrix: Which Specialist?

| Need | Specialist | Use Case |
|------|-----------|----------|
| Go API, database, concurrency | Backend Engineer | Service architecture, optimization |
| CI/CD, Docker, Kubernetes, IaC | DevOps Engineer | Deployment pipelines, infrastructure |
| React, TypeScript, components, state | Frontend Engineer | UI development, performance |
| Test strategy, E2E, coverage | QA Analyst | Testing architecture, automation |
| Monitoring, SLOs, performance, reliability | SRE | Observability, incident response |

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
Task #1: ring-developers:backend-engineer-golang
Task #2: ring-developers:devops-engineer
(Both run in parallel)

❌ WRONG:
Task #1: ring-developers:backend-engineer-golang
(Wait for response)
Task #2: ring-developers:devops-engineer
(Sequential = 2x slower)
```

---

## ORCHESTRATOR Principle

Remember:
- **You're the orchestrator** – Dispatch specialists, don't implement directly
- **Don't read specialist docs yourself** – Dispatch to specialist, they know their domain
- **Combine with using-ring principle** – Skills + Specialists = complete workflow

### Good Example (ORCHESTRATOR):
> "I need a Go service. Let me dispatch backend-engineer-golang to design it."

### Bad Example (OPERATOR):
> "I'll manually read Go best practices and design the service myself."

---

## Available in This Plugin

**Agents:**
- backend-engineer-golang
- devops-engineer
- frontend-engineer
- qa-analyst
- sre

**Skills:**
- using-developers (this skill)

**Note:** If a skill documents a developer agent but you can't find it, you may not have ring-developers enabled. Check `.claude-plugin/marketplace.json` or install ring-developers plugin.

---

## Integration with Other Plugins

- **using-ring** (default) – ORCHESTRATOR principle for ALL agents
- **using-product-reporter** – Financial/regulatory agents
- **using-team-product** – Pre-dev workflow agents

Dispatch based on your need:
- General code review → default plugin agents
- Specific domain expertise → ring-developers agents
- Regulatory compliance → ring-product-reporter agents
- Feature planning → ring-team-product agents
