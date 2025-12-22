# TDD Prompt Templates

Canonical source for TDD dispatch prompts used by dev-cycle and dev-implementation skills.

## Standards Loading (MANDATORY - Before TDD)

**Before dispatching any TDD phase, the agent MUST load:**

1. **Ring Standards** (MANDATORY) → Base technical patterns (architecture, error handling, logging, testing)
2. **PROJECT_RULES.md** (COMPLEMENTARY) → Project-specific choices (which DB, internal libs, naming conventions)

**Priority:** Ring Standards define HOW to implement. PROJECT_RULES.md defines WHAT the project uses.

See [standards-workflow.md](./standards-workflow.md) for the complete loading process.

## TDD-RED Phase Prompt Template

```
**TDD-RED PHASE ONLY** for: [unit_id] - [title]

**MANDATORY:** WebFetch Ring Standards for your language FIRST (see standards-workflow.md)

**Requirements:**
[requirements from task/subtask file]

**Acceptance Criteria:**
[acceptance_criteria]

**PROJECT CONTEXT (if PROJECT_RULES.md exists):**
[Insert relevant project-specific info: tech stack, internal libs, conventions]

**INSTRUCTIONS (TDD-RED):**
1. Follow Ring Standards for test structure and patterns
2. Write a failing test that captures the expected behavior
3. Run the test
4. **CAPTURE THE FAILURE OUTPUT** - this is MANDATORY

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

**MANDATORY:** WebFetch Ring Standards for your language FIRST (see standards-workflow.md)

**CONTEXT FROM TDD-RED:**
- Test file: [tdd_red.test_file]
- Failure output: [tdd_red.failure_output]

**PROJECT CONTEXT (if PROJECT_RULES.md exists):**
[Insert relevant project-specific info: tech stack, internal libs, conventions]

**INSTRUCTIONS (TDD-GREEN):**
1. Follow Ring Standards for architecture, error handling, and patterns
2. Write MINIMAL code to make the test pass
3. Apply project-specific conventions from PROJECT_RULES.md (if exists)
4. Run the test
5. **CAPTURE THE PASS OUTPUT** - this is MANDATORY
6. Refactor if needed (keeping tests green)
7. Commit

**RING STANDARDS REQUIREMENTS (MANDATORY):**
- Follow architecture patterns from Ring Standards (Hexagonal, Clean Architecture, etc.)
- Implement proper error handling (no panic, wrap errors with context)
- Add structured JSON logging for all operations
- Add OpenTelemetry tracing spans for external calls and key operations
- Ensure trace_id propagation in all log entries

**PROJECT-SPECIFIC (from PROJECT_RULES.md, if exists):**
- Use internal libraries referenced in PROJECT_RULES.md
- Follow project-specific naming conventions (if different from Ring Standards)
- Use tech stack choices defined in PROJECT_RULES.md (database, frameworks, etc.)

**REQUIRED OUTPUT:**
- Implementation file path
- **PASS OUTPUT** (copy/paste the actual test pass)
- Files changed
- Ring Standards followed: Y/N
- Observability added (logging: Y/N, tracing: Y/N)
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

## Standards Priority Summary

### Ring Standards (MANDATORY - Base patterns)

| What | Source | Defines |
|------|--------|---------|
| **Architecture patterns** | Ring Standards | Hexagonal, Clean Architecture, DDD |
| **Error handling** | Ring Standards | No panic, wrap with context |
| **Logging** | Ring Standards | Structured JSON (zerolog/zap or pino/winston) |
| **Tracing** | Ring Standards | OpenTelemetry spans, trace_id propagation |
| **Testing patterns** | Ring Standards | Table-driven tests, mocking |

### PROJECT_RULES.md (COMPLEMENTARY - Project specifics NOT in Ring Standards)

| What | Source | Defines |
|------|--------|---------|
| **Tech stack choices** | PROJECT_RULES.md | Which DB, which framework, which cache |
| **Internal libraries** | PROJECT_RULES.md | lib-commons, shared packages |

**Priority:** Ring Standards > PROJECT_RULES.md (project can add, not remove standards)

**Gate 0 implements standards + observability. Gate 2 (SRE) validates observability.**

## How to Use

Skills should reference this file:

```markdown
## TDD Prompt Templates

See [shared-patterns/template-tdd-prompts.md](../shared-patterns/template-tdd-prompts.md) for:
- TDD-RED phase prompt template
- TDD-GREEN phase prompt template
- HARD GATE verifications
- Observability requirements
```
