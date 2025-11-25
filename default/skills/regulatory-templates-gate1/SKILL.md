---
name: regulatory-templates-gate1
description: Gate 1 of regulatory templates - performs regulatory compliance analysis and field mapping
---

# Regulatory Templates - Gate 1: Placeholder Mapping (Post Gate 0)

## Overview

**UPDATED: Gate 1 now maps placeholders from Gate 0 template to data sources. NO structure creation, NO logic addition.**

**Parent skill:** `regulatory-templates`

**Prerequisites:**
- Context from `regulatory-templates-setup`
- Template base from `regulatory-templates-gate0`

**Output:** Mapping of placeholders to backend data sources

---

## When to Use

**Called by:** `regulatory-templates` skill after Gate 0 template structure copy

**Purpose:** Map each placeholder to its data source - structure already defined in Gate 0

## CRITICAL CHANGE

### ❌ OLD Gate 1 (Over-engineering)
- Created complex field mappings
- Added transformation logic
- Built nested structures
- Result: 90+ line templates

### ✅ NEW Gate 1 (Simple)
- Takes template from Gate 0
- Maps placeholders to single data source
- NO structural changes
- Result: <20 line templates

### 🔴 CRITICAL: NAMING CONVENTION - SNAKE_CASE STANDARD
**ALL field names MUST be converted to snake_case:**
- ✅ If API returns `legalDocument` → convert to `legal_document`
- ✅ If API returns `taxId` → convert to `tax_id`
- ✅ If API returns `openingDate` → convert to `opening_date`
- ✅ If API returns `naturalPerson` → convert to `natural_person`
- ✅ If API returns `tax_id` → keep as `tax_id` (already snake_case)

**ALWAYS convert camelCase, PascalCase, or any other convention to snake_case.**

### 🔴 CRITICAL: DATA SOURCES - ALWAYS USE CORRECT DOMAIN PREFIX

**REFERENCE:** See `/docs/regulatory/DATA_SOURCES.md` for complete documentation.

**Available Data Sources (Reporter Platform):**

| Data Source | Descrição | Entidades Principais |
|-------------|-----------|---------------------|
| `midaz_onboarding` | Dados cadastrais | organization, account |
| `midaz_transaction` | Dados transacionais | operation_route, balance, operation |
| `midaz_onboarding_metadata` | Metadados cadastro | custom fields |
| `midaz_transaction_metadata` | Metadados transações | custom fields |

**Field Path Format:**
```
{data_source}.{entity}.{index?}.{field}
```

**Examples:**
```django
# CNPJ da organização (primeiro item da lista)
{{ midaz_onboarding.organization.0.legal_document }}

# Código COSIF (iterando operation_routes)
{%- for route in midaz_transaction.operation_route %}
  {{ route.code }}
{% endfor %}

# Saldo (filtrado por operation_route)
{%- with balance = filter(midaz_transaction.balance, "operation_route_id", route.id)[0] %}
  {{ balance.available }}
{% endwith %}
```

**Common Regulatory Field Mappings:**

| Campo Regulatório | Data Source | Path |
|-------------------|-------------|------|
| CNPJ (8 dígitos) | `midaz_onboarding` | `organization.0.legal_document` |
| Código COSIF | `midaz_transaction` | `operation_route.code` |
| Saldo | `midaz_transaction` | `balance.available` |
| Data Base | `reporter` | `{% date_time "YYYY/MM" %}` |

**RULE:** Always prefix fields with the correct data source!
- ❌ WRONG: `{{ organization.legal_document }}`
- ✅ CORRECT: `{{ midaz_onboarding.organization.0.legal_document }}`

---

## Gate 1 Process

### STEP 1: Check for Data Dictionary (FROM/TO Mappings)

**HIERARCHICAL SEARCH - Data Dictionary first, MCP second:**

```javascript
// CRITICAL: Hierarchical search to avoid unnecessary MCP calls

const templateCode = context.template_selected.split(' ')[1]; // e.g., "4010"
const dictionaryPath = `docs/regulatory/dictionaries/cadoc-${templateCode}.yaml`;

// 1. FIRST: Check LOCAL data dictionary
if (fileExists(dictionaryPath)) {
  console.log(`✅ Data dictionary found: ${dictionaryPath}`);
  const dictionary = readYAML(dictionaryPath);

  // Dictionary contains:
  // - field_mappings: FROM (regulatory) → TO (systems)
  // - Validated transformations
  // - Known pitfalls
  // - Validation rules

  // Use existing mappings
  return useDictionary(dictionary);
}

// 2. IF NOT EXISTS: SEMI-AUTOMATIC discovery with human approval
console.log(`⚠️ Dictionary not found. Starting semi-automatic discovery...`);

// 2.1 Query schemas via MCP
console.log(`📡 Fetching system schemas via MCP...`);
const midazSchema = await mcp__apidog_midaz__read_project_oas_n78ry3();
const crmSchema = await mcp__apidog_crm__read_project_oas_a72jt2();

// 2.2 Analyze schemas and SUGGEST mappings (not decide)
// CRITICAL: Preserve exact field casing from schemas!
console.log(`🔍 Analyzing schemas and suggesting mappings...`);
console.log(`⚠️ PRESERVING EXACT FIELD CASING FROM API SCHEMAS`);
const suggestedMappings = analyzeSchemasAndSuggestMappings(
  regulatorySpec,
  midazSchema,  // Fields like: legalDocument, openingDate (camelCase)
  crmSchema     // Fields like: natural_person, tax_id (snake_case)
);

// 2.3 PRESENT suggestions to user for APPROVAL
// Use AskUserQuestion tool for each field mapping
console.log(`👤 Requesting user approval for suggested mappings...`);
const approvedMappings = await requestUserApproval(suggestedMappings);

// 2.4 CREATE dictionary with APPROVED mappings only
const newDictionary = {
  metadata: {
    template_code: templateCode,
    template_name: context.template_selected,
    authority: context.authority,
    created_at: new Date().toISOString(),
    created_by: "semi-automatic discovery with human approval",
    version: "1.0"
  },
  field_mappings: approvedMappings, // Only approved mappings
  xml_structure: extractXMLStructure(regulatorySpec),
  validation_rules: extractValidationRules(regulatorySpec)
};

// 2.5 Save APPROVED dictionary for future use
writeYAML(dictionaryPath, newDictionary);
console.log(`✅ Dictionary created with approved mappings: ${dictionaryPath}`);

// 2.6 Use newly created dictionary
return useDictionary(newDictionary);
```

### NAMING CONVENTION IN FIELD DISCOVERY

```javascript
CRITICAL: When discovering fields, ALWAYS CONVERT TO SNAKE_CASE!

Examples of CORRECT field mapping with snake_case conversion:
✅ API has "legalDocument" → Map as "organization.legal_document"
✅ API has "taxId" → Map as "organization.tax_id"
✅ API has "TaxID" → Map as "organization.tax_id"
✅ API has "openingDate" → Map as "organization.opening_date"
✅ API has "naturalPerson" → Map as "organization.natural_person"
✅ API has "tax_id" → Map as "organization.tax_id" (already snake_case)

Examples of INCORRECT field mapping (NEVER DO THIS):
❌ API has "legalDocument" → Mapping as "organization.legalDocument" (keep camelCase)
❌ API has "tax_id" → Mapping as "organization.taxId" (convert to camelCase)
❌ API has "openingDate" → Mapping as "organization.openingDate" (keep camelCase)

The search patterns below help FIND fields. Once found, CONVERT TO SNAKE_CASE!
```

### Field Discovery Pattern Dictionary

```javascript
FIELD DISCOVERY PATTERNS - Use for intelligent field mapping:
IMPORTANT: These patterns help FIND fields. Once found, use the EXACT field name from the API!

IDENTIFICATION PATTERNS:
- CPF/CNPJ → search: ["document", "tax_id", "legal_document", "cpf", "cnpj", "identification", "fiscal_number", "registro"]
- Nome → search: ["name", "full_name", "legal_name", "trade_name", "razao_social", "nome_completo", "denominacao"]
- Tipo Pessoa → search: ["type", "person_type", "tipo_pessoa", "natureza", "NATURAL_PERSON", "LEGAL_PERSON"]
- Nome Social → search: ["social_name", "nome_social", "preferred_name"]
- Nome Mãe → search: ["mother_name", "motherName", "nome_mae", "filiacao_mae"]
- Nome Pai → search: ["father_name", "fatherName", "nome_pai", "filiacao_pai"]

CONTACT PATTERNS:
- Email → search: ["email", "mail", "electronic_mail", "correio", "primaryEmail", "email_principal"]
- Telefone → search: ["phone", "mobile", "telephone", "telefone", "contact", "mobilePhone", "celular"]
- Endereço → search: ["address", "addresses", "location", "endereco", "logradouro", "domicilio"]
- Cidade → search: ["city", "cidade", "municipio", "locality"]
- Estado → search: ["state", "estado", "uf", "province", "region"]
- CEP → search: ["zipCode", "zip", "postal_code", "cep", "codigo_postal"]
- País → search: ["country", "pais", "countryCode", "nacionalidade"]

BANKING PATTERNS:
- Conta → search: ["account", "account_number", "numero_conta", "conta", "conta_corrente"]
- Agência → search: ["branch", "agency", "agencia", "branch_code", "codigo_agencia"]
- Banco → search: ["bank", "bank_id", "bankId", "bank_code", "codigo_banco", "instituicao"]
- IBAN → search: ["iban", "international_account", "conta_internacional"]
- Tipo Conta → search: ["account_type", "type", "tipo_conta", "modalidade"]
- Data Abertura Conta → search: ["opening_date", "openingDate", "created_at", "data_abertura"]

DATE PATTERNS:
- Nascimento → search: ["birth", "birth_date", "birthDate", "data_nascimento", "dt_nasc", "born"]
- Abertura → search: ["opening", "created", "opened", "start", "inicio", "created_at"]
- Fundação → search: ["foundation", "founding", "foundingDate", "established", "fundacao", "constituicao"]

BUSINESS PATTERNS:
- Atividade → search: ["activity", "business", "atividade", "ramo", "cnae", "economic_activity"]
- Porte → search: ["size", "company_size", "porte", "tamanho", "classificacao"]
- Faturamento → search: ["revenue", "income", "faturamento", "receita", "turnover"]
- Capital Social → search: ["capital", "social_capital", "capital_social", "patrimonio"]
```

### Hierarchical Search Strategy

```javascript
DYNAMIC FIELD DISCOVERY ORDER:

⚠️ CRITICAL: When you find a field, CONVERT IT TO SNAKE_CASE!
ALWAYS convert camelCase, PascalCase to snake_case!

For EACH regulatory field required:

STEP 1: Query Available Schemas
----------------------------------------
// Get current schemas via MCP
// PRESERVE field names exactly as they appear in schemas!
const crmSchema = await mcp__apidog-crm__read_project_oas_j55q8g();
const midazSchema = await mcp__apidog-midaz__read_project_oas_8p5ko0();
const reporterSchema = await mcp__apidog-reporter__read_project_oas_skd4ka();

STEP 2: Search CRM First (Most Complete)
----------------------------------------
Priority paths in CRM:
1. holder.document → CPF/CNPJ
2. holder.name → Nome completo
3. holder.type → NATURAL_PERSON or LEGAL_PERSON
4. holder.addresses.primary.* → Endereço principal
5. holder.addresses.additional1.* → Endereço adicional
6. holder.contact.* → Email e telefones
7. holder.naturalPerson.* → Dados de pessoa física
8. holder.legalPerson.* → Dados de pessoa jurídica
9. alias.bankingDetails.* → TODOS dados bancários
10. alias.metadata.* → Campos customizados

STEP 3: Search Midaz Second (Account/Transaction)
-------------------------------------------------
Priority paths in Midaz:
1. account.name → Nome da conta
2. account.alias → Identificador alternativo
3. account.metadata.* → Dados extras da conta
4. account.status → Status da conta
5. transaction.metadata.* → Dados da transação
6. balance.amount → Saldos
7. organization.legalDocument → Documento da organização

STEP 4: Check Metadata Fields (Custom Data)
-------------------------------------------
Both systems support metadata for custom fields:
- crm.holder.metadata.*
- crm.alias.metadata.*
- midaz.account.metadata.*
- midaz.transaction.metadata.*

STEP 5: Mark as Uncertain
-------------------------
If not found in any system:
- Document all searched locations
- Suggest closest matches found
- Indicate confidence level
```

### Confidence Scoring System

```javascript
CONFIDENCE CALCULATION FOR FIELD MAPPINGS:

HIGH CONFIDENCE (90-100%):
-------------------------
✓ Exact field name match in schema
✓ Data type matches regulatory requirement
✓ Found in primary expected system (CRM for personal, Midaz for transactions)
✓ Validation with sample data passes
✓ No transformation needed OR simple transformation

Example:
{
  "field": "CPF/CNPJ",
  "mapped_to": "crm.holder.document",
  "confidence": 95,
  "level": "HIGH",
  "reasoning": "Exact match, CRM is primary for identity, type matches"
}

MEDIUM CONFIDENCE (60-89%):
---------------------------
⚠ Partial field name match or pattern match
⚠ Data type compatible but needs transformation
⚠ Found in secondary system
⚠ Some validation uncertainty

Example:
{
  "field": "Data Abertura",
  "mapped_to": "midaz.account.created_at",
  "confidence": 75,
  "level": "MEDIUM",
  "reasoning": "Pattern match for date, needs timezone conversion"
}

LOW CONFIDENCE (30-59%):
------------------------
⚠ Only synonym or fuzzy match
⚠ Significant transformation required
⚠ Found only in metadata or unexpected location
⚠ Cannot validate with examples

Example:
{
  "field": "Codigo Agencia",
  "mapped_to": "midaz.account.metadata.branch",
  "confidence": 45,
  "level": "LOW",
  "reasoning": "Found in metadata only, cannot confirm format"
}

CONFIDENCE SCORING FORMULA:
Score = Base + NameMatch + SystemMatch + TypeMatch + ValidationMatch

Where:
- Base = 30 (if field exists)
- NameMatch = 0-25 (exact=25, partial=15, pattern=5)
- SystemMatch = 0-25 (primary=25, secondary=15, metadata=5)
- TypeMatch = 0-20 (exact=20, compatible=10, needs_transform=5)
- ValidationMatch = 0-20 (validated=20, partial=10, cannot_validate=0)
```

### Validation with Examples

```javascript
AUTOMATIC VALIDATION PROCESS:

For each mapped field:

1. FETCH SAMPLE DATA:
   // Get real record from API
   const sample = await fetch(`${api_base}/holders?limit=1`);
   const fieldValue = sample.path.to.field;

2. APPLY TRANSFORMATION:
   const transformed = applyTransformation(fieldValue, transformation_rule);

3. VALIDATE FORMAT:
   const isValid = validateAgainstRegex(transformed, regulatory_pattern);

VALIDATION PATTERNS:

CPF: /^\d{11}$/
CNPJ: /^\d{14}$/
CNPJ_BASE: /^\d{8}$/
DATE_BR: /^\d{2}\/\d{2}\/\d{4}$/
DATE_ISO: /^\d{4}-\d{2}-\d{2}$/
PHONE_BR: /^\+?55?\s?\(?\d{2}\)?\s?\d{4,5}-?\d{4}$/
EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/
CEP: /^\d{5}-?\d{3}$/

VALIDATION EXAMPLE:
Field: "CNPJ Base (8 digits)"
Source: crm.holder.document = "12345678000190"
Transformation: slice:':8'
Result: "12345678"
Pattern: /^\d{8}$/
Valid: ✓ TRUE (confidence +20)
```

### Agent Dispatch

**Use the Task tool to dispatch the finops-analyzer agent for Gate 1 analysis:**

1. **BEFORE dispatching the agent, check for existing data dictionary:**
   ```javascript
   // Extract template code from context
   const templateCode = context.template_selected.split(' ')[1].toLowerCase(); // e.g., "4010"
   const dictionaryPath = `/Users/jeffersonrodrigues/.claude/docs/regulatory/dictionaries/cadoc-${templateCode}.yaml`;

   // Try to read the dictionary file
   let dictionaryContent = null;
   let dictionaryExists = false;

   try {
     // Use Read tool to check for dictionary
     dictionaryContent = await Read(dictionaryPath);
     dictionaryExists = true;
     console.log(`✅ Data dictionary found: ${dictionaryPath}`);
   } catch (error) {
     console.log(`⚠️ Data dictionary not found. MCP discovery will be required.`);
     dictionaryExists = false;
   }
   ```

2. **Invoke the Task tool with these parameters:**
   - `subagent_type`: "finops-analyzer"
   - `model`: "opus" (for comprehensive analysis)
   - `description`: "Gate 1: Regulatory compliance analysis with dynamic field discovery"
   - `prompt`: Use the comprehensive prompt below, INCLUDING dictionary content if it exists

3. **Comprehensive Prompt Template:**

```
GATE 1: REGULATORY COMPLIANCE ANALYSIS WITH DATA DICTIONARY

TEMPLATE SELECTION (from context):
- Regulatory Template: ${context.template_selected}
- Template Code: ${context.template_code}
- Authority: ${context.authority}

DATA DICTIONARY STATUS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${dictionaryExists ?
`✅ DATA DICTIONARY PROVIDED - DO NOT USE MCP APIS!

The data dictionary has been loaded and is provided below.
YOU MUST USE THIS DICTIONARY DATA ONLY. DO NOT MAKE ANY MCP CALLS.

Dictionary Content:
================================================================================
${dictionaryContent}
================================================================================

INSTRUCTIONS FOR DICTIONARY MODE:
1. USE ONLY the field mappings from the dictionary above
2. DO NOT call mcp__apidog-midaz__ or mcp__apidog-crm__ APIs
3. VALIDATE each mapping from the dictionary
4. CHECK confidence levels and transformations
5. REPORT any issues found in the dictionary
6. PROCEED with analysis using dictionary data ONLY`
:
`⚠️ NO DATA DICTIONARY FOUND - MCP DISCOVERY REQUIRED

No existing data dictionary was found at the expected path.
You MUST perform dynamic field discovery using MCP APIs.

Path checked: docs/regulatory/dictionaries/cadoc-${context.template_code}.yaml

INSTRUCTIONS FOR MCP DISCOVERY MODE:

┌─────────────────────────────┐
│ 1. DISCOVER VIA MCP         │
│                             │
│ a) Query Midaz schema:      │
│    mcp__apidog-midaz__      │
│    read_project_oas_n78ry3  │
│                             │
│ b) Query CRM schema:        │
│    mcp__apidog-crm__        │
│    read_project_oas_a72jt2  │
│                             │
│ c) Analyze & SUGGEST        │
│    mappings with confidence │
└─────────────────────────────┘
                                       ↓
                          ┌─────────────────────────────┐
                          │ 3. REQUEST USER APPROVAL    │
                          │    (SEMI-AUTOMATIC)         │
                          │                             │
                          │ For EACH field mapping:     │
                          │                             │
                          │ Use AskUserQuestion:        │
                          │ "Field: CNPJ Base           │
                          │  Suggested: organization.   │
                          │  legalDocument + slice:':8' │
                          │  Confidence: HIGH (95%)     │
                          │                             │
                          │  Options:                   │
                          │  A) Approve (recommended)   │
                          │  B) Suggest alternative     │
                          │  C) Skip this field"        │
                          │                             │
                          │ User selects → Save choice  │
                          └─────────────────────────────┘
                                       ↓
                          ┌─────────────────────────────┐
                          │ 4. CREATE DATA DICTIONARY   │
                          │    (APPROVED MAPPINGS ONLY) │
                          │                             │
                          │ Generate YAML with:         │
                          │ - metadata                  │
                          │ - APPROVED field_mappings   │
                          │ - xml_structure             │
                          │ - validation_rules          │
                          │ - pitfalls                  │
                          │                             │
                          │ Save to:                    │
                          │ docs/regulatory/            │
                          │ dictionaries/               │
                          │ [template-code].yaml        │
                          └─────────────────────────────┘`}

CRITICAL: NAMING CONVENTION - SNAKE_CASE STANDARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ CONVERT ALL FIELD NAMES TO SNAKE_CASE!

When discovering or mapping fields:
✅ If API returns "legalDocument" → convert to "legal_document"
✅ If API returns "taxId" → convert to "tax_id"
✅ If API returns "openingDate" → convert to "opening_date"
✅ If API returns "naturalPerson" → convert to "natural_person"
✅ If API returns "tax_id" → keep as "tax_id" (already snake_case)

ALWAYS convert camelCase, PascalCase to snake_case!
This is the standard for all regulatory templates.

STEP 1: PROCESS FIELD MAPPINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If dictionary exists:
  - Use field_mappings from YAML
  - Apply documented transformations
  - Follow validation rules
  - Note any pitfalls

If dictionary created (new):
  - Document all discovered mappings
  - Calculate confidence scores
  - Test transformations
  - Identify potential pitfalls

STEP 2: VALIDATE MAPPINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For EACH field mapping:
  - Verify source field exists in system schema
  - Test transformation with example data
  - Validate output format matches regulatory requirement
  - Calculate confidence score (0-100)

STEP 3: GENERATE SPECIFICATION REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Output structured report with:

1. Data Dictionary Status:
   - dictionary_found: true/false
   - dictionary_path: "docs/regulatory/dictionaries/cadoc-4010.yaml"
   - dictionary_created: true/false (if new)

2. Field Mappings:
   For EACH regulatory field:
   - field_code: Official regulatory code
   - field_name: Official regulatory name
   - required: true/false
   - source_system: "midaz" | "crm" | "parameter"
   - source_field: Exact path (e.g., "organization.legalDocument")
   - transformation: Django filter (e.g., "slice:':8'")
   - confidence_score: 0-100
   - confidence_level: HIGH/MEDIUM/LOW
   - validated: true/false
   - example_input: Sample input value
   - example_output: Expected output value

3. Validation Summary:
   - total_fields: Number
   - mapped_fields: Number
   - coverage_percentage: Number
   - avg_confidence: Number

4. Data Dictionary Details (if created):
   - mcp_calls_made: ["midaz", "crm"]
   - mappings_discovered: Number
   - user_approvals_requested: Number
   - user_approvals_granted: Number
   - file_created: Path to new YAML file

STEP 4: USER APPROVAL FLOW (SEMI-AUTOMATIC)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**CRITICAL: When data dictionary doesn't exist, request user approval**

For EACH discovered field mapping, use AskUserQuestion tool:

```javascript
// Example for CNPJ field
AskUserQuestion({
  questions: [{
    question: "Approve mapping for regulatory field 'CNPJ Base (8 digits)'?\n\n" +
              "Suggested mapping:\n" +
              "  FROM: CADOC 4010 field 'cnpj' (required)\n" +
              "  TO: organization.legalDocument (Midaz)\n" +
              "  Transformation: slice:':8'\n" +
              "  Example: '12345678000195' → '12345678'\n" +
              "  Confidence: HIGH (95%)\n\n" +
              "Found in Midaz schema, exact match, correct type.",
    header: "CNPJ Field",
    multiSelect: false,
    options: [
      {
        label: "Approve ✓",
        description: "Use suggested mapping (recommended)"
      },
      {
        label: "Modify",
        description: "I'll provide alternative field path"
      },
      {
        label: "Skip",
        description: "Skip this field for now"
      }
    ]
  }]
});

// If user selects "Approve" → add to approved_mappings
// If user selects "Modify" → ask for alternative via "Other" option
// If user selects "Skip" → don't include in dictionary
```

**Approval Flow:**

1. **Present suggestion clearly:**
   - Show regulatory field name and requirements
   - Show suggested system field and transformation
   - Show confidence level and reasoning
   - Show example input/output

2. **Offer clear options:**
   - Approve (recommended for HIGH confidence)
   - Modify (user provides alternative)
   - Skip (leave unmapped for later)

3. **Handle responses:**
   - Approved → Add to field_mappings in dictionary
   - Modified → Use user's alternative
   - Skipped → Document as unmapped, don't block

4. **Batch approvals when possible:**
   - Can ask up to 4 questions at once
   - Group related fields together
   - But keep questions clear and focused

CRITICAL REQUIREMENTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ ALWAYS check for data dictionary FIRST
✅ ONLY call MCP if dictionary doesn't exist
✅ REQUEST user approval for ALL discovered mappings
✅ ONLY save APPROVED mappings to dictionary
✅ CREATE data dictionary after approvals
✅ SAVE dictionary for future use
✅ USE exact field paths from dictionary
✅ VALIDATE all transformations

❌ NEVER skip checking for data dictionary
❌ NEVER call MCP when dictionary exists
❌ NEVER save mappings without user approval
❌ NEVER guess field mappings
❌ NEVER auto-approve without asking user

OUTPUT FORMAT:
Structured YAML that can be saved as data dictionary.
Include ONLY approved field mappings with all details.
Document any skipped/unmapped fields separately.

COMPLETION STATUS: COMPLETE, INCOMPLETE, or NEEDS_DISCUSSION
```

4. **Example Task tool invocation:**
```javascript
// First, check for data dictionary
const templateCode = context.template_selected.split(' ')[1].toLowerCase();
const dictionaryPath = `/Users/jeffersonrodrigues/.claude/docs/regulatory/dictionaries/cadoc-${templateCode}.yaml`;

let dictionaryContent = null;
let dictionaryExists = false;

try {
  dictionaryContent = await Read(dictionaryPath);
  dictionaryExists = true;
  console.log('✅ Using existing data dictionary - NO MCP calls needed');
} catch {
  dictionaryExists = false;
  console.log('⚠️ No dictionary found - will use MCP discovery');
}

// Build the prompt with dictionary content if it exists
const fullPrompt = buildGate1Prompt(context, dictionaryExists, dictionaryContent);

// Call the Task tool with the built prompt
Task({
  subagent_type: "finops-analyzer",
  model: "opus",
  description: "Gate 1: Regulatory compliance analysis",
  prompt: fullPrompt
});
```

---

## Capture Gate 1 Response

**Extract and store these elements with enhanced confidence tracking:**

```json
{
  "template_name": "CADOC 4010 - Informações de Cadastro",
  "regulatory_standard": "BACEN_CADOC",
  "authority": "BACEN",
  "submission_frequency": "monthly",
  "submission_deadline": "2025-12-31",
  "total_fields": 45,
  "mandatory_fields": 38,
  "optional_fields": 7,
  "discovery_summary": {
    "crm_fields_available": 25,
    "midaz_fields_available": 15,
    "metadata_fields_used": 5,
    "unmapped_fields": 0
  },
  "field_mappings": [
    {
      "field_code": "001",
      "field_name": "CNPJ da Instituição",
      "required": true,
      "type": "string",
      "format": "8 digits (base CNPJ)",
      "mappings_found": [
        {
          "source": "crm.holder.document",
          "system": "CRM",
          "confidence": 95,
          "match_type": "exact"
        },
        {
          "source": "midaz.organization.legalDocument",
          "system": "MIDAZ",
          "confidence": 70,
          "match_type": "partial"
        }
      ],
      "selected_mapping": "crm.holder.document",
      "confidence_score": 95,
      "confidence_level": "HIGH",
      "reasoning": "Exact match in CRM, primary system for identity data",
      "transformation": "slice:':8'",
      "validation_passed": true,
      "status": "confirmed"
    },
    {
      "field_code": "020",
      "field_name": "Data de Abertura da Conta",
      "required": true,
      "type": "date",
      "format": "YYYY-MM-DD",
      "mappings_found": [
        {
          "source": "crm.alias.bankingDetails.openingDate",
          "system": "CRM",
          "confidence": 90,
          "match_type": "exact"
        },
        {
          "source": "midaz.account.created_at",
          "system": "MIDAZ",
          "confidence": 60,
          "match_type": "pattern"
        }
      ],
      "selected_mapping": "crm.alias.bankingDetails.openingDate",
      "confidence_score": 90,
      "confidence_level": "HIGH",
      "reasoning": "Banking details in CRM has exact opening date field",
      "transformation": "date_format:'%Y-%m-%d'",
      "validation_passed": true,
      "status": "confirmed"
    }
    // ... all fields with confidence tracking
  ],
  "uncertainties": [
    {
      "field_code": "025",
      "field_name": "Código da Atividade Econômica",
      "mappings_attempted": [
        "crm.holder.legalPerson.activity",
        "midaz.account.metadata.cnae"
      ],
      "best_match": {
        "source": "crm.holder.legalPerson.activity",
        "confidence": 45,
        "confidence_level": "LOW"
      },
      "doubt": "Field exists but format uncertain - needs validation in Gate 2",
      "suggested_resolution": "Validate if activity field contains CNAE code format"
    }
  ],
  "compliance_risk": "LOW", // Updated based on confidence levels
  "confidence_summary": {
    "high_confidence_fields": 40,
    "medium_confidence_fields": 4,
    "low_confidence_fields": 1,
    "overall_confidence": 89
  },
  "documentation_used": {
    "official_regulatory": "https://www.bcb.gov.br/estabilidadefinanceira/cadoc4010",
    "implementation_reference": "https://docs.lerian.studio/en/cadoc-4010-and-4016",
    "regulatory_framework": "BACEN Circular 3.869/2017"
  }
}
```

---

## Documentation Sources

### Official Regulatory Sources (SOURCE OF TRUTH)

---

## Pass/Fail Criteria

### PASS Criteria
- ✅ `COMPLETION STATUS: COMPLETE`
- ✅ 0 Critical gaps (unmapped mandatory fields)
- ✅ Overall confidence score ≥ 80%
- ✅ All mandatory fields mapped (even if LOW confidence)
- ✅ < 10% of fields with LOW confidence
- ✅ Dynamic discovery via MCP executed
- ✅ Documentation was consulted (both official and implementation)
- ✅ CRM checked first for banking/personal data

### FAIL Criteria
- ❌ `COMPLETION STATUS: INCOMPLETE`
- ❌ Critical gaps exist (mandatory fields unmapped)
- ❌ Overall confidence score < 60%
- ❌ > 20% fields with LOW confidence
- ❌ Documentation not consulted
- ❌ MCP discovery not performed
- ❌ Only checked one system (didn't check CRM + Midaz)

---

## State Tracking

### After PASS:

Update context and output:
```
SKILL: regulatory-templates-gate1
GATE: 1 - Regulatory Compliance Analysis
STATUS: PASSED
TEMPLATE: {context.template_selected}
FIELDS: {total_fields} total, {mandatory_fields} mandatory
UNCERTAINTIES: {uncertainties.length} to validate in Gate 2
COMPLIANCE_RISK: {compliance_risk}
NEXT: → Gate 2: Technical validation
EVIDENCE: Documentation consulted, all mandatory fields mapped
BLOCKERS: None
```

### After FAIL:

Output without updating context:
```
SKILL: regulatory-templates-gate1
GATE: 1 - Regulatory Compliance Analysis
STATUS: FAILED
TEMPLATE: {context.template_selected}
CRITICAL_GAPS: {critical_gaps.length}
HIGH_UNCERTAINTIES: {high_uncertainties.length}
NEXT: → Fix Critical gaps before proceeding
EVIDENCE: Gate 1 incomplete - missing critical mappings
BLOCKERS: Critical mapping gaps must be resolved
```

---

## Critical Validations

Ensure these patterns are followed:
- Use EXACT patterns from Lerian documentation
- Apply filters like `slice`, `floatformat` as shown in docs
- Follow tipoRemessa rules: "I" for new/rejected, "S" for approved only
- Date formats must match regulatory requirements (YYYY/MM, YYYY-MM-DD)
- CNPJ/CPF formatting rules must be exact

---

## Output to Parent Skill

Return to `regulatory-templates` main skill:

```javascript
{
  "gate1_passed": true/false,
  "gate1_context": {
    // All extracted data from Gate 1
  },
  "uncertainties_count": number,
  "critical_gaps": [],
  "next_action": "proceed_to_gate2" | "fix_gaps_and_retry"
}
```

---

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Documentation not accessible | Try alternative URLs or cached versions |
| Field names don't match Midaz | Mark as uncertain for Gate 2 validation |
| Missing mandatory fields | Mark as Critical gap, must resolve |
| Format specifications unclear | Consult both Lerian docs and government specs |

---

## Dynamic Discovery Example

```javascript
// EXAMPLE: Finding "Agência" field for CADOC 4010

// 1. Use pattern dictionary
const patterns = ["branch", "agency", "agencia", "branch_code"];

// 2. Query CRM first (banking data priority)
const crmSchema = mcp__apidog-crm__read_project_oas_j55q8g();
// Search result: crm.alias.bankingDetails.branch ✓ (exact match)

// 3. Query Midaz as fallback
const midazSchema = mcp__apidog-midaz__read_project_oas_8p5ko0();
// Search result: midaz.account.metadata.branch_code ⚠ (in metadata)

// 4. Calculate confidence
const crmMatch = {
  source: "crm.alias.bankingDetails.branch",
  confidence: 95, // Exact match + primary system
  level: "HIGH"
};

const midazMatch = {
  source: "midaz.account.metadata.branch_code",
  confidence: 45, // Metadata only
  level: "LOW"
};

// 5. Select highest confidence
selectedMapping: "crm.alias.bankingDetails.branch"
```

## Remember

1. **CONVERT TO SNAKE_CASE** - All fields must be snake_case (legal_document not legalDocument)
2. **Use MCP for dynamic discovery** - Never hardcode field paths
3. **CRM first for banking/personal data** - It has the most complete holder info
4. **Official specs are SOURCE OF TRUTH** - Regulatory requirements from government
5. **Lerian docs show IMPLEMENTATION** - How to create templates in their system
6. **Template-specific knowledge is valuable** - Always check for existing sub-skills
7. **Confidence scoring is key** - Always calculate and document confidence
8. **Be conservative with mappings** - Mark uncertain rather than guess
9. **Capture everything** - Gate 2 needs complete context with all attempted mappings
10. **Reference both sources** - Note official specs AND implementation examples
11. **Risk assessment based on confidence** - Low confidence = higher compliance risk

## Important Distinction

⚠️ **Regulatory Compliance vs Implementation**
- **WHAT** (Requirements) = Official government documentation
- **HOW** (Implementation) = Lerian documentation examples
- When validating compliance → Use official specs
- When creating templates → Use Lerian patterns
- Never confuse implementation examples with regulatory requirements