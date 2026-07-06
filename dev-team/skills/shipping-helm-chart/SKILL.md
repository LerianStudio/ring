---
name: ring:shipping-helm-chart
description: "End-to-end Helm delivery for a Lerian service: create the chart from the app project (ring:creating-helm-charts), validate it (helm lint/template + best-effort minikube), gate on publish (merge to LerianStudio/helm → CI publishes the OCI chart to ghcr), then wire it into a GitOps env (ring:deploying-helm-charts). Use to take a new/updated Lerian chart from app source all the way to a running cluster. Skip for chart-authoring only (use ring:creating-helm-charts) or deploying an already-published chart (use ring:deploying-helm-charts)."
---

# Ship a Helm Chart (app source → GitOps)

The full Lerian Helm lifecycle, in order. This skill **orchestrates two existing
skills** and makes the **publish gate** and **ordering** explicit — it does not
re-implement their logic.

## When to use
- Taking a Lerian service from app repo to a deployed chart, first time or a rev
- You need the whole path (create → validate → publish → gitops), not one slice

## Skip when
- Only authoring/fixing chart templates → `ring:creating-helm-charts`
- Only deploying a chart that is **already published** to OCI → `ring:deploying-helm-charts`

## Related
**Delegates to:** `ring:creating-helm-charts` (author), `ring:deploying-helm-charts` (wire)
**Standards:** `dev-team/docs/standards/helm/` (index → load per phase)
**Commit:** `ring:committing-changes`

## Chart location (decide first)
Charts live in the **`LerianStudio/helm` monorepo**, one per dir:
- Public product → `charts/<svc>-helm/` → `oci://ghcr.io/lerianstudio/<svc>-helm`
- Closed/internal → published to `oci://ghcr.io/lerianstudio/helm-internal/<svc>-helm`
NOT in the app repo's `deploy/charts/`. (See conventions.md → Chart Location.)

## The flow (ordered — the gate is real)

### Phase 1 — Create (in the helm monorepo)
Invoke **`ring:creating-helm-charts`**. It reads the app's `.env.example`/config,
scaffolds `charts/<svc>-helm/`, wires dependencies, security, probes, and — for a
NEW chart — the README **Application Version Mapping** matrix. If the service needs
AWS creds, apply the RolesAnywhere sidecar (`aws-rolesanywhere.md`).

### Phase 2 — Validate (local)
Invoke **`ring:deploying-helm-charts`** in `mode: local`: `helm lint`, `helm template`
(+ overlays, + `keda.enabled=false` if worker), and best-effort minikube install.
Gate: lint 0 failures, all templates render, minikube installed-and-healthy OR
explicitly `SKIPPED (render-only)`.

### Phase 3 — PUBLISH GATE (CI-owned — do not skip)
Commit + merge the chart to `LerianStudio/helm` (`ring:committing-changes`, `feat:`
so semantic-release bumps it). On merge, **`release.yml` publishes the OCI chart**
to `ghcr.io/lerianstudio[/helm-internal]/<svc>-helm` and updates the README matrix
version. **The chart version is CI-owned — never hand-pin it.**

⛔ GitOps wiring (Phase 4) **cannot render** until the OCI version exists: a brand-new
chart's `helmfile template` fails to pull until Phase 3 completes. Wait for the
published version (e.g. `oras` / `helm show chart oci://.../<svc>-helm --version X`).

### Phase 4 — Wire GitOps (deploy)
Invoke **`ring:deploying-helm-charts`** in `mode: gitops` with `app_class: service`,
the target `repo`/`env`/`tier`/`namespace`, `secrets_model` (aws→`eso`,
internal→`vault`), pinned to the **published** OCI version. It emits the file trio
(secrets[+iam-cert] → app → ingress), the ArgoCD Application, and gates on
`helmfile template`. Merge → app-of-apps picks it up (services sync manually).

## Verify (end to end)
- Phase 1: env coverage 100%, chart lint clean, matrix present (new chart).
- Phase 3: published OCI version resolvable.
- Phase 4: `helmfile template` exit 0 against the published version; Application
  project/destination/plugin/syncPolicy match a same-class sibling.
- Runtime deps to confirm out-of-band: DNS → ingress LB, host cert/wildcard.

## Anti-patterns
- Wiring GitOps before the chart is published (Phase 4 before Phase 3) → render fails.
- Hand-pinning the chart version (CI owns it).
- Authoring the chart in the app repo instead of the `helm` monorepo.
- Running it as one monolithic step — each phase is a checkpoint; stop on failure.
