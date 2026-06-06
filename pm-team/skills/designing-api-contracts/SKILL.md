---
name: ring:pre-dev-api-design
description: |
  Gate 4: API contracts document - defines component interfaces and data contracts
  before protocol/technology selection. Large Track only.
---

# API/Contract Design — Defining Component Interfaces

## When to use

- TRD passed Gate 3 validation
- System has multiple components that need to integrate
- Building APIs (internal or external)
- Large Track workflow (2+ day features)

## Skip when

- Small Track workflow → skip to Task Breakdown
- Single component system → skip to Data Model
- TRD not validated → complete Gate 3 first

## Sequence

**Runs before:** ring:pre-dev-data-model
**Runs after:** ring:pre-dev-trd-creation


Defines WHAT data and operations components expose and consume, before protocol or technology selection. Contracts enable parallel team work and prevent integration failures discovered during development.

## Phase 0: API Standards Discovery (MANDATORY)

Check if organizational naming standards exist.

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

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **1. Contract Discovery** | From TRD: identify all component interfaces; list operations each component exposes; define data contracts per operation |
| **2. Contract Definition** | Per operation: request schema, response schema, error conditions, versioning; apply API standards if loaded |
| **3. Gate 4 Validation** | All component interfaces defined; contracts complete; naming consistent with standards; error handling specified; versioning strategy documented |

## Contract Rules

### Include
- Operation names and descriptions
- Request schema (fields, types, required/optional, validation)
- Response schema (fields, types, nullable)
- Error catalog (code, HTTP status, condition, resolution)
- Versioning strategy (backward compatibility, deprecation)
- Pagination specification (if list operations)

### Never Include
- Protocol selection (REST vs gRPC → TRD)
- Implementation libraries (which HTTP framework)
- Infrastructure choices (caching layer, CDN)
- Code structure (packages, files)

## API Standards Application

**If api-standards-ref.md loaded:**

Use extracted naming for all field definitions. Document in output: "Fields follow [source] convention."

**If no standards:** Use industry defaults:
- Field naming: camelCase
- IDs: UUID v4
- Timestamps: ISO 8601 UTC
- Pagination: `page`, `limit`, `totalItems`, `nextCursor`
- Errors: `{ "code": "ERROR_CODE", "message": "...", "details": {} }`

## Output Format

**File:** `docs/pre-dev/{feature}/api-design.md`

Required sections:
1. **Standards Reference** — Source used (or "industry defaults")
2. **Component Interface Map** — Table of components + operations
3. **Operation Contracts** — Per operation: request/response schema, errors
4. **Shared Schemas** — Reusable data types
5. **Error Catalog** — All error codes used across operations
6. **Versioning Strategy** — Breaking vs non-breaking changes, deprecation policy

## Topology-Aware Output

| Structure | Files Generated |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/api-design.md` |
| monorepo | Root `docs/pre-dev/{feature}/api-design.md` |
| multi-repo | Both: `{backend.path}/docs/pre-dev/{feature}/api-design.md` + frontend copy |

## Gate 4 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Completeness** | All TRD components have interfaces; all operations defined; request/response complete |
| **Naming Consistency** | Fields follow declared naming convention throughout; no mixed conventions |
| **Error Handling** | All error conditions documented; HTTP status codes correct; resolution guidance present |
| **Versioning** | Version strategy documented; backward compatibility rules clear |
| **No Implementation** | Zero protocol specifics; zero framework names; zero infrastructure names |

**Gate Result:** ✅ PASS → Data Model | ⚠️ CONDITIONAL (fix naming/missing fields) | ❌ FAIL (incomplete contracts)
