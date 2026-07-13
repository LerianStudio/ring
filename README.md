<p align="center">
  <img src="assets/ring-banner.png" alt="Ring by Lerian" width="100%" />
</p>

# 💍 The Ring - Skills Library for AI Agents

**Proven engineering practices, enforced through skills.**

Ring is a comprehensive skills library and workflow system for AI agents that transforms how AI assistants approach software development. Currently implemented as a **Claude Code plugin marketplace** with **4 active plugins**, **76 skills**, and **33 agents** (see `.claude-plugin/marketplace.json` for current versions), the skills themselves are agent-agnostic and can be used with any AI agent system. Ring provides battle-tested patterns, mandatory workflows, and systematic approaches across the entire software delivery value chain.

## ✨ Why Ring?

Without Ring, AI assistants often:

- Skip tests and jump straight to implementation
- Make changes without understanding root causes
- Claim tasks are complete without verification
- Forget to check for existing solutions
- Repeat known mistakes

Ring solves this by:

- **Enforcing proven workflows** - Test-driven development, systematic debugging, proper planning
- **Providing 76 specialized skills** (23 core + 35 dev-team + 14 product planning + 4 technical writing)
- **33 specialized agents** - 2 planning/analysis + 24 developer/reviewer + 4 product research + 3 technical writing
- **Automating skill discovery** - Skills load automatically at session start
- **Preventing common failures** - Built-in anti-patterns and mandatory checklists

## 🧭 Project Identity

**Ring is Lerian-first, open-source-friendly.** Design decisions prioritize the Lerian engineering team's daily needs while keeping the architecture clean and reusable for external adoption. This means:

- **Lerian-specific skills stay active** — Internal integrations and domain-specific workflows remain in the marketplace because the team uses them
- **The architecture is universal** — Skills, agents, and the plugin system work with any codebase or team
- **Archival is usage-driven** — Skills are archived when they stop being used, not because they're "too specific"

## 🤖 Specialized Agents

**Planning & Analysis Agents (default plugin):**

- `ring:review-slicer` - Review slicer (groups large multi-themed PRs into thematic slices for focused parallel review)
- `ring:codebase-explorer` - Deep architecture analysis (deep-analysis, complements built-in Explore)
- Use `ring:reviewing-code` skill to orchestrate parallel review workflow

**Developer Agents (dev-team plugin):**

- `ring:backend-go` - Go backend specialist for financial systems
- `ring:backend-ts` - TypeScript/Node.js backend specialist (Express, NestJS, Fastify)
- `ring:bff-ts` - BFF & React/Next.js frontend with Clean Architecture
- `ring:ui-designer` - Visual design specialist
- `ring:frontend` - Senior Frontend Engineer (React/Next.js)
- `ring:devops` - DevOps and infrastructure specialist
- `ring:prompt-reviewer` - Agent Quality Analyst
- `ring:qa` - Backend QA specialist (unit, integration, load, chaos)
- `ring:qa-frontend` - Frontend QA specialist (accessibility, visual, E2E, performance)
- `ring:sre` - Observability and reliability specialist
- `ring:ui-engineer` - UI component specialist (design systems, accessibility)
- `ring:helm` - Helm chart specialist (chart structure, security, Lerian conventions)
- `ring:code-reviewer` - Foundation review (architecture, code quality, design patterns)
- `ring:logic-reviewer` - Correctness review (domain logic, requirements, edge cases)
- `ring:security-reviewer` - Safety review (vulnerabilities, OWASP, authentication)
- `ring:test-reviewer` - Test quality review (coverage, edge cases, assertions, test anti-patterns)
- `ring:nil-reviewer` - Nil/null safety review (traces pointer risks, missing guards, panic paths)
- `ring:dead-code-reviewer` - Dead code review (orphaned code detection, reachability analysis, dead dependency chains)
- `ring:commons-reviewer` - lib-commons package usage review (lifecycle, tenancy, http, idempotency, security, database, messaging, outbox; reinvented-wheel opportunities)
- `ring:obs-reviewer` - Conditional specialist for tracing, metrics, logging, runtime recovery, redaction, constants, and SafeGo implications
- `ring:systemplane-reviewer` - Conditional specialist for runtime config, hot-reload knobs, admin config, tenant-scoped settings, and systemplane imports
- `ring:streaming-reviewer` - Conditional specialist for business events, outbox, producers, broker publishing, CloudEvents, manifests, and catalogs
- `ring:tenancy-reviewer` - Multi-tenant usage review (lib-commons/multitenancy patterns, tenant isolation, JWT tenantId propagation)
- `ring:perf-reviewer` - Performance review (code hotspots, infra misconfigurations, Go/TypeScript/Python)

> **Standards Compliance:** Refactor-capable dev-team agents produce a `## Standards Compliance` output section with conditional requirement:
>
> - **Optional** when invoked directly or via `ring:running-dev-cycle`
> - **MANDATORY** when invoked from `ring:planning-backend-refactor` (triggered by `**MODE: ANALYSIS ONLY**` in prompt)
>
> When mandatory, agents load Ring standards via WebFetch and produce comparison tables with:
>
> - Current Pattern vs Expected Pattern
> - Severity classification (Critical/High/Medium/Low)
> - File locations and migration recommendations
>
> See `dev-team/docs/standards/*.md` for standards source. Cross-references: CLAUDE.md (Standards Compliance section), `dev-team/skills/planning-backend-refactor/SKILL.md`

**Product Research Agents (ring-pm-team plugin):**

- `ring:repo-researcher` - Repository structure and codebase analysis
- `ring:web-researcher` - Industry best practices research
- `ring:docs-researcher` - Framework documentation research
- `ring:product-designer` - Product design and UX research

**Technical Writing Agents (ring-tw-team plugin):**

- `ring:guide-writer` - Functional documentation (guides, tutorials, conceptual docs)
- `ring:api-writer` - API reference documentation (endpoints, schemas, examples)
- `ring:docs-reviewer` - Documentation quality review (voice, tone, structure, completeness)

_Plugin versions are managed in `.claude-plugin/marketplace.json`_

### 📦 Archived Plugins

The following plugins have been archived and are not actively maintained. They remain available in `.archive/` for reference:

| Plugin         | Description                                             | Status                                                   |
| -------------- | ------------------------------------------------------- | -------------------------------------------------------- |
| `pmm-team`     | Product Marketing (GTM, positioning, competitive intel) | Archived - functionality may be restored based on demand |
| `finance-team` | Financial planning and analysis                         | Archived - under evaluation                              |
| `ops-team`     | Operations management                                   | Archived - under evaluation                              |

_To restore an archived plugin, move its folder from `.archive/` to the root directory and register it in `marketplace.json`._

## 🖥️ Supported Platforms

Ring works across multiple AI development platforms:

| Platform        | Native manifest        | Symlink installer       | Status             |
| --------------- | ---------------------- | ----------------------- | ------------------ |
| **Claude Code** | ✅ marketplace.json    | ✅ `--claude`           | Source of truth    |
| **Codex**       | ✅ `.codex-plugin/`    | ✅ `--codex` (built)    | Both paths work    |
| **OpenCode**    | ✅ `.opencode/`        | ✅ `--opencode` (built) | Both paths work    |
| **Cursor**      | ✅ `.cursor-plugin/`   | ❌ not in installer     | Native only        |
| **Factory AI**  | ❌                     | ✅ `--factory`          | Installer only     |

**Two install mechanisms:**

- **Native manifest** — the harness installs Ring directly from this repo via its own package manager (`opencode.json`, Cursor plugin marketplace, Codex plugin manifest). No local build step, no manual symlink work. Best for end users and CI.
- **Symlink installer** (`ring-install.sh`) — symlinks from your local harness config dir into a cloned Ring repo. For Codex/OpenCode, the installer builds a transformed tree at `.ring-build/` first (namespace + frontmatter rewrites). Best for local development with hot-reload against the source tree.

See the [`Native plugin install`](#native-plugin-install-per-harness) and [`Symlink installer`](#symlink-installer-local-dev) sub-sections below for usage.

## 🚀 Quick Start

### Native plugin install (per harness)

Each Ring plugin ships native manifests for Claude Code, Codex, Cursor, and OpenCode. The harness installs the plugin directly from this repo via its own package manager — no transformation step, no local installer.

| Harness         | Mechanism                                | Per-plugin entry points |
| --------------- | ---------------------------------------- | ----------------------- |
| **Claude Code** | `.claude-plugin/marketplace.json` (root) | All 4 plugins enumerated in one marketplace file |
| **Codex**       | `<plugin>/.codex-plugin/plugin.json`     | [default](default/.codex-plugin/plugin.json) · [dev-team](dev-team/.codex-plugin/plugin.json) · [pm-team](pm-team/.codex-plugin/plugin.json) · [tw-team](tw-team/.codex-plugin/plugin.json) |
| **Cursor**      | `<plugin>/.cursor-plugin/plugin.json`    | [default](default/.cursor-plugin/plugin.json) · [dev-team](dev-team/.cursor-plugin/plugin.json) · [pm-team](pm-team/.cursor-plugin/plugin.json) · [tw-team](tw-team/.cursor-plugin/plugin.json) |
| **OpenCode**    | `<plugin>/.opencode/` (INSTALL + JS plugin) | [default](default/.opencode/INSTALL.md) · [dev-team](dev-team/.opencode/INSTALL.md) · [pm-team](pm-team/.opencode/INSTALL.md) · [tw-team](tw-team/.opencode/INSTALL.md) |

**`ring-default` is the foundation plugin** — install it alongside any other Ring plugin since it provides the `using-ring` bootstrap that orients agent behavior. Example for OpenCode:

```json
{
  "plugin": [
    "ring-default@git+https://github.com/lerianstudio/ring.git#main",
    "ring-dev-team@git+https://github.com/lerianstudio/ring.git#main"
  ]
}
```

Each harness's INSTALL.md (for OpenCode) or `plugin.json` (for Codex/Cursor) carries the exact install command for that platform.

### Symlink installer (local dev)

`ring-install.sh` symlinks your harness's local config dir into this cloned Ring repo. For Codex and OpenCode, it first builds a transformed tree at `.ring-build/` (namespace + frontmatter rewrites required by those tools).

**Supported targets:** Claude Code, Factory AI, OpenCode, Codex.
**Not supported by the installer:** Cursor (use the [native plugin install above](#native-plugin-install-per-harness)).

```bash
# Clone the repo
git clone https://github.com/lerianstudio/ring.git ~/ring
cd ~/ring

# Interactive menu (lets you pick targets)
bash ring-install.sh

# Or target specific harnesses without the prompt:
bash ring-install.sh --claude               # Claude Code (per-file symlinks)
bash ring-install.sh --factory              # Factory AI (per-file symlinks)
bash ring-install.sh --opencode             # OpenCode (builds .ring-build/opencode/ first)
bash ring-install.sh --codex                # Codex    (builds .ring-build/codex/ first)
bash ring-install.sh --all                  # All four supported targets
```

#### Installer subcommands

```bash
bash ring-install.sh install --opencode --codex   # install symlinks for selected targets
bash ring-install.sh remove                        # remove all Ring symlinks
bash ring-install.sh build                         # rebuild .ring-build/{opencode,codex} only
bash ring-install.sh clean                         # remove .ring-build/ outputs
bash ring-install.sh doctor                        # verify install + build outputs
bash ring-install.sh all --all -y                  # clean + build + install for all targets, no prompt
```

**Flags:** `--yes` / `-y` (skip confirmation), `--dry-run` (preview without changes), `--force` (back up non-symlink collisions), `--verbose`.

### Claude Code Plugin Marketplace

For Claude Code users, you can also install from the marketplace:

- Open Claude Code
- Go to Settings → Plugins
- Search for "ring"
- Click Install

### Manual Installation (Claude Code only)

```bash
# Clone the marketplace repository
git clone https://github.com/lerianstudio/ring.git ~/ring

# Skills auto-load at session start via hooks
# No additional configuration needed for Claude Code
```

### Code Analysis Pipeline

The `ring:reviewing-code` pipeline uses [Mithril](https://github.com/LerianStudio/mithril), an external code analysis tool installed via `go install`. Mithril performs static analysis, AST extraction, call graph generation, and context compilation for AI-assisted code review.

Install via `go install github.com/lerianstudio/mithril@latest`. See the [Mithril repository](https://github.com/LerianStudio/mithril) for full installation details and release notes.

### First Session

When you start a new Claude Code session with Ring installed, you'll see:

```
## Available Skills:
- ring:using-ring (Check for skills BEFORE any task)
- ring:test-driven-development (RED-GREEN-REFACTOR cycle)
- ring:reviewing-code (9 defaults + conditional specialist dispatch)
- ring:exploring-codebases (Two-phase codebase exploration)
... and 71 more skills
```

## 🎯 Core Skills

### Start Here

#### 1. **ring:using-ring** - Mandatory Skill Discovery

```
Before ANY action → Check skills
Before ANY tool → Check skills
Before ANY code → Check skills
```

#### 2. **ring:test-driven-development** - Test First, Always

```
RED → Write failing test → Watch it fail
GREEN → Minimal code → Watch it pass
REFACTOR → Clean up → Stay green
```

## 📚 All 76 Skills (Across 4 Plugins)

### Core Skills (ring-default plugin - 24 skills)

**Testing & Quality (3):**

- `ring:test-driven-development` - Write test first, watch fail, minimal code
- `ring:fixing-lint` - Parallel lint fixing with agent dispatch
- `ring:cleaning-comments` - Remove redundant, stale, or low-value comments while preserving intent-revealing ones

**Collaboration & Planning (11):**

- `ring:reviewing-code` - **Parallel 9 defaults + conditional specialist dispatch** with severity-based handling
- `ring:creating-worktrees` - Isolated development
- `ring:creating-managed-sessions` - Open one tmux window/session per worktree (auto-detects ai-tmux-sessions; windows inside tmux, new session outside)
- `ring:committing-changes` - Smart commit organization with atomic grouping, conventional commits, and trailers
- `ring:opening-pull-requests` - Open a PR with base-branch detection, scope allowlist enforcement, and template filling
- `ring:shipping-changes` - End-to-end commit-and-ship flow from working tree to open PR
- `ring:writing-plans` - Author phased implementation plans (phase → epic → task) from a spec; first phase detailed into dispatch-ready tasks, later phases epic-level for rolling-wave elaboration
- `ring:executing-plans` - Rolling-wave execution of a phased plan: implement the detailed phase, checkpoint with the user, elaborate the next phase against the real codebase, repeat
- `ring:dispatching-workflows` - Rolling-wave execution where each phase runs as a reviewed multi-agent workflow harness (mandatory in-harness review + adversarial contrarian pass) before returning verified work
- `ring:analyzing-options` - Structured comparison of approaches with effort estimates and a recommendation
- `ring:generating-pr-descriptions` - Generate PR descriptions from branch diff analysis

**Meta Skills (4):**

- `ring:using-ring` - Mandatory skill discovery
- `ring:writing-skills` - TDD for documentation
- `ring:testing-skills-with-subagents` - Skill validation
- `ring:engineering-prompts` - Engineer and refine prompts for skills and agents

**Session & Learning (5):**

- `ring:exploring-codebases` - Two-phase codebase exploration
- `ring:generating-release-guides` - Generate Ops Update Guide from git diff analysis
- `ring:visualizing` - Generate self-contained HTML pages to visually explain systems, code changes, and data
- `ring:creating-handoffs` - Create handoff documents capturing session state for seamless context-clear and resume
- `ring:searching-code` - Targeted code search patterns and dispatch strategies

**Audit & Readiness (1):**

- `ring:auditing-production-readiness` - 44-dimension production readiness audit; runs explorers in batches of up to 10, appends incrementally to a single report; output: scored report (0-430, max 440 with multi-tenant) with severity ratings. See [default/skills/auditing-production-readiness/SKILL.md](default/skills/auditing-production-readiness/SKILL.md) for invocation and implementation details.

### Developer Skills (ring-dev-team plugin - 35 skills)

**Orchestration & Refactoring (7):**

- `ring:using-dev-team` - Introduction to developer specialist agents
- `ring:running-dev-cycle` - Lean backend development cycle orchestrator driven by a rolling-wave phased plan (phases → epics `Epic N.M` → tasks `Task N.M.T`): Gate 0 implementation-owned TDD/coverage/docker-compose/runtime/delivery verification per task, Gate 8 review + Gate 9 validation per epic, phase boundary (Step 11.5) closes each phase and elaborates the next against the real codebase
- `ring:running-dev-cycle-frontend` - Lean frontend development cycle orchestrator on the same rolling-wave phased plan (Gate 0 per task, Gate 7 review per epic, Gate 8 validation per task, phase boundary per phase)
- `ring:planning-backend-refactor` - Backend/codebase standards analysis
- `ring:planning-frontend-refactor` - Frontend standards analysis and task generation
- `ring:planning-codebase-simplification` - Whole-codebase structural simplification sweep (hunts unjustified abstractions, adapters, shims; KILL/REVIEW/KEEP output; DELETE-by-default burden of proof for pre-public applications)
- `ring:managing-dev-cycle` - Development cycle state management (phase/epic status reporting and cancellation)

**Backend Gate Skills:**

- `ring:implementing-tasks` - Gate 0: TDD implementation
- `ring:adding-multi-tenancy` - Multi-tenant adaptation (database-per-tenant isolation, integrated into Gate 0)
- `ring:hardening-dockerfiles` - Docker image security audit for Docker Hub Health Score grade A
- `ring:creating-helm-charts` - Helm chart creation and maintenance following Lerian conventions
- `ring:mapping-service-resources` - Service/module/resource hierarchy scanner for dispatch layer
- `ring:implementing-readyz` - Comprehensive readiness probes (/readyz) with per-dependency status and TLS validation
- `ring:instrumenting-streaming-events` - Wire lib-streaming event emission from a validated instrumentation map

**Testing & Validation:**

- `ring:detecting-goroutine-leaks` - Goroutine leak detection and regression testing
- `ring:validating-acceptance-criteria` - Gate 9: User approval
- `ring:writing-dev-reports` - Assertiveness scoring and metrics
- `ring:verifying-code` - Atomic Go code verification with MERGE_READY/NEEDS_FIX verdict

**Migration & Reference (14):**

- `ring:using-lib-commons` - Comprehensive reference for lib-commons v5.0.2 (Lerian's shared Go library with 30+ packages)
- `ring:using-runtime` - Deep reference and 6-angle audit for lib-observability/runtime: SafeGo, panic recovery, observability trident, policy selection, framework integration. Catches naked goroutine launches that cause silent production failures.
- `ring:using-assert` - Deep reference and 6-angle audit for lib-observability/assert: production runtime assertions with observability trident, full domain predicate catalog (double-entry, transaction state machine, financial validations), AssertionError unwrapping patterns. Converts financial invariants into production-enforced rules.
- `ring:migrating-to-lib-systemplane` - Migrate Lerian Go services from .env/YAML config to systemplane (database-backed hot-reloadable config)
- `ring:generating-llms-txt` - Generate or audit llms.txt files following llmstxt.org spec for AI-friendly repository entry points
- `ring:applying-licenses` - Repository license management (Apache 2.0, Elastic v2, Proprietary)
- `ring:adopting-lib-commons-huma-wrapper` - Adopt the lib-commons/v5 shared Huma (OAS 3.1) OpenAPI wrapper + RFC 9457 problem model
- `ring:applying-composition-patterns` - Apply Go composition patterns (interfaces, embedding, functional options)
- `ring:migrating-to-lib-observability` - Migrate off deprecated lib-commons observability imports to lib-observability
- `ring:using-lib-observability` - Reference + sweep for lib-observability (log, metrics, zap, redaction, constants)
- `ring:using-lib-streaming` - Reference + sweep for lib-streaming (business events, outbox, producers, CloudEvents)
- `ring:using-lib-systemplane` - Reference + sweep for lib-systemplane (runtime config, hot-reloadable knobs)
- `ring:using-outbox` - Transactional outbox pattern via lib-commons for reliable event publishing
- `ring:using-tracing` - Reference + sweep for lib-observability tracing (spans, context propagation, OTel)

**Security (2):**

- `ring:auditing-dependency-security` - Supply-chain gate for dependency installations (validates identity, vulnerabilities, suspicious signals)
- `ring:reviewing-operational-risk` - Reviews built flows for operational recovery gaps and resilience risks

**Frontend Quality Skills (1):**

- `ring:checking-frontend-quality` - Frontend quality checks in modes `accessibility` (axe-core/WCAG), `visual` (snapshots/viewports), `e2e` (Playwright 3-browser), `performance` (Lighthouse/Core Web Vitals), or `all`; dispatches `ring:qa-frontend`

> Frontend and backend dev-cycle workflows both use `ring:reviewing-code` (core plugin) as the review gate.

### Product Planning Skills (ring-pm-team plugin - 14 skills)

**Pre-Development Workflow (includes ring:using-pm-team + 7 gate skills; Large track gate numbers shown):**

- `ring:using-pm-team` - Introduction to product planning workflow

0. `ring:researching-features` - Deep technical/product research (parallel agents)
1. `ring:writing-prds` - Squad-facing product requirements (WHAT/WHY)
2. `ring:mapping-feature-relationships` - Feature relationships and phasing (Large only)
3. `ring:writing-trds` - Technical architecture (HOW)
4. `ring:designing-api-contracts` - OpenAPI 3.1 contract (openapi.yaml)
5. `ring:designing-data-model` - Stack-native schema (schema.sql / schema.prisma)
6. `ring:pinning-dependency-versions` - Technology selection
7. `ring:writing-plans` (ring-default) - Single execution plan (plan.md), invoked by the orchestrator

**Workflow Orchestrators:**

- `ring:planning-small-features` - 4-gate orchestrator for small features (<2 days)
- `ring:planning-large-features` - 8-gate orchestrator for large features (>=2 days)

**Additional Planning Skills:**

- `ring:validating-ux-completeness` - Standalone UX validation for UI features (run before the TRD)
- `ring:reconciling-predev-docs` - Deep cross-reference review of pre-dev documentation artifacts
- `ring:mapping-streaming-events` - Standalone streaming-event discovery (event catalog + instrumentation map)
- `ring:creating-grafana-dashboards` - Grafana dashboard generation for instrumented services

### Technical Writing Skills (ring-tw-team plugin - 4 skills)

**Documentation Creation:**

- `ring:using-tw-team` - Introduction to technical writing specialists
- `ring:structuring-documentation` - Document hierarchy and organization
- `ring:applying-voice-and-tone` - Voice and tone guidelines (assertive, encouraging, human)
- `ring:reviewing-docs` - Quality checklist and review process

## 💡 Usage Examples

### Building a Feature

```
User: "Add user authentication to the app"
Claude: I'm using ring:planning-small-features to scope this feature...
        [Pre-dev workflow: PRD, TRD, plan]
Claude: I'm using ring:test-driven-development to implement...
        [RED-GREEN-REFACTOR cycle for each component]
Claude: I'm using ring:reviewing-code to validate...
        [9 defaults + conditional specialist parallel dispatch]
```

### Fixing a Bug

```
User: "The app crashes when clicking submit"
Claude: Investigating the crash:
        Phase 1: [Gathering evidence]
        Phase 2: [Pattern analysis]
        Phase 3: [Hypothesis testing]
        Phase 4: [Implementing fix with test]
```

### Planning a Project

```
User: "Plan an e-commerce platform"
Claude: I'll use the pre-dev workflow to plan this systematically...
        Gate 1: PRD Creation [Business requirements]
        Gate 2: Feature Map [Domain groupings]
        Gate 3: TRD Creation [Architecture patterns]
        ... [Through all 8 gates]
```

### Code Review (Parallel, 9 Defaults + Conditional Specialists)

```
User: "Review my authentication implementation"
Claude: Dispatching all 9 default reviewers plus triggered conditional specialists in parallel...
        [Launches ring:code-reviewer, ring:logic-reviewer, ring:security-reviewer,
         ring:test-reviewer, ring:nil-reviewer,
         ring:dead-code-reviewer, ring:perf-reviewer, ring:tenancy-reviewer,
         ring:commons-reviewer simultaneously]
        Conditional specialists trigger only when the diff touches their stack:
        lib-observability, lib-systemplane, or lib-streaming.

        Code reviewer: PASS. Clean architecture, good tests.
        Business reviewer: FAIL. Missing password reset flow (HIGH severity).
        Security reviewer: FAIL. JWT secret hardcoded (CRITICAL severity).
        Test reviewer: PASS. Good coverage, assertions well-structured.
        Nil-safety reviewer: PASS. No unguarded nil dereferences found.
        Performance reviewer: PASS. No hotspots or goroutine leaks found.
        Multi-tenant reviewer: PASS. No multi-tenant code in scope.
        lib-commons reviewer: PASS. Correct shared-library usage, no reinvented wheels detected.

        Aggregating issues by severity:
        - CRITICAL: JWT secret hardcoded in auth.ts:42
        - HIGH: Password reset flow missing from requirements

        Review report complete. No files changed by reviewers.
        Fixes require a separate implementation step, then a new review run.
```

**Key benefits:**

- **All reviewers run simultaneously** (not sequential)
- **Comprehensive** - Get all feedback at once, easier to prioritize
- **Report-only boundary** - Reviewers report findings; remediation is a separate step
- **Specialized lanes** - Each reviewer owns a clear domain to avoid duplicate slop

## 🏗️ Architecture

**Monorepo Marketplace** - Multiple specialized plugin collections:

```
ring/                                  # Monorepo root
├── .claude-plugin/
│   └── marketplace.json              # Multi-plugin marketplace config (4 active plugins)
├── default/                          # Core Ring plugin (ring-default)
│   ├── skills/                       # 23 core skills
│   │   ├── skill-name/
│   │   │   └── SKILL.md             # Skill definition with frontmatter
│   │   └── shared-patterns/         # Universal patterns (10 patterns)
│   ├── hooks/                       # Session initialization
│   │   ├── hooks.json              # Hook configuration
│   │   ├── session-start.sh        # Loads skills at startup
│   │   └── generate-skills-ref.py  # Auto-generates quick reference
│   ├── agents/                      # 2 planning/analysis agents
│   │   ├── review-slicer.md             # Review slicing for large PRs (`ring:review-slicer`)
│   │   └── codebase-explorer.md         # Deep architecture analysis (`ring:codebase-explorer`)
│   └── docs/                       # Documentation
├── dev-team/                      # Developer Agents plugin (ring-dev-team) - 35 skills, 24 agents
│   └── agents/                      # 24 specialized developer/reviewer agents
│       ├── backend-go.md       # Go backend specialist (`ring:backend-go`)
│       ├── backend-ts.md   # TypeScript/Node.js backend specialist (`ring:backend-ts`)
│       ├── bff-ts.md # BFF & React/Next.js specialist (`ring:bff-ts`)
│       ├── devops.md              # DevOps and infrastructure specialist (`ring:devops`)
│       ├── ui-designer.md             # Visual design specialist (`ring:ui-designer`)
│       ├── frontend.md             # Frontend engineer (`ring:frontend`)
│       ├── helm.md                 # Helm chart specialist (`ring:helm`)
│       ├── code-reviewer.md                 # Foundation review (`ring:code-reviewer`)
│       ├── logic-reviewer.md       # Correctness review (`ring:logic-reviewer`)
│       ├── security-reviewer.md             # Safety review (`ring:security-reviewer`)
│       ├── test-reviewer.md                 # Test quality review (`ring:test-reviewer`)
│       ├── nil-reviewer.md           # Nil/null safety review (`ring:nil-reviewer`)
│       ├── dead-code-reviewer.md            # Dead code analysis (`ring:dead-code-reviewer`)
│       ├── commons-reviewer.md          # lib-commons usage review (`ring:commons-reviewer`)
│       ├── obs-reviewer.md    # Conditional observability review (`ring:obs-reviewer`)
│       ├── systemplane-reviewer.md      # Conditional runtime-config review (`ring:systemplane-reviewer`)
│       ├── streaming-reviewer.md        # Conditional event producer review (`ring:streaming-reviewer`)
│       ├── tenancy-reviewer.md         # Multi-tenant usage review (`ring:tenancy-reviewer`)
│       ├── perf-reviewer.md          # Performance review (`ring:perf-reviewer`)
│       ├── prompt-reviewer.md       # Agent quality reviewer (`ring:prompt-reviewer`)
│       ├── qa.md                    # Backend QA specialist (`ring:qa`)
│       ├── qa-frontend.md           # Frontend QA specialist (`ring:qa-frontend`)
│       ├── sre.md                           # Observability and reliability specialist (`ring:sre`)
│       └── ui-engineer.md                   # UI component specialist (`ring:ui-engineer`)
├── pm-team/                    # Product Planning plugin (ring-pm-team)
│   └── skills/                      # 14 product planning skills
│       ├── writing-prds/          # PRD authoring
│       ├── writing-trds/          # TRD authoring
│       ├── designing-api-contracts/ # OpenAPI contract design
│       ├── designing-data-model/   # Stack-native schema design
│       └── pinning-dependency-versions/ # Dependency pinning
└── tw-team/                         # Technical Writing plugin (ring-tw-team)
    ├── skills/                      # 4 documentation skills
    ├── agents/                      # 3 technical writing agents
    └── hooks/                       # SessionStart hook
```

## 🤝 Contributing

### Adding a New Skill

**For core Ring skills:**

1. **Create the skill directory**

   ```bash
   mkdir default/skills/your-skill-name
   ```

2. **Write SKILL.md with frontmatter**

   ```yaml
   ---
   name: ring:your-skill-name
   description: Single paragraph (≤500 chars target, 1,536 cap). States WHAT the skill does, WHEN to invoke, and WHEN to skip.
   ---

   # Your Skill Name

   ## When to use
   - Specific condition that mandates this skill
   - Another trigger condition

   ## Skip when
   - When NOT to use → alternative skill
   - Another exclusion
   ```

   **Schema fields:**

   - **Required:** `name` (must use `ring:` prefix), `description`
   - **Optional:** `argument-hint`, `allowed-tools`, `model`, `disable-model-invocation`, `user-invocable`, `paths`
   - Trigger / skip / sequence / related content lives in body H2 sections (`## When to use`, `## Skip when`, `## Sequence`, `## Related`). See [docs/FRONTMATTER_SCHEMA.md](docs/FRONTMATTER_SCHEMA.md) for the canonical schema.

3. **Update documentation**

   - Skills auto-load via `default/hooks/generate-skills-ref.py`
   - Test with session start hook

4. **Submit PR**
   ```bash
   git checkout -b feat/your-skill-name
   git add default/skills/your-skill-name
   git commit -m "feat(skills): add your-skill-name for X"
   gh pr create
   ```

**For product/team-specific skills:**

1. **Create plugin structure**

   ```bash
   mkdir -p product-xyz/{skills,agents,hooks,lib}
   ```

2. **Register in marketplace**
   Edit `.claude-plugin/marketplace.json`:

   ```json
   {
     "name": "ring-product-xyz",
     "description": "Product XYZ specific skills",
     "version": "0.1.0",
     "source": "./product-xyz",
     "homepage": "https://github.com/lerianstudio/ring/tree/product-xyz"
   }
   ```

3. **Follow core plugin structure**
   - Use same layout as `default/`
   - Create `product-xyz/hooks/hooks.json` for initialization
   - Add skills to `product-xyz/skills/`

### Skill Quality Standards

- **Mandatory sections**: When to use, How to use, Anti-patterns
- **Include checklists**: TodoWrite-compatible task lists
- **Evidence-based**: Require verification before claims
- **Battle-tested**: Based on real-world experience
- **Clear triggers**: Unambiguous "when to use" conditions

## 📖 Documentation

- **Skills Quick Reference** - Auto-generated at session start from skill frontmatter
- [CLAUDE.md](CLAUDE.md) - Repository guide for Claude Code
- [MANUAL.md](MANUAL.md) - Quick reference for all skills, agents, and workflows
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture diagrams and component relationships
- [Installer](installer/) - Multi-platform installation and migration

## 🎯 Philosophy

Ring embodies these principles:

1. **Skills are mandatory, not optional** - If a skill applies, it MUST be used
2. **Evidence over assumptions** - Prove it works, don't assume
3. **Process prevents problems** - Following workflows prevents known failures
4. **Small steps, verified often** - Incremental progress with continuous validation
5. **Learn from failure** - Anti-patterns document what doesn't work

## 📊 Success Metrics

Teams using Ring report:

- 90% reduction in "works on my machine" issues
- 75% fewer bugs reaching production
- 60% faster debugging cycles
- 100% of code covered by tests (enforced by TDD)

## 🙏 Acknowledgments

Ring is built on decades of collective software engineering wisdom, incorporating patterns from:

- Extreme Programming (XP)
- Test-Driven Development (TDD)
- Domain-Driven Design (DDD)
- Agile methodologies
- DevOps practices

Special thanks to the Lerian Team for battle-testing these skills in production.

## 📄 License

MIT - See [LICENSE](LICENSE) file

## 🔗 Links

- [GitHub Repository](https://github.com/lerianstudio/ring)
- [Issue Tracker](https://github.com/lerianstudio/ring/issues)
- [Plugin Marketplace](https://claude.ai/marketplace/ring)

---

**Remember: If a skill applies to your task, you MUST use it. This is not optional.**
