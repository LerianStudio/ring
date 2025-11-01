---
name: writing-plans
description: Use when design is complete and you need detailed implementation tasks for engineers with zero codebase context - creates comprehensive implementation plans with exact file paths, complete code examples, and verification steps assuming engineer has minimal domain knowledge
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Zero-Context Test

**Before finalizing ANY plan, verify:**

```
Can someone execute this if they:
□ Never saw our codebase
□ Don't know our framework
□ Only have this document
□ Have no context about our domain

If NO to any → Add more detail
```

**Every task must be executable in isolation.**

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use ring:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Global Prerequisites:**
- Environment: [OS, runtime versions]
- Tools: [Exact commands to verify: `python --version`, `npm --version`]
- Access: [Any API keys, services that must be running]
- State: [Branch to work from, any required setup]

**Verification before starting:**
```bash
# Run ALL these commands and verify output:
python --version  # Expected: Python 3.8+
npm --version     # Expected: 7.0+
git status        # Expected: clean working tree
pytest --version  # Expected: 7.0+
```

---
```

## Task Structure

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Prerequisites:**
- Tools: pytest v7.0+, Python 3.8+
- Files must exist: `src/config.py`, `tests/conftest.py`
- Environment: `TESTING=true` must be set

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`

**Expected output:**
```
FAILED tests/path/test.py::test_name - NameError: name 'function' is not defined
```

**If you see different error:** Check file paths and imports

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`

**Expected output:**
```
PASSED tests/path/test.py::test_name
```

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
```

**If Task Fails:**

1. **Test won't run:**
   - Check: `ls tests/path/` (file exists?)
   - Fix: Create missing directories first
   - Rollback: `git checkout -- .`

2. **Implementation breaks other tests:**
   - Run: `pytest` (check what broke)
   - Rollback: `git reset --hard HEAD`
   - Revisit: Design may conflict with existing code

3. **Can't recover:**
   - Document: What failed and why
   - Stop: Return to human partner
   - Don't: Try to fix without understanding

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Required Patterns

This skill uses these universal patterns:
- **State Tracking:** See `skills/shared-patterns/state-tracking.md`
- **Failure Recovery:** See `skills/shared-patterns/failure-recovery.md`
- **Exit Criteria:** See `skills/shared-patterns/exit-criteria.md`
- **TodoWrite:** See `skills/shared-patterns/todowrite-integration.md`

Apply ALL patterns when using this skill.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use ring:subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses ring:executing-plans
