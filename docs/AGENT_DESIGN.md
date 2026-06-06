# Agent Design Reference

This document contains agent output format archetypes and standards compliance requirements for Ring agents.

---

## Agent Output Format Archetypes

Agents document their output structure in a body `## Output Format` section (not in frontmatter — `output_schema` is no longer a recognized frontmatter field). The archetypes below describe the canonical body sections each agent type MUST produce.

### Implementation Archetype

**For agents that write code/configs:**

The agent's body `## Output Format` section MUST instruct the agent to produce these top-level markdown sections:

- `## Summary`
- `## Implementation`
- `## Files Changed`
- `## Testing`
- `## Next Steps`

**Used by:** `ring:backend-go`, `ring:backend-ts`, `ring:bff-ts`

---

### Analysis Archetype

**For agents that analyze and recommend:**

The agent's body `## Output Format` section MUST instruct the agent to produce:

- `## Analysis`
- `## Findings`
- `## Recommendations`
- `## Next Steps`

**Used by:** `ring:ui-designer`

---

### Reviewer Archetype

**For code review agents:**

The agent's body `## Output Format` section MUST instruct the agent to produce:

- `## VERDICT: PASS | FAIL | NEEDS_DISCUSSION` (heading line carries the verdict)
- `## Summary`
- `## Issues Found` (with optional `### Critical | High | Medium | Low` subsections)
- `## Standards Compliance Report`
- `## Next Steps`

**Used by:** `ring:code-reviewer`, `ring:logic-reviewer`, `ring:security-reviewer`, `ring:test-reviewer`, `ring:nil-reviewer`, `ring:dead-code-reviewer`, `ring:perf-reviewer`, `ring:tenancy-reviewer`, `ring:commons-reviewer`, `ring:obs-reviewer`, `ring:systemplane-reviewer`, `ring:streaming-reviewer`

**Verdict contract:** `PASS` is allowed only with zero eligible findings. Any eligible issue means `FAIL`. Missing context means `NEEDS_DISCUSSION`. Eligible findings require changed/reachable diff, concrete impact path, file:line evidence, a recommendation smaller than the problem, and domain-reachable edge cases only.

**Note:** `ring:logic-reviewer` and `ring:security-reviewer` extend the base Reviewer archetype with additional domain-specific sections:
- `ring:logic-reviewer` adds: `## Mental Execution Analysis`, `## Business Requirements Coverage`, `## Edge Cases Analysis`
- `ring:security-reviewer` adds: `## OWASP Top 10 Coverage`, `## Compliance Status`

---

### Exploration Archetype

**For deep codebase analysis:**

The agent's body `## Output Format` section MUST instruct the agent to produce:

- `## EXPLORATION SUMMARY`
- `## KEY FINDINGS`
- `## ARCHITECTURE INSIGHTS`
- `## RELEVANT FILES`
- `## RECOMMENDATIONS`

**Used by:** `ring:codebase-explorer`

---

### Planning Archetype

**For implementation planning:**

The agent's body `## Output Format` section MUST instruct the agent to produce:

- `**Goal:**` line
- `**Architecture:**` line
- `**Tech Stack:**` line
- `**Global Prerequisites:**` line
- One `### Task N:` heading per task

**Used by:** `ring:writing-plans`

---

## Standards Compliance (Conditional Output Section)

The `ring-dev-team` agents include a **Standards Compliance** output section that is conditionally required based on invocation context.

### Schema Definition

All ring-dev-team agents document a `## Standards Compliance` section in their body `## Output Format`:

- Section name: `## Standards Compliance`
- Required: optional by default; MANDATORY when invoked from `ring:planning-backend-refactor`
- Purpose: comparison of codebase against Lerian/Ring standards

### Conditional Requirement: `invoked_from_dev_refactor`

| Context | Standards Compliance Required | Enforcement |
|---------|------------------------------|-------------|
| Direct agent invocation | Optional | Agent may include if relevant |
| Via `ring:running-dev-cycle` | Optional | Agent may include if relevant |
| Via `ring:planning-backend-refactor` | **MANDATORY** | Prompt includes `MODE: ANALYSIS ONLY` |

**How It's Triggered:**
1. User invokes `/ring:planning-backend-refactor` command
2. The skill dispatches agents with prompts starting with `**MODE: ANALYSIS ONLY**`
3. This prompt pattern signals to agents that Standards Compliance output is MANDATORY
4. Agents load Ring standards via WebFetch and produce comparison tables

**Detection in Agent Prompts:**
```text
If prompt contains "**MODE: ANALYSIS ONLY**":
  → Standards Compliance section is MANDATORY
  → Agent MUST load Ring standards via WebFetch
  → Agent MUST produce comparison tables

If prompt does NOT contain "**MODE: ANALYSIS ONLY**":
  → Standards Compliance section is optional
  → Agent focuses on implementation/other tasks
```

### Affected Agents

All ring-dev-team agents support Standards Compliance:

| Agent | Standards Source | Categories Checked |
|-------|------------------|-------------------|
| `ring:backend-go` | `golang.md` | lib-commons, Error Handling, Logging, Config |
| `ring:backend-ts` | `typescript.md` | Type Safety, Error Handling, Validation |
| `ring:bff-ts` | `frontend.md` | Component patterns, State management |
| `ring:ui-designer` | `frontend.md` | Accessibility, Design patterns |

Backend dev-cycle note: Go/TypeScript backend engineers own docker-compose/local runtime, coverage, TDD evidence, and basic health/observability checks during Gate 0. QA/SRE/DevOps specialists are not part of the active backend dev-cycle.

### Output Format Examples

**When ALL categories are compliant:**
```markdown
## Standards Compliance

Fully Compliant - Codebase follows all Lerian/Ring Standards.

No migration actions required.
```

**When ANY category is non-compliant:**
```markdown
## Standards Compliance

### Lerian/Ring Standards Comparison

| Category | Current Pattern | Expected Pattern | Status | File/Location |
|----------|----------------|------------------|--------|---------------|
| Error Handling | Using panic() | Return error | Non-Compliant | handler.go:45 |
| Logging | Uses fmt.Println | lib-observability/zap | Non-Compliant | service/*.go |
| Config | os.Getenv direct | SetConfigFromEnvVars() | Non-Compliant | config.go:15 |

### Compliance Summary
- **Total Violations:** 3
- **Critical:** 0
- **High:** 1
- **Medium:** 2
- **Low:** 0

### Required Changes for Compliance

1. **Error Handling Migration**
   - Replace: `panic("error message")`
   - With: `return fmt.Errorf("context: %w", err)`
   - Files affected: handler.go, service.go

2. **Logging Migration**
   - Replace: `fmt.Println("debug info")`
   - With: `logger.Info("debug info", zap.String("key", "value"))`
   - Import: `import "github.com/LerianStudio/lib-observability/zap"`
   - Files affected: internal/service/*.go
```

### Cross-References

| Document | Location | What It Contains |
|----------|----------|-----------------|
| **Skill Definition** | `dev-team/skills/planning-backend-refactor/SKILL.md` | HARD GATES requiring Standards Compliance |
| **Standards Source** | `dev-team/docs/standards/*.md` | Source of truth for compliance checks |
| **Agent Definitions** | `dev-team/agents/*.md` | Body `## Output Format` section documents Standards Compliance |
| **Session Hook** | `dev-team/hooks/session-start.sh` | Injects Standards Compliance guidance |

---

## Related Documents

- [CLAUDE.md](../CLAUDE.md) - Main project instructions (references this document)
- [PROMPT_ENGINEERING.md](PROMPT_ENGINEERING.md) - Language patterns for agent prompts
- [WORKFLOWS.md](WORKFLOWS.md) - How to add/modify agents

---

## Positive Example Blocks (Replaces Anti-Rationalization Tables)

**Anti-rationalization tables are no longer mandatory.** Based on Anthropic's research, positive `<example>` blocks showing correct behavior outperform prohibition-based tables.

**Why the pattern changed:**
Positive examples outperform prohibitions in prompt design. Telling a model what to do correctly — with a concrete example — is more effective than enumerating what it must not rationalize. Long anti-rationalization tables also increase prompt length without proportional benefit, and can inadvertently prime models to consider the wrong patterns.

**The new `<example>` pattern:**

Instead of a "Rationalization / Why It's WRONG / Required Action" table, agents should include a positive example block that demonstrates the correct behavior:

```markdown
<example>
Scenario: You are asked to implement an endpoint but the task lacks acceptance criteria.

Correct behavior:
1. STOP before writing any code
2. Report to orchestrator: "Blocker: Missing acceptance criteria for [endpoint]. Cannot proceed."
3. Wait for clarification — do not guess or assume

Incorrect behavior:
- Inferring acceptance criteria from context and proceeding
- Writing "placeholder" code "just to get started"
- Asking the user directly instead of reporting to orchestrator
</example>
```

**Mandatory Sections Every Agent MUST Have:**

| Section              | Purpose                        | Language Requirements                      |
| -------------------- | ------------------------------ | ------------------------------------------ |
| **Blocker Criteria** | Define when to STOP and report | Use "STOP", "CANNOT proceed", "HARD BLOCK" |
| **`<example>` block** | Show correct behavior          | Positive scenario with correct vs wrong    |

See [docs/PROMPT_ENGINEERING.md](PROMPT_ENGINEERING.md) for language guidelines (Lexical Salience, enforcement word positioning).

---

## Agent Modification Verification (MANDATORY)

**HARD GATE: Before creating or modifying any agent file, MUST verify compliance with this checklist.**

**Step 1: Verify Agent Has All Required Sections**

| Required Section                              | Pattern to Check                 | If Missing                                                        |
| --------------------------------------------- | -------------------------------- | ----------------------------------------------------------------- |
| **Standards Loading (MANDATORY)**             | `## Standards Loading`           | MUST add with `index.md` + selective module loading instructions |
| **Blocker Criteria - STOP and Report**        | `## Blocker Criteria`            | MUST add with decision type table                                 |
| **Positive `<example>` block**                | `<example>`                      | MUST add at least one block showing correct vs incorrect behavior |
| **Standards Compliance Report** (dev-team)    | `## Standards Compliance Report` | MUST add for dev-team agents                                      |
| **Output Format**                             | `## Output Format`               | MUST add body output schema                                        |

**Step 2: Pre-Completion Checklist**

```text
CHECKLIST (all must be YES):
[ ] Does agent have Standards Loading section referencing index.md?
[ ] Does agent have Blocker Criteria table?
[ ] Does agent have at least one positive <example> block?
[ ] Does agent define when to STOP and report?
[ ] Is agent within line budget: ≤300 lines (implementation) or ≤200 lines (reviewer)?

If any checkbox is no → Agent is INCOMPLETE. Add missing sections.
```

**This verification is not optional. This is a HARD GATE for all agent modifications.**
