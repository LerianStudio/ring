---
name: ring:dev-verify-code
description: |
  Atomic code verification for Go projects — run everything, get a MERGE_READY or NEEDS_FIX
  verdict. Phase 1 runs static analysis in parallel (lint, vet, imports, format, docs, unit
  tests). Phase 2 runs integration and E2E tests sequentially. Phase 3 presents a summary.
  Works OUTSIDE the full dev-cycle for quick pre-merge checks.
---

# Code Verification

## When to use
- Before creating a pull request
- After completing implementation and wanting to confirm everything passes
- When user wants a quick "is this ready?" check

## Skip when
- Project is not Go (no go.mod found)
- User only wants to run a single specific command
- Already inside a ring:dev-cycle execution (use the cycle gates instead)

## Related
**Complementary:** ring:dev-cycle, ring:codereview


Run everything. Get a verdict. **This skill only REPORTS — it does NOT fix anything.**

## Step 0: Discover Commands

1. Verify `go.mod` exists → if not, STOP: "Not a Go project."
2. Read `Makefile` to discover available targets
3. Check tool availability: `goimports`, `gofmt`

**Command resolution:**

| Check | Default | Makefile Override |
|-------|---------|------------------|
| Lint | `golangci-lint run ./...` | `make lint` if target exists |
| Vet | `go vet ./...` | `make vet` |
| Imports | `goimports -l .` | `make imports` |
| Format | `gofmt -l .` | `make fmt` or `make format` |
| Docs | `make generate-docs` | `make docs` |
| Unit Tests | `go test ./...` | `make test-unit` or `make test` |
| Integration Tests | `make test-integration` | — |
| E2E Tests | `make test-e2e` | — |

If Makefile target doesn't exist: use default command. If neither exists: SKIP (not a failure).

## Phase 1: Static Analysis + Unit Tests (parallel)

Run all 6 in **parallel**. Capture stdout, stderr, exit code, duration for each.

| # | Check | Fail Condition |
|---|-------|---------------|
| 1 | Lint | Non-zero exit |
| 2 | Vet | Non-zero exit |
| 3 | Imports | Any output (files listed need fixing) |
| 4 | Format | Any output (files listed need formatting) |
| 5 | Docs | Files modified (docs were stale) |
| 6 | Unit Tests | Non-zero exit |

Phase 1 gate: ALL pass → proceed to Phase 2. ANY fails → still run Phase 2, but verdict will be NEEDS_FIX.

## Phase 2: Integration + E2E Tests (sequential)

Run sequentially. Continue even if first fails.

| # | Check | Notes |
|---|-------|-------|
| 7 | Integration Tests | DB, external services, testcontainers |
| 8 | E2E Tests | Full user flows |

If target doesn't exist → SKIP (not a failure).

## Phase 3: Executive Summary

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
#3 imports:
  internal/handler/user.go
  internal/service/auth.go

VERDICT: NEEDS_FIX
```

## Verdict Rules

| Condition | Verdict |
|-----------|---------|
| All commands PASS (or SKIP for unavailable) | **MERGE_READY** |
| Any command FAIL | **NEEDS_FIX** |
| Target unavailable | **SKIP** — does not count as failure |

## Error Display

For each failed command: show first 10 lines of stderr (or stdout if stderr empty).
- `goimports -l` / `gofmt -l` output = list of files to fix
- `make generate-docs` changed files = list modified files
