# Prompt Engineering Reference

This document contains assertive language patterns for writing effective AI agent instructions that prevent rationalization and ensure compliance.

---

## Obligation & Requirement Words

| Word/Phrase | Usage | Example |
|-------------|-------|---------|
| **MUST** | Absolute requirement | "You MUST verify all categories" |
| **REQUIRED** | Mandatory action | "Standards compliance is REQUIRED" |
| **MANDATORY** | Non-optional | "MANDATORY: Read PROJECT_RULES.md first" |
| **SHALL** | Formal obligation | "Agent SHALL report all blockers" |
| **WILL** | Definite action | "You WILL follow this checklist" |
| **ALWAYS** | Every time, no exceptions | "ALWAYS check before proceeding" |

---

## Prohibition Words

| Word/Phrase | Usage | Example |
|-------------|-------|---------|
| **MUST NOT** | Absolute prohibition | "You MUST NOT skip verification" |
| **CANNOT** | Inability/prohibition | "You CANNOT proceed without approval" |
| **NEVER** | Zero tolerance | "NEVER assume compliance" |
| **FORBIDDEN** | Explicitly banned | "Using `any` type is FORBIDDEN" |
| **DO NOT** | Direct prohibition | "DO NOT make autonomous decisions" |
| **PROHIBITED** | Not allowed | "Skipping gates is PROHIBITED" |

---

## Enforcement Phrases

| Phrase | When to Use | Example |
|--------|-------------|---------|
| **HARD GATE** | Checkpoint that blocks progress | "HARD GATE: Verify standards before implementation" |
| **NON-NEGOTIABLE** | Cannot be changed or waived | "Security checks are NON-NEGOTIABLE" |
| **NO EXCEPTIONS** | Rule applies universally | "All agents MUST have this section. No exceptions." |
| **THIS IS NOT OPTIONAL** | Emphasize requirement | "Anti-rationalization tables - this is NOT optional" |
| **STOP AND REPORT** | Halt execution | "If blocker found → STOP and report" |
| **BLOCKING REQUIREMENT** | Prevents continuation | "This is a BLOCKING requirement" |

---

## Consequence Phrases

| Phrase | When to Use | Example |
|--------|-------------|---------|
| **If X → STOP** | Define halt condition | "If PROJECT_RULES.md missing → STOP" |
| **FAILURE TO X = Y** | Define consequences | "Failure to verify = incomplete work" |
| **WITHOUT X, CANNOT Y** | Define dependencies | "Without standards, cannot proceed" |
| **X IS INCOMPLETE IF** | Define completeness | "Agent is INCOMPLETE if missing sections" |

---

## Verification Phrases

| Phrase | When to Use | Example |
|--------|-------------|---------|
| **VERIFY** | Confirm something is true | "VERIFY all categories are checked" |
| **CONFIRM** | Get explicit confirmation | "CONFIRM compliance before proceeding" |
| **CHECK** | Inspect/examine | "CHECK for FORBIDDEN patterns" |
| **VALIDATE** | Ensure correctness | "VALIDATE output format" |
| **PROVE** | Provide evidence | "PROVE compliance with evidence, not assumptions" |

---

## Anti-Rationalization Phrases

| Phrase | Purpose | Example |
|--------|---------|---------|
| **Assumption ≠ Verification** | Prevent assuming | "Assuming compliance ≠ verifying compliance" |
| **Looking correct ≠ Being correct** | Prevent superficial checks | "Code looking correct ≠ code being correct" |
| **Partial ≠ Complete** | Prevent incomplete work | "Partial compliance ≠ full compliance" |
| **You don't decide X** | Remove AI autonomy | "You don't decide relevance. The checklist does." |
| **Your job is to X, not Y** | Define role boundaries | "Your job is to VERIFY, not to ASSUME" |

---

## Escalation Phrases

| Phrase | When to Use | Example |
|--------|---------|---------|
| **ESCALATE TO** | Define escalation path | "ESCALATE TO orchestrator if blocked" |
| **REPORT BLOCKER** | Communicate impediment | "REPORT BLOCKER and await user decision" |
| **AWAIT USER DECISION** | Pause for human input | "STOP. AWAIT USER DECISION on architecture" |
| **ASK, DO NOT GUESS** | Prevent assumptions | "When uncertain, ASK. Do not GUESS." |

---

## Template Patterns

### For Mandatory Sections

```markdown
## Section Name (MANDATORY)

**This section is REQUIRED. It is NOT optional. You MUST include this.**
```

### For Blocker Conditions

```markdown
**If [condition] → STOP. DO NOT proceed.**

Action: STOP immediately. Report blocker. AWAIT user decision.
```

### For Non-Negotiable Rules

```markdown
| Requirement | Cannot Override Because |
|-------------|------------------------|
| **[Rule]** | [Reason]. This is NON-NEGOTIABLE. |
```

### For Anti-Rationalization Tables

```markdown
| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "[Excuse]" | [Why incorrect]. | **[MANDATORY action]** |
```

---

## Code Transformation Context (CTC) Format

When documenting refactoring issues, agents MUST provide a Code Transformation Context block for EACH non-compliant issue. This gives execution agents exact before/after code context.

### Required Elements Checklist

For EACH issue, output MUST include:

- [ ] **Before (Current Code)** - Actual code extracted from the project with `file:line` reference
- [ ] **After (Ring Standards)** - Transformed code following Ring/Lerian standards
- [ ] **Standard References table** - Pattern, Source file, Section name, Line range
- [ ] **Why This Transformation Matters** - Problem, Standard violated, Impact

### Template Structure

```markdown
## Code Transformation Context: ISSUE-XXX

### Before (Current Code)
```{language}
// file: {path}:{start_line}-{end_line}
{actual code from project}
```

### After (Ring Standards)
```{language}
// file: {path}:{start_line}-{new_end_line}
// ✅ Ring Standard: {Pattern Name} ({standards_file}:{section})
{transformed code using lib-commons patterns}
```

### Standard References
| Pattern Applied | Source | Section | Line Range |
|-----------------|--------|---------|------------|
| {pattern} | `{file}.md` | {Section Title} | :{derive_at_runtime} |

### Why This Transformation Matters
- **Problem:** {current issue}
- **Ring Standard:** {which standard violated}
- **Impact:** {business/technical impact}
```

### Line Range Derivation (MANDATORY)

**⛔ DO NOT hardcode line numbers.** Standards files change over time.

**REQUIRED:** Derive exact `:{line_range}` values at runtime by:
1. Reading the current standards file (e.g., `golang.md`, `typescript.md`)
2. Searching for the relevant section header
3. Citing the actual line numbers from the live file

**Example derivation:**
```
Agent reads golang.md → Finds "## Configuration Loading" at line 99
Agent cites: "Configuration Loading (golang.md:99-230)"
```

### Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Comparison table is enough" | Table = WHAT. Context = HOW. Both REQUIRED. | **Add CTC block** |
| "I'll describe the change" | Description ≠ executable context | **Show actual code** |
| "Standards are obvious" | Obvious to you ≠ obvious to executor | **Include Standard References** |
| "One example is enough" | Each issue needs its OWN context | **Add CTC for EACH issue** |

---

## Key Principle

The more assertive and explicit the language, the less room for AI to rationalize, assume, or make autonomous decisions. Strong language creates clear boundaries.

---

## Related Documents

- [CLAUDE.md](../CLAUDE.md) - Main project instructions (references this document)
- [AGENT_DESIGN.md](AGENT_DESIGN.md) - Agent output schemas and requirements
