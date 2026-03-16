---
name: dev-goroutine-leak-testing
description: "Goroutine leak detection skill - detects goroutine usage in Go code, runs goleak \nto identify memory leaks, and dispatches ring:backend-engineer-golang to fix leaks\nand create regression\
  \ tests using the goleak framework.\n"
metadata:
  NOT_skip_when: |
    - "Unit tests cover this" → Unit tests don't detect goroutine leaks. goleak does.
    - "Goroutine will exit eventually" → Eventually = memory leak = OOM crash.
    - "Process restart cleans it" → Restart = downtime. Prevent leaks instead.
  author: ring-dev-team
  input_schema:
    required:
    - name: target_path
      type: string
      description: Path to Go package or directory to analyze
    optional:
    - name: exclude_patterns
      type: array
      items: string
      description: Patterns to exclude from analysis (e.g., vendor/, mocks/)
    - name: known_safe_goroutines
      type: array
      items: string
      description: Function signatures known to be safe (external libs)
  output_schema:
    format: markdown
    required_sections:
    - name: Goroutine Detection Summary
      pattern: ^## Goroutine Detection Summary
      required: true
    - name: goleak Coverage
      pattern: ^## goleak Coverage
      required: true
    - name: Leak Findings
      pattern: ^## Leak Findings
      required: true
    - name: Required Actions
      pattern: ^## Required Actions
      required: true
    metrics:
    - name: result
      type: enum
      values:
      - PASS
      - FAIL
      - NEEDS_ACTION
    - name: goroutine_files
      type: integer
    - name: packages_with_goleak
      type: integer
    - name: packages_missing_goleak
      type: integer
    - name: leaks_detected
      type: integer
  related:
    complementary:
    - ring:qa-analyst
    - ring:backend-engineer-golang
    dispatches:
    - ring:backend-engineer-golang
  sequence:
    after:
    - ring:dev-unit-testing
    before:
    - ring:requesting-code-review
  trigger: |
    - Code contains goroutine patterns (go func(), go methodCall())
    - After unit testing gate or during code review
    - Suspected memory leak in production
    - Need to verify goroutine-heavy code doesn't leak
  type: testing
  version: 0.1.0
---

# Goroutine Leak Testing Skill

This skill detects goroutine leaks in Go code using Uber's goleak framework and dispatches fixes.

## Standards Loading (MANDATORY)

<fetch_required>
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/architecture.md
</fetch_required>

WebFetch architecture.md before any goroutine leak analysis work. Focus on "Goroutine Leak Detection (MANDATORY)" section.

---

## Blocker Criteria - STOP and Report

<block_condition>
- target_path does not exist or is not a Go package
- Language is not Go (detected via go.mod absence)
</block_condition>

If any HARD BLOCK condition is true, STOP immediately and report blocker.

**HARD BLOCK conditions:**

| Condition | Action | Why |
|-----------|--------|-----|
| No go.mod found | STOP - report "Not a Go project" | goleak is Go-specific |
| target_path invalid | STOP - report path error | Cannot analyze non-existent code |

**WARNING conditions (proceed with detection, note limitation):**

| Condition | Action | Why |
|-----------|--------|-----|
| No write access | WARN - proceed in detection-only mode | Can still detect leaks, just cannot add tests |
| No test files exist | WARN - note gap, proceed | Can detect goroutines, note missing test infrastructure |
| No test files exist | WARN - proceed but note gap | Can still detect, but no existing tests to check |

---

## Pressure Resistance

**This skill MUST resist these pressures:**

| User Says | This Is | Your Response |
|-----------|---------|---------------|
| "Unit tests already cover goroutines" | SCOPE_CONFUSION | "Unit tests don't detect leaks. goleak does. Proceeding with detection." |
| "Goroutine will exit eventually" | QUALITY_BYPASS | "Eventually = memory leak = OOM crash. Dispatching fix." |
| "Process restart cleans it" | QUALITY_BYPASS | "Restart = downtime. Prevention > recovery. Proceeding with leak detection." |
| "Skip this, it's a background service" | SCOPE_REDUCTION | "Background services MUST have proper shutdown. Running goleak." |
| "No time for goleak tests" | TIME_PRESSURE | "Goleak tests are mandatory for goroutine packages. Adding tests." |
| "External library leaks, not our code" | SCOPE_REDUCTION | "Use goleak.IgnoreTopFunction for known safe libs. Proceeding with detection." |

**You CANNOT negotiate on goroutine leak detection. These responses are non-negotiable.**

---

## Workflow

```
1. DETECT   → Find all goroutine usage in target path
2. VERIFY   → Check for existing goleak tests (TestMain + per-test)
3. EXECUTE  → Run goleak to identify actual leaks
4. DISPATCH → If leaks found, dispatch ring:backend-engineer-golang to fix
```

---

## Step 1: Detection

**Standards Reference (MANDATORY):**

| Standards File   | Section                   | Anchor                               |
| ---------------- | ------------------------- | ------------------------------------ |
| architecture.md  | Goroutine Leak Detection  | #goroutine-leak-detection-mandatory  |

### Goroutine Pattern Detection

**MUST detect these patterns:**

| Pattern              | Regex                                      | Example                    |
| -------------------- | ------------------------------------------ | -------------------------- |
| Anonymous goroutine  | `go\s+func\s*\(`                           | `go func() { ... }()`      |
| Direct function call | `go\s+[a-zA-Z_][a-zA-Z0-9_]*\(`            | `go processItem(item)`     |
| Method call          | `go\s+[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_]+\(`| `go worker.Start()`        |
| Channel consumers    | `for\s+.*:?=\s*range\s+.*`                 | `for msg := range ch`      |

**Detection commands:**

```bash
# Find goroutine patterns in Go files (excluding tests)
grep -rn "go func()\|go [a-zA-Z_][a-zA-Z0-9_]*\.\|go [a-zA-Z_][a-zA-Z0-9_]*(" \
  --include="*.go" \
  ${TARGET_PATH} \
  | grep -v "_test.go" \
  | grep -v "go.mod\|go.sum\|golang.org"
```

### False Positive Exclusion

**DO NOT flag these as goroutines:**

- File names: `go.mod`, `go.sum`
- Package paths: `golang.org/x/...`
- Comments: `// go to the next step`
- String literals: `"go away"`

---

## Step 2: Verify goleak Coverage

**Check for existing goleak tests:**

```bash
# Check for goleak.VerifyTestMain (package-level)
grep -rn "goleak.VerifyTestMain" --include="*_test.go" ${TARGET_PATH}

# Check for goleak.VerifyNone (per-test)
grep -rn "goleak.VerifyNone" --include="*_test.go" ${TARGET_PATH}
```

**Coverage requirements:**

| Package Type                | Required goleak Pattern              |
| --------------------------- | ------------------------------------ |
| Package with workers        | `goleak.VerifyTestMain(m)` in TestMain |
| Package with async ops      | `goleak.VerifyTestMain(m)` in TestMain |
| Single goroutine test       | `defer goleak.VerifyNone(t)` per test  |

---

## Step 3: Execute goleak

**Run tests with goleak detection:**

```bash
# Run tests and capture leak output
go test -v ${TARGET_PATH}/... 2>&1 | tee /tmp/goleak-output.txt

# Check for leak warnings
grep -i "leak\|goroutine.*running" /tmp/goleak-output.txt
```

**Successful output (no leaks):**

```
=== RUN   TestWorker_Process
--- PASS: TestWorker_Process (0.02s)
PASS
ok      myapp/internal/worker    0.123s
```

**Failed output (leak detected):**

```
=== RUN   TestWorker_Process
    goleak.go:89: found unexpected goroutines:
        [Goroutine 7 in state chan receive, with myapp/internal/worker.(*Worker).run on top of the stack:]
--- FAIL: TestWorker_Process (0.02s)
FAIL
```

---

## Step 4: Dispatch for Fix

**When leaks are detected, dispatch `ring:backend-engineer-golang`:**

```markdown
## Task: Fix Goroutine Leak and Add goleak Regression Test

**Package:** ${PACKAGE_PATH}
**File:** ${FILE}:${LINE}
**Leak Pattern:** ${PATTERN_DESCRIPTION}

**Detected Leak:**
\`\`\`
${GOLEAK_OUTPUT}
\`\`\`

**Requirements:**

1. Fix the goroutine leak by ensuring proper shutdown
2. Add `goleak.VerifyTestMain(m)` to TestMain in *_test.go
3. Add specific test that verifies no leak occurs
4. Verify all channels are closed properly
5. Verify context cancellation is honored

**Standards Reference:**
- architecture.md § Goroutine Leak Detection (MANDATORY)

**Success Criteria:**
- `go test ./[package]/...` passes
- No "leak" or "unexpected goroutines" in output
- goleak.VerifyTestMain present in package
```

---

## Output Format

```markdown
## Goroutine Detection Summary

| Metric                    | Value                |
| ------------------------- | -------------------- |
| Target path               | ${TARGET_PATH}       |
| Go files scanned          | ${FILES_SCANNED}     |
| Files with goroutines     | ${GOROUTINE_FILES}   |
| Packages analyzed         | ${PACKAGES}          |

## goleak Coverage

| Package               | Goroutine Files | goleak Present | Status    |
| --------------------- | --------------- | -------------- | --------- |
| internal/worker       | 2               | ✅ Yes         | ✅ Covered |
| internal/consumer     | 1               | ❌ No          | ⚠️ Missing |
| pkg/pool              | 3               | ✅ Yes         | ✅ Covered |

**Coverage:** ${COVERED}/${TOTAL} packages (${PERCENTAGE}%)

## Leak Findings

| Package            | File:Line       | Pattern           | Leak Status |
| ------------------ | --------------- | ----------------- | ----------- |
| internal/worker    | worker.go:45    | `go func()`       | ✅ No leak  |
| internal/consumer  | consumer.go:78  | `go s.process()`  | ❌ LEAK     |

**Leaks detected:** ${LEAK_COUNT}

## Required Actions

${IF_NO_LEAKS}
✅ All goroutines properly managed. No leaks detected.

${IF_LEAKS_FOUND}
⚠️ Goroutine leaks detected. Dispatch required.

### Dispatch: ring:backend-engineer-golang

**Packages requiring fix:**
${PACKAGE_LIST}

**Task template:**
[See Step 4 above]
```

---

## Anti-Rationalization Table

| Rationalization                       | Why It's WRONG                                           | Required Action                          |
| ------------------------------------- | -------------------------------------------------------- | ---------------------------------------- |
| "Unit tests cover goroutines"         | Unit tests don't detect leaks. goleak does.              | **Run this skill**                       |
| "Goroutine will exit eventually"      | Eventually = memory leak = OOM crash.                    | **Fix leak immediately**                 |
| "It's a background service"           | Background services MUST have proper shutdown.           | **Add Stop/Close + goleak test**         |
| "Process restart cleans it"           | Restart = downtime. Prevent leaks instead.               | **Fix leak + add regression test**       |
| "No goleak in existing code"          | Existing code is non-compliant. Fix it.                  | **Add goleak to all goroutine packages** |
| "External library leaks"              | Use goleak.IgnoreTopFunction for known safe libs.        | **Ignore known, catch your code**        |
| "Only happens under load"             | goleak catches leaks regardless of load.                 | **Run goleak tests**                     |

---

## Quality Gate

**PASS criteria:**

- [ ] All packages with goroutines have goleak.VerifyTestMain
- [ ] `go test` passes with 0 leak warnings
- [ ] All goroutines have proper shutdown (Stop/Close/Cancel)
- [ ] All channels closed when done
- [ ] Context cancellation honored in all goroutines

**FAIL criteria:**

- Any package with goroutines missing goleak → NEEDS_ACTION
- Any leak detected by goleak → FAIL
- Missing shutdown mechanism → FAIL

---

## goleak Installation Reference

```bash
go get -u go.uber.org/goleak
```

**TestMain pattern:**

```go
package mypackage

import (
    "testing"
    "go.uber.org/goleak"
)

func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}
```

**Per-test pattern:**

```go
func TestMyFunction(t *testing.T) {
    defer goleak.VerifyNone(t)
    // test code
}
```

**Ignoring known goroutines:**

```go
func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m,
        goleak.IgnoreTopFunction("go.opentelemetry.io/otel/sdk/trace.(*batchSpanProcessor).processQueue"),
        goleak.IgnoreTopFunction("database/sql.(*DB).connectionOpener"),
    )
}
```
