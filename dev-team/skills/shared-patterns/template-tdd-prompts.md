# TDD Prompt Templates

Canonical source for TDD dispatch prompts used by dev-cycle and dev-implementation skills.

## Standards Loading (MANDATORY - Before TDD)

**Before dispatching any TDD phase, the agent MUST load:**

1. **Ring Standards** (MANDATORY) → Base technical patterns (architecture, error handling, logging, testing)
2. **PROJECT_RULES.md** (COMPLEMENTARY) → Project-specific info NOT in Ring Standards

**Priority:** Ring Standards define HOW to implement. PROJECT_RULES.md defines project-specific context only.

See [standards-workflow.md](./standards-workflow.md) for the complete loading process.

### What Each Source Provides (NO OVERLAP)

| Source | Provides | Examples |
|--------|----------|----------|
| **Ring Standards** | Technical patterns | Error handling, logging, testing, architecture, lib-commons, API structure |
| **PROJECT_RULES.md** | Project-specific only | External APIs, non-standard dirs, domain terminology, tech not in Ring |

**⛔ PROJECT_RULES.md MUST NOT duplicate Ring Standards content.**

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
7. **VERIFY STANDARDS COMPLIANCE** - Complete the checklist below
8. Commit

**⛔ RING STANDARDS REQUIREMENTS (MANDATORY - ALL MUST BE IMPLEMENTED):**

**You MUST WebFetch and implement ALL sections from Ring Standards for your language:**
- **Go:** `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md`
- **TypeScript:** `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md`

**⛔ HARD GATE: You MUST implement ALL sections listed in [standards-coverage-table.md](../shared-patterns/standards-coverage-table.md).**

- **Go projects:** See `backend-engineer-golang → golang.md` section index (20 sections)
- **TypeScript projects:** See `backend-engineer-typescript → typescript.md` section index (13 sections)

**You CANNOT skip ANY section. Mark N/A only with explicit justification.**

**PROJECT-SPECIFIC (from PROJECT_RULES.md, if exists):**
- Use internal libraries referenced in PROJECT_RULES.md
- Follow project-specific naming conventions (if different from Ring Standards)
- Use tech stack choices defined in PROJECT_RULES.md (database, frameworks, etc.)

**⛔ REQUIRED OUTPUT (HARD GATE - ALL SECTIONS MANDATORY):**

## Implementation Summary
- Implementation file path: [path]
- Files changed: [list]
- Commit SHA: [sha]

## Test Results
**PASS OUTPUT** (copy/paste the actual test pass):
```
[paste actual output here]
```

## Standards Coverage Table

**You MUST output a Standards Coverage Table per [shared-patterns/standards-coverage-table.md](../shared-patterns/standards-coverage-table.md).**

**Format:**
```
| # | Section (from standards-coverage-table.md) | Status | Evidence |
|---|-------------------------------------------|--------|----------|
| 1 | [Section Name] | ✅/❌ | [file:line] |
| ... | ... | ... | ... |
```

**Status Legend:**
- ✅ Implemented - Code follows this standard (with file:line evidence)
- ❌ Not Implemented - Missing or incorrect (BLOCKS proceeding)
- N/A - Not applicable (with reason)

## Compliance Summary
- **ALL STANDARDS MET:** ✅ YES / ❌ NO
- **If NO, what's missing:** [list missing items with section names]

**⛔ IF "ALL STANDARDS MET" = NO → Implementation is INCOMPLETE. Fix before proceeding.**

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

IF "ALL STANDARDS MET" = NO:
  → STOP. Cannot proceed to Gate 1.
  → Re-dispatch to same agent with fix request:
    "Fix missing standards: [list from compliance checklist]"
  → Max 3 retries, then STOP and report blocker
```

### Standards Compliance Verification (HARD GATE)

**The orchestrator MUST verify the agent's Standards Coverage Table before proceeding:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  GATE 0 COMPLETION CHECK                                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Parse agent output for "## Standards Coverage Table"                    │
│  2. Verify table has ALL sections from standards-coverage-table.md          │
│  3. Check "ALL STANDARDS MET" value in Compliance Summary                   │
│                                                                             │
│  IF "ALL STANDARDS MET: ✅ YES" AND all sections have ✅ or N/A:            │
│    → Gate 0 PASSED. Proceed to Gate 1 (DevOps)                              │
│                                                                             │
│  IF ANY section has ❌:                                                      │
│    → Gate 0 BLOCKED. Standards not implemented.                             │
│    → Extract ❌ sections from Standards Coverage Table                       │
│    → Re-dispatch to SAME agent with fix request:                            │
│                                                                             │
│      Task tool:                                                             │
│        subagent_type: "[same agent that did TDD-GREEN]"                     │
│        model: "opus"                                                        │
│        description: "Fix missing Ring Standards for [unit_id]"              │
│        prompt: |                                                            │
│          ⛔ FIX REQUIRED - Ring Standards Not Implemented                   │
│                                                                             │
│          Your Standards Coverage Table shows these sections as ❌:          │
│          [list ❌ sections from table]                                       │
│                                                                             │
│          WebFetch the standards again:                                      │
│          [URL for language-specific standards]                              │
│                                                                             │
│          Implement ALL missing sections.                                    │
│          Return updated Standards Coverage Table with ALL ✅ or N/A.        │
│                                                                             │
│    → After fix: Re-verify Standards Coverage Table                          │
│    → Max 3 iterations, then STOP and escalate to user                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Anti-Rationalization for Standards Compliance

See [shared-patterns/standards-coverage-table.md](../shared-patterns/standards-coverage-table.md) for the complete anti-rationalization table.

**Key rules:**
- ALL sections from standards-coverage-table.md MUST be checked
- ❌ on ANY section = BLOCKED (dispatch fix to same agent)
- N/A requires explicit reason
- Evidence (file:line) REQUIRED for all ✅ items

## Standards Priority Summary

### Ring Standards (MANDATORY - Base patterns)

| What | Source | Defines |
|------|--------|---------|
| **Architecture patterns** | Ring Standards | Hexagonal, Clean Architecture, DDD |
| **Error handling** | Ring Standards | No panic, wrap with context |
| **Logging** | Ring Standards | Structured JSON (zerolog/zap or pino/winston) |
| **Tracing** | Ring Standards | OpenTelemetry spans, trace_id propagation |
| **Testing patterns** | Ring Standards | Table-driven tests, mocking |

### PROJECT_RULES.md (COMPLEMENTARY - ONLY What Ring Does NOT Cover)

| What | Source | Defines |
|------|--------|---------|
| **Tech stack not in Ring** | PROJECT_RULES.md | Specific message broker, cache, DB if not PostgreSQL |
| **Non-standard directories** | PROJECT_RULES.md | Workers, consumers, polling (not standard API structure) |
| **External integrations** | PROJECT_RULES.md | Third-party APIs, webhooks, external services |
| **Domain terminology** | PROJECT_RULES.md | Technical names of entities/classes in this codebase |

**⛔ PROJECT_RULES.md MUST NOT contain:**
- Error handling patterns (Ring covers this)
- Logging standards (Ring covers this)
- Testing patterns (Ring covers this)
- Architecture patterns (Ring covers this)
- lib-commons usage (Ring covers this)
- Business rules (belongs in PRD/product docs)

**Priority:** Ring Standards > PROJECT_RULES.md (project adds context, not patterns)

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
