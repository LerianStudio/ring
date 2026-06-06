# Helm Standards - Index

> **⚠️ MAINTENANCE:** This directory is indexed in `dev-team/skills/shared-patterns/standards-coverage-table.md`.
> When adding/removing sections, follow FOUR-FILE UPDATE RULE in CLAUDE.md.

This directory contains modular Helm chart standards for Lerian Studio. Load only the modules you need.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Quick Reference - Which File for What](#quick-reference---which-file-for-what) | Task-based file selection guide |
| 2 | [Module Index](#module-index) | All 6 modules with descriptions |
| 3 | [WebFetch URLs](#webfetch-urls) | Raw GitHub URLs for agent loading |

---

## Quick Reference - Which File for What

| Task | Load These Files |
|------|------------------|
| **New Helm chart (full)** | conventions.md → values.md → templates.md → dependencies.md |
| **Add worker component** | worker-patterns.md → templates.md |
| **Audit chart compliance** | conventions.md → values.md → templates.md |
| **Add dependency** | dependencies.md |
| **ConfigMap/Secrets review** | values.md |
| **Security context review** | templates.md |

---

## Module Index

| # | Module | Description |
|---|--------|-------------|
| 1 | [conventions.md](conventions.md) | Chart naming, Chart.yaml template, directory structure, image repos, service type, port allocation |
| 2 | [values.md](values.md) | values.yaml structure, ConfigMap vs Secrets classification, mandatory env var groups |
| 3 | [templates.md](templates.md) | Deployment pattern, security context, health checks, secrets, initContainers, envFrom, HPA, ConfigMap, dynamic env vars |
| 4 | [dependencies.md](dependencies.md) | Subchart versions (PostgreSQL, MongoDB, RabbitMQ, Valkey, KEDA), bootstrap jobs |
| 5 | [worker-patterns.md](worker-patterns.md) | Dual-mode KEDA ScaledJob + Deployment fallback, trigger authentication |
| 6 | [compliance.md](compliance.md) | Standards Compliance output format for ring:helm |

---

## WebFetch URLs

For agents loading standards via WebFetch:

| Module | URL |
|--------|-----|
| **index.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/helm/index.md` |
| conventions.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/helm/conventions.md` |
| values.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/helm/values.md` |
| templates.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/helm/templates.md` |
| dependencies.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/helm/dependencies.md` |
| worker-patterns.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/helm/worker-patterns.md` |
| compliance.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/helm/compliance.md` |
