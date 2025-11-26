---
name: using-ring
description: Use when starting any conversation - establishes mandatory workflows for finding and using skills, including using Skill tool before announcing usage, following brainstorming before coding, and creating TodoWrite todos for checklists
when_to_use: Use when starting any conversation - establishes mandatory workflows for finding and using skills, including using Skill tool before announcing usage, following brainstorming before coding, and creating TodoWrite todos for checklists
---

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST read the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

# Getting Started with Skills

## MANDATORY FIRST RESPONSE PROTOCOL

Before responding to ANY user message, you MUST complete this checklist:

1. ☐ **Check for MANDATORY-USER-MESSAGE** - If additionalContext contains `<MANDATORY-USER-MESSAGE>` tags, display the message FIRST, verbatim, at the start of your response
2. ☐ List available skills in your mind
3. ☐ Ask yourself: "Does ANY skill match this request?"
4. ☐ If yes → Use the Skill tool to read and run the skill file
5. ☐ Announce which skill you're using (when non-obvious)
6. ☐ Follow the skill exactly

**Responding WITHOUT completing this checklist = automatic failure.**

### MANDATORY-USER-MESSAGE Contract

When SessionStart hook additionalContext contains `<MANDATORY-USER-MESSAGE>` tags:

- ✅ **MUST display verbatim** - No paraphrasing, summarizing, or modification
- ✅ **MUST display in first response** - Cannot wait for "relevant context"
- ✅ **MUST display at message start** - Before any other content
- ❌ **MUST NOT skip** - No rationalization ("not relevant", "will mention later")

**Example:**

```
Hook additionalContext contains:
<MANDATORY-USER-MESSAGE>
You MUST display the following message verbatim to the user:

╔═══════════════════════════════════════════════════════════╗
║  🔄 MARKETPLACE UPDATE - ACTION REQUIRED                  ║
╚═══════════════════════════════════════════════════════════╝

</MANDATORY-USER-MESSAGE>

Your response:
╔═══════════════════════════════════════════════════════════╗
║  🔄 MARKETPLACE UPDATE - ACTION REQUIRED                  ║
╚═══════════════════════════════════════════════════════════╝

Now, regarding your question about...
```

## Critical Rules

1. **Follow mandatory workflows.** Brainstorming before coding. Check for relevant skills before ANY task.

2. Execute skills with the Skill tool

## Common Rationalizations That Mean You're About To Fail

If you catch yourself thinking ANY of these thoughts, STOP. You are rationalizing. Check for and use the skill. Also check: are you being an OPERATOR instead of ORCHESTRATOR?

**Skill Checks:**
- "This is just a simple question" → WRONG. Questions are tasks. Check for skills.
- "This doesn't need a formal skill" → WRONG. If a skill exists for it, use it.
- "I remember this skill" → WRONG. Skills evolve. Run the current version.
- "This doesn't count as a task" → WRONG. If you're taking action, it's a task. Check for skills.
- "The skill is overkill for this" → WRONG. Skills exist because simple things become complex. Use it.
- "I'll just do this one thing first" → WRONG. Check for skills BEFORE doing anything.
- "I need context before checking skills" → WRONG. Gathering context IS a task. Check for skills first.

**Orchestrator Breaks (Direct Tool Usage):**
- "I can check git/files quickly" → WRONG. Use agents, stay ORCHESTRATOR.
- "Let me gather information first" → WRONG. Dispatch agent to gather it.
- "Just a quick look at files" → WRONG. That "quick" becomes 20k tokens. Use agent.
- "I'll scan the codebase manually" → WRONG. That's operator behavior. Use Explore.
- "This exploration is too simple for an agent" → WRONG. Simplicity makes agents more efficient.
- "I already started reading files" → WRONG. Stop. Dispatch agent instead.
- "It's faster to do it myself" → WRONG. You're burning context. Agents are 15x faster contextually.

**Why:** Skills document proven techniques. Agents preserve context. Not using them means repeating mistakes and wasting tokens.

**Both matter:** Skills check is mandatory. ORCHESTRATOR approach is mandatory.

If a skill exists or if you're about to use tools directly, you must use the proper approach or you will fail.

## The Cost of Skipping Skills

Every time you skip checking for skills:
- You fail your task (skills contain critical patterns)
- You waste time (rediscovering solved problems)
- You make known errors (skills prevent common mistakes)
- You lose trust (not following mandatory workflows)

**This is not optional. Check for skills or fail.**

## Mandatory Skill Check Points

**Before EVERY tool use**, ask yourself:
- About to use Read? → Is there a skill for reading this type of file?
- About to use Bash? → Is there a skill for this command type?
- About to use Grep? → Is there a skill for searching?
- About to use Task? → Which subagent_type matches?

**No tool use without skill check first.**

## ORCHESTRATOR Principle: Agent-First Always

**Your role is ORCHESTRATOR, not operator.**

You don't read files, run grep chains, or manually explore – you **dispatch agents** to do the work and return results. This is not optional. This is mandatory for context efficiency.

**The Problem with Direct Tool Usage:**
- Manual exploration chains: ~30-100k tokens in main context
- Each file read adds context bloat
- Grep/Glob chains multiply the problem
- User sees work happening but context explodes

**The Solution: Orchestration:**
- Dispatch agents to handle complexity
- Agents return only essential findings (~2-5k tokens)
- Main context stays lean for reasoning
- **15x more efficient** than direct file operations

### Your Decision: Agent or Direct?

**Use agents for:**
- Any exploration of codebase structure
- Understanding architecture or patterns
- Finding files/code by keyword
- Multi-step research or analysis
- Code review or quality assessment
- Implementation planning
- Architectural decisions
- Anything requiring 2+ tool calls

**Use direct Read ONLY for:**
- ONE specific known file path you can name right now
- File you can describe precisely: "the MANUAL.md at root"
- You cannot go exploring after reading it (no chain reactions)

**Default answer when uncertain:** Use an agent.

### Available Agents

#### Built-in Agents (Claude Code)
| Agent | Purpose |
|-------|---------|
| `Explore` | Codebase navigation & discovery |
| `general-purpose` | Multi-step research |
| `Plan` | Implementation planning |
| `claude-code-guide` | Claude Code documentation |

#### Ring Agents (Specialized)
| Agent | Purpose |
|-------|---------|
| `ring-default:code-reviewer` | Architecture & patterns |
| `ring-default:business-logic-reviewer` | Correctness & requirements |
| `ring-default:security-reviewer` | Security & OWASP |
| `ring-default:write-plan` | Implementation planning |

### Decision: Which Agent?

**Don't ask "should I use an agent?" Ask "which agent?"**

```
START: I need to do something with the codebase

├─▶ Explore/find/understand code
│   └─▶ Use Explore agent
│
├─▶ Multi-step research or investigation
│   └─▶ Use general-purpose agent
│
├─▶ Review code quality
│   └─▶ Use ALL THREE in parallel:
│       • code-reviewer
│       • business-logic-reviewer
│       • security-reviewer
│
├─▶ Create implementation tasks
│   └─▶ Use write-plan agent
│
├─▶ Question about Claude Code
│   └─▶ Use claude-code-guide agent
│
└─▶ I have ONE specific file path memorized
    └─▶ Read directly (and ONLY that file)
```

### Anti-Patterns: Context Sabotage

These mean you're breaking the ORCHESTRATOR role and burning context:

- "I'll quickly grep for X" → WRONG. Use Explore agent.
- "Let me scan a few files" → WRONG. Use Explore agent.
- "I need context first, then delegate" → WRONG. Delegate first, agent returns context.
- "I'll do a quick manual check" → WRONG. That "quick" becomes 20k tokens.
- "I already started reading files" → WRONG. Stop, dispatch agent instead.
- "Finding the right file is easier by hand" → WRONG. That's what Explore does.
- "I'll just peek at the structure" → WRONG. Use Explore agent.
- "This doesn't need an agent" → WRONG. If you're unsure, use one.

### Ring Reviewers: ALWAYS Parallel

When dispatching code reviewers, **single message with 3 Task calls:**

```
✅ CORRECT: One message with 3 Task calls (all in parallel)
❌ WRONG: Three separate messages (sequential, 3x slower)
```

### Context Efficiency: Orchestrator Wins

| Approach | Context Cost | Your Role |
|----------|--------------|-----------|
| Manual file reading (5 files) | ~25k tokens | Operator |
| Manual grep chains (10 searches) | ~50k tokens | Operator |
| Explore agent dispatch | ~2-3k tokens | Orchestrator |
| **Savings** | **15-25x more efficient** | **Orchestrator always wins** |

## Skills with Checklists

If a skill has a checklist, YOU MUST create TodoWrite todos for EACH item.

**Don't:**
- Work through checklist mentally
- Skip creating todos "to save time"
- Batch multiple items into one todo
- Mark complete without doing them

**Why:** Checklists without TodoWrite tracking = steps get skipped. Every time. The overhead of TodoWrite is tiny compared to the cost of missing steps.

## TodoWrite Requirement

When starting ANY task:
1. First todo: "Check for relevant skills"
2. Mark complete only after actual check
3. Document which skills apply/don't apply

Skipping this todo = automatic failure.

### MANDATORY-USER-MESSAGE TodoWrite Integration

When SessionStart hook additionalContext contains `<MANDATORY-USER-MESSAGE>` tags:

**MUST create todo:**
1. Todo content: "Display MANDATORY-USER-MESSAGE to user"
2. Status: `in_progress` (immediately)
3. Mark `completed` ONLY after displaying it verbatim

**Verification workflow:**
```
Hook additionalContext contains <MANDATORY-USER-MESSAGE>
  ↓
Create todo: "Display MANDATORY-USER-MESSAGE"
  ↓
Display message verbatim to user (content between the tags)
  ↓
Mark todo as completed
```

**This creates an audit trail** - TodoWrite tracking makes message display verifiable, not just a mental checklist item.

## Announcing Skill Usage

**Announce skill usage when the choice is non-obvious to the user.**

"I'm using [Skill Name] to [what you're doing]."

### When to Announce

**Announce when:**
- Skill choice isn't obvious from user's request
- Multiple skills could apply (explain why you picked this one)
- Using a meta-skill (brainstorming, writing-plans, systematic-debugging)
- User might not know this skill exists

**Examples:**
- User: "This auth bug is weird" → Announce: "I'm using systematic-debugging to investigate..."
- User: "Let's add user profiles" → Announce: "I'm using brainstorming to refine this into a design..."
- User: "Help me plan this feature" → Announce: "I'm using pre-dev-prd-creation to start the planning workflow..."

**Don't announce when obvious:**
- User: "Write tests first" → Don't announce test-driven-development (duh)
- User: "Review my code" → Don't announce requesting-code-review (obvious)
- User: "Fix this bug" + you're gathering evidence → Don't announce systematic-debugging (expected)
- User: "Run the build and verify it works" → Don't announce verification-before-completion (explicit)

**Why announce:** Transparency helps your human partner understand your process when it's not obvious from their request. It also confirms you actually read the skill.

**Why skip when obvious:** Reduces ceremony, respects user's time, avoids "well duh" moments.

## Pre-Dev Track Selection

**Before starting pre-dev workflow, choose your track:**

### Small Track (3 gates) - <2 Day Features

**Use when feature meets ALL criteria:**
- ✅ Implementation: <2 days
- ✅ No new external dependencies
- ✅ No new data models/entities
- ✅ No multi-service integration
- ✅ Uses existing architecture patterns
- ✅ Single developer can complete

**Gates:**
1. **pre-dev-prd-creation** - Business requirements (WHAT/WHY)
2. **pre-dev-trd-creation** - Technical architecture (HOW)
3. **pre-dev-task-breakdown** - Work increments

**Planning time:** 30-60 minutes

**Examples:**
- Add logout button to UI
- Fix email validation bug
- Add API rate limiting to existing endpoint

### Large Track (8 gates) - ≥2 Day Features

**Use when feature has ANY:**
- ❌ Implementation: ≥2 days
- ❌ New external dependencies (APIs, databases, libraries)
- ❌ New data models or entities
- ❌ Multi-service integration
- ❌ New architecture patterns
- ❌ Team collaboration required

**Gates:**
1. **pre-dev-prd-creation** - Business requirements
2. **pre-dev-feature-map** - Feature relationships
3. **pre-dev-trd-creation** - Technical architecture
4. **pre-dev-api-design** - Component contracts
5. **pre-dev-data-model** - Entity relationships
6. **pre-dev-dependency-map** - Technology selection
7. **pre-dev-task-breakdown** - Work increments
8. **pre-dev-subtask-creation** - Atomic units

**Planning time:** 2-4 hours

**Examples:**
- Add user authentication
- Implement payment processing
- Add file upload with CDN

### Decision Rule

**When in doubt: Use Large Track.**

Better to over-plan than discover mid-implementation that feature is larger than estimated.

**Can switch tracks:** If Small Track feature grows during implementation, pause and complete remaining Large Track gates.

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.

# About these skills

**Many skills contain rigid rules (TDD, debugging, verification).** Follow them exactly. Don't adapt away the discipline.

**Some skills are flexible patterns (architecture, naming).** Adapt core principles to your context.

The skill itself tells you which type it is.

## Instructions ≠ Permission to Skip Workflows

Your human partner's specific instructions describe WHAT to do, not HOW.

"Add X", "Fix Y" = the goal, NOT permission to skip brainstorming, TDD, or RED-GREEN-REFACTOR.

**Red flags:** "Instruction was specific" • "Seems simple" • "Workflow is overkill"

**Why:** Specific instructions mean clear requirements, which is when workflows matter MOST. Skipping process on "simple" tasks is how simple tasks become complex problems.

## Summary

**Starting any task:**
1. If relevant skill exists → Use the skill
3. Announce you're using it
4. Follow what it says

**Skill has checklist?** TodoWrite for every item.

**Finding a relevant skill = mandatory to read and use it. Not optional.**
