# Ring Marketplace Manual

Quick reference guide for the Ring skills library and workflow system. This monorepo provides 6 plugins with 89 skills, 38 agents, and 33 slash commands for enforcing proven software engineering practices across the entire software delivery value chain.

---

## 🏗️ Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                              MARKETPLACE (6 PLUGINS)                               │
│                     (monorepo: .claude-plugin/marketplace.json)                    │
│                                                                                    │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐      │
│  │ ring-default  │  │ ring-dev-team │  │ ring-pm-team  │  │ring-finops-   │      │
│  │  Skills(22)   │  │  Skills(29)   │  │  Skills(15)   │  │  team         │      │
│  │  Agents(10)   │  │  Agents(12)   │  │  Agents(4)    │  │  Skills(7)    │      │
│  │  Cmds(14)     │  │  Cmds(9)      │  │  Cmds(3)      │  │  Agents(3)    │      │
│  └───────────────┘  └───────────────┘  └───────────────┘  └───────────────┘      │
│  ┌───────────────┐  ┌───────────────┐                                            │
│  │ ring-tw-team  │  │ ring-pmo-team │                                            │
│  │  Skills(7)    │  │  Skills(9)    │                                            │
│  │  Agents(3)    │  │  Agents(6)    │                                            │
│  │  Cmds(3)      │  │  Cmds(4)      │                                            │
│  └───────────────┘  └───────────────┘                                            │
└────────────────────────────────────────────────────────────────────────────────────┘

                              HOW IT WORKS
                              ────────────

    ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
    │   SESSION    │         │    USER      │         │  CLAUDE CODE │
    │    START     │────────▶│   PROMPT     │────────▶│   WORKING    │
    └──────────────┘         └──────────────┘         └──────────────┘
           │                        │                        │
           ▼                        ▼                        ▼
    ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
    │    HOOKS     │         │   COMMANDS   │         │    SKILLS    │
    │ auto-inject  │         │ user-invoked │         │ auto-applied │
    │   context    │         │  /ring:...   │         │  internally  │
    └──────────────┘         └──────────────┘         └──────────────┘
           │                        │                        │
           │                        ▼                        │
           │                 ┌──────────────┐                │
           └────────────────▶│    AGENTS    │◀───────────────┘
                             │  dispatched  │
                             │  for work    │
                             └──────────────┘

                            COMPONENT ROLES
                            ───────────────

    ┌────────────┬──────────────────────────────────────────────────┐
    │ Component  │ Purpose                                          │
    ├────────────┼──────────────────────────────────────────────────┤
    │ MARKETPLACE│ Monorepo containing all plugins                  │
    │ PLUGIN     │ Self-contained package (skills+agents+commands)  │
    │ HOOK       │ Auto-runs at session events (injects context)    │
    │ SKILL      │ Workflow pattern (Claude Code uses internally)   │
    │ COMMAND    │ User-invokable action (/ring:codereview)         │
    │ AGENT      │ Specialized subprocess (Task tool dispatch)      │
    └────────────┴──────────────────────────────────────────────────┘
```

---

## 🎯 Quick Start

Ring is auto-loaded at session start. Three ways to invoke Ring capabilities:

1. **Slash Commands** – `/command-name`
2. **Skills** – `Skill tool: "ring:skill-name"`
3. **Agents** – `Task tool with subagent_type: "ring:agent-name"`

---

## 📋 Slash Commands

Commands are invoked directly: `/command-name`.

### Project & Feature Workflows

| Command                         | Use Case                                    | Example                                            |
| ------------------------------- | ------------------------------------------- | -------------------------------------------------- |
| `/ring:brainstorm [topic]`      | Interactive design refinement before coding | `/ring:brainstorm user-authentication`             |
| `/ring:explore-codebase [path]` | Autonomous two-phase codebase exploration   | `/ring:explore-codebase payment/`                  |
| `/ring:interview-me [topic]`    | Proactive requirements gathering interview  | `/ring:interview-me auth-system`                   |
| `/ring:md-to-html [file]`       | Transform a markdown file into an HTML page | `/ring:md-to-html architecture.md`                 |
| `/ring:diagram [topic]`         | Generate a Mermaid diagram                  | `/ring:diagram payment-flow`                       |
| `/ring:visualize [topic]`       | Generate visual explanation                 | `/ring:visualize auth-architecture`                |
| `/ring:release-guide`           | Generate step-by-step release instructions  | `/ring:release-guide`                              |
| `/ring:pre-dev-feature [name]`  | Plan simple features (<2 days) – 5 gates    | `/ring:pre-dev-feature logout-button`              |
| `/ring:pre-dev-full [name]`     | Plan complex features (≥2 days) – 10 gates  | `/ring:pre-dev-full payment-system`                |
| `/ring:worktree [branch-name]`  | Create isolated git workspace               | `/ring:worktree auth-system`                       |
| `/ring:write-plan [feature]`    | Generate detailed task breakdown            | `/ring:write-plan dashboard-redesign`              |
| `/ring:execute-plan [path]`     | Execute plan in batches with checkpoints    | `/ring:execute-plan docs/pre-dev/feature/tasks.md` |
| `/ring:delivery-status`         | Show delivery status and tracking           | `/ring:delivery-status`                            |

### Code & Integration Workflows

| Command                             | Use Case                                       | Example                                              |
| ----------------------------------- | ---------------------------------------------- | ---------------------------------------------------- |
| `/ring:codereview [files-or-paths]` | Dispatch 7 parallel code reviewers             | `/ring:codereview src/auth/`                         |
| `/ring:commit [message]`            | Create git commit with AI trailers             | `/ring:commit "fix(auth): improve token validation"` |
| `/ring:lint [path]`                 | Run lint and dispatch agents to fix all issues | `/ring:lint src/`                                    |

### Session Management

| Command                       | Use Case                                                      | Example                              |
| ----------------------------- | ------------------------------------------------------------- | ------------------------------------ |
| `/ring:create-handoff [name]` | Create handoff document before /clear (auto-resumes via hook) | `/ring:create-handoff auth-refactor` |

### Development Cycle (ring-dev-team)

| Command                     | Use Case                           | Example                                 |
| --------------------------- | ---------------------------------- | --------------------------------------- |
| `/ring:dev-cycle [task]`    | Start 10-gate development workflow | `/ring:dev-cycle "implement user auth"` |
| `/ring:dev-cycle-frontend [task]` | Start 9-gate frontend workflow | `/ring:dev-cycle-frontend "improve dashboard UX"` |
| `/ring:dev-refactor [path]` | Analyze codebase against standards | `/ring:dev-refactor src/`               |
| `/ring:dev-refactor-frontend [path]` | Analyze frontend against standards | `/ring:dev-refactor-frontend web/` |
| `/ring:dev-service-discovery [path]` | Scan service/module/resource hierarchy | `/ring:dev-service-discovery .` |
| `/ring:dev-status`          | Show current gate progress         | `/ring:dev-status`                      |
| `/ring:dev-report`          | Generate development cycle report  | `/ring:dev-report`                      |
| `/ring:dev-cancel`          | Cancel active development cycle    | `/ring:dev-cancel`                      |
| `/ring:migrate-v4 [path]`  | Analyze Go service for lib-commons v4 migration | `/ring:migrate-v4 src/`        |

### Technical Writing (Documentation)

| Command                      | Use Case                         | Example                            |
| ---------------------------- | -------------------------------- | ---------------------------------- |
| `/ring:write-guide [topic]`  | Start writing a functional guide | `/ring:write-guide authentication` |
| `/ring:write-api [endpoint]` | Start writing API documentation  | `/ring:write-api POST /accounts`   |
| `/ring:review-docs [file]`   | Review documentation for quality | `/ring:review-docs docs/guide.md`  |

### PMO Portfolio (ring-pmo-team)

| Command                             | Use Case                         | Example                                    |
| ----------------------------------- | -------------------------------- | ------------------------------------------ |
| `/ring:portfolio-review [scope]`    | Comprehensive portfolio review   | `/ring:portfolio-review Q1-2025`           |
| `/ring:dependency-analysis [scope]` | Cross-project dependency mapping | `/ring:dependency-analysis payment-system` |
| `/ring:executive-summary [scope]`   | Executive status summary         | `/ring:executive-summary board-meeting`    |
| `/ring:delivery-report [scope]`     | Generate delivery status report  | `/ring:delivery-report Q1-2025`            |

---

## 💡 About Skills

Skills (89) are workflows that Claude Code invokes automatically when it detects they're applicable. They handle testing, debugging, verification, planning, and code review enforcement. You don't call them directly - Claude Code uses them internally to enforce best practices.

Examples: ring:test-driven-development, ring:systematic-debugging, ring:requesting-code-review, ring:verification-before-completion, ring:production-readiness-audit (44-dimension audit, up to 10 explorers per batch, incremental report 0-430, max 440 with multi-tenant; see [default/skills/production-readiness-audit/SKILL.md](default/skills/production-readiness-audit/SKILL.md)), etc.

### Skill Selection Criteria

Each skill has structured frontmatter that helps Claude Code determine which skill to use:

| Field         | Purpose                           | Example                                  |
| ------------- | --------------------------------- | ---------------------------------------- |
| `description` | WHAT the skill does               | "Four-phase debugging framework..."      |
| `trigger`     | WHEN to use (specific conditions) | "Bug reported", "Test failure observed"  |
| `skip_when`   | WHEN NOT to use (exclusions)      | "Root cause already known → just fix it" |
| `sequence`    | Workflow ordering (optional)      | `after: [prd-creation]`                  |
| `related`     | Similar/complementary skills      | `similar: [root-cause-tracing]`          |

**How Claude Code chooses skills:**

1. Checks `trigger` conditions against current context
2. Uses `skip_when` to differentiate from similar skills
3. Considers `sequence` for workflow ordering
4. References `related` for disambiguation when multiple skills match

---

## 🤖 Available Agents

Invoke via `Task tool with subagent_type: "..."`.

### Code Review (ring-default)

**Always dispatch all 7 in parallel** (single message, 7 Task calls):

| Agent                          | Purpose                                      |
| ------------------------------ | -------------------------------------------- |
| `ring:code-reviewer`           | Architecture, patterns, maintainability      |
| `ring:business-logic-reviewer` | Domain correctness, edge cases, requirements |
| `ring:security-reviewer`       | Vulnerabilities, OWASP, auth, validation     |
| `ring:test-reviewer`           | Test coverage, quality, and completeness     |
| `ring:nil-safety-reviewer`     | Nil/null pointer safety analysis             |
| `ring:consequences-reviewer`   | Ripple effect, caller impact, downstream consequences |
| `ring:dead-code-reviewer`      | Unused code, unreachable paths, dead exports          |

**Example:** Before merging, run all 7 parallel reviewers via `/ring:codereview src/`

### Orchestration (ring-default)

| Agent                  | Purpose                                                            |
| ---------------------- | ------------------------------------------------------------------ |
| `ring:review-slicer`   | Groups large multi-themed PRs into thematic slices for focused review |

### Planning & Analysis (ring-default)

| Agent                    | Purpose                                                  |
| ------------------------ | -------------------------------------------------------- |
| `ring:write-plan`        | Generate implementation plans for zero-context execution |
| `ring:codebase-explorer` | Deep architecture analysis (vs `Explore` for speed)      |

### Developer Specialists (ring-dev-team)

Use when you need expert depth in specific domains:

| Agent                                   | Specialization               | Technologies                                       |
| --------------------------------------- | ---------------------------- | -------------------------------------------------- |
| `ring:backend-engineer-golang`          | Go microservices & APIs      | Fiber, gRPC, PostgreSQL, MongoDB, Kafka, OAuth2    |
| `ring:backend-engineer-typescript`      | TypeScript/Node.js backend   | Express, NestJS, Prisma, TypeORM, GraphQL          |
| `ring:devops-engineer`                  | Infrastructure & CI/CD       | Docker, Kubernetes, Terraform, GitHub Actions      |
| `ring:frontend-bff-engineer-typescript` | BFF & React/Next.js frontend | Next.js API Routes, Clean Architecture, DDD, React |
| `ring:frontend-designer`                | Visual design & aesthetics   | Typography, motion, CSS, distinctive UI            |
| `ring:frontend-engineer`                | General frontend development | React, TypeScript, CSS, component architecture     |
| `ring:helm-engineer`                    | Helm chart specialist        | Helm charts, Kubernetes, Lerian conventions        |
| `ring:prompt-quality-reviewer`          | AI prompt quality review     | Prompt engineering, clarity, effectiveness         |
| `ring:qa-analyst`                       | Quality assurance            | Test strategy, automation, coverage                |
| `ring:qa-analyst-frontend`              | Frontend QA specialist       | Accessibility, visual regression, E2E, performance |
| `ring:sre`                              | Site reliability & ops       | Monitoring, alerting, incident response, SLOs      |
| `ring:ui-engineer`                      | UI component specialist      | Design systems, accessibility, React               |

**Standards Compliance Output:** All ring-dev-team agents include a `## Standards Compliance` output section with conditional requirement:

| Invocation Context      | Standards Compliance | Trigger                                   |
| ----------------------- | -------------------- | ----------------------------------------- |
| Direct agent call       | Optional             | N/A                                       |
| Via `ring:dev-cycle`    | Optional             | N/A                                       |
| Via `ring:dev-refactor` | **MANDATORY**        | Prompt contains `**MODE: ANALYSIS ONLY**` |

**How it works:**

1. `ring:dev-refactor` dispatches agents with `**MODE: ANALYSIS ONLY**` in prompt
2. Agents detect this pattern and load Ring standards via WebFetch
3. Agents produce comparison tables: Current Pattern vs Expected Pattern
4. Output includes severity, location, and migration recommendations

**Example output when non-compliant:**

```markdown
## Standards Compliance

| Category | Current     | Expected        | Status | Location      |
| -------- | ----------- | --------------- | ------ | ------------- |
| Logging  | fmt.Println | lib-commons/zap | ⚠️     | service/\*.go |
```

**Cross-references:** CLAUDE.md (Standards Compliance section), `dev-team/skills/dev-refactor/SKILL.md`

### Product Planning Research (ring-pm-team)

For best practices research and repository analysis:

| Agent                            | Purpose                          | Use For                                 |
| -------------------------------- | -------------------------------- | --------------------------------------- |
| `ring:best-practices-researcher` | Best practices research          | Industry patterns, framework standards  |
| `ring:framework-docs-researcher` | Framework documentation research | Official docs, API references, examples |
| `ring:repo-research-analyst`     | Repository analysis              | Codebase patterns, structure analysis   |
| `ring:product-designer`          | Product design and UX research   | UX specifications, user validation, design review |

### Technical Writing (ring-tw-team)

For documentation creation and review:

| Agent                    | Purpose                      | Use For                              |
| ------------------------ | ---------------------------- | ------------------------------------ |
| `ring:functional-writer` | Functional documentation     | Guides, tutorials, conceptual docs   |
| `ring:api-writer`        | API reference documentation  | Endpoints, schemas, examples         |
| `ring:docs-reviewer`     | Documentation quality review | Voice, tone, structure, completeness |

### Regulatory & FinOps (ring-finops-team)

For Brazilian financial compliance workflows and cost analysis:

| Agent                                | Purpose                        | Use For                                         |
| ------------------------------------ | ------------------------------ | ----------------------------------------------- |
| `ring:finops-analyzer`               | Regulatory compliance analysis | Field mapping, BACEN/RFB validation (Gates 1-2) |
| `ring:finops-automation`             | Template generation            | Create .tpl files (Gate 3)                      |
| `ring:infrastructure-cost-estimator` | Cost estimation and analysis   | Infrastructure cost planning and optimization   |

### PMO Specialists (ring-pmo-team)

For portfolio-level project management and oversight:

| Agent                        | Purpose                   | Use For                                         |
| ---------------------------- | ------------------------- | ----------------------------------------------- |
| `ring:portfolio-manager`     | Portfolio-level planning  | Multi-project coordination, strategic alignment |
| `ring:resource-planner`      | Capacity planning         | Resource allocation, conflict resolution        |
| `ring:risk-analyst`          | Portfolio risk management | Risk identification, mitigation planning        |
| `ring:governance-specialist` | Process compliance        | Gate reviews, audit readiness                   |
| `ring:executive-reporter`    | Executive communications  | Dashboards, board packages, status summaries    |
| `ring:delivery-reporter`     | Delivery reporting        | Delivery status reports and tracking            |

---

## 📖 Common Workflows

### New Feature Development

1. **Design** → `/ring:brainstorm feature-name`
2. **Plan** → `/ring:pre-dev-feature feature-name` (or `ring:pre-dev-full` if complex)
3. **Isolate** → `/ring:worktree feature-branch`
4. **Implement** → Use `ring:test-driven-development` skill
5. **Review** → `/ring:codereview src/` (dispatches 7 reviewers)
6. **Commit** → `/ring:commit "message"`

### Bug Investigation

1. **Investigate** → Use `ring:systematic-debugging` skill
2. **Trace** → Use `ring:root-cause-tracing` if needed
3. **Implement** → Use `ring:test-driven-development` skill
4. **Verify** → Use `ring:verification-before-completion` skill
5. **Review & Merge** → `/ring:codereview` + `/ring:commit`

### Code Review

```
/ring:codereview [files-or-paths]
    ↓
Runs in parallel:
  • ring:code-reviewer
  • ring:business-logic-reviewer
  • ring:security-reviewer
  • ring:test-reviewer
  • ring:nil-safety-reviewer
  • ring:consequences-reviewer
  • ring:dead-code-reviewer
    ↓
Consolidated report with recommendations
```

---

## 🎓 Mandatory Rules

These enforce quality standards:

1. **TDD is enforced** – Test must fail (RED) before implementation
2. **Skill check is mandatory** – Use `ring:using-ring` before any task
3. **Reviewers run parallel** – Never sequential review (use `/ring:codereview`)
4. **Verification required** – Don't claim complete without evidence
5. **No incomplete code** – No "TODO" or placeholder comments
6. **Error handling required** – Don't ignore errors

---

## 💡 Best Practices

### Command Selection

| Situation                                              | Use This                |
| ------------------------------------------------------ | ----------------------- |
| New feature, unsure about design                       | `/ring:brainstorm`      |
| Feature will take < 2 days                             | `/ring:pre-dev-feature` |
| Feature will take ≥ 2 days or has complex dependencies | `/ring:pre-dev-full`    |
| Need implementation tasks                              | `/ring:write-plan`      |
| Before merging code                                    | `/ring:codereview`      |

### Agent Selection

| Need                              | Agent to Use                                |
| --------------------------------- | ------------------------------------------- |
| General code quality review       | 7 parallel reviewers via `/ring:codereview` |
| Large PR review (15+ files)       | Auto-sliced via `ring:review-slicer`        |
| Implementation planning           | `ring:write-plan`                           |
| Deep codebase analysis            | `ring:codebase-explorer`                    |
| Go backend expertise              | `ring:backend-engineer-golang`              |
| TypeScript/Node.js backend        | `ring:backend-engineer-typescript`          |
| Infrastructure/DevOps             | `ring:devops-engineer`                      |
| React/Next.js frontend & BFF      | `ring:frontend-bff-engineer-typescript`     |
| General frontend development      | `ring:frontend-engineer`                    |
| Visual design & aesthetics        | `ring:frontend-designer`                    |
| Helm charts & Kubernetes          | `ring:helm-engineer`                        |
| UI component development          | `ring:ui-engineer`                          |
| AI prompt quality review          | `ring:prompt-quality-reviewer`              |
| Backend quality assurance          | `ring:qa-analyst`                           |
| Frontend quality assurance         | `ring:qa-analyst-frontend`                  |
| Site reliability & operations     | `ring:sre`                                  |
| Best practices research           | `ring:best-practices-researcher`            |
| Framework documentation research  | `ring:framework-docs-researcher`            |
| Repository analysis               | `ring:repo-research-analyst`                |
| Product design & UX research      | `ring:product-designer`                     |
| Functional documentation (guides) | `ring:functional-writer`                    |
| API reference documentation       | `ring:api-writer`                           |
| Documentation quality review      | `ring:docs-reviewer`                        |
| Regulatory compliance analysis    | `ring:finops-analyzer`                      |
| Regulatory template generation    | `ring:finops-automation`                    |
| Infrastructure cost estimation    | `ring:infrastructure-cost-estimator`        |
| Portfolio-level planning          | `ring:portfolio-manager`                    |
| Resource capacity planning        | `ring:resource-planner`                     |
| Portfolio risk assessment         | `ring:risk-analyst`                         |
| Governance and compliance         | `ring:governance-specialist`                |
| Executive reporting               | `ring:executive-reporter`                   |
| Delivery status reporting         | `ring:delivery-reporter`                    |

---

## 🔧 How Ring Works

### Session Startup

1. SessionStart hook runs automatically
2. All 89 skills are auto-discovered and available
3. `ring:using-ring` workflow is activated (skill checking is now mandatory)

### Agent Dispatching

```
Task tool:
  subagent_type: "ring:code-reviewer"
  prompt: [context]
    ↓
Runs agent
    ↓
Returns structured output per agent's output_schema
```

### Parallel Review Pattern

```
Single message with 7 Task calls (not sequential):

Task #1: ring:code-reviewer
Task #2: ring:business-logic-reviewer
Task #3: ring:security-reviewer
Task #4: ring:test-reviewer
Task #5: ring:nil-safety-reviewer
Task #6: ring:consequences-reviewer
Task #7: ring:dead-code-reviewer
    ↓
All run in parallel (saves ~15 minutes vs sequential)
    ↓
Consolidated report
```

### Environment Variables

| Variable                | Default | Purpose                                                |
| ----------------------- | ------- | ------------------------------------------------------ |
| `CLAUDE_PLUGIN_ROOT`    | (auto)  | Path to installed plugin directory                     |

---

## 📚 More Information

- **Full Documentation** → `default/skills/*/SKILL.md` files
- **Agent Definitions** → `default/agents/*.md` files
- **Commands** → `default/commands/*.md` files
- **Plugin Config** → `.claude-plugin/marketplace.json`
- **CLAUDE.md** → Project-specific instructions (checked into repo)

---

## ❓ Need Help?

- **How to use Claude Code?** → Ask about Claude Code features, MCP servers, slash commands
- **How to use Ring?** → Check skill names in this manual or in `ring:using-ring` skill
- **Feature/bug tracking?** → https://github.com/lerianstudio/ring/issues
