# Helm Standards Compliance

## Standards Compliance Output Format

When invoked from the `ring:planning-backend-refactor` skill with a codebase-report.md, `ring:helm` MUST produce a Standards Compliance section comparing the chart against Lerian Helm conventions.

### Output Format

```markdown
## Standards Compliance

| # | Convention | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Chart naming (-helm suffix) | ✅/❌ | Chart.yaml name field |
| 2 | ConfigMap/Secrets split | ✅/❌ | file:line |
| 3 | Security context | ✅/❌ | file:line |
| 4 | Probe paths match app | ✅/❌ | file:line |
| 5 | Env var coverage (100%) | ✅/❌ | N covered / M total |
| 6 | HPA enabled | ✅/❌ | file:line |
| 7 | PDB enabled | ✅/❌ | file:line |
| 8 | Service ClusterIP | ✅/❌ | file:line |
| 9 | Ingress disabled by default | ✅/❌ | file:line |
| 10 | Labels (app.kubernetes.io/*) | ✅/❌ | file:line |
```

## Checklist

```text
CHECK each item:

[ ] Chart.yaml name has -helm suffix (unless exception)
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
