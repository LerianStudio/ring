---
name: writing-api-docs
description: |
  Patterns and structure for writing API reference documentation including
  endpoint descriptions, request/response schemas, and error documentation.

trigger: |
  - Documenting REST API endpoints
  - Writing request/response examples
  - Documenting error codes
  - Creating API field descriptions

skip_when: |
  - Writing conceptual guides → use writing-functional-docs
  - Reviewing documentation → use documentation-review
  - Writing code → use dev-team agents

sequence:
  before: [documentation-review]

related:
  similar: [writing-functional-docs]
  complementary: [api-field-descriptions, documentation-structure]
---

# Writing API Reference Documentation

API reference documentation describes what each endpoint does, its parameters, request/response formats, and error conditions. It focuses on the "what" rather than the "why."

## API Reference Principles

- **RESTful and Predictable:** Standard HTTP methods, consistent URL patterns, document idempotency
- **Consistent Formats:** JSON requests/responses, clear typing, standard error format
- **Explicit Versioning:** Version in URL path, backward compatibility notes, deprecated fields marked

---

## Endpoint Documentation Structure

| Section | Content |
|---------|---------|
| **Title** | Endpoint name |
| **Description** | Brief description of what the endpoint does |
| **HTTP Method + Path** | `POST /v1/organizations/{orgId}/ledgers/{ledgerId}/accounts` |
| **Path Parameters** | Table: Parameter, Type, Required, Description |
| **Query Parameters** | Table: Parameter, Type, Default, Description |
| **Request Body** | JSON example + fields table |
| **Success Response** | Status code + JSON example + fields table |
| **Errors** | Table: Status Code, Error Code, Description |

---

## Field Description Patterns

| Type | Pattern |
|------|---------|
| Basic | `name: string — The name of the Account` |
| With constraints | `code: string — The asset code (max 10 chars, uppercase)` |
| With example | `email: string — Email address (e.g., "user@example.com")` |
| Deprecated | `chartOfAccountsGroupName: string — **[Deprecated]** Use \`route\` instead` |

---

## Data Types Reference

| Type | Description | Example |
|------|-------------|---------|
| `uuid` | UUID v4 identifier | `3172933b-50d2-4b17-96aa-9b378d6a6eac` |
| `string` | Text value | `"Customer Account"` |
| `integer` | Whole number | `42` |
| `boolean` | True/false | `true` |
| `timestamptz` | ISO 8601 (UTC) | `2024-01-15T10:30:00Z` |
| `jsonb` | JSON object | `{"key": "value"}` |
| `array` | List of values | `["item1", "item2"]` |
| `enum` | Predefined values | `currency`, `crypto` |

---

## Request/Response Examples

**Rules:**
- Show realistic, working examples (not "foo", "bar")
- Show all fields that would be returned
- Use actual UUIDs, timestamps, realistic data

---

## Error Documentation

**Standard error format:**
```json
{
  "code": "ACCOUNT_NOT_FOUND",
  "message": "The specified account does not exist",
  "details": { "accountId": "invalid-uuid" }
}
```

**Error table:**

| Status | Code | Description | Resolution |
|--------|------|-------------|------------|
| 400 | INVALID_REQUEST | Validation failed | Check request format |
| 401 | UNAUTHORIZED | Missing/invalid auth | Provide valid API key |
| 403 | FORBIDDEN | Insufficient permissions | Contact admin |
| 404 | NOT_FOUND | Resource doesn't exist | Verify resource ID |
| 409 | CONFLICT | Resource already exists | Use different identifier |
| 422 | UNPROCESSABLE_ENTITY | Business rule violation | Check constraints |
| 429 | TOO_MANY_REQUESTS | Rate limit exceeded | Retry after delay |
| 500 | INTERNAL_ERROR | Server error | Retry or contact support |

---

## HTTP Status Codes

**Success:** 200 (GET/PUT/PATCH), 201 (POST creates), 204 (DELETE)

**Client errors:** 400 (malformed), 401 (no auth), 403 (no permission), 404 (not found), 409 (conflict), 422 (invalid semantics), 429 (rate limit)

**Server errors:** 500 (internal)

---

## Pagination Documentation

For paginated endpoints, document query parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| limit | integer | 10 | Results per page (max 100) |
| page | integer | 1 | Page number |

Response includes: `items`, `page`, `limit`, `totalItems`, `totalPages`

---

## Versioning Notes

> **Note:** You're viewing documentation for the **current version** (v3).

For deprecated: `> **Deprecated:** This endpoint will be removed in v4. Use [/v3/accounts](link) instead.`

---

## Quality Checklist

- [ ] HTTP method and path correct
- [ ] All path parameters documented
- [ ] All query parameters documented
- [ ] All request body fields documented with types
- [ ] All response fields documented with types
- [ ] Required vs optional clear
- [ ] Realistic request/response examples included
- [ ] All error codes documented
- [ ] Deprecated fields marked
- [ ] Links to related endpoints included
