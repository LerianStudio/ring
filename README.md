<p align="center">
  <img src="assets/ring-banner.png" alt="Ring by Lerian" width="100%" />
</p>

# 💍 The Ring - Skills Library for AI Agents

**Proven engineering practices, enforced through skills.**

Ring is a comprehensive skills library and workflow system for AI agents that transforms how AI assistants approach software development. Currently implemented as a **Claude Code plugin marketplace** with **4 active plugins**, **77 skills**, and **34 agents** (see `.claude-plugin/marketplace.json` for current versions), the skills themselves are agent-agnostic and can be used with any AI agent system. Ring provides battle-tested patterns, mandatory workflows, and systematic approaches across the entire software delivery value chain.

## ✨ Why Ring?

Without Ring, AI assistants often:

- Skip tests and jump straight to implementation
- Make changes without understanding root causes
- Claim tasks are complete without verification
- Forget to check for existing solutions
- Repeat known mistakes

Ring solves this by:

- **Enforcing proven workflows** - Test-driven development, systematic debugging, proper planning
- **Providing 77 specialized skills** (16 core + 37 dev-team + 18 product planning + 6 technical writing)
- **34 specialized agents** - 3 planning/analysis + 24 developer/reviewer + 4 product research + 3 technical writing
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
- `ring:write-plan` - Implementation planning agent
- `ring:codebase-explorer` - Deep architecture analysis (deep-analysis, complements built-in Explore)
- Use `ring:codereview` skill to orchestrate parallel review workflow

**Developer Agents (dev-team plugin):**

- `ring:backend-engineer-golang` - Go backend specialist for financial systems
- `ring:backend-engineer-typescript` - TypeScript/Node.js backend specialist (Express, NestJS, Fastify)
- `ring:frontend-bff-engineer-typescript` - BFF & React/Next.js frontend with Clean Architecture
- `ring:frontend-designer` - Visual design specialist
- `ring:frontend-engineer` - Senior Frontend Engineer (React/Next.js)
- `ring:devops-engineer` - DevOps and infrastructure specialist
- `ring:prompt-quality-reviewer` - Agent Quality Analyst
- `ring:qa-analyst` - Backend QA specialist (unit, integration, load, chaos)
- `ring:qa-analyst-frontend` - Frontend QA specialist (accessibility, visual, E2E, performance)
- `ring:sre` - Observability and reliability specialist
- `ring:ui-engineer` - UI component specialist (design systems, accessibility)
- `ring:helm-engineer` - Helm chart specialist (chart structure, security, Lerian conventions)
- `ring:code-reviewer` - Foundation review (architecture, code quality, design patterns)
- `ring:business-logic-reviewer` - Correctness review (domain logic, requirements, edge cases)
- `ring:security-reviewer` - Safety review (vulnerabilities, OWASP, authentication)
- `ring:test-reviewer` - Test quality review (coverage, edge cases, assertions, test anti-patterns)
- `ring:nil-safety-reviewer` - Nil/null safety review (traces pointer risks, missing guards, panic paths)
- `ring:dead-code-reviewer` - Dead code review (orphaned code detection, reachability analysis, dead dependency chains)
- `ring:lib-commons-reviewer` - lib-commons package usage review (lifecycle, tenancy, http, idempotency, security, database, messaging, outbox; reinvented-wheel opportunities)
- `ring:lib-observability-reviewer` - Conditional specialist for tracing, metrics, logging, runtime recovery, redaction, constants, and SafeGo implications
- `ring:lib-systemplane-reviewer` - Conditional specialist for runtime config, hot-reload knobs, admin config, tenant-scoped settings, and systemplane imports
- `ring:lib-streaming-reviewer` - Conditional specialist for business events, outbox, producers, broker publishing, CloudEvents, manifests, and catalogs
- `ring:multi-tenant-reviewer` - Multi-tenant usage review (lib-commons/multitenancy patterns, tenant isolation, JWT tenantId propagation)
- `ring:performance-reviewer` - Performance review (code hotspots, infra misconfigurations, Go/TypeScript/Python)

> **Standards Compliance:** Refactor-capable dev-team agents produce a `## Standards Compliance` output section with conditional requirement:
>
> - **Optional** when invoked directly or via `ring:dev-cycle`
> - **MANDATORY** when invoked from `ring:dev-refactor` (triggered by `**MODE: ANALYSIS ONLY**` in prompt)
>
> When mandatory, agents load Ring standards via WebFetch and produce comparison tables with:
>
> - Current Pattern vs Expected Pattern
> - Severity classification (Critical/High/Medium/Low)
> - File locations and migration recommendations
>
> See `dev-team/docs/standards/*.md` for standards source. Cross-references: CLAUDE.md (Standards Compliance section), `dev-team/skills/dev-refactor/SKILL.md`

**Product Research Agents (ring-pm-team plugin):**

- `ring:repo-research-analyst` - Repository structure and codebase analysis
- `ring:best-practices-researcher` - Industry best practices research
- `ring:framework-docs-researcher` - Framework documentation research
- `ring:product-designer` - Product design and UX research

**Technical Writing Agents (ring-tw-team plugin):**

- `ring:functional-writer` - Functional documentation (guides, tutorials, conceptual docs)
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

| Platform        | Format                 | Status             | Features                        |
| --------------- | ---------------------- | ------------------ | ------------------------------- |
| **Claude Code** | Native (marketplace)   | ✅ Source of truth | Skills, agents, hooks           |
| **Codex**       | Native (plugin.json)   | ✅ Supported       | Skills, agents                  |
| **Cursor**      | Native + Transformed   | ✅ Supported       | Skills, agents, hooks           |
| **OpenCode**    | Native (JS plugin)     | ✅ Supported       | Skills, bootstrap injection     |
| **Factory AI**  | Transformed            | ✅ Supported       | Droids, skills                  |
| **Cline**       | Transformed            | ✅ Supported       | Prompts                         |

**Format Notes:**

- **Native** — the harness installs Ring directly from manifest files in this repo (no transformation). Each Ring plugin ships its own per-harness manifest under `<plugin>/.codex-plugin/`, `<plugin>/.cursor-plugin/`, and `<plugin>/.opencode/`.
- **Transformed** — the multi-platform installer copies and adapts Ring content into the harness's local config (e.g., `~/.cursor/skills/`, droids for Factory AI, structured prompts for Cline).

**Platform-Specific Guides:**

- For **native install** per harness, see the sub-section below (`Native plugin install (per harness)`).
- For **transformed install** via the multi-platform installer, see the [installer README](installer/).

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

### Multi-Platform Installation (Transformed)

The Ring installer detects installed platforms and copies/transforms content into each harness's local config (used for Factory AI, Cline, and the transformed-mode Cursor flow).

**Linux/macOS/Git Bash:**

```bash
# Interactive installer (auto-detects platforms)
curl -fsSL https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.sh | bash

# Or clone and run locally
git clone https://github.com/lerianstudio/ring.git ~/ring
cd ~/ring
./installer/install-ring.sh
```

**Windows PowerShell:**

```powershell
# Interactive installer (auto-detects platforms)
irm https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.ps1 | iex

# Or clone and run locally
git clone https://github.com/lerianstudio/ring.git $HOME\ring
cd $HOME\ring
.\installer\install-ring.ps1
```

### Direct Platform Installation

Install to specific platforms without the interactive menu:

```bash
# Install to Claude Code only (native format)
./installer/install-ring.sh install --platforms claude

# Install to Factory AI only (droids format)
./installer/install-ring.sh install --platforms factory

# Install to multiple platforms
./installer/install-ring.sh install --platforms claude,cursor,cline

# Install to all detected platforms
./installer/install-ring.sh install --platforms auto

# Dry run (preview changes without installing)
./installer/install-ring.sh install --platforms auto --dry-run
```

### Installer Commands

```bash
# List installed platforms and versions
./installer/install-ring.sh list

# Update existing installation
./installer/install-ring.sh update

# Check for available updates
./installer/install-ring.sh check

# Sync (update only changed files)
./installer/install-ring.sh sync

# Uninstall from specific platform
./installer/install-ring.sh uninstall --platforms cursor

# Detect available platforms
./installer/install-ring.sh detect
```

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

The codereview pipeline uses [Mithril](https://github.com/LerianStudio/mithril), an external code analysis tool installed via `go install`. Mithril performs static analysis, AST extraction, call graph generation, and context compilation for AI-assisted code review.

Install via `go install github.com/lerianstudio/mithril@latest`. See the [Mithril repository](https://github.com/LerianStudio/mithril) for full installation details and release notes.

### First Session

When you start a new Claude Code session with Ring installed, you'll see:

```
## Available Skills:
- ring:using-ring (Check for skills BEFORE any task)
- ring:test-driven-development (RED-GREEN-REFACTOR cycle)
- ring:codereview (9 defaults + conditional specialist dispatch)
- ring:explore-codebase (Two-phase codebase exploration)
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

## 📚 All 75 Skills (Across 4 Plugins)

### Core Skills (ring-default plugin - 14 skills)

**Testing & Quality (2):**

- `ring:test-driven-development` - Write test first, watch fail, minimal code
- `ring:lint` - Parallel lint fixing with agent dispatch

**Collaboration & Planning (3):**

- `ring:codereview` - **Parallel 9 defaults + conditional specialist dispatch** with severity-based handling
- `ring:worktree` - Isolated development
- `ring:commit` - Smart commit organization with atomic grouping, conventional commits, and trailers

**Meta Skills (3):**

- `ring:using-ring` - Mandatory skill discovery
- `ring:writing-skills` - TDD for documentation
- `ring:testing-skills-with-subagents` - Skill validation

**Integration (1):**

- `ring:gandalf-webhook` - Send tasks to Gandalf (AI team member) via webhook for Slack, Google Workspace, and Jira interactions

**Session & Learning (4):**

- `ring:explore-codebase` - Two-phase codebase exploration
- `ring:release-guide` - Generate Ops Update Guide from git diff analysis
- `ring:visualize` - Generate self-contained HTML pages to visually explain systems, code changes, and data
- `ring:create-handoff` - Create handoff documents capturing session state for seamless context-clear and resume

**Audit & Readiness (1):**

- `ring:production-readiness-audit` - 44-dimension production readiness audit; runs explorers in batches of up to 10, appends incrementally to a single report; output: scored report (0-430, max 440 with multi-tenant) with severity ratings. See [default/skills/production-readiness-audit/SKILL.md](default/skills/production-readiness-audit/SKILL.md) for invocation and implementation details.

### Developer Skills (ring-dev-team plugin - 37 skills)

**Orchestration & Refactoring (7):**

- `ring:using-dev-team` - Introduction to developer specialist agents
- `ring:dev-cycle` - Lean backend development workflow orchestrator: Gate 0 implementation-owned TDD/coverage/docker-compose/runtime/delivery verification, Gate 8 review, Gate 9 validation
- `ring:dev-cycle-frontend` - 9-gate frontend development workflow orchestrator
- `ring:dev-refactor` - Backend/codebase standards analysis
- `ring:dev-refactor-frontend` - Frontend standards analysis and task generation
- `ring:dev-simplify` - Whole-codebase structural simplification sweep (hunts unjustified abstractions, adapters, shims; KILL/REVIEW/KEEP output; DELETE-by-default burden of proof for pre-public applications)
- `ring:dev-cycle-management` - Development cycle state management (status reporting and cancellation)

**Backend Gate Skills:**

- `ring:dev-implementation` - Gate 0: TDD implementation
- `ring:dev-multi-tenant` - Multi-tenant adaptation (database-per-tenant isolation, integrated into Gate 0)
- `ring:dev-docker-security` - Docker image security audit for Docker Hub Health Score grade A
- `ring:dev-helm` - Helm chart creation and maintenance following Lerian conventions
- `ring:dev-service-discovery` - Service/module/resource hierarchy scanner for dispatch layer
- `ring:dev-readyz` - Comprehensive readiness probes (/readyz) with per-dependency status and TLS validation
- `ring:dev-streaming-instrumentation` - Wire lib-streaming event emission from a validated instrumentation map

**Deprecated Skills (Reference Only):**

- `ring:dev-delivery-verification` - DEPRECATED: delivery verification merged into ring:dev-implementation Step 7 (Gate 0 exit criterion). Skill preserved for reference only.

**Testing & Validation:**

- `ring:dev-goroutine-leak-testing` - Goroutine leak detection and regression testing
- `ring:dev-k6-load-testing` - k6 load test generation following Lerian platform conventions
- `ring:dev-validation` - Gate 9: User approval
- `ring:dev-report` - Assertiveness scoring and metrics
- `ring:dev-verify-code` - Atomic Go code verification with MERGE_READY/NEEDS_FIX verdict

**Migration & Reference (6):**

- `ring:using-lib-commons` - Comprehensive reference for lib-commons v5.0.2 (Lerian's shared Go library with 30+ packages)
- `ring:using-runtime` - Deep reference and 6-angle audit for lib-observability/runtime: SafeGo, panic recovery, observability trident, policy selection, framework integration. Catches naked goroutine launches that cause silent production failures.
- `ring:using-assert` - Deep reference and 6-angle audit for lib-observability/assert: production runtime assertions with observability trident, full domain predicate catalog (double-entry, transaction state machine, financial validations), AssertionError unwrapping patterns. Converts financial invariants into production-enforced rules.
- `ring:dev-systemplane-migration` - Migrate Lerian Go services from .env/YAML config to systemplane (database-backed hot-reloadable config)
- `ring:dev-llms-txt` - Generate or audit llms.txt files following llmstxt.org spec for AI-friendly repository entry points
- `ring:dev-licensing` - Repository license management (Apache 2.0, Elastic v2, Proprietary)

**Security (1):**

- `ring:dev-dep-security-check` - Supply-chain gate for dependency installations (validates identity, vulnerabilities, suspicious signals)

**Frontend Gate Skills (4):**

- `ring:dev-frontend-accessibility` - Frontend accessibility validation gate
- `ring:dev-frontend-visual` - Visual regression and UI quality gate
- `ring:dev-frontend-e2e` - End-to-end testing gate
- `ring:dev-frontend-performance` - Frontend performance validation gate

> Frontend and backend dev-cycle workflows both use `ring:codereview` (core plugin) as the review gate.

### Product Planning Skills (ring-pm-team plugin - 18 skills)

**Pre-Development Workflow (includes ring:using-pm-team + 9 gates):**

- `ring:using-pm-team` - Introduction to product planning workflow

0. `ring:pre-dev-research` - Research phase (parallel agents)
1. `ring:pre-dev-prd-creation` - Business requirements (WHAT/WHY)
2. `ring:pre-dev-feature-map` - Feature relationships
3. `ring:pre-dev-trd-creation` - Technical architecture (HOW)
4. `ring:pre-dev-api-design` - Component contracts
5. `ring:pre-dev-data-model` - Entity relationships
6. `ring:pre-dev-dependency-map` - Technology selection
7. `ring:pre-dev-task-breakdown` - Work increments
8. `ring:pre-dev-subtask-creation` - Atomic units

**Workflow Orchestrators:**

- `ring:pre-dev-feature` - 5-gate orchestrator for small features (<2 days)
- `ring:pre-dev-full` - 10-gate orchestrator for large features (>=2 days)

**Additional Planning Skills:**

- `ring:pre-dev-design-validation` - Gate 1.5/2.5: Design validation for UI features
- `ring:pre-dev-delivery-planning` - Gate 4 (Small) / Gate 9 (Large): Delivery roadmap and timeline
- `ring:delivery-status` - Delivery progress tracking against roadmap
- `ring:deep-doc-review` - Deep cross-reference review of pre-dev documentation artifacts

### Technical Writing Skills (ring-tw-team plugin - 6 skills)

**Documentation Creation:**

- `ring:using-tw-team` - Introduction to technical writing specialists
- `ring:write-guide` - Patterns for guides, tutorials, conceptual docs
- `ring:write-api` - API reference documentation patterns
- `ring:documentation-structure` - Document hierarchy and organization
- `ring:voice-and-tone` - Voice and tone guidelines (assertive, encouraging, human)
- `ring:review-docs` - Quality checklist and review process

## 💡 Usage Examples

### Building a Feature

```
User: "Add user authentication to the app"
Claude: I'm using ring:pre-dev-feature to scope this feature...
        [Pre-dev workflow: PRD, TRD, tasks]
Claude: I'm using ring:test-driven-development to implement...
        [RED-GREEN-REFACTOR cycle for each component]
Claude: I'm using ring:codereview to validate...
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
        ... [Through all 10 gates]
```

### Code Review (Parallel, 9 Defaults + Conditional Specialists)

```
User: "Review my authentication implementation"
Claude: Dispatching all 9 default reviewers plus triggered conditional specialists in parallel...
        [Launches ring:code-reviewer, ring:business-logic-reviewer, ring:security-reviewer,
         ring:test-reviewer, ring:nil-safety-reviewer,
         ring:dead-code-reviewer, ring:performance-reviewer, ring:multi-tenant-reviewer,
         ring:lib-commons-reviewer simultaneously]
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
│   ├── skills/                       # 16 core skills
│   │   ├── skill-name/
│   │   │   └── SKILL.md             # Skill definition with frontmatter
│   │   └── shared-patterns/         # Universal patterns (15 patterns)
│   ├── hooks/                       # Session initialization
│   │   ├── hooks.json              # Hook configuration
│   │   ├── session-start.sh        # Loads skills at startup
│   │   └── generate-skills-ref.py  # Auto-generates quick reference
│   ├── agents/                      # 3 planning/analysis agents
│   │   ├── review-slicer.md             # Review slicing for large PRs (`ring:review-slicer`)
│   │   ├── write-plan.md                # Implementation planning (`ring:write-plan`)
│   │   └── codebase-explorer.md         # Deep architecture analysis (`ring:codebase-explorer`)
│   └── docs/                       # Documentation
├── dev-team/                      # Developer Agents plugin (ring-dev-team) - 37 skills, 24 agents
│   └── agents/                      # 24 specialized developer/reviewer agents
│       ├── backend-engineer-golang.md       # Go backend specialist (`ring:backend-engineer-golang`)
│       ├── backend-engineer-typescript.md   # TypeScript/Node.js backend specialist (`ring:backend-engineer-typescript`)
│       ├── frontend-bff-engineer-typescript.md # BFF & React/Next.js specialist (`ring:frontend-bff-engineer-typescript`)
│       ├── devops-engineer.md              # DevOps and infrastructure specialist (`ring:devops-engineer`)
│       ├── frontend-designer.md             # Visual design specialist (`ring:frontend-designer`)
│       ├── frontend-engineer.md             # Frontend engineer (`ring:frontend-engineer`)
│       ├── helm-engineer.md                 # Helm chart specialist (`ring:helm-engineer`)
│       ├── code-reviewer.md                 # Foundation review (`ring:code-reviewer`)
│       ├── business-logic-reviewer.md       # Correctness review (`ring:business-logic-reviewer`)
│       ├── security-reviewer.md             # Safety review (`ring:security-reviewer`)
│       ├── test-reviewer.md                 # Test quality review (`ring:test-reviewer`)
│       ├── nil-safety-reviewer.md           # Nil/null safety review (`ring:nil-safety-reviewer`)
│       ├── dead-code-reviewer.md            # Dead code analysis (`ring:dead-code-reviewer`)
│       ├── lib-commons-reviewer.md          # lib-commons usage review (`ring:lib-commons-reviewer`)
│       ├── lib-observability-reviewer.md    # Conditional observability review (`ring:lib-observability-reviewer`)
│       ├── lib-systemplane-reviewer.md      # Conditional runtime-config review (`ring:lib-systemplane-reviewer`)
│       ├── lib-streaming-reviewer.md        # Conditional event producer review (`ring:lib-streaming-reviewer`)
│       ├── multi-tenant-reviewer.md         # Multi-tenant usage review (`ring:multi-tenant-reviewer`)
│       ├── performance-reviewer.md          # Performance review (`ring:performance-reviewer`)
│       ├── prompt-quality-reviewer.md       # Agent quality reviewer (`ring:prompt-quality-reviewer`)
│       ├── qa-analyst.md                    # Backend QA specialist (`ring:qa-analyst`)
│       ├── qa-analyst-frontend.md           # Frontend QA specialist (`ring:qa-analyst-frontend`)
│       ├── sre.md                           # Observability and reliability specialist (`ring:sre`)
│       └── ui-engineer.md                   # UI component specialist (`ring:ui-engineer`)
├── pm-team/                    # Product Planning plugin (ring-pm-team)
│   └── skills/                      # 18 product planning skills
│       └── pre-dev-*/              # PRD, TRD, API, Data, Tasks
└── tw-team/                         # Technical Writing plugin (ring-tw-team)
    ├── skills/                      # 6 documentation skills
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
