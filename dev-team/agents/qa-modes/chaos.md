# QA Analyst — Chaos Testing Mode

Extends `qa-analyst.v2.md`. Load this file when dispatched with `mode: chaos`.

## When Chaos Testing Applies

- Services with external dependencies (DB, cache, message queue, HTTP)
- Validating graceful degradation and circuit breaker behavior
- Testing retry logic and timeout handling
- Verifying system remains consistent during partial failures

## Chaos Test Structure

```go
// Simulate dependency failure with testcontainers
func TestAccountService_DatabaseDown(t *testing.T) {
    ctx := context.Background()
    pgContainer := startPostgres(t)

    repo := NewPostgresRepository(connectionString(pgContainer))
    svc := NewAccountService(repo)

    // Verify baseline works
    _, err := svc.Create(ctx, CreateRequest{Name: "Test"})
    require.NoError(t, err)

    // Inject failure — pause container
    err = pgContainer.Stop(ctx, nil)
    require.NoError(t, err)

    // Service should return error gracefully (not panic, not hang)
    done := make(chan error, 1)
    go func() {
        _, err := svc.Create(ctx, CreateRequest{Name: "DuringOutage"})
        done <- err
    }()

    select {
    case err := <-done:
        require.Error(t, err)
        // Verify it's a wrapped DB error, not a panic or timeout
        assert.Contains(t, err.Error(), "connection")
    case <-time.After(5 * time.Second):
        t.Fatal("service hung during DB outage — timeout violated")
    }
}
```

## Failure Scenarios to Test

| Scenario | What to Verify |
|----------|---------------|
| Database connection lost | Returns error with DB code, no panic, no hang |
| Cache unavailable | Degrades gracefully, returns error or stale data per policy |
| RabbitMQ connection dropped | Messages not lost (outbox pattern), reconnects cleanly |
| Downstream service 500 | Circuit breaker opens after threshold |
| Downstream service timeout | Context deadline propagated, not hung |
| Network partition (partial) | Correct partial failure handling |

## Circuit Breaker Verification

```go
func TestCircuitBreaker_OpensAfterThreshold(t *testing.T) {
    cb := circuitbreaker.New(circuitbreaker.Config{
        Threshold:   5,
        Timeout:     1 * time.Second,
    })

    // Inject 5 failures
    for i := 0; i < 5; i++ {
        cb.Execute(func() error { return errors.New("failure") })
    }

    // Circuit should be open — fast-fail without calling downstream
    start := time.Now()
    err := cb.Execute(func() error {
        time.Sleep(100 * time.Millisecond) // should not reach here
        return nil
    })
    elapsed := time.Since(start)

    require.Error(t, err)
    assert.Contains(t, err.Error(), "circuit open")
    assert.Less(t, elapsed, 10*time.Millisecond, "circuit breaker did not fast-fail")
}
```

## Output Format

```markdown
## VERDICT: [PASS | FAIL]

## Chaos Testing Summary

| Metric | Value |
|--------|-------|
| Failure Scenarios | N |
| Services Tested | [list] |
| Duration | Xs |

## Failure Scenarios

| Scenario | Behavior Expected | Result |
|----------|-----------------|--------|
| DB connection lost | Wrapped error returned in <5s | ✅ PASS |
| Cache unavailable | Graceful degradation to direct DB | ✅ PASS |
| Circuit breaker | Opens after 5 failures, fast-fails | ✅ PASS |

## Identified Risks

[If any scenarios fail]
### Scenario: [name]
- **Expected:** [behavior]
- **Actual:** [what happened]
- **Risk:** [production impact]
- **Fix:** [recommendation]

## Next Steps
[PASS: "System handles dependency failures gracefully." | FAIL: list failure scenarios with fixes.]
```
