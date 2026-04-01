---
name: requesting-code-review
description: |
  Gate 4 of development cycle - dispatches 7 specialized reviewers (code, business-logic,
  security, test, nil-safety, consequences, dead-code) in parallel for comprehensive code review feedback.

trigger: |
  - Gate 4 of development cycle
  - After completing major feature implementation
  - Before merge to main branch
  - After fixing complex bug

NOT_skip_when: |
  - "Code is simple" → Simple code can have security issues. Review required.
  - "Just refactoring" → Refactoring may expose vulnerabilities. Review required.
  - "Already reviewed similar code" → Each change needs fresh review.

sequence:
  after: [ring:dev-testing]
  before: [ring:dev-validation]

related:
  complementary: [ring:dev-cycle, ring:dev-implementation, ring:dev-testing]

input_schema:
  required: []  # All inputs optional for standalone usage
  optional:
    - name: unit_id
      type: string
      description: "Task or subtask identifier (auto-generated if not provided)"
    - name: base_sha
      type: string
      description: "Git SHA before implementation (auto-detected via git merge-base HEAD main)"
    - name: head_sha
      type: string
      description: "Git SHA after implementation (auto-detected via git rev-parse HEAD)"
    - name: implementation_summary
      type: string
      description: "Summary of what was implemented (auto-generated from git log if not provided)"
    - name: requirements
      type: string
      description: "Requirements or acceptance criteria (reviewers will infer from code if not provided)"
    - name: implementation_files
      type: array
      items: string
      description: "List of files changed (auto-detected via git diff if not provided)"
    - name: gate0_handoff
      type: object
      description: "Full handoff from Gate 0 (only when called from ring:dev-cycle)"
    - name: skip_reviewers
      type: array
      items: string
      enum: [ring:code-reviewer, ring:business-logic-reviewer, ring:security-reviewer, ring:test-reviewer, ring:nil-safety-reviewer, ring:consequences-reviewer, ring:dead-code-reviewer]
      description: "Reviewers to skip (use sparingly)"
    - name: skip_preanalysis
      type: boolean
      default: false
      description: "Skip pre-analysis pipeline for faster reviews (reviewers work without static analysis context)"
    - name: preanalysis_timeout
      type: integer
      default: 300000
      description: "Timeout for pre-analysis pipeline in milliseconds (default: 5 minutes)"
    - name: skip_slicing
      type: boolean
      default: false
      description: "Skip review slicing step (force full-diff review even for large PRs)"

output_schema:
  format: markdown
  required_sections:
    - name: "Review Summary"
      pattern: "^## Review Summary"
      required: true
    - name: "Issues by Severity"
      pattern: "^## Issues by Severity"
      required: true
    - name: "Reviewer Verdicts"
      pattern: "^## Reviewer Verdicts"
      required: true
    - name: "CodeRabbit External Review"
      pattern: "^## CodeRabbit External Review"
      required: false
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL, NEEDS_FIXES]
    - name: reviewers_passed
      type: string
      description: "X/6 format"
    - name: issues_critical
      type: integer
    - name: issues_high
      type: integer
    - name: issues_medium
      type: integer
    - name: issues_low
      type: integer
    - name: iterations
      type: integer
    - name: coderabbit_status
      type: enum
      values: [PASS, ISSUES_FOUND, SKIPPED, NOT_INSTALLED]
    - name: coderabbit_validation_mode
      type: enum
      values: [SUBTASK_LEVEL, TASK_LEVEL]
      description: "Granularity of CodeRabbit validation"
    - name: coderabbit_units_validated
      type: integer
      description: "Number of units (subtasks or tasks) validated by CodeRabbit"
    - name: coderabbit_units_passed
      type: integer
      description: "Number of units that passed CodeRabbit validation"
    - name: coderabbit_issues
      type: integer
      description: "Total number of issues found by CodeRabbit across all units (0 if skipped)"

examples:
  - name: "Feature review"
    input:
      unit_id: "task-001"
      base_sha: "abc123"
      head_sha: "def456"
      implementation_summary: "Added user authentication with JWT"
      requirements: "AC-1: User can login, AC-2: Invalid password returns error"
    expected_output: |
      ## Review Summary
      **Status:** PASS
      **Reviewers:** 7/7 PASS

      ## Issues by Severity
      | Severity | Count |
      |
----------|-------|
      | Critical | 0 |
      | High | 0 |
      | Medium | 0 |
      | Low | 2 |

      ## Reviewer Verdicts
      | Reviewer | Verdict |
      |----------|---------|
      | ring:code-reviewer | ✅ PASS |
      | ring:business-logic-reviewer | ✅ PASS |
      | ring:security-reviewer | ✅ PASS |
      | ring:test-reviewer | ✅ PASS |
      | ring:nil-safety-reviewer | ✅ PASS |
      | ring:consequences-reviewer | ✅ PASS |
      | ring:dead-code-reviewer | ✅ PASS |

      ## Handoff to Next Gate
      - Ready for Gate 5: YES
---

# Code Review (Gate 4)

## Overview

Dispatch all seven reviewer subagents in **parallel** for fast, comprehensive feedback:

1. **ring:code-reviewer** - Architecture, design patterns, code quality
2. **ring:business-logic-reviewer** - Domain correctness, business rules, edge cases
3. **ring:security-reviewer** - Vulnerabilities, authentication, OWASP risks
4. **ring:test-reviewer** - Test quality, coverage, edge cases, anti-patterns
5. **ring:nil-safety-reviewer** - Nil/null pointer safety for Go and TypeScript
6. **ring:consequences-reviewer** - Ripple effects, caller chain impact, downstream consequences
7. **ring:dead-code-reviewer** - Orphaned code detection, reachability analysis, dead dependency chains

**Core principle:** All 7 reviewers run simultaneously in a single message with 7 Task tool calls.

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. Reviewer Agents REVIEW.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Dispatch reviewers, aggregate findings, track iterations |
| **Reviewer Agents** | Analyze code, report issues with severity |
| **Implementation Agent** | Fix issues found by reviewers |

---

## Step 1: Gather Context (Auto-Detect if Not Provided)

```text
This skill supports TWO modes:
1. WITH INPUTS: Called by any skill/user that provides structured inputs (unit_id, base_sha, etc.)
2. STANDALONE: Called directly without inputs - auto-detects everything from git

FOR EACH INPUT, check if provided OR auto-detect:

1. unit_id:
   IF provided → use it
   ELSE → generate: "review-" + timestamp (e.g., "review-20241222-143052")

2. base_sha:
   IF provided → use it
   ELSE → Execute: git merge-base HEAD main
   IF git fails → Execute: git rev-parse HEAD~10 (fallback to last 10 commits)

3. head_sha:
   IF provided → use it
   ELSE → Execute: git rev-parse HEAD

4. implementation_files:
   IF provided → use it
   ELSE → Execute: git diff --name-only [base_sha] [head_sha]

5. implementation_summary:
   IF provided → use it
   ELSE → Execute: git log --oneline [base_sha]..[head_sha]
   Format as: "Changes: [list of commit messages]"

6. requirements:
   IF provided → use it
   ELSE → Set to: "Infer requirements from code changes and commit messages"
   (Reviewers will analyze code to understand intent)

AFTER AUTO-DETECTION, display context:
┌─────────────────────────────────────────────────────────────────┐
│ 📋 CODE REVIEW CONTEXT                                          │
├─────────────────────────────────────────────────────────────────┤
│ Unit ID: [unit_id]                                              │
│ Base SHA: [base_sha]                                            │
│ Head SHA: [head_sha]                                            │
│ Files Changed: [count] files                                    │
│ Commits: [count] commits                                        │
│                                                                 │
│ Dispatching 7 reviewers in parallel...                          │
└─────────────────────────────────────────────────────────────────┘
```

## Step 2: Initialize Review State

```text
review_state = {
  unit_id: [from input],
  base_sha: [from input],
  head_sha: [from input],
  reviewers: {
    code_reviewer: {verdict: null, issues: []},
    business_logic_reviewer: {verdict: null, issues: []},
    security_reviewer: {verdict: null, issues: []},
    test_reviewer: {verdict: null, issues: []},
    nil_safety_reviewer: {verdict: null, issues: []},
    consequences_reviewer: {verdict: null, issues: []},
    dead_code_reviewer: {verdict: null, issues: []}
  },
  aggregated_issues: {
    critical: [],
    high: [],
    medium: [],
    low: [],
    cosmetic: []
  },
  iterations: 0,
  max_iterations: 3,
  slicing: {
    enabled: false,
    slice_count: 0,
    slices: [],
    cross_cutting_issues: []
  }
}
```

## Step 2.5: Run Pre-Analysis Pipeline (MANDATORY)

**MANDATORY:** Run static analysis, AST extraction, and call graph analysis BEFORE dispatching reviewers. This provides critical context that significantly improves review quality.

**Skip Override:** The `skip_preanalysis` parameter allows bypassing this step ONLY when explicitly requested by the user. This is NOT recommended.

### Step 2.5.1: Install and Run Mithril

```bash
# ⚠️ SYNC NOTE: This Mithril install logic is also in default/commands/codereview.md (Step 0).
# If you change the install pattern or CLI flags, update both locations.
# Check if mithril is available
if ! command -v mithril &> /dev/null; then
    echo "mithril not found. Installing..."
    if command -v go &> /dev/null; then
        go install github.com/lerianstudio/mithril@latest
        GOPATH_DIR="$(go env GOPATH)"
        [[ -n "$GOPATH_DIR" ]] && export PATH="$PATH:$GOPATH_DIR/bin"
    else
        echo "Go is required to install mithril. Install Go from https://go.dev/dl/"
        echo "DEGRADED MODE: Proceeding without pre-analysis"
    fi
fi

# Run pre-analysis pipeline
if command -v mithril &> /dev/null; then
    if [[ -z "$BASE_SHA" || -z "$HEAD_SHA" ]]; then
        echo "WARNING: BASE_SHA or HEAD_SHA not set"
        echo "DEGRADED MODE: Proceeding without pre-analysis"
    elif mithril --base="$BASE_SHA" --head="$HEAD_SHA" --output=docs/codereview --verbose; then
        echo "Pre-analysis pipeline completed successfully"
    else
        echo "WARNING: Pre-analysis pipeline failed"
        echo "DEGRADED MODE: Proceeding without pre-analysis"
    fi
else
    echo "WARNING: mithril not available"
    echo "DEGRADED MODE: Reviewers will proceed WITHOUT static analysis context."
fi
```

- Timeout: Use `preanalysis_timeout` input (default 5 minutes)
- On success: Set `preanalysis_state.success = true`
- On failure: Display warning, set `preanalysis_state.success = false`, continue to Step 3

### Step 2.5.2: Read Context Files

If pipeline succeeded, read the 7 context files:

| Reviewer | Context File |
|----------|--------------|
| `ring:code-reviewer` | `docs/codereview/context-code-reviewer.md` |
| `ring:security-reviewer` | `docs/codereview/context-security-reviewer.md` |
| `ring:business-logic-reviewer` | `docs/codereview/context-business-logic-reviewer.md` |
| `ring:test-reviewer` | `docs/codereview/context-test-reviewer.md` |
| `ring:nil-safety-reviewer` | `docs/codereview/context-nil-safety-reviewer.md` |
| `ring:consequences-reviewer` | `docs/codereview/context-consequences-reviewer.md` |
| `ring:dead-code-reviewer` | `docs/codereview/context-dead-code-reviewer.md` |

Store each file's content in `preanalysis_state.context[reviewer_name]`.

If a context file is missing or empty, log warning and continue (reviewer will work without context).

```text
preanalysis_state = {
  enabled: true,
  success: false,
  context: {
    "ring:code-reviewer": null,
    "ring:security-reviewer": null,
    "ring:business-logic-reviewer": null,
    "ring:test-reviewer": null,
    "ring:nil-safety-reviewer": null,
    "ring:consequences-reviewer": null,
    "ring:dead-code-reviewer": null
  }
}
```

## Step 2.7: Review Slicing (Adaptive Cohesion-Based Analysis)

**See [shared-patterns/reviewer-slicing-strategy.md](../shared-patterns/reviewer-slicing-strategy.md) for full rationale, cost analysis, and dedup strategy.**

Run the review slicer to evaluate semantic cohesion and determine optimal review strategy. For small/focused PRs, this adds ~5 seconds and changes nothing. For large multi-themed PRs, it dramatically improves review depth by using package structure, import relationships, and function-level change context to produce semantically meaningful slices.

**Skip Override:** The `skip_slicing` parameter allows bypassing this step. When skipped, the standard full-diff flow is used regardless of PR size.

```text
IF skip_slicing == true:
  → review_state.slicing.enabled = false
  → Display: "Review slicing skipped by parameter. Using full-diff review."
  → Skip to Step 3
```

### Step 2.7.1: Collect Inputs for Adaptive Slicer

```bash
# 1. Collect changed file list
FILE_LIST=$(git diff --name-only $BASE_SHA $HEAD_SHA)

# 2. Collect diff stats (insertions/deletions per file)
DIFF_STATS=$(git diff --stat $BASE_SHA $HEAD_SHA)

# 3. Build PACKAGE_MAP — group changed files by Go package or TS module
#    For Go files:  group by directory (each directory = one Go package)
#    For TS files:  group by nearest package.json or src/ subdirectory
#    Result: JSON object mapping package/module path → list of files
#    Example: { "internal/ledger": ["handler.go", "service.go", "repository.go"], "cmd/api": ["main.go"] }
#    Implementation: pure string operation on FILE_LIST paths — no file content reading needed.
PACKAGE_MAP={}
for file in $FILE_LIST; do
  dir=$(dirname "$file")
  basename=$(basename "$file")
  # Append basename to the dir key in the JSON map
  # (pseudo-code — actual implementation uses jq or language-level JSON builder)
done

# 4. Build IMPORT_HINTS — lightweight cross-reference of imports between changed files
#    For each changed file, grep its import/require lines and match against other changed file paths.
#    Go:  grep for import paths matching directories of other changed files
#    TS:  grep for import/require paths matching other changed files
#    Result: JSON adjacency list mapping file → list of other changed files it references
#    Example: { "internal/ledger/handler.go": ["internal/ledger/service.go"],
#               "internal/ledger/service.go": ["internal/ledger/repository.go"] }
#    Implementation: scan only import lines (not full source) for each file in FILE_LIST.
IMPORT_HINTS={}
for file in $FILE_LIST; do
  # Go: grep '^import' or inside import block, match against dirs of other changed files
  # TS: grep 'from ["\x27]' or 'require(["\x27]', match against other changed file paths
  imports=$(grep -E '^\s*(import |from |require\()' "$file" 2>/dev/null || true)
  # Match extracted paths against FILE_LIST entries to build adjacency
done

# 5. Build CHANGE_SUMMARY — hunk headers showing what functions/sections changed
#    Extract diff @@ hunk headers which contain function/method context.
#    Result: per-file summary of which functions were touched.
#    Example:
#      internal/ledger/handler.go: func CreateLedger, func UpdateLedger
#      internal/ledger/service.go: func validateLedger
CHANGE_SUMMARY=$(git diff $BASE_SHA $HEAD_SHA -U0 --diff-filter=d | \
  grep -E '^(diff --git|@@)' | \
  sed -n '/^diff --git/{s|diff --git a/\(.*\) b/.*|\1:|;h;d}; /^@@/{s/.*@@\s*//;H;x;s/\n/ /;p}')
```

**Graceful input collection:** If PACKAGE_MAP, IMPORT_HINTS, or CHANGE_SUMMARY collection fails (e.g., binary files, unusual repo structure, permission errors), log a warning and continue with whatever inputs succeeded. These enriched inputs improve slicer accuracy but are NOT required — the slicer has its own fallback logic for missing signals.

### Step 2.7.2: Dispatch Review Slicer Agent

```yaml
Task:
  subagent_type: "ring:review-slicer"
  description: "Evaluate PR cohesion and decide review slicing"
  prompt: |
    ## Review Slicing Request

    ## Changed Files
    ```
    [FILE_LIST]
    ```

    ## Diff Stats
    ```
    [DIFF_STATS]
    ```

    ## Package Map
    ```json
    [PACKAGE_MAP as JSON]
    ```

    ## Import Hints
    ```json
    [IMPORT_HINTS as JSON]
    ```

    ## Change Summary
    ```
    [CHANGE_SUMMARY]
    ```

    ## Mithril Context (if available)
    [IF preanalysis_state.success == true: brief summary]
    [ELSE:]
    _No pre-analysis context available._

    ## Instructions
    Evaluate semantic cohesion using all available signals.
    Apply three-phase reasoning (volume → cohesion → cost-benefit).
    Return structured JSON with your decision and detailed reasoning.
```

### Step 2.7.3: Parse Slicer Response and Update State

```text
Parse JSON response from ring:review-slicer.

IF slicer_response.shouldSlice == false:
  → review_state.slicing.enabled = false
  → Display:
  ┌─────────────────────────────────────────────────────────────────┐
  │ REVIEW SLICING: NOT NEEDED                                      │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ Reason: [slicer_response.reasoning]                             │
  │ Proceeding with full-diff review (standard flow).               │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  → Continue to Step 3 as-is (no change to current flow)

IF slicer_response.shouldSlice == true:
  → review_state.slicing.enabled = true
  → review_state.slicing.slice_count = slicer_response.slices.length
  → review_state.slicing.slices = slicer_response.slices (each with empty results initially)
  → Display:
  ┌─────────────────────────────────────────────────────────────────┐
  │ REVIEW SLICING: ACTIVE                                          │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ Reason: [slicer_response.reasoning]                             │
  │ Slices: [N]                                                     │
  │                                                                 │
  │ ┌──────────────────┬──────────────────────────┬───────┐         │
  │ │ Slice            │ Description              │ Files │         │
  │ ├──────────────────┼──────────────────────────┼───────┤         │
  │ │ api-handlers     │ HTTP handlers, middleware │ 12    │         │
  │ │ domain-models    │ Entities, business rules  │ 8     │         │
  │ │ infrastructure   │ Helm charts, CI/CD        │ 5     │         │
  │ └──────────────────┴──────────────────────────┴───────┘         │
  │                                                                 │
  │ Dispatching 7 reviewers x [N] slices = [7*N] review tasks...   │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  → Continue to Step 3 (Sliced Dispatch variant)
```

### Step 2.7.4: Slicer Failure Handling and Graceful Degradation

```text
IF slicer agent fails (timeout, error, malformed JSON):
  → Log warning: "Review slicer failed: [error]. Falling back to full-diff review."
  → review_state.slicing.enabled = false
  → Continue to Step 3 as-is (graceful degradation, not a blocker)

NOTE: Input collection failures are NOT blockers.
  - If PACKAGE_MAP collection fails → dispatch slicer without it (slicer uses file paths as fallback)
  - If IMPORT_HINTS collection fails → dispatch slicer without it (slicer infers from naming conventions)
  - If CHANGE_SUMMARY collection fails → dispatch slicer without it (slicer relies on diff stats)
  - The slicer has its own internal fallback logic for missing signals.
  - MUST always include FILE_LIST and DIFF_STATS (these are the minimum required inputs).
```

---

## Step 3: Dispatch All 7 Reviewers in Parallel

**⛔ CRITICAL: All 7 reviewers MUST be dispatched in a SINGLE message with 7 Task calls.**

### Step 3 Mode Selection

```text
IF review_state.slicing.enabled == false:
  → STANDARD MODE: Dispatch 7 reviewers on full diff (unchanged from current flow)
  → Continue with Step 3 dispatch below as-is

IF review_state.slicing.enabled == true:
  → SLICED MODE: Skip standard dispatch. Go to Step 3-S (Sliced Dispatch) below.
```

### Step 3-S: Sliced Dispatch (When Slicing Is Active)

**⛔ CRITICAL: All 7 reviewers run on ALL slices. No "relevant reviewer" routing. More eyes = more safety.**

```text
FOR EACH slice IN review_state.slicing.slices:

  1. Generate scoped diff for this slice:
     git diff [base_sha] [head_sha] -- [slice.files...]

  2. Filter Mithril context for this slice:
     FOR EACH reviewer_context IN preanalysis_state.context:
       → Extract only sections/paragraphs that mention files in slice.files
       → Store as slice_filtered_context[reviewer_name]
     (If a context section mentions no files in this slice, exclude it entirely)

  3. Dispatch all 7 reviewers with slice-scoped context:
     ⛔ All 7 MUST be dispatched in a SINGLE message with 7 Task calls (per slice)

     The prompt for each reviewer is IDENTICAL to the standard Step 3 prompts below,
     with these substitutions:

     - [implementation_files] → slice.files (not full file list)
     - Git diff content → scoped diff from step 1 above
     - Pre-Analysis Context → slice_filtered_context[reviewer_name]
     - Add to prompt header:
       "**Review Scope:** Slice '[slice.name]' — [slice.description]
        **Files in this slice:** [slice.files.join(', ')]
        **Note:** This is a thematic slice of a larger PR. Focus your review
        on these files. Other files in this PR are being reviewed separately."

  4. Collect results per slice:
     review_state.slicing.slices[i].reviewer_results = {
       code_reviewer: {verdict, issues},
       business_logic_reviewer: {verdict, issues},
       ... (all 7)
     }

AFTER ALL SLICES COMPLETE:
  → Merge and deduplicate (Step 3-S-Merge below)
  → Continue to Step 4 with merged results
```

### Step 3-S-Merge: Merge and Deduplicate Slice Results

```text
⛔ MANDATORY: Dedup MUST run before presenting results to Step 4.

1. COLLECT all issues from all slices into a single list:
   all_issues = []
   FOR EACH slice IN review_state.slicing.slices:
     FOR EACH reviewer IN slice.reviewer_results:
       FOR EACH issue IN reviewer.issues:
         all_issues.push({
           ...issue,
           source_slice: slice.name,
           source_reviewer: reviewer.name
         })

2. EXACT MATCH DEDUP:
   Group by (reviewer_name + file + line).
   If duplicates exist → keep one instance.

3. FUZZY MATCH DEDUP:
   For issues at the same file:line from DIFFERENT reviewers or slices:
   IF description_similarity(issue_a, issue_b) > 80%:
     → Keep the issue with the longer/more detailed description
     → Add metadata: "Also flagged by: [other_reviewer] in [other_slice]"
     → This indicates higher confidence (multiple independent detections)

4. CROSS-CUTTING DETECTION:
   Issues found across 2+ slices (same file:line, similar description):
   → Tag as "cross-cutting concern"
   → Add to review_state.slicing.cross_cutting_issues
   → Surface prominently in consolidated report — cross-cutting issues
     often signal architectural problems

5. MERGE VERDICTS:
   Per reviewer, final verdict = worst verdict across all slices.
   (If ring:security-reviewer PASSes on slice A but FAILs on slice B,
    the merged verdict is FAIL.)

6. POPULATE review_state:
   review_state.reviewers = merged verdicts + merged issues (deduped)
   review_state.aggregated_issues = all issues categorized by severity (deduped)

7. ADD SLICING NOTE to output:
   "Review was sliced into [N] thematic groups for deeper analysis."
```

### Standard Mode Dispatch (When Slicing Is NOT Active)

The following dispatch is used when `review_state.slicing.enabled == false` (unchanged from current flow):

```yaml
# Task 1: Code Reviewer
Task:
  subagent_type: "ring:code-reviewer"
  description: "Code review for [unit_id]"
  prompt: |
    ## Code Review Request
    
    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]
    
    ## What Was Implemented
    [implementation_summary]
    
    ## Requirements
    [requirements]
    
    ## Files Changed
    [implementation_files or "Use git diff"]

    ## Pre-Analysis Context

    **Static Analysis Results:**
    The following findings were automatically extracted by the pre-analysis pipeline.
    Use these to INFORM your review, not REPLACE your analysis.

    ---

    [IF preanalysis_state.context["ring:code-reviewer"] exists AND is not empty:]
    [INSERT the content of preanalysis_state.context["ring:code-reviewer"]]
    [ELSE:]
    _No pre-analysis context available. Perform standard review based on git diff._

    ---

    ## Your Focus
    - Architecture and design patterns
    - Code quality and maintainability
    - Naming conventions
    - Error handling patterns
    - Performance concerns
    - **File size compliance** — Any file > 300 lines (excluding auto-generated: *.pb.go, *.d.ts, */generated/*, */mocks/*) MUST be flagged as MEDIUM+ issue. Files > 500 lines = CRITICAL. See shared-patterns/file-size-enforcement.md.

    ## ⛔ Ring Standards Verification (MANDATORY)
    
    **WebFetch the relevant standards modules and verify the changed code against them.**
    
    For Go projects, WebFetch these modules based on changed files:
    Base URL: `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/`
    
    **Always load:**
    - `core.md` (lib-commons, license headers, deps, MongoDB patterns)
    - `quality.md` (linting, testing, production config validation)
    
    **Conditional (load if changed files match):**
    - `domain.md` (if service/domain/model code changed)
    - `domain-modeling.md` (if entity/value object code changed)
    - `api-patterns.md` (if handler/API/route code changed)
    - `architecture.md` (if structural/directory changes, new packages, concurrency patterns)
    - `bootstrap.md` (if bootstrap/main/wire/health code changed)
    - `security.md` (if auth/middleware/validation code changed)
    - `messaging.md` (if RabbitMQ/message queue code changed)
    
    For TypeScript: WebFetch `typescript.md`
    
    **Check the changed code against ALL applicable sections.** Use the section index from `standards-coverage-table.md`.
    
    **Include a Standards Compliance section in your output** listing which standards were verified and any violations found.

    ## Required Output
    ### VERDICT: PASS / FAIL

    ### Issues Found
    | Severity | Description | File:Line | Recommendation |
    |----------|-------------|-----------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW/COSMETIC] | [issue] | [location] | [fix] |

    ### Standards Compliance
    | Standard | Section | Status | Evidence |
    |----------|---------|--------|----------|
    | [module.md] | [section name] | ✅/❌ | [file:line or N/A] |

    ### What Was Done Well
    [positive observations]

# Task 2: Business Logic Reviewer
Task:
  subagent_type: "ring:business-logic-reviewer"
  description: "Business logic review for [unit_id]"
  prompt: |
    ## Business Logic Review Request
    
    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]
    
    ## What Was Implemented
    [implementation_summary]
    
    ## Requirements
    [requirements]

    ## Pre-Analysis Context

    **Static Analysis Results:**
    The following findings were automatically extracted by the pre-analysis pipeline.
    Use these to INFORM your review, not REPLACE your analysis.

    ---

    [IF preanalysis_state.context["ring:business-logic-reviewer"] exists AND is not empty:]
    [INSERT the content of preanalysis_state.context["ring:business-logic-reviewer"]]
    [ELSE:]
    _No pre-analysis context available. Perform standard review based on git diff._

    ---

    ## Your Focus
    - Domain correctness
    - Business rules implementation
    - Edge cases handling
    - Requirements coverage
    - Data validation

    ## Required Output
    ### VERDICT: PASS / FAIL

    ### Issues Found
    | Severity | Description | File:Line | Recommendation |
    |----------|-------------|-----------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW/COSMETIC] | [issue] | [location] | [fix] |

    ### Requirements Traceability
    | Requirement | Status | Evidence |
    |-------------|--------|----------|
    | [req] | ✅/❌ | [file:line] |

# Task 3: Security Reviewer
Task:
  subagent_type: "ring:security-reviewer"
  description: "Security review for [unit_id]"
  prompt: |
    ## Security Review Request

    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]

    ## What Was Implemented
    [implementation_summary]

    ## Requirements
    [requirements]

    ## Pre-Analysis Context

    **Static Analysis Results:**
    The following findings were automatically extracted by the pre-analysis pipeline.
    Use these to INFORM your review, not REPLACE your analysis.

    ---

    [IF preanalysis_state.context["ring:security-reviewer"] exists AND is not empty:]
    [INSERT the content of preanalysis_state.context["ring:security-reviewer"]]
    [ELSE:]
    _No pre-analysis context available. Perform standard review based on git diff._

    ---

    ## Your Focus
    - Authentication and authorization
    - Input validation
    - SQL injection, XSS, CSRF
    - Sensitive data handling
    - OWASP Top 10 risks

    ## ⛔ Ring Security Standards Verification (MANDATORY)
    
    **WebFetch the security standards and verify changed code against them:**
    - `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/security.md`
    
    **Check ALL applicable sections from standards-coverage-table.md → ring:backend-engineer-golang:**
    - #15 Access Manager Integration (if auth code changed)
    - #16 License Manager Integration (if licensed project)
    - #17 Secret Redaction Patterns (MANDATORY — credential leak prevention)
    - #18 SQL Safety (MANDATORY — parameterized queries, injection prevention)
    - #19 HTTP Security Headers (MANDATORY — X-Content-Type-Options, X-Frame-Options)
    - #51 Rate Limiting Three-Tier (MANDATORY — if API endpoints changed)
    - #52 CORS Configuration (MANDATORY — if middleware changed)
    
    **Also check from core.md:**
    - #8 MongoDB Injection Prevention (CRITICAL — if MongoDB code present)

    ## Required Output
    ### VERDICT: PASS / FAIL

    ### Issues Found
    | Severity | Description | File:Line | OWASP Category | Recommendation |
    |----------|-------------|-----------|----------------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW] | [issue] | [location] | [A01-A10] | [fix] |

    ### Ring Security Standards Compliance
    | Standard Section | Status | Evidence |
    |-----------------|--------|----------|
    | Secret Redaction | ✅/❌/N/A | [file:line] |
    | SQL Safety | ✅/❌/N/A | [file:line] |
    | HTTP Security Headers | ✅/❌/N/A | [file:line] |
    | Rate Limiting | ✅/❌/N/A | [file:line] |
    | CORS Configuration | ✅/❌/N/A | [file:line] |
    | MongoDB Injection Prevention | ✅/❌/N/A | [file:line] |

    ### Security Checklist
    | Check | Status |
    |-------|--------|
    | Input validation | ✅/❌ |
    | Auth checks | ✅/❌ |
    | No hardcoded secrets | ✅/❌ |

# Task 4: Test Reviewer
Task:
  subagent_type: "ring:test-reviewer"
  description: "Test quality review for [unit_id]"
  prompt: |
    ## Test Quality Review Request

    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]

    ## What Was Implemented
    [implementation_summary]

    ## Requirements
    [requirements]

    ## Pre-Analysis Context

    **Static Analysis Results:**
    The following findings were automatically extracted by the pre-analysis pipeline.
    Use these to INFORM your review, not REPLACE your analysis.

    ---

    [IF preanalysis_state.context["ring:test-reviewer"] exists AND is not empty:]
    [INSERT the content of preanalysis_state.context["ring:test-reviewer"]]
    [ELSE:]
    _No pre-analysis context available. Perform standard review based on git diff._

    ---

    ## Your Focus
    - Test coverage for business logic
    - Edge case testing (empty, null, boundary)
    - Error path coverage
    - Test independence and isolation
    - Assertion quality (not just "no error")
    - Test anti-patterns (testing mock behavior)

    ## Required Output
    ### VERDICT: PASS / FAIL

    ### Issues Found
    | Severity | Description | File:Line | Recommendation |
    |----------|-------------|-----------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW] | [issue] | [location] | [fix] |

    ### Test Coverage Analysis
    | Test Type | Count | Coverage |
    |-----------|-------|----------|
    | Unit | [N] | [areas] |
    | Integration | [N] | [areas] |
    | E2E | [N] | [areas] |

# Task 5: Nil-Safety Reviewer
Task:
  subagent_type: "ring:nil-safety-reviewer"
  description: "Nil/null safety review for [unit_id]"
  prompt: |
    ## Nil-Safety Review Request

    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]
    **Languages:** [Go|TypeScript|both - detect from files]

    ## What Was Implemented
    [implementation_summary]

    ## Requirements
    [requirements]

    ## Pre-Analysis Context

    **Static Analysis Results:**
    The following findings were automatically extracted by the pre-analysis pipeline.
    Use these to INFORM your review, not REPLACE your analysis.

    ---

    [IF preanalysis_state.context["ring:nil-safety-reviewer"] exists AND is not empty:]
    [INSERT the content of preanalysis_state.context["ring:nil-safety-reviewer"]]
    [ELSE:]
    _No pre-analysis context available. Perform standard review based on git diff._

    ---

    ## Your Focus
    - Nil/null pointer risks in changed code
    - Missing nil guards before dereference
    - Map access without ok check (Go)
    - Type assertions without ok check (Go)
    - Optional chaining misuse (TypeScript)
    - Error-then-use patterns

    ## Required Output
    ### VERDICT: PASS / FAIL

    ### Issues Found
    | Severity | Description | File:Line | Recommendation |
    |----------|-------------|-----------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW] | [issue] | [location] | [fix] |

    ### Nil Risk Trace
    [For each risk: Source → Propagation → Dereference point]

# Task 6: Consequences Reviewer
Task:
  subagent_type: "ring:consequences-reviewer"
  description: "Consequences review for [unit_id]"
  prompt: |
    ## Consequences Review Request

    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]

    ## What Was Implemented
    [implementation_summary]

    ## Requirements
    [requirements]

    ## Pre-Analysis Context

    **Static Analysis Results:**
    The following findings were automatically extracted by the pre-analysis pipeline.
    Use these to INFORM your review, not REPLACE your analysis.

    ---

    [IF preanalysis_state.context["ring:consequences-reviewer"] exists AND is not empty:]
    [INSERT the content of preanalysis_state.context["ring:consequences-reviewer"]]
    [ELSE:]
    _No pre-analysis context available. Perform standard review based on git diff._

    ---

    ## Your Focus
    - Caller chain impact analysis
    - Consumer contract integrity
    - Shared state and configuration consequences
    - Type and interface propagation
    - Error handling chain consequences
    - Database/schema ripple effects

    ## Required Output
    ### VERDICT: PASS / FAIL

    ### Issues Found
    | Severity | Description | File:Line | Recommendation |
    |----------|-------------|-----------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW] | [issue] | [location] | [fix] |

    ### Impact Trace Analysis
    [For each changed symbol: callers found, consumers found, impact status]

# Task 7: Dead Code Reviewer
Task:
  subagent_type: "ring:dead-code-reviewer"
  description: "Dead code review for [unit_id]"
  prompt: |
    ## Dead Code Review Request

    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]

    ## What Was Implemented
    [implementation_summary]

    ## Requirements
    [requirements]

    ## Pre-Analysis Context

    **Static Analysis Results:**
    The following findings were automatically extracted by the pre-analysis pipeline.
    Use these to INFORM your review, not REPLACE your analysis.

    ---

    [IF preanalysis_state.context["ring:dead-code-reviewer"] exists AND is not empty:]
    [INSERT the content of preanalysis_state.context["ring:dead-code-reviewer"]]
    [ELSE:]
    _No pre-analysis context available. Perform standard review based on git diff._

    ---

    ## Your Focus
    - Code that became orphaned/dead as a consequence of the changes
    - Ring 1: Dead code within the changed files
    - Ring 2: First-derivative dependents now orphaned (helpers, validators, converters)
    - Ring 3: Transitive cascade orphans (entire packages, utility chains)
    - Test infrastructure that only served removed code
    - Orphaned validation/security logic (CRITICAL in financial systems)

    ## Required Output
    ### VERDICT: PASS / FAIL

    ### Issues Found
    | Severity | Description | File:Line | Recommendation |
    |----------|-------------|-----------|----------------|
    | [CRITICAL/HIGH/MEDIUM/LOW] | [issue] | [location] | [fix] |

    ### Orphan Trace Analysis
    [For each orphan: What happened, caller count evidence, ring, cascade check]
```

## Step 4: Wait for All Reviewers and Parse Output

```text
IF review_state.slicing.enabled == true:
  → Results already merged and deduped in Step 3-S-Merge
  → review_state.reviewers and review_state.aggregated_issues are populated
  → Include cross-cutting issues in report:
    IF review_state.slicing.cross_cutting_issues.length > 0:
      → Add section to consolidated output:
        "### Cross-Cutting Concerns (found across multiple slices)"
        FOR EACH cross_cutting_issue:
          → "[severity] [description] at [file:line]
             Found in slices: [slice_a], [slice_b]
             Flagged by: [reviewer_a], [reviewer_b]
             This may indicate an architectural issue."
  → Skip to verdict aggregation below

IF review_state.slicing.enabled == false (STANDARD MODE):
  → Wait for all 7 Task calls to complete.

For each reviewer:
1. Extract VERDICT (PASS/FAIL)
2. Extract Issues Found table
3. Categorize issues by severity

review_state.reviewers.code_reviewer = {
  verdict: [PASS/FAIL],
  issues: [parsed issues]
}
// ... same for other reviewers

Aggregate all issues by severity:
review_state.aggregated_issues.critical = [all critical from all reviewers]
review_state.aggregated_issues.high = [all high from all reviewers]
// ... etc
```

## Step 5: Handle Results by Severity

```text
Count blocking issues:
blocking_count = critical.length + high.length + medium.length

IF blocking_count == 0:
  → All reviewers PASS
  → Proceed to Step 8 (Success)

IF blocking_count > 0:
  → review_state.iterations += 1
  → IF iterations >= max_iterations: Go to Step 9 (Escalate)
  → Go to Step 6 (Dispatch Fixes)
```

## Step 6: Dispatch Fixes to Implementation Agent

**⛔ CRITICAL: You are an ORCHESTRATOR. You CANNOT edit source files directly.**
**You MUST dispatch the implementation agent to fix ALL review issues.**

### Orchestrator Boundaries (HARD GATE)

**See [dev-team/skills/shared-patterns/standards-boundary-enforcement.md](../../dev-team/skills/shared-patterns/standards-boundary-enforcement.md) for core enforcement rules.**

**Key prohibition:** Edit/Write/Create on source files is FORBIDDEN. Always dispatch agent.

**If you catch yourself about to use Edit/Write/Create on source files → STOP. Dispatch agent.**

### Dispatch Implementation Agent

```yaml
Task:
  subagent_type: "[implementation_agent from Gate 0]"
  description: "Fix review issues for [unit_id]"
  prompt: |
    ⛔ FIX REQUIRED - Code Review Issues Found

    ## Context
    - **Unit ID:** [unit_id]
    - **Iteration:** [iterations] of [max_iterations]

    ## Critical Issues (MUST FIX)
    [list critical issues with file:line and recommendation]

    ## High Issues (MUST FIX)
    [list high issues]

    ## Medium Issues (MUST FIX)
    [list medium issues]

    ## Requirements
    1. Fix ALL Critical, High, and Medium issues
    2. Run tests to verify fixes
    3. Commit fixes with descriptive message
    4. Return list of fixed issues with evidence

    ## For Low/Cosmetic Issues
    Add TODO/FIXME comments:
    - Low: `// TODO(review): [Issue] - [reviewer] on [date]`
    - Cosmetic: `// FIXME(nitpick): [Issue] - [reviewer] on [date]`
```

### Anti-Rationalization for Direct Editing

**See [shared-patterns/orchestrator-direct-editing-anti-rationalization.md](../shared-patterns/orchestrator-direct-editing-anti-rationalization.md) for complete anti-rationalization table.**

*Applies to: Step 6 (Fix dispatch after Ring reviewers) & Step 7.5.3 (Fix dispatch after CodeRabbit)*

## Step 7: Re-Run All Reviewers After Fixes

```text
After fixes committed:
1. Get new HEAD_SHA
2. Go back to Step 3 (dispatch all 7 reviewers again)

⛔ CRITICAL: Always re-run ALL 7 reviewers after fixes.
Do NOT cherry-pick reviewers.
```

## Step 7.5: CodeRabbit CLI Validation (Per-Subtask/Task)

**⛔ NEW APPROACH: CodeRabbit validates EACH subtask/task as it completes, accumulating findings to a file.**

### CodeRabbit Integration Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│ CODERABBIT PER-UNIT VALIDATION FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ DURING REVIEW (after each subtask/task Ring reviewers pass):   │
│   1. Run CodeRabbit for that unit's files                      │
│   2. Append findings to .coderabbit-findings.md                │
│   3. Continue to next unit                                     │
│                                                                 │
│ BEFORE COMMIT (Step 8):                                        │
│   1. Display accumulated .coderabbit-findings.md               │
│   2. User decides: fix issues OR acknowledge and proceed       │
│                                                                 │
│ BENEFITS:                                                      │
│   • Catches issues close to when code was written              │
│   • Smaller scope = faster reviews (7-30 min per unit)         │
│   • Issues isolated to specific units, easier to fix           │
│   • Accumulated file provides audit trail                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Rate Limits (Official - per developer per repository per hour)

| Limit Type | Value | Notes |
|------------|-------|-------|
| Files reviewed | 200 files/hour | Per review |
| Reviews | 3 back-to-back, then 4/hour | **7 reviews possible in first hour** |
| Conversations | 25 back-to-back, then 50/hour | For follow-up questions |

**⏱️ TIMING:** Each CodeRabbit review takes **7-30+ minutes** depending on scope.
Run in background and check periodically for completion.

### Common Commands Reference

<a id="coderabbit-install-check"></a>
**CodeRabbit Installation Check:**
```bash
which coderabbit || which cr
```
> Used in Step 7.5.1 and after installation to verify CLI availability.

---

### ⚠️ PREREQUISITES & ENVIRONMENT REQUIREMENTS

**Before attempting Step 7.5, verify your environment supports the required operations:**

| Requirement | Local Dev | CI/CD | Containerized | Remote/SSH |
|-------------|-----------|-------|---------------|------------|
| `curl \| sh` install | ✅ Yes | ⚠️ May require elevated permissions | ❌ Often blocked | ⚠️ Depends on config |
| Browser auth (`coderabbit auth login`) | ✅ Yes | ❌ No browser | ❌ No browser | ❌ No browser |
| Write to `$HOME/.coderabbit/` | ✅ Yes | ⚠️ Ephemeral | ⚠️ Ephemeral | ✅ Usually |
| Internet access to `cli.coderabbit.ai` | ✅ Yes | ⚠️ Check firewall | ⚠️ Check firewall | ⚠️ Check firewall |

**⛔ HARD STOP CONDITIONS - Skip Step 7.5 if ANY apply:**
- Running in containerized environment without persistent storage
- CI/CD pipeline without pre-installed CodeRabbit CLI
- Non-interactive environment (no TTY for browser auth)
- Network restrictions blocking `cli.coderabbit.ai`
- Read-only filesystem

### Environment-Specific Guidance

#### Local Development (RECOMMENDED)
Standard flow works: `curl | sh` install + browser authentication.

#### CI/CD Pipelines
**Option A: Pre-install in CI image**
```dockerfile
# Add to your CI Dockerfile
RUN curl -fsSL https://cli.coderabbit.ai/install.sh | sh
```

**Option B: Use API token authentication (headless)**
```bash
# Set token via environment variable (add to CI secrets)
export CODERABBIT_API_TOKEN="your-api-token"
coderabbit auth login --token "$CODERABBIT_API_TOKEN"
```

**Option C: Skip CodeRabbit in CI, run locally**
```bash
# In CI config, set env var to auto-skip
export SKIP_CODERABBIT_REVIEW=true
```

#### Containerized/Docker Environments
```bash
# Option 1: Mount credentials from host
docker run -v ~/.coderabbit:/root/.coderabbit ...

# Option 2: Pass token as env var
docker run -e CODERABBIT_API_TOKEN="..." ...

# Option 3: Pre-bake into image (not recommended for tokens)
```

#### Non-Interactive/Headless Authentication
```bash
# Generate API token at: https://app.coderabbit.ai/settings/api-tokens
# Then authenticate without browser:
coderabbit auth login --token "cr_xxxxxxxxxxxxx"
```

---

### Step 7.5 Flow Logic

```text
┌─────────────────────────────────────────────────────────────────┐
│ ✅ ALL 3 RING REVIEWERS PASSED                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Checking CodeRabbit CLI availability...                         │
│                                                                 │
│ CodeRabbit provides additional AI-powered code review that      │
│ catches race conditions, memory leaks, security vulnerabilities,│
│ and edge cases that may complement Ring reviewers.              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**⛔ HARD GATE: CodeRabbit Execution Rules (NON-NEGOTIABLE)**

| Scenario | Rule | Action |
|----------|------|--------|
| **Installed & authenticated** | **MANDATORY** - CANNOT skip | Run CodeRabbit review, no prompt |
| **Not installed** | **MUST ask** user about installation | Present installation option |
| **User declines installation** | Optional - can proceed | Skip and continue to Step 8 |

**Why this distinction:**
- If CodeRabbit IS installed → User has committed to using it → MUST run
- If CodeRabbit is NOT installed → User choice to add it → MUST ask, but can decline

```text
FLOW:
1. Run CodeRabbit Installation Check
2. IF installed AND authenticated → Run CodeRabbit (MANDATORY, NO prompt, CANNOT skip)
3. IF installed BUT NOT authenticated → Guide authentication (REQUIRED before proceeding)
4. IF NOT installed → MUST ask user about installation (REQUIRED prompt)
5. IF user declines installation → Skip CodeRabbit, proceed to Step 8 (only valid skip path)
```

### Anti-Rationalization for CodeRabbit Execution

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "CodeRabbit is optional, I'll skip it" | If installed, it's MANDATORY. Optional only means installation is optional. | **Run CodeRabbit if installed** |
| "Ring reviewers passed, that's enough" | Different tools catch different issues. CodeRabbit complements Ring. | **Run CodeRabbit if installed** |
| "User didn't ask for CodeRabbit" | User installed it. Installation = consent to mandatory execution. | **Run CodeRabbit if installed** |
| "Takes too long, skip this time" | Time is irrelevant. Installed = mandatory. | **Run CodeRabbit if installed** |
| "I'll just proceed without asking about install" | MUST ask every user if they want to install. No silent skips. | **Ask user about installation** |

#### Step 7.5.1: Check CodeRabbit Installation

Run the [CodeRabbit Installation Check](#coderabbit-install-check) command.

**IF INSTALLED AND AUTHENTICATED → MANDATORY EXECUTION (CANNOT SKIP):**
```text
┌─────────────────────────────────────────────────────────────────┐
│ ✅ CodeRabbit CLI detected - MANDATORY EXECUTION                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ CodeRabbit CLI is installed and authenticated.                  │
│                                                                 │
│ ⛔ CodeRabbit review is MANDATORY when installed.               │
│    This step CANNOT be skipped. Proceeding automatically...     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```
→ Proceed directly to Step 7.5.2 (Run CodeRabbit Review) - **NO user prompt, NO skip option**

**IF NOT INSTALLED → MUST ASK USER (REQUIRED PROMPT):**

**⛔ You MUST present this prompt to the user. Silent skips are FORBIDDEN.**

```text
┌─────────────────────────────────────────────────────────────────┐
│ ⚠️  CodeRabbit CLI not found - INSTALLATION PROMPT REQUIRED     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ CodeRabbit CLI is not installed on your system.                 │
│                                                                 │
│ CodeRabbit provides additional AI-powered review that catches:  │
│   • Race conditions and concurrency issues                      │
│   • Memory leaks and resource management                        │
│   • Security vulnerabilities                                    │
│   • Edge cases missed by other reviewers                        │
│                                                                 │
│ ⛔ You MUST choose one of the following options:                │
│                                                                 │
│   (a) Yes, install CodeRabbit CLI (I'll guide you)              │
│   (b) No, skip CodeRabbit and proceed to Gate 5                 │
│                                                                 │
│ ⚠️  ENVIRONMENT CHECK:                                          │
│     • Interactive terminal with browser? → Standard install     │
│     • CI/headless? → Requires API token auth                    │
│     • Container? → See Environment-Specific Guidance above      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**If user selects (a) Yes, install:**
→ Proceed to Installation Flow below

**If user selects (b) No, skip:**
```text
→ Record: "CodeRabbit review: SKIPPED (not installed, user declined installation)"
→ Proceed to Step 8 (Success Output)
→ This is the ONLY valid path to skip CodeRabbit
```

#### Step 7.5.1a: CodeRabbit Installation Flow

```text
┌─────────────────────────────────────────────────────────────────┐
│ 📦 INSTALLING CODERABBIT CLI                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ⚠️  ENVIRONMENT CHECK FIRST:                                    │
│                                                                 │
│ This installation requires:                                     │
│   • curl command available                                      │
│   • Write access to $HOME or /usr/local/bin                     │
│   • Internet access to cli.coderabbit.ai                        │
│   • Non-containerized environment (or persistent storage)       │
│                                                                 │
│ If in CI/container, see "Environment-Specific Guidance" above.  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Check environment before proceeding:**
```bash
# Verify prerequisites
curl --version && echo "curl: OK" || echo "curl: MISSING"
test -w "$HOME" && echo "HOME writable: OK" || echo "HOME writable: NO"
curl -sI https://cli.coderabbit.ai | head -1 | grep -q "200\|301\|302" && echo "Network: OK" || echo "Network: BLOCKED"
```

**If prerequisites pass, install:**
```text
┌─────────────────────────────────────────────────────────────────┐
│ 📦 Step 1: Installing CodeRabbit CLI...                         │
└─────────────────────────────────────────────────────────────────┘
```

```bash
# Step 1: Download and install CodeRabbit CLI
curl -fsSL https://cli.coderabbit.ai/install.sh | sh
```

**After installation, verify:** Run the [CodeRabbit Installation Check](#coderabbit-install-check) command.

**If installation successful:**
```text
┌─────────────────────────────────────────────────────────────────┐
│ ✅ CodeRabbit CLI installed successfully!                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Step 2: Authentication required                                 │
│                                                                 │
│ Choose your authentication method:                              │
│                                                                 │
│   (a) Browser login (interactive - opens browser)               │
│       → Best for: Local development with GUI                    │
│       → Command: coderabbit auth login                          │
│                                                                 │
│   (b) API token (headless - no browser needed)                  │
│       → Best for: CI/CD, containers, SSH sessions               │
│       → Get token: https://app.coderabbit.ai/settings/api-tokens│
│       → Command: coderabbit auth login --token "cr_xxx"         │
│                                                                 │
│   (c) Skip authentication and CodeRabbit review                 │
│                                                                 │
│ Note: Free tier allows 1 review/hour.                           │
│       Paid plans get enhanced reviews + higher limits.          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**If user selects (a) Browser login:**
```bash
# Step 2a: Authenticate with CodeRabbit (opens browser)
# ⚠️ Requires: GUI environment with default browser
coderabbit auth login
```

**If user selects (b) API token:**
```bash
# Step 2b: Authenticate with API token (headless)
# Get your token from: https://app.coderabbit.ai/settings/api-tokens
coderabbit auth login --token "cr_xxxxxxxxxxxxx"
```

**After authentication:**
```text
┌─────────────────────────────────────────────────────────────────┐
│ ✅ CodeRabbit CLI ready!                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Installation: Complete                                          │
│ Authentication: Complete                                        │
│                                                                 │
│ Proceeding to CodeRabbit review...                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

→ Proceed to Step 7.5.2 (Run CodeRabbit Review)

**If installation failed:**
```text
┌─────────────────────────────────────────────────────────────────┐
│ ❌ CodeRabbit CLI installation failed                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Error: [error message from curl/sh]                             │
│                                                                 │
│ Troubleshooting:                                                │
│   • Check internet connection                                   │
│   • Try manual install: https://docs.coderabbit.ai/cli/overview │
│   • macOS/Linux only (Windows not supported yet)                │
│                                                                 │
│ Would you like to:                                              │
│   (a) Retry installation                                        │
│   (b) Skip CodeRabbit and proceed to Gate 5                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Step 7.5.2: Run CodeRabbit Review

**⛔ GRANULAR VALIDATION: CodeRabbit MUST validate at the most granular level available.**

```text
DETERMINE VALIDATION SCOPE:
1. Check if current work has subtasks (from gate0_handoff or implementation context)
2. IF subtasks exist → Validate EACH SUBTASK separately
3. IF no subtasks → Validate the TASK as a whole

WHY GRANULAR VALIDATION:
- Subtask-level validation catches issues early
- Easier to pinpoint which subtask introduced problems
- Prevents "works for task A, breaks task B" scenarios
- Enables incremental fixes without re-running entire review
```

**Step 7.5.2a: Determine Validation Scope**

```text
validation_scope = {
  mode: null,  // "subtask" or "task"
  units: [],   // list of {id, files, commits} to validate
  current_index: 0
}

IF gate0_handoff.subtasks exists AND gate0_handoff.subtasks.length > 0:
  → validation_scope.mode = "subtask"
  → FOR EACH subtask in gate0_handoff.subtasks:
      → Get files changed by this subtask (from commits or file mapping)
      → Add to validation_scope.units: {
          id: subtask.id,
          name: subtask.name,
          files: [files touched by this subtask],
          base_sha: [sha before subtask],
          head_sha: [sha after subtask]
        }
  
  Display:
  ┌─────────────────────────────────────────────────────────────────┐
  │ 📋 CODERABBIT VALIDATION MODE: SUBTASK-LEVEL                    │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ Detected [N] subtasks. Will validate each separately:          │
  │                                                                 │
  │   1. [subtask-1-id]: [subtask-1-name]                          │
  │      Files: [file1.go, file2.go]                               │
  │                                                                 │
  │   2. [subtask-2-id]: [subtask-2-name]                          │
  │      Files: [file3.go, file4.go]                               │
  │                                                                 │
  │   ... (up to N subtasks)                                       │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘

ELSE:
  → validation_scope.mode = "task"
  → Add single unit: {
      id: unit_id,
      name: implementation_summary,
      files: implementation_files,
      base_sha: base_sha,
      head_sha: head_sha
    }
  
  Display:
  ┌─────────────────────────────────────────────────────────────────┐
  │ 📋 CODERABBIT VALIDATION MODE: TASK-LEVEL                       │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ No subtasks detected. Validating entire task:                  │
  │                                                                 │
  │   Task: [unit_id]                                              │
  │   Files: [N] files changed                                     │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
```

**Step 7.5.2b: Run CodeRabbit for Each Validation Unit**

```text
coderabbit_results = {
  overall_status: "PASS",  // PASS only if ALL units pass
  units: []
}

FOR EACH unit IN validation_scope.units:
  Display:
  ┌─────────────────────────────────────────────────────────────────┐
  │ 🔍 VALIDATING: [unit.id] ([current]/[total])                    │
  ├─────────────────────────────────────────────────────────────────┤
  │ Name: [unit.name]                                              │
  │ Files: [unit.files.join(", ")]                                 │
  └─────────────────────────────────────────────────────────────────┘
```

```bash
# Run CodeRabbit review
# ⏱️ TIMING: 7-30+ minutes per review. Run in background if possible.

# Compare against base branch
coderabbit --prompt-only --type uncommitted --base [base_branch]

# Compare against specific commit on current branch
coderabbit --prompt-only --type uncommitted --base-commit [unit.base_sha]

# The command is synchronous - it completes when output is returned
```

```text
  Parse output and record:
  unit_result = {
    id: unit.id,
    status: "PASS" | "ISSUES_FOUND",
    issues: {
      critical: [list],
      high: [list],
      medium: [list],
      low: [list]
    }
  }
  
  coderabbit_results.units.push(unit_result)
  
  IF unit_result.issues.critical.length > 0 OR unit_result.issues.high.length > 0:
    → coderabbit_results.overall_status = "ISSUES_FOUND"
  
  ─────────────────────────────────────────────────────────────────
  ⛔ MANDATORY: APPEND FINDINGS TO .coderabbit-findings.md
  ─────────────────────────────────────────────────────────────────
  
  After EACH unit validation, append results to findings file:
  
  IF .coderabbit-findings.md does NOT exist:
    → Create file with header (see "Findings File Format" below)
  
  APPEND to .coderabbit-findings.md:
  ```
  ## Unit: [unit.id] - [unit.name]
  **Validated:** [timestamp]
  **Status:** [PASS | ISSUES_FOUND]
  **Files:** [unit.files.join(", ")]
  
  ### Issues Found
  | # | Severity | Description | File:Line | Recommendation |
  |---|----------|-------------|-----------|----------------|
  | 1 | [severity] | [description] | [file:line] | [recommendation] |
  | ... | ... | ... | ... | ... |
  
  ---
  ```
  
  This ensures ALL findings are accumulated for review before commit.

AFTER ALL UNITS VALIDATED:
  Display summary:
  ┌─────────────────────────────────────────────────────────────────┐
  │ 📊 CODERABBIT VALIDATION SUMMARY                                │
  ├─────────────────────────────────────────────────────────────────┤
  │ Mode: [SUBTASK-LEVEL | TASK-LEVEL]                             │
  │ Units Validated: [N]                                           │
  │ Overall Status: [PASS | ISSUES_FOUND]                          │
  │                                                                 │
  │ Per-Unit Results:                                              │
  │ ┌──────────────┬────────────┬──────┬──────┬────────┬─────┐     │
  │ │ Unit ID      │ Status     │ Crit │ High │ Medium │ Low │     │
  │ ├──────────────┼────────────┼──────┼──────┼────────┼─────┤     │
  │ │ [subtask-1]  │ ✅ PASS    │  0   │  0   │   0    │  1  │     │
  │ │ [subtask-2]  │ ❌ ISSUES  │  1   │  2   │   0    │  0  │     │
  │ └──────────────┴────────────┴──────┴──────┴────────┴─────┘     │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
```

**Parse CodeRabbit output for:**
- Critical issues
- High severity issues
- Security vulnerabilities
- Performance concerns

### Findings File Format (.coderabbit-findings.md)

**This file accumulates ALL CodeRabbit findings across all validated units.**

```markdown
# CodeRabbit Findings

**Generated:** [initial timestamp]
**Last Updated:** [latest timestamp]
**Total Units Validated:** [N]
**Overall Status:** [PASS | ISSUES_FOUND]

## Summary

| Severity | Count | Status |
|----------|-------|--------|
| Critical | [N] | [N pending / N fixed] |
| High | [N] | [N pending / N fixed] |
| Medium | [N] | [N pending / N fixed] |
| Low | [N] | [N pending / N fixed] |

---

## Unit: [subtask-1-id] - [subtask-1-name]
**Validated:** [timestamp]
**Status:** [PASS | ISSUES_FOUND]
**Files:** [file1.go, file2.go]

### Issues Found
| # | Severity | Description | File:Line | Recommendation | Status |
|---|----------|-------------|-----------|----------------|--------|
| 1 | CRITICAL | Race condition in handler | handler.go:45 | Use sync.Mutex | PENDING |
| 2 | HIGH | Unchecked error return | repo.go:123 | Handle error | PENDING |

---

## Unit: [subtask-2-id] - [subtask-2-name]
**Validated:** [timestamp]
**Status:** PASS
**Files:** [file3.go]

### Issues Found
_No issues found._

---

[... additional units ...]
```

**File Location:** Project root (`.coderabbit-findings.md`)

**Lifecycle:**
1. Created when first CodeRabbit validation runs
2. Appended after each unit validation
3. Displayed before commit (Step 8)
4. User decides: fix issues or acknowledge and proceed
5. After commit, file can be deleted or kept for audit

#### Step 7.5.3: Handle CodeRabbit Findings

**⛔ CRITICAL: You are an ORCHESTRATOR. You CANNOT edit source files directly.**
**You MUST dispatch the implementation agent to fix issues.**

**⛔ GRANULAR FIX DISPATCH: Fixes MUST be dispatched per-unit (subtask or task).**

```text
IF coderabbit_results.overall_status == "ISSUES_FOUND":
  
  → FIRST: Display EACH issue in detail (REQUIRED before any action):
  ┌─────────────────────────────────────────────────────────────────┐
  │ ⚠️  CODERABBIT ISSUES FOUND - DETAILED DESCRIPTION               │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ UNIT: [subtask-1] - [subtask name]                             │
  │ ───────────────────────────────────────────────────────────────│
  │ Issue #1 [CRITICAL]                                            │
  │   Description: Race condition in concurrent request handler    │
  │   File: src/handler.go:45                                      │
  │   Code Context:                                                │
  │     43 | func (h *Handler) Process(ctx context.Context) {      │
  │     44 |     h.counter++  // ← NOT THREAD-SAFE                 │
  │     45 |     data := h.sharedMap[key]                          │
  │   Why it matters: Multiple goroutines can corrupt shared state │
  │   Recommendation: Use sync.Mutex or atomic operations          │
  │                                                                 │
  │ Issue #2 [HIGH]                                                │
  │   Description: Unchecked error return from database query      │
  │   File: src/repo.go:123                                        │
  │   Code Context:                                                │
  │     121 | func (r *Repo) GetUser(id string) (*User, error) {   │
  │     122 |     result, _ := r.db.Query(query, id)  // ← IGNORED │
  │     123 |     return parseUser(result), nil                    │
  │   Why it matters: Silent failures can cause data corruption    │
  │   Recommendation: Check and handle the error properly          │
  │                                                                 │
  │ UNIT: [subtask-2] - [subtask name]                             │
  │ ───────────────────────────────────────────────────────────────│
  │ Issue #3 [HIGH]                                                │
  │   Description: SQL injection vulnerability                     │
  │   File: src/query.go:89                                        │
  │   Code Context:                                                │
  │     87 | func BuildQuery(userInput string) string {            │
  │     88 |     return fmt.Sprintf("SELECT * FROM users WHERE     │
  │     89 |            name = '%s'", userInput)  // ← INJECTABLE  │
  │   Why it matters: Attacker can execute arbitrary SQL           │
  │   Recommendation: Use parameterized queries                    │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  
  → THEN: Ask user for action:
  "CodeRabbit found [N] issues in [M] units. What would you like to do?"
    (a) Fix all issues - dispatch implementation agent per unit
    (b) Proceed to Gate 5 (acknowledge risk)
    (c) Review findings in detail (show code context)

  IF user selects (a) Fix issues:
    → ⛔ DO NOT edit files directly
    → FOR EACH unit WITH issues (validation_scope.units where status == "ISSUES_FOUND"):
    
        Display:
        ┌─────────────────────────────────────────────────────────────────┐
        │ 🔧 DISPATCHING FIX: [unit.id] ([current]/[total with issues])   │
        ├─────────────────────────────────────────────────────────────────┤
        │ Unit: [unit.name]                                              │
        │ Critical Issues: [N]                                           │
        │ High Issues: [N]                                               │
        └─────────────────────────────────────────────────────────────────┘
        
        → DISPATCH implementation agent with unit-specific findings:
        
        Task:
          subagent_type: "[same agent used in Gate 0]"
          description: "Fix CodeRabbit issues for [unit.id]"
          prompt: |
            ## CodeRabbit Issues to Fix - [unit.id]
            
            **Scope:** This fix is for [subtask/task]: [unit.name]
            **Files in Scope:** [unit.files.join(", ")]
            
            The following issues were found by CodeRabbit CLI external review
            for THIS SPECIFIC [subtask/task].
            
            ⚠️ IMPORTANT: Only fix issues in files belonging to this unit:
            [unit.files list]
            
            ### Critical Issues
            [list from unit.issues.critical]
            
            ### High Issues  
            [list from unit.issues.high]
            
            ## Requirements
            1. Fix each issue following Ring Standards
            2. Only modify files in scope: [unit.files]
            3. Run tests to verify fixes don't break functionality
            4. Commit fixes with message referencing unit: "fix([unit.id]): [description]"
        
        → Wait for agent to complete
        → Record fix result for this unit
        
        → VALIDATE EACH ISSUE INDIVIDUALLY:
        ┌─────────────────────────────────────────────────────────────────┐
        │ 🔍 VALIDATING FIXES FOR: [unit.id]                              │
        ├─────────────────────────────────────────────────────────────────┤
        │                                                                 │
        │ Each issue MUST be validated individually:                      │
        │                                                                 │
        │ Issue #1: [issue description]                                   │
        │   File: [file:line]                                            │
        │   Severity: CRITICAL                                           │
        │   Fix Applied: [description of fix]                            │
        │   Validation: ✅ RESOLVED / ❌ NOT RESOLVED                     │
        │   Evidence: [code snippet or test result]                      │
        │                                                                 │
        │ Issue #2: [issue description]                                   │
        │   File: [file:line]                                            │
        │   Severity: HIGH                                               │
        │   Fix Applied: [description of fix]                            │
        │   Validation: ✅ RESOLVED / ❌ NOT RESOLVED                     │
        │   Evidence: [code snippet or test result]                      │
        │                                                                 │
        │ ... (repeat for ALL issues)                                    │
        │                                                                 │
        └─────────────────────────────────────────────────────────────────┘
        
        → IF any issue NOT RESOLVED:
            → Identify the correct agent for re-dispatch:
              - Check gate0_handoff.implementation_agent (if available)
              - OR infer from file type:
                - *.go files → ring:backend-engineer-golang
                - *.ts files (backend) → ring:backend-engineer-typescript
                - *.ts/*.tsx files (frontend) → ring:frontend-engineer
                - *.yaml/*.yml (infra) → ring:devops-engineer
            
            → Re-dispatch ONLY unresolved issues to the correct agent:
            
            Task:
              subagent_type: "[correct agent based on file type or gate0_handoff]"
              description: "Retry fix for unresolved issues in [unit.id]"
              prompt: |
                ## RETRY: Unresolved CodeRabbit Issues - [unit.id]
                
                Previous fix attempt did NOT resolve these issues.
                This is attempt [N] of 2 maximum.
                
                ### Unresolved Issues (MUST FIX)
                | # | Severity | Description | File:Line | Previous Attempt | Why It Failed |
                |---|----------|-------------|-----------|------------------|---------------|
                | [issue.id] | [severity] | [description] | [file:line] | [what was tried] | [why not resolved] |
                
                ### Requirements
                1. Review the previous fix attempt and understand why it failed
                2. Apply a different/better solution
                3. Verify the fix resolves the issue
                4. Run relevant tests
                5. Commit with message: "fix([unit.id]): retry [issue description]"
            
            → Max 2 fix attempts per issue
            → IF issue still NOT RESOLVED after 2 attempts:
                → Mark as UNRESOLVED_ESCALATE
                → Add to escalation report for manual review
        
        → Record per-issue validation results:
        unit_validation = {
          id: unit.id,
          issues_validated: [
            {
              issue_id: 1,
              description: "[issue]",
              severity: "CRITICAL",
              file: "[file:line]",
              fix_applied: "[description]",
              status: "RESOLVED" | "NOT_RESOLVED",
              evidence: "[snippet or test]",
              attempts: 1
            },
            ...
          ],
          all_resolved: true | false
        }
    
    → AFTER ALL UNITS FIXED:
        Display:
        ┌─────────────────────────────────────────────────────────────────┐
        │ ✅ FIX DISPATCH COMPLETE                                        │
        ├─────────────────────────────────────────────────────────────────┤
        │ Units Fixed: [N] / [total with issues]                         │
        │ Total Issues Validated: [N]                                    │
        │ Issues Resolved: [N] / [N]                                     │
        │                                                                 │
        │ Per-Unit Fix Status:                                           │
        │ ┌──────────────┬────────────┬───────────────────────┐          │
        │ │ Unit ID      │ Status     │ Commit                │          │
        │ ├──────────────┼────────────┼───────────────────────┤          │
        │ │ [subtask-1]  │ ✅ FIXED   │ abc123                │          │
        │ │ [subtask-2]  │ ✅ FIXED   │ def456                │          │
        │ └──────────────┴────────────┴───────────────────────┘          │
        │                                                                 │
        │ Issue-Level Validation Details:                                │
        │ ┌──────────────────────────────────────────────────────────┐   │
        │ │ UNIT: [subtask-1]                                        │   │
        │ ├──────────────────────────────────────────────────────────┤   │
        │ │ #1 [CRITICAL] Race condition in handler                  │   │
        │ │    File: src/handler.go:45                               │   │
        │ │    Fix: Added mutex lock                                 │   │
        │ │    Status: ✅ RESOLVED                                   │   │
        │ │    Evidence: Test race_test.go passes                    │   │
        │ ├──────────────────────────────────────────────────────────┤   │
        │ │ #2 [HIGH] Unchecked error return                         │   │
        │ │    File: src/handler.go:67                               │   │
        │ │    Fix: Added error check with proper handling           │   │
        │ │    Status: ✅ RESOLVED                                   │   │
        │ │    Evidence: Error path verified in unit test            │   │
        │ └──────────────────────────────────────────────────────────┘   │
        │                                                                 │
        └─────────────────────────────────────────────────────────────────┘

LEGACY FLOW (when validation_scope.mode == "task"):
  IF CodeRabbit found CRITICAL or HIGH issues:
    → Display findings to user
    → Ask: "CodeRabbit found [N] critical/high issues. Fix now or proceed anyway?"
      (a) Fix issues - dispatch to implementation agent
      (b) Proceed to Gate 5 (acknowledge risk)
      (c) Review findings in detail

    IF user selects (a) Fix issues:
      → ⛔ DO NOT edit files directly
      → DISPATCH implementation agent with CodeRabbit findings:
      
      Task:
        subagent_type: "[same agent used in Gate 0]"
        description: "Fix CodeRabbit issues for [unit_id]"
        prompt: |
          ## CodeRabbit Issues to Fix
          
          The following issues were found by CodeRabbit CLI external review.
          Fix ALL Critical and High severity issues.
          
          ### Critical Issues
          [list from CodeRabbit output]
          
          ### High Issues
          [list from CodeRabbit output]
          
          ## Requirements
          1. Fix each issue following Ring Standards
          2. Run tests to verify fixes don't break functionality
          3. Commit fixes with descriptive message
    
    → After agent completes, re-run CodeRabbit: `coderabbit --prompt-only`
    → If CodeRabbit issues remain, repeat fix cycle (max 2 iterations for CodeRabbit)
    
    → ⛔ AFTER CodeRabbit passes, MUST re-run Ring reviewers:
    
    ┌─────────────────────────────────────────────────────────────────┐
    │ 🔄 RE-RUNNING RING REVIEWERS AFTER CODERABBIT FIXES             │
    ├─────────────────────────────────────────────────────────────────┤
    │                                                                 │
    │ CodeRabbit fixes may have introduced new issues detectable by   │
    │ Ring reviewers. Re-validation is MANDATORY before Gate 5.       │
    │                                                                 │
    └─────────────────────────────────────────────────────────────────┘
    
    Step 7.5.3a: Re-Run All 7 Ring Reviewers
    ─────────────────────────────────────────
    1. Get new HEAD_SHA after CodeRabbit fixes
    2. Dispatch all 7 reviewers in parallel (per Step 3):
       - ring:code-reviewer
       - ring:business-logic-reviewer
       - ring:security-reviewer
       - ring:test-reviewer
       - ring:nil-safety-reviewer
       - ring:consequences-reviewer
       - ring:dead-code-reviewer
    3. Wait for all 7 to complete

    Step 7.5.3b: Handle Ring Reviewer Results
    ─────────────────────────────────────────
    IF all 7 Ring reviewers PASS:
      → Proceed to Step 8 (Success Output)
    
    IF any Ring reviewer finds CRITICAL/HIGH/MEDIUM issues:
      → Increment ring_revalidation_iterations counter
      → IF ring_revalidation_iterations >= 2:
          → ESCALATE: "Max iterations reached after CodeRabbit fixes"
          → Go to Step 9 (Escalate)
      → DISPATCH implementation agent to fix Ring reviewer issues
      → After fixes committed:
          → Re-run CodeRabbit: `coderabbit --prompt-only`
          → IF CodeRabbit passes:
              → Re-run all 7 Ring reviewers (loop back to Step 7.5.3a)
          → IF CodeRabbit finds issues:
              → Fix CodeRabbit issues first, then re-run Ring reviewers
    
    State tracking for CodeRabbit fix cycle:
    ```
    coderabbit_fix_state = {
      coderabbit_iterations: 0,      // max 2 for CodeRabbit-only fixes
      ring_revalidation_iterations: 0,  // max 2 for Ring reviewer re-runs
      total_max_iterations: 4        // absolute cap: 2 CR + 2 Ring
    }
    ```

IF CodeRabbit found only MEDIUM/LOW issues:
  → Display summary
  → ⛔ DO NOT edit files directly to add TODOs
  → DISPATCH implementation agent to add TODO comments:
  
  Task:
    subagent_type: "[same agent used in Gate 0]"
    description: "Add TODO comments for CodeRabbit findings"
    prompt: |
      Add TODO comments for these CodeRabbit findings:
      [list MEDIUM/LOW issues with file:line]
      
      Format: // TODO(coderabbit): [issue description]
  
  → After TODO comments added (code changed):
      → Re-run all 7 Ring reviewers (per Step 7.5.3a above)
      → IF Ring reviewers PASS: Proceed to Step 8
      → IF Ring reviewers find issues: Fix and re-run (max 2 iterations)

IF CodeRabbit found no issues:
  → Display: "✅ CodeRabbit review passed - no additional issues found"
  → No code changes made by CodeRabbit flow
  → Proceed directly to Step 8 (no Ring re-run needed)
```

### Anti-Rationalization for Direct Editing

**See [shared-patterns/orchestrator-direct-editing-anti-rationalization.md](../shared-patterns/orchestrator-direct-editing-anti-rationalization.md) - same table applies here.**

*Applies to: Step 6 (Fix dispatch after Ring reviewers) & Step 7.5.3 (Fix dispatch after CodeRabbit)*

#### Step 7.5.4: CodeRabbit Results Summary

```markdown
## CodeRabbit External Review
**Status:** [PASS|ISSUES_FOUND|SKIPPED]
**Validation Mode:** [SUBTASK-LEVEL|TASK-LEVEL]
**Units Validated:** [N]
**Total Issues Found:** [N]
**Issues Resolved:** [N]/[N]

### Per-Unit Validation Results
| Unit ID | Unit Name | Status | Critical | High | Medium | Low |
|---------|-----------|--------|----------|------|--------|-----|
| [subtask-1] | [name] | ✅ PASS | 0 | 0 | 0 | 1 |
| [subtask-2] | [name] | ✅ FIXED | 1→0 | 2→0 | 0 | 0 |
| [task-id] | [name] | ✅ PASS | 0 | 0 | 0 | 0 |

### Issues Found - Detailed Description (ALWAYS shown when issues exist)

#### Unit: [subtask-2]
| # | Severity | Description | File:Line | Code Context | Why It Matters | Recommendation |
|---|----------|-------------|-----------|--------------|----------------|----------------|
| 1 | CRITICAL | Race condition | handler.go:45 | `h.counter++` not thread-safe | Corrupts shared state | Use sync.Mutex |
| 2 | HIGH | Unchecked error | repo.go:123 | `result, _ := r.db.Query()` | Silent failures | Handle error |
| 3 | HIGH | SQL injection | query.go:89 | `fmt.Sprintf("...%s", input)` | Security breach | Parameterized query |

### Issue-Level Validation (REQUIRED after fixes are applied)

#### Unit: [subtask-2]
| # | Severity | Description | File:Line | Fix Applied | Status | Evidence |
|---|----------|-------------|-----------|-------------|--------|----------|
| 1 | CRITICAL | Race condition in concurrent handler | handler.go:45 | Added mutex lock around shared state | ✅ RESOLVED | race_test.go passes |
| 2 | HIGH | Unchecked error from DB query | repo.go:123 | Added error check with rollback | ✅ RESOLVED | Error path tested |
| 3 | HIGH | SQL injection vulnerability | query.go:89 | Used parameterized query | ✅ RESOLVED | Security test added |

#### Unit: [subtask-3] (if applicable)
| # | Severity | Description | File:Line | Fix Applied | Status | Evidence |
|---|----------|-------------|-----------|-------------|--------|----------|
| 1 | HIGH | Missing input validation | api.go:34 | Added validation middleware | ✅ RESOLVED | Fuzz test passes |

### Overall Summary by Severity
| Severity | Found | Resolved | Remaining | Action |
|----------|-------|----------|-----------|--------|
| Critical | [N] | [N] | 0 | Fixed |
| High | [N] | [N] | 0 | Fixed |
| Medium | [N] | [N] | 0 | TODO added |
| Low | [N] | - | [N] | TODO added |
```

### CodeRabbit Skip Scenarios (ONLY VALID PATHS)

**⛔ CodeRabbit can ONLY be skipped in these specific scenarios. Any other skip is a VIOLATION.**

| Scenario | Record As | Next Step | Why Valid |
|----------|-----------|-----------|-----------|
| CLI not installed, user **explicitly** declines install | `SKIPPED (not installed, user declined)` | Step 8 | User was asked and chose not to install |
| Installation failed after attempt, user skips | `SKIPPED (installation failed)` | Step 8 | Technical failure, user informed |
| Authentication failed after attempt, user skips | `SKIPPED (auth failed)` | Step 8 | Technical failure, user informed |
| Environment doesn't support (CI/container) | `SKIPPED (unsupported environment)` | Step 8 | Technical limitation |

**⛔ INVALID SKIP SCENARIOS (FORBIDDEN):**

| Invalid Scenario | Why FORBIDDEN | Required Action |
|------------------|---------------|-----------------|
| CLI installed but "skipped for speed" | Installed = MANDATORY | **Run CodeRabbit** |
| CLI installed but "Ring reviewers passed" | Complementary tools, both required | **Run CodeRabbit** |
| CLI not installed, no prompt shown | MUST ask user about installation | **Show installation prompt** |
| Silent skip without user interaction | All skips require explicit user choice | **Ask user** |

**⛔ NON-NEGOTIABLE:** When CodeRabbit CLI IS installed and authenticated, execution is **MANDATORY** - it CANNOT be skipped under any circumstance.

---

## Step 8: Display Accumulated Findings & Prepare Success Output

**⛔ BEFORE generating success output, MUST display accumulated CodeRabbit findings.**

### Step 8.1: Display Accumulated CodeRabbit Findings

```text
IF .coderabbit-findings.md exists:
  
  ┌─────────────────────────────────────────────────────────────────┐
  │ 📋 CODERABBIT FINDINGS - ACCUMULATED DURING REVIEW              │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ The following issues were identified by CodeRabbit during the  │
  │ review process. Review before proceeding to commit.            │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  
  → Display contents of .coderabbit-findings.md
  → Show summary table:
  
  ┌─────────────────────────────────────────────────────────────────┐
  │ 📊 CODERABBIT FINDINGS SUMMARY                                  │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ | Severity | Count | Status |                                  │
  │ |----------|-------|--------|                                  │
  │ | Critical | [N]   | [pending/fixed] |                         │
  │ | High     | [N]   | [pending/fixed] |                         │
  │ | Medium   | [N]   | [pending/fixed] |                         │
  │ | Low      | [N]   | [pending/fixed] |                         │
  │                                                                 │
  │ Total Issues: [N] | Fixed: [N] | Pending: [N]                  │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  
  → Ask user:
  ┌─────────────────────────────────────────────────────────────────┐
  │ ❓ ACTION REQUIRED                                              │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ [N] CodeRabbit issues are pending. What would you like to do?  │
  │                                                                 │
  │   (a) Fix all pending issues now (dispatch implementation agent)│
  │   (b) Review and fix issues one-by-one (interactive mode)      │
  │   (c) Acknowledge and proceed to commit (issues documented)    │
  │                                                                 │
  │ Note: Choosing (c) will include findings file in commit for    │
  │       tracking. Issues remain documented for future fixing.    │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  
  IF user selects (a) Fix all issues:
    → Dispatch implementation agent with ALL pending issues from findings file
    → After fixes, update .coderabbit-findings.md (mark issues as FIXED)
    → Re-run CodeRabbit validation for affected files
    → Loop back to Step 8.1 to display updated findings
  
  IF user selects (b) Interactive mode (one-by-one):
    → Go to Step 8.1.1 (Interactive Issue Review)
  
  IF user selects (c) Acknowledge and proceed:
    → Record: "CodeRabbit issues acknowledged by user"
    → Include .coderabbit-findings.md in commit (for audit trail)
    → Proceed to Step 8.2 (Success Output)

─────────────────────────────────────────────────────────────────
Step 8.1.1: Interactive Issue Review (One-by-One)
─────────────────────────────────────────────────────────────────

issues_to_fix = []
issues_to_skip = []

FOR EACH issue IN pending_issues (ordered by severity: CRITICAL → HIGH → MEDIUM → LOW):
  
  Display:
  ┌─────────────────────────────────────────────────────────────────┐
  │ 🔍 ISSUE [current]/[total] - [SEVERITY]                         │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ Unit: [unit.id] - [unit.name]                                  │
  │ File: [file:line]                                              │
  │                                                                 │
  │ Description:                                                   │
  │   [issue description]                                          │
  │                                                                 │
  │ Code Context:                                                  │
  │   [code snippet around the issue]                              │
  │                                                                 │
  │ Why it matters:                                                │
  │   [explanation of impact]                                      │
  │                                                                 │
  │ Recommendation:                                                │
  │   [suggested fix]                                              │
  │                                                                 │
  ├─────────────────────────────────────────────────────────────────┤
  │ What would you like to do with this issue?                     │
  │                                                                 │
  │   (f) Fix this issue                                           │
  │   (s) Skip this issue (acknowledge)                            │
  │   (a) Fix ALL remaining issues                                 │
  │   (k) Skip ALL remaining issues                                │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  
  IF user selects (f) Fix:
    → Add to issues_to_fix list
    → Continue to next issue
  
  IF user selects (s) Skip:
    → Add to issues_to_skip list
    → Continue to next issue
  
  IF user selects (a) Fix ALL remaining:
    → Add current + all remaining to issues_to_fix list
    → Break loop
  
  IF user selects (k) Skip ALL remaining:
    → Add current + all remaining to issues_to_skip list
    → Break loop

AFTER loop completes:
  Display summary:
  ┌─────────────────────────────────────────────────────────────────┐
  │ 📋 INTERACTIVE REVIEW COMPLETE                                  │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │ Issues to fix: [N]                                             │
  │   [list of issues selected for fixing]                         │
  │                                                                 │
  │ Issues to skip: [N]                                            │
  │   [list of issues selected to skip]                            │
  │                                                                 │
  │ Proceed with this selection? (y/n)                             │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
  
  IF user confirms (y):
    IF issues_to_fix.length > 0:
      → Dispatch implementation agent with ONLY issues_to_fix
      → After fixes, update .coderabbit-findings.md:
        - Mark fixed issues as FIXED
        - Mark skipped issues as ACKNOWLEDGED
      → Re-run CodeRabbit validation for affected files
      → Loop back to Step 8.1
    ELSE:
      → All issues skipped/acknowledged
      → Proceed to Step 8.2 (Success Output)
  
  IF user cancels (n):
    → Return to Step 8.1 main prompt

ELSE (no findings file exists):
  → CodeRabbit was skipped or found no issues
  → Proceed directly to Step 8.2 (Success Output)
```

### Step 8.1.5: Visual Review Report

**MANDATORY: Generate a visual HTML report before presenting the review summary.**

Invokes `Skill("ring:visual-explainer")` to produce a self-contained HTML page showing review results visually. This complements the markdown output with an interactive browser view.

**Read the code-diff template first:** Read `default/skills/visual-explainer/templates/code-diff.html` to absorb the patterns before generating.

**Generate the HTML report with these sections:**

**1. Review Dashboard**
- Overall status (PASS/FAIL) with large status indicator
- Unit ID, iterations count, total duration
- KPI cards: Total issues found, issues fixed, issues remaining, reviewers passed (X/7)

**2. Reviewer Verdicts Panel**
- 7 reviewer cards in a grid layout, each showing:
  - Reviewer name, PASS/FAIL badge
  - Issue count by severity (severity badges)
  - Key findings summary (1-2 lines)

**3. Issues by Severity**
- Severity breakdown bar (Critical red / High orange / Medium violet / Low dim)
- Per-issue cards with: severity badge, description, file:line reference, reviewer that found it, recommendation
- Issues that were fixed during iterations: show before (issue) vs after (fix applied) using diff panels

**4. CodeRabbit Findings** (if applicable)
- Separate section showing CodeRabbit-specific issues
- Status per unit validated

**5. Fix Iteration Timeline** (if iterations > 0)
- Visual timeline showing: Iteration 1 → Issues found → Fixes applied → Iteration 2 → ...

**Output:** Save to `docs/codereview/review-report-{unit_id}.html`

**Open in browser:**
```text
macOS: open docs/codereview/review-report-{unit_id}.html
Linux: xdg-open docs/codereview/review-report-{unit_id}.html
```

**Tell the user** the file path. The visual report opens before the markdown summary is displayed.

See [dev-team/skills/shared-patterns/anti-rationalization-visual-report.md](../../../dev-team/skills/shared-patterns/anti-rationalization-visual-report.md) for anti-rationalization table.

### Step 8.2: Generate Success Output

```text
Generate skill output:

## Review Summary
**Status:** PASS
**Unit ID:** [unit_id]
**Iterations:** [review_state.iterations]

## Issues by Severity
| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | [count] |
| Cosmetic | [count] |

## Reviewer Verdicts
| Reviewer | Verdict | Issues |
|----------|---------|--------|
| ring:code-reviewer | ✅ PASS | [count] |
| ring:business-logic-reviewer | ✅ PASS | [count] |
| ring:security-reviewer | ✅ PASS | [count] |
| ring:test-reviewer | ✅ PASS | [count] |
| ring:nil-safety-reviewer | ✅ PASS | [count] |
| ring:consequences-reviewer | ✅ PASS | [count] |
| ring:dead-code-reviewer | ✅ PASS | [count] |

## Review Slicing
[IF review_state.slicing.enabled:]
**Sliced:** Yes — [review_state.slicing.slice_count] thematic groups
**Slices:** [slice names with file counts]
**Cross-Cutting Concerns:** [count]
[ELSE:]
**Sliced:** No — full-diff review

## Low/Cosmetic Issues (TODO/FIXME added)
[list with file locations]

## CodeRabbit Findings
**Findings File:** .coderabbit-findings.md
**Total Issues Found:** [N]
**Issues Fixed:** [N]
**Issues Acknowledged:** [N]
**Status:** [ALL_FIXED | ACKNOWLEDGED | NO_ISSUES]

## Handoff to Next Gate
- Review status: COMPLETE
- All blocking issues: RESOLVED
- Reviewers passed: 7/7
- CodeRabbit findings: [status]
- Ready for Gate 5 (Validation): YES
```

## Step 9: Escalate - Max Iterations Reached

**VISUAL REPORT:** Generate the same visual HTML report as Step 8.1.5, but with FAIL status prominently displayed. The report highlights unresolved issues in red, shows which reviewers still have FAIL verdicts, and includes the full iteration history. Save to `docs/codereview/review-report-{unit_id}.html` and open in browser.

```text
Generate skill output:

## Review Summary
**Status:** FAIL
**Unit ID:** [unit_id]
**Iterations:** [max_iterations] (MAX REACHED)

## Issues by Severity
| Severity | Count |
|----------|-------|
| Critical | [count] |
| High | [count] |
| Medium | [count] |

## Unresolved Issues
[list all Critical/High/Medium still open]

## Reviewer Verdicts
| Reviewer | Verdict |
|----------|---------|
| ring:code-reviewer | [PASS/FAIL] |
| ring:business-logic-reviewer | [PASS/FAIL] |
| ring:security-reviewer | [PASS/FAIL] |

## Handoff to Next Gate
- Review status: FAILED
- Unresolved blocking issues: [count]
- Ready for Gate 5: NO
- **Action Required:** User must manually resolve issues

⛔ ESCALATION: Max iterations (3) reached. Blocking issues remain.
```

---

## Blocker Criteria

STOP and report if:

| Decision Type | Blocker Condition | Required Action |
|---|---|---|
| Missing git context | Cannot determine base_sha or head_sha | STOP and request valid git context |
| No files changed | git diff returns empty between refs | STOP and verify implementation exists |
| Max iterations exceeded | 3 fix iterations completed but issues remain | STOP and escalate to user for manual resolution |
| Pre-analysis pipeline fails | Mithril installation fails or execution returns error | Report and proceed in DEGRADED MODE |
| All reviewers fail to dispatch | Task tool unavailable or errors | STOP and report infrastructure issue |

### Cannot Be Overridden

The following requirements CANNOT be waived:
- MUST dispatch ALL 7 reviewers in parallel (not sequential, not partial)
- CANNOT edit source files directly - MUST dispatch implementation agent for fixes
- MUST re-run ALL 7 reviewers after any fix (no cherry-picking reviewers)
- CANNOT skip CodeRabbit if installed and authenticated
- MUST fix Critical, High, and Medium severity issues before Gate 5

## Severity Calibration

| Severity | Condition | Required Action |
|---|---|---|
| CRITICAL | Security vulnerability found | MUST fix immediately before any other work |
| CRITICAL | Data loss or corruption risk | MUST fix immediately |
| HIGH | Business logic error or missing validation | MUST fix before completing Gate 4 |
| HIGH | Nil/null safety violation | MUST fix before completing Gate 4 |
| MEDIUM | Code quality issue affecting maintainability | MUST fix before completing Gate 4 |
| MEDIUM | Missing error handling | MUST fix before completing Gate 4 |
| LOW | Code style or minor improvements | Add TODO comment, fix in next iteration |
| COSMETIC | Formatting, naming suggestions | Add FIXME comment, optional fix |

## Pressure Resistance

See [dev-team/skills/shared-patterns/shared-pressure-resistance.md](../../dev-team/skills/shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios.

| User Says | Your Response |
|-----------|---------------|
| "Skip review, code is simple" | "Simple code can have security issues. Dispatching all 7 reviewers." |
| "Just run ring:code-reviewer" | "All 7 reviewers run in parallel. No time saved by skipping." |
| "Fix later, merge now" | "Blocking issues (Critical/High/Medium) MUST be fixed before Gate 5." |

## Anti-Rationalization Table

See [dev-team/skills/shared-patterns/shared-anti-rationalization.md](../../dev-team/skills/shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

### Gate 4-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Run reviewers one at a time" | Sequential = slow. Parallel = 7x faster. | **Dispatch all 7 in single message** |
| "Skip security for internal code" | Internal code can have vulnerabilities. | **Include ring:security-reviewer** |
| "Critical issue is false positive" | Prove it with evidence, don't assume. | **Fix or provide evidence** |
| "Low issues don't need TODO" | TODOs ensure issues aren't forgotten. | **Add TODO comments** |
| "6 of 7 reviewers passed" | Gate 4 requires ALL 7. 6/7 = 0/7. | **Re-run ALL 7 reviewers** |
| "MEDIUM is not blocking" | MEDIUM = MUST FIX. Same as CRITICAL/HIGH. | **Fix MEDIUM issues NOW** |

---

## Execution Report Format

```markdown
## Review Summary
**Status:** [PASS|FAIL|NEEDS_FIXES]
**Unit ID:** [unit_id]
**Duration:** [Xm Ys]
**Iterations:** [N]

## Issues by Severity
| Severity | Count |
|----------|-------|
| Critical | [N] |
| High | [N] |
| Medium | [N] |
| Low | [N] |

## Reviewer Verdicts
| Reviewer | Verdict |
|----------|---------|
| ring:code-reviewer | ✅/❌ |
| ring:business-logic-reviewer | ✅/❌ |
| ring:security-reviewer | ✅/❌ |
| ring:test-reviewer | ✅/❌ |
| ring:nil-safety-reviewer | ✅/❌ |
| ring:consequences-reviewer | ✅/❌ |
| ring:dead-code-reviewer | ✅/❌ |

## Review Slicing
**Sliced:** [Yes — N thematic groups | No — full-diff review]
**Cross-Cutting Concerns:** [N] (if sliced)

## CodeRabbit External Review (MANDATORY if installed, Optional to install)
**Status:** [PASS|ISSUES_FOUND|SKIPPED|NOT_INSTALLED]
**Validation Mode:** [SUBTASK-LEVEL|TASK-LEVEL]
**Units Validated:** [N]
**Units Passed:** [N]/[N]
**Issues Found:** [N]
**Issues Resolved:** [N]/[N]

### Per-Unit Results (if subtask-level)
| Unit ID | Status | Critical | High | Medium | Low |
|---------|--------|----------|------|--------|-----|
| [subtask-1] | ✅ PASS | 0 | 0 | 0 | 1 |
| [subtask-2] | ✅ FIXED | 0 | 0 | 0 | 0 |

### Issue-Level Validation (REQUIRED when issues were fixed)
| Unit | # | Severity | Description | Fix Applied | Status | Evidence |
|------|---|----------|-------------|-------------|--------|----------|
| subtask-2 | 1 | CRITICAL | Race condition | Mutex added | ✅ RESOLVED | Test passes |
| subtask-2 | 2 | HIGH | Unchecked error | Error handling added | ✅ RESOLVED | Test passes |

## Handoff to Next Gate
- Review status: [COMPLETE|FAILED]
- Blocking issues: [resolved|N remaining]
- Review slicing: [N slices | not sliced]
- CodeRabbit: [PASS|SKIPPED|N issues acknowledged]
- CodeRabbit validation: [N]/[N] units passed
- Ready for Gate 5: [YES|NO]
```
