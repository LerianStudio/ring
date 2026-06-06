---
name: ring:writing-skills
description: "Writing or editing a Ring skill: SKILL.md structure, frontmatter and Agent-Search-Optimization rules, token-efficiency targets, and bulletproofing (Iron Law, rationalization tables, Red Flags) so discipline-enforcing skills resist excuses. Use when creating or revising a skill. Delegates pressure-testing to ring:testing-skills-with-subagents. Skip for pure reference skills with no rules, or project conventions (put those in CLAUDE.md)."
---

# Writing Skills

## When to use
- Creating a new skill
- Editing an existing skill
- Skill needs to resist rationalization under pressure

## Skip when
- Writing pure reference skill (API docs) → no rules to test
- Skill has no compliance costs → no rationalization risk

## Related
**Complementary:** ring:testing-skills-with-subagents

**Writing skills IS TDD applied to process documentation.**

Same Iron Law: No skill without failing test first.  
Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).

**REQUIRED BACKGROUND:** Understand ring:test-driven-development before using this skill.

## What is a Skill?

A reusable reference guide for proven techniques, patterns, or tools. **Not** a narrative about how you solved something once.

**Create when:** technique wasn't obvious, you'd reference it again, applies broadly.  
**Skip when:** one-off solution, project-specific convention (put in CLAUDE.md).

## Skill Types

| Type | Examples |
|------|---------|
| Technique (steps to follow) | condition-based-waiting, root-cause-tracing |
| Pattern (way of thinking) | flatten-with-flags, test-invariants |
| Reference (docs/API) | API reference, command syntax |

## SKILL.md Structure

```
---
name: ring:skill-name-with-hyphens
description: Use when [triggers/symptoms] — [what it does, third person]
---
# Skill Name
## Overview (1-2 sentences)
## When to Use (symptoms + skip conditions)
## Core Pattern (before/after examples)
## Quick Reference (table for scanning)
## Implementation (inline or linked)
## Common Mistakes
```

**Frontmatter rules:** Only `name` and `description`. Max 1024 chars total. `name`: letters, numbers, hyphens only. `description`: third-person, starts "Use when...", <500 chars if possible.

## Agent Search Optimization (ASO)

**Agents read description to decide which skills to load.** Make it answer: "Should I read this skill right now?"

- Use concrete triggers and symptoms (problem-focused, not language-specific)
- Use keywords agents would search: error messages, symptoms, tool names
- Active voice, verb-first names: `creating-skills` not `skill-creation`
- Reference skills by name only: `ring:test-driven-development`, no `@` links (force-loads context)

## Token Efficiency

| Skill Type | Target |
|------------|--------|
| Bootstrap/getting-started | <150 words (loads in every session) |
| Simple technique | <500 words |
| Discipline-enforcing | <2,000 words (need rationalization tables) |
| Process/workflow | <4,000 words (multi-phase workflows) |

## RED-GREEN-REFACTOR for Skills

| Phase | Action |
|-------|--------|
| **RED** | Run pressure scenario WITHOUT skill → document agent choices/rationalizations verbatim |
| **GREEN** | Write skill addressing specific failures → verify agent now complies |
| **REFACTOR** | Find new rationalizations → add counters → re-test until bulletproof |

**REQUIRED SUB-SKILL:** Use ring:testing-skills-with-subagents for pressure scenarios and hole-plugging.

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

Applies to new skills AND edits. Delete untested skills and start over. No exceptions.

## Bulletproofing Against Rationalization

For discipline-enforcing skills:

1. **Forbid specific workarounds explicitly** — don't just state the rule, list prohibited alternatives
2. **Address "spirit vs letter" early:** `"Violating the letter is violating the spirit."`
3. **Build rationalization table** from baseline testing — capture every excuse agents make
4. **Create Red Flags list** — make self-checking easy

```markdown
## Red Flags — STOP
- [symptom 1]
- [symptom 2]
All of these mean: [required action].
```

## Skill Creation Checklist

| Phase | Requirements |
|-------|--------------|
| RED | 3+ pressure scenarios, run WITHOUT skill, document rationalizations verbatim |
| GREEN | Valid frontmatter, description starts "Use when...", addresses baseline failures, one excellent example, verify compliance |
| REFACTOR | Rationalization table, Red Flags list, re-test against new loopholes |
| Quality | Flowchart only if non-obvious, quick ref table, no narrative |
| Deploy | Commit and push |

**STOP after each skill — do NOT batch-create without testing each.**

## File Organization

| Type | Structure |
|------|-----------|
| Self-contained | `skill/SKILL.md` only |
| With tool | `SKILL.md` + reusable script |
| Heavy reference | `SKILL.md` + `*.md` refs + `scripts/` |
