---
name: ring:planning-usability-tests
description: "Planning a usability test that produces unbiased evidence: defines objectives, realistic NON-leading tasks, the right participants (real users, not teammates), method (moderated/unmoderated, think-aloud), and success criteria + metrics (task-success rate target, time-on-task, errors, SUS) decided BEFORE the test. Forbids leading tasks, convenience participants, and post-hoc success criteria. Use before running a usability study or validating a flow with users. Skip for generating hypotheses (use ring:simulating-synthetic-users) or pure A/B metric tests."
---

# Planning Usability Tests

## Overview

A usability test is only worth running if its design doesn't bias the result. The recurring failures are subtle: tasks that hint at the answer, "users" who are actually teammates, and success criteria invented *after* seeing the data so any outcome looks like a win. This skill plans a test that produces evidence you can trust: real users, neutral tasks, and a pass/fail bar set before anyone touches the prototype.

## When to use

- Before running a usability study (moderated or unmoderated)
- Validating whether a design/flow actually works for real users
- Turning synthetic-user hypotheses (ring:simulating-synthetic-users) into real validation
- "Is this design good?" needs a real answer, not an opinion

## Skip when

- Generating hypotheses cheaply → ring:simulating-synthetic-users (then come back here to validate)
- Pure quantitative A/B test of a metric (different method)
- The question is preference/market, not usability (survey/research instead)

## Sequence

**Runs after:** ring:simulating-synthetic-users (hypotheses to validate), design work
**Related:** ring:building-personas (defines who the real participants are)

## Iron Law

```
SET SUCCESS CRITERIA BEFORE THE TEST. TASKS MUST NOT LEAD. PARTICIPANTS MUST BE REAL USERS.
```

If you decide what "success" means after seeing results, every result confirms you — that's not a test. A task that tells the user where to click measures reading, not usability. A teammate already knows the product, so they can't reveal what a real user wouldn't find. Violating the letter (one leading task, one "close enough" participant, criteria nudged after a pilot) is violating the spirit.

## The plan (what to define, in order)

1. **Objective + research questions.** What decision will this test inform? What specifically are you unsure works?
2. **Participants.** WHO (which persona — ring:building-personas), how recruited, and explicitly NOT teammates/people who built it. **How many:** ~5 per persona segment catches most issues for qualitative tests; more for quantitative confidence.
3. **Method.** Moderated (probe the why, think-aloud) vs unmoderated (scale, less depth); in-person/remote; prototype fidelity.
4. **Tasks.** Realistic scenarios in the *user's* words, framed by goal not by UI. Non-leading (see below). 3–6 tasks; order to avoid one teaching the next.
5. **Metrics + success criteria — set NOW, before running:**
   - **Task-success rate** with a target (e.g. ≥80% complete unaided).
   - **Time-on-task**, **error count**, **assists needed**.
   - **SUS** (System Usability Scale) for a standardized score.
   - Define the pass bar per task up front.
6. **Script.** Intro (reduce performance anxiety: "we're testing the design, not you"), think-aloud prompt, neutral probes, no leading.
7. **Logistics.** Consent/recording, incentive, environment, pilot run to debug the script.

## Leading vs neutral tasks (the most common bias)

| ❌ Leading | ✅ Neutral |
|-----------|-----------|
| "Click the blue **Enviar** button to send R$150 to Maria" | "You need to send R$150 to Maria. Show me how you'd do that." |
| "Use the **filter** at the top to find last month's transactions" | "Find the transactions from last month." |
| "Open **Settings** and turn on two-factor auth" | "Make your account more secure against someone stealing your password." |

The neutral version never names the UI element or the path — it states the user's goal and observes whether they find the way.

## Rationalization table

| The excuse | Why it's wrong | Required action |
|------------|----------------|-----------------|
| "I'll just grab a few teammates to test" | They know the product and the intent — they can't surface what a real user misses | Recruit real users of the relevant persona; teammates ≠ participants |
| "Recruiting is slow this sprint, I'll run with whoever's available" | Time pressure pushing you to convenience participants is the #1 way validity dies quietly | The cheapest validity lever is 2 real users > 5 teammates. If truly forced, label each session (real user vs internal), downgrade confidence, and NEVER report it as 'we tested with users' |
| "Comparative baseline against the old design — where feasible" | 'Where feasible' is the escape hatch the baseline slips through; then 'X% faster' has nothing to compare to | For a redesign, the old-version baseline on the same tasks is required, not optional |
| "We'll see how it goes and judge after" | Post-hoc criteria make every result a 'success'; that's confirmation, not a test | Write the pass bar (success-rate target per task) before running |
| "Just tell them which button to click so it goes smoothly" | A task that names the UI tests reading, not findability | State the goal in the user's words; never the path/element |
| "Two people was enough, they liked it" | 'Liked it' is opinion; n=2 misses most issues | ~5/segment; measure behavior (success/time/errors), not approval |
| "Ask them if they found it easy" | Self-reported ease ≠ observed success; people are polite | Observe task completion; use SUS for standardized self-report, not ad-hoc 'was it easy?' |
| "The pilot went fine, let's tweak the task to get cleaner data" | Tweaking tasks after seeing results to shape the outcome is rigging | Pilot fixes *clarity/bugs* in the script, never nudges toward a desired result |

## Red Flags — STOP

- Success criteria aren't written down before the test (or you're deciding them after).
- A task names a UI element, a button label, or the navigation path.
- Participants are teammates, friends, or anyone who's seen the product built.
- The plan measures "did they like it?" instead of task success/time/errors.
- Fewer than ~5 per segment for a qualitative test, presented as conclusive.
- You changed tasks/criteria after a pilot to get a nicer result.

All of these mean: stop, set the pass bar now, rewrite tasks to state goals not paths, recruit real users, and measure behavior over opinion.

## Output

```markdown
# Usability Test Plan — {flow/feature}
**Date:** {YYYY-MM-DD}

- **Objective / research questions:** {decision this informs; what we're unsure works}
- **Participants:** {persona segment(s)} · n≈{5/segment} · recruited via {…} · NOT teammates
- **Method:** {moderated/unmoderated · remote/in-person · think-aloud · prototype fidelity}

## Tasks (goal-framed, non-leading)
1. Scenario: "{user goal in their words}" · Success = {observable completion} · Pass bar: {e.g. ≥80%}
2. …

## Metrics & success criteria (set before running)
| Metric | Target |
|--------|--------|
| Task-success rate | ≥{80}% unaided |
| Time-on-task | ≤{X} / baseline |
| Errors / assists | ≤{X} |
| SUS | ≥{68} |

## Script notes
- Intro ("testing the design, not you"), think-aloud, neutral probes only.

## Logistics
- Consent/recording · incentive · pilot to debug script (clarity only, no result-shaping)
```

## Next step

Plan approved → recruit, pilot, run. Results → feed back into design; failed pass bars → revise and (if needed) re-test. Hypotheses came from ring:simulating-synthetic-users → this is where they get real validation.
