### Standard Mode Dispatch

Use this dispatch when `review_state.slicing.enabled == false`.

**Scope header:** when `scope == "epic"`, inject this block immediately after each review request heading:

```markdown
**REVIEW SCOPE: EPIC-LEVEL**
This review covers the CUMULATIVE diff of epic {epic_id}, including changes from {N} tasks: {task_ids}. Review the epic as one integrated unit; task boundaries are implementation detail.
```

When `scope == "epic"`, use `cumulative_diff_range.base_sha` and `cumulative_diff_range.head_sha` for every reviewer.

## Finding Eligibility Gate

Reviewers MUST NOT report slop findings. A finding is eligible only when all checks pass:

| Gate | Requirement |
|------|-------------|
| Changed or reachable diff | The issue is in changed code or code directly reachable from changed code. |
| Concrete impact path | The report explains what breaks, leaks, slows down, or becomes unmaintainable. |
| File:line evidence | The report cites exact file:line evidence, not generic advice. |
| Smaller recommendation | The recommended fix is smaller than the problem it solves. No architecture astronautics. |
| Domain-reachable edge case | Edge cases must be reachable in the product/domain flow, not hypothetical language trivia. |

If any gate fails, do not report the finding.

Each prompt receives:
- `unit_id`, `base_sha`, `head_sha`
- `implementation_summary`, `requirements`, `implementation_files`
- pre-analysis context for that reviewer when available
- explicit instruction: report findings only; do not modify files

```yaml
# Task 1: Code Reviewer
Task:
  subagent_type: "ring:code-reviewer"
  description: "Code review for [unit_id]"
  prompt: |
    ## Code Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
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
    [preanalysis_state.context["ring:code-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Architecture, design patterns, maintainability, naming, error handling, file-size compliance, and existing Ring standards.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Task 2: Business Logic Reviewer
Task:
  subagent_type: "ring:logic-reviewer"
  description: "Business logic review for [unit_id]"
  prompt: |
    ## Business Logic Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
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
    [preanalysis_state.context["ring:logic-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Domain correctness, requirements coverage, state transitions, financial invariants, business edge cases, and mental execution.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Task 3: Security Reviewer
Task:
  subagent_type: "ring:security-reviewer"
  description: "Security review for [unit_id]"
  prompt: |
    ## Security Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
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
    [preanalysis_state.context["ring:security-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Authentication, authorization, input validation, injection, sensitive data handling, OWASP risks, and dependency security.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Task 4: Test Reviewer
Task:
  subagent_type: "ring:test-reviewer"
  description: "Test quality review for [unit_id]"
  prompt: |
    ## Test Quality Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
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
    [preanalysis_state.context["ring:test-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Behavioral coverage, edge cases, error paths, assertion quality, test independence, and mock anti-patterns.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Task 5: Nil-Safety Reviewer
Task:
  subagent_type: "ring:nil-reviewer"
  description: "Nil/null safety review for [unit_id]"
  prompt: |
    ## Nil-Safety Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
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
    [preanalysis_state.context["ring:nil-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Nil/null sources, propagation, dereference points, map/type assertion safety, optional chaining, and API response consistency.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Task 6: Dead Code Reviewer
Task:
  subagent_type: "ring:dead-code-reviewer"
  description: "Dead code review for [unit_id]"
  prompt: |
    ## Dead Code Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
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
    [preanalysis_state.context["ring:dead-code-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Code that became orphaned because of the change: changed files, direct dependents, transitive cascade, tests, validation, and security logic.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Task 7: Performance Reviewer
Task:
  subagent_type: "ring:perf-reviewer"
  description: "Performance review for [unit_id]"
  prompt: |
    ## Performance Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
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
    [preanalysis_state.context["ring:perf-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Hot-path allocations, goroutine leaks, N+1 queries, event-loop blocking, GC pressure, cgroup/runtime config, and connection pool sizing.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Task 8: Multi-Tenant Reviewer
Task:
  subagent_type: "ring:tenancy-reviewer"
  description: "Multi-tenant review for [unit_id]"
  prompt: |
    ## Multi-Tenant Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
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
    [preanalysis_state.context["ring:tenancy-reviewer"] or "No pre-analysis context available."]
    ## Focus
    TenantId extraction, dispatch layer usage, database-per-tenant isolation, tenant-scoped resources, and tenant leak scenarios.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Task 9: lib-commons Reviewer
Task:
  subagent_type: "ring:commons-reviewer"
  description: "lib-commons usage review for [unit_id]"
  prompt: |
    ## lib-commons Usage Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
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
    [preanalysis_state.context["ring:commons-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Correct lib-commons usage, version consistency, deprecated imports, and reinvented shared infrastructure.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Conditional Task: lib-observability Reviewer
# Trigger: diff touches tracing, metrics, logging, runtime recovery/panic safety,
# redaction, observability constants, or goroutines with recover/SafeGo implications.
Task:
  subagent_type: "ring:obs-reviewer"
  description: "lib-observability review for [unit_id]"
  prompt: |
    ## lib-observability Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]
    ## What Was Implemented
    [implementation_summary]
    ## Requirements
    [requirements]
    ## Files Changed
    [implementation_files or "Use git diff"]
    ## Trigger Matched
    This conditional specialist runs because the diff touches tracing, metrics, logging, runtime recovery/panic safety, redaction, observability constants, or goroutines with recover/SafeGo implications.
    ## Pre-Analysis Context
    [preanalysis_state.context["ring:obs-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Correct lib-observability usage: tracing propagation, metrics factory, structured logging, runtime SafeGo/recover, assertions, redaction, constants, and deprecated observability shim migration.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Conditional Task: lib-systemplane Reviewer
# Trigger: diff touches runtime config, hot-reload knobs, admin config surface,
# tenant-scoped settings, or systemplane imports/config.
Task:
  subagent_type: "ring:systemplane-reviewer"
  description: "lib-systemplane review for [unit_id]"
  prompt: |
    ## lib-systemplane Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]
    ## What Was Implemented
    [implementation_summary]
    ## Requirements
    [requirements]
    ## Files Changed
    [implementation_files or "Use git diff"]
    ## Trigger Matched
    This conditional specialist runs because the diff touches runtime config, hot-reload knobs, admin config surface, tenant-scoped settings, or systemplane imports/config.
    ## Pre-Analysis Context
    [preanalysis_state.context["ring:systemplane-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Correct lib-systemplane usage: runtime-mutable config lifecycle, hot reload, tenant-scoped settings, admin authorizers, v4 residue, and DIY config-watching replacement.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.

# Conditional Task: lib-streaming Reviewer
# Trigger: diff touches business events, outbox, event producers, broker publishing,
# CloudEvents, or event manifests/catalogs.
Task:
  subagent_type: "ring:streaming-reviewer"
  description: "lib-streaming review for [unit_id]"
  prompt: |
    ## lib-streaming Review Request
    [INJECT REVIEW SCOPE: EPIC-LEVEL block here when scope=epic]
    **Unit ID:** [unit_id]
    **Base SHA:** [base_sha]
    **Head SHA:** [head_sha]
    ## What Was Implemented
    [implementation_summary]
    ## Requirements
    [requirements]
    ## Files Changed
    [implementation_files or "Use git diff"]
    ## Trigger Matched
    This conditional specialist runs because the diff touches business events, outbox, event producers, broker publishing, CloudEvents, or event manifests/catalogs.
    ## Pre-Analysis Context
    [preanalysis_state.context["ring:streaming-reviewer"] or "No pre-analysis context available."]
    ## Focus
    Correct lib-streaming usage: Builder/Emitter wiring, durable outbox, CloudEvents, Catalog, manifest, NoopEmitter fallback, and raw publisher avoidance for business events.
    ## Required Output
    Use the reviewer agent's `## Output Format`. Apply the Finding Eligibility Gate before reporting any issue.
```
