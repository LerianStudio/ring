---
name: regulatory-templates-gate3
description: |
  Gate 3 sub-skill - generates complete .tpl template file with all validated
  mappings from Gates 1-2.

trigger: |
  - Gate 2 PASSED
  - Ready to generate production template file

skip_when: |
  - Gate 2 not passed → complete Gate 2 first
  - Template already generated → verify or regenerate

sequence:
  after: [regulatory-templates-gate2]
---

# Regulatory Templates - Gate 3: Template File Generation

## Overview

**This sub-skill executes Gate 3 of the regulatory template workflow: generating the complete .tpl template file with all validated mappings and transformations from Gates 1-2.**

**Parent skill:** `regulatory-templates`

**Prerequisites:**
- Gate 1 PASSED (field mappings complete)
- Gate 2 PASSED (validations confirmed)
- Context object with Gates 1-2 results

**Output:** Generated .tpl template file ready for use

---

## Foundational Principle

**Template generation is the final quality gate before production deployment.**

Gate 3 transforms validated specifications into production artifacts:
- **Agent-based generation**: finops-automation applies validated mappings consistently - manual creation introduces human error
- **Two-file separation**: Clean .tpl (production code) + .tpl.docs (documentation) - inline comments bloat production artifacts
- **All mandatory fields**: 100% inclusion required - 95% = 5% of regulatory data missing in BACEN submission
- **Correct transformations**: Django filters applied per Gates 1-2 validation - errors here multiply in every submission
- **Valid syntax**: Template must execute without errors - syntax failures block Reporter deployment

**Skipping requirements in Gate 3 means:**
- Manual creation bypasses systematic validation (fatigue errors, missed transformations)
- Single-file output mixes production code with documentation (maintenance nightmare)
- Missing fields cause BACEN submission failures (compliance violations)
- Invalid syntax blocks deployment (emergency fixes under pressure)

**Gate 3 is not automation for convenience - it's the final verification layer.**

---

## When to Use

**Called by:** `regulatory-templates` skill after Gate 2 passes

**Purpose:** Create the final Django/Jinja2 template file with all field mappings, transformations, and validation logic

---

## NO EXCEPTIONS - Generation Requirements Are Mandatory

**Gate 3 template generation requirements have ZERO exceptions.** This is the final artifact that goes to production.

### Common Pressures You Must Resist

| Pressure | Your Thought | Reality |
|----------|--------------|---------|
| **Fatigue** | "Manual creation is faster when tired" | Fatigue increases error rate. Agent doesn't get tired. 10 min manual < 15 min validated |
| **Simplicity** | "One file easier than two" | Production artifacts must be clean. Documentation bloats .tpl files |
| **Confidence** | "45/47 fields works for 99% cases" | 100% mandatory required. 95% = BACEN submission failures on edge cases |
| **Experience** | "I can optimize agent output" | Agent applies validated mappings systematically. Manual edits introduce drift |

### Generation Requirements (Non-Negotiable)

**Agent-Based Generation:**
- ✅ REQUIRED: Use finops-automation agent for all template generation
- ❌ FORBIDDEN: Manual .tpl creation, editing agent output
- Why: Agent applies Gates 1-2 validations consistently, prevents fatigue errors

**Two-File Output:**
- ✅ REQUIRED: Generate .tpl (clean code) + .tpl.docs (documentation)
- ❌ FORBIDDEN: Single file with inline comments, merged documentation
- Why: Production artifacts stay clean, documentation separate for maintenance

**All Mandatory Fields:**
- ✅ REQUIRED: 100% mandatory fields in template (47/47)
- ❌ FORBIDDEN: "45/47 is good enough", placeholder comments for missing
- Why: Each missing field = potential regulatory compliance failure

**Validated Output:**
- ✅ REQUIRED: Use exact agent output without manual "improvements"
- ❌ FORBIDDEN: Refactoring for optimization, rewriting for clarity
- Why: Agent output validated against Gates 1-2, edits create drift

### The Bottom Line

**Manual shortcuts in final artifact = production regulatory failures.**

Gate 3 is the last checkpoint. All previous gates' work culminates here. Bypassing agent generation defeats the entire 3-gate validation process.

**If you're tempted to skip agent generation, ask yourself: Am I willing to debug production BACEN submission failures from manual template errors?**

---

## Rationalization Table - Know the Excuses

| Excuse | Why It's Wrong | Correct Response |
|--------|---------------|------------------|
| "Manual creation same output, faster" | Agent validates systematically, manual risks errors | Use agent completely |
| "10 min vs 15 min, I'm tired" | Fatigue increases manual error rate | Let agent work |
| "Two files is over-engineering" | Production code must be clean, no doc bloat | Generate TWO files |
| "One file easier to maintain" | Mixing code and docs creates maintenance burden | Separate concerns |
| "45/47 works for 99% cases" | 100% mandatory required, edge cases matter | Include ALL fields |
| "I can optimize agent output" | Optimization creates drift from validated spec | Use exact output |
| "Agent code is verbose" | Verbose but validated > concise but wrong | Trust validation |
| "Skip for now, add fields later" | Template is final artifact, can't patch BACEN | Complete now |

### If You Find Yourself Making These Excuses

**STOP. You are rationalizing.**

Gate 3 is where 5+ hours of Gates 1-2 work becomes a production artifact. Shortcuts here waste all previous validation effort.

---

## Gate 3 Process

### Agent Dispatch

**Dispatch:** `Task(subagent_type: "finops-automation", model: "sonnet")`

**Prompt includes:**

| Section | Content |
|---------|---------|
| Context | template_name, template_code, authority, field_mappings.length, validation_rules.length |
| Field Mappings | Per field: code, name, source, transformation, confidence%, required |
| Validation Rules | Per rule: rule_id, description, formula |
| Tasks | 1. Generate clean .tpl 2. Include all mappings 3. Apply Django syntax 4. Structure per regulatory spec 5. Conditional logic 6. Minimal comments |

**CRITICAL - Naming Convention:**
- ALL fields in snake_case (already converted by Gate 1)
- Examples: `legal_document`, `operation_route`, `opening_date`, `natural_person`

**CRITICAL - Data Sources:**
- `midaz_onboarding`: organization, account (cadastral)
- `midaz_transaction`: operation_route, balance, operation (transactional)
- Format: `{{ data_source.entity.index.field|filter }}`
- Example: `{{ midaz_onboarding.organization.0.legal_document|slice:':8' }}`

---

## Expected Output

| File | Content |
|------|---------|
| `{code}_preview.tpl` | Clean Django/Jinja2 template code, production-ready, minimal comments |
| `{code}_preview.tpl.docs` | Full documentation: field mappings, transformations, troubleshooting |

---

## Red Flags - STOP Immediately

If you catch yourself thinking ANY of these, STOP and re-read the NO EXCEPTIONS section:

### Manual Shortcuts
- "Create .tpl manually, faster"
- "Edit agent output for optimization"
- "I can write cleaner code"
- "Agent is too verbose"

### File Structure Violations
- "One file easier to maintain"
- "Inline comments instead of .docs"
- "Merge documentation into .tpl"
- "Two files is over-engineering"

### Partial Completion
- "45/47 fields works for most cases"
- "Skip edge case fields"
- "Add missing fields later"
- "99% is good enough"

### Justification Language
- "Being pragmatic"
- "I'm too tired for agent wait"
- "Manual is faster"
- "Over-engineering"
- "Optimization is better"

### If You See These Red Flags

1. **Acknowledge rationalization** ("I'm trying to skip agent generation")
2. **Read NO EXCEPTIONS** (understand why agent is required)
3. **Read Rationalization Table** (see excuse refuted)
4. **Use agent completely** (no manual shortcuts)

**Template generation shortcuts waste all Gates 1-2 validation work.**

---

## Pass/Fail Criteria

### PASS Criteria
- ✅ Template file generated successfully
- ✅ All mandatory fields included
- ✅ Transformations correctly applied
- ✅ Django/Jinja2 syntax valid
- ✅ Output format matches specification
- ✅ File saved with correct extension

### FAIL Criteria
- ❌ Missing mandatory fields
- ❌ Invalid template syntax
- ❌ Transformation errors
- ❌ File generation failed

---

## State Tracking

**PASS:** `SKILL: regulatory-templates-gate3 | GATE: 3 | STATUS: PASSED ✅ | FILE: {filename} | FIELDS: {n}/{total} | NEXT: Template ready for use`

**FAIL:** `SKILL: regulatory-templates-gate3 | GATE: 3 | STATUS: FAILED ❌ | ERROR: {error} | BLOCKERS: {description}`

---

## Output to Parent Skill

Return: `gate3_passed`, `template_file` (filename, path, size_bytes, fields_included), `ready_for_use`, `next_action` (template_complete | fix_and_regenerate)

---

## Common Template Patterns

| Pattern | Syntax |
|---------|--------|
| Field access | `{{ organization.legal_document }}` (snake_case) |
| Collection loop | `{% for item in collection %}{{ item.field }}{% endfor %}` |
| Conditional | `{% if condition %}<field>{{ value }}</field>{% endif %}` |
| Nested | `{{ parent.child.grandchild }}` |
| Filter chain | `{{ value\|slice:':8'\|upper }}` |

**Remember:** Use exact Gate 1 paths, snake_case only, apply Gate 2 transformations, follow regulatory format exactly.