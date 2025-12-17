# DevOps Standards

> **⚠️ MAINTENANCE:** This file is indexed in `dev-team/skills/shared-patterns/standards-coverage-table.md`.
> When adding/removing `## ` sections, update the coverage table AND agent files per THREE-FILE UPDATE RULE in CLAUDE.md.

This file defines the specific standards for DevOps, SRE, and infrastructure.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Cloud Provider](#cloud-provider) | AWS, GCP, Azure services |
| 2 | [Infrastructure as Code](#infrastructure-as-code) | Terraform patterns and best practices |
| 3 | [Containers](#containers) | Dockerfile, Docker Compose, .env |
| 4 | [Helm](#helm) | Chart structure and configuration |
| 5 | [Observability](#observability) | Logging and tracing standards |
| 6 | [Security](#security) | Secrets management, network policies |
| 7 | [Makefile Standards](#makefile-standards) | Required commands and patterns |

**Meta-sections (not checked by agents):**
- [Checklist](#checklist) - Self-verification before deploying

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

---

## Containers

### Dockerfile Best Practices

```dockerfile
# Multi-stage build for minimal images
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/server ./cmd/api

# Production image
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /app/server /server

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/server"]
```

### Image Guidelines

| Guideline | Reason |
|-----------|--------|
| Use multi-stage builds | Smaller images |
| Use distroless/alpine | Minimal attack surface |
| Run as non-root | Security |
| Pin versions | Reproducibility |
| Use .dockerignore | Smaller context |

### Docker Compose (Local Dev)

**MANDATORY:** Use `.env` file for environment variables instead of inline definitions.

```yaml
# docker-compose.yml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

  db:
    image: postgres:15-alpine
    env_file:
      - .env
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
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

#### .env File Structure

```bash
# .env (add to .gitignore)

# Application
ENV_NAME=local
LOG_LEVEL=debug
SERVER_ADDRESS=:8080

# PostgreSQL
POSTGRES_USER=user
POSTGRES_PASSWORD=pass
POSTGRES_DB=app
DB_HOST=db
DB_PORT=5432

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Telemetry
ENABLE_TELEMETRY=false
```

| Guideline | Reason |
|-----------|--------|
| Use `env_file` directive | Centralized configuration |
| Add `.env` to `.gitignore` | Prevent secrets in version control |
| Provide `.env.example` | Document required variables |
| Use consistent naming | Match application config struct |

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

## Observability

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

## Makefile Standards

All projects **MUST** include a Makefile with standardized commands for consistent developer experience.

### Required Commands

| Command | Purpose | Category |
|---------|---------|----------|
| `make build` | Build all components | Core |
| `make lint` | Run linters (golangci-lint) | Code Quality |
| `make test` | Run all tests | Testing |
| `make cover` | Generate test coverage report | Testing |
| `make test-unit` | Run unit tests only | Testing |
| `make up` | Start all services with Docker Compose | Docker |
| `make down` | Stop all services | Docker |
| `make start` | Start existing containers | Docker |
| `make stop` | Stop running containers | Docker |
| `make restart` | Restart all containers | Docker |
| `make rebuild-up` | Rebuild and restart services | Docker |
| `make set-env` | Copy .env.example to .env | Setup |
| `make generate-docs` | Generate API documentation (Swagger) | Documentation |

### Component Delegation Pattern (Monorepo)

For monorepo projects with multiple components:

| Command | Purpose |
|---------|---------|
| `make infra COMMAND=<cmd>` | Run command in infra component |
| `make onboarding COMMAND=<cmd>` | Run command in onboarding component |
| `make all-components COMMAND=<cmd>` | Run command across all components |

### Root Makefile Example

```makefile
# Project Root Makefile

# Component directories
INFRA_DIR := ./components/infra
ONBOARDING_DIR := ./components/onboarding
TRANSACTION_DIR := ./components/transaction

COMPONENTS := $(INFRA_DIR) $(ONBOARDING_DIR) $(TRANSACTION_DIR)

# Docker command detection
DOCKER_CMD := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; else echo "docker-compose"; fi)

#-------------------------------------------------------
# Core Commands
#-------------------------------------------------------

.PHONY: build
build:
	@for dir in $(COMPONENTS); do \
		echo "Building in $$dir..."; \
		(cd $$dir && $(MAKE) build) || exit 1; \
	done
	@echo "[ok] All components built successfully"

.PHONY: test
test:
	@for dir in $(COMPONENTS); do \
		(cd $$dir && $(MAKE) test) || exit 1; \
	done

.PHONY: test-unit
test-unit:
	@for dir in $(COMPONENTS); do \
		(cd $$dir && go test -v -short ./...) || exit 1; \
	done

.PHONY: cover
cover:
	@sh ./scripts/coverage.sh
	@go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated at coverage.html"

#-------------------------------------------------------
# Code Quality Commands
#-------------------------------------------------------

.PHONY: lint
lint:
	@for dir in $(COMPONENTS); do \
		if find "$$dir" -name "*.go" -type f | grep -q .; then \
			(cd $$dir && golangci-lint run --fix ./...) || exit 1; \
		fi; \
	done
	@echo "[ok] Linting completed successfully"

#-------------------------------------------------------
# Docker Commands
#-------------------------------------------------------

.PHONY: up
up:
	@for dir in $(COMPONENTS); do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			(cd $$dir && $(DOCKER_CMD) -f docker-compose.yml up -d) || exit 1; \
		fi; \
	done
	@echo "[ok] All services started successfully"

.PHONY: down
down:
	@for dir in $(COMPONENTS); do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			(cd $$dir && $(DOCKER_CMD) -f docker-compose.yml down) || exit 1; \
		fi; \
	done

.PHONY: start
start:
	@for dir in $(COMPONENTS); do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			(cd $$dir && $(DOCKER_CMD) -f docker-compose.yml start) || exit 1; \
		fi; \
	done

.PHONY: stop
stop:
	@for dir in $(COMPONENTS); do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			(cd $$dir && $(DOCKER_CMD) -f docker-compose.yml stop) || exit 1; \
		fi; \
	done

.PHONY: restart
restart:
	@make stop && make start

.PHONY: rebuild-up
rebuild-up:
	@for dir in $(COMPONENTS); do \
		if [ -f "$$dir/docker-compose.yml" ]; then \
			(cd $$dir && $(DOCKER_CMD) -f docker-compose.yml down && \
			 $(DOCKER_CMD) -f docker-compose.yml build && \
			 $(DOCKER_CMD) -f docker-compose.yml up -d) || exit 1; \
		fi; \
	done

#-------------------------------------------------------
# Setup Commands
#-------------------------------------------------------

.PHONY: set-env
set-env:
	@for dir in $(COMPONENTS); do \
		if [ -f "$$dir/.env.example" ] && [ ! -f "$$dir/.env" ]; then \
			cp "$$dir/.env.example" "$$dir/.env"; \
			echo "Created .env in $$dir"; \
		fi; \
	done

#-------------------------------------------------------
# Documentation Commands
#-------------------------------------------------------

.PHONY: generate-docs
generate-docs:
	@./scripts/generate-docs.sh

#-------------------------------------------------------
# Component Delegation
#-------------------------------------------------------

.PHONY: infra
infra:
	@if [ -z "$(COMMAND)" ]; then \
		echo "Error: Use COMMAND=<cmd>"; exit 1; \
	fi
	@cd $(INFRA_DIR) && $(MAKE) $(COMMAND)

.PHONY: onboarding
onboarding:
	@if [ -z "$(COMMAND)" ]; then \
		echo "Error: Use COMMAND=<cmd>"; exit 1; \
	fi
	@cd $(ONBOARDING_DIR) && $(MAKE) $(COMMAND)

.PHONY: all-components
all-components:
	@if [ -z "$(COMMAND)" ]; then \
		echo "Error: Use COMMAND=<cmd>"; exit 1; \
	fi
	@for dir in $(COMPONENTS); do \
		(cd $$dir && $(MAKE) $(COMMAND)) || exit 1; \
	done
```

### Component Makefile Example

```makefile
# Component Makefile (e.g., components/onboarding/Makefile)

SERVICE_NAME := onboarding-service
ARTIFACTS_DIR := ./artifacts

.PHONY: build test lint up down

build:
	@go build -o $(ARTIFACTS_DIR)/$(SERVICE_NAME) ./cmd/app

test:
	@go test -v ./...

lint:
	@golangci-lint run --fix ./...

up:
	@docker compose -f docker-compose.yml up -d

down:
	@docker compose -f docker-compose.yml down
```

---

## Checklist

Before deploying infrastructure, verify:

- [ ] Terraform state stored remotely with locking
- [ ] All resources tagged appropriately
- [ ] Docker images use multi-stage builds
- [ ] Secrets managed via External Secrets or similar
- [ ] Monitoring dashboards and alerts configured
