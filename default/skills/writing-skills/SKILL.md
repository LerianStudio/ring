---
name: ring-default:writing-skills
description: |
  TDD for process documentation - write test cases (pressure scenarios), watch
  baseline fail, write skill, iterate until bulletproof against rationalization.

trigger: |
  - Creating a new skill
  - Editing an existing skill
  - Skill needs to resist rationalization under pressure

skip_when: |
  - Writing pure reference skill (API docs) → no rules to test
  - Skill has no compliance costs → no rationalization risk

related:
  complementary: [testing-skills-with-subagents]
---

# Writing Skills

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

**Personal skills live in agent-specific directories (e.g., `~/.claude/skills` for Claude Code, `~/.codex/skills` for Codex, or custom agent directories)** 

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** You MUST understand ring-default:test-driven-development before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill adapts TDD to documentation.

**Official guidance:** For Anthropic's official skill authoring best practices, see anthropic-best-practices.md. This document provides additional patterns and guidelines that complement the TDD-focused approach in this skill.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future agent instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## TDD Mapping for Skills

| TDD Concept | Skill Creation |
|-------------|----------------|
| **Test case** | Pressure scenario with subagent |
| **Production code** | Skill document (SKILL.md) |
| **Test fails (RED)** | Agent violates rule without skill (baseline) |
| **Test passes (GREEN)** | Agent complies with skill present |
| **Refactor** | Close loopholes while maintaining compliance |
| **Write test first** | Run baseline scenario BEFORE writing skill |
| **Watch it fail** | Document exact rationalizations agent uses |
| **Minimal code** | Write skill addressing those specific violations |
| **Watch it pass** | Verify agent now complies |
| **Refactor cycle** | Find new rationalizations → plug → re-verify |

The entire skill creation process follows RED-GREEN-REFACTOR.

## When to Create a Skill

**Create when:**
- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**
- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions (put in CLAUDE.md)

## Skill Types

### Technique
Concrete method with steps to follow (condition-based-waiting, root-cause-tracing)

### Pattern
Way of thinking about problems (flatten-with-flags, test-invariants)

### Reference
API docs, syntax guides, tool documentation (office docs)

## Directory Structure

`skills/skill-name/SKILL.md` (required) + optional supporting files. Flat namespace.

**Separate files for:** Heavy reference (100+ lines), reusable tools. **Keep inline:** Principles, code patterns (<50 lines).

## SKILL.md Structure

**Frontmatter (YAML):**
- Only two fields supported: `name` and `description`
- Max 1024 characters total
- `name`: Use letters, numbers, and hyphens only (no parentheses, special chars)
- `description`: Third-person, includes BOTH what it does AND when to use it
  - Start with "Use when..." to focus on triggering conditions
  - Include specific symptoms, situations, and contexts
  - Keep under 500 characters if possible

```markdown
---
name: Skill-Name-With-Hyphens
description: Use when [triggers/symptoms] - [what it does, third person]
---
# Skill Name
## Overview (1-2 sentences), ## When to Use (symptoms, NOT to use)
## Core Pattern (before/after code), ## Quick Reference (table for scanning)
## Implementation (inline or link), ## Common Mistakes, ## Real-World Impact (optional)
```


## Agent Search Optimization (ASO)

**Critical for discovery:** Future agents need to FIND your skill

### 1. Rich Description Field

**Purpose:** Agents read description to decide which skills to load for a given task. Make it answer: "Should I read this skill right now?"

**Format:** Start with "Use when..." to focus on triggering conditions, then explain what it does

**Content:**
- Use concrete triggers, symptoms, and situations that signal this skill applies
- Describe the *problem* (race conditions, inconsistent behavior) not *language-specific symptoms* (setTimeout, sleep)
- Keep triggers technology-agnostic unless the skill itself is technology-specific
- If skill is technology-specific, make that explicit in the trigger
- Write in third person (injected into system prompt)

| Quality | Example |
|---------|---------|
| **BAD** | `For async testing` (vague), `I can help...` (first person), `setTimeout/sleep` (tech-specific but skill isn't) |
| **GOOD** | `Use when tests have race conditions... - replaces timeouts with condition polling` (problem + solution) |

### 2. Keyword Coverage

Use words agents would search for:
- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
- Symptoms: "flaky", "hanging", "zombie", "pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
- Tools: Actual commands, library names, file types

### 3. Descriptive Naming

**Use active voice, verb-first:**
- ✅ `creating-skills` not `skill-creation`
- ✅ `testing-skills-with-subagents` not `subagent-skill-testing`

### 4. Token Efficiency (Critical)

**Problem:** getting-started and frequently-referenced skills load into EVERY conversation. Every token counts.

**Target word counts by skill type:**
- **Bootstrap/Getting-started**: <150 words each (loads in every session)
- **Simple technique skills**: <500 words (procedures, patterns, single concept)
- **Discipline-enforcing skills**: <2,000 words (TDD, verification, systematic debugging - need rationalization tables)
- **Process/workflow skills**: <4,000 words (multi-phase workflows with comprehensive templates)

**Rationale:** Complex skills need extensive rationalization prevention and complete templates. Don't artificially compress at the cost of effectiveness.

**Techniques:** Reference `--help` instead of documenting flags. Cross-reference other skills instead of repeating. Compress examples (42 words → 20 words). Don't repeat cross-referenced content.

**Verify:** `wc -w skills/path/SKILL.md` (check against word counts above)

**Name by what you DO or core insight:**
- ✅ `condition-based-waiting` > `async-test-helpers`
- ✅ `using-skills` not `skill-usage`
- ✅ `flatten-with-flags` > `data-structure-refactoring`
- ✅ `root-cause-tracing` > `debugging-techniques`

**Gerunds (-ing) work well for processes:**
- `creating-skills`, `testing-skills`, `debugging-with-logs`
- Active, describes the action you're taking

### 4. Cross-Referencing Other Skills

**When writing documentation that references other skills:**

Use skill name only, with explicit requirement markers:
- ✅ Good: `**REQUIRED SUB-SKILL:** Use ring-default:test-driven-development`
- ✅ Good: `**REQUIRED BACKGROUND:** You MUST understand ring-default:systematic-debugging`
- ❌ Bad: `See skills/testing/test-driven-development` (unclear if required)
- ❌ Bad: `@skills/testing/test-driven-development/SKILL.md` (force-loads, burns context)

**Why no @ links:** `@` syntax force-loads files immediately, consuming 200k+ context before you need them.

## Flowchart Usage

**Only for:** Non-obvious decisions, process loops, "A vs B" choices. **Never for:** Reference (→tables), code (→blocks), linear steps (→lists). See graphviz-conventions.dot for conventions.

## Code Examples

**One excellent example in most relevant language.** Complete, well-commented WHY, real scenario, ready to adapt. Don't: multi-language, fill-in-blank templates, contrived examples.

## File Organization

| Type | Structure | When |
|------|-----------|------|
| **Self-Contained** | `skill/SKILL.md` only | All content fits inline |
| **With Tool** | `SKILL.md` + `example.ts` | Reusable code, not narrative |
| **Heavy Reference** | `SKILL.md` + `*.md` refs + `scripts/` | Reference >100 lines |

## The Iron Law (Same as TDD)

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

This applies to NEW skills AND EDITS to existing skills.

Write skill before testing? Delete it. Start over.
Edit skill without testing? Same violation.

**No exceptions:**
- Not for "simple additions"
- Not for "just adding a section"
- Not for "documentation updates"
- Don't keep untested changes as "reference"
- Don't "adapt" while running tests
- Delete means delete

**REQUIRED BACKGROUND:** The ring-default:test-driven-development skill explains why this matters. Same principles apply to documentation.

## Testing All Skill Types

| Skill Type | Examples | Test With | Success Criteria |
|------------|----------|-----------|------------------|
| **Discipline** (rules) | TDD, verification | Pressure scenarios (time + sunk cost + exhaustion), academic questions | Agent follows rule under maximum pressure |
| **Technique** (how-to) | condition-based-waiting, root-cause-tracing | Application + variation + gap testing | Agent applies technique to new scenario |
| **Pattern** (mental model) | reducing-complexity | Recognition + application + counter-examples | Agent identifies when/how to apply |
| **Reference** (docs/APIs) | API docs, command refs | Retrieval + application + gap testing | Agent finds and applies info correctly |

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps, unclear sections. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "Too tedious to test" | Testing is less tedious than debugging bad skill in production. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
| "Academic review is enough" | Reading ≠ using. Test application scenarios. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

**All of these mean: Test before deploying. No exceptions.**

## Bulletproofing Skills Against Rationalization

Skills that enforce discipline (like TDD) need to resist rationalization. Agents are smart and will find loopholes when under pressure.

**Psychology note:** Understanding WHY persuasion techniques work helps you apply them systematically. See persuasion-principles.md for research foundation (Cialdini, 2021; Meincke et al., 2025) on authority, commitment, scarcity, social proof, and unity principles.

### Close Every Loophole Explicitly

Don't just state rule - forbid specific workarounds:
- **BAD:** `Write code before test? Delete it.`
- **GOOD:** Add `Delete it. Start over.` + explicit `No exceptions:` list (don't keep as reference, don't adapt, don't look, delete means delete)

### Address "Spirit vs Letter" Arguments

Add foundational principle early:

```markdown
**Violating the letter of the rules is violating the spirit of the rules.**
```

This cuts off entire class of "I'm following the spirit" rationalizations.

### Build Rationalization Table

Capture rationalizations from baseline testing (see Testing section below). Every excuse agents make goes in the table:

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
```

### Create Red Flags List

Make it easy for agents to self-check when rationalizing:

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**
```

### Update CSO for Violation Symptoms

Add to description: symptoms of when you're ABOUT to violate the rule:

```yaml
description: use when implementing any feature or bugfix, before writing implementation code
```

## RED-GREEN-REFACTOR for Skills

| Phase | Action |
|-------|--------|
| **RED** | Run pressure scenario WITHOUT skill → document choices/rationalizations verbatim |
| **GREEN** | Write skill addressing specific failures → verify agent complies |
| **REFACTOR** | Find new rationalizations → add counters → re-test until bulletproof |

**REQUIRED SUB-SKILL:** Use ring-default:testing-skills-with-subagents for pressure scenarios, pressure types, hole-plugging, meta-testing.

## Anti-Patterns

| Pattern | Example | Why Bad |
|---------|---------|---------|
| **Narrative** | "In session 2025-10-03, we found..." | Too specific, not reusable |
| **Multi-language** | example-js.js, example-py.py | Mediocre quality, maintenance burden |
| **Code in flowcharts** | `step1 [label="import fs"]` | Can't copy-paste, hard to read |
| **Generic labels** | helper1, step3, pattern4 | Labels need semantic meaning |

## STOP: Before Moving to Next Skill

**After writing ANY skill, you MUST STOP and complete the deployment process.**

**Do NOT:**
- Create multiple skills in batch without testing each
- Move to next skill before current one is verified
- Skip testing because "batching is more efficient"

**The deployment checklist below is MANDATORY for EACH skill.**

Deploying untested skills = deploying untested code. It's a violation of quality standards.

## Skill Creation Checklist (TDD Adapted)

**Use TodoWrite for each phase.**

| Phase | Requirements |
|-------|--------------|
| **RED** | 3+ pressure scenarios, run WITHOUT skill, document rationalizations verbatim |
| **GREEN** | Name (letters/numbers/hyphens), YAML frontmatter (<1024 chars), description starts "Use when...", third person, keywords, address baseline failures, one excellent example, verify compliance |
| **REFACTOR** | New rationalizations → add counters, build rationalization table, create red flags, re-test |
| **Quality** | Flowchart only if non-obvious, quick ref table, common mistakes, no narrative |
| **Deploy** | Commit and push, consider contributing PR |

## Discovery Workflow

How future agents find your skill:

1. **Encounters problem** ("tests are flaky")
3. **Finds SKILL** (description matches)
4. **Scans overview** (is this relevant?)
5. **Reads patterns** (quick reference table)
6. **Loads example** (only when implementing)

**Optimize for this flow** - put searchable terms early and often.

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law: No skill without failing test first.
Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).
Same benefits: Better quality, fewer surprises, bulletproof results.

If you follow TDD for code, follow it for skills. It's the same discipline applied to documentation.
