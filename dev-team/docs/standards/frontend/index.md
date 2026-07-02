# Frontend Standards - Testing Index

> **⚠️ MAINTENANCE:** This directory is indexed in `dev-team/skills/shared-patterns/standards-coverage-table.md`.
> When adding/removing sections, follow FOUR-FILE UPDATE RULE in CLAUDE.md.

This directory contains testing-mode-specific frontend standards from Lerian Studio. The general frontend standards live in [`../frontend.md`](../frontend.md); this index covers the 4 specialized testing modules dispatched by `ring:qa-frontend`.

> **Reference**: Always consult `docs/PROJECT_RULES.md` for common project standards.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Quick Reference - Which File for What](#quick-reference---which-file-for-what) | Task-based file selection guide |
| 2 | [Module Index](#module-index) | All 4 testing modules with descriptions |
| 3 | [WebFetch URLs](#webfetch-urls) | Raw GitHub URLs for agent loading |

---

## Quick Reference - Which File for What

| Task | Load These Files |
|------|------------------|
| **General frontend standards** | ../frontend.md (parent file) |
| **Accessibility testing (Gate 2)** | testing-accessibility.md |
| **Visual regression testing (Gate 4)** | testing-visual.md |
| **End-to-end testing (Gate 5)** | testing-e2e.md |
| **Performance testing (Gate 6)** | testing-performance.md |

---

## Module Index

| # | Module | Description |
|---|--------|-------------|
| 1 | [testing-accessibility.md](testing-accessibility.md) | axe-core automated scans, WCAG 2.1 AA compliance, keyboard navigation, screen reader testing |
| 2 | [testing-visual.md](testing-visual.md) | Snapshot tests, viewport coverage, state coverage, edge case visualization |
| 3 | [testing-e2e.md](testing-e2e.md) | Playwright user-flow tests across Chromium, Firefox, WebKit |
| 4 | [testing-performance.md](testing-performance.md) | Core Web Vitals (LCP, FID, CLS), Lighthouse score >90, bundle size budgets |

---

## WebFetch URLs

For agents loading standards via WebFetch:

| Module | URL |
|--------|-----|
| **index.md** | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/index.md` |
| testing-accessibility.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-accessibility.md` |
| testing-visual.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-visual.md` |
| testing-e2e.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-e2e.md` |
| testing-performance.md | `https://raw.githubusercontent.com/LerianStudio/ring/main/dev-team/docs/standards/frontend/testing-performance.md` |
