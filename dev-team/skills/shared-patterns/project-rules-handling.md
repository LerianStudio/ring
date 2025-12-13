# PROJECT_RULES.md Handling

Canonical source for handling missing or non-compliant PROJECT_RULES.md scenarios used by all dev-team agents.

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

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "PROJECT_RULES.md not critical" | It defines everything. Cannot assume. | **STOP. Report blocker.** |
| "Existing code is fine to follow" | Only if compliant. Non-compliant = blocker. | **Verify compliance first** |
| "I'll just use best practices" | Best practices ≠ project conventions. | **Load PROJECT_RULES.md first** |
| "Small task, doesn't need rules" | All tasks need rules. Size is irrelevant. | **Load PROJECT_RULES.md first** |
| "I can infer from codebase" | Inference ≠ explicit standards. | **STOP. Report blocker.** |

## How to Reference This File

Agents should include:

```markdown
## Handling Ambiguous Requirements

See [shared-patterns/project-rules-handling.md](../skills/shared-patterns/project-rules-handling.md) for:
- Missing PROJECT_RULES.md handling (HARD BLOCK)
- Non-compliant existing code handling
- When to ask vs follow standards

**Agent-Specific Non-Compliant Signs:**
- [List agent-specific violations to watch for]
```
