---
name: ring:creating-managed-sessions
description: "Opening managed tmux sessions/windows for feature worktrees when ai-tmux-sessions is installed: detects the integration, then for each worktree opens a tmux window (inside tmux) or a new detached session (outside tmux) with cwd pinned to the worktree path. Accepts worktree paths + slugs to run non-interactively (used by ring:writing-plans / ring:creating-worktrees). Use when the executor should run one tmux window per worktree. Skip when ai-tmux-sessions or tmux is absent, or when the user declined managed sessions."
---

# Creating Managed tmux Sessions

## When to use
- One or more worktrees exist (or are about to be created) and the executor should run in a dedicated tmux window/session per worktree
- The user opted into managed tmux sessions during the ring:writing-plans execution handoff
- Invoked in tandem with ring:creating-worktrees so each worktree gets its own tmux window with `cwd` on the worktree

## Skip when
- `ai-tmux-sessions` is not installed, or `tmux` is not on `PATH` → fall back to running the executor in place
- User declined managed sessions at the handoff prompt
- Only a single worktree/tree with no isolation need → just run the executor directly

## Sequence
This skill can be invoked two ways:
- **Standalone** — point it at one or more existing worktree paths to open tmux windows/sessions for them.
- **From ring:writing-plans / ring:creating-worktrees** — after the Worktree choice, when the user opts into managed sessions, invoked with the worktree path(s) + slug(s) so it runs non-interactively.

**Runs after:** ring:creating-worktrees (worktrees must exist before their windows open).
**Pairs with:** ring:writing-plans (offers the orthogonal managed-sessions question at the execution handoff).

**Announce at start:** "Using ring:creating-managed-sessions skill to open tmux windows for the worktrees."

## Parameters
- `worktrees` (optional): list of `{ path, slug }` pairs — one per worktree to open. When provided, the skill runs **non-interactively**: it opens one window/session per entry, named by `slug`, with `cwd` set to `path`.
  - `slug` MUST match the worktree/feature slug used by ring:creating-worktrees (`<feature-slug>`), so window names line up with the worktree path (`../<repo>-<feature-slug>/` or `../<project>-worktrees/<project>-<feature-slug>/`) and branch `feature/<feature-slug>`.
- When `worktrees` is **absent**, ask the user which existing worktree path(s) to open, then proceed with the same logic.

## Detection

Only proceed if BOTH are true:

```bash
[[ -f ~/.config/ai-sessions/ai-sessions.sh ]] && command -v tmux >/dev/null 2>&1
```

- `~/.config/ai-sessions/ai-sessions.sh` present → `ai-tmux-sessions` is installed.
- `tmux` on `PATH` → tmux is usable.

If either check fails, **do not** attempt any tmux commands. Report that managed sessions are unavailable and hand control back so the executor runs in place (tree/worktree without a managed window).

## Window vs Session Logic

The decision hinges on whether we are already inside a tmux client, detected via the `$TMUX` environment variable:

| Condition | Action | Command |
|-----------|--------|---------|
| `$TMUX` is set (inside tmux) | Add a **window** to the current session | `tmux new-window` |
| `$TMUX` is empty (outside tmux) | Create a **new detached session** | `tmux new-session -d` |

```bash
if [[ -n "$TMUX" ]]; then
  # Inside tmux → one window per worktree in the current session
  tmux new-window -n "$slug" -c "$worktree_path"
else
  # Outside tmux → new detached session, first worktree seeds the session
  project=$(basename "$(git rev-parse --show-toplevel)")
  session="ring-$project"
  tmux new-session -d -s "$session" -n "$slug" -c "$worktree_path"
fi
```

- **Inside tmux** (`$TMUX` set): every worktree becomes a `new-window` in the current session. No new session is created.
- **Outside tmux** (`$TMUX` empty): create ONE detached session `ring-<repo>` seeded with the first worktree, then add the remaining worktrees as `new-window -t ring-<repo>` inside it. The user attaches later with `tmux attach -t ring-<repo>`.

## Naming

- **Window name:** the worktree/feature `slug` (e.g. `payment-retry`). This keeps the window name aligned with the worktree directory (`../<repo>-<slug>/` or `../<project>-worktrees/<project>-<slug>/`) and branch `feature/<slug>`.
- **Session name (outside tmux):** `ring-<repo>` where `<repo>` is `basename "$(git rev-parse --show-toplevel)"`.
- Slugs come straight from ring:creating-worktrees; do not re-slugify differently here or names will drift from the worktree directories.

## Worktree Must Exist First

A window's `cwd` (`-c <path>`) must point to a real directory. If a target worktree does not exist yet:

1. Create it first via ring:creating-worktrees (`feature_name` → sibling `../<repo>-<slug>/`, or `<base_dir>/<project>-<slug>/` in orchestration mode; branch `feature/<slug>`).
2. Only then open the tmux window/session with `-c` on the freshly created path.

Never open a window with `-c` on a non-existent path — tmux errors out or falls back to the wrong cwd.

## Name Collisions

A window or session with the target name may already exist (re-run, resumed work).

**Existing window (inside tmux):**
```bash
if tmux list-windows -F '#{window_name}' 2>/dev/null | grep -qx "$slug"; then
  tmux select-window -t "$slug"   # reuse the existing window
else
  tmux new-window -n "$slug" -c "$worktree_path"
fi
```

**Existing session (outside tmux):**
```bash
if tmux has-session -t "$session" 2>/dev/null; then
  # session exists → add/select the window inside it instead of recreating
  if tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null | grep -qx "$slug"; then
    tmux select-window -t "$session:$slug"
  else
    tmux new-window -t "$session" -n "$slug" -c "$worktree_path"
  fi
else
  tmux new-session -d -s "$session" -n "$slug" -c "$worktree_path"
fi
```

If reuse is undesirable (e.g. a genuinely different worktree collides on the same slug), create with a timestamp suffix instead: `"${slug}-$(date +%H%M%S)"`.

## Teardown

**Default: leave windows/sessions open.** The user closes them manually when done (`tmux kill-window` / `tmux kill-session -t ring-<repo>`, or `exit` inside the pane). Managed sessions are a convenience for parallel work, not ephemeral scratch — auto-closing risks discarding an active shell. Only tear down when the user explicitly asks.

## Report

After opening, report per worktree:

```
Managed sessions ready:
  <slug> → window "<slug>" (cwd ../<repo>-<slug>/)   [inside tmux]
  <slug> → session "ring-<repo>" window "<slug>"      [outside tmux — attach: tmux attach -t ring-<repo>]
```

If detection failed: `ai-tmux-sessions/tmux not available — running executor in place, no managed sessions.`

## Quick Reference

| Situation | Action |
|-----------|--------|
| `~/.config/ai-sessions/ai-sessions.sh` missing or no `tmux` | Skip entirely, run executor in place |
| `$TMUX` set | `tmux new-window -n <slug> -c <path>` per worktree |
| `$TMUX` empty | `tmux new-session -d -s ring-<repo> -c <path>`, then `new-window -t ring-<repo>` for the rest |
| Worktree path does not exist | Create via ring:creating-worktrees first, then open window |
| Window/session name already exists | `select-window` to reuse, or add `-$(date +%H%M%S)` suffix |
| Finished with a window | Leave open by default; user closes manually |

## Non-Negotiables

- Detection (`ai-sessions.sh` present AND `tmux` on PATH) MUST pass before any tmux command runs.
- `$TMUX` presence decides window-vs-session — never create a new session when already inside tmux.
- Every window/session opens with `-c <worktree_path>` so `cwd` lands on the worktree.
- Worktrees MUST exist before their windows open.
- Windows/sessions are left open by default; teardown only on explicit request.

## Integration

Pairs with **ring:creating-worktrees** (creates the worktrees this skill opens windows for) and **ring:writing-plans** (offers the orthogonal managed-sessions choice at the execution handoff). Downstream, the chosen executor (ring:executing-plans / ring:dispatching-workflows / ring:running-dev-cycle) runs inside each managed window.
