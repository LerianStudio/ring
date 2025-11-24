# Universal TodoWrite Integration

Add this requirement to skill starts:

## TodoWrite Requirement

**BEFORE starting this skill:**

1. Create todos for major phases:
```javascript
[
  {content: "Phase 1: [name]", status: "in_progress", activeForm: "Working on Phase 1"},
  {content: "Phase 2: [name]", status: "pending", activeForm: "Working on Phase 2"},
  {content: "Phase 3: [name]", status: "pending", activeForm: "Working on Phase 3"}
]
```

2. Update after each phase:
   - Mark complete when done
   - Move next to in_progress
   - Add any new discovered tasks

3. Never work without todos:
   - Skipping todos = skipping the skill
   - Mental tracking = guaranteed to miss steps
   - Todos are your external memory

**Example for debugging:**
```javascript
[
  {content: "Root cause investigation", status: "in_progress", ...},
  {content: "Pattern analysis", status: "pending", ...},
  {content: "Hypothesis testing", status: "pending", ...},
  {content: "Implementation", status: "pending", ...}
]
```

If you're not updating todos, you're not following the skill.
