---
name: ring:codereview
description: Run comprehensive parallel code review with all 7 specialized reviewers
argument-hint: "[files-or-paths]"
---

Dispatch all 7 specialized code reviewers in parallel, collect their reports, and provide a consolidated analysis.

## Review Process

### Step 0: Run Pre-Analysis Pipeline (MANDATORY)

**MANDATORY:** Before dispatching reviewers, run the pre-analysis pipeline to generate static analysis context.

```bash
# ⚠️ SYNC NOTE: This Mithril install logic is also in default/skills/requesting-code-review/SKILL.md (Step 2.5.1).
# If you change the install pattern or CLI flags, update both locations.
# Check if mithril is available
if ! command -v mithril &> /dev/null; then
    echo "mithril not found. Installing via go install..."
    if command -v go &> /dev/null; then
        go install github.com/lerianstudio/mithril@latest
        GOPATH_DIR="$(go env GOPATH)"
        [[ -n "$GOPATH_DIR" ]] && export PATH="$PATH:$GOPATH_DIR/bin"
    else
        echo "WARNING: Go is required to install mithril."
        echo "  Install Go from https://go.dev/dl/"
        echo "DEGRADED MODE: Proceeding without pre-analysis"
    fi
fi

# Run pre-analysis pipeline
if command -v mithril &> /dev/null; then
    BASE_REF=$(git merge-base HEAD main 2>/dev/null || echo "main")
    if mithril --base="$BASE_REF" --head=HEAD --output=docs/codereview --verbose; then
        echo "Pre-analysis pipeline completed successfully"
    else
        echo "WARNING: Pre-analysis pipeline failed"
        echo "DEGRADED MODE: Proceeding without pre-analysis"
    fi
fi
```

**Output:** Creates 7 context files in `docs/codereview/`:
- `context-code-reviewer.md`
- `context-security-reviewer.md`
- `context-business-logic-reviewer.md`
- `context-test-reviewer.md`
- `context-nil-safety-reviewer.md`
- `context-consequences-reviewer.md`
- `context-dead-code-reviewer.md`

⚠️ **DEGRADED MODE:** If mithril is not available, display warning and continue. Reviewers will work without pre-analysis context.

---

### Step 0.5: Review Slicing (Adaptive Cohesion-Based Grouping for Large PRs)

**See [shared-patterns/reviewer-slicing-strategy.md](../skills/shared-patterns/reviewer-slicing-strategy.md) for full rationale.**

After Mithril completes, determine whether the PR should be sliced into thematic groups for focused review. The slicer evaluates semantic cohesion between changed files — files that belong to the same package, import each other, or modify related functions are grouped together rather than split apart. This reuses the same logic as `ring:requesting-code-review` Step 2.7.

⚠️ **SYNC NOTE:** This enhanced input collection logic is shared with `default/skills/requesting-code-review/SKILL.md` (Step 2.7). If you change the inputs or collection approach, update both locations.

**Collect slicer inputs:**

```bash
# Reuse BASE_REF from Step 0 (already computed as git merge-base HEAD main)

# 1. FILE_LIST — flat list of changed file paths
FILE_LIST=$(git diff --name-only "$BASE_REF" HEAD)

# 2. DIFF_STATS — per-file insertion/deletion counts
DIFF_STATS=$(git diff --stat "$BASE_REF" HEAD)

# 3. PACKAGE_MAP — group changed files by Go package (directory) or TS module
#    Simple string operation: group file paths by their parent directory.
#    Example: { "internal/ledger": ["handler.go", "service.go"], "cmd/api": ["main.go"] }
PACKAGE_MAP=$(git diff --name-only "$BASE_REF" HEAD | while read -r f; do
  dir=$(dirname "$f")
  base=$(basename "$f")
  echo "$dir|$base"
done | sort)

# 4. IMPORT_HINTS — lightweight cross-reference between changed files
#    For each changed file, grep its import statements to find references
#    to other changed files' packages/paths.
#    Example: { "handler.go": ["service.go"], "service.go": ["repository.go"] }
IMPORT_HINTS=""
for f in $(git diff --name-only "$BASE_REF" HEAD); do
  if [[ -f "$f" ]]; then
    imports=$(grep -E '^import |^\t"' "$f" 2>/dev/null || true)
    if [[ -n "$imports" ]]; then
      IMPORT_HINTS="${IMPORT_HINTS}${f}:
${imports}
"
    fi
  fi
done

# 5. CHANGE_SUMMARY — extract hunk headers showing modified functions/methods
#    Example: handler.go: func CreateLedger, func UpdateLedger
CHANGE_SUMMARY=$(git diff "$BASE_REF" HEAD | grep -E '^@@.*@@' | sed 's/^@@ .* @@//' || true)
```

**Dispatch the slicer agent:**

```
Task tool (ring:review-slicer):
  subagent_type: "ring:review-slicer"
  description: "Classify PR files for adaptive cohesion-based review slicing"
  prompt: |
    ## Review Slicing Request

    Decide whether this PR should be sliced into thematic groups for review.
    Evaluate semantic cohesion: files that share a package, import each other,
    or modify related functions should stay together.

    ## Changed Files
    [FILE_LIST]

    ## Diff Stats
    [DIFF_STATS]

    ## Package Map
    [PACKAGE_MAP]

    ## Import Hints (cross-references between changed files)
    [IMPORT_HINTS]

    ## Change Summary (modified functions/methods)
    [CHANGE_SUMMARY]

    ## Mithril Context
    [MITHRIL_CONTEXT — from docs/codereview/ if available]

    Evaluate cohesion signals and return structured JSON.
```

**Graceful degradation:** If enhanced input collection (IMPORT_HINTS, PACKAGE_MAP, CHANGE_SUMMARY) fails for any reason, dispatch the slicer with the available inputs only (FILE_LIST and DIFF_STATS at minimum). The slicer handles missing signals gracefully — it will fall back to file-count and directory-based heuristics when cohesion signals are absent.

**Parse the slicer response:**

```text
IF slicer_response.shouldSlice == false:
  → Proceed to Step 1 as-is (standard full-diff dispatch)
  → Display: "Review slicing: not needed ([reasoning])"

IF slicer_response.shouldSlice == true:
  → Store slices for use in Step 1
  → Display: "Review sliced into [N] thematic groups: [slice names]"
  → Step 1 uses Sliced Dispatch mode (see conditional in Step 1 below)

IF slicer agent fails:
  → Log warning, fall back to standard full-diff dispatch
```

---

### Step 1: Dispatch All Seven Reviewers in Parallel

**CRITICAL: Use a single message with 7 Task tool calls to launch all reviewers simultaneously.**

**If slicing is NOT active:** Use the standard dispatch below as-is.

**If slicing IS active:** For EACH slice, dispatch all 7 reviewers with:
- Scoped diff: `git diff [BASE_REF] HEAD -- [slice files...]`
- Filtered Mithril context: only sections mentioning files in the slice
- Add to each reviewer prompt: `"Review Scope: Slice '[name]' — [description]"`
- After all slices complete, merge results and deduplicate per Step 3-S-Merge in `ring:requesting-code-review` SKILL.md

Gather the required context first:
- WHAT_WAS_IMPLEMENTED: Summary of changes made
- PLAN_OR_REQUIREMENTS: Original plan or requirements (if available)
- BASE_SHA: Base commit for comparison (if applicable)
- HEAD_SHA: Head commit for comparison (if applicable)
- DESCRIPTION: Additional context about the changes
- LANGUAGES: Go, TypeScript, or both (for ring:nil-safety-reviewer)

Then dispatch all 7 reviewers:

```
Task tool #1 (ring:code-reviewer):
  subagent_type: "ring:code-reviewer"
  description: "Review code quality and architecture"
  prompt: |
    WHAT_WAS_IMPLEMENTED: [summary of changes]
    PLAN_OR_REQUIREMENTS: [original plan/requirements]
    BASE_SHA: [base commit if applicable]
    HEAD_SHA: [head commit if applicable]
    DESCRIPTION: [additional context]

Task tool #2 (ring:business-logic-reviewer):
  subagent_type: "ring:business-logic-reviewer"
  description: "Review business logic correctness"
  prompt: |
    [Same parameters as above]

Task tool #3 (ring:security-reviewer):
  subagent_type: "ring:security-reviewer"
  description: "Review security vulnerabilities"
  prompt: |
    [Same parameters as above]

Task tool #4 (ring:test-reviewer):
  subagent_type: "ring:test-reviewer"
  description: "Review test quality and coverage"
  prompt: |
    [Same parameters as above]
    Focus: Edge cases, error paths, test independence, assertion quality.

Task tool #5 (ring:nil-safety-reviewer):
  subagent_type: "ring:nil-safety-reviewer"
  description: "Review nil/null pointer safety"
  prompt: |
    [Same parameters as above]
    LANGUAGES: [Go|TypeScript|both]
    Focus: Nil sources, propagation paths, missing guards.

Task tool #6 (ring:consequences-reviewer):
  subagent_type: "ring:consequences-reviewer"
  description: "Review ripple effects and downstream consequences"
  prompt: |
    [Same parameters as above]
    Focus: Caller chain impact, consumer contract integrity, shared state consequences, downstream breakage.

Task tool #7 (ring:dead-code-reviewer):
  subagent_type: "ring:dead-code-reviewer"
  description: "Review orphaned and dead code across three rings"
  prompt: |
    [Same parameters as above]
    Focus: Orphaned code detection across three rings (unreachable functions, unused exports, stale imports, abandoned feature flags).
```

**Wait for all seven reviewers to complete their work.**

### Step 2: Collect and Aggregate Reports

Each reviewer returns:
- **Verdict:** PASS/FAIL/NEEDS_DISCUSSION
- **Strengths:** What was done well
- **Issues:** Categorized by severity (Critical/High/Medium/Low/Cosmetic)
- **Recommendations:** Specific actionable feedback

Consolidate all issues by severity across all seven reviewers.

**If slicing was active:** Results are already merged and deduplicated per Step 3-S-Merge in `ring:requesting-code-review`. The dedup logic:
- **Exact match:** Same reviewer + same file:line = keep one
- **Fuzzy match:** Different reviewers/slices + same file:line + similar description = keep the more detailed one, note multi-reviewer confidence
- **Cross-cutting:** Issues found across 2+ slices are tagged as cross-cutting concerns and surfaced prominently

Add a note to the report: "Review was sliced into [N] thematic groups for deeper analysis."

### Conflict Resolution

When aggregating findings, detect and flag conflicting recommendations between reviewers:

| Conflict Type | Resolution | Priority |
|--------------|------------|----------|
| Security vs Performance | Security recommendation wins | CRITICAL |
| More tests vs Over-testing | Defer to ring:test-reviewer for test scope | MEDIUM |
| More mocks vs Less mocks | Evaluate based on ring:test-reviewer guidance | MEDIUM |
| Refactor vs Keep simple | Defer to ring:code-reviewer for architecture decisions | MEDIUM |

**Flagging Conflicts:**
When reviewers provide contradictory guidance:
1. Include BOTH recommendations in consolidated report
2. Add a "⚠️ Conflict" marker
3. Present to user for final decision
4. Do NOT automatically resolve conflicting recommendations

**Example:**
```
⚠️ Conflict Detected:
- ring:test-reviewer: "Add more mock isolation for external services"
- ring:code-reviewer: "Current mocking approach is sufficient"
- Resolution: User decision required - see both perspectives above
```

### Step 3: Provide Consolidated Report

Return a consolidated report in this format:

```markdown
# Full Review Report

## VERDICT: [PASS | FAIL | NEEDS_DISCUSSION]

## Executive Summary

[2-3 sentences about overall review across all gates]

**Total Issues:**
- Critical: [N across all gates]
- High: [N across all gates]
- Medium: [N across all gates]
- Low: [N across all gates]

---

## Code Quality Review (Foundation)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Issues
[List all critical code quality issues]

### High Issues
[List all high code quality issues]

[Medium/Low issues summary]

---

## Business Logic Review (Correctness)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Issues
[List all critical business logic issues]

### High Issues
[List all high business logic issues]

[Medium/Low issues summary]

---

## Security Review (Safety)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Vulnerabilities
[List all critical security vulnerabilities]

### High Vulnerabilities
[List all high security vulnerabilities]

[Medium/Low vulnerabilities summary]

---

## Test Quality Review (Coverage)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Issues
[Untested core logic, tests testing mock behavior]

### High Issues
[Missing edge cases, test anti-patterns]

[Medium/Low issues summary]

---

## Nil-Safety Review (Pointer Safety)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Issues
[Direct panic paths, unguarded nil dereference]

### High Issues
[Conditional nil risks, missing ok checks]

[Medium/Low issues summary]

---

## Consequences Review (Ripple Effect)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Issues
[Broken callers, violated contracts, downstream breakage]

### High Issues
[At-risk callers, stale consumer assumptions]

[Medium/Low issues summary]

---

## Dead Code Review (Hygiene)

**Verdict:** [PASS | FAIL]
**Issues:** Critical [N], High [N], Medium [N], Low [N]

### Critical Issues
[Unreachable functions, orphaned exports used by external consumers]

### High Issues
[Unused imports, abandoned feature flags, stale integration points]

[Medium/Low issues summary]

---

## Consolidated Action Items

**MUST FIX (Critical):**
1. [Issue from any gate] - `file:line`
2. [Issue from any gate] - `file:line`

**SHOULD FIX (High):**
1. [Issue from any gate] - `file:line`
2. [Issue from any gate] - `file:line`

**CONSIDER (Medium/Low):**
[Brief list]

---

## Next Steps

**If PASS:**
- ✅ All 7 reviewers passed
- ✅ Ready for next step (merge/production)

**If FAIL:**
- ❌ Fix all Critical/High/Medium issues immediately
- ❌ Add TODO(review) comments for Low issues in code
- ❌ Add FIXME(nitpick) comments for Cosmetic/Nitpick issues in code
- ❌ Re-run all 7 reviewers in parallel after fixes

**If NEEDS_DISCUSSION:**
- 💬 [Specific discussion points across gates]
```

## Severity-Based Action Guide

After producing the consolidated report, provide clear guidance:

**Critical/High/Medium Issues:**
```
These issues MUST be fixed immediately:
1. [Issue description] - file.ext:line - [Reviewer]
2. [Issue description] - file.ext:line - [Reviewer]

Recommended approach:
- Dispatch fix subagent to address all Critical/High/Medium issues
- After fixes complete, re-run all 7 reviewers in parallel to verify
```

**Low Issues:**
```
Add TODO comments in the code for these issues:

// TODO(review): [Issue description]
// Reported by: [reviewer-name] on [date]
// Severity: Low
// Location: file.ext:line
```

**Cosmetic/Nitpick Issues:**
```
Add FIXME comments in the code for these issues:

// FIXME(nitpick): [Issue description]
// Reported by: [reviewer-name] on [date]
// Severity: Cosmetic
// Location: file.ext:line
```

## Reviewer Failure Handling

If any reviewer fails during execution (timeout, error, incomplete output):

### Single Reviewer Failure

1. **Do NOT aggregate partial results** - Wait for all 7 reviewers
2. **Retry the failed reviewer once:**
   ```
   Task tool (retry failed reviewer):
     description: "Retry [reviewer-name] review"
     prompt: [same parameters as original]
   ```
3. **If retry fails:** Report which reviewer failed and why
4. **Continue with available results** only if user explicitly approves

### Multiple Reviewer Failures

1. **Stop and report** - Do not provide partial review
2. **Investigate root cause:**
   - Large codebase? Consider chunking files
   - Timeout? Increase timeout or reduce scope
   - Error? Check file paths and permissions
3. **Retry all failed reviewers** after addressing root cause

### Incomplete Output Detection

Signs that a reviewer produced incomplete output:

| Pattern | Detection Method | Action |
|---------|-----------------|--------|
| Missing VERDICT | Output lacks "## VERDICT:" or "**Verdict:**" | Re-dispatch reviewer |
| Empty Issues section | "## Issues Found" followed by no content or "None" only | Verify this is intentional (PASS case) |
| Missing required sections | Check against output_schema in agent definition | Re-dispatch with explicit section reminder |
| Truncated output | Ends mid-sentence or lacks closing sections | Re-dispatch with smaller scope |
| Generic responses | Only contains boilerplate without file-specific analysis | Re-dispatch with explicit file list |

**Validation Regex Patterns:**
- Verdict present: `/^##?\s*VERDICT:?\s*(PASS|FAIL|NEEDS_DISCUSSION)/im`
- Issues section: `/^##?\s*Issues Found/im`
- Summary present: `/^##?\s*(Summary|Executive Summary)/im`

**Action:** Re-dispatch the reviewer with explicit instruction to include all required sections.

## Remember

1. **All reviewers are independent** - They run in parallel, not sequentially
2. **Dispatch all 7 reviewers in parallel** - Single message, 7 Task calls
4. **Wait for all to complete** - Don't aggregate until all reports received
5. **Consolidate findings by severity** - Group all issues across reviewers
6. **Provide clear action guidance** - Tell user exactly what to fix vs. document
7. **Overall FAIL if any reviewer fails** - One failure means work needs fixes
8. **Retry failed reviewers once** - Don't give up on first failure

---

## Mithril Installation

Ring's pre-analysis pipeline requires [Mithril](https://github.com/LerianStudio/mithril), an external code analysis tool.

### Prerequisites

- [Go 1.22+](https://go.dev/dl/)

### Install via `go install`

```bash
go install github.com/lerianstudio/mithril@latest
```

Verify the installation:

```bash
mithril version
mithril --help
```

If `mithril` is not in your PATH after installation, add `$(go env GOPATH)/bin` to your shell's `PATH`.

## Security Model

Mithril is installed via `go install`, which uses Go's [module proxy](https://proxy.golang.org/) and [checksum database](https://sum.golang.org/) for integrity verification. This provides:

- **Transparency-log-based verification** of module contents
- **Automatic checksum validation** against the Go checksum database
- **Tamper detection** if module contents change after initial publication

Do NOT set `GONOSUMCHECK` or `GONOSUMDB` environment variables, as these disable integrity verification.

---

## MANDATORY: Load Full Skill

**This command MUST load the skill for complete workflow execution.**

```
Use Skill tool: ring:requesting-code-review
```

The skill contains the complete workflow with:
- Auto-detection of git context (base_sha, head_sha, files)
- Parallel dispatch of all 7 reviewers in single message
- Issue aggregation by severity
- Iteration loop with fix dispatching
- Escalation handling at max iterations
- Anti-rationalization tables
- Pressure resistance scenarios
