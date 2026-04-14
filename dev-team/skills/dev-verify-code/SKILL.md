---
name: ring:dev-verify-code
description: |
  Atomic code verification for Go projects — run everything, get a MERGE_READY or NEEDS_FIX
  verdict. Phase 1 runs static analysis in parallel (lint, vet, imports, format, docs, unit
  tests). Phase 2 runs integration and E2E tests sequentially. Phase 3 presents an executive
  summary with a clear verdict. Works OUTSIDE the full dev-cycle for quick pre-merge checks.

  Adapted from alexgarzao/optimus (optimus-verify-code).

trigger: |
  - When user asks to verify, validate, or check the code before merge
  - Before creating a pull request
  - After completing implementation and wanting to confirm everything passes
  - When user wants a quick "is this ready?" check without the full 10-gate dev-cycle

skip_when: |
  - Project is not Go (no go.mod found)
  - User only wants to run a single specific command
  - Already inside a ring:dev-cycle execution (use the cycle gates instead)

NOT_skip_when: |
  - "Tests passed last time" → Code changed since then. Verify again.
  - "Only changed one file" → One file can break lint, vet, and tests.
  - "CI will catch it" → Catching locally is faster and cheaper.
  - "It's a small fix" → Small fixes still need full verification.
  - "Already reviewed" → Review is not verification. Run the checks.

related:
  complementary:
    - ring:requesting-code-review
    - ring:dev-delivery-verification
    - ring:dev-validation
  differentiation:
    - name: ring:requesting-code-review
      difference: |
        ring:requesting-code-review dispatches 7 specialist reviewer agents for deep
        analysis of code quality, business logic, and security. ring:dev-verify-code
        runs automated tooling checks (lint, vet, tests) and reports pass/fail verdicts.
    - name: ring:dev-cycle
      difference: |
        ring:dev-cycle is the full 10-gate development workflow. ring:dev-verify-code
        is a standalone, lightweight "run everything and tell me" check that lives
        outside the cycle — ideal for quick pre-merge validation.

verification:
  automated:
    - command: "test -f go.mod"
      description: Go project detected
      success_pattern: exit 0
    - command: "test -f Makefile"
      description: Makefile exists for command discovery
      success_pattern: exit 0
  manual:
    - Executive summary presented with correct verdict
    - All command outputs captured and displayed
    - Duration measured for each command individually

sequence:
  standalone: true
  note: |
    This skill operates independently of the dev-cycle gates.
    It can be invoked at any time for a quick verification pass.
---

# Verify Code

Atomic code verification for Go projects. Run everything, get a verdict.

**This skill only REPORTS — it does NOT fix anything.**

---

## Step 0: Discover Available Commands

Before running any checks, discover what is available in the project.

**MUST perform these checks:**

1. Verify `go.mod` exists — if not, STOP and report: "Not a Go project."
2. Read `Makefile` (if present) to discover available targets
3. Check tool availability: `goimports`, `gofmt` (both ship with Go toolchain; `goimports` may need install)

**Command Discovery from Makefile:**

| Default Command | Makefile Override | How to Detect |
|----------------|-------------------|---------------|
| `go vet ./...` | `make vet` | Check if `vet:` target exists |
| `goimports -l .` | `make imports` | Check if `imports:` target exists |
| `gofmt -l .` | `make fmt` or `make format` | Check if `fmt:` or `format:` target exists |
| `make lint` | `make lint` | Check if `lint:` target exists |
| `make generate-docs` | `make generate-docs` or `make docs` | Check if target exists |
| `make test-unit` | `make test-unit` or `make test` | Check if target exists |
| `make test-integration` | `make test-integration` | Check if target exists |
| `make test-e2e` | `make test-e2e` | Check if target exists |

**If a Makefile target does not exist**, fall back to the default command. If neither exists, mark that check as SKIP.

---

## Phase 1: Static Analysis + Unit Tests (parallel)

Run all Phase 1 commands simultaneously using parallel Bash tool calls. Capture stdout, stderr, exit code, and duration for each.

| # | Check | Default Command | Notes |
|---|-------|----------------|-------|
| 1 | Lint | `make lint` | golangci-lint or equivalent |
| 2 | Vet | `go vet ./...` | Suspicious constructs the compiler misses |
| 3 | Imports | `goimports -l .` | FAIL if any output (listed files need fixing) |
| 4 | Format | `gofmt -l .` | FAIL if any output (listed files need formatting) |
| 5 | Docs | `make generate-docs` | FAIL if it modifies files (docs were stale) |
| 6 | Unit Tests | `make test-unit` | Full test suite — do NOT use `-short` flag |

**Execution rules:**

- MUST run all 6 in parallel (use parallel Bash tool calls)
- Capture output of each independently
- `goimports -l .` and `gofmt -l .` FAIL if they produce any output (listed files need fixing)
- If `make generate-docs` modifies files, report which files changed — docs were stale
- If a command is unavailable (no Makefile target, tool not installed), mark as SKIP

**Phase 1 gate:**

- ALL 6 pass → proceed to Phase 2
- ANY fails → still proceed to Phase 2, but final verdict will be NEEDS_FIX

---

## Phase 2: Integration + E2E Tests (sequential)

Run sequentially. Continue even if one fails.

| # | Check | Default Command | Notes |
|---|-------|----------------|-------|
| 7 | Integration Tests | `make test-integration` | DB, external services, testcontainers |
| 8 | E2E Tests | `make test-e2e` | Full user flows |

**Execution rules:**

- MUST run `make test-integration` first
- Regardless of result, MUST run `make test-e2e` next
- Capture output, exit code, and duration for each
- If a Makefile target does not exist, mark as SKIP (not a failure)

---

## Phase 3: Executive Summary

After both phases complete, present the summary to the user.

### Summary Format

```
============================================
  VERIFICATION SUMMARY
============================================

Phase 1 — Static Analysis + Unit Tests: PASS / FAIL
Phase 2 — Integration + E2E Tests:      PASS / FAIL / SKIP
Total time: Xs

┌───┬──────────────────────┬────────┬──────────┐
│ # │ Check                │ Status │ Duration │
├───┼──────────────────────┼────────┼──────────┤
│ 1 │ lint                 │ PASS   │ 3.2s     │
│ 2 │ vet                  │ PASS   │ 1.1s     │
│ 3 │ imports              │ FAIL   │ 0.4s     │
│ 4 │ format               │ PASS   │ 0.3s     │
│ 5 │ docs                 │ PASS   │ 2.1s     │
│ 6 │ unit tests           │ PASS   │ 8.5s     │
│ 7 │ integration tests    │ PASS   │ 22.3s    │
│ 8 │ e2e tests            │ SKIP   │ -        │
└───┴──────────────────────┴────────┴──────────┘

ERRORS (first 10 lines per failure):
─────────────────────────────────────
#3 imports
  internal/handler/user.go
  internal/service/auth.go

VERDICT: NEEDS_FIX
```

### Verdict Rules

| Condition | Verdict |
|-----------|---------|
| All commands pass (or SKIP for unavailable targets) | **MERGE_READY** |
| Any command fails | **NEEDS_FIX** |
| Target not available (no Makefile target / tool not installed) | **SKIP** that check — does not count as failure |

### Error Display Rules

For each failed command:
- Show the first 10 lines of stderr (or stdout if stderr is empty)
- If `goimports -l` or `gofmt -l` failed, the output IS the list of files to fix
- If `make generate-docs` changed files, list which files were modified

---

## Stack Awareness

This skill is **Go-primary** but designed to be stack-aware:

| Stack | Support Level | Notes |
|-------|--------------|-------|
| **Go** | Full | All 8 checks supported |
| TypeScript/Node | Future | Would use eslint, prettier, jest, etc. |
| Multi-stack | Future | Detect from project files, run appropriate checks |

For non-Go projects, STOP and report: "ring:dev-verify-code currently supports Go projects only. Detected: [stack]."

---

## Rules

<forbidden>
- Fixing any code — this skill only reports
- Using `-short` flag in any test command — all tests must run completely
- Skipping commands that are slow — run everything
- Running checks sequentially when they can run in parallel (Phase 1)
- Presenting partial results — always show the full summary
- Counting SKIP as a failure in the verdict
</forbidden>

**MUST follow:**

- MUST measure duration for each command individually
- MUST always show the full summary even if everything passes
- MUST proceed to Phase 2 even if Phase 1 has failures
- MUST continue E2E even if integration fails
- MUST report, never fix

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|----------------|----------------|-----------------|
| "Tests passed last time, skip verification" | Code changed since then. Previous results are stale. | **Run all checks** |
| "Only lint failed, that's cosmetic" | Lint failures may hide real issues. Report everything. | **Report as NEEDS_FIX** |
| "Integration tests are slow, skip them" | Slow tests catch real bugs. Speed is not an excuse. | **Run all checks** |
| "CI will run these anyway" | Local verification catches issues earlier and cheaper. | **Run all checks** |
| "Let me fix this one thing first" | This skill reports only. Fixing is a separate step. | **Report, do not fix** |
| "Makefile target probably doesn't exist" | Check first, do not assume. SKIP only after verification. | **Check Makefile, then decide** |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|--------------|
| "Just run the tests, skip lint" | "ring:dev-verify-code runs all checks. For a single command, run it directly." |
| "It's fine, just mark it as ready" | "MUST run verification to determine verdict. Cannot mark ready without evidence." |
| "Skip integration tests, they're slow" | "All checks run regardless of duration. SKIP only applies to unavailable targets." |
| "Fix the import issues while you're at it" | "This skill only reports. Use the appropriate tool or agent to fix issues." |
