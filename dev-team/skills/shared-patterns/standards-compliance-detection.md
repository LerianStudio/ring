# Standards Compliance Mode Detection

Canonical source for Standards Compliance detection logic used by all dev-team agents.

---

## ⛔ CRITICAL: Standards Compliance is ALWAYS Required for Implementation

**Standards Compliance is NOT optional. It is MANDATORY for ALL implementation agents.**

| Context | Standards Compliance | Rationale |
|---------|---------------------|-----------|
| **Implementation (TDD-GREEN)** | **ALWAYS REQUIRED** | Agent MUST output Standards Coverage Table |
| **Analysis (MODE: ANALYSIS ONLY)** | **ALWAYS REQUIRED** | Agent MUST output Standards Coverage Table + Findings |
| **Validation (SRE, QA)** | **ALWAYS REQUIRED** | Agent MUST verify against standards |

**There is NO context where an implementation agent can skip Standards Compliance.**

---

## Trigger Conditions

### ALWAYS Required (Implementation Context)

**These agents MUST ALWAYS output Standards Coverage Table:**

| Agent | Standards File | When |
|-------|---------------|------|
| `backend-engineer-golang` | golang.md | ANY implementation task |
| `backend-engineer-typescript` | typescript.md | ANY implementation task |
| `frontend-bff-engineer-typescript` | typescript.md | ANY implementation task |
| `frontend-engineer` | frontend.md | ANY implementation task |
| `devops-engineer` | devops.md | ANY artifact creation |
| `sre` | sre.md | ANY validation task |
| `qa-analyst` | golang.md/typescript.md | ANY testing task |

**⛔ HARD GATE:** If agent does NOT output Standards Coverage Table → Output is INCOMPLETE → Orchestrator MUST re-dispatch.

### Additional Triggers (Analysis Context)

These patterns trigger **detailed findings** in addition to Standards Coverage Table:

| Detection Pattern | Examples |
|------------------|----------|
| Exact match | `**MODE: ANALYSIS ONLY**` |
| Case variations | `MODE: Analysis Only`, `mode: analysis only`, `**mode: ANALYSIS ONLY**` |
| Partial markers | `ANALYSIS MODE`, `analysis-only`, `analyze only`, `MODE ANALYSIS` |
| Context clues | Invoked from `dev-refactor` skill |
| Explicit request | "compare against standards", "audit compliance", "check against Ring standards" |

## Detection Logic

```python
def get_standards_compliance_mode(prompt: str, context: dict) -> str:
    """
    Returns:
    - "FULL": Standards Coverage Table + Detailed Findings (analysis mode)
    - "TABLE_ONLY": Standards Coverage Table only (implementation mode)
    - "TABLE_ONLY" is the MINIMUM - never returns "NONE"
    """
    # Analysis mode patterns
    analysis_patterns = [
        "mode: analysis only",
        "analysis mode",
        "analysis-only",
        "analyze only",
        "compare against standards",
        "audit compliance",
        "check against ring"
    ]
    prompt_lower = prompt.lower()

    # Check for analysis mode
    if any(p in prompt_lower for p in analysis_patterns):
        return "FULL"

    # Check invocation context
    if context.get("invocation_source") == "dev-refactor":
        return "FULL"

    # Default: TABLE_ONLY (Standards Coverage Table is ALWAYS required)
    return "TABLE_ONLY"
```

## When Uncertain

If detection is ambiguous, output FULL compliance (table + findings). Better to over-report than under-report.

## When Mode is Detected, Agent MUST

1. **WebFetch** the Ring standards file for their language/domain
2. **Read** `docs/PROJECT_RULES.md` if it exists in the target codebase
3. **Include** a `## Standards Compliance` section in output with comparison table
4. **CANNOT skip** - this is a HARD GATE, not optional

## MANDATORY Output Table Format

```markdown
| Category | Current Pattern | Ring Standard | Status | File/Location |
|----------|----------------|---------------|--------|---------------|
| [category] | [what codebase does] | [what standard requires] | ✅/⚠️/❌ | [file:line] |
```

## Status Legend

- ✅ Compliant - Matches Ring standard
- ⚠️ Partial - Some compliance, needs improvement
- ❌ Non-Compliant - Does not follow standard
- N/A - Not applicable (with reason)

## Standards Coverage Table (dev-refactor context)

**Detection:** This section applies when prompt contains `**MODE: ANALYSIS ONLY**`

**Inputs (provided by dev-refactor):**

| Input | Source | Contains |
|-------|--------|----------|
| Ring Standards | WebFetch | Sections to check (## headers) |
| codebase-report.md | Provided path | Current architecture, patterns, code snippets |
| PROJECT_RULES.md | Provided path | Project-specific conventions |

**Outputs (expected by dev-refactor):**
1. Standards Coverage Table (every section enumerated)
2. Detailed findings in FINDING-XXX format for ⚠️/❌ items

**HARD GATE:** When invoked from dev-refactor skill, before outputting detailed findings, you MUST output a Standards Coverage Table.

**Process:**
1. **Parse the WebFetch result** - Extract ALL `## Section` headers from standards file
2. **Count total sections found** - Record the number
3. **For EACH section** - Determine status (✅ Compliant, ⚠️ Partial, ❌ Non-Compliant, or N/A with reason)
4. **Output table** - MUST have one row per section
5. **Verify completeness** - Table rows MUST equal sections found

---

## ⛔ CRITICAL: Section Names MUST Match Coverage Table EXACTLY

**You MUST use section names from `standards-coverage-table.md`. You CANNOT invent your own.**

### FORBIDDEN Actions

```
❌ Inventing section names ("Security", "Go Version", "Code Quality")
❌ Merging sections ("Error Handling & Logging" instead of separate rows)
❌ Renaming sections ("Config" instead of "Configuration Loading")
❌ Skipping sections not found in codebase
❌ Adding sections not in coverage table
```

### REQUIRED Actions

```
✅ Use EXACT section names from standards-coverage-table.md
✅ Output ALL sections listed in coverage table for your agent type
✅ Mark missing/not-applicable sections as "N/A" with reason
✅ One row per section - no merging
```

### Section Name Validation

**For golang.md, section names MUST be:**
- Version, Core Dependency: lib-commons, Frameworks & Libraries, Configuration Loading, Telemetry & Observability, Bootstrap Pattern, Data Transformation: ToEntity/FromEntity, Error Codes Convention, Error Handling, Function Design, Pagination Patterns, Testing Patterns, Logging Standards, Linting, Architecture Patterns, Directory Structure, Concurrency Patterns, RabbitMQ Worker Pattern

**NOT:**
- ❌ "Error Handling" (missing "Error Codes Convention" as separate row)
- ❌ "Logging" (should be "Logging Standards")
- ❌ "Configuration" (should be "Configuration Loading")
- ❌ "Security" (not a section in golang.md)
- ❌ "Bootstrap" (should be "Bootstrap Pattern")

### Anti-Rationalization for Section Names

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "My section name is clearer" | Consistency > clarity. Coverage table is the contract. | **Use EXACT names from coverage table** |
| "I combined related sections" | Each section = one row. Merging loses traceability. | **One row per section, no merging** |
| "This section doesn't apply" | Report as N/A with reason. Never skip silently. | **Include row with N/A status** |
| "I added a useful section" | You don't decide sections. Coverage table does. | **Only sections from coverage table** |
| "The codebase uses different terminology" | Standards use Ring terminology. Map codebase terms to standard terms. | **Use standard section names** |

## MANDATORY: Quote Standards from WebFetch in Findings

**For EVERY ⚠️ Partial or ❌ Non-Compliant finding, you MUST:**

1. **Quote the codebase pattern** from codebase-report.md (what exists)
2. **Quote the Ring standard** from WebFetch result (what's expected)
3. **Explain the gap** (what needs improvement)

**Output Format for Non-Compliant Findings:**

```markdown
### FINDING: [Category Name]

**Status:** ⚠️ Partial / ❌ Non-Compliant
**Location:** [file:line from codebase-report.md]
**Severity:** CRITICAL / HIGH / MEDIUM / LOW

**Current (from codebase-report.md):**
[Quote the actual code/pattern from codebase-report.md]

**Expected (from Ring Standard):**
[Quote the relevant code/pattern from WebFetch result]

**Gap Analysis:**
- What is different
- What needs to be improved
- Standard reference: {standards-file}.md → [Section Name]
```

**⛔ HARD GATE: You MUST quote from BOTH sources (codebase-report.md AND WebFetch result).**

## Anti-Rationalization

See [shared-anti-rationalization.md](shared-anti-rationalization.md) for universal agent anti-rationalizations.

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Detection wasn't exact match" | Partial matches and context clues count. | **Include Standards Compliance section** |
| "Codebase already compliant" | Assumption ≠ verification. Check every section. | **Output full Standards Coverage Table** |
| "Only relevant sections matter" | You don't decide relevance. Standards file does. | **Check ALL ## sections from WebFetch** |
| "Summary is enough" | Detailed quotes are MANDATORY for findings. | **Quote from BOTH sources** |
| "WebFetch failed, skip compliance" | STOP and report blocker. Cannot proceed without standards. | **Report blocker, do NOT skip** |

## How to Reference This File

Agents should include:

```markdown
## Standards Compliance (ALWAYS REQUIRED)

See [shared-patterns/standards-compliance-detection.md](../skills/shared-patterns/standards-compliance-detection.md) for:
- Standards Compliance is MANDATORY for ALL implementation agents
- MANDATORY output table format (Standards Coverage Table)
- Additional findings format for analysis mode
- Anti-rationalization rules

**Agent-Specific Standards:**
- WebFetch URL: `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/{file}.md`
- Sections to check: See [standards-coverage-table.md](../skills/shared-patterns/standards-coverage-table.md)

**⛔ Standards Coverage Table is ALWAYS required. No exceptions.**
- Implementation mode: Output Standards Coverage Table
- Analysis mode: Output Standards Coverage Table + Detailed Findings
```
