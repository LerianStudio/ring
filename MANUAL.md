# Ring Marketplace Manual

Quick reference guide for the Ring skills library and workflow system. This monorepo provides 4 plugins with 34+ skills, 12 agents, and 8 slash commands for enforcing proven software engineering practices.

## 🎯 Quick Start

Ring is auto-loaded at session start. Three ways to invoke Ring capabilities:

1. **Slash Commands** – `/ring-default:command-name`
2. **Skills** – `Skill tool: "ring-default:skill-name"`
3. **Agents** – `Task tool with subagent_type: "ring-default:agent-name"`

---

## 📋 Slash Commands

All commands prefixed with `/ring-default:` (can use `/ring:` shorthand in context).

### Project & Feature Workflows

| Command | Use Case | Example |
|---------|----------|---------|
| `/ring-default:brainstorm [topic]` | Interactive design refinement before coding | `/ring-default:brainstorm user-authentication` |
| `/ring-default:pre-dev-feature [name]` | Plan simple features (<2 days) – 3 gates | `/ring-default:pre-dev-feature logout-button` |
| `/ring-default:pre-dev-full [name]` | Plan complex features (≥2 days) – 8 gates | `/ring-default:pre-dev-full payment-system` |
| `/ring-default:worktree [branch-name]` | Create isolated git workspace | `/ring-default:worktree auth-system` |
| `/ring-default:write-plan [feature]` | Generate detailed task breakdown | `/ring-default:write-plan dashboard-redesign` |
| `/ring-default:execute-plan [path]` | Execute plan in batches with checkpoints | `/ring-default:execute-plan docs/pre-dev/feature/tasks.md` |

### Code & Integration Workflows

| Command | Use Case | Example |
|---------|----------|---------|
| `/ring-default:review [files-or-paths]` | Dispatch 3 parallel code reviewers | `/ring-default:review src/auth/` |
| `/ring-default:commit [message]` | Create git commit with AI trailers | `/ring-default:commit "fix(auth): improve token validation"` |

---

## 💡 About Skills

Skills (34+) are workflows that Claude Code invokes automatically when it detects they're applicable. They handle testing, debugging, verification, planning, and code review enforcement. You don't call them directly – Claude Code uses them internally to enforce best practices.

Examples: test-driven-development, systematic-debugging, requesting-code-review, verification-before-completion, etc.

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

**Example:** Before merging, run all 3 parallel reviewers via `/ring-default:review src/`

### Planning & Analysis (ring-default)

| Agent | Purpose | Model |
|-------|---------|-------|
| `ring-default:write-plan` | Generate implementation plans for zero-context execution | Opus |
| `ring-default:codebase-explorer` | Deep architecture analysis (vs `Explore` for speed) | Opus |

### Developer Specialists (ring-developers)

Use when you need expert depth in specific domains:

| Agent | Specialization | Technologies |
|-------|----------------|--------------|
| `ring-developers:backend-engineer-golang` | Go microservices & APIs | Fiber, gRPC, PostgreSQL, MongoDB, Kafka, OAuth2 |
| `ring-developers:devops-engineer` | Infrastructure & CI/CD | Docker, Kubernetes, Terraform, GitHub Actions |
| `ring-developers:frontend-engineer` | React/Next.js dashboards | React, TypeScript, Tailwind, state management |
| `ring-developers:qa-analyst` | Quality assurance | Test strategy, automation, coverage |
| `ring-developers:sre` | Site reliability & ops | Monitoring, alerting, incident response, SLOs |

### Regulatory & FinOps (ring-product-reporter)

For Brazilian financial compliance workflows:

| Agent | Purpose | Use For |
|-------|---------|---------|
| `ring-product-reporter:finops-analyzer` | Regulatory compliance analysis | Field mapping, BACEN/RFB validation (Gates 1-2) |
| `ring-product-reporter:finops-automation` | Template generation | Create .tpl files (Gate 3) |

---

## 📖 Common Workflows

### New Feature Development

1. **Design** → `/ring-default:brainstorm feature-name`
2. **Plan** → `/ring-default:pre-dev-feature feature-name` (or `pre-dev-full` if complex)
3. **Isolate** → `/ring-default:worktree feature-branch`
4. **Implement** → Use `ring-default:test-driven-development` skill
5. **Review** → `/ring-default:review src/` (dispatches 3 reviewers)
6. **Commit** → `/ring-default:commit "message"`

### Bug Investigation

1. **Investigate** → Use `ring-default:systematic-debugging` skill
2. **Trace** → Use `ring-default:root-cause-tracing` if needed
3. **Implement** → Use `ring-default:test-driven-development` skill
4. **Verify** → Use `ring-default:verification-before-completion` skill
5. **Review & Merge** → `/ring-default:review` + `/ring-default:commit`

### Code Review

```
/ring-default:review [files-or-paths]
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
3. **Reviewers run parallel** – Never sequential review (use `/ring-default:review`)
4. **Verification required** – Don't claim complete without evidence
5. **No incomplete code** – No "TODO" or placeholder comments
6. **Error handling required** – Don't ignore errors

---

## 💡 Best Practices

### Command Selection

| Situation | Use This |
|-----------|----------|
| New feature, unsure about design | `/ring-default:brainstorm` |
| Feature will take < 2 days | `/ring-default:pre-dev-feature` |
| Feature will take ≥ 2 days or has complex dependencies | `/ring-default:pre-dev-full` |
| Need implementation tasks | `/ring-default:write-plan` |
| Before merging code | `/ring-default:review` |


### Agent Selection

| Need | Agent to Use |
|------|-------------|
| General code quality review | 3 parallel reviewers via `/ring-default:review` |
| Go backend expertise | `ring-developers:backend-engineer-golang` |
| Infrastructure/DevOps | `ring-developers:devops-engineer` |
| React/Next.js frontend | `ring-developers:frontend-engineer` |
| Deep codebase analysis | `ring-default:codebase-explorer` |
| Regulatory compliance | `ring-product-reporter:finops-analyzer` |

---

## 🔧 How Ring Works

### Session Startup

1. SessionStart hook runs automatically
2. All 34+ skills are auto-discovered and available
3. `using-ring` workflow is activated (skill checking is now mandatory)

### Agent Dispatching

```
Task tool:
  subagent_type: "ring-default:code-reviewer"
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

Task #1: ring-default:code-reviewer
Task #2: ring-default:business-logic-reviewer
Task #3: ring-default:security-reviewer
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
