---
name: ring:dev-docker-security
description: |
  Creates or audits Dockerfiles to achieve Docker Hub Health Score grade A.
  Enforces non-root user, minimal base images, supply chain attestations,
  and zero fixable CVEs.
---

# Docker Security (Health Score Grade A)

## When to use
- Creating a new Dockerfile
- Auditing an existing Dockerfile for security
- Preparing images for Docker Hub publication
- Docker Hub health score is below grade A

## Skip when
- Project has no Dockerfile and none is being created
- Changes are application-code only with no Docker modifications
- Using pre-built images without custom Dockerfile

## Related
**Complementary:** ring:dev-implementation, ring:dev-helm


General Dockerfile patterns: `dev-team/docs/standards/devops.md#containers`.
This skill focuses on Docker Hub Health Score compliance.

## Health Score Policies

| # | Policy | Weight | Compliance |
|---|--------|--------|------------|
| 1 | Default non-root user | Required | `USER` directive with non-root user |
| 2 | No fixable critical/high CVEs | Required | Distroless or Alpine, multi-stage |
| 3 | No high-profile vulnerabilities (CISA KEV) | Required | Up-to-date base images |
| 4 | No AGPL v3 licenses | Required | Audit dependencies |
| 5 | Supply chain attestations (SBOM + provenance) | Required | Pipeline config |
| 6 | No outdated base images | Optional | Only for Docker Hub hosted images |
| 7 | No unapproved base images | Optional | Only for Docker Hub hosted images |

Policies 6-7 are **not evaluated** when using non-Docker Hub base images (gcr.io/distroless, etc.).

## Policy Implementation

### Policy 1 — Non-Root User

```dockerfile
# Alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Debian/Ubuntu
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

# Distroless (pre-existing user)
USER nonroot:nonroot
```

`USER root` does NOT satisfy this policy.

### Policies 2 & 3 — Minimal Attack Surface

```dockerfile
# Go (statically compiled) — ~0 CVEs
FROM gcr.io/distroless/static-debian12

# Go (CGO) or general
FROM gcr.io/distroless/base-debian12

# Node.js
FROM node:22-alpine

# Multi-stage mandatory
FROM golang:1.23-alpine AS builder
# ... build ...
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/binary /app/binary
```

### Policy 4 — No AGPL v3

```bash
trivy fs --scanners license --severity CRITICAL .
```

Replace any AGPL-3.0 dependency.

### Policy 5 — Supply Chain Attestations (Pipeline)

```yaml
# build-push-action config
sbom: generator=docker/scout-sbom-indexer:latest
provenance: mode=max
```

Not a Dockerfile concern — verify CI/CD includes both parameters.

## Dockerfile Templates

### Go Service
```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app ./cmd/...

FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/app /app/app
EXPOSE 3000
USER nonroot:nonroot
ENTRYPOINT ["/app/app"]
```

### TypeScript/Node.js
```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:22-alpine
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
USER appuser
CMD ["node", "dist/index.js"]
```

## Audit Checklist

```
CRITICAL (blocks grade A):
[ ] USER directive with non-root user
[ ] Multi-stage build (no build tools in final)
[ ] Minimal base image (distroless/alpine)
[ ] No secrets in image layers

HIGH (CVE risk):
[ ] Base image is up to date
[ ] Package versions pinned
[ ] No dev dependencies in final stage

MEDIUM:
[ ] .dockerignore excludes .git, node_modules, test files
[ ] COPY used (not ADD)
[ ] Cache layers ordered: deps before source

SUPPLY CHAIN (pipeline):
[ ] sbom: parameter in build-push-action
[ ] provenance: mode=max
```

## Report Template

```markdown
## Health Score Compliance

| Policy | Status | Details |
|--------|--------|---------|
| Default non-root user | PASS/FAIL | USER {user} at line {N} |
| No fixable CVEs | PASS/RISK | Base: {image} |
| No KEV vulnerabilities | PASS/RISK | Base image {status} |
| No AGPL v3 licenses | PASS/RISK | {N} deps audited |
| Supply chain attestations | PASS/MISSING | sbom: {yes/no}, provenance: {yes/no} |

**Grade A: {ACHIEVED / NOT ACHIEVED}**

## Actions Taken
| File | Action | Changes |
```
