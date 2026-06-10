## Step 10: Gate 8 - Review (Per Epic — after all tasks complete Gate 0 and before Gate 9)

⛔ **CADENCE:** This gate runs ONCE per epic, NOT per task. Reviewers see the CUMULATIVE diff of all tasks in the epic — cross-task interaction bugs (contract drift, hidden coupling, duplicated logic) are MORE visible at this cadence, not less.

**REQUIRED SUB-SKILL:** Use `ring:reviewing-code`

### Step 10.1: Prepare Input for ring:reviewing-code Skill

⛔ **Input scope:** EPIC-level. `base_sha` is the SHA before the FIRST task's Gate 0 (i.e., the epic's starting commit); `head_sha` is the current HEAD after all tasks up to this point. The resulting diff covers ALL tasks of the epic.

```text
epic = state.epics[state.current_epic_index]

review_input = {
  // REQUIRED - EPIC-level
  unit_id: epic.id,  // EPIC id (Epic N.M)
  base_sha: epic.base_sha,            // SHA before the FIRST task started
  head_sha: [current HEAD],           // SHA after all tasks up to this point

  // REQUIRED - summary and requirements aggregated from epic + tasks
  implementation_summary: epic.title + "\n" +
    epic.tasks.map(t => "- " + t.id + ": " + (t.summary || "")).join("\n"),
  requirements: epic.acceptance_criteria
    || flatten(epic.tasks.map(t => t.acceptance_criteria || [])),

  // OPTIONAL - additional context
  implementation_files: flatten(epic.tasks.map(t =>
    t.gate_progress.implementation.files_changed || []
  )),  // UNION across tasks
  gate0_handoffs: epic.tasks.map(t => t.gate_progress.implementation)  // ARRAY
}
```

### Step 10.2: Invoke ring:reviewing-code Skill

```text
1. Record gate start timestamp

2. Invoke ring:reviewing-code skill with structured input:

   Skill("ring:reviewing-code") with input:
     unit_id: review_input.unit_id                    # EPIC id (Epic N.M)
     base_sha: review_input.base_sha                  # SHA before first task
     head_sha: review_input.head_sha                  # Current HEAD (cumulative diff)
     implementation_summary: review_input.implementation_summary
     requirements: review_input.requirements
     implementation_files: review_input.implementation_files  # UNION across tasks
     gate0_handoffs: review_input.gate0_handoffs      # ARRAY of task handoffs

   The skill handles:
   - Dispatching all 9 default reviewers plus triggered specialists in PARALLEL (single message)
   - Defaults: ring:code-reviewer, ring:logic-reviewer, ring:security-reviewer, ring:test-reviewer, ring:nil-reviewer, ring:dead-code-reviewer, ring:perf-reviewer, ring:tenancy-reviewer, ring:commons-reviewer
   - Conditional specialists: ring:obs-reviewer, ring:systemplane-reviewer, ring:streaming-reviewer when their triggers match
   - Aggregating issues by severity (CRITICAL/HIGH/MEDIUM/LOW/COSMETIC)
   - Reporting findings only; remediation and re-review are orchestrator responsibilities after this skill returns

3. Parse skill output for results:
   
   Expected output sections:
   - "## Review Summary" → status, iterations
   - "## Issues by Severity" → counts per severity level
   - "## Reviewer Verdicts" → all selected reviewers

   if skill output contains "Status: PASS":
      → Gate 8 PASSED. Proceed to Step 10.3.

   if skill output contains "Status: ISSUES_FOUND":
      → Gate 8 BLOCKED.
      → Dispatch fixes to the appropriate implementation agent, then re-run ring:reviewing-code.

   if skill output contains "Status: INCOMPLETE":
      → Gate 8 INCOMPLETE. Fix dispatch/reviewer failure before proceeding.

4. **MANDATORY: ⛔ Save state to file — Write tool → [state.state_path]**
```

### Step 10.3: Gate 8 Complete

```text
5. When ring:reviewing-code skill returns PASS:

   Parse from skill output:
   - default_reviewers_passed: extract default reviewer PASS count from "## Reviewer Verdicts" (must be "9/9")
   - conditional_specialists_triggered: extract triggered conditional specialist names from "## Conditional Specialists Triggered"
   - conditional_specialists_passed: extract conditional specialist PASS count from "## Reviewer Verdicts" ("0/0" when none triggered)
   - selected_reviewer_count: 9 + conditional_specialists_triggered.length
   - issues_critical: extract count from "## Issues by Severity"
   - issues_high: extract count from "## Issues by Severity"
   - issues_medium: extract count from "## Issues by Severity"
   - iterations: extract from "Iterations:" line

   - agent_outputs.review = {
       skill: "ring:reviewing-code",
       output: "[full skill output]",
       iterations: [count],
       timestamp: "[ISO timestamp]",
       duration_ms: [execution time],
       default_reviewers_passed: "9/9",
       conditional_specialists_triggered: [],
       conditional_specialists_passed: "0/0",
       selected_reviewer_count: 9,
       code_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []  // Structured issues - see schema below
       },
       logic_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       security_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       nil_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       test_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       dead_code_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       perf_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       tenancy_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       },
       commons_reviewer: {
         verdict: "PASS",
         issues_count: N,
         issues: []
       }
     }
   
   **Populate `issues[]` for each reviewer with all issues found (even if fixed):**
   ```json
   issues: [
     {
       "severity": "CRITICAL|HIGH|MEDIUM|LOW|COSMETIC",
       "category": "error-handling|security|performance|maintainability|business-logic|...",
       "description": "[detailed description of the issue]",
       "file": "internal/handler/user.go",
       "line": 45,
       "code_snippet": "return err",
       "suggestion": "Use fmt.Errorf(\"failed to create user: %w\", err)",
       "fixed": true|false,
       "fixed_in_iteration": [iteration number when fixed, null if not fixed]
     }
   ]
   ```
   
   **Issue tracking rules:**
   - all issues found across all iterations MUST be recorded
   - `fixed: true` + `fixed_in_iteration: N` for issues resolved during review
   - `fixed: false` + `fixed_in_iteration: null` for LOW/COSMETIC report items
   - This enables feedback-loop to analyze recurring issue patterns

6. Update state:
   - gate_progress.review.status = "completed"
   - gate_progress.review.completed_at = "[ISO timestamp]"
   (gate_progress.review is the gate verdict — status only. Reviewer pass counts,
    iterations, and per-reviewer outputs live in agent_outputs.review from step 5;
    do not duplicate them here.)

7. Proceed to Gate 9
```

### Gate 8 Anti-Rationalization

See [shared-patterns/shared-anti-rationalization.md](../../shared-patterns/shared-anti-rationalization.md) — the "Review Anti-Rationalizations" and "Universal" sections cover the common cases (low issue count, "one reviewer is enough", sequential review, "fix it later", user-authorized skip). Gate-8-specific cases below still apply:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Issue is cosmetic, not really MEDIUM" | Reviewer decided severity. Accept their judgment. | **Fix the issue, re-run the selected review pool** |
| "Same issue keeps appearing, skip it" | Recurring issue = fix is wrong. Debug properly. | **Root cause analysis, then fix** |
| "Iteration limit reached, just proceed" | Limit = escalate, not bypass. Quality is non-negotiable. | **Escalate to user, DO NOT proceed** |
| "Tests pass, review issues don't matter" | Tests ≠ review. Different quality dimensions. | **Fix the issue, re-run the selected review pool** |

### Gate 8 Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just skip this MEDIUM issue" | "MEDIUM severity issues are blocking by definition. I MUST dispatch a fix to the appropriate agent before proceeding. This protects code quality." |
| "I'll fix it later, let's continue" | "Gate 8 is a HARD GATE. All CRITICAL/HIGH/MEDIUM issues must be resolved NOW. I'm dispatching the fix to [agent] and will re-run the selected review pool after." |
| "We're running out of time" | "Proceeding with known issues creates larger problems later. The fix dispatch is automated and typically takes 2-5 minutes. Quality gates exist to save time overall." |
| "Override the gate, I approve" | "User approval cannot override reviewer findings. The gate ensures code quality. I'll dispatch the fix now." |
| "It's just a style issue" | "If it's truly cosmetic, reviewers would mark it COSMETIC (non-blocking). MEDIUM means it affects maintainability or correctness. Fixing now." |

---
