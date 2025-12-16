# Standards Workflow

Canonical source for the complete standards loading and handling workflow used by all dev-team agents.

## Overview

All dev-team agents MUST follow this workflow before any work:

```
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Read PROJECT_RULES.md                              │
│  ├─ Exists? → Continue to Step 2                            │
│  └─ Missing? → HARD BLOCK (see Scenario 1)                  │
├─────────────────────────────────────────────────────────────┤
│  Step 2: WebFetch Ring Standards                            │
│  ├─ Success? → Continue to Step 3                           │
│  └─ Failed? → HARD BLOCK, report blocker                    │
├─────────────────────────────────────────────────────────────┤
│  Step 3: Check Existing Code Compliance                     │
│  ├─ Compliant? → Proceed with work                          │
│  └─ Non-Compliant + No PROJECT_RULES? → HARD BLOCK (Scenario 2) │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 1: Read Local PROJECT_RULES.md (HARD GATE)

```text
Read docs/PROJECT_RULES.md
```

**MANDATORY:** Project-specific technical information that must always be considered. Cannot proceed without reading this file.

**What PROJECT_RULES.md Contains:**
- Project tech stack decisions
- Team conventions and patterns
- Architecture constraints
- Brand guidelines (for frontend)
- Database choices
- Authentication approach

---

## Step 2: WebFetch Ring Standards (HARD GATE)

**MANDATORY ACTION:** You MUST use the WebFetch tool NOW.

| Parameter | Value |
|-----------|-------|
| url | See agent-specific URL below |
| prompt | "Extract all [domain] standards, patterns, and requirements" |

**Execute this WebFetch before proceeding.** Do NOT continue until standards are loaded and understood.

**If WebFetch fails → STOP and report blocker. Cannot proceed without Ring standards.**

### Agent-Specific WebFetch URLs

| Agent | Standards File | URL |
|-------|---------------|-----|
| `ring-dev-team:backend-engineer-golang` | golang.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md` |
| `ring-dev-team:backend-engineer-typescript` | typescript.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md` |
| `ring-dev-team:frontend-bff-engineer-typescript` | typescript.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md` |
| `ring-dev-team:frontend-engineer` | frontend.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md` |
| `ring-dev-team:frontend-designer` | frontend.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md` |
| `ring-dev-team:devops-engineer` | devops.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md` |
| `ring-dev-team:sre` | sre.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md` |
| `ring-dev-team:qa-analyst` | golang.md or typescript.md | Based on project language (check PROJECT_RULES.md first) |
| `ring-dev-team:prompt-quality-reviewer` | N/A | Domain-independent (no standards WebFetch required) |

---

## Step 3: Apply Both Sources (MANDATORY)

- **Ring Standards** = Base technical patterns (error handling, testing, architecture)
- **PROJECT_RULES.md** = Project tech stack and specific patterns
- **Both are complementary. Neither excludes the other. Both must be followed.**

### Precedence Rules

| Scenario | Resolution |
|----------|------------|
| Ring says X, PROJECT_RULES.md silent | Follow Ring |
| Ring says X, PROJECT_RULES.md says Y | Follow PROJECT_RULES.md (project can override) |
| Ring says X, PROJECT_RULES.md says "follow Ring" | Follow Ring |
| Neither covers topic | Ask user (STOP and report blocker) |

---

## Scenario 1: PROJECT_RULES.md Does Not Exist

**If `docs/PROJECT_RULES.md` does not exist → HARD BLOCK.**

**Action:** STOP immediately. Do NOT proceed with any work.

### Response Format

```markdown
## Blockers
- **HARD BLOCK:** `docs/PROJECT_RULES.md` does not exist
- **Required Action:** User must create `docs/PROJECT_RULES.md` before any work can begin
- **Reason:** Project standards define tech stack, architecture decisions, and conventions that AI cannot assume
- **Status:** BLOCKED - Awaiting user to create PROJECT_RULES.md

## Next Steps
None. This agent cannot proceed until `docs/PROJECT_RULES.md` is created by the user.
```

### You CANNOT

- Offer to create PROJECT_RULES.md for the user
- Suggest a template or default values
- Proceed with any implementation/work
- Make assumptions about project standards

**The user MUST create this file themselves. This is non-negotiable.**

---

## Scenario 2: PROJECT_RULES.md Missing AND Existing Code is Non-Compliant

**Scenario:** No PROJECT_RULES.md, existing code violates Ring Standards.

**Action:** STOP. Report blocker. Do NOT match non-compliant patterns.

### Response Format

```markdown
## Blockers
- **Decision Required:** Project standards missing, existing code non-compliant
- **Current State:** Existing code uses [specific violations]
- **Options:**
  1. Create docs/PROJECT_RULES.md adopting Ring standards (RECOMMENDED)
  2. Document existing patterns as intentional project convention (requires explicit approval)
  3. Migrate existing code to Ring standards before implementing new features
- **Recommendation:** Option 1 - Establish standards first, then implement
- **Awaiting:** User decision on standards establishment
```

### Agent-Specific Non-Compliant Signs

| Agent Type | Signs of Non-Compliant Code |
|------------|----------------------------|
| **Go Backend** | `panic()` for errors, `fmt.Println` instead of structured logging, ignored errors with `result, _ :=`, no context propagation |
| **TypeScript Backend** | `any` types, no Zod validation, `// @ts-ignore`, missing Result type for errors |
| **Frontend** | No component tests, inline styles instead of design system, missing accessibility attributes |
| **DevOps** | Hardcoded secrets, no health checks, missing resource limits |
| **SRE** | Unstructured logging (plain text), missing trace_id correlation |
| **QA** | Tests without assertions, mocking implementation details, no edge cases |

**You CANNOT implement new code that matches non-compliant patterns. This is non-negotiable.**

---

## Scenario 3: Ask Only When Standards Don't Answer

After loading both PROJECT_RULES.md and Ring Standards:

**Ask when standards don't cover:**
- Database selection (PostgreSQL vs MongoDB)
- Authentication provider (WorkOS vs Auth0 vs custom)
- Multi-tenancy approach (schema vs row-level vs database-per-tenant)
- Message queue selection (RabbitMQ vs Kafka vs NATS)
- UI framework selection (React vs Vue vs Svelte)

**Don't ask (follow standards or best practices):**
- Error handling patterns → Follow Ring Standards
- Testing patterns → Follow Ring Standards
- Logging format → Follow Ring Standards
- Code structure → Check PROJECT_RULES.md or match compliant existing code

**IMPORTANT:** "Match existing code" only applies when existing code IS COMPLIANT. If existing code violates Ring Standards, do NOT match it - report blocker instead.

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "PROJECT_RULES.md not critical" | It defines everything. Cannot assume. | **STOP. Report blocker.** |
| "Existing code is fine to follow" | Only if compliant. Non-compliant = blocker. | **Verify compliance first** |
| "I'll just use best practices" | Best practices ≠ project conventions. | **Load PROJECT_RULES.md first** |
| "Small task, doesn't need rules" | All tasks need rules. Size is irrelevant. | **Load PROJECT_RULES.md first** |
| "I can infer from codebase" | Inference ≠ explicit standards. | **STOP. Report blocker.** |
| "I know the standards already" | Knowledge ≠ loading. Load for THIS task. | **Execute WebFetch NOW** |
| "Standards are too strict" | Standards exist to prevent failures. | **Follow Ring standards** |
| "WebFetch failed, use cached knowledge" | Stale knowledge causes drift. | **Report blocker, retry WebFetch** |

---

## How to Reference This File

Agents should include:

```markdown
## Standards Loading (MANDATORY)

See [shared-patterns/standards-workflow.md](../skills/shared-patterns/standards-workflow.md) for:
- Full loading process (PROJECT_RULES.md + WebFetch)
- Precedence rules
- Missing/non-compliant handling
- Anti-rationalization table

**Agent-Specific Configuration:**

| Setting | Value |
|---------|-------|
| **WebFetch URL** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/{file}.md` |
| **Standards File** | {file}.md |
| **Prompt** | "Extract all [domain] standards, patterns, and requirements" |
```
