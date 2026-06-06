---
name: ring:using-ring
description: "Enforcing Ring's orchestrator protocol every conversation: dispatch specialist/Explore agents instead of operating tools directly, honor the >3-file hard gate, and run skill discovery before any task. Use at conversation start, before any task, when a request matches auto-trigger phrases (fix issues, refactor, find where, visualize), or when tempted to read/edit files directly. Never skip — mandatory."
---

# Using Ring (Orchestrator Protocol)

## When to use
- Every conversation start (automatic via SessionStart hook)
- Before ANY task (check for applicable skills)
- When tempted to operate tools directly instead of delegating

## Skip when
- Never skip - this skill is always mandatory

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST read the skill.
IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.
</EXTREMELY-IMPORTANT>

## ⛔ 3-FILE RULE: HARD GATE

**DO NOT read/edit >3 files directly. PROHIBITION, not guidance.**

```
≤3 files → Direct OK (if user requested)
>3 files → STOP. Launch agent. VIOLATION = 15x context waste.
```

**Already at 3 files?** STOP. Dispatch agent NOW.

## Auto-Trigger Phrases: Mandatory Agent Dispatch

| User Phrase | Mandatory Action |
|-------------|-----------------|
| "fix issues", "fix remaining", "fix findings" | Launch specialist agent |
| "apply fixes", "fix errors", "fix warnings", "fix linting" | Launch specialist agent |
| "update across", "change all", "refactor" | Launch specialist agent |
| "find where", "search for", "understand how" | Launch Explore agent |
| "draw diagram", "visualize", "comparison table" | Load ring:visualizing skill |

## Mandatory First Response Protocol

1. ☐ Check for `<MANDATORY-USER-MESSAGE>` in additionalContext — display verbatim if present
2. ☐ Orchestration decision: which agent handles this? (TodoWrite)
3. ☐ Skill check: does any skill match this request?
4. ☐ If yes → read and run the skill
5. ☐ Announce skill/agent being used
6. ☐ Execute

## ORCHESTRATOR Principle

**You dispatch agents. You do not operate tools directly.**

| Instead of... | Do this |
|---------------|---------|
| Reading files | Dispatch Explore agent |
| Grep/Glob chains | Dispatch Explore agent |
| Manual multi-file edits | Dispatch specialist agent |
| "Quick look" at codebase | Dispatch Explore agent |

**Exceptions (rare):** User explicitly provides a file path AND explicitly requests you read it.

## Which Agent?

| Task | Agent |
|------|-------|
| Explore/find/understand/search | **Explore** |
| Plan implementation, break down features | **Plan** |
| Multi-step research, complex investigation | **general-purpose** |
| Code review | 9 default reviewers plus triggered conditional specialists via ring:reviewing-code skill |
| Implementation plan document | ring:writing-plans |

**Ring reviewers: always parallel in a single turn with multiple Task calls.**

## Pre-Action Checkpoint (before every Read/Grep/Glob/Bash)

```
1. FILES: ___ >3? → Agent. Already 3? → Agent now.
2. USER PHRASE: matches auto-trigger? → Agent
3. DECISION: [Agent: ___] or [Direct: reason]
```

## TodoWrite Requirements

First two todos for ANY task:
1. "Orchestration decision: [agent-name]"
2. "Check for relevant skills"

If skill has checklist → TodoWrite for every item.

## Summary

**Before any task:** orchestration decision → skill check → announce → execute.  
**Before any tool use:** complete pre-action checkpoint.  
**Default answer: dispatch an agent.** Exception is rare.
