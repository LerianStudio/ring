---
name: dev-refactor
description: |
  MANDATORY EXECUTION SEQUENCE (follow EXACTLY):

  1. Validate docs/PROJECT_RULES.md exists
  2. Detect project language (go.mod = Go, package.json = TypeScript)
  3. DISPATCH ring-default:codebase-explorer FIRST (generates codebase-report.md)
     - This step is MANDATORY and CANNOT be skipped
     - Must complete BEFORE step 4
  4. THEN dispatch ring-dev-team specialist agents (backend-engineer-golang, qa-analyst, etc.)
  5. Generate findings.md from agent outputs
  6. Generate tasks.md for dev-cycle

  WARNING: If you skip step 3 (codebase-explorer) → SKILL FAILURE
  WARNING: codebase-explorer and specialist agents are SEPARATE steps

  Purpose: Analyzes existing codebase against standards to identify gaps.

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

## ⛔⛔⛔ STOP - EXECUTE THIS FIRST ⛔⛔⛔

```text
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                           ║
║   ██████╗ ████████╗ ██████╗ ██████╗     ███████╗██╗██████╗ ███████╗████████╗             ║
║   ██╔═══╝    ██╔══╝██╔═══██╗██╔══██╗    ██╔════╝██║██╔══██╗██╔════╝   ██╔══╝             ║
║   ██████╗    ██║   ██║   ██║██████╔╝    █████╗  ██║██████╔╝███████╗   ██║                ║
║   ╚═══██║    ██║   ██║   ██║██╔═══╝     ██╔══╝  ██║██╔══██╗╚════██║   ██║                ║
║   ██████║    ██║   ╚██████╔╝██║         ██║     ██║██║  ██║███████║   ██║                ║
║   ╚═════╝    ╚═╝    ╚═════╝ ╚═╝         ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝                ║
║                                                                                           ║
║   YOU MUST USE TodoWrite TOOL NOW - BEFORE READING ANYTHING ELSE                          ║
║                                                                                           ║
║   Use TodoWrite with EXACTLY these items:                                                 ║
║                                                                                           ║
║   todos:                                                                                  ║
║     - content: "Validate PROJECT_RULES.md exists"                                         ║
║       status: "in_progress"                                                               ║
║       activeForm: "Validating PROJECT_RULES.md"                                           ║
║     - content: "Detect project language"                                                  ║
║       status: "pending"                                                                   ║
║       activeForm: "Detecting project language"                                            ║
║     - content: "Dispatch ring-default:codebase-explorer"                                  ║
║       status: "pending"                                                                   ║
║       activeForm: "Dispatching codebase-explorer"                                         ║
║     - content: "Save codebase-report.md artifact"                                         ║
║       status: "pending"                                                                   ║
║       activeForm: "Saving codebase-report.md"                                             ║
║     - content: "Dispatch ring-dev-team specialist agents"                                 ║
║       status: "pending"                                                                   ║
║       activeForm: "Dispatching specialist agents"                                         ║
║     - content: "Generate findings.md"                                                     ║
║       status: "pending"                                                                   ║
║       activeForm: "Generating findings.md"                                                ║
║     - content: "Generate tasks.md"                                                        ║
║       status: "pending"                                                                   ║
║       activeForm: "Generating tasks.md"                                                   ║
║     - content: "Get user approval"                                                        ║
║       status: "pending"                                                                   ║
║       activeForm: "Getting user approval"                                                 ║
║                                                                                           ║
║   ⛔ DO NOT SKIP THIS STEP                                                                ║
║   ⛔ DO NOT CREATE YOUR OWN TODO LIST                                                     ║
║   ⛔ DO NOT COMBINE ITEMS 3 AND 5                                                         ║
║   ⛔ "Dispatch ring-default:codebase-explorer" MUST BE A SEPARATE ITEM                    ║
║                                                                                           ║
║   If TodoWrite not executed FIRST → SKILL FAILURE                                         ║
║                                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
```

**↓↓↓ AFTER TodoWrite completes, continue reading below ↓↓↓**

---

## ⛔ OVERRIDE NOTICE

**THIS SKILL OVERRIDES GENERAL INSTRUCTIONS FROM `using-ring`.**

The general instruction "Use Explore for codebase scanning" does NOT apply here.
This skill has its own specialized agents that MUST be used instead.

**When this skill is active:**
- ❌ DO NOT use `Explore` agent (even though using-ring recommends it for codebase work)
- ❌ DO NOT use `general-purpose` agent
- ❌ DO NOT use `Plan` agent
- ✅ Step 3: Use `ring-default:codebase-explorer` (ONLY agent allowed for codebase exploration)
- ✅ Step 4+: Use `ring-dev-team:*` agents (specialists)

**⛔ CRITICAL: For codebase exploration, use `ring-default:codebase-explorer`, NOT `Explore`.**
The built-in `Explore` agent is FORBIDDEN. It does NOT load Ring standards.

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
║  │  HARD GATE 2: codebase-report.md MUST be generated (Step 3)                       │  ║
║  │               └── Dispatch ring-default:codebase-explorer BEFORE specialists        │  ║
║  │               └── Save output to docs/refactor/{timestamp}/codebase-report.md       │  ║
║  │               └── WITHOUT THIS → ALL SPECIALIST OUTPUT IS INVALID                   │  ║
║  └─────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                           ║
║  ┌─────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  HARD GATE 1: ONLY ring-dev-team:* agents allowed (Step 4)                          │  ║
║  │               └── BEFORE typing Task tool → CHECK subagent_type                     │  ║
║  │               └── Does it start with "ring-dev-team:" ? → REQUIRED                  │  ║
║  │               └── ✅ EXCEPTION: ring-default:codebase-explorer (GATE 2 only)        │  ║
║  │                                                                                     │  ║
║  │  ❌ FORBIDDEN (DO NOT USE):                                                         │  ║
║  │     • Explore                    → SKILL FAILURE                                    │  ║
║  │     • general-purpose            → SKILL FAILURE                                    │  ║
║  │     • Plan                       → SKILL FAILURE                                    │  ║
║  │     • ANY agent without ring-dev-team: prefix (except ring-default:codebase-explorer)            │  ║
║  │                                                                                     │  ║
║  │  ✅ REQUIRED (USE THESE):                                                           │  ║
║  │     • ring-default:codebase-explorer (Step 3 - generates report)                    │  ║
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
| "I already explored this codebase" | Previous exploration ≠ current report. Each run is fresh. | Execute Step 3 |
| "The user wants quick results" | Quick invalid results = useless. Valid results require ALL steps. | Execute ALL steps |
| "This step seems redundant" | Steps are designed together. Skipping one breaks others. | Execute ALL steps |
| "I can combine steps to save time" | Steps have dependencies. Combining = invalid order. | Execute in ORDER |
| "The codebase hasn't changed" | You don't know that. Fresh report ensures accuracy. | Execute Step 3 |
| "I'll do a partial analysis" | Partial = incomplete = SKILL FAILURE. | Complete analysis |
| "Just this once I'll skip" | Once = always. No exceptions exist. | Execute ALL steps |
| "The user didn't ask for all this" | User invoked the skill. Skill defines the process. | Execute ALL steps |
| "Other skills don't require this" | THIS skill requires it. Follow THIS skill's rules. | Execute ALL steps |

**NON-NEGOTIABLE:** Every invocation of dev-refactor MUST execute Steps 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 in that exact order.

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) and [docs/AGENT_DESIGN.md](https://raw.githubusercontent.com/LerianStudio/ring/main/docs/AGENT_DESIGN.md) for canonical gate requirements and anti-rationalization patterns. This skill enforces those rules verbatim; only dev-refactor-specific procedures are documented below.

---

## ⛔ STEP 0: PROJECT_RULES.md VALIDATION (EXECUTE FIRST)

**THIS IS THE FIRST ACTION. Execute BEFORE reading any other section.**

### Validation Sequence

```text
1. Check: Does docs/PROJECT_RULES.md exist?
   └── YES → Continue to Content Adequacy Check below
   └── NO  → OUTPUT BLOCKER AND TERMINATE (see "If File Does Not Exist" section)
```

### Content Adequacy Check

After confirming file exists:

2. Check: Does PROJECT_RULES.md contain substantive standards?

   Minimum requirements (at least ONE of these):
   - Architecture section (>20 lines)
   - Code conventions section (>20 lines)
   - Technology stack section (>15 lines)
   - Testing requirements section (>15 lines)
   - Total file length >100 lines

   └── YES → Continue to "HARD GATES" section
   └── NO  → OUTPUT "STUB FILE BLOCKER" AND TERMINATE

### If File Is Stub/Empty → MANDATORY BLOCKER OUTPUT

**⛔ You MUST output this EXACT response and TERMINATE immediately:**

```markdown
## ⛔ HARD BLOCK: PROJECT_RULES.md Contains No Standards

**Status:** BLOCKED - Cannot proceed with analysis

### What Was Checked
- ✅ `docs/PROJECT_RULES.md` - File exists
- ❌ File content - Contains no substantive design standards (stub/placeholder detected)

### Why This Is a Hard Gate
PROJECT_RULES.md must contain ACTUAL project standards, not placeholder text.

**Analysis against an empty baseline = meaningless comparison.**

### Current File State
- File length: [X] lines
- Content detected: [Stub/Placeholder/Minimal]
- Missing: Architecture patterns, code conventions, testing requirements

### What This Agent CANNOT Do
- ❌ Proceed with stub/placeholder file
- ❌ Use "default best practices" as substitute
- ❌ Infer standards from existing code
- ❌ Generate standards automatically

### Required Action
The project owner must populate `docs/PROJECT_RULES.md` with actual standards:
- Architecture patterns (hexagonal, clean, DDD, etc.) - minimum 20 lines
- Code conventions (naming, error handling, logging) - minimum 20 lines
- Testing requirements (coverage thresholds, patterns) - minimum 15 lines
- Technology stack decisions - minimum 15 lines

**Minimum viable PROJECT_RULES.md: 100+ lines of substantive content**

### Next Steps
1. User populates `docs/PROJECT_RULES.md` with actual project standards
2. Re-run `/ring-dev-team:dev-refactor` after file contains standards

**This skill terminates here. No further analysis will be performed.**
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
- This agent runs FIRST in Step 3 to generate `codebase-report.md`
- It provides deep architectural understanding that specialists need
- Without it, specialists analyze blindly (the problem you experienced)

### Validation Sequence

```text
1. Check: Is subagent_type "ring-default:codebase-explorer"?
   └── YES → ALLOWED (Step 3 only)
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

## Parallel Dispatch (Step 4)

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

### Analysis Rationalizations (DO NOT THINK THESE)

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Code works fine / skip analysis" | Working ≠ maintainable. Technical debt hidden. | Complete ALL dimensions |
| "Too time-consuming / no time" | Cost of analysis < cost of compounding debt | Complete full analysis |
| "Standards don't fit us" | Document YOUR standards. Analysis still reveals gaps. | Analyze against project rules |
| "Only critical matters" | Today's medium = tomorrow's critical | Document all severities |
| "Legacy gets a pass" | Legacy needs analysis MOST | Full analysis required |
| "Team has their own way" | Undocumented patterns = inconsistent patterns | Document in PROJECT_RULES.md |
| "ROI doesn't justify analysis" | Can't calculate ROI without analysis data | Complete analysis first |
| "Partial analysis is enough" | Missing dimensions = missing problems | ALL dimensions required |
| "3+ years stable = no debt" | Stability ≠ maintainability. Debt compounds silently. | Complete analysis |
| "Code smells aren't problems" | Smells indicate deeper issues. They compound. | Document all severities |
| "Analysis complete, user decides" | Skill requires tasks.md generation | Generate tasks.md |
| "Findings documented, job done" | Findings → Tasks → Execution. Docs alone ≠ change. | Generate tasks.md |

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

╔═════════════════════════════════════════════════════════════════════════════════╗
║  STEP 3: CODEBASE EXPLORATION (MANDATORY - DO NOT SKIP)                         ║
║                                                                                 ║
║  [ ] 3a: Task tool dispatched ring-default:codebase-explorer?                   ║
║          ⛔ HARD GATE - This step is NON-NEGOTIABLE                             ║
║          ⛔ This generates codebase-report.md (REQUIRED for Step 4)             ║
║          ⛔ WITHOUT THIS, ALL SUBSEQUENT STEPS PRODUCE INVALID OUTPUT           ║
║          ✅ EXCEPTION: This is the ONLY ring-default:* agent allowed            ║
║                                                                                 ║
║  [ ] 3b: Write tool saved output to docs/refactor/{timestamp}/codebase-report.md? ║
║          ⛔ MANDATORY - File MUST exist before Step 4                           ║
║                                                                                 ║
║  ⛔ IF STEP 3 NOT COMPLETE → CANNOT PROCEED TO STEP 4                           ║
╚═════════════════════════════════════════════════════════════════════════════════╝

GATE 1:   [ ] Agent dispatch validated? → BEFORE typing Task tool:
           ⛔ HARD GATE - See "HARD GATE 1" section
           ⚠️ Does subagent_type start with "ring-dev-team:"? → REQUIRED
           ✅ EXCEPTION: ring-default:codebase-explorer (GATE 2 only)
           ❌ FORBIDDEN: Explore, general-purpose, Plan

Step 4:   [ ] ALL applicable ring-dev-team:* agents dispatched in SINGLE message?
           ⛔ MANDATORY - Agents receive codebase-report.md path
           ⛔ MANDATORY - Agents compare codebase with Ring standards
           ❌ FORBIDDEN: Any agent without ring-dev-team: prefix

Step 5:   [ ] Agent outputs compiled into findings.md?
           ⛔ MANDATORY - Use Write tool to CREATE findings.md
           ⛔ MANDATORY - Generate findings.md with CTC for each finding
           ⛔ MANDATORY - Each finding has Before/After/Standard References
           ❌ If Write tool NOT used → findings.md does NOT exist → SKILL FAILURE

Step 6:   [ ] Findings grouped into REFACTOR-XXX tasks?
           ⛔ MANDATORY - Group by dependency order

Step 7:   [ ] tasks.md generated with finding references?
           ⛔ MANDATORY - Each task MUST reference FINDING-XXX
           ⛔ MANDATORY - Each task MUST include Execution Context from findings
           ❌ If NO → SKILL FAILURE

Step 8:   [ ] User approval requested via AskUserQuestion?
           ⛔ MANDATORY - User must approve before execution

Step 9:   [ ] Artifacts saved to docs/refactor/{timestamp}/?
           ⛔ MANDATORY - codebase-report.md saved
           ⛔ MANDATORY - findings.md saved
           ⛔ MANDATORY - tasks.md saved

Step 10:  [ ] Handoff to dev-cycle (if approved)?
           ⛔ MANDATORY (if user approved) - Use Skill tool to invoke dev-cycle
           ⛔ MANDATORY - Skill tool with skill="ring-dev-team:dev-cycle"
           ❌ If approval received AND Skill tool NOT used → SKILL FAILURE
```

**⛔ SKIP PREVENTION:** You CANNOT proceed to Step N+1 without completing Step N. There are NO exceptions. There are NO shortcuts. There are NO "quick modes".

**⛔ GATE 0 (PROJECT_RULES.md):** If PROJECT_RULES.md doesn't exist, you MUST output the blocker template and TERMINATE. No rationalizations allowed.

**⛔ GATE 2 (CODEBASE REPORT):** If codebase-report.md doesn't exist, you CANNOT dispatch specialist agents. This is not optional. This is not "nice to have". Without the report, ALL specialist output is INVALID.

**⛔ GATE 1 (AGENT PREFIX):** If subagent_type doesn't start with `ring-dev-team:`, STOP and use the correct agent. EXCEPTION: `ring-default:codebase-explorer` is allowed ONLY in GATE 2.

**⛔ EXPLICIT TOOL REQUIREMENTS (MANDATORY):**

| Step | Tool Required | Action |
|------|---------------|--------|
| Step 3 | **Task tool** | DISPATCH `ring-default:codebase-explorer` |
| Step 3 | **Write tool** | SAVE `docs/refactor/{timestamp}/codebase-report.md` |
| Step 5 | **Write tool** | CREATE `docs/refactor/{timestamp}/findings.md` |
| Step 10 | **Skill tool** | INVOKE `ring-dev-team:dev-cycle` (after approval) |

**Nothing is implicit. Tool usage = action happens. No tool = action does NOT happen.**

#### Prompt Requirements for Step 4

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

**✅ EXCEPTION for Step 3 ONLY:**
| `ring-default:codebase-explorer` | Explores codebase structure | **ALLOWED IN STEP 3 ONLY** - generates codebase-report.md for specialists |

**After Step 3, ring-default:codebase-explorer is FORBIDDEN. Specialists compare the report with Ring standards.**

**Dispatch Pattern:**
- ❌ WRONG: Sequential dispatch (one agent per message)
- ✅ RIGHT: ALL agents in SINGLE message (parallel execution)

**See Step 4 for full dispatch templates with complete prompts.**

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
2. Step 7 (Generate tasks.md) was skipped
3. Return to Step 7 before declaring completion

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

## Step 1: Detect Project Language

**⛔ MANDATORY: Detect ALL languages, dispatch agents for ALL.**

### Detection Sequence

1. Check for go.mod → If found, add `ring-dev-team:backend-engineer-golang` to dispatch list
2. Check for package.json → Inspect to determine:
   - Backend TypeScript → Add `ring-dev-team:backend-engineer-typescript`
   - Frontend → Add `ring-dev-team:frontend-bff-engineer-typescript`
3. Check for pyproject.toml → Add Python agent (if applicable)

### Multi-Language Enforcement

**If 2+ languages detected:**
- ✅ MUST dispatch specialist for EACH language in Step 4
- ❌ Dispatching for only one language = INCOMPLETE ANALYSIS = SKILL FAILURE

### Multi-Language Rationalization - DO NOT THINK THIS

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Project is primarily Go, TypeScript is minor" | Minor ≠ skip. ALL languages MUST be analyzed. | Dispatch agents for ALL |
| "Only one TypeScript file doesn't need full analysis" | Size irrelevant. Standards apply uniformly. | Dispatch TypeScript agent |
| "I'll analyze the main language first, then decide" | Decide ≠ YOUR responsibility. Dispatch ALL from start. | Dispatch agents for ALL |

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
- Ready to dispatch ring-default:codebase-explorer

---

## ⛔ HARD GATE 2: CODEBASE REPORT GENERATION (Step 3)

```text
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║  ⛔⛔⛔ HARD GATE 2: CODEBASE REPORT IS MANDATORY ⛔⛔⛔                                    ║
║                                                                                           ║
║  Step 3 MUST be executed for EVERY run of this skill.                                   ║
║  There are NO exceptions. There are NO shortcuts.                                         ║
║                                                                                           ║
║  ┌─────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  BEFORE Step 4 (specialist agents):                                                 │  ║
║  │                                                                                     │  ║
║  │  [ ] Did you dispatch ring-default:codebase-explorer?                               │  ║
║  │  [ ] Did you receive the codebase-report.md output?                                 │  ║
║  │  [ ] Did you save it to docs/refactor/{timestamp}/codebase-report.md?               │  ║
║  │                                                                                     │  ║
║  │  If ANY checkbox is NO → STOP. Execute Step 3 before proceeding.                  │  ║
║  └─────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                           ║
║  Skipping Step 3 = SKILL FAILURE. Output will be INVALID.                               ║
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
| "The codebase is small, I can analyze directly" | Small ≠ skip steps. ALL codebases need the report. | Execute Step 3 |
| "I already know this codebase from context" | Knowledge ≠ documented report. Agents need the file. | Execute Step 3 |
| "This will take too long" | Time is IRRELEVANT. Invalid output is worse than slow output. | Execute Step 3 |
| "The user just wants quick feedback" | Quick invalid feedback = useless. Valid output requires report. | Execute Step 3 |
| "I can read the files myself instead" | You are the ORCHESTRATOR. Explorer generates the REPORT. | Execute Step 3 |
| "Step 3 is optional for simple projects" | There is NO such thing as optional. It's a HARD GATE. | Execute Step 3 |
| "I'll skip it this once" | Once = SKILL FAILURE. No exceptions exist. | Execute Step 3 |
| "The specialists can explore themselves" | Specialists COMPARE, they don't EXPLORE. Wrong responsibility. | Execute Step 3 |
| "Codebase-explorer is slow, I'll use Explore" | Explore is FORBIDDEN. Only ring-default:codebase-explorer is allowed. | Execute Step 3 |
| "I can infer the architecture from file names" | Inference = guessing = INVALID. Report provides FACTS. | Execute Step 3 |
| "PROJECT_RULES.md already describes the project" | PROJECT_RULES.md = standards. Report = actual implementation. Different things. | Execute Step 3 |
| "Previous analysis is still valid" | Each run = fresh report. Codebase may have changed. | Execute Step 3 |

### Violation Recovery (If You Already Skipped)

**If you ALREADY proceeded to Step 4 without completing Step 3:**

1. **STOP IMMEDIATELY** - Do not continue with specialist agents
2. **DISCARD any specialist outputs** - They are INVALID without the report
3. **GO BACK to Step 3** - Execute ring-default:codebase-explorer NOW
4. **SAVE the report** - To docs/refactor/{timestamp}/codebase-report.md
5. **THEN proceed to Step 4** - With the report path in prompts
6. **DOCUMENT** - Note: "Recovered from skipped Step 3"

**Output from specialists without codebase-report.md is INVALID and MUST NOT be used.**

---

## Step 3: Generate Codebase Report (MANDATORY)

**⛔ THIS IS A HARD GATE. Skipping = SKILL FAILURE.**

**Why this step exists:**
Without understanding the ACTUAL codebase structure, specialists analyze blindly and produce generic recommendations like "improve architecture" instead of actionable insights.

**Responsibility Split:**
| Component | Does | Does NOT |
|-----------|------|----------|
| **ring-default:codebase-explorer** | Maps what EXISTS in the project | Compare with standards |
| **Specialist agents** | Load Ring standards + Compare with report | Explore codebase |

### Explicit Tool Invocation (MANDATORY)

**⛔ You MUST use the Task tool to dispatch ring-default:codebase-explorer. This is NOT implicit.**

```text
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║  ⛔⛔⛔ CRITICAL: USE TASK TOOL - NOT EXPLORE AGENT ⛔⛔⛔                                   ║
║                                                                                           ║
║  ❌ DO NOT use: Explore agent (built-in)     → SKILL FAILURE                              ║
║  ❌ DO NOT use: general-purpose agent        → SKILL FAILURE                              ║
║                                                                                           ║
║  ✅ MUST use: Task tool with parameters below                                             ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
```

**⛔ Use Task tool with EXACTLY these parameters:**

```yaml
Task:
  subagent_type: "ring-default:codebase-explorer"
  model: "opus"
  description: "Generate codebase architecture report"
  prompt: |
    **EXPLORATION TYPE: THOROUGH**

    Generate a comprehensive codebase report describing WHAT EXISTS in this project.
    You are NOT comparing with standards. You are DOCUMENTING what you find.

    Include: Project Structure, Architecture Pattern, Technology Stack,
    Code Patterns (config, database, handlers, errors, telemetry, testing),
    Key Files Inventory with file:line references.

    Output format: EXPLORATION SUMMARY, KEY FINDINGS, ARCHITECTURE INSIGHTS,
    RELEVANT FILES, RECOMMENDATIONS.
```

**⛔ VERIFICATION after Task completes:**
1. Agent used was `ring-default:codebase-explorer` (NOT `Explore`)
2. Output contains required sections
3. Ready to save with Write tool

### If Task Tool NOT Used → SKILL FAILURE

Agent is NOT dispatched → No report generated → All subsequent steps produce INVALID output.

### Prompt Template for ring-default:codebase-explorer

Use this EXACT prompt when invoking the Task tool:

```text
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

Use standard ring-default:codebase-explorer schema:
- EXPLORATION SUMMARY
- KEY FINDINGS (with file:line references)
- ARCHITECTURE INSIGHTS
- RELEVANT FILES (the inventory table)
- RECOMMENDATIONS (areas that look incomplete, NOT standards comparison)
```

### Save the Report (MANDATORY)

**⛔ After Task tool returns output, you MUST save to file using Write tool.**

```text
Action: Use Write tool with EXACTLY these parameters:

┌─────────────────────────────────────────────────────────────────────────────────┐
│  Write tool parameters:                                                         │
│                                                                                 │
│  file_path: "docs/refactor/{timestamp}/codebase-report.md"                      │
│  content: [Full output from ring-default:codebase-explorer Task]                │
│                                                                                 │
│  ⛔ If Write tool NOT used → codebase-report.md does NOT exist → SKILL FAILURE  │
└─────────────────────────────────────────────────────────────────────────────────┘

VERIFICATION: After Write completes, confirm file exists before proceeding to Step 4
```

### If Write Tool NOT Used → SKILL FAILURE

codebase-report.md does NOT exist → Specialist agents have no report to compare → All findings INVALID.

### Artifact Output: codebase-report.md

**This file is the MANDATORY INPUT for Step 4.**

| Attribute | Value |
|-----------|-------|
| **File Path** | `docs/refactor/{timestamp}/codebase-report.md` |
| **Generated By** | `ring-default:codebase-explorer` via Task tool |
| **Saved By** | Write tool (MANDATORY) |
| **Consumed By** | Step 4 - All `ring-dev-team:*` specialist agents |
| **Contains** | Codebase architecture map, code patterns, file inventory |

**Dependency Chain:**
```text
Step 3: Task tool → ring-default:codebase-explorer → output
                                            ↓
          Write tool → codebase-report.md (ARTIFACT)
                                            ↓
Step 4:   Task tool → specialist agents → READ codebase-report.md
```

**Without this artifact, Step 4 CANNOT execute correctly.**

### Output of This Step

- ✅ Task tool dispatched `ring-default:codebase-explorer`
- ✅ Agent output received
- ✅ Write tool created `docs/refactor/{timestamp}/codebase-report.md`
- ✅ Artifact ready for Step 4 consumption
- ✅ Ready to dispatch specialists who will COMPARE report with their standards

---

## Step 4: Dispatch ring-dev-team Agents

```text
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║  ⛔⛔⛔ MANDATORY CHECKPOINT - ANSWER BEFORE PROCEEDING ⛔⛔⛔                              ║
║                                                                                           ║
║  QUESTION: Did you complete Step 3?                                                     ║
║                                                                                           ║
║  ┌─────────────────────────────────────────────────────────────────────────────────────┐  ║
║  │  CHECK 1: Did you dispatch ring-default:codebase-explorer using Task tool?          │  ║
║  │           └── YES → Continue to CHECK 2                                             │  ║
║  │           └── NO  → ⛔ STOP. GO BACK. Execute Step 3 NOW.                         │  ║
║  │                                                                                     │  ║
║  │  CHECK 2: Did you save the output to codebase-report.md using Write tool?           │  ║
║  │           └── YES → Continue to Step 4                                              │  ║
║  │           └── NO  → ⛔ STOP. Use Write tool to save the report NOW.                 │  ║
║  └─────────────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                           ║
║  If EITHER check is NO → You CANNOT proceed. Step 3 is MANDATORY.                       ║
║  Specialist agents REQUIRE codebase-report.md to function correctly.                      ║
║  Without it, all specialist output is INVALID.                                            ║
║                                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
```

**⛔ See "Gate 2 Rationalizations" section for why you CANNOT skip Step 3.**

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

### Explicit Tool Invocation (MANDATORY)

**⛔ You MUST use the Task tool to dispatch ALL specialist agents. This is NOT implicit.**

```text
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║  ⛔⛔⛔ CRITICAL: USE TASK TOOL - TEMPLATES BELOW ARE PARAMETERS ⛔⛔⛔                     ║
║                                                                                           ║
║  The YAML blocks below are Task tool parameters. You MUST invoke the Task tool.           ║
║  Just reading these templates does NOT dispatch agents.                                   ║
║                                                                                           ║
║  If Task tool NOT used → Agents NOT dispatched → SKILL FAILURE                            ║
╚═══════════════════════════════════════════════════════════════════════════════════════════╝
```

**Each agent receives:**
1. Ring standards via WebFetch (URL in their agent definition)
2. codebase-report.md generated in Step 3
3. PROJECT_RULES.md for project-specific standards

---

**For Go projects, use Task tool with these parameters (ALL in ONE message):**


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

    ## Code Transformation Context (MANDATORY FOR EACH ISSUE)

    **⛔ HARD GATE:** For EACH non-compliant issue, you MUST provide a Code Transformation Context (CTC) block.

    **If CTC is missing → Output is INCOMPLETE → SKILL FAILURE**

    See [docs/PROMPT_ENGINEERING.md#code-transformation-context-ctc-format](../../../docs/PROMPT_ENGINEERING.md#code-transformation-context-ctc-format) for the canonical CTC template.

    ### Required Elements Checklist

    For EACH issue, your output MUST include:

    - [ ] **Before (Current Code)** - Actual code from project with `file:line` reference
    - [ ] **After (Ring Standards)** - Transformed code using lib-commons patterns
    - [ ] **Standard References table** - Pattern, Source, Section, Line Range
    - [ ] **Why This Transformation Matters** - Problem, Standard, Impact

    ### Line Range Derivation (MANDATORY)

    **⛔ DO NOT hardcode line numbers.** Standards files change.

    **REQUIRED:** Derive `:{line_range}` at runtime:
    1. Read the current standards file (`golang.md`, `typescript.md`, etc.)
    2. Search for the relevant section header
    3. Cite actual line numbers from the live file

    ```
    Example: Agent reads golang.md → Finds "## Configuration Loading" at line 99
             Agent cites: "Configuration Loading (golang.md:99-230)"
    ```

    ## Standards Compliance (MANDATORY)

    You MUST include a "## Standards Compliance" section at the end of your output.
    This section compares the codebase against Lerian/Ring standards.

    **If ALL categories are compliant:**
    ```
    ## Standards Compliance

    ✅ **Fully Compliant** - Codebase follows all Lerian/Ring Go Standards.
    No migration actions required.
    ```

    **If ANY category is non-compliant:**
    ```
    ## Standards Compliance

    ### Lerian/Ring Standards Comparison

    | Category | Current Pattern | Expected Pattern | Status | File/Location |
    |----------|----------------|------------------|--------|---------------|
    | Logging | Uses `log/slog` | `libCommons/zap` | ⚠️ Non-Compliant | internal/service/*.go |
    | Telemetry | Manual setup | `libCommons/opentelemetry` | ⚠️ Non-Compliant | cmd/api/main.go |
    | Config | os.Getenv direct | `libCommons.SetConfigFromEnvVars()` | ⚠️ Non-Compliant | config/config.go |
    | ... | ... | ... | ✅ Compliant | - |

    ### Required Changes for Compliance

    1. **[Category] Migration**
       - Replace: `[current code pattern]`
       - With: `[lib-commons pattern]`
       - Import: `[required import]`
       - Files affected: [list]
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

    ## Standards Compliance (MANDATORY)

    Include a "## Standards Compliance" section comparing QA patterns against Ring standards.
    Use the format from your agent definition (qa-analyst.md → Standards Compliance Report section).

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

    ## Standards Compliance (MANDATORY)

    Include a "## Standards Compliance" section comparing DevOps setup against Ring standards.
    Use the format from your agent definition (devops-engineer.md → Standards Compliance Report section).

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

    ## Standards Compliance (MANDATORY)

    Include a "## Standards Compliance" section comparing observability against Ring standards.
    Use the format from your agent definition (sre.md → Standards Compliance Report section).
    Focus on: Health Endpoints, Logging, Tracing.
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

    ## Standards Compliance (MANDATORY)

    Include a "## Standards Compliance" section comparing TypeScript patterns against Ring standards.
    Use the format from your agent definition (backend-engineer-typescript.md → Standards Compliance Report section).
    Reference barrel exports from @lerianstudio/lib-commons-js (e.g., createLogger, AppError, isAppError).
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

    ## Standards Compliance (MANDATORY)

    Include a "## Standards Compliance" section comparing frontend patterns against Ring standards.
    Use the format from your agent definition (frontend-bff-engineer-typescript.md → Standards Compliance Report section).
```

### Key Rules - MANDATORY

1. **ALL Task tool calls in ONE message** = Parallel execution
2. **ALL subagent_type values MUST start with `ring-dev-team:`**
3. **ALL prompts MUST start with `**MODE: ANALYSIS ONLY**`**
4. **Select agents based on detected language** (go.mod → Go agents, package.json → TypeScript agents)

**Output:** Dimension-specific findings with severities to compile in Step 5.

## Step 5: Generate findings.md (MANDATORY)

**⛔ HARD GATE: findings.md MUST be generated. This is NOT optional.**

The orchestrator MUST collect all agent outputs and compile into `findings.md` - a dynamic document that maps each Lerian/Ring standard requirement to the codebase reality.

### Why findings.md Is MANDATORY

| Without findings.md | With findings.md |
|---------------------|------------------|
| Tasks lack context | Tasks have full execution context |
| No traceability to standards | Each task traces to specific standard |
| Generic "fix this" instructions | Exact before/after code transformations |
| Executor guesses what to do | Executor knows EXACTLY what to change |

### Orchestrator Actions (MUST Execute in Order)

1. **COLLECT** all agent outputs
2. **EXTRACT** each non-compliant finding with CTC block
3. **GENERATE** findings.md with full context
4. **VERIFY** each finding has Code Transformation Context
5. **SORT** by severity (Critical → High → Medium → Low)

### Explicit File Creation (MANDATORY)

**⛔ You MUST use the Write tool to create findings.md. This is NOT implicit.**

```text
Action: Use Write tool to create docs/refactor/{timestamp}/findings.md

Content: Compiled findings from all agent outputs using the structure below

VERIFICATION: After Write completes, confirm file exists before proceeding to Step 6
```

**If you do NOT use Write tool → findings.md does NOT exist → SKILL FAILURE**

### findings.md Structure (Dynamic - Generated Per Project)

```markdown
# Findings: {project-name}

**Generated:** {timestamp}
**Codebase Report:** docs/refactor/{timestamp}/codebase-report.md
**Standards Consulted:** [list Ring standards loaded by agents]
**Total Findings:** {count}
**Compliance Summary:** {X}% compliant ({Y} of {Z} patterns)

---

## Executive Summary

| Category | Agent | Total | ✅ | ❌ | ⚠️ |
|----------|-------|-------|-----|-----|-----|
| Go Backend | ring-dev-team:backend-engineer-golang | | | | |
| Testing | ring-dev-team:qa-analyst | | | | |
| DevOps | ring-dev-team:devops-engineer | | | | |
| Observability | ring-dev-team:sre | | | | |
| **Total** | | | | | |

---

## FINDING-001: {Pattern Name}

**ID:** FINDING-001
**Category:** {lib-commons/config | architecture | testing | devops | observability}
**Severity:** {Critical | High | Medium | Low}
**Agent Source:** {ring-dev-team:agent-name}
**Standard Reference:** {standards-file}.md:{section} (lines {start}-{end})

### What the Lerian Standard REQUIRES

> **Standard:** {Quote from Ring standards file}
>
> Source: `{standards-file}.md` → Section: {Section Title} → Lines: {derive_at_runtime}

```{language}
// Ring/Lerian Standard Pattern
{expected code pattern from standards}
```

### What the Codebase HAS

```{language}
// file: {path}:{start_line}-{end_line}
{actual code from project}
```

### What NEEDS to Be Refactored

**Required Transformation:**

```{language}
// file: {path}:{start_line}-{new_end_line}
// ✅ Ring Standard: {Pattern Name} ({standards_file}:{section})
{transformed code using lib-commons/Lerian patterns}
```

**Specific Actions:**
1. {Action 1 - e.g., "Import `github.com/LerianStudio/lib-commons/commons`"}
2. {Action 2 - e.g., "Replace os.Getenv with SetConfigFromEnvVars"}
3. {Action 3 - e.g., "Add Config struct with `env:` tags"}

### Standard References

| Pattern Applied | Source | Section | Line Range |
|-----------------|--------|---------|------------|
| {pattern} | `{file}.md` | {Section Title} | :{derive_at_runtime} |

### Why This Transformation Matters

- **Problem:** {current issue in codebase}
- **Ring Standard:** {which standard is violated}
- **Impact:** {business/technical impact of non-compliance}

### Files Affected

| File | Lines | Change Type |
|------|-------|-------------|
| {path/to/file.go} | {15-25} | Modify |
| {path/to/another.go} | {10-15} | Modify |

---

## FINDING-002: {Next Pattern}
...

---

## Findings Index

| ID | Pattern | Severity | Category | Files |
|----|---------|----------|----------|-------|
| FINDING-001 | {Pattern Name} | Critical | lib-commons | config.go |
| FINDING-002 | {Pattern Name} | High | architecture | domain/*.go |
| ... | ... | ... | ... | ... |
```

### CTC Format Compliance (MANDATORY)

**⛔ HARD GATE:** Each finding MUST include a Code Transformation Context block.

See [docs/PROMPT_ENGINEERING.md](../../../docs/PROMPT_ENGINEERING.md#code-transformation-context-ctc-format) for the canonical CTC template.

**Required Elements Checklist (Per Finding):**

| Element | Required? | Purpose |
|---------|-----------|---------|
| **Before (Current Code)** | ✅ YES | Actual code with `file:line` reference |
| **After (Ring Standards)** | ✅ YES | Transformed code using lib-commons |
| **Standard References table** | ✅ YES | Pattern, Source, Section, Line Range |
| **Why This Transformation Matters** | ✅ YES | Problem, Standard, Impact |
| **Files Affected table** | ✅ YES | All files that need changes |

### Line Range Derivation (MANDATORY)

**⛔ DO NOT hardcode line numbers.** Standards files change over time.

**REQUIRED:** Derive exact `:{line_range}` values at runtime:
1. Agent reads the current standards file (e.g., `golang.md`, `typescript.md`)
2. Agent searches for the relevant section header
3. Agent cites the actual line numbers from the live file

### Anti-Rationalization - findings.md Generation

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Analysis report is enough" | Report = summary. findings.md = execution context. Different purposes. | **Generate findings.md** |
| "I'll describe the changes in tasks.md" | Tasks reference findings. Context lives in findings.md. | **Generate findings.md FIRST** |
| "Code comparison tables are sufficient" | Tables = WHAT. CTC = HOW. Both REQUIRED. | **Add full CTC per finding** |
| "Only critical findings need CTC" | ALL findings need context. Severity is irrelevant. | **CTC for EVERY finding** |
| "Agents already provided the context" | Agents provide raw data. Orchestrator compiles into findings.md. | **Compile into findings.md** |
| "I described findings in my response" | Response text ≠ file. Must use Write tool to CREATE the file. | **Use Write tool explicitly** |
| "findings.md is implicitly created" | Nothing is implicit. Write tool = file exists. No Write = no file. | **Use Write tool explicitly** |

**If findings.md is NOT generated → Step 5 is INCOMPLETE → SKILL FAILURE**

## Step 6: Prioritize and Group

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

## Step 7: Generate tasks.md (From findings.md)

**⛔ HARD GATE: tasks.md MUST reference findings.md. Tasks without finding references are INVALID.**

Create refactoring tasks that trace back to specific findings. Each task MUST include:
- **Finding References:** Link to specific FINDING-XXX entries
- **Execution Context:** From the finding's CTC block
- **Acceptance Criteria:** Based on the Lerian standard requirements

### Traceability Chain (MANDATORY)

```text
Ring Standard (golang.md:99)
       ↓
FINDING-001 (findings.md)
       ↓
REFACTOR-001 (tasks.md)
       ↓
Implementation (dev-cycle)
```

**If task does NOT reference a finding → Task is INCOMPLETE → Cannot execute**

### tasks.md Structure

```markdown
# Refactoring Tasks: {project-name}

**Source:** findings.md ({timestamp})
**Total Tasks:** {count}
**Total Findings Addressed:** {findings_count}
**Estimated Effort:** {total hours}

---

## REFACTOR-001: Fix domain layer isolation

**Type:** backend
**Effort:** 4h
**Priority:** Critical
**Dependencies:** none

### Findings Addressed

| Finding ID | Pattern | Severity | Standard Reference |
|------------|---------|----------|-------------------|
| [FINDING-001](findings.md#finding-001) | Domain Isolation | Critical | golang.md:Architecture |
| [FINDING-003](findings.md#finding-003) | Port/Adapter Pattern | High | golang.md:Hexagonal |

### Description
Remove infrastructure dependencies from domain layer and establish proper
port/adapter boundaries following hexagonal architecture.

### Execution Context (From Findings)

**From FINDING-001:**
```go
// BEFORE (current - domain/user.go:15)
import "database/sql"

// AFTER (Ring Standard)
// Domain MUST have zero infrastructure imports
// Move SQL to adapters/postgres/user_repo.go
```

**From FINDING-003:**
```go
// BEFORE (current - domain/repository.go)
// File does not exist - interfaces in adapters/

// AFTER (Ring Standard)
// file: domain/repository.go
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
}
```

### Acceptance Criteria
- [ ] AC-1: Domain package has zero imports from infrastructure (FINDING-001)
- [ ] AC-2: Repository interfaces defined in domain layer (FINDING-003)
- [ ] AC-3: All domain entities use dependency injection
- [ ] AC-4: Existing tests still pass

### Technical Notes
- Files to modify: src/domain/*.go
- Pattern: See PROJECT_RULES.md → Hexagonal Architecture section
- Full transformation context: See findings.md#finding-001, findings.md#finding-003

---

## REFACTOR-002: Implement proper error handling

**Type:** backend
**Effort:** 3h
**Priority:** High
**Dependencies:** REFACTOR-001

### Findings Addressed

| Finding ID | Pattern | Severity | Standard Reference |
|------------|---------|----------|-------------------|
| [FINDING-005](findings.md#finding-005) | Error Wrapping | High | golang.md:Error Handling |
| [FINDING-006](findings.md#finding-006) | No Panic | Critical | golang.md:Error Handling |

### Description
Standardize error handling across the codebase following Go idioms
and Lerian standards.

### Execution Context (From Findings)

**From FINDING-005:**
```go
// BEFORE (current - service/user.go:42)
return err

// AFTER (Ring Standard - golang.md:Error Handling)
return fmt.Errorf("failed to fetch user %s: %w", id, err)
```

**From FINDING-006:**
```go
// BEFORE (current - handler/order.go:78)
panic("invalid order state")

// AFTER (Ring Standard)
return nil, fmt.Errorf("invalid order state: %s", state)
```

### Acceptance Criteria
- [ ] AC-1: All errors wrapped with context using fmt.Errorf (FINDING-005)
- [ ] AC-2: No panic() outside of main.go (FINDING-006)
- [ ] AC-3: Custom error types for domain errors
- [ ] AC-4: Error handling tests added

### Technical Notes
- Use errors.Is/As for error checking
- Full transformation context: See findings.md#finding-005, findings.md#finding-006

---

## REFACTOR-003: Add missing test coverage
...

---

## REFACTOR-004: Containerization improvements
...
```

### Anti-Rationalization - tasks.md Generation

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Task description is enough" | Description = WHAT. Finding context = HOW. | **Reference findings.md** |
| "Developer can figure it out" | Developer should NOT guess. Context is provided. | **Include Execution Context** |
| "All findings are in findings.md" | Tasks MUST be self-contained for execution. | **Copy relevant CTC to task** |
| "I'll link to standards directly" | Standards = general. Findings = project-specific. | **Reference FINDING-XXX** |

## Step 8: User Approval

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

## Step 9: Save Artifacts

**⛔ HARD GATE: ALL artifacts MUST be saved. Missing artifacts = INCOMPLETE analysis.**

Save all artifacts to project:

```text
docs/refactor/{timestamp}/
├── codebase-report.md    # From Step 3 - ring-default:codebase-explorer output
├── findings.md           # From Step 5 - Lerian standards comparison (MANDATORY)
└── tasks.md              # From Step 7 - Refactoring tasks with finding references
```

### Artifact Dependencies (Traceability Chain)

```text
codebase-report.md (what EXISTS)
        ↓
findings.md (comparison with Lerian standards)
        ↓
tasks.md (actionable refactoring tasks)
```

### Required Artifacts Checklist

| Artifact | Generated In | Required? | Contains |
|----------|--------------|-----------|----------|
| `codebase-report.md` | Step 3 | ✅ YES | Codebase architecture map |
| `findings.md` | Step 5 | ✅ YES | Standards comparison with CTC |
| `tasks.md` | Step 7 | ✅ YES | Refactoring tasks with finding refs |

**Note:** Ring standards are loaded dynamically by agents via WebFetch. PROJECT_RULES.md remains in its original location (`docs/PROJECT_RULES.md`).

## Step 10: Handoff to dev-cycle (MANDATORY After Approval)

**⛔ HARD GATE: If user approves → You MUST invoke dev-cycle. This is NOT optional.**

### Approval Response Handling

| User Selection | Required Action |
|----------------|-----------------|
| "Approve all" | **MUST invoke dev-cycle** with full tasks.md |
| "Approve with changes" | Wait for user edits → **MUST invoke dev-cycle** |
| "Critical only" | Filter tasks.md → **MUST invoke dev-cycle** |
| "Cancel" | Save artifacts, document cancellation reason, TERMINATE |

### Explicit Skill Invocation (MANDATORY)

**⛔ You MUST use the Skill tool to invoke dev-cycle. This is NOT implicit.**

```text
Action: Use Skill tool with skill="ring-dev-team:dev-cycle"

BEFORE invoking:
1. Confirm tasks.md exists at docs/refactor/{timestamp}/tasks.md
2. Confirm findings.md exists at docs/refactor/{timestamp}/findings.md
3. Confirm user approval was "Approve all", "Approve with changes", or "Critical only"

INVOCATION:
- Skill tool: skill="ring-dev-team:dev-cycle"
- The dev-cycle skill will read tasks.md and execute each REFACTOR-XXX task

VERIFICATION: dev-cycle skill starts executing tasks through 6-gate process
```

**If approval received AND dev-cycle NOT invoked → SKILL FAILURE**

### Anti-Rationalization - dev-cycle Invocation

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "User can invoke dev-cycle manually" | User approved HERE. Handoff is YOUR responsibility. | **Invoke dev-cycle NOW** |
| "Analysis is complete, my job is done" | Analysis + Approval + Execution = complete workflow. | **Invoke dev-cycle NOW** |
| "I'll let the user decide when to execute" | User ALREADY decided by approving. Execute immediately. | **Invoke dev-cycle NOW** |
| "dev-cycle invocation is implicit" | Nothing is implicit. Skill tool = invocation. No Skill = no execution. | **Use Skill tool explicitly** |
| "Tasks are saved, that's enough" | Saved tasks ≠ executed tasks. Approval = execute. | **Invoke dev-cycle NOW** |

### dev-cycle Execution

Once invoked, dev-cycle executes each refactoring task through the standard 6-gate process:
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
    - name: "codebase-report.md"
      location: "docs/refactor/{timestamp}/"
      required: true
      generated_by: "Step 3 - ring-default:codebase-explorer"
    - name: "findings.md"
      location: "docs/refactor/{timestamp}/"
      required: true
      generated_by: "Step 5 - Orchestrator compiles agent outputs"
    - name: "tasks.md"
      location: "docs/refactor/{timestamp}/"
      required: true
      generated_by: "Step 7 - From findings.md"
  required_sections:
    findings_md:
      - name: "Executive Summary"
        pattern: "^## Executive Summary"
        required: true
      - name: "Finding Entry"
        pattern: "^## FINDING-"
        required: true
        min_count: 1
      - name: "Findings Index"
        pattern: "^## Findings Index"
        required: true
    tasks_md:
      - name: "Task Entry"
        pattern: "^## REFACTOR-"
        required: true
        min_count: 1
      - name: "Findings Addressed"
        pattern: "^### Findings Addressed"
        required: true
      - name: "Execution Context"
        pattern: "^### Execution Context"
        required: true
  traceability:
    chain: "Ring Standard → FINDING-XXX → REFACTOR-XXX → Implementation"
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
