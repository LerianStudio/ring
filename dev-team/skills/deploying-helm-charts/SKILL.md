---
name: ring:deploying-helm-charts
description: "Deploying an existing Lerian Helm chart via ring:helm-deploy: local validation (helm lint/template + best-effort minikube install with health verification) and GitOps wiring into a Lerian environment (helmfile.yaml + per-env values.yaml + ArgoCD app-of-apps Application), env-correct (ALB vs nginx, gp2 vs local-path, domain/TLS) and offline-render safe. Use after a chart exists (ring:creating-helm-charts) to test it locally and/or ship it to a GitOps env. Skip for authoring chart templates (use ring:creating-helm-charts) or non-Helm deploys."
---

# Helm Chart Deployment (local test + GitOps wiring)

## When to use
- Validating an existing Lerian chart locally (lint/template/minikube)
- Wiring a chart into a GitOps env (`lerian-aws-gitops` or `lerian-internal-gitops`)
- Adding a new addon/application to an environment via helmfile + ArgoCD

## Skip when
- Authoring chart templates/values → use `ring:creating-helm-charts` (agent `ring:helm`)
- Non-Helm deployment (raw manifests / docker-compose)

## Sequence
Standalone/on-demand. Runs **after** a chart exists. Complements `ring:creating-helm-charts`.

## Related
**Complementary:** ring:creating-helm-charts (authoring), ring:committing-changes (commit)

**Standards reference:** `dev-team/docs/standards/helm/local-testing.md`, `gitops-helmfile.md`
**Executor agent:** `ring:helm-deploy`

You orchestrate. `ring:helm-deploy` validates locally and writes the GitOps files.

## Step 1: Validate Input

Required: `chart_path` (existing `-helm` chart), `mode` (`local` | `gitops` | `both`),
`app_class` (`addon` | `service`).
For `gitops`/`both`: `repo` (`lerian-aws-gitops` | `lerian-internal-gitops`), `env`
(the target env name), `namespace`. For first-party services also:
`tier` (`stg-mt`/`dev-st`/`prd-st`/`cross`/`sandbox` on internal), `secrets_model`
(aws→`eso`, internal service→`vault`).
Optional: `minikube` (best-effort default true), `dependencies-toggles`.

## Step 2: Confirm Env Conventions (gitops modes)

Identify a **sibling of the same `app_class` in the same env/tier** to copy from:
- `project` (env-name on aws / tier-scoped `<env>-st`/`-mt`/`cross` on internal)
- `destination` (`name: <spoke cluster>` / `name: in-cluster` / `server:`)
- `plugin` (`avp-helmfile` for internal services, else `helmfile`)
- ingress class (nginx internal / alb aws), domain zone, storageClass, secrets model

If no same-class sibling exists → the agent reports and asks; do NOT guess.
Note: one internal env is AWS/EKS, not on-prem.

## Step 3: Dispatch Agent

```yaml
Task:
  subagent_type: "ring:helm-deploy"
  description: "Deploy {chart} → {repo}/{env}"
  prompt: |
    ## Helm Deployment

    chart_path: {chart_path}
    mode: {mode}            # local | gitops | both
    repo: {repo}
    env: {env}
    namespace: {namespace}
    minikube: {best-effort}

    Standards: load dev-team/docs/standards/helm/{index,local-testing,gitops-helmfile}.md

    ## Required Steps
    1. HARD GATE: chart exists + `helm lint .` passes (else STOP → ring:helm).
    2. Local ladder: helm lint; helm template (+ overlays, + keda.enabled=false if worker).
    3. Minikube (best-effort): if `minikube status` OK AND context is minikube →
       helm install --wait, verify pods Running/Ready + probes, then uninstall + delete ns.
       Else report `minikube: SKIPPED (render-only)`.
    4. GitOps wiring (if mode includes gitops):
       ADDON → file trio under environments/{env}/helmfile/addons/{name}/ +
         apps/applications/{name}.yaml (plugin helmfile; syncPolicy prune/selfHeal true).
       SERVICE → environments/{env}/helmfile/applications/[{tier}/]{name}/ with the
         **3-release template** (secrets→app→ingress via `needs:`): app chart from
         oci://ghcr.io/lerianstudio/{name}-helm (pinned); secrets via ESO (aws) or
         Vault refs (internal); ingress via incubator/raw; values.yaml with
         namespaceOverride + imagePullSecrets ghcr-credential. Application:
         plugin `avp-helmfile` (internal service) else `helmfile`; project/destination
         copied from same-class sibling; syncPolicy prune:false/selfHeal:false;
         ignoreDifferences Secret/data (+ Deployment/replicas if HPA).
       Both: env column (ingress/storageClass/domain/TLS); NO .Capabilities/lookup;
       PDB apiVersions pin only if the chart needs it.
    5. Pre-merge gate: `helmfile template` from the addon/service dir exits 0.

## Step 4: Verify Output

- Local: lint 0 failures; every template variant renders; minikube result reported
  (installed+verified OR explicitly SKIPPED).
- GitOps: file trio present; `helmfile template` exits 0; ingress/storageClass/domain
  match the env; Application `project`/`destination`/`ENV_ENV_NAME` match the sibling.
- Report the two runtime deps to confirm out-of-band: DNS record + host cert/wildcard.

## Step 5: Commit

Use `ring:committing-changes` (MUST NOT commit manually). Do NOT sync ArgoCD from
here — merging to `main` triggers the app-of-apps auto-sync.
