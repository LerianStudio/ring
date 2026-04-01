# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ⛔ CRITICAL RULES (READ FIRST)

**These rules are NON-NEGOTIABLE. They MUST be followed for every task.**

### 1. Agent Modification = Mandatory Verification

When creating or modifying any agent in `*/agents/*.md`:

- **MUST** verify agent has all required sections (see "Agent Modification Verification")
- **MUST** use STRONG language (MUST, REQUIRED, CANNOT, FORBIDDEN)
- **MUST** include anti-rationalization tables
- If any section is missing → Agent is INCOMPLETE

### 2. Agents are EXECUTORS, Not DECISION-MAKERS

- Agents **VERIFY**, they DO NOT **ASSUME**
- Agents **REPORT** blockers, they DO NOT **SOLVE** ambiguity autonomously
- Agents **FOLLOW** gates, they DO NOT **SKIP** gates
- Agents **ASK** when uncertain, they DO NOT **GUESS**

### 3. Anti-Patterns (MUST NOT do these)

1. **MUST NOT skip ring:using-ring** - It's mandatory, not optional
2. **MUST NOT run reviewers sequentially** - dispatch in parallel
3. **MUST NOT skip TDD's RED phase** - Test must fail before implementation
4. **MUST NOT ignore skill when applicable** - "Simple task" is not an excuse
5. **ZERO PANIC POLICY** - `panic()`, `log.Fatal()`, and `Must*` helpers are FORBIDDEN everywhere (including bootstrap/init). Return `(T, error)` instead. Only exception: `regexp.MustCompile()` with compile-time constants.
6. **MUST NOT commit manually** - use `/ring:commit` command
7. **MUST NOT assume compliance** - VERIFY with evidence

### 4. Unified Ring Namespace (MANDATORY)

All Ring components use the unified `ring:` prefix. Plugin differentiation is handled internally.

- ✅ `ring:code-reviewer`
- ✅ `ring:backend-engineer-golang`
- ❌ `<missing ring prefix>` (FORBIDDEN: omitting the `ring:` prefix)
- ❌ `ring-default:ring:code-reviewer` (deprecated plugin-specific prefix)

### 5. Standards-Agent Synchronization (MUST CHECK)

When modifying standards files (`dev-team/docs/standards/*.md`):

**⛔ FOUR-FILE UPDATE RULE:**

1. Edit `dev-team/docs/standards/{file}.md` - Add your `## Section Name`
2. **Update TOC** - Add section to the `## Table of Contents` at the top of the same file
3. Edit `dev-team/skills/shared-patterns/standards-coverage-table.md` - Add section to agent's index table
4. Edit `dev-team/agents/{agent}.md` - Verify agent references coverage table (not inline categories)

**All files in same commit** - MUST NOT update one without the others.

**⛔ TOC MAINTENANCE RULE:**
Every standards file has a `## Table of Contents` section that MUST stay in sync:

- **Format:** `| # | [Section Name](#anchor-link) | Description |`
- **Meta-sections** (Checklist, Standards Compliance) are listed separately below the table
- **Anchor links** use lowercase with hyphens (e.g., `#error-handling-mandatory`)
- **Section count in TOC** MUST match section count in `standards-coverage-table.md`

**⛔ CHECKLIST: Adding/Removing a Section in Standards Files**

```
Before committing changes to dev-team/docs/standards/*.md:

[ ] 1. Did you add/remove a `## Section` in the standards file?
[ ] 2. Did you update the `## Table of Contents` in the SAME file?
    - Add/remove row: `| N | [Section Name](#anchor) | Description |`
    - Update numbering if needed
[ ] 3. Did you update `dev-team/skills/shared-patterns/standards-coverage-table.md`?
    - Find the agent's section index (e.g., "ring:backend-engineer-golang → golang.md")
    - Add/remove the section row
[ ] 4. Do the section counts match?
    - Count `## ` headers in standards file (excluding meta-sections)
    - Count rows in TOC
    - Count rows in standards-coverage-table.md for that agent
    - all THREE must be equal

If any checkbox is no → Fix before committing.
```

**⛔ AGENT INLINE CATEGORIES ARE FORBIDDEN:**

- ✅ Agent has "Sections to Check" referencing `standards-coverage-table.md`
- ❌ Agent has inline "Comparison Categories" table (FORBIDDEN - causes drift)

**Meta-sections (excluded from agent checks):**

- `## Checklist` - Self-verification section in standards files
- `## Standards Compliance` - Output format examples
- `## Standards Compliance Output Format` - Output templates

| Standards File  | Agents That Use It                                                                             |
| --------------- | ---------------------------------------------------------------------------------------------- |
| `golang.md`     | `ring:backend-engineer-golang`, `ring:qa-analyst`                                              |
| `typescript.md` | `ring:backend-engineer-typescript`, `ring:frontend-bff-engineer-typescript`, `ring:qa-analyst` |
| `frontend.md`   | `ring:frontend-engineer`, `ring:frontend-designer`                                             |
| `devops.md`     | `ring:devops-engineer`                                                                         |
| `sre.md`        | `ring:sre`                                                                                     |

**Section Index Location:** `dev-team/skills/shared-patterns/standards-coverage-table.md` → "Agent → Standards Section Index"

**Quick Reference - Section Counts:**

MUST match `dev-team/skills/shared-patterns/standards-coverage-table.md`. See the coverage table for current counts per agent.

| Agent                                   | Standards File             |
| --------------------------------------- | -------------------------- |
| `ring:backend-engineer-golang`          | golang.md                  |
| `ring:backend-engineer-typescript`      | typescript.md              |
| `ring:frontend-bff-engineer-typescript` | typescript.md              |
| `ring:frontend-engineer`                | frontend.md                |
| `ring:frontend-designer`                | frontend.md                |
| `ring:devops-engineer`                  | devops.md                  |
| `ring:sre`                              | sre.md                     |
| `ring:qa-analyst`                       | golang.md or typescript.md |

**⛔ If section counts in skills don't match the coverage table → Update the skill.**

### 6. CLAUDE.md ↔ AGENTS.md Synchronization (AUTOMATIC via Symlink)

**⛔ AGENTS.md IS A SYMLINK TO CLAUDE.md - MUST NOT break:**

- `CLAUDE.md` - Primary project instructions (source of truth)
- `AGENTS.md` - Symlink to CLAUDE.md (automatically synchronized)

**Current Setup:** `AGENTS.md -> CLAUDE.md` (symlink)

**Why:** Both files serve as entry points for AI agents. CLAUDE.md is read by Claude Code, AGENTS.md is read by other AI systems. The symlink ensures they always contain identical information.

**Rules:**

- **MUST NOT delete the AGENTS.md symlink**
- **MUST NOT replace AGENTS.md with a regular file**
- **MUST edit CLAUDE.md** - changes automatically appear in AGENTS.md
- If symlink is broken → Restore with: `ln -sf CLAUDE.md AGENTS.md`

---

### 7. Content Duplication Prevention (MUST CHECK)

Before adding any content to prompts, skills, agents, or documentation:

1. **SEARCH FIRST**: `grep -r "keyword" --include="*.md"` - Check if content already exists
2. **If content exists** → **REFERENCE it**, DO NOT duplicate. Use: `See [file](path) for details`
3. **If adding new content** → Add to the canonical source per table below
4. **MUST NOT copy** content between files - link to the single source of truth

| Information Type      | Canonical Source (Single Source of Truth) |
| --------------------- | ----------------------------------------- |
| Critical rules        | CLAUDE.md                                 |
| Language patterns     | docs/PROMPT_ENGINEERING.md                |
| Agent schemas         | docs/AGENT_DESIGN.md                      |
| Workflows             | docs/WORKFLOWS.md                         |
| Plugin overview       | README.md                                 |
| Agent requirements    | CLAUDE.md (Agent Modification section)    |
| Shared skill patterns | `{plugin}/skills/shared-patterns/*.md`    |

**Shared Patterns Rule (MANDATORY):**
When content is reused across multiple skills within a plugin:

1. **Extract to shared-patterns**: Create `{plugin}/skills/shared-patterns/{pattern-name}.md`
2. **Reference from skills**: Use `See [shared-patterns/{name}.md](../shared-patterns/{name}.md)`
3. **MUST NOT duplicate**: If the same table/section appears in 2+ skills → extract to shared-patterns

| Shared Pattern Type           | Location                                                      |
| ----------------------------- | ------------------------------------------------------------- |
| Pressure resistance scenarios | `{plugin}/skills/shared-patterns/pressure-resistance.md`      |
| Anti-rationalization tables   | `{plugin}/skills/shared-patterns/anti-rationalization.md`     |
| Execution report format       | `{plugin}/skills/shared-patterns/execution-report.md`         |
| Standards coverage table      | `{plugin}/skills/shared-patterns/standards-coverage-table.md` |

**Reference Pattern:**

- ✅ `See [docs/PROMPT_ENGINEERING.md](docs/PROMPT_ENGINEERING.md) for language patterns`
- ✅ `See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressures`
- ❌ Copying the language patterns table into another file
- ❌ Duplicating pressure resistance tables across multiple skills

---

## Quick Navigation

| Section                                                                                   | Content                                            |
| ----------------------------------------------------------------------------------------- | -------------------------------------------------- |
| [CRITICAL RULES](#-critical-rules-read-first)                                             | Non-negotiable requirements                        |
| [CLAUDE.md ↔ AGENTS.md Sync](#6-claudemd--agentsmd-synchronization-automatic-via-symlink) | Symlink ensures sync                               |
| [Content Duplication Prevention](#7-content-duplication-prevention-must-check)            | Canonical sources + reference pattern              |
| [Anti-Rationalization Tables](#anti-rationalization-tables-mandatory-for-all-agents)      | Prevent AI from assuming/skipping                  |
| [Lexical Salience Guidelines](#lexical-salience-guidelines-mandatory)                     | Selective emphasis for effective prompts           |
| [Agent Modification Verification](#agent-modification-verification-mandatory)             | Checklist for agent changes                        |
| [Repository Overview](#repository-overview)                                               | What Ring is                                       |
| [Architecture](#architecture)                                                             | Plugin summary                                     |
| [Key Workflows](#key-workflows)                                                           | Quick reference + [full docs](docs/WORKFLOWS.md)   |
| [Agent Output Schemas](#agent-output-schema-archetypes)                                   | Schema summary + [full docs](docs/AGENT_DESIGN.md) |
| [Compliance Rules](#compliance-rules)                                                     | TDD, Review, Commit rules                          |
| [Standards-Agent Synchronization](#5-standards-agent-synchronization-must-check)          | Standards ↔ Agent mapping                          |
| [Documentation Sync](#documentation-sync-checklist)                                       | Files to update                                    |

---

## Anti-Rationalization Tables (MANDATORY for All Agents)

**MANDATORY: Every agent must include an anti-rationalization table.** This is a HARD GATE for agent design.

**Why This Is Mandatory:**
AI models naturally attempt to be "helpful" by making autonomous decisions. This is dangerous in structured workflows. Agents MUST NOT rationalize skipping gates, assuming compliance, or making decisions that belong to users or orchestrators.

**Anti-rationalization tables use selective emphasis.** Place enforcement words (MUST, STOP, FORBIDDEN) at the beginning of instructions for maximum impact. See [Lexical Salience Guidelines](#lexical-salience-guidelines-mandatory).

**Required Table Structure:**

```markdown
| Rationalization                     | Why It's WRONG                   | Required Action                |
| ----------------------------------- | -------------------------------- | ------------------------------ |
| "[Common excuse AI might generate]" | [Why this thinking is incorrect] | **[MANDATORY action in bold]** |
```

**Example from ring:backend-engineer-golang.md:**

```markdown
| Rationalization                          | Why It's WRONG                                     | Required Action           |
| ---------------------------------------- | -------------------------------------------------- | ------------------------- |
| "Codebase already uses lib-commons"      | Partial usage ≠ full compliance. Check everything. | **Verify all categories** |
| "Already follows Lerian standards"       | Assumption ≠ verification. Prove it with evidence. | **Verify all categories** |
| "Only checking what seems relevant"      | You don't decide relevance. The checklist does.    | **Verify all categories** |
| "Code looks correct, skip verification"  | Looking correct ≠ being correct. Verify.           | **Verify all categories** |
| "Previous refactor already checked this" | Each refactor is independent. Check again.         | **Verify all categories** |
| "Small codebase, not all applies"        | Size is irrelevant. Standards apply uniformly.     | **Verify all categories** |
```

**Mandatory Sections Every Agent MUST Have:**

| Section                        | Purpose                           | Language Requirements                            |
| ------------------------------ | --------------------------------- | ------------------------------------------------ |
| **Blocker Criteria**           | Define when to STOP and report    | Use "STOP", "CANNOT proceed", "HARD BLOCK"       |
| **Cannot Be Overridden**       | List non-negotiable requirements  | Use "CANNOT be waived", "NON-NEGOTIABLE"         |
| **Severity Calibration**       | Define issue severity levels      | Use "CRITICAL", "MUST be fixed"                  |
| **Pressure Resistance**        | Handle user pressure to skip      | Use "Cannot proceed", "I'll implement correctly" |
| **Anti-Rationalization Table** | Prevent AI from assuming/skipping | Use "Why It's WRONG", "REQUIRED action"          |

**Language Guidelines for Agent Prompts:**

See [Lexical Salience Guidelines](#lexical-salience-guidelines-mandatory) for the complete weak→strong transformation rules and enforcement word positioning.

**HARD GATE: If an agent lacks anti-rationalization tables, it is incomplete and must be updated.**

---

## Lexical Salience Guidelines (MANDATORY)

**Effective prompts use selective emphasis.** When too many words are in CAPS, none stand out - the AI treats all as equal priority.

### Principle: Less is More

| Approach        | Effectiveness | Why                                                            |
| --------------- | ------------- | -------------------------------------------------------------- |
| Few CAPS words  | HIGH          | AI attention focuses on truly critical instructions            |
| Many CAPS words | LOW           | Salience dilution - everything emphasized = nothing emphasized |

### Words to Keep in Lowercase (Context Words)

These words provide context but DO NOT need emphasis:

| Word       | Use Instead                |
| ---------- | -------------------------- |
| ~~all~~    | all                        |
| ~~any~~    | any                        |
| ~~only~~   | only                       |
| ~~each~~   | each                       |
| ~~every~~  | every                      |
| ~~not~~    | not (except in "MUST not") |
| ~~no~~     | no                         |
| ~~and~~    | and                        |
| ~~or~~     | or                         |
| ~~if~~     | if                         |
| ~~else~~   | else                       |
| ~~never~~  | "MUST NOT"                 |
| ~~always~~ | "must"                     |

### Words to Keep in CAPS (Enforcement Words)

Use these sparingly and only at the **beginning** of instructions:

| Word      | Purpose             | Correct Position                       |
| --------- | ------------------- | -------------------------------------- |
| MUST      | Primary requirement | "MUST verify before proceeding"        |
| STOP      | Immediate action    | "STOP and report blocker"              |
| HARD GATE | Critical checkpoint | "HARD GATE: Cannot proceed without..." |
| FAIL/PASS | Verdict states      | "FAIL: Gate 4 incomplete"              |
| MANDATORY | Section marker      | "MANDATORY: Initialize first"          |
| CRITICAL  | Severity level      | "CRITICAL: Security issue"             |
| FORBIDDEN | Strong prohibition  | "FORBIDDEN: Direct code editing"       |
| REQUIRED  | Alternative to MUST | "REQUIRED: Load standards first"       |
| CANNOT    | Prohibition         | "CANNOT skip this gate"                |

### Positioning Rule: Beginning of Instructions

**Enforcement words MUST appear at the BEGINNING of instructions, not in the middle or end.**

| Position      | Effectiveness | Example                                        |
| ------------- | ------------- | ---------------------------------------------- |
| **Beginning** | HIGH          | "MUST verify all sections before proceeding"   |
| Middle        | LOW           | "You should verify all sections, this is MUST" |
| End           | LOW           | "Verify all sections before proceeding, MUST"  |

### Transformation Examples

| Before (Diluted)                   | After (Focused)                         |
| ---------------------------------- | --------------------------------------- |
| "You MUST check all sections"      | "MUST check all sections"               |
| "never skip any gate"              | "MUST not skip any gate"                |
| "This is MANDATORY for every task" | "MANDATORY: This applies to every task" |
| "always verify BEFORE proceeding"  | "MUST verify before proceeding"         |
| "Check if this CONDITION is met"   | "MUST check if this condition is met"   |

### Sentence Structure Pattern

```
[ENFORCEMENT WORD]: [Action/Instruction] [Context]

Examples:
- MUST dispatch agent before proceeding to next gate
- STOP and report if PROJECT_RULES.md is missing
- HARD GATE: All 7 reviewers must pass before Gate 5
- FORBIDDEN: Reading source code directly as orchestrator
```

### Strategic Spacing (Attention Reset)

**Spacing matters for AI attention.** When multiple critical rules appear in sequence, add blank lines between sections to allow "attention reset".

**→ See [docs/PROMPT_ENGINEERING.md](docs/PROMPT_ENGINEERING.md#strategic-spacing-attention-reset) for:**

- Effectiveness comparison table
- Good example with spaced sections
- Anti-pattern example (dense text)

### Semantic Block Tags (Recognition Patterns)

**Use XML-like tags to create recognizable blocks for critical instructions.** Tags create semantic boundaries that AI models recognize as structured blocks requiring special attention.

**→ See [docs/PROMPT_ENGINEERING.md](docs/PROMPT_ENGINEERING.md#semantic-block-tags-recognition-patterns) for:**

- Complete tag reference table (9 tags)
- Example usage with all tag types
- Why tags work explanation

---

## Agent Modification Verification (MANDATORY)

**HARD GATE: Before creating or modifying any agent file, Claude Code MUST verify compliance with this checklist.**

When you receive instructions to create or modify an agent in `*/agents/*.md`:

**Step 1: Read This Section**
Before any agent work, re-read this CLAUDE.md section to understand current requirements.

**Step 2: Verify Agent Has all Required Sections**

| Required Section                       | Pattern to Check                  | If Missing                                      |
| -------------------------------------- | --------------------------------- | ----------------------------------------------- |
| **Standards Loading (MANDATORY)**      | `## Standards Loading`            | MUST add with WebFetch instructions             |
| **Blocker Criteria - STOP and Report** | `## Blocker Criteria`             | MUST add with decision type table               |
| **Cannot Be Overridden**               | `### Cannot Be Overridden`        | MUST add with non-negotiable requirements       |
| **Severity Calibration**               | `## Severity Calibration`         | MUST add with CRITICAL/HIGH/MEDIUM/LOW table    |
| **Pressure Resistance**                | `## Pressure Resistance`          | MUST add with "User Says / Your Response" table |
| **Anti-Rationalization Table**         | `Rationalization.*Why It's WRONG` | MUST add in Standards Compliance section        |
| **When Implementation is Not Needed**  | `## When.*Not Needed`             | MUST add with compliance signs                  |
| **Standards Compliance Report**        | `## Standards Compliance Report`  | MUST add for dev-team agents                    |

**Step 3: Verify Language Strength**

Check agent uses STRONG language, not weak:

```text
SCAN for weak phrases → REPLACE with strong:
- "should" → "MUST"
- "recommended" → "REQUIRED"
- "consider" → "MANDATORY"
- "can skip" → "CANNOT skip"
- "optional" → "NON-NEGOTIABLE"
- "try to" → "HARD GATE:"
```

**Step 4: Before Completing Agent Modification**

```text
CHECKLIST (all must be YES):
[ ] Does agent have Standards Loading section?
[ ] Does agent have Blocker Criteria table?
[ ] Does agent have Cannot Be Overridden table?
[ ] Does agent have Severity Calibration table?
[ ] Does agent have Pressure Resistance table?
[ ] Does agent have Anti-Rationalization table?
[ ] Does agent have When Not Needed section?
[ ] Does agent use STRONG language (MUST, REQUIRED, CANNOT)?
[ ] Does agent define when to STOP and report?
[ ] Does agent define non-negotiable requirements?

If any checkbox is no → Agent is INCOMPLETE. Add missing sections.
```

**This verification is not optional. This is a HARD GATE for all agent modifications.**

---

## Repository Overview

Ring is a comprehensive skills library and workflow system for AI agents that enforces proven software engineering practices through mandatory workflows, parallel code review, and systematic pre-development planning. Currently implemented as a Claude Code plugin marketplace with **6 active plugins**, the skills are agent-agnostic and reusable across different AI systems.

**Active Plugins:**

- **ring-default**: 22 core skills, 14 slash commands, 10 specialized agents
- **ring-dev-team**: 29 development skills, 9 slash commands, 12 developer agents (Backend Go, Backend TypeScript, DevOps, Frontend TypeScript, Frontend Designer, Frontend Engineer, Helm, QA Backend, QA Frontend, SRE, UI Engineer, Prompt Quality Reviewer)
- **ring-pm-team**: 15 product management skills, 4 research agents, 3 slash commands (includes delivery planning + status tracking + Product Designer)
- **ring-pmo-team**: 9 PMO skills, 4 slash commands, 6 PMO agents (Portfolio Manager, Resource Planner, Risk Analyst, Governance Specialist, Executive Reporter, Delivery Reporter)
- **ring-finops-team**: 7 regulatory skills, 3 FinOps agents (Analyzer, Automation, Infrastructure Cost Estimator)
- **ring-tw-team**: 7 technical writing skills, 3 slash commands, 3 documentation agents (Functional Writer, API Writer, Docs Reviewer)

**Note:** Plugin versions are managed in `.claude-plugin/marketplace.json`

**Total: 89 skills (22 + 29 + 15 + 9 + 7 + 7) across 6 plugins**
**Total: 38 agents (10 + 12 + 4 + 6 + 3 + 3) across 6 plugins**
**Total: 33 commands (14 + 9 + 3 + 4 + 0 + 3) across 6 plugins**

The architecture uses markdown-based skill definitions with YAML frontmatter, auto-discovered at session start via hooks, and executed through Claude Code's native Skill/Task tools.

---

## Installation

See [README.md](README.md#installation) for detailed installation instructions.

**Quick install:** `curl -fsSL https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.sh | bash`

---

## Architecture

**Monorepo Structure** - 6 plugin collections:

| Plugin           | Path           | Contents                         |
| ---------------- | -------------- | -------------------------------- |
| ring-default     | `default/`     | 22 skills, 10 agents, 14 commands |
| ring-dev-team    | `dev-team/`    | 29 skills, 12 agents, 9 commands |
| ring-pm-team     | `pm-team/`     | 15 skills, 4 agents, 3 commands  |
| ring-pmo-team    | `pmo-team/`    | 9 skills, 6 agents, 4 commands   |
| ring-finops-team | `finops-team/` | 7 skills, 3 agents               |
| ring-tw-team     | `tw-team/`     | 7 skills, 3 agents, 3 commands   |

Each plugin contains: `skills/`, `agents/`, `commands/`, `hooks/`

See [README.md](README.md#architecture) for full directory structure.

---

## Common Commands

```bash
# Git operations (no build system - this is a plugin)
git status                          # Check current branch (main)
git log --oneline -20              # Recent commits show hook development
git worktree list                  # Check isolated development branches

# Skill invocation (via Claude Code)
Skill tool: "ring:test-driven-development"  # Enforce TDD workflow
Skill tool: "ring:systematic-debugging"     # Debug with 4-phase analysis
Skill tool: "ring:using-ring"               # Load mandatory workflows

# Slash commands
/ring:codereview          # Dispatch 7 parallel reviewers
/ring:brainstorm          # Socratic design refinement
/ring:pre-dev-feature     # <2 day features (5 gates)
/ring:pre-dev-full        # ≥2 day features (10 gates)
/ring:dev-cycle           # 10-gate development cycle + post-cycle multi-tenant
/ring:execute-plan        # Batch execution with checkpoints
/ring:worktree            # Create isolated development branch

# Hook validation (from default plugin)
bash default/hooks/session-start.sh      # Test skill loading
python default/hooks/generate-skills-ref.py # Generate skill overview
```

---

## Key Workflows

| Workflow | Quick Reference |
|----------|-----------------|
| Add skill | `mkdir default/skills/name/` → create `SKILL.md` with frontmatter |
| Add agent | Create `*/agents/name.md` → verify required sections per [Agent Design](docs/AGENT_DESIGN.md) |
| Modify hooks | Edit `*/hooks/hooks.json` → test with `bash */hooks/session-start.sh` |
| Code review | `/ring:codereview` dispatches 7 parallel reviewers |
| Pre-dev (small) | `/ring:pre-dev-feature` → 5-gate workflow |
| Pre-dev (large) | `/ring:pre-dev-full` → 10-gate workflow |
| Dev cycle - backend (10 gates) | `/ring:dev-cycle [tasks-file]` → implementation→delivery-verification→devops→SRE→unit-testing→fuzz-testing→property-testing→integration-testing→chaos-testing→review→validation (see [dev-team/skills/dev-cycle/SKILL.md](dev-team/skills/dev-cycle/SKILL.md)) |
| Dev cycle - frontend (9 gates) | `/ring:dev-cycle-frontend [tasks-file]` → implementation→devops→accessibility→unit-testing→visual-testing→e2e-testing→performance→review→validation (see [dev-team/skills/dev-cycle-frontend/SKILL.md](dev-team/skills/dev-cycle-frontend/SKILL.md)) |
| Refactor - frontend | `/ring:dev-refactor-frontend` → dispatches 5-7 frontend agents in ANALYSIS mode → generates findings → tasks → handoff to `/ring:dev-cycle-frontend` |

See [docs/WORKFLOWS.md](docs/WORKFLOWS.md) for detailed instructions.

---

## Important Patterns

### Code Organization

- **Skill Structure**: `default/skills/{name}/SKILL.md` with YAML frontmatter
- **Agent Output**: Required markdown sections per `default/agents/*.md:output_schema`
- **Hook Scripts**: Must output JSON with success/error fields
- **Shared Patterns**: Reference via `default/skills/shared-patterns/*.md`
- **Documentation**: Artifacts in `docs/pre-dev/{feature}/*.md`
- **Monorepo Layout**: Each plugin (`default/`, `{name}-team/`) is self-contained

### Naming Conventions

- Skills: `kebab-case` matching directory name
- Agents: `ring:{domain}.md` or `ring:{domain}-reviewer.md` format
- Commands: `/{action}` format (e.g., `/ring:brainstorm`, `/ring:pre-dev-feature`)
- Hooks: `{event}-{purpose}.sh` format

#### Agent/Skill/Command Invocation

See [Unified Ring Namespace](#4-unified-ring-namespace-mandatory) above for invocation format. MUST use `ring:{component}` (e.g., `ring:code-reviewer`, `ring:backend-engineer-golang`).

---

## Agent Output Schema Archetypes

| Schema Type    | Used By                | Key Sections                                    |
| -------------- | ---------------------- | ----------------------------------------------- |
| Implementation | \* engineers           | Summary, Implementation, Files Changed, Testing |
| Analysis       | ring:frontend-designer | Analysis, Findings, Recommendations             |
| Reviewer       | \*-reviewer            | VERDICT, Issues Found, What Was Done Well       |
| Exploration    | ring:codebase-explorer | Exploration Summary, Key Findings, Architecture |
| Planning       | ring:write-plan        | Goal, Architecture, Tech Stack, Tasks           |

See [docs/AGENT_DESIGN.md](docs/AGENT_DESIGN.md) for complete schema definitions and Standards Compliance requirements.

---

## Compliance Rules

```text
# TDD compliance (default/skills/test-driven-development/SKILL.md)
- Test file must exist before implementation
- Test must produce failure output (RED)
- Only then write implementation (GREEN)

# Review compliance (default/skills/requesting-code-review/SKILL.md)
- All 7 reviewers must pass
- Critical findings = immediate fix required
- Re-run all 7 reviewers after fixes

# Skill compliance (default/skills/using-ring/SKILL.md)
- Check for applicable skills before any task
- If skill exists for task → MUST use it
- Announce non-obvious skill usage

# Commit compliance (default/commands/commit.md)
- MUST use /ring:commit for all commits
- MUST NOT write git commit commands manually
- Command enforces: conventional commits, trailers, no emoji signatures
- MUST use --trailer parameter for AI identification (not in message body)
- Format: git commit -m "msg" --trailer "Generated-by: Claude" --trailer "AI-Model: <model>"
- MUST NOT use HEREDOC to include trailers in message body
```

---

## Session Context

The system loads at SessionStart (from `default/` plugin):

1. `default/hooks/session-start.sh` - Loads skill quick reference via `generate-skills-ref.py`
2. `ring:using-ring` skill - Injected as mandatory workflow
3. `default/hooks/claude-md-reminder.sh` - Reminds about CLAUDE.md on prompt submit

**Monorepo Context:**

- Repository: Monorepo marketplace with multiple plugin collections
- Active plugins: 6 (`ring-default`, `ring-dev-team`, `ring-pm-team`, `ring-pmo-team`, `ring-finops-team`, `ring-tw-team`)
- Plugin versions: See `.claude-plugin/marketplace.json`
- Core plugin: `default/` (22 skills, 10 agents, 14 commands)
- Developer agents: `dev-team/` (29 skills, 12 agents, 9 commands)
- Product planning: `pm-team/` (15 skills, 4 agents, 3 commands)
- PMO specialists: `pmo-team/` (9 skills, 6 agents, 4 commands)
- FinOps regulatory: `finops-team/` (7 skills, 3 agents)
- Technical writing: `tw-team/` (7 skills, 3 agents, 3 commands)
- Current git branch: `main`
- Remote: `github.com/LerianStudio/ring`

---

## Documentation Sync Checklist

**IMPORTANT:** When modifying agents, skills, commands, or hooks, check all these files for consistency:

```
Root Documentation:
├── CLAUDE.md              # Project instructions (this file)
├── MANUAL.md              # Team quick reference guide
├── README.md              # Public documentation
└── ARCHITECTURE.md        # Architecture diagrams

Reference Documentation:
├── docs/PROMPT_ENGINEERING.md  # Assertive language patterns
├── docs/AGENT_DESIGN.md        # Output schemas, standards compliance
└── docs/WORKFLOWS.md           # Detailed workflow instructions

Plugin Hooks (inject context at session start):
├── default/hooks/session-start.sh        # Skills reference
├── dev-team/hooks/session-start.sh       # Developer agents
├── pm-team/hooks/session-start.sh        # Pre-dev skills
├── pmo-team/hooks/session-start.sh       # PMO specialist agents
├── finops-team/hooks/session-start.sh    # FinOps regulatory agents
└── tw-team/hooks/session-start.sh        # Technical writing agents

Using-* Skills (plugin introductions):
├── default/skills/using-ring/SKILL.md             # Core workflow + agent list
├── dev-team/skills/using-dev-team/SKILL.md        # Developer agents guide
├── pm-team/skills/using-pm-team/SKILL.md          # Pre-dev workflow
├── pmo-team/skills/using-pmo-team/SKILL.md        # PMO portfolio guide
├── finops-team/skills/using-finops-team/SKILL.md  # FinOps regulatory guide
└── tw-team/skills/using-tw-team/SKILL.md          # Technical writing guide
```

**Checklist when adding/modifying:**

- [ ] CLAUDE.md updated? → AGENTS.md auto-updates (it's a symlink)
- [ ] AGENTS.md symlink broken? → Restore with `ln -sf CLAUDE.md AGENTS.md`
- [ ] Agent added? Update hooks, using-\* skills, MANUAL.md, README.md
- [ ] Skill added? Update CLAUDE.md architecture, hooks if plugin-specific
- [ ] Command added? Update MANUAL.md, README.md
- [ ] Plugin added? Create hooks/, using-\* skill, update marketplace.json
- [ ] Names changed? Search repo for old names: `grep -r "old-name" --include="*.md" --include="*.sh"`

**Naming Convention Enforcement:**

- [ ] All agent invocations use `ring:agent-name` format
- [ ] All skill invocations use `ring:skill-name` format
- [ ] All command invocations use `/{command-name}` format
- [ ] No bare agent/skill names in invocation contexts (must have ring: prefix)
- [ ] No deprecated `ring-{plugin}:` format used

**MUST use unified namespace:** `ring:{component}` (e.g., `ring:code-reviewer`)
