---
name: regulatory-templates-gate2
description: Gate 2 of regulatory templates - validates uncertain mappings and confirms all field specifications
---

# Regulatory Templates - Gate 2: Technical Validation

## Overview

**This sub-skill executes Gate 2 of the regulatory template workflow: validating uncertain mappings from Gate 1 and confirming all field specifications through testing.**

**Parent skill:** `regulatory-templates`

**Prerequisites:**
- Gate 1 PASSED
- Context object with Gate 1 results

**Output:** Validated mappings with test results and validation rules

---

## When to Use

**Called by:** `regulatory-templates` skill after Gate 1 passes

**Purpose:** Resolve uncertainties, validate field mappings, test transformations, define validation rules

---

## Gate 2 Process

### Check for Template-Specific Validation Rules

```javascript
// Check for template-specific sub-skill with validation rules
const templateCode = gate1_context.template_selected.split(' ')[1];
const subSkillPath = `skills/regulatory-${gate1_context.template_selected.toLowerCase().replace(' ', '')}/SKILL.md`;

if (fileExists(subSkillPath)) {
  console.log(`Using template-specific validation rules from regulatory-${templateCode}`);
  // Sub-skill contains:
  // - Confirmed validation rules (VR001, VR002, etc.)
  // - Business rules (BR001, BR002, etc.)
  // - Format rules specific to template
  // - Test data with expected outputs
}
```

### Agent Dispatch with Gate 1 Context

**Use the Task tool to dispatch the finops-analyzer agent for Gate 2 validation:**

1. **Invoke the Task tool with these parameters:**
   - `subagent_type`: "finops-analyzer" (Same analyzer for Gate 2)
   - `model`: "opus"
   - `description`: "Gate 2: Technical validation"
   - `prompt`: Use the prompt template below with Gate 1 context

2. **Prompt Template for Gate 2:**

```
GATE 2: TECHNICAL VALIDATION

⚠️ CRITICAL: DO NOT MAKE MCP API CALLS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
All field mappings and data sources have already been identified in Gate 1.
This gate focuses on VALIDATION ONLY using the provided context.
DO NOT call mcp__apidog-midaz__ or mcp__apidog-crm__ APIs.

CHECK TEMPLATE SPECIFICATIONS:
Load template specifications from centralized configuration
Use validation rules from template specifications
Apply standardized validation patterns for all templates

CONTEXT FROM GATE 1 (PROVIDED):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${JSON.stringify(gate1_context, null, 2)}

UNCERTAIN MAPPINGS FROM GATE 1:
${gate1_context.uncertainties.map(u => `
- Field ${u.field_code}: ${u.field_name}
  - Current mapping: ${u.midaz_field || u.best_match?.source || 'Not mapped'}
  - Doubt: ${u.doubt}
  - Confidence: ${u.confidence || u.best_match?.confidence || 'Unknown'}
  - Action needed: ${u.suggested_resolution || 'Validate mapping'}`).join('\n')}

VALIDATION TASKS (WITHOUT MCP):
For EACH uncertainty above:
1. USE the field mapping information from Gate 1 context
2. VALIDATE transformations using the format rules provided
3. CHECK business logic against regulatory requirements
4. CONFIRM data types and formats match expectations
5. Mark as: CONFIRMED ✓ or REJECTED ✗ (with alternative if rejected)

Also provide:
- Validation rules for the template
- Cross-field validation logic
- Test data with results

OUTPUT FORMAT:
For each uncertain field:
- Field code: [code]
- Resolution: confirmed/rejected
- Alternative if rejected: [alternative midaz field]
- Test result: [actual test output]

COMPLETION STATUS must be COMPLETE or INCOMPLETE.
```

3. **Example Task tool invocation:**
```javascript
// Gate 2 uses ONLY the context from Gate 1, NO MCP calls
const gate2Prompt = `
GATE 2: TECHNICAL VALIDATION

⚠️ CRITICAL: DO NOT MAKE MCP API CALLS
All mappings are in the Gate 1 context provided below.

CONTEXT FROM GATE 1:
${JSON.stringify(gate1_context, null, 2)}

[Rest of validation tasks...]
`;

// Call the Task tool - agent should NOT make MCP calls
Task({
  subagent_type: "finops-analyzer",
  model: "opus",
  description: "Gate 2: Technical validation (no MCP)",
  prompt: gate2Prompt
});
```

---

## Validation Process

**⚠️ IMPORTANT: All validation must be done using Gate 1 context data ONLY. No MCP API calls.**

### 1. Field Validation

For each uncertain field from Gate 1:

```javascript
{
  "field_code": "020",
  "original_doubt": "Field may not exist in Midaz schema",
  "validation_steps": [
    "1. Query Midaz API for schema",
    "2. Check field existence",
    "3. Verify data type matches requirement",
    "4. Test with sample data",
    "5. Confirm transformation logic"
  ],
  "resolution": "confirmed",
  "transformation": "UTC to America/Sao_Paulo",
  "test_data": {
    "input": "2025-01-15T10:30:00Z",
    "expected": "2025-01-15 08:30:00",
    "actual": "2025-01-15 08:30:00",
    "status": "passed"
  }
}
```

### 2. Validation Rules Definition

Create validation rules for the template:

```javascript
{
  "validation_rules": [
    {
      "rule_id": "VR001",
      "type": "field_format",
      "field": "001",
      "description": "CNPJ must be 8 digits (base)",
      "formula": "length(field_001) == 8"
    },
    {
      "rule_id": "VR002",
      "type": "cross_field",
      "fields": ["001", "003"],
      "description": "CPF must have 11 digits, CNPJ must have 14",
      "formula": "length(field_001) IN (11, 14)"
    },
    {
      "rule_id": "VR003",
      "type": "date_range",
      "field": "020",
      "description": "Date must be within reporting period",
      "formula": "field_020 >= period_start AND field_020 <= period_end"
    }
  ]
}
```

### 3. Test Results Documentation

Document all test results:

```javascript
{
  "test_results": [
    {
      "field": "001",
      "test": "CNPJ extraction",
      "input": "12345678000190",
      "transformation": "slice:':8'",
      "output": "12345678",
      "expected": "12345678",
      "passed": true
    },
    {
      "field": "020",
      "test": "Date timezone conversion",
      "input": "2025-01-15T10:30:00Z",
      "transformation": "UTC to America/Sao_Paulo",
      "output": "2025-01-15 08:30:00",
      "expected": "2025-01-15 08:30:00",
      "passed": true
    }
  ]
}
```

---

## Capture Gate 2 Response

**Extract and merge with Gate 1 context:**

```javascript
{
  // Everything from Gate 1 +
  "validated_mappings": [
    {
      "field_code": "020",
      "resolution": "confirmed",
      "transformation": "UTC to America/Sao_Paulo",
      "test_data": {
        "input": "2025-01-15T10:30:00Z",
        "expected": "2025-01-15 08:30:00",
        "actual": "2025-01-15 08:30:00",
        "status": "passed"
      }
    }
  ],
  "validation_rules": [/* rules array */],
  "all_uncertainties_resolved": true,
  "test_summary": {
    "total_tests": 45,
    "passed": 43,
    "failed": 2,
    "success_rate": "95.6%"
  }
}
```

---

## Pass/Fail Criteria

### PASS Criteria
- ✅ All Gate 1 uncertainties resolved (confirmed or alternatives found)
- ✅ Test data validates successfully (>90% pass rate)
- ✅ No new Critical/High issues
- ✅ All mandatory fields have confirmed mappings
- ✅ Validation rules defined for all critical fields

### FAIL Criteria
- ❌ Uncertainties remain unresolved
- ❌ Test failures on mandatory fields
- ❌ Cannot find alternative mappings for rejected fields
- ❌ Data type mismatches that can't be transformed
- ❌ **Mandatory fields validation < 100%**

---

## Mandatory Fields Final Validation

### CRITICAL: Must Execute Before Gate 2 Completion

```javascript
function validateMandatoryFields(context) {
  // Get mandatory fields from template-specific skill
  const templateSkill = `regulatory-${context.template_code.toLowerCase()}`;
  const mandatoryFields = await loadTemplateSpecificMandatoryFields(templateSkill);
  const validationResults = [];

  for (const field of mandatoryFields) {
    const result = {
      field_code: field.code,
      field_name: field.name,
      is_mandatory: true,
      checks: {
        mapped: checkFieldIsMapped(field, context.gate1.field_mappings),
        confidence_ok: checkConfidenceLevel(field, context.gate1.field_mappings) >= 80,
        validated: checkFieldValidated(field, context.gate2.validated_mappings),
        tested: checkFieldTested(field, context.gate2.test_results),
        transformation_ok: checkTransformationWorks(field, context.gate2.test_results)
      }
    };

    result.status = Object.values(result.checks).every(v => v === true) ? "PASS" : "FAIL";
    validationResults.push(result);
  }

  const allPassed = validationResults.every(r => r.status === "PASS");
  const coverage = (validationResults.filter(r => r.status === "PASS").length / mandatoryFields.length) * 100;

  return {
    all_mandatory_fields_valid: allPassed,
    validation_results: validationResults,
    coverage_percentage: coverage,
    failed_fields: validationResults.filter(r => r.status === "FAIL")
  };
}
```

### Mandatory Fields Dashboard Output

```markdown
## 📊 MANDATORY FIELDS VALIDATION DASHBOARD

Template: {template_name}
Total Mandatory Fields: {total_mandatory}
Coverage: {coverage}%
Status: {status_emoji} {status_text}

| # | Field | Required | Mapped | Confidence | Validated | Tested | Status |
|---|-------|----------|--------|------------|-----------|--------|--------|
| 1 | CNPJ  | ✅ YES   | ✅     | 95% HIGH   | ✅        | ✅     | ✅ PASS |
| 2 | Date  | ✅ YES   | ✅     | 100% HIGH  | ✅        | ✅     | ✅ PASS |

VALIDATION SUMMARY:
✅ Coverage: {coverage}% ({passed}/{total})
✅ Validation: {validation}% ({validated}/{total})
✅ Testing: {testing}% ({tested}/{total})
✅ Average Confidence: {avg_confidence}%

RESULT: {final_result}
```

### Gate 2 Pass Condition Update

```javascript
// Gate 2 ONLY passes if mandatory validation passes
const mandatoryValidation = validateMandatoryFields(context);

if (mandatoryValidation.all_mandatory_fields_valid) {
  context.gate2_passed = true;
  context.mandatory_validation = mandatoryValidation;
} else {
  context.gate2_passed = false;
  context.blocker = `Mandatory fields validation failed: ${mandatoryValidation.failed_fields.length} fields incomplete`;
  context.mandatory_validation = mandatoryValidation;
}
```

---

## State Tracking

### After PASS:

```
SKILL: regulatory-templates-gate2
GATE: 2 - Technical Validation
STATUS: PASSED
TEMPLATE: {context.template_selected}
RESOLVED: {validated_mappings.length} uncertainties resolved
RULES: {validation_rules.length} validation rules defined
TESTS: {test_summary.passed}/{test_summary.total} passed
NEXT: → Gate 3: API Integration Readiness
EVIDENCE: All field mappings validated with test data
BLOCKERS: None
```

### After FAIL:

```
SKILL: regulatory-templates-gate2
GATE: 2 - Technical Validation
STATUS: FAILED
TEMPLATE: {context.template_selected}
UNRESOLVED: {unresolved_uncertainties} uncertainties
TEST_FAILURES: {test_failures} critical tests failed
NEXT: → Fix validation failures before Gate 3
EVIDENCE: Technical validation incomplete
BLOCKERS: Field validation failures must be resolved
```

---

## Technical Validation Checklist

### Field Naming Convention Validation
- [ ] Verify all field names use snake_case (not camelCase)
- [ ] Check MCP API Dog for actual field naming in each datasource
- [ ] Examples: `banking_details` not `bankingDetails`, `account_id` not `accountId`
- [ ] Document any exceptions found in legacy systems

### Data Type Validations
- [ ] String fields: Check max length, encoding (UTF-8)
- [ ] Number fields: Check precision, decimal places
- [ ] Date fields: Check format (YYYY-MM-DD, YYYY/MM)
- [ ] Boolean fields: Check true/false representation
- [ ] Enum fields: Check valid values list

### Transformation Validations
- [ ] CNPJ/CPF: Slice operations work correctly
- [ ] Dates: Timezone conversions accurate
- [ ] Numbers: Decimal formatting (floatformat)
- [ ] Strings: Trim, uppercase, padding as needed
- [ ] Nulls: Default values applied correctly

### Cross-Field Validations
- [ ] Dependent fields have consistent values
- [ ] Date ranges are logical
- [ ] Calculated fields match formulas
- [ ] Conditional fields follow business rules

---

## Common Validation Patterns

### CNPJ Base Extraction
```javascript
// Input: "12345678000190" (14 digits)
// Output: "12345678" (8 digits)
transformation: "slice:':8'"
```

### Date Format Conversion
```javascript
// Input: "2025-01-15T10:30:00Z" (ISO 8601)
// Output: "2025/01" (YYYY/MM for CADOC)
transformation: "date_format:'%Y/%m'"
```

### Decimal Precision
```javascript
// Input: 1234.5678
// Output: "1234.57"
transformation: "floatformat:2"
```

### Conditional Fields
```javascript
// If tipoRemessa == "I": include all records
// If tipoRemessa == "S": only approved records
filter: "status == 'approved' OR tipoRemessa == 'I'"
```

---

## Output to Parent Skill

Return to `regulatory-templates` main skill:

```javascript
{
  "gate2_passed": true/false,
  "gate2_context": {
    // Merged Gate 1 + Gate 2 context
  },
  "all_uncertainties_resolved": true/false,
  "validation_rules_count": number,
  "test_success_rate": percentage,
  "next_action": "proceed_to_gate3" | "fix_validations_and_retry"
}
```

---

## Remember

1. **Test with real data** - Use actual Midaz data samples
2. **Document transformations** - Every change must be traceable
3. **Validate edge cases** - Test nulls, empty strings, extremes
4. **Cross-reference rules** - Ensure consistency across fields
5. **Keep evidence** - Store test results for audit trail