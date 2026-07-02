# DevOps Standards

> **⚠️ MAINTENANCE:** This file is indexed in `dev-team/skills/shared-patterns/standards-coverage-table.md`.
> When adding/removing `## ` sections, follow FOUR-FILE UPDATE RULE in CLAUDE.md: (1) edit standards file, (2) update TOC, (3) update standards-coverage-table.md, (4) update agent file.

This file defines the specific standards for DevOps, SRE, and infrastructure.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Table of Contents

| #   | Section                                           | Description                                        |
| --- | ------------------------------------------------- | -------------------------------------------------- |
| 1   | [Cloud Provider](#cloud-provider)                 | AWS, GCP, Azure services                           |
| 2   | [Infrastructure as Code](#infrastructure-as-code) | Terraform patterns and best practices              |
| 3   | [Containers](#containers)                         | Dockerfile, Docker Compose, .env                   |
| 4   | [Helm](#helm)                                     | Chart structure, configuration, Lerian delegation  |
| 5   | [Observability](#observability)                   | Logging and tracing standards                      |
| 6   | [Security](#security)                             | Secrets management, network policies               |
| 7   | [Makefile Standards](#makefile-standards)         | Required commands and patterns                     |
| 8   | [CI/CD Pipeline](#cicd-pipeline-mandatory)        | GitHub Actions, required stages, branch protection |

**Meta-sections (not checked by agents):**

- [Checklist](#checklist) - Self-verification before deploying

---

## Cloud Provider

| Provider | Primary Services              |
| -------- | ----------------------------- |
| AWS      | EKS, RDS, S3, Lambda, SQS     |
| GCP      | GKE, Cloud SQL, Cloud Storage |
| Azure    | AKS, Azure SQL, Blob Storage  |

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

| Guideline              | Reason                 |
| ---------------------- | ---------------------- |
| Use multi-stage builds | Smaller images         |
| Use distroless/alpine  | Minimal attack surface |
| Run as non-root        | Security               |
| Pin versions           | Reproducibility        |
| Use .dockerignore      | Smaller context        |

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

| Guideline                  | Reason                             |
| -------------------------- | ---------------------------------- |
| Use `env_file` directive   | Centralized configuration          |
| Add `.env` to `.gitignore` | Prevent secrets in version control |
| Provide `.env.example`     | Document required variables        |
| Use consistent naming      | Match application config struct    |

---

## Helm

### General Chart Structure

```
/charts/{service-name}
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
  enabled: false # Use external database
```

### Lerian Helm Charts

For Lerian-convention Helm chart creation (naming conventions, directory structure, ConfigMap/Secrets split, dual-mode KEDA/Deployment, AWS RolesAnywhere sidecar, port allocation, and all production patterns), use the dedicated skill and agent:

- **Skill:** `ring:creating-helm-charts` — Orchestrates Helm chart creation following Lerian conventions
- **Agent:** `ring:helm` — Specialist agent with all Lerian Helm patterns
- **Standards:** [`dev-team/docs/standards/helm/`](helm/index.md) — Complete Lerian Helm conventions (conventions, values, templates, dependencies, worker patterns)

> **⚠️ DELEGATION:** When creating or modifying Helm charts that follow Lerian conventions, `ring:devops` MUST delegate to `ring:helm` via the `ring:creating-helm-charts` skill. The generic patterns above apply to other charts only.

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

| Command                | Purpose                                               | Category      |
| ---------------------- | ----------------------------------------------------- | ------------- |
| `make build`           | Build all components                                  | Core          |
| `make lint`            | Run linters (golangci-lint)                           | Code Quality  |
| `make test`            | Run all tests                                         | Testing       |
| `make cover`           | Generate test coverage report                         | Testing       |
| `make test-unit`       | Run unit tests only                                   | Testing       |
| `make up`              | Start all services with Docker Compose                | Docker        |
| `make down`            | Stop all services                                     | Docker        |
| `make start`           | Start existing containers                             | Docker        |
| `make stop`            | Stop running containers                               | Docker        |
| `make restart`         | Restart all containers                                | Docker        |
| `make rebuild-up`      | Rebuild and restart services                          | Docker        |
| `make set-env`         | Copy .env.example to .env                             | Setup         |
| `make dev-setup`       | Install development tools (swag, golangci-lint, etc.) | Setup         |
| `make generate-docs`   | Generate API documentation (Swagger)                  | Documentation |
| `make migrate-up`      | Apply all pending database migrations                 | Database      |
| `make migrate-down`    | Rollback last migration                               | Database      |
| `make migrate-create`  | Create new migration file                             | Database      |
| `make migrate-version` | Show current migration version                        | Database      |

### Component Delegation Pattern (Monorepo)

For monorepo projects with multiple components:

| Command                             | Purpose                             |
| ----------------------------------- | ----------------------------------- |
| `make infra COMMAND=<cmd>`          | Run command in infra component      |
| `make onboarding COMMAND=<cmd>`     | Run command in onboarding component |
| `make all-components COMMAND=<cmd>` | Run command across all components   |

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

### Database Migration Commands (MANDATORY)

MUST: All projects with a database include these migration commands using `golang-migrate`:

```makefile
#-------------------------------------------------------
# Database Migration Commands
#-------------------------------------------------------

# Database URL from environment or default
DATABASE_URL ?= postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSLMODE)
MIGRATE = migrate -path ./migrations -database "$(DATABASE_URL)"

.PHONY: migrate-up
migrate-up: ## Apply all pending migrations
	@echo "Applying migrations..."
	$(MIGRATE) up
	@echo "[ok] Migrations applied successfully"

.PHONY: migrate-down
migrate-down: ## Rollback last migration
	@echo "Rolling back last migration..."
	$(MIGRATE) down 1
	@echo "[ok] Rollback completed"

.PHONY: migrate-down-all
migrate-down-all: ## Rollback all migrations (DANGEROUS)
	@echo "WARNING: Rolling back ALL migrations..."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	$(MIGRATE) down
	@echo "[ok] All migrations rolled back"

.PHONY: migrate-create
migrate-create: ## Create new migration (usage: make migrate-create NAME=create_users)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make migrate-create NAME=create_users"; \
		exit 1; \
	fi
	migrate create -ext sql -dir ./migrations -seq $(NAME)
	@echo "[ok] Migration files created in ./migrations/"

.PHONY: migrate-version
migrate-version: ## Show current migration version
	$(MIGRATE) version

.PHONY: migrate-force
migrate-force: ## Force set migration version (usage: make migrate-force VERSION=1)
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is required. Usage: make migrate-force VERSION=1"; \
		exit 1; \
	fi
	$(MIGRATE) force $(VERSION)
	@echo "[ok] Version forced to $(VERSION)"

.PHONY: migrate-status
migrate-status: ## Show migration status
	@echo "Current migration version:"
	@$(MIGRATE) version 2>/dev/null || echo "No migrations applied yet"
```

**Usage examples:**

```bash
# Apply all pending migrations
make migrate-up

# Rollback last migration (one feature = one rollback)
make migrate-down

# Create new migration for a feature
make migrate-create NAME=add_user_preferences

# Check current version
make migrate-version

# Force version after manual fix (use with caution)
make migrate-force VERSION=5
```

### Documentation Commands (MANDATORY)

All projects with API endpoints MUST include Swagger generation using swaggo:

```makefile
#-------------------------------------------------------
# Documentation Commands
#-------------------------------------------------------

.PHONY: generate-docs
generate-docs: ## Generate Swagger API documentation
	@echo "Generating Swagger documentation..."
	@if ! command -v swag >/dev/null 2>&1; then \
		echo "Error: swag is not installed. Run: make dev-setup"; \
		exit 1; \
	fi
	swag init -g cmd/app/main.go -o api --parseDependency --parseInternal
	@echo "[ok] Swagger documentation generated in api/"

.PHONY: serve-docs
serve-docs: ## Serve Swagger UI locally (requires swagger-ui)
	@echo "Serving Swagger UI at http://localhost:8081"
	@docker run -p 8081:8080 -e SWAGGER_JSON=/api/swagger.json -v $(PWD)/api:/api swaggerapi/swagger-ui
```

**Command parameters:**

| Flag                 | Purpose                                        |
| -------------------- | ---------------------------------------------- |
| `-g cmd/app/main.go` | Entry point file with API metadata annotations |
| `-o api`             | Output directory for generated files           |
| `--parseDependency`  | Parse external dependencies for models         |
| `--parseInternal`    | Parse internal packages for types              |

**Generated files:**

```text
/api
  docs.go         # Go code for embedding (GENERATED - do not edit)
  swagger.json    # OpenAPI spec in JSON (GENERATED - do not edit)
  swagger.yaml    # OpenAPI spec in YAML (GENERATED - do not edit)
```

**⛔ FORBIDDEN:** Editing generated files directly. Always edit the annotations in source code.

### Development Setup Commands (MANDATORY)

All projects MUST include a dev-setup command to install required tools:

```makefile
#-------------------------------------------------------
# Development Setup Commands
#-------------------------------------------------------

.PHONY: dev-setup
dev-setup: ## Install development tools
	@echo "Installing development tools..."

	@# golangci-lint
	@if ! command -v golangci-lint >/dev/null 2>&1; then \
		echo "Installing golangci-lint..."; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest; \
	else \
		echo "[ok] golangci-lint already installed"; \
	fi

	@# swag (Swagger generator)
	@if ! command -v swag >/dev/null 2>&1; then \
		echo "Installing swag..."; \
		go install github.com/swaggo/swag/cmd/swag@latest; \
	else \
		echo "[ok] swag already installed"; \
	fi

	@# golang-migrate
	@if ! command -v migrate >/dev/null 2>&1; then \
		echo "Installing golang-migrate..."; \
		go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest; \
	else \
		echo "[ok] migrate already installed"; \
	fi

	@# mockgen (for GoMock)
	@if ! command -v mockgen >/dev/null 2>&1; then \
		echo "Installing mockgen..."; \
		go install go.uber.org/mock/mockgen@latest; \
	else \
		echo "[ok] mockgen already installed"; \
	fi

	@echo "[ok] All development tools installed"

.PHONY: check-tools
check-tools: ## Verify all required tools are installed
	@echo "Checking required tools..."
	@command -v go >/dev/null 2>&1 || { echo "❌ go not found"; exit 1; }
	@command -v golangci-lint >/dev/null 2>&1 || { echo "❌ golangci-lint not found"; exit 1; }
	@command -v swag >/dev/null 2>&1 || { echo "❌ swag not found"; exit 1; }
	@command -v migrate >/dev/null 2>&1 || { echo "❌ migrate not found"; exit 1; }
	@command -v mockgen >/dev/null 2>&1 || { echo "❌ mockgen not found"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "❌ docker not found"; exit 1; }
	@echo "[ok] All required tools are installed"
```

**Required tools:**

| Tool            | Purpose             | Installation                                                                          |
| --------------- | ------------------- | ------------------------------------------------------------------------------------- |
| `golangci-lint` | Code linting        | `go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest`               |
| `swag`          | Swagger generation  | `go install github.com/swaggo/swag/cmd/swag@latest`                                   |
| `migrate`       | Database migrations | `go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest` |
| `mockgen`       | Mock generation     | `go install go.uber.org/mock/mockgen@latest`                                          |

### Generate Mocks Command (MANDATORY)

```makefile
#-------------------------------------------------------
# Code Generation Commands
#-------------------------------------------------------

.PHONY: generate
generate: ## Run all code generation (mocks, etc.)
	@echo "Running go generate..."
	@go generate ./...
	@echo "[ok] Code generation completed"

.PHONY: generate-mocks
generate-mocks: ## Generate mock files using mockgen
	@echo "Generating mocks..."
	@go generate ./...
	@echo "[ok] Mocks generated"
```

---

## CI/CD Pipeline (MANDATORY)

This section covers CI/CD pipeline patterns and automation requirements.

### CI Pipeline Stages (MANDATORY)

All services MUST have CI pipelines with these stages:

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.24"
      - name: golangci-lint
        uses: golangci/golangci-lint-action@v4

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.24"
      - name: Run tests
        run: make test
      - name: Check coverage
        run: make cover

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run govulncheck
        run: go run golang.org/x/vuln/cmd/govulncheck@latest ./...

  build:
    runs-on: ubuntu-latest
    needs: [lint, test, security]
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: docker build -t ${{ github.repository }}:${{ github.sha }} .
```

### Required CI Stages

| Stage       | Purpose                | Failure Action           |
| ----------- | ---------------------- | ------------------------ |
| lint        | Code quality           | Block merge              |
| test        | Unit tests + coverage  | Block merge              |
| security    | Vulnerability scan     | Block merge              |
| build       | Docker image creation  | Block merge              |
| deploy (CD) | Environment deployment | Manual approval for prod |

### Branch Protection (REQUIRED)

```yaml
# Settings → Branches → Branch protection rules → main

Required checks:
  - lint
  - test
  - security
  - build

Settings:
  - Require a pull request before merging: ✅
  - Require approvals: 1
  - Dismiss stale approvals: ✅
  - Require status checks to pass: ✅
  - Require branches to be up to date: ✅
```

### Detection Commands

```bash
# Find projects without CI config
find . -name "go.mod" -exec dirname {} \; | while read dir; do
  if [ ! -f "$dir/.github/workflows/ci.yml" ] && [ ! -f "$dir/.gitlab-ci.yml" ]; then
    echo "MISSING CI: $dir"
  fi
done
```

### Anti-Rationalization Table

| Rationalization             | Why It's WRONG                                          | Required Action                |
| --------------------------- | ------------------------------------------------------- | ------------------------------ |
| "Local tests are enough"    | Local ≠ CI environment. CI catches env-specific issues. | **Add CI pipeline**            |
| "Security scan is slow"     | Slow scan > production vulnerability.                   | **Include govulncheck**        |
| "We'll add CI later"        | Later = technical debt. Start with CI.                  | **Add CI on project creation** |
| "Manual deployment is fine" | Manual = error-prone + no audit trail.                  | **Automate deployments**       |

---

## Checklist

Before deploying infrastructure, verify:

- [ ] Terraform state stored remotely with locking
- [ ] All resources tagged appropriately
- [ ] Docker images use multi-stage builds
- [ ] Secrets managed via External Secrets or similar
- [ ] Monitoring dashboards and alerts configured
