---
name: ring:dev-service-discovery
description: Scans a Go project and identifies the Service → Module → Resource hierarchy for dispatch layer registration. Detects modules, resources per module (PostgreSQL, MongoDB, RabbitMQ), database names, MongoDB indexes, and shared databases. Generates MongoDB index migration pairs (.up.json/.down.json), detects existing PostgreSQL migrations, produces a visual HTML report, and offers opt-in S3 upload. Use before ring:dev-multi-tenant on a new service or when mapping resources for dispatch.
---

# Service Discovery

## When to use
- User wants to know what to provision in dispatch layer for a service
- User asks "what services/modules/resources does this project have?"
- Before running ring:dev-multi-tenant on a new service
- User asks about MongoDB indexes in a project

## Skip when
- Not a Go project
- Task does not involve service discovery, dispatch layer, or resource mapping
- Project has no external dependencies

## Related
**Complementary:** ring:dev-multi-tenant, ring:dev-implementation

## Prerequisites
- Go project with go.mod in the current working directory


Scans Go project to produce dispatch layer registration data. Orchestrator executes all detection phases directly.

## Phase 1: Service Detection

```bash
# Service name
grep "ApplicationName\|ServiceName" internal/bootstrap/config.go 2>/dev/null | head -5
cat .env.example 2>/dev/null | grep -i "APPLICATION_NAME\|SERVICE_NAME" | head -3

# Service type
test -f go.mod && cat go.mod | head -3  # module path hints service purpose
ls internal/adapters/ 2>/dev/null       # adapters reveal type

# Unified service check
ls components/ 2>/dev/null              # multiple components = unified service
```

Output:
```
service_name: "my-service"
is_unified: true | false
components: [{name, path, applicationName}]  # if unified
```

## Phase 2: Module Detection

```bash
# Strategy A: Explicit WithModule calls (preferred)
grep -rn "WithModule(" internal/ components/ 2>/dev/null
# Extract string arg: WithModule("onboarding") → module "onboarding"

# Strategy B: Component-based (if no WithModule found)
ls components/  # each component = one module
# module_name = component's ApplicationName

# Strategy C: Single-component fallback
# module_name = service ApplicationName
```

Merge: Strategy A → B fills gaps → C fallback.

## Phase 3: Resource Detection per Module

For each module, scan `{component_path}/internal/adapters/`:

```bash
# PostgreSQL: subdirectory existence
ls {base_path}postgres/ 2>/dev/null

# MongoDB
ls {base_path}mongodb/ 2>/dev/null || ls {base_path}mongo/ 2>/dev/null

# RabbitMQ
ls {base_path}rabbitmq/ 2>/dev/null
grep -l "producer\|Producer" {base_path}rabbitmq/ 2>/dev/null
grep -l "consumer\|Consumer" {base_path}rabbitmq/ 2>/dev/null

# Redis (informational only — NOT a dispatch layer resource)
ls {base_path}redis/ 2>/dev/null
```

## Phase 3.5: Database Name Detection per Module

```bash
# From bootstrap config
grep -E 'env:"POSTGRES_NAME|env:"DB_.*_NAME|env:"MONGO_NAME|env:"MONGO_.*_NAME' \
  {component_path}/internal/bootstrap/config.go

# From .env.example (actual values)
grep -E "POSTGRES_NAME=|DB_.*_NAME=|MONGO_NAME=|MONGO_.*_NAME=" {component_path}/.env.example

# External datasources
grep -E "DATASOURCE_.*_DATABASE=" {component_path}/.env.example
```

Cross-reference across modules: same database name in 2+ modules = shared (provision once).

## Phase 4: MongoDB Index Detection & Migration File Generation

**Only execute if MongoDB was detected in any module during Phase 3.**

Execute the procedure in `references/mongodb-index-detection.md` — Steps 1, 2, 3, 4 only.
(Detection and local generation only; S3 upload is handled in Phase 6.)

1. **Step 1** — Detect in-code index definitions (`EnsureIndexes`, `IndexModel`, `CreateIndex`) per module.
2. **Step 2** — Detect existing local migration files in `{component_path}/scripts/mongodb/*.up.json` + `*.down.json` (fallback legacy `*.js`). LOCAL ONLY — no S3 lookup.
3. **Step 3** — Cross-reference code vs. local migration files, classify each as `covered` / `missing_migration` / `migration_only`.
4. **Step 4** — Generate one `.up.json` + `.down.json` file pair per missing index (atomic per index, NOT grouped by collection):
   - Path: `{component_path}/scripts/mongodb/{NNNNNN}_{index_name}.up.json` / `.down.json` — per-module directory preserves ownership for Phase 6 upload (single-component services resolve `{component_path}` to repo root)
   - Naming: `idx_{collection}_{fields}` (or `uniq_*` for uniqueness business rules)
   - HARD GATE: every `.up.json` MUST have explicit `"options.name"` matching the file name
   - **Track per module:** populate `module.generated_migration_files = [{up_file, down_file, index_name}, ...]` so Phase 6 knows exactly which files belong to which module

**Format reminder:** the dispatch layer reads `.up.json` / `.down.json` from S3 and applies indexes on tenant provisioning. The service does NOT execute these files. Legacy `.js` scripts are NOT uploaded — only JSON migrations.

## Phase 4.5: PostgreSQL Migration Detection

**Only execute if PostgreSQL was detected in any module during Phase 3.**

Detection only — Postgres migrations are written by developers; this skill does NOT generate `.sql` files.

```bash
# Common golang-migrate locations (per module path resolved in Phase 3)
ls {component_path}/scripts/postgres/*.up.sql 2>/dev/null
ls {component_path}/scripts/postgresql/*.up.sql 2>/dev/null
ls {component_path}/db/migrations/*.up.sql 2>/dev/null
ls {component_path}/migrations/*.up.sql 2>/dev/null
```

For each `.up.sql` file found:
- Verify the matching `.down.sql` exists (golang-migrate convention).
- Map it to its module (by directory path).
- Track for the Phase 6 upload.

Store: `module.postgres_migrations = [{up_file, down_file, sequence, description}]`

If a `.up.sql` exists without `.down.sql` → flag in Phase 5 HTML report (golang-migrate requires pairs).

## Phase 5: Generate HTML Report

Dispatch `ring:visualize`:

```
Generate HTML report showing:
- Service: {service_name} | Unified: {is_unified}
- For each module:
  - Resources table: type, repositories/collections, has_producer, has_consumer, queues
  - Database names: postgres_db, mongo_db (with env var names)
  - Redis: detected / not detected (note: key prefixing only)
- Shared databases: list with modules that share them
- Dispatch layer registration template (JSON)
- MongoDB index coverage table (collection / keys / code / migration / index name) per `references/mongodb-index-detection.md` "Report Section: MongoDB Index Coverage"
- PostgreSQL migration table per module: file count, missing-pair warnings (`.up.sql` without `.down.sql`)
- Upload-ready summary: total Mongo pairs and Postgres pairs to be offered for upload in Phase 6

Style: clean, data-dense table layout
```

## Phase 6: Optional S3 Upload

**Execute after Phase 5. Always opt-in — never upload without explicit user confirmation.**

```text
1. Print summary and ask:
   "Ready to upload to S3:
    - MongoDB: {N} index migration pairs (.up.json/.down.json) across {M} modules
    - PostgreSQL: {P} migration pairs (.up.sql/.down.sql) across {Q} modules
    Upload to S3? (y/n)"

2. If user declines → done. Files remain local. Report status: "Upload skipped by user."

3. If user accepts:
   a. Verify AWS CLI: `aws --version`. If absent → abort, report "AWS CLI not installed."
   b. Ask: "Which S3 bucket? (e.g., lerian-development-migrations)"
   c. Ask: "Which environment? (staging / production)"
   d. Verify access: `aws s3 ls s3://{bucket}/{env}/ 2>&1`. If access denied or 404 → abort, report error.

4. Upload Mongo files (per module, best-effort — continue on individual failures):
   for each module with module.generated_migration_files populated in Phase 4:
     for each {up_file, down_file} in module.generated_migration_files:
       aws s3 cp {up_file}   s3://{bucket}/{env}/{service}/{module}/mongodb/$(basename {up_file})   --content-type "application/json"
       aws s3 cp {down_file} s3://{bucket}/{env}/{service}/{module}/mongodb/$(basename {down_file}) --content-type "application/json"

5. Upload Postgres files (per module, best-effort):
   for each module with module.postgres_migrations populated in Phase 4.5:
     for each {up_file, down_file} in module.postgres_migrations:
       aws s3 cp {up_file}   s3://{bucket}/{env}/{service}/{module}/postgresql/$(basename {up_file})   --content-type "application/sql"
       aws s3 cp {down_file} s3://{bucket}/{env}/{service}/{module}/postgresql/$(basename {down_file}) --content-type "application/sql"

6. Verify per module:
   aws s3 ls s3://{bucket}/{env}/{service}/{module}/mongodb/
   aws s3 ls s3://{bucket}/{env}/{service}/{module}/postgresql/

7. Report uploaded files (full s3:// paths) and any errors. Do NOT abort the whole run if a single file fails — list failures at the end.
```

**Path convention (matches actual bucket layout):** `s3://{bucket}/{env}/{service}/{module}/{mongodb|postgresql}/{filename}`

## Output: Dispatch Layer Registration Template

```json
{
  "service": "{service_name}",
  "modules": [
    {
      "name": "{module_name}",
      "resources": [
        {
          "type": "postgresql",
          "database": "{db_name}",
          "env_var": "POSTGRES_NAME"
        },
        {
          "type": "mongodb",
          "database": "{db_name}",
          "env_var": "MONGO_NAME"
        },
        {
          "type": "rabbitmq",
          "has_producer": true,
          "has_consumer": true,
          "queues": ["{queue_name}"]
        }
      ]
    }
  ],
  "shared_databases": []
}
```
