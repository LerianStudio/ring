# Helm Conventions (Lerian Standard)

## Chart Location

Charts live in the **`LerianStudio/helm` monorepo**, one directory per chart:
- Public product → `charts/<svc>-helm/` → `oci://ghcr.io/lerianstudio/<svc>-helm`
- Closed/internal → `oci://ghcr.io/lerianstudio/helm-internal/<svc>-helm`

Do NOT author the chart in the app repo's `deploy/charts/` — that path is legacy.
The `home:`/`sources:` fields still point at the app's **source** repo (the code),
which is correct; the chart **files** live in the `helm` monorepo and are published
to OCI by that repo's `release.yml` (semantic-release). GitOps then references the
published OCI version.

## Chart Naming

```text
RULE: Chart name in Chart.yaml MUST have "-helm" suffix.

EXCEPTIONS (no suffix):
  - plugin-access-manager
  - otel-collector-lerian

EXAMPLES:
  ✅ reporter-helm
  ✅ tracer-helm
  ✅ plugin-fees-helm
  ✅ plugin-access-manager (exception)
  ❌ reporter (missing -helm)
  ❌ plugin-access-manager-helm (exception should NOT have suffix)
```

---

## Chart.yaml Template

```yaml
apiVersion: v2
name: {service}-helm
description: A Helm chart for deploying {service}
type: application
home: https://github.com/LerianStudio/{service}/tree/main/deploy/charts/{service}
sources:
  - https://github.com/LerianStudio/{service}
maintainers:
  - name: "Lerian Studio"
    email: "support@lerian.studio"
version: 1.0.0
appVersion: "1.0.0"
keywords:
  - midaz
  - lerian
  - {service}
icon: https://avatars.githubusercontent.com/u/148895005?s=200&v=4
```

---

## Directory Structure

```text
{service}/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl              # OR helpers.tpl (both valid)
│   ├── {component}/              # Per-component directory
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   ├── secrets.yaml
│   │   ├── ingress.yaml
│   │   ├── hpa.yaml
│   │   ├── pdb.yaml
│   │   └── sa.yaml               # ServiceAccount
│   └── common/                   # Shared resources
│       └── keda-trigger-authentication.yaml
└── charts/                       # Subchart dependencies
```

---

## Image Repository Convention

```text
FORMAT: ghcr.io/lerianstudio/{service-name}

For multi-component:
  ghcr.io/lerianstudio/{service}-{component}

EXAMPLES:
  ghcr.io/lerianstudio/reporter-manager
  ghcr.io/lerianstudio/reporter-worker
  ghcr.io/lerianstudio/plugin-fees
  ghcr.io/lerianstudio/product-console
```

---

## Service Type Rule

<cannot_skip>
Service type MUST always be ClusterIP.
No NodePort. No LoadBalancer. Ingress handles external access.
</cannot_skip>

---

## Port Allocation

```text
Lerian port ranges:
  3000-3099: Core one core services
  4000-4099: Plugin/application APIs
  5432: PostgreSQL
  5672: RabbitMQ AMQP
  6379: Redis/Valkey
  8080-8999: Legacy/infrastructure ports
  15672: RabbitMQ management
  27017: MongoDB
```

---

## README Version Matrix (NEW chart — create it)

The `LerianStudio/helm` root `README.md` carries a per-chart **Application Version
Mapping** table (Chart Version → each app component's image version). On a **new
chart** this section MUST be **created by hand** — the CI updater only maintains
existing tables and **errors** if the chart's table is missing
(`update-readme-matrix` → "Could not find version matrix table for chart 'X'").

Add a section to the root README:

```markdown
### {Chart Display Name}

For implementation and configuration details, see the [README](https://charts.lerian.studio/charts/{chart}).

#### Application Version Mapping

| Chart Version | {Component} Version |
| :---: | :---: |
| `{chart version}` | {component image tag} |
-----------------
```

- One `{Component} Version` column per app component (multi-component = one each,
  e.g. `Manager Version | Worker Version`).
- **Header format is load-bearing:** `TitleCase(component) + " Version"` — this is
  what `update-readme-matrix --component <name>` matches. Wrong header = CI can't
  update it on future bumps.
- First row: current chart `version` (backticked) + each component's image `tag`.

<cannot_skip>
Do NOT hand-bump versions after creation. Chart Version is managed by
semantic-release (`update-chart-version-readme` in release.yml); component versions
by `update-readme-matrix` on component bump. The chart-creation job only creates the
initial table STRUCTURE with correct headers + seed row.
</cannot_skip>
