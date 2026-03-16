---
name: regulatory-templates
description: |
  5-stage regulatory template orchestrator - manages setup, Gate 1 (analysis + auto-save),
  Gate 2 (validation), Gate 3 (generation), optional Test Gate, optional Contribution Gate.
  Supports any regulatory template (BACEN, RFB, CVM, SUSEP, COAF, or other).
metadata:
  dependencies:
  - ring:regulatory-templates-setup
  - ring:regulatory-templates-gate1
  - ring:regulatory-templates-gate2
  - ring:regulatory-templates-gate3
  - ring:finops-analyzer
  - ring:finops-automation
  role: orchestrator
  sequence:
    before:
    - regulatory-templates-setup
  skip_when: |
    - Non-Brazilian regulations → not applicable
    - Analysis-only without template → use finops-analyzer directly
    - Template already exists, just needs updates → modify directly
  trigger: |
    - Creating BACEN CADOCs (4010, 4016, 4111, or any other)
    - Mapping e-Financeira, DIMP, APIX templates
    - Full automation from analysis to template creation
    - Creating any new regulatory template not yet in registry
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
- "Map e-Financeira to Core one and set up in Reporter"
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

**Flow:** Setup → Gate 1 → Gate 2 → Gate 3 → Template Created ✅

| Phase | Sub-skill | Purpose | Agent |
|-------|-----------|---------|-------|
| Setup | `regulatory-templates-setup` | Template selection, context init | — |
| Gate 1 | `regulatory-templates-gate1` | Regulatory analysis, field mapping | `finops-analyzer` |
| Gate 2 | `regulatory-templates-gate2` | Validate mappings, test transformations | `finops-analyzer` |
| Gate 3 | `regulatory-templates-gate3` | Generate .tpl template file | `finops-automation` |

---

## Orchestration Process

**Step 1:** Initialize TodoWrite with tasks (setup, gate1, gate2, gate3, + optional: gate_test, contribution)

**Steps 2–5:** Execute mandatory gates using Skill tool:

| Step | Skill | On PASS | On FAIL |
|------|-------|---------|---------|
| 2 | `regulatory-templates-setup` | Store context → Gate 1 | Fix selection issues |
| 3 | `regulatory-templates-gate1` | Store spec report + auto-saved dict → Gate 2 | Address critical gaps, retry |
| 4 | `regulatory-templates-gate2` | Store finalized report → Gate 3 | Resolve uncertainties, retry |
| 5 | `regulatory-templates-gate3` | Template complete → Gate Teste (if configured) | 401=refresh token, 500/503=wait+retry |

**Steps 6–7 (optional):** Execute only when conditions are met:

| Step | Gate | Condition | On PASS | On FAIL |
|------|------|-----------|---------|---------|
| 6 | Gate Teste | `reporter_dev_url` set AND user opts in | Mark `gate_test_passed: true` → Contribution Gate | Feedback → retry Gate 3 |
| 7 | Contribution Gate | `is_new_template: true` AND user opts in | PR opened, URL reported | Provide manual instructions |

**Context flows in memory** - no intermediate files created

---

## Gate Teste — Validação no Ambiente Dev (Opcional)

**Triggered when:** `reporter_dev_url` is set in context (configured during Setup)

**Process:**
1. Check if `reporter_dev_url` is available in context
2. If available → Ask: "Quer validar o template gerado no ambiente de desenvolvimento agora?"
3. **If YES:**
   - Submit the generated `.tpl` to `reporter_dev_url` with available test data
   - Display the rendered output to the user
   - Ask: "O output está correto? Deseja fazer algum ajuste?"
   - If adjustments needed: return feedback to Gate 3 with specific corrections → re-run Gate 3 → re-run Gate Teste
   - If correct: mark `gate_test_passed: true`, proceed
4. **If NO or `reporter_dev_url` not configured:** mark `gate_test_passed: skipped`, proceed

**Output context addition:** `gate_test: { passed: true|false|skipped }`

---

## Contribution Gate — PR para o Ring (Opcional)

**Triggered when:** `is_new_template: true` is in context (set during Setup when user selects "Novo template")

**Process:**
1. Ask: "Quer contribuir este template de volta para a comunidade Ring? Isso abre um PR público no repositório LerianStudio/ring."
2. **If NO:**
   - Inform: "Template e dicionário salvos localmente. Disponíveis para uso imediato."
   - Mark `contribution: skipped`
3. **If YES:**
   - Verify user has GitHub token configured (via environment or user input)
   - Fork `LerianStudio/ring` to user's GitHub account (if not already forked)
   - Create branch: `feat/regulatory-template-{template_code_lower}` (ex: `feat/regulatory-template-cadoc4030`)
   - Prepare the following files locally:
     - New dictionary YAML: `finops-team/docs/regulatory/templates/{authority}/{category}/{code}/dictionary.yaml`
     - Updated `registry.yaml` with new template entry
     - Generated `.tpl` file in appropriate directory
   - **Commit signing is required.** A GitHub PAT token authenticates API calls but does NOT produce a cryptographically signed commit. The user must sign the commit themselves using one of:
     - GPG key: `git commit -S -m "..."`
     - SSH signing key (configured in `~/.gitconfig` with `gpg.format=ssh`)
   - Provide the user with the exact commit command:
     ```bash
     git checkout -b feat/regulatory-template-{template_code_lower}
     # Files are ready at the paths listed above
     git add finops-team/docs/regulatory/templates/{authority}/{category}/{code}/dictionary.yaml
     git add finops-team/docs/regulatory/templates/registry.yaml
     git add finops-team/docs/regulatory/templates/{authority}/{category}/{code}/*.tpl
     git commit -S -m "feat(finops): add {Template Name} regulatory template"
     gh pr create --title "feat(finops): add {Template Name} regulatory template" \
       --body "..."
     ```
   - Open PR to `LerianStudio/ring` with auto-generated PR body:
     ```
     feat(finops): add {Template Name} regulatory template

     - Authority: {BACEN|RFB|other}
     - Format: {XML|TXT|HTML}
     - Fields mapped: {N} ({HIGH}H / {MEDIUM}M / {LOW}L confidence)
     - Dictionary: auto-generated via ring:regulatory-templates workflow

     Contributed via ring:finops-team regulatory-templates workflow
     ```
   - Report PR URL: "✅ PR aberto: {url}"
   - Mark `contribution: { pr_url: "{url}", status: "open" }`
4. **If user does not have GPG/SSH signing configured:**
   - Explain: "Commit assinado requer chave GPG ou SSH configurada no git. Veja: https://docs.github.com/authentication/managing-commit-signature-verification"
   - Provide alternative: open a draft PR without signed commit and mark it for manual signing

**🔴 CRITICAL — Commit signing:**
- A GitHub PAT authenticates API calls but does NOT cryptographically sign commits
- Signed commits REQUIRE the user's GPG key (`git commit -S`) or SSH signing key
- **NEVER use agent credentials** for commits
- The contribution must be attributed to and signed by the human contributor
- If user cannot sign → provide draft PR instructions and explain signing requirement

**BLOCKER:** If fork or branch creation fails → provide manual git instructions. Do NOT attempt workarounds using agent credentials.

---

## Context Management - Report-Driven Flow

**Context accumulates through gates (each adds, never overwrites):**

| After | Context Additions |
|-------|-------------------|
| Setup | `template_selected`, `template_code`, `authority`, `deadline` |
| Gate 1 | `specification_report` (template_info, fields, transformations, validations, structure) |
| Gate 2 | `finalized_report` (validated, uncertainties_resolved, all_fields_mapped, ready_for_implementation) |
| Gate 3 | `gate3` (template_file, filename, path, ready_for_use, report_compliance: 100%) |

---

## Template Specifications Management

- Gates load specs dynamically from centralized config
- Add new templates by adding specifications only (no new skills)
- Pattern: `loadTemplateSpecifications(templateName)` for field mappings, validation rules, format specs

---

## State Tracking

Output after EACH sub-skill: `SKILL: regulatory-templates | PHASE: {phase} | TEMPLATE: {template} | GATES: {n}/3 | CURRENT: {action} | NEXT: {next} | BLOCKERS: {blockers}`

---

## Error Handling

| Error | Action |
|-------|--------|
| Gate failure (retriable) | Fix issues → retry gate |
| Gate failure (non-retriable) | Escalate to user |
| Gate 3: 401 | Refresh token → retry |
| Gate 3: 500/503 | Wait 2 min → retry |

---

## Coordination Rules

1. Sequential execution (1→2→3)
2. Context accumulates (never overwrites)
3. Failure stops progress
4. State tracking after each sub-skill
5. TodoWrite updates immediately
6. NO intermediate files (memory only)
7. SINGLE output file (.tpl in Gate 3)

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

---

## Severity Calibration

**MUST classify workflow issues using these severity levels:**

| Severity | Definition | Examples | Workflow Impact |
|----------|------------|----------|-----------------|
| **CRITICAL** | BLOCKS workflow completion OR risks regulatory violation | - Gate fails with no recovery path<br>- Context lost between gates<br>- Agent unavailable<br>- Mandatory field unmapped after all gates | **HARD BLOCK** - Cannot produce compliant template |
| **HIGH** | REQUIRES intervention for workflow to succeed | - Gate 1 returns INCOMPLETE<br>- Gate 2 fails validation threshold<br>- Gate 3 syntax errors<br>- Context incomplete for next gate | **MUST resolve** - retry gate or escalate |
| **MEDIUM** | SHOULD address for optimal workflow | - Low confidence mappings passing gates<br>- Optional fields skipped<br>- Minor validation warnings<br>- Suboptimal gate performance | **SHOULD address** - document if deferred |
| **LOW** | Minor improvements possible | - State tracking verbosity<br>- Context field ordering<br>- Documentation improvements | **OPTIONAL** - note in completion report |

**Classification Rules:**

**CRITICAL = ANY of:**
- Any gate fails with non-retriable error
- finops-analyzer or finops-automation agents unavailable
- Template cannot be produced after all retry attempts
- Regulatory mandatory field missing from final template

**HIGH = ANY of:**
- Gate returns INCOMPLETE or FAILED (retriable)
- Context missing required fields for next gate
- Gate 3 produces invalid template syntax
- >10% of mandatory fields at LOW confidence

---

## Blocker Criteria - STOP and Report

**You MUST distinguish between decisions you CAN make vs those requiring escalation.**

| Decision Type | Examples | Action |
|---------------|----------|--------|
| **Can Decide** | Gate retry strategy, context field ordering, state tracking format | **Proceed with workflow** |
| **MUST Escalate** | Agent unavailable, non-retriable errors, regulatory spec ambiguity | **STOP and ask for clarification** |
| **CANNOT Override** | Sequential gate execution, context accumulation, gate PASS criteria, no intermediate files | **HARD BLOCK** - Workflow requires this |

**HARD GATES (STOP immediately):**

1. **Agent Unavailable:** finops-analyzer or finops-automation not accessible
2. **Gate Non-Retriable Failure:** Error cannot be fixed by retry
3. **Context Loss:** Previous gate results not available
4. **Specification Ambiguity:** Regulatory requirement unclear, cannot map

**Escalation Message Template:**
```markdown
⛔ **WORKFLOW BLOCKER - Cannot Continue**

**Issue:** [Specific blocker]
**Gate:** [Current gate that failed]
**Impact:** [What cannot be completed]
**Required:** [What needs resolution]

**Cannot proceed to next gate until resolved.**
```

---

## Cannot Be Overridden

**NON-NEGOTIABLE requirements (no exceptions, no user override):**

| Requirement | Why NON-NEGOTIABLE | Verification |
|-------------|-------------------|--------------|
| **Sequential Gate Execution (1→2→3)** | Each gate depends on previous gate output | gate_order == [1, 2, 3] |
| **Gate PASS Required Before Next** | Failed gates produce invalid input for next | current_gate.status == PASSED |
| **Context Accumulation (Never Overwrite)** | Previous gate data required by later gates | context.has(all_previous_gate_data) |
| **No Intermediate Files** | Memory-only context prevents file corruption | intermediate_files.count == 0 |
| **Single Output File (.tpl)** | Gate 3 produces final artifact only | output_files == [.tpl, .tpl.docs] |

**User CANNOT:**
- Run gates out of order ("skip to Gate 3" = NO)
- Proceed without PASS ("good enough to continue" = NO)
- Replace context ("use different mappings" = NO - run full workflow)
- Create intermediate files ("save for debugging" = NO)
- Manually create template ("faster than Gate 3" = NO)

---

## Quick Reference

| Sub-skill | Purpose | Input | Output |
|-----------|---------|-------|--------|
| regulatory-templates-setup | Initial configuration | User selections | Base context |
| regulatory-templates-gate1 | Regulatory analysis | Base context | Field mappings, spec report |
| regulatory-templates-gate2 | Technical validation | Context + Gate 1 | Validated mappings, rules |
| regulatory-templates-gate3 | Template creation | Context + Gates 1-2 | .tpl file |

## Checklist

**Before:** Sub-skills exist, agents available, template selected, URLs configured
**After each gate:** Result captured, context updated, TodoWrite updated, state tracked
**After completion:** Template created, verified, user notified