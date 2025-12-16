---
name: using-git-worktrees
description: |
  Isolated workspace creation - creates git worktrees with smart directory selection
  and safety verification for parallel feature development.

trigger: |
  - Starting feature that needs isolation from main workspace
  - Before executing implementation plan
  - Working on multiple features simultaneously

skip_when: |
  - Quick fix in current branch → stay in place
  - Already in isolated worktree for this feature → continue
  - Repository doesn't use worktrees → use standard branch workflow

sequence:
  after: [brainstorming]
  before: [writing-plans, executing-plans]
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Directory Selection Process

**Priority order:** (1) Existing `.worktrees/` or `worktrees/` (2) CLAUDE.md preference (3) Ask user

```bash
ls -d .worktrees worktrees 2>/dev/null   # Check existing (prefer .worktrees)
grep -i "worktree.*director" CLAUDE.md    # Check project preference
```

**If none found, ask:** `.worktrees/` (project-local, hidden) OR `~/.config/ring/worktrees/<project>/` (global)

## Safety Verification

**Project-local directories:** MUST verify .gitignore before creating: `grep -q "^\.worktrees/$\|^worktrees/$" .gitignore`
- If NOT in .gitignore: Add it → commit → proceed (fix broken things immediately)
- **Why critical:** Prevents accidentally committing worktree contents

**Global directory (~/.config/ring/worktrees):** No verification needed - outside project.

## Creation Steps

```bash
# 1. Detect project
project=$(basename "$(git rev-parse --show-toplevel)")

# 2. Create worktree (path = $LOCATION/$BRANCH or ~/.config/ring/worktrees/$project/$BRANCH)
git worktree add "$path" -b "$BRANCH_NAME" && cd "$path"

# 3. Auto-detect and run setup
[ -f package.json ] && npm install
[ -f Cargo.toml ] && cargo build
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f pyproject.toml ] && poetry install
[ -f go.mod ] && go mod download

# 4. Verify clean baseline (npm test / cargo test / pytest / go test ./...)
```

**If tests fail:** Report failures, ask whether to proceed or investigate.
**If tests pass:** Report: `Worktree ready at <path> | Tests passing (<N> tests) | Ready to implement <feature>`

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify .gitignore) |
| `worktrees/` exists | Use it (verify .gitignore) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → Ask user |
| Directory not in .gitignore | Add it immediately + commit |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Skip .gitignore verification | Worktree contents tracked, pollute git status | Always grep .gitignore first |
| Assuming directory location | Inconsistency, violates conventions | Follow priority: existing > CLAUDE.md > ask |
| Proceeding with failing tests | Can't distinguish new vs pre-existing bugs | Report failures, get permission |
| Hardcoding setup commands | Breaks on different tools | Auto-detect from project files |

## Example Workflow

Announce → Check `.worktrees/` exists → Verify .gitignore → `git worktree add .worktrees/auth -b feature/auth` → `npm install` → `npm test` (47 passing) → Report ready

## Red Flags

**Never:**
- Create worktree without .gitignore verification (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking
- Assume directory location when ambiguous
- Skip CLAUDE.md check

**Always:**
- Follow directory priority: existing > CLAUDE.md > ask
- Verify .gitignore for project-local
- Auto-detect and run project setup
- Verify clean test baseline

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
- **executing-plans** or **subagent-driven-development** - Work happens in this worktree
