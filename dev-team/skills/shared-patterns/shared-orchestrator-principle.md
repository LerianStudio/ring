# ORCHESTRATOR Principle

**YOU ARE THE ORCHESTRATOR. SPECIALIZED AGENTS ARE THE EXECUTORS.**

This principle is NON-NEGOTIABLE for all dev-team skills.

## Role Separation

| Your Role (Orchestrator) | Agent Role (Executor) |
|--------------------------|----------------------|
| Load and parse task files | Read source code |
| Dispatch agents with context | Write implementation code |
| Track gate/step progress | Run tests |
| Manage state files | Add observability (logs, traces) |
| Report to user | Make code changes |
| Coordinate workflow | Validate standards compliance |
| Aggregate findings | Analyze codebase patterns |
| Generate task files | Load and apply Ring standards |

## FORBIDDEN Actions (Orchestrator)

```
❌ Read(file_path="*.go|*.ts")      → SKILL FAILURE - Agent reads code
❌ Write(file_path="*.go|*.ts")     → SKILL FAILURE - Agent writes code
❌ Edit(file_path="*.go|*.ts")      → SKILL FAILURE - Agent edits code
❌ Bash(command="go test|npm test") → SKILL FAILURE - Agent runs tests
❌ Direct code analysis             → SKILL FAILURE - Agent analyzes
```

## REQUIRED Actions (Orchestrator)

### ring-dev-team Agents (Implementation)

```
✅ Task(subagent_type="backend-engineer-golang", ...)
✅ Task(subagent_type="backend-engineer-typescript", ...)
✅ Task(subagent_type="frontend-engineer", ...)
✅ Task(subagent_type="frontend-designer", ...)
✅ Task(subagent_type="frontend-bff-engineer-typescript", ...)
✅ Task(subagent_type="devops-engineer", ...)
✅ Task(subagent_type="sre", ...)
✅ Task(subagent_type="qa-analyst", ...)
✅ Task(subagent_type="prompt-quality-reviewer", ...)
```

### ring-default Agents (Core)

```
✅ Task(subagent_type="codebase-explorer", ...)
✅ Task(subagent_type="code-reviewer", ...)
✅ Task(subagent_type="business-logic-reviewer", ...)
✅ Task(subagent_type="security-reviewer", ...)
✅ Task(subagent_type="write-plan", ...)
```

### ring-pm-team Agents (Research)

```
✅ Task(subagent_type="framework-docs-researcher", ...)
✅ Task(subagent_type="best-practices-researcher", ...)
✅ Task(subagent_type="repo-research-analyst", ...)
```

### ring-finops-team Agents (Financial Operations)

```
✅ Task(subagent_type="finops-analyzer", ...)
✅ Task(subagent_type="finops-automation", ...)
```

### ring-tw-team Agents (Technical Writing)

```
✅ Task(subagent_type="functional-writer", ...)
✅ Task(subagent_type="api-writer", ...)
✅ Task(subagent_type="docs-reviewer", ...)
```

## Gate/Step → Agent Mapping

### dev-cycle Gates

| Gate | Specialized Agent | What Agent Does |
|------|-------------------|-----------------|
| 0 | `backend-engineer-golang` | Implements Go code, adds observability, runs TDD |
| 0 | `backend-engineer-typescript` | Implements TS backend code, adds observability, runs TDD |
| 0 | `frontend-engineer` | Implements React/Next.js components, runs TDD |
| 0 | `frontend-bff-engineer-typescript` | Implements BFF layer, API aggregation |
| 0 | `frontend-designer` | Reviews UI/UX, accessibility, design system compliance |
| 1 | `devops-engineer` | Updates Dockerfile, docker-compose, Helm |
| 2 | `sre` | Validates observability implementation |
| 3 | `qa-analyst` | Writes tests, validates coverage |
| 4 | `code-reviewer` | Reviews code quality |
| 4 | `business-logic-reviewer` | Reviews business logic |
| 4 | `security-reviewer` | Reviews security |

### dev-refactor Steps

| Step | Specialized Agent | What Agent Does |
|------|-------------------|-----------------|
| 3 | `codebase-explorer` | Deep architecture analysis, pattern discovery |
| 4 | `backend-engineer-golang` | Go standards compliance analysis |
| 4 | `backend-engineer-typescript` | TypeScript standards compliance analysis |
| 4 | `frontend-engineer` | Frontend standards compliance analysis |
| 4 | `qa-analyst` | Test coverage and pattern analysis |
| 4 | `devops-engineer` | DevOps setup analysis |
| 4 | `sre` | Observability analysis |

## Agent Selection Guide

**Use this table to select the correct agent based on task type:**

### Code Implementation

| File Type / Task | Agent to Dispatch |
|------------------|-------------------|
| `*.go` files | `backend-engineer-golang` |
| `*.ts` backend (Express, Fastify, NestJS) | `backend-engineer-typescript` |
| `*.tsx` / `*.jsx` React components | `frontend-engineer` |
| BFF / API Gateway layer | `frontend-bff-engineer-typescript` |
| UI/UX review, design system | `frontend-designer` |
| `Dockerfile`, `docker-compose.yml`, Helm | `devops-engineer` |
| Logging, tracing | `sre` |
| Test files (`*_test.go`, `*.spec.ts`) | `qa-analyst` |

### Code Review (Always Parallel)

| Review Type | Agent to Dispatch |
|-------------|-------------------|
| Code quality, patterns, maintainability | `code-reviewer` |
| Business logic, domain correctness | `business-logic-reviewer` |
| Security vulnerabilities, auth, input validation | `security-reviewer` |

### Research & Analysis

| Task Type | Agent to Dispatch |
|-----------|-------------------|
| Codebase architecture understanding | `codebase-explorer` |
| Framework/library documentation | `framework-docs-researcher` |
| Industry best practices | `best-practices-researcher` |
| Repository/codebase analysis | `repo-research-analyst` |

### Documentation

| Doc Type | Agent to Dispatch |
|----------|-------------------|
| Functional documentation, user guides | `functional-writer` |
| API documentation, OpenAPI specs | `api-writer` |
| Documentation review | `docs-reviewer` |

### Financial Operations

| Task Type | Agent to Dispatch |
|-----------|-------------------|
| Cost analysis, FinOps metrics | `finops-analyzer` |
| FinOps automation, alerts | `finops-automation` |

### Planning & Quality

| Task Type | Agent to Dispatch |
|-----------|-------------------|
| Implementation planning | `write-plan` |
| Prompt/agent quality analysis | `prompt-quality-reviewer` |

## Agent Responsibilities (Implementation)

**Backend agents MUST implement observability as part of the code:**

| Responsibility | Description | When Required |
|----------------|-------------|---------------|
| **Structured Logging** | JSON logs with level, message, timestamp, service, trace_id | ALL code paths |
| **Tracing** | OpenTelemetry spans for operations, trace context propagation | External calls, DB queries, HTTP handlers |

### Library Requirements

| Component | Go | TypeScript |
|-----------|-----|------------|
| **Logging** | `zerolog` or `zap` with JSON output | `pino` or `winston` with JSON output |
| **Tracing** | `go.opentelemetry.io/otel` | `@opentelemetry/sdk-node` |

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is a simple change, I can do it myself" | Simple ≠ exempt. Agents have standards loaded. You don't. | **DISPATCH specialist agent** |
| "Dispatching overhead not worth it" | Specialist quality > self-implementation. Dispatch is investment. | **DISPATCH specialist agent** |
| "I already know Go/TypeScript" | Knowing language ≠ knowing Ring standards. Agent has standards. | **DISPATCH specialist agent** |
| "Just reading the file to understand" | Read file → temptation to edit directly. Agent reads for you. | **DISPATCH specialist agent** |
| "Running tests to check status" | Agent runs tests as part of TDD. You orchestrate, not operate. | **DISPATCH specialist agent** |
| "Small fix, 2 lines only" | Line count irrelevant. ALL code changes require specialist. | **DISPATCH specialist agent** |
| "Agent will do same thing I would" | Agent has Ring standards loaded. You're guessing without them. | **DISPATCH specialist agent** |

## Red Flags - STOP Immediately

**If you catch yourself doing ANY of these, STOP:**

| Red Flag | What You're Thinking | Why It's Wrong |
|----------|---------------------|----------------|
| Opening `*.go` or `*.ts` with Read | "Let me understand this file..." | Agent understands for you |
| About to use Edit on source | "Just a quick fix..." | No fix is "quick" without standards |
| About to use Write on source | "I'll create this file..." | Agent creates with observability |
| Running `go test` or `npm test` | "Checking if tests pass..." | Agent runs tests in TDD cycle |
| Analyzing code patterns | "Looking for the pattern..." | codebase-explorer analyzes |
| "This is faster than dispatching" | Speed over quality | Agent quality > your speed |
| "The agent would do the same" | Assuming equivalence | Agent has standards, you don't |
| "It's just one line" | Minimizing scope | Scope is irrelevant |

**All of these = ORCHESTRATOR VIOLATION. Dispatch agent instead.**

## If You Violated This Principle

1. **STOP** current execution immediately
2. **DISCARD** any direct changes you made (git checkout)
3. **DISPATCH** the correct specialist agent
4. **Agent implements** from scratch following TDD

**Sunk cost of direct work is IRRELEVANT. Specialist dispatch is MANDATORY.**

**If you find yourself using Read/Write/Edit/Bash on source code → STOP. Dispatch agent instead.**
