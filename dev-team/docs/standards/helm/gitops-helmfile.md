# GitOps Deploy via Helmfile (Lerian)

How a chart reaches a cluster at Lerian: **ArgoCD + a helmfile CMP plugin**, per
environment, in one of two GitOps repos. ArgoCD renders **offline**
(`helmfile template`) — templates MUST NOT use `.Capabilities` or `lookup`.

First decision, always: is this an **addon** (third-party cluster infra) or a
**first-party service** (a Lerian OCI chart)? They differ in almost every field.

## The two repos + cluster types

| Repo | Clusters | Ingress | storageClass | Domain / TLS | Secrets model |
|------|----------|---------|--------------|--------------|---------------|
| `lerian-aws-gitops` | AWS/EKS envs (control-plane + spokes) | **ALB** (kustomize `ingress/`, groups `public`/`private`) | EBS (aws-ebs-csi default) | private `*.<env>.<zone>` / ACM | **ESO** (External Secrets Operator) |
| `lerian-internal-gitops` | on-prem/eveo envs — **note: one env is actually AWS/EKS** | on-prem **nginx** / AWS-env **ALB** | on-prem `local-path` / AWS-env EBS | on-prem `*.<env>.<zone>` wildcard, `tls:[]` / AWS-env ACM | **Vault** via `avp-helmfile` |

⚠️ In `lerian-internal-gitops` one env is actually **AWS/EKS**, not on-prem — branch
on cluster **type**, not on repo. Confirm the target env's type from a sibling addon.

## addons vs first-party services

| | `helmfile/addons/<x>/` | `helmfile/applications/[<tier>/]<svc>/` |
|---|---|---|
| Content | third-party infra (consul, ingress-nginx, cert-manager, keda, seaweedfs, ESO, karpenter…) | first-party Lerian product charts |
| CMP plugin (internal repo) | `helmfile` (no Vault) | **`avp-helmfile`** (ArgoCD Vault Plugin) |
| Chart source | upstream helm repo / OCI | `oci://ghcr.io/lerianstudio/<svc>-helm` |
| Namespace | shared infra ns | `<svc>[-<tier>]`, hardcoded in helmfile |
| ArgoCD project | usually `cross` (internal) / env name (aws) | tier-scoped (`<env>-st`,`<env>-mt`,`sandbox`) / env name (aws) |
| syncPolicy | `prune:true, selfHeal:true` | **`prune:false, selfHeal:false`** (manual) |
| ignoreDifferences | none | **Secret `/data` + Deployment `/spec/replicas`** |

## First-party chart sources (OCI, pinned)

- Public products: `oci://ghcr.io/lerianstudio/<chart>-helm`
- Closed/internal: `oci://ghcr.io/lerianstudio/helm-internal/<chart>-helm`
- Also seen: Docker Hub mirror `oci://registry-1.docker.io/lerianstudio/<chart>-helm`
  (e.g. plugin-fees) and an `oci://ghcr.io/lerianstudio/alpha/<chart>` channel.
- `-helm` suffix, **except** `plugin-access-manager` and `otel-collector-lerian`.
- Charts are published from the `LerianStudio/helm` monorepo (canonical chart
  standard: `helm/docs/helm-chart-standard.md` + a Go validator). No `repositories:`
  entry — the OCI URL is inline in the release.

## The three-release template (first-party)

A service is **never one release**. Ordered by `needs:`:

```yaml
repositories:
  - name: incubator            # the universal "extra k8s resource" chart
    url: https://charts.helm.sh/incubator

releases:
  # 1) pull secret (+ on internal: iam-cert for the RolesAnywhere sidecar)
  - name: <svc>-secrets        # or ghcr-credential
    namespace: <ns>
    chart: incubator/raw
    values:
      - resources:
          # aws (ESO): ExternalSecret(s) from the org ClusterSecretStore, using the
          #   documented secret-path convention (per-svc creds + shared infra + ghcr) — copy a sibling
          # internal (Vault): dockerconfigjson pull Secret via a Vault ref
          #   <path:secret/data/<env>/ghcr-credential#dockerconfigjson>
          # optionally sync-wave "-100" so it lands before the chart
  # 2) the app chart
  - name: <svc>
    namespace: <ns>
    chart: oci://ghcr.io/lerianstudio/<svc>-helm
    version: "<pinned>"        # ALWAYS pin (GA or -beta.N)
    needs: [<ns>/<svc>-secrets]
    wait: true
    timeout: 600
    values: [values.yaml]
  # 3) ingress via raw (aws ALB group / internal nginx)
  - name: <svc>-ingress
    namespace: <ns>
    chart: incubator/raw
    needs: [<ns>/<svc>]
    values:
      - resources:
          - apiVersion: networking.k8s.io/v1
            kind: Ingress
            # aws: alb group.name + group.order + target-type ip + backend-protocol HTTP
            # internal: ingressClassName nginx + backend-protocol + tls:[] (wildcard)
```

`values.yaml` sets `namespaceOverride: <ns>`, image from ghcr with
`imagePullSecrets: [ghcr-credential]`, and (internal) Vault refs
`<path:secret/data/<env>/<svc>/<tier>#KEY>` resolved by AVP at render.

## Secrets: two models, do not mix

- **aws-gitops → ESO.** An `ExternalSecret` (via raw) pulls from the org's
  `ClusterSecretStore` using the documented secret-path convention (per-service
  credentials + shared infra secrets + the ghcr pull secret) — **copy a sibling** for
  the exact store name and paths. The chart consumes the synced K8s Secret (`existingSecret`).
- **internal-gitops → Vault + AVP.** The `avp-helmfile` plugin resolves
  `<path:secret/data/<env>/...#KEY>` placeholders at render. Pull secret comes from
  `secret/data/<env>/ghcr-credential`. Addons use the plain `helmfile` plugin (no Vault).

Both need `ignoreDifferences` on `Secret /data` (managed out-of-band, drifts by design).

## ArgoCD Application matrix

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <env>-<svc>[-<tier>]      # e.g. <env>-<svc>-<tier>
  namespace: argocd
  finalizers: [resources-finalizer.argocd.argoproj.io]   # present on services; inconsistent on addons
spec:
  project: <see matrix below>
  source:
    repoURL: https://github.com/LerianStudio/<repo>.git
    targetRevision: main
    path: environments/<env>/helmfile/applications/[<tier>/]<svc>
    plugin:
      name: <helmfile | avp-helmfile>          # avp-helmfile for first-party on internal repo
      env:
        - { name: APP_NAMESPACE, value: "<ns>" }
        - { name: ENV_ENV_NAME, value: "<env>" }   # NOTE: vestigial — not consumed by helmfiles; ns is hardcoded
  destination:
    # aws first-party: name: <registered spoke cluster>  |  aws control-plane: name: in-cluster
    # internal: server: https://kubernetes.default.svc
    namespace: <ns>
  syncPolicy:
    automated: { prune: false, selfHeal: false }   # SERVICES manual; ADDONS true/true
    syncOptions: [ CreateNamespace=true, ServerSideApply=true ]
  ignoreDifferences:                                # services only
    - { group: "", kind: Secret, jsonPointers: [/data] }
    - { group: apps, kind: Deployment, jsonPointers: [/spec/replicas] }   # if HPA
```

| Field | aws-gitops | internal-gitops |
|-------|-----------|-----------------|
| project | env name | tier-scoped (`<env>-st`, `<env>-mt`, `sandbox`, `cross`) |
| destination | first-party `name: <spoke cluster>`; control-plane `name: in-cluster` | `server: https://kubernetes.default.svc` |
| plugin | `helmfile` | addons `helmfile`; services `avp-helmfile` |
| secrets | ESO | Vault (AVP) |

Add CRD-operator flags (`retry`, `RespectIgnoreDifferences`,
`SkipDryRunOnMissingResource`) only for operator/CRD-heavy addons (ESO, keda, otel).

## Multi-tier fan-out (internal)

One service can exist as up to 6 near-identical copies per env
(`cross`, `dev-st`, `stg-st`, `prd-st`, `stg-mt`, `sandbox`) — each its own
`helmfile/applications/<tier>/<svc>/` dir **and** its own `apps/applications/<svc>-<tier>.yaml`.
There is **no helmfile `environments:`/gotmpl templating** — it is copy-paste. To add
a service to a new tier, copy a sibling tier dir + Application and adjust ns/tier/project.

## App-of-apps discovery

Directory-based: `apps/app-of-apps.yaml` points at `apps/applications/`; ArgoCD syncs
every `*.yaml` there as a child. Drop a file → it deploys. You do NOT sync a child
directly ("Resource not found in cluster" = parent hasn't synced → hard-refresh + sync
the parent app-of-apps).

## Offline-render caveats (ArgoCD CMP)

- No `.Capabilities`/`lookup` in templates.
- Pin `apiVersions: [policy/v1/PodDisruptionBudget]` **only** when the chart selects
  apiVersion via `.Capabilities` (e.g. consul) — not on every helmfile.
- `APP_NAMESPACE`/`ENV_ENV_NAME` are convention-only in these repos; namespaces are
  hardcoded in each helmfile. Do not rely on them to template anything.

## Pre-merge gate

```bash
cd environments/<env>/helmfile/{addons|applications/<tier>}/<svc>
helmfile template   # exit 0; inspect kinds
```

Merging to `main` triggers auto-sync (addons) or leaves services for manual sync.
Runtime deps render cannot prove: **DNS** → ingress LB, and the **cert/wildcard**
covering the host. Flag both.

## Anti-patterns
- Treating a first-party service like an addon (wrong plugin, one release, wrong sync).
- `.Capabilities`/`lookup`; unpinned OCI version.
- Mixing secret models (ESO on internal, Vault on aws).
- Guessing `project`/`destination`/plugin — **copy a sibling in the same env/tier**.
- Assuming all internal envs are on-prem (one is AWS/EKS).
- Assuming `ENV_ENV_NAME` templates the namespace (it doesn't).
