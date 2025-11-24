# Universal State Tracking Pattern

Add this section to any multi-step skill:

## State Tracking (MANDATORY)

Create and maintain a status comment:

```
SKILL: [skill-name]
PHASE: [current phase/step]
COMPLETED: [✓ list what's done]
NEXT: [→ what's next]
EVIDENCE: [last verification output]
BLOCKED: [any blockers]
```

**Update after EACH phase/step.**

Example:
```
SKILL: systematic-debugging
PHASE: 2 - Pattern Analysis
COMPLETED: ✓ Error reproduced ✓ Recent changes reviewed
NEXT: → Compare with working examples
EVIDENCE: Test fails with "KeyError: 'user_id'"
BLOCKED: None
```

This comment should be included in EVERY response while using the skill.
