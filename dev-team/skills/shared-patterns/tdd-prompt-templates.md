# TDD Prompt Templates

Canonical source for TDD dispatch prompts used by dev-cycle and dev-implementation skills.

## TDD-RED Phase Prompt Template

```
**TDD-RED PHASE ONLY** for: [unit_id] - [title]

Requirements:
[requirements from task/subtask file]

Acceptance Criteria:
[acceptance_criteria]

**INSTRUCTIONS (TDD-RED):**
1. Write a failing test that captures the expected behavior
2. Run the test
3. **CAPTURE THE FAILURE OUTPUT** - this is MANDATORY

**STOP AFTER RED PHASE.** Do NOT write implementation code.

**REQUIRED OUTPUT:**
- Test file path
- Test function name
- **FAILURE OUTPUT** (copy/paste the actual test failure)

Example failure output:
```
=== FAIL: TestUserAuthentication (0.00s)
    auth_test.go:15: expected token to be valid, got nil
```
```

## TDD-GREEN Phase Prompt Template

```
**TDD-GREEN PHASE** for: [unit_id] - [title]

**CONTEXT FROM TDD-RED:**
- Test file: [tdd_red.test_file]
- Failure output: [tdd_red.failure_output]

**INSTRUCTIONS (TDD-GREEN):**
1. Write MINIMAL code to make the test pass
2. Run the test
3. **CAPTURE THE PASS OUTPUT** - this is MANDATORY
4. Refactor if needed (keeping tests green)
5. Commit

**OBSERVABILITY REQUIREMENTS (implement as part of the code):**
- Add structured JSON logging for all operations (info for success, error for failures)
- Add OpenTelemetry tracing spans for external calls and key operations
- Add metrics where applicable (request counts, latencies, business events)
- Ensure trace_id propagation in all log entries

**REQUIRED OUTPUT:**
- Implementation file path
- **PASS OUTPUT** (copy/paste the actual test pass)
- Files changed
- Observability added (logging: Y/N, tracing: Y/N, metrics: Y/N)
- Commit SHA

Example pass output:
```
=== PASS: TestUserAuthentication (0.003s)
PASS
ok      myapp/auth    0.015s
```
```

## HARD GATE Verifications

### After TDD-RED

```
IF failure_output is empty OR contains "PASS":
  → STOP. Cannot proceed. "TDD-RED incomplete - no failure output captured"
```

### After TDD-GREEN

```
IF pass_output is empty OR contains "FAIL":
  → Return to TDD-GREEN (retry implementation)
  → Max 3 retries, then STOP and report blocker
```

## Observability Requirements Summary

Backend agents MUST implement observability as part of the code:

| Component | Go Libraries | TypeScript Libraries |
|-----------|--------------|---------------------|
| **Logging** | `zerolog` or `zap` | `pino` or `winston` |
| **Tracing** | `go.opentelemetry.io/otel` | `@opentelemetry/sdk-node` |
| **Metrics** | `prometheus/client_golang` | `prom-client` |

**Gate 0 implements observability. Gate 2 (SRE) validates it.**

## How to Use

Skills should reference this file:

```markdown
## TDD Prompt Templates

See [shared-patterns/tdd-prompt-templates.md](../shared-patterns/tdd-prompt-templates.md) for:
- TDD-RED phase prompt template
- TDD-GREEN phase prompt template
- HARD GATE verifications
- Observability requirements
```
