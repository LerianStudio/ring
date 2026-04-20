---
name: ring:flowker-new-template
description: |
  Scaffolds a new Core four workflow template — a pre-built workflow blueprint with
  parameter validation and a Build function that emits `*model.CreateWorkflowInput`.
  Use when codifying a recurring workflow pattern (e.g., KYC-AML check, payment-settlement).

trigger: |
  - User wants to add a new workflow template (e.g., "novo template", "workflow blueprint", "recurring workflow pattern")
  - Task requires a new entry in Core four's `pkg/templates/` catalog
  - Multiple users should be able to instantiate the same workflow shape with different parameters

skip_when: |
  - Adding a new provider (external service integration) → use `ring:flowker-new-provider`
  - Adding a one-off workflow for a single user → just POST to `/v1/workflows`, no template needed
  - Not inside the Core four repository

NOT_skip_when: |
  - "The workflow is too simple for a template" → Templates exist exactly to remove boilerplate for common shapes. Use it.
  - "I'll write a script that generates the workflow JSON" → Templates are the built-in mechanism with schema validation. Use it.
  - "I don't need parameter validation" → JSON Schema validation prevents broken workflows at creation time, not runtime. Do it.

sequence:
  before: [ring:codereview]

related:
  similar: [ring:flowker-new-provider]
  complementary: [ring:backend-engineer-golang, ring:codereview]

input_schema:
  required:
    - name: template_id
      type: string
      description: "Template identifier in kebab-case (e.g., 'kyc-aml-check'). Becomes `executor.TemplateID`."
    - name: template_name
      type: string
      description: "Human-readable name."
    - name: description
      type: string
      description: "Describes what workflow this template produces."
    - name: category
      type: string
      description: "Grouping label (e.g., 'compliance', 'payments')."
    - name: params
      type: array
      description: "Template parameters. Each: { name, type, required (bool), provider_config (nullable — if set, value must reference a provider config of that ProviderID) }."
    - name: nodes
      type: array
      description: "Ordered workflow nodes. Each: { id, type (trigger|executor|conditional), reference (TriggerID or ExecutorID), data_mapping (param references) }."
    - name: edges
      type: array
      description: "Workflow edges. Each: { source_node_id, target_node_id, condition (optional) }."

output_schema:
  format: markdown
  required_sections:
    - name: "Template Summary"
      pattern: "^## Template Summary"
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
    - name: nodes_count
      type: integer
    - name: edges_count
      type: integer
    - name: test_coverage
      type: float

verification:
  automated:
    - command: "go build ./..."
      description: "Code compiles"
    - command: "go test ./pkg/templates/<template_id>/... -cover"
      description: "Unit tests pass with coverage"
      success_pattern: 'coverage:.*[8-9][0-9].[0-9]%|100'
    - command: "go test ./pkg/templates/ -run TestRegisterDefaults"
      description: "Template registers in catalog"
    - command: "make lint"
      description: "Lint passes"
  manual:
    - "curl http://localhost:8080/v1/catalog/templates returns new template"
    - "curl -X POST /v1/workflows/from-template creates a valid workflow"

---

# Core four New Template

## Overview

Creates a new **workflow template** in Core four — a reusable blueprint that accepts parameters and emits a complete `*model.CreateWorkflowInput`. Templates live in `pkg/templates/<name>/` and get registered in `pkg/templates/register.go` at bootstrap.

**Core principle:** Templates remove boilerplate for workflows users repeatedly construct (same nodes, same edges, different parameter values — like provider config IDs or workflow names).

<block_condition>
- Missing required input (template_id, nodes, edges, params) = FAIL
- `build()` references an executor ID not present in the catalog = FAIL
- Edge references a node_id that does not exist in nodes = FAIL
- Unit test coverage < 85% = FAIL
- Template does not appear in `GET /v1/catalog/templates` = FAIL
</block_condition>

## Prerequisites

- Go 1.25.5
- Working directory = Core four repo root
- All executor IDs referenced in template nodes MUST already exist in the catalog (verify via `GET /v1/catalog/providers/<provider_id>/executors`)
- All trigger IDs referenced MUST exist (currently only `webhook`)

## Key Interfaces (file:line refs)

| Interface / Type | Location | Purpose |
|------------------|----------|---------|
| `executor.Template` | `pkg/executor/template.go:23-52` | ID, Name, Description, Category, ParamSchema, ValidateParams, Build, ProviderConfigFields |
| `base.NewTemplate` | `pkg/executor/base/template.go` | Factory with JSON Schema validation |
| `executor.ProviderConfigField` | `pkg/executor/template.go` | Param→ProviderID binding for dynamic enrichment |
| `model.CreateWorkflowInput` | `pkg/model/workflow.go` | Output shape that `build()` returns |
| Consumer service | `internal/services/command/create_workflow_from_template.go` | What calls `Build()` at runtime |

**Existing reference template** (read before scaffolding):
- `pkg/templates/tracer_midaz/template.go` — canonical 4-node template (webhook → tracer validate → decision → midaz create-transaction)
- `pkg/templates/tracer_midaz/template_test.go` — test patterns to replicate

## Gate 0 — Interview

Gather ALL inputs before generating any file. STOP if missing.

<cannot_skip>
Must collect: template_id, nodes (with types and references), edges (with source/target), params (with types and optional provider_config binding).
Every executor ID and trigger ID in nodes MUST be verified to exist in the catalog.
</cannot_skip>

Ask the user:

```text
Template identity:
  - template_id (kebab-case): ____
  - template_name: ____
  - description: ____
  - category: ____

Parameters:
  REPEAT for each param:
    - param_name: ____
    - param_type: string | uuid | integer | boolean
    - required: true | false
    - provider_config_binding:
        - NONE (regular param)
        - provider_id (e.g., "midaz") → this param holds a provider_configuration UUID of that provider

Workflow structure:
  Nodes (ordered):
    REPEAT for each node:
      - node_id (unique within template): ____
      - type: trigger | executor | conditional
      - reference:
          - trigger type: "webhook" (only option currently)
          - executor type: ExecutorID (e.g., "tracer.validate-transaction") — VERIFY EXISTS
          - conditional: N/A
      - data_mapping:
          - which template params feed into this node's data?

  Edges:
    REPEAT for each edge:
      - source_node_id: ____
      - target_node_id: ____
      - condition (for edges out of conditional nodes): "true" | "false" | label | null
```

Before proceeding to Gate 1: VERIFY every executor ID in nodes exists:

```bash
for exec_id in <referenced_executor_ids>; do
  curl -s http://localhost:8080/v1/catalog/providers/<provider>/executors | jq ".[] | select(.id == \"$exec_id\")"
done
```

If any executor ID does not exist, STOP and ask the user to create the provider first (`ring:flowker-new-provider`).

## Gate 1 — Scaffold (Deterministic)

### File 1: `pkg/templates/{{template_id_snake}}/template.go`

```go
package {{template_id_snake}}

import (
	"fmt"

	"github.com/google/uuid"

	"github.com/LerianStudio/flowker/pkg/executor"
	"github.com/LerianStudio/flowker/pkg/executor/base"
	"github.com/LerianStudio/flowker/pkg/model"
)

const (
	// TemplateID is the catalog identifier for {{template_name}}.
	TemplateID executor.TemplateID = "{{template_id}}"

	// Name is the human-readable template name.
	Name = "{{template_name}}"

	// Description summarizes the workflow this template produces.
	Description = "{{description}}"

	// Category groups related templates.
	Category = "{{category}}"

	// Version is the template version. Bump on breaking param schema changes.
	Version = "v1"
)

// paramSchema validates user-supplied template parameters.
// Filled in Gate 2.
const paramSchema = `{{paramSchema_placeholder}}`

// Register wires the template into the given catalog.
func Register(catalog executor.Catalog) error {
	tmpl, err := base.NewTemplate(
		TemplateID,
		Name,
		Description,
		Version,
		Category,
		paramSchema,
		build,
		providerConfigFields(),
	)
	if err != nil {
		return fmt.Errorf("failed to register %s template: %w", Name, err)
	}
	return catalog.RegisterTemplate(tmpl)
}

func providerConfigFields() []executor.ProviderConfigField {
	return []executor.ProviderConfigField{
		{{#each params_with_provider_binding}}
		{ParamName: "{{param_name}}", ProviderID: "{{provider_id}}"},
		{{/each}}
	}
}

// build emits the workflow structure from validated params.
// Filled in Gate 2.
func build(params map[string]any) (any, error) {
	return nil, fmt.Errorf("build not implemented")
}
```

### File 2: `pkg/templates/{{template_id_snake}}/template_test.go`

```go
package {{template_id_snake}}_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	executorpkg "github.com/LerianStudio/flowker/pkg/executor"
	{{template_id_snake}} "github.com/LerianStudio/flowker/pkg/templates/{{template_id_snake}}"
)

func TestRegister_Success(t *testing.T) {
	catalog := executorpkg.NewCatalog()
	require.NoError(t, {{template_id_snake}}.Register(catalog))

	tmpl, ok := catalog.GetTemplate({{template_id_snake}}.TemplateID)
	require.True(t, ok)
	require.Equal(t, {{template_id_snake}}.Name, tmpl.Name())
}

func TestRegister_Duplicate(t *testing.T) {
	catalog := executorpkg.NewCatalog()
	require.NoError(t, {{template_id_snake}}.Register(catalog))

	err := {{template_id_snake}}.Register(catalog)
	require.Error(t, err, "duplicate registration must fail")
}

func TestValidateParams_Valid(t *testing.T) {
	catalog := executorpkg.NewCatalog()
	require.NoError(t, {{template_id_snake}}.Register(catalog))
	tmpl, _ := catalog.GetTemplate({{template_id_snake}}.TemplateID)

	validParams := map[string]any{
		{{#each params}}
		"{{param_name}}": {{valid_example}},
		{{/each}}
	}
	require.NoError(t, tmpl.ValidateParams(validParams))
}

func TestValidateParams_MissingRequired(t *testing.T) {
	catalog := executorpkg.NewCatalog()
	require.NoError(t, {{template_id_snake}}.Register(catalog))
	tmpl, _ := catalog.GetTemplate({{template_id_snake}}.TemplateID)

	require.Error(t, tmpl.ValidateParams(map[string]any{}))
}

func TestBuild_ValidParams(t *testing.T) {
	catalog := executorpkg.NewCatalog()
	require.NoError(t, {{template_id_snake}}.Register(catalog))
	tmpl, _ := catalog.GetTemplate({{template_id_snake}}.TemplateID)

	params := map[string]any{
		{{#each params}}
		"{{param_name}}": {{valid_example}},
		{{/each}}
	}
	out, err := tmpl.Build(params)
	require.NoError(t, err)
	require.NotNil(t, out)

	// Verify output shape
	workflow, ok := out.(*model.CreateWorkflowInput)
	require.True(t, ok)
	require.Len(t, workflow.Nodes, {{nodes_count}})
	require.Len(t, workflow.Edges, {{edges_count}})
}
```

### File 3 (patch): `pkg/templates/register.go`

```diff
 import (
     "github.com/LerianStudio/flowker/pkg/executor"
+    "github.com/LerianStudio/flowker/pkg/templates/{{template_id_snake}}"
     "github.com/LerianStudio/flowker/pkg/templates/tracer_midaz"
 )

 func RegisterDefaults(catalog executor.Catalog) error {
     if err := tracer_midaz.Register(catalog); err != nil {
         return err
     }
+    if err := {{template_id_snake}}.Register(catalog); err != nil {
+        return err
+    }
     return nil
 }
```

## Gate 2 — Build Function & Param Schema (Judgment)

Dispatch `ring:backend-engineer-golang` to fill two things: `paramSchema` (JSON Schema) and `build()` function body.

<dispatch_required agent="ring:backend-engineer-golang">
Fill paramSchema with JSON Schema Draft 2020-12 AND implement build() returning *model.CreateWorkflowInput.
</dispatch_required>

Prompt template:

```yaml
Task:
  subagent_type: "ring:backend-engineer-golang"
  description: "Implement build() and paramSchema for {{template_id}} template"
  prompt: |
    Fill the JSON Schema AND the build() function in:
    pkg/templates/{{template_id_snake}}/template.go

    ## paramSchema Requirements
    - JSON Schema Draft 2020-12
    - Properties matching each declared param:
      - string params: {"type": "string", "minLength": 1}
      - uuid params: {"type": "string", "format": "uuid"}
      - integer: {"type": "integer"}
      - boolean: {"type": "boolean"}
    - Required params listed in "required" array
    - Params with provider_config_binding MUST be uuid-formatted strings

    ## build() Requirements
    Implement `build(params map[string]any) (any, error)` that:
    1. Extracts each param into typed variable
    2. Constructs `[]model.Node` with:
       - Unique node IDs (use uuid.New().String() or static readable IDs)
       - NodeType = trigger | executor | conditional
       - Reference = TriggerID or ExecutorID as declared
       - Data = map[string]any derived from params (per data_mapping)
    3. Constructs `[]model.Edge` with:
       - Source and Target = node IDs from step 2
       - Condition = as declared (nil for unconditional edges)
    4. Returns &model.CreateWorkflowInput{
           Name: params["workflow_name"].(string),
           Description: Description,
           Nodes: nodes,
           Edges: edges,
       }

    ## Validation
    - `go build ./pkg/templates/{{template_id_snake}}/...` must pass
    - Returned `*model.CreateWorkflowInput` must have:
      - Exactly {{nodes_count}} nodes
      - Exactly {{edges_count}} edges
      - First node must be of type `trigger`
      - Every edge source_node_id and target_node_id must match an existing node ID

    ## Reference
    See `pkg/templates/tracer_midaz/template.go` as canonical example (4 nodes, 3 edges, webhook→validate→conditional→transaction).
```

## Gate 3 — Unit Tests

Dispatch `ring:dev-unit-testing` with coverage threshold 85%.

<dispatch_required skill="ring:dev-unit-testing">
Run Gate 3 unit testing on the new template package.
</dispatch_required>

Provide this input:

```yaml
unit_id: "{{template_id}}-template"
language: "go"
coverage_threshold: 85.0
implementation_files:
  - "pkg/templates/{{template_id_snake}}/template.go"
acceptance_criteria:
  - "Register succeeds on fresh catalog"
  - "Register fails on duplicate (second call returns error)"
  - "ValidateParams passes on fully-populated valid param set"
  - "ValidateParams fails on missing required params"
  - "ValidateParams fails on wrong type (e.g., string where int expected)"
  - "Build returns *model.CreateWorkflowInput with correct Nodes count"
  - "Build returns *model.CreateWorkflowInput with correct Edges count"
  - "Build returns error on param missing that ValidateParams would reject"
  - "Build output: first node is trigger type"
  - "Build output: every edge source/target references an existing node ID"
```

## Gate 4 — Review

Dispatch `ring:codereview` (parallel 6-reviewer pipeline).

<dispatch_required skill="ring:codereview">
Run the standard parallel review pipeline on all files created/modified.
</dispatch_required>

Business-logic reviewer MUST verify:
- Node graph is connected (no orphan nodes)
- No cycles in edges (template workflows should be DAG)
- ProviderConfigField bindings align with executor IDs used in nodes

## Verification Commands (run from flowker repo root)

```bash
# 1. Code compiles
go build ./...

# 2. Unit tests pass with coverage
go test ./pkg/templates/{{template_id_snake}}/... -cover -covermode=atomic

# 3. Template registers without error
go test ./pkg/templates/ -run TestRegisterDefaults -v

# 4. Lint clean
make lint

# 5. Runtime verification (requires local server + existing provider configs)
make up
curl -s http://localhost:8080/v1/catalog/templates | jq '.[].id' | grep {{template_id}}
curl -s http://localhost:8080/v1/catalog/templates/{{template_id}} | jq '.param_schema'

# 6. Create a real workflow from the template
curl -X POST http://localhost:8080/v1/workflows/from-template \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"template_id": "{{template_id}}", "params": {<your valid params>}}'
```

All commands must succeed. Paste actual output into the Verification Report section.

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| Calling external APIs inside `build()` | `build()` must be pure and deterministic | All data comes from `params map[string]any`; fetch happens in runtime services |
| Looking up provider configs inside `build()` | Provider config lookup is `CreateWorkflowFromTemplate` service's job | Declare `ProviderConfigField` bindings; param value is the UUID string |
| Referencing an executor ID without verifying it exists | Broken at workflow-creation time, not at template registration | Gate 0 verifies catalog presence before scaffold |
| Orphan nodes (not connected by any edge) | Workflow engine will never execute them | Every non-trigger node must have at least one incoming edge |
| Using `model.Node` fields the catalog doesn't know | Workflow validation fails at creation | Use only documented `model.Node` fields; verify against `pkg/model/workflow.go` |
| Randomizing UUIDs inside `build()` on every call | Breaks idempotency tests | Either accept deterministic seeds via params or document non-determinism |
| Adding MongoDB collections or handlers | Templates are stateless catalog entries | Just `pkg/templates/<name>/template.go` and register |

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Skip ValidateParams, JSON Schema is overkill" | "Without validation, bad params reach `build()` and crash at runtime. Schema catches them at creation." |
| "Let `build()` fetch live provider config" | "`build()` must be pure. Provider-config lookup is the consuming service's responsibility." |
| "Templates are copy-paste, let me skip tests" | "Build() is where node/edge bugs hide. Tests prevent a broken template from registering." |
| "Just hardcode node IDs to fixed UUIDs" | "Fixed UUIDs collide across workflows created from the same template. Generate per-Build call." |
| "I'll wire up `ProviderConfigField` later" | "Without binding, the UI cannot offer a dropdown of valid provider configs. Declare it now." |

## Example: Walkthrough — fictional `kyc-aml-check` template

**Input (Gate 0):**
- `template_id`: `kyc-aml-check`
- `category`: `compliance`
- Params:
  - `workflow_name` (string, required)
  - `kyc_provider_config_id` (uuid, required, binding: provider `example-kyc`)
  - `aml_provider_config_id` (uuid, required, binding: provider `example-aml`)
- Nodes:
  1. `trigger_webhook` — type: trigger, ref: `webhook`
  2. `kyc_verify` — type: executor, ref: `example-kyc.verify-identity`
  3. `aml_check` — type: executor, ref: `example-aml.screen-entity`
  4. `decision` — type: conditional
  5. `approve` / `reject` — leaf nodes (executor or terminal)
- Edges:
  - `trigger_webhook → kyc_verify`
  - `kyc_verify → aml_check`
  - `aml_check → decision`
  - `decision → approve` (condition: "true")
  - `decision → reject` (condition: "false")

**Output after Gate 1:**
```
pkg/templates/kyc_aml_check/
├── template.go       (Register + paramSchema placeholder + build stub)
└── template_test.go  (5 tests scaffolded)
pkg/templates/register.go  (+3 lines)
```

**After Gate 2:**
- `paramSchema` requires all three params
- `build()` returns `*model.CreateWorkflowInput` with 5 nodes, 5 edges
- First node is trigger, graph is acyclic, all executor IDs verified

**After Gate 3:**
- Coverage: 94%
- All 5 tests pass

**After Gate 4:**
- Business-logic reviewer: PASS (graph connected, no cycles, ProviderConfigField matches executor provider)
- Test reviewer: PASS

## Handoff to Next Gate

Emit this structured output when complete:

```markdown
## Template Summary
**Status:** PASS / FAIL
**Template ID:** {{template_id}}
**Category:** {{category}}
**Nodes:** {{count}}
**Edges:** {{count}}
**Test Coverage:** {{percent}}%

## Files Created
| Path | Purpose | Lines |
|------|---------|-------|
| pkg/templates/{{template_id_snake}}/template.go | Register + build + schema | N |
| pkg/templates/{{template_id_snake}}/template_test.go | Unit tests | N |

## Files Modified
| Path | Change |
|------|--------|
| pkg/templates/register.go | +import +Register call |

## Verification Report
```
[paste `go test -cover` output]
[paste `make lint` output]
[paste `curl /v1/catalog/templates/{{template_id}}` output]
[paste `POST /v1/workflows/from-template` success output]
```

## Handoff
- Template appears in catalog: YES
- Workflow successfully created from template: YES
- Next step: document template in project README / user-facing docs
```
