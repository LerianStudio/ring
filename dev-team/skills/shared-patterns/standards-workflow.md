# Standards Workflow

Canonical source for the complete standards loading and handling workflow used by all dev-team agents.

## Overview

All dev-team agents MUST follow this workflow before any work:

```
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Read PROJECT_RULES.md                              │
│  ├─ Exists? → Continue to Step 2                            │
│  └─ Missing? → Create PROJECT_RULES.md (see Scenario 1)     │
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

### What PROJECT_RULES.md Contains (COMPLEMENTARY to Ring Standards)

**⛔ DEDUPLICATION RULE:** PROJECT_RULES.md documents ONLY what Ring Standards do NOT cover.

| Category | Belongs In | Examples |
|----------|------------|----------|
| **Tech stack not in Ring** | PROJECT_RULES.md | Specific message broker, specific cache, DB if not PostgreSQL |
| **Non-standard directories** | PROJECT_RULES.md | Pooling workers, MessageBroker consumers, custom workers |
| **External integrations** | PROJECT_RULES.md | Third-party APIs, webhooks, external services |
| **Project-specific env vars** | PROJECT_RULES.md | Environment config not covered by Ring |
| **Domain terminology** | PROJECT_RULES.md | Technical names of entities/classes in this codebase |
| Error handling patterns | Ring Standards | ❌ Do NOT duplicate |
| Logging standards | Ring Standards | ❌ Do NOT duplicate |
| Testing patterns | Ring Standards | ❌ Do NOT duplicate |
| Architecture patterns | Ring Standards | ❌ Do NOT duplicate |
| lib-commons, shared packages | Ring Standards | ❌ Do NOT duplicate |
| API directory structure | Ring Standards | ❌ Do NOT duplicate |
| Business rules | Product docs (PRD) | ❌ Does NOT belong in PROJECT_RULES |

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
| `backend-engineer-golang` | golang.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md` |
| `backend-engineer-typescript` | typescript.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md` |
| `frontend-bff-engineer-typescript` | typescript.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md` |
| `frontend-engineer` | frontend.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md` |
| `frontend-designer` | frontend.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md` |
| `devops-engineer` | devops.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md` |
| `sre` | sre.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md` |
| `qa-analyst` | golang.md or typescript.md | Based on project language (check PROJECT_RULES.md first) |
| `prompt-quality-reviewer` | N/A | Domain-independent (no standards WebFetch required) |

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

**If `docs/PROJECT_RULES.md` does not exist → Offer to CREATE it with user input.**

**Action:** Guide user through PROJECT_RULES.md creation with automatic deduplication against Ring Standards.

### Creation Flow

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│  Step 1: WebFetch Ring Standards FIRST                                      │
│  ├─ Load standards for detected language (Go, TypeScript, etc.)             │
│  └─ This establishes what is ALREADY covered                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  Step 2: Analyze Codebase for Project-Specific Information                  │
│  ├─ Detect tech stack not in Ring (message brokers, caches, etc.)           │
│  ├─ Detect non-standard directories (workers, consumers, etc.)              │
│  ├─ Detect external integrations (third-party APIs, webhooks)               │
│  └─ Detect domain terminology (entity names, module names)                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  Step 3: Ask User ONLY for What Cannot Be Detected                          │
│  ├─ "Any external APIs or services not visible in code?"                    │
│  ├─ "Any specific environment variables needed?"                            │
│  └─ "Any planned tech not yet in codebase?"                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  Step 4: Generate PROJECT_RULES.md (Deduplicated)                           │
│  ├─ Header referencing Ring Standards                                       │
│  ├─ ONLY project-specific sections                                          │
│  └─ NO content that duplicates Ring Standards                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

### PROJECT_RULES.md Template (Deduplicated)

```markdown
# Project Rules

> ⛔ IMPORTANT: Ring Standards are NOT automatic. Agents MUST WebFetch them before implementation.
> This file documents ONLY project-specific information not covered by Ring Standards.
>
> Ring Standards URLs:
> - Go: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md
> - TypeScript: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md
> - Frontend: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend.md
> - DevOps: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md
> - SRE: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/sre.md

## What Ring Standards Cover (DO NOT DUPLICATE HERE)

The following are defined in Ring Standards and MUST NOT be duplicated in this file:
- Error handling patterns (no panic, wrap errors)
- Logging standards (structured JSON via lib-commons)
- Testing patterns (table-driven tests, mocks)
- Architecture patterns (Hexagonal, Clean Architecture)
- Observability (OpenTelemetry via lib-commons)
- lib-commons / lib-common-js usage and patterns
- API directory structure (Midaz pattern)
- Database connections (PostgreSQL, MongoDB, Redis via lib-commons)
- Bootstrap pattern (config.go, service.go, server.go)

**Agents MUST WebFetch Ring Standards and output Standards Coverage Table.**

---

## Tech Stack (Not in Ring Standards)

[ONLY technologies not covered by Ring Standards]

| Technology | Purpose | Notes |
|------------|---------|-------|
| [e.g., NATS] | [Message broker] | [Specific config notes] |
| [e.g., Valkey] | [Cache] | [If not Redis] |

## Non-Standard Directory Structure

[ONLY directories that deviate from Ring's standard API structure]

| Directory | Purpose | Pattern |
|-----------|---------|---------|
| [e.g., `workers/`] | [Pooling workers] | [Not API, different pattern] |
| [e.g., `consumers/`] | [Message consumers] | [Async processing] |

## External Integrations

[Third-party services specific to this project]

| Service | Purpose | Docs |
|---------|---------|------|
| [e.g., Stripe] | [Payments] | [Link to integration docs] |
| [e.g., SendGrid] | [Email] | [Link] |

## Environment Configuration

[Project-specific env vars NOT covered by Ring's standard config]

| Variable | Purpose | Example |
|----------|---------|---------|
| [e.g., `STRIPE_API_KEY`] | [Payment processing] | [Format notes] |

## Domain Terminology

[Technical names used in this codebase]

| Term | Definition | Used In |
|------|------------|---------|
| [e.g., `Ledger`] | [Financial record container] | [Models, services] |

---

*Generated: [ISO timestamp]*
*Ring Standards Version: [version from WebFetch]*
```

### Deduplication Validation

**Before saving PROJECT_RULES.md, validate NO duplication exists:**

| If Content Mentions | Action |
|---------------------|--------|
| Error handling patterns | ❌ REMOVE - Ring Standards covers this |
| Logging format/structure | ❌ REMOVE - Ring Standards covers this |
| Testing patterns | ❌ REMOVE - Ring Standards covers this |
| lib-commons | ❌ REMOVE - Ring Standards covers this |
| Hexagonal/Clean Architecture | ❌ REMOVE - Ring Standards covers this |
| OpenTelemetry/tracing | ❌ REMOVE - Ring Standards covers this |
| Standard API directory structure | ❌ REMOVE - Ring Standards covers this |
| Business rules | ❌ REMOVE - Belongs in PRD/product docs |

### Response Format (When PROJECT_RULES.md Missing)

```markdown
## PROJECT_RULES.md Not Found

I'll help you create `docs/PROJECT_RULES.md` with ONLY project-specific information.

**Ring Standards already cover:**
- Error handling, logging, testing patterns
- Architecture (Hexagonal), observability (OpenTelemetry)
- lib-commons usage, API structure

**I need to document (if applicable):**
1. Tech stack not in Ring (specific message broker, cache, etc.)
2. Non-standard directories (workers, consumers, etc.)
3. External integrations (third-party APIs)
4. Project-specific environment variables
5. Domain terminology (entity/module names)

**Analyzing codebase...**
[Analysis results]

**Questions (only what I couldn't detect):**
1. Any external APIs or services not visible in code?
2. Any specific environment variables needed?
3. Any planned technology not yet implemented?
```

### Anti-Rationalization for Creation

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Include error handling section anyway" | Ring Standards covers this. Duplication causes drift. | **REMOVE from PROJECT_RULES.md** |
| "Add lib-commons usage notes" | Ring Standards is the source of truth. | **REMOVE from PROJECT_RULES.md** |
| "Document testing patterns here" | Ring Standards defines testing patterns. | **REMOVE from PROJECT_RULES.md** |
| "Include business rules for context" | Business rules belong in PRD, not tech docs. | **REMOVE from PROJECT_RULES.md** |
| "Better to have everything in one place" | Single source of truth prevents drift. Ring = patterns. | **Reference Ring, don't duplicate** |

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
