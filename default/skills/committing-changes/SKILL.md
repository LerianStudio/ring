---
name: ring:committing-changes
description: >-
  Commit changes with scope allowlist enforcement, atomic grouping, GPG-signed
  conventional commits, and trailer management. Detects the repo's PR-validation
  scope policy before proposing any message. Use when the user asks to commit or
  has changes ready to record. Skip when the working tree is clean or the user
  wants raw git commands without grouping.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

Analyze changes, enforce scope policy, group them into coherent atomic commits, and create signed commits following repository conventions. This skill transforms a messy working directory into a clean, logical commit history — with a scope that will actually pass PR validation.

## ⛔ HARD STOP — READ SCOPE POLICY BEFORE ANYTHING ELSE

**The scope is REQUIRED in every commit message. It MUST come from the repo's allowlist.**

MUST detect the allowlist in Step 0 before analyzing or drafting any commit message. A commit with an invented or omitted scope will fail PR validation and block the PR.

---

## Step 0 — Detect Scope Policy

Many repos enforce an allowlist of valid `scope` values via a GitHub Actions workflow. Failing this check blocks the PR, so MUST detect it before proposing any commit message.

### 0.1 — Locate the policy file

Check in this order:

1. `.github/workflows/pr-validation.yml` (primary)
2. `.github/workflows/pr-title.yml`
3. `.github/workflows/commitlint.yml`
4. `.github/workflows/semantic-pull-request.yml`
5. Root configs: `commitlint.config.{js,cjs,mjs,ts}`, `.commitlintrc*`

### 0.2 — Extract the allowed scope list

Common forms to look for:

| Form | Example |
|------|---------|
| `scopes:` block (one per line) | Under `amannn/action-semantic-pull-request` |
| `scopes: a,b,c` inline | Comma-separated on one line |
| `scope-enum` rule | In commitlint config arrays |

Also note any **type** restrictions — some repos limit types beyond the default Conventional Commits set.

### 0.3 — Apply the policy

| Situation | Required Action |
|-----------|-----------------|
| Policy found, scope is clear | Use only scopes from the allowlist |
| Policy found, scope is ambiguous | STOP and ask the user which allowed scope to use |
| No policy file found | MUST still include a scope — ask the user what scope to use |

**NEVER** omit the scope. **NEVER** invent a scope not in the allowlist. A bare `type: description` is FORBIDDEN.

State the policy source and chosen scope to the user before proceeding.

---

## Step 1 — Gather Context

Run in parallel:

```bash
git status
git diff
git diff --cached
git log --oneline -10
```

---

## Step 2 — Analyze and Group Changes

For each changed file determine:
1. **Type**: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `style`, `perf`, `ci`, `build`
2. **Scope**: from the allowlist resolved in Step 0
3. **Logical group**: what other files belong with this change?

### Grouping Principles

| Principle | Description |
|-----------|-------------|
| **Feature + Tests** | Implementation and its tests go together |
| **Config Changes** | `package.json`, `tsconfig`, etc. grouped separately |
| **Documentation** | `README`, `docs/` changes grouped together |
| **Refactoring** | Pure refactors (no behavior change) separate |
| **Bug Fixes** | Each fix is atomic with its test |

### Single vs Multiple Commits

**Single commit when:**
- All changes belong to one coherent feature/fix
- User provides a specific message via argument
- Changes are minimal and related

**Multiple commits when:**
- Changes span different concerns (feature + docs + deps)
- Mix of features, fixes, and chores
- Better git history benefits future archaeology

---

## Step 3 — Determine Commit Order

Order matters for bisectability:

1. **Dependencies first** — so subsequent commits can use them
2. **Core changes** — implementation before consumers
3. **Tests with implementation** — keep them atomic
4. **Documentation last** — documents the final state

---

## Step 4 — Present Plan and Confirm

MUST get user confirmation before executing.

```
Proposed Commit Plan:
─────────────────────
Scope policy: .github/workflows/pr-validation.yml → allowed scopes: [api, auth, docs, ci]
Chosen scope: auth

1. feat(auth): add OAuth2 refresh token support
   - src/auth/oauth.ts (modified)
   - src/auth/oauth.test.ts (modified)

2. chore(deps): update authentication dependencies
   - package.json (modified)
   - package-lock.json (modified)

3. docs(docs): update OAuth2 setup guide
   - docs/auth/oauth-setup.md (modified)

Proceed with this plan? [Execute plan / Single commit / Let me review]
```

Use `AskUserQuestion` to confirm before proceeding.

---

## Step 5 — Draft Commit Messages

Every commit message MUST follow:

```
<type>(<scope>): <subject>

<body — optional>
```

- Subject: max 50 characters, imperative mood ("add" not "added")
- Body: wrap at 72 characters, explain motivation/context
- Scope: REQUIRED, from the allowlist — NEVER omit, NEVER invent

---

## Step 6 — Execute Commits

### ⛔ HARD STOP — TRAILER RULES

**THE MOST COMMON MISTAKE:** Putting trailer text INSIDE the `-m` quotes.

```bash
# ❌ WRONG — trailer text is INSIDE the -m quotes
git commit -m "feat(auth): add feature

X-Lerian-Ref: 0x1"

# ✅ CORRECT — --trailer is a SEPARATE argument OUTSIDE quotes
git commit -m "feat(auth): add feature" --trailer "X-Lerian-Ref: 0x1"
```

**Before writing ANY git commit command, verify:**

- [ ] `-m "..."` contains ONLY the commit message (no trailer text inside)
- [ ] `--trailer` flags are OUTSIDE and AFTER the `-m` parameter
- [ ] Command is structured as: `git commit -S -m "msg" --trailer "key: value"`

### Required Command Structure

```bash
git commit -S \
  -m "<type>(<scope>): <subject>" \
  -m "<body if needed>" \
  --trailer "X-Lerian-Ref: 0x1"
```

For each commit group, in order:

1. Stage only the files for this commit:
   ```bash
   git add <file1> <file2> ...
   ```

2. Create signed commit with trailer:
   ```bash
   git commit -S \
     -m "<type>(<scope>): <subject>" \
     -m "<body if needed>" \
     --trailer "X-Lerian-Ref: 0x1"
   ```

**If GPG signing fails:** check `git config user.signingkey` and `gpg --list-secret-keys`.

If no usable key is found, STOP — do NOT offer an unsigned path. Inform the user:

```
GPG signing is required. No usable signing key was found.

To proceed:
  1. Generate a key: gpg --gen-key
  2. Configure git:  git config --global user.signingkey <key-id>
  3. Re-run this skill.

Committing without -S is not an option — Step 7 will reject unsigned commits.
```

MUST wait for the user to configure a key before continuing. NEVER drop `-S` silently or offer "unsigned" as a fallback.

3. Repeat for each commit group.

---

## Step 7 — Verify Commits

First, resolve the range ref for verification. `$BASE` may be provided by an orchestrating skill (e.g., `ring:shipping-changes`). Resolve in this order:

```bash
# 1. Upstream tracking ref (works when branch already has a remote tracking branch)
if git rev-parse @{u} >/dev/null 2>&1; then
  RANGE_REF="@{u}"

# 2. $BASE propagated by the orchestrating skill (e.g., ring:shipping-changes)
elif [ -n "$BASE" ]; then
  RANGE_REF="origin/$BASE"

# 3. Standalone: detect base branch via GitHub API
else
  BASE=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null \
    || git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
  RANGE_REF="origin/$BASE"
fi
```

Then verify every commit in the batch:

```bash
git log --oneline "$RANGE_REF..HEAD"

for commit in $(git rev-list "$RANGE_REF..HEAD"); do
  # %G? returns: G=good, U=unknown-validity, X/Y=expired, B=bad, E=missing key, N=no signature
  sig_status=$(git log -1 --format="%G?" "$commit")
  echo "$sig_status" | grep -qE '^[GU]' \
    || { echo "Commit $commit: signature invalid or insufficient (status=$sig_status)"; exit 1; }
  git log -1 --format="%(trailers)" "$commit" | grep -q '^X-Lerian-Ref: ' \
    || { echo "Commit $commit: X-Lerian-Ref trailer missing"; exit 1; }
done

git status
```

For each commit:
- Accept `G` (good) or `U` (unknown validity). Reject `X`/`Y` (expired key), `B` (bad signature), `E` (missing key), `N` (unsigned).
- If the trailer `grep` fails → stop and report the missing trailer.

**Why `U` is accepted:** `U` means the commit is cryptographically signed with a valid key, but GPG has not established a trust chain for that key (e.g., the key was not signed by a trusted introducer). This is the normal state for freshly generated keys or keys imported from colleagues without manual trust assignment. The signature itself is valid — it proves authorship. `G` additionally requires GPG's web-of-trust to vouch for the key identity, which is stricter than needed for commit attribution. Both are acceptable; only unsigned (`N`), bad (`B`), missing-key (`E`), and expired-key (`X`/`Y`) commits are rejected.

Note: when called from `ring:shipping-changes`, `$BASE` is already resolved in Phase 0 and propagated here — the `@{u}` and standalone detection paths are only needed for standalone invocations.

---

## Step 8 — Offer Push

After successful commit, ask the user:

```javascript
AskUserQuestion({
  questions: [{
    question: "Push commits to remote?",
    header: "Push",
    options: [
      { label: "Yes", description: "Push to current branch" },
      { label: "No", description: "Keep local only" }
    ]
  }]
});
```

If yes:
```bash
# Branch with upstream:
git push

# Branch without upstream:
git push -u origin <current-branch>
```

---

## Examples

### Feature commit
```bash
git commit -S \
  -m "feat(auth): add OAuth2 refresh token support" \
  -m "Implements automatic token refresh when access token expires." \
  --trailer "X-Lerian-Ref: 0x1"
```

### Bug fix
```bash
git commit -S \
  -m "fix(api): handle null response in user endpoint" \
  --trailer "X-Lerian-Ref: 0x1"
```

### Chore
```bash
git commit -S \
  -m "chore(deps): update dependencies to latest versions" \
  --trailer "X-Lerian-Ref: 0x1"
```

---

## Anti-Patterns (FORBIDDEN)

```bash
# ❌ WRONG — no scope
git commit -m "feat: add feature"

# ❌ WRONG — invented scope not in allowlist
git commit -m "feat(custom-scope): add feature"

# ❌ WRONG — trailer text inside -m
git commit -m "feat(auth): add feature

X-Lerian-Ref: 0x1"

# ❌ WRONG — emoji or hashtags in message body
git commit -m "feat(auth): add feature
🤖 Generated with Claude"

# ✅ CORRECT
git commit -S \
  -m "feat(auth): add feature" \
  --trailer "X-Lerian-Ref: 0x1"
```

---

## Trailer Query Commands

```bash
# Find commits with specific trailer value
git log --all --format="%H %s %(trailers:key=X-Lerian-Ref,valueonly)" | grep "0x1"

# Show all trailers for a commit
git log -1 --format="%(trailers)"
```

---

## When User Provides Message

If the user provides a commit message as an argument:
1. Use it as the subject/body
2. Validate it has a scope from the allowlist — if missing, ask which scope to use
3. Create signed commit with trailer

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll omit the scope for this one" | Every commit MUST carry a scope. A bare `type: description` fails PR validation. | **MUST include scope from allowlist** |
| "This scope isn't in the allowlist but it makes sense" | Invented scopes fail automated checks. The allowlist exists for a reason. | **MUST use only allowlist scopes or ask user** |
| "No policy file, so scope is optional" | Scope is always required. Without a policy, ask the user which scope to use. | **MUST ask user for scope if no policy found** |
| "I'll commit everything at once" | Mixed changes = messy history, hard to bisect/revert. | **Analyze and group changes first** |
| "Grouping takes too long" | Clean history saves hours of debugging later. | **Always propose commit plan** |
| "I'll put the trailer text in the message body" | `--trailer` is a GIT FLAG, not message text. | **Use `--trailer "X-Lerian-Ref: 0x1"` as separate argument** |
| "I'll skip GPG signing" | Unsigned commits fail Step 7 verification. There is no unsigned fallback path — configure a key and retry. | **MUST stop and instruct user to configure GPG key. NEVER drop `-S`** |
| "HEREDOC will format trailers correctly" | HEREDOC puts everything in the message body. | **Use `--trailer` flag, NOT HEREDOC** |
