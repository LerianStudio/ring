---
name: ring:dev-readyz
slug: dev-readyz
version: 1.0.0
type: skill
description: |
  Implements comprehensive readiness probes (/readyz) and startup self-probes for
  Lerian services. Goes beyond basic K8s liveness: validates every external dependency
  (database, cache, queue, TLS handshakes) and exposes per-dependency status with
  latency and TLS info. Designed to be consumed by Tenant Manager post-provisioning.

  Origin: Monetarie SaaS incident — product-console started successfully but MongoDB
  was silently unreachable (TLS mismatch with DocumentDB). K8s liveness passed, traffic
  routed, client hit errors. This skill ensures that never happens again.

trigger: |
  - New service being created
  - Service has external dependencies (DB, cache, queue)
  - Gate 0 (Implementation) added connection code
  - Service lacks /readyz or has incomplete dependency checks
  - Service missing startup self-probe

NOT_skip_when: |
  - "K8s TCP probe is enough" → TCP ≠ app ready. Monetarie proved it.
  - "/health already exists" → /health without self-probe = blind. /readyz validates ALL deps.
  - "TLS check is overkill" → TLS mismatch = silent failure. This incident exists because of it.
  - "Frontend doesn't need /readyz" → Console IS the product that broke. Every app needs it.
  - "We'll add checks later" → Later = client-facing incident. Add now.
  - "Service is simple" → Simple services still connect to databases. No exceptions.

sequence:
  after: [ring:dev-implementation]
  parallel_with: [ring:dev-sre]
  before: [ring:dev-devops]

related:
  complementary: [ring:dev-cycle, ring:dev-sre, ring:dev-devops, ring:dev-service-discovery]
  standards: [docs/standards/golang/bootstrap.md, docs/standards/sre.md, docs/standards/helm/templates.md]

input_schema:
  required:
    - name: language
      type: string
      enum: [go, typescript]
      description: "Programming language of the service"
    - name: service_type
      type: string
      enum: [api, worker, batch, frontend, bff]
      description: "Type of service"
  optional:
    - name: dependencies
      type: array
      items: string
      description: "Known dependencies (auto-detected if omitted)"
    - name: deployment_mode
      type: string
      enum: [saas, byoc, local]
      description: "Target deployment mode for validation rules"

output_schema:
  format: markdown
  required_sections:
    - name: "Dependency Scan"
      pattern: "^## Dependency Scan"
      required: true
    - name: "Readyz Implementation"
      pattern: "^## Readyz Implementation"
      required: true
    - name: "Self-Probe Implementation"
      pattern: "^## Self-Probe Implementation"
      required: true
    - name: "Validation Result"
      pattern: "^## Validation Result"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL, PARTIAL]
    - name: dependencies_detected
      type: integer
    - name: dependencies_covered
      type: integer

examples:
  - name: "Go API service"
    invocation: "/ring:dev-readyz"
    expected_flow: |
      1. Scan project for external dependencies
      2. Validate /readyz endpoint covers all deps
      3. Generate missing checks
      4. Implement startup self-probe
      5. Verify /health reflects self-probe result
---

# Readyz & Self-Probe Implementation

## Phase 1: Dependency Scan

Scan the project to detect ALL external dependencies:

```bash
# Go: detect imports and connection patterns
grep -rn 'pgx\|pgxpool\|mongo\.\|mongo-driver\|redis\.\|valkey\|amqp\|rabbitmq\|s3\|aws' go.mod internal/ pkg/ cmd/
grep -rn 'NewPostgres\|NewMongo\|NewRedis\|NewRabbit\|NewValkey\|WithModule' internal/

# TypeScript/Next.js: detect connection patterns
grep -rn 'MongoClient\|mongoose\|pg\|Pool\|redis\|amqplib\|S3Client' package.json src/ app/ lib/
```

Build dependency map: PostgreSQL (pgx), MongoDB (mongo-driver), Redis/Valkey (go-redis), RabbitMQ (amqp091-go), S3 (aws-sdk), HTTP clients. For each, detect if TLS is configured (`sslmode`, `tls=true`, `rediss://`, `amqps://`).

**SaaS deployment mode: TLS is MANDATORY for all database connections.** No exceptions.

## Phase 2: /readyz Endpoint

### Response Contract (MANDATORY)

```json
{
  "status": "healthy",
  "checks": {
    "postgres": { "status": "up", "latency_ms": 2, "tls": true },
    "mongodb":  { "status": "up", "latency_ms": 3, "tls": true },
    "rabbitmq": { "status": "up", "connected": true },
    "valkey":   { "status": "up", "latency_ms": 1, "tls": false }
  },
  "version": "1.2.3",
  "deployment_mode": "saas"
}
```

- `status`: `"healthy"` if ALL checks pass, `"unhealthy"` if ANY fails
- Each check includes `latency_ms` (for connections with ping) and `tls` (boolean)
- `deployment_mode`: from `DEPLOYMENT_MODE` env or inferred from config
- `version`: from build info or `VERSION` env

### Go Implementation (Fiber + lib-commons)

```go
// internal/adapters/http/in/readyz.go

type DependencyCheck struct {
    Status    string `json:"status"`
    LatencyMs int64  `json:"latency_ms,omitempty"`
    TLS       *bool  `json:"tls,omitempty"`
    Connected *bool  `json:"connected,omitempty"`
    Error     string `json:"error,omitempty"`
}

type ReadyResponse struct {
    Status         string                      `json:"status"`
    Checks         map[string]DependencyCheck  `json:"checks"`
    Version        string                      `json:"version"`
    DeploymentMode string                      `json:"deployment_mode"`
}

func isCacheDependency(name string) bool {
    normalized := strings.ToLower(name)
    return strings.Contains(normalized, "redis") ||
        strings.Contains(normalized, "valkey") ||
        strings.Contains(normalized, "cache")
}

func ReadyHandler(deps Dependencies) fiber.Handler {
    return func(c *fiber.Ctx) error {
        ctx, cancel := context.WithTimeout(c.UserContext(), 5*time.Second)
        defer cancel()

        resp := ReadyResponse{
            Status:         "healthy",
            Checks:         make(map[string]DependencyCheck),
            Version:        buildVersion,
            DeploymentMode: os.Getenv("DEPLOYMENT_MODE"),
        }

        // Each check: ping + measure latency + verify TLS
        // Use 2s timeout per dependency, 1s for cache
        for name, checker := range deps.HealthCheckers() {
            timeout := 2 * time.Second
            if isCacheDependency(name) {
                timeout = 1 * time.Second
            }

            depCtx, depCancel := context.WithTimeout(ctx, timeout)
            check := checker.Check(depCtx)
            depCancel()

            resp.Checks[name] = check
            if check.Status != "up" {
                resp.Status = "unhealthy"
            }
        }

        if resp.Status != "healthy" {
            return libHTTP.ServiceUnavailable(c, "UNHEALTHY", "Service Unhealthy", resp)
        }
        return libHTTP.OK(c, resp)
    }
}
```

### TLS Verification (CRITICAL)

Each checker MUST verify TLS state from the connection options (e.g., `connOpts.TLSConfig != nil` for Go, `mongoClient.options?.tls` for TS). This is what would have caught the Monetarie bug.

**RabbitMQ note:** The `amqp091-go` library's `*amqp.Connection` does not reliably expose TLS state after dialing. For RabbitMQ, TLS detection MUST inspect the connection URL scheme (`amqps://` = TLS, `amqp://` = plaintext). The checker constructor MUST accept the connection URL alongside the `*amqp.Connection` object and derive `tls: true/false` from the scheme. Do not attempt to reflect on the live connection object for this purpose.

### SaaS TLS Enforcement

"SaaS deployment mode: TLS is MANDATORY" means two separate things that are both required:

| Concern | Responsibility | Mechanism |
|---------|---------------|-----------|
| **Surface** TLS state | `/readyz` probe | Reports `"tls": true/false` per dependency in JSON response |
| **Enforce** TLS | Bootstrap / connection code | MUST refuse to start if `DEPLOYMENT_MODE=saas` and TLS is not configured |

MUST implement both. Surfacing without enforcement means the service starts silently insecure. Enforcement without surfacing means the Tenant Manager cannot confirm TLS posture post-provisioning. Neither alone is sufficient.

Bootstrap enforcement pattern (Go):

```go
if os.Getenv("DEPLOYMENT_MODE") == "saas" && connOpts.TLSConfig == nil {
    return nil, fmt.Errorf("TLS is required in SaaS mode but not configured for %s", depName)
}
```

### Next.js Implementation

Same pattern at `app/api/admin/health/readyz/route.ts`: ping each dependency, measure latency, check TLS, return 200/503 with the same JSON contract. Use `Response.json()` with appropriate status code.

### Endpoint Paths

| Stack | Ready Path | Health Path |
|-------|-------------|-------------|
| Go API | `/readyz` | `/health` |
| Go Worker | `/readyz` on `HEALTH_PORT` | `/health` on `HEALTH_PORT` |
| Next.js | `/api/admin/health/readyz` | same as Ready Path |

Next.js exposes a single `/api/admin/health/readyz` endpoint which serves both readiness and health checks.

## Phase 3: Startup Self-Probe

The app MUST run all readiness checks at boot and log results BEFORE accepting traffic.

### Go Implementation

```go
// cmd/app/main.go or internal/bootstrap/selfprobe.go

func RunSelfProbe(ctx context.Context, deps Dependencies, logger Logger) error {
    logger.Infow("startup_self_probe_started",
        "probe", "self",
    )
    results := make(map[string]DependencyCheck)
    allHealthy := true

    for name, checker := range deps.HealthCheckers() {
        check := checker.Check(ctx)
        results[name] = check

        if check.Status == "up" {
            logger.Infow("self_probe_check",
                "probe", "self",
                "name", name,
                "status", check.Status,
                "duration_ms", check.LatencyMs,
                "tls", check.TLS,
            )
        } else {
            logger.Errorw("self_probe_check",
                "probe", "self",
                "name", name,
                "status", check.Status,
                "duration_ms", check.LatencyMs,
                "error", check.Error,
            )
            allHealthy = false
        }
    }

    if !allHealthy {
        logger.Errorw("startup_self_probe_failed",
            "probe", "self",
            "results", results,
        )
        return fmt.Errorf("self-probe failed: one or more dependencies unreachable")
    }

    logger.Infow("startup_self_probe_passed",
        "probe", "self",
        "results", results,
    )
    return nil
}
```

### Impact on /health

Self-probe failure MUST affect /health:

```go
var selfProbeOK atomic.Bool // package-level

func init() { selfProbeOK.Store(false) } // unhealthy until proven otherwise

// At startup, after self-probe succeeds:
if err := RunSelfProbe(ctx, deps, logger); err != nil {
    // selfProbeOK stays false — /health returns 503
    // K8s liveness probe will restart the pod
} else {
    selfProbeOK.Store(true)
}

// /health handler
f.Get("/health", func(c *fiber.Ctx) error {
    if !selfProbeOK.Load() {
        return libHTTP.ServiceUnavailable(c, "UNHEALTHY", "Self-probe failed", nil)
    }
    return libHTTP.HealthWithDependencies(deps)(c)
})
```

**This is the key insight:** `/health` is no longer just "process alive." It's "startup self-probe passed AND lib-commons runtime dependency state is healthy." A pod that starts but can't reach its databases will be restarted by K8s instead of silently serving errors, and runtime dependency or circuit-breaker failures are still surfaced through the standard lib-commons health handler.

### Self-Probe Lifecycle

1. App starts → self-probe → logs each dep → `/health` reflects result
2. ALL pass: 200 on `/health`, `/readyz` operates normally
3. ANY fail: 503 on `/health`, K8s restarts pod via liveness probe
4. Optional: periodic re-probe via `SELF_PROBE_INTERVAL` env

### Next.js Self-Probe Lifecycle

Next.js `instrumentation.ts` `register()` executes once at process startup and BLOCKS before the first request is served — this IS the self-probe point for Next.js. Use it.

MUST NOT call `process.exit()` on probe failure inside `register()`. Doing so prevents K8s from collecting a useful log tail. Instead:

1. In `register()`: run all dependency checks; if any fail, set a module-level flag (`let startupHealthy = false`).
2. The `/api/admin/health/readyz` route handler checks this flag.
3. Return 503 with the failed checks if the flag is false.
4. K8s readinessProbe hits `/api/admin/health/readyz`, sees 503, and withholds traffic — no `process.exit()` needed.

```ts
// instrumentation.ts
let startupHealthy = false;
let startupChecks: Record<string, DependencyCheck> = {};

export async function register() {
  const results = await runAllChecks();
  startupChecks = results;
  startupHealthy = Object.values(results).every(c => c.status === "up");
  // log results here — process stays alive regardless
}

export { startupHealthy, startupChecks };
```

The `/api/admin/health/readyz` route imports `startupHealthy` and `startupChecks` from `instrumentation.ts` and returns 200 or 503 accordingly.

### Runtime vs Startup

These two mechanisms are complementary, not redundant:

| Mechanism | When | Purpose |
|-----------|------|---------|
| Self-probe | STARTUP — before first request | Validates dependencies are reachable before traffic is allowed |
| `/readyz` | RUNTIME — per request | Validates dependencies are still reachable as K8s readinessProbe |
| `/health` | RUNTIME — per request | Reflects self-probe result AND lib-commons runtime circuit-breaker state |

A pod that passes startup self-probe can still fail `/readyz` later (e.g., DB goes away mid-run). A pod that fails self-probe should never receive traffic in the first place. Both gates are necessary.

## Phase 4: Validation

Verify `/readyz` endpoint, `RunSelfProbe` function, and `/health` self-probe wiring all exist.

### Checklist

- [ ] All detected dependencies have a checker in /readyz
- [ ] Each checker validates TLS when TLS is configured
- [ ] Each checker has a timeout (2s DB, 1s cache)
- [ ] Response includes per-dep latency and TLS status
- [ ] Startup self-probe runs before accepting traffic
- [ ] Self-probe results logged as structured JSON
- [ ] /health returns 503 if self-probe failed
- [ ] Helm values use /readyz for readinessProbe
- [ ] SaaS mode enforces TLS on all DB connections

### Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "K8s TCP probe is enough" | TCP ≠ app ready. Monetarie incident: pod alive, Mongo dead. | **Implement /readyz** |
| "/health covers it" | /health without self-probe is blind to dep failures | **Add self-probe, wire to /health** |
| "TLS check is overhead" | TLS mismatch = silent failure for every query | **Check TLS per dependency** |
| "Only backend needs this" | Console (frontend) caused the incident | **All apps, no exceptions** |
| "Dependencies are reliable" | Networks partition. Configs drift. Certs expire. | **Check every time** |
| "Too many checks slow startup" | Bounded per-dependency timeouts keep overhead low. Incident costs hours. | **No excuse** |
| "Service has only one dependency" | One broken dependency = total outage. Complexity argument is irrelevant at zero scale. Self-probe is three lines of code. | **Implement self-probe, no exceptions** |
