---
name: ring:documenting-design
description: "Documenting design decisions and their rationale so they persist and stay findable: captures the WHY (problem, alternatives considered, trade-offs, what was decided and by whom) as a lightweight decision record, plus component/pattern usage docs. NOT release notes or changelogs (that's ring:generating-release-guides) and NOT marketing. Use when a non-obvious design decision is made, a pattern needs documenting, or a verbal decision risks being lost. Skip for trivial or self-evident choices."
---

# Documenting Design

## Overview

Design documentation captures *why* a design is the way it is, so the team doesn't re-litigate settled decisions or lose the reasoning when people move on. The chronic failure: decisions get made in a meeting or Slack thread, everyone "knows" them, and six weeks later nobody can say what was decided or why — so it's re-argued, or silently violated. This skill records the rationale, not just the result.

**This is NOT `ring:generating-release-guides`.** That produces ops-facing release/migration notes from a git diff — *what changed* for operators. Design documentation captures *why a design decision was made* for the product/design/eng team. Using the release-guide skill for design rationale is the exact mismapping this skill corrects. Different audience, different content, different trigger.

## When to use

- A non-obvious design decision was made (a trade-off, a chosen-over-alternatives call)
- A reusable component/pattern needs usage documentation (when to use, variants, do/don't)
- A verbal/Slack decision risks being lost (the "we decided X in that meeting" problem)
- Onboarding context: someone needs the *why* behind the current design

## Skip when

- Trivial or self-evident choices with no trade-off worth recording
- Ops-facing release/migration notes → ring:generating-release-guides
- Long-form tutorials/guides → ring:writing-functional-docs (tw-team)

## Iron Law

```
DOCUMENT THE WHY, NOT JUST THE WHAT. AN UNRECORDED DECISION WILL BE RE-ARGUED OR VIOLATED.
```

"We use Geist" is a fact; *why, over what alternatives, decided by whom, when* is the documentation. Recording only the outcome leaves the next person unable to tell a deliberate decision from an accident — so they "fix" it. Violating the letter (a decision agreed verbally but never written) is violating the spirit: if it's not written, it didn't happen.

## What a design decision record captures

| Field | Why it's there |
|-------|----------------|
| **Decision** | The call, in one line (what we will do) |
| **Date + who decided** | Authority + when; lets you spot stale decisions |
| **Context / problem** | What forced the decision; the situation |
| **Alternatives considered** | What else was on the table (so it's not re-proposed) |
| **Rationale / trade-offs** | *Why this* over the alternatives; what we accept by choosing it |
| **Status** | proposed / accepted / superseded (+ link if superseded) |
| **Implications** | What now must be true (code, other docs, follow-ups) |

For a **component/pattern doc**, capture instead: purpose, when to use / when not, variants & states, do/don't examples, accessibility notes, and the tokens it uses.

## Core pattern (before → after)

❌ **Before — outcome only (a fact, not documentation)**
> The Console uses Geist.

✅ **After — a decision record**
> **Decision:** Geist is the font for Console + sindarian-ui; Inter is banned.
> **Date/who:** 2026-04-22, ratified by design (Gandalf → Milena review).
> **Context:** Console shipped Inter; Ring DS forbids it ("generic AI aesthetic").
> **Alternatives:** keep Inter (rejected: generic identity); Satoshi/Clash (rejected: less suited to dense tabular UI).
> **Rationale/trade-off:** Geist is built for dense financial UIs (tabular numerals, small-size legibility) and ships natively via next/font. Trade-off: a migration touching the shared sindarian-ui package.
> **Status:** accepted. **Implications:** swap font in Console layout + sindarian-ui; coordinate with frontend owner; QA visual pass.

The "after" is what stops the decision being re-argued or quietly reverted.

## Process

1. **Trigger check:** is this a non-obvious decision or a reusable pattern? If trivial, skip.
2. **Capture the why immediately** — at decision time, not "later" (later = lost). A verbal decision isn't done until it's recorded.
3. **Fill the record** (fields above). Keep it lightweight — a few lines per field, not an essay.
4. **Store it where it's found** — alongside the design system / in the repo's design docs, linked from where the decision applies. Not a private doc nobody can find.
5. **Set status + keep it current** — when a decision is replaced, mark the old one `superseded` and link forward; don't delete (the history is the value).

## Rationalization table

| The excuse | Why it's wrong | Required action |
|------------|----------------|-----------------|
| "Everyone was in the meeting, they know the decision" | Memory fades, people leave, and 'knowing' isn't findable | Write the record now; verbal ≠ documented |
| "I'll document it later" | Later never comes; the rationale is freshest now | Capture the why at decision time |
| "Just write what we decided" (no why) | Without the why, the next person can't tell intent from accident and will 'fix' it | Record alternatives + rationale + trade-off |
| "I wrote a detailed doc of what each decision is — it looks complete" | A long, tidy list of WHATs is *deceptively* complete: it reads as thorough while carrying zero rationale. Detail about the what is not the why | Every decision needs Why + rejected-alternatives + trade-off, even if the What description is already long |
| "It's a safeguard, the doc says it exists" | If you don't record *why* a safeguard exists, a future 'let's simplify' ticket removes it with nothing to push back | For each safeguard, record the risk it prevents + a 'do not remove without {security/compliance} review' red line |
| "We have a changelog / release notes for this" | Those are ops-facing what-changed; they don't carry design rationale | Use a decision record; release-guide skill is a different audience |
| "The code is the documentation" | Code shows what, never why-over-alternatives; nobody greps a decision | Record the decision separately, linked to the code |
| "It's obvious why we did it" | Obvious-to-you-today; not to the new hire or future-you | One line of rationale costs little and saves the re-argument |

## Red Flags — STOP

- A non-obvious decision was made and exists only in a meeting/Slack/someone's head.
- The doc records *what* but not *why* / alternatives / trade-offs — including a long, detailed what that *feels* complete but carries no rationale.
- A documented safeguard has no recorded reason-for-existing / "do not remove without review" line.
- You reached for the release-guide/changelog format for design rationale.
- The doc lives somewhere unfindable (private DM, personal drive).
- A superseded decision was deleted instead of marked and linked.
- "We'll write it up later."

All of these mean: stop, capture the decision + its why now, in the findable design-docs location, with status.

## Output

```markdown
# Design Decision — {short title}
**Status:** proposed | accepted | superseded({link}) · **Date:** {YYYY-MM-DD} · **Decided by:** {who}

**Decision:** {one line}
**Context:** {what forced it}
**Alternatives considered:** {A — why rejected; B — why rejected}
**Rationale & trade-offs:** {why this; what we accept}
**Implications:** {code/docs/follow-ups that must change}
```
*(For component/pattern docs: Purpose · When to use / not · Variants & states · Do/Don't · Accessibility · Tokens.)*

## Next step

Recorded + stored findably → link it from the design system / relevant code. Decision changes later → mark old `superseded`, link forward. Pattern docs → keep beside the component.
