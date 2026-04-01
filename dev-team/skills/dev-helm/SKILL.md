---
name: dev-helm
description: |
  Mandatory skill for creating and maintaining Helm charts following Lerian conventions.
  Enforces standardized chart structure, values organization, template patterns,
  security defaults, and dependency management.
metadata:
  anti_patterns: |
    - "It's a simple chart, I don't need all that" → Every chart grows. Structure prevents debt.
    - "I'll add security later" → Security is foundational, not an afterthought.
    - "The defaults are fine" → Lerian has specific conventions that MUST be followed.
    - "I'll just copy another chart" → Copying without understanding introduces drift. Use this skill.
  dependencies:
  - ring:dev-devops
  input_schema:
    required:
    - name: service_name
      type: string
      description: Name of the service (e.g., reporter, tracer, plugin-fees)
    - name: chart_type
      type: string
      enum:
      - single
      - multi-component
      - umbrella
      description: Chart architecture type
    - name: components
      type: array
      items: string
      description: List of components (e.g., [manager, worker] or [pix, inbound, outbound])
    optional:
    - name: dependencies
      type: array
      items: string
      description: Infrastructure dependencies (postgresql, mongodb, rabbitmq, valkey, keda)
    - name: has_worker
      type: boolean
      description: Whether the service has a background worker (ScaledJob/Deployment)
      default: false
    - name: namespace
      type: string
      description: Target Kubernetes namespace
  output_schema:
    format: markdown
    required_sections:
    - name: Chart Structure
      pattern: ^## Chart Structure
      required: true
    - name: Validation Results
      pattern: ^## Validation Results
      required: true
    metrics:
    - name: compliance_status
      type: enum
      values:
      - PASS
      - FAIL
      - PARTIAL
    - name: files_created
      type: integer
  related:
    complementary:
    - ring:dev-devops
    - ring:dev-sre
    - ring:dev-implementation
    similar:
    - ring:dev-devops
  role: orchestrator
  sequence:
    after:
    - ring:dev-devops
    before:
    - ring:dev-sre
  skip_when: |
    - Modifying only application code (no chart changes)
    - Working on non-Helm deployment (docker-compose only) → Use ring:dev-devops
  trigger: |
    - Creating a new Helm chart for any Lerian service
    - Modifying an existing Helm chart (adding components, dependencies, templates)
    - Reviewing a Helm chart PR for convention compliance
    - Migrating a docker-compose setup to Helm
  verification:
    automated:
    - command: helm lint .
      description: Helm linter passes
      success_pattern: 0 chart\(s\) failed
    - command: helm template test . 2>&1 | head -5
      description: Template renders without errors
      success_pattern: ^(apiVersion|-{3})
    manual:
    - All values.yaml fields follow Lerian naming conventions
    - Secrets do not contain real credentials
    - Health check paths match application endpoints
---

# Helm Chart Creation & Maintenance (Lerian Conventions)

## Overview

This skill enforces Lerian's Helm chart conventions across all services. Every Helm chart MUST follow these patterns to ensure consistency, security, and operability across the platform.

**Reference standards:** [`dev-team/docs/standards/helm/`](../../docs/standards/helm/index.md)
**Executor agent:** `ring:helm-engineer`

## CRITICAL: Role Clarification

| Who | Responsibility |
|-----|----------------|
| **This Skill (ring:dev-helm)** | Orchestrates the workflow: validates input, dispatches agent, verifies output |
| **Agent (ring:helm-engineer)** | Executes: reads app source, creates chart files, validates with helm lint |

---

## Step 1: Validate Input

<verify_before_proceed>
- service_name is provided
- chart_type is one of: single, multi-component, umbrella
- components list is not empty
</verify_before_proceed>

```text
REQUIRED INPUT:
- service_name: name of the service
- chart_type: single | multi-component | umbrella
- components: list of component names

OPTIONAL INPUT:
- dependencies: [postgresql, mongodb, rabbitmq, valkey, keda]
- has_worker: true/false
- namespace: target namespace

if any REQUIRED input is missing:
  → STOP and report: "Missing required input: [field]"
```

---

## Step 2: Scaffold Chart Structure

MUST create the standard directory structure. See [helm/conventions.md](../../docs/standards/helm/conventions.md) for:

- Chart naming convention (`-helm` suffix rule and exceptions)
- Chart.yaml template with all required fields
- Directory structure (per-component directories, common/ for shared resources)
- Image repository naming convention
- Service type rule (always ClusterIP)
- Port allocation ranges

### Naming Convention Quick Reference

```text
CHART NAME RULES:
- Default: {service_name}-helm (e.g., reporter-helm, tracer-helm)
- Exception: plugin-access-manager (no -helm suffix)
- Exception: otel-collector-lerian (no -helm suffix)

if service_name is NOT in exception list:
  → chart name = {service_name}-helm
```

---

## Step 3: Create _helpers.tpl

MUST define helper functions per component. See [helm/templates.md](../../docs/standards/helm/templates.md#helpers-_helperstpl) for:

- Required helper functions (name, fullname, chart, labels, selectorLabels, versionLabelValue)
- Mandatory Kubernetes labels (app.kubernetes.io/*)
- Multi-component additional labels (component, part-of)

---

## Step 4: Create values.yaml

<cannot_skip>
values.yaml MUST follow the exact Lerian structure.
</cannot_skip>

See [helm/values.md](../../docs/standards/helm/values.md) for:

- Complete top-level structure (global overrides, per-component config, common shared, dependencies)
- ConfigMap vs Secrets classification rules
- Mandatory environment variable groups (app config, telemetry, health, auth, database)

<block_condition>
HARD GATE: MUST read the application's .env.example or config.go to extract ALL expected
environment variables. Do NOT guess. Missing env vars are the #1 cause of CrashLoopBackOff.
</block_condition>

---

## Step 5: Dispatch Agent

<dispatch_required agent="ring:helm-engineer">
Create/update Helm chart following Lerian conventions.
</dispatch_required>

```yaml
Task:
  subagent_type: "ring:helm-engineer"
  description: "Create Helm chart for {service_name}"
  prompt: |
    ⛔ MANDATORY: Create Helm chart following Lerian conventions.

    ## Context
    - **Service:** {service_name}
    - **Components:** {components}
    - **Dependencies:** {dependencies}
    - **Chart Type:** {chart_type}

    ## Required Steps
    1. Read application .env.example and config struct
    2. Verify health check endpoints in application source
    3. Create chart structure per Lerian conventions
    4. Map ALL env vars to configmap/secrets
    5. Validate with helm lint and helm template

    ## Required Output
    - Standards Verification (FIRST)
    - Env Var Coverage table (100% coverage required)
    - Validation Results (helm lint MUST pass)
```

```text
if agent returns env_vars_missing > 0:
  → FAIL: "Chart has missing env vars. Fix before proceeding."

if agent returns helm_lint_status == FAIL:
  → Re-dispatch agent with specific lint errors

if all checks PASS:
  → Proceed to Step 6 (Worker) or Step 7 (Validation)
```

---

## Step 6: Worker Component (if has_worker)

<verify_before_proceed>
- Is there a background worker/consumer component?
- Does it use KEDA ScaledJob or standard Deployment?
</verify_before_proceed>

See [helm/worker-patterns.md](../../docs/standards/helm/worker-patterns.md) for:

- Dual-mode pattern (KEDA default + Deployment fallback)
- Template guards for mode selection
- ScaledJob template requirements
- Worker Deployment template requirements

---

## Step 7: Validate Chart

<cannot_skip>
ALL checks MUST pass before chart is considered complete.
</cannot_skip>

### Automated Validation

```text
RUN in order:

1. helm lint .
   → MUST pass with 0 failures

2. helm template test .
   → MUST render without errors

3. helm template test . --set keda.enabled=false
   → MUST render without errors (if worker exists)

4. Verify ALL application env vars are covered:
   → Read app's .env.example or config struct
   → Compare with configmap + secrets in values.yaml
   → REPORT any missing vars

5. Verify health check paths:
   → Read app's health endpoint registration code
   → Compare with probe paths in deployment template
   → REPORT any mismatches
```

### Manual Checklist

```text
CHECK each item:

[ ] Chart.yaml name has -helm suffix (unless exception)
[ ] Image declarations use structured repository/tag/pullPolicy with kindIs guard ([pattern](../../docs/standards/helm/templates.md#image-declaration-pattern-mandatory))
[ ] All values quoted in ConfigMap ({{ $value | quote }})
[ ] No hardcoded credentials in values.yaml (use placeholders)
[ ] Security context: runAsNonRoot: true, drop ALL capabilities
[ ] Service type is ClusterIP (never NodePort or LoadBalancer)
[ ] HPA enabled by default with CPU and memory metrics
[ ] PDB enabled by default
[ ] Probes match actual application health endpoints
[ ] initContainers wait for all infrastructure dependencies
[ ] Secrets support useExistingSecret pattern
[ ] All env vars from app's .env.example are present
[ ] OTEL injection is conditional on ENABLE_TELEMETRY
[ ] AWS IAM sidecar is conditional on aws.rolesAnywhere.enabled
[ ] Ingress disabled by default
```

---

## Pressure Resistance

See [shared-patterns/shared-pressure-resistance.md](../shared-patterns/shared-pressure-resistance.md)

| User Says | Your Response |
|-----------|---------------|
| "Skip the security context" | "Security context is **MANDATORY**. All containers MUST run as non-root." |
| "We don't need PDB" | "PDB is **REQUIRED** for production readiness. Adding it now." |
| "Just use the default health path" | "**MUST verify** health paths against application code. Wrong paths cause CrashLoopBackOff." |
| "We'll add env vars later" | "Missing env vars are the #1 cause of deployment failures. Reading .env.example now." |
| "No need for existing secret support" | "**MANDATORY** for production. Teams use external secret managers." |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Health probes are the same for all services" | Each service has unique endpoints. Wrong paths = CrashLoopBackOff | **MUST read application source code** |
| "We can use NodePort for testing" | Lerian convention: always ClusterIP. Ingress handles external access | **Set service.type: ClusterIP** |
| "Secrets can use default values" | Default passwords in values.yaml are a security risk | **Use empty strings or placeholders** |
| "One configmap for everything" | Sensitive data MUST be in Secrets, not ConfigMap | **Split per ConfigMap vs Secrets rule** |
| "The chart works, so it's done" | Must validate against app env vars AND lint AND template render | **Run ALL validation steps** |
| "initContainers are overkill" | Without dependency checks, pods crash before DB is ready | **Add wait-for-dependencies** |
| "Just use a flat string for the image" | CI gitops-update can't target the tag independently; breaks automated deploys | **Use structured repository/tag/pullPolicy with kindIs guard** |

---

## Execution Report Format

```markdown
## Helm Chart Report: {service_name}

**Status:** [PASS|FAIL|PARTIAL]
**Chart Type:** [single|multi-component|umbrella]
**Components:** [list]
**Dependencies:** [list]

## Files Created/Modified
| File | Action | Status |
|------|--------|--------|
| Chart.yaml | CREATED | OK |
| values.yaml | CREATED | OK |
| templates/_helpers.tpl | CREATED | OK |
| templates/{component}/deployment.yaml | CREATED | OK |
| ... | ... | ... |

## Env Var Coverage
| Source (.env.example) | In ConfigMap | In Secrets | Status |
|-----------------------|-------------|------------|--------|
| SERVER_PORT | YES | - | OK |
| DB_PASSWORD | - | YES | OK |
| MISSING_VAR | NO | NO | MISSING |

## Validation Results
| Check | Status |
|-------|--------|
| helm lint | PASS/FAIL |
| helm template (default) | PASS/FAIL |
| helm template (no keda) | PASS/FAIL |
| Health paths verified | PASS/FAIL |
| All env vars covered | PASS/FAIL |
| Security context | PASS/FAIL |
| No hardcoded secrets | PASS/FAIL |

## Notes
- [Any deviations from standard with justification]
```
