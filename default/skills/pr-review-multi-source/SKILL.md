---
name: ring:pr-review-multi-source
description: |
  PR-aware code review orchestrator that fetches PR metadata AND existing review
  comments from ALL sources (CodeRabbit, human reviewers, CI), dispatches Ring's
  7 specialized reviewer agents to evaluate BOTH code AND existing comments, and
  presents consolidated findings with source attribution. Batch applies approved
  fixes at the end and responds to PR comment threads with resolution status.

  Adapted from alexgarzao/optimus (optimus-pr-review).

trigger: |
  - When user provides a PR URL for review (e.g., "review this PR: https://github.com/org/repo/pull/123")
  - When user asks to review a pull request with multi-source comment analysis
  - When user wants to evaluate existing CodeRabbit or human review comments alongside fresh agent review

skip_when: |
  - No PR URL provided and user wants a generic code review (use ring:requesting-code-review directly)
  - PR is already merged or closed (nothing actionable to review)
  - User wants to run automated checks only (no interactive review needed)
  - User wants a code review without PR context (use ring:requesting-code-review)

NOT_skip_when: |
  - "The PR is small" → Small PRs still benefit from structured review with PR context and comment analysis.
  - "I already looked at the diff" → Specialist agents catch issues human review misses.
  - "CI passed" → CI checks automated rules; agents review logic, security, and quality.
  - "CodeRabbit already reviewed" → Agents validate/contest CodeRabbit findings and catch what it misses.
  - "Human reviewers already approved" → Agent review provides systematic coverage that human review may miss.

related:
  complementary:
    - ring:requesting-code-review
    - ring:code-reviewer
    - ring:security-reviewer
    - ring:business-logic-reviewer
    - ring:test-reviewer
    - ring:nil-safety-reviewer
    - ring:consequences-reviewer
    - ring:dead-code-reviewer
  differentiation:
    - name: ring:requesting-code-review
      difference: |
        ring:requesting-code-review is Gate 4 of the dev cycle — a generic code review
        that works on git diff without PR context. ring:pr-review-multi-source adds PR
        metadata (description, linked issues), collects existing comments from ALL sources
        (CodeRabbit, human reviewers, CI), and has agents validate/contest them with
        source attribution.
  sequence:
    before:
      - ring:requesting-code-review

verification:
  automated:
    - command: "which gh 2>/dev/null && echo 'available'"
      description: gh CLI is installed
      success_pattern: available
  manual:
    - PR metadata and comments fetched correctly
    - Source attribution present in all findings
    - All findings presented interactively
    - Approved fixes applied in batch
    - PR readiness verdict presented
    - PR comment threads replied with resolution status
---

# PR Review Multi-Source

PR-aware code review orchestrator. Fetches PR metadata, collects existing review comments from all sources (CodeRabbit, human reviewers, CI), dispatches Ring's 7 specialized reviewer agents to evaluate both code and existing comments, and presents findings with source attribution.

> Adapted from [alexgarzao/optimus](https://github.com/alexgarzao/optimus) (optimus-pr-review).

---

## Phase 0: Fetch PR Context

### Step 0.1: Obtain PR URL

If the user provided a PR URL, use it directly.

If no URL was provided, attempt to find the PR for the current branch:

```bash
gh pr view --json url,number,title --jq '.url' 2>/dev/null
```

If no PR is found, inform the user that a PR URL is required.

### Step 0.2: Fetch PR Metadata

Use `gh pr view` to extract all relevant metadata:

```bash
gh pr view <PR_NUMBER_OR_URL> --json title,body,state,headRefName,baseRefName,changedFiles,additions,deletions,labels,milestone,assignees,reviewRequests,comments,url,number
```

**Guard: Check PR state.** If the PR state is `MERGED` or `CLOSED`, inform the user and STOP. Only open PRs should be reviewed.

If the command fails (invalid URL, PR not found, or permission denied), inform the user and ask for a corrected URL.

Extract and store:
- **Title and description** — the PR's purpose and context
- **Head branch and base branch** — for accurate diff
- **Changed files count** — scope indicator
- **Labels and milestone** — categorization context
- **Linked issues** — from PR description (look for "Fixes #", "Closes #", "Resolves #" patterns)

### Step 0.3: Collect Existing PR Comments

Collect ALL comments from ALL sources on the PR:

**General PR comments:**
```bash
gh pr view <PR_NUMBER_OR_URL> --comments
```

**Review comments (inline code comments and review summaries):**
```bash
gh api --paginate repos/{owner}/{repo}/pulls/{number}/reviews
gh api --paginate repos/{owner}/{repo}/pulls/{number}/comments
```

For each comment, extract and categorize:
- **Source:** Identify the author — CodeRabbit (bot), human reviewer (by username), CI/CD bot, or other automated tool
- **Type:** General comment, inline code comment, review summary, or approval/request-changes
- **File and line** (for inline comments) — map to the changed files
- **Content** — the actual feedback
- **Status:** Resolved/unresolved (if the platform tracks it)
- **comment_id:** The REST API comment ID (numeric)
- **node_id:** The GraphQL node ID (e.g., `PRR_...`, `PRRC_...`) — required for Phase 9 thread resolution

**Duplicated comments sections:**
Some review tools (e.g., CodeRabbit) group repeated or similar comments under sections titled "Duplicated Comments" or similar headings. These contain valid feedback. You MUST:
1. Parse these sections and extract each individual comment
2. Treat them as regular review comments — do NOT skip them because they are labeled as "duplicated"
3. Map each duplicated comment to the affected files/lines listed in the section

Group comments by source:
```
PR Comments:
  - CodeRabbit: X comments (Y inline, Z summary, W from duplicated sections)
  - Human reviewers: X comments from [usernames]
  - CI/CD: X comments
  - Unresolved threads: X
```

### Step 0.4: Checkout PR Branch

Ensure the working tree matches the PR state:

```bash
gh pr checkout <PR_NUMBER_OR_URL>
```

If already on the correct branch, skip this step. If checkout fails due to uncommitted changes, inform the user and ask them to stash or commit their changes first.

### Step 0.5: Fetch Changed Files

Get the list of files changed in the PR:

```bash
gh pr diff <PR_NUMBER_OR_URL> --name-only
```

Read the full content of each changed file for the review agents.

Use TodoWrite to track progress through the phases.

---

## Phase 1: Present PR Summary

Present a summary of the PR to the user before starting the review:

```markdown
## PR Review: #<number> — <title>

**Branch:** <head> → <base>
**Changed files:** X files (+Y additions, -Z deletions)
**Labels:** [label1, label2]
**Linked issues:** #issue1, #issue2

### PR Description
<PR body/description>

### Existing Review Comments
- **CodeRabbit:** X comments (Y unresolved)
- **Human reviewers:** X comments from [usernames] (Y unresolved)
- **CI/CD:** X comments

### Changed Files
- file1.go
- file2.go
- file3_test.go
```

---

## Phase 2: Determine Review Type

Ask the user which type of review to run:

- **Initial** (5 agents) — correctness and critical gaps, suitable for in-progress PRs.
  Dispatches: ring:code-reviewer, ring:business-logic-reviewer, ring:security-reviewer, ring:test-reviewer, ring:nil-safety-reviewer
- **Final** (7 agents) — full coverage including ripple effects and dead code, suitable for PRs ready to merge.
  Dispatches all 7: adds ring:consequences-reviewer and ring:dead-code-reviewer

---

## Phase 3: Parallel Agent Dispatch

### Step 3.1: Discover Project Context

1. **Identify stack:** Check for `go.mod`, `package.json`, `Makefile`, `Cargo.toml`, etc.
2. **Identify test commands:** Look in `Makefile`, `package.json` scripts, or CI config for lint, unit test, integration test, and E2E test commands
3. **Identify coding standards:** Look for `PROJECT_RULES.md`, linter configs, or equivalent
4. **Identify reference docs:** Look for PRD, TRD, API design, data model

Store discovered commands for use in the verification gate (Phase 7):
```
LINT_CMD=<discovered lint command>
TEST_UNIT_CMD=<discovered unit test command>
TEST_INTEGRATION_CMD=<discovered integration test command>
TEST_E2E_CMD=<discovered E2E test command>
```

### Step 3.2: Dispatch Agents

Dispatch ALL applicable agents simultaneously via the Task tool. Each agent receives:
- The full content of every changed file
- The PR context (description, linked issues)
- ALL existing PR comments (so agents can validate/contest them)
- Coding standards and reference docs

**Agent prompt MUST include:**

```
PR Context:
  - PR #<number>: <title>
  - Purpose: <PR description summary>
  - Linked issues: <list>
  - Base branch: <base>

Existing PR Comments (evaluate these — validate or contest each one):
  [paste all comments grouped by source, including comments from "Duplicated Comments" sections]

Review scope: Only the files changed in this PR.
Review type: Initial / Final.

Your job:
  1. Review the CODE for issues in your domain
  2. EVALUATE each existing PR comment in your domain:
     - AGREE: The comment is valid and should be addressed
     - CONTEST: The comment is incorrect or unnecessary (explain why)
     - ALREADY FIXED: The comment was addressed in a subsequent commit
  3. Report NEW findings not covered by existing comments

Required output format:
  ## New Findings
  For each: severity, file, line, description, recommendation

  ## Comment Evaluation
  For each existing comment in your domain:
  - Comment source and summary
  - Your verdict: AGREE / CONTEST / ALREADY FIXED
  - Justification
```

### Initial Review (5 agents)

| # | Agent | Focus |
|---|-------|-------|
| 1 | **ring:code-reviewer** | Architecture, design patterns, SOLID, DRY, maintainability |
| 2 | **ring:business-logic-reviewer** | Domain correctness, business rules, edge cases |
| 3 | **ring:security-reviewer** | Vulnerabilities, authentication, input validation, OWASP |
| 4 | **ring:test-reviewer** | Test coverage gaps, error scenarios, flaky patterns |
| 5 | **ring:nil-safety-reviewer** | Nil/null pointer safety, missing guards, panic paths |

### Final Review (7 agents — includes the 5 above plus)

| # | Agent | Focus |
|---|-------|-------|
| 6 | **ring:consequences-reviewer** | Ripple effects, caller chain impact, consumer contract integrity |
| 7 | **ring:dead-code-reviewer** | Orphaned code, dead dependencies, unreachable paths |

All agents MUST be dispatched in a SINGLE message with parallel Task calls.

---

## Phase 4: Consolidation

After ALL agents return:

1. **Merge** all new findings into a single list
2. **Merge** all comment evaluations into a single list
3. **Deduplicate** — if multiple agents flag the same issue, keep one entry and note which agents agreed
4. **Cross-reference** — for existing comments, note agreement/disagreement between agents and between agents and the original commenter
5. **Sort** by severity: CRITICAL > HIGH > MEDIUM > LOW
6. **Assign** sequential IDs (F1, F2, F3...)

### Source Attribution

Each finding MUST include its source(s):

| Source Type | Label |
|-------------|-------|
| New finding from agent review | `[Agent: <agent-name>]` |
| Existing CodeRabbit comment validated by agent | `[CodeRabbit + Agent: <agent-name>]` |
| Existing human review comment validated by agent | `[Reviewer: <username> + Agent: <agent-name>]` |
| Existing comment contested by agent | `[Contested: <source> vs Agent: <agent-name>]` |

---

## Phase 5: Present Overview

```markdown
## PR Review: #<number> — X findings

### New Findings (from agents)
| # | Severity | File | Summary | Agent(s) |
|---|----------|------|---------|----------|

### Validated Existing Comments
| # | Severity | File | Original Source | Summary | Validating Agent(s) |
|---|----------|------|----------------|---------|---------------------|

### Contested Comments
| # | Original Source | Comment Summary | Contesting Agent | Reason |
|---|----------------|----------------|-----------------|--------|

### Summary
- New findings: X (C critical, H high, M medium, L low)
- Validated comments: X
- Contested comments: X
- Already fixed: X
```

---

## Phase 6: Interactive Finding-by-Finding Resolution (collect decisions only)

Process ONE finding at a time, in severity order (CRITICAL first, LOW last). Include both new findings and validated existing comments. Present contested comments for user decision.

For EACH finding, present:

### 1. Finding Header

`## [SEVERITY] F# | [Category]`
- Source(s): which agent(s) and/or external reviewer(s) flagged this
- Agreement: which sources agree/disagree

### 2. Problem Description

- Clear description of the issue with code snippet if applicable
- For validated existing comments: show the original comment and the agent's validation
- For contested comments: show both the original comment and the agent's contestation
- Why it matters — what breaks, what risk it creates

### 3. Proposed Solutions

One or more approaches, each with:
- What changes
- Tradeoffs (complexity, performance, breaking changes)
- If it's a straightforward fix with no tradeoffs, state: "Direct fix, no tradeoffs."

Include a recommendation when one option is clearly better.

### 4. Wait for User Decision

**BLOCKING**: Do NOT advance to the next finding until the user decides.

The user may:
- Approve an option (e.g., "A", "B")
- Request more context
- Discard the finding
- Defer to a future version
- Group with the next finding if related

### 5. Record Decision

Internally record every decision: finding ID, source(s), chosen option (or "skip"/"defer"), and rationale if provided. Do NOT apply any fix yet — fixes are batched in Phase 7.

Use TodoWrite to track each finding's resolution status.

---

## Phase 7: Batch Apply All Approved Fixes

**IMPORTANT:** This phase starts ONLY after ALL findings have been presented and ALL decisions collected. No fix is applied during Phase 6.

### Step 7.1: Present Pre-Apply Summary

Before touching any code, show the user a summary of everything that will be changed:

```markdown
## Fixes to Apply (X of Y findings)

| # | Finding | Source | Decision | Files Affected |
|---|---------|--------|----------|---------------|
| F1 | [summary] | [Agent + CodeRabbit] | Option A | file1.go |
| F3 | [summary] | [Agent: Security] | Option B | auth.go |

### Skipped (Z findings)
| # | Finding | Source | Reason |
|---|---------|--------|--------|
| F2 | [summary] | [Reviewer: john] | User: out of scope |

### Deferred (W findings)
| # | Finding | Source | Destination |
|---|---------|--------|-------------|
| F5 | [summary] | [Agent: QA] | Backlog |
```

### Step 7.2: Apply All Fixes

Apply ALL approved fixes in a single pass:

1. Group fixes by file to minimize file I/O
2. Apply all changes
3. Run lint — if format issues, fix and re-run
4. Run unit tests — if failures, diagnose and fix (max 3 attempts per failure)
5. If a fix causes test failures after 3 attempts, revert that specific fix, present the failure to the user, and ask for guidance

### Step 7.3: Verification Gate

After all fixes applied, run the full gate using discovered project commands:
- Always run lint and unit tests
- If backend files were changed: also run integration tests
- If frontend files were changed: also run E2E tests (if available)

All commands MUST pass before proceeding to Phase 8.

---

## Phase 8: Final Summary

```markdown
## PR Review Summary: #<number> — <title>

### Sources Analyzed
- CodeRabbit comments: X evaluated (Y validated, Z contested)
- Human reviewer comments: X evaluated (Y validated, Z contested)
- New agent findings: X
- Already fixed: X

### Fixed (X findings)
| # | Source | File(s) | Fix Applied |
|---|--------|---------|-------------|

### Skipped (X findings)
| # | Source | File(s) | Reason |
|---|--------|---------|--------|

### Deferred (X findings)
| # | Source | File(s) | Destination |
|---|--------|---------|-------------|

### Verification
- Lint: PASS
- Unit tests: PASS (X tests)
- Integration tests: PASS / SKIPPED
- E2E tests: PASS / SKIPPED

### PR Readiness
- [ ] All CRITICAL/HIGH findings resolved
- [ ] Changes align with PR description and linked issues
- [ ] No unrelated changes included in the PR
- [ ] Test coverage adequate for the changes

**Verdict:** READY FOR MERGE / NEEDS CHANGES
```

**Do NOT commit automatically.** Present the summary and ask the user if they want to commit.

---

## Phase 9: Respond to PR Comments

After the user commits (or explicitly skips commit), respond to each existing PR comment thread that was evaluated during the review.

### Step 9.1: Identify Comment Threads to Respond

For each existing PR comment that was evaluated by agents, determine the appropriate response based on the user's decision:

| Decision | Action |
|----------|--------|
| **Fixed** | Reply with the commit SHA and mark as resolved |
| **Skipped/Discarded** | Reply explaining why it won't be fixed |
| **Deferred** | Reply explaining it was deferred and where it was tracked |
| **Contested** | Reply explaining why the comment was contested |
| **Already fixed** | Reply noting it was already addressed |

### Step 9.2: Post Replies and Resolve Threads

For each comment thread, post the reply AND resolve the conversation on GitHub:

**For inline review comments (most common):**
```bash
# Post the reply
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --method POST \
  -f body="<reply>" \
  -F in_reply_to=<comment_id>
```

**For general PR comments:**
```bash
gh pr comment <PR_NUMBER_OR_URL> --body "<reply>"
```

**Resolve the conversation thread** (for review comment threads):
```bash
gh api graphql -f query='
  mutation {
    resolveReviewThread(input: {threadId: "<thread_node_id>"}) {
      thread { isResolved }
    }
  }
'
```

To get the thread node ID, query the PR's review threads with pagination:
```bash
# Paginate reviewThreads — repeat until hasNextPage is false
cursor=""
all_threads="[]"
while true; do
  after_arg=""
  if [ -n "$cursor" ]; then after_arg=", after: \"$cursor\""; fi

  result=$(gh api graphql -f query="
    query {
      repository(owner: \"<owner>\", name: \"<repo>\") {
        pullRequest(number: <number>) {
          reviewThreads(first: 100${after_arg}) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              isResolved
              comments(first: 100) {
                nodes { id body }
              }
            }
          }
        }
      }
    }
  ")

  # Accumulate nodes (merge with jq or equivalent)
  all_threads=$(echo "$all_threads" "$result" | jq -s '.[0] + [.[1].data.repository.pullRequest.reviewThreads.nodes[]]')

  has_next=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')
  if [ "$has_next" != "true" ]; then break; fi
  cursor=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor')
done
```

**Note:** For PRs with >100 comments per thread, add a similar inner pagination loop on `comments`. In practice, most threads have <10 comments, so `first: 100` on comments is sufficient for the inner query.

Match each thread by comparing the REST comment's `node_id` (collected in Step 0.3) against any comment's `id` in `comments.nodes[*]`, then resolve using the thread's `id`. Do NOT use `databaseId` — it is deprecated in GitHub's GraphQL API.

### Step 9.3: Reply Templates

**Fixed:**
```
Fixed in <commit_sha>.
```

**Skipped/Discarded:**
```
Won't fix: <user's reason or rationale>.
```

**Deferred:**
```
Deferred to <destination> (e.g., backlog, future PR): <brief reason>.
```

**Contested:**
```
Contested: <agent's reasoning for why the comment is incorrect or unnecessary>.
```

**Already fixed:**
```
Already addressed in a previous commit.
```

### Step 9.4: Present Reply Summary

After posting all replies, present a summary:

```markdown
### PR Comment Replies Posted
| # | Thread | Source | Reply | Status |
|---|--------|--------|-------|--------|
| 1 | file.go:42 | CodeRabbit | Fixed in abc1234 | Resolved |
| 2 | file.go:88 | @reviewer | Won't fix: out of scope | Closed |
| 3 | general | CodeRabbit | Deferred to backlog | Closed |
```

---

## Rules

- MUST fetch PR metadata AND existing comments before starting the review
- Agents MUST evaluate existing comments — validate, contest, or mark as already fixed
- Every finding MUST include source attribution (agent, CodeRabbit, human reviewer)
- MUST NOT review files outside the PR scope — only files changed in the PR
- MUST include PR description, linked issues, and existing comments in every agent prompt
- One finding at a time, severity order (CRITICAL > HIGH > MEDIUM > LOW)
- No changes without prior user approval — the user decides the approach
- Fixes are collected during Phase 6 and applied in batch during Phase 7
- MUST NOT merge the PR — only review and present findings
- MUST NOT commit fixes without explicit user approval
- After commit, MUST reply to every existing PR comment thread with resolution status
- If `gh` CLI is not installed, inform the user and suggest installation (e.g., `brew install gh` on macOS). If installed but not authenticated, ask the user to run `gh auth login`
