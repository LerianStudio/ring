---
name: ring:creating-worktrees
description: "Creating an isolated git worktree for parallel branch work: selects the directory by priority order, verifies/adds .gitignore safety, auto-installs the detected toolchain's dependencies, runs a baseline test, and reports readiness. Use before a feature that needs isolation from the main workspace or before executing an implementation plan. Skip for a quick fix on the current branch or when already in the feature's worktree."
---

# Using Git Worktrees

## When to use
- Starting feature that needs isolation from main workspace
- Before executing implementation plan
- Working on multiple features simultaneously

## Skip when
- Quick fix in current branch → stay in place
- Already in isolated worktree for this feature → continue
- Repository doesn't use worktrees → use standard branch workflow

## Sequence
**Runs before:** ring:writing-plans

Git worktrees create isolated workspaces sharing the same repository for parallel branch work.

**Announce at start:** "Using ring:creating-worktrees skill to set up isolated workspace."

## Directory Selection (priority order)

1. Existing `.worktrees/` or `worktrees/` directory
2. CLAUDE.md preference (`grep -i "worktree.*director" CLAUDE.md`)
3. Ask user: `.worktrees/` (project-local, hidden) OR `~/.config/ring/worktrees/<project>/` (global)

```bash
ls -d .worktrees worktrees 2>/dev/null
```

## Safety Verification

**Project-local directories only:** Verify `.gitignore` before creating:

```bash
grep -q "^\.worktrees/$\|^worktrees/$" .gitignore
```

Not in `.gitignore` → add it → commit → proceed. (Prevents accidentally tracking worktree contents.)

**Global directory** (`~/.config/ring/worktrees`): No verification needed.

## Creation Steps

```bash
# 1. Detect project name
project=$(basename "$(git rev-parse --show-toplevel)")

# 2. Create worktree
git worktree add "$path" -b "$BRANCH_NAME" && cd "$path"

# 3. Auto-detect and run setup
[ -f package.json ] && npm install
[ -f Cargo.toml ] && cargo build
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f pyproject.toml ] && poetry install
[ -f go.mod ] && go mod download

# 4. Verify clean baseline
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed.  
**If tests pass:** Report: `Worktree ready at <path> | Tests passing (<N> tests) | Ready to implement <feature>`

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify .gitignore) |
| Both `.worktrees/` and `worktrees/` exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → ask user |
| Directory not in .gitignore | Add immediately + commit |
| Tests fail during baseline | Report failures + ask |

## Non-Negotiables

- Project-local directories MUST be in .gitignore before creation
- Baseline test verification REQUIRED before proceeding with work
- Directory selection MUST follow priority order
- Dependency installation MUST run (auto-detect from project files)

## Integration

Pairs with **finishing-a-development-branch** for cleanup and **ring:running-dev-cycle** for work.
