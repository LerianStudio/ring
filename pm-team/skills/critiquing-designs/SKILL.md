---
name: ring:critiquing-designs
description: "Running a structured, heuristic-based critique of a Lerian product screen, flow, wireframe, or prototype (including from a screenshot or Figma): Nielsen's 10 heuristics, severity per finding, principle-vs-preference tag, fixed 5-part format (observation → heuristic → why → severity → fix), and at least one strength. Critiques the design, never the designer; forbids vague praise and rubber-stamping. Use when asked to critique, review, or give feedback on a screen/mockup/design ('what do you think of this screen?', 'review this design'); preferred over the generic design:design-critique for Lerian/Console work. Skip for code-only review (use ring:reviewing-code)."
---

# Critiquing Designs

## Overview

A design critique finds usability problems *before* they ship, using a shared rubric so feedback is objective, specific, and actionable — not taste. This skill evaluates a design against **Nielsen's 10 heuristics**, rates each issue by **severity**, and forces every point through a **5-part structure** so "I don't like it" can never pass as feedback.

## When to use

- Reviewing a screen, flow, wireframe, or prototype before handoff
- Design review / critique sessions
- User asks "what do you think of this?", "review this design", "critique this mockup"
- A design "feels off" and you need to say *why*, concretely

## Skip when

- Code-only review with no UI/UX surface → ring:reviewing-code
- Pure copy review → ring:writing-ux-copy
- The artifact is too early to critique usability (rough concept sketch) — frame the problem first (ring:framing-problems)

## Iron Law

```
CRITIQUE THE DESIGN, NOT THE DESIGNER. EVERY POINT IS SPECIFIC, RUBRIC-BACKED, AND ACTIONABLE.
```

"I like it" / "looks clean" / "feels off" are not critique — they're reactions. A point that doesn't name *what*, *where*, *which heuristic*, and *what to do* is noise. Praise that isn't specific is as useless as vague criticism. Violating the letter (one "looks good overall" with no evidence) is violating the spirit.

## Nielsen's 10 heuristics (the rubric)

| # | Heuristic | Ask |
|---|-----------|-----|
| 1 | Visibility of system status | Does the user always know what's happening? (loading, saved, progress) |
| 2 | Match to the real world | Words/concepts the user has, not system jargon? |
| 3 | User control & freedom | Easy undo/cancel/back? Clear exits? |
| 4 | Consistency & standards | Same thing = same word/look; follows platform + the design system |
| 5 | Error prevention | Does it stop mistakes before they happen? (constraints, confirmations) |
| 6 | Recognition over recall | Options visible; user not forced to remember across screens |
| 7 | Flexibility & efficiency | Shortcuts for experts without blocking novices |
| 8 | Aesthetic & minimalist design | No competing/irrelevant content diluting the essential |
| 9 | Help users recover from errors | Plain-language errors that say what + how to fix |
| 10 | Help & documentation | Help available where needed, task-focused |

## The 5-part feedback format (every finding)

Each finding MUST have all five parts:

1. **Observation** — what you see, specifically, and *where* (screen/element).
2. **Heuristic** — which of the 10 it violates (or upholds, for a strength).
3. **Why it matters** — the user consequence (confusion, error, abandonment, lost trust).
4. **Severity** — `critical` / `major` / `minor` / `praise` (see scale).
5. **Suggested fix** — a concrete, actionable change (not "make it better").

> Example (one finding):
> 1. **Observation:** After tapping "Enviar", the button gives no feedback for ~2s while the request runs. (Step 3, confirm screen)
> 2. **Heuristic:** #1 Visibility of system status.
> 3. **Why it matters:** The user can't tell if the tap registered → taps again → risk of double-send (real money).
> 4. **Severity:** critical.
> 5. **Fix:** Show an immediate loading state on the button (`Enviando…`, disabled) and block re-taps until the response resolves.

## Severity scale

| Severity | Meaning | Action |
|----------|---------|--------|
| `critical` | Blocks the task, causes data/money loss, or hard confusion | Must fix before ship |
| `major` | Significant friction or frequent error; task still possible | Fix this cycle |
| `minor` | Polish, edge case, mild inconsistency | Backlog |
| `praise` | Works notably well — name it so it's preserved | Keep; replicate elsewhere |

Always include at least one genuine `praise` point when warranted — critique preserves what works, it doesn't only hunt for faults.

**Severity rates importance, not your certainty.** A `minor` stated as fact is still a claim. Don't let the severity tag launder a preference into an authoritative finding.

## Epistemic status — label what you actually know

Every finding is one of three, and you must be honest about which:

| Tag | Means | Allowed to state as |
|-----|-------|---------------------|
| **[principle]** | Violates a named heuristic with a real user consequence | A finding to fix |
| **[convention]** | Common best practice / platform norm, not a hard rule | A recommendation, named as such |
| **[preference]** | Your taste (a specific color, an exact px value, a layout you'd pick) | Say "I'd prefer…" or **cut it** |

A specific prescriptive value (e.g. "use 8px here", "make it #2D7FF9") must cite the design system/token, or be marked `[preference]`. A number you didn't derive is not a finding. If you can't tag a point `[principle]` or `[convention]`, it's `[preference]` — label it or drop it.

## Process

1. **Get context first:** who's the user (persona), what's the primary task, what device/viewport. Without this you're critiquing in a vacuum — ask or state assumptions.
2. **Walk the primary task path** screen by screen as the user would, not as the designer explains it.
3. **Pass each screen against the 10 heuristics** — note violations AND strengths.
4. **Write every finding in the 5-part format**, with file/screen references.
5. **Rate and sort by severity**; lead with critical/major.
6. **Summarize:** top 3 things to fix, top 1–2 things to keep.

## Rationalization table

| The excuse | Why it's wrong | Required action |
|------------|----------------|-----------------|
| "It looks clean / I like it" | A reaction, not a critique — gives the designer nothing to act on | Tie every point to a heuristic + fix |
| "Don't want to be harsh / hurt their feelings" | Vague kindness ships usability bugs; specificity *is* the respect | Critique the design specifically; never the person |
| "Overall it's good, ship it" (no findings) | A real design has findings at some severity; "no notes" usually means you didn't look | Walk the task path; produce findings + at least one specific praise |
| "This is just my taste" | If it's taste, it's not a finding — drop it or find the heuristic | Only raise points backed by a heuristic + user consequence |
| "I'll dress my preferred spacing/color up as a usability point" | Preference stated with authority is the most common critique failure — it wastes the designer's time on your taste | Tag it `[preference]` and say "I'd prefer", or cut it; prescriptive values must cite the design system |
| "The severity tag shows how it ranks, that's enough" | Severity ≠ certainty; a `minor [preference]` can still read as fact | Tag epistemic status (principle/convention/preference) AND severity |
| "Severity doesn't matter, list everything flat" | Unranked lists bury the critical issues under nitpicks | Rate every finding; lead with critical/major |
| "I don't know the user, but here's my take" | Critique without the persona/task is guesswork | Establish persona + task first (or state the assumption) |

## Red Flags — STOP

- A finding without one of the 5 parts (especially: no heuristic, or no concrete fix).
- A preference dressed as a principle, or a specific px/hex value stated as fact without citing the design system → tag `[preference]` or cut.
- Any point that's taste ("I'd prefer blue") with no heuristic + user consequence.
- "Looks good, no notes" — you didn't walk the task path.
- Feedback aimed at the designer ("you forgot…") instead of the design.
- A flat list with no severity, or all-criticism with zero praise.
- Critiquing without knowing the persona and primary task.

All of these mean: stop, anchor each point to a heuristic + user consequence + concrete fix, rate it, and keep what works.

## Output

```markdown
# Design Critique — {screen/flow}
**Date:** {YYYY-MM-DD} · **Persona/task:** {who, doing what, on what device}

## Critical
1. **Observation:** … (where) · **Heuristic:** #N … · **Why:** … · **Severity:** critical · **Status:** [principle] · **Fix:** …

## Major
…

## Minor
…

## Keep (praise)
- **Observation:** … · **Heuristic:** #N · **Why it works:** …

## Summary
- Fix first: {top 3} · Preserve: {top 1–2}
```

## Next step

Critical/major findings → back to the designer for revision, then re-critique. Clean → proceed to handoff / ring:validating-ux-completeness.
