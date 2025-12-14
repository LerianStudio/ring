---
name: finishing-a-development-branch
description: |
  Branch completion workflow - guides merge/PR/cleanup decisions after implementation
  is verified complete.

trigger: |
  - Implementation complete (tests passing)
  - Ready to integrate work to main branch
  - Need to decide: merge, PR, or more work

skip_when: |
  - Tests not passing → fix first
  - Implementation incomplete → continue development
  - Already merged → proceed to next task

sequence:
  after: [ring-default:verification-before-completion, ring-default:requesting-code-review]
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

Run `npm test / cargo test / pytest / go test ./...` **If tests fail:** Show failures, stop. Cannot proceed until tests pass.

### Step 2: Determine Base Branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

### Step 3: Present Options

Present exactly these 4 options (no explanation):
1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

### Step 4: Execute Choice

| Option | Commands |
|--------|----------|
| **1. Merge Locally** | `git checkout <base>` → `git pull` → `git merge <feature>` → verify tests → `git branch -d <feature>` → Cleanup worktree |
| **2. Create PR** | `git push -u origin <feature>` → `gh pr create --title "..." --body "## Summary..."` → Cleanup worktree |
| **3. Keep As-Is** | Report: "Keeping branch <name>. Worktree preserved at <path>." **Don't cleanup.** |
| **4. Discard** | **Confirm first:** "Type 'discard' to confirm." → `git checkout <base>` → `git branch -D <feature>` → Cleanup worktree |

### Step 5: Cleanup Worktree

**Options 1, 2, 4:** `git worktree list | grep $(git branch --show-current)` → if in worktree: `git worktree remove <path>`
**Option 3:** Keep worktree.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Skipping test verification | Merge broken code, create failing PR | Always verify tests before offering options |
| Open-ended questions | "What should I do next?" → ambiguous | Present exactly 4 structured options |
| Automatic worktree cleanup | Remove worktree when might need it | Only cleanup for Options 1 and 4 |
| No confirmation for discard | Accidentally delete work | Require typed "discard" confirmation |

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
