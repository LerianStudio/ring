# Ring Marketplace Manual

Quick reference guide for the Ring skills library and workflow system. This monorepo provides 9 plugins with 87 skills, 42 agents, and 30 slash commands for enforcing proven software engineering practices across the entire software delivery value chain.

---

## 🏗️ Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                              MARKETPLACE (9 PLUGINS)                               │
│                     (monorepo: .claude-plugin/marketplace.json)                    │
│                                                                                    │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐      │
│  │ ring-default  │  │ ring-dev-team │  │ ring-pm-team  │  │ ring-finops-  │      │
│  │  Skills(22)   │  │  Skills(10)   │  │  Skills(10)   │  │  team(6)      │      │
│  │  Agents(5)    │  │  Agents(7)    │  │  Agents(3)    │  │  Agents(2)    │      │
│  │  Cmds(7)      │  │  Cmds(5)      │  │  Cmds(2)      │  │               │      │
│  └───────────────┘  └───────────────┘  └───────────────┘  └───────────────┘      │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐      │
│  │ ring-finance- │  │ ring-ops-team │  │ ring-pmm-team │  │ ring-pmo-team │      │
│  │  team(8)      │  │  Skills(8)    │  │  Skills(8)    │  │  Skills(8)    │      │
│  │  Skills(8)    │  │  Agents(5)    │  │  Agents(6)    │  │  Agents(5)    │      │
│  │  Agents(6)    │  │  Cmds(4)      │  │  Cmds(3)      │  │  Cmds(3)      │      │
│  │  Cmds(3)      │  └───────────────┘  └───────────────┘  └───────────────┘      │
│  └───────────────┘  ┌───────────────┐                                             │
│                     │ ring-tw-team  │                                             │
│                     │  Skills(7)    │                                             │
│                     │  Agents(3)    │                                             │
│                     │  Cmds(3)      │                                             │
│                     └───────────────┘                                             │
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
    │ COMMAND    │ User-invokable action (/ring-default:codereview)         │
    │ AGENT      │ Specialized subprocess (Task tool dispatch)      │
    └────────────┴──────────────────────────────────────────────────┘
```

---

## 🎯 Quick Start

Ring is auto-loaded at session start. Three ways to invoke Ring capabilities:

1. **Slash Commands** – `/ring-{plugin}:command-name`
2. **Skills** – `Skill tool: "ring-{plugin}:skill-name"`
3. **Agents** – `Task tool with subagent_type: "ring-{plugin}:agent-name"`

---

## 📋 Slash Commands

All commands use fully qualified prefix: `/ring-{plugin}:{command}`.
Plugin prefixes: `ring-default:`, `ring-dev-team:`, `ring-pm-team:`, `ring-finops-team:`, `ring-finance-team:`, `ring-ops-team:`, `ring-pmm-team:`, `ring-pmo-team:`, `ring-tw-team:`.

### Project & Feature Workflows

| Command | Use Case | Example |
|---------|----------|---------|
| `/ring-default:brainstorm [topic]` | Interactive design refinement before coding | `/ring-default:brainstorm user-authentication` |
| `/ring-pm-team:pre-dev-feature [name]` | Plan simple features (<2 days) – 3 gates | `/ring-pm-team:pre-dev-feature logout-button` |
| `/ring-pm-team:pre-dev-full [name]` | Plan complex features (≥2 days) – 8 gates | `/ring-pm-team:pre-dev-full payment-system` |
| `/ring-default:worktree [branch-name]` | Create isolated git workspace | `/ring-default:worktree auth-system` |
| `/ring-default:write-plan [feature]` | Generate detailed task breakdown | `/ring-default:write-plan dashboard-redesign` |
| `/ring-default:execute-plan [path]` | Execute plan in batches with checkpoints | `/ring-default:execute-plan docs/pre-dev/feature/tasks.md` |

### Code & Integration Workflows

| Command | Use Case | Example |
|---------|----------|---------|
| `/ring-default:codereview [files-or-paths]` | Dispatch 3 parallel code reviewers | `/ring-default:codereview src/auth/` |
| `/ring-default:commit [message]` | Create git commit with AI trailers | `/ring-default:commit "fix(auth): improve token validation"` |
| `/ring-default:lint [path]` | Run lint and dispatch agents to fix all issues | `/ring-default:lint src/` |

### Development Cycle (ring-dev-team)

| Command | Use Case | Example |
|---------|----------|---------|
| `/ring-dev-team:dev-cycle [task]` | Start 6-gate development workflow | `/ring-dev-team:dev-cycle "implement user auth"` |
| `/ring-dev-team:dev-refactor [path]` | Analyze codebase against standards | `/ring-dev-team:dev-refactor src/` |
| `/ring-dev-team:dev-status` | Show current gate progress | `/ring-dev-team:dev-status` |
| `/ring-dev-team:dev-report` | Generate development cycle report | `/ring-dev-team:dev-report` |
| `/ring-dev-team:dev-cancel` | Cancel active development cycle | `/ring-dev-team:dev-cancel` |

### Technical Writing (Documentation)

| Command | Use Case | Example |
|---------|----------|---------|
| `/ring-tw-team:write-guide [topic]` | Start writing a functional guide | `/ring-tw-team:write-guide authentication` |
| `/ring-tw-team:write-api [endpoint]` | Start writing API documentation | `/ring-tw-team:write-api POST /accounts` |
| `/ring-tw-team:review-docs [file]` | Review documentation for quality | `/ring-tw-team:review-docs docs/guide.md` |

---

## 💡 About Skills

Skills (55) are workflows that Claude Code invokes automatically when it detects they're applicable. They handle testing, debugging, verification, planning, and code review enforcement. You don't call them directly – Claude Code uses them internally to enforce best practices.

Examples: test-driven-development, systematic-debugging, requesting-code-review, verification-before-completion, etc.

### Skill Selection Criteria

Each skill has structured frontmatter that helps Claude Code determine which skill to use:

| Field | Purpose | Example |
|-------|---------|---------|
| `description` | WHAT the skill does | "Four-phase debugging framework..." |
| `trigger` | WHEN to use (specific conditions) | "Bug reported", "Test failure observed" |
| `skip_when` | WHEN NOT to use (exclusions) | "Root cause already known → just fix it" |
| `sequence` | Workflow ordering (optional) | `after: [prd-creation]` |
| `related` | Similar/complementary skills | `similar: [root-cause-tracing]` |

**How Claude Code chooses skills:**
1. Checks `trigger` conditions against current context
2. Uses `skip_when` to differentiate from similar skills
3. Considers `sequence` for workflow ordering
4. References `related` for disambiguation when multiple skills match

---

## 🤖 Available Agents

Invoke via `Task tool with subagent_type: "..."`.

### Code Review (ring-default)

**Always dispatch all 3 in parallel** (single message, 3 Task calls):

| Agent | Purpose | Model |
|-------|---------|-------|
| `ring-default:code-reviewer` | Architecture, patterns, maintainability | Opus |
| `ring-default:business-logic-reviewer` | Domain correctness, edge cases, requirements | Opus |
| `ring-default:security-reviewer` | Vulnerabilities, OWASP, auth, validation | Opus |

**Example:** Before merging, run all 3 parallel reviewers via `/ring-default:codereview src/`

### Planning & Analysis (ring-default)

| Agent | Purpose | Model |
|-------|---------|-------|
| `ring-default:write-plan` | Generate implementation plans for zero-context execution | Opus |
| `ring-default:codebase-explorer` | Deep architecture analysis (vs `Explore` for speed) | Opus |

### Developer Specialists (ring-dev-team)

Use when you need expert depth in specific domains:

| Agent | Specialization | Technologies |
|-------|----------------|--------------|
| `ring-dev-team:backend-engineer-golang` | Go microservices & APIs | Fiber, gRPC, PostgreSQL, MongoDB, Kafka, OAuth2 |
| `ring-dev-team:backend-engineer-typescript` | TypeScript/Node.js backend | Express, NestJS, Prisma, TypeORM, GraphQL |
| `ring-dev-team:devops-engineer` | Infrastructure & CI/CD | Docker, Kubernetes, Terraform, GitHub Actions |
| `ring-dev-team:frontend-bff-engineer-typescript` | BFF & React/Next.js frontend | Next.js API Routes, Clean Architecture, DDD, React |
| `ring-dev-team:frontend-designer` | Visual design & aesthetics | Typography, motion, CSS, distinctive UI |
| `ring-dev-team:frontend-engineer` | General frontend development | React, TypeScript, CSS, component architecture |
| `ring-dev-team:prompt-quality-reviewer` | AI prompt quality review | Prompt engineering, clarity, effectiveness |
| `ring-dev-team:qa-analyst` | Quality assurance | Test strategy, automation, coverage |
| `ring-dev-team:sre` | Site reliability & ops | Monitoring, alerting, incident response, SLOs |

**Standards Compliance Output:** All ring-dev-team agents include a `## Standards Compliance` output section with conditional requirement:

| Invocation Context | Standards Compliance | Trigger |
|--------------------|---------------------|---------|
| Direct agent call | Optional | N/A |
| Via `dev-cycle` | Optional | N/A |
| Via `dev-refactor` | **MANDATORY** | Prompt contains `**MODE: ANALYSIS ONLY**` |

**How it works:**
1. `dev-refactor` dispatches agents with `**MODE: ANALYSIS ONLY**` in prompt
2. Agents detect this pattern and load Ring standards via WebFetch
3. Agents produce comparison tables: Current Pattern vs Expected Pattern
4. Output includes severity, location, and migration recommendations

**Example output when non-compliant:**
```markdown
## Standards Compliance

| Category | Current | Expected | Status | Location |
|----------|---------|----------|--------|----------|
| Logging | fmt.Println | lib-commons/zap | ⚠️ | service/*.go |
```

**Cross-references:** CLAUDE.md (Standards Compliance section), `dev-team/skills/dev-refactor/SKILL.md`

### Regulatory & FinOps (ring-finops-team)

For Brazilian financial compliance workflows:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `ring-finops-team:finops-analyzer` | Regulatory compliance analysis | Field mapping, BACEN/RFB validation (Gates 1-2) |
| `ring-finops-team:finops-automation` | Template generation | Create .tpl files (Gate 3) |

### Technical Writing (ring-tw-team)

For documentation creation and review:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `ring-tw-team:functional-writer` | Functional documentation | Guides, tutorials, conceptual docs |
| `ring-tw-team:api-writer` | API reference documentation | Endpoints, schemas, examples |
| `ring-tw-team:docs-reviewer` | Documentation quality review | Voice, tone, structure, completeness |

### Financial Operations (ring-finance-team)

For financial analysis, budgeting, modeling, and treasury operations:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `ring-finance-team:financial-analyst` | Financial analysis & ratios | Statement analysis, trend analysis, benchmarking |
| `ring-finance-team:budget-planner` | Budgets & forecasts | Annual budgets, rolling forecasts, variance analysis |
| `ring-finance-team:financial-modeler` | Financial models | DCF valuation, LBO models, M&A models, scenarios |
| `ring-finance-team:treasury-specialist` | Cash & liquidity | Cash forecasting, working capital, FX exposure |
| `ring-finance-team:accounting-specialist` | Accounting operations | Journal entries, reconciliations, month-end close |
| `ring-finance-team:metrics-analyst` | KPIs & dashboards | Metric definition, dashboard design, anomaly detection |

**Commands:**
- `/ring-finance-team:analyze-financials` - Run comprehensive financial analysis
- `/ring-finance-team:create-budget` - Create budgets or forecasts
- `/ring-finance-team:build-model` - Build financial models (DCF, LBO, etc.)

### Production Operations (ring-ops-team)

For production infrastructure, incidents, and platform engineering:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `ring-ops-team:platform-engineer` | Platform engineering | Service mesh, API gateways, developer platforms |
| `ring-ops-team:incident-responder` | Incident management | Production incidents, RCA, post-mortems |
| `ring-ops-team:cloud-cost-optimizer` | Cost optimization | Cost analysis, RI planning, FinOps practices |
| `ring-ops-team:infrastructure-architect` | Infrastructure design | Multi-region architecture, DR, capacity planning |
| `ring-ops-team:security-operations` | Security & compliance | Security audits, vulnerability management |

**Commands:**
- `/ring-ops-team:incident` - Start production incident response
- `/ring-ops-team:capacity-review` - Infrastructure capacity review
- `/ring-ops-team:cost-analysis` - Cloud cost optimization
- `/ring-ops-team:security-audit` - Security audit workflow

### Product Marketing (ring-pmm-team)

For go-to-market strategy, positioning, and launch coordination:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `ring-pmm-team:market-researcher` | Market intelligence | TAM/SAM/SOM, segmentation, trend analysis |
| `ring-pmm-team:positioning-strategist` | Strategic positioning | Differentiation, category design, positioning statements |
| `ring-pmm-team:messaging-specialist` | Messaging & copy | Value props, messaging frameworks, proof points |
| `ring-pmm-team:gtm-planner` | GTM strategy | Channel strategy, campaign planning, launch tactics |
| `ring-pmm-team:launch-coordinator` | Launch execution | Checklists, stakeholder coordination, day-of execution |
| `ring-pmm-team:pricing-analyst` | Pricing strategy | Pricing models, competitive pricing, value-based pricing |

**Commands:**
- `/ring-pmm-team:market-analysis` - Comprehensive market analysis
- `/ring-pmm-team:gtm-plan` - Full GTM planning (7 gates)
- `/ring-pmm-team:competitive-intel` - Competitive intelligence & battlecards

### Portfolio Management (ring-pmo-team)

For portfolio governance, resource planning, and executive reporting:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `ring-pmo-team:portfolio-manager` | Portfolio coordination | Multi-project coordination, strategic alignment |
| `ring-pmo-team:resource-planner` | Resource planning | Capacity planning, allocation optimization |
| `ring-pmo-team:governance-specialist` | Governance & compliance | Gate reviews, process compliance, audits |
| `ring-pmo-team:risk-analyst` | Risk management | Risk identification, RAID logs, mitigation |
| `ring-pmo-team:executive-reporter` | Executive communication | Dashboards, board packages, status summaries |

**Commands:**
- `/ring-pmo-team:portfolio-review` - Full portfolio health review
- `/ring-pmo-team:executive-summary` - Generate executive report
- `/ring-pmo-team:dependency-analysis` - Cross-project dependencies

---

## 📖 Common Workflows

### New Feature Development

1. **Design** → `/ring-default:brainstorm feature-name`
2. **Plan** → `/ring-pm-team:pre-dev-feature feature-name` (or `ring-pm-team:pre-dev-full` if complex)
3. **Isolate** → `/ring-default:worktree feature-branch`
4. **Implement** → Use `ring-default:test-driven-development` skill
5. **Review** → `/ring-default:codereview src/` (dispatches 3 reviewers)
6. **Commit** → `/ring-default:commit "message"`

### Bug Investigation

1. **Investigate** → Use `ring-default:systematic-debugging` skill
2. **Trace** → Use `ring-default:root-cause-tracing` if needed
3. **Implement** → Use `ring-default:test-driven-development` skill
4. **Verify** → Use `ring-default:verification-before-completion` skill
5. **Review & Merge** → `/ring-default:codereview` + `/ring-default:commit`

### Code Review

```
/ring-default:codereview [files-or-paths]
    ↓
Runs in parallel:
  • ring-default:code-reviewer (Opus)
  • ring-default:business-logic-reviewer (Opus)
  • ring-default:security-reviewer (Opus)
    ↓
Consolidated report with recommendations
```

---

## 🎓 Mandatory Rules

These enforce quality standards:

1. **TDD is enforced** – Test must fail (RED) before implementation
2. **Skill check is mandatory** – Use `ring-default:using-ring` before any task
3. **Reviewers run parallel** – Never sequential review (use `/ring-default:codereview`)
4. **Verification required** – Don't claim complete without evidence
5. **No incomplete code** – No "TODO" or placeholder comments
6. **Error handling required** – Don't ignore errors

---

## 💡 Best Practices

### Command Selection

| Situation | Use This |
|-----------|----------|
| New feature, unsure about design | `/ring-default:brainstorm` |
| Feature will take < 2 days | `/ring-pm-team:pre-dev-feature` |
| Feature will take ≥ 2 days or has complex dependencies | `/ring-pm-team:pre-dev-full` |
| Need implementation tasks | `/ring-default:write-plan` |
| Before merging code | `/ring-default:codereview` |


### Agent Selection

| Need | Agent to Use |
|------|-------------|
| General code quality review | 3 parallel reviewers via `/ring-default:codereview` |
| Implementation planning | `ring-default:write-plan` |
| Deep codebase analysis | `ring-default:codebase-explorer` |
| Go backend expertise | `ring-dev-team:backend-engineer-golang` |
| TypeScript/Node.js backend | `ring-dev-team:backend-engineer-typescript` |
| Infrastructure/DevOps | `ring-dev-team:devops-engineer` |
| React/Next.js frontend & BFF | `ring-dev-team:frontend-bff-engineer-typescript` |
| General frontend development | `ring-dev-team:frontend-engineer` |
| Visual design & aesthetics | `ring-dev-team:frontend-designer` |
| AI prompt quality review | `ring-dev-team:prompt-quality-reviewer` |
| Quality assurance & testing | `ring-dev-team:qa-analyst` |
| Site reliability & operations | `ring-dev-team:sre` |
| Regulatory compliance analysis | `ring-finops-team:finops-analyzer` |
| Regulatory template generation | `ring-finops-team:finops-automation` |
| Best practices research | `ring-pm-team:best-practices-researcher` |
| Framework documentation research | `ring-pm-team:framework-docs-researcher` |
| Repository analysis | `ring-pm-team:repo-research-analyst` |
| Functional documentation (guides) | `ring-tw-team:functional-writer` |
| API reference documentation | `ring-tw-team:api-writer` |
| Documentation quality review | `ring-tw-team:docs-reviewer` |
| Financial statement analysis | `ring-finance-team:financial-analyst` |
| Budget & forecast creation | `ring-finance-team:budget-planner` |
| Financial model building (DCF, LBO) | `ring-finance-team:financial-modeler` |
| Treasury & cash management | `ring-finance-team:treasury-specialist` |
| Accounting operations & close | `ring-finance-team:accounting-specialist` |
| KPI definition & dashboards | `ring-finance-team:metrics-analyst` |
| Platform engineering & service mesh | `ring-ops-team:platform-engineer` |
| Production incident response | `ring-ops-team:incident-responder` |
| Cloud cost optimization | `ring-ops-team:cloud-cost-optimizer` |
| Infrastructure architecture & DR | `ring-ops-team:infrastructure-architect` |
| Security audits & compliance | `ring-ops-team:security-operations` |
| Market research & TAM/SAM/SOM | `ring-pmm-team:market-researcher` |
| Product positioning strategy | `ring-pmm-team:positioning-strategist` |
| Messaging & value propositions | `ring-pmm-team:messaging-specialist` |
| Go-to-market planning | `ring-pmm-team:gtm-planner` |
| Launch coordination & execution | `ring-pmm-team:launch-coordinator` |
| Pricing strategy & analysis | `ring-pmm-team:pricing-analyst` |
| Portfolio management & health | `ring-pmo-team:portfolio-manager` |
| Resource capacity & allocation | `ring-pmo-team:resource-planner` |
| Project governance & gates | `ring-pmo-team:governance-specialist` |
| Portfolio risk management | `ring-pmo-team:risk-analyst` |
| Executive dashboards & reporting | `ring-pmo-team:executive-reporter` |

---

## 🔧 How Ring Works

### Session Startup

1. SessionStart hook runs automatically
2. All 87 skills are auto-discovered and available
3. `using-ring` workflow is activated (skill checking is now mandatory)

### Agent Dispatching

```
Task tool:
  subagent_type: "code-reviewer"
  model: "opus"
  prompt: [context]
    ↓
Runs agent with Opus model
    ↓
Returns structured output per agent's output_schema
```

### Parallel Review Pattern

```
Single message with 3 Task calls (not sequential):

Task #1: code-reviewer
Task #2: business-logic-reviewer
Task #3: security-reviewer
    ↓
All run in parallel (saves ~15 minutes vs sequential)
    ↓
Consolidated report
```

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
- **How to use Ring?** → Check skill names in this manual or in `using-ring` skill
- **Feature/bug tracking?** → https://github.com/lerianstudio/ring/issues
