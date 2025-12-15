# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ⛔ CRITICAL RULES (READ FIRST)

**These rules are NON-NEGOTIABLE. They MUST be followed for EVERY task.**

### 1. Agent Modification = Mandatory Verification
When creating or modifying ANY agent in `*/agents/*.md`:
- **MUST** verify agent has ALL required sections (see "Agent Modification Verification")
- **MUST** use STRONG language (MUST, REQUIRED, CANNOT, FORBIDDEN)
- **MUST** include anti-rationalization tables
- If ANY section is missing → Agent is INCOMPLETE

### 2. Agents are EXECUTORS, Not DECISION-MAKERS
- Agents **VERIFY**, they do NOT **ASSUME**
- Agents **REPORT** blockers, they do NOT **SOLVE** ambiguity autonomously
- Agents **FOLLOW** gates, they do NOT **SKIP** gates
- Agents **ASK** when uncertain, they do NOT **GUESS**

### 3. Anti-Patterns (NEVER Do These)
1. **NEVER skip using-ring** - It's mandatory, not optional
2. **NEVER run reviewers sequentially** - Always dispatch in parallel
3. **NEVER skip TDD's RED phase** - Test must fail before implementation
4. **NEVER ignore skill when applicable** - "Simple task" is not an excuse
5. **NEVER use panic() in Go** - Error handling required
6. **NEVER commit manually** - Always use `/commit` command
7. **NEVER assume compliance** - VERIFY with evidence

### 4. Fully Qualified Names (ALWAYS)
- ✅ `ring-default:code-reviewer`
- ✅ `ring-dev-team:backend-engineer-golang`
- ❌ `code-reviewer` (missing plugin prefix)
- ❌ `ring:code-reviewer` (ambiguous shorthand)

### 5. Standards-Agent Synchronization (ALWAYS CHECK)
When modifying standards files (`dev-team/docs/standards/*.md`):

**⛔ THREE-FILE UPDATE RULE:**
1. Edit `dev-team/docs/standards/{file}.md` - Add your `## Section Name`
2. Edit `dev-team/skills/shared-patterns/standards-coverage-table.md` - Add section to agent's index table
3. Edit `dev-team/agents/{agent}.md` - Verify agent references coverage table (NOT inline categories)
4. **All three files in same commit** - Never update one without the others

**⛔ AGENT INLINE CATEGORIES ARE FORBIDDEN:**
- ✅ Agent has "Sections to Check" referencing `standards-coverage-table.md`
- ❌ Agent has inline "Comparison Categories" table (FORBIDDEN - causes drift)

**Meta-sections (excluded from agent checks):**
- `## Checklist` - Self-verification section in standards files
- `## Standards Compliance` - Output format examples
- `## Standards Compliance Output Format` - Output templates

| Standards File | Agents That Use It |
|----------------|-------------------|
| `golang.md` | `backend-engineer-golang`, `qa-analyst` |
| `typescript.md` | `backend-engineer-typescript`, `frontend-bff-engineer-typescript`, `qa-analyst` |
| `frontend.md` | `frontend-engineer`, `frontend-designer` |
| `devops.md` | `devops-engineer` |
| `sre.md` | `sre` |

**Section Index Location:** `dev-team/skills/shared-patterns/standards-coverage-table.md` → "Agent → Standards Section Index"

**Quick Reference - Section Counts (MUST match standards-coverage-table.md):**

| Agent | Standards File | Section Count |
|-------|----------------|---------------|
| `backend-engineer-golang` | golang.md | See coverage table |
| `backend-engineer-typescript` | typescript.md | See coverage table |
| `frontend-bff-engineer-typescript` | typescript.md | See coverage table |
| `frontend-engineer` | frontend.md | See coverage table |
| `frontend-designer` | frontend.md | See coverage table |
| `devops-engineer` | devops.md | See coverage table |
| `sre` | sre.md | See coverage table |
| `qa-analyst` | golang.md OR typescript.md | See coverage table |

**⛔ If section counts in skills don't match this table → Update the skill.**

### 6. Agent Model Requirements (ALWAYS RESPECT)
When invoking agents via Task tool:
- **MUST** check agent's `model:` field in YAML frontmatter
- **MUST** pass matching `model` parameter to Task tool
- Agents with `model: opus` → **MUST** call with `model="opus"`
- Agents with `model: sonnet` → **MUST** call with `model="sonnet"`
- **NEVER** omit model parameter for specialized agents
- **NEVER** let system auto-select model for agents with model requirements

**Examples:**
- ✅ `Task(subagent_type="ring-default:code-reviewer", model="opus", ...)`
- ✅ `Task(subagent_type="ring-dev-team:backend-engineer-golang", model="opus", ...)`
- ❌ `Task(subagent_type="ring-default:code-reviewer", ...)` - Missing model parameter
- ❌ `Task(subagent_type="ring-default:code-reviewer", model="sonnet", ...)` - Wrong model

**Agent Self-Verification:**
All agents with `model:` field in frontmatter MUST include "Model Requirements" section that verifies they are running on the correct model and STOPS if not.

### 8. CLAUDE.md ↔ AGENTS.md Synchronization (AUTOMATIC via Symlink)

**⛔ AGENTS.md IS A SYMLINK TO CLAUDE.md - DO NOT BREAK:**
- `CLAUDE.md` - Primary project instructions (source of truth)
- `AGENTS.md` - Symlink to CLAUDE.md (automatically synchronized)

**Current Setup:** `AGENTS.md -> CLAUDE.md` (symlink)

**Why:** Both files serve as entry points for AI agents. CLAUDE.md is read by Claude Code, AGENTS.md is read by other AI systems. The symlink ensures they ALWAYS contain identical information.

**Rules:**
- **NEVER delete the AGENTS.md symlink**
- **NEVER replace AGENTS.md with a regular file**
- **ALWAYS edit CLAUDE.md** - changes automatically appear in AGENTS.md
- If symlink is broken → Restore with: `ln -sf CLAUDE.md AGENTS.md`

---

### 7. Content Duplication Prevention (ALWAYS CHECK)
Before adding ANY content to prompts, skills, agents, or documentation:
1. **SEARCH FIRST**: `grep -r "keyword" --include="*.md"` - Check if content already exists
2. **If content exists** → **REFERENCE it**, do NOT duplicate. Use: `See [file](path) for details`
3. **If adding new content** → Add to the canonical source per table below
4. **NEVER copy** content between files - always link to the single source of truth

| Information Type | Canonical Source (Single Source of Truth) |
|-----------------|-------------------------------------------|
| Critical rules | CLAUDE.md |
| Language patterns | docs/PROMPT_ENGINEERING.md |
| Agent schemas | docs/AGENT_DESIGN.md |
| Workflows | docs/WORKFLOWS.md |
| Plugin overview | README.md |
| Agent requirements | CLAUDE.md (Agent Modification section) |
| Shared skill patterns | `{plugin}/skills/shared-patterns/*.md` |

**Shared Patterns Rule (MANDATORY):**
When content is reused across multiple skills within a plugin:
1. **Extract to shared-patterns**: Create `{plugin}/skills/shared-patterns/{pattern-name}.md`
2. **Reference from skills**: Use `See [shared-patterns/{name}.md](../shared-patterns/{name}.md)`
3. **NEVER duplicate**: If the same table/section appears in 2+ skills → extract to shared-patterns

| Shared Pattern Type | Location |
|--------------------|----------|
| Pressure resistance scenarios | `{plugin}/skills/shared-patterns/pressure-resistance.md` |
| Anti-rationalization tables | `{plugin}/skills/shared-patterns/anti-rationalization.md` |
| Execution report format | `{plugin}/skills/shared-patterns/execution-report.md` |
| Standards coverage table | `{plugin}/skills/shared-patterns/standards-coverage-table.md` |

**Reference Pattern:**
- ✅ `See [docs/PROMPT_ENGINEERING.md](docs/PROMPT_ENGINEERING.md) for language patterns`
- ✅ `See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressures`
- ❌ Copying the language patterns table into another file
- ❌ Duplicating pressure resistance tables across multiple skills

---

## Quick Navigation

| Section | Content |
|---------|---------|
| [CRITICAL RULES](#-critical-rules-read-first) | Non-negotiable requirements |
| [CLAUDE.md ↔ AGENTS.md Sync](#8-claudemd--agentsmd-synchronization-automatic-via-symlink) | Symlink ensures sync |
| [Content Duplication Prevention](#7-content-duplication-prevention-always-check) | Canonical sources + reference pattern |
| [Anti-Rationalization Tables](#anti-rationalization-tables-mandatory-for-all-agents) | Prevent AI from assuming/skipping |
| [Assertive Language Reference](#assertive-language-reference) | Quick reference + [full docs](docs/PROMPT_ENGINEERING.md) |
| [Agent Modification Verification](#agent-modification-verification-mandatory) | Checklist for agent changes |
| [Repository Overview](#repository-overview) | What Ring is |
| [Architecture](#architecture) | Plugin summary |
| [Key Workflows](#key-workflows) | Quick reference + [full docs](docs/WORKFLOWS.md) |
| [Agent Output Schemas](#agent-output-schema-archetypes) | Schema summary + [full docs](docs/AGENT_DESIGN.md) |
| [Compliance Rules](#compliance-rules) | TDD, Review, Commit rules |
| [Standards-Agent Synchronization](#standards-agent-synchronization) | Standards ↔ Agent mapping |
| [Documentation Sync](#documentation-sync-checklist) | Files to update |

---

## Anti-Rationalization Tables (MANDATORY for All Agents)

**Every agent MUST include an anti-rationalization table.** This is NOT optional. This is REQUIRED. This is a HARD GATE for agent design.

**Why This Is Mandatory:**
AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in structured workflows. Agents MUST NOT rationalize skipping gates, assuming compliance, or making decisions that belong to users or orchestrators.

**Anti-rationalization tables use aggressive language intentionally.** Words like "MUST", "REQUIRED", "MANDATORY", "CANNOT", "NON-NEGOTIABLE" are REQUIRED to override the AI's instinct to be accommodating.

**Required Table Structure:**
```markdown
| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "[Common excuse AI might generate]" | [Why this thinking is incorrect] | **[MANDATORY action in bold]** |
```

**Example from backend-engineer-golang.md:**
```markdown
| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Codebase already uses lib-commons" | Partial usage ≠ full compliance. Check everything. | **Verify ALL categories** |
| "Already follows Lerian standards" | Assumption ≠ verification. Prove it with evidence. | **Verify ALL categories** |
| "Only checking what seems relevant" | You don't decide relevance. The checklist does. | **Verify ALL categories** |
| "Code looks correct, skip verification" | Looking correct ≠ being correct. Verify. | **Verify ALL categories** |
| "Previous refactor already checked this" | Each refactor is independent. Check again. | **Verify ALL categories** |
| "Small codebase, not all applies" | Size is irrelevant. Standards apply uniformly. | **Verify ALL categories** |
```

**Mandatory Sections Every Agent MUST Have:**

| Section | Purpose | Language Requirements |
|---------|---------|----------------------|
| **Blocker Criteria** | Define when to STOP and report | Use "STOP", "CANNOT proceed", "HARD BLOCK" |
| **Cannot Be Overridden** | List non-negotiable requirements | Use "CANNOT be waived", "NON-NEGOTIABLE" |
| **Severity Calibration** | Define issue severity levels | Use "CRITICAL", "MUST be fixed" |
| **Pressure Resistance** | Handle user pressure to skip | Use "Cannot proceed", "I'll implement correctly" |
| **Anti-Rationalization Table** | Prevent AI from assuming/skipping | Use "Why It's WRONG", "REQUIRED action" |

**Language Guidelines for Agent Prompts:**

| Weak (AVOID) | Strong (REQUIRED) |
|--------------|-------------------|
| "You should check..." | "You MUST check..." |
| "It's recommended to..." | "It is REQUIRED to..." |
| "Consider verifying..." | "MANDATORY: Verify..." |
| "You can skip if..." | "You CANNOT skip. No exceptions." |
| "Optionally include..." | "This section is NON-NEGOTIABLE." |
| "Try to follow..." | "HARD GATE: You will follow..." |

**If an agent lacks anti-rationalization tables → The agent is INCOMPLETE and MUST be updated.**

---

## Assertive Language Reference

**Quick reference for prompt engineering:**

| Category | Examples |
|----------|----------|
| Requirements | MUST, REQUIRED, MANDATORY, SHALL, ALWAYS |
| Prohibitions | CANNOT, NEVER, FORBIDDEN, MUST NOT, PROHIBITED |
| Enforcement | HARD GATE, NON-NEGOTIABLE, NO EXCEPTIONS, STOP AND REPORT |
| Anti-rationalization | "Assumption ≠ Verification", "You don't decide X" |

See [docs/PROMPT_ENGINEERING.md](docs/PROMPT_ENGINEERING.md) for complete language patterns and template examples.

---

## Agent Modification Verification (MANDATORY)

**HARD GATE: Before creating or modifying ANY agent file, Claude Code MUST verify compliance with this checklist.**

When you receive instructions to create or modify an agent in `*/agents/*.md`:

**Step 1: Read This Section**
Before ANY agent work, re-read this CLAUDE.md section to understand current requirements.

**Step 2: Verify Agent Has ALL Required Sections**

| Required Section | Pattern to Check | If Missing |
|------------------|------------------|------------|
| **Standards Loading (MANDATORY)** | `## Standards Loading` | MUST add with WebFetch instructions |
| **Blocker Criteria - STOP and Report** | `## Blocker Criteria` | MUST add with decision type table |
| **Cannot Be Overridden** | `### Cannot Be Overridden` | MUST add with non-negotiable requirements |
| **Severity Calibration** | `## Severity Calibration` | MUST add with CRITICAL/HIGH/MEDIUM/LOW table |
| **Pressure Resistance** | `## Pressure Resistance` | MUST add with "User Says / Your Response" table |
| **Anti-Rationalization Table** | `Rationalization.*Why It's WRONG` | MUST add in Standards Compliance section |
| **When Implementation is Not Needed** | `## When.*Not Needed` | MUST add with compliance signs |
| **Standards Compliance Report** | `## Standards Compliance Report` | MUST add for dev-team agents |

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
CHECKLIST (ALL must be YES):
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
[ ] If agent has model: field in frontmatter, does it have Model Requirements section?

If ANY checkbox is NO → Agent is INCOMPLETE. Add missing sections.
```

**This verification is NOT optional. This is a HARD GATE for all agent modifications.**

---

## Repository Overview

Ring is a comprehensive skills library and workflow system for AI agents that enforces proven software engineering practices through mandatory workflows, parallel code review, and systematic pre-development planning. Currently implemented as a Claude Code plugin marketplace with **9 active plugins**, the skills are agent-agnostic and reusable across different AI systems.

**Active Plugins:**
- **ring-default**: 22 core skills, 7 slash commands, 5 specialized agents
- **ring-dev-team**: 10 development skills, 5 slash commands, 7 developer agents (Backend Go, Backend TypeScript, DevOps, Frontend TypeScript, Frontend Designer, QA, SRE)
- **ring-pm-team**: 10 product planning skills, 3 research agents, 2 slash commands
- **ring-finops-team**: 6 regulatory skills, 2 FinOps agents
- **ring-finance-team**: 8 financial operations skills, 6 finance agents, 3 slash commands (Financial Analyst, Budget Planner, Financial Modeler, Treasury Specialist, Accounting Specialist, Metrics Analyst)
- **ring-ops-team**: 8 operations skills, 5 ops agents, 4 slash commands (Platform Engineer, Incident Responder, Cloud Cost Optimizer, Infrastructure Architect, Security Operations)
- **ring-pmm-team**: 8 product marketing skills, 6 PMM agents, 3 slash commands (Market Researcher, Positioning Strategist, Messaging Specialist, GTM Planner, Launch Coordinator, Pricing Analyst)
- **ring-pmo-team**: 8 PMO skills, 5 PMO agents, 3 slash commands (Portfolio Manager, Resource Planner, Governance Specialist, Risk Analyst, Executive Reporter)
- **ring-tw-team**: 7 technical writing skills, 3 slash commands, 3 documentation agents (Functional Writer, API Writer, Docs Reviewer)

**Note:** Plugin versions are managed in `.claude-plugin/marketplace.json`

**Total: 87 skills (22 + 10 + 10 + 6 + 8 + 8 + 8 + 8 + 7) across 9 plugins**
**Total: 42 agents (5 + 7 + 3 + 2 + 6 + 5 + 6 + 5 + 3) across 9 plugins**

The architecture uses markdown-based skill definitions with YAML frontmatter, auto-discovered at session start via hooks, and executed through Claude Code's native Skill/Task tools.

---

## Installation

See [README.md](README.md#installation) or [docs/platforms/](docs/platforms/) for detailed installation instructions.

**Quick install:** `curl -fsSL https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.sh | bash`

---

## Architecture

**Monorepo Structure** - 9 plugin collections:

| Plugin | Path | Contents |
|--------|------|----------|
| ring-default | `default/` | 22 skills, 5 agents, 7 commands |
| ring-dev-team | `dev-team/` | 10 skills, 7 agents, 5 commands |
| ring-pm-team | `pm-team/` | 10 skills, 3 agents, 2 commands |
| ring-finops-team | `finops-team/` | 6 skills, 2 agents |
| ring-finance-team | `finance-team/` | 8 skills, 6 agents, 3 commands |
| ring-ops-team | `ops-team/` | 8 skills, 5 agents, 4 commands |
| ring-pmm-team | `pmm-team/` | 8 skills, 6 agents, 3 commands |
| ring-pmo-team | `pmo-team/` | 8 skills, 5 agents, 3 commands |
| ring-tw-team | `tw-team/` | 7 skills, 3 agents, 3 commands |

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
Skill tool: "test-driven-development"  # Enforce TDD workflow
Skill tool: "systematic-debugging"     # Debug with 4-phase analysis
Skill tool: "using-ring"              # Load mandatory workflows

# Slash commands
/codereview          # Dispatch 3 parallel reviewers
/brainstorm          # Socratic design refinement
/pre-dev-feature     # <2 day features (4 gates)
/pre-dev-full        # ≥2 day features (9 gates)
/execute-plan        # Batch execution with checkpoints
/worktree            # Create isolated development branch

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
| Code review | `/codereview` dispatches 3 parallel reviewers |
| Pre-dev (small) | `/pre-dev-feature` → 4-gate workflow |
| Pre-dev (large) | `/pre-dev-full` → 9-gate workflow |

See [docs/WORKFLOWS.md](docs/WORKFLOWS.md) for detailed instructions.

---

## Important Patterns

### Code Organization
- **Skill Structure**: `default/skills/{name}/SKILL.md` with YAML frontmatter
- **Agent Output**: Required markdown sections per `default/agents/*.md:output_schema`
- **Hook Scripts**: Must output JSON with success/error fields
- **Shared Patterns**: Reference via `default/skills/shared-patterns/*.md`
- **Documentation**: Artifacts in `docs/pre-dev/{feature}/*.md`
- **Monorepo Layout**: Each plugin (`default/`, `team-*/`, `dev-team/`) is self-contained

### Naming Conventions
- Skills: `kebab-case` matching directory name
- Agents: `{domain}-reviewer.md` format
- Commands: `/ring-{plugin}:{action}` format (e.g., `/ring-default:brainstorm`, `/ring-pm-team:pre-dev-feature`)
- Hooks: `{event}-{purpose}.sh` format

#### Agent/Skill/Command Invocation
- **ALWAYS use fully qualified names**: `ring-{plugin}:{component}`
- **Examples:**
  - ✅ Correct: `ring-default:code-reviewer`
  - ✅ Correct: `ring-dev-team:backend-engineer-golang`
  - ❌ Wrong: `code-reviewer` (missing plugin prefix)
  - ❌ Wrong: `ring:code-reviewer` (ambiguous shorthand)
- **Rationale:** Prevents ambiguity in multi-plugin environments

---

## Agent Output Schema Archetypes

| Schema Type | Used By | Key Sections |
|-------------|---------|--------------|
| Implementation | * engineers | Summary, Implementation, Files Changed, Testing |
| Analysis | frontend-designer, finops-analyzer | Analysis, Findings, Recommendations |
| Reviewer | *-reviewer | VERDICT, Issues Found, What Was Done Well |
| Exploration | codebase-explorer | Exploration Summary, Key Findings, Architecture |
| Planning | write-plan | Goal, Architecture, Tech Stack, Tasks |

See [docs/AGENT_DESIGN.md](docs/AGENT_DESIGN.md) for complete schema definitions and Standards Compliance requirements.

---

## Compliance Rules

```bash
# TDD compliance (default/skills/test-driven-development/SKILL.md:638)
- Test file must exist before implementation
- Test must produce failure output (RED)
- Only then write implementation (GREEN)

# Review compliance (default/skills/requesting-code-review/SKILL.md:188)
- All 3 reviewers must pass
- Critical findings = immediate fix required
- Re-run all reviewers after fixes

# Skill compliance (default/skills/using-ring/SKILL.md:222)
- Check for applicable skills before ANY task
- If skill exists for task → MUST use it
- Announce non-obvious skill usage

# Commit compliance (default/commands/commit.md)
- ALWAYS use /commit for all commits
- Never write git commit commands manually
- Command enforces: conventional commits, trailers, no emoji signatures
- MUST use --trailer parameter for AI identification (NOT in message body)
- Format: git commit -m "msg" --trailer "Generated-by: Claude" --trailer "AI-Model: <model>"
- NEVER use HEREDOC to include trailers in message body
```

---

## Session Context

The system loads at SessionStart (from `default/` plugin):
1. `default/hooks/session-start.sh` - Loads skill quick reference via `generate-skills-ref.py`
2. `using-ring` skill - Injected as mandatory workflow
3. `default/hooks/claude-md-reminder.sh` - Reminds about CLAUDE.md on prompt submit

**Monorepo Context:**
- Repository: Monorepo marketplace with multiple plugin collections
- Active plugins: 9 (`ring-default`, `ring-dev-team`, `ring-pm-team`, `ring-finops-team`, `ring-finance-team`, `ring-ops-team`, `ring-pmm-team`, `ring-pmo-team`, `ring-tw-team`)
- Plugin versions: See `.claude-plugin/marketplace.json`
- Core plugin: `default/` (22 skills, 5 agents, 7 commands)
- Developer agents: `dev-team/` (10 skills, 7 agents, 5 commands)
- Product planning: `pm-team/` (10 skills, 3 agents, 2 commands)
- FinOps regulatory: `finops-team/` (6 skills, 2 agents)
- Finance operations: `finance-team/` (8 skills, 6 agents, 3 commands)
- Production operations: `ops-team/` (8 skills, 5 agents, 4 commands)
- Product marketing: `pmm-team/` (8 skills, 6 agents, 3 commands)
- Portfolio management: `pmo-team/` (8 skills, 5 agents, 3 commands)
- Technical writing: `tw-team/` (7 skills, 3 agents, 3 commands)
- Current git branch: `main`
- Remote: `github.com/LerianStudio/ring`

---

## Documentation Sync Checklist

**IMPORTANT:** When modifying agents, skills, commands, or hooks, check ALL these files for consistency:

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
├── finops-team/hooks/session-start.sh    # FinOps regulatory agents
├── finance-team/hooks/session-start.sh   # Finance operations agents
├── ops-team/hooks/session-start.sh       # Production operations agents
├── pmm-team/hooks/session-start.sh       # Product marketing agents
├── pmo-team/hooks/session-start.sh       # PMO agents
└── tw-team/hooks/session-start.sh        # Technical writing agents

Using-* Skills (plugin introductions):
├── default/skills/using-ring/SKILL.md             # Core workflow + agent list
├── dev-team/skills/using-dev-team/SKILL.md        # Developer agents guide
├── pm-team/skills/using-pm-team/SKILL.md          # Pre-dev workflow
├── finops-team/skills/using-finops-team/SKILL.md  # FinOps regulatory guide
├── finance-team/skills/using-finance-team/SKILL.md # Finance operations guide
├── ops-team/skills/using-ops-team/SKILL.md        # Production operations guide
├── pmm-team/skills/using-pmm-team/SKILL.md        # Product marketing guide
├── pmo-team/skills/using-pmo-team/SKILL.md        # PMO governance guide
└── tw-team/skills/using-tw-team/SKILL.md          # Technical writing guide
```

**Checklist when adding/modifying:**
- [ ] CLAUDE.md updated? → AGENTS.md auto-updates (it's a symlink)
- [ ] AGENTS.md symlink broken? → Restore with `ln -sf CLAUDE.md AGENTS.md`
- [ ] Agent added? Update hooks, using-* skills, MANUAL.md, README.md
- [ ] Skill added? Update CLAUDE.md architecture, hooks if plugin-specific
- [ ] Command added? Update MANUAL.md, README.md
- [ ] Plugin added? Create hooks/, using-* skill, update marketplace.json
- [ ] Names changed? Search repo for old names: `grep -r "old-name" --include="*.md" --include="*.sh"`

**Naming Convention Enforcement:**
- [ ] All agent invocations use `ring-{plugin}:agent-name` format
- [ ] All skill invocations use `ring-{plugin}:skill-name` format
- [ ] All command invocations use `/ring-{plugin}:command-name` format
- [ ] No `ring:` shorthand used (except in historical examples with context)
- [ ] No bare agent/skill names in invocation contexts

**Always use fully qualified names:** `ring-{plugin}:{component}` (e.g., `ring-default:code-reviewer`)
