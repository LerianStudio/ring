---
name: ring:dev-goroutine-leak-testing
description: |
  Goroutine leak detection skill — detects goroutine usage in Go code, runs goleak
  to identify memory leaks, and dispatches ring:backend-engineer-golang to fix leaks
  and create regression tests.
---

# Goroutine Leak Testing

## When to use
- Code contains goroutine patterns (go func(), go methodCall())
- After implementation or during code review
- Suspected memory leak in production
- Need to verify goroutine-heavy code doesn't leak

## Skip when
- Codebase contains no goroutine usage
- Not a Go project
- Task is documentation-only, configuration-only, or non-code
- Changes do not touch any concurrent code paths

## Sequence
**Runs before:** ring:codereview
**Runs after:** ring:dev-implementation

## Related
**Complementary:** ring:backend-engineer-golang


Standards: WebFetch `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang/architecture.md` → "Goroutine Leak Detection" section.

## Step 1: Detect Goroutine Patterns

```bash
# Find goroutine patterns (excluding tests, go.mod, go.sum)
grep -rn "go func()\|go [a-zA-Z_][a-zA-Z0-9_]*\.\|go [a-zA-Z_][a-zA-Z0-9_]*(" \
  --include="*.go" \
  {target_path} \
  | grep -v "_test.go" \
  | grep -v "go.mod\|go.sum\|golang.org"
```

Goroutine patterns:
- `go func()` — anonymous goroutine
- `go methodCall(` — direct call
- `go obj.Method(` — method call
- `for ... := range ch` — channel consumer

Exclude: go.mod/go.sum, golang.org imports, comments, string literals.

## Step 2: Verify goleak Coverage

```bash
# Package-level
grep -rn "goleak.VerifyTestMain" --include="*_test.go" {target_path}

# Per-test
grep -rn "goleak.VerifyNone" --include="*_test.go" {target_path}
```

Requirements:
- Every package with goroutines → `goleak.VerifyTestMain(m)` in TestMain
- Critical goroutines → `defer goleak.VerifyNone(t)` per-test

## Step 3: Run goleak

```bash
go test -v ./... -run TestMain 2>&1 | grep -E "goleak|leak|goroutine|PASS|FAIL"
```

Leak output looks like:
```
goleak.go:89: found unexpected goroutines:
    [Goroutine 7 in state chan receive, with myapp/internal/worker.(*Worker).run on top of the stack:]
```

## Step 4: Dispatch Fix (if leaks found)

```yaml
Task:
  subagent_type: "ring:backend-engineer-golang"
  description: "Fix goroutine leak in {package_path}"
  prompt: |
    Fix goroutine leak and add goleak regression test.

    Package: {package_path}
    File: {file}:{line}
    Leak output:
    {goleak_output}

    Standards: Load architecture.md via WebFetch → Goroutine Leak Detection section.

    Requirements:
    1. Fix leak — ensure proper shutdown (context cancellation, close channels, cancel goroutines)
    2. Add goleak.VerifyTestMain(m) to TestMain in package
    3. Add specific test proving no leak occurs

    Pattern templates:
    ```go
    // Worker with proper shutdown
    type Worker struct { done chan struct{} }
    func (w *Worker) Start(ctx context.Context) {
      go func() {
        for {
          select {
          case <-ctx.Done(): return  // MUST honor context
          case <-w.done: return
          case item := <-w.queue: w.process(item)
          }
        }
      }()
    }

    // TestMain with goleak
    func TestMain(m *testing.M) {
      goleak.VerifyTestMain(m)
    }
    ```

    Known safe goroutines to ignore:
    - google.golang.org/grpc (background RPCs)
    - go.opencensus.io (exporters)
    - Use: goleak.IgnoreTopFunction("known/pkg.func")

    Output: files changed, test results (no "unexpected goroutines")
```

## Output Format

```markdown
## Goroutine Detection Summary

| Metric | Value |
|--------|-------|
| Target path | {target_path} |
| Files with goroutines | N |
| Packages analyzed | N |

## goleak Coverage
| Package | Goroutine Files | goleak Present | Status |
|---------|----------------|---------------|--------|

Coverage: X/Y packages (Z%)

## Leak Findings
| Package | File:Line | Pattern | Status |
|---------|-----------|---------|--------|

Leaks detected: N

## Actions
{PASS: goleak present, no leaks}
{or: Dispatched ring:backend-engineer-golang to fix N leaks}
```
