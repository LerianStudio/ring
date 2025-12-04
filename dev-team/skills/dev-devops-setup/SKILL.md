---
name: dev-devops-setup
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
  after: [dev-implementation]
  before: [dev-testing]

related:
  complementary: [dev-implementation, dev-testing]
---

# DevOps Setup (Gate 1)

## Overview

This skill configures the development and deployment infrastructure:
- Creates or updates Dockerfile for the application
- Configures docker-compose.yml for local development
- Documents environment variables in .env.example
- Verifies the containerized application works

## Prerequisites

Before starting Gate 4:

1. **Gate 3 Complete**: Code implementation is done
2. **Environment Requirements**: List from Gate 3 handoff:
   - New dependencies
   - New environment variables
   - New services needed
3. **Existing Config**: Current Docker/compose files (if any)

## Step 1: Analyze DevOps Requirements

Review Gate 3 handoff and existing configuration:

```
From Gate 3 Handoff:
- New dependencies: {list}
- New environment variables: {list}
- New services needed: {list}

Existing Configuration:
- Dockerfile: EXISTS/MISSING
- docker-compose.yml: EXISTS/MISSING
- .env.example: EXISTS/MISSING

Actions Needed:
- [ ] Create Dockerfile: YES/NO
- [ ] Update Dockerfile: YES/NO
- [ ] Create docker-compose.yml: YES/NO
- [ ] Update docker-compose.yml: YES/NO
- [ ] Create .env.example: YES/NO
- [ ] Update .env.example: YES/NO
```

## Step 2: Dispatch DevOps Agent

Dispatch `ring-dev-team:devops-engineer` for infrastructure setup:

```
Task tool:
  subagent_type: "ring-dev-team:devops-engineer"
  model: "opus"
  prompt: |
    Set up Docker configuration for the implemented feature.

    ## Implementation Summary
    {paste Gate 3 handoff}

    ## Existing Configuration
    {paste existing Dockerfile, docker-compose.yml, .env.example if they exist}

    ## Requirements

    ### Dockerfile
    If creating new or updating existing:
    - Use multi-stage build for minimal image size
    - Include only production dependencies
    - Set appropriate USER (non-root)
    - Use specific base image versions (not :latest)
    - Include health check
    - Optimize layer caching

    ### docker-compose.yml
    Configure for local development:
    - Service for main application
    - Database service (if needed): PostgreSQL, MongoDB, Redis
    - Message queue service (if needed): RabbitMQ, Kafka
    - Volume mounts for development
    - Network configuration
    - Depends_on with health checks
    - Port mappings

    ### Environment Variables
    Document in .env.example:
    - All required variables with placeholder values
    - Comments explaining each variable
    - Group by service/purpose
    - Mark optional vs required

    ### Local Setup Documentation
    Create/update docs/LOCAL_SETUP.md:
    - Prerequisites (Docker, Docker Compose versions)
    - Step-by-step setup instructions
    - How to run the application
    - How to run tests in Docker
    - Troubleshooting common issues

    ## Output Requirements
    Provide:
    1. Complete Dockerfile (or updates)
    2. Complete docker-compose.yml (or updates)
    3. Complete .env.example (or updates)
    4. Setup documentation
    5. Verification commands
```

## Step 3: Create/Update Dockerfile

Dockerfile best practices for different stacks:

### Go Application

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build application
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server

# Production stage
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Non-root user
RUN adduser -D -g '' appuser
USER appuser

COPY --from=builder /app/main .

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["./main"]
```

### TypeScript/Node.js Application

```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Cache dependencies
COPY package*.json ./
RUN npm ci

# Build application
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Non-root user
RUN adduser -D -g '' appuser

# Production dependencies only
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy built application
COPY --from=builder /app/dist ./dist

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/main.js"]
```

### Python Application

```dockerfile
# Build stage
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim

WORKDIR /app

# Non-root user
RUN useradd -m -r appuser

# Copy virtual environment
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application
COPY . .

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Step 4: Create/Update docker-compose.yml

Standard docker-compose.yml structure:

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "${APP_PORT:-8080}:8080"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - LOG_LEVEL=${LOG_LEVEL:-info}
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - .:/app:ro  # Read-only for security
    networks:
      - app-network
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=${DB_USER:-postgres}
      - POSTGRES_PASSWORD=${DB_PASSWORD:-postgres}
      - POSTGRES_DB=${DB_NAME:-app}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "${DB_PORT:-5432}:5432"
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-postgres}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redis-data:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres-data:
  redis-data:

networks:
  app-network:
    driver: bridge
```

## Step 5: Create/Update .env.example

Environment variable documentation:

```bash
# ===========================================
# Application Configuration
# ===========================================

# Server port (default: 8080)
APP_PORT=8080

# Environment: development, staging, production
APP_ENV=development

# Log level: debug, info, warn, error
LOG_LEVEL=info

# ===========================================
# Database Configuration
# ===========================================

# PostgreSQL connection URL
# Format: postgres://user:password@host:port/database
DATABASE_URL=postgres://postgres:postgres@db:5432/app

# Individual database settings (alternative to URL)
DB_HOST=db
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=app

# ===========================================
# Redis Configuration
# ===========================================

# Redis connection URL
REDIS_URL=redis://redis:6379

# ===========================================
# Authentication (if applicable)
# ===========================================

# JWT secret key (generate with: openssl rand -hex 32)
JWT_SECRET=your-secret-key-here

# JWT expiration (e.g., 15m, 1h, 24h)
JWT_EXPIRATION=1h

# ===========================================
# External Services (if applicable)
# ===========================================

# API keys and external service configuration
# STRIPE_API_KEY=sk_test_...
# SENDGRID_API_KEY=SG...
```

## Step 6: Create Local Setup Documentation

Create or update `docs/LOCAL_SETUP.md`:

```markdown
# Local Development Setup

## Prerequisites

- Docker >= 24.0
- Docker Compose >= 2.20
- Make (optional, for convenience commands)

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd <project-name>
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start services:**
   ```bash
   docker-compose up -d
   ```

4. **Verify services are running:**
   ```bash
   docker-compose ps
   # All services should show "Up (healthy)"
   ```

5. **View logs:**
   ```bash
   docker-compose logs -f app
   ```

## Available Services

| Service | URL | Description |
|---------|-----|-------------|
| App | http://localhost:8080 | Main application |
| PostgreSQL | localhost:5432 | Database |
| Redis | localhost:6379 | Cache |

## Common Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Rebuild after code changes
docker-compose build app
docker-compose up -d app

# View logs
docker-compose logs -f [service-name]

# Run tests
docker-compose exec app [test-command]

# Access database
docker-compose exec db psql -U postgres -d app

# Access Redis CLI
docker-compose exec redis redis-cli
```

## Troubleshooting

### Port already in use
```bash
# Find process using the port
lsof -i :8080
# Kill the process or change APP_PORT in .env
```

### Database connection refused
```bash
# Check if database is healthy
docker-compose ps db
# Check database logs
docker-compose logs db
```

### Permission issues
```bash
# Reset volumes
docker-compose down -v
docker-compose up -d
```
```

## Step 7: Verify Setup Works

Run verification commands:

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# Check health
docker-compose ps

# Verify app responds
curl http://localhost:8080/health

# Run a smoke test
docker-compose exec app [test-command]

# Check logs for errors
docker-compose logs app | grep -i error
```

**Verification checklist:**
- [ ] `docker-compose build` succeeds
- [ ] `docker-compose up -d` starts all services
- [ ] All services show "healthy" status
- [ ] Health endpoint responds
- [ ] No errors in logs
- [ ] Application can connect to database
- [ ] Application can connect to Redis (if used)

## Step 8: Prepare Handoff to Gate 2

Package the following for Gate 2 (Testing):

```markdown
## Gate 4 Handoff

**DevOps Status:** COMPLETE/PARTIAL

**Files Created/Modified:**
- Dockerfile: CREATED/UPDATED/UNCHANGED
- docker-compose.yml: CREATED/UPDATED/UNCHANGED
- .env.example: CREATED/UPDATED/UNCHANGED
- docs/LOCAL_SETUP.md: CREATED/UPDATED/UNCHANGED

**Services Configured:**
- App: {port}
- Database: {type, port}
- Cache: {type, port}
- Other: {list}

**Environment Variables Added:**
- {VAR_NAME}: {description}

**Verification Results:**
- Build: PASS/FAIL
- Startup: PASS/FAIL
- Health check: PASS/FAIL
- Connectivity: PASS/FAIL

**Ready for Testing:**
- [ ] All services start successfully
- [ ] Health endpoints respond
- [ ] Database migrations run
- [ ] Environment is reproducible
```

## Common DevOps Patterns

### Multi-Environment Support

```yaml
# docker-compose.override.yml (for development)
services:
  app:
    build:
      target: development
    volumes:
      - .:/app
    environment:
      - DEBUG=true

# docker-compose.prod.yml (for production)
services:
  app:
    build:
      target: production
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
```

### Database Migrations

```yaml
services:
  migrate:
    build:
      context: .
      dockerfile: Dockerfile
    command: ["./migrate", "up"]
    depends_on:
      db:
        condition: service_healthy
    environment:
      - DATABASE_URL=${DATABASE_URL}
```

### Development Hot Reload

For Go:
```yaml
services:
  app:
    build:
      context: .
      target: development
    volumes:
      - .:/app
    command: ["air", "-c", ".air.toml"]
```

For Node.js:
```yaml
services:
  app:
    volumes:
      - .:/app
      - /app/node_modules
    command: ["npm", "run", "dev"]
```

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
