# MongoDB Index Detection & Migration File Generation

**Only execute this phase if MongoDB was detected in any module during Phase 3.**

This phase detects MongoDB index definitions in two places:
1. **In-code indexes** — `EnsureIndexes()` methods in repository files that create indexes at startup
2. **Migration files** — `scripts/mongodb/*.up.json` / `*.down.json` per-index file pairs (or legacy `*.js` scripts)

**Scope:** detection (Steps 1–3) and file generation (Step 4). LOCAL only — this reference does NOT validate files already in S3 and does NOT upload. The opt-in S3 upload (combined Mongo + Postgres) is handled by SKILL.md Phase 6.

**How dispatch layer uses these files:**
The dispatch layer reads `.up.json` and `.down.json` files from the S3 bucket and applies them automatically when provisioning or deprovisioning tenant databases. It reads `.up.json` to create indexes on new tenant databases, and `.down.json` to drop indexes when rolling back or deprovisioning. The service itself does NOT execute these files — the dispatch layer does.

---

## Step 1: Detect In-Code Index Definitions

```text
For EACH module where MongoDB was detected:

1. Find EnsureIndexes methods:
   - Grep tool (regex): grep -E 'func.*EnsureIndexes|IndexModel|CreateIndex|createIndex'
     in {base_path}mongodb/ OR {base_path}mongo/ --include="*.go"
   - For each file with matches, extract:
     a. Collection name (from the receiver's collection field or constant)
     b. Index keys (from bson.D{{Key: "field", Value: 1}})
     c. Index options (unique, sparse, TTL, partialFilterExpression, etc.)
     d. Index name (if specified via SetName)
     e. Partial filter expression (if SetPartialFilterExpression or PartialFilterExpression is used — commonly {"deleted_at": null} for soft-delete)

2. Parse index models:
   - Look for mongo.IndexModel{} structs
   - Extract Keys (bson.D fields) and Options
   - Map bson.D ordered pairs to a flat object: bson.D{{Key: "a", Value: 1}, {Key: "b", Value: -1}} → {"a": 1, "b": -1}
   - Map each to: {collection, keys: {field: order, ...}, unique: bool, name: string}
   - MUST use flat object format for keys (same as Step 2 script detection) to enable cross-referencing

Store results:
  module.mongo_indexes_in_code = [
    {
      file: "service_repository.go",
      collection: "services",
      indexes: [
        {keys: {"service_name": 1}, unique: true, name: ""},
        {keys: {"tenant_id": 1, "service_name": 1}, unique: true, name: ""},
      ]
    }
  ]
```

---

## Step 2: Detect Existing Migration Files

```text
Scan for existing MongoDB migration file pairs:

1. Primary source — JSON migration files (per-index):
   - Glob tool: pattern "scripts/mongodb/*.up.json"
   - For each .up.json found:
     a. Read and parse JSON
     b. The index is inside "indexes" array (always one element per file)
     c. Extract: collection (from "collection" field), keys (from "indexes[0].keys"), index_name (from "indexes[0].options.name")
     d. Also extract: partialFilterExpression, unique, sparse, expireAfterSeconds if present in options
     e. Verify corresponding .down.json exists
     f. Map each to: {file, collection, keys, index_name, options, has_down: bool}

2. Fallback source — legacy .js scripts (per-collection):
   - Glob tool: pattern "scripts/mongodb/*.js" OR "scripts/mongo/*.js"
   - For each script found:
     a. Extract collection name (from db.getCollection("name"))
     b. Extract index definitions (from both createIndex() and createIndexSafely() calls)
     c. Map each index to: {file, collection, keys, index_name}
   - Only use if NO .up.json files are found (legacy project support)

3. Also check for:
   - Makefile targets that reference mongosh or mongo scripts
   - Docker/docker-compose commands that run index scripts
   - CI/CD pipeline steps that execute index creation

Store results (one entry per index, not per file):
  existing_migrations = [
    {
      file: "scripts/mongodb/000001_services_idx_tenant_id.up.json",
      collection: "services",
      keys: {"tenant_id": 1},
      index_name: "idx_tenant_id",
      has_down: true
    },
    {
      file: "scripts/mongodb/000002_services_idx_tenant_service_unique.up.json",
      collection: "services",
      keys: {"tenant_id": 1, "service_name": 1},
      index_name: "idx_tenant_service_unique",
      has_down: true
    }
  ]
```

---

## Step 3: Cross-Reference and Identify Gaps

```text
Compare in-code indexes vs migration files.
Both sources use the same flat object format for keys (e.g., {"tenant_id": 1, "service_name": 1}).

For each in-code index:
  - Compute index_name using naming convention (idx_{collection}_{field}, idx_{collection}_{f1}_{f2}, etc.)
  - Find matching migration (same collection + same key fields in same order)
  - If found → status: "covered"
  - If NOT found → status: "missing_migration"

For each migration file:
  - Find matching in-code index (same collection + same key fields in same order)
  - If found → status: "covered"
  - If NOT found → status: "migration_only" (migration exists but no code match)

Generate gap analysis:
  index_coverage = {
    covered: [{collection, keys, index_name, in_code_file, migration_file}],
    missing_migration: [{collection, keys, index_name, in_code_file}],  // needs .up.json/.down.json
    migration_only: [{collection, keys, index_name, migration_file}],   // extra migrations, no code match
  }
```

---

## Step 4: Generate Migration Files for Missing Coverage

**Only if `missing_migration` entries exist.**

For each missing index, generate a `.up.json` and `.down.json` file pair. Each index is an atomic migration — one file pair per index, NOT grouped by collection.

**Directory (per module):** `{component_path}/scripts/mongodb/` (create if it doesn't exist)
For single-component services this resolves to `scripts/mongodb/` at the repo root. For unified services with multiple components, each module writes to its own component path so Phase 6 can map files back to modules unambiguously.

**Module tracking (MANDATORY):** as files are written, append each pair to `module.generated_migration_files = [{up_file, down_file, index_name}, ...]`. Phase 6 (S3 upload, opt-in) iterates this array per module — without it, the upload phase has no reliable file→module mapping in multi-component services.

**Index naming convention:**
- Standard: `idx_{collection}_{field1}_{field2}` (e.g., `idx_connection_org_config_name`)
- Unique constraint: `uniq_{collection}_{field1}_{field2}` (e.g., `uniq_job_org_hash_active`)
- Nested fields: replace dots with underscores (e.g., `search.document` → `search_document`)
- Include collection name in the index name for disambiguation

**File naming convention:**
- `{NNNNNN}_{index_name}.up.json`
- `{NNNNNN}_{index_name}.down.json`
- The `{index_name}` in the filename matches `"options.name"` inside the JSON
- Sequence number `{NNNNNN}` is globally incremented (start from last existing number + 1, or 000001 if none exist)

**⛔ HARD GATE: Index naming is MANDATORY.**
Every `.up.json` MUST have an explicit `"name": "idx_..."` in its `options`.
The corresponding `.down.json` MUST use that exact name in `indexNames`.
Indexes without explicit names use MongoDB's auto-generated names (e.g., `field_1`),
which are inconsistent across environments and break down migrations.

### Generation Flow

```text
For EACH module with `missing_migration` entries (sequence is per-module):

1. Determine next sequence number for this module:
   - Glob: {component_path}/scripts/mongodb/*.up.json
   - Extract highest NNNNNN from existing files
   - next_seq = highest + 1 (or 1 if no files exist)

2. For EACH missing index in this module (from index_coverage.missing_migration):
   a. Compute index_name from keys using naming convention above
   b. Generate .up.json (MUST use "indexes" array wrapper):
      {
        "collection": "{collection}",
        "indexes": [
          {
            "keys": {keys object — flat format matching Step 1},
            "options": {
              "name": "{index_name}"
              // add "unique": true if index is unique
              // add "partialFilterExpression": {...} if index has a filter (e.g., soft-delete)
              // add "sparse": true if index is sparse
              // add "expireAfterSeconds": N if TTL index
            }
          }
        ]
      }
   c. Generate .down.json:
      {
        "collection": "{collection}",
        "indexNames": ["{index_name}"]
      }
   d. Write both files to {component_path}/scripts/mongodb/
   e. Append {up_file, down_file, index_name} to module.generated_migration_files
   f. Increment sequence number

3. Example output for a unified service with 2 modules (onboarding, transaction):
   components/onboarding/scripts/mongodb/
   ├── 000001_idx_metadata_tenant_id.up.json
   ├── 000001_idx_metadata_tenant_id.down.json
   components/transaction/scripts/mongodb/
   ├── 000001_idx_account_external_id.up.json
   └── 000001_idx_account_external_id.down.json

   For a single-component service, files land at scripts/mongodb/ at the repo root.
```

### .up.json Template

```json
{
  "collection": "{collection}",
  "indexes": [
    {
      "keys": {
        "{field1}": 1,
        "{field2}": 1
      },
      "options": {
        "unique": true,
        "name": "idx_{collection}_{field1}_{field2}",
        "partialFilterExpression": {
          "deleted_at": null
        }
      }
    }
  ]
}
```

### .down.json Template

```json
{
  "collection": "{collection}",
  "indexNames": [
    "idx_{collection}_{field1}_{field2}"
  ]
}
```

### Convenience: mongosh Script (Optional)

After generating all `.up.json`/`.down.json` pairs, optionally generate a single `create-{collection}-indexes.js` script per collection for manual execution via `mongosh`. This script is NOT uploaded to S3 — it exists only for local convenience.

```javascript
// MongoDB Index Creation Script for {Collection} Collection
// Generated from: {N} .up.json migration files
// Usage: mongosh "mongodb://localhost:27017/{database}" scripts/mongodb/create-{collection}-indexes.js

function createIndexSafely(collection, keys, options) {
    const indexName = options.name || Object.entries(keys).map(([k, v]) => `${k}_${v}`).join("_");
    options.name = indexName;
    const existingIndexes = collection.getIndexes();
    const indexExists = existingIndexes.some(idx => idx.name === indexName);

    if (indexExists) {
        print(`  [SKIP] Index '${indexName}' already exists`);
        return true;
    }

    try {
        collection.createIndex(keys, options);
        print(`  [OK] Index '${indexName}' created successfully`);
        return true;
    } catch (err) {
        print(`  [ERROR] Failed to create index '${indexName}': ${err.message}`);
        return false;
    }
}

const coll = db.getCollection("{collection}");
let success = true;

// {For each .up.json of this collection, generate a createIndexSafely call}
success = createIndexSafely(coll,
    { "{field}": 1 },
    { name: "idx_{field}" }
) && success;

print(success ? "All indexes OK" : "WARNING: Some indexes failed");
```

---

## Report Section: MongoDB Index Coverage

Include this section in the Phase 4 HTML report when MongoDB indexes are detected.

### Table Format

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ MongoDB Index Coverage                                                       │
├──────────────┬────────────────────┬────────┬──────────────────┬─────────────┤
│ Collection   │ Index Keys         │ Code   │ Migration (.json)│ Index Name  │
├──────────────┼────────────────────┼────────┼──────────────────┼─────────────┤
│ services     │ {service_name: 1}  │ ✅     │ ✅               │ idx_service_name_unique │
│ services     │ {tenant_id: 1}     │ ❌     │ ✅ (extra)       │ idx_tenant_id │
│ services     │ {status: 1}        │ ❌     │ ✅ (extra)       │ idx_status  │
│ audit_logs   │ {created_at: 1}    │ ✅     │ ❌ MISSING       │ (to generate) │
└──────────────┴────────────────────┴────────┴──────────────────┴─────────────┘

Legend:
  ✅ ✅  = Covered (in code + has .up.json/.down.json pair)
  ✅ ❌  = Missing migration files (will be generated)
  ❌ ✅  = Migration-only (no code match — review if still needed)
```

If there are **missing migration files**, show a callout:

```
⚠️  {N} indexes detected in code without corresponding .up.json/.down.json pairs.
    Migration files will be generated automatically in scripts/mongodb/.
    Each index = one .up.json + one .down.json file.
    The dispatch layer reads these from S3 to apply indexes on new tenant databases.
    Without them, new tenant databases will have NO indexes.
```

### Checklist Addition

For each module with MongoDB, add index status to the registration checklist:

```
- [ ] **Module:** `onboarding`
  - [ ] Resource: mongodb
  - [ ] MongoDB indexes: 3 in-code, 2 migration pairs (1 missing → will generate)
```
