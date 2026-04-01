---
name: ring:pm-team:lerian-map-management
description: |
  Manage the Lerian Map platform — maintain products, features, iterations, and delivery roadmaps
  via REST API. Enforces Lerian naming/tagging standards, keeps map data in sync with repository
  activity, and supports TPMs/PMs in keeping the map 100% accurate.

trigger: |
  - Creating or updating a product, feature, or iteration in the Lerian Map
  - Importing or refreshing a delivery roadmap
  - Updating feature status based on PR/commit activity
  - Reviewing or applying map naming/tagging standards
  - Binding map features to GitHub PRs or commits via tags
  - Generating a map health/completeness report

skip_when: |
  - Querying map data only (no write intended) → use lerian-map skill directly
  - GitHub-only operations (PRs, issues, commits) → use ring:dev-cycle

related:
  similar: [ring:pre-dev-feature-map, ring:delivery-status-tracking]
  complementary: [ring:pre-dev-delivery-planning, ring:pmo-retrospective]
---

# Lerian Map Management

## Core Rules

1. **API only** — never scrape or browser-automate the Lerian Map UI.
2. **Standards first** — apply naming, language, and tagging conventions before writing.
3. **Evidence before status** — only update feature status when backed by repo evidence (PR merged, commit, release).
4. **Sync is two-way** — map updates may trigger PR descriptions; PR activity may trigger map status updates.

---

## API Quick Reference

**Connectivity:** `map.clotilde.lerian.net` is on the internal Clotilde server — **Tailscale must be active** or all requests will fail (timeout / DNS not resolving).

**Base URL:** `https://map.clotilde.lerian.net/api`
**Auth:** `Authorization: Bearer $API_KEY`

```bash
API_KEY=$(security find-generic-password -a gandalf -s lerian-map-api-key -w)
```

| Entity | List | Create | Update | Delete |
|--------|------|--------|--------|--------|
| Products | `GET /products` | `POST /products` | `PUT /products/{id}` | `DELETE /products/{id}` |
| Features | `GET /features?productId=&status=&iterationId=` | `POST /features` | `PUT /features/{id}` | `DELETE /features/{id}` (soft) |
| Iterations | `GET /iterations` | `POST /iterations` | `PUT /iterations/{id}` | `DELETE /iterations/{id}` (soft) |

**Import delivery roadmap:**
```bash
curl -s -X POST https://map.clotilde.lerian.net/api/features/{id}/import-roadmap \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"markdown": "<roadmap content>", "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD"}'
```

---

## Naming & Description Standards

### Language
- All product and feature **names**: English only.
- **Descriptions**: English only.
- Exception: client-facing labels explicitly requested in Portuguese.

### Product Names
Format: `<Domain> - <Capability>` or a single noun when unambiguous.
Examples: `Core one Console`, `Plugin PIX`, `Fees`, `Reporter`.

### Feature Names
Format: imperative action phrase — concise, no filler words.
- ✅ `Balance Update Refactor`, `Multi-Tenant RabbitMQ`, `Rate Limit Middleware`
- ❌ `feat: add new feature for X`, `improve the X thing`, `WIP: balance`

Max length: 80 characters.

### Descriptions
- Max 500 characters (API enforced).
- One sentence of context + one sentence of outcome.
- No internal jargon, ticket IDs, or Slack thread references.

### Tags — PR/Commit Binding
To enable automatic status sync via Ring agents, PRs and commits must reference the map feature ID in the title or body:

```
feat(reporter): add dashboard with reminders [map:#18]
```

Tag format: `[map:#<featureId>]` — include in PR title or first line of body.
This allows Ring's delivery-status-tracking to auto-match PRs to features without manual input.

---

## Feature Status Lifecycle

| Status | Meaning | Evidence Required |
|--------|---------|-------------------|
| `planned` | Scoped, not started | Feature created, no PRs |
| `in_progress` | Active development | Open PR or commits on feature branch |
| `completed` | Shipped | PR merged to main/master or release tag |
| `delayed` | Past endDate, not completed | endDate passed + no completion evidence |

**Never mark completed without a merged PR or release as evidence.**

---

## Iteration Standards

- Name format: `Sprint YYYY-MM-DD / YYYY-MM-DD` (start/end of the iteration window).
- Alternatively: `Q1 2026 · Wave 1` for quarterly cadences.
- All active features must have an `iterationId` assigned. Features without iteration = scheduling debt.

---

## Delivery Plan Standards

When importing a delivery roadmap (`/import-roadmap`), the markdown must follow the format from `ring:pre-dev-delivery-planning`. Key requirements:

- Each task must have: name, owner, planned start, planned end, dependencies.
- Dates must be ISO 8601 (`YYYY-MM-DD`).
- Include a Taura Security window if the feature touches auth, payment flows, or external APIs. Example entry:

```markdown
### Taura Security Review
- Owner: Security (Taura)
- Start: YYYY-MM-DD
- End: YYYY-MM-DD
- Depends on: [implementation tasks]
```

Adjust `endDate` on the feature to account for the Taura window — never ship before security sign-off.

---

## Console Product — Special Rule

The Lerian Console is a **transversal product**: its features are owned and developed by the domain teams (Core one, PIX, Reporter, etc.), not a dedicated Console team.

When creating Console features in the map:
- Set `productId` to the Console product ID.
- Set `repositoryPath` to the owning team's repo (e.g., `LerianStudio/midaz-console`).
- Feature name must reflect the domain: `Console: Balance Visualization` not just `Balance Visualization`.

**Never register a Console subproduct or plugin as a standalone product** — it creates duplicate tracking and breaks portfolio visibility.

---

## Map Health Check

Run periodically (weekly or before weekly/planning meetings) to surface gaps:

```bash
API_KEY=$(security find-generic-password -a gandalf -s lerian-map-api-key -w)

# Features with no iteration assigned
curl -s -H "Authorization: Bearer $API_KEY" \
  "https://map.clotilde.lerian.net/api/features" \
  | jq '[.[] | select(.iterationId == null and .status != "completed")]'

# Features past endDate still in_progress or planned
TODAY=$(date +%Y-%m-%d)
curl -s -H "Authorization: Bearer $API_KEY" \
  "https://map.clotilde.lerian.net/api/features" \
  | jq --arg today "$TODAY" \
    '[.[] | select(.endDate != null and .endDate < $today and (.status == "planned" or .status == "in_progress"))]'
```

Report format (post to #product-team or weekly digest):
- Features with no iteration: list with owner
- Delayed features: list with days overdue, last known PR activity
- Features with no description: list
- Features with no `[map:#id]` tag on any linked PR: list

---

## Workflow: Adding a New Feature

1. Confirm product exists — `GET /products`, match by name.
2. Apply naming standard (English, imperative, ≤80 chars).
3. Write description (context + outcome, ≤500 chars).
4. Set `status: planned`, assign `iterationId` if sprint is known.
5. Set `startDate` / `endDate` from delivery plan.
6. Set `repositoryPath` to the owning repo.
7. `POST /features` — capture returned `id`.
8. Notify owning team to add `[map:#<id>]` to their PRs.

## Workflow: Updating Feature Status from PRs

1. Read PR title + body for `[map:#<id>]` tag.
2. Fetch feature: `GET /features/{id}`.
3. Map PR state → feature status:
   - PR open → `in_progress`
   - PR merged → `completed` (set `endDate` to merge date if not already set)
   - PR closed without merge + no other open PRs → back to `planned`
4. `PUT /features/{id}` with new status (and `endDate` if completing).

## Workflow: Import Delivery Roadmap

1. Fetch delivery roadmap markdown from repo (`docs/pre-dev/<feature>/delivery-roadmap.md`).
2. Ensure Taura window is present if applicable.
3. `POST /features/{id}/import-roadmap` with markdown + dates.
4. Verify import: `GET /features/{id}` — confirm `startDate` / `endDate` reflect plan.
5. Update feature `status` to `in_progress` if development has started.
