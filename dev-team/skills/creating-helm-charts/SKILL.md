---
name: ring:dev-helm
description: |
  Mandatory skill for creating and maintaining Helm charts following Lerian conventions.
  Enforces standardized chart structure, values organization, template patterns,
  security defaults, and dependency management.
---

# Helm Chart Creation & Maintenance

## When to use
- Creating a new Helm chart for any Lerian service
- Modifying an existing Helm chart (adding components, dependencies, templates)
- Reviewing a Helm chart PR for convention compliance
- Migrating a docker-compose setup to Helm

## Skip when
- Modifying only application code (no chart changes)
- Working on non-Helm deployment (docker-compose only) → use backend engineer via ring:dev-implementation

## Sequence
Standalone/on-demand. Not part of the lean backend dev-cycle.

## Related
**Complementary:** ring:dev-implementation


**Standards reference:** `dev-team/docs/standards/helm/`
**Executor agent:** `ring:helm-engineer`

You orchestrate. `ring:helm-engineer` creates chart files.

## Step 1: Validate Input

Required: `service_name`, `chart_type` (single|multi-component|umbrella), `components` (non-empty).
Optional: `dependencies` (postgresql, mongodb, rabbitmq, valkey, keda), `has_worker`, `namespace`.

## Step 2: Naming Convention

```
Default: {service_name}-helm  (e.g., reporter-helm, tracer-helm)
Exceptions (no -helm suffix):
  - plugin-access-manager
  - otel-collector-lerian
```

## Step 3: Dispatch Agent

```yaml
Task:
  subagent_type: "ring:helm-engineer"
  description: "Create Helm chart for {service_name}"
  prompt: |
    ## Helm Chart Creation

    service_name: {service_name}
    components: {components}
    dependencies: {dependencies}
    chart_type: {chart_type}
    namespace: {namespace}

    Standards: Load dev-team/docs/standards/helm/ files.

    ## Required Steps
    1. Read application .env.example and bootstrap/config.go
       — extract ALL env vars (missing vars = CrashLoopBackOff)
    2. Verify health check endpoint in application source
    3. Create chart structure:

    charts/{service_name}-helm/
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/
    │   ├── _helpers.tpl
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   ├── secret.yaml (if secrets exist)
    │   ├── hpa.yaml (optional)
    │   └── serviceaccount.yaml
    └── charts/ (dependencies)

    4. Chart.yaml: name, version, appVersion, description, type: application
    5. _helpers.tpl: name, fullname, chart, labels, selectorLabels, versionLabelValue
    6. values.yaml structure:
       - global: replicaCount, image.repository/tag/pullPolicy
       - Per-component config sections
       - configmap: all non-secret env vars
       - secrets: all sensitive env vars (no real values)
       - service: type: ClusterIP, port, targetPort
       - resources: requests/limits
       - probes: livenessProbe, readinessProbe (match /health and /readyz)
       - dependencies config sections

    7. Security defaults:
       - securityContext: runAsNonRoot: true, runAsUser: 1000
       - readOnlyRootFilesystem: true
       - allowPrivilegeEscalation: false

    8. Service type: ALWAYS ClusterIP (never NodePort or LoadBalancer)

    ## Required Output
    - Env Var Coverage table (100% of .env.example covered)
    - helm lint result: MUST PASS
    - helm template render: MUST produce valid YAML
    - Files created list
```

## Step 4: Validate Output

```
if env_vars_missing > 0:
  → FAIL: list missing vars, re-dispatch

if helm lint fails:
  → Re-dispatch with specific lint errors

if all checks PASS:
  → Proceed to worker setup or final validation
```

## Worker Chart (if has_worker = true)

Additional dispatch for worker component:
- Separate Deployment without Service
- Different resource limits (CPU-focused, no port exposure)
- Same configmap/secrets references
- LivenessProbe via process check (not HTTP)

## Validation Checklist

```markdown
## Helm Chart Validation

| Check | Status | Evidence |
|-------|--------|----------|
| Env var coverage (100%) | ✅/❌ | X/Y vars mapped |
| helm lint PASS | ✅/❌ | command output |
| helm template renders | ✅/❌ | YAML valid |
| Security context set | ✅/❌ | deployment.yaml:{line} |
| Service type = ClusterIP | ✅/❌ | service.yaml:{line} |
| Health probes match endpoints | ✅/❌ | deployment.yaml:{line} |
| No real secrets in values | ✅/❌ | |
```
