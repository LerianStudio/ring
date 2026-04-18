---
name: ring:dev-devops
description: |
  Gate 1 of the development cycle. Creates/updates Docker configuration,
  docker-compose setup, and environment variables for local development
  and deployment readiness. Runs at TASK cadence (after all subtasks
  complete Gate 0 + Gate 3 + Gate 9).

trigger: |
  - Gate 1 of development cycle
  - Implementation complete from Gate 0
  - Need containerization or environment setup

skip_when: |
  - Not inside a development cycle (ring:dev-cycle)
  - Task is documentation-only, configuration-only, or non-code
  - Project already has complete Docker and docker-compose setup unchanged by Gate 0
  - Pure library package with no deployable service

NOT_skip_when: |
  - "Application runs fine locally" → Docker ensures consistency across environments.
  - "Docker is overkill" → Docker is baseline, not overkill.
  - "We'll containerize before production" → Containerize NOW or never.

sequence:
  after: [ring:dev-implementation]
  before: [ring:dev-ring:sre]

related:
  complementary: [ring:dev-implementation, ring:dev-unit-testing]

input_schema:
  required:
    - name: unit_id
      type: string
      description: "TASK identifier (not a subtask id). This skill runs at TASK cadence — unit_id is always a task id."
    - name: language
      type: string
      enum: [go, typescript, python]
      description: "Programming language of the implementation"
    - name: service_type
      type: string
      enum: [api, worker, batch, cli]
      description: "Type of service being containerized"
    - name: implementation_files
      type: array
      items: string
      description: "Union of changed files across all subtasks of this task."
    - name: gate0_handoffs
      type: array
      description: "Array of per-subtask implementation handoffs (one entry per subtask). NOT a single gate0_handoff object."
  optional:
    - name: new_dependencies
      type: array
      items: string
      description: "New dependencies added in Gate 0"
    - name: new_env_vars
      type: array
      items: string
      description: "New environment variables needed"
    - name: new_services
      type: array
      items: string
      description: "New services needed (postgres, redis, etc.)"
    - name: existing_dockerfile
      type: boolean
      default: false
      description: "Whether Dockerfile already exists"
    - name: existing_compose
      type: boolean
      default: false
      description: "Whether docker-compose.yml already exists"

output_schema:
  format: markdown
  required_sections:
    - name: "DevOps Summary"
      pattern: "^## DevOps Summary"
      required: true
    - name: "Files Changed"
      pattern: "^## Files Changed"
      required: true
    - name: "Verification Results"
      pattern: "^## Verification Results"
      required: true
    - name: "Handoff to Next Gate"
      pattern: "^## Handoff to Next Gate"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL, PARTIAL]
    - name: dockerfile_action
      type: enum
      values: [CREATED, UPDATED, UNCHANGED]
    - name: compose_action
      type: enum
      values: [CREATED, UPDATED, UNCHANGED]
    - name: env_example_action
      type: enum
      values: [CREATED, UPDATED, UNCHANGED]
    - name: services_configured
      type: integer
    - name: verification_passed
      type: boolean

verification:
  automated:
    - command: "docker-compose build"
      description: "Docker images build successfully"
      success_pattern: 'Successfully built|successfully'
    - command: "docker-compose up -d && sleep 10 && docker-compose ps"
      description: "All services start and are healthy"
      success_pattern: 'Up|running|healthy'
    - command: "docker-compose logs app | head -5 | jq -e '.level'"
      description: "Structured JSON logging works"
      success_pattern: 'info|debug|warn|error'
  manual:
    - "Verify docker-compose ps shows all services as 'Up (healthy)'"
    - "Verify .env.example documents all required environment variables"

---

# DevOps Setup (Gate 1)

## Overview

This skill configures the development and deployment infrastructure:
- Creates or updates Dockerfile for the application
- Configures docker-compose.yml for local development
- Documents environment variables in .env.example
- Verifies the containerized application works

## CRITICAL: Role Clarification

**This skill ORCHESTRATES. DevOps Agent IMPLEMENTS.**

| Who | Responsibility |
|-----|----------------|
| **This Skill** | Gather requirements, prepare prompts, validate outputs |
| **DevOps Agent** | Create Dockerfile, docker-compose, .env.example, verify |

---

## Step 1: Validate Input

<verify_before_proceed>
- unit_id exists
- language is valid (go|typescript|python)
- service_type is valid (api|worker|batch|cli)
- implementation_files is not empty
</verify_before_proceed>

```text
REQUIRED INPUT (from ring:dev-cycle orchestrator):
- unit_id: [TASK id — runs at task cadence, not per subtask]
- language: [go|typescript|python]
- service_type: [api|worker|batch|cli]
- implementation_files: [union of changed files across all subtasks of this task]
- gate0_handoffs: [array of per-subtask Gate 0 handoffs — one entry per subtask]

OPTIONAL INPUT:
- new_dependencies: [deps added in Gate 0]
- new_env_vars: [env vars needed]
- new_services: [postgres, redis, etc.]
- existing_dockerfile: [true/false]
- existing_compose: [true/false]

if any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"
  → Return to orchestrator with error
```

## Step 2: Analyze DevOps Requirements

```text
1. Check existing files:
   - Dockerfile: [EXISTS/MISSING]
   - docker-compose.yml: [EXISTS/MISSING]
   - .env.example: [EXISTS/MISSING]

2. Determine actions needed:
   - Dockerfile: CREATE / UPDATE / NONE
   - docker-compose.yml: CREATE / UPDATE / NONE
   - .env.example: CREATE / UPDATE / NONE

3. Identify services needed:
   - From new_services input
   - From language (Go → alpine base, TS → node base)
   - From service_type (api → expose port, worker → no port)
```

## Step 3: Initialize DevOps State

```text
devops_state = {
  unit_id: [from input],
  dockerfile_action: "pending",
  compose_action: "pending",
  env_action: "pending",
  services: [],
  verification: {
    build: null,
    startup: null,
    health: null
  },
  iterations: 0,
  max_iterations: 3
}
```

## Step 4: Dispatch DevOps Agent

<dispatch_required agent="ring:devops-engineer">
Create/update Dockerfile, docker-compose.yml, and .env.example for containerization.
</dispatch_required>

```yaml
Task:
  subagent_type: "ring:devops-engineer"
  description: "Create/update DevOps artifacts for [unit_id]"
  prompt: |
    ⛔ MANDATORY: Create all DevOps Artifacts

    ## Input Context
    - **Unit ID:** [unit_id]
    - **Language:** [language]
    - **Service Type:** [service_type]
    - **Implementation Files:** [implementation_files]
    - **New Dependencies:** [new_dependencies or "None"]
    - **New Environment Variables:** [new_env_vars or "None"]
    - **New Services Needed:** [new_services or "None"]

    ## Existing Files
    - Dockerfile: [EXISTS/MISSING]
    - docker-compose.yml: [EXISTS/MISSING]
    - .env.example: [EXISTS/MISSING]

    ## Standards Source (Cache-First Pattern)

    **Standards Source (Cache-First Pattern):** This sub-skill reads standards from `state.cached_standards` populated by dev-cycle Step 1.5. If invoked outside a cycle (standalone), it falls back to direct WebFetch with a warning. See `shared-patterns/standards-cache-protocol.md` for protocol details.

    ## Standards Reference

    URL: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md

    **Cache-first loading protocol:**
    For each required standards URL:
      IF state.cached_standards[url] exists:
        → Read content from state.cached_standards[url].content
        → Log: "Using cached standard: {url} (fetched {state.cached_standards[url].fetched_at})"
      ELSE:
        → WebFetch url (fallback — should not happen if orchestrator ran Step 1.5)
        → Log warning: "Standard {url} was not pre-cached; fetched inline"

    You MUST implement all sections from devops.md.

    ## Requirements

    ### Dockerfile
    - Multi-stage build (builder → production)
    - Non-root USER (appuser)
    - Specific versions (no :latest)
    - HEALTHCHECK instruction
    - Layer caching optimization

    ### docker-compose.yml
    - Version: 3.8
    - App service with build context
    - Database/cache services as needed
    - Named volumes for persistence
    - Health checks with depends_on conditions
    - Network: app-network (bridge)

    ### .env.example
    - all variables with placeholders
    - Comments explaining each
    - Grouped by service
    - Required vs optional marked
    - **MANDATORY: Multi-tenant variables** (for ALL services):
      ```
      # Multi-tenant configuration (MANDATORY)
      MULTI_TENANT_ENABLED=false
      MULTI_TENANT_URL=
      ```

    ## Required Output Format

    ### Standards Coverage Table
    | # | Section (from devops.md) | Status | Evidence |
    |---|--------------------------|--------|----------|
    | 1 | Containers | ✅/❌ | Dockerfile:[line] |
    | 2 | Docker Compose | ✅/❌ | docker-compose.yml:[line] |
    | 3 | Environment | ✅/❌ | .env.example:[line] |
    | 4 | Health Checks | ✅/❌ | [file:line] |

    ### Files Created/Updated
    | File | Action | Key Changes |
    |------|--------|-------------|
    | Dockerfile | Created/Updated | [summary] |
    | docker-compose.yml | Created/Updated | [summary] |
    | .env.example | Created/Updated | [summary] |

    ### Verification Commands

    <verify_before_proceed>
    - docker-compose build succeeds
    - docker-compose up -d starts all services
    - docker-compose ps shows healthy status
    - docker-compose logs shows JSON format
    </verify_before_proceed>

    Execute these and report results:
    1. `docker-compose build` → [PASS/FAIL]
    2. `docker-compose up -d` → [PASS/FAIL]
    3. `docker-compose ps` → [all healthy?]
    4. `docker-compose logs app | head -5` → [JSON logs?]

    ### Compliance Summary
    - **all STANDARDS MET:** ✅ YES / ❌ no
    - **If no, what's missing:** [list sections]
```

## Step 5: Validate Agent Output

```text
Parse agent output:

1. Extract Standards Coverage Table
2. Extract Files Created/Updated
3. Extract Verification results

if "all STANDARDS MET: ✅ YES" and all verifications PASS:
  → devops_state.dockerfile_action = [from table]
  → devops_state.compose_action = [from table]
  → devops_state.env_action = [from table]
  → devops_state.verification = {build: PASS, startup: PASS, health: PASS}
  → Proceed to Step 7

if any section has ❌ or any verification FAIL:
  → devops_state.iterations += 1
  → if iterations >= max_iterations: Go to Step 8 (Escalate)
  → Re-dispatch agent with specific failures
```

## Step 6: Re-Dispatch for Fixes (if needed)

```yaml
Task:
  subagent_type: "ring:devops-engineer"
  description: "Fix DevOps issues for [unit_id]"
  prompt: |
    ⛔ FIX REQUIRED - DevOps Standards Not Met

    ## Issues Found
    [list ❌ sections and FAIL verifications]

    ## Standards Reference

    URL: https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/devops.md

    **Cache-first loading protocol:**
    For each required standards URL:
      IF state.cached_standards[url] exists:
        → Read content from state.cached_standards[url].content
        → Log: "Using cached standard: {url} (fetched {state.cached_standards[url].fetched_at})"
      ELSE:
        → WebFetch url (fallback — should not happen if orchestrator ran Step 1.5)
        → Log warning: "Standard {url} was not pre-cached; fetched inline"

    Fix all issues and re-run verification commands.
    Return updated Standards Coverage Table with all ✅.
```

After fix → Go back to Step 5

## Step 7: Prepare Success Output

```text
Generate skill output:

## DevOps Summary
**Status:** PASS
**Unit ID:** [unit_id]
**Iterations:** [devops_state.iterations]

## Files Changed
| File | Action | Summary |
|------|--------|---------|
| Dockerfile | [CREATED/UPDATED/UNCHANGED] | [summary] |
| docker-compose.yml | [CREATED/UPDATED/UNCHANGED] | [summary] |
| .env.example | [CREATED/UPDATED/UNCHANGED] | [summary] |

## Services Configured
| Service | Image | Port | Health Check |
|---------|-------|------|--------------|
| app | [built] | [port] | [healthcheck] |
| [db] | [image] | [port] | [healthcheck] |
| [cache] | [image] | [port] | [healthcheck] |

## Verification Results
| Check | Status | Output |
|-------|--------|--------|
| Build | ✅ PASS | Successfully built |
| Startup | ✅ PASS | All services Up |
| Health | ✅ PASS | All healthy |
| Logging | ✅ PASS | JSON structured |

## Handoff to Next Gate
- DevOps status: COMPLETE
- Services: [list]
- Env vars: [count] documented
- Verification: all PASS
- Ready for Gate 2 (SRE): YES
```

## Step 8: Escalate - Max Iterations Reached

```text
Generate skill output:

## DevOps Summary
**Status:** FAIL
**Unit ID:** [unit_id]
**Iterations:** [max_iterations] (MAX REACHED)

## Files Changed
[list what was created/updated]

## Issues Remaining
[list unresolved issues]

## Verification Results
[list PASS/FAIL for each check]

## Handoff to Next Gate
- DevOps status: FAILED
- Ready for Gate 2: no
- **Action Required:** User must manually resolve issues

⛔ ESCALATION: Max iterations (3) reached. User intervention required.
```

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Security risk, deployment blocked | :latest tags, secrets in image, root user, missing HEALTHCHECK |
| **HIGH** | Build fails, services broken | docker-compose build fails, services don't start, no health checks |
| **MEDIUM** | Configuration gaps, optimization issues | Missing layer caching, no named volumes, incomplete .env.example |
| **LOW** | Best practices, documentation | Missing comments in Dockerfile, suboptimal ordering |

Report all severities. CRITICAL = immediate fix. HIGH = fix before gate pass. MEDIUM = fix in iteration. LOW = document.

---

## Pressure Resistance

See [shared-patterns/shared-pressure-resistance.md](../shared-patterns/shared-pressure-resistance.md) for universal pressure scenarios.

| User Says | Your Response |
|-----------|---------------|
| "Skip Docker, runs fine locally" | "Docker ensures consistency. Dispatching ring:devops-engineer now." |
| "Demo tomorrow, no time" | "Docker takes 30 min. Better than environment crash during demo." |
| "We'll containerize later" | "Later = never. Containerizing now." |

---

## Anti-Rationalization Table

See [shared-patterns/shared-anti-rationalization.md](../shared-patterns/shared-anti-rationalization.md) for universal anti-rationalizations.

### Gate 1-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Works fine locally" | Your machine ≠ production | **Containerize for consistency** |
| "Docker is overkill" | Docker is baseline, not overkill | **Create Dockerfile** |
| "Just need docker run" | docker-compose is reproducible | **Use docker-compose** |
| "Lambda doesn't need Docker" | SAM uses Docker locally | **Use SAM containers** |

---

## Execution Report Format

```markdown
## DevOps Summary
**Status:** [PASS|FAIL|PARTIAL]
**Unit ID:** [unit_id]
**Duration:** [Xm Ys]
**Iterations:** [N]

## Files Changed
| File | Action |
|------|--------|
| Dockerfile | [CREATED/UPDATED/UNCHANGED] |
| docker-compose.yml | [CREATED/UPDATED/UNCHANGED] |
| .env.example | [CREATED/UPDATED/UNCHANGED] |

## Services Configured
| Service | Image | Port |
|---------|-------|------|
| [name] | [image] | [port] |

## Verification Results
| Check | Status |
|-------|--------|
| Build | ✅/❌ |
| Startup | ✅/❌ |
| Health | ✅/❌ |
| Logging | ✅/❌ |

## Handoff to Next Gate
- DevOps status: [COMPLETE|PARTIAL|FAILED]
- Ready for Gate 2: [YES|no]
```
