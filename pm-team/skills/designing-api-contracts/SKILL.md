---
name: ring:designing-api-contracts
description: "Designing the API contract as a real OpenAPI 3.1 specification (openapi.yaml with full paths, operations, schemas, components, Lerian error envelope, and auth schemes) from the validated TRD. Gate 4 of ring:planning-large-features, Large Track only; runs after ring:writing-trds, before ring:designing-data-model. Use when a system exposes APIs that components or clients consume. Skip for Small Track, a system with no API surface, or an unvalidated TRD."
---

# API Contract Design — Producing the OpenAPI Spec

## When to use

- TRD passed Gate 3 validation
- System exposes APIs (internal or external) that components or clients consume
- Large Track workflow (2+ day features)

## Skip when

- Small Track workflow → skip to ring:writing-plans
- No API surface (batch job, library, internal worker) → skip to Data Model
- TRD not validated → complete Gate 3 first

## Sequence

**Runs before:** ring:designing-data-model
**Runs after:** ring:writing-trds

The deliverable is a REAL, machine-consumable **OpenAPI 3.1 spec** — not markdown tables. Implementation agents generate handlers, clients, and tests directly from this file. If it doesn't lint, the gate doesn't pass.

## Phase 0: API Standards Discovery (MANDATORY)

Check if organizational naming standards exist. See [shared-patterns/standards-discovery.md](../shared-patterns/standards-discovery.md) for the complete workflow.

AskUserQuestion: "Do you have a data dictionary or API field naming standards to reference?"
- "No — Use industry best practices"
- "Yes — URL to document"
- "Yes — File path"

**If standards provided:** WebFetch or read the document and extract:
- Field naming convention (camelCase vs snake_case)
- Standard field names across APIs (createdAt, updatedAt, isActive)
- Data type formats (dates, IDs, amounts)
- Validation patterns (email, phone)
- Standard error codes
- Pagination fields

Save to `docs/pre-dev/{feature}/api-standards-ref.md`.

**If no standards:** Use Lerian/industry defaults and record them in api-standards-ref.md:
- Field naming: camelCase
- IDs: UUID v4
- Timestamps: ISO 8601 UTC
- Pagination: `items`, `page`, `limit`, `next_cursor`, `prev_cursor`

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Surface Discovery** | From TRD: identify every API-exposing component; list resources and operations; map auth requirements per surface |
| **2. Spec Authoring** | Write `openapi.yaml`: info, servers, tags, paths with full operations, components (schemas, parameters, responses, securitySchemes); apply naming from api-standards-ref.md |
| **3. Validation** | Lint the spec; run the Gate 4 checklist |

## Spec Requirements

**File:** `docs/pre-dev/{feature}/openapi.yaml` — `openapi: 3.1.0`.

Every operation MUST have:
- `operationId` (unique, lowerCamelCase verb-noun: `createAccount`, `listTransactions`)
- `summary`, `tags`
- Request body schema via `$ref` to `components/schemas` (no inline anonymous objects for domain types)
- All success responses with schemas
- All expected error responses (400/401/403/404/409/422/500 as applicable) referencing the error envelope
- `security` requirement (or explicit `security: []` for public endpoints)

Components MUST define:
- All domain schemas with types, formats, `required` arrays, constraints (`maxLength`, `enum`, `pattern`), and `examples`
- Shared parameters (pagination, path IDs)
- Reusable error responses
- `securitySchemes` matching the feature's auth requirements from the TRD (e.g., OAuth2/OIDC client credentials, bearer JWT, API key). Do NOT invent auth the TRD doesn't require.

List operations MUST use the Lerian pagination envelope: `items` plus `limit` and `page` (offset mode) or `next_cursor`/`prev_cursor` (cursor mode).

## Lerian Error Envelope (MANDATORY)

All error responses reference one shared schema:

```yaml
components:
  schemas:
    Error:
      type: object
      required: [code, title, message]
      properties:
        code:
          type: string
          description: Stable machine-readable error code
          examples: ["ACC-0007"]
        title:
          type: string
          examples: ["Entity Not Found"]
        message:
          type: string
          description: Human-readable explanation with resolution guidance
        fields:
          type: object
          additionalProperties: { type: string }
          description: Per-field validation messages (422 only)
```

Maintain an error catalog as `description` text on the Error schema or a top-level `x-error-catalog` extension: every code, its HTTP status, trigger condition, and resolution.

## Validation (Gate 4)

Lint before declaring the gate passed. Optional but recommended:

```bash
npx @stoplight/spectral-cli lint docs/pre-dev/{feature}/openapi.yaml
# or
npx @redocly/cli lint docs/pre-dev/{feature}/openapi.yaml
```

If neither tool is available, verify the YAML parses and every `$ref` resolves.

| Category | Requirements |
|----------|--------------|
| **Valid spec** | Parses as YAML; `openapi: 3.1.0`; lints clean (spectral/redocly if available); all `$ref`s resolve |
| **Completeness** | Every TRD API-exposing component has paths; every operation has request/response schemas and error responses |
| **Naming Consistency** | Fields follow api-standards-ref.md convention throughout; operationIds consistent; no mixed conventions |
| **Error Handling** | All error responses use the Lerian envelope; catalog covers every code with status and resolution |
| **Auth** | securitySchemes match TRD auth requirements; every operation declares security (or explicit `security: []`) |

**Gate Result:** ✅ PASS → Data Model | ⚠️ CONDITIONAL (naming/lint warnings to fix) | ❌ FAIL (invalid spec or missing operations)

## Topology-Aware Output

| Structure | Files Generated |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/openapi.yaml` |
| monorepo | Root `docs/pre-dev/{feature}/openapi.yaml` |
| multi-repo | Both: `{backend.path}/docs/pre-dev/{feature}/openapi.yaml` + frontend copy |

## Related

- ring:writing-trds — produces the TRD this spec is derived from
- ring:designing-data-model — consumes the spec's schemas to derive the physical schema
