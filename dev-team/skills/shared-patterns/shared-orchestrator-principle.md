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

**⛔ HARD GATE: Using any of these tools on source code = IMMEDIATE SKILL FAILURE**

```
❌ Read(file_path="*.go|*.ts|*.tsx|*.jsx")  → SKILL FAILURE - Agent reads code
❌ Write(file_path="*.go|*.ts|*.tsx|*.jsx") → SKILL FAILURE - Agent writes code
❌ Edit(file_path="*.go|*.ts|*.tsx|*.jsx")  → SKILL FAILURE - Agent edits code
❌ Bash(command="go test|npm test")         → SKILL FAILURE - Agent runs tests
❌ Direct code analysis                     → SKILL FAILURE - Agent analyzes
```

**⛔ EXPLICIT TOOL PROHIBITION:**

| Tool | On Source Files | Correct Action |
|------|-----------------|----------------|
| `Read` | ❌ FORBIDDEN | Dispatch `ring:codebase-explorer` or specialist agent |
| `Edit` | ❌ FORBIDDEN | Dispatch specialist agent to make changes |
| `Write` | ❌ FORBIDDEN | Dispatch specialist agent to create files |
| `Grep` on code | ❌ FORBIDDEN | Dispatch `ring:codebase-explorer` for pattern discovery |
| `Bash` (go/npm/yarn) | ❌ FORBIDDEN | Specialist agent runs commands |

**Source files include:** `*.go`, `*.ts`, `*.tsx`, `*.jsx`, `*.py`, `*.java`, `*.rs`, `*.rb`

**You MAY use tools on:**
- Task files (`tasks.md`, `findings.md`)
- State files (`*-state.json`)
- Report files (`*-report.md`)
- Ring plugin files (when maintaining Ring itself, not via ring:dev-refactor)

## REQUIRED Actions (Orchestrator)

### ring-dev-team Agents (Implementation)

```
✅ Task(subagent_type="ring:backend-engineer-golang", ...)
✅ Task(subagent_type="ring:backend-engineer-typescript", ...)
✅ Task(subagent_type="ring:frontend-engineer", ...)
✅ Task(subagent_type="ring:frontend-designer", ...)
✅ Task(subagent_type="ring:frontend-bff-engineer-typescript", ...)
✅ Task(subagent_type="ring:devops-engineer", ...)
✅ Task(subagent_type="ring:sre", ...)
✅ Task(subagent_type="ring:qa-analyst", ...)
✅ Task(subagent_type="ring:prompt-quality-reviewer", ...)
```

### ring-default Agents (Core)

```
✅ Task(subagent_type="ring:codebase-explorer", ...)
✅ Task(subagent_type="ring:code-reviewer", ...)
✅ Task(subagent_type="ring:business-logic-reviewer", ...)
✅ Task(subagent_type="ring:security-reviewer", ...)
✅ Task(subagent_type="ring:write-plan", ...)
```

### ring-pm-team Agents (Research)

```
✅ Task(subagent_type="ring:framework-docs-researcher", ...)
✅ Task(subagent_type="ring:best-practices-researcher", ...)
✅ Task(subagent_type="ring:repo-research-analyst", ...)
```

### ring-tw-team Agents (Technical Writing)

```
✅ Task(subagent_type="ring:functional-writer", ...)
✅ Task(subagent_type="ring:api-writer", ...)
✅ Task(subagent_type="ring:docs-reviewer", ...)
```

### ring-finops-team Agents (Regulatory Compliance)

```
✅ Task(subagent_type="ring:finops-analyzer", ...)
✅ Task(subagent_type="ring:finops-automation", ...)
```

## Gate Cadence Classification

Gates in dev-cycle operate at three cadences:

| Cadence | Gates (backend) | Gates (frontend) |
|---------|-----------------|------------------|
| **Subtask** | 0 (impl + delivery verify), 3 (unit test), 9 (validation) | 0, 3, 8 |
| **Task** | 1 (devops), 2 (sre), 4 (fuzz), 5 (property), 6 write, 7 write, 8 (review) | 1, 2, 4, 5, 6, 7 |
| **Cycle** | 6 execute, 7 execute, multi-tenant verify, dev-report, final commit | (minimal cycle-level) |

Sub-skills that run at task cadence receive input aggregated across all subtasks of
the task (e.g., `implementation_files` = UNION of all subtasks' changed files).

Sub-skills that run at subtask cadence receive input scoped to that single subtask.

See `shared-patterns/gate-cadence-classification.md` for the full classification and rationale.

## Gate/Step → Agent Mapping

### ring:dev-cycle Gates

| Gate | Specialized Agent | What Agent Does |
|------|-------------------|-----------------|
| 0 | `ring:backend-engineer-golang` | Implements Go code, adds observability, runs TDD |
| 0 | `ring:backend-engineer-typescript` | Implements TS backend code, adds observability, runs TDD |
| 0 | `ring:frontend-engineer` | Implements React/Next.js components, runs TDD |
| 0 | `ring:frontend-bff-engineer-typescript` | Implements BFF layer, API aggregation |
| 0 | `ring:frontend-designer` | Reviews UI/UX, accessibility, design system compliance |
| 1 | `ring:devops-engineer` | Updates Dockerfile, docker-compose, Helm |
| 2 | `ring:sre` | Validates observability implementation |
| 3 | `ring:qa-analyst` | Writes tests, validates coverage |
| 4 | `ring:code-reviewer` | Reviews code quality |
| 4 | `ring:business-logic-reviewer` | Reviews business logic |
| 4 | `ring:security-reviewer` | Reviews security |

### ring:dev-refactor Steps

| Step | Specialized Agent | What Agent Does |
|------|-------------------|-----------------|
| 3 | `ring:codebase-explorer` | Deep architecture analysis, pattern discovery |
| 4 | `ring:backend-engineer-golang` | Go standards compliance analysis |
| 4 | `ring:backend-engineer-typescript` | TypeScript standards compliance analysis |
| 4 | `ring:frontend-engineer` | Frontend standards compliance analysis |
| 4 | `ring:qa-analyst` | Test coverage and pattern analysis |
| 4 | `ring:devops-engineer` | DevOps setup analysis |
| 4 | `ring:sre` | Observability analysis |

## Agent Selection Guide

**Use this table to select the correct agent based on task type:**

### Code Implementation

| File Type / Task | Agent to Dispatch |
|------------------|-------------------|
| `*.go` files | `ring:backend-engineer-golang` |
| `*.ts` backend (Express, Fastify, NestJS) | `ring:backend-engineer-typescript` |
| `*.tsx` / `*.jsx` React components | `ring:frontend-engineer` |
| BFF / API Gateway layer | `ring:frontend-bff-engineer-typescript` |
| UI/UX review, design system | `ring:frontend-designer` |
| `Dockerfile`, `docker-compose.yml`, Helm | `ring:devops-engineer` |
| Logging, tracing | `ring:sre` |
| Test files (`*_test.go`, `*.spec.ts`) | `ring:qa-analyst` |

### Code Review (Always Parallel)

| Review Type | Agent to Dispatch |
|-------------|-------------------|
| Code quality, patterns, maintainability | `ring:code-reviewer` |
| Business logic, domain correctness | `ring:business-logic-reviewer` |
| Security vulnerabilities, auth, input validation | `ring:security-reviewer` |

### Research & Analysis

| Task Type | Agent to Dispatch |
|-----------|-------------------|
| Codebase architecture understanding | `ring:codebase-explorer` |
| Framework/library documentation | `ring:framework-docs-researcher` |
| Industry best practices | `ring:best-practices-researcher` |
| Repository/codebase analysis | `ring:repo-research-analyst` |

### Documentation

| Doc Type | Agent to Dispatch |
|----------|-------------------|
| Functional documentation, user guides | `ring:functional-writer` |
| API documentation, OpenAPI specs | `ring:api-writer` |
| Documentation review | `ring:docs-reviewer` |

### Planning & Quality

| Task Type | Agent to Dispatch |
|-----------|-------------------|
| Implementation planning | `ring:write-plan` |
| Prompt/agent quality analysis | `ring:prompt-quality-reviewer` |

## Agent Responsibilities (Implementation)

**Backend agents MUST implement observability as part of the code:**

| Responsibility | Description | When Required |
|----------------|-------------|---------------|
| **Structured Logging** | JSON logs with level, message, timestamp, service, trace_id | all code paths |
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
| "Small fix, 2 lines only" | Line count irrelevant. all code changes require specialist. | **DISPATCH specialist agent** |
| "Agent will do same thing I would" | Agent has Ring standards loaded. You're guessing without them. | **DISPATCH specialist agent** |

## Red Flags - STOP Immediately

**If you catch yourself doing any of these, STOP:**

| Red Flag | What You're Thinking | Why It's Wrong |
|----------|---------------------|----------------|
| Opening `*.go` or `*.ts` with Read | "Let me understand this file..." | Agent understands for you |
| About to use Edit on source | "Just a quick fix..." | No fix is "quick" without standards |
| About to use Write on source | "I'll create this file..." | Agent creates with observability |
| Running `go test` or `npm test` | "Checking if tests pass..." | Agent runs tests in TDD cycle |
| Analyzing code patterns | "Looking for the pattern..." | ring:codebase-explorer analyzes |
| "This is faster than dispatching" | Speed over quality | Agent quality > your speed |
| "The agent would do the same" | Assuming equivalence | Agent has standards, you don't |
| "It's just one line" | Minimizing scope | Scope is irrelevant |

**All of these = ORCHESTRATOR VIOLATION. Dispatch agent instead.**

## If You Violated This Principle

**⛔ RECOVERY PROCESS (MANDATORY):**

1. **STOP** current execution immediately
2. **ACKNOWLEDGE** the violation explicitly: "I violated the ORCHESTRATOR principle by [action]"
3. **DISCARD** any direct changes:
   ```bash
   git checkout -- <files you edited>
   # or for all changes:
   git checkout -- .
   ```
4. **DISPATCH** the correct specialist agent with the ORIGINAL task
5. **Agent implements** from scratch following TDD and Ring standards

**Sunk cost of direct work is IRRELEVANT. Specialist dispatch is MANDATORY.**

### Recovery Checklist

```text
[ ] Did I directly Read/Edit/Write source code? → VIOLATION
[ ] Did I run go test/npm test directly? → VIOLATION  
[ ] Did I use Grep to analyze source patterns? → VIOLATION
[ ] Did I make code changes without dispatching? → VIOLATION

If any checkbox is YES:
1. git checkout -- <affected files>
2. Dispatch correct specialist agent
3. Do not continue with direct changes
```

### What To Tell The User

If you violated and need to recover:

```markdown
## ORCHESTRATOR Violation Detected

I violated the ORCHESTRATOR principle by directly [editing/reading/analyzing] source code.

**Recovery actions:**
1. Discarding direct changes: `git checkout -- <files>`
2. Dispatching specialist agent: `[agent-name]`
3. Agent will implement correctly with Ring standards

**Proceeding with correct workflow...**
```

**If you find yourself using Read/Write/Edit/Bash on source code → STOP. Dispatch agent instead.**
