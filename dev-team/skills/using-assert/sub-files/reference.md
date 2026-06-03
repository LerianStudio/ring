---

## Report Template

MANDATORY: The synthesizer MUST produce `/tmp/assert-sweep-report.md` following this
exact structure. MUST NOT add sections. MUST NOT reorder sections. MUST populate every
section even if empty (use "None detected" placeholders).

```markdown
# lib-observability/assert Sweep Report

**Target:** <absolute path to target repo>
**Generated:** <ISO-8601 timestamp>
**Sweep duration:** <seconds>

---

## Version Status

| Field                       | Value             |
| --------------------------- | ----------------- |
| Pinned observability version| <v1.0.0>          |
| Pinned commons version      | <v5.x or "not used">|
| Latest stable               | <resolved at runtime> |
| Drift classification        | <minor-drift>     |
| Major upgrade required      | <yes / no>        |
| Module path                 | <github.com/LerianStudio/lib-observability/assert>|
| Uses lib-commons shim       | <yes / no>        |

**Assessment:** <one-paragraph narrative — "project imports lib-observability/assert
directly, all recommendations apply to pinned version" or "project still imports via
the lib-commons/v5/commons/assert deprecation shim — migration to the canonical
lib-observability/assert path is required before adopting recommendations below">

---

## Unadopted Features

Changes to `lib-observability/assert` between the pinned version and latest stable that
the target has not yet adopted:

| Version | Feature                     | Classification  | Relevant Finding Angle |
| ------- | --------------------------- | --------------- | ---------------------- |
| <ver>   | <feature>                   | <classification>| <angle>                |

(If no assert-scoped changes exist in the delta, write "No unadopted features — the
lib-observability/assert API surface is unchanged between pinned and latest versions.")

---

## Quick Wins

Severity LOW–MEDIUM, migration complexity trivial. Low-risk, high-leverage fixes
batchable in a single dev-cycle task.

<bulleted list of findings grouped by angle — each bullet: "Angle N: <summary>, <file count> files, trivial">

---

## Strategic Migrations

Severity HIGH–CRITICAL, migration complexity moderate–complex. High-value, multi-task
efforts that MUST go through the full dev-cycle.

<bulleted list of findings grouped by angle — each bullet: "Angle N: <summary>, <file count> files, complexity, expected impact">

---

## Full Findings

| Angle                         | Severity  | File                        | Line | DIY Pattern                                | Replacement                              | Complexity |
| ----------------------------- | --------- | --------------------------- | ---- | ------------------------------------------ | ---------------------------------------- | ---------- |
| 1 panic() in non-test         | CRITICAL  | internal/ledger/posting.go  | 84   | panic("amount must be positive")           | asserter.That + assert.PositiveDecimal   | moderate   |
| 5 invariant test-only         | HIGH      | internal/ledger/ledger.go   | 112  | DebitsEqualCredits only in test            | asserter.That + DebitsEqualCredits       | moderate   |
| 3 hand-rolled predicate       | HIGH      | internal/txn/validate.go    | 47   | isValidTransactionStatus(s)                | assert.ValidTransactionStatus            | trivial    |
| ...                           | ...       | ...                         | ...  | ...                                        | ...                                      | ...        |

---

## Summary Statistics

| Severity | Findings | Files affected | Estimated effort |
| -------- | -------- | -------------- | ---------------- |
| CRITICAL | N        | N              | N days           |
| HIGH     | N        | N              | N days           |
| MEDIUM   | N        | N              | N days           |
| LOW      | N        | N              | N days           |
| **Total**| **N**    | **N**          | **N days**       |

**Angles clean:** <list of angles where no DIY was detected — signals codebase health>

---

## Recommended Next Step

`ring:dev-cycle` consuming `/tmp/assert-sweep-tasks.json` — N tasks generated,
grouped by severity, CRITICAL first. Angle 1 (zero-panic policy) and Angle 5
(test-only invariants) MUST land before other tiers — both are production-safety
risks.
```

---

## Task Generation for ring:dev-cycle

MANDATORY: The synthesizer MUST also emit `/tmp/assert-sweep-tasks.json` — a JSON
array of tasks shaped for `ring:dev-cycle` consumption. The format matches what
`ring:dev-refactor` produces.

**Task grouping rules:**

1. MUST group findings by severity — CRITICAL first, then HIGH, MEDIUM, LOW.
2. Within a severity tier, MUST group findings from the same file or tightly-related
   files (same package, same bounded context) into a single task.
3. CRITICAL findings (Angle 1 — zero-panic violations) MUST be standalone tasks (no
   batching across concerns) — each gets its own dev-cycle pass.
4. MUST include dependency references when one task's correctness depends on another
   (e.g., "Add InitAssertionMetrics" depends on "Migrate imports to lib-observability/assert"
   when the target still imports the lib-commons/v5 shim).

**Task schema:**

```json
{
  "id": "assert-sweep-001",
  "title": "Replace panic() in ledger posting with asserter",
  "severity": "CRITICAL",
  "description": "Target service violates zero-panic policy in internal/ledger/posting.go (3 call sites). panic() on invariant violations crashes the service instead of firing the observability trident and returning a recoverable error. Replace each panic with asserter.That + the appropriate domain predicate (PositiveDecimal, DebitsEqualCredits, ValidTransactionStatus). The assertion_failed_total metric becomes an observable signal on these invariants.",
  "files_affected": [
    "internal/ledger/posting.go:84",
    "internal/ledger/posting.go:127",
    "internal/ledger/posting.go:201"
  ],
  "acceptance_criteria": [
    "All panic() calls in internal/ledger/posting.go removed",
    "Each invariant enforced via asserter.That + canonical assert predicate",
    "Callers updated to accept returned error",
    "Unit tests verify asserter fires on invariant violation (metric counter + span event)",
    "No regexp.MustCompile exception abused — any remaining panic() is justified and minimal"
  ],
  "estimated_complexity": "moderate",
  "depends_on": [],
  "angle": 1,
  "replacement_api": "lib-observability/assert.Asserter + domain predicates"
}
```

**Task emission verbatim example:**

```json
[
  {
    "id": "assert-sweep-001",
    "title": "Migrate imports from lib-commons/v5/commons/assert to lib-observability/assert",
    "severity": "HIGH",
    "description": "Target service imports github.com/LerianStudio/lib-commons/v5/commons/assert — the deprecation shim that re-exports every symbol from github.com/LerianStudio/lib-observability/assert. Types, functions, signatures, and behavior are identical. The canonical home for the package is lib-observability; the shim exists only for backward compatibility. Update all imports to the canonical path so future predicate additions and the eventual removal of the shim do not block this codebase. All recommendations below assume the canonical import. This task MUST complete before any other assert-sweep task lands.",
    "files_affected": ["go.mod", "go.sum", "<all Go files importing lib-commons/v5/commons/assert>"],
    "acceptance_criteria": [
      "go.mod declares github.com/LerianStudio/lib-observability at latest v1.x tag",
      "All imports updated from github.com/LerianStudio/lib-commons/v5/commons/assert to github.com/LerianStudio/lib-observability/assert",
      "go build ./... passes",
      "go test ./... passes"
    ],
    "estimated_complexity": "moderate",
    "depends_on": [],
    "angle": "version",
    "replacement_api": "lib-observability/assert"
  },
  {
    "id": "assert-sweep-002",
    "title": "Replace panic() in ledger posting with asserter",
    "severity": "CRITICAL",
    "description": "<as above>",
    "files_affected": ["internal/ledger/posting.go:84", "..."],
    "acceptance_criteria": ["..."],
    "estimated_complexity": "moderate",
    "depends_on": ["assert-sweep-001"],
    "angle": 1,
    "replacement_api": "lib-observability/assert.Asserter + domain predicates"
  },
  {
    "id": "assert-sweep-003",
    "title": "Mirror test-only DebitsEqualCredits invariant into production PostTransaction",
    "severity": "HIGH",
    "description": "Tests assert the double-entry invariant in TestPostTransaction_BalancesEqual, but the production PostTransaction function does not. A caller that produces unbalanced debits will silently corrupt the ledger. Mirror the invariant into production via asserter.That + assert.DebitsEqualCredits so every posting enforces the same check the test does.",
    "files_affected": ["internal/ledger/ledger.go:112", "internal/ledger/ledger_test.go:34"],
    "acceptance_criteria": [
      "PostTransaction calls asserter.That(ctx, assert.DebitsEqualCredits(...), ...) before persisting",
      "Existing tests pass unchanged",
      "New test: calling PostTransaction with unbalanced debits returns AssertionError and increments assertion_failed_total"
    ],
    "estimated_complexity": "moderate",
    "depends_on": ["assert-sweep-001"],
    "angle": 5,
    "replacement_api": "lib-observability/assert + DebitsEqualCredits"
  }
]
```

**Handoff message template** (orchestrator surfaces to user after Phase 4):

```
lib-observability/assert sweep complete. Findings: <N> across <M> of 6 angles.
- CRITICAL: <N>   HIGH: <N>   MEDIUM: <N>   LOW: <N>

Report: /tmp/assert-sweep-report.md
Tasks:  /tmp/assert-sweep-tasks.json (<N> tasks)

Next: Invoke ring:dev-cycle with the task file to execute fixes. CRITICAL tasks
(Angle 1 zero-panic violations) and HIGH tasks (Angle 5 test-only invariants, Angle 3
hand-rolled predicates) MUST be addressed before MEDIUM/LOW tiers.
```

---

# REFERENCE MODE

Sections 1–14 below catalog the `lib-observability/assert` package (canonical home;
lib-commons/v5/commons/assert is a deprecation shim with identical signatures). Resolve
the actual version at runtime via `gh api repos/LerianStudio/lib-observability/releases/latest --jq .tag_name`.
Read the sections relevant to your current task. Sweep Mode explorers receive extracts
from these sections as context for their angle.

## 1. API Surface

Full catalog of exported symbols in `github.com/LerianStudio/lib-observability/assert`
(the canonical path; `github.com/LerianStudio/lib-commons/v5/commons/assert` re-exports
the same symbols as deprecated aliases).

### Constructor

```go
func New(ctx context.Context, logger Logger, component, operation string) *Asserter
```

Creates an asserter scoped to a specific component and operation. `Logger` is the
package-defined minimal logging interface (`assert.Logger`). `component` and
`operation` become metric labels and span-event attributes on every assertion failure.

### Asserter methods

```go
func (a *Asserter) That(ctx context.Context, condition bool, msg string, keysAndValues ...any) error
func (a *Asserter) NotNil(ctx context.Context, value any, msg string, keysAndValues ...any) error
func (a *Asserter) NotEmpty(ctx context.Context, s string, msg string, keysAndValues ...any) error
func (a *Asserter) NoError(ctx context.Context, err error, msg string, keysAndValues ...any) error
func (a *Asserter) Never(ctx context.Context, msg string, keysAndValues ...any) error
func (a *Asserter) Halt(err error)
```

Each method (except `Halt`) returns `error` on failure and `nil` on success. `Halt`
returns no value — it calls `runtime.Goexit()` when `err != nil`.

### Bootstrap

```go
func InitAssertionMetrics(factory *metrics.MetricsFactory)
func GetAssertionMetrics() *AssertionMetrics
func ResetAssertionMetrics()
```

`InitAssertionMetrics` registers the `assertion_failed_total` counter with the provided
metrics factory (`*github.com/LerianStudio/lib-observability/metrics.MetricsFactory`).
MUST be called once during service bootstrap AFTER telemetry is initialized. Without
this call, the log and span-event layers of the trident still fire, but the metric
layer stays silent. `GetAssertionMetrics` returns the singleton (nil before init).
`ResetAssertionMetrics` clears the singleton — test-only.

### Constants

```go
const AssertionSpanEventName = "assertion.failed"
```

The OTel span-event name attached to the active span on every failure (see Section 6).

### Error types

```go
type AssertionError struct {
    Component string
    Operation string
    Assertion string          // method name: "That", "NotNil", "NotEmpty", "NoError", "Never"
    Message   string
    Context   map[string]any  // keysAndValues flattened into a map
}

func (e *AssertionError) Error() string
func (e *AssertionError) Is(target error) bool

var ErrAssertionFailed = errors.New("assertion failed")  // sentinel for errors.Is
```

### Domain predicates

See [Section 4](#4-full-domain-predicate-catalog) for the full catalog. Signatures
summarized:

```go
// Numeric (int64)
func Positive(n int64) bool
func NonNegative(n int64) bool
func NotZero(n int64) bool
func InRange(n, minVal, maxVal int64) bool

// Numeric (int)
func PositiveInt(n int) bool
func InRangeInt(n, minVal, maxVal int) bool

// Financial
func PositiveDecimal(amount decimal.Decimal) bool
func NonNegativeDecimal(amount decimal.Decimal) bool
func ValidAmount(amount decimal.Decimal) bool
func ValidScale(scale int) bool
func DebitsEqualCredits(debits, credits decimal.Decimal) bool
func NonZeroTotals(debits, credits decimal.Decimal) bool
func BalanceSufficientForRelease(onHold, releaseAmount decimal.Decimal) bool
func BalanceIsZero(available, onHold decimal.Decimal) bool

// Transaction state machine
func ValidTransactionStatus(status string) bool
func TransactionCanTransitionTo(current, target string) bool
func TransactionCanBeReverted(status string, hasParent bool) bool
func TransactionHasOperations(operations []string) bool
func TransactionOperationsContain(operations, allowed []string) bool
// Deprecated alias of TransactionOperationsContain:
func TransactionOperationsMatch(operations, allowed []string) bool

// Network / infrastructure
func ValidUUID(s string) bool
func ValidPort(port string) bool
func ValidSSLMode(mode string) bool

// Time
func DateNotInFuture(date time.Time) bool
func DateAfter(date, reference time.Time) bool
```

---

## 2. Asserter Lifecycle

### Scoping

One asserter per **operation**, not per service. Reuse the asserter across all
invariant checks within the same request handler, message consumer callback, or
bounded operation. The `component` + `operation` labels are the axis along which
metrics and traces are grouped — making the labels too coarse (`component="app"`)
destroys metric granularity; making them too fine (`operation="post-transaction-step-4"`)
explodes label cardinality.

### Context propagation

Pass `ctx` into both the constructor and every method. The context is used to attach
span events to the **active trace**, so operators can jump from an assertion-failure
span event straight to the full request waterfall.

### Component naming conventions

Lowercase, hyphenated, bounded-context-shaped. Examples:

| Component             | Bounded context                    |
| --------------------- | ---------------------------------- |
| `ledger`              | Double-entry ledger core           |
| `transaction`         | Transaction lifecycle              |
| `auth`                | Authentication / authorization     |
| `ingest`              | Inbound event ingestion            |
| `outbox-dispatcher`   | Transactional outbox dispatcher    |
| `posting-engine`      | Balance posting                    |
| `webhook-deliverer`   | Outbound webhook delivery          |
| `dlq-consumer`        | Dead-letter queue consumer         |

### Operation naming conventions

Action-shaped, lowercase, hyphenated. Examples:

| Operation           | What it covers                          |
| ------------------- | --------------------------------------- |
| `post-transaction`  | Full posting workflow                   |
| `create-account`    | Account creation                        |
| `release-hold`      | Release held funds                      |
| `approve-pending`   | PENDING → APPROVED transition           |
| `revert-transaction`| Reverse an approved transaction         |
| `deliver-webhook`   | Send one outbound webhook               |

### Anti-pattern: per-service singleton asserter

```go
// DON'T: one asserter for the whole service
var serviceAsserter = assert.New(ctx, logger, "my-service", "all")

// DO: one asserter per operation
func postTransaction(ctx context.Context, ...) error {
    a := assert.New(ctx, logger, "ledger", "post-transaction")
    // ... invariant checks
}
```

A per-service singleton collapses all assertion metrics into a single
`{component=my-service, operation=all}` label pair, destroying the signal dashboards
rely on.

---

## 3. Instance Methods — When to Use Each

| Method      | When to use                                                            | Example                                                      |
| ----------- | ---------------------------------------------------------------------- | ------------------------------------------------------------ |
| `That`      | General boolean condition — compose with any predicate                 | `a.That(ctx, assert.DebitsEqualCredits(d, c), "...", ...)`   |
| `NotNil`    | Reflect-based nil check — catches typed nils stored in `any` interface | `a.NotNil(ctx, account, "...")`                              |
| `NotEmpty`  | String-only empty check                                                | `a.NotEmpty(ctx, tenantID, "...")`                           |
| `NoError`   | Shortcut for `err != nil` with auto error-type injection               | `a.NoError(ctx, dbErr, "...", "query", "SELECT ...")`        |
| `Never`     | Unreachable branch — exhaustive switch default, impossible sentinel    | `a.Never(ctx, "impossible status", "status", status)`        |
| `Halt`      | Goroutine-level halt via `runtime.Goexit()`                            | `a.Halt(err)` — only halts if `err != nil`                   |

### `That` — general condition

```go
if err := a.That(ctx, amount.IsPositive(), "amount must be positive",
    "amount", amount.String(), "account_id", accountID); err != nil {
    return err
}
```

Use when composing domain predicates. The condition is evaluated by the caller, so
predicates stay pure and the asserter handles observability.

### `NotNil` — typed-nil aware

`NotNil` uses `reflect.ValueOf(v).IsNil()` so it catches the common bug of a typed nil
stored in an `any` interface:

```go
var p *MyStruct  // p is typed nil
var v any = p    // v is not untyped nil — v == nil is FALSE

// a.NotNil correctly detects v is effectively nil
if err := a.NotNil(ctx, v, "MyStruct required"); err != nil {
    return err
}
```

### `NotEmpty` — strings only

`NotEmpty` only checks strings. For slices, use `That`:

```go
if err := a.That(ctx, len(ops) > 0, "operations required"); err != nil {
    return err
}
```

### `NoError` — auto error-type injection

`NoError` automatically appends the original error's type and message to the context,
so the caller does not need to pass them explicitly:

```go
if err := a.NoError(ctx, dbErr, "database query failed",
    "query", "SELECT balance", "account_id", accountID); err != nil {
    return err
}
// Context map also includes: "error_type", "<type>", "error", "<dbErr.Error()>"
```

### `Never` — for unreachable code

Use at exhaustive-switch defaults and impossible-state sentinels:

```go
switch status {
case "APPROVED":
    return approvePath(ctx)
case "CANCELED":
    return cancelPath(ctx)
case "PENDING":
    return pendingPath(ctx)
default:
    return a.Never(ctx, "unreachable status",
        "status", status, "transaction_id", txnID)
}
```

### `Halt` — goroutine-level halt

`Halt(err)` when `err != nil` calls `runtime.Goexit()`:

- Defers in the current goroutine still run
- Other goroutines are unaffected
- Process does not crash

Use only when continuing **this** goroutine is unsafe but the rest of the process is
fine (e.g., a background worker whose state is irrecoverable but whose peers are
healthy). `runtime.Goexit()` is preferred over `panic` because it respects the
zero-panic policy while still stopping the goroutine.

---

## 4. Full Domain Predicate Catalog

Predicates are pure `bool`-returning functions. Zero observability. Compose with an
asserter via `a.That(ctx, predicate, ...)` to add the trident.

### Numeric (int64)

| Predicate                              | What it validates                | Scenario                              |
| -------------------------------------- | -------------------------------- | ------------------------------------- |
| `Positive(n int64) bool`               | `n > 0`                          | Line counts, retry budgets, TTLs      |
| `NonNegative(n int64) bool`            | `n >= 0`                         | Queue depths, active connection count |
| `NotZero(n int64) bool`                | `n != 0`                         | Signed deltas that must change state  |
| `InRange(n, minVal, maxVal int64) bool`| `minVal <= n <= maxVal`          | Bounded tunables, pagination limits   |

### Numeric (int)

| Predicate                                | What it validates                | Scenario                            |
| ---------------------------------------- | -------------------------------- | ----------------------------------- |
| `PositiveInt(n int) bool`                | `n > 0`                          | Slice lengths, page counts          |
| `InRangeInt(n, minVal, maxVal int) bool` | `minVal <= n <= maxVal`          | Bounded `int`-typed configuration   |

Composition:

```go
a := assert.New(ctx, logger, "posting-engine", "allocate-remainder")
if err := a.That(ctx, assert.Positive(entryCount),
    "entry count must be positive",
    "transaction_id", txnID, "entry_count", entryCount); err != nil {
    return err
}
```

### Financial (shopspring/decimal)

| Predicate                                           | What it validates                                          |
| --------------------------------------------------- | ---------------------------------------------------------- |
| `PositiveDecimal(amount decimal.Decimal) bool`      | `amount > 0`                                               |
| `NonNegativeDecimal(amount decimal.Decimal) bool`   | `amount >= 0`                                              |
| `ValidAmount(amount decimal.Decimal) bool`          | Exponent in `[-18, 18]` — within ledger precision          |
| `ValidScale(scale int) bool`                        | `0 <= scale <= 18`                                         |
| `DebitsEqualCredits(debits, credits) bool`          | `debits == credits` — double-entry invariant               |
| `NonZeroTotals(debits, credits) bool`               | Both sides non-zero                                        |
| `BalanceSufficientForRelease(onHold, release) bool` | `onHold >= release` — sufficient held funds                |
| `BalanceIsZero(available, onHold) bool`             | Both `available` and `onHold` are exactly zero             |

Composition — double-entry enforcement at posting time:

```go
a := assert.New(ctx, logger, "ledger", "post-transaction")

if err := a.That(ctx, assert.DebitsEqualCredits(debits, credits),
    "double-entry violation: debits != credits",
    "debits", debits.String(),
    "credits", credits.String(),
    "transaction_id", txnID); err != nil {
    return err
}

if err := a.That(ctx, assert.NonZeroTotals(debits, credits),
    "double-entry violation: zero-sum posting",
    "debits", debits.String(),
    "credits", credits.String()); err != nil {
    return err
}
```

Composition — sufficient-balance check on hold release:

```go
a := assert.New(ctx, logger, "posting-engine", "release-hold")
if err := a.That(ctx, assert.BalanceSufficientForRelease(holdAmount, releaseAmount),
    "insufficient held funds for release",
    "account_id", accountID,
    "on_hold", holdAmount.String(),
    "release", releaseAmount.String()); err != nil {
    return err
}
```

### Transaction state machine

| Predicate                                                   | What it validates                                               |
| ----------------------------------------------------------- | --------------------------------------------------------------- |
| `ValidTransactionStatus(status string) bool`                | One of `CREATED, APPROVED, PENDING, CANCELED, NOTED`            |
| `TransactionCanTransitionTo(current, target string) bool`   | Transition from current to target is legal                      |
| `TransactionCanBeReverted(status string, hasParent bool)`   | Only `APPROVED` transactions without a parent can be reverted   |
| `TransactionHasOperations(operations []string) bool`        | `len(operations) > 0`                                           |
| `TransactionOperationsContain(operations, allowed []string)`| All operation types in `operations` are members of `allowed`   |
| `TransactionOperationsMatch(operations, allowed []string)`  | Deprecated alias for `TransactionOperationsContain`             |

The legal-transition graph (enforced by `TransactionCanTransitionTo`):

```
CREATED → APPROVED
CREATED → PENDING
CREATED → CANCELED
PENDING → APPROVED
PENDING → CANCELED
APPROVED → (terminal, except for NOTED reversal under explicit revert)
```

Composition — status transition at approval time:

```go
a := assert.New(ctx, logger, "transaction", "approve-pending")

if err := a.That(ctx, assert.ValidTransactionStatus(currentStatus),
    "unknown transaction status",
    "transaction_id", txnID, "status", currentStatus); err != nil {
    return err
}

if err := a.That(ctx, assert.TransactionCanTransitionTo(currentStatus, "APPROVED"),
    "illegal status transition",
    "transaction_id", txnID,
    "from", currentStatus, "to", "APPROVED"); err != nil {
    return err
}
```

Composition — revert guard:

```go
a := assert.New(ctx, logger, "transaction", "revert-transaction")
if err := a.That(ctx, assert.TransactionCanBeReverted(status, hasParent),
    "transaction cannot be reverted",
    "transaction_id", txnID,
    "status", status,
    "has_parent", hasParent); err != nil {
    return err
}
```

### Network / infrastructure

| Predicate                       | What it validates                           |
| ------------------------------- | ------------------------------------------- |
| `ValidUUID(s string) bool`      | Well-formed UUID (v1–v7 accepted)           |
| `ValidPort(port string) bool`   | `"1"` to `"65535"` as decimal string        |
| `ValidSSLMode(mode string) bool`| PostgreSQL SSL modes                        |

Composition — guarding configuration at bootstrap:

```go
a := assert.New(ctx, logger, "bootstrap", "parse-config")
if err := a.That(ctx, assert.ValidPort(cfg.Port),
    "invalid port in config",
    "port", cfg.Port); err != nil {
    return err
}
```

### Time

| Predicate                                             | What it validates                    |
| ----------------------------------------------------- | ------------------------------------ |
| `DateNotInFuture(date time.Time) bool`                | `date <= time.Now()`                 |
| `DateAfter(date, reference time.Time) bool`           | `date > reference`                   |

Composition — guard against clock-skew / bad input:

```go
a := assert.New(ctx, logger, "ingest", "accept-event")
if err := a.That(ctx, assert.DateNotInFuture(event.Timestamp),
    "event timestamp in the future",
    "event_id", event.ID,
    "timestamp", event.Timestamp.Format(time.RFC3339)); err != nil {
    return err
}
```

---

## 5. Composition Pattern

The division of labor is deliberate and strict:

| Layer       | Responsibility                                      | Observability |
| ----------- | --------------------------------------------------- | ------------- |
| Predicates  | Pure domain logic — `bool` return                   | None          |
| Asserter    | Observability trident on failure (log + span + metric) | All           |

This separation means:

- Predicates are cheap to test (pure functions, no mocks)
- Predicates are cheap to compose (any Boolean combination)
- Predicates are cheap to share across packages (no dependency on logger/metrics)
- Asserter carries the observability weight — a single call site, three outputs

★ Insight ─────────────────────────────────────
The predicates ARE the business rules. `assert.DebitsEqualCredits` is not "defensive
code that happens to check the accounting invariant" — it IS the accounting invariant,
expressed as executable code. A codebase that composes canonical predicates with
asserters has its regulatory rulebook encoded as runtime-enforced contracts. A codebase
that hand-rolls predicates has its rulebook encoded as prose-in-code-review, which
drifts the moment someone's pattern is a little different than canon.
─────────────────────────────────────────────────

### Canonical composition sites

| Site                             | Composition                                                                 |
| -------------------------------- | --------------------------------------------------------------------------- |
| Posting engine entry             | `DebitsEqualCredits` + `NonZeroTotals` + `PositiveDecimal` per entry        |
| Status transition handler        | `ValidTransactionStatus` + `TransactionCanTransitionTo`                     |
| Hold release                     | `BalanceSufficientForRelease` + `PositiveDecimal`                           |
| Revert guard                     | `TransactionCanBeReverted`                                                  |
| Config bootstrap                 | `ValidPort` + `ValidSSLMode` + `ValidUUID` (for static IDs)                 |
| Inbound event acceptance         | `DateNotInFuture` + `NotEmpty` (ids) + `ValidTransactionStatus` (payload)   |

---

## 6. The Observability Trident

Every assertion failure produces three outputs. They are emitted unconditionally when
the asserter is correctly initialized — the consumer cannot opt into "log only" or
"metric only" without modifying the asserter itself.

### Layer 1 — Structured log

```
ERROR assertion failed: double-entry violation: debits != credits
  component=ledger
  operation=post-transaction
  assertion=That
  debits=150.00
  credits=149.50
  transaction_id=abc-123
```

Emitted via the `log.Logger` passed to `assert.New`. Fields: `component`, `operation`,
`assertion` (method name), `message`, and all `keysAndValues` the caller provided.

### Layer 2 — OTel span event

Event name: `assertion.failed`, attached to the **active span** on the context.

Attributes:

| Attribute              | Value                               |
| ---------------------- | ----------------------------------- |
| `assertion.type`       | Method name (`That`, `NotNil`, ...) |
| `assertion.message`    | The message string                  |
| `assertion.component`  | From `assert.New`                   |
| `assertion.operation`  | From `assert.New`                   |
| All `keysAndValues`    | As span attributes                  |

The span's status is NOT automatically set to Error — the asserter only adds the event.
If the caller wants to mark the span failed, it must do so explicitly.

### Layer 3 — Metric

Counter `assertion_failed_total`, incremented by 1 on each failure.

Labels:

| Label        | Source                              |
| ------------ | ----------------------------------- |
| `component`  | From `assert.New`                   |
| `operation`  | From `assert.New`                   |
| `assertion`  | Method name (`That`, `NotNil`, ...) |

Canonical PromQL for operator dashboards:

```promql
# Rate of assertion failures per component
sum by (component) (rate(assertion_failed_total[5m]))

# Top failing operations
topk(10, sum by (component, operation) (rate(assertion_failed_total[1h])))

# Alert: sustained double-entry violations (ledger-scoped)
sum(rate(assertion_failed_total{component="ledger", operation="post-transaction"}[10m])) > 0
```

★ Insight ─────────────────────────────────────
`assertion_failed_total{assertion="DebitsEqualCredits"}` is a regulatory-grade metric,
not a debugging metric. A spike is a **potential accounting event** — auditors will
ask for the trace. The fact that this signal has three redundant channels (log for
grep, span event for trace correlation, metric for alerting) means no operator can
plausibly claim "we didn't know" after a ledger drift. That's the point.
─────────────────────────────────────────────────

### Production mode behavior

When `runtime.SetProductionMode(true)` is active (or `ENV=production`), the asserter:

- **Suppresses stack traces** in both the log and the span event
- Keeps all other fields identical

In development mode, stack traces are included to help debugging. The choice is binary
— there is no "include N frames" tuning.

---

## 7. AssertionError Unwrapping

Every asserter method returns `*assert.AssertionError` on failure. Error boundaries
MUST unwrap the structural context to preserve observability in logs.

### Canonical unwrap pattern

```go
var assertErr *assert.AssertionError
if errors.As(err, &assertErr) {
    logger.Error("assertion violated",
        "component", assertErr.Component,
        "operation", assertErr.Operation,
        "assertion", assertErr.Assertion,
        "message",   assertErr.Message,
        "context",   assertErr.Context,  // map[string]any of keysAndValues
    )
}
```

### Sentinel check

```go
if errors.Is(err, assert.ErrAssertionFailed) {
    // This is an assertion failure (any type). Use for flow-control
    // decisions without needing the structural context.
}
```

### Where to unwrap

| Boundary                        | What to do                                                          |
| ------------------------------- | ------------------------------------------------------------------- |
| Fiber `ErrorHandler`            | Unwrap, log structured, return 500                                  |
| gRPC unary/stream interceptor   | Unwrap, log structured, convert to `codes.Internal`                 |
| RabbitMQ consumer callback      | Unwrap, log structured, Nack with `requeue=false` (invariant bug)   |
| HTTP middleware error-handler   | Unwrap, log structured, do not leak internal invariants to response |
| Outer `main` defer              | Unwrap, log structured, exit non-zero                               |

### HTTP status code mapping

**AssertionError → HTTP 500, never 400.** Assertion failures represent **internal
invariant violations**, not user-input errors. Returning 400 implies the client made a
bad request, which misleads both the caller and the operator triaging the incident.

```go
// WRONG:
if assertErr != nil {
    return c.Status(400).JSON(fiber.Map{"error": "bad input"}) // misleading
}

// RIGHT:
if assertErr != nil {
    return c.Status(500).JSON(fiber.Map{"error": "internal invariant violated"})
}
```

The one exception is when the assertion wraps a clearly-user-caused validation (e.g.,
`NotEmpty` on a user-provided field at a public API boundary) — in that case, validate
at the edge with a normal error path before the invariant check, so the assertion is
reserved for actual invariants.

---

## 8. Decision Tree — panic vs assert vs error

Three-way decision every Go engineer makes, every day, in a Lerian codebase:

| Choice   | When                                                         | Observability |
| -------- | ------------------------------------------------------------ | ------------- |
| `panic`  | **Never** — except `regexp.MustCompile` with string literal  | Crash         |
| `assert` | Invariant that SHOULD always hold — violation is a bug       | Trident       |
| `error`  | Expected failure mode — user input, I/O, external system     | Normal        |

### `panic` — effectively banned

Zero-panic policy. The ONLY accepted `panic` in Lerian code is `regexp.MustCompile(...)`
where the argument is a compile-time string literal constant. That specific call is
acceptable because the panic can only fire if the regex literal is malformed at
compile time, which surfaces during development, not in production.

Everything else returns an error. No exceptions. A `panic` that reaches production
crashes the service and loses the request; the trident explicitly exists so that
production never needs `panic` to be heard.

### `assert` — for invariants

An **invariant** is something that the code path's caller/callee contract guarantees
will be true. A violation is a bug, not a user error or external failure. When an
invariant is violated, the right response is:

- Trident fires (visible to operators)
- Error propagates (callers can decide how to respond)
- Process keeps running (no crash)

### `error` — for expected failures

An **expected failure** is a normal, anticipated outcome of calling the function:

- User input that does not validate
- External system that returned 503
- Database connection that refused
- Context that was cancelled

Expected failures use normal error returns. They do NOT need the trident because:

- They are not bugs (no operator action needed for each occurrence)
- They are already handled by domain-level metrics (e.g., HTTP error rate, DB error counter)

### The additive mode — `assert` AND `error` together

A choice the three-way table doesn't capture: when the same call site benefits from
BOTH the trident (operator dashboard signal) AND the returned sentinel (caller can
`errors.Is` and recover). The trident is purely additive — it logs / traces / increments
the metric, then the caller's documented sentinel propagates unchanged.

This mode is the right call when **all three** conditions hold:

| Condition | What it means |
|-----------|---------------|
| **Deploy-bound firing** | The check runs at construction / bootstrap / config-load — once per process startup, not once per request. A misconfiguration fires the trident exactly once until an operator fixes it. |
| **Operator-actionable** | The signal points at something an operator can fix in env vars, build wiring, or catalog construction — not something a user needs to retry differently. |
| **Sentinel still propagates** | The asserter call is purely additive; the original caller-correctable sentinel (`errors.Is` matchable, `IsCallerError`-classified) still flows back up the stack. |

When all three hold, asserting on a caller-correctable sentinel is correct, even though
the strict reading of the three-way table ("user input → error") would suggest otherwise.
The trident is a **deploy-time loud signal**, not per-request noise — its cardinality is
bounded by misconfiguration count, not request volume.

Examples that fit additive mode:

- `LoadConfig()` rejecting `STREAMING_CB_FAILURE_RATIO=2.5` — env-var typo, fires once
  at bootstrap, sentinel `ErrInvalidConfigField` still wraps the failure.
- `Builder.Target("primary\nattacker").Build()` — control-char in target name, fires
  once at construction, sentinel `ErrInvalidRouteDefinition` still propagates.
- `NewCatalog(...)` rejecting duplicate `(ResourceType, EventType, SchemaVersion)` —
  caller wired the catalog wrong, fires once at construction, sentinel
  `ErrDuplicateEventDefinition` still propagates.
- `NewEventDefinition` with malformed semver in `SchemaVersion` — caller's catalog row
  is wrong, fires at catalog construction, sentinel still propagates.

Examples that do NOT fit additive mode (use plain `error`, no trident):

- `Emit(req)` rejecting an oversized payload on every call — traffic-bound; would burn
  metric volume proportional to QPS for a misbehaving client. The transport / domain
  error counter already covers this shape with better labels.
- `validateRequestBody` at an HTTP edge — user input, expected at any rate.
- A per-request status-transition predicate failing — the domain-level error metric
  already counts it.

★ Insight ─────────────────────────────────────
The diagnostic question is not "did the caller make a mistake?" — it's "**how many times
will this fire if the mistake exists?**" Once-per-deploy = trident is value-add.
Once-per-request = trident is noise. The original three-way decision tree collapses
these into one cell; real systems have both shapes, and treating them the same either
gives up dashboard signal at deploy time (too strict) or floods dashboards during
incidents (too loose).
─────────────────────────────────────────────────

### Worked examples

| Scenario                                                       | Choice | Reasoning                                                                                                                                   |
| -------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `ctx.Done()` fires during a DB query                            | error  | Expected — request was cancelled or timeout reached                                                                                         |
| Database returns `connection refused`                           | error  | Expected external failure                                                                                                                    |
| User POSTs `amount = "not a number"`                            | error  | Expected input failure — validate at edge                                                                                                    |
| DB query returns success but `rows` is nil                      | assert | Invariant — the driver contract says nil is impossible on success                                                                            |
| Transaction status read from own DB is `"BANANA"`               | assert | Invariant — we wrote it, we control the enum                                                                                                 |
| Tenant ID missing from request context after JWT middleware     | assert | Invariant — the middleware guarantees it; if missing, middleware has a bug                                                                   |
| Account balance goes negative after hold release                | assert | Invariant — accounting laws                                                                                                                  |
| RabbitMQ broker down during publish                             | error  | Expected external failure                                                                                                                    |
| `regexp.MustCompile("[a-z]+")` at package init                   | panic  | Accepted exception — compile-time constant                                                                                                   |
| `regexp.MustCompile(userProvidedPattern)`                        | error  | NOT an exception — user input; validate and return error                                                                                     |
| Impossible `default:` branch in exhaustive switch over enum      | assert | Invariant via `a.Never(ctx, ...)`                                                                                                            |
| JWT signature invalid                                            | error  | Expected failure — auth boundary rejection                                                                                                   |
| Double-entry debits != credits at posting time                   | assert | Invariant — accounting law                                                                                                                   |
| `STREAMING_CB_FAILURE_RATIO=2.5` rejected at `LoadConfig`        | assert AND error | Additive mode — construction-time, deploy-bound, operator-actionable. Sentinel `ErrInvalidConfigField` still propagates.          |
| `Builder.Target("name\nattacker")` rejected at construction      | assert AND error | Additive mode — construction-time, deploy-bound. Sentinel `ErrInvalidRouteDefinition` still propagates.                           |
| `NewCatalog` rejects duplicate `(Resource, Event, Version)`      | assert AND error | Additive mode — construction-time, deploy-bound. Sentinel `ErrDuplicateEventDefinition` still propagates.                         |
| `NewEventDefinition` rejects malformed semver SchemaVersion      | assert AND error | Additive mode — construction-time. Catches the misconfiguration once at deploy instead of once per Emit.                          |
| `Emit(req)` rejects oversized payload (per-request)              | error  | Traffic-bound caller mistake — plain error, no trident. See anti-pattern #7. Use a domain-level counter at the edge if you need a metric. |
| Per-request status-transition predicate fails on user input      | error  | Traffic-bound — domain error metric already counts it.                                                                                       |

★ Insight ─────────────────────────────────────
The question "panic, assert, or error?" has a simple diagnostic: **who is responsible
when this fires?** If a user is responsible (bad input), it's an error. If an operator
is responsible (bug, unexpected state), it's an assert. If nobody can act (compile-time
wrong regex), it's the one accepted panic. Anything that doesn't fit is an error.
─────────────────────────────────────────────────

---

## 9. Testing Patterns

Proving assertions fire correctly is part of the test suite, not a manual exercise.

### Inject a test metrics factory

```go
import (
    "github.com/LerianStudio/lib-observability/assert"
    "github.com/LerianStudio/lib-observability/metrics"
)

func TestPostTransaction_FiresAssertionOnUnbalanced(t *testing.T) {
    testFactory := metrics.NewTestFactory()
    assert.InitAssertionMetrics(testFactory)

    a := assert.New(ctx, testLogger, "ledger", "post-transaction")
    err := PostTransaction(ctx, a, buildUnbalancedTransaction())

    require.Error(t, err)
    require.True(t, errors.Is(err, assert.ErrAssertionFailed))

    // Verify the counter incremented with the expected labels
    require.Equal(t, int64(1), testFactory.CounterValue("assertion_failed_total",
        map[string]string{
            "component": "ledger",
            "operation": "post-transaction",
            "assertion": "That",
        }))
}
```

### Verify span event via in-memory OTel exporter

```go
import "go.opentelemetry.io/otel/sdk/trace/tracetest"

func TestPostTransaction_EmitsSpanEvent(t *testing.T) {
    exporter := tracetest.NewInMemoryExporter()
    // ... set up test tracer provider with this exporter

    _ = PostTransaction(ctx, a, buildUnbalancedTransaction())

    spans := exporter.GetSpans()
    require.Len(t, spans, 1)

    events := spans[0].Events
    require.Len(t, events, 1)
    require.Equal(t, "assertion.failed", events[0].Name)

    attrs := events[0].Attributes
    requireAttr(t, attrs, "assertion.component", "ledger")
    requireAttr(t, attrs, "assertion.operation", "post-transaction")
    requireAttr(t, attrs, "assertion.type", "That")
}
```

### AssertionError field-equality tests

```go
func TestPostTransaction_ReturnsStructuredAssertionError(t *testing.T) {
    err := PostTransaction(ctx, a, buildUnbalancedTransaction())

    var assertErr *assert.AssertionError
    require.True(t, errors.As(err, &assertErr))
    require.Equal(t, "ledger", assertErr.Component)
    require.Equal(t, "post-transaction", assertErr.Operation)
    require.Equal(t, "That", assertErr.Assertion)
    require.Contains(t, assertErr.Message, "double-entry violation")
}
```

### Production-drift mirror check

For every test that uses an `assert.<Predicate>`, verify the production code under test
ALSO uses the same predicate via an asserter. This is the systematic check for Angle 5:

```go
// For each test hitting a predicate:
func TestPostTransaction_BalancesEqual(t *testing.T) {
    txn := buildTransaction(100, 100)
    require.True(t, assert.DebitsEqualCredits(txn.Debits(), txn.Credits()))
    require.NoError(t, PostTransaction(ctx, a, txn))
}

// The production PostTransaction MUST also call a.That(ctx,
// assert.DebitsEqualCredits(...), ...) — otherwise the invariant is test-only.
```

One manual or automated cross-reference pass per PR catches the drift that Angle 5
sweeps surface across a whole codebase.

---

## 10. Anti-Pattern Catalog

Seven anti-patterns with consequences. Each is a one-way door — once in production, the
damage compounds.

### 1. `panic()` for invariants

```go
// BEFORE:
if amount.IsNegative() {
    panic("amount must be positive")
}
```

**Consequence:** Crashes the service on an invariant that the asserter would have
reported non-fatally. Request is lost. Operators find a stack trace in logs but no
metric signal. Zero-panic policy violated.

### 2. Silent error return on invariant violation

```go
// BEFORE:
if debits.Cmp(credits) != 0 {
    return errors.New("unbalanced") // no metric, no trace
}
```

**Consequence:** Debit/credit mismatch is returned as a plain error. Log at the
boundary shows "unbalanced" but no `assertion_failed_total` metric, so dashboards
never alert. A silent, slow-motion ledger drift.

### 3. Reinvented predicates

```go
// BEFORE:
func debitsEqualCredits(d, c decimal.Decimal) bool {
    return d.Cmp(c) == 0
}
```

**Consequence:** DIY diverges from canon. The canonical `assert.DebitsEqualCredits`
may include non-zero-total checks, tolerance handling, or invariant upgrades in
future versions — the DIY version stays frozen. Cross-service behavior inconsistency.

### 4. Missing `InitAssertionMetrics`

```go
// Bootstrap:
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
// assert.InitAssertionMetrics missing
a := assert.New(ctx, logger, "ledger", "post")
_ = a.That(ctx, false, "test")
```

**Consequence:** Log and span event fire. Metric counter does not exist in the
registry, so Prometheus never scrapes it. Dashboards show flat lines even as
assertions fire thousands of times per minute during an incident.

### 5. Assertion only in tests

```go
// Test:
require.True(t, assert.DebitsEqualCredits(d, c))

// Production PostTransaction — no invariant check.
```

**Consequence:** Test suite passes. Production code blindly writes whatever debits and
credits the caller provides. First upstream bug that produces unbalanced input writes
corruption directly to the ledger. Silent drift until the first audit.

### 6. Opaque AssertionError in boundary logs

```go
// BEFORE — Fiber error handler:
ErrorHandler: func(c *fiber.Ctx, err error) error {
    logger.Error("request failed", "error", err.Error())
    return c.Status(500).JSON(...)
}
```

**Consequence:** Error is stringified. `Component`, `Operation`, `Assertion` labels are
embedded in the string, not as log fields. Operators cannot filter/group logs by these
dimensions. Incident triage requires correlating by timestamp to the span event to
recover the structure.

### 7. Asserter on hot-path-evaluated caller input

```go
// BEFORE — anti-pattern: asserter on per-request caller input:
func (p *Producer) Emit(ctx context.Context, req EmitRequest) error {
    a := assert.New(ctx, p.logger, "producer", "emit-payload-cap")
    if err := a.That(ctx, len(req.Payload) <= maxBytes,
        "payload exceeds cap",
        "size", len(req.Payload), "cap", maxBytes); err != nil {
        return ErrPayloadTooLarge
    }
    // ...
}
```

**Consequence:** A misbehaving client sending oversized payloads at full request rate
fires `assertion_failed_total` at `req/s × bad-client-share` for the lifetime of the
problem. The signal is real but redundant — the existing transport / domain error
counter already captures the same shape with better labels (per-client, per-resource,
per-event). The asserter trident becomes incident-time noise that must be filtered out
of dashboards, and at high QPS it allocates one `*AssertionError` per bad request.

**The fix:** Use plain error returns for traffic-bound caller mistakes. Reserve the
trident for **deploy-bound** caller mistakes (Section 8 "additive mode") and for
invariant violations (the original three-way table). If you need a metric for "how
often clients send bad input," create a domain-specific counter at the edge — don't
repurpose `assertion_failed_total` for it.

★ Insight ─────────────────────────────────────
This is the mirror image of Anti-Pattern #2 (silent invariant return). #2 is "no
trident where there should be one"; #7 is "trident where there shouldn't be one." Both
end with operators unable to trust the dashboard: #2 hides bugs, #7 buries them in
noise. The discriminator between #7 and Section 8's additive mode is firing rate —
not whether the caller made the mistake.
─────────────────────────────────────────────────

---

## 11. Bootstrap Order

The `assert.InitAssertionMetrics` call has a specific position in service bootstrap:

- AFTER logger initialization (assertions emit via the logger)
- AFTER telemetry initialization (uses the metrics factory)
- ALONGSIDE `runtime.InitPanicMetrics` (both read from the same `tl.MetricsFactory`)
- BEFORE any code path that might fire an assertion (i.e., before any handler / consumer
  / worker starts)

For the complete bootstrap sequence (logger → telemetry → runtime → assert →
infrastructure clients → server), see `ring:using-lib-observability` (or
`ring:using-lib-commons` for codebases still on the v5 shim).

The two-line addition at the right point:

```go
// After tracing.NewTelemetry(...):
runtime.InitPanicMetrics(tl.MetricsFactory, logger)
assert.InitAssertionMetrics(tl.MetricsFactory)
```

---

## 12. Cross-References

This skill does not duplicate material available elsewhere. Use these pointers:

| For                                                         | See                                                            |
| ----------------------------------------------------------- | -------------------------------------------------------------- |
| Full lib-observability package catalog (assert, tracing, metrics, log, zap, runtime) | `ring:using-lib-observability` |
| Full bootstrap sequence with all observability clients      | `ring:using-lib-observability`                                 |
| lib-commons v5 deprecation shim — re-export aliases         | `ring:using-lib-commons` (compatibility window only)           |
| Panic recovery + `SafeGo` + error reporter integration      | `ring:using-runtime`                                           |
| Running a full codebase standards sweep                     | `ring:dev-refactor`                                            |
| Consuming sweep tasks into a development cycle              | `ring:dev-cycle`                                               |

`ring:using-runtime` is the natural companion to this skill — `runtime` protects
against panics that would otherwise silently kill a goroutine; `assert` protects
against invariant violations that would otherwise silently corrupt state. Together,
they close both halves of the invisible-failure problem in Go services. Both packages
now live under `github.com/LerianStudio/lib-observability` (see `ring:using-lib-observability`).

---

## 13. Cross-Cutting Patterns

Patterns that apply across all `lib-observability/assert` usage.

### Nil-receiver safety

Every exported `Asserter` method is nil-receiver safe. Calling a method on a nil
`*Asserter` returns `ErrNilAsserter` (or equivalent) rather than panicking. This means
code paths that conditionally construct an asserter (e.g., when the logger is optional
in bootstrap) do not need a separate nil check at every call site.

### Production mode effects

`runtime.SetProductionMode(true)` affects the assertion output:

- Stack traces suppressed in logs and span events
- All other fields preserved
- Metric emission unchanged (production mode does not affect counters)

Development mode includes stack traces to aid debugging. The setting is global
(per-process) and is normally set once at bootstrap.

### Interaction with runtime

Asserter methods return errors. They do NOT panic. Therefore they do NOT trigger
`runtime.SafeGo` or `runtime.RecoverWithPolicy` recovery paths. This is intentional:

- `runtime` handles panics (goroutine-death prevention)
- `assert` handles invariant violations (state-corruption prevention)
- The two mechanisms are orthogonal and both are needed

A goroutine launched via `runtime.SafeGo` that fires an assertion: the assertion
returns an error; the goroutine decides what to do with it (return, log, retry); if the
goroutine then panics separately, `SafeGo` recovers. No overlap.

### Performance

Assertion hot-path cost:

- Success path: predicate evaluation + one `if` comparison — effectively free
- Failure path: one `*AssertionError` heap allocation + log line + span event + metric increment

Failure is expected to be rare (invariants should hold nearly always), so the allocation
on failure is acceptable. The success path has zero allocations — safe to place in
tight loops, request handlers, and message consumers.

---

## 14. Breaking Changes

### lib-commons/v5/commons/assert → lib-observability/assert (canonical move)

The package moved out of lib-commons and into the new foundation library
`github.com/LerianStudio/lib-observability/assert` (v1.0.0+). lib-commons v5 keeps a
deprecation shim — every type and function in `lib-commons/v5/commons/assert` is
marked `Deprecated:` and delegates verbatim to `lib-observability/assert`. There are
no behavior changes; only the canonical import path moves.

**Source-compatible:** All method signatures, predicate signatures, error types, and
the `AssertionSpanEventName` constant are identical. `AssertionMetrics`, `New`,
`InitAssertionMetrics`, `GetAssertionMetrics`, `ResetAssertionMetrics`, and every
predicate are re-exported via type aliases / thin wrappers.

**Migration path:**

```diff
- import "github.com/LerianStudio/lib-commons/v5/commons/assert"
+ import "github.com/LerianStudio/lib-observability/assert"
```

```diff
- import metrics "github.com/LerianStudio/lib-commons/v5/commons/opentelemetry/metrics"
+ import "github.com/LerianStudio/lib-observability/metrics"
```

Then `go mod tidy` to pick up `github.com/LerianStudio/lib-observability` and drop the
unused lib-commons subpackage if it is no longer used elsewhere. Code that still imports
the shim continues to compile during the deprecation window.

### v4.x → v5.x (lib-commons/commons/assert) — legacy

For codebases still on lib-commons/v4, the v4 → v5 module bump came first; that bump
had no API-breaking changes inside `commons/assert`. After that, switch the import to
`lib-observability/assert` per the section above.

### lib-observability/assert v1.0.x+

Patch releases — no API changes. Check the latest v1.x tag for current patch level via
`gh api repos/LerianStudio/lib-observability/releases/latest --jq .tag_name`.

---
