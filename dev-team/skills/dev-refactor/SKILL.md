---
name: dev-refactor
description: |
  Analyzes existing codebase against standards to identify gaps in architecture, code quality,
  testing, and DevOps. Auto-detects project language and uses appropriate agent standards
  (Go, TypeScript, Frontend, DevOps, SRE). Generates refactoring tasks.md compatible with dev-cycle.

trigger: |
  - User wants to refactor existing project to follow standards
  - User runs /ring-dev-team:dev-refactor command
  - Legacy codebase needs modernization
  - Project audit requested

skip_when: |
  - Greenfield project → Use /ring-pm-team:pre-dev-* instead
  - Single file fix → Use ring-dev-team:dev-cycle directly
  - Unknown language (no go.mod, package.json, etc.) → Specify language manually

sequence:
  before: [ring-dev-team:dev-cycle]

related:
  similar: [ring-pm-team:pre-dev-research]
  complementary: [ring-dev-team:dev-cycle, ring-dev-team:dev-implementation]
---

# Dev Refactor Skill

## ⛔ OVERRIDE NOTICE - READ FIRST

**THIS SKILL OVERRIDES GENERAL INSTRUCTIONS FROM `using-ring`.**

The general instruction "Use Explore for codebase scanning" does NOT apply here.
This skill has its own specialized agents that MUST be used instead.

**When this skill is active:**
- ❌ DO NOT use `Explore` agent (even though using-ring recommends it for codebase work)
- ❌ DO NOT use `general-purpose` agent
- ❌ DO NOT use `Plan` agent
- ✅ ONLY use `ring-dev-team:*` agents (see list below)

**Why?** The ring-dev-team:* agents have domain expertise and load Ring standards via WebFetch.
Generic agents like Explore do NOT have this capability.

---

```text
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║  ⛔⛔⛔ CRITICAL: READ BEFORE DOING ANYTHING ⛔⛔⛔                                        ║
║                                                                                           ║
║  THIS SKILL HAS 3 HARD GATES. VIOLATION = SKILL FAILURE.                                  ║
║  ALL STEPS ARE MANDATORY. NO STEP CAN BE SKIPPED.                                         ║
║                                                                                           ║
║  ┌─────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  HARD GATE 0: PROJECT_RULES.md MUST exist                                           │  ║
║  │               └── If NOT found → OUTPUT BLOCKER AND TERMINATE                       │  ║
║  └─────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                           ║
║  ┌─────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  HARD GATE 2: codebase-report.md MUST be generated (Step 2.5)                       │  ║
║  │               └── Dispatch ring-default:codebase-explorer BEFORE specialists        │  ║
║  │               └── Save output to docs/refactor/{timestamp}/codebase-report.md       │  ║
║  │               └── WITHOUT THIS → ALL SPECIALIST OUTPUT IS INVALID                   │  ║
║  └─────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                           ║
║  ┌─────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  HARD GATE 1: ONLY ring-dev-team:* agents allowed (Step 3)                          │  ║
║  │               └── BEFORE typing Task tool → CHECK subagent_type                     │  ║
║  │               └── Does it start with "ring-dev-team:" ? → REQUIRED                  │  ║
║  │               └── ✅ EXCEPTION: ring-default:codebase-explorer (GATE 2 only)        │  ║
║  │                                                                                     │  ║
║  │  ❌ FORBIDDEN (DO NOT USE):                                                         │  ║
║  │     • Explore                    → SKILL FAILURE                                    │  ║
║  │     • general-purpose            → SKILL FAILURE                                    │  ║
║  │     • Plan                       → SKILL FAILURE                                    │  ║
║  │     • ANY agent without ring-dev-team: prefix (except codebase-explorer)            │  ║
║  │                                                                                     │  ║
║  │  ✅ REQUIRED (USE THESE):                                                           │  ║
║  │     • ring-default:codebase-explorer (GATE 2 - generates report)                    │  ║
║  │     • ring-dev-team:backend-engineer-golang                                         │  ║
║  │     • ring-dev-team:backend-engineer-typescript                                     │  ║
║  │     • ring-dev-team:qa-analyst                                                      │  ║
║  │     • ring-dev-team:devops-engineer                                                 │  ║
║  │     • ring-dev-team:sre                                                             │  ║
║  └─────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                           ║
║  NO workaround. NO alternative. NO exception. NO "quick mode". NO shortcuts.              ║
║  EVERY execution follows the SAME steps. "Simple project" is NOT an excuse.               ║
║  Ignoring them = SKILL FAILURE. There is NO way around them.                              ║
║                                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
```

This skill analyzes an existing codebase to identify gaps between current implementation and project standards, then generates a structured refactoring plan compatible with the dev-cycle workflow.

---

## ⛔ UNIVERSAL ANTI-RATIONALIZATION TABLE

**If you catch yourself thinking ANY of these at ANY step, STOP. You are about to cause SKILL FAILURE:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This project is small/simple" | Size is IRRELEVANT. ALL projects follow ALL steps. | Execute ALL steps |
| "I already explored this codebase" | Previous exploration ≠ current report. Each run is fresh. | Execute Step 2.5 |
| "The user wants quick results" | Quick invalid results = useless. Valid results require ALL steps. | Execute ALL steps |
| "This step seems redundant" | Steps are designed together. Skipping one breaks others. | Execute ALL steps |
| "I can combine steps to save time" | Steps have dependencies. Combining = invalid order. | Execute in ORDER |
| "The codebase hasn't changed" | You don't know that. Fresh report ensures accuracy. | Execute Step 2.5 |
| "I'll do a partial analysis" | Partial = incomplete = SKILL FAILURE. | Complete analysis |
| "Just this once I'll skip" | Once = always. No exceptions exist. | Execute ALL steps |
| "The user didn't ask for all this" | User invoked the skill. Skill defines the process. | Execute ALL steps |
| "Other skills don't require this" | THIS skill requires it. Follow THIS skill's rules. | Execute ALL steps |

**NON-NEGOTIABLE:** Every invocation of dev-refactor MUST execute Steps 0 → 1 → 2 → 2.5 → 3 → 4 → 5 → 6 → 7 → 8 → 9 in that exact order.

---

## ⛔ STEP 0: PROJECT_RULES.md VALIDATION (EXECUTE FIRST)

**THIS IS THE FIRST ACTION. Execute BEFORE reading any other section.**

### Validation Sequence

```text
1. Check: Does docs/PROJECT_RULES.md exist?
   └── YES → Continue to "HARD GATES" section below
   └── NO  → OUTPUT BLOCKER AND TERMINATE (see below)
```

### If File Does Not Exist → MANDATORY BLOCKER OUTPUT

**⛔ You MUST output this EXACT response and TERMINATE immediately:**

```markdown
## ⛔ HARD BLOCK: PROJECT_RULES.md Not Found

**Status:** BLOCKED - Cannot proceed with analysis

### What Was Checked
- ❌ `docs/PROJECT_RULES.md` - Not found

### Why This Is a Hard Gate
PROJECT_RULES.md defines the project's specific standards, architecture decisions,
and conventions. Without it, there is NO baseline to compare against.

**Analysis without standards = meaningless comparison.**

### What This Agent CANNOT Do
- ❌ Use "default best practices" as a substitute
- ❌ Infer standards from existing code patterns
- ❌ Proceed with partial analysis
- ❌ Use Ring standards alone (they complement, not replace project rules)

### Required Action
The project owner must create `docs/PROJECT_RULES.md` defining:
- Architecture patterns (hexagonal, clean, DDD, etc.)
- Code conventions (naming, error handling, logging)
- Testing requirements (coverage thresholds, patterns)
- DevOps standards (containerization, CI/CD)

### Next Steps
1. User creates `docs/PROJECT_RULES.md` manually
2. Re-run `/ring-dev-team:dev-refactor` after file exists

**This skill terminates here. No further analysis will be performed.**
```

### Post-Blocker Behavior (MANDATORY)

After outputting the blocker above:
1. **TERMINATE** - Do not continue to any other step
2. **Do NOT** offer to create PROJECT_RULES.md for the user
3. **Do NOT** suggest workarounds or alternatives
4. **Do NOT** analyze using "default" or "industry" standards

### Gate 0 Rationalizations - DO NOT THINK THESE

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll use default Go/TypeScript best practices" | Best practices ≠ project standards. Every project has unique decisions. | Output blocker, TERMINATE |
| "Existing code shows the patterns to follow" | Existing code may BE the problem. Can't use debt as standard. | Output blocker, TERMINATE |
| "Ring standards are enough" | Ring standards are BASE. PROJECT_RULES.md adds project-specific decisions. | Output blocker, TERMINATE |
| "Code works, so I can infer the standards" | Working ≠ correct. Inference = guessing = wrong analysis. | Output blocker, TERMINATE |
| "Small project doesn't need formal standards" | Small projects grow. Standards prevent debt accumulation. | Output blocker, TERMINATE |
| "User didn't ask for standards, just analysis" | Analysis requires baseline. No baseline = no analysis possible. | Output blocker, TERMINATE |
| "I can analyze and recommend standards later" | Recommend against what baseline? Analysis is meaningless without reference. | Output blocker, TERMINATE |

---

## ⛔ HARD GATE 1: AGENT DISPATCH VALIDATION (EXECUTE BEFORE ANY DISPATCH)

**THIS IS A HARD GATE. Violation = SKILL FAILURE. Execute BEFORE calling ANY Task tool.**

**⛔ FORBIDDEN AGENTS (causes SKILL FAILURE):**
- `Explore` - Generic agent, no Ring standards
- `general-purpose` - Generic agent, no domain expertise
- `Plan` - Planning agent, not for analysis
- ANY agent without `ring-dev-team:` or `ring-default:codebase-explorer` prefix

**✅ EXCEPTION: `ring-default:codebase-explorer` is ALLOWED**
- This agent runs FIRST in Step 2.5 to generate `codebase-report.md`
- It provides deep architectural understanding that specialists need
- Without it, specialists analyze blindly (the problem you experienced)

### Validation Sequence

```text
1. Check: Is subagent_type "ring-default:codebase-explorer"?
   └── YES → ALLOWED (Step 2.5 only)
   └── NO  → Continue to check 2

2. Check: Does subagent_type start with "ring-dev-team:" ?
   └── YES → Continue with dispatch
   └── NO  → STOP IMMEDIATELY. DO NOT DISPATCH. (see below)
```

### If Agent Does NOT Have "ring-dev-team:" Prefix → MANDATORY STOP

**⛔ You MUST NOT dispatch the agent. This is a HARD GATE.**

```text
┌─────────────────────────────────────────────────────────────────────┐
│  ⛔ HARD GATE: AGENT PREFIX VALIDATION                              │
│                                                                     │
│  subagent_type MUST start with "ring-dev-team:"                     │
│                                                                     │
│  ✅ "ring-dev-team:..." → ALLOWED - proceed with dispatch           │
│  ❌ ANYTHING ELSE       → FORBIDDEN - DO NOT DISPATCH               │
│                                                                     │
│  This is NOT optional. This is NOT a suggestion.                    │
│  This is a MANDATORY HARD GATE.                                     │
│                                                                     │
│  Dispatching an agent without "ring-dev-team:" prefix = SKILL FAILURE│
└─────────────────────────────────────────────────────────────────────┘
```

### Why This Is a Hard Gate (NOT Optional)

**Agents without `ring-dev-team:` prefix CANNOT perform this skill's function:**

| Capability | ring-dev-team:* | Other agents |
|------------|-----------------|--------------|
| WebFetch for Ring standards | ✅ HAS | ❌ LACKS |
| Domain expertise built-in | ✅ HAS | ❌ LACKS |
| Standards-based compliance output | ✅ HAS | ❌ LACKS |

**Using other agents = Analysis against NOTHING = INVALID output = SKILL FAILURE.**

This is not about preference. Other agents are **technically incapable** of performing standards-based analysis.

### Post-Check Behavior (MANDATORY)

**If the agent you're about to dispatch does NOT have `ring-dev-team:` prefix:**

1. **DO NOT DISPATCH** - Stop before calling Task tool
2. **SELECT CORRECT AGENT** - Find appropriate `ring-dev-team:*` agent
3. **VERIFY PREFIX** - Confirm it starts with `ring-dev-team:`
4. **THEN DISPATCH** - Only after verification passes

**There is NO workaround. There is NO alternative. There is NO exception.**

### Violation Recovery (If You Already Made a Mistake)

**If you ALREADY dispatched an agent without `ring-dev-team:` prefix:**

1. **STOP IMMEDIATELY** - Do not continue using its output
2. **DISCARD THE OUTPUT** - It is INVALID (lacks standards knowledge)
3. **RE-DISPATCH** - Use appropriate `ring-dev-team:*` agent
4. **DOCUMENT** - Note: "Recovered from incorrect agent dispatch"

**Output from non-ring-dev-team agents is INVALID and MUST NOT be used.**

### Gate 1 Rationalizations - DO NOT THINK THESE

**If you catch yourself thinking ANY of these, STOP. You are about to violate HARD GATE 1:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This other agent is faster" | Speed is IRRELEVANT. Wrong agent = INVALID output. | STOP. Use `ring-dev-team:*` |
| "I'll explore first, then use specialists" | Exploration with wrong agent = wasted time + INVALID data. | STOP. Use `ring-dev-team:*` directly |
| "I need to understand the code first" | ring-dev-team:* agents understand AND analyze. One step. | STOP. Use `ring-dev-team:*` |
| "These agents are similar enough" | Similar ≠ equivalent. They LACK standards loading. | STOP. Use `ring-dev-team:*` |
| "Just this once won't matter" | Once = SKILL FAILURE. No exceptions exist. | STOP. Use `ring-dev-team:*` |
| "I can use the output anyway" | Output without standards = GARBAGE IN. | STOP. Discard. Re-dispatch. |
| "The user won't notice" | The USER defined this gate. Violation = failure. | STOP. Use `ring-dev-team:*` |
| "It's close enough" | Close ≠ correct. HARD GATE means EXACT match required. | STOP. Use `ring-dev-team:*` |

---

## ⛔ HARD GATES - READ AFTER STEP 0 PASSES

**This skill has TWO mandatory hard gates. Violation of either gate is a SKILL FAILURE.**

### Gate 0: PROJECT_RULES.md (Prerequisite) ✓

**Already validated in Step 0 above.** If you reached this section, PROJECT_RULES.md exists.

### Gate 1: Agent Dispatch (Execution) - HARD GATE

**⛔ THIS IS A HARD GATE. Violation = SKILL FAILURE.**

**⛔ MANDATORY:** ALL agents MUST have `ring-dev-team:` prefix. NO EXCEPTIONS.

**⛔ See "HARD GATE 1: AGENT DISPATCH VALIDATION" above for complete validation sequence, mandatory behavior, and rationalizations to avoid.**

**⛔ FORBIDDEN AGENTS (from banner):**
- `Explore` → SKILL FAILURE
- `general-purpose` → SKILL FAILURE
- `ring-default:*` → SKILL FAILURE
- ANY agent without `ring-dev-team:` prefix → SKILL FAILURE

#### Parallel Dispatch (Step 3)

**ALL applicable ring-dev-team:* agents MUST be dispatched in a SINGLE message (parallel execution).**

Select agents based on the analysis dimensions needed for the task. Dispatch ALL that apply.

#### Violations - STOP IMMEDIATELY (HARD GATE VIOLATIONS)

| Violation | Consequence | Required Action |
|-----------|-------------|-----------------|
| Using agent without `ring-dev-team:` prefix | **SKILL FAILURE** - Output is INVALID | STOP. Discard output. Re-dispatch with `ring-dev-team:*` |
| Dispatching agents sequentially | Wastes time, incomplete context | Re-send as SINGLE message with ALL agents |
| Dispatching fewer agents than needed | Incomplete analysis | Add ALL applicable `ring-dev-team:*` agents |
| Reading >3 files directly | Violates 3-file rule | Use `ring-dev-team:*` agents instead |

**If you already violated a gate:** STOP IMMEDIATELY. Discard invalid output. Re-execute with correct agents. There is NO way to salvage output from wrong agents.

### Pressure Resistance - DO NOT RATIONALIZE

**If you catch yourself thinking ANY of these, STOP immediately:**

#### Agent & Execution Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This other agent is faster" | Speed ≠ correctness. Wrong agent = wrong analysis. | Use `ring-dev-team:*` agent |
| "I'll just read the files directly" | Violates 3-file rule, incomplete analysis | Dispatch `ring-dev-team:*` agents |
| "One agent is enough" | Multiple dimensions require multiple specialized agents | Dispatch ALL applicable in parallel |
| "Sequential dispatch is fine" | Wastes time, skill requires parallel | Single message, ALL agents |

**Note:** PROJECT_RULES.md rationalizations are covered in "STEP 0: PROJECT_RULES.md VALIDATION" at the top of this skill.

#### Analysis Scope Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Code works fine" | Working ≠ maintainable. Analysis finds hidden debt. | Complete full analysis |
| "Code works, skip analysis" | Working ≠ maintainable. Technical debt hidden. | Complete ALL dimensions |
| "Too time-consuming" | Cost of analysis < cost of compounding debt | Complete full analysis |
| "No time for full analysis" | Partial analysis = partial picture | ALL dimensions required |
| "Standards don't fit us" | Document YOUR standards. Analysis still reveals gaps. | Analyze against project rules |
| "Only critical matters" | Today's medium = tomorrow's critical | Document all severities |
| "Only critical issues matter" | Medium issues become critical over time | Document all, prioritize later |
| "Legacy gets a pass" | Legacy sets precedent. Analysis shows what to improve. | Document all gaps |
| "Standards don't apply to legacy" | Legacy needs analysis MOST | Full analysis required |
| "Team has their own way" | Document "their way" as standards. Analyze against it. | Use PROJECT_RULES.md |
| "That's just how we do it here" | Undocumented patterns = inconsistent patterns | Document in PROJECT_RULES.md |

#### ROI & Justification Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "ROI of refactoring is low" | ROI calculation requires analysis. Can't calculate without data. | Complete analysis first |
| "ROI doesn't justify full analysis" | You can't know ROI without the analysis data | Complete analysis, then evaluate |
| "Partial analysis is enough" | Partial analysis = partial picture. Hidden debt in skipped areas. | ALL dimensions required |
| "Partial analysis is sufficient" | Missing dimensions = missing problems | Complete all dimensions |
| "3 years without bugs = stable" | No bugs ≠ no debt. Time doesn't validate architecture. | Full architecture analysis |
| "3+ years stable = no debt" | Stability ≠ maintainability. Debt compounds silently. | Complete analysis |
| "Analysis is overkill" | Analysis is the MINIMUM. Refactoring without analysis is guessing. | Complete all steps |
| "Code smells ≠ problems" | Code smells ARE problems. They slow development and cause bugs. | Document all findings |
| "Code smells aren't real problems" | Smells indicate deeper issues. They compound over time. | Document all severities |
| "No specific problem motivating" | Technical debt IS the problem. Analysis quantifies it. | Complete analysis |
| "No specific problem to solve" | Unknown problems are still problems. Analysis reveals them. | Full dimension scan |

#### Completion Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Analysis complete, user can decide" | Analysis without action guidance is incomplete. | Generate tasks.md |
| "Analysis is done, user decides next" | Skill requires tasks.md generation | Generate tasks.md before completing |
| "Findings documented, my job done" | Findings → Tasks → Execution. Documentation alone changes nothing. | Generate tasks.md |
| "Documented findings, job complete" | Tasks.md is mandatory output | Complete Step 6 (tasks.md) |

**Non-negotiable:** These gates exist because specialized agents load Ring standards via WebFetch and have domain expertise. Generic agents do NOT have this capability.

### Execution Checklist - MUST COMPLETE IN ORDER

```text
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║  ⛔ ALL STEPS ARE MANDATORY. NO STEP CAN BE SKIPPED. NO EXCEPTIONS.                        ║
║                                                                                           ║
║  Every execution of this skill MUST follow the EXACT same sequence.                       ║
║  "Simple project" is NOT an excuse. "Small codebase" is NOT an excuse.                    ║
║  "I already know the code" is NOT an excuse. FOLLOW THE STEPS.                            ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝

GATE 0:   [ ] PROJECT_RULES.md exists? → If NO, output blocker and TERMINATE
           ⛔ HARD GATE - See "HARD GATE 0" section
           ❌ Cannot proceed without this file

Step 1:   [ ] Language detected? → go.mod / package.json found
           ⛔ MANDATORY - Determines which agents to dispatch

Step 2:   [ ] PROJECT_RULES.md read?
           ⛔ MANDATORY - Project-specific standards context

GATE 2:   [ ] Codebase Explorer dispatched? → ring-default:codebase-explorer
           ⛔ HARD GATE - See "HARD GATE 2" section
           ⛔ This generates codebase-report.md (REQUIRED for Step 3)
           ⛔ WITHOUT THIS, ALL SUBSEQUENT STEPS PRODUCE INVALID OUTPUT
           ✅ EXCEPTION: This is the ONLY ring-default:* agent allowed

Step 2.5b:[ ] codebase-report.md saved to docs/refactor/{timestamp}/?
           ⛔ MANDATORY - File MUST exist before Step 3

GATE 1:   [ ] Agent dispatch validated? → BEFORE typing Task tool:
           ⛔ HARD GATE - See "HARD GATE 1" section
           ⚠️ Does subagent_type start with "ring-dev-team:"? → REQUIRED
           ✅ EXCEPTION: ring-default:codebase-explorer (GATE 2 only)
           ❌ FORBIDDEN: Explore, general-purpose, Plan

Step 3:   [ ] ALL applicable ring-dev-team:* agents dispatched in SINGLE message?
           ⛔ MANDATORY - Agents receive codebase-report.md path
           ⛔ MANDATORY - Agents compare codebase with Ring standards
           ❌ FORBIDDEN: Any agent without ring-dev-team: prefix

Step 4:   [ ] Agent outputs compiled into analysis-report.md?
           ⛔ MANDATORY - Merge all comparison tables

Step 5:   [ ] Findings grouped into REFACTOR-XXX tasks?
           ⛔ MANDATORY - Group by dependency order

Step 6:   [ ] tasks.md generated?
           ⛔ MANDATORY - Skill is INCOMPLETE without this
           ❌ If NO → SKILL FAILURE

Step 7:   [ ] User approval requested via AskUserQuestion?
           ⛔ MANDATORY - User must approve before execution

Step 8:   [ ] Artifacts saved to docs/refactor/{timestamp}/?
           ⛔ MANDATORY - All artifacts must be persisted

Step 9:   [ ] Handoff to dev-cycle (if approved)?
           ⛔ MANDATORY (if user approved) - Execute via dev-cycle
```

**⛔ SKIP PREVENTION:** You CANNOT proceed to Step N+1 without completing Step N. There are NO exceptions. There are NO shortcuts. There are NO "quick modes".

**⛔ GATE 0 (PROJECT_RULES.md):** If PROJECT_RULES.md doesn't exist, you MUST output the blocker template and TERMINATE. No rationalizations allowed.

**⛔ GATE 2 (CODEBASE REPORT):** If codebase-report.md doesn't exist, you CANNOT dispatch specialist agents. This is not optional. This is not "nice to have". Without the report, ALL specialist output is INVALID.

**⛔ GATE 1 (AGENT PREFIX):** If subagent_type doesn't start with `ring-dev-team:`, STOP and use the correct agent. EXCEPTION: `ring-default:codebase-explorer` is allowed ONLY in GATE 2.

#### Prompt Requirements for Step 3

All specialist agent prompts MUST:
1. Reference codebase-report.md path: `docs/refactor/{timestamp}/codebase-report.md`
2. Instruct agent to load Ring standards via WebFetch
3. Request comparison tables: Standard Pattern | Codebase Has | Status | Location | Fix
4. Request code snippets: Current Code vs Expected Code

#### WRONG vs RIGHT: Agent Dispatch

**❌ WRONG - FORBIDDEN AGENTS:**

| Agent | Why WRONG | Consequence |
|-------|-----------|-------------|
| `Explore` | Generic agent, no Ring standards | SKILL FAILURE |
| `general-purpose` | Generic agent, no domain expertise | SKILL FAILURE |
| `Plan` | Planning agent, not for analysis | SKILL FAILURE |
| `ring-default:code-reviewer` | Wrong plugin, for review not analysis | SKILL FAILURE |
| `ring-default:codebase-explorer` | Wrong plugin, generic exploration | SKILL FAILURE |

**❌ WRONG - Sequential dispatch (multiple separate messages):**
- Message 1: Task with agent A → Wait → Response
- Message 2: Task with agent B → Wait → Response
- **This is WRONG** - Must be SINGLE message with ALL agents in parallel

**✅ RIGHT - COPY THIS PATTERN EXACTLY:**

Use Task tool with these EXACT parameters for EACH agent:
- `subagent_type`: MUST start with `ring-dev-team:` (e.g., `ring-dev-team:backend-engineer-golang`)
- `description`: Short description (e.g., "Analyze Go architecture")
- `prompt`: MUST start with `**MODE: ANALYSIS ONLY**` and reference PROJECT_RULES.md

**✅ RIGHT - Parallel dispatch in SINGLE message:**

```text
In ONE message, dispatch ALL applicable ring-dev-team:* agents:

Example for Go project:

Task: subagent_type="ring-dev-team:backend-engineer-golang"
      description="Analyze Go code quality"
      prompt="**MODE: ANALYSIS ONLY** - Analyze Go codebase against PROJECT_RULES.md..."

Task: subagent_type="ring-dev-team:qa-analyst"
      description="Analyze test coverage"
      prompt="**MODE: ANALYSIS ONLY** - Analyze test coverage against PROJECT_RULES.md..."

Task: subagent_type="ring-dev-team:devops-engineer"
      description="Analyze DevOps setup"
      prompt="**MODE: ANALYSIS ONLY** - Analyze DevOps config against PROJECT_RULES.md..."

Task: subagent_type="ring-dev-team:sre"
      description="Analyze observability"
      prompt="**MODE: ANALYSIS ONLY** - Analyze observability against PROJECT_RULES.md..."

ALL Task tool calls in ONE message = PARALLEL execution = CORRECT
```

**Available ring-dev-team:* agents:**
- `ring-dev-team:backend-engineer-golang` - Go backend analysis
- `ring-dev-team:backend-engineer-typescript` - TypeScript backend analysis
- `ring-dev-team:frontend-bff-engineer-typescript` - Frontend/BFF analysis
- `ring-dev-team:frontend-designer` - UI/UX analysis
- `ring-dev-team:devops-engineer` - DevOps/Docker analysis
- `ring-dev-team:qa-analyst` - Test coverage analysis
- `ring-dev-team:sre` - Observability/monitoring analysis

**Select agents based on project language and analysis dimensions needed.**

**Key rules:**
- ✅ ALL agents MUST have `ring-dev-team:` prefix - NO EXCEPTIONS
- ✅ Dispatch ALL applicable agents in SINGLE message (parallel)
- ✅ ALL prompts MUST start with `**MODE: ANALYSIS ONLY**`
- ✅ ALL prompts MUST reference PROJECT_RULES.md
- ❌ NEVER use Explore, general-purpose, or ring-default:* agents for analysis

---

## What This Skill Does

1. **Detects project language** (Go, TypeScript, Python) from manifest files
2. **Reads PROJECT_RULES.md** (project-specific standards - MANDATORY)
3. **Dispatches specialized agents** that load their own Ring standards via WebFetch
4. **Compiles agent findings** into structured analysis report
5. **Generates tasks.md** in the same format as PM Team output
6. **User approves** the plan before execution via dev-cycle

## Foundational Principle

**REFACTORING ANALYSIS IS NOT OPTIONAL FOR CODEBASES WITH TECHNICAL DEBT**

When user requests refactoring or improvement:
1. **NEVER** skip analysis because "code works"
2. **ALWAYS** analyze ALL applicable dimensions
3. **DOCUMENT** all findings, not just critical
4. **PRESERVE** full analysis even if user filters later

**Cost comparison:**
- Cost of refactoring now: Known, bounded
- Cost of compounding debt: Unknown, unbounded

**Analysis now saves 10x effort later.**

## Analysis-to-Action Pipeline - MANDATORY

**Analysis without action guidance is incomplete:**

| Deliverable | Required? | Purpose |
|-------------|----------|---------|
| analysis-report.md | ✅ YES | Document findings |
| tasks.md | ✅ YES | Convert findings to actionable tasks |
| User approval prompt | ✅ YES | Get explicit decision on execution |

**Analysis completion checklist:**
- [ ] ALL applicable dimensions analyzed
- [ ] Findings categorized by severity
- [ ] Findings converted to REFACTOR-XXX tasks
- [ ] tasks.md generated in PM Team format
- [ ] User presented with approval options

**"Analysis complete" means tasks.md exists and user has been asked to approve.**

**If analysis ends without tasks.md:**
1. Analysis is NOT complete
2. Step 6 (Generate tasks.md) was skipped
3. Return to Step 6 before declaring completion

## Analysis Dimensions - ALL REQUIRED

**Every analysis MUST cover ALL applicable dimensions:**

| Dimension | What It Checks | Skip Allowed? |
|-----------|---------------|---------------|
| Architecture | Patterns, structure, dependencies | ❌ NO |
| Code Quality | Standards compliance, complexity, naming | ❌ NO |
| Testing | Coverage, test quality, TDD compliance | ❌ NO |
| DevOps | Containerization, CI/CD, infrastructure | ❌ NO |

**If user says "only check X":**
- Check X thoroughly
- Check other dimensions briefly
- Report: "Full analysis recommended for dimensions: [Y, Z]"

**NEVER produce partial analysis without noting gaps.**

## Cancellation Documentation - MANDATORY

**If user cancels analysis at approval step:**

1. **ASK:** "Why is analysis being cancelled?"
2. **DOCUMENT:** Save reason to `docs/refactor/{timestamp}/cancelled-reason.md`
3. **PRESERVE:** Keep partial analysis artifacts
4. **NOTE:** "Analysis cancelled by user: [reason]. Partial findings preserved."

**Cancellation without documentation is NOT allowed.**

## Prerequisites

**⛔ See "HARD GATES" section above for mandatory checks.**

Before starting analysis:
1. **Project root identified**: Know where the codebase lives
2. **Language detectable**: Project has go.mod, package.json, or similar manifest
3. **Scope defined**: Full project or specific directories
4. **PROJECT_RULES.md exists**: Gate 1 in HARD GATES section

## Analysis Dimensions

### 1. Architecture Analysis

```text
Checks:
├── DDD Patterns (if enabled in PROJECT_RULES.md)
│   ├── Entities have identity comparison
│   ├── Value Objects are immutable
│   ├── Aggregates enforce invariants
│   ├── Repositories are interface-based
│   └── Domain events for state changes
│
├── Clean Architecture / Hexagonal
│   ├── Dependency direction (inward only)
│   ├── Domain has no external dependencies
│   ├── Ports defined as interfaces
│   └── Adapters implement ports
│
└── Directory Structure
    ├── Matches PROJECT_RULES.md layout
    ├── Separation of concerns
    └── No circular dependencies
```

### 2. Code Quality Analysis

```text
Checks:
├── Naming Conventions
│   ├── Files match pattern (snake_case, kebab-case, etc.)
│   ├── Functions/methods follow convention
│   └── Constants are UPPER_SNAKE
│
├── Error Handling
│   ├── No ignored errors (_, err := ...)
│   ├── Errors wrapped with context
│   ├── No panic() for business logic
│   └── Custom error types for domain
│
├── Forbidden Practices
│   ├── No global mutable state
│   ├── No magic numbers/strings
│   ├── No commented-out code
│   ├── No TODO without issue reference
│   └── No `any` type (TypeScript)
│
└── Security
    ├── Input validation at boundaries
    ├── Parameterized queries (no SQL injection)
    ├── Sensitive data not logged
    └── Secrets not hardcoded
```

### 3. Testing Analysis

```text
Checks:
├── Test Coverage
│   ├── Current coverage percentage
│   ├── Gap to minimum (80%)
│   └── Critical paths covered
│
├── Test Patterns
│   ├── Table-driven tests (Go)
│   ├── Arrange-Act-Assert structure
│   ├── Mocks for external dependencies
│   └── No test pollution (global state)
│
├── Test Naming
│   ├── Follows Test{Unit}_{Scenario}_{Expected}
│   └── Descriptive test names
│
└── Test Types
    ├── Unit tests exist
    ├── Integration tests exist
    └── Test fixtures/factories
```

### 4. DevOps Analysis

```text
Checks:
├── Containerization
│   ├── Dockerfile exists
│   ├── Multi-stage build
│   ├── Non-root user
│   └── Health check defined
│
├── Local Development
│   ├── docker-compose.yml exists
│   ├── All services defined
│   └── Volumes for hot reload
│
├── Environment
│   ├── .env.example exists
│   ├── All env vars documented
│   └── No secrets in repo
│
└── CI/CD
    ├── Pipeline exists
    ├── Tests run in CI
    └── Linting enforced
```

## Step 0: Verify PROJECT_RULES.md Exists ✓

**⛔ Already covered in "STEP 0: PROJECT_RULES.md VALIDATION" at the top of this skill.**

If you reached this section, validation passed. Proceed to Step 1.

---

## Step 1: Detect Project Language

**⛔ See "HARD GATES" section above - Gate 2 → Agent Selection by Language**

Detect manifest files (`go.mod`, `package.json`) to determine which `ring-dev-team:*` agent to use.

## Step 2: Read PROJECT_RULES.md

**Read the project-specific standards file:**

```text
Action: Use Read tool to load docs/PROJECT_RULES.md

This file contains:
- Project-specific conventions
- Technology stack decisions
- Architecture patterns chosen for THIS project
- Team-specific coding standards
```

**What dev-refactor does NOT do:**
- Does NOT call WebFetch for Ring standards
- Does NOT load golang.md, typescript.md, devops.md, sre.md directly

**Why?** Each specialized agent (devops-engineer, sre, qa-analyst, backend-engineer-*) has its own WebFetch instructions in its agent definition. They load their own standards when dispatched. This avoids duplication and keeps responsibilities clear:

| Component | Responsibility |
|-----------|---------------|
| **dev-refactor** | Reads PROJECT_RULES.md (local), dispatches agents, compiles findings |
| **Agents** | Load Ring standards via WebFetch, analyze their dimension, return findings |

**Output of this step:**
- PROJECT_RULES.md content loaded and understood
- Ready to dispatch codebase-explorer

---

## ⛔ HARD GATE 2: CODEBASE REPORT GENERATION (Step 2.5)

```text
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║  ⛔⛔⛔ HARD GATE 2: CODEBASE REPORT IS MANDATORY ⛔⛔⛔                                    ║
║                                                                                           ║
║  Step 2.5 MUST be executed for EVERY run of this skill.                                   ║
║  There are NO exceptions. There are NO shortcuts.                                         ║
║                                                                                           ║
║  ┌─────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  BEFORE Step 3 (specialist agents):                                                 │  ║
║  │                                                                                     │  ║
║  │  [ ] Did you dispatch ring-default:codebase-explorer?                               │  ║
║  │  [ ] Did you receive the codebase-report.md output?                                 │  ║
║  │  [ ] Did you save it to docs/refactor/{timestamp}/codebase-report.md?               │  ║
║  │                                                                                     │  ║
║  │  If ANY checkbox is NO → STOP. Execute Step 2.5 before proceeding.                  │  ║
║  └─────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                           ║
║  Skipping Step 2.5 = SKILL FAILURE. Output will be INVALID.                               ║
║                                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
```

### Why This Is a HARD GATE (NOT Optional)

**Without codebase-report.md, specialist agents CANNOT function correctly:**

| With codebase-report.md | Without codebase-report.md |
|-------------------------|---------------------------|
| Agents compare ACTUAL code with standards | Agents guess what code might look like |
| Output: "Replace os.Getenv at config.go:15" | Output: "Consider using better config" |
| Specific file:line references | Generic recommendations |
| Code snippets: current vs expected | No code context |
| **VALID analysis** | **INVALID analysis** |

**This is not about preference. Without the report, agents are TECHNICALLY INCAPABLE of producing valid output.**

### Gate 2 Rationalizations - DO NOT THINK THESE

**If you catch yourself thinking ANY of these, STOP IMMEDIATELY. You are about to violate HARD GATE 2:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "The codebase is small, I can analyze directly" | Small ≠ skip steps. ALL codebases need the report. | Execute Step 2.5 |
| "I already know this codebase from context" | Knowledge ≠ documented report. Agents need the file. | Execute Step 2.5 |
| "This will take too long" | Time is IRRELEVANT. Invalid output is worse than slow output. | Execute Step 2.5 |
| "The user just wants quick feedback" | Quick invalid feedback = useless. Valid output requires report. | Execute Step 2.5 |
| "I can read the files myself instead" | You are the ORCHESTRATOR. Explorer generates the REPORT. | Execute Step 2.5 |
| "Step 2.5 is optional for simple projects" | There is NO such thing as optional. It's a HARD GATE. | Execute Step 2.5 |
| "I'll skip it this once" | Once = SKILL FAILURE. No exceptions exist. | Execute Step 2.5 |
| "The specialists can explore themselves" | Specialists COMPARE, they don't EXPLORE. Wrong responsibility. | Execute Step 2.5 |
| "Codebase-explorer is slow, I'll use Explore" | Explore is FORBIDDEN. Only codebase-explorer is allowed. | Execute Step 2.5 |
| "I can infer the architecture from file names" | Inference = guessing = INVALID. Report provides FACTS. | Execute Step 2.5 |
| "PROJECT_RULES.md already describes the project" | PROJECT_RULES.md = standards. Report = actual implementation. Different things. | Execute Step 2.5 |
| "Previous analysis is still valid" | Each run = fresh report. Codebase may have changed. | Execute Step 2.5 |

### Violation Recovery (If You Already Skipped)

**If you ALREADY proceeded to Step 3 without codebase-report.md:**

1. **STOP IMMEDIATELY** - Do not continue with specialist agents
2. **DISCARD any specialist outputs** - They are INVALID without the report
3. **GO BACK to Step 2.5** - Execute codebase-explorer NOW
4. **SAVE the report** - To docs/refactor/{timestamp}/codebase-report.md
5. **THEN proceed to Step 3** - With the report path in prompts
6. **DOCUMENT** - Note: "Recovered from skipped Step 2.5"

**Output from specialists without codebase-report.md is INVALID and MUST NOT be used.**

---

## Step 2.5: Generate Codebase Report (MANDATORY - HARD GATE 2)

**⛔ THIS IS A HARD GATE. Skipping = SKILL FAILURE.**

**Why this step exists:**
Without understanding the ACTUAL codebase structure, specialists analyze blindly and produce generic recommendations like "improve architecture" instead of actionable insights.

**Responsibility Split:**
| Component | Does | Does NOT |
|-----------|------|----------|
| **codebase-explorer** | Maps what EXISTS in the project | Compare with standards |
| **Specialist agents** | Load Ring standards + Compare with report | Explore codebase |

### Execution Template - COPY EXACTLY

```
Task:
  subagent_type: "ring-default:codebase-explorer"
  model: "opus"
  description: "Generate codebase architecture report"
  prompt: |
    **EXPLORATION TYPE: THOROUGH (30-45 minutes)**

    Generate a comprehensive codebase report describing WHAT EXISTS in this project.

    **IMPORTANT:** You are NOT comparing with standards. You are DOCUMENTING what you find.
    The specialist agents will receive your report and compare it with their standards.

    ## SECTIONS TO INCLUDE

    ### 1. Project Structure
    - Directory layout (internal/, pkg/, cmd/, adapters/, domain/, etc.)
    - Module organization pattern (feature-based vs layer-based)
    - Entry points (main.go, index.ts, etc.)
    - Test organization (co-located vs separate)

    ### 2. Architecture Pattern
    - What architecture is used? (hexagonal, clean, MVC, etc.)
    - Layer boundaries identified
    - Dependency direction observed

    ### 3. Technology Stack
    From go.mod / package.json / pyproject.toml:
    - Language and version
    - Main frameworks (Fiber, Express, FastAPI, etc.)
    - Database libraries
    - Observability libraries
    - Testing libraries

    ### 4. Code Patterns Found

    Document HOW things are currently implemented:

    #### Configuration
    - Where is config loaded? (file:line)
    - How? (env vars, config files, etc.)
    - Show code snippet

    #### Database Access
    - Where are repositories? (directory)
    - What pattern? (raw SQL, ORM, etc.)
    - Do models transform to domain? (yes/no, example file)

    #### HTTP Handlers
    - Where are handlers? (directory)
    - How is routing set up? (file:line)
    - Middleware chain found

    #### Error Handling
    - Pattern observed (wrapped errors, custom types, etc.)
    - Example locations

    #### Telemetry/Observability
    - Is there logging setup? (where)
    - Is there tracing setup? (where)
    - Is there metrics setup? (where)
    - Health endpoints found? (paths)

    #### Testing
    - Test file pattern (xxx_test.go, xxx.spec.ts)
    - Test patterns observed (table-driven, AAA, etc.)
    - Mocking approach

    ### 5. Key Files Inventory

    | Category | File | Purpose | Lines |
    |----------|------|---------|-------|
    | Entry Point | cmd/app/main.go | Application start | 50 |
    | Config | internal/bootstrap/config.go | Config loading | 150 |
    | Router | internal/adapters/http/routes.go | Route definitions | 120 |
    | Handler | internal/adapters/http/user_handler.go | User endpoints | 200 |
    | Service | internal/services/user_service.go | Business logic | 180 |
    | Repository | internal/adapters/postgres/user_repo.go | DB access | 150 |
    | Domain | internal/domain/user.go | Entity definition | 60 |
    | Test | internal/services/user_service_test.go | Unit tests | 250 |
    | Dockerfile | Dockerfile | Container build | 35 |
    | Docker Compose | docker-compose.yml | Local dev setup | 80 |

    ### 6. Code Snippets (IMPORTANT)

    For EACH major pattern, include a code snippet showing CURRENT implementation:

    ```go
    // Configuration loading (internal/bootstrap/config.go:15-25)
    [actual code snippet here]
    ```

    ```go
    // Handler pattern (internal/adapters/http/user_handler.go:30-50)
    [actual code snippet here]
    ```

    ```go
    // Repository pattern (internal/adapters/postgres/user_repo.go:20-45)
    [actual code snippet here]
    ```

    ## OUTPUT FORMAT

    Use standard codebase-explorer schema:
    - EXPLORATION SUMMARY
    - KEY FINDINGS (with file:line references)
    - ARCHITECTURE INSIGHTS
    - RELEVANT FILES (the inventory table)
    - RECOMMENDATIONS (areas that look incomplete, NOT standards comparison)
```

### Save the Report

After receiving the codebase-explorer output:

```text
Action: Use Write tool to save to docs/refactor/{timestamp}/codebase-report.md

Content: Full output from codebase-explorer
```

**Output of this step:**
- `codebase-report.md` saved with complete architecture map
- Code snippets showing current implementations
- Key files inventory for specialists to reference
- Ready to dispatch specialists who will COMPARE with their standards

---

## Step 3: Dispatch ring-dev-team Agents

**⛔ HARD GATE 1 APPLIES HERE - READ BEFORE DISPATCHING ANY AGENT**

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│  ⛔ BEFORE TYPING "Task" - VERIFY AGENT PREFIX                                  │
│                                                                                 │
│  subagent_type MUST start with "ring-dev-team:"                                 │
│                                                                                 │
│  ✅ ALLOWED: ring-dev-team:backend-engineer-golang                              │
│  ✅ ALLOWED: ring-dev-team:backend-engineer-typescript                          │
│  ✅ ALLOWED: ring-dev-team:qa-analyst                                           │
│  ✅ ALLOWED: ring-dev-team:devops-engineer                                      │
│  ✅ ALLOWED: ring-dev-team:sre                                                  │
│  ✅ ALLOWED: ring-dev-team:frontend-bff-engineer-typescript                     │
│  ✅ ALLOWED: ring-dev-team:frontend-designer                                    │
│                                                                                 │
│  ❌ FORBIDDEN: Explore                    → SKILL FAILURE                       │
│  ❌ FORBIDDEN: general-purpose            → SKILL FAILURE                       │
│  ❌ FORBIDDEN: ring-default:*             → SKILL FAILURE                       │
│  ❌ FORBIDDEN: Plan                       → SKILL FAILURE                       │
│  ❌ FORBIDDEN: ANY agent without ring-dev-team: prefix → SKILL FAILURE          │
│                                                                                 │
│  This is NOT optional. This is NOT a suggestion.                                │
│  Dispatching a FORBIDDEN agent = SKILL FAILURE. No exceptions.                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Execution Template - COPY EXACTLY

**⚠️ IMPORTANT: Each agent receives the codebase-report.md and compares with their Ring standards.**

**The prompts below instruct agents to:**
1. Read their Ring standards via WebFetch (they have the URL in their agent definition)
2. Read the codebase-report.md generated in Step 2.5
3. Compare what EXISTS (report) with what SHOULD exist (standards)
4. Generate specific findings with CURRENT code vs EXPECTED code

---

**For Go projects, dispatch in ONE message:**

```
Task 1:
  subagent_type: "ring-dev-team:backend-engineer-golang"
  description: "Compare Go codebase with Ring standards"
  prompt: |
    **MODE: ANALYSIS ONLY** - Compare codebase with Ring Go standards.

    ## INPUT
    1. **Ring Standards:** Load via WebFetch from your agent instructions (golang.md)
    2. **Codebase Report:** Read docs/refactor/{timestamp}/codebase-report.md
    3. **Project Rules:** docs/PROJECT_RULES.md

    ## YOUR TASK

    Compare the CURRENT implementation (from codebase-report.md) with EXPECTED patterns (from Ring standards).

    For EACH pattern in Ring standards, check if the codebase follows it:

    ### lib-commons v2 Patterns
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | `SetConfigFromEnvVars(&cfg)` | os.Getenv() calls | ❌ | config.go:15 | Replace with... |
    | `NewTrackingFromContext(ctx)` | No telemetry recovery | ❌ | handler.go:22 | Add call... |
    | `ToEntity() / FromEntity()` | Raw struct returns | ❌ | user_repo.go:45 | Add methods... |
    | `InitializeTelemetry()` | Missing | ❌ | bootstrap/ | Add in config.go |
    | `StartWithGracefulShutdown()` | app.Listen() only | ⚠️ | main.go:30 | Use ServerManager |

    ### Architecture Patterns
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | Domain has no external imports | imports "database/sql" | ❌ | domain/user.go:5 | Remove import |
    | Interfaces in consumers | In implementers | ❌ | adapters/repo.go | Move to services/ |

    ### Error Handling
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | `fmt.Errorf("context: %w", err)` | Raw error return | ❌ | service.go:42 | Wrap with context |
    | No panic() in business logic | panic() found | ❌ | handler.go:88 | Return error |
    | Error codes with prefix | No error codes | ❌ | - | Add pkg/constant/errors.go |

    ## OUTPUT FORMAT

    For EACH non-compliant pattern, provide:

    ```markdown
    ### ISSUE-001: [Pattern Name]

    **Severity:** Critical | High | Medium | Low
    **Location:** file.go:line
    **Standard:** [Quote from Ring standards]

    **Current Code:**
    ```go
    // What exists in codebase
    ```

    **Expected Code:**
    ```go
    // What Ring standards require
    ```

    **Why This Matters:** [Business impact]
    ```

Task 2:
  subagent_type: "ring-dev-team:qa-analyst"
  description: "Compare test coverage with Ring standards"
  prompt: |
    **MODE: ANALYSIS ONLY** - Compare test patterns with Ring standards.

    ## INPUT
    1. **Ring Standards:** Load via WebFetch from your agent instructions
    2. **Codebase Report:** Read docs/refactor/{timestamp}/codebase-report.md
    3. **Project Rules:** docs/PROJECT_RULES.md

    ## YOUR TASK

    Compare CURRENT test implementation with EXPECTED patterns:

    ### Test Coverage
    | Metric | Current | Required | Status |
    |--------|---------|----------|--------|
    | Total coverage | X% | 85% | ❌/✅ |
    | Handler coverage | X% | 100% | ❌/✅ |
    | Service coverage | X% | 100% | ❌/✅ |

    ### Test Patterns
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | Table-driven tests | Single assertions | ❌ | user_test.go:20 | Convert to table |
    | Test naming convention | Random names | ❌ | - | Use Test{Unit}_{Scenario}_{Expected} |
    | Mocks for externals | Real DB calls | ❌ | repo_test.go | Add mock interface |

    ## OUTPUT FORMAT

    Same as Task 1 - for each non-compliant pattern:
    - Current code snippet
    - Expected code snippet from standards
    - Specific file:line to change

Task 3:
  subagent_type: "ring-dev-team:devops-engineer"
  description: "Compare DevOps setup with Ring standards"
  prompt: |
    **MODE: ANALYSIS ONLY** - Compare DevOps config with Ring standards.

    ## INPUT
    1. **Ring Standards:** Load via WebFetch from your agent instructions (devops.md)
    2. **Codebase Report:** Read docs/refactor/{timestamp}/codebase-report.md
    3. **Project Rules:** docs/PROJECT_RULES.md

    ## YOUR TASK

    Compare CURRENT DevOps setup with EXPECTED patterns:

    ### Dockerfile
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | Multi-stage build | Single stage | ❌ | Dockerfile:1 | Add builder stage |
    | Non-root user | Runs as root | ❌ | Dockerfile | Add USER 1000 |
    | HEALTHCHECK | Missing | ❌ | Dockerfile | Add HEALTHCHECK CMD |
    | Distroless/alpine base | Full debian | ⚠️ | Dockerfile:10 | Use distroless |

    ### docker-compose.yml
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | All dependencies | Missing redis | ❌ | docker-compose.yml | Add redis service |
    | Health checks | No healthcheck | ❌ | - | Add healthcheck per service |
    | Custom network | Default bridge | ⚠️ | - | Add network definition |

    ### Environment
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | .env.example | Missing | ❌ | - | Create file |
    | .env in .gitignore | Not ignored | ❌ | .gitignore | Add .env |

    ## OUTPUT FORMAT

    Same as Task 1 - show current vs expected with exact fixes.

Task 4:
  subagent_type: "ring-dev-team:sre"
  description: "Compare observability with Ring standards"
  prompt: |
    **MODE: ANALYSIS ONLY** - Compare observability setup with Ring standards.

    ## INPUT
    1. **Ring Standards:** Load via WebFetch from your agent instructions (sre.md)
    2. **Codebase Report:** Read docs/refactor/{timestamp}/codebase-report.md
    3. **Project Rules:** docs/PROJECT_RULES.md

    ## YOUR TASK

    Compare CURRENT observability with EXPECTED patterns:

    ### Health Endpoints
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | GET /health | Missing | ❌ | routes.go | Add libHTTP.Ping |
    | GET /ready | Missing | ❌ | routes.go | Add readiness check |
    | GET /version | Missing | ❌ | routes.go | Add libHTTP.Version |

    ### Logging
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | JSON structured logs | Plain text | ❌ | logger.go | Use libZap.InitializeLogger() |
    | Log from context | Direct logger | ❌ | handler.go:15 | Use NewTrackingFromContext |
    | No sensitive data logged | Password logged | 🚨 | auth.go:42 | Remove from log |

    ### Tracing
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | Span per operation | No spans | ❌ | - | Add tracer.Start() |
    | Error recording | Not recorded | ❌ | - | Add HandleSpanError() |
    | Context propagation | Breaks chain | ❌ | service.go:30 | Pass ctx |

    ## OUTPUT FORMAT

    Same as Task 1 - show current vs expected with exact fixes.
```

---

**For TypeScript projects, replace Task 1 with:**

```
Task 1:
  subagent_type: "ring-dev-team:backend-engineer-typescript"
  description: "Compare TypeScript codebase with Ring standards"
  prompt: |
    **MODE: ANALYSIS ONLY** - Compare codebase with Ring TypeScript standards.

    ## INPUT
    1. **Ring Standards:** Load via WebFetch from your agent instructions (typescript.md)
    2. **Codebase Report:** Read docs/refactor/{timestamp}/codebase-report.md
    3. **Project Rules:** docs/PROJECT_RULES.md

    ## YOUR TASK

    Compare CURRENT implementation with EXPECTED patterns:

    ### TypeScript Configuration
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | strict: true | strict: false | ❌ | tsconfig.json:5 | Set to true |
    | noImplicitAny | Missing | ❌ | tsconfig.json | Add option |

    ### Type Safety
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | No `any` type | 15 `any` usages | ❌ | [list files] | Replace with proper types |
    | Branded types for IDs | Plain strings | ❌ | types.ts | Add branded types |
    | Zod validation | No validation | ❌ | - | Add Zod schemas |

    ### Error Handling
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | Result type | throw exceptions | ❌ | service.ts:42 | Return Result<T,E> |
    | Discriminated unions | Plain objects | ⚠️ | types.ts | Add discriminator |

    ## OUTPUT FORMAT

    Same as Go - show current vs expected with exact fixes.
```

---

**For Frontend projects, add:**

```
Task 5:
  subagent_type: "ring-dev-team:frontend-bff-engineer-typescript"
  description: "Compare frontend with Ring standards"
  prompt: |
    **MODE: ANALYSIS ONLY** - Compare frontend with Ring standards.

    ## INPUT
    1. **Ring Standards:** Load via WebFetch from your agent instructions (frontend.md)
    2. **Codebase Report:** Read docs/refactor/{timestamp}/codebase-report.md
    3. **Project Rules:** docs/PROJECT_RULES.md

    ## YOUR TASK

    Compare CURRENT frontend patterns with EXPECTED:

    ### Component Architecture
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | Functional components | Class components | ❌ | UserList.tsx | Convert to function |
    | Typed props | any props | ❌ | Button.tsx:5 | Add interface |

    ### State Management
    | Standard Pattern | Codebase Has | Status | Location | Fix |
    |-----------------|--------------|--------|----------|-----|
    | Server state in React Query | In Redux | ⚠️ | store/ | Migrate to RQ |
    | Minimal global state | Everything global | ❌ | - | Use local state |

    ## OUTPUT FORMAT

    Same format - current vs expected with exact fixes.
```

### Key Rules - MANDATORY

1. **ALL Task tool calls in ONE message** = Parallel execution
2. **ALL subagent_type values MUST start with `ring-dev-team:`**
3. **ALL prompts MUST start with `**MODE: ANALYSIS ONLY**`**
4. **Select agents based on detected language** (go.mod → Go agents, package.json → TypeScript agents)

**Output:** Dimension-specific findings with severities to compile in Step 4.

## Step 4: Compile Findings

**Orchestrator action: Collect agent outputs and merge into analysis-report.md**

Each specialist agent returns:
- Comparison tables (Standard Pattern | Codebase Has | Status | Location | Fix)
- Code snippets (Current vs Expected from their Ring standards)
- Severity classifications

The dev-refactor orchestrator must:
1. **Collect** all agent outputs
2. **Merge** comparison tables by category
3. **Deduplicate** overlapping findings
4. **Count** compliance status (✅ Compliant, ❌ Non-Compliant, ⚠️ Partial)
5. **Sort** by severity (Critical → High → Medium → Low)

**Output structure (template only - agents fill the content):**

```markdown
# Analysis Report: {project-name}

**Generated:** {date}
**Codebase Report:** docs/refactor/{timestamp}/codebase-report.md
**Standards Used:** [list Ring standards loaded by agents]

## Executive Summary

| Category | Total | ✅ | ❌ | ⚠️ |
|----------|-------|-----|-----|-----|
| [From backend-engineer agent] | | | | |
| [From qa-analyst agent] | | | | |
| [From devops-engineer agent] | | | | |
| [From sre agent] | | | | |
| **Total** | | | | |

## Pattern Compliance Details

[Merged tables from all agents - each agent provides their category]

## Issues by Severity

### Critical
[Issues from agents with severity=Critical, includes code snippets]

### High
[Issues from agents with severity=High]

### Medium
[Issues from agents with severity=Medium]

### Low
[Issues from agents with severity=Low]
```

**Key point:** The orchestrator does NOT add code examples. The agents provide all code comparisons based on their Ring standards knowledge.

## Step 5: Prioritize and Group

Group related issues into logical refactoring tasks:

```text
Grouping Strategy:
1. By bounded context / module
2. By dependency order (fix dependencies first)
3. By risk (critical security first)

Example grouping:
├── REFACTOR-001: Fix domain layer isolation
│   ├── ARCH-001: Remove infra imports from domain
│   ├── ARCH-003: Extract repository interfaces
│   └── ARCH-005: Move domain events to domain layer
│
├── REFACTOR-002: Implement proper error handling
│   ├── CODE-002: Wrap errors with context (15 locations)
│   ├── CODE-007: Replace panic with error returns
│   └── CODE-012: Add custom domain error types
│
├── REFACTOR-003: Add missing test coverage
│   ├── TEST-001: User service unit tests
│   ├── TEST-002: Order handler tests
│   └── TEST-003: Repository integration tests
│
└── REFACTOR-004: Containerization improvements
    ├── DEVOPS-001: Add multi-stage Dockerfile
    └── DEVOPS-002: Create docker-compose.yml
```

## Step 6: Generate tasks.md

Create refactoring tasks in the same format as PM Team output:

```markdown
# Refactoring Tasks: {project-name}

**Source:** Analysis Report {date}
**Total Tasks:** {count}
**Estimated Effort:** {total hours}

---

## REFACTOR-001: Fix domain layer isolation

**Type:** backend
**Effort:** 4h
**Priority:** Critical
**Dependencies:** none

### Description
Remove infrastructure dependencies from domain layer and establish proper
port/adapter boundaries following hexagonal architecture.

### Acceptance Criteria
- [ ] AC-1: Domain package has zero imports from infrastructure
- [ ] AC-2: Repository interfaces defined in domain layer
- [ ] AC-3: All domain entities use dependency injection
- [ ] AC-4: Existing tests still pass

### Technical Notes
- Files to modify: src/domain/*.go
- Pattern: See PROJECT_RULES.md → Hexagonal Architecture section
- Related issues: ARCH-001, ARCH-003, ARCH-005

### Issues Addressed
| ID | Description | Location |
|----|-------------|----------|
| ARCH-001 | Domain imports database | src/domain/user.go:15 |
| ARCH-003 | No repository interface | src/domain/ |
| ARCH-005 | Events in wrong layer | src/infrastructure/events.go |

---

## REFACTOR-002: Implement proper error handling

**Type:** backend
**Effort:** 3h
**Priority:** High
**Dependencies:** REFACTOR-001

### Description
Standardize error handling across the codebase following Go idioms
and project standards.

### Acceptance Criteria
- [ ] AC-1: All errors wrapped with context using fmt.Errorf
- [ ] AC-2: No panic() outside of main.go
- [ ] AC-3: Custom error types for domain errors
- [ ] AC-4: Error handling tests added

### Technical Notes
- Use errors.Is/As for error checking
- See PROJECT_RULES.md → Error Handling section

### Issues Addressed
| ID | Description | Location |
|----|-------------|----------|
| CODE-002 | Unwrapped errors | 15 locations |
| CODE-007 | panic in business logic | src/service/order.go:78 |
| CODE-012 | No domain error types | src/domain/ |

---

## REFACTOR-003: Add missing test coverage
...

---

## REFACTOR-004: Containerization improvements
...
```

## Step 7: User Approval

Present the generated plan and ask for approval using AskUserQuestion tool:

```yaml
AskUserQuestion:
  questions:
    - question: "Review the refactoring plan. How do you want to proceed?"
      header: "Approval"
      multiSelect: false
      options:
        - label: "Approve all"
          description: "Save tasks.md, proceed to dev-cycle execution"
        - label: "Approve with changes"
          description: "Let user edit tasks.md first, then proceed"
        - label: "Critical only"
          description: "Filter to only Critical/High priority tasks"
        - label: "Cancel"
          description: "Abort execution, keep analysis report only"
```

## Step 8: Save Artifacts

Save analysis report and tasks to project:

```text
docs/refactor/{timestamp}/
├── analysis-report.md    # Full analysis with all findings
├── tasks.md              # Approved refactoring tasks
└── project-rules-used.md # Copy of PROJECT_RULES.md at time of analysis
```

**Note:** Ring standards are not saved as they are loaded dynamically by agents via WebFetch. Only the project-specific rules are preserved for reference.

## Step 9: Handoff to dev-cycle

If approved, the workflow continues:

```bash
# Automatic handoff
/ring-dev-team:dev-cycle docs/refactor/{timestamp}/tasks.md
```

This executes each refactoring task through the standard 6-gate process:
- Gate 0: Implementation (TDD)
- Gate 1: DevOps Setup
- Gate 2: SRE (Observability)
- Gate 3: Testing
- Gate 4: Review (3 parallel reviewers)
- Gate 5: Validation (user approval)

## Output Schema

```yaml
output_schema:
  format: "markdown"
  artifacts:
    - name: "analysis-report.md"
      location: "docs/refactor/{timestamp}/"
      required: true
    - name: "tasks.md"
      location: "docs/refactor/{timestamp}/"
      required: true
  required_sections:
    - name: "Summary"
      pattern: "^## Summary"
      required: true
    - name: "Critical Issues"
      pattern: "^## Critical Issues"
      required: true
    - name: "Tasks Generated"
      pattern: "^## REFACTOR-"
      required: true
```

## Example Usage

```bash
# Full project analysis
/ring-dev-team:dev-refactor

# Analyze specific directory
/ring-dev-team:dev-refactor src/domain

# Analyze with custom standards
/ring-dev-team:dev-refactor --standards path/to/PROJECT_RULES.md

# Analysis only (no execution)
/ring-dev-team:dev-refactor --analyze-only
```

## Related Skills

| Skill | Purpose |
|-------|---------|
| `ring-dev-team:dev-cycle` | Executes refactoring tasks through 6 gates (after approval) |

## Key Principles

1. **Same workflow**: Refactoring uses the same dev-cycle as new features
2. **Separation of concerns**: dev-refactor reads PROJECT_RULES.md locally; agents load Ring standards via WebFetch
3. **Standards-driven**: Analysis combines project-specific rules (PROJECT_RULES.md) + Ring standards (loaded by agents)
4. **Traceable**: Every task links back to specific issues found
5. **Incremental**: Can approve subset of tasks (critical only, etc.)
6. **Reversible**: Original analysis preserved for reference
