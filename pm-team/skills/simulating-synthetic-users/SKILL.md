---
name: ring:simulating-synthetic-users
description: "Running AI synthetic-user simulations to GENERATE usability hypotheses before real testing: feeds an evidence-grounded persona Level-5 profile to an agent that role-plays attempting a task, surfacing likely friction/confusion/abandonment points. Output is always hypotheses to validate with real users — never validation itself. Requires a real L5 profile; blocks on a fabricated one. Use to prioritize what to test or scout a flow cheaply. Skip when you can test real users directly, or to 'confirm' a decision already made."
---

# Simulating Synthetic Users

## Overview

A synthetic user is an AI role-playing a persona to attempt a task and narrate where it gets confused, hesitates, or gives up. Used right, it's a cheap **hypothesis generator** that tells you *where to look* before spending real-user time. Used wrong, it's a confirmation machine that hands your own assumptions back to you dressed as user research. This skill keeps it on the right side of that line.

## When to use

- Before real usability testing, to scout a flow and prioritize what to test
- To pressure a design across multiple personas cheaply when real users aren't yet available
- To generate a ranked list of likely friction points for a test plan

## Skip when

- You can test with real users directly — do that instead; synthetic never replaces it
- You want to "confirm" a decision already made (that's not testing, that's theater)
- No evidence-grounded persona exists (build one first — ring:building-personas)

## Sequence

**Runs after:** ring:building-personas (needs a Level-5 synthetic profile)
**Runs before:** ring:planning-usability-tests / real testing (synthetic output feeds the test plan)

## Iron Law

```
SYNTHETIC OUTPUT IS A HYPOTHESIS, NEVER A FINDING. IT TELLS YOU WHAT TO TEST, NOT WHAT IS TRUE.
```

A simulation cannot validate anything — it can only predict where a real user *might* struggle. The moment you write "users get confused here" instead of "we hypothesize users may get confused here — test it," you've laundered a guess into evidence. Violating the letter (quietly dropping the "hypothesis" framing in the summary) is violating the spirit.

## Hard prerequisite: a real Level-5 profile

Synthetic simulation requires the persona's **Level-5 synthetic profile** (priorities, tolerances, decision heuristics, vocabulary, error reactions) from ring:building-personas — and that profile must be **evidence-grounded (🟢/🟡), not fabricated (🔴)**.

- If the L5 profile is 🔴 (mostly assumption) or missing → **STOP.** A simulation built on an invented profile role-plays *your guesses*, then returns them as "user behavior" — a closed confirmation loop with the appearance of research. Go back and ground the profile, or run the sim explicitly labeled "assumption-only, zero evidential weight."

## The confirmation-loop trap (read this twice)

The core failure mode: you have a design you like (or a decision already made), you run a synthetic user, it "confirms" the design works, you ship. But the AI was primed by your own framing and persona — it told you what you set it up to say. **A simulation that only confirms your prior is worthless.** Guard against it:

- Prompt the synthetic user to **try to fail / find problems**, not to succeed.
- Run **multiple personas** and **multiple runs per persona** (≥3) — improvisation variance is real; a single run is anecdote.
- Never run a sim whose only purpose is to greenlight a decision already taken.

## Process

1. **Check the L5 prerequisite.** Evidence-grounded profile exists? If not, stop or label assumption-only.
2. **Define the task + entry state**, exactly as a real test would (e.g. "approve transaction TXN-4471, a R$250.000 transfer", starting at the queue).
3. **Prompt for honest struggle:** instruct the synthetic user to narrate every action and the thought behind it, mark each hesitation/confusion/workaround, and state where they'd abandon or escalate. Tell it to surface problems, not to perform success.
4. **Run ≥3 times per persona, across the relevant personas.** Capture divergence.
5. **Extract hypotheses, not findings.** Each output becomes "Hypothesis: {persona} may {struggle} at {step} because {reason} — confidence {low/med}, validate by {method}."
6. **Rank by likely impact × how many personas hit it.** Feed the top ones into the real test plan.
7. **Label the whole artifact** as synthetic-derived hypotheses with the source profiles' confidence tags.

## Rationalization table

| The excuse | Why it's wrong | Required action |
|------------|----------------|-----------------|
| "The sim confirmed the design works, ship it" | The AI echoed your framing; confirmation isn't validation | Treat as hypothesis; test the risky ones with real users before shipping |
| "We don't have a real persona, I'll just describe a plausible user" | A fabricated profile makes the sim role-play your guesses → confirmation loop | Ground the L5 (ring:building-personas) or label output zero-evidence |
| "One run is enough, it was clear" | Single run = anecdote; LLM output varies per run | Run ≥3 per persona; report divergence |
| "Synthetic users are cheaper, let's skip real testing" | Synthetic predicts, real validates — they're different steps | Use synthetic to prioritize; still test real users |
| "I'll write 'users struggled with X' in the summary" | That states a finding from a simulation — false | Write "hypothesis: users may struggle with X — validate" |
| "Let's run it to prove the feature is needed to leadership" | A sim run to justify a decision is theater, not research | Don't; if a decision's made, say so — don't dress it as evidence |
| "If we're short on time I'll just run more sim variations" | More runs = more hypotheses, never validation; offering it as a substitute defers the real test indefinitely | Run enough to find divergence, then STILL test real users; don't let extra sims replace validation |
| "It's fine, I put the caveats in" | Synthetic output looks like data; a footnote caveat gets stripped when someone reuses the slide | Put the non-validation status in the title/status line, not a footnote — strip-resistant |

## Red Flags — STOP

- The persona L5 is 🔴/fabricated/missing and you're running anyway without the zero-evidence label.
- Your output says "users do/think/struggle" instead of "hypothesis: users may…".
- You ran the sim once and drew a conclusion.
- The sim's job was to confirm a design/decision you'd already chosen.
- You're about to present synthetic output to stakeholders as user research / validation.
- You prompted the synthetic user to complete the task successfully rather than to find where it breaks.

All of these mean: stop, ground the profile, prompt for honest failure, run it several times, and report everything as hypotheses to validate with real users.

## Output

```markdown
# Synthetic-User Simulation — {flow}
**Date:** {YYYY-MM-DD} · **Status:** synthetic-derived HYPOTHESES (not validation)
**Personas:** {names + L5 confidence 🟢/🟡} · **Runs:** {N per persona}

## Hypotheses (ranked)
1. **Hypothesis:** {persona} may {struggle/abandon} at {step} because {reason}.
   - Seen in {x/N} runs · Confidence: low/med · **Validate by:** {real-user method}
2. …

## Did NOT reproduce / low signal
- …

## Recommended real-user tests
- Top {3} hypotheses to put in front of real users next.
```

## Next step

Hypotheses → feed the top ones into ring:planning-usability-tests for real validation. A 🔴 source profile → the whole run is assumption-only; ground the persona before relying on any of it.
