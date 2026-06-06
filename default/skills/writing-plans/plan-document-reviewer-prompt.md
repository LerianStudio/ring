# Plan Document Reviewer — Subagent Dispatch Template

Companion to [SKILL.md](SKILL.md). Use this when dispatching a subagent to review a completed plan.

**Purpose:** Verify the plan is complete, matches the spec, and has proper task decomposition.

**Dispatch after:** The complete plan is written and self-review (in `ring:writing-plans`) is done.

**When to dispatch vs. self-review only:**
- Self-review alone → small plans, single author, fast iteration
- Add subagent dispatch → large surface, multiple authors, critical path, plan blocks downstream work

## Dispatch Template

```
Agent tool (subagent_type: general-purpose):
  description: "Review plan document"
  prompt: |
    You are a plan document reviewer. Verify this plan is complete and ready for implementation.

    **Plan to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Spec Alignment | Every spec requirement maps to an epic; no major scope creep |
    | Phase Boundaries | Every phase ends in working, verifiable software |
    | Wave Discipline | Exactly one phase is task-detailed; later phases sit at epic level (premature task detail is stale risk) |
    | Task Quality | Detailed-wave tasks are dispatch-ready: context with file:line refs, implementation vision with decisions made, exact files, verification — no "TBD", "appropriate handling", or unnamed edge cases |
    | Contract Consistency | Names, signatures, and schemas referenced across epics agree |
    | Buildability | Could an implementer with zero context start each detailed task within a minute of reading it? |

    ## Calibration

    **Only flag issues that would cause real problems during implementation.**
    An implementer building the wrong thing or getting stuck is an issue.
    Minor wording, stylistic preferences, and "nice to have" suggestions are not.

    Approve unless there are serious gaps — missing requirements from the spec,
    contradictory steps, placeholder content, or tasks so vague they can't be acted on.

    ## Output Format

    ## Plan Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Phase N / Epic N.M / Task N.M.T]: [specific issue] — [why it matters for implementation]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations.

## Handling Reviewer Output

| Reviewer Status | Action |
|-----------------|--------|
| Approved, no issues | Proceed to execution handoff |
| Approved, recommendations only | Optionally apply; proceed to handoff |
| Issues Found | Fix the flagged epics/tasks inline, then re-dispatch or self-verify |

Do NOT loop indefinitely on minor cosmetic findings — the calibration above scopes the reviewer to real blockers.
