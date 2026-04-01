---
name: ring:dev-docker-security
description: |
  Creates or audits Dockerfiles and Docker image configurations to achieve
  Docker Hub Health Score grade A. Enforces all evaluable security policies
  and supply chain best practices.

trigger: |
  - Creating a new Dockerfile
  - Auditing an existing Dockerfile for security
  - Preparing images for Docker Hub publication
  - Docker Hub health score is below grade A

related:
  complementary: [ring:dev-devops, ring:dev-sre]

input_schema:
  required:
    - name: dockerfile_path
      type: string
      description: "Path to the Dockerfile to create or audit"
  optional:
    - name: base_image
      type: string
      description: "Preferred base image (e.g., gcr.io/distroless/static-debian12)"
    - name: language
      type: string
      enum: [go, typescript, python, rust, java]
      description: "Programming language of the application"
    - name: service_type
      type: string
      enum: [api, worker, batch, cli]
      description: "Type of service"
    - name: mode
      type: string
      enum: [create, audit]
      default: audit
      description: "Create a new Dockerfile or audit an existing one"

output_schema:
  format: markdown
  required_sections:
    - name: "Health Score Compliance"
      pattern: "^## Health Score Compliance"
      required: true
    - name: "Policy Results"
      pattern: "^### Policy Results"
      required: true
    - name: "Actions Taken"
      pattern: "^## Actions Taken"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: policies_met
      type: integer
    - name: policies_total
      type: integer
---

# Docker Security — Docker Hub Health Score Grade A

## Overview

> General Dockerfile patterns are documented in [dev-team/docs/standards/devops.md#containers](../../docs/standards/devops.md#containers). This skill focuses specifically on Docker Hub Health Score compliance.

This skill creates or audits Dockerfiles and image configurations to achieve **Docker Hub Health Score grade A**.

## Docker Hub Health Score Policies

| # | Policy | Weight | How to Comply |
|---|--------|--------|---------------|
| 1 | **Default non-root user** | Required | Dockerfile MUST have a `USER` directive with a non-root user |
| 2 | **No fixable critical/high CVEs** | Required | Zero critical/high vulnerabilities with available fixes |
| 3 | **No high-profile vulnerabilities** | Required | Zero CVEs in the CISA KEV catalog |
| 4 | **No AGPL v3 licenses** | Required | No packages with AGPL-3.0 licenses |
| 5 | **Supply chain attestations** | Required | SBOM + provenance attached to pushed images (pipeline config) |
| 6 | **No outdated base images** | Optional | Only evaluated for Docker Hub hosted base images |
| 7 | **No unapproved base images** | Optional | Only evaluated for Docker Hub hosted base images |

Policies 6 and 7 are **optional** — not evaluated when using non-Docker Hub base images (e.g., `gcr.io/distroless`). Do not treat them as blockers.

---

## Pipeline Enforcement

These policies are automatically enforced on every PR that changes application components. The **PR Security Scan** workflow blocks merge if any required policy fails.

### What happens on every PR

1. Docker image is built from the Dockerfile in the PR
2. **Trivy** scans the image for vulnerabilities and AGPL-3.0 licenses
3. **Dockerfile analysis** verifies the `USER` directive
4. **CISA KEV cross-reference** checks found CVEs against the Known Exploited Vulnerabilities catalog
5. **Health Score Compliance table** is posted as a PR comment

### Merge gate

Any policy failure blocks the PR — missing `USER` directive, a fixable critical/high CVE, a KEV vulnerability, or an AGPL-3.0 package.

Policy 5 (SBOM + provenance) is evaluated only on release builds via pipeline config:

```yaml
sbom: generator=docker/scout-sbom-indexer:latest
provenance: mode=max
```

---

## Step 1: Analyze Current State

```text
1. Read the Dockerfile (if mode=audit)
2. Identify: base image, build stages, USER directive, package installation
3. If mode=create, gather requirements from inputs
```

## Step 2: Apply Security Policies

### Policy 1 — Default Non-Root User

Every Dockerfile MUST set a non-root user after all `RUN`/`COPY` steps:

```dockerfile
USER nonroot:nonroot          # distroless (pre-existing user)

# Alpine: create user first
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Debian/Ubuntu: create user first
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser
```

`USER root` does NOT satisfy this policy. The user must be non-root and must exist in the image.

### Policies 2 & 3 — No Fixable CVEs / No KEV Vulnerabilities

Both policies share the same remediation — minimize the attack surface:

- **Prefer distroless** — ~0 CVEs (no shell, no package manager)
- **Alpine over Debian/Ubuntu** — fewer packages = fewer CVEs
- **Multi-stage builds** — build tools stay in builder, only runtime in final
- **Pin versions** — avoid pulling newly vulnerable packages
- **Update base images regularly**

```dockerfile
FROM gcr.io/distroless/static-debian12    # Go (statically compiled)
FROM gcr.io/distroless/base-debian12      # Dynamically linked
FROM node:22-alpine                        # Node.js
```

### Policy 4 — No AGPL v3 Licenses

Audit dependencies before adding them. Use `trivy fs --scanners license` to check. If AGPL-3.0 is found, replace the dependency. This applies to ALL packages in the final image, including OS packages.

### Policy 5 — Supply Chain Attestations

Not a Dockerfile concern — configured in the build pipeline (`sbom:` + `provenance: mode=max`). When auditing, verify the CI/CD pipeline includes both parameters.

---

## Step 3: Dockerfile Templates

### Go Service

```dockerfile
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /app/server ./cmd/app

FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /server
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/server"]
```

### Node.js Service

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:22-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 3000
USER appuser
CMD ["node", "dist/index.js"]
```

### Python Service

```dockerfile
FROM python:3.13-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt
COPY . .

FROM python:3.13-slim
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY --from=builder /app .
EXPOSE 8000
USER appuser
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Step 4: Audit Checklist

```text
CRITICAL (blocks grade A):
[ ] USER directive exists with non-root user
[ ] Multi-stage build (build tools not in final image)
[ ] Minimal base image (distroless/alpine preferred)
[ ] No secrets or credentials in image layers

HIGH (impacts CVE count):
[ ] Base image is up to date
[ ] Package versions are pinned
[ ] No development dependencies in final image

MEDIUM (best practices):
[ ] .dockerignore excludes .git, node_modules, etc.
[ ] COPY used instead of ADD
[ ] Build cache leveraged (COPY deps before source)

SUPPLY CHAIN (pipeline):
[ ] sbom: parameter in build-push-action
[ ] provenance: mode=max in build-push-action
```

---

## Step 5: Generate Report

```markdown
## Health Score Compliance

**Target:** Grade A
**Result:** [PASS|FAIL]

### Policy Results

| Policy | Status | Details |
|--------|--------|---------|
| Default non-root user | [PASS/FAIL] | USER [username] at line [N] |
| No fixable critical/high CVEs | [PASS/RISK] | Base: [image], [N] packages in final |
| No high-profile vulnerabilities | [PASS/RISK] | Base image [up to date/outdated] |
| No AGPL v3 licenses | [PASS/RISK] | [N] dependencies audited |
| Supply chain attestations | [PASS/MISSING] | sbom: [yes/no], provenance: [yes/no] |

## Actions Taken

| File | Action | Changes |
|------|--------|---------|
| Dockerfile | [CREATED/UPDATED] | [summary] |
| .dockerignore | [CREATED/UPDATED/UNCHANGED] | [summary] |
```

---

## Severity Calibration

| Severity | Criteria | Examples |
|----------|----------|----------|
| **CRITICAL** | Blocks grade A | Missing USER, running as root, secrets in layers |
| **HIGH** | Causes CVE failures | Full debian base, unpinned versions, outdated base |
| **MEDIUM** | Reduces security posture | No .dockerignore, ADD instead of COPY, no multi-stage |
| **LOW** | Best practice deviation | Missing labels, suboptimal layer ordering |
