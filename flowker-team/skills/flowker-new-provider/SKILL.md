---
name: ring:flowker-new-provider
description: |
  Scaffolds a new Core four provider (HTTP-based external service integration) with
  executors, JSON Schema validation, auth wiring, and unit tests. Use when adding
  integrations like KYC, AML, payment gateways, or custom REST APIs to Core four.

trigger: |
  - User wants to add a new provider to Core four (e.g., "add provider", "integrate API X", "novo provider")
  - Task requires creating a new entry in Core four's `pkg/executors/` catalog
  - Working directory is the Core four repo (github.com/LerianStudio/flowker)

skip_when: |
  - Adding a new executor to an existing provider → modify the existing `pkg/executors/<name>/` directory directly
  - Adding a new template (pre-built workflow blueprint) → use `ring:flowker-new-template` instead
  - Adding a new trigger type (scheduled, Kafka, gRPC) → requires architectural refactor first, not templatable
  - Not inside the Core four repository

NOT_skip_when: |
  - "It's just one HTTP call, I can do it manually" → Manual work misses `register.go` patch, tests, schema validation. Use the skill.
  - "The existing HTTP provider is enough" → The generic `http` provider is not exposed publicly; each external service needs its own catalog entry.
  - "I'll add the schema later" → Provider without schema fails `base.NewProvider()` at startup. Schema is mandatory.

sequence:
  before: [ring:dev-unit-testing, ring:codereview]

related:
  similar: [ring:flowker-new-template]
  complementary: [ring:backend-engineer-golang, ring:dev-unit-testing, ring:codereview]

input_schema:
  required:
    - name: provider_id
      type: string
      description: "Provider identifier in kebab-case (e.g., 'stripe', 'kyc-vendor'). Becomes `executor.ProviderID`."
    - name: provider_name
      type: string
      description: "Human-readable name (e.g., 'Stripe Payments')."
    - name: description
      type: string
      description: "Short description of what this provider integrates with."
    - name: base_url_pattern
      type: string
      description: "How base URL(s) are structured (single URL? multi-region? env-specific?)."
    - name: auth_type
      type: string
      enum: [none, api_key, bearer, basic, oidc_client_credentials, oidc_user]
      description: "Auth mechanism supported by `pkg/executors/http/auth/factory.go`."
    - name: operations
      type: array
      description: "List of operations. Each: { id (kebab-case), name, http_method, path_template, description }."
  optional:
    - name: custom_input_builder
      type: boolean
      default: false
      description: "Set true when URL routing or auth translation cannot be handled by default HTTP runner (Core one-style)."

output_schema:
  format: markdown
  required_sections:
    - name: "Provider Summary"
      pattern: "^## Provider Summary"
      required: true
    - name: "Files Created"
      pattern: "^## Files Created"
      required: true
    - name: "Verification Report"
      pattern: "^## Verification Report"
      required: true
    - name: "Handoff"
      pattern: "^## Handoff"
      required: true
  metrics:
    - name: result
      type: enum
      values: [PASS, FAIL]
    - name: operations_created
      type: integer
    - name: test_coverage
      type: float
    - name: input_builder
      type: enum
      values: [default, custom, N/A]

verification:
  automated:
    - command: "go build ./..."
      description: "Code compiles"
    - command: "go test ./pkg/executors/<provider_id>/... -cover"
      description: "Unit tests pass with coverage"
      success_pattern: 'coverage:.*[8-9][0-9].[0-9]%|100'
    - command: "go test ./pkg/executors/ -run TestRegisterDefaults"
      description: "Provider registers in catalog"
    - command: "make lint"
      description: "Lint passes"
  manual:
    - "curl http://localhost:8080/v1/catalog/providers returns new provider"
    - "Provider config schema validates example payload"

---

# Core four New Provider

## Overview

Creates a new **static-catalog provider** in Core four with N executors, JSON Schema validation, auth wiring, and unit tests. Providers are stateless — they live in `pkg/executors/<name>/` and get registered in `pkg/executors/register.go` at bootstrap.

**Core principle:** Each external HTTP service (KYC vendor, payment gateway, custom API) is one provider. Each operation on that service (`create_charge`, `refund`, etc.) is one executor.

<block_condition>
- Missing required input (provider_id, operations list, auth_type) = FAIL
- Generated code does not compile = FAIL
- Unit test coverage < 85% = FAIL
- Provider does not appear in `GET /v1/catalog/providers` = FAIL
</block_condition>

## Prerequisites

- Go 1.25.5 (Core four's language version)
- Working directory = Core four repo root
- Provider's external API docs (endpoints, auth, request/response shapes)
- Decision made: does this provider need a custom `InputBuilder`? (default: no — only needed for Core one-style per-operation URL routing or nested auth translation)

## Key Interfaces (file:line refs)

The scaffolded code MUST satisfy these interfaces. Reference before generation:

| Interface | Location | Purpose |
|-----------|----------|---------|
| `executor.Provider` | `pkg/executor/provider.go:13-29` | ID, Name, Description, Version, ConfigSchema |
| `executor.Executor` | `pkg/executor/executor.go:15-36` | ID, Name, Category, Version, ProviderID, Schema, ValidateConfig |
| `executor.Runner` | `pkg/executor/runner.go:11-18` | Execute(ctx, input) — reused from `pkg/executors/http/runner.go` |
| `executor.InputBuilder` | `pkg/executor/input_builder.go:11-12` | OPTIONAL — only for custom URL/auth routing |
| `base.NewProvider` | `pkg/executor/base/provider.go:18-78` | Factory that validates schema |
| `base.NewExecutor` | `pkg/executor/base/base.go:20-83` | Factory with JSON Schema compilation |

**Existing reference providers** (read before scaffolding):
- Simple HTTP + API key auth: `pkg/executors/tracer/` (best template for new providers)
- Complex OIDC + custom routing: `pkg/executors/midaz/` (template when `custom_input_builder: true`)

## Gate 0 — Interview

Gather ALL inputs before generating any file. If any required input is missing, STOP and ask.

<cannot_skip>
Must collect for EVERY operation: id, name, http_method, path_template, short description.
Must decide: auth_type. Must decide: custom_input_builder (true only if Core one-like routing needed).
</cannot_skip>

Ask the user (or load from input_schema):

```text
Provider identity:
  - provider_id (kebab-case, no dots): ____
  - provider_name (human-readable): ____
  - description: ____

Base URL strategy:
  - single base URL OR multi-endpoint (e.g., Core one has onboarding_base_url + transaction_base_url)?

Authentication (choose ONE):
  - none / api_key / bearer / basic / oidc_client_credentials / oidc_user

Operations (REPEAT for each):
  - operation_id (kebab-case, e.g., "create-charge"): ____
  - operation_name: ____
  - http_method (GET/POST/PUT/PATCH/DELETE): ____
  - path_template (e.g., "/v1/charges", "/v1/accounts/{account_id}"): ____
  - request body shape (inline JSON Schema properties): ____

Custom InputBuilder needed?
  - false (default) → HTTP runner handles routing using ExecutionInput.URL/Method
  - true → ONLY when URL must change per-operation via template + provider config (Core one pattern)
```

If user cannot answer, dispatch `ring:interviewing-user` to run a structured interview.

## Gate 1 — Scaffold (Deterministic)

Create the directory and files below. All placeholders in `{{...}}` come from Gate 0 input.

### File 1: `pkg/executors/{{provider_id}}/provider.go`

```go
package {{provider_id_no_hyphens}}

import (
	"fmt"

	"github.com/LerianStudio/flowker/pkg/executor"
	"github.com/LerianStudio/flowker/pkg/executor/base"
	"github.com/LerianStudio/flowker/pkg/executors/http"
)

const (
	// ProviderID is the catalog identifier for {{provider_name}}.
	ProviderID executor.ProviderID = "{{provider_id}}"

	// Name is the human-readable provider name.
	Name = "{{provider_name}}"

	// Description summarizes what this provider integrates with.
	Description = "{{description}}"

	// Version is the provider version. Bump on breaking schema changes.
	Version = "v1"
)

// providerConfigSchema validates user-supplied provider configuration.
// Filled in Gate 2 with real JSON Schema.
const providerConfigSchema = `{{providerConfigSchema_placeholder}}`

// Register wires the provider and its executors into the given catalog.
func Register(catalog executor.Catalog) error {
	provider, err := base.NewProvider(ProviderID, Name, Description, Version, providerConfigSchema)
	if err != nil {
		return fmt.Errorf("failed to register %s provider: %w", Name, err)
	}

	registrations := []executor.ExecutorRegistration{}
	{{#each operations}}
	{{operation_name}}Exec, err := new{{OperationNameCamel}}Executor()
	if err != nil {
		return fmt.Errorf("failed to create %s %s executor: %w", Name, "{{operation_id}}", err)
	}
	registrations = append(registrations, executor.ExecutorRegistration{
		Executor: {{operation_name}}Exec,
		Runner:   http.NewRunner({{operation_name}}Exec.ID(), nil),
	})
	{{/each}}

	return catalog.RegisterProvider(provider, registrations)
}
```

### File 2 (per operation): `pkg/executors/{{provider_id}}/{{operation_id_snake}}.go`

```go
package {{provider_id_no_hyphens}}

import (
	"fmt"

	"github.com/LerianStudio/flowker/pkg/executor"
	"github.com/LerianStudio/flowker/pkg/executor/base"
)

const (
	// {{OperationNameCamel}}ID is the catalog ID for the {{operation_name}} operation.
	{{OperationNameCamel}}ID executor.ID = "{{provider_id}}.{{operation_id}}"
)

// {{operation_id_lower}}Schema defines the JSON Schema for {{operation_name}} input.
// Filled in Gate 2.
const {{operation_id_lower}}Schema = `{{operationSchema_placeholder}}`

func new{{OperationNameCamel}}Executor() (*base.Executor, error) {
	exec, err := base.NewExecutor(
		{{OperationNameCamel}}ID,
		"{{operation_name}}",
		"{{category}}",
		Version,
		ProviderID,
		{{operation_id_lower}}Schema,
	)
	if err != nil {
		return nil, fmt.Errorf("new %s executor: %w", "{{operation_id}}", err)
	}
	return exec, nil
}
```

### File 3: `pkg/executors/{{provider_id}}/{{provider_id_no_hyphens}}_test.go`

```go
package {{provider_id_no_hyphens}}_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"

	executorpkg "github.com/LerianStudio/flowker/pkg/executor"
	{{provider_id_no_hyphens}} "github.com/LerianStudio/flowker/pkg/executors/{{provider_id}}"
)

func TestRegister_Success(t *testing.T) {
	catalog := executorpkg.NewCatalog()

	err := {{provider_id_no_hyphens}}.Register(catalog)
	require.NoError(t, err)

	provider, ok := catalog.GetProvider({{provider_id_no_hyphens}}.ProviderID)
	require.True(t, ok)
	require.Equal(t, {{provider_id_no_hyphens}}.Name, provider.Name())
}

{{#each operations}}
func Test{{OperationNameCamel}}_Success(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "{{http_method}}", r.Method)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
	}))
	defer server.Close()

	catalog := executorpkg.NewCatalog()
	require.NoError(t, {{provider_id_no_hyphens}}.Register(catalog))

	runner, ok := catalog.GetRunner({{provider_id_no_hyphens}}.{{OperationNameCamel}}ID)
	require.True(t, ok)

	input := executorpkg.ExecutionInput{
		Method:  "{{http_method}}",
		URL:     server.URL + "{{path_template_resolved}}",
		Headers: map[string]string{"Content-Type": "application/json"},
	}

	result, err := runner.Execute(context.Background(), input)
	require.NoError(t, err)
	require.Equal(t, executorpkg.ExecutionStatusSuccess, result.Status)
}
{{/each}}
```

### File 4 (patch): `pkg/executors/register.go`

Add the import and call. Example diff:

```diff
 import (
     "github.com/LerianStudio/flowker/pkg/executor"
+    "github.com/LerianStudio/flowker/pkg/executors/{{provider_id}}"
     "github.com/LerianStudio/flowker/pkg/executors/midaz"
     "github.com/LerianStudio/flowker/pkg/executors/tracer"
 )

 func RegisterDefaults(catalog executor.Catalog) error {
     if err := midaz.Register(catalog); err != nil {
         return err
     }
     if err := tracer.Register(catalog); err != nil {
         return err
     }
+    if err := {{provider_id_no_hyphens}}.Register(catalog); err != nil {
+        return err
+    }
     return nil
 }
```

### File 5 (patch): `pkg/executors/register_test.go`

Add an assertion that the new provider appears after `RegisterDefaults`:

```go
func Test{{ProviderNameCamel}}ProviderRegistered(t *testing.T) {
    catalog := executor.NewCatalog()
    require.NoError(t, RegisterDefaults(catalog))

    _, ok := catalog.GetProvider({{provider_id_no_hyphens}}.ProviderID)
    require.True(t, ok, "{{provider_id}} provider must be registered")
}
```

## Gate 2 — Schema Design (Judgment)

Dispatch `ring:backend-engineer-golang` to fill `providerConfigSchema` and per-operation schemas.

<dispatch_required agent="ring:backend-engineer-golang">
Fill JSON Schema Draft 2020-12 content. Schemas must compile via jsonschema library.
</dispatch_required>

Prompt template:

```yaml
Task:
  subagent_type: "ring:backend-engineer-golang"
  description: "Fill JSON schemas for {{provider_id}} provider"
  prompt: |
    Fill the JSON Schema Draft 2020-12 strings in these files:
    - pkg/executors/{{provider_id}}/provider.go → providerConfigSchema
    - pkg/executors/{{provider_id}}/<op>.go → <op>Schema (one per operation)

    ## Provider Config Schema Requirements
    - Auth type: {{auth_type}}
    - Auth fields required (reference pkg/executors/http/auth/factory.go:14-75 for accepted shapes):
      - api_key: flat `api_key` string
      - bearer: flat `token` string
      - basic: `username` + `password`
      - oidc_client_credentials: nested `auth` block with issuer_url/client_id/client_secret/scopes
    - Base URL fields (based on base_url_pattern): single `base_url` OR multiple *_base_url
    - All URL fields: "type": "string", "format": "uri"

    ## Operation Schema Requirements (for each operation)
    - Properties matching the operation's request body shape
    - Required fields marked in "required" array
    - Use "type", "format", "enum", "minLength", "pattern" as appropriate
    - Do not use draft-04 syntax ($ref to external files) — keep inline

    ## Output
    - Modified .go files with filled schema constants
    - Validation: `go build ./pkg/executors/{{provider_id}}/...` must pass
    - Validation: provider must instantiate via `base.NewProvider` without error
```

## Gate 3 — Auth & InputBuilder Decision

### Decision tree

```text
IF custom_input_builder == false:
  → Skip this gate. HTTP runner handles routing via ExecutionInput.URL + Method
  → Auth is handled by pkg/executors/http/auth/factory.go via provider config

IF custom_input_builder == true:
  → Create pkg/executors/{{provider_id}}/input_builder.go
  → Dispatch ring:backend-engineer-golang to implement:
      - type {{provider_id}}Provider struct wrapping base.Provider + InputBuilder
      - executorRoutes map: executor.ID → {method, path_template}
      - resolvePathParams() extracting from provider config / nodeData / requestBody
      - buildAuth() translating provider-specific auth → http/auth factory format
  → Reference pkg/executors/midaz/input_builder.go:1-126 as canonical example
```

### When is `custom_input_builder` required?

| Condition | Custom InputBuilder? |
|-----------|---------------------|
| All operations use same base URL, only path differs | NO |
| Method + URL known at executor definition time | NO |
| Auth fits `http/auth/factory` types directly | NO |
| Path contains `{variables}` resolved from provider config | **YES** |
| Multiple base URLs per provider (e.g., onboarding vs transaction) | **YES** |
| Auth has nested config block requiring translation | **YES** |

## Gate 4 — Unit Tests

Dispatch `ring:dev-unit-testing` with coverage threshold 85%.

<dispatch_required skill="ring:dev-unit-testing">
Run the full Gate 3 dev-cycle skill against the new provider package.
</dispatch_required>

Provide this input to `ring:dev-unit-testing`:

```yaml
unit_id: "{{provider_id}}-provider"
language: "go"
coverage_threshold: 85.0
implementation_files:
  - "pkg/executors/{{provider_id}}/provider.go"
  - "pkg/executors/{{provider_id}}/<op>.go (per operation)"
  - "pkg/executors/{{provider_id}}/input_builder.go (if custom)"
acceptance_criteria:
  - "Provider registers successfully via Register(catalog)"
  - "Provider appears in catalog.GetProvider({{ProviderID}})"
  - "Each executor appears in catalog.GetExecutor(<id>)"
  - "Each runner is bound via catalog.GetRunner(<id>)"
  - "providerConfigSchema validates a minimal valid config"
  - "providerConfigSchema rejects config missing required fields"
  - "Each operation schema validates a minimal valid input"
  - "Each operation, invoked with httptest.NewServer, returns ExecutionStatusSuccess on 2xx"
  - "Each operation returns ExecutionStatusFailure on 4xx/5xx"
```

## Gate 5 — Review

Dispatch `ring:codereview` (parallel 6-reviewer pipeline).

<dispatch_required skill="ring:codereview">
Run the standard parallel review pipeline on all files created/modified.
</dispatch_required>

Reviewers that must PASS: code, business-logic, security, test, nil-safety, consequences.

Security reviewer MUST verify:
- No credentials logged or echoed in errors
- Auth config not exposed in ExecutionResult.Data
- Path params sanitized against injection (`..`, `/`, query-string smuggling)

## Verification Commands (run from flowker repo root)

```bash
# 1. Code compiles
go build ./...

# 2. Unit tests pass with coverage
go test ./pkg/executors/{{provider_id}}/... -cover -covermode=atomic

# 3. Provider registers without error
go test ./pkg/executors/ -run TestRegisterDefaults -v

# 4. Lint clean
make lint

# 5. Runtime verification (requires local server)
make up
curl -s http://localhost:8080/v1/catalog/providers | jq '.[].id' | grep {{provider_id}}
curl -s http://localhost:8080/v1/catalog/providers/{{provider_id}}/executors | jq '.[].id'
```

All commands must succeed. Paste actual output into the Verification Report section.

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| Adding env vars for provider config | Provider config is runtime data in `provider_configurations` collection, not static env | Define schema for runtime config; don't touch `.env.example` |
| Creating MongoDB models or repositories | Providers are stateless catalog entries | Just register in `pkg/executors/<name>/provider.go` |
| Modifying `internal/bootstrap/config.go` | `RegisterDefaults()` already runs at bootstrap, no new wiring | Only edit `pkg/executors/register.go` |
| Adding Swagger annotations per provider | `GET /v1/catalog/providers` is a generic handler, reflects registered schema | No handler code needed |
| Custom `InputBuilder` when default works | Core one-style complexity without Core one-style need = boilerplate tax | Default path: just set URL+Method in ExecutionInput; custom only when URLs vary per op |
| Hardcoding credentials in schema examples | Examples get copy-pasted into prod configs | Use clearly fake placeholder values (`"api_key": "PLACEHOLDER_REPLACE_ME"`) |
| Skipping `httptest.NewServer` for "we'll integration test" | Unit tests verify request shape cheaply; integration tests are separate | Test each operation with httptest mock |

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Just copy-paste tracer and rename" | "Copying without adapting schema and auth invites subtle bugs. Run Gates 1-4." |
| "Skip tests, the external API is mocked in staging" | "Gate 4 unit tests verify code correctness, independent of staging. Write them." |
| "I'll add the InputBuilder if we hit a problem later" | "InputBuilder decision is Gate 3 — based on objective criteria (per-op URLs, nested auth). Decide now, don't defer." |
| "The schema is obvious, skip Gate 2" | "Missing `required` array or wrong types break runtime validation. Fill schema explicitly." |
| "Why 85% coverage? It's boilerplate" | "Schema validation and auth edge cases are where bugs hide. 85% is the Ring floor." |

## Example: Walkthrough — fictional `ExampleKYC` provider

**Input (Gate 0):**
- `provider_id`: `example-kyc`
- `provider_name`: `Example KYC`
- `description`: `Identity verification via Example KYC vendor`
- `auth_type`: `api_key`
- `operations`:
  - `{id: "verify-identity", name: "Verify Identity", method: "POST", path: "/v1/verify"}`
  - `{id: "get-result", name: "Get Result", method: "GET", path: "/v1/verifications/{verification_id}"}`
- `custom_input_builder`: `true` (because `get-result` has path variable)

**Output after Gate 1:**
```
pkg/executors/example-kyc/
├── provider.go            (Register() + providerConfigSchema placeholder)
├── verify_identity.go     (VerifyIdentityID + schema placeholder)
├── get_result.go          (GetResultID + schema placeholder)
├── input_builder.go       (route map + resolvePathParams)
└── example_kyc_test.go    (3 tests: Register, VerifyIdentity, GetResult)
pkg/executors/register.go  (+3 lines)
pkg/executors/register_test.go (+1 test)
```

**After Gate 2 (schema filled):**
- `providerConfigSchema` requires `{base_url, api_key}`
- `verifyIdentitySchema` requires `{full_name, document_number, document_type}`
- `getResultSchema` requires `{verification_id}`

**After Gate 4:**
- Coverage: 92%
- All 3 tests pass

**After Gate 5:**
- Security reviewer: PASS (no api_key leak in errors)
- Test reviewer: PASS (httptest covers 2xx + 4xx paths)

## Handoff to Next Gate

Emit this structured output when complete:

```markdown
## Provider Summary
**Status:** PASS / FAIL
**Provider ID:** {{provider_id}}
**Operations:** {{count}}
**InputBuilder:** default | custom
**Test Coverage:** {{percent}}%

## Files Created
| Path | Purpose | Lines |
|------|---------|-------|
| pkg/executors/{{provider_id}}/provider.go | Register + schema | N |
| pkg/executors/{{provider_id}}/<op>.go × {{count}} | Executor per operation | N |
| pkg/executors/{{provider_id}}/input_builder.go | Custom routing (if applicable) | N |
| pkg/executors/{{provider_id}}/{{provider_id_no_hyphens}}_test.go | Unit tests | N |

## Files Modified
| Path | Change |
|------|--------|
| pkg/executors/register.go | +import +Register call |
| pkg/executors/register_test.go | +registration test |

## Verification Report
```
[paste `go test -cover` output]
[paste `make lint` output]
[paste `curl /v1/catalog/providers/{{provider_id}}` output]
```

## Handoff
- Provider appears in catalog: YES
- Ready for integration testing: YES
- Next step: create provider config via `POST /v1/provider-configurations` with real credentials
```
