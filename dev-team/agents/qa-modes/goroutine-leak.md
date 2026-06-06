# QA Analyst — Goroutine Leak Detection Mode

Extends `qa-analyst.v2.md`. Load this file when dispatched with `mode: goroutine-leak`.

## When Goroutine Leak Detection Applies

- Services that spawn goroutines (workers, background processors)
- Code using channels, goroutines, or `go func()` patterns
- Long-running services where leaks would cause memory exhaustion
- After refactoring goroutine lifecycle management

## Detection with goleak

```go
import "go.uber.org/goleak"

func TestMain(m *testing.M) {
    // goleak checks for leaked goroutines after all tests complete
    goleak.VerifyTestMain(m)
}

// Per-test leak check
func TestWorker_GracefulShutdown(t *testing.T) {
    defer goleak.VerifyNone(t)

    w := NewWorker(config)
    w.Start()

    // Simulate work
    time.Sleep(100 * time.Millisecond)

    // Shutdown must clean up all goroutines
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    err := w.Shutdown(ctx)

    require.NoError(t, err)
    // goleak.VerifyNone fires here — will fail if goroutines still running
}
```

## Common Leak Patterns to Test

```go
// Pattern 1: Channel without consumer
func TestNoChannelLeak(t *testing.T) {
    defer goleak.VerifyNone(t)

    ch := make(chan int) // unbuffered
    go func() {
        ch <- 1 // will block if nobody reads → goroutine leak
    }()
    <-ch // must always consume
}

// Pattern 2: Context cancellation not propagated
func TestContextPropagation(t *testing.T) {
    defer goleak.VerifyNone(t)

    ctx, cancel := context.WithCancel(context.Background())
    go longRunningTask(ctx) // must respect context cancellation

    cancel() // signal shutdown
    time.Sleep(50 * time.Millisecond) // allow goroutine to exit
    // goleak verifies it exited
}

// Pattern 3: Worker pool cleanup
func TestWorkerPool_CleanShutdown(t *testing.T) {
    defer goleak.VerifyNone(t)

    pool := NewWorkerPool(5)
    pool.Start()

    // Submit work
    for i := 0; i < 10; i++ {
        pool.Submit(func() { time.Sleep(10 * time.Millisecond) })
    }

    pool.Shutdown() // must drain all workers
    // goleak verifies no goroutines remain
}
```

## Running Leak Detection

```bash
go test ./... -run TestWorker -v -race
# -race also catches concurrent access bugs
```

## Output Format

```markdown
## VERDICT: [PASS | FAIL]

## Goroutine Leak Detection Summary

| Metric | Value |
|--------|-------|
| Components Tested | N |
| Tests Run | N |
| Leaks Detected | N |
| Tool | goleak v1.x |

## Leak Findings

[If any]
### Leaked goroutine in: `[component]`
**Location:** `file.go:line`
**Goroutine trace:**
```
goroutine 23 [chan receive]:
main.processEvents(0xc0000b4000)
    internal/service/events.go:87 +0x45
```
**Root cause:** `processEvents` goroutine blocks on channel; no context cancellation.
**Fix:**
```go
func processEvents(ctx context.Context, ch <-chan Event) {
    for {
        select {
        case <-ctx.Done():
            return // exits goroutine cleanly
        case event := <-ch:
            handle(event)
        }
    }
}
```

## What Passed

| Component | Test | Status |
|-----------|------|--------|
| Worker.Start/Shutdown | Graceful shutdown drains goroutines | ✅ PASS |
| EventProcessor | Context cancellation propagated | ✅ PASS |

## Next Steps
[PASS: "No goroutine leaks detected." | FAIL: list leaked components with fixes.]
```
