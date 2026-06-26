---
name: ring:implementing-tasks
description: "Implementing a single planned task (Task N.M.T) end-to-end: selects the right backend agent by language and service type, drives one TDD RED->GREEN turn, then verifies coverage, lint, license headers, runtime, and delivery before handoff. Runs as Gate 0 before ring:reviewing-code. Use to drive ONE task inside an already-running cycle. Skip when asked to implement a whole plan.md or multiple tasks (use ring:running-dev-cycle)."
---

# Code Implementation (Gate 0)

## When to use
- Gate 0 of development cycle
- Tasks loaded at initialization
- Ready to write code

## Skip when
- Not inside a development cycle (ring:running-dev-cycle or ring:planning-backend-refactor)
- Task is documentation-only, configuration-only, or non-code
- Implementation already completed for the current gate

## Sequence
**Runs before:** ring:reviewing-code

## Related
**Complementary:** ring:running-dev-cycle, ring:test-driven-development, ring:reviewing-code


You orchestrate. Agents implement. Select the agent, prepare the prompt, track state, validate outputs.

## Step 1: Validate Input

The unit of work is a single task (Task N.M.T, e.g. Task 1.1.1) from the phased plan.
Its requirements arrive inline from the orchestrator, which reads the task block under
its epic in plan.md: Context, Implementation vision, Files, Verification, and Done when.

Required: `unit_id` (the task's `Task N.M.T` id), `requirements` (the task block), `language` (go|typescript|python), `service_type` (api|worker|batch|cli|frontend|bff).
Optional: `technical_design`, `existing_patterns`, `project_rules_path` (default: `docs/PROJECT_RULES.md`).

STOP if any required input is missing.

## Step 2: Validate Prerequisites

Check `PROJECT_RULES.md` exists at `project_rules_path` → STOP if not found.

**Agent selection:**

| Language | Service Type | Agent |
|----------|--------------|-------|
| go | api, worker, batch, cli | ring:backend-go |
| typescript | api, worker | ring:backend-ts |
| typescript | frontend, bff | ring:bff-ts |

## Step 3: Gate 0 — TDD (RED → GREEN)

Dispatch the selected agent ONCE. The agent writes the failing test, captures the RED failure output as evidence, then implements to GREEN — in one turn.

```yaml
Task:
  subagent_type: "{selected_agent}"
  description: "Gate 0 TDD (RED→GREEN) for {unit_id}"
  prompt: |
    ## TDD: write a failing test, then make it pass

    unit_id: {unit_id}
    requirements: {requirements}
    language: {language}
    service_type: {service_type}

    Standards: load via state.cached_standards or WebFetch Ring standards for the language.
    Project rules: {project_rules_path}

    ## Frontend TDD policy (React/Next.js only)
    Visual-only components (layout, styling, animations): RED not required — report
    "Visual-only → RED skipped; visual checks apply in the frontend flow."
    Behavioral components (hooks, validation, state, conditional rendering, API): RED required.

    ## Multi-Tenant (Go only)
    Implement DUAL-MODE from the start. Use resolvers for all resources
    (tmcore.GetPGContext, tmcore.GetMBContext, etc.) — they work transparently
    in single-tenant and multi-tenant mode. Load multi-tenant.md for patterns.

    ## Your task
    1. Write a test capturing expected behavior; run it; it MUST fail (no implementation yet); capture the failure output.
    2. Implement the minimum code to make the test pass; run tests — all pass.
    3. Enforce coverage threshold (Ring minimum 85%, PROJECT_RULES may raise it).
    4. Create/update docker-compose and .env.example when the service needs local dependencies.
    5. Verify local runtime starts cleanly for the changed service path; verify basic health/observability for the changed code.
    6. Write delivery verification results.
    7. Commit: "{feat|fix|test|chore}(scope): description".

    ## Required output
    - RED: test file path + the actual failure output (MANDATORY — must contain FAIL)
    - GREEN: implementation files + test pass output
    - Coverage report (must meet threshold)
    - Local runtime: docker-compose/.env.example status or explicit "not required"
    - Basic health/observability verification
    - Delivery verification: requirements delivered, dead-code check, files changed
    - Git commit SHA
```

Validate output: the RED failure output must contain "FAIL" (evidence the test failed before implementation existed), and the GREEN output must show PASS with coverage ≥ threshold. Re-dispatch if RED evidence is missing or tests do not pass.

## Step 4: Gate 0 Exit — Delivery Verification

After TDD-GREEN passes, verify delivery:

**Automated checks (run on all files changed by Gate 0):**

```bash
# A. File size (>1500 = FAIL, >1000 = PARTIAL unless cohesion justified)
find . -name "*.go" ! -name "*_test.go" ! -path "*/generated/*" \
  -exec wc -l {} + | awk '$1 > 1000'

# B. License headers
for f in $files_changed; do
  head -10 "$f" | grep -qiE 'copyright|licensed|spdx|license' || echo "MISSING: $f"
done

# C. Lint (go: golangci-lint; ts: eslint)
golangci-lint run ./... || echo "LINT FAILED"

# D. Coverage (Ring minimum 85%; PROJECT_RULES.md can raise)
# Go example: go test ./... -cover
# TypeScript example: npm test -- --coverage

# E. Local runtime / docker-compose
# If docker-compose.yml is required, verify it can config and start the changed service dependencies.

# F. Migration safety (if SQL migrations changed)
# Check for blocking ops: ADD COLUMN NOT NULL without DEFAULT, DROP COLUMN,
# CREATE INDEX without CONCURRENTLY, ALTER COLUMN TYPE, TRUNCATE
```

**Verdict:**
- PASS: all requirements delivered, 0 dead code, all checks pass
- PARTIAL: some requirements delivered → list gaps, return to Gate 0
- FAIL: critical requirements missing → return to Gate 0 with explicit instructions

## Step 5: Commit

When Step 4 verdict is PASS, load and call `ring:committing-changes` to create the signed atomic commit for this task before returning control to the dev-cycle orchestrator.

```yaml
Skill("ring:committing-changes")
```

MUST only run on PASS. On PARTIAL or FAIL, return to Gate 0 — do NOT commit.

## Output Format

```markdown
## Implementation Summary
- unit_id, agent used, TDD phase results

## TDD Results
- RED: test file path + failure output
- GREEN: test pass output + coverage

## Files Changed
- List of created/modified files

## Delivery Verification
- Each requirement: DELIVERED or NOT DELIVERED
- Automated checks: PASS/FAIL per check

## Handoff to Next Gate
- files_changed list for Gate 8 review
- ready_for_review: YES or NO
- Verdict: PASS | PARTIAL | FAIL
```
