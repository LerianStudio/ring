---
name: dev-devops
description: |
  Gate 1 of the development cycle. Creates/updates Docker configuration,
  docker-compose setup, and environment variables for local development
  and deployment readiness.

trigger: |
  - Gate 1 of development cycle
  - Implementation complete from Gate 0
  - Need containerization or environment setup

skip_when: |
  - No code implementation exists (need Gate 0 first)
  - Project has no Docker requirements
  - Only documentation changes

sequence:
  after: [ring-dev-team:dev-implementation]
  before: [ring-dev-team:dev-sre]

related:
  complementary: [ring-dev-team:dev-implementation, ring-dev-team:dev-testing]

verification:
  automated:
    - command: "docker-compose build"
      description: "Docker images build successfully"
      success_pattern: "Successfully built|successfully"
      failure_pattern: "error|failed|Error"
    - command: "docker-compose up -d && sleep 10 && docker-compose ps"
      description: "All services start and are healthy"
      success_pattern: "Up|running|healthy"
      failure_pattern: "Exit|exited|unhealthy"
    - command: "docker-compose logs app | head -5 | jq -e '.level'"
      description: "Structured JSON logging works"
      success_pattern: "info|debug|warn|error"
  manual:
    - "Verify docker-compose ps shows all services as 'Up (healthy)'"
    - "Verify .env.example documents all required environment variables"

examples:
  - name: "New Go service"
    context: "Gate 0 completed Go API implementation"
    expected_output: |
      - Dockerfile with multi-stage build
      - docker-compose.yml with app, postgres, redis
      - .env.example with all variables documented
      - docs/LOCAL_SETUP.md created
  - name: "Add Redis to existing service"
    context: "Implementation added caching, needs Redis"
    expected_output: |
      - docker-compose.yml updated with redis service
      - .env.example updated with REDIS_URL
      - Health check updated to verify Redis connection
---

# DevOps Setup (Gate 1)

## Overview

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) and [dev-team/docs/standards/devops.md](https://raw.githubusercontent.com/LerianStudio/ring/main/docs/standards/devops.md) for canonical DevOps requirements. This skill orchestrates Gate 1 execution.

This skill configures the development and deployment infrastructure:
- Creates or updates Dockerfile for the application
- Configures docker-compose.yml for local development
- Documents environment variables in .env.example
- Verifies the containerized application works

## Pressure Resistance

**Gate 1 (DevOps) is MANDATORY for all containerizable applications. Pressure scenarios and required responses:**

| Pressure Type | Request | Agent Response |
|---------------|---------|----------------|
| **Works Locally** | "App runs fine without Docker" | "Local ≠ production. Docker ensures reproducible environments. REQUIRED." |
| **Complexity** | "Docker adds unnecessary complexity" | "Docker removes environment complexity. One command to run = simpler." |
| **Later** | "We'll containerize before production" | "Later = never. Containerize now while context is fresh." |
| **Simple App** | "Just use docker run" | "docker-compose ensures reproducibility. Even single-service apps need it." |

**Non-negotiable principle:** If the application can run in a container, it MUST be containerized in Gate 1.

## Common Rationalizations - REJECTED

| Excuse | Reality |
|--------|---------|
| "Works fine locally" | Your machine ≠ production. Docker = consistency. |
| "Docker is overkill for this" | Docker is baseline, not overkill. Complexity is hidden, not added. |
| "We'll add Docker later" | Later = never. Context lost = mistakes made. |
| "Just need docker run" | docker-compose is reproducible. docker run is not documented. |
| "CI/CD will handle Docker" | CI/CD uses your Dockerfile. No Dockerfile = no CI/CD. |
| "It's just a script/tool" | Scripts need reproducible environments too. Containerize. |
| "Demo tomorrow, Docker later" | Demo with environment issues = failed demo. Docker BEFORE demo. |
| "Works on demo machine" | Demo machine ≠ production. Docker ensures consistency. |
| "Quick demo setup, proper later" | Quick setup becomes permanent. Proper setup now or never. |

## Red Flags - STOP

If you catch yourself thinking ANY of these, STOP immediately:

- "This works fine without Docker"
- "Docker is too complex for this project"
- "We can add containerization later"
- "docker run is good enough"
- "It's just an internal tool"
- "The developer can set up their own environment"
- "Demo tomorrow, Docker later"
- "Works on demo machine"
- "Quick setup for demo, proper later"

**All of these indicate Gate 1 violation. Proceed with containerization.**

## Modern Deployment Patterns

**Different deployment targets still require containerization for development parity:**

| Deployment Target | Development Requirement | Why |
|-------------------|------------------------|-----|
| **Traditional VM/Server** | Dockerfile + docker-compose | Standard containerization |
| **Kubernetes** | Dockerfile + docker-compose + Helm optional | K8s uses containers |
| **AWS Lambda/Serverless** | Dockerfile OR SAM template | Local testing needs container |
| **Vercel/Netlify** | Dockerfile for local dev | Platform builds ≠ local builds |
| **Static Site (CDN)** | Optional (nginx container for parity) | Recommended but not required |

### Serverless Applications

**Lambda/Cloud Functions still need local containerization:**

```yaml
# For AWS Lambda - use SAM or serverless framework
# sam local invoke uses Docker under the hood

# docker-compose.yml for serverless local dev
services:
  lambda-local:
    build: .
    command: sam local start-api
    ports:
      - "3000:3000"
    volumes:
      - .:/var/task
```

**Serverless does NOT exempt from Gate 1. It changes the containerization approach.**

### Platform-Managed Deployments (Vercel, Netlify, Railway)

**Even when platform handles production containers:**

| Platform Handles | You Still Need | Why |
|------------------|----------------|-----|
| Production build | Dockerfile for local | Parity between local and prod |
| Scaling | docker-compose | Team onboarding consistency |
| SSL/CDN | .env.example | Environment documentation |

**Anti-Rationalization for Serverless/Platform:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Lambda doesn't need Docker" | SAM uses Docker locally. Container is hidden, not absent. | **Use SAM/serverless containers** |
| "Vercel handles everything" | Vercel deploys. Local dev is YOUR problem. | **Dockerfile for local dev** |
| "Platform builds from source" | Platform build ≠ your local. Parity matters. | **Match platform build locally** |
| "Static site has no runtime" | Build process has runtime. Containerize the build. | **nginx or build container** |

## Demo Pressure Handling

**Demos do NOT justify skipping containerization:**

| Demo Scenario | Correct Response |
|--------------|------------------|
| "Demo tomorrow, no time for Docker" | Docker takes 30 min. 30 min now > environment crash during demo. |
| "Demo machine already configured" | Demo machine config will be lost. Docker is documentation. |
| "Just need to show it works" | Showing it works requires it to work. Docker ensures that. |
| "Will containerize after demo" | After demo = never. Containerize now. |

**Demo-specific guidance:**
1. Use docker-compose for demo (consistent environment)
2. Include `.env.demo` with demo-safe values
3. Document demo-specific overrides
4. Demo = test of deployment, not bypass of deployment

## Gate 1 Requirements

**MANDATORY unless ALL skip_when conditions apply:**
- All services MUST be containerized with Docker
- docker-compose.yml REQUIRED for any app with:
  - Database dependency
  - Multiple services
  - Environment variables
  - External API calls

**INVALID Skip Reasons:**
- ❌ "Application runs fine locally without Docker"
- ❌ "Docker adds complexity we don't need yet"
- ❌ "We'll containerize before production"
- ❌ "Just use docker run instead of compose"

**VALID Skip Reasons:**
- ✅ Only documentation changes (no code)
- ✅ Library/SDK with no runtime component
- ✅ Project explicitly documented as non-containerized (rare)

## Prerequisites

Before starting Gate 1:

1. **Gate 0 Complete**: Code implementation is done
2. **Environment Requirements**: List from Gate 0 handoff:
   - New dependencies
   - New environment variables
   - New services needed
3. **Existing Config**: Current Docker/compose files (if any)

## Step 1: Analyze DevOps Requirements

**From Gate 0:** New dependencies, env vars, services needed

**Check existing:** Dockerfile (EXISTS/MISSING), docker-compose.yml (EXISTS/MISSING), .env.example (EXISTS/MISSING)

**Determine actions:** Create/Update each file as needed based on gaps

## Step 2: Dispatch DevOps Agent

**MANDATORY:** `Task(subagent_type: "ring-dev-team:devops-engineer", model: "opus")`

**Prompt includes:** Gate 0 handoff summary, existing config files, requirements for Dockerfile/compose/.env/docs

| Component | Requirements |
|-----------|-------------|
| **Dockerfile** | Multi-stage build, non-root USER, specific versions (no :latest), health check, layer caching |
| **docker-compose.yml** | App service, DB/cache services, volumes, networks, depends_on with health checks |
| **.env.example** | All vars with placeholders, comments, grouped by service, marked required vs optional |
| **docs/LOCAL_SETUP.md** | Prerequisites, setup steps, run commands, troubleshooting |

**Agent returns:** Complete files + verification commands

## Step 3: Create/Update Dockerfile

**Pattern:** Multi-stage build → builder stage (deps first, then source) → production stage (non-root user, only artifacts)

**Required elements:** `WORKDIR /app`, `USER appuser` (non-root), `EXPOSE {port}`, `HEALTHCHECK` (30s interval, 3s timeout)

| Language | Builder | Runtime | Build Command | Notes |
|----------|---------|---------|---------------|-------|
| **Go** | `golang:1.21-alpine` | `alpine:3.19` | `CGO_ENABLED=0 go build` | Add ca-certificates, tzdata |
| **TypeScript** | `node:20-alpine` | `node:20-alpine` | `npm ci && npm run build` | `npm ci --only=production` in prod |
| **Python** | `python:3.11-slim` | `python:3.11-slim` | venv + `pip install` | Copy `/opt/venv` to prod |

## Step 4: Create/Update docker-compose.yml

**Version:** `3.8` | **Network:** `app-network` (bridge) | **Restart:** `unless-stopped`

| Service | Image | Ports | Volumes | Healthcheck | Key Config |
|---------|-------|-------|---------|-------------|------------|
| **app** | Build from Dockerfile | `${APP_PORT:-8080}:8080` | `.:/app:ro` | - | `depends_on` with `condition: service_healthy` |
| **db** | `postgres:15-alpine` | `${DB_PORT:-5432}:5432` | `postgres-data:/var/lib/postgresql/data` | `pg_isready -U $DB_USER` | POSTGRES_USER/PASSWORD/DB env vars |
| **redis** | `redis:7-alpine` | `${REDIS_PORT:-6379}:6379` | `redis-data:/data` | `redis-cli ping` | 10s interval, 5s timeout, 5 retries |

**Named volumes:** `postgres-data`, `redis-data`

## Step 5: Create/Update .env.example

**Format:** Grouped by service, comments explaining each, defaults shown with `:-` syntax

| Group | Variables | Format/Notes |
|-------|-----------|--------------|
| **Application** | `APP_PORT=8080`, `APP_ENV=development`, `LOG_LEVEL=info` | Standard app config |
| **Database** | `DATABASE_URL=postgres://user:pass@host:port/db` | Or individual: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME |
| **Redis** | `REDIS_URL=redis://redis:6379` | Connection string |
| **Auth** | `JWT_SECRET=...`, `JWT_EXPIRATION=1h` | Generate secret: `openssl rand -hex 32` |
| **External** | Commented placeholders | `# STRIPE_API_KEY=sk_test_...` |

## Step 6: Create Local Setup Documentation

Create `docs/LOCAL_SETUP.md` with these sections:

| Section | Content |
|---------|---------|
| **Prerequisites** | Docker ≥24.0, Docker Compose ≥2.20, Make (optional) |
| **Quick Start** | 1. Clone → 2. `cp .env.example .env` → 3. `docker-compose up -d` → 4. Verify `docker-compose ps` |
| **Services** | Table: Service, URL, Description (App/DB/Cache) |
| **Commands** | `up -d`, `down`, `build`, `logs -f`, `exec app [cmd]`, `exec db psql`, `exec redis redis-cli` |
| **Troubleshooting** | Port in use (`lsof -i`), DB refused (check `ps`, `logs`), Permissions (`down -v`, `up -d`) |

## Step 7: Verify Setup Works

**Commands:** `docker-compose build` → `docker-compose up -d` → `docker-compose ps` → `docker-compose logs app | grep -i error`

**Checklist:** Build succeeds ✓ | Services start ✓ | All healthy ✓ | No errors ✓ | DB connects ✓ | Redis connects ✓

## Step 8: Prepare Handoff to Gate 2

**Handoff format:** DevOps status (COMPLETE/PARTIAL) | Files changed (Dockerfile, compose, .env, docs) | Services configured (App:port, DB:type/port, Cache:type/port) | Env vars added | Verification results (build/startup/connectivity: PASS/FAIL) | Ready for testing: YES/NO

## Common DevOps Patterns

| Pattern | File | Key Config |
|---------|------|------------|
| **Multi-env** | `docker-compose.override.yml` (dev) / `.prod.yml` | `target: development/production`, volumes, memory limits |
| **Migrations** | Separate service in compose | `command: ["./migrate", "up"]`, `depends_on: db: condition: service_healthy` |
| **Hot Reload** | Override compose | Go: `air -c .air.toml`, Node: `npm run dev` with volume mounts |

## Execution Report

| Metric | Value |
|--------|-------|
| Duration | Xm Ys |
| Iterations | N |
| Result | PASS/FAIL/PARTIAL |

### Details
- dockerfile_action: CREATED/UPDATED/UNCHANGED
- compose_action: CREATED/UPDATED/UNCHANGED
- env_example_action: CREATED/UPDATED/UNCHANGED
- services_configured: N
- env_vars_documented: N
- verification_passed: YES/NO

### Issues Encountered
- List any issues or "None"

### Handoff to Next Gate
- DevOps status (complete/partial)
- Services configured and ports
- New environment variables
- Verification results
- Ready for testing: YES/NO
