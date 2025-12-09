---
name: condition-based-waiting
description: |
  Flaky test fix pattern - replaces arbitrary timeouts with condition polling
  that waits for actual state changes.

trigger: |
  - Tests use setTimeout/sleep with arbitrary values
  - Tests are flaky (pass sometimes, fail under load)
  - Tests timeout when run in parallel
  - Waiting for async operations in tests

skip_when: |
  - Testing actual timing behavior (debounce, throttle) → timeout is correct
  - Synchronous tests → no waiting needed
---

# Condition-Based Waiting

## Overview

Flaky tests often guess at timing with arbitrary delays. This creates race conditions where tests pass on fast machines but fail under load or in CI.

**Core principle:** Wait for the actual condition you care about, not a guess about how long it takes.

## When to Use

**Decision flow:** Test uses setTimeout/sleep? → Testing actual timing behavior? → (yes: document WHY timeout needed) | (no: **use condition-based waiting**)

**Use when:** Arbitrary delays (`setTimeout`, `sleep`) | Flaky tests (pass sometimes, fail under load) | Timeouts in parallel runs | Async operation waits

**Don't use when:** Testing actual timing behavior (debounce, throttle) - document WHY if using arbitrary timeout

## Core Pattern

```typescript
// ❌ BEFORE: Guessing at timing
await new Promise(r => setTimeout(r, 50));
const result = getResult();
expect(result).toBeDefined();

// ✅ AFTER: Waiting for condition
await waitFor(() => getResult() !== undefined);
const result = getResult();
expect(result).toBeDefined();
```

## Quick Patterns

| Scenario | Pattern |
|----------|---------|
| Wait for event | `waitFor(() => events.find(e => e.type === 'DONE'))` |
| Wait for state | `waitFor(() => machine.state === 'ready')` |
| Wait for count | `waitFor(() => items.length >= 5)` |
| Wait for file | `waitFor(() => fs.existsSync(path))` |
| Complex condition | `waitFor(() => obj.ready && obj.value > 10)` |

## Implementation

**Generic polling:** `waitFor(condition, description, timeoutMs=5000)` - poll every 10ms, throw on timeout with clear message. See @example.ts for domain-specific helpers (`waitForEvent`, `waitForEventCount`, `waitForEventMatch`).

## Common Mistakes

| ❌ Bad | ✅ Fix |
|--------|--------|
| Polling too fast (`setTimeout(check, 1)`) | Poll every 10ms |
| No timeout (loop forever) | Always include timeout with clear error |
| Stale data (cache before loop) | Call getter inside loop for fresh data |

## When Arbitrary Timeout IS Correct

`await waitForEvent(...); await setTimeout(200)` - OK when: (1) First wait for triggering condition (2) Based on known timing, not guessing (3) Comment explaining WHY (e.g., "200ms = 2 ticks at 100ms intervals")

## Real-World Impact

Fixed 15 flaky tests across 3 files: 60% → 100% pass rate, 40% faster execution, zero race conditions.
