---
name: ring:opening-pull-requests
description: >-
  Open a GitHub Pull Request with automatic base branch detection, scope
  allowlist enforcement, PR template filling, and post-create base verification.
  Replaces ring:generating-pr-descriptions. Use after pushing a branch when
  ready to open a PR. Skip if the branch is not yet pushed or there are
  uncommitted changes — commit first with ring:committing-changes.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

Open a GitHub Pull Request against the correct base branch, with a title that will pass scope validation and a body that fills the repo's PR template. Verifies the base after creation and corrects it automatically if GitHub defaulted to the wrong target.

## ⛔ HARD STOP — DO NOT CALL `gh pr create` BEFORE COMPLETING STEPS 1–6

Skipping detection steps is how PRs end up targeting `main` when the repo expects `develop`, or how PRs fail validation due to a missing or invalid scope. MUST complete every step in order.

---

## Step 1 — Detect Base Branch

NEVER assume the base. Run all three probes first, then apply the precedence rules below.

### Probes (run in parallel)

```bash
# Probe A — GitHub API default
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
# Fallback if gh unavailable: git remote show origin | grep 'HEAD branch' | awk '{print $NF}'

# Probe B — PR template hint
# Read .github/pull_request_template.md — note any explicit branch name mentioned

# Probe C — develop branch existence
git ls-remote --heads origin develop
```

### Precedence (apply in order — first match wins)

| Priority | Source | Rule |
|----------|--------|------|
| **1 — highest** | PR template | If `.github/pull_request_template.md` explicitly names a target branch, use it. Overrides everything. |
| **2** | develop exists + user confirms | If Probe C finds `develop` AND it differs from Probe A, show both options and ask the user to confirm. Use the user's choice. |
| **3 — fallback** | GitHub API default | Use the value from Probe A. |
| **4** | Neither detected | STOP — ask the user which branch to target. |

State the resolved `$BASE` and which source determined it before proceeding.

---

## Step 2 — Detect Scope Policy

MUST detect the allowlist before proposing the PR title. A title with a wrong or missing scope will fail PR validation and block the merge.

### 2.1 — Locate the policy file

Check in this order:

1. `.github/workflows/pr-validation.yml` (primary)
2. `.github/workflows/pr-title.yml`
3. `.github/workflows/commitlint.yml`
4. `.github/workflows/semantic-pull-request.yml`
5. Root configs: `commitlint.config.{js,cjs,mjs,ts}`, `.commitlintrc*`

### 2.2 — Extract allowed scopes and types

| Form | Example |
|------|---------|
| `scopes:` block (one per line) | Under `amannn/action-semantic-pull-request` |
| `scopes: a,b,c` inline | Comma-separated on one line |
| `scope-enum` rule | In commitlint config arrays |

Also extract any **type** restrictions — some repos limit allowed types beyond the default Conventional Commits set.

### 2.3 — Apply the policy

| Situation | Required Action |
|-----------|-----------------|
| Policy found, scope is clear | Use only scopes from the allowlist |
| Policy found, scope is ambiguous | STOP and ask the user which allowed scope to use |
| No policy file found | Infer a candidate scope from recent merged PRs first: `gh pr list --state merged --limit 15 --json title --jq '.[].title'`. Present the inferred scope to the user for confirmation; if no clear pattern emerges, ask the user for a scope. |

**NEVER** omit the scope. **NEVER** invent a scope not in the allowlist.

State the policy source and chosen scope before proceeding.

---

## Step 3 — Verify Preconditions

```bash
git status --porcelain                                  # check for uncommitted changes
git branch --show-current                               # confirm current branch name (empty in detached HEAD)
git fetch origin <current-branch> --quiet               # refresh remote ref before checking push state
git ls-remote --heads origin <current-branch>           # confirm branch exists on remote
git rev-list origin/<current-branch>..HEAD --count      # confirm no local commits ahead
```

| Condition | Detection | Required Action |
|-----------|-----------|-----------------|
| Uncommitted changes exist | `git status --porcelain` returns output | STOP — ask user to commit first with `ring:committing-changes` |
| Detached HEAD / no branch | `git branch --show-current` returns empty output | STOP — ask user to checkout or create a named branch first |
| Branch not on remote | `git ls-remote` returns no SHA for the branch | STOP — push first: `git push -u origin <branch>` |
| Local commits ahead of remote | `git rev-list origin/<branch>..HEAD --count` returns non-zero | STOP — push pending commits first: `git push` |

**Fail closed.** Check in this order: uncommitted changes → detached HEAD → branch on remote → no local commits ahead. Only continue when all four checks pass. Do NOT interpolate an empty branch name into `git ls-remote` or `git rev-list`.

---

## Step 4 — Read PR Template

```bash
cat .github/pull_request_template.md 2>/dev/null
```

If the template exists, use it as the body structure and fill in every section. If no template exists, use this default structure:

```markdown
## Summary

<!-- What does this PR do and why? -->

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Breaking Changes

None.

## Testing

- [ ] Unit tests pass
- [ ] Manually tested

## Related Issues

<!-- Closes #issue -->
```

---

## Step 5 — Gather Diff Context

```bash
git log origin/$BASE..HEAD --oneline
git diff origin/$BASE...HEAD --stat
```

Use this output to fill the PR body accurately.

---

## Step 6 — Draft PR Title and Body

### Title

```
<type>(<scope>): <description>
```

Requirements:
- Under 70 characters
- Lowercase, no period at the end
- Scope MUST come from the allowlist (Step 2)
- Type MUST be allowed per policy (Step 2)

Examples:
- `feat(auth): add OAuth2 refresh token support`
- `fix(api): handle null response in user endpoint`
- `chore(deps): update authentication dependencies`

### Body

Fill the PR template completely:

| Section | Instructions |
|---------|-------------|
| **Description/Summary** | Summarize what the PR does and why |
| **Type of Change** | Check boxes matching the commit type |
| **Breaking Changes** | Describe if applicable; otherwise "None." |
| **Testing** | Check applicable boxes; add CI run link if available |
| **Related Issues** | Fill only if user mentioned an issue; leave blank otherwise |

---

## Step 7 — Show Full Draft for Approval

Present the complete draft to the user:

```
PR Draft — waiting for your approval
─────────────────────────────────────
Base branch:  develop   (from: git ls-remote)
Scope policy: .github/workflows/pr-validation.yml → scopes: [api, auth, docs, ci]
Chosen scope: auth

Title:
  feat(auth): add OAuth2 refresh token support

Body:
  ## Summary
  Adds automatic token refresh when access token expires...
  ...

Command that will run:
  gh pr create --title "feat(auth): add OAuth2 refresh token support" \
               --body "..." \
               --base develop

Approve and create? [Yes / Edit title / Edit body / Cancel]
```

MUST wait for explicit user approval before executing `gh pr create`.

---

## Step 8 — Create the PR

```bash
gh pr create \
  --title "<title>" \
  --body "<body>" \
  --base $BASE
```

Capture the PR number from the output.

---

## Step 9 — Verify Base Branch

MUST verify the PR was opened against the expected base before reporting success. GitHub sometimes defaults to a different base.

```bash
gh pr view <number> --json baseRefName --jq '.baseRefName'
```

| Result | Action |
|--------|--------|
| Equals `$BASE` | Proceed — report success |
| Does NOT equal `$BASE` | Immediately retarget: `gh pr edit <number> --base $BASE` |

After retargeting, verify again:

```bash
gh pr view <number> --json baseRefName --jq '.baseRefName'
```

Only report success after the base is confirmed correct.

---

## Step 10 — Return PR URL

```bash
gh pr view <number> --json url --jq '.url'
```

Return the PR URL to the user.

---

## Anti-Patterns (FORBIDDEN)

- Do NOT call `gh pr create` before completing Steps 1–7 — bypassing detection causes PRs targeting the wrong base
- Do NOT hardcode `--base develop` or `--base main` — always pass `--base $BASE` resolved in Step 1
- Do NOT skip Step 9 (post-create verification) — GitHub may default to the wrong base
- Do NOT invent scopes — a scope not in the allowlist fails PR validation
- Do NOT omit the scope — every PR title MUST carry `type(scope): description`, never `type: description`

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "The repo always uses develop, I can hardcode it" | Any repo could be different. Detection takes 2 seconds. | **MUST detect with `git ls-remote`** |
| "I'll skip the post-create verification" | GitHub defaults to wrong bases frequently. The PR ends up merging into the wrong branch. | **MUST verify with `gh pr view --json baseRefName`** |
| "Scope is optional, nobody will notice" | PR validation workflow will block it and waste everyone's time. | **MUST include scope from allowlist** |
| "I'll guess the scope, it looks right" | Guessing breaks validation. Ask the user if ambiguous. | **MUST use only allowlist scopes** |
| "No PR template? I'll skip the body" | A minimal body is always better than an empty one. | **MUST use default structure if no template** |
| "Already opened PR, base looks fine" | GitHub silently defaults to wrong base. Verify explicitly. | **MUST run `gh pr view --json baseRefName`** |
