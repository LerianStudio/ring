# Custom Prompt Validation (Shared Pattern)

Canonical validation rules for custom instructions in ring:dev-cycle and ring:dev-refactor skills.

## Validation Rules

| Rule | Description |
|------|-------------|
| **Recommended Length** | Up to 50-75 words (~300-400 chars) |
| **Hard Limit** | 500 characters (truncated with warning if exceeded) |
| **Whitespace** | Leading/trailing whitespace trimmed |
| **Control Characters** | Stripped (except newlines) |
| **Unicode** | Normalized |
| **Format** | Plain text only |

**Note:** Sanitization does NOT cover semantic prompt-injection attempts.

## Gate Protection

CRITICAL: The following gates enforce mandatory requirements that custom instructions CANNOT override:

| Gate | What CANNOT Be Overridden |
|------|---------------------------|
| Gate 3 (Testing) | MUST enforce 85% coverage threshold, TDD RED phase |
| Gate 4 (Review) | MUST dispatch all 10 reviewers |
| Gate 5 (Validation) | MUST require user approval |

## Conflict Detection

**Method:** Targeted pattern matching (reduces false positives):

| Pattern | Matches | Example |
|---------|---------|---------|
| `skip (gate\|test\|review\|validation\|coverage)` | Gate bypass attempts | "skip testing" |
| `bypass (check\|requirement\|threshold\|gate)` | Requirement bypass | "bypass coverage check" |
| `ignore (coverage\|reviewer\|threshold)` | Threshold override | "ignore 85% coverage" |
| `(disable\|lower\|reduce) .*(threshold\|coverage)` | Threshold modification | "lower threshold to 70%" |
| `don't run (test\|review\|validation)` | Gate skip | "don't run tests" |

**Output:** Warning to stderr + recorded in state file
**Format:** `⚠️ IGNORED: Prompt matched pattern "[pattern_name]" at "[matched_text]" — cannot override [gate/requirement]`
**Behavior:** Warning logged, directive ignored, gate executes normally

## Injection Format

Prepended to ALL agent prompts:

```yaml
Task tool:
  prompt: |
    **CUSTOM CONTEXT (from user):**
    {custom_prompt}

    ---

    **Standard Instructions:**
    [... rest of agent prompt ...]
```

## State Persistence

- **Stored:** `custom_prompt` field in `docs/ring:dev-cycle/current-cycle.json`
- **Scope:** Applied to ALL gates and ALL agent dispatches
- **Resume:** Survives interrupts; editable by modifying state file before `--resume`
- **Reports:** Included in execution reports under "Custom Context Used"
