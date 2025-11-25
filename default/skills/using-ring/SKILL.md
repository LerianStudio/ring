---
name: using-ring
description: Use when starting any conversation - establishes mandatory workflows for finding and using skills, including using Skill tool before announcing usage, following brainstorming before coding, and creating TodoWrite todos for checklists
---

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST read the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

# Getting Started with Skills

## MANDATORY FIRST RESPONSE PROTOCOL

Before responding to ANY user message, you MUST complete this checklist:

1. ☐ List available skills in your mind
2. ☐ Ask yourself: "Does ANY skill match this request?"
3. ☐ If yes → Use the Skill tool to read and run the skill file
4. ☐ Announce which skill you're using
5. ☐ Follow the skill exactly

**Responding WITHOUT completing this checklist = automatic failure.**

## Critical Rules

1. **Follow mandatory workflows.** Brainstorming before coding. Check for relevant skills before ANY task.

2. Execute skills with the Skill tool

## Common Rationalizations That Mean You're About To Fail

If you catch yourself thinking ANY of these thoughts, STOP. You are rationalizing. Check for and use the skill.

- "This is just a simple question" → WRONG. Questions are tasks. Check for skills.
- "I can check git/files quickly" → WRONG. Files don't have conversation context. Check for skills.
- "Let me gather information first" → WRONG. Skills tell you HOW to gather information. Check for skills.
- "This doesn't need a formal skill" → WRONG. If a skill exists for it, use it.
- "I remember this skill" → WRONG. Skills evolve. Run the current version.
- "This doesn't count as a task" → WRONG. If you're taking action, it's a task. Check for skills.
- "The skill is overkill for this" → WRONG. Skills exist because simple things become complex. Use it.
- "I'll just do this one thing first" → WRONG. Check for skills BEFORE doing anything.
- "Let me gather information first" → WRONG. Skills tell you HOW to gather information. Check for skills.
- "I need context before checking skills" → WRONG. Gathering context IS a task. Check for skills first.
- "Just a quick look at files" → WRONG. Looking at files requires skills check first.

**Why:** Skills document proven techniques that save time and prevent mistakes. Not using available skills means repeating solved problems and making known errors.

If a skill for your task exists, you must use it or you will fail at your task.

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

## Agent-First Exploration (Context Efficiency)

**The Problem:** Direct Glob/Grep/Read chains consume 50-100k tokens in main context.
**The Solution:** Agents offload work to subagents, using only ~2k tokens in main.

### Available Agents

#### Built-in Agents (Claude Code)
| Agent | When to Use |
|-------|-------------|
| `Explore` | Codebase questions, finding files, understanding architecture |
| `general-purpose` | Complex multi-step research, tasks requiring many tool calls |
| `Plan` | Creating implementation plans, exploration before coding |
| `claude-code-guide` | Questions about Claude Code features, SDK, or capabilities |

#### Ring Agents (Custom)
| Agent | When to Use |
|-------|-------------|
| `ring-default:code-reviewer` | Review architecture, patterns, maintainability |
| `ring-default:business-logic-reviewer` | Review correctness, edge cases, requirements |
| `ring-default:security-reviewer` | Review vulnerabilities, OWASP, auth, validation |
| `ring-default:write-plan` | Generate detailed implementation plans |

### Decision Tree: Which Agent?

```
START: What am I trying to do?
│
├─▶ "Understand/explore codebase"
│   └─▶ Use `Explore` agent
│
├─▶ "Find specific code/files"
│   └─▶ Use `Explore` agent (NOT Glob/Grep chains)
│
├─▶ "Complex research with many steps"
│   └─▶ Use `general-purpose` agent
│
├─▶ "Review code for quality"
│   └─▶ Use Ring reviewers IN PARALLEL:
│       • ring-default:code-reviewer
│       • ring-default:business-logic-reviewer
│       • ring-default:security-reviewer
│
├─▶ "Create implementation plan"
│   └─▶ Use `ring-default:write-plan` agent
│
├─▶ "Question about Claude Code itself"
│   └─▶ Use `claude-code-guide` agent
│
└─▶ "Read ONE specific known file"
    └─▶ OK to use `Read` directly
```

### The 3-File Rule

**If you'll need to read more than 3 files → Use an agent instead.**

Why? At 3+ files, you're exploring, not targeted reading. Agents do this better.

### Rationalizations That Mean You're Burning Context

- "I'll just quickly check this file" → Will you check more after? Use agent.
- "Let me see what's in this directory" → That's exploration. Use agent.
- "I need context before using an agent" → Agents gather context FOR you.
- "It's faster to do it myself" → Agents are 15x more context-efficient.
- "I already started this chain" → Switch to agent NOW. Sunk cost fallacy.

### Ring Reviewers: ALWAYS Parallel

When using Ring reviewers, dispatch ALL THREE in a single message:

```
✅ CORRECT: One message with 3 Task calls (parallel)
❌ WRONG: Three separate messages (sequential, 3x slower)
```

### Context Cost Comparison

| Approach | Tokens Used |
|----------|-------------|
| Manual exploration (10 tool calls) | ~30,000 tokens |
| Single Explore agent call | ~2,000 tokens |
| **Savings** | **15x more efficient** |

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
