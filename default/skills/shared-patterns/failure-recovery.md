# Universal Failure Recovery Pattern

Add this section to any skill with potential failure points:

## When You Violate This Skill

**Skills can be violated by skipping steps or doing things out of order.**

Add skill-specific violation recovery procedures:

### Violation Template

```markdown
### Violation: [Common violation name]

**How to detect:**
[What indicates this violation occurred]

**Recovery procedure:**
1. [Step 1 to recover]
2. [Step 2 to recover]
3. [Step 3 to recover]

**Why recovery matters:**
[Explanation of why you can't just continue]
```

**Example:**

Violation: Wrote implementation before test (in TDD)

**How to detect:**
- Implementation file exists but no test file
- Git history shows implementation committed before test

**Recovery procedure:**
1. Stash or delete the implementation code
2. Write the failing test first
3. Run test to verify it fails
4. Rewrite the implementation to make test pass

**Why recovery matters:**
The test must fail first to prove it actually tests something. If implementation exists first, you can't verify the test works - it might be passing for the wrong reason or not testing anything at all.

---

## When Things Go Wrong

**If you get stuck:**

1. **Attempt failed?**
   - Document exactly what happened
   - Include error messages verbatim
   - Note what you tried

2. **Can't proceed?**
   - State blocker explicitly: "Blocked by: [specific issue]"
   - Don't guess or work around
   - Ask for help

3. **Confused?**
   - Say "I don't understand [specific thing]"
   - Don't pretend to understand
   - Research or ask for clarification

4. **Multiple failures?**
   - After 3 attempts: STOP
   - Document all attempts
   - Reassess approach with human partner

**Never:** Pretend to succeed when stuck
**Never:** Continue after 3 failures
**Never:** Hide confusion or errors
**Always:** Be explicit about blockage
