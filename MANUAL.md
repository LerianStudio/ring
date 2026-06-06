# Ring Marketplace Manual

Quick reference guide for the Ring skills library and workflow system. This monorepo provides 4 plugins with 71 skills and 33 agents for enforcing proven software engineering practices across the entire software delivery value chain.

---

## 🏗️ Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                              MARKETPLACE (4 PLUGINS)                               │
│                     (monorepo: .claude-plugin/marketplace.json)                    │
│                                                                                    │
│  ┌───────────────┐  ┌───────────────┐                                              │
│  │ ring-default  │  │ ring-dev-team │                                              │
│  │  Skills(16)   │  │  Skills(33)   │                                              │
│  │  Agents(2)    │  │  Agents(24)   │                                              │
│  └───────────────┘  └───────────────┘                                              │
│  ┌───────────────┐  ┌───────────────┐                                              │
│  │ ring-pm-team  │  │ ring-tw-team  │                                              │
│  │  Skills(18)   │  │  Skills(4)    │                                              │
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

Skills (71) are the primary invocation mechanism for Ring. They can be invoked directly by users (`Skill tool: "ring:skill-name"`) or applied automatically by Claude Code when it detects they're applicable. They handle testing, debugging, verification, planning, code review enforcement, and more.

Examples: ring:test-driven-development, ring:reviewing-code, ring:auditing-production-readiness (44-dimension audit, up to 10 explorers per batch, incremental report 0-430, max 440 with multi-tenant; see [default/skills/auditing-production-readiness/SKILL.md](default/skills/auditing-production-readiness/SKILL.md)), etc.

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
| `ring:logic-reviewer`       | Domain correctness, edge cases, requirements |
| `ring:security-reviewer`             | Vulnerabilities, OWASP, auth, validation     |
| `ring:test-reviewer`                 | Test coverage, quality, and completeness     |
| `ring:nil-reviewer`           | Nil/null pointer safety analysis             |
| `ring:dead-code-reviewer`            | Unused code, unreachable paths, dead exports          |
| `ring:perf-reviewer`          | Performance hotspots, allocations, goroutine leaks, N+1 queries |
| `ring:tenancy-reviewer`         | lib-commons/multitenancy patterns, tenant isolation, tenantId propagation |
| `ring:commons-reviewer`          | lib-commons package usage and reinvented-wheel opportunities |

Conditional specialists run only when their stack is touched:

| Agent | Trigger |
| ----- | ------- |
| `ring:obs-reviewer` | tracing, metrics, logging, runtime recovery/panic safety, redaction, constants, SafeGo/recover implications |
| `ring:systemplane-reviewer` | runtime config, hot-reload knobs, admin config surface, tenant-scoped settings, systemplane imports/config |
| `ring:streaming-reviewer` | business events, outbox, event producers, broker publishing, CloudEvents, manifests/catalogs |

**Example:** Before merging, run the 9 default reviewers plus any triggered specialists via `ring:reviewing-code` skill

### Orchestration (ring-default)

| Agent                  | Purpose                                                            |
| ---------------------- | ------------------------------------------------------------------ |
| `ring:review-slicer`   | Groups large multi-themed PRs into thematic slices for focused review |

### Planning & Analysis (ring-default)

| Agent                    | Purpose                                                  |
| ------------------------ | -------------------------------------------------------- |
| `ring:codebase-explorer` | Deep architecture analysis (vs `Explore` for speed)      |

### Developer Specialists (ring-dev-team)

Use when you need expert depth in specific domains:

| Agent                                   | Specialization               | Technologies                                       |
| --------------------------------------- | ---------------------------- | -------------------------------------------------- |
| `ring:backend-go`          | Go microservices & APIs      | Fiber, gRPC, PostgreSQL, MongoDB, Kafka, OAuth2    |
| `ring:backend-ts`      | TypeScript/Node.js backend   | Express, NestJS, Prisma, TypeORM, GraphQL          |
| `ring:devops`                  | DevOps & infrastructure      | Docker, Kubernetes, CI/CD, cloud operations         |
| `ring:bff-ts` | BFF & React/Next.js frontend | Next.js API Routes, Clean Architecture, DDD, React |
| `ring:ui-designer`                | Visual design & aesthetics   | Typography, motion, CSS, distinctive UI            |
| `ring:frontend`                | General frontend development | React, TypeScript, CSS, component architecture     |
| `ring:helm`                    | Helm chart specialist        | Helm charts, Kubernetes, Lerian conventions        |
| `ring:prompt-reviewer`          | AI prompt quality review     | Prompt engineering, clarity, effectiveness         |
| `ring:qa`                       | Backend QA specialist        | Unit, integration, load, chaos, regression testing  |
| `ring:qa-frontend`              | Frontend QA specialist       | Accessibility, visual regression, E2E, performance |
| `ring:sre`                              | SRE specialist               | Observability, reliability, SLOs, incident readiness |
| `ring:perf-reviewer`             | Performance review           | Go, TypeScript, Python, GOMAXPROCS, GC tuning      |
| `ring:tenancy-reviewer`            | Multi-tenant usage review    | lib-commons/multitenancy, tenant isolation, JWT tenantId |
| `ring:commons-reviewer`             | lib-commons usage review | lifecycle, tenancy, http, idempotency, security, database, messaging |
| `ring:obs-reviewer`       | Conditional observability review | tracing, metrics, logging, runtime, redaction |
| `ring:systemplane-reviewer`         | Conditional runtime-config review | lib-systemplane, hot reload, admin config, tenant settings |
| `ring:streaming-reviewer`           | Conditional event producer review | lib-streaming, outbox, CloudEvents, manifests |
| `ring:ui-engineer`                      | UI component specialist      | Design systems, accessibility, React               |

**Standards Compliance Output:** Refactor-capable ring-dev-team agents produce a `## Standards Compliance` output section with conditional requirement:

| Invocation Context      | Standards Compliance | Trigger                                   |
| ----------------------- | -------------------- | ----------------------------------------- |
| Direct agent call       | Optional             | N/A                                       |
| Via `ring:running-dev-cycle`    | Optional             | N/A                                       |
| Via `ring:planning-backend-refactor` | **MANDATORY**        | Prompt contains `**MODE: ANALYSIS ONLY**` |

**How it works:**

1. `ring:planning-backend-refactor` dispatches agents with `**MODE: ANALYSIS ONLY**` in prompt
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

**Cross-references:** CLAUDE.md (Standards Compliance section), `dev-team/skills/planning-backend-refactor/SKILL.md`

### Product Planning Research (ring-pm-team)

For best practices research and repository analysis:

| Agent                            | Purpose                          | Use For                                 |
| -------------------------------- | -------------------------------- | --------------------------------------- |
| `ring:web-researcher` | Best practices research          | Industry patterns, framework standards  |
| `ring:docs-researcher` | Framework documentation research | Official docs, API references, examples |
| `ring:repo-researcher`     | Repository analysis              | Codebase patterns, structure analysis   |
| `ring:product-designer`          | Product design and UX research   | UX specifications, user validation, design review |

### Technical Writing (ring-tw-team)

For documentation creation and review:

| Agent                    | Purpose                      | Use For                              |
| ------------------------ | ---------------------------- | ------------------------------------ |
| `ring:guide-writer` | Functional documentation     | Guides, tutorials, conceptual docs   |
| `ring:api-writer`        | API reference documentation  | Endpoints, schemas, examples         |
| `ring:docs-reviewer`     | Documentation quality review | Voice, tone, structure, completeness |

---

## 📖 Common Workflows

### New Feature Development

1. **Plan** → Use `ring:planning-small-features` skill (or `ring:planning-large-features` if complex) — produces a rolling-wave phased plan (`tasks.md`: phases → epics E-X.Y → tasks T-X.Y.Z; only Phase 1 task-detailed)
2. **Isolate** → Use `ring:creating-worktrees` skill
3. **Implement** → Use `ring:running-dev-cycle` skill (consumes `tasks.md`: Gate 0 TDD per task, review/validation per epic, phase-boundary elaboration of the next phase) — or `ring:test-driven-development` directly for ad-hoc changes
4. **Review** → Use `ring:reviewing-code` skill (dispatches 9 defaults plus triggered specialists; runs at epic cadence inside dev-cycle)
5. **Commit** → Use `ring:committing-changes` skill

### Bug Investigation

1. **Implement fix** → Use `ring:test-driven-development` skill
2. **Review & Merge** → Use `ring:reviewing-code` + `ring:committing-changes` skills

### Code Review

```
ring:reviewing-code skill
    ↓
Runs in parallel:
  • ring:code-reviewer
  • ring:logic-reviewer
  • ring:security-reviewer
  • ring:test-reviewer
  • ring:nil-reviewer
  • ring:dead-code-reviewer
  • ring:perf-reviewer
  • ring:tenancy-reviewer
  • ring:commons-reviewer
  • conditionally: ring:obs-reviewer
  • conditionally: ring:systemplane-reviewer
  • conditionally: ring:streaming-reviewer
    ↓
Consolidated report with recommendations
```

---

## 🎓 Mandatory Rules

These enforce quality standards:

1. **TDD is enforced** – Test must fail (RED) before implementation
2. **Skill check is mandatory** – Use `ring:using-ring` before any task
3. **Reviewers run parallel** – Never sequential review (use `ring:reviewing-code` skill)
4. **Verification required** – Don't claim complete without evidence
5. **No incomplete code** – No "TODO" or placeholder comments
6. **Error handling required** – Don't ignore errors

---

## 💡 Best Practices

### Skill & Command Selection

| Situation                                              | Use This                       |
| ------------------------------------------------------ | ------------------------------ |
| Feature will take < 2 days                             | `ring:planning-small-features` (skill) |
| Feature will take ≥ 2 days or has complex dependencies | `ring:planning-large-features` (skill)    |
| Need implementation tasks                              | `ring:writing-plans` (skill)   |
| Before merging code                                    | `ring:reviewing-code` (skill)      |
| Start development cycle                                | `ring:running-dev-cycle` (skill)       |

### Agent Selection

| Need                              | Agent to Use                                |
| --------------------------------- | ------------------------------------------- |
| General code quality review       | 9 default reviewers plus triggered specialists via `ring:reviewing-code` skill |
| Large PR review (15+ files)       | Auto-sliced via `ring:review-slicer`        |
| Implementation planning           | `ring:writing-plans`                        |
| Deep codebase analysis            | `ring:codebase-explorer`                    |
| Go backend expertise              | `ring:backend-go`              |
| TypeScript/Node.js backend        | `ring:backend-ts`          |
| React/Next.js frontend & BFF      | `ring:bff-ts`     |
| General frontend development      | `ring:frontend`                    |
| Visual design & aesthetics        | `ring:ui-designer`                    |
| DevOps and infrastructure         | `ring:devops`                      |
| Helm charts & Kubernetes          | `ring:helm`                        |
| UI component development          | `ring:ui-engineer`                          |
| AI prompt quality review          | `ring:prompt-reviewer`              |
| Backend quality assurance         | `ring:qa`                           |
| Frontend quality assurance         | `ring:qa-frontend`                  |
| Observability and reliability     | `ring:sre`                                  |
| Performance review                | `ring:perf-reviewer`                 |
| Multi-tenant usage review         | `ring:tenancy-reviewer`                |
| lib-commons usage review          | `ring:commons-reviewer`                 |
| Best practices research           | `ring:web-researcher`            |
| Framework documentation research  | `ring:docs-researcher`            |
| Repository analysis               | `ring:repo-researcher`                |
| Product design & UX research      | `ring:product-designer`                     |
| Functional documentation (guides) | `ring:guide-writer`                    |
| API reference documentation       | `ring:api-writer`                           |
| Documentation quality review      | `ring:docs-reviewer`                        |

---

## 🔧 How Ring Works

### Session Startup

1. SessionStart hook runs automatically
2. All 71 skills are auto-discovered and available
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
Task #2: ring:logic-reviewer
Task #3: ring:security-reviewer
Task #4: ring:test-reviewer
Task #5: ring:nil-reviewer
Task #6: ring:dead-code-reviewer
Task #7: ring:perf-reviewer
Task #8: ring:tenancy-reviewer
Task #9: ring:commons-reviewer
Conditional: ring:obs-reviewer / ring:systemplane-reviewer / ring:streaming-reviewer when triggered
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
