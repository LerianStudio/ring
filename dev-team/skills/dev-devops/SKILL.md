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
    - command: "curl -sf http://localhost:8080/health || curl -sf http://localhost:3000/health"
      description: "Health endpoint responds"
      success_pattern: "200|ok|healthy"
    - command: "grep -r 'runs-on:' .github/workflows/ 2>/dev/null | grep -v 'shared-workflows' | head -1"
      description: "No inline/hardcoded pipeline jobs"
      success_pattern: "^$"
      failure_pattern: "runs-on:"
    - command: "terraform fmt -check -recursive 2>/dev/null || echo 'terraform not installed or not a terraform project'"
      description: "Terraform files are properly formatted"
      success_pattern: "^$|not a terraform"
      failure_pattern: ".tf"
    - command: "grep -rE 'source\\s*=\\s*\"\\./' *.tf 2>/dev/null | head -1"
      description: "No internal Terraform modules"
      success_pattern: "^$"
      failure_pattern: "source"
    - command: "grep -E '^FROM\\s+(alpine|ubuntu)' Dockerfile 2>/dev/null | grep -v 'AS builder'"
      description: "No Alpine/Ubuntu final image"
      success_pattern: "^$"
      failure_pattern: "FROM"
    - command: "grep 'gcr.io/distroless/static-debian12' Dockerfile 2>/dev/null"
      description: "Uses distroless final image"
      success_pattern: "distroless"
      failure_pattern: "^$"
    - command: "grep -E '^ARG.*(TOKEN|SECRET|PASSWORD|KEY)' Dockerfile 2>/dev/null"
      description: "No secrets in build arguments"
      success_pattern: "^$"
      failure_pattern: "ARG"
    - command: "grep 'CGO_ENABLED=0' Dockerfile 2>/dev/null"
      description: "Static binary (CGO disabled)"
      success_pattern: "CGO_ENABLED=0"
      failure_pattern: "^$"
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

## Shared Workflows Compliance (MANDATORY)

> **STRICT RULE:** All CI/CD pipelines MUST use shared workflows from `LerianStudio/github-actions-shared-workflows`.

### Pre-Implementation Check

Before creating ANY pipeline file:

```bash
# Check if shared workflow exists for your need
# Repository: https://github.com/LerianStudio/github-actions-shared-workflows

# Available workflows:
# - pr-security-scan.yml     → Security scanning on PRs
# - pr-validation.yml        → Semantic PR titles, size checks
# - go-pr-analysis.yml       → Go CI: lint, test, coverage
# - go-release.yml           → GoReleaser automation
# - release.yml              → Semantic versioning
# - gitops-update.yml        → Deploy to environments
# - api-dog-e2e-tests.yml    → E2E testing
# - changed-paths.yml        → Monorepo path detection
# - build.yml                → Docker build
```

### Compliance Verification Commands

```bash
# MUST PASS: No inline jobs in workflows
grep -r "runs-on:" .github/workflows/ 2>/dev/null | grep -v "shared-workflows"
# Expected: No output (empty = PASS)

# MUST PASS: Using shared workflows
grep -r "uses:.*LerianStudio/github-actions-shared-workflows" .github/workflows/
# Expected: At least one match

# MUST PASS: No forbidden patterns
grep -rE "(golangci-lint-action|setup-go|docker/build-push-action)" .github/workflows/ 2>/dev/null | grep -v "shared-workflows"
# Expected: No output (these should come from shared workflows)
```

### If Shared Workflow is Missing

**DO NOT create inline jobs. Report blocker:**

```markdown
## Blockers
- **Missing Shared Workflow:** [describe needed functionality]
- **Required Action:** Create workflow in LerianStudio/github-actions-shared-workflows
- **Status:** BLOCKED until shared workflow exists
```

### Valid vs Invalid Pipeline Patterns

**VALID:**
```yaml
jobs:
  ci:
    uses: LerianStudio/github-actions-shared-workflows/.github/workflows/go-pr-analysis.yml@v1.0.0
    secrets: inherit
```

**INVALID (FORBIDDEN):**
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: golangci/golangci-lint-action@v4
```

## Terraform Compliance (MANDATORY)

> **STRICT RULE:** All Terraform infrastructure MUST follow patterns from `LerianStudio/midaz-terraform-foundation`. Internal modules are FORBIDDEN.

### Reference Repository

**Source of Truth:** `LerianStudio/midaz-terraform-foundation`

This repository demonstrates proper use of official Terraform Registry modules for AWS, GCP, and Azure.

### Pre-Implementation Checks

Before writing ANY Terraform:

```bash
# 1. Check midaz-terraform-foundation for existing patterns
# Repository: https://github.com/LerianStudio/midaz-terraform-foundation/tree/main/examples

# 2. Verify component structure exists
ls -la {component}/
# Expected: main.tf, variables.tf, outputs.tf, backend.tf, versions.tf

# 3. Check official module availability
# AWS: https://registry.terraform.io/namespaces/terraform-aws-modules
# GCP: https://registry.terraform.io/namespaces/terraform-google-modules
```

### Compliance Verification Commands

```bash
# MUST PASS: terraform fmt check
terraform fmt -check -recursive
# Expected: Exit code 0 (no output = formatted correctly)

# MUST PASS: No internal modules (local paths)
grep -rE "source\s*=\s*\"\./" *.tf 2>/dev/null
# Expected: No output

# MUST PASS: No internal modules (git repos)
grep -rE "source\s*=\s*\"git::" *.tf 2>/dev/null | grep -v "terraform-aws-modules\|terraform-google-modules"
# Expected: No output

# MUST HAVE: Remote backend
grep -l "backend" backend.tf 2>/dev/null
# Expected: backend.tf

# MUST HAVE: ManagedBy tag
grep -E "ManagedBy.*=.*Terraform" *.tf 2>/dev/null
# Expected: At least one match
```

### Official Modules Quick Reference

**AWS:**
- VPC: `terraform-aws-modules/vpc/aws` ~> 5.0
- EKS: `terraform-aws-modules/eks/aws` ~> 21.0
- RDS: `terraform-aws-modules/rds/aws` ~> 6.0

**GCP:**
- GKE: `terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster` ~> 36.0

**Azure:**
- Use native `azurerm_*` resources

### If Internal Module Seems Needed

**DO NOT create internal modules. Report blocker:**

```markdown
## Blockers
- **Internal Module Request:** [describe needed functionality]
- **Official Module:** [module name] does not support this
- **Required Action:**
  1. Review official module docs again
  2. Use native provider resources
  3. OR request feature upstream
- **Status:** BLOCKED until official solution found
```

### Valid vs Invalid Terraform Patterns

**VALID - Official Module:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  # ...
}
```

**VALID - Native Resource:**
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  # ...
}
```

**INVALID - Internal Module (FORBIDDEN):**
```hcl
module "vpc" {
  source = "./modules/vpc"  # FORBIDDEN
}

module "eks" {
  source = "git::https://github.com/company/terraform-modules//eks"  # FORBIDDEN
}
```

## Dockerfile Standards Compliance (MANDATORY)

> **STRICT RULE:** All Dockerfiles MUST use `gcr.io/distroless/static-debian12` as the final image. Alpine/Ubuntu final images are FORBIDDEN.

### Dockerfile Pattern Selection

Before creating ANY Dockerfile:

1. **Determine application type:**
   - OpenSource → Use flowker pattern
   - Closed Source/Licensed → Use plugin-fees pattern

2. **Verify requirements:**

| Criteria | OpenSource | Closed Source |
|----------|-----------|---------------|
| Public repository | YES | NO |
| Private Go modules | NO | YES |
| Code obfuscation needed | NO | YES |

### OpenSource Pattern (flowker)

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.25.3-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG TARGETPLATFORM
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$(echo $TARGETPLATFORM | cut -d'/' -f2) \
  go build -tags netgo -ldflags '-s -w -extldflags "-static"' -o /app/server cmd/app/main.go

FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Closed Source Pattern (plugin-fees)

```dockerfile
# syntax=docker/dockerfile:1.4
FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS builder
WORKDIR /app
ARG TARGETPLATFORM
RUN apk add --no-cache git && go install mvdan.cc/garble@latest
ENV PATH="/root/go/bin:${PATH}"
COPY go.mod go.sum ./
RUN --mount=type=secret,id=github_token \
  GITHUB_TOKEN=$(cat /run/secrets/github_token) && \
  printf "machine github.com\nlogin x-oauth-basic\npassword %s\n" "$GITHUB_TOKEN" > ~/.netrc && \
  go mod download && rm ~/.netrc
COPY . .
ENV GOGARBLE=app/v3,github.com/LerianStudio/lib-license-go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$(echo $TARGETPLATFORM | cut -d'/' -f2) \
  garble -tiny -literals build -tags netgo -ldflags '-w -extldflags "-static"' -o /app/server cmd/app/main.go

FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Compliance Verification Commands

```bash
# MUST PASS: No Alpine/Ubuntu final image
grep -E "^FROM\s+(alpine|ubuntu)" Dockerfile | grep -v "AS builder"
# Expected: No output (empty = PASS)

# MUST PASS: Uses distroless
grep "gcr.io/distroless/static-debian12" Dockerfile
# Expected: At least one match

# MUST PASS: Multi-stage build
grep -c "^FROM" Dockerfile
# Expected: 2 or more

# MUST PASS: No secrets in ARG
grep -E "^ARG.*(TOKEN|SECRET|PASSWORD|KEY)" Dockerfile
# Expected: No output (empty = PASS)

# MUST PASS: Static binary
grep "CGO_ENABLED=0" Dockerfile
# Expected: At least one match

# MUST PASS: Pinned version (no :latest)
grep -E "^FROM.*:latest" Dockerfile
# Expected: No output (empty = PASS)

# MUST PASS: Layer caching optimization
head -20 Dockerfile | grep -E "COPY go\.(mod|sum)"
# Expected: go.mod/go.sum copied before full COPY
```

### FORBIDDEN Patterns - Blocker

If ANY of these are detected, STOP and report blocker:

| Pattern | Detection Command | Action |
|---------|------------------|--------|
| Alpine final image | `grep "^FROM alpine" Dockerfile \| grep -v "AS builder"` | BLOCKER |
| Ubuntu final image | `grep "^FROM ubuntu" Dockerfile \| grep -v "AS builder"` | BLOCKER |
| Secrets in ARG | `grep "^ARG.*TOKEN" Dockerfile` | BLOCKER |
| :latest tag | `grep "^FROM.*:latest" Dockerfile` | BLOCKER |
| Missing CGO_ENABLED=0 | `! grep "CGO_ENABLED=0" Dockerfile` | BLOCKER |

**Report blocker format:**

```markdown
## Blockers
- **Dockerfile Violation:** [describe: Alpine final, secrets in ARG, etc.]
- **Detection:** [command that found violation]
- **Required:** Use Ring Dockerfile Standards ([OpenSource/Closed Source] pattern)
- **Status:** BLOCKED until Dockerfile is compliant
```

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

**Pattern Selection:** OpenSource (public repo, no private deps) OR Closed Source (private repo, obfuscation needed)

**MANDATORY for ALL Dockerfiles:**

| Requirement | Value | Reason |
|-------------|-------|--------|
| Final image | `gcr.io/distroless/static-debian12` | Security, minimal attack surface |
| Build platform | `--platform=$BUILDPLATFORM` | Multi-arch support |
| Base version | Pinned (e.g., `golang:1.25.3-alpine`) | Reproducibility |
| CGO | `CGO_ENABLED=0` | Static binary |
| LDFLAGS | `-s -w -extldflags "-static"` | Stripped, static binary |
| Layer caching | `COPY go.mod go.sum` before `COPY .` | Build performance |

**Language-Specific Patterns:**

| Language | Builder | Final | Key Flags |
|----------|---------|-------|-----------|
| **Go (OpenSource)** | `golang:X.X.X-alpine` | `gcr.io/distroless/static-debian12` | `-ldflags '-s -w'` |
| **Go (Closed Source)** | `golang:X.X.X-alpine` + garble | `gcr.io/distroless/static-debian12` | `garble -tiny -literals` |
| **TypeScript** | `node:20-alpine` | `gcr.io/distroless/nodejs20-debian12` | `npm ci --only=production` |

**FORBIDDEN - Will fail Gate 1:**
- Alpine/Ubuntu as final image
- Secrets in ARG/ENV
- `:latest` tag
- Missing CGO_ENABLED=0
- Single-stage builds

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

**Commands:** `docker-compose build` → `docker-compose up -d` → `docker-compose ps` → `curl localhost:8080/health` → `docker-compose logs app | grep -i error`

**Checklist:** Build succeeds ✓ | Services start ✓ | All healthy ✓ | Health responds ✓ | No errors ✓ | DB connects ✓ | Redis connects ✓

**Shared Workflows Checklist (if pipelines exist):**
- [ ] No inline pipeline jobs (grep verification passed)
- [ ] All pipelines use shared workflows from LerianStudio/github-actions-shared-workflows
- [ ] Pipeline versions pinned appropriately (semantic versions for production)

**Terraform Checklist (if Terraform project):**
- [ ] `terraform fmt -check -recursive` passes (if Terraform project)
- [ ] No internal modules (grep verification passed)
- [ ] Remote backend configured in backend.tf
- [ ] Standard tags present (Environment, ManagedBy)
- [ ] Using official modules per midaz-terraform-foundation patterns

**Dockerfile Checklist (MANDATORY):**
- [ ] Dockerfile uses `gcr.io/distroless/static-debian12` final image
- [ ] No Alpine/Ubuntu final images (grep verification passed)
- [ ] No secrets in build arguments
- [ ] CGO_ENABLED=0 for static binary
- [ ] Base image version pinned (no :latest)
- [ ] Multi-stage build (2+ FROM statements)
- [ ] Layer caching optimized (go.mod/go.sum before COPY .)

## Step 8: Prepare Handoff to Gate 2

**Handoff format:** DevOps status (COMPLETE/PARTIAL) | Files changed (Dockerfile, compose, .env, docs) | Services configured (App:port, DB:type/port, Cache:type/port) | Env vars added | Verification results (build/startup/health/connectivity: PASS/FAIL) | Ready for testing: YES/NO

**Shared Workflows Compliance:**
- CI Pipeline: USING SHARED/NOT APPLICABLE/BLOCKER
- Release Pipeline: USING SHARED/NOT APPLICABLE/BLOCKER
- Inline Jobs: NONE FOUND/VIOLATION DETECTED

**Pipeline Verification:**
- Inline job check: PASS/FAIL
- Shared workflow usage: YES/NO/N/A

**Terraform Compliance:**
- terraform fmt check: PASS/FAIL/N/A
- Internal modules: NONE FOUND/VIOLATION DETECTED/N/A
- Remote backend: CONFIGURED/MISSING/N/A
- Standard tags: PRESENT/MISSING/N/A
- Official modules: YES/VIOLATION/N/A

**Dockerfile Compliance:**
- Final image: DISTROLESS/VIOLATION
- Multi-stage build: YES/NO
- Static binary (CGO_ENABLED=0): YES/NO
- Secrets handling: BUILDKIT_SECRETS/ARG_VIOLATION/N/A
- Base version pinned: YES/NO
- Pattern used: OPENSOURCE/CLOSED_SOURCE

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
