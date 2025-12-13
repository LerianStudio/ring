# SRE Standards

This file defines the specific standards for Site Reliability Engineering and observability.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Observability Stack

| Component | Primary | Alternatives |
|-----------|---------|--------------|
| Metrics | Prometheus | DataDog, CloudWatch, New Relic |
| Logs | Loki | ELK Stack, Splunk, CloudWatch Logs |
| Traces | Jaeger/Tempo | Zipkin, X-Ray, Honeycomb |
| Dashboards | Grafana | DataDog, New Relic, Kibana |
| Alerting | Alertmanager | PagerDuty, OpsGenie, VictorOps |
| APM | OpenTelemetry | DataDog APM, New Relic APM |

---

## Metrics Standards

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: production
    env: prod

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
```

### Application Metrics

#### Go

```go
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    // Counter - monotonically increasing
    httpRequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Namespace: "api",
            Name:      "http_requests_total",
            Help:      "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )

    // Histogram - distribution of values
    httpRequestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Namespace: "api",
            Name:      "http_request_duration_seconds",
            Help:      "HTTP request duration in seconds",
            Buckets:   []float64{.001, .005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5},
        },
        []string{"method", "endpoint"},
    )

    // Gauge - can go up and down
    activeConnections = promauto.NewGauge(
        prometheus.GaugeOpts{
            Namespace: "api",
            Name:      "active_connections",
            Help:      "Current number of active connections",
        },
    )

    // Summary - quantiles
    dbQueryDuration = promauto.NewSummaryVec(
        prometheus.SummaryOpts{
            Namespace:  "api",
            Name:       "db_query_duration_seconds",
            Help:       "Database query duration",
            Objectives: map[float64]float64{0.5: 0.05, 0.9: 0.01, 0.99: 0.001},
        },
        []string{"query_type"},
    )
)

// Usage in middleware
func metricsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()

        // Wrap response writer to capture status
        wrapped := &responseWriter{ResponseWriter: w, status: 200}

        next.ServeHTTP(wrapped, r)

        duration := time.Since(start).Seconds()

        httpRequestsTotal.WithLabelValues(
            r.Method,
            r.URL.Path,
            strconv.Itoa(wrapped.status),
        ).Inc()

        httpRequestDuration.WithLabelValues(
            r.Method,
            r.URL.Path,
        ).Observe(duration)
    })
}
```

#### TypeScript

```typescript
import { Counter, Histogram, Gauge, Registry } from 'prom-client';

const register = new Registry();

// Counter
const httpRequestsTotal = new Counter({
  name: 'api_http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'endpoint', 'status'],
  registers: [register],
});

// Histogram
const httpRequestDuration = new Histogram({
  name: 'api_http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'endpoint'],
  buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [register],
});

// Gauge
const activeConnections = new Gauge({
  name: 'api_active_connections',
  help: 'Current number of active connections',
  registers: [register],
});

// Middleware
export function metricsMiddleware(req: Request, res: Response, next: NextFunction) {
  const start = process.hrtime();

  res.on('finish', () => {
    const [seconds, nanoseconds] = process.hrtime(start);
    const duration = seconds + nanoseconds / 1e9;

    httpRequestsTotal.labels(req.method, req.path, String(res.statusCode)).inc();
    httpRequestDuration.labels(req.method, req.path).observe(duration);
  });

  next();
}
```

#### Python

```python
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import time

# Counter
http_requests_total = Counter(
    'api_http_requests_total',
    'Total number of HTTP requests',
    ['method', 'endpoint', 'status']
)

# Histogram
http_request_duration = Histogram(
    'api_http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint'],
    buckets=[0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5]
)

# Gauge
active_connections = Gauge(
    'api_active_connections',
    'Current number of active connections'
)

# FastAPI middleware
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration = time.perf_counter() - start

    http_requests_total.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()

    http_request_duration.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)

    return response
```

### Metric Naming Conventions

```
# Format: <namespace>_<subsystem>_<name>_<unit>

# Good
api_http_requests_total
api_http_request_duration_seconds
api_db_connections_active
api_cache_hits_total

# Bad
requests                    # No namespace
http_request_time          # Ambiguous unit
APIRequestCount            # Wrong case
```

---

## Logging Standards

### Structured Log Format

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "error",
  "logger": "api.handler",
  "message": "Failed to process request",
  "service": "api",
  "version": "1.2.3",
  "environment": "production",
  "trace_id": "abc123def456",
  "span_id": "789xyz",
  "request_id": "req-001",
  "user_id": "usr_456",
  "error": {
    "type": "ConnectionError",
    "message": "connection timeout after 30s",
    "stack": "..."
  },
  "context": {
    "method": "POST",
    "path": "/api/v1/users",
    "status": 500,
    "duration_ms": 30045
  }
}
```

### Log Levels

| Level | Usage | Examples |
|-------|-------|----------|
| **ERROR** | Failures requiring attention | Database connection failed, API error |
| **WARN** | Potential issues | Retry attempt, rate limit approaching |
| **INFO** | Normal operations | Request completed, user logged in |
| **DEBUG** | Detailed debugging | Query parameters, internal state |
| **TRACE** | Very detailed (rarely used) | Full request/response bodies |

### What to Log

```yaml
# DO log
- Request start/end with duration
- Error details with stack traces
- Authentication events (login, logout, failed attempts)
- Authorization failures
- External service calls (start, end, duration)
- Business events (order placed, payment processed)
- Configuration changes
- Deployment events

# DO NOT log
- Passwords or API keys
- Credit card numbers (full)
- Personal identifiable information (PII)
- Session tokens
- Internal security mechanisms
- Health check requests (too noisy)
```

### Log Aggregation (Loki)

```yaml
# loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2024-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/cache
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
```

---

## Tracing Standards

### OpenTelemetry Configuration

```go
// Go - OpenTelemetry setup
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/resource"
    "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
)

func initTracer(ctx context.Context) (*trace.TracerProvider, error) {
    exporter, err := otlptracegrpc.New(ctx,
        otlptracegrpc.WithEndpoint("otel-collector:4317"),
        otlptracegrpc.WithInsecure(),
    )
    if err != nil {
        return nil, err
    }

    res, err := resource.New(ctx,
        resource.WithAttributes(
            semconv.ServiceName("api"),
            semconv.ServiceVersion("1.0.0"),
            semconv.DeploymentEnvironment("production"),
        ),
    )
    if err != nil {
        return nil, err
    }

    tp := trace.NewTracerProvider(
        trace.WithBatcher(exporter),
        trace.WithResource(res),
        trace.WithSampler(trace.TraceIDRatioBased(0.1)), // Sample 10%
    )

    otel.SetTracerProvider(tp)
    return tp, nil
}

// Usage
tracer := otel.Tracer("api")
ctx, span := tracer.Start(ctx, "processOrder")
defer span.End()

span.SetAttributes(
    attribute.String("order.id", orderID),
    attribute.Int("order.items", len(items)),
)
```

### Span Naming Conventions

```
# Format: <operation>.<entity>

# HTTP handlers
GET /api/users         -> http.request
POST /api/orders       -> http.request

# Database
SELECT users           -> db.query
INSERT orders          -> db.query

# External calls
Payment API call       -> http.client.payment
Email service call     -> http.client.email

# Internal operations
Process order          -> order.process
Validate input         -> input.validate
```

### Trace Context Propagation

```go
// Propagate trace context in HTTP headers
import (
    "go.opentelemetry.io/otel/propagation"
)

// Client - inject context
req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
otel.GetTextMapPropagator().Inject(ctx, propagation.HeaderCarrier(req.Header))

// Server - extract context
ctx := otel.GetTextMapPropagator().Extract(
    r.Context(),
    propagation.HeaderCarrier(r.Header),
)
```

---

## OpenTelemetry with lib-commons (MANDATORY for Go)

All Go services **MUST** integrate OpenTelemetry using `lib-commons/v2`. This ensures consistent observability patterns across all Lerian Studio services.

> **Reference**: See `dev-team/docs/standards/golang.md` for complete lib-commons integration patterns.

### Required Imports

```go
import (
    libCommons "github.com/LerianStudio/lib-commons/v2/commons"
    libZap "github.com/LerianStudio/lib-commons/v2/commons/zap"           // Logger initialization (bootstrap only)
    libLog "github.com/LerianStudio/lib-commons/v2/commons/log"           // Logger interface (services, routes, consumers)
    libOpentelemetry "github.com/LerianStudio/lib-commons/v2/commons/opentelemetry"
    libHTTP "github.com/LerianStudio/lib-commons/v2/commons/net/http"
    libServer "github.com/LerianStudio/lib-commons/v2/commons/server"
)
```

### Telemetry Flow (MANDATORY)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. BOOTSTRAP (config.go)                                        │
│    telemetry := libOpentelemetry.InitializeTelemetry(&config)   │
│    → Creates OpenTelemetry provider once at startup             │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. ROUTER (routes.go)                                           │
│    tlMid := libHTTP.NewTelemetryMiddleware(tl)                  │
│    f.Use(tlMid.WithTelemetry(tl))      ← Injects into context   │
│    ...routes...                                                  │
│    f.Use(tlMid.EndTracingSpans)        ← Closes root spans      │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. ANY LAYER (handlers, services, repositories)                 │
│    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)│
│    ctx, span := tracer.Start(ctx, "operation_name")             │
│    defer span.End()                                              │
│    logger.Infof("Processing...")   ← Logger from same context   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. SERVER LIFECYCLE (fiber.server.go)                           │
│    libServer.NewServerManager(nil, &s.telemetry, s.logger)      │
│        .WithHTTPServer(s.app, s.serverAddress)                  │
│        .StartWithGracefulShutdown()                             │
│    → Handles signal trapping + telemetry flush + clean shutdown │
└─────────────────────────────────────────────────────────────────┘
```

### 1. Bootstrap Initialization (MANDATORY)

```go
// bootstrap/config.go
func InitServers() *Service {
    cfg := &Config{}
    if err := libCommons.SetConfigFromEnvVars(cfg); err != nil {
        panic(err)
    }

    // Initialize logger FIRST (zap package for initialization in bootstrap)
    logger := libZap.InitializeLogger()

    // Initialize telemetry with config
    telemetry := libOpentelemetry.InitializeTelemetry(&libOpentelemetry.TelemetryConfig{
        LibraryName:               cfg.OtelLibraryName,
        ServiceName:               cfg.OtelServiceName,
        ServiceVersion:            cfg.OtelServiceVersion,
        DeploymentEnv:             cfg.OtelDeploymentEnv,
        CollectorExporterEndpoint: cfg.OtelColExporterEndpoint,
        EnableTelemetry:           cfg.EnableTelemetry,
        Logger:                    logger,
    })

    // Pass telemetry to router...
}
```

### 2. Router Middleware Setup (MANDATORY)

```go
// adapters/http/in/routes.go
func NewRouter(lg libLog.Logger, tl *libOpentelemetry.Telemetry, ...) *fiber.App {
    f := fiber.New(fiber.Config{
        DisableStartupMessage: true,
        ErrorHandler: func(ctx *fiber.Ctx, err error) error {
            return libHTTP.HandleFiberError(ctx, err)
        },
    })

    // Create telemetry middleware
    tlMid := libHTTP.NewTelemetryMiddleware(tl)

    // MUST be first middleware - injects tracer+logger into context
    f.Use(tlMid.WithTelemetry(tl))
    f.Use(cors.New())
    f.Use(libHTTP.WithHTTPLogging(libHTTP.WithCustomLogger(lg)))

    // ... define routes ...

    // Version endpoint
    f.Get("/version", libHTTP.Version)

    // MUST be last middleware - closes root spans
    f.Use(tlMid.EndTracingSpans)

    return f
}
```

### 3. Recovering Logger & Tracer (MANDATORY)

```go
// ANY file in ANY layer (handler, service, repository)
func (s *Service) ProcessEntity(ctx context.Context, id string) error {
    // Single call recovers BOTH logger AND tracer from context
    logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)

    // Create child span for this operation
    ctx, span := tracer.Start(ctx, "service.process_entity")
    defer span.End()

    // Logger is automatically correlated with trace
    logger.Infof("Processing entity: %s", id)

    // Pass ctx to downstream calls - trace propagates automatically
    return s.repo.Update(ctx, id)
}
```

### 4. Error Handling with Spans (MANDATORY)

```go
// For technical errors (unexpected failures)
if err != nil {
    libOpentelemetry.HandleSpanError(&span, "Failed to connect database", err)
    logger.Errorf("Database error: %v", err)
    return nil, err
}

// For business errors (expected validation failures)
if err != nil {
    libOpentelemetry.HandleSpanBusinessErrorEvent(&span, "Validation failed", err)
    logger.Warnf("Validation error: %v", err)
    return nil, err
}
```

### 5. Server Lifecycle with Graceful Shutdown (MANDATORY)

```go
// bootstrap/fiber.server.go
type Server struct {
    app           *fiber.App
    serverAddress string
    logger        libLog.Logger
    telemetry     libOpentelemetry.Telemetry
}

func (s *Server) Run(l *libCommons.Launcher) error {
    libServer.NewServerManager(nil, &s.telemetry, s.logger).
        WithHTTPServer(s.app, s.serverAddress).
        StartWithGracefulShutdown()  // Handles: SIGINT/SIGTERM, telemetry flush, connections close
    return nil
}
```

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `OTEL_RESOURCE_SERVICE_NAME` | Service name in traces | `service-name` |
| `OTEL_LIBRARY_NAME` | Library identifier | `service-name` |
| `OTEL_RESOURCE_SERVICE_VERSION` | Service version | `1.0.0` |
| `OTEL_RESOURCE_DEPLOYMENT_ENVIRONMENT` | Environment | `production` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Collector endpoint | `http://otel-collector:4317` |
| `ENABLE_TELEMETRY` | Enable/disable | `true` |

### lib-commons Telemetry Checklist

| Check | What to Verify | Status |
|-------|----------------|--------|
| Bootstrap Init | `libOpentelemetry.InitializeTelemetry()` called in bootstrap | Required |
| Middleware Order | `WithTelemetry()` is FIRST, `EndTracingSpans` is LAST | Required |
| Context Recovery | All layers use `libCommons.NewTrackingFromContext(ctx)` | Required |
| Span Creation | Operations create spans via `tracer.Start(ctx, "name")` | Required |
| Error Handling | Uses `HandleSpanError` or `HandleSpanBusinessErrorEvent` | Required |
| Graceful Shutdown | `libServer.NewServerManager().StartWithGracefulShutdown()` | Required |
| Env Variables | All OTEL_* variables configured | Required |

### What NOT to Do

```go
// FORBIDDEN: Manual OpenTelemetry setup without lib-commons
import "go.opentelemetry.io/otel"
tp := trace.NewTracerProvider(...)  // DON'T do this manually

// FORBIDDEN: Creating loggers without context
logger := zap.NewLogger()  // DON'T do this in services

// FORBIDDEN: Not passing context to downstream calls
s.repo.Update(id)  // DON'T forget context

// CORRECT: Always use lib-commons patterns
telemetry := libOpentelemetry.InitializeTelemetry(&config)
logger, tracer, _, _ := libCommons.NewTrackingFromContext(ctx)
s.repo.Update(ctx, id)  // Context propagates trace
```

### Standards Compliance Categories

When evaluating a codebase for lib-commons telemetry compliance, check these categories:

| Category | Expected Pattern | Evidence Location |
|----------|------------------|-------------------|
| Telemetry Init | `libOpentelemetry.InitializeTelemetry()` | `internal/bootstrap/config.go` |
| Logger Init | `libZap.InitializeLogger()` (bootstrap only) | `internal/bootstrap/config.go` |
| Middleware Setup | `NewTelemetryMiddleware()` + `WithTelemetry()` | `internal/adapters/http/in/routes.go` |
| Middleware Order | `WithTelemetry` first, `EndTracingSpans` last | `internal/adapters/http/in/routes.go` |
| Context Recovery | `libCommons.NewTrackingFromContext(ctx)` | All handlers, services, repositories |
| Span Creation | `tracer.Start(ctx, "operation")` | All significant operations |
| Error Spans | `HandleSpanError` / `HandleSpanBusinessErrorEvent` | Error handling paths |
| Graceful Shutdown | `libServer.NewServerManager().StartWithGracefulShutdown()` | `internal/bootstrap/fiber.server.go` |

---

## Structured Logging with lib-common-js (MANDATORY for TypeScript)

All TypeScript services **MUST** integrate structured logging using `@LerianStudio/lib-common-js`. This ensures consistent observability patterns across all Lerian Studio services.

> **Note**: lib-common-js currently provides logging infrastructure. Telemetry will be added in future versions.

### Required Dependencies

```json
{
  "dependencies": {
    "@LerianStudio/lib-common-js": "^1.0.0"
  }
}
```

### Required Imports

```typescript
import { initializeLogger, Logger } from '@LerianStudio/lib-common-js/logger';
import { loadConfigFromEnv } from '@LerianStudio/lib-common-js/config';
import { createLoggingMiddleware } from '@LerianStudio/lib-common-js/http';
```

### Logging Flow (MANDATORY)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. BOOTSTRAP (config.ts)                                        │
│    const logger = initializeLogger()                            │
│    → Creates structured logger once at startup                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. ROUTER (routes.ts)                                           │
│    const logMid = createLoggingMiddleware(logger)               │
│    app.use(logMid)            ← Injects logger into request     │
│    ...routes...                                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. ANY LAYER (handlers, services, repositories)                 │
│    const logger = req.logger || parentLogger                    │
│    logger.info('Processing...', { entityId, requestId })        │
│    → Structured JSON logs with correlation IDs                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1. Bootstrap Initialization (MANDATORY)

```typescript
// bootstrap/config.ts
import { initializeLogger } from '@LerianStudio/lib-common-js/logger';
import { loadConfigFromEnv } from '@LerianStudio/lib-common-js/config';

export async function initServers(): Promise<Service> {
    // Load configuration from environment
    const config = loadConfigFromEnv<Config>();

    // Initialize logger
    const logger = initializeLogger({
        level: config.logLevel,
        serviceName: config.serviceName,
        serviceVersion: config.serviceVersion,
    });

    logger.info('Service starting', {
        service: config.serviceName,
        version: config.serviceVersion,
        environment: config.envName,
    });

    // Pass logger to router...
}
```

### 2. Router Middleware Setup (MANDATORY)

```typescript
// adapters/http/routes.ts
import { createLoggingMiddleware } from '@LerianStudio/lib-common-js/http';
import express from 'express';

export function createRouter(
    logger: Logger,
    handlers: Handlers
): express.Application {
    const app = express();

    // Create logging middleware - injects logger into request
    const logMid = createLoggingMiddleware(logger);
    app.use(logMid);
    app.use(cors());
    app.use(express.json());

    // ... define routes ...

    return app;
}
```

### 3. Using Logger in Handlers/Services (MANDATORY)

```typescript
// handlers/user-handler.ts
async function createUser(req: Request, res: Response): Promise<void> {
    const logger = req.logger;
    const requestId = req.headers['x-request-id'] as string;

    logger.info('Creating user', {
        requestId,
        email: req.body.email,
    });

    try {
        const user = await userService.create(req.body, logger);
        logger.info('User created successfully', {
            requestId,
            userId: user.id,
        });
        res.status(201).json(user);
    } catch (error) {
        logger.error('Failed to create user', {
            requestId,
            error: error.message,
            stack: error.stack,
        });
        throw error;
    }
}
```

### Required Structured Log Format

All logs **MUST** be JSON formatted with these fields:

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "info",
  "message": "Processing request",
  "service": "api-service",
  "version": "1.2.3",
  "environment": "production",
  "requestId": "req-001",
  "context": {
    "method": "POST",
    "path": "/api/v1/users",
    "userId": "usr_456"
  }
}
```

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `LOG_LEVEL` | Logging level | `info` |
| `SERVICE_NAME` | Service identifier | `api-service` |
| `SERVICE_VERSION` | Service version | `1.0.0` |
| `ENV_NAME` | Environment name | `production` |

### lib-common-js Logging Checklist

| Check | What to Verify | Status |
|-------|----------------|--------|
| Logger Init | `initializeLogger()` called in bootstrap | Required |
| Middleware | `createLoggingMiddleware(logger)` configured | Required |
| Request Correlation | Logs include `requestId` from headers | Required |
| Structured Format | All logs are JSON formatted | Required |
| Error Logging | Errors include message, stack, and context | Required |
| No Sensitive Data | Passwords, tokens, PII NOT logged | Required |
| Log Levels | Appropriate levels used (info, warn, error) | Required |

### What NOT to Do

```typescript
// FORBIDDEN: Using console.log
console.log('Processing user'); // DON'T do this

// FORBIDDEN: Logging sensitive data
logger.info('User login', { password: user.password }); // NEVER

// FORBIDDEN: Unstructured log messages
logger.info(`Processing user ${userId}`); // DON'T use string interpolation

// CORRECT: Always use lib-common-js structured logging
const logger = initializeLogger(config);
logger.info('Processing user', { userId, requestId }); // Structured fields
```

### Standards Compliance Categories (TypeScript Logging)

When evaluating a codebase for lib-common-js logging compliance, check these categories:

| Category | Expected Pattern | Evidence Location |
|----------|------------------|-------------------|
| Logger Init | `initializeLogger()` | `src/bootstrap/config.ts` |
| Middleware Setup | `createLoggingMiddleware(logger)` | `src/adapters/http/routes.ts` |
| Request Correlation | `requestId` in all logs | Handlers, services |
| JSON Format | Structured JSON output | All log statements |
| Error Logging | Error object with stack trace | Error handlers |
| No console.log | No direct console usage | Entire codebase |
| No Sensitive Data | Passwords, tokens excluded | All log statements |

---

## Health Checks

### Required Endpoints

### Implementation

```go
// Go implementation for observability
type ObservabilityChecker struct {
    db    *sql.DB
    redis *redis.Client
}

// Liveness - is the process alive?
func (h *HealthChecker) LivenessHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}

// Readiness - can we serve traffic?
func (h *HealthChecker) ReadinessHandler(w http.ResponseWriter, r *http.Request) {
    ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
    defer cancel()

    checks := []struct {
        name string
        fn   func(context.Context) error
    }{
        {"database", func(ctx context.Context) error { return h.db.PingContext(ctx) }},
        {"redis", func(ctx context.Context) error { return h.redis.Ping(ctx).Err() }},
    }

    var failures []string
    for _, check := range checks {
        if err := check.fn(ctx); err != nil {
            failures = append(failures, fmt.Sprintf("%s: %v", check.name, err))
        }
    }

    if len(failures) > 0 {
        w.WriteHeader(http.StatusServiceUnavailable)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  "unhealthy",
            "checks":  failures,
        })
        return
    }

    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status": "healthy",
    })
}
```

### Kubernetes Configuration

```yaml
# Observability configuration
# JSON structured logging required
# OpenTelemetry tracing recommended for distributed systems
```

---

## Checklist

Before deploying to production:

- [ ] **Logging**: Structured JSON logs with trace correlation
- [ ] **Tracing**: OpenTelemetry instrumentation (Go with lib-commons)
- [ ] **Structured Logging**: lib-common-js integration (TypeScript)
