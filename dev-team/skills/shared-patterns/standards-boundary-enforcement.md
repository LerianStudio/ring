# Standards Boundary Enforcement

Canonical source for preventing agents from hallucinating requirements beyond what exists in Ring standards files.

---

## ⛔ CRITICAL: Check only What Standards Define

**This is NON-NEGOTIABLE. Agents MUST not invent, assume, or hallucinate requirements.**

| Rule | Enforcement |
|------|-------------|
| **only check items explicitly listed in standards** | If not in WebFetch result → not a requirement |
| **never invent "should have" items** | Standards define WHAT exists, not what you think should exist |
| **never add industry best practices not in standards** | Ring standards ARE the best practices for this org |
| **never assume common patterns are required** | If not listed → not required |

**If you flag something not in standards → Your output is INVALID. Remove the hallucinated finding.**

---

## Why This Pattern Exists

**Problem:** AI agents "helpfully" invent requirements based on:
- General industry knowledge
- Common patterns seen in training data
- Assumptions about what "should" exist
- Extrapolation from partial information

**Example Failures:**
| Agent Said | Reality | Problem |
|------------|---------|---------|
| "Missing `make proto`" | not in devops.md Makefile Standards | Hallucinated requirement |
| "Missing `make mocks`" | not in devops.md Makefile Standards | Hallucinated requirement |
| "Missing `make migrate-up/down`" | not in devops.md Makefile Standards | Hallucinated requirement |
| "Should use gRPC" | not in golang.md Frameworks | Hallucinated requirement |
| "Needs GraphQL schema" | not in typescript.md | Hallucinated requirement |

**Solution:** Agents MUST extract requirements only from WebFetch result, never from general knowledge.

---

## ⛔ MANDATORY: Standards Extraction Process

**Before checking compliance, you MUST:**

### Step 1: WebFetch the Standards File

```text
WebFetch:
  url: [agent-specific URL from standards-workflow.md]
  prompt: "Extract all requirements, patterns, and expected items"
```

### Step 2: Extract and LIST the Requirements

**For each section you will check, you MUST output what you found:**

```markdown
## Standards Extracted from WebFetch

### Section: [Name]

**Requirements found in standards file:**
1. [Exact requirement from WebFetch]
2. [Exact requirement from WebFetch]
3. [Exact requirement from WebFetch]

**I will check only these items. Nothing else.**
```

### Step 3: Check only Extracted Requirements

**Your findings MUST reference the extracted list:**

```markdown
### Finding: [Issue]

**Standard Reference:** [Section Name] → Requirement #2 from extracted list
**Evidence:** [file:line showing violation]
```

---

## Agent-Specific Boundaries

**⛔ CRITICAL: Do not duplicate standards content here. Reference the standards files.**

### How to Use This Pattern

Each agent MUST:
1. **WebFetch** the appropriate standards file
2. **Extract** requirements from the fetched content
3. **Check only** what the standards explicitly list
4. **Verify** before flagging - if not in WebFetch result, DO NOT flag

### Common Hallucinations by Agent Type

**These are items agents commonly invent that are not typically in standards. Always verify in WebFetch result before flagging.**

#### ring:backend-go → golang.md

| Common Hallucination | Action |
|---------------------|--------|
| gRPC requirement | Verify in golang.md "Frameworks & Libraries" section |
| GraphQL requirement | Verify in golang.md "Frameworks & Libraries" section |
| Gin instead of Fiber | Check actual HTTP framework in golang.md |
| GORM instead of pgx | Check actual ORM/driver in golang.md |

#### ring:backend-ts → typescript.md

| Common Hallucination | Action |
|---------------------|--------|
| class-validator | Verify validation library in typescript.md |
| TypeORM | Verify ORM in typescript.md |
| Jest | Verify testing framework in typescript.md |
| InversifyJS | Verify DI framework in typescript.md |

#### ring:ui-designer → frontend.md

| Common Hallucination | Action |
|---------------------|--------|
| Design library (Material UI, Chakra) | Verify in frontend.md "Libraries & Tools" section |
| CSS framework (Bootstrap, Bulma) | Verify in frontend.md "Styling Standards" section |
| Accessibility standard (WCAG AAA) | Verify EXACT level in frontend.md "Accessibility" section |
| Component library (Radix, Headless UI) | Verify in frontend.md "Component Patterns" section |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Industry standard to have make proto" | Industry ≠ Ring standards. Ring defines requirements. | **Do not flag** |
| "Most Go projects need gRPC" | Most ≠ this project. Standards define this project. | **Do not flag** |
| "It's a best practice to have X" | Best practices are IN the standards. If not there, not required. | **Do not flag** |
| "This would improve the codebase" | Improvement suggestions ≠ compliance findings. | **Do not flag as non-compliant** |
| "I've seen this in similar projects" | Similar ≠ this. Standards are project-specific. | **Do not flag** |
| "Common sense says this is needed" | Common sense ≠ explicit requirement. Standards are explicit. | **Do not flag** |
| "The team might need this" | Probably ≠ definitely. Standards define definitely. | **Do not flag** |
| "It's implied by the architecture" | Implied ≠ explicit. Only explicit requirements count. | **Do not flag** |

---

## Self-Verification Checklist

**Before submitting findings, verify:**

```text
For each finding:
1. Is this item EXPLICITLY listed in the WebFetch result?       [ ]
2. Can I quote the EXACT line from standards defining this?     [ ]
3. Am I flagging absence of something not in standards?         [ ]
4. Am I inventing requirements from general knowledge?          [ ]
5. Am I assuming "should have" vs "standards say must have"?    [ ]

If #1 or #2 is no → REMOVE the finding
If #3, #4, or #5 is YES → REMOVE the finding
```

---

## How Agents Reference This Pattern

Add to agent's Standards Compliance section:

```markdown
## Standards Boundary (MANDATORY)

See [shared-patterns/standards-boundary-enforcement.md](../skills/shared-patterns/standards-boundary-enforcement.md) for:
- only check what standards explicitly define
- Agent-specific requirement boundaries
- Forbidden hallucinations list
- Self-verification checklist

**⛔ HARD GATE:** Before flagging any item as non-compliant:
1. Verify the requirement EXISTS in WebFetch result
2. Quote the exact standard that requires it
3. If you cannot quote it → Do not flag it
```
