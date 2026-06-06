# QA Analyst — Property-Based Testing Mode

Extends `qa-analyst.v2.md`. Load this file when dispatched with `mode: property`.

## When Property Testing Applies

- Domain invariants (double-entry balance, idempotency, reversibility)
- Data transformations (encoding/decoding round-trips)
- Financial calculations (amount arithmetic, currency conversion)
- State machines (valid transitions only)

## Property Test Structure (Go with rapid)

```go
import "pgregory.net/rapid"

func TestTransfer_BalanceConservation(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        // Generate arbitrary valid inputs
        amount := rapid.Float64Range(0.01, 1000000.00).Draw(t, "amount")
        fromBalance := rapid.Float64Range(amount, amount*2).Draw(t, "fromBalance")

        from := &Account{Balance: fromBalance}
        to := &Account{Balance: 0}

        totalBefore := from.Balance + to.Balance
        err := Transfer(from, to, amount)
        require.NoError(t, err)
        totalAfter := from.Balance + to.Balance

        // Invariant: total balance must be conserved
        assert.InDelta(t, totalBefore, totalAfter, 0.001,
            "balance conservation violated: before=%f, after=%f", totalBefore, totalAfter)
    })
}

func TestAmountParsing_RoundTrip(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        original := rapid.Float64Range(-999999, 999999).Draw(t, "amount")
        str := FormatAmount(original)
        parsed, err := ParseAmount(str)
        require.NoError(t, err)
        assert.InDelta(t, original, parsed, 0.001)
    })
}
```

## Properties to Define

1. **Invariants:** Things that must always be true (balance conservation, unique IDs)
2. **Round-trips:** `parse(format(x)) == x`
3. **Idempotency:** `f(f(x)) == f(x)` for idempotent operations
4. **Monotonicity:** Value only increases/decreases as expected
5. **Commutativity:** `f(a,b) == f(b,a)` where applicable

## Running Property Tests

```bash
# Standard test run (100 iterations default)
go test ./... -run TestTransfer_BalanceConservation

# More iterations for critical paths
RAPID_CHECKS=1000 go test ./... -run TestTransfer
```

## Output Format

```markdown
## VERDICT: [PASS | FAIL]

## Property Testing Summary

| Metric | Value |
|--------|-------|
| Properties Tested | N |
| Iterations per Property | 100 (default) |
| Counterexamples Found | N |

## Properties Report

| Property | Invariant | Iterations | Status |
|----------|-----------|-----------|--------|
| Balance conservation | totalBefore == totalAfter | 100 | ✅ PASS |
| Amount round-trip | parse(format(x)) == x | 100 | ✅ PASS |

## Counterexamples Found

[If any]
### Property: [name]
- **Counterexample:** `input = <value>`
- **Invariant violated:** [description]
- **Root cause:** [analysis]
- **Fix:** [recommendation]

## Next Steps
[PASS: "All properties hold." | FAIL: Fix invariant violations.]
```
