---
name: ring:creating-worktrees
description: "Creating an isolated git worktree for parallel branch work: selects the directory by priority order, verifies/adds .gitignore safety, and reports readiness. Accepts an optional feature_name to skip interactive prompts (used by ring:writing-plans). Dependency install and baseline test are optional (opt-in). Use before a feature that needs isolation from the main workspace or after an implementation plan is ready. Skip for a quick fix on the current branch or when already in the feature's worktree."
---

# Using Git Worktrees

## When to use
- Starting feature that needs isolation from main workspace
- After an implementation plan is ready, before executing it
- Working on multiple features simultaneously

## Parameters
- `feature_name` (optional): when provided (e.g. passed by ring:writing-plans),
  the skill runs **non-interactively**. It derives:
  - branch name → `feature/<feature-slug>`
  - path → `.worktrees/<feature-slug>/`
  where `<feature-slug>` is `feature_name` slugified (lowercase, spaces/underscores → hyphens).
  No directory-selection prompt is shown; `.worktrees/` is used directly (with the same .gitignore safety check).
- When `feature_name` is **absent**, the skill runs interactively exactly as before (directory selection, prompts).

## Skip when
- Quick fix in current branch → stay in place
- Already in isolated worktree for this feature → continue
- Repository doesn't use worktrees → use standard branch workflow

## Sequence
This skill can be invoked two ways:
- **Standalone** — before any work begins, to isolate a feature from the main workspace (interactive).
- **From ring:writing-plans** — after the plan is ready, during the Execution Handoff, invoked with a `feature_name` so it runs non-interactively.

**Runs after:** ring:writing-plans (when invoked via its Execution Handoff).

Git worktrees create isolated workspaces sharing the same repository for parallel branch work. Because the worktree shares the same `.git` and the surrounding environment is already configured, dependency install and baseline tests are **not** required for the Ring plan-driven flow — they are opt-in (see Optional Setup).

**Announce at start:** "Using ring:creating-worktrees skill to set up isolated workspace."

## Directory Selection (priority order)

> Skipped when `feature_name` is provided — the path is fixed to `.worktrees/<feature-slug>/` (still subject to the .gitignore safety check below).

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

# When feature_name is provided (non-interactive):
#   slug=$(echo "$feature_name" | tr '[:upper:] _' '[:lower:]--' | tr -s '-')
#   BRANCH_NAME="feature/$slug"
#   path=".worktrees/$slug/"

# 2. Create worktree
git worktree add "$path" -b "$BRANCH_NAME" && cd "$path"
```

**Report on success:** `Worktree ready at <path> | Branch <BRANCH_NAME> | Ready to implement <feature>`

## Optional Setup (opt-in)

Dependency install and baseline test are **not run by default**. In the Ring flow the worktree shares the same `.git` and the environment is already configured, so they are unnecessary. Run them only when the dev explicitly asks — e.g. first-time setup of the project on a new machine.

```bash
# Install deps (only if requested)
[ -f package.json ] && npm install
[ -f Cargo.toml ] && cargo build
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f pyproject.toml ] && poetry install
[ -f go.mod ] && go mod download

# Baseline test (only if requested)
npm test / cargo test / pytest / go test ./...
```

**If a requested baseline test fails:** Report failures, ask whether to proceed.  
**If it passes:** add `| Tests passing (<N> tests)` to the readiness report.

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify .gitignore) |
| Both `.worktrees/` and `worktrees/` exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → ask user |
| Directory not in .gitignore | Add immediately + commit |
| `feature_name` provided | Skip prompts: branch `feature/<slug>`, path `.worktrees/<slug>/` |
| Requested baseline test fails | Report failures + ask |

## Non-Negotiables

- Project-local directories MUST be in .gitignore before creation
- When `feature_name` is absent, directory selection MUST follow priority order
- Dependency install and baseline test are OPTIONAL (opt-in) — run only when the dev explicitly requests them

## Integration

Pairs with **finishing-a-development-branch** for cleanup and **ring:running-dev-cycle** for work.
