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

## Alerting Standards

### Severity Levels

| Level | Response Time | Impact | Examples |
|-------|---------------|--------|----------|
| **Critical** | Immediate (page) | Service down, data loss | 5xx spike, database unreachable |
| **High** | 15 minutes | Major degradation | Error rate > 5%, latency > 2s |
| **Medium** | 1 hour | Partial degradation | Error rate > 1%, latency > 500ms |
| **Low** | 4 hours | Potential issues | Disk 80%, cert expiring in 7 days |
| **Info** | Next business day | No impact | Minor anomalies, warnings |

### Alert Rules Template

```yaml
# alerts.yml
groups:
  - name: api-availability
    rules:
      # Critical - Page immediately
      - alert: APIDown
        expr: up{job="api"} == 0
        for: 1m
        labels:
          severity: critical
          team: platform
        annotations:
          summary: "API is down"
          description: "API pod {{ $labels.pod }} has been down for 1 minute"
          runbook_url: "https://wiki.example.com/runbooks/api-down"

      # High - Quick response needed
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total[5m]))
          > 0.05
        for: 5m
        labels:
          severity: high
          team: platform
        annotations:
          summary: "High error rate on API"
          description: "Error rate is {{ $value | humanizePercentage }}"
          runbook_url: "https://wiki.example.com/runbooks/high-error-rate"

      # Medium - Investigation needed
      - alert: HighLatency
        expr: |
          histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
          > 0.5
        for: 10m
        labels:
          severity: medium
          team: platform
        annotations:
          summary: "High P99 latency"
          description: "P99 latency is {{ $value | humanizeDuration }}"

      # Low - Non-urgent
      - alert: DiskSpaceWarning
        expr: |
          (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 20
        for: 30m
        labels:
          severity: low
          team: platform
        annotations:
          summary: "Disk space below 20%"
          description: "{{ $labels.device }} has {{ $value | humanize }}% free"
```

### Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/xxx'

route:
  receiver: 'default'
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: true
    - match:
        severity: high
      receiver: 'slack-urgent'
    - match:
        severity: medium
      receiver: 'slack-warnings'
    - match:
        severity: low
      receiver: 'slack-info'

receivers:
  - name: 'default'
    slack_configs:
      - channel: '#alerts'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: '<pagerduty-key>'
        severity: critical

  - name: 'slack-urgent'
    slack_configs:
      - channel: '#alerts-urgent'
        send_resolved: true
        title: '{{ if eq .Status "firing" }}:fire:{{ else }}:white_check_mark:{{ end }} {{ .CommonLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'slack-warnings'
    slack_configs:
      - channel: '#alerts-warnings'

  - name: 'slack-info'
    slack_configs:
      - channel: '#alerts-info'

inhibit_rules:
  - source_match:
      severity: critical
    target_match:
      severity: high
    equal: ['alertname']
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

## Health Checks

### Required Endpoints

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `/health` | Kubernetes liveness | `200 OK` if process running |
| `/ready` | Kubernetes readiness | `200 OK` if can serve traffic |
| `/metrics` | Prometheus scraping | Prometheus format |

### Implementation

```go
// Go implementation
type HealthChecker struct {
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
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 2
```

---

## Grafana Dashboard Standards

### Required Panels

#### Overview Row
1. **Request Rate** - `sum(rate(http_requests_total[5m]))`
2. **Error Rate** - `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))`
3. **Latency P50/P95/P99** - `histogram_quantile(0.99, ...)`
4. **Active Pods** - `count(up{job="api"})`

#### Resources Row
5. **CPU Usage** - `sum(rate(container_cpu_usage_seconds_total[5m]))`
6. **Memory Usage** - `sum(container_memory_working_set_bytes)`
7. **Network I/O** - Bytes in/out

#### Dependencies Row
8. **Database Latency** - `histogram_quantile(0.99, db_query_duration_seconds_bucket)`
9. **Cache Hit Rate** - `sum(rate(cache_hits_total[5m])) / sum(rate(cache_requests_total[5m]))`
10. **External API Latency** - Per-dependency

#### Business Row (service-specific)
11. **Orders/sec**, **Users online**, etc.

### Dashboard JSON Template

```json
{
  "annotations": {
    "list": [
      {
        "datasource": "-- Grafana --",
        "enable": true,
        "name": "Deployments",
        "iconColor": "green",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "refresh": "30s",
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "panels": [
    {
      "title": "Request Rate",
      "type": "stat",
      "gridPos": { "x": 0, "y": 0, "w": 6, "h": 4 },
      "targets": [
        {
          "expr": "sum(rate(http_requests_total[5m]))",
          "legendFormat": "req/s"
        }
      ],
      "options": {
        "colorMode": "value",
        "graphMode": "area"
      }
    },
    {
      "title": "Error Rate",
      "type": "gauge",
      "gridPos": { "x": 6, "y": 0, "w": 6, "h": 4 },
      "targets": [
        {
          "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100"
        }
      ],
      "options": {
        "thresholds": {
          "steps": [
            { "value": 0, "color": "green" },
            { "value": 1, "color": "yellow" },
            { "value": 5, "color": "red" }
          ]
        }
      }
    }
  ]
}
```

---

## Checklist

Before deploying to production:

- [ ] **Metrics**: Prometheus metrics exposed at `/metrics`
- [ ] **Dashboards**: Grafana dashboard with required panels
- [ ] **Alerts**: Alert rules for critical scenarios
- [ ] **Logging**: Structured JSON logs with trace correlation
- [ ] **Tracing**: OpenTelemetry instrumentation
- [ ] **Health Checks**: `/health` and `/ready` endpoints
- [ ] **Runbooks**: Documented for all critical alerts
