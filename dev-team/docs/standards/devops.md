# DevOps Standards

This file defines the specific standards for DevOps, SRE, and infrastructure.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Cloud Provider

| Provider | Primary Services |
|----------|-----------------|
| AWS | EKS, RDS, S3, Lambda, SQS |
| GCP | GKE, Cloud SQL, Cloud Storage |
| Azure | AKS, Azure SQL, Blob Storage |

---

## Infrastructure as Code

### Terraform (Preferred)

#### Project Structure

```
/terraform
  /modules
    /vpc
      main.tf
      variables.tf
      outputs.tf
    /eks
    /rds
  /environments
    /dev
      main.tf
      terraform.tfvars
    /staging
    /prod
  backend.tf
  providers.tf
  versions.tf
```

#### State Management

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "env/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

#### Module Pattern

```hcl
# modules/eks/main.tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_groups = {
    default = {
      min_size     = var.min_nodes
      max_size     = var.max_nodes
      desired_size = var.desired_nodes

      instance_types = var.instance_types
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = var.tags
}

# modules/eks/variables.tf
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.28"
  description = "Kubernetes version"
}

# modules/eks/outputs.tf
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}
```

#### Best Practices

```hcl
# Always use version constraints
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Use data sources for existing resources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Use locals for computed values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  name_prefix = "${var.project}-${var.environment}"
}

# Always tag resources
resource "aws_instance" "example" {
  # ...

  tags = merge(var.common_tags, {
    Name        = "${local.name_prefix}-instance"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
```

### Terraform Standards (midaz-terraform-foundation) - MANDATORY

> **STRICT RULE:** Internal/custom Terraform modules are FORBIDDEN. Always use official modules from the Terraform Registry as demonstrated in `LerianStudio/midaz-terraform-foundation`.

**Reference Repository:** `LerianStudio/midaz-terraform-foundation`

This repository provides reference Terraform examples for deploying foundation infrastructure on AWS, GCP, and Azure. All infrastructure MUST follow these patterns.

#### Official Modules Catalog (MANDATORY)

**AWS Official Modules:**

| Component | Module | Version | Registry |
|-----------|--------|---------|----------|
| VPC | `terraform-aws-modules/vpc/aws` | `~> 5.0` | [Link](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) |
| VPC Endpoints | `terraform-aws-modules/vpc/aws//modules/vpc-endpoints` | `~> 5.0` | Same module |
| EKS | `terraform-aws-modules/eks/aws` | `~> 21.0` | [Link](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws) |
| RDS | `terraform-aws-modules/rds/aws` | `~> 6.0` | [Link](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws) |

**GCP Official Modules:**

| Component | Module | Version | Registry |
|-----------|--------|---------|----------|
| GKE | `terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster` | `~> 36.0` | [Link](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google) |
| VPC | Native `google_compute_network` resources | N/A | Use google provider resources |

**Azure Resources:**

| Component | Resource | Notes |
|-----------|----------|-------|
| AKS | `azurerm_kubernetes_cluster` | Native resource |
| Network | `azurerm_virtual_network`, `azurerm_subnet` | Native resources |
| DNS | `azurerm_dns_zone` | Native resource |

#### Standard File Structure (MANDATORY)

Every Terraform component MUST have this structure:

```
{component}/
├── main.tf        # Module calls and resources
├── variables.tf   # Input variables with descriptions
├── outputs.tf     # Output values
├── backend.tf     # Remote state configuration (REQUIRED)
├── versions.tf    # Provider and terraform version constraints
├── data.tf        # Data sources (optional)
└── *.tfvars       # Variable values (NEVER commit with secrets)
```

#### Tagging Standard (MANDATORY)

All resources MUST have these tags:

```hcl
tags = merge({
  Environment = lower(var.environment)
  ManagedBy   = "Terraform"
}, var.additional_tags)
```

**Required tags:**
- `Environment` - Must use `lower(var.environment)` for consistency
- `ManagedBy` - Always set to `"Terraform"`
- `additional_tags` - Variable for project-specific tags

#### Remote State Configuration (MANDATORY)

No local state allowed. ALL Terraform MUST use remote state with locking.

**AWS Backend:**
```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "component/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

**GCP Backend:**
```hcl
terraform {
  backend "gcs" {
    bucket = "company-terraform-state"
    prefix = "component"
  }
}
```

**Azure Backend:**
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate"
    container_name       = "terraform-state"
    key                  = "component.tfstate"
  }
}
```

#### Version Constraints (MANDATORY)

```hcl
# versions.tf
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # OR for GCP
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # OR for Azure
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
```

#### terraform fmt (MANDATORY)

All Terraform files MUST be formatted with `terraform fmt`:

```bash
# Format all files
terraform fmt -recursive

# Check formatting (CI/CD)
terraform fmt -check -recursive
# Exit code 0 = formatted, non-zero = needs formatting
```

**This check MUST pass before any commit or PR merge.**

#### FORBIDDEN Patterns

**NEVER create internal/custom modules:**
```hcl
# FORBIDDEN: Internal module
module "vpc" {
  source = "./modules/vpc"  # WRONG - internal module
}

module "eks" {
  source = "git::https://github.com/company/terraform-modules//eks"  # WRONG - internal repo
}
```

**ALWAYS use official Terraform Registry modules:**
```hcl
# CORRECT: Official module from Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
}
```

#### When Official Module Doesn't Cover Your Need

**DO NOT create internal modules. Instead:**

1. **Check if feature exists:** Review official module documentation thoroughly
2. **Use native resources:** If module doesn't support it, use provider resources directly
3. **Request feature upstream:** Open issue/PR on the official module repository
4. **Document workaround:** If using native resources, document why in code comments

**Blocker format when internal module seems needed:**
```markdown
## Blockers
- **Infrastructure Gap:** [describe needed functionality]
- **Official Module:** [module name] does not support this
- **Required Action:**
  1. Check official module docs again
  2. Use native provider resources
  3. OR request feature upstream
- **Status:** BLOCKED - Cannot create internal module
```

#### Compliance Verification Commands

```bash
# MUST PASS: terraform fmt check
terraform fmt -check -recursive
# Expected: Exit code 0

# MUST PASS: No internal modules
grep -rE "source\s*=\s*\"\./" *.tf 2>/dev/null
# Expected: No output

grep -rE "source\s*=\s*\"git::" *.tf 2>/dev/null
# Expected: No output (unless official module)

# MUST HAVE: Remote backend configured
grep -l "backend" backend.tf
# Expected: backend.tf found

# MUST HAVE: Standard tags
grep -E "ManagedBy.*Terraform" *.tf
# Expected: At least one match
```

#### Reference Examples

See `LerianStudio/midaz-terraform-foundation/examples/` for complete reference implementations:

```
examples/
├── aws/
│   ├── vpc/          # VPC with subnets, NAT, flow logs
│   ├── eks/          # EKS with managed node groups
│   ├── rds/          # RDS with replica support
│   └── valkey/       # ElastiCache Valkey
├── gcp/
│   ├── vpc/          # VPC with subnets
│   ├── gke/          # GKE private cluster
│   └── cloud-sql/    # Cloud SQL PostgreSQL
└── azure/
    ├── network/      # VNet with subnets
    ├── aks/          # AKS cluster
    └── database/     # Azure Database
```

---

## Containers

### Dockerfile Standards (MANDATORY)

> **STRICT RULE:** Alpine/Ubuntu final images are FORBIDDEN. All production images MUST use `gcr.io/distroless/static-debian12` as the final stage.

The organization maintains TWO Dockerfile patterns based on application licensing:

1. **OpenSource Applications** - Standard multi-stage builds (flowker pattern)
2. **Closed Source + Licensed Applications** - Garble obfuscation builds (plugin-fees pattern)

#### OpenSource Applications (flowker pattern)

For all public repositories and open-source applications:

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.25.3-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ARG TARGETPLATFORM
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$(echo $TARGETPLATFORM | cut -d'/' -f2) go build -tags netgo -ldflags '-s -w -extldflags "-static"' -o /app/server cmd/app/main.go

FROM gcr.io/distroless/static-debian12

COPY --from=builder /app/server /server
COPY --from=builder /app/migrations /migrations

EXPOSE 8080

ENTRYPOINT ["/server"]
```

**Key Elements:**
- `--platform=$BUILDPLATFORM` for multi-platform builds
- `golang:X.X.X-alpine` for builder (pinned version, NOT latest)
- Layer caching: `COPY go.mod go.sum ./` then `RUN go mod download` BEFORE `COPY . .`
- `CGO_ENABLED=0` for static binary
- `-ldflags '-s -w'` strips debug info (smaller binary)
- `gcr.io/distroless/static-debian12` final image (MANDATORY)
- No USER directive needed (distroless runs as nonroot by default)

#### Closed Source + Licensed Applications (plugin-fees pattern)

For private repositories with licensed code requiring obfuscation:

```dockerfile
# syntax=docker/dockerfile:1.4

# --- Build stage ---
FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS builder

WORKDIR /app

ARG TARGETPLATFORM

# Install git and garble for code obfuscation
RUN apk add --no-cache git && \
    go install mvdan.cc/garble@latest

ENV PATH="/root/go/bin:${PATH}"

COPY go.mod go.sum ./

# Use BuildKit secret for GitHub token (private modules)
RUN --mount=type=secret,id=github_token \
  GITHUB_TOKEN=$(cat /run/secrets/github_token) && \
  printf "machine github.com\nlogin x-oauth-basic\npassword %s\n" "$GITHUB_TOKEN" > ~/.netrc && \
  go mod download && \
  rm ~/.netrc

COPY . .

# Garble obfuscation for licensed code
ENV GOGARBLE=app/v3,github.com/LerianStudio/lib-license-go

# Build with garble -tiny -literals for obfuscation
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$(echo $TARGETPLATFORM | cut -d'/' -f2) \
  garble -tiny -literals build -tags netgo -ldflags '-w -extldflags "-static"' -o /app/server cmd/app/main.go

FROM gcr.io/distroless/static-debian12

COPY --from=builder /app/server /server

EXPOSE 8080

ENTRYPOINT ["/server"]
```

**Key Elements:**
- `# syntax=docker/dockerfile:1.4` enables BuildKit features
- `garble` installation for code obfuscation
- `--mount=type=secret,id=github_token` for private module access (NOT build args)
- `GOGARBLE` environment variable specifies packages to obfuscate
- `garble -tiny -literals` maximizes obfuscation
- Same distroless final image requirement

#### Building Multi-Platform Images

```bash
# OpenSource (standard build)
docker buildx build --platform linux/amd64,linux/arm64 -t app:latest .

# Closed Source (with secrets)
docker buildx build --platform linux/amd64,linux/arm64 \
  --secret id=github_token,src=.github_token \
  -t app:latest .
```

#### MANDATORY Requirements

All Dockerfiles MUST have:

| Requirement | OpenSource | Closed Source | Reason |
|-------------|-----------|---------------|--------|
| Multi-stage build | YES | YES | Minimal final image |
| Distroless final image | YES | YES | Security, no shell |
| `--platform=$BUILDPLATFORM` | YES | YES | Multi-arch support |
| Pinned base image version | YES | YES | Reproducibility |
| Layer caching (go.mod first) | YES | YES | Build performance |
| `CGO_ENABLED=0` | YES | YES | Static binary |
| `-ldflags '-s -w'` | YES | YES | Smaller binary |
| BuildKit secrets | NO | YES | Private modules |
| Garble obfuscation | NO | YES | License protection |

#### FORBIDDEN Patterns

**Never do these:**

```dockerfile
# FORBIDDEN: Alpine/Ubuntu final image
FROM alpine:3.19
COPY --from=builder /app/server /server

# FORBIDDEN: Runtime dependencies
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=builder /app/server /server

# FORBIDDEN: Secrets in build args
ARG GITHUB_TOKEN
RUN git clone https://${GITHUB_TOKEN}@github.com/...

# FORBIDDEN: Using :latest tag
FROM golang:latest AS builder

# FORBIDDEN: Not using multi-stage builds
FROM golang:1.22
COPY . .
RUN go build -o /server ./cmd/app
CMD ["/server"]

# FORBIDDEN: Installing packages in final image
FROM gcr.io/distroless/static-debian12
RUN apt-get update  # This won't even work - distroless has no shell
```

**Always do these:**

```dockerfile
# CORRECT: Distroless final image
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /server

# CORRECT: Secrets via BuildKit mount
RUN --mount=type=secret,id=github_token ...

# CORRECT: Pinned version
FROM golang:1.25.3-alpine AS builder

# CORRECT: Multi-stage build
FROM golang:1.25.3-alpine AS builder
# ... build steps ...
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/server /server
```

#### Choosing the Right Pattern

| Criteria | Use OpenSource Pattern | Use Closed Source Pattern |
|----------|----------------------|---------------------------|
| Public repository | YES | NO |
| No private dependencies | YES | NO |
| No license-protected code | YES | NO |
| Private repository | NO | YES |
| Uses private Go modules | NO | YES |
| Contains licensed code | NO | YES |
| Requires code obfuscation | NO | YES |

#### Compliance Verification Commands

```bash
# MUST PASS: No Alpine/Ubuntu final image
grep -E "^FROM\s+(alpine|ubuntu)" Dockerfile | grep -v "AS builder"
# Expected: No output

# MUST PASS: Uses distroless
grep "gcr.io/distroless/static-debian12" Dockerfile
# Expected: At least one match

# MUST PASS: Multi-stage build
grep -c "^FROM" Dockerfile
# Expected: 2 or more

# MUST PASS: No secrets in ARG
grep -E "^ARG.*(TOKEN|SECRET|PASSWORD|KEY)" Dockerfile
# Expected: No output

# MUST PASS: Static binary
grep "CGO_ENABLED=0" Dockerfile
# Expected: At least one match

# MUST PASS: Pinned version (no :latest)
grep -E "^FROM.*:latest" Dockerfile
# Expected: No output
```

### Image Guidelines

| Guideline | Reason |
|-----------|--------|
| Use multi-stage builds | Smaller images, no build tools in production |
| Use distroless final image | Minimal attack surface, no shell, no package manager |
| Run as non-root | Security (distroless default) |
| Pin versions | Reproducibility |
| Use .dockerignore | Smaller context |
| No runtime dependencies | Static binaries only |

### Docker Compose (Local Dev)

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/app
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: app
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d app"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

---

## Kubernetes

### Managed Kubernetes

| Provider | Service | Use Case |
|----------|---------|----------|
| AWS | EKS | AWS-native workloads |
| GCP | GKE | Multi-cloud, Autopilot |
| Azure | AKS | Azure ecosystem |

### Deployment Manifest

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      serviceAccountName: api
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: api
          image: company/api:v1.0.0
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health/live
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: api-secrets
                  key: database-url
```

### Service & Ingress

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - api.example.com
      secretName: api-tls
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 80
```

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

---

## Helm

### Chart Structure

```
/charts/api
  Chart.yaml
  values.yaml
  values-dev.yaml
  values-prod.yaml
  /templates
    deployment.yaml
    service.yaml
    ingress.yaml
    configmap.yaml
    secret.yaml
    hpa.yaml
    _helpers.tpl
```

### Chart.yaml

```yaml
apiVersion: v2
name: api
description: API service Helm chart
type: application
version: 1.0.0
appVersion: "1.0.0"
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

### values.yaml

```yaml
# values.yaml
replicaCount: 3

image:
  repository: company/api
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: api-tls
      hosts:
        - api.example.com

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

postgresql:
  enabled: false  # Use external database
```

---

## CI/CD

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
          cache: true

      - name: Run tests
        run: go test -race -coverprofile=coverage.out ./...

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage.out

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: golangci/golangci-lint-action@v4
        with:
          version: latest

  build:
    needs: [test, lint]
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### OIDC Authentication (No Long-Lived Secrets)

```yaml
# AWS OIDC
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-actions
    aws-region: us-east-1

# GCP OIDC
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/123456/locations/global/workloadIdentityPools/github/providers/github
    service_account: github-actions@project.iam.gserviceaccount.com
```

---

## Observability

### Metrics (Prometheus)

```yaml
# prometheus-rules.yaml
groups:
  - name: api
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total[5m])) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: High error rate detected
          description: Error rate is {{ $value | humanizePercentage }}

      - alert: HighLatency
        expr: |
          histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
          > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High latency detected
          description: P99 latency is {{ $value }}s
```

### Logging (Structured JSON)

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "info",
  "message": "Request completed",
  "request_id": "abc-123",
  "user_id": "usr_456",
  "method": "POST",
  "path": "/api/v1/users",
  "status": 201,
  "duration_ms": 45,
  "trace_id": "def-789"
}
```

### Tracing (OpenTelemetry)

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024

exporters:
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [jaeger]
```

---

## SLO Targets

| Service Type | Availability | Latency P99 | Error Rate |
|--------------|-------------|-------------|------------|
| Web API | 99.9% | < 500ms | < 0.1% |
| Background Jobs | 99.5% | < 30s | < 1% |
| Database | 99.99% | < 100ms | < 0.01% |
| Cache | 99.9% | < 10ms | < 0.1% |

### Error Budget Calculation

```
Monthly Error Budget = 100% - SLO
99.9% SLO = 0.1% error budget = ~43 minutes/month downtime

Error Budget Remaining = Error Budget - (Actual Errors / Total Requests)
```

---

## Security

### Secrets Management

```yaml
# Use External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: api-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: api-secrets
  data:
    - secretKey: database-url
      remoteRef:
        key: prod/api/database
        property: url
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: database
      ports:
        - protocol: TCP
          port: 5432
```

---

## Shared Workflows (MANDATORY)

> **STRICT RULE:** Hardcoded pipelines are FORBIDDEN in individual repositories.

The organization maintains centralized CI/CD workflows at **`LerianStudio/github-actions-shared-workflows`**. All repositories MUST use these shared workflows instead of creating inline pipeline logic.

### Policy (Non-Negotiable)

1. **If a shared workflow exists for needed functionality → USE IT**
2. **If a shared workflow doesn't exist → CREATE IT in `github-actions-shared-workflows` FIRST, then use it**
3. **NEVER create inline/hardcoded pipeline jobs in individual repos**
4. **No exceptions, no "temporary" solutions, no deadline pressure excuses**

### Available Shared Workflows Catalog

| Workflow | Purpose | When to Use |
|----------|---------|-------------|
| `pr-security-scan.yml` | Security scanning on PRs | Every PR (mandatory for all repos) |
| `pr-validation.yml` | Semantic PR titles, size checks | Every PR (mandatory for all repos) |
| `go-pr-analysis.yml` | Go CI: lint, test, coverage | PRs in Go projects |
| `go-release.yml` | GoReleaser automation | Releases in Go projects |
| `release.yml` | Semantic versioning | All releases |
| `gitops-update.yml` | Deploy to environments | Deployments via GitOps |
| `api-dog-e2e-tests.yml` | E2E testing with APIDog | API testing |
| `changed-paths.yml` | Monorepo path detection | Monorepo projects |
| `build.yml` | Docker build | Container builds |

### Standard Pipeline Structure

**CI Pipeline (`.github/workflows/ci.yml`):**
```yaml
name: CI

on:
  pull_request:
    branches: [main, develop]

jobs:
  security:
    uses: LerianStudio/github-actions-shared-workflows/.github/workflows/pr-security-scan.yml@v1.0.0
    secrets: inherit

  validation:
    uses: LerianStudio/github-actions-shared-workflows/.github/workflows/pr-validation.yml@v1.0.0
    secrets: inherit

  analysis:
    uses: LerianStudio/github-actions-shared-workflows/.github/workflows/go-pr-analysis.yml@v1.0.0
    secrets: inherit
    with:
      go-version: '1.22'
```

**Release Pipeline (`.github/workflows/release.yml`):**
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    uses: LerianStudio/github-actions-shared-workflows/.github/workflows/go-release.yml@v1.0.0
    secrets: inherit
    with:
      go-version: '1.22'
```

### FORBIDDEN Patterns

**NEVER do this:**
```yaml
# FORBIDDEN: Inline job definitions
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: golangci/golangci-lint-action@v4
        with:
          version: latest
```

**ALWAYS do this:**
```yaml
# CORRECT: Use shared workflow with semantic version
jobs:
  analysis:
    uses: LerianStudio/github-actions-shared-workflows/.github/workflows/go-pr-analysis.yml@v1.0.0
    secrets: inherit
```

### When No Shared Workflow Exists

**DO NOT create inline jobs. Instead:**

1. **Identify the gap:** Document what functionality is missing
2. **Create PR in shared-workflows repo:** Add the new workflow to `LerianStudio/github-actions-shared-workflows`
3. **Get review and merge:** Follow shared-workflows contribution guidelines
4. **Then use it:** Reference the new shared workflow in your repository

**Blocker format when shared workflow is missing:**
```markdown
## Blockers
- **Missing Shared Workflow:** [functionality needed]
- **Required Action:** Create workflow in LerianStudio/github-actions-shared-workflows
- **Proposed Workflow Name:** [suggested-name.yml]
- **Status:** BLOCKED until shared workflow is created and merged
```

### Version Pinning Guidelines

**Shared Workflows Branching Strategy:**
- `main` branch: Released stable versions (e.g., `v1.0.0`, `v1.1.0`)
- `develop` branch: Beta versions for testing (e.g., `v1.1.0-beta.7`)

| Environment | Version Strategy | Example | Source Branch |
|-------------|-----------------|---------|---------------|
| Development | `@v1.1.0-beta.N` | For testing new workflow features | `develop` |
| Production | `@v1.0.0` | Pinned to stable release | `main` |

**Best Practice:** Always pin to stable semantic version tags in production:
```yaml
# Production: Use stable releases from main branch
uses: LerianStudio/github-actions-shared-workflows/.github/workflows/release.yml@v1.0.0

# Development: Use beta versions from develop branch for testing
uses: LerianStudio/github-actions-shared-workflows/.github/workflows/release.yml@v1.1.0-beta.7
```

**Version Selection Rules:**
- **Never use branch references** (`@main`, `@develop`) - always use tags
- **Production:** Use stable releases only (`vX.Y.Z`)
- **Development:** May use beta versions (`vX.Y.Z-beta.N`) for testing new features
- **Upgrade path:** Test beta in dev → promote stable to production

### Pipeline Creation Rules

Before creating ANY pipeline file:

- [ ] **Check shared-workflows catalog:** Does a workflow exist for this?
- [ ] **If yes → use it:** Reference the shared workflow
- [ ] **If no → create it first:** PR to shared-workflows repo, then use it
- [ ] **Never justify inline code:** "Temporary", "deadline", "simple" are not valid reasons
- [ ] **Version pinning:** Use semantic versions for production

### Compliance Verification

```bash
# Detect forbidden inline patterns (run in repo root)
grep -r "runs-on:" .github/workflows/ | grep -v "shared-workflows" && echo "VIOLATION: Inline jobs detected" || echo "PASS: No inline jobs"

# Check for proper shared workflow usage
grep -r "uses:.*LerianStudio/github-actions-shared-workflows" .github/workflows/ && echo "PASS: Using shared workflows" || echo "WARNING: No shared workflows found"
```

---

## Checklist

Before deploying infrastructure, verify:

- [ ] Terraform state stored remotely with locking
- [ ] All resources tagged appropriately
- [ ] Docker images use multi-stage builds
- [ ] Kubernetes manifests have resource limits
- [ ] Health checks (liveness + readiness) configured
- [ ] HPA configured for autoscaling
- [ ] Secrets managed via External Secrets or similar
- [ ] Network policies restrict traffic
- [ ] OIDC authentication (no long-lived secrets in CI)
- [ ] Monitoring dashboards and alerts configured
- [ ] SLO targets defined and tracked

---

## 12-Factor App Infrastructure (DevOps)

DevOps is responsible for infrastructure that ENABLES 12-Factor compliance. Developers write the code; DevOps ensures the environment supports it.

### DevOps-Owned Factors

| Factor | DevOps Responsibility |
|--------|----------------------|
| I. Codebase | Git repository setup, branch protection |
| II. Dependencies | Dockerfile with dependency installation |
| V. Build/Release/Run | CI/CD pipeline with separate stages |
| VII. Port Binding | Container port configuration |
| X. Dev/Prod Parity | docker-compose matches production |
| XII. Admin | Migration jobs, one-off processes |

---

### III. Config - Environment Injection

**DevOps provides environment variables; developers read them.**

#### Kubernetes ConfigMap/Secret

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  LOG_LEVEL: "info"
  SERVER_ADDRESS: ":8080"

---
# secret.yaml (use External Secrets in production)
apiVersion: v1
kind: Secret
metadata:
  name: api-secrets
type: Opaque
stringData:
  DATABASE_URL: "postgres://user:pass@db:5432/app"
  REDIS_URL: "redis://redis:6379"
```

#### docker-compose (Local Dev)

```yaml
services:
  api:
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/app
      - REDIS_URL=redis://redis:6379
      - LOG_LEVEL=debug
```

---

### X. Dev/Prod Parity (CRITICAL)

**docker-compose MUST use same services as production.**

#### CORRECT

```yaml
services:
  api:
    build: .
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/app

  db:
    image: postgres:15-alpine    # Same version as production!

  redis:
    image: redis:7-alpine        # Same version as production!
```

#### FORBIDDEN

```yaml
services:
  db:
    image: sqlite               # FAIL - Production uses PostgreSQL!

  cache:
    image: fake-redis           # FAIL - Production uses real Redis!

  api:
    environment:
      - SKIP_AUTH=true          # FAIL - Never skip auth!
```

---

### V. Build/Release/Run

**CI/CD must have THREE separate stages.**

```yaml
# GitHub Actions
jobs:
  build:    # Stage 1: Create immutable artifact
    steps:
      - run: docker build -t app:${{ github.sha }} .
      - run: docker push app:${{ github.sha }}

  release:  # Stage 2: Combine artifact with config
    needs: build
    steps:
      - run: helm template --set image.tag=${{ github.sha }} > release.yaml

  deploy:   # Stage 3: Execute release
    needs: release
    steps:
      - run: kubectl apply -f release.yaml
```

---

### 12-Factor Infrastructure Checklist (DevOps)

- [ ] Environment variables injected via ConfigMap/Secret
- [ ] docker-compose uses same database/cache as production
- [ ] CI/CD has separate build/release/deploy stages
- [ ] No SKIP_AUTH or DEV_ONLY variables
- [ ] Admin processes use same image as app
