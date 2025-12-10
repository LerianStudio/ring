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

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║  ⛔⛔⛔ CRITICAL: READ BEFORE DOING ANYTHING ⛔⛔⛔                            ║
║                                                                               ║
║  THIS SKILL HAS 2 HARD GATES THAT WILL FAIL YOUR EXECUTION:                   ║
║                                                                               ║
║  GATE 0: PROJECT_RULES.md must exist → Or TERMINATE immediately               ║
║  GATE 2: ONLY ring-dev-team:* agents allowed → Explore/general-purpose = FAIL ║
║                                                                               ║
║  FORBIDDEN AGENTS (using ANY = SKILL FAILURE):                                ║
║  ❌ Explore                                                                   ║
║  ❌ general-purpose                                                           ║
║  ❌ ring-default:codebase-explorer                                            ║
║  ❌ ANY agent without "ring-dev-team:" prefix                                 ║
║                                                                               ║
║  REQUIRED AGENTS (use ONLY these):                                            ║
║  ✅ ring-dev-team:backend-engineer-golang                                     ║
║  ✅ ring-dev-team:backend-engineer-typescript                                 ║
║  ✅ ring-dev-team:frontend-bff-engineer-typescript                            ║
║  ✅ ring-dev-team:qa-analyst                                                  ║
║  ✅ ring-dev-team:devops-engineer                                             ║
║  ✅ ring-dev-team:sre                                                         ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

This skill analyzes an existing codebase to identify gaps between current implementation and project standards, then generates a structured refactoring plan compatible with the dev-cycle workflow.

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

## ⛔ STEP 1.5: AGENT DISPATCH VALIDATION (EXECUTE BEFORE ANY DISPATCH)

**THIS VALIDATION IS MANDATORY. Execute BEFORE calling ANY Task tool.**

### Pre-Dispatch Self-Check

**Before EVERY Task tool call, you MUST ask yourself:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  ⛔ MANDATORY SELF-CHECK BEFORE DISPATCH                            │
│                                                                     │
│  Am I about to dispatch ANY of these FORBIDDEN agents?              │
│                                                                     │
│  ❌ "Explore"                    → FORBIDDEN                        │
│  ❌ "general-purpose"            → FORBIDDEN                        │
│  ❌ "ring-default:codebase-explorer" → FORBIDDEN                    │
│  ❌ subagent_type WITHOUT "ring-dev-team:" prefix → FORBIDDEN       │
│                                                                     │
│  If YES to ANY → DO NOT DISPATCH. Use correct agent below.          │
└─────────────────────────────────────────────────────────────────────┘
```

### Forbidden Agents - ABSOLUTE PROHIBITION

**These agents are FORBIDDEN for dev-refactor analysis. Using them is a SKILL FAILURE:**

| FORBIDDEN Agent | Why It's Wrong | Correct Replacement |
|-----------------|----------------|---------------------|
| `Explore` | Generic, no standards knowledge | `ring-dev-team:backend-engineer-*` |
| `general-purpose` | No specialized domain knowledge | `ring-dev-team:*` agent |
| `ring-default:codebase-explorer` | Architecture-only, incomplete | `ring-dev-team:backend-engineer-*` |
| Any agent without `ring-dev-team:` prefix | Not a dev-team specialist | Use `ring-dev-team:*` |

### If You Catch Yourself Typing FORBIDDEN Agent

**STOP. Do NOT press enter. Replace with correct agent:**

```
WRONG: subagent_type: "Explore"
RIGHT: subagent_type: "ring-dev-team:backend-engineer-golang"

WRONG: subagent_type: "general-purpose"
RIGHT: subagent_type: "ring-dev-team:qa-analyst"

WRONG: subagent_type: "ring-default:codebase-explorer"
RIGHT: subagent_type: "ring-dev-team:devops-engineer"
```

### Violation Recovery

**If you ALREADY dispatched a forbidden agent:**

1. **STOP** - Do not use its output
2. **DISCARD** - The output is invalid (lacks standards)
3. **RE-DISPATCH** - Use correct `ring-dev-team:*` agent
4. **DOCUMENT** - Note: "Recovered from incorrect agent dispatch"

**Output from forbidden agents is INVALID and MUST NOT be used in analysis.**

### WHY ring-dev-team:* Agents Are REQUIRED (Technical Reason)

**The difference is NOT just naming. It's CAPABILITY:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  FORBIDDEN AGENTS (Explore, general-purpose, codebase-explorer)             │
│                                                                             │
│  ❌ Do NOT have WebFetch instructions for Ring standards                    │
│  ❌ Do NOT know Go/TypeScript/DevOps/SRE specific patterns                  │
│  ❌ Do NOT have domain expertise prompts                                    │
│  ❌ Output is GENERIC - "looks okay" instead of "violates standard X"       │
│                                                                             │
│  Result: Analysis against NOTHING. Just observations, not compliance check. │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  REQUIRED AGENTS (ring-dev-team:*)                                          │
│                                                                             │
│  ✅ HAVE WebFetch instructions to load Ring standards (golang.md, etc.)     │
│  ✅ HAVE language-specific expertise built into agent definition            │
│  ✅ HAVE domain knowledge (error handling, testing patterns, etc.)          │
│  ✅ Output is SPECIFIC - "violates golang.md section 3.2: error wrapping"   │
│                                                                             │
│  Result: Analysis against STANDARDS. Compliance check, not just observation.│
└─────────────────────────────────────────────────────────────────────────────┘
```

**Same input, DIFFERENT output:**

| Input | Explore Agent Output | ring-dev-team:backend-engineer-golang Output |
|-------|---------------------|---------------------------------------------|
| `if err != nil { return err }` | "Error is returned" | "VIOLATION: Error not wrapped with context. See golang.md §4.1" |
| Missing test file | "No test file found" | "VIOLATION: Missing test violates 80% coverage requirement. See qa-standards.md" |
| No Dockerfile | "Dockerfile not present" | "VIOLATION: Missing multi-stage Dockerfile. See devops.md §2.1" |

**This is why using forbidden agents = INVALID analysis.**

### Agent Dispatch Rationalizations - DO NOT THINK THESE

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Explore is faster for initial scan" | Speed ≠ correctness. Wrong agent = wrong analysis. | Use `ring-dev-team:*` |
| "I'll use Explore first, then specialists" | Two-pass is waste. Specialists do it right first time. | Use `ring-dev-team:*` only |
| "Explore can understand architecture" | Understanding ≠ analyzing against standards. | Use `ring-dev-team:*` |
| "general-purpose is flexible" | Flexibility ≠ domain expertise. | Use `ring-dev-team:*` |
| "codebase-explorer is for codebases" | Name doesn't matter. It lacks standards loading. | Use `ring-dev-team:*` |
| "I need to understand code first" | Specialists understand AND analyze. One step. | Use `ring-dev-team:*` |
| "Quick exploration before real analysis" | No exploration phase exists. Analysis IS the skill. | Use `ring-dev-team:*` |
| "These agents are similar enough" | Similar ≠ equivalent. Standards loading is critical. | Use `ring-dev-team:*` |

---

## ⛔ HARD GATES - READ AFTER STEP 0 PASSES

**This skill has TWO mandatory hard gates. Violation of either gate is a SKILL FAILURE.**

### Gate 1: PROJECT_RULES.md (Prerequisite) ✓

**Already validated in Step 0 above.** If you reached this section, PROJECT_RULES.md exists.

### Gate 2: Agent Dispatch (Execution)

**⛔ FORBIDDEN:** Using generic agents (`Explore`, `general-purpose`, `ring-default:codebase-explorer`) for codebase analysis.

**⛔ MANDATORY:** Use ONLY `ring-dev-team:*` specialized agents.

**⛔ See "STEP 1.5: AGENT DISPATCH VALIDATION" above for complete forbidden list and self-check.**

#### Agent Selection by Language

| Manifest Found | Language | REQUIRED Agent |
|----------------|----------|----------------|
| `go.mod` | Go | `ring-dev-team:backend-engineer-golang` |
| `package.json` + react/next/vue | Frontend TS | `ring-dev-team:frontend-bff-engineer-typescript` |
| `package.json` + express/fastify/nestjs | Backend TS | `ring-dev-team:backend-engineer-typescript` |
| `Dockerfile` only | DevOps | `ring-dev-team:devops-engineer` |
| Multiple manifests | Mixed | Dispatch ALL applicable language agents |

#### Parallel Dispatch (Step 3)

**ALL applicable ring-dev-team:* agents MUST be dispatched in a SINGLE message (parallel execution):**

```
┌─────────────────────────────────────────────────────────────┐
│  SINGLE Task tool message with ALL applicable agents:       │
│                                                             │
│  • ring-dev-team:{language-agent}  → Code/Architecture      │
│  • ring-dev-team:qa-analyst        → Testing                │
│  • ring-dev-team:devops-engineer   → DevOps                 │
│  • ring-dev-team:sre               → SRE/Observability      │
│  • (+ any other ring-dev-team:* agents relevant to task)    │
└─────────────────────────────────────────────────────────────┘
```

#### Violations - STOP IMMEDIATELY

| Violation | Why It's Wrong | Required Action |
|-----------|----------------|-----------------|
| Using `Explore` agent | Generic, lacks language-specific standards | Re-dispatch with correct agent |
| Using `general-purpose` agent | No specialized Go/TS knowledge | Re-dispatch with correct agent |
| Using `ring-default:codebase-explorer` | Architecture-only, missing code quality | Re-dispatch with correct agent |
| Dispatching agents sequentially | Wastes time, should be parallel | Re-send as single message |
| Dispatching fewer agents than needed | Incomplete analysis | Add ALL applicable agents |
| Reading >3 files directly | Violates 3-file rule | Use agents instead |

**If you already violated a gate:** STOP current approach. Re-execute with correct agents.

### Pressure Resistance - DO NOT RATIONALIZE

**If you catch yourself thinking ANY of these, STOP immediately:**

#### Agent & Execution Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Explore agent is faster" | Generic agent lacks language-specific standards | Use `ring-dev-team:*` agent |
| "I'll just read the files directly" | Violates 3-file rule, incomplete analysis | Dispatch specialized agents |
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

```
Step 0:   [ ] PROJECT_RULES.md exists? → If NO, output blocker and TERMINATE
           ⚠️ See "STEP 0: PROJECT_RULES.md VALIDATION" at top of skill

Step 1:   [ ] Language detected? → go.mod / package.json found

Step 1.5: [ ] Agent dispatch validated? → BEFORE typing Task tool:
           ⚠️ See "STEP 1.5: AGENT DISPATCH VALIDATION"
           ⚠️ Self-check: Am I dispatching Explore/general-purpose? → FORBIDDEN
           ⚠️ Self-check: Does subagent_type start with "ring-dev-team:"? → REQUIRED

Step 2:   [ ] PROJECT_RULES.md read?

Step 3:   [ ] ALL applicable ring-dev-team:* agents dispatched in SINGLE message?
           ⚠️ FORBIDDEN: Explore, general-purpose, ring-default:codebase-explorer
           ⚠️ If wrong agent used → DISCARD output, re-dispatch correct agent

Step 4:   [ ] Agent outputs compiled into analysis-report.md?
Step 5:   [ ] Findings grouped into REFACTOR-XXX tasks?
Step 6:   [ ] tasks.md generated? → If NO, skill is INCOMPLETE
Step 7:   [ ] User approval requested via AskUserQuestion?
Step 8:   [ ] Artifacts saved to docs/refactor/{timestamp}/?
Step 9:   [ ] Handoff to dev-cycle (if approved)?
```

**SKIP PREVENTION:** You CANNOT proceed to Step N+1 without completing Step N. No exceptions.

**Step 0 is NON-NEGOTIABLE:** If PROJECT_RULES.md doesn't exist, you MUST output the blocker template from the top of this skill and terminate. No rationalizations allowed.

**Step 1.5 is NON-NEGOTIABLE:** If you are about to dispatch Explore, general-purpose, or any agent without `ring-dev-team:` prefix, STOP and use the correct agent. No rationalizations allowed.

#### Prompt Prefix (REQUIRED)

All agent prompts MUST start with:
```
**MODE: ANALYSIS ONLY** - Analyze codebase for refactoring.
Return findings with: severity (Critical/High/Medium/Low), location (file:line), issue, recommendation.
```

#### WRONG vs RIGHT: Agent Dispatch Examples

**❌ WRONG - These dispatches are SKILL FAILURES:**

```yaml
# WRONG: Using Explore agent
- subagent_type: "Explore"  # ❌ FORBIDDEN - generic agent

# WRONG: Using general-purpose
- subagent_type: "general-purpose"  # ❌ FORBIDDEN - no domain expertise

# WRONG: Using codebase-explorer
- subagent_type: "ring-default:codebase-explorer"  # ❌ FORBIDDEN - no standards

# WRONG: Sequential dispatch (multiple separate messages)
# ❌ WRONG - Must be SINGLE message with ALL applicable agents in parallel
```

**✅ RIGHT - Correct dispatch pattern:**

```yaml
# SINGLE message with ALL applicable ring-dev-team:* agents in parallel:
# Dispatch EVERY agent that is relevant to the analysis dimensions needed.

# For language/code analysis (pick based on detected language):
- subagent_type: "ring-dev-team:backend-engineer-golang"      # Go projects
- subagent_type: "ring-dev-team:backend-engineer-typescript"  # TS backend
- subagent_type: "ring-dev-team:frontend-bff-engineer-typescript"  # TS frontend

# For testing analysis:
- subagent_type: "ring-dev-team:qa-analyst"

# For DevOps analysis:
- subagent_type: "ring-dev-team:devops-engineer"

# For SRE/Observability analysis:
- subagent_type: "ring-dev-team:sre"

# All prompts MUST start with:
prompt: |
  **MODE: ANALYSIS ONLY** - Analyze against PROJECT_RULES.md.
  Return: severity (Critical/High/Medium/Low), location (file:line), issue, recommendation.
```

**Key rules:**
- ✅ ALL agents MUST have `ring-dev-team:` prefix
- ✅ Dispatch ALL applicable agents in SINGLE message (parallel)
- ✅ Select language agent based on detected manifest (go.mod, package.json)
- ✅ ALL prompts start with `**MODE: ANALYSIS ONLY**`
- ✅ ALL prompts reference PROJECT_RULES.md

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
- Ready to dispatch agents with project context

## Step 3: Scan Codebase

**⛔ See "HARD GATES" section above - Gate 2 → Parallel Dispatch**

Dispatch ALL applicable ring-dev-team:* agents in a SINGLE message:
1. `ring-dev-team:{language-agent}` - Code/Architecture
2. `ring-dev-team:qa-analyst` - Testing
3. `ring-dev-team:devops-engineer` - DevOps
4. `ring-dev-team:sre` - SRE/Observability

All prompts MUST start with `**MODE: ANALYSIS ONLY**`.

**Output:** Dimension-specific findings with severities to compile in Step 4.

## Step 4: Compile Findings

**Collect outputs from all dispatched agents and merge into structured report.**

Each agent returns findings in their output. The dev-refactor skill must:
1. **Collect** all agent outputs (backend-engineer-*, qa-analyst, devops-engineer, sre)
2. **Parse** findings from each output (severity, location, issue, recommendation)
3. **Deduplicate** overlapping findings
4. **Categorize** by dimension (Architecture, Code Quality, Testing, DevOps)
5. **Sort** by severity (Critical → High → Medium → Low)

**Merge results into structured report:**

```markdown
# Analysis Report: {project-name}

**Generated:** {date}
**Standards:** {path to PROJECT_RULES.md used}
**Scope:** {directories analyzed}

## Summary

| Dimension    | Issues | Critical | High | Medium | Low |
|--------------|--------|----------|------|--------|-----|
| Architecture | 12     | 2        | 4    | 4      | 2   |
| Code Quality | 23     | 1        | 8    | 10     | 4   |
| Testing      | 8      | 3        | 3    | 2      | 0   |
| DevOps       | 5      | 0        | 2    | 2      | 1   |
| **Total**    | **48** | **6**    | **17**| **18**| **7**|

## Critical Issues (Fix Immediately)

### ARCH-001: Domain depends on infrastructure
**Location:** `src/domain/user.go:15`
**Issue:** Domain entity imports database package
**Standard:** Domain layer must have zero external dependencies
**Fix:** Extract repository interface, inject via constructor

### CODE-001: SQL injection vulnerability
**Location:** `src/handler/search.go:42`
**Issue:** User input concatenated into SQL query
**Standard:** Always use parameterized queries
**Fix:** Use query builder or prepared statements

...

## High Priority Issues
...

## Medium Priority Issues
...

## Low Priority Issues
...
```

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
