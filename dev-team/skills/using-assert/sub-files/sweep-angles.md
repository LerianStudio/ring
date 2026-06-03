## Explorer Angle Specifications

MANDATORY: All 6 angles run on every sweep. The catalog below is the source of truth
for what each explorer looks for. MUST NOT edit angle specs at dispatch time — copy
verbatim into the explorer prompt.

---

#### Angle 1: `panic()` / `log.Fatal` / `log.Panic` / `Must*` in non-test code

**Severity:** CRITICAL

**DIY Patterns to Detect:**
- `panic(` in any `.go` file that is not `_test.go`
- `log.Fatal(` / `log.Fatalf(` / `log.Fatalln(` in non-test code
- `log.Panic(` / `log.Panicf(` / `log.Panicln(` in non-test code
- Custom `Must*` helper calls (e.g., `MustParseDecimal`, `MustConnect`) in non-test code
- **Exception (allowed):** `regexp.MustCompile` with a compile-time **string literal constant** is the only sanctioned exception to the zero-panic policy. If the argument is a variable or computed at runtime, it is a violation.

**lib-observability/assert Replacement:**
- `asserter.That(ctx, condition, "message", keysAndValues...)` — returns error, observability trident fires
- `asserter.NotNil(ctx, value, "message", keysAndValues...)` — for nil-receiver guards
- `asserter.NoError(ctx, err, "message", keysAndValues...)` — when wrapping an existing error
- `asserter.Never(ctx, "message", keysAndValues...)` — for unreachable branches

**Migration Complexity:** moderate (callers must be updated to accept returned error)

**Example Transformation:**

```go
// BEFORE:
func postEntry(amount decimal.Decimal) {
    if amount.IsNegative() {
        panic("amount must be positive")
    }
    if amount.IsZero() {
        log.Fatal("amount cannot be zero")
    }
    // ...
}

// AFTER:
func postEntry(ctx context.Context, a *assert.Asserter, amount decimal.Decimal) error {
    if err := a.That(ctx, assert.PositiveDecimal(amount),
        "amount must be positive",
        "amount", amount.String()); err != nil {
        return err
    }
    // ...
    return nil
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for zero-panic policy violations. MUST find every `panic(`,
> `log.Fatal(`, `log.Fatalf(`, `log.Fatalln(`, `log.Panic(`, `log.Panicf(`, `log.Panicln(`,
> and `.Must*(` helper call in any `.go` file that is NOT a `_test.go` file. The only
> allowed exception is `regexp.MustCompile(` whose argument is a compile-time string
> literal — if the argument is a variable, that is a violation. For each finding record
> file:line, the exact call, and whether the surrounding context is bootstrap/init,
> runtime, or hot-path. Severity CRITICAL — these are production crashes waiting to happen
> and each one is a zero-panic policy violation. Write `/tmp/assert-sweep-1-panic.json`.

---

#### Angle 2: Defensive nil/empty checks without metric emission

**Severity:** HIGH

**DIY Patterns to Detect:**
- `if x == nil { return err }` / `if x == nil { return fmt.Errorf(...) }` in code paths where the nil represents an **invariant violation** (internal state that should never be nil), not an expected input-validation failure
- `if s == "" { return err }` on fields that are invariants (tenant ID on authenticated request, transaction ID on internal call), not user input
- `if err != nil { return err }` at invariant boundaries (internal service calls where error "should never happen" but propagates silently with no observability)
- Any pattern that silently propagates an invariant failure without emitting metric / log / span event

**Important distinction:** NOT every `if err != nil { return err }` is wrong. Expected failure paths — user input validation, external I/O failure, context cancellation — are normal error returns and do NOT need asserter coverage. This angle targets **invariant** paths: internal state that the caller/callee contract guarantees will be valid, where a violation is a bug, not a user error.

**lib-observability/assert Replacement:**
- `asserter.NotNil(ctx, x, "x must not be nil at this boundary", keys...)` — for nil-at-invariant
- `asserter.NotEmpty(ctx, s, "tenant ID required at this boundary")` — for empty-string invariants
- `asserter.NoError(ctx, err, "internal call must not fail", keys...)` — for "should never error" paths

**Migration Complexity:** moderate — requires deciding which checks are invariants vs expected failures

**Example Transformation:**

```go
// BEFORE — invariant check silently returns error, no observability:
func postToLedger(ctx context.Context, txnID string, account *Account) error {
    if account == nil {
        return errors.New("account is nil") // silent — never surfaces in metrics
    }
    if txnID == "" {
        return errors.New("transaction ID empty") // silent
    }
    // ...
}

// AFTER — asserter fires the observability trident on invariant violation:
func postToLedger(ctx context.Context, a *assert.Asserter, txnID string, account *Account) error {
    if err := a.NotNil(ctx, account, "account required at ledger boundary",
        "transaction_id", txnID); err != nil {
        return err
    }
    if err := a.NotEmpty(ctx, txnID, "transaction ID required at ledger boundary"); err != nil {
        return err
    }
    // ...
    return nil
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for defensive invariant checks that return silently without
> observability. Search for `if x == nil { return`, `if s == "" { return`, and
> `if err != nil { return err }` patterns. For each finding, assess whether the check is
> on an **invariant path** (internal state that should never be invalid — e.g., tenant
> ID on an authenticated request, non-nil DB connection after successful init, non-empty
> transaction ID on internal call) or an **expected-failure path** (user input
> validation, external I/O, context cancellation). Flag only invariant-path checks —
> expected failures are normal error returns and do NOT need asserter coverage. For each
> flagged finding record file:line, the invariant being checked, and why it is an
> invariant (not expected failure). Severity HIGH — silent invariant violations corrupt
> state and never appear in dashboards. Write `/tmp/assert-sweep-2-defensive.json`.

---

#### Angle 3: Hand-rolled domain predicates duplicating `assert.*`

**Severity:** HIGH

**DIY Patterns to Detect:**
- Functions named `isPositive`, `isValidAmount`, `debitsEqualCredits`, `validateTransactionStatus`, `isValidUUID`, `isPortValid`, `isValidSSLMode`, `inRange`, and their typo/case variants
- Inline equivalents that duplicate canonical predicates: `if amount.IsPositive() && !amount.IsZero()` (equivalent to `assert.PositiveDecimal`), `if d.Cmp(c) == 0 && !d.IsZero()` (equivalent to `assert.DebitsEqualCredits` + `NonZeroTotals`)
- Custom transaction-status switch statements exhaustively enumerating CREATED/APPROVED/PENDING/CANCELED/NOTED (duplicates `assert.ValidTransactionStatus`)
- Hand-rolled status-transition lookup tables (duplicates `assert.TransactionCanTransitionTo`)

**lib-observability/assert Replacement:** Delete the DIY predicate, compose asserter with the canonical predicate:

| DIY Predicate                  | Canonical Replacement                          |
| ------------------------------ | ---------------------------------------------- |
| `isPositive(n int64)`          | `assert.Positive(n)`                           |
| `isNonNegative(n int64)`       | `assert.NonNegative(n)`                        |
| `isInRange(n, min, max)`       | `assert.InRange(n, minVal, maxVal)`            |
| `isPositiveAmount(d decimal)`  | `assert.PositiveDecimal(d)`                    |
| `isNonNegativeAmount(d)`       | `assert.NonNegativeDecimal(d)`                 |
| `isValidAmount(d)`             | `assert.ValidAmount(d)`                        |
| `isValidScale(s int)`          | `assert.ValidScale(s)`                         |
| `debitsEqualCredits(d, c)`     | `assert.DebitsEqualCredits(d, c)`              |
| `isValidTxStatus(s)`           | `assert.ValidTransactionStatus(s)`             |
| `canTransitionTo(from, to)`    | `assert.TransactionCanTransitionTo(from, to)`  |
| `isValidUUID(s)`               | `assert.ValidUUID(s)`                          |
| `isValidPort(p)`               | `assert.ValidPort(p)`                          |
| `isValidSSLMode(m)`            | `assert.ValidSSLMode(m)`                       |

**Migration Complexity:** trivial (delete + swap)

**Example Transformation:**

```go
// BEFORE — hand-rolled predicate reinvents the canonical one:
func isValidTransactionStatus(s string) bool {
    switch s {
    case "CREATED", "APPROVED", "PENDING", "CANCELED", "NOTED":
        return true
    }
    return false
}

func process(ctx context.Context, txnID, status string) error {
    if !isValidTransactionStatus(status) {
        return fmt.Errorf("invalid status: %s", status)
    }
    // ...
}

// AFTER — canonical predicate + asserter:
func process(ctx context.Context, a *assert.Asserter, txnID, status string) error {
    if err := a.That(ctx, assert.ValidTransactionStatus(status),
        "invalid transaction status",
        "transaction_id", txnID, "status", status); err != nil {
        return err
    }
    // ...
    return nil
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for hand-rolled domain predicates that duplicate
> `lib-observability/assert` canonical predicates. Search for functions named `isPositive*`,
> `isValidAmount*`, `isValidTransactionStatus*`, `canTransition*`, `isValidUUID*`,
> `isValidPort*`, `debitsEqualCredits*`, `isInRange*`, and similar patterns. Also
> search for inline equivalents — switch statements enumerating
> CREATED/APPROVED/PENDING/CANCELED/NOTED, inline `d.Cmp(c) == 0 && !d.IsZero()`
> constructions, and range checks (`x >= min && x <= max`) that could be
> `assert.InRange`. Cross-reference each hand-rolled predicate against the canonical
> catalog in the "Full Domain Predicate Catalog" section of `ring:using-assert`. For
> each finding record file:line, the DIY predicate name or inline construction, and the
> exact canonical replacement. Severity HIGH — divergence between DIY predicates and
> canonical ones causes subtle bugs (e.g., DIY forgetting a status, accepting zero
> amounts, losing sign checks). Write `/tmp/assert-sweep-3-predicates.json`.

---

#### Angle 4: Missing `InitAssertionMetrics` at startup

**Severity:** MEDIUM

**DIY Patterns to Detect:**
- The service uses `assert.New(` or asserter methods somewhere in the codebase
- But `main.go`, `cmd/*/main.go`, `internal/app/`, or `internal/bootstrap/` packages do NOT contain `assert.InitAssertionMetrics(`
- Symptom: `assert` is imported and used, but the `assertion_failed_total` metric counter is never emitted, so assertion failures are invisible in dashboards even when they fire

**Grep pattern:**
```
Presence:  grep -r 'assert.New\|assertion.That\|a.That\|a.NotNil\|a.NotEmpty\|a.NoError'
Absence:   grep -r 'assert.InitAssertionMetrics' → returns no results
```

**lib-observability/assert Replacement:**

Add to the bootstrap sequence, AFTER telemetry is set up, ALONGSIDE `runtime.InitPanicMetrics`:

```go
// After: tl, _ := tracing.NewTelemetry(...)
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
assert.InitAssertionMetrics(tl.MetricsFactory)  // add this
```

**Migration Complexity:** trivial (one-line bootstrap addition)

**Example Transformation:**

```go
// BEFORE — metrics factory wired, panic metrics initialized, assert metrics forgotten:
tl, _ := tracing.NewTelemetry(telemetryConfig)
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
// assertion_failed_total counter will never fire even when assertions do

// AFTER:
tl, _ := tracing.NewTelemetry(telemetryConfig)
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
assert.InitAssertionMetrics(tl.MetricsFactory)
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo to determine whether `lib-observability/assert` is used without
> `InitAssertionMetrics` being called during bootstrap. First, grep for any usage
> of `assert.New(` or asserter methods (`.That(`, `.NotNil(`, `.NotEmpty(`,
> `.NoError(`, `.Never(`) across the codebase — this establishes that the service
> DOES use the assert package. Then grep `main.go`, `cmd/*/main.go`,
> `internal/app/*`, and `internal/bootstrap/*` for `assert.InitAssertionMetrics(`
> — its ABSENCE is the finding. If assert is used but InitAssertionMetrics is never
> called, record the file:line where asserter usage begins (to establish "yes, used")
> and the bootstrap file:line where the call should be added. If assert is not used
> at all in the service, emit an empty findings array. Severity MEDIUM — missing
> this call does not break functionality but causes invisible failures (trident emits
> log + span event but the metric counter stays at zero, so dashboards never alert on
> assertion spikes). Write `/tmp/assert-sweep-4-initmetrics.json`.

---

#### Angle 5: Financial invariants enforced only in tests, not in production

**Severity:** HIGH

**DIY Patterns to Detect:**
- `_test.go` files that assert on financial invariants using `assert.DebitsEqualCredits`, `assert.TransactionCanTransitionTo`, `assert.BalanceSufficientForRelease`, `assert.PositiveDecimal`, `assert.NonZeroTotals`, or equivalent hand-rolled checks
- But the corresponding **production code path** (the function the test exercises) does NOT enforce the same invariant via an asserter call

**Detection technique:**
1. Grep test files for invariant assertions: `require.True.*DebitsEqualCredits`, `require.NoError.*asserter.That.*DebitsEqualCredits`, or hand-rolled equivalents
2. For each hit, identify the function under test (e.g., test `TestPostTransaction` exercises `PostTransaction`)
3. Read the production function and check: does it call `asserter.That(ctx, assert.DebitsEqualCredits(...), ...)` itself? If not → finding

**Why this matters:** The test confirms the invariant holds under the test's inputs. The production code path can still **receive** inputs that violate the invariant (e.g., a bug upstream produces unbalanced debits) and silently corrupt ledger state. The invariant lives in the test, not in the production code, so CI stays green while production drifts.

**lib-observability/assert Replacement:**

Mirror the test assertion into the production code path:

```go
// Production code — add the same invariant check the test makes:
func PostTransaction(ctx context.Context, a *assert.Asserter, txn *Transaction) error {
    // Invariant: debits must equal credits (double-entry)
    if err := a.That(ctx, assert.DebitsEqualCredits(txn.TotalDebits(), txn.TotalCredits()),
        "double-entry invariant violated at posting",
        "transaction_id", txn.ID,
        "debits", txn.TotalDebits().String(),
        "credits", txn.TotalCredits().String()); err != nil {
        return err
    }
    // ... actual posting logic
    return nil
}
```

**Migration Complexity:** moderate — requires understanding test intent and mirroring into production

**Example Transformation:**

```go
// BEFORE — test asserts invariant, production does not:

// ledger_test.go
func TestPostTransaction_BalancesEqual(t *testing.T) {
    txn := buildTransaction(100, 100)
    require.True(t, assert.DebitsEqualCredits(txn.TotalDebits(), txn.TotalCredits()))
    err := PostTransaction(ctx, txn)
    require.NoError(t, err)
}

// ledger.go — production code has NO invariant check:
func PostTransaction(ctx context.Context, txn *Transaction) error {
    return repo.Insert(ctx, txn) // trusts input blindly
}

// AFTER — invariant mirrored into production, asserter fires trident if violated:

// ledger.go:
func PostTransaction(ctx context.Context, a *assert.Asserter, txn *Transaction) error {
    if err := a.That(ctx, assert.DebitsEqualCredits(txn.TotalDebits(), txn.TotalCredits()),
        "double-entry invariant violated",
        "transaction_id", txn.ID,
        "debits", txn.TotalDebits().String(),
        "credits", txn.TotalCredits().String()); err != nil {
        return err
    }
    return repo.Insert(ctx, txn)
}
```

★ Insight ─────────────────────────────────────
This is the highest-leverage angle in the sweep for a ledger codebase. An invariant
that lives only in tests passes CI and deploys to production, where it becomes a silent
assumption. Production code then trusts upstream callers, and the first time an upstream
bug produces unbalanced debits, the ledger writes the corruption straight to disk.
Mirroring test invariants into production is not redundancy — it's defense-in-depth
against the limits of test coverage.
─────────────────────────────────────────────────

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for financial invariants enforced only in tests and not in
> production. Walk `_test.go` files and find every assertion referencing
> `assert.DebitsEqualCredits`, `assert.TransactionCanTransitionTo`,
> `assert.BalanceSufficientForRelease`, `assert.PositiveDecimal`,
> `assert.NonZeroTotals`, or hand-rolled equivalents (e.g., `require.Equal(t, debits,
> credits)`). For each test assertion, identify the production function under test
> (typically inferred from test name — `TestPostTransaction` → `PostTransaction`). Read
> the production function and check: does it call an asserter with the SAME invariant?
> If not → finding. For each finding record the test file:line, the production
> file:line (function definition), and the specific invariant that is test-only.
> Severity HIGH — these are silent ledger-corruption risks. Write
> `/tmp/assert-sweep-5-test-only.json`.

---

#### Angle 6: `AssertionError` not unwrapped in error boundaries

**Severity:** MEDIUM

**DIY Patterns to Detect:**
- Fiber error handlers (`fiber.Config{ErrorHandler: ...}` or `FiberErrorHandler` overrides) that log errors without `errors.As(err, &assertErr)`
- gRPC unary/stream interceptors that log errors returned by service methods without AssertionError unwrap
- RabbitMQ consumer callbacks / message-handler error paths that log errors without AssertionError unwrap
- HTTP middleware error-logging paths that lose the structured AssertionError context
- Any `logger.Error("handler failed", "error", err)` at an error boundary — when `err` may be an AssertionError, the structural context (Component, Operation, Assertion) is flattened into the opaque error string

**lib-observability/assert Replacement:**

At error boundaries, unwrap and log the structural context:

```go
func logHandlerError(ctx context.Context, logger log.Logger, err error) {
    var assertErr *assert.AssertionError
    if errors.As(err, &assertErr) {
        logger.Error("assertion violated",
            "component", assertErr.Component,
            "operation", assertErr.Operation,
            "assertion", assertErr.Assertion,
            "message", assertErr.Message,
            "context", assertErr.Context,
        )
        return
    }
    logger.Error("handler error", "error", err)
}
```

**Migration Complexity:** trivial (one unwrap block added at each error boundary)

**Example Transformation:**

```go
// BEFORE — error boundary flattens AssertionError:
app := fiber.New(fiber.Config{
    ErrorHandler: func(c *fiber.Ctx, err error) error {
        logger.Error("request failed", "error", err.Error())
        // Component / Operation / Assertion labels lost in err.Error() string
        return c.Status(500).JSON(fiber.Map{"error": err.Error()})
    },
})

// AFTER — unwrap AssertionError at the boundary:
app := fiber.New(fiber.Config{
    ErrorHandler: func(c *fiber.Ctx, err error) error {
        var assertErr *assert.AssertionError
        if errors.As(err, &assertErr) {
            logger.Error("assertion violated at boundary",
                "component", assertErr.Component,
                "operation", assertErr.Operation,
                "assertion", assertErr.Assertion,
                "message", assertErr.Message,
            )
            // Assertion failures are internal invariant violations → 500, not 400
            return c.Status(500).JSON(fiber.Map{"error": "internal invariant violated"})
        }
        logger.Error("request failed", "error", err.Error())
        return c.Status(500).JSON(fiber.Map{"error": err.Error()})
    },
})
```

**Consequence of missing this pattern:** When an assertion fires, the trident emits the
metric and span event correctly, but the log line at the error boundary shows only the
flattened message string. Operators reading the log cannot tell which Component +
Operation + Assertion failed without correlating by timestamp to the span event — painful
during incident triage.

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for error boundaries that do not unwrap `*assert.AssertionError`.
> Search for Fiber error handlers (`ErrorHandler:`, `FiberErrorHandler`), gRPC
> interceptors (`grpc.UnaryInterceptor`, `grpc.StreamInterceptor`), RabbitMQ consumer
> callbacks, and HTTP middleware error-logging paths. For each boundary, check whether
> the error-handling code contains `errors.As(err, &<assertErrVar>)` where the variable
> is of type `*assert.AssertionError`. Boundaries that log the error without this unwrap
> are findings — they flatten Component/Operation/Assertion into an opaque string and
> lose structural observability in logs. For each finding record file:line, the boundary
> type (Fiber / gRPC / AMQP / HTTP middleware), and the log statement that should unwrap.
> Severity MEDIUM — the trident (metric + span event) still fires correctly; only the log
> layer loses structure. Write `/tmp/assert-sweep-6-unwrap.json`.

---
