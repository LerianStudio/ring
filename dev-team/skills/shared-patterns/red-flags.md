# Red Flags - STOP Immediately

This file contains universal red flag indicators that should trigger immediate pause in any gate or skill execution.

---

## Purpose

If you catch yourself thinking ANY of the patterns below, **STOP immediately**. These thoughts indicate you're about to violate mandatory workflow requirements.

---

## Universal Red Flags

### Process Bypass Thoughts

- "This task is too simple for full process"
- "We already passed most steps/gates"
- "Manager/Director/CTO said to skip"
- "Just this once won't hurt"
- "I'll do it properly next time"
- "90% done, almost there"
- "Ship now, fix later"

### Time/Authority Pressure Thoughts

- "User is in a hurry"
- "Demo tomorrow, skip steps"
- "Cost of waiting is too high"
- "Authority approved skipping"
- "Emergency, no time for process"

### Quality Bypass Thoughts

- "Tests pass, review is redundant"
- "We can fix issues later"
- "This is internal, less rigor needed"
- "It's just a prototype"
- "YAGNI - we don't need it yet"

---

## TDD Red Flags

- "I'll write tests after the code works"
- "Let me keep this code as reference"
- "This is too simple for full TDD"
- "Manual testing already validated this"
- "I'm being pragmatic, not dogmatic"
- "TDD isn't explicitly required here"

---

## Review Red Flags

- "This change is too trivial for review"
- "Only N lines, skip review"
- "One reviewer found nothing, skip the others"
- "These are just cosmetic issues"
- "Small fix doesn't need re-review"
- "Sequential reviews are fine this time"
- "Security scanner covers security review"

---

## Testing Red Flags

- "Manual testing already validated this"
- "Close enough to coverage threshold"
- "These integration tests prove it better"
- "We can add tests after review"
- "All criteria covered, percentage doesn't matter"
- "Tests slow down development"

---

## Validation Red Flags

- "User is busy, I'll assume approval"
- "Tests pass, validation is redundant"
- "These minor issues can be fixed later"
- "User didn't say no, so it's approved"
- "User seemed satisfied with the demo"
- "'Looks good' means approved"

---

## Observability Red Flags

- "We'll add observability after launch"
- "Plain text logs are enough for now"
- "It's just an internal service"
- "We can monitor manually"
- "It's just MVP, we'll add it later"

---

## Specialist Dispatch Red Flags

- "This is a small task, no specialist needed"
- "I already know how to do this"
- "Dispatching takes too long"
- "I'll just fix this one thing quickly"
- "The specialist will just do what I would do"

---

## What To Do When You Hit a Red Flag

1. **STOP** current thought/action immediately
2. **RECOGNIZE** you're about to violate mandatory workflow
3. **RETURN** to the correct process (gate requirements, TDD, dispatch specialist, etc.)
4. **DOCUMENT** if there's pressure to skip (who, why, outcome)

---

## How to Reference This File

Skills should include:

```markdown
## Red Flags - STOP

See [shared-patterns/red-flags.md](../shared-patterns/red-flags.md) for universal red flags.

If you catch yourself thinking ANY of those patterns, STOP immediately and return to proper process.
```
