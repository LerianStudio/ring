# Ring Marketplace Manual

Quick reference guide for the Ring skills library and workflow system. This monorepo provides 6 plugins with 94 skills and 39 agents for enforcing proven software engineering practices across the entire software delivery value chain.

---

## 🏗️ Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                              MARKETPLACE (6 PLUGINS)                               │
│                     (monorepo: .claude-plugin/marketplace.json)                    │
│                                                                                    │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐      │
│  │ ring-default  │  │ ring-dev-team │  │ ring-pm-team  │  │ring-finops-   │      │
│  │  Skills(23)   │  │  Skills(33)   │  │  Skills(16)   │  │  team         │      │
│  │  Agents(10)   │  │  Agents(13)   │  │  Agents(4)    │  │  Skills(7)    │      │
│  │               │  │               │  │               │  │  Agents(3)    │      │
│  └───────────────┘  └───────────────┘  └───────────────┘  └───────────────┘      │
│  ┌───────────────┐  ┌───────────────┐                                            │
│  │ ring-tw-team  │  │ ring-pmo-team │                                            │
│  │  Skills(6)    │  │  Skills(9)    │                                            │
│  │  Agents(3)    │  │  Agents(6)    │                                            │
│  │               │  │               │                                            │
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
    │    HOOKS     │         │    SKILLS    │         │    AGENTS    │
    │ auto-inject  │         │   primary    │         │  dispatched  │
    │   context    │         │  invocation  │         │  for work    │
    └──────────────┘         └──────────────┘         └──────────────┘
           │                        │                        │
           │                        ▼                        │
           │                 ┌──────────────┐                │
           └────────────────▶│   RESULTS    │◀───────────────┘
                             │  aggregated  │
                             │  & reported  │
                             └──────────────┘

                            COMPONENT ROLES
                            ───────────────

    ┌────────────┬──────────────────────────────────────────────────┐
    │ Component  │ Purpose                                          │
    ├────────────┼──────────────────────────────────────────────────┤
    │ MARKETPLACE│ Monorepo containing all plugins                  │
    │ PLUGIN     │ Self-contained package (skills+agents+hooks)     │
    │ HOOK       │ Auto-runs at session events (injects context)    │
    │ SKILL      │ Primary invocation (user or Claude Code)          │
    │ AGENT      │ Specialized subprocess (Task tool dispatch)      │
    └────────────┴──────────────────────────────────────────────────┘
```

---

## 🎯 Quick Start

Ring is auto-loaded at session start. Two ways to invoke Ring capabilities:

1. **Skills** – `Skill tool: "ring:skill-name"` (primary invocation method)
2. **Agents** – `Task tool with subagent_type: "ring:agent-name"`

---

## 💡 About Skills

Skills (94) are the primary invocation mechanism for Ring. They can be invoked directly by users (`Skill tool: "ring:skill-name"`) or applied automatically by Claude Code when it detects they're applicable. They handle testing, debugging, verification, planning, code review enforcement, and more.

Examples: ring:test-driven-development, ring:systematic-debugging, ring:codereview, ring:production-readiness-audit (44-dimension audit, up to 10 explorers per batch, incremental report 0-430, max 440 with multi-tenant; see [default/skills/production-readiness-audit/SKILL.md](default/skills/production-readiness-audit/SKILL.md)), etc.

### Skill Selection Criteria

Each skill has structured frontmatter that helps Claude Code determine which skill to use:

| Field         | Purpose                           | Example                                  |
| ------------- | --------------------------------- | ---------------------------------------- |
| `description` | WHAT the skill does               | "Four-phase debugging framework..."      |
| `trigger`     | WHEN to use (specific conditions) | "Bug reported", "Test failure observed"  |
| `skip_when`   | WHEN NOT to use (exclusions)      | "Root cause already known → just fix it" |
| `sequence`    | Workflow ordering (optional)      | `after: [prd-creation]`                  |
| `related`     | Similar/complementary skills      | `similar: [systematic-debugging]`        |

**How Claude Code chooses skills:**

1. Checks `trigger` conditions against current context
2. Uses `skip_when` to differentiate from similar skills
3. Considers `sequence` for workflow ordering
4. References `related` for disambiguation when multiple skills match

---

## 🤖 Available Agents

Invoke via `Task tool with subagent_type: "..."`.

### Code Review (ring-default)

**Always dispatch all 8 in parallel** (single message, 8 Task calls):

| Agent                          | Purpose                                      |
| ------------------------------ | -------------------------------------------- |
| `ring:code-reviewer`           | Architecture, patterns, maintainability      |
| `ring:business-logic-reviewer` | Domain correctness, edge cases, requirements |
| `ring:security-reviewer`       | Vulnerabilities, OWASP, auth, validation     |
| `ring:test-reviewer`           | Test coverage, quality, and completeness     |
| `ring:nil-safety-reviewer`     | Nil/null pointer safety analysis             |
| `ring:consequences-reviewer`   | Ripple effect, caller impact, downstream consequences |
| `ring:dead-code-reviewer`      | Unused code, unreachable paths, dead exports          |
| `ring:performance-reviewer`    | Performance hotspots, allocations, goroutine leaks, N+1 queries |

**Example:** Before merging, run all 8 parallel reviewers via `ring:codereview` skill

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
| `ring:performance-reviewer`             | Performance review           | Go, TypeScript, Python, GOMAXPROCS, GC tuning      |
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

1. **Design** → Use `ring:brainstorm` skill
2. **Plan** → Use `ring:pre-dev-feature` skill (or `ring:pre-dev-full` if complex)
3. **Isolate** → Use `ring:worktree` skill
4. **Implement** → Use `ring:test-driven-development` skill
5. **Review** → Use `ring:codereview` skill (dispatches 8 reviewers)
6. **Commit** → Use `ring:commit` skill

### Bug Investigation

1. **Investigate** → Use `ring:systematic-debugging` skill
2. **Implement** → Use `ring:test-driven-development` skill
3. **Review & Merge** → Use `ring:codereview` + `ring:commit` skills

### Code Review

```
ring:codereview skill
    ↓
Runs in parallel:
  • ring:code-reviewer
  • ring:business-logic-reviewer
  • ring:security-reviewer
  • ring:test-reviewer
  • ring:nil-safety-reviewer
  • ring:consequences-reviewer
  • ring:dead-code-reviewer
  • ring:performance-reviewer
    ↓
Consolidated report with recommendations
```

---

## 🎓 Mandatory Rules

These enforce quality standards:

1. **TDD is enforced** – Test must fail (RED) before implementation
2. **Skill check is mandatory** – Use `ring:using-ring` before any task
3. **Reviewers run parallel** – Never sequential review (use `ring:codereview` skill)
4. **Verification required** – Don't claim complete without evidence
5. **No incomplete code** – No "TODO" or placeholder comments
6. **Error handling required** – Don't ignore errors

---

## 💡 Best Practices

### Skill & Command Selection

| Situation                                              | Use This                       |
| ------------------------------------------------------ | ------------------------------ |
| New feature, unsure about design                       | `ring:brainstorm` (skill)      |
| Feature will take < 2 days                             | `ring:pre-dev-feature` (skill) |
| Feature will take ≥ 2 days or has complex dependencies | `ring:pre-dev-full` (skill)    |
| Need implementation tasks                              | `ring:write-plan` (skill)      |
| Before merging code                                    | `ring:codereview` (skill)      |
| Start development cycle                                | `ring:dev-cycle` (skill)       |

### Agent Selection

| Need                              | Agent to Use                                |
| --------------------------------- | ------------------------------------------- |
| General code quality review       | 8 parallel reviewers via `ring:codereview` skill |
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
| Performance review                | `ring:performance-reviewer`                 |
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
2. All 94 skills are auto-discovered and available
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
Single message with 8 Task calls (not sequential):

Task #1: ring:code-reviewer
Task #2: ring:business-logic-reviewer
Task #3: ring:security-reviewer
Task #4: ring:test-reviewer
Task #5: ring:nil-safety-reviewer
Task #6: ring:consequences-reviewer
Task #7: ring:dead-code-reviewer
Task #8: ring:performance-reviewer
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
- **Plugin Config** → `.claude-plugin/marketplace.json`
- **CLAUDE.md** → Project-specific instructions (checked into repo)

---

## ❓ Need Help?

- **How to use Claude Code?** → Ask about Claude Code features, MCP servers, skills
- **How to use Ring?** → Check skill names in this manual or in `ring:using-ring` skill
- **Feature/bug tracking?** → https://github.com/lerianstudio/ring/issues
