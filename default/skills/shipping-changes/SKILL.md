---
name: ring:shipping-changes
description: >-
  End-to-end git orchestrator: branch → commit → push → PR, with a full plan
  presented before any execution. Detects base branch and scope allowlist once
  and propagates to all phases. Use when ready to ship a complete unit of work.
  Skip if only one phase is needed: commit-only → ring:committing-changes,
  PR-only → ring:opening-pull-requests.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

End-to-end shipping workflow: detect base branch and scope policy once, present a complete plan, then execute branch → commit → push → PR in sequence, confirming at each phase. Uses `ring:committing-changes` and `ring:opening-pull-requests` internally — their rules and anti-patterns apply in full.

## ⛔ HARD STOP — PRESENT PLAN BEFORE EXECUTING ANY MUTATING COMMAND

Read-only discovery commands (`git fetch`, `git ls-remote`, `git status`, `git diff`, `git log`) are allowed before approval — they are needed to build the plan.

MUST complete Phase 0 detection, analyze the current state, and present a complete plan to the user before running any **mutating** `git` or `gh` command (`git checkout -b`, `git add`, `git commit`, `git push`, `gh pr create`). Executing mutating commands without approval is FORBIDDEN.

---

## Phase 0 — Detect Base Branch and Scope Policy

MUST complete both detections before analyzing changes or drafting anything. These values are resolved once and propagated to all subsequent phases.

### 0A — Detect Base Branch

```bash
# Probe A — GitHub API default (fallback: git remote show origin | grep 'HEAD branch' | awk '{print $NF}')
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'

# Probe B — PR template hint: read .github/pull_request_template.md for explicit branch name

# Probe C — develop existence
git ls-remote --heads origin develop
```

Apply precedence in order — first match wins:

| Priority | Source | Rule |
|----------|--------|------|
| **1 — highest** | PR template | Explicit branch name in `.github/pull_request_template.md` — overrides everything |
| **2** | develop + user | Probe C finds `develop` AND differs from Probe A → ask user to confirm which target |
| **3 — fallback** | GitHub API | Use value from Probe A |
| **4** | Neither | STOP — ask the user |

**Why not develop-first:** a repo may have a stale `develop` branch while the real PR target is `main`. The GitHub API is the authoritative source; `develop` existence triggers a confirmation step instead of a silent assumption.

### 0B — Detect Scope Policy

Check in this order:

1. `.github/workflows/pr-validation.yml` (primary)
2. `.github/workflows/pr-title.yml`
3. `.github/workflows/commitlint.yml`
4. `.github/workflows/semantic-pull-request.yml`
5. Root configs: `commitlint.config.{js,cjs,mjs,ts}`, `.commitlintrc*`

Extract the allowed `scope` list and any `type` restrictions.

| Situation | Required Action |
|-----------|-----------------|
| Policy found, scope is clear | Use only scopes from the allowlist |
| Policy found, scope is ambiguous | STOP and ask the user which allowed scope to use |
| No policy file found | MUST still include a scope — ask the user what scope to use |

---

## Phase 0C — Analyze Current State

```bash
git status
git branch
git diff
git log --oneline -5
```

Use this output for the plan.

---

## Phase 0D — Present Full Plan for Approval

Present everything before touching git:

```
Shipping Plan — waiting for your approval
──────────────────────────────────────────
Base branch:    develop   (from: git ls-remote)
Scope policy:   .github/workflows/pr-validation.yml → scopes: [api, auth, docs, ci]
Chosen scope:   auth

Phase 1 — Branch
  Current branch: main → will create: feat/add-oauth2-refresh
  Command: git checkout -b feat/add-oauth2-refresh origin/develop

Phase 2 — Commit
  Files to stage:
    - src/auth/oauth.ts (modified)
    - src/auth/oauth.test.ts (modified)
    - docs/auth/oauth-setup.md (modified)
  Proposed commits:
    1. feat(auth): add OAuth2 refresh token support
    2. docs(docs): update OAuth2 setup guide

Phase 3 — Push
  Command: git push -u origin feat/add-oauth2-refresh

Phase 4 — Pull Request
  Title:   feat(auth): add OAuth2 refresh token support
  Base:    develop
  Command: gh pr create --title "..." --body "..." --base develop

Approve and execute? [Yes / Modify / Cancel]
```

MUST wait for explicit user approval. Do NOT begin Phase 1 until approved.

---

## Phase 1 — Branch

### 1.1 — Check current branch

If already on a feature branch (not `$BASE`, not `main` when `$BASE=develop`):

```javascript
AskUserQuestion({
  questions: [{
    question: "You're already on a feature branch. How should I proceed?",
    header: "Branch",
    options: [
      { label: "Use current branch", description: "Continue on this branch" },
      { label: "Create new branch", description: "Create a new branch from origin/$BASE" }
    ]
  }]
});
```

### 1.2 — Create branch (if needed)

Branch naming convention: `<type>/<description>` in kebab-case.

```bash
git fetch origin --quiet
# Check for duplicate
git ls-remote --heads origin <type>/<description>

# If no duplicate:
git checkout -b <type>/<description> origin/$BASE
```

If a branch with the same name already exists on remote, ask the user for a different name.

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`

---

## Phase 2 — Commit

Delegate to `ring:committing-changes` with the resolved `$BASE` and scope policy as context.

**MUST propagate `$BASE`** to `ring:committing-changes` — Step 7 of that skill uses `origin/$BASE..HEAD` for commit batch scoping. Without it, the skill falls back to `@{u}` or re-detects the base, which works but is redundant when `$BASE` is already known here.

The following rules from `ring:committing-changes` apply in full:
- `$BASE` is already resolved — pass it explicitly so Step 7 skips re-detection
- Scope MUST come from the allowlist resolved in Phase 0B
- Scope MUST be included in every commit message — never omit
- Commits MUST be atomic and logically grouped
- Trailers via `--trailer "X-Lerian-Ref: 0x1"`, NEVER inside `-m`
- GPG sign with `-S` (no fallback — if no key, stop and instruct user to configure one)

---

## Phase 3 — Push

```bash
git push -u origin <current-branch>
```

Show the user:
- Branch name
- Number of commits being pushed
- Short summary of those commits

Confirm success before proceeding to Phase 4.

**NEVER** use `--force` or `--force-with-lease` unless the user explicitly requests it.

---

## Phase 4 — Pull Request

Delegate to `ring:opening-pull-requests` with the resolved `$BASE` and scope policy as context.

The following rules from `ring:opening-pull-requests` apply in full:
- PR title MUST carry `type(scope): description` with scope from allowlist
- Body MUST fill the repo's PR template
- MUST verify base branch after `gh pr create`
- MUST retarget with `gh pr edit <number> --base $BASE` if base is wrong
- MUST return PR URL after confirmed success

---

## Arguments

If an argument is provided (e.g., `/ring:shipping-changes feat/add-oauth2`), parse it as `<type>/<description>` for the branch name and skip the branch-naming question.

---

## Anti-Patterns (FORBIDDEN)

- Do NOT execute any `git` or `gh` command before presenting the plan and getting approval
- Do NOT hardcode `--base develop` or `--base main` — always use `$BASE` resolved in Phase 0A
- Do NOT skip Phase 0B scope detection — missing scope breaks PR validation
- Do NOT omit scope in commit messages or PR title
- Do NOT invent scopes not in the allowlist — ask the user if unclear
- Do NOT use `--force` on push unless the user explicitly asks
- Do NOT skip the post-PR-create base verification (delegated to `ring:opening-pull-requests`)
- Do NOT proceed to the next phase if the current phase fails — stop and ask the user

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I know the base branch, I can skip detection" | Any repo can change. Detection takes 2 seconds and prevents irreversible mistakes. | **MUST detect with `git ls-remote`** |
| "I'll present the plan after I start" | The plan exists so the user can catch mistakes before they happen. | **MUST present plan BEFORE any execution** |
| "Scope detection is only for PRs" | Commit messages also need the allowlist scope — they're validated together. | **MUST detect scope before Phase 2** |
| "The user approved the plan, I can skip confirmations per phase" | Phases can fail independently. Each phase confirms its own success. | **MUST confirm success at each phase** |
| "I'll use the same scope as last time" | Each repo may have a different allowlist. Re-detect for every invocation. | **MUST detect scope from the current repo** |
| "Branch creation failed but I'll continue" | Subsequent phases depend on the branch existing. | **MUST stop and ask the user on any failure** |
| "Force push is fine since it's a feature branch" | `--force` rewrites history. Only do this on explicit user request. | **MUST NOT force push without explicit request** |
