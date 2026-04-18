# Prompt Engineering Reference

This document contains lexical salience patterns for writing effective AI agent instructions. The key principle: **selective emphasis creates focus** - when too many words are capitalized, none stand out.

---

## Lexical Salience Principle

| Approach | Effectiveness | Why |
|----------|---------------|-----|
| Few CAPS words at sentence START | HIGH | AI attention focuses on critical instructions |
| Many CAPS words scattered throughout | LOW | Salience dilution - everything emphasized = nothing emphasized |

**Rule:** Place enforcement words at the BEGINNING of instructions, not in the middle or end.

---

## Enforcement Words (Use Sparingly, at Beginning)

| Word | Purpose | Correct Usage |
|------|---------|---------------|
| **MUST** | Primary requirement | "MUST verify before proceeding" |
| **REQUIRED** | Mandatory action | "REQUIRED: Load standards first" |
| **MANDATORY** | Section marker | "MANDATORY: Initialize todo list" |
| **STOP** | Halt execution | "STOP and report blocker" |
| **HARD GATE** | Critical checkpoint | "HARD GATE: Cannot proceed without..." |
| **CANNOT** | Prohibition | "CANNOT skip this gate" |
| **FORBIDDEN** | Explicitly banned | "FORBIDDEN: Direct code editing" |

---

## Words to Keep Lowercase (Context Words)

These provide context but dilute emphasis when capitalized:

| Avoid | Use Instead |
|-------|-------------|
| ~~ALL~~ | all |
| ~~ANY~~ | any |
| ~~ONLY~~ | only |
| ~~EACH~~ | each |
| ~~EVERY~~ | every |
| ~~NOT~~ | not (except in "MUST NOT") |
| ~~NO~~ | no |
| ~~AND~~ | and |
| ~~OR~~ | or |
| ~~IF~~ | if |
| ~~NEVER~~ | use "MUST NOT" instead |
| ~~ALWAYS~~ | use "MUST" instead |

---

## Positioning Examples

| Position | Effectiveness | Example |
|----------|---------------|---------|
| **Beginning** | HIGH | "MUST verify all sections before proceeding" |
| Middle | LOW | "You should verify all sections, this is MUST" |
| End | LOW | "Verify all sections before proceeding, MUST" |

---

## Transformation Examples

| Before (Diluted) | After (Focused) |
|------------------|-----------------|
| "You MUST check ALL sections" | "MUST check all sections" |
| "NEVER skip ANY gate" | "MUST NOT skip any gate" |
| "This is MANDATORY for EVERY task" | "MANDATORY: This applies to every task" |
| "ALWAYS verify BEFORE proceeding" | "MUST verify before proceeding" |
| "Check IF this CONDITION is met" | "MUST check if this condition is met" |
| "ALL agents MUST have this" | "MANDATORY: All agents must have this" |

---

## Sentence Structure Pattern

```
[ENFORCEMENT WORD]: [Action/Instruction] [Context]

Examples:
- MUST dispatch agent before proceeding to next gate
- STOP and report if PROJECT_RULES.md is missing
- HARD GATE: All 10 reviewers must pass before Gate 5
- FORBIDDEN: Reading source code directly as orchestrator
- REQUIRED: WebFetch Ring standards before implementation
- MANDATORY: Save state after every gate transition
```

---

## Strategic Spacing (Attention Reset)

**Spacing matters for AI attention.** When multiple critical rules appear in sequence, add blank lines between sections to allow "attention reset" - each section gets its own salient word.

| Pattern | Effectiveness | Why |
|---------|---------------|-----|
| Blank line between rule groups | HIGH | Attention "resets" between sections |
| Dense continuous text | LOW | Critical words blur together |

### Example - Strategic Spacing

```markdown
## Authentication

Handle auth tokens according to existing patterns.
Validate JWT signatures on every request.
NEVER log sensitive credentials.

## Data Access

Use repository pattern for all queries.
Implement pagination for list endpoints.
CRITICAL: All mutations must be idempotent.

## Error Handling

Wrap errors with context.
Map internal errors to HTTP codes.
NEVER expose stack traces to clients.
```

**Why this works:**
- Each section has ONE salient word (NEVER, CRITICAL, NEVER)
- Blank lines create visual and semantic boundaries
- AI attention focuses on one rule group at a time
- The enforcement word in each section stands out

### Anti-Pattern - Dense Text

```markdown
## Rules
Handle auth tokens. Validate JWT. NEVER log credentials. Use repository pattern. CRITICAL: mutations idempotent. Wrap errors. NEVER expose stacks.
```

**Why this fails:** Three CAPS words in one dense block - none stands out.

**Rule:** When writing multiple critical rules, space them into logical groups with blank lines between.

---

## Consequence Phrases

| Phrase | When to Use | Example |
|--------|-------------|---------|
| **→ STOP** | Define halt condition | "If PROJECT_RULES.md missing → STOP" |
| **= FAIL** | Define failure | "Missing verification = FAIL" |
| **is incomplete** | Define completeness | "Agent is incomplete if missing sections" |

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

## Task Tool Invocation (Agent Dispatch)

When a skill or workflow needs to dispatch an agent, the **Task tool MUST be used explicitly**. Agent dispatch is NOT implicit - if the Task tool is not called, no agent is dispatched.

### Why Explicit Invocation Is Required

| Implicit (WRONG) | Explicit (CORRECT) |
|------------------|-------------------|
| Describing what agent should do | Using Task tool to dispatch agent |
| YAML-like templates without tool call | Task tool with exact parameters |
| "The agent will analyze..." | "Use Task tool to dispatch agent" |
| Agent runs automatically | Agent runs ONLY when Task tool called |

**If Task tool NOT used → Agent NOT dispatched → SKILL FAILURE**

### Template Structure

When documenting agent dispatch in skills, use this explicit format:

```markdown
### Explicit Tool Invocation (MANDATORY)

**⛔ You MUST use the Task tool to dispatch [agent-name]. This is NOT implicit.**

```text
Action: Use Task tool with EXACTLY these parameters:

┌─────────────────────────────────────────────────────────────────────────────────┐
│  Task tool parameters:                                                          │
│                                                                                 │
│  subagent_type: "[fully-qualified-agent-name]"                                  │
│  description: "[short description]"                                             │
│  prompt: [See prompt template below]                                            │
│                                                                                 │
│  ⛔ If Task tool NOT used → [artifact] does NOT exist → SKILL FAILURE           │
└─────────────────────────────────────────────────────────────────────────────────┘

VERIFICATION: After Task completes, confirm agent returned output before proceeding
```

### If Task Tool NOT Used → SKILL FAILURE

Agent is NOT dispatched → No output generated → All subsequent steps produce INVALID output.
```

### Required Elements

| Element | Required? | Purpose |
|---------|-----------|---------|
| **"Use Task tool"** | ✅ YES | Explicit tool instruction |
| **subagent_type** | ✅ YES | Fully qualified agent name |
| **description** | ✅ YES | Short task description |
| **prompt** | ✅ YES | Instructions for the agent |
| **SKILL FAILURE warning** | ✅ YES | Consequence of not using tool |
| **VERIFICATION step** | ✅ YES | Confirm output before proceeding |

### Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Template implies Task tool" | Implication ≠ instruction. Be explicit. | **Write "Use Task tool"** |
| "Agent dispatch is obvious" | Obvious to you ≠ obvious to executor | **Add explicit parameters** |
| "I described what agent does" | Description ≠ invocation | **Call Task tool explicitly** |
| "Previous steps used Task tool" | Each dispatch is independent | **Explicit for EACH agent** |

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

## Semantic Block Tags (Recognition Patterns)

**Use XML-like tags to create recognizable blocks for critical instructions.** Tags create semantic boundaries that AI models recognize as structured blocks requiring special attention.

| Tag | Purpose | AI Behavior |
|-----|---------|-------------|
| `<fetch_required>` | URLs to load before task | WebFetch all URLs first |
| `<block_condition>` | Blocker triggers | STOP if any condition true |
| `<forbidden>` | Prohibited actions | Reject if detected |
| `<dispatch_required>` | Single agent invocation | Use Task tool with specified agent |
| `<parallel_dispatch>` | Multiple agents in parallel | Dispatch all listed agents simultaneously |
| `<verify_before_proceed>` | Pre-conditions | Check all before continuing |
| `<output_required>` | Mandatory output sections | Include in response |
| `<cannot_skip>` | Non-negotiable steps | No exceptions allowed |
| `<user_decision>` | Requires user input | Wait for explicit response |

### Example Usage

```markdown
## Required Resources

<fetch_required>
https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md
https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md
</fetch_required>

MUST fetch all URLs above before starting the task.

---

<block_condition>
- PROJECT_RULES.md not found
- Coverage below 85%
- Any reviewer returns FAIL
</block_condition>

If any condition is true, STOP immediately and report blocker.

---

<forbidden>
- fmt.Println() in Go code
- console.log() in TypeScript
- Direct source code editing by orchestrator
</forbidden>

Any occurrence = IMMEDIATE REJECTION.

---

<dispatch_required agent="ring:backend-engineer-golang">
Implement user authentication endpoint with JWT validation.
</dispatch_required>

MUST use Task tool with specified agent.

---

<parallel_dispatch agents="ring:backend-engineer-golang, ring:qa-analyst, ring:devops-engineer, ring:sre">
Analyze codebase against Ring standards. All agents receive same context:
- Codebase Report: docs/ring:dev-refactor/{timestamp}/codebase-report.md
- Project Rules: docs/PROJECT_RULES.md
</parallel_dispatch>

MUST dispatch all listed agents simultaneously in one message.
```

### Why Tags Work

- **Clear boundaries** - AI recognizes start/end of critical blocks
- **Semantic meaning** - Tag name conveys intent
- **Parseable** - Can be programmatically validated
- **Consistent pattern** - Same tag = same behavior across all prompts

---

## Related Documents

- [CLAUDE.md](../CLAUDE.md) - Main project instructions (references this document)
- [AGENT_DESIGN.md](AGENT_DESIGN.md) - Agent output schemas and requirements
- [WORKFLOWS.md](WORKFLOWS.md) - Workflows (skills, pre-dev, 6-gate dev-cycle, code review)
