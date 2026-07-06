# Helm Local Testing (lint → template → minikube)

Validation ladder for a Lerian chart **before** it is wired into GitOps. Runs
entirely on the engineer's machine. Minikube install is **best-effort**: attempt
it when a local cluster is reachable; otherwise stop at render validation and
report the skip explicitly. Never claim a cluster install that did not run.

---

## Rung 1 — Static render (ALWAYS required)

```bash
cd charts/<service>-helm

helm lint .                                   # 0 failures required
helm template test . > /tmp/render.yaml       # must render without errors
helm template test . --set keda.enabled=false # if a worker exists (both modes)
```

Gate: `helm lint` = 0 failures AND every `helm template` variant exits 0.
Inspect `/tmp/render.yaml` for the resources you expect (Deployment/StatefulSet,
Service, ConfigMap, Secret, probes, HPA/PDB). A resource silently missing =
values mis-wired.

## Rung 2 — Dependency + values sanity

```bash
helm dependency build .          # resolves Chart.yaml deps into charts/
helm template test . -f values.yaml -f values-<env>.yaml   # each env overlay
```

Gate: every env overlay renders clean. Diff the rendered env vars against the
app's `.env.example` — `env_vars_missing` MUST be 0 (missing = CrashLoopBackOff).

## Rung 3 — Minikube install (BEST-EFFORT)

```bash
# Detect a usable local cluster first; skip gracefully if absent.
minikube status >/dev/null 2>&1 || { echo "SKIP: no minikube — render-only"; exit 0; }
kubectl config current-context   # confirm it is minikube, NOT a real cluster

NS=<service>-test
helm install <service> . -n "$NS" --create-namespace \
  --set <secrets/creds as needed> --wait --timeout 300s
```

Then verify actual runtime health (this is what render cannot prove):

```bash
kubectl get pods -n "$NS"                       # all Running/Ready
kubectl rollout status deploy/<service> -n "$NS" --timeout=120s
kubectl describe pod -n "$NS" -l app.kubernetes.io/name=<service> | grep -A3 -iE "liveness|readiness"
kubectl logs -n "$NS" -l app.kubernetes.io/name=<service> --tail=50   # no panics/CrashLoop
```

Cleanup after verifying:

```bash
helm uninstall <service> -n "$NS" && kubectl delete ns "$NS"
```

### Best-effort contract
- No minikube / not reachable → **report `minikube: SKIPPED (render-only)`**, do
  not fail the task.
- Context is a **real cluster** (not minikube) → **STOP**, never install.
- Install ran → report pod status, probe results, and that cleanup happened.

## Output — Local Testing block

```markdown
## Testing
| Rung | Command | Result |
|------|---------|--------|
| lint | helm lint . | ✅ 0 failures |
| template | helm template test . | ✅ 18 resources |
| template (keda off) | --set keda.enabled=false | ✅ 16 resources |
| env overlays | -f values-<env>.yaml | ✅ all render |
| minikube | helm install --wait | ✅ Running/Ready · ⏭️ SKIPPED (no cluster) |
```

## Anti-patterns
- Reporting "installed OK" without pod/probe evidence.
- Installing into a non-minikube context.
- Skipping the `--set keda.enabled=false` render when a worker exists.
- Treating a render pass as proof the app boots — only Rung 3 proves that.
