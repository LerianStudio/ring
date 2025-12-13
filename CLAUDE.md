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
6. **NEVER commit manually** - Always use `/ring-default:commit` command
7. **NEVER assume compliance** - VERIFY with evidence

### 4. Fully Qualified Names (ALWAYS)
- ✅ `ring-default:code-reviewer`
- ✅ `ring-dev-team:backend-engineer-golang`
- ❌ `ring:code-reviewer` (WRONG)
- ❌ `backend-engineer-golang` (WRONG)

### 5. Content Duplication Prevention (ALWAYS CHECK)
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
| Anti-rationalization tables (skills) | `{plugin}/skills/shared-patterns/skills-anti-rationalization.md` |
| Anti-rationalization tables (agents) | `{plugin}/skills/shared-patterns/agent-anti-rationalization.md` |
| Execution report format | `{plugin}/skills/shared-patterns/execution-report.md` |

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
| [Content Duplication Prevention](#5-content-duplication-prevention-always-check) | Canonical sources + reference pattern |
| [Anti-Rationalization Tables](#anti-rationalization-tables-mandatory-for-all-agents) | Prevent AI from assuming/skipping |
| [Assertive Language Reference](#assertive-language-reference) | Quick reference + [full docs](docs/PROMPT_ENGINEERING.md) |
| [Agent Modification Verification](#agent-modification-verification-mandatory) | Checklist for agent changes |
| [Repository Overview](#repository-overview) | What Ring is |
| [Architecture](#architecture) | Plugin summary |
| [Key Workflows](#key-workflows) | Quick reference + [full docs](docs/WORKFLOWS.md) |
| [Agent Output Schemas](#agent-output-schema-archetypes) | Schema summary + [full docs](docs/AGENT_DESIGN.md) |
| [Compliance Rules](#compliance-rules) | TDD, Review, Commit rules |
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
[ ] Does agent use STRONG language (MUST, REQUIRED, CANNOT)?
[ ] Does agent define when to STOP and report?
[ ] Does agent define non-negotiable requirements?

If ANY checkbox is NO → Agent is INCOMPLETE. Add missing sections.
```

**This verification is NOT optional. This is a HARD GATE for all agent modifications.**

---

## Repository Overview

Ring is a comprehensive skills library and workflow system for AI agents that enforces proven software engineering practices through mandatory workflows, parallel code review, and systematic pre-development planning. Currently implemented as a Claude Code plugin marketplace with **5 active plugins**, the skills are agent-agnostic and reusable across different AI systems.

**Active Plugins:**
- **ring-default**: 22 core skills, 7 slash commands, 5 specialized agents
- **ring-dev-team**: 10 development skills, 5 slash commands, 7 developer agents (Backend Go, Backend TypeScript, DevOps, Frontend TypeScript, Frontend Designer, QA, SRE)
- **ring-finops-team**: 6 regulatory skills, 2 FinOps agents
- **ring-pm-team**: 10 product planning skills, 3 research agents, 2 slash commands
- **ring-tw-team**: 7 technical writing skills, 3 slash commands, 3 documentation agents (Functional Writer, API Writer, Docs Reviewer)

**Note:** Plugin versions are managed in `.claude-plugin/marketplace.json`

**Total: 55 skills (22 + 10 + 6 + 10 + 7) across 5 plugins**

The architecture uses markdown-based skill definitions with YAML frontmatter, auto-discovered at session start via hooks, and executed through Claude Code's native Skill/Task tools.

---

## Installation

See [README.md](README.md#installation) or [docs/platforms/](docs/platforms/) for detailed installation instructions.

**Quick install:** `curl -fsSL https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.sh | bash`

---

## Architecture

**Monorepo Structure** - 5 plugin collections:

| Plugin | Path | Contents |
|--------|------|----------|
| ring-default | `default/` | 22 skills, 5 agents, 7 commands |
| ring-dev-team | `dev-team/` | 10 skills, 7 agents, 5 commands |
| ring-finops-team | `finops-team/` | 6 skills, 2 agents |
| ring-pm-team | `pm-team/` | 10 skills, 3 agents, 2 commands |
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
Skill tool: "ring-default:test-driven-development"  # Enforce TDD workflow
Skill tool: "ring-default:systematic-debugging"     # Debug with 4-phase analysis
Skill tool: "ring-default:using-ring"              # Load mandatory workflows

# Slash commands
/ring-default:codereview          # Dispatch 3 parallel reviewers
/ring-default:brainstorm          # Socratic design refinement
/ring-pm-team:pre-dev-feature     # <2 day features (4 gates)
/ring-pm-team:pre-dev-full        # ≥2 day features (9 gates)
/ring-default:execute-plan        # Batch execution with checkpoints
/ring-default:worktree            # Create isolated development branch

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
| Code review | `/ring-default:codereview` dispatches 3 parallel reviewers |
| Pre-dev (small) | `/ring-pm-team:pre-dev-feature` → 4-gate workflow |
| Pre-dev (large) | `/ring-pm-team:pre-dev-full` → 9-gate workflow |

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
  - ❌ Wrong: `ring:code-reviewer` (ambiguous shorthand)
  - ❌ Wrong: `backend-engineer-golang` (missing plugin prefix)
- **Rationale:** Prevents ambiguity in multi-plugin environments

---

## Agent Output Schema Archetypes

| Schema Type | Used By | Key Sections |
|-------------|---------|--------------|
| Implementation | ring-dev-team:* engineers | Summary, Implementation, Files Changed, Testing |
| Analysis | frontend-designer, finops-analyzer | Analysis, Findings, Recommendations |
| Reviewer | ring-default:*-reviewer | VERDICT, Issues Found, What Was Done Well |
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
- ALWAYS use /ring-default:commit for all commits
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
- Active plugins: 5 (`ring-default`, `ring-dev-team`, `ring-finops-team`, `ring-pm-team`, `ring-tw-team`)
- Plugin versions: See `.claude-plugin/marketplace.json`
- Core plugin: `default/` (22 skills, 5 agents, 7 commands)
- Developer agents plugin: `dev-team/` (10 skills, 9 agents, 5 commands)
- FinOps plugin: `finops-team/` (6 skills, 2 agents)
- Product planning plugin: `pm-team/` (10 skills, 3 research agents, 2 commands)
- Technical writing plugin: `tw-team/` (7 skills, 3 agents, 3 commands)
- Reserved plugins: `ops-team/`, `pmm-team/` (2 directories)
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
├── finops-team/hooks/session-start.sh    # FinOps agents
├── pm-team/hooks/session-start.sh        # Pre-dev skills
└── tw-team/hooks/session-start.sh        # Technical writing agents

Using-* Skills (plugin introductions):
├── default/skills/using-ring/SKILL.md           # Core workflow + agent list
├── dev-team/skills/using-dev-team/SKILL.md      # Developer agents guide
├── finops-team/skills/using-finops-team/SKILL.md # FinOps guide
├── pm-team/skills/using-pm-team/SKILL.md        # Pre-dev workflow
└── tw-team/skills/using-tw-team/SKILL.md        # Technical writing guide
```

**Checklist when adding/modifying:**
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
