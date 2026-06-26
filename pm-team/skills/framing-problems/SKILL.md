---
name: ring:framing-problems
description: "Framing a rough idea, request, or complaint into a validated problem statement BEFORE designing a solution: separates symptom from root cause, demands evidence, names the user + job + context, defines success metrics and scope, and converts to How-Might-We questions. Forbids jumping to a solution or solving a stated symptom. Use at the start of a feature, when a request arrives as a solution ('build X'), or when the problem feels fuzzy. Skip when the problem is already framed and validated."
---

# Framing Problems

## Overview

Most design failures are well-built solutions to the wrong problem. This skill forces the problem into focus *before* anyone designs: it strips a request down to the real user problem, separates symptom from root cause, demands evidence, and only then opens the solution space with How-Might-We questions. The output is a problem statement the team can commit to.

## When to use

- Kicking off any feature or initiative
- A request arrives pre-shaped as a solution ("build a dashboard", "add a button", "we need AI here")
- A complaint/metric drop needs diagnosis ("users are churning on this screen")
- The problem feels fuzzy and people are already arguing about solutions

## Skip when

- The problem is already framed, evidenced, and validated (move to design)
- A trivial, obvious fix with no ambiguity about the underlying problem

## Sequence

**Runs before:** ring:building-personas / design / ring:writing-prds
**Related:** ring:critiquing-designs (which assumes a framed problem)

## Iron Law

```
FRAME THE PROBLEM BEFORE PROPOSING A SOLUTION. SEPARATE SYMPTOM FROM ROOT CAUSE, AND DEMAND EVIDENCE.
```

"Build X" is a solution, not a problem. Accepting it as the brief skips the only step that prevents building the wrong thing. A problem framed from one person's hunch with no evidence is a guess wearing a suit. Violating the letter (sneaking a solution into the "problem" statement) is violating the spirit.

## Core pattern (before → after)

❌ **Before — a solution masquerading as a problem**
> "We need to add a bulk-export button to the transactions page."

✅ **After — a framed problem**
> **Problem:** Finance operators reconciling month-end can't get transaction data out of the Console to cross-check in their own tools, so they re-key it by hand — slow and error-prone. *(evidence: 7/10 support tickets this month, 2 user interviews)*
> **User + job:** Finance operator, doing month-end reconciliation, needs the period's transactions in their spreadsheet/ERP.
> **Root cause vs symptom:** "No export button" is the *symptom*; the root problem is *no path to get data out for external reconciliation*. (Export is one possible solution; an API or scheduled report might serve better.)
> **Success:** operators complete reconciliation without manual re-keying; re-key errors → 0.
> **HMW:** How might we let operators get the period's transactions into their own tools reliably?

The "after" keeps the solution space open (export *or* API *or* report) because it named the problem, not the feature.

## The framing checklist

1. **Restate as a problem, not a solution.** If the input is "build X", ask "what problem does X solve?" and frame *that*.
2. **Name the user + job + context.** Who has this problem, what are they trying to do, when/where. (Tie to a persona if one exists.)
3. **Symptom vs root cause.** Ask "why" until you hit the cause, not the surface complaint. State both; design against the cause.
4. **Evidence.** What tells you this is real and worth solving? (tickets, interviews, analytics, observed behavior.) No evidence → mark `[ASSUMPTION]` and note how to validate; don't present a hunch as fact.
5. **Success metric.** How will you know it's solved? A behavior/outcome change, not "users like it".
6. **Scope.** What's explicitly in and out. What you're NOT solving.
7. **Constraints & assumptions.** Known limits (tech, regulatory, time) and the assumptions the frame rests on.
8. **Convert to How-Might-We.** 1–3 HMW questions that open the solution space without prescribing the answer.

## Rationalization table

| The excuse | Why it's wrong | Required action |
|------------|----------------|-----------------|
| "The stakeholder already said build X — just do it" | "Build X" is a solution; you'd be skipping whether X solves a real problem | Frame the problem X is meant to solve; X becomes one candidate solution |
| "The problem is obvious, no need to write it" | Obvious-to-you ≠ shared; unframed problems drift mid-project | Write user + job + root cause + success in 4 lines minimum |
| "We don't have evidence but we're pretty sure" | Pretty-sure builds the wrong thing at full cost | Mark `[ASSUMPTION]`, state how you'd validate, proceed with eyes open |
| "Adding a button IS the problem statement" | That's the symptom; the root cause may need a different solution | Ask why-5; state symptom AND cause, design against cause |
| "Let's brainstorm solutions, framing slows us down" | Solutioning before framing is the slow path — you redo it | Lock the problem statement first; then open HMW |
| "Success = users will like it" | Unmeasurable; can't tell if you solved it | Define a behavior/outcome metric |
| "I'll keep their proposed solution in the frame so I don't seem to push back" | A diplomatic frame that smuggles the requester's solution back in defeats the framing — you've just relabeled "build X" | The frame names the PROBLEM; the requester's idea is at most one clearly-labeled candidate solution, never baked into the statement |
| "I'll soften so leadership feels I agreed" | Ambiguity that lets the reader think you endorsed the solution is a real concession, not just tone | Be unambiguous that the solution is unvalidated; agree on the problem, not the solution |
| "I'll give a confident '~2 days' / '%' to sound concrete" | A fabricated estimate presented with confidence is a guess wearing data's clothes | State what you'd check and that the effort/number is unknown until you look |

## Red Flags — STOP

- Your "problem statement" contains a solution (a feature, a UI element, a technology).
- You can't name who has the problem, the job they're doing, or the root cause.
- There's no evidence and no `[ASSUMPTION]` tag.
- No success metric, or the metric is "users like it".
- You're listing solutions before the problem is locked.
- You accepted "build X" as the brief without asking what problem X solves.
- To appease the requester, their original solution survived *inside* your problem statement, or you phrased it so they'd think you agreed it's happening.
- You stated a timeline/percentage with confidence you don't have.

All of these mean: stop, restate as a user problem, separate symptom from cause, attach evidence or tag the assumption, and define how you'll know it's solved.

## Output

```markdown
# Problem Frame — {short name}
**Date:** {YYYY-MM-DD}

- **Problem:** {user can't do/achieve X, causing Y} — {evidence or [ASSUMPTION]}
- **User + job + context:** {who, doing what, when/where}
- **Symptom → root cause:** {surface complaint} → {underlying cause}
- **Success metric:** {behavior/outcome that proves it's solved}
- **In scope / Out of scope:** … / …
- **Constraints & assumptions:** …
- **How might we:** {1–3 HMW questions, no solution baked in}
```

## Next step

Framed + evidenced → proceed to ring:building-personas / design / ring:writing-prds. Evidence is thin (🔴) → validate the key assumption before investing in solutions.
