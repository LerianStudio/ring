# Audit Dimensions: Category E — Infrastructure & Hardening

These are the 6 explorer agent prompts for Infrastructure dimensions.
Inject Ring standards and detected stack before dispatching.

### Agent 24: Container Security Auditor

```prompt
Audit container security and Dockerfile best practices for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Containers" section from devops.md}
---END STANDARDS---

**Search Patterns:**
- Files: `Dockerfile*`, `docker-compose*.yml`, `Makefile`
- Keywords: `FROM`, `USER`, `COPY`, `ADD`, `HEALTHCHECK`
- Standards-specific: `distroless`, `nonroot`, `multi-stage`

**Reference Implementation (GOOD):**
```dockerfile
# Multi-stage build
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /main cmd/app/main.go

# Distroless or minimal runtime image
FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /
COPY --from=builder /main .
# Non-root user
USER nonroot:nonroot
# Healthcheck defined
HEALTHCHECK --interval=30s --timeout=3s CMD ["/main", "-health"]
ENTRYPOINT ["/main"]
```

**Check Against Ring Standards For:**
1. (HARD GATE) Multi-stage builds (builder vs runtime) per devops.md containers section
2. (HARD GATE) Non-root user execution (`USER nonroot` or numeric ID) per Ring standards
3. Minimal/Distroless runtime images per Ring container patterns
4. Pinned base image versions (not `latest`)
5. `COPY` used instead of `ADD` (unless extracting tar)
6. .dockerignore file exists and excludes secrets/git
7. Sensitive args not passed as build-args (secrets)

**Severity Ratings:**
- CRITICAL: Running as root in production image (HARD GATE violation per Ring standards)
- CRITICAL: HARD GATE violation — no multi-stage build per devops.md
- HIGH: Secrets in Dockerfile/history
- MEDIUM: Using `latest` tag
- LOW: Missing HEALTHCHECK in Dockerfile

**Output Format:**
```
## Container Security Audit Findings

### Summary
- Multi-stage build: Yes/No
- Non-root user: Yes/No
- Base image pinned: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 25: HTTP Hardening Auditor

```prompt
Audit HTTP security headers and hardening configuration for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Search Patterns:**
- Files: `**/fiber_server.go`, `**/middleware*.go`
- Keywords: `Helmet`, `CSRF`, `Secure`, `HttpOnly`, `SameSite`

**Reference Implementation (GOOD):**
```go
// Security headers
app.Use(helmet.New(helmet.Config{
    XSSProtection:             "1; mode=block",
    ContentTypeNosniff:        "nosniff",
    XFrameOptions:             "DENY",
    HSTSMaxAge:                31536000,
    HSTSExcludeSubdomains:     false,
    HSTSPreloadEnabled:        true,
    ContentSecurityPolicy:     "default-src 'self'",
}))
```

**Check For:**
1. HSTS enabled (Strict-Transport-Security)
2. CSP configured (Content-Security-Policy)
3. X-Frame-Options set to DENY or SAMEORIGIN
4. Secure cookies (Secure, HttpOnly, SameSite=Strict/Lax)
5. Server banner suppressed (Server: value removed)

**Severity Ratings:**
- HIGH: Missing HSTS
- MEDIUM: Missing CSP or overly permissive
- LOW: Server banner exposed

**Output Format:**
```
## HTTP Hardening Audit Findings

### Summary
- HSTS enabled: Yes/No
- CSP configured: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 26: CI/CD Pipeline Auditor

```prompt
Audit CI/CD pipelines for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: CI section from devops.md}
---END STANDARDS---

**Search Patterns:**
- Files: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Makefile`
- Keywords: `test`, `lint`, `build`, `docker`, `sign`
- Standards-specific: `golangci-lint`, `gosec`, `trivy`, `cosign`

**Reference Implementation (GOOD):**
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
      - run: go test -race -v ./...
      - run: golangci-lint run

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: securego/gosec@v2.21.4
        with:
          args: ./...
```

**Check Against Ring Standards For:**
1. (HARD GATE) CI pipeline exists (GitHub Actions/GitLab CI) per devops.md
2. (HARD GATE) Tests run on PRs per Ring CI requirements
3. Linting runs on PRs (golangci-lint)
4. Security scanning (gosec, trivy) integrated
5. Artifact signing (cosign/sigstore)
6. Docker image build and push stages
7. Automated deployment stages (if applicable)

**Severity Ratings:**
- CRITICAL: No CI pipeline (HARD GATE violation per Ring standards)
- CRITICAL: Tests not running on PR (HARD GATE violation)
- HIGH: Missing linting in CI
- MEDIUM: Missing security scanning
- LOW: Artifacts not signed

**Output Format:**
```
## CI/CD Pipeline Audit Findings

### Summary
- CI Pipeline: Active/Missing
- Tests on PR: Yes/No
- Linting: Yes/No
- Security Scans: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 27: Async Reliability Auditor

```prompt
Audit asynchronous processing reliability for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "RabbitMQ Worker Pattern" section from messaging.md}
---END STANDARDS---

**Search Patterns:**
- Files: `**/worker/*.go`, `**/queue/*.go`, `**/kafka/*.go`, `**/rabbitmq/*.go`
- Keywords: `Ack`, `Nack`, `Retry`, `DeadLetter`, `DLQ`, `ConsumerGroup`
- Standards-specific: `amqp`, `RabbitMQ`, `lib-commons messaging`

**Reference Implementation (GOOD):**
```go
// Reliable consumer with DLQ strategy
func (c *Consumer) Handle(msg *Message) error {
    if err := c.process(msg); err != nil {
        if msg.RetryCount >= maxRetries {
            // Move to Dead Letter Queue
            return c.dlq.Publish(msg)
        }
        // Retry with backoff
        return c.RetryLater(msg, backoff(msg.RetryCount))
    }
    return msg.Ack()
}
```

**Reference Implementation (GOOD — Outbox, Idempotency & Poison Messages):**
```go
// Transactional outbox pattern — event published within same DB transaction
func (s *Service) CreateOrder(ctx context.Context, order *Order) error {
    return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
        if err := tx.Create(order).Error; err != nil {
            return err
        }
        outboxEvent := OutboxEvent{
            AggregateID:   order.ID,
            AggregateType: "Order",
            EventType:     "OrderCreated",
            Payload:       mustMarshal(order),
            Status:        "pending",
        }
        return tx.Create(&outboxEvent).Error
    })
}

// Outbound webhook with retry and delivery tracking
func (w *WebhookDelivery) Deliver(ctx context.Context, endpoint string, payload []byte) error {
    var lastErr error
    for attempt := 0; attempt < w.maxRetries; attempt++ {
        resp, err := w.httpClient.Post(endpoint, "application/json", bytes.NewReader(payload))
        if err == nil && resp.StatusCode >= 200 && resp.StatusCode < 300 {
            w.trackDelivery(ctx, endpoint, "delivered", attempt+1)
            return nil
        }
        lastErr = fmt.Errorf("attempt %d: status=%d err=%w", attempt+1, resp.StatusCode, err)
        w.trackDelivery(ctx, endpoint, "retrying", attempt+1)
        time.Sleep(exponentialBackoff(attempt))
    }
    w.trackDelivery(ctx, endpoint, "failed", w.maxRetries)
    return fmt.Errorf("webhook delivery failed after %d attempts: %w", w.maxRetries, lastErr)
}

// Idempotent message consumer with deduplication
func (c *Consumer) HandleIdempotent(ctx context.Context, msg *Message) error {
    if processed, _ := c.dedup.IsProcessed(ctx, msg.ID); processed {
        logger.Info("duplicate message skipped", "msg_id", msg.ID)
        return msg.Ack()
    }
    if err := c.process(ctx, msg); err != nil {
        return err
    }
    c.dedup.MarkProcessed(ctx, msg.ID, 24*time.Hour)
    return msg.Ack()
}

// Event ordering via partition key
func (p *Producer) PublishOrderEvent(ctx context.Context, orderID string, event interface{}) error {
    return p.channel.Publish(ctx, PublishOptions{
        Exchange:     "orders",
        RoutingKey:   "order.events",
        PartitionKey: orderID,
        Body:         mustMarshal(event),
        Headers: map[string]interface{}{
            "sequence": event.SequenceNumber,
        },
    })
}

// Poison message isolation (separate from DLQ)
func (c *Consumer) HandleWithPoisonDetection(msg *Message) error {
    var event DomainEvent
    if err := json.Unmarshal(msg.Body, &event); err != nil {
        c.poisonQueue.Publish(msg, fmt.Sprintf("deserialization failed: %v", err))
        return msg.Ack()
    }
    if err := c.process(event); err != nil {
        if msg.RetryCount >= maxRetries {
            return c.dlq.Publish(msg)
        }
        return c.RetryLater(msg, backoff(msg.RetryCount))
    }
    return msg.Ack()
}
```

**Reference Implementation (BAD — Outbox, Idempotency & Poison Messages):**
```go
// BAD: Fire-and-forget webhook — no retry, no delivery tracking
func (s *Service) NotifyWebhook(endpoint string, payload []byte) {
    go func() {
        http.Post(endpoint, "application/json", bytes.NewReader(payload))
    }()
}

// BAD: Event published OUTSIDE transaction — lost events on rollback
func (s *Service) CreateOrder(ctx context.Context, order *Order) error {
    if err := s.db.Create(order).Error; err != nil {
        return err
    }
    return s.publisher.Publish("OrderCreated", order)
}

// BAD: Consumer without idempotency — processes duplicates
func (c *Consumer) Handle(msg *Message) error {
    return c.process(msg)
}

// BAD: Poison messages treated same as processing failures
func (c *Consumer) Handle(msg *Message) error {
    var event DomainEvent
    if err := json.Unmarshal(msg.Body, &event); err != nil {
        return msg.Nack(true)  // Requeue — malformed message retried forever
    }
    return c.process(event)
}
```

**Check Against Ring Standards For:**
1. (HARD GATE) Dead Letter Queues (DLQ) configured for failed messages per messaging.md
2. (HARD GATE) Explicit Ack/Nack handling (no auto-ack) per Ring RabbitMQ worker pattern
3. Retry policies with exponential backoff
4. Consumer groups for parallel processing
5. Graceful shutdown of consumers (wait for processing to finish)
6. Message durability settings (persistent queues)
7. lib-commons messaging integration where applicable
8. Outbound webhook delivery guarantees — webhook publishing MUST implement retry with exponential backoff and delivery status tracking (not fire-and-forget HTTP calls)
9. At-least-once delivery patterns for event publishing — events MUST be published within the same transaction as the state change (transactional outbox pattern) to prevent lost events on rollback
10. Idempotent message receivers — consumers MUST implement deduplication checks (idempotency keys, message ID tracking) before processing to handle at-least-once delivery without duplicate side effects
11. Event ordering guarantees where required — order-dependent workflows MUST use partition keys or sequence numbers to guarantee processing order within a partition
12. Poison message handling — messages that repeatedly fail deserialization or schema validation MUST be isolated separately from DLQ, preventing bad messages from blocking queue consumers

**Severity Ratings:**
- CRITICAL: Messages auto-acked before processing (HARD GATE violation per Ring standards)
- HIGH: No DLQ for poison messages (infinite loops) — HARD GATE violation
- HIGH: No retry backoff strategy
- HIGH: Outbound webhooks with no retry mechanism (fire-and-forget HTTP call — delivery failures are silently lost)
- HIGH: Event publishing outside transaction boundary (state change commits but event publish fails — lost events, inconsistent downstream state)
- HIGH: Message consumers without idempotency checks (at-least-once delivery causes duplicate processing — double charges, duplicate records)
- MEDIUM: Missing graceful shutdown for workers
- MEDIUM: No event ordering strategy for order-dependent workflows (e.g., "order cancelled" processed before "order created")
- MEDIUM: No poison message isolation (malformed messages that fail deserialization block the queue or get retried infinitely)
- LOW: No webhook delivery status tracking/dashboard (cannot audit delivery success rates)

**Output Format:**
```
## Async Reliability Audit Findings

### Summary
- Async processing detected: Yes/No
- DLQ configured: Yes/No
- Retry strategy: Yes/No

### Critical Issues
[file:line] - Description

### Recommendations
1. ...
```
```

### Agent 32: Makefile & Dev Tooling Auditor

```prompt
Audit Makefile and development tooling for production readiness.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: "Makefile Standards" section 7 from devops.md}
---END STANDARDS---

**Search Patterns:**
- Files: `Makefile`, `makefile`, `GNUmakefile`
- Keywords: `.PHONY`, `build`, `test`, `lint`, `help`, `docker`
- Also search: `scripts/*.sh` for development scripts

**Reference Implementation (GOOD):**
```makefile
.PHONY: build test lint cover up down logs setup migrate seed generate swagger docker-build docker-push clean help check

build: ## Build the application binary
	go build -o bin/app cmd/app/main.go

test: ## Run all unit tests
	go test -race -v ./...

lint: ## Run linters
	golangci-lint run

cover: ## Run tests with coverage
	go test -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

up: ## Start local dependencies (docker-compose)
	docker compose up -d

down: ## Stop local dependencies
	docker compose down

logs: ## Tail local dependency logs
	docker compose logs -f

setup: ## Initial project setup
	go mod download
	go install github.com/swaggo/swag/cmd/swag@v1.16.4

migrate: ## Run database migrations
	migrate -path migrations -database "$$DATABASE_URL" up

seed: ## Seed database with test data
	go run cmd/seed/main.go

generate: ## Run code generators (mockgen, etc.)
	go generate ./...

swagger: ## Generate Swagger documentation
	swag init -g cmd/app/main.go

docker-build: ## Build Docker image
	docker build -t app:latest .

docker-push: ## Push Docker image
	docker push app:latest

clean: ## Clean build artifacts
	rm -rf bin/ coverage.out coverage.html

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

check: ## Run all checks (lint + test + cover)
	$(MAKE) lint
	$(MAKE) test
	$(MAKE) cover
```

**Check Against Ring Standards For:**
1. (HARD GATE) Makefile exists in project root per devops.md
2. Required targets present: build, lint, test, cover, up, down, logs, setup, migrate, seed, generate, swagger, docker-build, docker-push, clean, help, check
3. All targets have help descriptions (## comments)
4. .PHONY declarations for non-file targets
5. `help` target shows available commands
6. `check` target runs full validation pipeline

**Severity Ratings:**
- HIGH: No Makefile in project (HARD GATE violation per Ring standards)
- MEDIUM: Missing required Makefile targets (list which ones are missing)
- MEDIUM: Targets without help descriptions
- LOW: Missing .PHONY declarations
- LOW: Targets without error handling

**Output Format:**
```
## Makefile & Dev Tooling Audit Findings

### Summary
- Makefile present: Yes/No
- Required targets present: X/17
- Missing targets: [list]
- Targets with help: X/Y

### Required Targets Checklist
| Target | Present | Has Help |
|--------|---------|----------|
| build | Yes/No | Yes/No |
| test | Yes/No | Yes/No |
| lint | Yes/No | Yes/No |
| cover | Yes/No | Yes/No |
| up | Yes/No | Yes/No |
| down | Yes/No | Yes/No |
| logs | Yes/No | Yes/No |
| setup | Yes/No | Yes/No |
| migrate | Yes/No | Yes/No |
| seed | Yes/No | Yes/No |
| generate | Yes/No | Yes/No |
| swagger | Yes/No | Yes/No |
| docker-build | Yes/No | Yes/No |
| docker-push | Yes/No | Yes/No |
| clean | Yes/No | Yes/No |
| help | Yes/No | Yes/No |
| check | Yes/No | Yes/No |

### Recommendations
1. ...
```
```

### Agent 34: License Headers Auditor

```prompt
Audit license/copyright headers on source files for production readiness. If no LICENSE file exists in the project root, report all items as "N/A — No LICENSE file detected" with evidence.

**Detected Stack:** {DETECTED_STACK}

**Ring Standards (Source of Truth):**
---BEGIN STANDARDS---
{INJECTED: License header section from core.md section 7 (if exists), otherwise use organizational defaults}
---END STANDARDS---

**Search Patterns:**
- Files: `**/*.go` (check first 5 lines for copyright/license header)
- Also check: `LICENSE`, `LICENSE.md`, `NOTICE` files in project root
- Keywords: `Copyright`, `Licensed under`, `SPDX-License-Identifier`

**Reference Implementation (GOOD):**
```go
// Copyright 2025 LerianStudio. All rights reserved.
// Use of this source code is governed by the Apache License 2.0
// that can be found in the LICENSE file.
// SPDX-License-Identifier: Apache-2.0

package domain

import (
    ...
)
```

**Reference Implementation (BAD):**
```go
// BAD: No license header at all
package domain

import (
    ...
)

// BAD: Outdated year
// Copyright 2020 LerianStudio. All rights reserved.
// (If current year is 2025+)

// BAD: Inconsistent header format
/* This file is part of Project X
 * (c) Company Name
 */
package domain
```

**Check Against Ring Standards For:**
1. LICENSE file exists in project root
2. All .go files have copyright/license header comment in first 5 lines
3. Consistent header format across all files
4. Year in copyright is current or includes current year (e.g., "2024-2025")
5. SPDX-License-Identifier present (preferred for machine-readability)
6. License matches LICENSE file (e.g., Apache-2.0 header matches Apache-2.0 LICENSE)

**Severity Ratings:**
- HIGH: .go files missing license headers (if license headers are required)
- MEDIUM: Inconsistent license header format across files
- MEDIUM: License header does not match LICENSE file
- LOW: Outdated year in copyright header
- LOW: Missing SPDX identifier

**Output Format:**
```
## License Headers Audit Findings

### Summary
- LICENSE file present: Yes/No (type: Apache-2.0/MIT/etc.)
- Total .go files: X
- Files with headers: Y/X
- Consistent format: Yes/No
- Year current: Yes/No

### Files Missing Headers
[file] - No license header found

### Inconsistent Headers
[file] - Header differs from standard format

### Recommendations
1. ...
```
```

