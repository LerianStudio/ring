# Ring Marketplace Manual

Quick reference guide for the Ring skills library and workflow system. This monorepo provides 4 plugins with 75 skills and 34 agents for enforcing proven software engineering practices across the entire software delivery value chain.

---

## 🏗️ Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                              MARKETPLACE (4 PLUGINS)                               │
│                     (monorepo: .claude-plugin/marketplace.json)                    │
│                                                                                    │
│  ┌───────────────┐  ┌───────────────┐                                              │
│  │ ring-default  │  │ ring-dev-team │                                              │
│  │  Skills(16)   │  │  Skills(37)   │                                              │
│  │  Agents(3)    │  │  Agents(24)   │                                              │
│  └───────────────┘  └───────────────┘                                              │
│  ┌───────────────┐  ┌───────────────┐                                              │
│  │ ring-pm-team  │  │ ring-tw-team  │                                              │
│  │  Skills(18)   │  │  Skills(6)    │                                              │
│  │  Agents(4)    │  │  Agents(3)    │                                              │
│  └───────────────┘  └───────────────┘                                              │
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

### Multi-harness install

Beyond Claude Code (source of truth), Ring is installable in Codex, Cursor, and OpenCode via per-plugin native manifests (`<plugin>/.codex-plugin/`, `<plugin>/.cursor-plugin/`, `<plugin>/.opencode/`). For local-dev symlinks across Claude Code, Factory AI, OpenCode, and Codex, use `bash ring-install.sh` at repo root. See [README § Supported Platforms](README.md#-supported-platforms) and [README § Quick Start](README.md#-quick-start) for full instructions.

---

## 💡 About Skills

Skills (77) are the primary invocation mechanism for Ring. They can be invoked directly by users (`Skill tool: "ring:skill-name"`) or applied automatically by Claude Code when it detects they're applicable. They handle testing, debugging, verification, planning, code review enforcement, and more.

Examples: ring:test-driven-development, ring:codereview, ring:production-readiness-audit (44-dimension audit, up to 10 explorers per batch, incremental report 0-430, max 440 with multi-tenant; see [default/skills/production-readiness-audit/SKILL.md](default/skills/production-readiness-audit/SKILL.md)), etc.

### Skill Selection Criteria

See [docs/FRONTMATTER_SCHEMA.md](docs/FRONTMATTER_SCHEMA.md) for the canonical schema. Skill selection now relies on the condensed `description` field plus body sections like `## When to use` / `## Skip when` / `## Sequence` / `## Related`.

Claude Code matches user intent against the skill's `description` field at SessionStart; body sections provide additional context once the skill is invoked.

---

## 🤖 Available Agents

Invoke via `Task tool with subagent_type: "..."`.

### Code Review pool (dev-team)

**Always dispatch all 9 defaults in parallel** (single message), plus triggered conditional specialists:

| Agent                                | Purpose                                      |
| ------------------------------------ | -------------------------------------------- |
| `ring:code-reviewer`                 | Architecture, patterns, maintainability      |
| `ring:business-logic-reviewer`       | Domain correctness, edge cases, requirements |
| `ring:security-reviewer`             | Vulnerabilities, OWASP, auth, validation     |
| `ring:test-reviewer`                 | Test coverage, quality, and completeness     |
| `ring:nil-safety-reviewer`           | Nil/null pointer safety analysis             |
| `ring:dead-code-reviewer`            | Unused code, unreachable paths, dead exports          |
| `ring:performance-reviewer`          | Performance hotspots, allocations, goroutine leaks, N+1 queries |
| `ring:multi-tenant-reviewer`         | lib-commons/multitenancy patterns, tenant isolation, tenantId propagation |
| `ring:lib-commons-reviewer`          | lib-commons package usage and reinvented-wheel opportunities |

Conditional specialists run only when their stack is touched:

| Agent | Trigger |
| ----- | ------- |
| `ring:lib-observability-reviewer` | tracing, metrics, logging, runtime recovery/panic safety, redaction, constants, SafeGo/recover implications |
| `ring:lib-systemplane-reviewer` | runtime config, hot-reload knobs, admin config surface, tenant-scoped settings, systemplane imports/config |
| `ring:lib-streaming-reviewer` | business events, outbox, event producers, broker publishing, CloudEvents, manifests/catalogs |

**Example:** Before merging, run the 9 default reviewers plus any triggered specialists via `ring:codereview` skill

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
| `ring:devops-engineer`                  | DevOps & infrastructure      | Docker, Kubernetes, CI/CD, cloud operations         |
| `ring:frontend-bff-engineer-typescript` | BFF & React/Next.js frontend | Next.js API Routes, Clean Architecture, DDD, React |
| `ring:frontend-designer`                | Visual design & aesthetics   | Typography, motion, CSS, distinctive UI            |
| `ring:frontend-engineer`                | General frontend development | React, TypeScript, CSS, component architecture     |
| `ring:helm-engineer`                    | Helm chart specialist        | Helm charts, Kubernetes, Lerian conventions        |
| `ring:prompt-quality-reviewer`          | AI prompt quality review     | Prompt engineering, clarity, effectiveness         |
| `ring:qa-analyst`                       | Backend QA specialist        | Unit, integration, load, chaos, regression testing  |
| `ring:qa-analyst-frontend`              | Frontend QA specialist       | Accessibility, visual regression, E2E, performance |
| `ring:sre`                              | SRE specialist               | Observability, reliability, SLOs, incident readiness |
| `ring:performance-reviewer`             | Performance review           | Go, TypeScript, Python, GOMAXPROCS, GC tuning      |
| `ring:multi-tenant-reviewer`            | Multi-tenant usage review    | lib-commons/multitenancy, tenant isolation, JWT tenantId |
| `ring:lib-commons-reviewer`             | lib-commons usage review | lifecycle, tenancy, http, idempotency, security, database, messaging |
| `ring:lib-observability-reviewer`       | Conditional observability review | tracing, metrics, logging, runtime, redaction |
| `ring:lib-systemplane-reviewer`         | Conditional runtime-config review | lib-systemplane, hot reload, admin config, tenant settings |
| `ring:lib-streaming-reviewer`           | Conditional event producer review | lib-streaming, outbox, CloudEvents, manifests |
| `ring:ui-engineer`                      | UI component specialist      | Design systems, accessibility, React               |

**Standards Compliance Output:** Refactor-capable ring-dev-team agents produce a `## Standards Compliance` output section with conditional requirement:

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
| Logging  | fmt.Println | lib-observability/zap | ⚠️     | service/\*.go |
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

---

## 📖 Common Workflows

### New Feature Development

1. **Plan** → Use `ring:pre-dev-feature` skill (or `ring:pre-dev-full` if complex)
2. **Isolate** → Use `ring:worktree` skill
3. **Implement** → Use `ring:test-driven-development` skill
4. **Review** → Use `ring:codereview` skill (dispatches 9 defaults plus triggered specialists)
5. **Commit** → Use `ring:commit` skill

### Bug Investigation

1. **Implement fix** → Use `ring:test-driven-development` skill
2. **Review & Merge** → Use `ring:codereview` + `ring:commit` skills

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
  • ring:dead-code-reviewer
  • ring:performance-reviewer
  • ring:multi-tenant-reviewer
  • ring:lib-commons-reviewer
  • conditionally: ring:lib-observability-reviewer
  • conditionally: ring:lib-systemplane-reviewer
  • conditionally: ring:lib-streaming-reviewer
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
| Feature will take < 2 days                             | `ring:pre-dev-feature` (skill) |
| Feature will take ≥ 2 days or has complex dependencies | `ring:pre-dev-full` (skill)    |
| Need implementation tasks                              | `ring:write-plan` (skill)      |
| Before merging code                                    | `ring:codereview` (skill)      |
| Start development cycle                                | `ring:dev-cycle` (skill)       |

### Agent Selection

| Need                              | Agent to Use                                |
| --------------------------------- | ------------------------------------------- |
| General code quality review       | 9 default reviewers plus triggered specialists via `ring:codereview` skill |
| Large PR review (15+ files)       | Auto-sliced via `ring:review-slicer`        |
| Implementation planning           | `ring:write-plan`                           |
| Deep codebase analysis            | `ring:codebase-explorer`                    |
| Go backend expertise              | `ring:backend-engineer-golang`              |
| TypeScript/Node.js backend        | `ring:backend-engineer-typescript`          |
| React/Next.js frontend & BFF      | `ring:frontend-bff-engineer-typescript`     |
| General frontend development      | `ring:frontend-engineer`                    |
| Visual design & aesthetics        | `ring:frontend-designer`                    |
| DevOps and infrastructure         | `ring:devops-engineer`                      |
| Helm charts & Kubernetes          | `ring:helm-engineer`                        |
| UI component development          | `ring:ui-engineer`                          |
| AI prompt quality review          | `ring:prompt-quality-reviewer`              |
| Backend quality assurance         | `ring:qa-analyst`                           |
| Frontend quality assurance         | `ring:qa-analyst-frontend`                  |
| Observability and reliability     | `ring:sre`                                  |
| Performance review                | `ring:performance-reviewer`                 |
| Multi-tenant usage review         | `ring:multi-tenant-reviewer`                |
| lib-commons usage review          | `ring:lib-commons-reviewer`                 |
| Best practices research           | `ring:best-practices-researcher`            |
| Framework documentation research  | `ring:framework-docs-researcher`            |
| Repository analysis               | `ring:repo-research-analyst`                |
| Product design & UX research      | `ring:product-designer`                     |
| Functional documentation (guides) | `ring:functional-writer`                    |
| API reference documentation       | `ring:api-writer`                           |
| Documentation quality review      | `ring:docs-reviewer`                        |

---

## 🔧 How Ring Works

### Session Startup

1. SessionStart hook runs automatically
2. All 75 skills are auto-discovered and available
3. `ring:using-ring` workflow is activated (skill checking is now mandatory)

### Agent Dispatching

```
Task tool:
  subagent_type: "ring:code-reviewer"
  prompt: [context]
    ↓
Runs agent
    ↓
Returns structured markdown output per the agent's documented sections
```

### Parallel Review Pattern

```
Single message with the selected review pool (not sequential):

Task #1: ring:code-reviewer
Task #2: ring:business-logic-reviewer
Task #3: ring:security-reviewer
Task #4: ring:test-reviewer
Task #5: ring:nil-safety-reviewer
Task #6: ring:dead-code-reviewer
Task #7: ring:performance-reviewer
Task #8: ring:multi-tenant-reviewer
Task #9: ring:lib-commons-reviewer
Conditional: ring:lib-observability-reviewer / ring:lib-systemplane-reviewer / ring:lib-streaming-reviewer when triggered
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
- **Agent Definitions** → `default/agents/*.md` and `dev-team/agents/*.md` files
- **Plugin Config** → `.claude-plugin/marketplace.json`
- **CLAUDE.md** → Project-specific instructions (checked into repo)

---

## ❓ Need Help?

- **How to use Claude Code?** → Ask about Claude Code features, MCP servers, skills
- **How to use Ring?** → Check skill names in this manual or in `ring:using-ring` skill
- **Feature/bug tracking?** → https://github.com/lerianstudio/ring/issues
