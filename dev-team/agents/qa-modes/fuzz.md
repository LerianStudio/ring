# QA Analyst — Fuzz Testing Mode

Extends `qa-analyst.v2.md`. Load this file when dispatched with `mode: fuzz`.

## When Fuzz Testing Applies

- Input parsing functions (JSON, Protobuf, custom formats)
- Cryptographic operations (HMAC verification, JWT parsing)
- Financial calculation functions (amount parsing, currency conversion)
- Any function that takes untrusted external input

## Fuzz Test Structure (Go)

```go
func FuzzAmountParser(f *testing.F) {
    // Seed corpus — valid representative inputs
    f.Add("100.00")
    f.Add("0.01")
    f.Add("999999999.99")
    f.Add("-100.00")

    f.Fuzz(func(t *testing.T, input string) {
        // Must not panic — only check for crashes/panics
        _, err := ParseAmount(input)
        // err is OK — panic is not
        if err != nil {
            return // valid rejection
        }
        // If no error, verify invariants
    })
}
```

## Running Fuzz Tests

```bash
# Run for 60 seconds (CI budget)
go test -fuzz=FuzzAmountParser -fuzztime=60s ./internal/...

# Re-run with saved corpus
go test -run=FuzzAmountParser ./internal/...
```

## Corpus Management

- Seed corpus: representative valid inputs + known edge cases
- Failure corpus: saved to `testdata/fuzz/FuzzFuncName/` automatically on crash
- Add discovered crashes to seed corpus after fixing

## Output Format

```markdown
## VERDICT: [PASS | FAIL]

## Fuzz Testing Summary

| Metric | Value |
|--------|-------|
| Functions Fuzzed | N |
| Corpus Seeds | N |
| Duration | 60s |
| Crashes Found | N |

## Corpus Report

| Function | Seeds | New Paths | Crashes |
|----------|-------|-----------|---------|
| FuzzAmountParser | 4 | 12 | 0 |

## Crashes Found

[If any]
### FuzzXxx crash at input: `<raw bytes>`
- **File saved:** `testdata/fuzz/FuzzXxx/crash-abc123`
- **Root cause:** [description]
- **Fix:** [recommendation]

## Next Steps
[PASS: "No crashes. Corpus saved." | FAIL: Fix crashes, extend corpus.]
```
