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

---

## Quick Navigation

| Section | Content |
|---------|---------|
| [CRITICAL RULES](#-critical-rules-read-first) | Non-negotiable requirements |
| [Anti-Rationalization Tables](#anti-rationalization-tables-mandatory-for-all-agents) | Prevent AI from assuming/skipping |
| [Assertive Language Reference](#assertive-language-reference-for-prompt-engineering) | Words for prompt engineering |
| [Agent Modification Verification](#agent-modification-verification-mandatory) | Checklist for agent changes |
| [Repository Overview](#repository-overview) | What Ring is |
| [Architecture](#architecture) | Folder structure |
| [Key Workflows](#key-workflows) | Adding skills, agents, hooks |
| [Agent Output Schemas](#agent-output-schema-archetypes) | Output format templates |
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

## Assertive Language Reference (For Prompt Engineering)

**Use these words and phrases to write effective AI instructions that prevent rationalization and ensure compliance.**

### Obligation & Requirement Words

| Word/Phrase | Usage | Example |
|-------------|-------|---------|
| **MUST** | Absolute requirement | "You MUST verify all categories" |
| **REQUIRED** | Mandatory action | "Standards compliance is REQUIRED" |
| **MANDATORY** | Non-optional | "MANDATORY: Read PROJECT_RULES.md first" |
| **SHALL** | Formal obligation | "Agent SHALL report all blockers" |
| **WILL** | Definite action | "You WILL follow this checklist" |
| **ALWAYS** | Every time, no exceptions | "ALWAYS check before proceeding" |

### Prohibition Words

| Word/Phrase | Usage | Example |
|-------------|-------|---------|
| **MUST NOT** | Absolute prohibition | "You MUST NOT skip verification" |
| **CANNOT** | Inability/prohibition | "You CANNOT proceed without approval" |
| **NEVER** | Zero tolerance | "NEVER assume compliance" |
| **FORBIDDEN** | Explicitly banned | "Using `any` type is FORBIDDEN" |
| **DO NOT** | Direct prohibition | "DO NOT make autonomous decisions" |
| **PROHIBITED** | Not allowed | "Skipping gates is PROHIBITED" |

### Enforcement Phrases

| Phrase | When to Use | Example |
|--------|-------------|---------|
| **HARD GATE** | Checkpoint that blocks progress | "HARD GATE: Verify standards before implementation" |
| **NON-NEGOTIABLE** | Cannot be changed or waived | "Security checks are NON-NEGOTIABLE" |
| **NO EXCEPTIONS** | Rule applies universally | "All agents MUST have this section. No exceptions." |
| **THIS IS NOT OPTIONAL** | Emphasize requirement | "Anti-rationalization tables - this is NOT optional" |
| **STOP AND REPORT** | Halt execution | "If blocker found → STOP and report" |
| **BLOCKING REQUIREMENT** | Prevents continuation | "This is a BLOCKING requirement" |

### Consequence Phrases

| Phrase | When to Use | Example |
|--------|-------------|---------|
| **If X → STOP** | Define halt condition | "If PROJECT_RULES.md missing → STOP" |
| **FAILURE TO X = Y** | Define consequences | "Failure to verify = incomplete work" |
| **WITHOUT X, CANNOT Y** | Define dependencies | "Without standards, cannot proceed" |
| **X IS INCOMPLETE IF** | Define completeness | "Agent is INCOMPLETE if missing sections" |

### Verification Phrases

| Phrase | When to Use | Example |
|--------|-------------|---------|
| **VERIFY** | Confirm something is true | "VERIFY all categories are checked" |
| **CONFIRM** | Get explicit confirmation | "CONFIRM compliance before proceeding" |
| **CHECK** | Inspect/examine | "CHECK for FORBIDDEN patterns" |
| **VALIDATE** | Ensure correctness | "VALIDATE output format" |
| **PROVE** | Provide evidence | "PROVE compliance with evidence, not assumptions" |

### Anti-Rationalization Phrases

| Phrase | Purpose | Example |
|--------|---------|---------|
| **Assumption ≠ Verification** | Prevent assuming | "Assuming compliance ≠ verifying compliance" |
| **Looking correct ≠ Being correct** | Prevent superficial checks | "Code looking correct ≠ code being correct" |
| **Partial ≠ Complete** | Prevent incomplete work | "Partial compliance ≠ full compliance" |
| **You don't decide X** | Remove AI autonomy | "You don't decide relevance. The checklist does." |
| **Your job is to X, not Y** | Define role boundaries | "Your job is to VERIFY, not to ASSUME" |

### Escalation Phrases

| Phrase | When to Use | Example |
|--------|---------|---------|
| **ESCALATE TO** | Define escalation path | "ESCALATE TO orchestrator if blocked" |
| **REPORT BLOCKER** | Communicate impediment | "REPORT BLOCKER and await user decision" |
| **AWAIT USER DECISION** | Pause for human input | "STOP. AWAIT USER DECISION on architecture" |
| **ASK, DO NOT GUESS** | Prevent assumptions | "When uncertain, ASK. Do not GUESS." |

### Template Patterns

**For Mandatory Sections:**
```markdown
## Section Name (MANDATORY)

**This section is REQUIRED. It is NOT optional. You MUST include this.**
```

**For Blocker Conditions:**
```markdown
**If [condition] → STOP. DO NOT proceed.**

Action: STOP immediately. Report blocker. AWAIT user decision.
```

**For Non-Negotiable Rules:**
```markdown
| Requirement | Cannot Override Because |
|-------------|------------------------|
| **[Rule]** | [Reason]. This is NON-NEGOTIABLE. |
```

**For Anti-Rationalization:**
```markdown
| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "[Excuse]" | [Why incorrect]. | **[MANDATORY action]** |
```

**Key Principle:** The more assertive and explicit the language, the less room for AI to rationalize, assume, or make autonomous decisions. Strong language creates clear boundaries.

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

Ring supports multiple AI platforms. The installer auto-detects installed platforms and transforms content appropriately.

### Supported Platforms

| Platform | Install Path | Format | Components |
|----------|-------------|--------|------------|
| Claude Code | `~/.claude/` | Native | skills, agents, commands, hooks |
| Factory AI | `~/.factory/` | Transformed | skills, droids, commands |
| Cursor | `~/.cursor/` | Transformed | .cursorrules, workflows |
| Cline | `~/.cline/` | Transformed | prompts |

### Quick Install

```bash
# Interactive installer (Linux/macOS/Git Bash)
curl -fsSL https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.sh | bash

# Interactive installer (Windows PowerShell)
irm https://raw.githubusercontent.com/lerianstudio/ring/main/install-ring.ps1 | iex

# Or clone and run locally
git clone https://github.com/lerianstudio/ring.git ~/ring
cd ~/ring
./installer/install-ring.sh
```

### Platform-Specific Installation

```bash
# Install to specific platform
./installer/install-ring.sh install --platforms claude
./installer/install-ring.sh install --platforms factory
./installer/install-ring.sh install --platforms cursor
./installer/install-ring.sh install --platforms cline

# Install to multiple platforms
./installer/install-ring.sh install --platforms claude,cursor,cline

# Auto-detect and install all
./installer/install-ring.sh install --platforms auto
```

### Installer Commands

```bash
./installer/install-ring.sh install   # Install to platforms
./installer/install-ring.sh update    # Update existing installation
./installer/install-ring.sh sync      # Sync only changed files
./installer/install-ring.sh list      # List installed platforms
./installer/install-ring.sh check     # Check for updates
./installer/install-ring.sh uninstall # Remove from platforms
./installer/install-ring.sh detect    # Detect available platforms
```

See `docs/platforms/` for platform-specific guides.

---

## Architecture

**Monorepo Structure** - Marketplace with multiple plugin collections:

```
ring/                                  # Monorepo root
├── .claude-plugin/
│   └── marketplace.json              # Multi-plugin marketplace config (5 active plugins)
├── default/                          # Core Ring plugin (ring-default)
│   ├── skills/                       # 22 core skills
│   │   ├── brainstorming/            # Socratic design refinement
│   │   ├── test-driven-development/  # RED-GREEN-REFACTOR cycle enforcement
│   │   ├── systematic-debugging/     # 4-phase root cause analysis
│   │   ├── using-ring/              # MANDATORY skill discovery (non-negotiable)
│   │   └── shared-patterns/         # Reusable: state-tracking, failure-recovery
│   ├── agents/                      # 5 specialized agents
│   │   ├── code-reviewer.md         # Foundation review (architecture, patterns)
│   │   ├── business-logic-reviewer.md # Correctness (requirements, edge cases)
│   │   ├── security-reviewer.md     # Safety (OWASP, auth, validation)
│   │   ├── write-plan.md            # Implementation planning
│   │   └── codebase-explorer.md     # Deep architecture analysis (Opus)
│   ├── commands/                    # 7 slash commands
│   │   ├── codereview.md           # /ring-default:codereview - dispatch 3 parallel reviewers
│   │   ├── brainstorm.md           # /ring-default:brainstorm - interactive design
│   │   └── lint.md                 # /ring-default:lint - parallel lint fixing
│   ├── hooks/                      # Session lifecycle
│   │   ├── hooks.json             # SessionStart, UserPromptSubmit config
│   │   ├── session-start.sh       # Load skills quick reference
│   │   ├── generate-skills-ref.py # Parse SKILL.md frontmatter
│   │   └── claude-md-reminder.sh  # CLAUDE.md reminder on prompt submit
│   └── docs/                      # Documentation
├── dev-team/                      # Developer Agents plugin (ring-dev-team)
│   ├── skills/                    # 10 developer skills
│   │   ├── using-dev-team/        # Plugin introduction
│   │   ├── dev-refactor/          # Codebase analysis against standards
│   │   ├── dev-cycle/             # 6-gate development workflow orchestrator
│   │   ├── dev-devops/            # Gate 1: DevOps setup (Docker, compose)
│   │   ├── dev-feedback-loop/     # Assertiveness scoring and metrics
│   │   ├── dev-implementation/    # Gate 0: TDD implementation
│   │   ├── dev-review/            # Gate 4: Parallel code review
│   │   ├── dev-sre/               # Gate 2: Observability setup
│   │   ├── dev-testing/           # Gate 3: Test coverage
│   │   └── dev-validation/        # Gate 5: User approval
│   └── agents/                    # 7 specialized developer agents
│       ├── backend-engineer-golang.md      # Go backend specialist
│       ├── backend-engineer-typescript.md  # TypeScript/Node.js backend specialist
│       ├── devops-engineer.md              # DevOps infrastructure specialist
│       ├── frontend-bff-engineer-typescript.md # BFF & React/Next.js frontend specialist
│       ├── frontend-designer.md            # Visual design specialist
│       ├── qa-analyst.md                   # Quality assurance specialist
│       └── sre.md                          # Site reliability engineer
├── finops-team/                   # FinOps plugin (ring-finops-team)
│   ├── skills/                    # 6 regulatory compliance skills
│   │   └── regulatory-templates*/ # Brazilian regulatory compliance (BACEN, RFB)
│   ├── agents/                    # 2 FinOps agents
│   │   ├── finops-analyzer.md    # Financial operations analysis
│   │   └── finops-automation.md  # FinOps automation
│   └── docs/
│       └── regulatory/           # Brazilian regulatory documentation
├── pm-team/                       # Product Planning plugin (ring-pm-team)
│   ├── commands/                  # 2 slash commands
│   │   ├── pre-dev-feature.md    # /ring-pm-team:pre-dev-feature - 4-gate workflow
│   │   └── pre-dev-full.md       # /ring-pm-team:pre-dev-full - 9-gate workflow
│   ├── agents/                    # 3 research agents
│   │   ├── repo-research-analyst.md      # Codebase pattern research
│   │   ├── best-practices-researcher.md  # Web/Context7 research
│   │   └── framework-docs-researcher.md  # Tech stack documentation
│   └── skills/                    # 10 pre-dev workflow skills
│       └── pre-dev-*/            # Research→PRD→TRD→API→Data→Tasks
├── tw-team/                       # Technical Writing plugin (ring-tw-team)
│   ├── skills/                    # 7 documentation skills
│   │   ├── using-tw-team/        # Plugin introduction
│   │   ├── writing-functional-docs/ # Functional doc patterns
│   │   ├── writing-api-docs/     # API reference patterns
│   │   ├── documentation-structure/ # Doc hierarchy
│   │   ├── voice-and-tone/       # Voice/tone guidelines
│   │   ├── documentation-review/ # Quality checklist
│   │   └── api-field-descriptions/ # Field description patterns
│   ├── agents/                    # 3 technical writing agents
│   │   ├── functional-writer.md  # Guides, tutorials, conceptual docs
│   │   ├── api-writer.md         # API reference documentation
│   │   └── docs-reviewer.md      # Documentation quality review
│   ├── commands/                  # 3 slash commands
│   │   ├── write-guide.md        # /ring-tw-team:write-guide
│   │   ├── write-api.md          # /ring-tw-team:write-api
│   │   └── review-docs.md        # /ring-tw-team:review-docs
│   └── hooks/                     # Session lifecycle
│       ├── hooks.json            # Hook configuration
│       └── session-start.sh      # Context injection
├── installer/                     # Multi-platform installer
│   ├── ring_installer/           # Python package
│   │   ├── adapters/             # Platform adapters (claude, factory, cursor, cline)
│   │   ├── transformers/         # Content transformers
│   │   ├── utils/                # Utilities (fs, version, platform_detect)
│   │   └── core.py               # Installation logic
│   ├── tests/                    # Test suite
│   ├── install-ring.sh           # Bash entry point
│   └── install-ring.ps1          # PowerShell entry point
├── docs/
│   ├── plans/                    # Implementation plans
│   └── platforms/                # Platform-specific guides
├── ops-team/                      # Team-specific skills (reserved)
└── pmm-team/                      # Team-specific skills (reserved)
```

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

### Adding a New Skill

**For core Ring skills:**
1. Create directory: `mkdir default/skills/your-skill-name/`
2. Write `default/skills/your-skill-name/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: your-skill-name
   description: |
     Brief description of WHAT the skill does (method/technique).

   trigger: |
     - Specific condition that mandates this skill
     - Another trigger condition

   skip_when: |
     - When NOT to use → alternative skill
     - Another exclusion

   sequence:
     after: [prerequisite-skill]   # Optional: ordering
     before: [following-skill]

   related:
     similar: [differentiate-from]      # Optional: disambiguation
     complementary: [pairs-well-with]
   ---
   ```
3. Test with `Skill tool: "ring-default:testing-skills-with-subagents"`
4. Skill auto-loads next SessionStart via `default/hooks/generate-skills-ref.py`

**For product/team-specific skills:**
1. Create plugin directory: `mkdir -p product-xyz/{skills,agents,commands,hooks}`
2. Add to `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "ring-product-xyz",
     "description": "Product XYZ specific skills",
     "version": "0.1.0",
     "source": "./product-xyz"
   }
   ```
3. Follow same skill structure as default plugin

### Modifying Hooks
1. Edit `default/hooks/hooks.json` for trigger configuration
2. Scripts in `default/hooks/`: `session-start.sh`, `claude-md-bootstrap.sh`
3. Test: `bash default/hooks/session-start.sh` outputs JSON with additionalContext
4. SessionStart hooks run on `startup|resume` and `clear|compact`
5. Note: `${CLAUDE_PLUGIN_ROOT}` resolves to plugin root (`default/` for core plugin)

### Plugin-Specific Using-* Skills

Each plugin auto-loads a `using-{plugin}` skill via SessionStart hook to introduce available agents and capabilities:

**Default Plugin:**
- `using-ring` → ORCHESTRATOR principle, mandatory workflow
- Always injected, always mandatory
- Located: `default/skills/using-ring/SKILL.md`

**Ring Dev Team Plugin:**
- `ring-dev-team:using-dev-team` → 7 specialist developer agents
- Auto-loads when ring-dev-team plugin is enabled
- Located: `dev-team/skills/using-dev-team/SKILL.md`
- Agents (invoke as `ring-dev-team:{agent-name}`): backend-engineer-golang, backend-engineer-typescript, devops-engineer, frontend-bff-engineer-typescript, frontend-designer, qa-analyst, sre

**Ring FinOps Team Plugin:**
- `using-finops-team` → 2 FinOps agents for Brazilian compliance
- Auto-loads when ring-finops-team plugin is enabled
- Located: `finops-team/skills/using-finops-team/SKILL.md`
- Agents (invoke as `ring-finops-team:{agent-name}`): finops-analyzer (compliance analysis), finops-automation (template generation)

**Ring PM Team Plugin:**
- `using-pm-team` → Pre-dev workflow skills (8 gates)
- Auto-loads when ring-pm-team plugin is enabled
- Located: `pm-team/skills/using-pm-team/SKILL.md`
- Skills: 8 pre-dev gates for feature planning

**Ring TW Team Plugin:**
- `using-tw-team` → 3 technical writing agents for documentation
- Auto-loads when ring-tw-team plugin is enabled
- Located: `tw-team/skills/using-tw-team/SKILL.md`
- Agents (invoke as `ring-tw-team:{agent-name}`): functional-writer (guides), api-writer (API reference), docs-reviewer (quality review)
- Commands: write-guide, write-api, review-docs

**Hook Configuration:**
- Each plugin has: `{plugin}/hooks/hooks.json` + `{plugin}/hooks/session-start.sh`
- SessionStart hook executes, outputs additionalContext with skill reference
- Only plugins in marketplace.json get loaded (conditional)

### Creating Review Agents
1. Add to `default/agents/your-reviewer.md` with output_schema
2. Reference in `default/skills/requesting-code-review/SKILL.md:85`
3. Dispatch via Task tool with `subagent_type="ring-default:your-reviewer"`
4. Must run in parallel with other reviewers (single message, multiple Tasks)

### Pre-Dev Workflow
```
Simple (<2 days): /ring-pm-team:pre-dev-feature
├── Gate 0: pm-team/skills/pre-dev-research → docs/pre-dev/feature/research.md (parallel agents)
├── Gate 1: pm-team/skills/pre-dev-prd-creation → docs/pre-dev/feature/PRD.md
├── Gate 2: pm-team/skills/pre-dev-trd-creation → docs/pre-dev/feature/TRD.md
└── Gate 3: pm-team/skills/pre-dev-task-breakdown → docs/pre-dev/feature/tasks.md

Complex (≥2 days): /ring-pm-team:pre-dev-full
├── Gate 0: Research Phase (3 parallel agents: repo-research, best-practices, framework-docs)
├── Gates 1-3: Same as above
├── Gate 4: pm-team/skills/pre-dev-api-design → docs/pre-dev/feature/API.md
├── Gate 5: pm-team/skills/pre-dev-data-model → docs/pre-dev/feature/data-model.md
├── Gate 6: pm-team/skills/pre-dev-dependency-map → docs/pre-dev/feature/dependencies.md
├── Gate 7: pm-team/skills/pre-dev-task-breakdown → docs/pre-dev/feature/tasks.md
└── Gate 8: pm-team/skills/pre-dev-subtask-creation → docs/pre-dev/feature/subtasks.md
```

### Parallel Code Review
```python
# Instead of sequential (60 min):
review1 = Task("ring-default:code-reviewer")      # 20 min
review2 = Task("ring-default:business-logic-reviewer")     # 20 min
review3 = Task("ring-default:security-reviewer")  # 20 min

# Run parallel (20 min total):
Task.parallel([
    ("ring-default:code-reviewer", prompt),
    ("ring-default:business-logic-reviewer", prompt),
    ("ring-default:security-reviewer", prompt)
])  # Single message, 3 tool calls
```

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

Agents use standard output schema patterns based on their purpose:

**Implementation Schema** (for agents that write code/configs):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "Summary"
      pattern: "^## Summary"
      required: true
    - name: "Implementation"
      pattern: "^## Implementation"
      required: true
    - name: "Files Changed"
      pattern: "^## Files Changed"
      required: true
    - name: "Testing"
      pattern: "^## Testing"
      required: true
    - name: "Next Steps"
      pattern: "^## Next Steps"
      required: true
```

**Used by:** `ring-dev-team:backend-engineer-golang`, `ring-dev-team:backend-engineer-typescript`, `ring-dev-team:frontend-bff-engineer-typescript`, `ring-dev-team:devops-engineer`, `ring-dev-team:qa-analyst`, `ring-dev-team:sre`, `ring-finops-team:finops-automation`

**Analysis Schema** (for agents that analyze and recommend):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "Analysis"
      pattern: "^## Analysis"
      required: true
    - name: "Findings"
      pattern: "^## Findings"
      required: true
    - name: "Recommendations"
      pattern: "^## Recommendations"
      required: true
    - name: "Next Steps"
      pattern: "^## Next Steps"
      required: true
```

**Used by:** `ring-dev-team:frontend-designer`, `ring-finops-team:finops-analyzer`

**Reviewer Schema** (for code review agents):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "VERDICT"
      pattern: "^## VERDICT: (PASS|FAIL|NEEDS_DISCUSSION)$"
      required: true
    - name: "Summary"
      pattern: "^## Summary"
      required: true
    - name: "Issues Found"
      pattern: "^## Issues Found"
      required: true
    - name: "Categorized Issues"
      pattern: "^### (Critical|High|Medium|Low)"
      required: false
    - name: "What Was Done Well"
      pattern: "^## What Was Done Well"
      required: true
    - name: "Next Steps"
      pattern: "^## Next Steps"
      required: true
```

**Used by:** `ring-default:code-reviewer`, `ring-default:business-logic-reviewer`, `ring-default:security-reviewer`

**Note:** `ring-default:business-logic-reviewer` and `ring-default:security-reviewer` extend the base Reviewer Schema with additional domain-specific required sections:
- `ring-default:business-logic-reviewer` adds: "Mental Execution Analysis", "Business Requirements Coverage", "Edge Cases Analysis"
- `ring-default:security-reviewer` adds: "OWASP Top 10 Coverage", "Compliance Status"

**Exploration Schema** (for deep codebase analysis):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "EXPLORATION SUMMARY"
      pattern: "^## EXPLORATION SUMMARY$"
      required: true
    - name: "KEY FINDINGS"
      pattern: "^## KEY FINDINGS$"
      required: true
    - name: "ARCHITECTURE INSIGHTS"
      pattern: "^## ARCHITECTURE INSIGHTS$"
      required: true
    - name: "RELEVANT FILES"
      pattern: "^## RELEVANT FILES$"
      required: true
    - name: "RECOMMENDATIONS"
      pattern: "^## RECOMMENDATIONS$"
      required: true
```

**Used by:** `ring-default:codebase-explorer`

**Planning Schema** (for implementation planning):
```yaml
output_schema:
  format: "markdown"
  required_sections:
    - name: "Goal"
      pattern: "^\\*\\*Goal:\\*\\*"
      required: true
    - name: "Architecture"
      pattern: "^\\*\\*Architecture:\\*\\*"
      required: true
    - name: "Tech Stack"
      pattern: "^\\*\\*Tech Stack:\\*\\*"
      required: true
    - name: "Global Prerequisites"
      pattern: "^\\*\\*Global Prerequisites:\\*\\*"
      required: true
    - name: "Task"
      pattern: "^### Task \\d+:"
      required: true
```

**Used by:** `ring-default:write-plan`

---

## Standards Compliance (Conditional Output Section)

The `ring-dev-team` agents include a **Standards Compliance** output section that is conditionally required based on invocation context:

**Schema Definition:**
```yaml
- name: "Standards Compliance"
  pattern: "^## Standards Compliance"
  required: false  # In schema, but MANDATORY when invoked from dev-refactor
  description: "Comparison of codebase against Lerian/Ring standards"
```

**When Required:**
- **MANDATORY** when agent is invoked from `ring-dev-team:dev-refactor` skill
- **Optional** for direct agent invocations or other workflows

**Enforcement Mechanism:**
- Enforced via prose instructions in agent prompts, not programmatically
- The `dev-refactor` skill dispatches agents with `MODE: ANALYSIS ONLY` prompts that explicitly require Standards Compliance output
- Agents use WebFetch to load standards at runtime from GitHub

**Agents with Standards Compliance:**
- `ring-dev-team:backend-engineer-golang`
- `ring-dev-team:backend-engineer-typescript`
- `ring-dev-team:devops-engineer`
- `ring-dev-team:frontend-bff-engineer-typescript`
- `ring-dev-team:frontend-designer`
- `ring-dev-team:qa-analyst`
- `ring-dev-team:sre`

**Example Output Format:**
```markdown
## Standards Compliance

### Violations Found
| Category | Severity | Location | Issue | Standard Reference |
|----------|----------|----------|-------|-------------------|
| Error Handling | High | pkg/api/handler.go:45 | Using panic() instead of error returns | golang.md#error-handling |
| Logging | Medium | internal/service/user.go:78 | Missing structured logging fields | golang.md#logging |

### Compliance Summary
- **Total Violations:** 2
- **Critical:** 0
- **High:** 1
- **Medium:** 1
- **Low:** 0

### Recommendations
1. Replace panic() with proper error returns per golang.md standards
2. Add structured logging fields (request_id, user_id) to service layer
```

**Cross-References:**
- Skill: `dev-team/skills/dev-refactor/SKILL.md` (defines HARD GATES requiring Standards Compliance)
- Standards: `dev-team/docs/standards/*.md` (source of truth for compliance checks)
- Agents: `dev-team/agents/*.md` (output_schema includes Standards Compliance)

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

Plugin Hooks (inject context at session start):
├── default/hooks/session-start.sh        # Skills reference
├── default/hooks/claude-md-reminder.sh   # Agent reminder table
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

Agent Cross-References:
└── default/agents/write-plan.md          # References reviewers
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
