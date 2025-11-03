# Review Orchestrator Integration Test

## Purpose

Validate that review-orchestrator correctly:
1. Invokes gates sequentially
2. Stops at first failure
3. Creates shared state
4. Returns consolidated report

## Test Case 1: All Gates Pass

**Setup:**
Create clean test file with no issues:

`test-files/clean-code.ts`
```typescript
export function add(a: number, b: number): number {
  return a + b;
}
```

**Execute:**
Invoke review-orchestrator on this file

**Expected:**
- Gate 1: PASS
- Gate 2: PASS
- Gate 3: PASS
- Consolidated verdict: PASS
- State file contains all 3 gates

**Verification:**
```bash
cat .ring/review-state.json | jq '.gates | keys'
# Expected: ["gate_1", "gate_2", "gate_3"]

cat .ring/review-state.json | jq '.gates.gate_1.verdict'
# Expected: "PASS"
```

## Test Case 2: Gate 1 Fails

**Setup:**
Create test file with code quality issues:

`test-files/bad-code.ts`
```typescript
function x(y: any) {
  const z = y + 5;
  return z;
}
```

**Execute:**
Invoke review-orchestrator on this file

**Expected:**
- Gate 1: FAIL (poor naming, any type, no error handling)
- Gate 2: NOT RUN (stopped at Gate 1)
- Gate 3: NOT RUN
- Consolidated verdict: FAIL
- State file contains only gate_1

**Verification:**
```bash
cat .ring/review-state.json | jq '.gates | keys'
# Expected: ["gate_1"] (NOT gate_2 or gate_3)

cat .ring/review-state.json | jq '.failed_at_gate'
# Expected: 1
```

## Test Case 3: Gate 1 Passes, Gate 2 Fails

**Setup:**
Create well-structured code with business logic error:

`test-files/business-error.ts`
```typescript
// Well-structured but wrong business logic
export async function cancelOrder(orderId: string): Promise<void> {
  const order = await orderRepo.findById(orderId);

  // BUG: Can cancel any status (should only allow Pending/Confirmed)
  order.status = OrderStatus.Cancelled;
  await orderRepo.save(order);

  // BUG: No refund logic
}
```

**Expected:**
- Gate 1: PASS (code quality is fine)
- Gate 2: FAIL (missing business rules)
- Gate 3: NOT RUN
- Consolidated verdict: FAIL
- State file has gate_1 and gate_2

## Success Criteria

All 3 test cases pass as expected:
- ✅ Sequential execution verified
- ✅ Stop-on-fail verified
- ✅ State persistence verified
- ✅ Consolidated report generated
