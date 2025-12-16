---
name: regulatory-templates-gate1
description: |
  Gate 1 sub-skill - performs regulatory compliance analysis and field mapping
  from template specifications.

trigger: |
  - regulatory-templates-setup completed
  - Need to analyze regulatory specification and map fields

skip_when: |
  - Setup not complete → run setup first
  - Gate 1 already passed → proceed to Gate 2

sequence:
  after: [regulatory-templates-setup]
  before: [regulatory-templates-gate2]
---

# Regulatory Templates - Gate 1: Placeholder Mapping (Post Gate 0)

## Overview

**UPDATED: Gate 1 now maps placeholders from Gate 0 template to data sources. NO structure creation, NO logic addition.**

**Parent skill:** `regulatory-templates`

**Prerequisites:**
- Context from `regulatory-templates-setup`
- Template base from `regulatory-templates-setup`

**Output:** Mapping of placeholders to backend data sources

---

## Foundational Principle

**Field mapping errors compound through Gates 2-3 and into production.**

Gate 1 is the foundation of regulatory template accuracy:
- **snake_case conversion**: Python/Django ecosystem standard (PEP 8) - mixed conventions cause maintenance nightmares
- **Data source prefixes**: BACEN audits require data lineage traceability - "where did this value come from?"
- **Interactive validation**: No dictionary = no ground truth - user approval prevents assumption errors
- **Confidence thresholds**: Quality gates prevent low-confidence mappings from reaching production
- **Dictionary checks**: Consistency across team, audit trail for regulatory reviews

**Every "shortcut" in Gate 1 multiplies through downstream gates:**
- Skip snake_case → Gate 3 templates have mixed conventions → maintenance debt
- Skip prefixes → Gate 2 cannot trace data sources → debugging nightmares
- Auto-approve mappings → Gate 2 validates wrong assumptions → compliance violations
- Skip optional fields → Gate 1 fails confidence threshold → rework loops
- Lower thresholds → Low-confidence fields reach Gate 3 → production errors

**Technical correctness in Gate 1 = foundation for compliance in production.**

---

## When to Use

**Called by:** `regulatory-templates` skill after Gate 0 template structure copy

**Purpose:** Map each placeholder to its data source - structure already defined in Gate 0

---

## NO EXCEPTIONS - Technical Requirements Are Mandatory

**Gate 1 field mapping requirements have ZERO exceptions.** Every requirement exists to prevent specific failure modes.

### Common Pressures You Must Resist

| Pressure | Your Thought | Reality |
|----------|--------------|---------|
| **Speed** | "camelCase works, skip conversion" | PEP 8 violation creates maintenance debt. 30 min now vs 75+ min debugging later |
| **Simplicity** | "Prefix is verbose, omit it" | BACEN audits require data lineage. Implicit resolution = debugging nightmares |
| **Efficiency** | "AUTO-approve obvious mappings" | No dictionary = no ground truth. "Obvious" assumptions cause compliance violations |
| **Pragmatism** | "Skip optional fields" | Confidence calculated across ALL fields. 64% coverage = FAIL |
| **Authority** | "75% confidence is enough" | Threshold erosion: 75% → 70% → 60%. LOW confidence fields = high-risk mappings |
| **Experience** | "I memorized these, skip dictionary" | Memory is fallible. 1-min check prevents 20-40 min error correction |

### Technical Requirements (Non-Negotiable)

**snake_case Conversion:**
- ✅ REQUIRED: Convert ALL field names to snake_case
- ❌ FORBIDDEN: Use camelCase, PascalCase, or mixed conventions
- Why: Python/Django PEP 8 standard, grep-able patterns, maintenance

**Data Source Prefixes:**
- ✅ REQUIRED: `{{ midaz_onboarding.organization.0.legal_document }}`
- ❌ FORBIDDEN: `{{ organization.legal_document }}`
- Why: Data lineage traceability, multi-source disambiguation, audit compliance

**Interactive Validation:**
- ✅ REQUIRED: AskUserQuestion for EACH field mapping
- ❌ FORBIDDEN: Auto-approve HIGH confidence fields
- Why: No dictionary = no ground truth, user provides domain knowledge

**Confidence Threshold:**
- ✅ REQUIRED: Overall confidence ≥ 80%
- ❌ FORBIDDEN: Lower threshold or skip fields
- Why: Quality gate for Gate 2/3, prevents low-confidence mappings in production

**Dictionary Check:**
- ✅ REQUIRED: Check `~/.claude/docs/regulatory/dictionaries/` first
- ❌ FORBIDDEN: Skip check and use memory
- Why: Consistency, audit trail, error prevention

### The Bottom Line

**Shortcuts in field mapping = errors in production regulatory submissions.**

Gate 1 creates the foundation for Gates 2-3. Technical correctness here prevents compliance violations downstream.

**If you're tempted to skip ANY requirement, ask yourself: Am I willing to debug production BACEN submission failures caused by this shortcut?**

---

## Rationalization Table - Know the Excuses

Every rationalization below has been used to justify skipping requirements. **ALL are invalid.**

| Excuse | Why It's Wrong | Correct Response |
|--------|---------------|------------------|
| "camelCase works fine in Django" | PEP 8 violation, maintenance debt, inconsistent conventions | Convert ALL to snake_case |
| "Prefix is verbose and ugly" | Audit trail required, multi-source disambiguation critical | Prefix ALL fields |
| "HIGH confidence = obvious, no approval needed" | No dictionary = no ground truth, assumptions fail | Ask approval for EACH field |
| "Optional fields don't affect compliance" | Confidence calculated across ALL fields, 64% = FAIL | Map ALL fields |
| "75% is close to 80%, good enough" | Threshold erosion, LOW confidence = high risk | Research to ≥80% |
| "I know these mappings by heart" | Memory fallible, experience creates overconfidence | Check dictionary first |
| "Everyone knows where organization comes from" | Implicit tribal knowledge, new team members lost | Explicit beats implicit |
| "User approval wastes their time" | User provides domain knowledge we lack | Interactive validation mandatory |
| "Conversion is unnecessary busywork" | Dismissing requirements without understanding cost | Technical correctness prevents debt |
| "This is simple, process is overkill" | Simple tasks accumulate into complex problems | Follow workflow completely |

### If You Find Yourself Making These Excuses

**STOP. You are rationalizing.**

The requirements exist to prevent these exact thoughts from causing errors. If a requirement seems "unnecessary," that's evidence it's working - preventing shortcuts that seem reasonable but create risk.

---

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

**Field Path Format:** `{data_source}.{entity}.{index?}.{field}`

**Examples:** `{{ midaz_onboarding.organization.0.legal_document }}` | `{{ midaz_transaction.operation_route.code }}` | `{{ midaz_transaction.balance.available }}`

**Common Mappings:** CNPJ→`organization.0.legal_document`, COSIF→`operation_route.code`, Saldo→`balance.available`

**RULE:** Always prefix with data source! ❌ `{{ organization.legal_document }}` → ✅ `{{ midaz_onboarding.organization.0.legal_document }}`

---

## Gate 1 Process

### STEP 1: Check for Data Dictionary (FROM/TO Mappings)

**HIERARCHICAL SEARCH - Dictionary first, Interactive Validation second:**

**Dictionary Path:** `~/.claude/docs/regulatory/dictionaries/{category}-{code}.yaml`

| Step | If Dictionary EXISTS | If Dictionary NOT EXISTS |
|------|---------------------|--------------------------|
| 1 | Load YAML, use field_mappings | Query MCP: `mcp__apidog_midaz/crm__read_project_oas()` |
| 2 | Apply transformations | Analyze schemas, SUGGEST mappings (preserve casing) |
| 3 | Use existing mappings | **AskUserQuestion** for EACH field (user approval required) |
| 4 | Return | Create dictionary with APPROVED mappings only |
| 5 | — | Save to dictionary path for future use |

**Dictionary contains:** field_mappings (FROM→TO), transformations, pitfalls, validation_rules

---

## 🔴 CRITICAL: INTERACTIVE VALIDATION FOR TEMPLATES WITHOUT DICTIONARY

### Data Dictionaries Location

**Dicionários de dados disponíveis em:** `~/.claude/docs/regulatory/dictionaries/`

Consulte os dicionários existentes antes de iniciar o mapeamento de campos.

---

### Interactive Validation Process (MANDATORY for templates without dictionary)

| Step | Action | Details |
|------|--------|---------|
| **A** | Discover Fields | Read regulatory spec (XSD/PDF) → Extract ALL required fields + types + formats |
| **B** | Query API Schemas | `mcp__apidog-midaz/crm__read_project_oas()` → Extract available fields from both systems |
| **C** | Interactive Validation | For EACH field: AskUserQuestion with top 3-4 suggestions + "Skip" + "Other" (custom path) |
| **D** | Validate Transformations | If field needs transform: AskUserQuestion with options (e.g., `slice:':8'`, "No transformation") |
| **E** | Generate Dictionary | Create YAML with APPROVED mappings only → Save to `DICTIONARY_BASE_PATH/[template].yaml`

---

### AskUserQuestion Implementation for Field Mapping

**CRITICAL: Use AskUserQuestion tool with these patterns:**

| Pattern | Question Format | Options |
|---------|----------------|---------|
| **Field Source** | `Map '${field.name}' (${type}, ${required})?` | Top 3 suggestions (with confidence %) + "Skip for now" + "Other" (auto) |
| **Transformation** | `Transformation for '${field.name}'?` | Suggested filters (with examples) + "No transformation" + "Other" (auto) |
| **Batch Approval** | `Approve mapping for '${name}'? Suggested: ${path}, Confidence: ${%}` | "Approve ✓" / "Reject ✗" (max 4 questions per batch) |

**Note:** "Other" option automatically added by AskUserQuestion for custom input.

---

### Complete Interactive Validation Flow

**Process:** Read spec → Query MCP schemas → For EACH field: AskUserQuestion → Process response → Track approved/skipped

| Response Type | Action |
|--------------|--------|
| "Skip" | Add to skippedFields (resolve in Gate 2) |
| Custom input ("Other") | Add with `approved_by: "user_custom_input"`, confidence: 100 |
| Suggested option | If needs transformation: ask for filter (slice, floatformat, etc.) → Add with `approved_by: "user_selection"` |

**Output:** `{ approvedMappings: [...], skippedFields: [...] }`

---

### Validation Rules for User Input

**Valid path patterns for custom input:**

| Source | Pattern | Example |
|--------|---------|---------|
| `midaz_onboarding` | `midaz_onboarding.(organization\|account).N.field` | `midaz_onboarding.organization.0.legal_document` |
| `midaz_transaction` | `midaz_transaction.(operation_route\|balance\|operation).field` | `midaz_transaction.balance.available` |
| `crm` | `crm.(holder\|alias).field` | `crm.holder.document` |
| `metadata` | `(midaz\|crm).entity.metadata.field` | `midaz.account.metadata.branch` |

**Validation:** If path doesn't match patterns → warn user but allow (may be valid custom path).

### NAMING CONVENTION IN FIELD DISCOVERY

**CRITICAL: ALWAYS CONVERT TO SNAKE_CASE!**

| API Returns | Map As | ✅/❌ |
|-------------|--------|------|
| `legalDocument` | `organization.legal_document` | ✅ |
| `taxId` / `TaxID` | `organization.tax_id` | ✅ |
| `openingDate` | `organization.opening_date` | ✅ |
| `legalDocument` | `organization.legalDocument` | ❌ NEVER |

**Search patterns help FIND fields. Once found, CONVERT TO SNAKE_CASE!**

### Hierarchical Search Strategy

**CRITICAL: Convert ALL discovered fields to snake_case!**

| Step | Action | Priority Paths |
|------|--------|----------------|
| **1** | Query MCP schemas | `mcp__apidog_crm/midaz__read_project_oas()` |
| **2** | Search CRM first | holder.document, holder.name, holder.type, holder.addresses.*, holder.contact.*, holder.naturalPerson.*, holder.legalPerson.*, alias.bankingDetails.*, alias.metadata.* |
| **3** | Search Midaz second | account.name, account.alias, account.metadata.*, account.status, transaction.metadata.*, balance.amount, organization.legalDocument |
| **4** | Check metadata | crm.holder/alias.metadata.*, midaz.account/transaction.metadata.* |
| **5** | Mark as uncertain | If not found → document searched locations + suggest closest matches + indicate confidence |

### Confidence Scoring System

| Level | Score | Criteria |
|-------|-------|----------|
| **HIGH** (90-100%) | Base(30) + Name(25) + System(25) + Type(20) + Validation(20) | Exact name match, type matches, primary system, validation passes, simple/no transform |
| **MEDIUM** (60-89%) | Base(30) + partial matches | Partial name or pattern match, compatible type needs transform, secondary system, some uncertainty |
| **LOW** (30-59%) | Base(30) only | Synonym/fuzzy match, significant transform, metadata only, cannot validate |

**Formula:** `Score = Base(30) + NameMatch(0-25) + SystemMatch(0-25) + TypeMatch(0-20) + ValidationMatch(0-20)`

| Component | Values |
|-----------|--------|
| NameMatch | exact=25, partial=15, pattern=5 |
| SystemMatch | primary=25, secondary=15, metadata=5 |
| TypeMatch | exact=20, compatible=10, needs_transform=5 |
| ValidationMatch | validated=20, partial=10, cannot_validate=0 |

### Validation with Examples

**Process:** Fetch sample → Apply transformation → Validate format

| Pattern | Regex |
|---------|-------|
| CPF | `/^\d{11}$/` |
| CNPJ | `/^\d{14}$/` |
| CNPJ_BASE | `/^\d{8}$/` |
| DATE_BR | `/^\d{2}\/\d{2}\/\d{4}$/` |
| DATE_ISO | `/^\d{4}-\d{2}-\d{2}$/` |
| PHONE_BR | `/^\+?55?\s?\(?\d{2}\)?\s?\d{4,5}-?\d{4}$/` |
| CEP | `/^\d{5}-?\d{3}$/` |

**Example:** CNPJ Base: `"12345678000190"` → `slice:':8'` → `"12345678"` → `/^\d{8}$/` → ✓ valid (+20 confidence)

### Agent Dispatch

**Dispatch:** `Task(subagent_type: "finops-analyzer", model: "opus")`

**Pre-dispatch:** Check dictionary at `~/.claude/docs/regulatory/dictionaries/{category}-{code}.yaml`

| Mode | Condition | Instructions |
|------|-----------|--------------|
| **Dictionary Mode** | File exists | USE dictionary data ONLY. NO MCP calls. Validate mappings. |
| **MCP Discovery Mode** | File missing | Query MCP APIs → Suggest mappings → AskUserQuestion for EACH → Create dictionary with APPROVED only |

**Prompt includes:** Template info, dictionary status/content (if exists), snake_case requirement, validation steps, output format

**CRITICAL REQUIREMENTS:**

| ✅ DO | ❌ NEVER |
|-------|---------|
| Check dictionary FIRST | Skip dictionary check |
| MCP only if no dictionary | Call MCP when dictionary exists |
| AskUserQuestion for ALL mappings | Auto-approve without asking |
| Save APPROVED mappings only | Save unapproved guesses |
| Validate all transformations | Guess field mappings |

**Report Output:** dictionary_status, field_mappings (code, name, required, source, transformation, confidence, validated, examples), validation_summary (total, mapped, coverage%, avg_confidence)

**COMPLETION STATUS:** COMPLETE, INCOMPLETE, or NEEDS_DISCUSSION

---

## Capture Gate 1 Response

**Response structure:**

| Section | Fields |
|---------|--------|
| **Template Info** | template_name, regulatory_standard, authority, submission_frequency, submission_deadline |
| **Field Counts** | total_fields, mandatory_fields, optional_fields |
| **Discovery Summary** | crm_fields_available, midaz_fields_available, metadata_fields_used, unmapped_fields |
| **Field Mappings** (per field) | field_code, field_name, required, type, format, mappings_found[], selected_mapping, confidence_score, confidence_level, reasoning, transformation, validation_passed, status |
| **Uncertainties** (per field) | field_code, field_name, mappings_attempted[], best_match, doubt, suggested_resolution |
| **Confidence Summary** | high/medium/low_confidence_fields, overall_confidence |
| **Compliance Risk** | LOW/MEDIUM/HIGH (based on confidence levels) |
| **Documentation Used** | official_regulatory URL, implementation_reference URL, regulatory_framework |

---

## Documentation Sources

### Official Regulatory Sources (SOURCE OF TRUTH)

---

## Red Flags - STOP Immediately

If you catch yourself thinking ANY of these, STOP and re-read the NO EXCEPTIONS section:

### Skip Patterns
- "Skip snake_case conversion for..."
- "Omit prefix for obvious fields"
- "Use camelCase this time"
- "Mixed conventions are fine"
- "Dictionary check is ceremony"

### Partial Compliance
- "Convert only mandatory fields"
- "Prefix only ambiguous fields"
- "Auto-approve HIGH confidence"
- "Map only mandatory fields"
- "75% is close enough to 80%"

### Experience-Based Shortcuts
- "I memorized these mappings"
- "I know where this comes from"
- "We've done this 50 times"
- "The pattern is obvious"
- "Dictionary won't exist anyway"

### Justification Language
- "Unnecessary busywork"
- "Verbose and ugly"
- "Wasting user time"
- "Process over outcome"
- "Being pragmatic"
- "Close enough"
- "Everyone knows"

### If You See These Red Flags

1. **Acknowledge the rationalization** ("I'm trying to skip snake_case")
2. **Read the NO EXCEPTIONS section** (understand why it's required)
3. **Read the Rationalization Table** (see your exact excuse refuted)
4. **Follow the requirement completely** (no modifications)

**Technical requirements are not negotiable. Field mapping errors compound through Gates 2-3.**

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

| Status | Output Fields |
|--------|--------------|
| **PASS** | STATUS: PASSED, FIELDS: total/mandatory, UNCERTAINTIES: count, COMPLIANCE_RISK, NEXT: Gate 2, EVIDENCE: docs consulted + all mandatory mapped |
| **FAIL** | STATUS: FAILED, CRITICAL_GAPS: count, HIGH_UNCERTAINTIES: count, NEXT: Fix gaps, BLOCKERS: Critical mapping gaps |

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

**Return to `regulatory-templates`:** `{ gate1_passed: bool, gate1_context: {...}, uncertainties_count: N, critical_gaps: [], next_action: "proceed_to_gate2" | "fix_gaps_and_retry" }`

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

**Finding "Agência" field for CADOC 4010:**

| Step | Action | Result |
|------|--------|--------|
| 1 | Pattern search | `["branch", "agency", "agencia", "branch_code"]` |
| 2 | Query CRM first | `crm.alias.bankingDetails.branch` ✓ (exact, 95%) |
| 3 | Query Midaz fallback | `midaz.account.metadata.branch_code` ⚠ (metadata, 45%) |
| 4 | Select highest | `crm.alias.bankingDetails.branch` (HIGH confidence) |

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