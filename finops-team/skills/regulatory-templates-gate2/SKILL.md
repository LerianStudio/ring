---
name: regulatory-templates-gate2
description: |
  Gate 2 sub-skill - validates uncertain mappings from Gate 1 and confirms
  all field specifications through testing.

trigger: |
  - Gate 1 PASSED
  - Need to validate mappings before template generation

skip_when: |
  - Gate 1 not passed → complete Gate 1 first
  - Gate 2 already passed → proceed to Gate 3

sequence:
  after: [regulatory-templates-gate1]
  before: [regulatory-templates-gate3]
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

## Foundational Principle

**Validation is the checkpoint that prevents incorrect mappings from reaching production.**

Gate 2 is the quality gate between analysis (Gate 1) and implementation (Gate 3):
- **All uncertainties resolved**: Gate 1 analysis ≠ Gate 2 validation. MEDIUM/LOW uncertainties often hide critical issues
- **100% mandatory validation**: 95% = 5% of mandatory data could be wrong in BACEN submission
- **>90% test pass rate**: Test data reveals transformation bugs, data type mismatches, edge cases
- **Confirmed mappings**: Prevents Gate 3 from generating templates based on assumptions
- **Validation rules defined**: Gate 3 needs explicit validation logic for template generation

**Skipping validation in Gate 2 means:**
- Gate 1 assumptions become Gate 3 implementation (no verification layer)
- Uncertainties propagate to production (BACEN submission failures)
- Low-confidence mappings generate incorrect templates (compliance violations)
- No test data validation = edge cases break in production

**Gate 2 is not redundant - it's the firewall between analysis and implementation.**

---

## When to Use

**Called by:** `regulatory-templates` skill after Gate 1 passes

**Purpose:** Resolve uncertainties, validate field mappings, test transformations, define validation rules

---

## NO EXCEPTIONS - Validation Requirements Are Mandatory

**Gate 2 validation requirements have ZERO exceptions.** This is the quality firewall before template generation.

### Common Pressures You Must Resist

| Pressure | Your Thought | Reality |
|----------|--------------|---------|
| **Pragmatism** | "Critical uncertainties only, skip MEDIUM/LOW" | PASS criteria: ALL uncertainties resolved. MEDIUM/LOW cascade to mandatory failures |
| **Efficiency** | "88% test pass rate is excellent" | Threshold is >90%. 12% failure = edge cases that break in production |
| **Complexity** | "Validation dashboard is redundant" | Mandatory validation = 100% required. Dashboard catches missing validations |
| **Confidence** | "Mappings look correct, skip testing" | Visual inspection ≠ test validation. Test data reveals hidden bugs |
| **Authority** | "95% mandatory validation is outstanding" | 100% is non-negotiable. 5% gap = 5% of mandatory data wrong in BACEN |
| **Frustration** | "Use workarounds for rejected fields" | FAIL criteria: Cannot find alternatives. Workarounds bypass validation |

### Validation Requirements (Non-Negotiable)

**All Uncertainties Resolved:**
- ✅ REQUIRED: Resolve ALL Gate 1 uncertainties (CRITICAL + MEDIUM + LOW)
- ❌ FORBIDDEN: "Fix critical only", "Skip low-priority items"
- Why: MEDIUM/LOW uncertainties often reveal systemic issues, cascade to mandatory failures

**Test Data Validation:**
- ✅ REQUIRED: Test pass rate >90%
- ❌ FORBIDDEN: "88% is close enough", "Skip testing, looks correct"
- Why: Test data reveals transformation bugs, data type mismatches, edge cases

**Mandatory Field Validation:**
- ✅ REQUIRED: 100% mandatory fields validated
- ❌ FORBIDDEN: "95% is outstanding", "Edge cases don't matter"
- Why: Each 1% gap = potential BACEN submission failure on mandatory data

**Alternative Mappings:**
- ✅ REQUIRED: Find alternatives for ALL rejected fields
- ❌ FORBIDDEN: "Use workarounds", "Keep original with patches"
- Why: Rejected mappings fail validation for a reason - workarounds bypass the firewall

### The Bottom Line

**Partial validation = no validation.**

Gate 2 exists to catch what Gate 1 missed. Lowering thresholds or skipping validation defeats the purpose. Every PASS criterion exists because production incidents occurred without it.

**If you're tempted to skip ANY validation, ask yourself: Am I willing to defend this shortcut during a BACEN audit?**

---

## Rationalization Table - Know the Excuses

Every rationalization below has been used to justify skipping validation. **ALL are invalid.**

| Excuse | Why It's Wrong | Correct Response |
|--------|---------------|------------------|
| "Critical uncertainties only, MEDIUM/LOW can wait" | ALL uncertainties = all 8. MEDIUM cascade to mandatory failures | Resolve ALL uncertainties |
| "88% is excellent, 2% gap is edge cases" | >90% threshold exists for production edge cases | Fix to reach >90% |
| "Validation dashboard is redundant with Gate 1" | Gate 1 = mapping, Gate 2 = validation. Different purposes | Run dashboard, ensure 100% |
| "Mappings look correct, testing is busywork" | Visual inspection missed bugs testing would catch | Run test data validation |
| "95% is outstanding, 5% isn't worth 2 hours" | 100% is binary requirement. 95% ≠ 100% | Fix to reach 100% |
| "Rejected fields can use workarounds" | Workarounds bypass validation layer | Find valid alternatives |
| "Gate 2 rarely finds issues after 50 templates" | Experience doesn't exempt from validation | Run full validation |
| "Following spirit not letter" | Validation thresholds ARE the spirit | Meet all thresholds |
| "Being pragmatic vs dogmatic" | Thresholds prevent regulatory incidents | Rigor is pragmatism |
| "Fix in next sprint if issues arise" | Regulatory submissions are final, can't patch | Fix now before Gate 3 |

### If You Find Yourself Making These Excuses

**STOP. You are rationalizing.**

The validation exists to prevent these exact thoughts from allowing errors into production. If validation seems "redundant," that's evidence it's working - catching what analysis missed.

---

## Gate 2 Process

### Check for Template-Specific Validation Rules

Check for template-specific sub-skill at `skills/regulatory-{template}/SKILL.md` containing:
- Validation rules (VR001, VR002...), business rules (BR001, BR002...)
- Format rules, test data with expected outputs

### Agent Dispatch with Gate 1 Context

**Dispatch:** `Task(subagent_type: "finops-analyzer", model: "opus")`

**CRITICAL:** ⚠️ DO NOT MAKE MCP API CALLS - use Gate 1 context ONLY

**Prompt structure:**

| Section | Content |
|---------|---------|
| Context | Full Gate 1 context (field mappings, uncertainties) |
| Uncertain Mappings | For each: field_code, current_mapping, doubt, confidence, action_needed |
| Validation Tasks | 1. Use Gate 1 mapping 2. Validate transformations 3. Check business logic 4. Confirm data types 5. Mark CONFIRMED/REJECTED |
| Output | Per field: code, resolution, alternative (if rejected), test_result |

**Output:** Field resolutions + validation rules + cross-field logic + test data

---

## Validation Process

**⚠️ All validation uses Gate 1 context ONLY - no MCP API calls.**

### 1. Field Validation

Per uncertain field: field_code, original_doubt, validation_steps (5), resolution (confirmed/rejected), transformation, test_data (input/expected/actual/status)

### 2. Validation Rules Definition

| Rule Type | Example | Formula |
|-----------|---------|---------|
| field_format | CNPJ 8 digits | `length(field_001) == 8` |
| cross_field | CPF/CNPJ check | `length(field_001) IN (11, 14)` |
| date_range | Within period | `field_020 >= period_start AND field_020 <= period_end` |

### 3. Test Results Documentation

Per test: field, test_name, input, transformation, output, expected, passed (true/false)

**Example:** Field 001 CNPJ extraction: `"12345678000190"` → `slice:':8'` → `"12345678"` ✓

---

## Capture Gate 2 Response

**Merge with Gate 1:** `validated_mappings[]`, `validation_rules[]`, `all_uncertainties_resolved`, `test_summary` (total/passed/failed/success_rate)

---

## Red Flags - STOP Immediately

If you catch yourself thinking ANY of these, STOP and re-read the NO EXCEPTIONS section:

### Partial Resolution
- "Resolve critical only, skip MEDIUM/LOW"
- "Fix most uncertainties, good enough"
- "ALL is unrealistic, most is pragmatic"

### Threshold Degradation
- "88% is close to 90%"
- "95% mandatory validation is outstanding"
- "Close enough to pass"
- "The gap isn't material"

### Skip Validation Steps
- "Validation dashboard is redundant"
- "Mappings look correct visually"
- "Testing is busywork"
- "We'll catch issues in Gate 3"

### Workaround Thinking
- "Use workarounds for rejected fields"
- "Patch it in Gate 3"
- "Fix in next sprint"
- "This is an edge case"

### Justification Language
- "Being pragmatic"
- "Following spirit not letter"
- "Outstanding is good enough"
- "Rarely finds issues anyway"
- "Experience says this is fine"

### If You See These Red Flags

1. **Acknowledge the rationalization** ("I'm trying to skip LOW uncertainties")
2. **Read the NO EXCEPTIONS section** (understand why ALL means ALL)
3. **Read the Rationalization Table** (see your exact excuse refuted)
4. **Meet the threshold completely** (100%, >90%, ALL)

**Validation thresholds are binary gates, not aspirational goals.**

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

**CRITICAL:** Execute before Gate 2 completion

**Per mandatory field, check:**
- mapped (in gate1.field_mappings)
- confidence_ok (≥80%)
- validated (in gate2.validated_mappings)
- tested (in gate2.test_results)
- transformation_ok (works correctly)

**Status:** All checks PASS → field PASS; any FAIL → field FAIL

**Gate 2 Pass Condition:** `all_mandatory_fields_valid == true` required. Coverage must be 100%.

---

## State Tracking

**PASS:** `SKILL: regulatory-templates-gate2 | GATE: 2 | STATUS: PASSED | RESOLVED: {n} uncertainties | RULES: {n} defined | TESTS: {passed}/{total} | NEXT: → Gate 3`

**FAIL:** `SKILL: regulatory-templates-gate2 | GATE: 2 | STATUS: FAILED | UNRESOLVED: {n} | TEST_FAILURES: {n} | BLOCKERS: {description}`

---

## Technical Validation Checklist

| Category | Validations |
|----------|-------------|
| Field Naming | snake_case (not camelCase), check MCP API Dog naming |
| Data Types | String (length, UTF-8), Number (precision), Date (format), Boolean, Enum |
| Transformations | CNPJ/CPF slice, date timezone, decimal format, string trim/uppercase/padding, null defaults |
| Cross-Field | Dependent consistency, date ranges, calculated fields, conditional logic |

## Common Validation Patterns

| Pattern | Input → Transformation → Output |
|---------|--------------------------------|
| CNPJ extraction | `"12345678000190"` → `slice:':8'` → `"12345678"` |
| Date format | `"2025-01-15T10:30:00Z"` → `date_format:'%Y/%m'` → `"2025/01"` |
| Decimal precision | `1234.5678` → `floatformat:2` → `"1234.57"` |
| Conditional | `tipoRemessa == "I"` → include all; `"S"` → approved only |

---

## Output to Parent Skill

Return: `gate2_passed`, `gate2_context` (merged), `all_uncertainties_resolved`, `validation_rules_count`, `test_success_rate`, `next_action` (proceed_to_gate3 | fix_validations_and_retry)