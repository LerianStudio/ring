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
    │ COMMAND    │ User-invokable action (/codereview)         │
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
Plugin prefixes: ``, ``, ``, ``, ``, ``, ``, ``, ``.

### Project & Feature Workflows

| Command | Use Case | Example |
|---------|----------|---------|
| `/brainstorm [topic]` | Interactive design refinement before coding | `/brainstorm user-authentication` |
| `/pre-dev-feature [name]` | Plan simple features (<2 days) – 3 gates | `/pre-dev-feature logout-button` |
| `/pre-dev-full [name]` | Plan complex features (≥2 days) – 8 gates | `/pre-dev-full payment-system` |
| `/worktree [branch-name]` | Create isolated git workspace | `/worktree auth-system` |
| `/write-plan [feature]` | Generate detailed task breakdown | `/write-plan dashboard-redesign` |
| `/execute-plan [path]` | Execute plan in batches with checkpoints | `/execute-plan docs/pre-dev/feature/tasks.md` |

### Code & Integration Workflows

| Command | Use Case | Example |
|---------|----------|---------|
| `/codereview [files-or-paths]` | Dispatch 3 parallel code reviewers | `/codereview src/auth/` |
| `/commit [message]` | Create git commit with AI trailers | `/commit "fix(auth): improve token validation"` |
| `/lint [path]` | Run lint and dispatch agents to fix all issues | `/lint src/` |

### Development Cycle (ring-dev-team)

| Command | Use Case | Example |
|---------|----------|---------|
| `/dev-cycle [task]` | Start 6-gate development workflow | `/dev-cycle "implement user auth"` |
| `/dev-refactor [path]` | Analyze codebase against standards | `/dev-refactor src/` |
| `/dev-status` | Show current gate progress | `/dev-status` |
| `/dev-report` | Generate development cycle report | `/dev-report` |
| `/dev-cancel` | Cancel active development cycle | `/dev-cancel` |

### Technical Writing (Documentation)

| Command | Use Case | Example |
|---------|----------|---------|
| `/write-guide [topic]` | Start writing a functional guide | `/write-guide authentication` |
| `/write-api [endpoint]` | Start writing API documentation | `/write-api POST /accounts` |
| `/review-docs [file]` | Review documentation for quality | `/review-docs docs/guide.md` |

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
| `code-reviewer` | Architecture, patterns, maintainability | Opus |
| `business-logic-reviewer` | Domain correctness, edge cases, requirements | Opus |
| `security-reviewer` | Vulnerabilities, OWASP, auth, validation | Opus |

**Example:** Before merging, run all 3 parallel reviewers via `/codereview src/`

### Planning & Analysis (ring-default)

| Agent | Purpose | Model |
|-------|---------|-------|
| `write-plan` | Generate implementation plans for zero-context execution | Opus |
| `codebase-explorer` | Deep architecture analysis (vs `Explore` for speed) | Opus |

### Developer Specialists (ring-dev-team)

Use when you need expert depth in specific domains:

| Agent | Specialization | Technologies |
|-------|----------------|--------------|
| `backend-engineer-golang` | Go microservices & APIs | Fiber, gRPC, PostgreSQL, MongoDB, Kafka, OAuth2 |
| `backend-engineer-typescript` | TypeScript/Node.js backend | Express, NestJS, Prisma, TypeORM, GraphQL |
| `devops-engineer` | Infrastructure & CI/CD | Docker, Kubernetes, Terraform, GitHub Actions |
| `frontend-bff-engineer-typescript` | BFF & React/Next.js frontend | Next.js API Routes, Clean Architecture, DDD, React |
| `frontend-designer` | Visual design & aesthetics | Typography, motion, CSS, distinctive UI |
| `frontend-engineer` | General frontend development | React, TypeScript, CSS, component architecture |
| `prompt-quality-reviewer` | AI prompt quality review | Prompt engineering, clarity, effectiveness |
| `qa-analyst` | Quality assurance | Test strategy, automation, coverage |
| `sre` | Site reliability & ops | Monitoring, alerting, incident response, SLOs |

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
| `finops-analyzer` | Regulatory compliance analysis | Field mapping, BACEN/RFB validation (Gates 1-2) |
| `finops-automation` | Template generation | Create .tpl files (Gate 3) |

### Technical Writing (ring-tw-team)

For documentation creation and review:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `functional-writer` | Functional documentation | Guides, tutorials, conceptual docs |
| `api-writer` | API reference documentation | Endpoints, schemas, examples |
| `docs-reviewer` | Documentation quality review | Voice, tone, structure, completeness |

### Financial Operations (ring-finance-team)

For financial analysis, budgeting, modeling, and treasury operations:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `financial-analyst` | Financial analysis & ratios | Statement analysis, trend analysis, benchmarking |
| `budget-planner` | Budgets & forecasts | Annual budgets, rolling forecasts, variance analysis |
| `financial-modeler` | Financial models | DCF valuation, LBO models, M&A models, scenarios |
| `treasury-specialist` | Cash & liquidity | Cash forecasting, working capital, FX exposure |
| `accounting-specialist` | Accounting operations | Journal entries, reconciliations, month-end close |
| `metrics-analyst` | KPIs & dashboards | Metric definition, dashboard design, anomaly detection |

**Commands:**
- `/analyze-financials` - Run comprehensive financial analysis
- `/create-budget` - Create budgets or forecasts
- `/build-model` - Build financial models (DCF, LBO, etc.)

### Production Operations (ring-ops-team)

For production infrastructure, incidents, and platform engineering:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `platform-engineer` | Platform engineering | Service mesh, API gateways, developer platforms |
| `incident-responder` | Incident management | Production incidents, RCA, post-mortems |
| `cloud-cost-optimizer` | Cost optimization | Cost analysis, RI planning, FinOps practices |
| `infrastructure-architect` | Infrastructure design | Multi-region architecture, DR, capacity planning |
| `security-operations` | Security & compliance | Security audits, vulnerability management |

**Commands:**
- `/incident` - Start production incident response
- `/capacity-review` - Infrastructure capacity review
- `/cost-analysis` - Cloud cost optimization
- `/security-audit` - Security audit workflow

### Product Marketing (ring-pmm-team)

For go-to-market strategy, positioning, and launch coordination:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `market-researcher` | Market intelligence | TAM/SAM/SOM, segmentation, trend analysis |
| `positioning-strategist` | Strategic positioning | Differentiation, category design, positioning statements |
| `messaging-specialist` | Messaging & copy | Value props, messaging frameworks, proof points |
| `gtm-planner` | GTM strategy | Channel strategy, campaign planning, launch tactics |
| `launch-coordinator` | Launch execution | Checklists, stakeholder coordination, day-of execution |
| `pricing-analyst` | Pricing strategy | Pricing models, competitive pricing, value-based pricing |

**Commands:**
- `/market-analysis` - Comprehensive market analysis
- `/gtm-plan` - Full GTM planning (7 gates)
- `/competitive-intel` - Competitive intelligence & battlecards

### Portfolio Management (ring-pmo-team)

For portfolio governance, resource planning, and executive reporting:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `portfolio-manager` | Portfolio coordination | Multi-project coordination, strategic alignment |
| `resource-planner` | Resource planning | Capacity planning, allocation optimization |
| `governance-specialist` | Governance & compliance | Gate reviews, process compliance, audits |
| `risk-analyst` | Risk management | Risk identification, RAID logs, mitigation |
| `executive-reporter` | Executive communication | Dashboards, board packages, status summaries |

**Commands:**
- `/portfolio-review` - Full portfolio health review
- `/executive-summary` - Generate executive report
- `/dependency-analysis` - Cross-project dependencies

---

## 📖 Common Workflows

### New Feature Development

1. **Design** → `/brainstorm feature-name`
2. **Plan** → `/pre-dev-feature feature-name` (or `pre-dev-full` if complex)
3. **Isolate** → `/worktree feature-branch`
4. **Implement** → Use `test-driven-development` skill
5. **Review** → `/codereview src/` (dispatches 3 reviewers)
6. **Commit** → `/commit "message"`

### Bug Investigation

1. **Investigate** → Use `systematic-debugging` skill
2. **Trace** → Use `root-cause-tracing` if needed
3. **Implement** → Use `test-driven-development` skill
4. **Verify** → Use `verification-before-completion` skill
5. **Review & Merge** → `/codereview` + `/commit`

### Code Review

```
/codereview [files-or-paths]
    ↓
Runs in parallel:
  • code-reviewer (Opus)
  • business-logic-reviewer (Opus)
  • security-reviewer (Opus)
    ↓
Consolidated report with recommendations
```

---

## 🎓 Mandatory Rules

These enforce quality standards:

1. **TDD is enforced** – Test must fail (RED) before implementation
2. **Skill check is mandatory** – Use `using-ring` before any task
3. **Reviewers run parallel** – Never sequential review (use `/codereview`)
4. **Verification required** – Don't claim complete without evidence
5. **No incomplete code** – No "TODO" or placeholder comments
6. **Error handling required** – Don't ignore errors

---

## 💡 Best Practices

### Command Selection

| Situation | Use This |
|-----------|----------|
| New feature, unsure about design | `/brainstorm` |
| Feature will take < 2 days | `/pre-dev-feature` |
| Feature will take ≥ 2 days or has complex dependencies | `/pre-dev-full` |
| Need implementation tasks | `/write-plan` |
| Before merging code | `/codereview` |


### Agent Selection

| Need | Agent to Use |
|------|-------------|
| General code quality review | 3 parallel reviewers via `/codereview` |
| Implementation planning | `write-plan` |
| Deep codebase analysis | `codebase-explorer` |
| Go backend expertise | `backend-engineer-golang` |
| TypeScript/Node.js backend | `backend-engineer-typescript` |
| Infrastructure/DevOps | `devops-engineer` |
| React/Next.js frontend & BFF | `frontend-bff-engineer-typescript` |
| General frontend development | `frontend-engineer` |
| Visual design & aesthetics | `frontend-designer` |
| AI prompt quality review | `prompt-quality-reviewer` |
| Quality assurance & testing | `qa-analyst` |
| Site reliability & operations | `sre` |
| Regulatory compliance analysis | `finops-analyzer` |
| Regulatory template generation | `finops-automation` |
| Best practices research | `best-practices-researcher` |
| Framework documentation research | `framework-docs-researcher` |
| Repository analysis | `repo-research-analyst` |
| Functional documentation (guides) | `functional-writer` |
| API reference documentation | `api-writer` |
| Documentation quality review | `docs-reviewer` |
| Financial statement analysis | `financial-analyst` |
| Budget & forecast creation | `budget-planner` |
| Financial model building (DCF, LBO) | `financial-modeler` |
| Treasury & cash management | `treasury-specialist` |
| Accounting operations & close | `accounting-specialist` |
| KPI definition & dashboards | `metrics-analyst` |
| Platform engineering & service mesh | `platform-engineer` |
| Production incident response | `incident-responder` |
| Cloud cost optimization | `cloud-cost-optimizer` |
| Infrastructure architecture & DR | `infrastructure-architect` |
| Security audits & compliance | `security-operations` |
| Market research & TAM/SAM/SOM | `market-researcher` |
| Product positioning strategy | `positioning-strategist` |
| Messaging & value propositions | `messaging-specialist` |
| Go-to-market planning | `gtm-planner` |
| Launch coordination & execution | `launch-coordinator` |
| Pricing strategy & analysis | `pricing-analyst` |
| Portfolio management & health | `portfolio-manager` |
| Resource capacity & allocation | `resource-planner` |
| Project governance & gates | `governance-specialist` |
| Portfolio risk management | `risk-analyst` |
| Executive dashboards & reporting | `executive-reporter` |

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
