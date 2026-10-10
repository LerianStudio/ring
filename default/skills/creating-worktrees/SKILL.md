---
name: ring:creating-worktrees
description: "Creating an isolated git worktree for parallel branch work: creates the worktree as a sibling of the repo (never inside it), asks the user where to place it (suggesting the default), and reports readiness. Accepts an optional feature_name to skip interactive prompts (used by ring:writing-plans) and an optional base_dir to group parallel worktrees under a shared parent. Dependency install and baseline test are optional (opt-in). Use before a feature that needs isolation from the main workspace or after an implementation plan is ready. Skip for a quick fix on the current branch or when already in the feature's worktree."
---

# Using Git Worktrees

## When to use
- Starting feature that needs isolation from main workspace
- After an implementation plan is ready, before executing it
- Working on multiple features simultaneously

## Where worktrees go (sibling of the repo, never inside it)

Worktrees are created **outside** the repository, as sibling directories — never inside the repo as a hidden `.worktrees/` folder. Two shapes:

- **Single feature** → a sibling directory of the repo:
  `../<repo>-<slug>/`
  (e.g. repo `med2`, feature `refund` → `../med2-refund/`)
- **Multiple features (orchestration mode)** → a sibling **grouping parent** directory, one subfolder per feature inside it:
  ```
  ../<project>-worktrees/
  ../<project>-worktrees/<project>-<slug-1>/
  ../<project>-worktrees/<project>-<slug-2>/
  ```
  Example (`med2`):
  ```
  ../med2-worktrees/
  ../med2-worktrees/med2-spi-block-balancer
  ../med2-worktrees/med2-infraction
  ../med2-worktrees/med2-refund
  ```
  `<project>` names the grouping parent (`<project>-worktrees`). Derive it from the project / the common prefix shared by the feature slugs, or **ask the user**.

**Always ask the user where to create the worktree(s)** — present the suggested default (the shapes above) and let them confirm or override with any path they prefer.

## Parameters
- `feature_name` (optional): when provided (e.g. passed by ring:writing-plans),
  the skill runs **non-interactively**. It derives:
  - branch name → `feature/<feature-slug>`
  - `<feature-slug>` = `feature_name` slugified (lowercase, spaces/underscores → hyphens)
  - path (default, when `base_dir` absent) → `../<repo>-<feature-slug>/`
- `base_dir` (optional): parent directory under which to create the worktree — used by orchestration mode to group parallel worktrees. When provided, path → `<base_dir>/<project>-<feature-slug>/`. Typically `../<project>-worktrees/`.
- When `feature_name` is **absent**, the skill runs interactively: it asks the user where to place the worktree, showing the sibling default as the pre-filled suggestion.

## Skip when
- Quick fix in current branch → stay in place
- Already in isolated worktree for this feature → continue
- Repository doesn't use worktrees → use standard branch workflow

## Sequence
This skill can be invoked two ways:
- **Standalone** — before any work begins, to isolate a feature from the main workspace (interactive: asks where to place it).
- **From ring:writing-plans** — after the plan is ready, during the Execution Handoff, invoked with a `feature_name` (and, in orchestration mode, a `base_dir`) so it runs non-interactively.

**Runs after:** ring:writing-plans (when invoked via its Execution Handoff).

Git worktrees create isolated workspaces sharing the same repository for parallel branch work. Because the worktree shares the same `.git` and the surrounding environment is already configured, dependency install and baseline tests are **not** required for the Ring plan-driven flow — they are opt-in (see Optional Setup).

**Announce at start:** "Using ring:creating-worktrees skill to set up isolated workspace."

## Location Selection

Compute the suggested default, then confirm with the user before creating.

```bash
# Repo name and its parent directory
repo=$(basename "$(git rev-parse --show-toplevel)")
parent=$(dirname "$(git rev-parse --show-toplevel)")
```

**Interactive (no `feature_name`):** ask the user where to create the worktree, offering the sibling default as the pre-filled suggestion:

```
Where should the worktree go?

  [default] ../<repo>-<slug>/        — sibling of this repo (recommended)
  [custom]  <any path you type>      — override with your own location
```

The user confirms the default or types an override. Never place the worktree inside the repo working tree unless the user explicitly asks for it.

**Non-interactive (`feature_name` provided):**
- `base_dir` absent → `../<repo>-<slug>/`
- `base_dir` present → `<base_dir>/<project>-<slug>/`

## Orchestration Mode (multiple features → shared grouping parent)

When creating worktrees for several features at once (driven by ring:writing-plans orchestration mode):

1. **Name the grouping parent.** Default `../<project>-worktrees/`. Derive `<project>` from the common prefix of the feature slugs, or **ask the user** to name it. Confirm the parent path with the user before creating anything.
2. **Create the parent once**, then one worktree subfolder per feature inside it: `<parent>/<project>-<slug>/`.

```bash
# Example: project=med2, parent=../med2-worktrees
mkdir -p "$parent_dir"                       # e.g. ../med2-worktrees
for slug in "${slugs[@]}"; do
  git worktree add "$parent_dir/$project-$slug" -b "feature/$slug"
done
```

## Safety Verification (only when placed inside the repo)

Sibling/grouping worktrees live **outside** the repo tree, so they are never tracked by git — no `.gitignore` change is needed for the default shapes.

**Only if the user overrides to a path inside the repo working tree**, verify `.gitignore` before creating so the worktree contents are not accidentally tracked:

```bash
# Only relevant when the chosen path is inside the repo (e.g. an in-repo worktrees dir)
grep -q "^worktrees/$\|^.worktrees/$" .gitignore
```

Not in `.gitignore` → add it → commit → proceed.

## Creation Steps

```bash
# 1. Detect repo name + parent
repo=$(basename "$(git rev-parse --show-toplevel)")
parent=$(dirname "$(git rev-parse --show-toplevel)")

# When feature_name is provided (non-interactive):
#   slug=$(echo "$feature_name" | tr '[:upper:] _' '[:lower:]--' | tr -s '-')
#   BRANCH_NAME="feature/$slug"
#   # single feature (no base_dir):
#   path="$parent/$repo-$slug"
#   # orchestration (base_dir provided, e.g. ../<project>-worktrees):
#   path="$base_dir/$project-$slug"

# 2. Create worktree (parent dir must exist for the grouping shape)
mkdir -p "$(dirname "$path")"
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
| Single feature | Sibling `../<repo>-<slug>/` (ask user to confirm) |
| Multiple features | Grouping parent `../<project>-worktrees/`, one `<project>-<slug>/` per feature |
| Choosing location | Always ask user; suggest the sibling default, allow override |
| `feature_name` provided, no `base_dir` | Skip prompts: branch `feature/<slug>`, path `../<repo>-<slug>/` |
| `feature_name` + `base_dir` provided | Skip prompts: branch `feature/<slug>`, path `<base_dir>/<project>-<slug>/` |
| User overrides to a path inside the repo | Ensure it is in `.gitignore` + commit before creating |
| Requested baseline test fails | Report failures + ask |

## Non-Negotiables

- Worktrees are created as **siblings of the repo**, never inside it (no hidden `.worktrees/` in the repo) unless the user explicitly overrides.
- The skill MUST ask the user where to place the worktree(s), presenting the suggested default; the user confirms or overrides.
- Multiple features share a single grouping parent `../<project>-worktrees/`, one subfolder per feature.
- A path placed inside the repo working tree MUST be in `.gitignore` before creation.
- Dependency install and baseline test are OPTIONAL (opt-in) — run only when the dev explicitly requests them.

## tmux Integration (managed sessions)

When invoked in tandem with managed tmux sessions — i.e. the user opted in during the ring:writing-plans execution handoff and `ai-tmux-sessions` is detected — the ring pairs worktree creation with ring:creating-managed-sessions: **after** each worktree is created, a tmux window (or a new detached session, when outside tmux) is opened with `cwd` pinned to the freshly created worktree path.

- The worktree MUST exist before its window opens — this skill runs first, then ring:creating-managed-sessions opens the window with `-c <path-worktree>`.
- Window/session names reuse the `<feature-slug>` this skill derives (window `<slug>`; session `ring-<repo>` when outside tmux), so tmux names line up with the worktree path (`../<repo>-<slug>/` or `../<project>-worktrees/<project>-<slug>/`) and branch `feature/<feature-slug>`.
- Detection and the window-vs-session logic (`$TMUX` present → `new-window`; absent → `new-session -d`) live entirely in ring:creating-managed-sessions; this skill only guarantees the worktree exists to point `cwd` at.

See **ring:creating-managed-sessions** for detection, naming, collisions, and teardown.

## Integration

Pairs with **finishing-a-development-branch** for cleanup, **ring:running-dev-cycle** for work, and **ring:creating-managed-sessions** to open a tmux window/session per created worktree.
