# MongoDB Index Detection & Migration File Generation

**Only execute this phase if MongoDB was detected in any module during Phase 3.**

This phase detects MongoDB index definitions in two places:
1. **In-code indexes** — `EnsureIndexes()` methods in repository files that create indexes at startup
2. **Migration files** — `scripts/mongodb/*.up.json` / `*.down.json` per-index file pairs (or legacy `*.js` scripts)

**How tenant-manager uses these files:**
The tenant-manager reads `.up.json` and `.down.json` files from the S3 bucket and applies them automatically when provisioning or deprovisioning tenant databases. It reads `.up.json` to create indexes on new tenant databases, and `.down.json` to drop indexes when rolling back or deprovisioning. The service itself does NOT execute these files — the tenant-manager does.

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

## Step 3.5: Validate Existing S3 Migration JSON Files

**Execute BEFORE generating new files. Checks that existing `.up.json` and `.down.json` file pairs in S3 follow the canonical format.**

**Key principle: each index = one `.up.json` + one `.down.json` file pair.** Files are NOT grouped by collection — each index is an atomic migration.

### File Structure

Each `.up.json` wraps the index in an `"indexes"` array — even though each file contains only one index. This is the format the tenant-manager expects.

```json
{
  "collection": "connection",
  "indexes": [
    {
      "keys": {
        "organization_id": 1,
        "config_name": 1
      },
      "options": {
        "unique": true,
        "name": "idx_connection_org_config_name",
        "partialFilterExpression": {
          "deleted_at": null
        }
      }
    }
  ]
}
```

Each `.down.json` contains the drop instruction referencing the index name:

```json
{
  "collection": "connection",
  "indexNames": [
    "idx_connection_org_config_name"
  ]
}
```

**Key format rules (from real S3 files):**
- `.up.json` MUST have `"indexes"` array wrapper (even for single index)
- `"options"` MUST contain `"name"` field
- `"partialFilterExpression"` is common — include when the in-code index has a filter (e.g., soft-delete `{"deleted_at": null}`)
- `"unique": true` goes inside `"options"`, not alongside `"keys"`

### Index Name Conventions

Two naming prefixes are used:
- `idx_*` — general-purpose indexes, including unique indexes (e.g., `idx_connection_org_config_name` which has `"unique": true`)
- `uniq_*` — used when the index's primary purpose is enforcing a uniqueness business constraint (e.g., `uniq_job_org_hash_active` prevents duplicate active jobs per org+hash)

Both prefixes can have `"unique": true` in options. The distinction is semantic: `uniq_*` signals that uniqueness IS the business rule, while `idx_*` with unique signals a query-performance index that happens to enforce uniqueness.

Rules:
- Compound: concatenate field names with `_` (e.g., `idx_connection_org_product_config`)
- Nested fields: replace dots with underscores (e.g., `search.document` → `search_document`)
- The index name typically includes the collection name as prefix for disambiguation

### File Naming Convention

Each file pair follows the pattern: `{NNNNNN}_{index_name}.up.json` / `.down.json`

The `{index_name}` in the file name matches the `"name"` inside `"options"`.

```
scripts/mongodb/
├── 000001_idx_connection_org_config_name.up.json
├── 000001_idx_connection_org_config_name.down.json
├── 000002_idx_connection_org_created.up.json
├── 000002_idx_connection_org_created.down.json
├── 000003_idx_connection_org_database_name.up.json
└── 000003_idx_connection_org_database_name.down.json
```

The sequence number `{NNNNNN}` is globally incremented across all indexes to preserve creation order.

### Validation

```text
For EACH existing S3 migration file pair (downloaded in Step 2 or fetched now):

1. Verify AWS CLI + bucket access (same as Step 5 checks)
2. List existing migrations: aws s3 ls s3://{bucket}/{service}/ --recursive | grep mongodb
3. Download each .up.json and .down.json for comparison

VALIDATE each .up.json:

V1. Index name present:
    - "options" object MUST contain "name" field
    - Name MUST follow idx_* or uniq_* convention
    - ⛔ FAIL: {"keys": {"field": 1}, "options": {"unique": true}}  ← missing "name"
    - ✅ PASS: {"keys": {"field": 1}, "options": {"unique": true, "name": "idx_connection_field"}}
    - ✅ PASS: {"keys": {"field": 1}, "options": {"unique": true, "name": "uniq_job_org_hash"}}

V2. Key order matches code:
    - For compound indexes, the key order in the JSON MUST match the order
      in the Go source code (bson.D is ordered)
    - JSON object key order matters for MongoDB compound indexes (ESR rule)
    - ⛔ FAIL: code has {search.document: 1, external_id: 1} but JSON has {external_id: 1, search.document: 1}
    - ✅ PASS: both code and JSON have {search.document: 1, external_id: 1}

V3. File count matches code:
    - Total number of .up.json files per collection MUST match number of in-code indexes for that collection
    - Missing files → report as "S3 migration outdated — missing N index files"
    - Extra files → report as "S3 has N extra index files not in code — review"

VALIDATE each .down.json:

V4. Down references match up:
    - The "indexNames" array in .down.json MUST contain the exact "name" from the paired .up.json
    - ⛔ FAIL: .up.json has "idx_field_unique" but .down.json has "field_1" (auto-generated name)
    - ✅ PASS: .down.json has ["idx_field_unique"] matching .up.json

V5. Pair completeness:
    - Every .up.json MUST have a corresponding .down.json (and vice versa)
    - ⛔ FAIL: 000001_services_idx_tenant_id.up.json exists without .down.json
    - ✅ PASS: both .up.json and .down.json exist for every index

OUTPUT format:
  S3 Migration Validation:
  | File | V1 (name) | V2 (key order) | V4 (down match) | V5 (pair) | Status |
  |------|-----------|----------------|-----------------|-----------|--------|
  | 000001_holders_idx_tenant_id | ✅ | ✅ | ✅ | ✅ | PASS |
  | 000002_aliases_idx_external_id | ⛔ missing name | ⛔ key order | ⛔ auto-gen name | ✅ | FAIL |

  File count per collection:
  | Collection | In-Code | S3 Files | Status |
  |------------|---------|----------|--------|
  | holders    | 3       | 3        | ✅ Match |
  | aliases    | 2       | 1        | ⛔ Missing 1 |

If ANY validation fails → fix the JSON files and re-upload BEFORE generating new files.
```

---

## Step 4: Generate Migration Files for Missing Coverage

**Only if `missing_migration` entries exist.**

For each missing index, generate a `.up.json` and `.down.json` file pair. Each index is an atomic migration — one file pair per index, NOT grouped by collection.

**Directory:** `scripts/mongodb/` (create if it doesn't exist)

**Index naming convention (matches Step 3.5):**
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
1. Determine next sequence number:
   - Glob: scripts/mongodb/*.up.json
   - Extract highest NNNNNN from existing files
   - next_seq = highest + 1 (or 1 if no files exist)

2. For EACH missing index (from index_coverage.missing_migration):
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
   d. Write both files to scripts/mongodb/
   e. Increment sequence number

3. Example output for 2 missing indexes:
   scripts/mongodb/
   ├── 000001_idx_connection_org_config_name.up.json
   ├── 000001_idx_connection_org_config_name.down.json
   ├── 000002_idx_connection_org_created.up.json
   └── 000002_idx_connection_org_created.down.json
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

## Step 5: Upload Migration Files to S3

**Execute after Step 4 (file generation) or when migration files already exist.**

Upload `.up.json` and `.down.json` file pairs to S3 following the migrations bucket convention. Uses the AWS CLI installed on the local machine. Only JSON migration files are uploaded — `.js` convenience scripts are NOT uploaded.

### S3 Path Convention

The migrations bucket follows the **Service → Module → Resource Type** hierarchy:

```
{bucket}/
├── {service}/
│   ├── {module_1}/
│   │   ├── mongodb/        ← .up.json/.down.json pairs go here
│   │   └── postgresql/     ← DDL migrations (not managed by this skill)
│   └── {module_2}/
│       ├── mongodb/
│       └── postgresql/
```

Example for ledger service:
```
lerian-development-migrations/
├── ledger/
│   ├── onboarding/
│   │   ├── mongodb/         ← 14 files (7 indexes × 2 files each)
│   │   └── postgresql/      ← 9 DDL migrations
│   └── transaction/
│       ├── mongodb/         ← 8 files (4 indexes × 2 files each)
│       └── postgresql/      ← 18 DDL migrations
```

Each module's MongoDB migration files go into `s3://{bucket}/{service}/{module}/mongodb/`.

### Upload Flow

```text
1. Collect migration files per module:
   - For each module with MongoDB detected (from Phase 3):
     - Glob: scripts/mongodb/*.up.json AND scripts/mongodb/*.down.json
     - Map each file pair to its target module (via collection name in the file)
   - If none found → skip upload, log warning

2. Verify AWS CLI is available:
   - Run: aws --version
   - If not found → SKIP Step 5: Log warning "AWS CLI not installed. Skipping S3 upload."
     → Continue to Phase 4 report with upload status: "Skipped (AWS CLI not available)"

3. Ask the user which S3 bucket to use:
   "Found {N} index migration file pairs to upload for service '{service_name}'.
    Which S3 bucket should I upload to?

    Example: lerian-development-migrations
    (files will be placed at: s3://{bucket}/{service}/{module}/mongodb/)"

   - Wait for user response
   - Store as: s3_bucket = "{user_response}"

4. Verify S3 access:
   - Run: aws s3 ls s3://{s3_bucket}/ 2>&1
   - If access denied → SKIP Step 5: Log warning "No access to bucket '{s3_bucket}'."
     → Continue to Phase 4 report with upload status: "Failed (access denied)"
   - If bucket not found → SKIP Step 5: Log warning "Bucket '{s3_bucket}' not found."
     → Continue to Phase 4 report with upload status: "Failed (bucket not found)"

5. Upload each file pair to the correct module path (best-effort, continue on failure):
   - For each (file_pair, module):
     # Use the local filename directly — it already has the correct .up.json/.down.json extension
     aws s3 cp {up_json_path} \
       s3://{s3_bucket}/{service_name}/{module}/mongodb/$(basename {up_json_path}) \
       --content-type "application/json"
     aws s3 cp {down_json_path} \
       s3://{s3_bucket}/{service_name}/{module}/mongodb/$(basename {down_json_path}) \
       --content-type "application/json"
   - If a single upload fails, log the error and continue with remaining files
   - Track: successful_uploads = [], failed_uploads = []

6. Verify upload per module:
   - For each module:
     aws s3 ls s3://{s3_bucket}/{service_name}/{module}/mongodb/
   - List uploaded files with sizes
   - Verify .up.json and .down.json pairs are complete
   - If count mismatches: report as "Partially uploaded ({X}/{Y} pairs)"

7. Report results:
   "Uploaded {N} index migration pairs to S3:
    ✅ s3://{s3_bucket}/ledger/onboarding/mongodb/000001_metadata_idx_tenant_id.up.json
    ✅ s3://{s3_bucket}/ledger/onboarding/mongodb/000001_metadata_idx_tenant_id.down.json
    ✅ s3://{s3_bucket}/ledger/onboarding/mongodb/000002_metadata_idx_key_unique.up.json
    ✅ s3://{s3_bucket}/ledger/onboarding/mongodb/000002_metadata_idx_key_unique.down.json"
```

### Report Section Addition

Add to the Phase 4 HTML report:

```
┌──────────────────────────────────────────────────────────────┐
│ S3 Upload Status                                             │
├───────────────────────────────────────┬──────────────────────┤
│ Migration File                        │ Status               │
├───────────────────────────────────────┼──────────────────────┤
│ 000001_services_idx_tenant_id         │ ✅ Uploaded (up+down)│
│ 000002_services_idx_name_unique       │ ✅ Uploaded (up+down)│
│ 000003_audit_idx_created_at           │ ⚠️  Generated locally │
└───────────────────────────────────────┴──────────────────────┘
S3 prefix: s3://{bucket}/{service}/{module}/mongodb/
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
    The tenant-manager reads these from S3 to apply indexes on new tenant databases.
    Without them, new tenant databases will have NO indexes.
```

### Checklist Addition

For each module with MongoDB, add index status to the registration checklist:

```
- [ ] **Module:** `onboarding`
  - [ ] Resource: mongodb
  - [ ] MongoDB indexes: 3 in-code, 2 migration pairs (1 missing → will generate)
```
