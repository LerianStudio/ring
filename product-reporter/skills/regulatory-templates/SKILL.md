---
name: regulatory-templates
description: Use when mapping Brazilian regulatory templates (BACEN CADOCs, e-Financeira, DIMP, APIX) to Midaz/Reporter - orchestrates 3-gate validation process through modular sub-skills with dynamic context passing, culminating in template file generation
---

# Regulatory Templates - Orchestrator

## Overview

**This skill orchestrates the regulatory template creation workflow through modular sub-skills, managing a 3-gate sequential validation process with dynamic context passing between gates.**

**Architecture:** Modular design with dedicated sub-skills for each phase:
- `regulatory-templates-setup` - Initial configuration and selection
- `regulatory-templates-gate1` - Regulatory compliance analysis and field mapping
- `regulatory-templates-gate2` - Technical validation of mappings
- `regulatory-templates-gate3` - Template file generation (.tpl)

**Template Specifications:** All template specifications are dynamically loaded within gates from centralized configurations. Templates are organized by regulatory authority with cascading selection:

**BACEN (Banco Central):**
- **CADOC:** 4010 (Cadastro), 4016 (Crédito), 4111 (Câmbio)
- **APIX:** 001 (Dados Cadastrais), 002 (Contas e Transações)

**RFB (Receita Federal):**
- **e-Financeira:** evtCadDeclarante, evtAberturaeFinanceira, evtFechamentoeFinanceira, evtMovOpFin, evtMovPP, evtMovOpFinAnual
- **DIMP:** v10 (Movimentação Patrimonial)

**REQUIRED AGENTS:** The sub-skills dispatch specialized agents:
- `finops-analyzer` - For Gates 1-2 and Discussion (regulatory analysis and validation)
- `finops-automation` - For Gate 3 (template file generation)

---

## Foundational Principle

**Brazilian regulatory compliance (BACEN, RFB) has zero margin for error.**

This isn't hyperbole:
- BACEN penalties for incorrect submissions: R$10,000 - R$500,000 + license sanctions
- RFB penalties for e-Financeira errors: Criminal liability for false declarations
- Template errors are discovered during audits, often months after submission
- "We'll fix it later" is impossible - submissions are final

**This workflow exists because:**
1. Human confidence without validation = optimism bias (proven by TDD research)
2. "Mostly correct" regulatory submissions = rejected submissions + penalties
3. Shortcuts under pressure = exactly when errors are most likely
4. Each gate prevents specific failure modes discovered in production

**The 3-gate architecture is not bureaucracy - it's risk management.**

Every section that seems "rigid" or "redundant" exists because someone, somewhere, cut that corner and caused a regulatory incident.

**Follow this workflow exactly. Your professional reputation depends on it.**

---

## When to Use

**Use this skill when:**
- User requests mapping and creation of Brazilian regulatory templates
- BACEN CADOCs (4010, 4016, 4111), e-Financeira, DIMP, APIX
- Full automation from analysis to template creation

**Symptoms triggering this skill:**
- "Create CADOC 4010 template"
- "Map e-Financeira to Midaz and set up in Reporter"
- "Automate DIMP template creation"

**When NOT to use:**
- Non-Brazilian regulations
- Analysis-only without template creation
- Templates already exist and just need updates

---

## NO EXCEPTIONS - Read This First

**This workflow has ZERO exceptions.** Brazilian regulatory compliance (BACEN, RFB) has zero margin for error.

### Common Pressures You Must Resist

| Pressure | Your Thought | Reality |
|----------|--------------|---------|
| **Deadline** | "Skip Gate 2, we're confident" | Gate 1 analysis ≠ Gate 2 validation. Confidence without verification = optimism bias |
| **Authority** | "Manager says skip it" | Manager authority doesn't override regulatory requirements. Workflow protects both of you |
| **Fatigue** | "Manual creation is faster" | Fatigue makes errors MORE likely. Automation doesn't get tired |
| **Economic** | "Optional fields have no fines" | Template is reusable. Skipping fields = technical debt + future rework |
| **Sunk Cost** | "Reuse existing template" | 70% overlap = 30% different. Regulatory work doesn't tolerate "mostly correct" |
| **Pragmatism** | "Setup is ceremony" | Setup initializes context. Skipping = silent assumptions |
| **Efficiency** | "Fix critical only" | Gate 2 PASS criteria: ALL uncertainties resolved, not just critical |

### Emergency Scenarios

**"Production is down, need template NOW"**
→ Production issues don't override regulatory compliance. Fix production differently.

**"CEO directive to ship immediately"**
→ CEO authority doesn't override BACEN requirements. Escalate risk in writing.

**"Client contract requires delivery today"**
→ Contract penalties < regulatory penalties. Renegotiate delivery, don't skip validation.

**"Tool/agent is unavailable"**
→ Wait for tools or escalate. Manual workarounds bypass validation layers.

### The Bottom Line

**Shortcuts in regulatory templates = career-ending mistakes.**

BACEN and RFB submissions are final. You cannot "patch next sprint." Every gate exists because regulatory compliance has zero tolerance for "mostly correct."

**If you're tempted to skip ANY part of this workflow, stop and ask yourself: Am I willing to stake my professional reputation on this shortcut?**

---

## Rationalization Table - Know the Excuses

Every rationalization below has been used to justify skipping workflow steps. **ALL are invalid.**

| Excuse | Why It's Wrong | Correct Response |
|--------|---------------|------------------|
| "Gate 2 is redundant when Gate 1 is complete" | Gate 1 = analysis, Gate 2 = validation. Different purposes. Validation catches analysis errors | Run Gate 2 completely |
| "Manual creation is pragmatic" | Manual bypasses validation layer. Gate 3 agent validates against Gate 2 report | Use automation agent |
| "Optional fields don't affect compliance" | Overall confidence includes all fields. Skipping 36% fails PASS criteria | Map all fields |
| "70% overlap means we can copy" | 30% difference contains critical regulatory fields. Similarity ≠ simplicity | Run full workflow |
| "Setup is bureaucratic ceremony" | Setup initializes context for Gates 1-3. Skipping creates silent assumptions | Run setup completely |
| "Fix critical issues only" | Gate 2 PASS: ALL uncertainties resolved. Medium/low issues cascade to mandatory failures | Resolve all uncertainties |
| "We're experienced, simplified workflow" | Experience doesn't exempt you from validation. Regulatory work requires process | Follow full workflow |
| "Following spirit not letter" | Regulatory compliance requires BOTH. Skipping steps violates spirit AND letter | Process IS the spirit |
| "Being pragmatic vs dogmatic" | Process exists because pragmatism failed. Brazilian regulatory penalties are severe | Rigor is pragmatism |
| "Tool is too rigid for real-world" | Rigidity prevents errors. Real-world includes regulatory audits and penalties | Rigidity is protection |

### If You Find Yourself Making These Excuses

**STOP. You are rationalizing.**

The workflow exists specifically to prevent these exact thoughts from leading to errors. If the workflow seems "too rigid," that's evidence it's working - preventing you from shortcuts that seem reasonable but create risk.

---

## Workflow Overview

```
┌─────────────────────┐
│  ORCHESTRATOR       │
│  (this skill)       │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐     ┌──────────────────────────┐
│ SETUP SUB-SKILL     │────▶│ • Template Selection     │
│                     │     │ • Context Initialization  │
└──────┬──────────────┘     └──────────────────────────┘
       │
       ▼ context
┌─────────────────────┐     ┌──────────────────────────┐
│ GATE 1 SUB-SKILL    │────▶│ • Regulatory Analysis    │
│                     │     │ • Field Mapping          │
│                     │     │ • Identify Data Sources  │
└──────┬──────────────┘     └──────────────────────────┘
       │
       ▼ context + gate1
┌─────────────────────┐     ┌──────────────────────────┐
│ GATE 2 SUB-SKILL    │────▶│ • Validate Mappings      │
│                     │     │ • Test Transformations   │
│                     │     │ • Define Validation Rules │
└──────┬──────────────┘     │ • Resolve Uncertainties   │
       │                    └──────────────────────────┘
       ▼ context + gate1 + gate2
┌─────────────────────┐     ┌──────────────────────────┐
│ GATE 3 SUB-SKILL    │────▶│ • Generate Template File │
│                     │     │ • Apply Transformations  │
│                     │     │ • Create .tpl File       │
└──────┬──────────────┘     │ • Django/Jinja2 Format   │
       │                    └──────────────────────────┘
       ▼
┌─────────────────────┐
│ TEMPLATE CREATED ✅  │
│ Ready for BACEN     │
└─────────────────────┘
```

---

## Orchestration Process

### Step 1: Initialize TodoWrite Tasks

```javascript
TodoWrite({
  todos: [
    {
      content: "Select regulatory template",
      status: "in_progress",
      activeForm: "Running setup configuration"
    },
    {
      content: "Gate 1: Regulatory compliance analysis and field mapping",
      status: "pending",
      activeForm: "Running Gate 1: Regulatory analysis"
    },
    {
      content: "Gate 2: Technical validation of field mappings",
      status: "pending",
      activeForm: "Running Gate 2: Technical validation"
    },
    {
      content: "Gate 3: Template file generation",
      status: "pending",
      activeForm: "Running Gate 3: Template generation"
    },
    {
      content: "Verify template creation and functionality",
      status: "pending",
      activeForm: "Verifying template"
    }
  ]
})
```

### Step 2: Execute Setup Sub-skill

**Use the Skill tool to execute the setup sub-skill:**

1. Call the Skill tool with:
   - `skill`: "regulatory-templates-setup"

2. Capture the returned context from the setup skill

3. Update TodoWrite to mark setup as completed and Gate 1 as in_progress

4. **Note:** Context is maintained in memory only - no files are created

### Step 3: Execute Gate 1 Sub-skill

**Use the Skill tool to execute Gate 1:**

1. Call the Skill tool with:
   - `skill`: "regulatory-templates-gate1"

2. The Gate 1 skill will dispatch the finops-analyzer agent to:
   - **READ the regulatory specification** from `/docs/regulatory/templates/`
   - **ANALYZE the specification requirements**
   - **GENERATE a SPECIFICATION REPORT**

3. Capture the report output containing:
   - Template structure and format
   - Mandatory and optional fields
   - Transformation rules
   - Validation requirements
   - Business rules
   - Compliance checklist

4. Check if gate1_passed is true:
   - If PASSED: Store the specification report in context, update TodoWrite, proceed to Gate 2
   - If FAILED: Handle Gate 1 failure, address critical gaps before retry

### Step 4: Execute Gate 2 Sub-skill

**Use the Skill tool to execute Gate 2:**

1. Call the Skill tool with:
   - `skill`: "regulatory-templates-gate2"
   - Context includes the **specification report** from Gate 1

2. The Gate 2 skill will dispatch the finops-analyzer agent to:
   - **VALIDATE the specification report completeness**
   - **RESOLVE any uncertainties or gaps**
   - **CONFIRM all transformation rules**
   - **FINALIZE the specification report**

3. Check if gate2_passed is true:
   - **CRITICAL:** Verify mandatory fields validation = 100%
   - If validation < 100%: FAIL with mandatory fields incomplete error
   - If PASSED: Store the **FINALIZED REPORT** in context, update TodoWrite, proceed to Gate 3
   - If FAILED: Handle unresolved uncertainties

### Step 5: Execute Gate 3 Sub-skill

**Use the Skill tool to execute Gate 3:**

1. Call the Skill tool with:
   - `skill`: "regulatory-templates-gate3"
   - Context includes the **FINALIZED SPECIFICATION REPORT** from Gate 2

2. The Gate 3 skill will dispatch the finops-automation agent (using sonnet model) to:
   - **USE THE SPECIFICATION REPORT as input**
   - **GENERATE the .tpl template based on report**
   - **VALIDATE template against report requirements**
   - **CREATE production-ready template file**

3. Check if gate3_passed is true:
   - If PASSED: Template created successfully, update TodoWrite, verify output
   - If FAILED: Handle Gate 3 failure with retry logic (401 = token refresh, 500/503 = wait and retry)

---

## Sub-skill Execution Pattern

**Each sub-skill is executed using the Skill tool:**

1. **To execute a sub-skill:**
   - Use the Skill tool with parameter `skill: "skill-name"`
   - The sub-skill will handle agent dispatch internally

2. **Example invocations:**
   ```
   Skill tool with skill: "regulatory-templates-setup"
   Skill tool with skill: "regulatory-templates-gate1"
   Skill tool with skill: "regulatory-templates-gate2"
   Skill tool with skill: "regulatory-templates-gate3"
   ```

3. **Context flows automatically** through the orchestrator's memory

---

## Context Management - Report-Driven Flow

### Context Structure Evolution

**After Setup:**
```javascript
{
  template_selected: "CADOC 4010",
  template_code: "4010",
  authority: "BACEN",
  deadline: "2025-12-31"
}
```

**After Gate 1 - SPECIFICATION REPORT GENERATED:**
```javascript
{
  // ... setup context +
  specification_report: {
    template_info: {
      name: "CADOC 4010",
      format: "XML",
      version: "1.0"
    },
    fields: {
      mandatory: [/* field definitions */],
      optional: [/* field definitions */]
    },
    transformations: [/* transformation rules */],
    validations: [/* validation rules */],
    structure: {/* document structure */}
  }
}
```

**After Gate 2 - FINALIZED REPORT:**
```javascript
{
  // ... setup + gate1 context +
  finalized_report: {
    // Enhanced specification report with:
    validated: true,
    uncertainties_resolved: true,
    all_fields_mapped: true,
    transformations_confirmed: true,
    ready_for_implementation: true
  }
}
```

**After Gate 3 - TEMPLATE GENERATED:**
```javascript
{
  // ... setup + gate1 + gate2 context +
  gate3: {
    template_file: {
      filename: "cadoc4010_20251119_preview.tpl",
      path: "/path/to/file",
      generated_from_report: true,
      validation_passed: true
    },
    ready_for_use: true,
    report_compliance: "100%"
  }
}
```

---

## Template Specifications Management

### How Gates Load Template Specifications

**Each gate dynamically loads template specifications from centralized configurations:**

```javascript
// Pattern used by all gates
const templateCode = context.template_selected.split(' ')[1]; // e.g., "4010"
const templateName = context.template_selected.toLowerCase().replace(' ', ''); // e.g., "cadoc4010"

// Load specifications from centralized config
const templateSpecs = loadTemplateSpecifications(templateName);
// Gate 1: Use field mappings from specifications
// Gate 2: Apply validation rules from specifications
// Gate 3: Use template structure from specifications
```

### Benefits of Centralized Specifications

1. **Simplicity:** Single source of truth for all templates
2. **Maintainability:** Update specs without changing gate logic
3. **Scalability:** Add new templates by adding specifications only
4. **Consistency:** All templates follow same processing logic
5. **Evolution:** Template updates require only spec changes

### Adding New Template Support

When adding support for a new regulatory template:

1. **Add template specifications** to centralized configuration
2. **No new skills required** - Gates handle all templates
3. **Content:** Field mappings, validation rules, format specifications
4. **Testing:** Run through 3-gate process with new specs

---

## State Tracking

**Output state tracking comment after EACH sub-skill execution:**

```
SKILL: regulatory-templates (orchestrator)
PHASE: {current_phase}
TEMPLATE: {context.template_selected}
GATES_COMPLETED: {completed_gates}/3
CURRENT: {current_action}
NEXT: {next_action}
EVIDENCE: {last_result}
BLOCKERS: {blockers or "None"}
```

---

## Error Handling

### Gate Failure Handling

```javascript
function handleGateFailure(gateNumber, issues) {
  // Log failure
  console.log(`Gate ${gateNumber} FAILED`);

  // Determine if retriable
  if (isRetriable(issues)) {
    // Fix issues
    fixIssues(issues);

    // Retry gate
    retryGate(gateNumber);
  } else {
    // Escalate to user
    askUserForHelp(gateNumber, issues);
  }
}
```

### Gate 3 Special Retry Logic

```javascript
function handleGate3Failure(result) {
  if (result.error_code === 401) {
    // Token expired - refresh and retry
    refreshToken();
    retryGate3();
  } else if ([500, 503].includes(result.error_code)) {
    // Server error - wait and retry
    wait(120000); // 2 minutes
    retryGate3();
  } else {
    // Non-retriable error
    escalateToUser(result.error);
  }
}
```

---

## Success Output

```markdown
✅ TEMPLATE CREATED SUCCESSFULLY

Template: {context.template_name}
Template ID: {gate3_result.template_id}
Fields Configured: {gate3_result.fields_configured}/{context.total_fields}
Validation Rules: {gate3_result.validation_rules_applied}
Test Status: PASSED ✅

Gates Summary:
- Setup: ✅ Template selected
- Gate 1: ✅ Regulatory analysis complete
- Gate 2: ✅ Technical validation complete
- Gate 3: ✅ Template created and verified

Ready for production use!
```

---

## Coordination Rules

1. **Sequential Execution:** Gates must execute in order (1→2→3)
2. **Context Accumulation:** Each gate adds to context, never overwrites
3. **Failure Stops Progress:** Cannot proceed to next gate if current fails
4. **State Tracking Required:** Output state after each sub-skill
5. **TodoWrite Updates:** Mark complete immediately after each phase
6. **NO INTERMEDIATE FILES:** Context flows in memory only - no .md files between gates
7. **SINGLE OUTPUT FILE:** Only create final .tpl template file in Gate 3

---

## Red Flags - STOP Immediately

If you catch yourself thinking ANY of these, STOP and re-read the NO EXCEPTIONS section:

### Skip Patterns
- "Skip Gate X" (any variation)
- "Run Gates out of order"
- "Parallel gates for speed"
- "Simplified workflow for experienced teams"
- "Emergency override protocol"

### Manual Workarounds
- "Create template manually"
- "Copy existing template"
- "Manual validation is sufficient"
- "I'll verify it myself"

### Partial Compliance
- "Fix critical only"
- "Map mandatory fields only"
- "Skip setup, we already know"
- "Lower pass threshold"

### Justification Language
- "Being pragmatic"
- "Following spirit not letter"
- "Real-world flexibility"
- "Process over outcome"
- "Dogmatic adherence"
- "We're confident"
- "Manager approved"

### If You See These Red Flags

1. **Acknowledge the rationalization** ("I'm trying to skip Gate 2")
2. **Read the NO EXCEPTIONS section** (understand why it's required)
3. **Follow the workflow completely** (no modifications)
4. **Document the pressure** (for future skill improvement)

**The workflow is non-negotiable. Regulatory compliance doesn't have "reasonable exceptions."**

---

## Benefits of Modular Architecture

1. **Maintainability:** Each sub-skill can be updated independently
2. **Reusability:** Sub-skills can be used in other workflows
3. **Testing:** Each gate can be tested in isolation
4. **Debugging:** Easier to identify which gate failed
5. **Scalability:** New gates can be added as sub-skills

---

## Common Patterns

### Calling Sub-skills

**Use the Skill tool to invoke sub-skills:**
```
1. Call Skill tool with skill: "regulatory-templates-gate1"
2. Sub-skill will handle agent dispatch internally
3. Context is maintained in orchestrator memory
```

### Checking Gate Results

**After each gate execution:**
- If gate_passed = true: Merge results into context, proceed to next gate
- If gate_passed = false: Handle failure, address issues before retry

### Updating Progress

**Use TodoWrite tool after each gate:**
- Mark current gate as "completed"
- Mark next gate as "in_progress"
- Keep user informed of progress

---

## Remember

1. **This is an orchestrator** - Delegates work to sub-skills
2. **Context flows forward** - Each gate builds on previous
3. **Sub-skills are independent** - Can be tested/updated separately
4. **State tracking is mandatory** - After each sub-skill execution
5. **All behavior preserved** - Same functionality, modular structure

---

## Quick Reference

| Sub-skill | Purpose | Input | Output |
|-----------|---------|-------|--------|
| regulatory-templates-setup | Initial configuration | User selections | Base context |
| regulatory-templates-gate1 | Regulatory analysis | Base context | Field mappings, uncertainties |
| regulatory-templates-gate2 | Technical validation | Context + Gate 1 | Validated mappings, rules |
| regulatory-templates-gate3 | API readiness | Context + Gates 1-2 | Authentication, endpoints |
| regulatory-templates-gate4 | Template creation | Complete context | Template ID, verification |

---

## Master Assertion Checklist

Before executing workflow:
- [ ] All sub-skills exist in skills directory
- [ ] Agents finops-analyzer and finops-automation available
- [ ] User has selected template type
- [ ] Environment URLs configured

After each gate:
- [ ] Gate result captured
- [ ] Context updated with gate output
- [ ] TodoWrite updated
- [ ] State tracking comment output
- [ ] Next action determined

After workflow completion:
- [ ] Template created successfully
- [ ] Template ID captured
- [ ] Verification passed
- [ ] User notified with details