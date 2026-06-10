## Step 0: Verify PROJECT_RULES.md Exists (HARD GATE)

**NON-NEGOTIABLE. Cycle CANNOT proceed without project standards.**

### Step 0 Flow

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│  Check: Does docs/PROJECT_RULES.md exist?                                   │
│                                                                             │
│  ├── YES → Proceed to Step 1 (Initialize or Resume)                        │
│  │                                                                          │
│  └── no → ASK: "Is this a LEGACY project (created without PM workflow)?"   │
│       │                                                                     │
│       ├── YES (legacy project) → LEGACY PROJECT ANALYSIS:                   │
│       │   Step 1: Dispatch ring:codebase-explorer (technical info only)          │
│       │   Step 2: Ask 3 questions (what agent can't determine):             │
│       │     1. What do you need help with?                                  │
│       │     2. Any external APIs not visible in code?                       │
│       │     3. Any specific technology not in Ring Standards?               │
│       │   Step 3: Generate PROJECT_RULES.md (deduplicated from Ring)        │
│       │   Note: Business rules belong in PRD, not in PROJECT_RULES          │
│       │   → Proceed to Step 1                                               │
│       │                                                                     │
│       └── no (new project) → ASK: "Do you have PRD, TRD, or Feature Map?"  │
│           │                                                                 │
│           ├── YES (has PM docs) → "Please provide the file path(s)"        │
│           │   → Read PRD/TRD/Feature Map → Extract info                    │
│           │   → Generate PROJECT_RULES.md                                  │
│           │   → Ask supplementary questions if info is incomplete          │
│           │   → Save and proceed to Step 1                                 │
│           │                                                                 │
│           └── no (no PM docs) → ⛔ HARD BLOCK:                              │
│               "PM documents are REQUIRED for new projects.                  │
│                Run /ring:planning-large-features or /ring:planning-small-features first."               │
│               → STOP (cycle cannot proceed)                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Step 0.1: Check for PROJECT_RULES.md

```yaml
# Check if file exists
Read tool:
  file_path: "docs/PROJECT_RULES.md"

# If file exists and has content → Proceed to Step 1
# If file does not exist or is empty → Continue to Step 0.2
```

### Step 0.2: Check if Legacy Project

#### Ask the User

Use AskUserQuestion. Context to convey: `docs/PROJECT_RULES.md` is missing and is needed to understand the project's conventions and domain. First determine whether this is a LEGACY project — one created WITHOUT the PM team workflow (no PRD, TRD, or Feature Map).

#### Question

"Is this a legacy project (created without PM team workflow)?"

#### Options

(a) Yes, this is a legacy project (b) No, this is a new project following Ring workflow

#### If YES (legacy)

Go to Step 0.2.1 (Legacy Project Analysis)

#### If no (new project)

Go to Step 0.3 (Check for PM Documents)

### Step 0.2.1: Legacy Project Analysis (Technical Only)

#### Overview

For legacy projects, analyze the codebase for TECHNICAL information only (business rules belong in PRD/product docs, not here):

1. Automated analysis via `ring:codebase-explorer`
2. Ask for project-specific tech not in Ring Standards
3. Generate PROJECT_RULES.md (deduplicated)

#### Step 0.2.1a: Automated Codebase Analysis (MANDATORY)

**⛔ You MUST use the Task tool to dispatch ring:codebase-explorer. This is not implicit.**

#### Dispatch Agent

Dispatch ring:codebase-explorer to analyze the legacy project for TECHNICAL information:

```text
Action: Use Task tool with EXACTLY these parameters:

┌─────────────────────────────────────────────────────────────────────────────────┐
│  ⛔ If Task tool not used → Analysis does not happen → PROJECT_RULES.md INVALID │
└─────────────────────────────────────────────────────────────────────────────────┘
```

```yaml
# Agent 1: Codebase Explorer - Technical Analysis
Task tool:
  subagent_type: "ring:codebase-explorer"
  description: "Analyze legacy project for PROJECT_RULES.md"
  prompt: |
    Analyze this LEGACY codebase to extract technical information for PROJECT_RULES.md.
    
    This is an existing project created without PM documentation.
    Your job is to understand what exists in the code.
    
    **Extract:**
    1. **Project Structure:** Directory layout, module organization
    2. **Technical Stack:** Languages, frameworks, databases, external services
    3. **Architecture Patterns:** Clean Architecture, MVC, microservices, etc.
    4. **Existing Features:** Main modules, endpoints, capabilities
    5. **Internal Libraries:** Shared packages, utilities
    6. **Configuration:** Environment variables, config patterns
    7. **Database:** Schema patterns, migrations, ORM usage
    8. **External Integrations:** APIs consumed, message queues
    
    **Output format:**
    ## Technical Analysis (Legacy Project)
    
    ### Project Overview
    [What this project appears to do based on code analysis]
    
    ### Technical Stack
    - Language: [detected]
    - Framework: [detected]
    - Database: [detected]
    - External Services: [detected]
    
    ### Architecture Patterns
    [Detected patterns]
    
    ### Existing Features
    [List of features/modules found]
    
    ### Project Structure
    [Directory layout explanation]
    
    ### Configuration
    [Env vars, config files found]
    
    ### External Integrations
    [APIs, services detected]

```

**Note:** Business logic analysis is not needed for PROJECT_RULES.md. Business rules belong in PRD/product docs, not technical project rules.

#### Verification (MANDATORY)

After agent completes, confirm:
- [ ] `ring:codebase-explorer` returned "## Technical Analysis (Legacy Project)" section
- [ ] Output contains non-empty content for: Tech Stack, External Integrations, Configuration

**If agent failed or returned empty output → Re-dispatch. Cannot proceed without technical analysis.**

#### Step 0.2.1b: Supplementary Questions (Only What Agents Can't Determine)

#### Post-Analysis Questions

After agents complete, ask only what they couldn't determine from code — a few details only the user can provide (not visible in the code).

#### Questions to Ask

Use AskUserQuestion for each:

| # | Question | Why Agents Can't Determine This |
|---|----------|--------------------------------|
| 1 | **What do you need help with?** (Current task/feature/fix) | Future intent, not in code |
| 2 | **Any external APIs or services not visible in code?** (Third-party integrations planned) | Planned integrations, not yet in code |
| 3 | **Any specific technology not in Ring Standards?** (Message broker, cache, etc.) | Project-specific tech not in Ring |

**Note:** Business rules belong in PRD/product docs, not in PROJECT_RULES.md.

#### Step 0.2.1c: Generate PROJECT_RULES.md

#### Combine Agent Outputs and User Answers

**⛔ CANONICAL TEMPLATE** — both the legacy branch (here) and the PM-docs branch (Step 0.3.1) generate `docs/PROJECT_RULES.md` from this single template. Only the provenance footer and section sources differ between branches.

```yaml
Create tool:
  file_path: "docs/PROJECT_RULES.md"
  content: |
    # Project Rules
    
    > Ring Standards are loaded by agents via WebFetch — the dev-cycle orchestrator pre-caches them at cycle start (SKILL.md Step 1.5). They are NOT applied implicitly.
    > This file documents ONLY what Ring Standards do not cover. Do not duplicate Ring content here.
    >
    > Ring Standards URLs:
    > - Go: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/golang.md
    > - TypeScript: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/typescript.md
    
    ## What Ring Standards Cover (DO not DUPLICATE HERE)
    
    The following are defined in Ring Standards and MUST not be duplicated:
    - Error handling patterns (no panic, wrap errors)
    - Logging standards (structured JSON via lib-observability `log`/`zap` adapters)
    - Testing patterns (table-driven tests, mocks)
    - Architecture patterns (Hexagonal, Clean Architecture)
    - Observability (OpenTelemetry tracing/metrics, panic recovery, assertions, redaction) — via lib-observability
    - lib-commons / lib-common-js usage and patterns (lifecycle, outbox repository, circuit breakers, tenant management, HTTP, idempotency)
    - lib-observability usage and patterns (tracing, metrics, logging, assert, runtime, redaction) — see [[using-lib-observability]]
    - lib-systemplane usage and patterns (hot-reloadable runtime config: log levels, feature flags, rate limits, timeouts) — see [[using-lib-systemplane]]
    - lib-streaming usage and patterns (past-tense business event emission to per-tenant SaaS subscribers) — see [[using-lib-streaming]]
    - API directory structure (Lerian pattern)
    - Database connections (PostgreSQL, MongoDB, Redis via lib-commons)
    - Bootstrap pattern (config.go, service.go, server.go)
    
    **Agents MUST WebFetch Ring Standards and output a Standards Coverage Table.**
    
    ---
    
    ## Tech Stack (Not in Ring Standards)
    
    [Technologies not covered by Ring Standards — e.g., specific message broker, specific cache, DB if not PostgreSQL]
    
    | Technology | Purpose | Notes |
    |------------|---------|-------|
    | [detected] | [purpose] | [notes] |
    
    ## Non-Standard Directory Structure
    
    [Directories that deviate from Ring's standard API structure — e.g., workers/, consumers/, polling/]
    
    | Directory | Purpose | Pattern |
    |-----------|---------|---------|
    | [detected] | [purpose] | [pattern] |
    
    ## External Integrations
    
    [Third-party services specific to this project]
    
    | Service | Purpose | Docs |
    |---------|---------|------|
    | [detected] | [purpose] | [link] |
    
    ## Environment Configuration
    
    [Project-specific env vars not covered by Ring]
    
    | Variable | Purpose | Example |
    |----------|---------|---------|
    | [detected] | [purpose] | [example] |
    
    ## Domain Terminology
    
    [Technical names used in this codebase]
    
    | Term | Definition | Used In |
    |------|------------|---------|
    | [detected] | [definition] | [location] |
    
    ---
    
    *Generated: [ISO timestamp]*
    *Source: Legacy project analysis (ring:codebase-explorer)*
    *Ring Standards Version: [version from WebFetch]*
```

#### Present to User

Tell the user: PROJECT_RULES.md was generated from `ring:codebase-explorer` (technical patterns, stack, structure) combined with their input (current goal, external integrations, project-specific tech). Ring Standards content is not duplicated — agents load it via WebFetch. Ask them to review and correct as needed.

#### Ask for Approval

Use AskUserQuestion:
- Question: "PROJECT_RULES.md has been generated. Would you like to review it before proceeding?"
- Options: (a) Proceed (b) Open for editing first

#### After Approval

Proceed to Step 1

### Step 0.3: Check for PM Documents (PRD/TRD/Feature Map)

#### Check for PM Documents

For NEW projects (not legacy), ask about PM documents. Context: a new project following the Ring workflow should have PM documents from pre-dev — PRD (Product Requirements), TRD (Technical Requirements), or Feature Map (from `ring:mapping-feature-relationships`).

#### Question

"Do you have PRD, TRD, or Feature Map documents for this project?"

#### Options

(a) Yes, I have PM documents (b) No, I don't have these documents

#### If YES - Ask for File Paths

```text
"Please provide the file path(s) to your PM documents:
 - PRD path (or 'skip' if none): 
 - TRD path (or 'skip' if none): 
 - Feature Map path (or 'skip' if none): "
```

#### Example Paths

Typical PM team output structure:

```text
docs/pre-dev/{feature-name}/
├── research.md
├── prd.md              → PRD path: docs/pre-dev/auth-system/prd.md
├── feature-map.md      → Feature Map path: docs/pre-dev/auth-system/feature-map.md
├── trd.md              → TRD path: docs/pre-dev/auth-system/trd.md
├── openapi.yaml
├── schema.sql          (or schema.prisma — stack-native)
├── dependencies.md
└── plan.md
```

#### Common Patterns

- `/ring:planning-large-features` output: `docs/pre-dev/{feature}/research.md`, `prd.md`, `feature-map.md`, `trd.md`, `openapi.yaml`, `schema.sql`/`schema.prisma`, `dependencies.md`, `plan.md`
- `/ring:planning-small-features` output: `docs/pre-dev/{feature}/research.md`, `prd.md`, `trd.md`, `plan.md`
- Custom locations: User may have docs in different paths (e.g., `requirements/`, `specs/`)

#### Then

Go to Step 0.3.1 (Generate from PM Documents)

#### If no

HARD BLOCK (Step 0.3.2)

### Step 0.3.1: Generate from PM Documents (PRD/TRD/Feature Map)

#### Read the Provided Documents

```yaml
# Read PRD if provided
Read tool:
  file_path: "[user-provided PRD path]"

# Read TRD if provided  
Read tool:
  file_path: "[user-provided TRD path]"

# Read Feature Map if provided
Read tool:
  file_path: "[user-provided Feature Map path]"
```

#### Extract PROJECT_RULES.md Content from PM Documents

**⛔ DEDUPLICATION RULE:** Extract only what Ring Standards DO NOT cover.

| From PRD | Extract For PROJECT_RULES.md | Note |
|----------|------------------------------|------|
| Domain terms, entities | Domain Terminology | Technical names only |
| External service mentions | External Integrations | Third-party APIs |
| ~~Business rules~~ | ~~N/A~~ | ❌ Stays in PRD, not PROJECT_RULES |
| ~~Architecture~~ | ~~N/A~~ | ❌ Ring Standards covers this |

| From TRD | Extract For PROJECT_RULES.md | Note |
|----------|------------------------------|------|
| Tech stack not in Ring | Tech Stack (Not in Ring) | Only non-standard tech |
| External APIs | External Integrations | Third-party services |
| Non-standard directories | Non-Standard Directory Structure | Workers, consumers, etc. |
| ~~Architecture decisions~~ | ~~N/A~~ | ❌ Ring Standards covers this |
| ~~Database patterns~~ | ~~N/A~~ | ❌ Ring Standards covers this |

| From Feature Map | Extract For PROJECT_RULES.md | Note |
|------------------|------------------------------|------|
| Technology choices not in Ring | Tech Stack (Not in Ring) | Only if not in Ring |
| External dependencies | External Integrations | Third-party services |
| ~~Architecture~~ | ~~N/A~~ | ❌ Ring Standards covers this |

#### Generate PROJECT_RULES.md

Generate `docs/PROJECT_RULES.md` using the **canonical template in Step 0.2.1c above**, with these branch-specific differences:

- **Section sources** (per the extraction tables above): Tech Stack and Non-Standard Directories from TRD/Feature Map; External Integrations from TRD/PRD; Domain Terminology from PRD. Apply the deduplication rule — extract only what Ring Standards do NOT cover.
- **Provenance footer** — replace the legacy footer with:
  ```
  *Generated from: [PRD path], [TRD path], [Feature Map path]*
  *Ring Standards Version: [version from WebFetch]*
  *Generated: [ISO timestamp]*
  ```

#### Check for Missing Information

If any section is empty or incomplete, ask supplementary questions:

| Missing Section | Supplementary Question |
|-----------------|------------------------|
| Tech Stack (Not in Ring) | "Any technology not covered by Ring Standards (message broker, cache, etc.)?" |
| External Integrations | "Any third-party APIs or external services?" |
| Domain Terminology | "What are the main entities/classes in this codebase?" |
| Non-Standard Directories | "Any directories that don't follow standard API structure (workers, consumers)?" |

**Note:** Do not ask about architecture, error handling, logging, testing - Ring Standards covers these.

#### After Generation

Present to user for review, then proceed to Step 1.

### Step 0.3.2: HARD BLOCK - No PM Documents (New Projects Only)

#### When User Has No PM Documents

⛔ **CANNOT PROCEED — PM DOCUMENTS REQUIRED.** Development cannot start without PM documents. The user MUST create PRD, TRD, and/or Feature Map first using PM team skills:

- `/ring:planning-large-features` → features ≥2 days (8 gates)
- `/ring:planning-small-features` → features <2 days (4 gates)

These guide creation of the PRD, TRD, and Feature Map (technology choices, feature relationships). After completing pre-dev, run `/ring:running-dev-cycle` again.

#### Action

STOP EXECUTION. Do not proceed to Step 1.

### Step 0 Anti-Rationalization

See [shared-patterns/shared-anti-rationalization.md](../../shared-patterns/shared-anti-rationalization.md) for universal rationalizations. These are specific to the PROJECT_RULES.md gate:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Skip PM docs, I'll add them later" | Later = never. No PM docs = no project context = agents guessing. | **Run /ring:planning-large-features or /ring:planning-small-features NOW** |
| "Project is simple, doesn't need PM docs" | Simple projects still need domain context defined upfront. | **Create PM documents first** |
| "I know what I want to build" | Your knowledge ≠ documented knowledge agents can use. | **Document in PRD/TRD/Feature Map** |
| "PM workflow takes too long" | PM workflow takes 30-60 min. Rework from unclear requirements takes days. | **Invest time upfront** |
| "Just let me start coding" | Coding without requirements = building the wrong thing. | **Requirements first, code second** |
| "It's legacy but I don't want to answer questions" | Legacy analysis takes ~5 min. Without it, agents have zero context. | **Answer the 4 questions** |
| "Legacy project is too complex to explain" | Start with high-level answers. PROJECT_RULES.md can be refined later. | **Provide what you know NOW** |

### Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just skip this, I'll create PM docs later" | "PM documents are REQUIRED for new projects. Without them, agents cannot understand your project's domain context or technical requirements. Run `/ring:planning-large-features` or `/ring:planning-small-features` first." |
| "I don't need formal documents" | "PM documents are the source of truth for PROJECT_RULES.md. Development cannot start without documented requirements." |
| "This is just a quick prototype" | "Even prototypes need clear requirements. `/ring:planning-small-features` takes ~30 minutes and prevents hours of rework." |
| "I already explained what I want verbally" | "Verbal explanations cannot be used by agents. Requirements MUST be documented in PRD/TRD/Feature Map files." |
| "It's a legacy project but skip the questions" | "The legacy analysis (ring:codebase-explorer + 3 questions) is the only way I can understand your project. It takes ~5 minutes and enables me to help you effectively." |
| "I'll fill in PROJECT_RULES.md myself" | "That works! Create `docs/PROJECT_RULES.md` with: Tech Stack (not in Ring), External Integrations, Domain Terminology. Do not duplicate Ring Standards content. Then run `/ring:running-dev-cycle` again." |

---
