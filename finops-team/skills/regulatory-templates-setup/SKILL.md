---
name: ring:regulatory-templates-setup
description: |
  Initial setup sub-skill - handles template selection and context initialization
  for the 5-stage regulatory workflow. Supports any regulatory template (pre-defined
  or new) via official spec intake (URL/XSD/PDF).
metadata:
  dependencies: []
  role: setup
  sequence:
    after:
    - ring:regulatory-templates
    before:
    - ring:regulatory-templates-gate1
  skip_when: |
    - Not in regulatory-templates workflow
    - Setup already completed for current template
  trigger: |
    - Called by regulatory-templates orchestrator at workflow start
    - Need to select template type and initialize context
---

# Regulatory Templates - Initial Setup

## Overview

**This sub-skill handles the initial setup phase for regulatory template creation, including template selection and context initialization.**

**Parent skill:** `regulatory-templates`

**Output:** Complete initial context object with all selections and configurations

---

## Foundational Principle

**Setup initializes the foundation - errors here propagate through all 3 gates.**

Setup is not "just configuration" - it's critical validation:
- **Template selection**: Wrong template = entire workflow on wrong regulatory spec (hours wasted)
- **Context initialization**: Incomplete context = gates fail mysteriously downstream
- **Dictionary status check**: Skipped check = lost automation, unnecessary interactive validation
- **User awareness**: No alert about validation mode = poor UX, blocked progress

**Skipping setup steps means:**
- Hard-coded context bypasses validation (typos, wrong versions)
- Missing values cause gate failures (debugging waste)
- Silent dictionary check = user unprepared for interactive validation
- No audit trail of selections (compliance gap)

**Setup is the contract between user intent and gate execution. Get it wrong = everything downstream breaks.**

---

## When to Use

**Called by:** `regulatory-templates` skill at the beginning of the workflow

**Purpose:** Gather all user selections and initialize the context object that will flow through all gates

---

## NO EXCEPTIONS - Setup Requirements Are Mandatory

**Setup requirements have ZERO exceptions.** Foundation errors compound through all gates.

### Common Pressures You Must Resist

| Pressure | Your Thought | Reality |
|----------|--------------|---------|
| **Ceremony** | "User said CADOC 4010, skip selection" | Validation confirms, prevents typos, initializes full context |
| **Speed** | "Hard-code context, skip AskUserQuestion" | Bypasses validation, loses audit trail, breaks contract |
| **Simplicity** | "Dictionary check is file I/O ceremony" | Check determines validation mode (auto vs interactive 40 min difference) |
| **Efficiency** | "Skip user alert, they'll see validation later" | Poor UX, unprepared user, blocked progress |

### Setup Requirements (Non-Negotiable)

**Template Selection:**
- ✅ REQUIRED: Use AskUserQuestion for authority and template selection
- ❌ FORBIDDEN: Hard-code based on user message, skip selection dialog
- Why: Validation confirms correct template, prevents typos, establishes audit trail

**Dictionary Status Check:**
- ✅ REQUIRED: Check ~/.claude/docs/regulatory/dictionaries/ for template dictionary
- ❌ FORBIDDEN: Skip check, assume no dictionary exists
- Why: Determines validation mode (automatic vs interactive = 40 min time difference)

**User Alert:**
- ✅ REQUIRED: Alert user if interactive validation required (no dictionary)
- ❌ FORBIDDEN: "They'll figure it out in Gate 1"
- Why: User preparedness, UX, informed consent for 40-min validation process

**Complete Context:**
- ✅ REQUIRED: Initialize ALL context fields (authority, template_code, template_name, dictionary_status, documentation_path)
- ❌ FORBIDDEN: Minimal context, "gates will add details later"
- Why: Incomplete context causes mysterious gate failures

### The Bottom Line

**Setup shortcuts = silent failures in all downstream gates.**

Setup is foundation. Wrong template selection wastes hours on wrong spec. Missing context breaks gates mysteriously. Skipped checks lose automation.

**If tempted to skip setup, ask: Am I willing to debug gate failures from incomplete initialization?**

---

## Rationalization Table

| Excuse | Why It's Wrong | Correct Response |
|--------|---------------|------------------|
| "User already said CADOC 4010" | Validation confirms, prevents typos (4010 vs 4020) | Run selection |
| "Hard-code context is faster" | Bypasses validation, loses audit trail | Use AskUserQuestion |
| "Dictionary check is ceremony" | Determines 40-min validation mode difference | Check dictionary |
| "They'll see validation in Gate 1" | Poor UX, unprepared user | Alert if interactive |
| "Just pass minimal context" | Incomplete causes mysterious gate failures | Initialize ALL fields |
| "Setup is just config" | Foundation errors compound through 3 gates | Setup is validation |

### If You Find Yourself Making These Excuses

**STOP. You are rationalizing.**

Setup appears simple but errors propagate through 4-6 hours of gate execution. Foundation correctness prevents downstream waste.

---

---

## Severity Calibration

**MUST classify setup issues using these severity levels:**

| Severity | Definition | Examples | Gate Impact |
|----------|------------|----------|-------------|
| **CRITICAL** | BLOCKS workflow progression OR invalidates foundation | - Template not in registry<br>- Authority selection invalid<br>- Context initialization failed<br>- Required field missing from context | **HARD BLOCK** - Cannot proceed to Gate 1 |
| **HIGH** | REQUIRES resolution for accurate gate execution | - Dictionary status unknown<br>- Documentation path missing<br>- Template code incorrect<br>- User not alerted about validation mode | **MUST resolve** before Gate 1 |
| **MEDIUM** | SHOULD fix for optimal workflow | - Deadline not specified (using default)<br>- Optional context fields missing<br>- Documentation incomplete | **SHOULD resolve** - document if deferred |
| **LOW** | Minor improvements possible | - Context verbosity<br>- Naming improvements<br>- Additional metadata | **OPTIONAL** - note in report |

**Classification Rules:**

**CRITICAL = ANY of:**
- Template selection cannot be validated against registry
- Authority is not BACEN or RFB (invalid for Brazilian regulatory)
- Context object missing required fields (authority, template_code, template_name)
- Setup steps cannot complete

**HIGH = ANY of:**
- Dictionary status not checked (determines 40-min vs automatic validation)
- User not informed about interactive validation requirement
- Documentation path not set correctly
- Template metadata incomplete

---

## Blocker Criteria - STOP and Report

**You MUST distinguish between decisions you CAN make vs those requiring escalation.**

| Decision Type | Examples | Action |
|---------------|----------|--------|
| **Can Decide** | Default deadline, context field ordering, documentation format | **Proceed with setup** |
| **MUST Escalate** | Template not in registry, user selection unclear, multiple valid authorities | **STOP and ask for clarification** |
| **CANNOT Override** | AskUserQuestion requirement, dictionary check, context completeness, user alert for interactive mode | **HARD BLOCK** - Must complete before Gate 1 |

**HARD GATES (STOP immediately):**

1. **Template Not Found:** Template missing from registry
2. **Ambiguous Selection:** User response doesn't match available templates
3. **Missing Context:** Required context fields cannot be populated
4. **Dictionary Check Skipped:** Cannot determine validation mode without check

**Escalation Message Template:**
```markdown
⛔ **SETUP BLOCKER - Cannot Initialize Context**

**Issue:** [Specific blocker]
**Impact:** [What cannot be determined/initialized]
**Required:** [What needs resolution]

**Cannot proceed to Gate 1 until resolved.**
```

---

## Cannot Be Overridden

**NON-NEGOTIABLE requirements (no exceptions, no user override):**

| Requirement | Why NON-NEGOTIABLE | Verification |
|-------------|-------------------|--------------|
| **AskUserQuestion for Selection** | Prevents typos, validates against registry, creates audit trail | Used AskUserQuestion tool |
| **Dictionary Status Check** | Determines validation mode (40-min difference) | Checked dictionary path |
| **User Alert for Interactive Mode** | UX requirement, informed consent for long process | Alert shown if no dictionary |
| **Complete Context Initialization** | Incomplete context causes mysterious gate failures | ALL required fields populated |
| **Template Registry Validation** | Ensures template exists and is supported | Template verified in registry |

**CANNOT allow user to:**
- Skip template selection ("I already told you CADOC 4010" = NO - validate anyway)
- Bypass dictionary check ("just assume no dictionary" = NO)
- Skip user alert ("they'll figure it out" = NO)
- Initialize partial context ("add missing fields later" = NO)
- Hard-code selections ("same as last time" = NO - run selection)

---

## Pressure Resistance

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

### Setup-Specific Pressures

| User Says | Your Response |
|-----------|---------------|
| "I already said CADOC 4010, just start" | "I MUST validate the selection against our registry. This takes 30 seconds and prevents typos (4010 vs 4020). Running AskUserQuestion now." |
| "Skip dictionary check, it doesn't exist" | "I CANNOT skip the dictionary check. It determines if we need 40-minute interactive validation or can proceed automatically. Checking now." |
| "Don't alert me, just proceed" | "I MUST inform you if interactive validation is required. This is a 40-minute process that requires your input. You need to be prepared." |
| "Just use the same template as last time" | "I CANNOT hard-code previous selections. Each workflow MUST validate against current registry. Requirements may have changed." |
| "Setup is ceremony, go straight to analysis" | "I CANNOT skip setup. It initializes the context that ALL gates depend on. Incomplete setup = mysterious failures in Gates 1-3." |

---

## Setup Steps

### Step 1: Regulatory Authority Selection

**AskUserQuestion:** "Which regulatory authority template?"

| Option | Description |
|--------|-------------|
| CADOC | BACEN - Cadastro de Clientes do SFN |
| e-Financeira | RFB - SPED e-Financeira |
| DIMP | RFB - Declaração de Informações sobre Movimentação Patrimonial |
| APIX | BACEN - Open Banking API |
| **Novo template** | **Qualquer regulação BACEN/RFB/CVM/SUSEP/outro não listado acima** |

> **Open system:** The workflow supports ANY regulatory template, not just the pre-defined list. If the template is not listed, select "Novo template" and provide the spec.

---

### Step 1.0: New Template Intake (only if "Novo template" selected)

If the user selects "Novo template", collect the following before proceeding:

**AskUserQuestion (sequence):**
1. **Template name** — ex: "CADOC 4030", "DLO", "e-Financeira evtPatrimonio", "DECRED"
2. **Regulatory authority** — BACEN | RFB | CVM | SUSEP | COAF | outro (especificar)
3. **Output format** — XML | TXT (fixed-width) | HTML | CSV | JSON
4. **Official spec** — URL do manual/circular oficial OU caminho de arquivo XSD/PDF (OBRIGATÓRIO)
5. **Reporter dev URL** (optional) — URL do ambiente de desenvolvimento para validação pós-geração

**Context additions for new templates:**
```yaml
is_new_template: true
template_spec_url: "<URL fornecida>"
template_spec_format: "<XML|TXT|HTML|CSV>"
reporter_dev_url: "<URL ou null>"  # for optional Test Gate
```

**Alert user:**
> "Template novo detectado. Gate 1 irá extrair os campos da spec fornecida, usar pattern matching com templates existentes para sugerir mapeamentos, e **salvar o dicionário automaticamente** ao final. Na próxima execução deste template, o workflow será automático (~5 min)."

**BLOCKER:** If no official spec URL/file is provided → STOP. Cannot map fields without the authoritative specification.

---

### Step 1.1: Template Selection (Conditional by Authority)

**AskUserQuestion:** Show template options based on authority selected:

| Authority | Question | Options |
|-----------|----------|---------|
| **CADOC** | "Which CADOC document?" | 4010 (Cadastro), 4016 (Crédito), 4111 (Câmbio) |
| **e-Financeira** | "Which event?" | evtCadDeclarante, evtAbertura, evtFechamento, evtMovOpFin, evtMovPP, evtMovOpFinAnual |
| **DIMP** | "Which version?" | v10 (current) |
| **APIX** | "Which API?" | 001 (Cadastrais), 002 (Contas/Transações) |

**Template Registry:**

| Category | Code | Name | Frequency | Format | FATCA/CRS |
|----------|------|------|-----------|--------|-----------|
| CADOC | 4010 | Informações de Cadastro | Monthly | XML | N/A |
| CADOC | 4016 | Operações de Crédito | Monthly | XML | N/A |
| CADOC | 4111 | Operações de Câmbio | Daily | XML | N/A |
| e-Financeira | evtCadDeclarante | Cadastro do Declarante | Per Period | XML | Yes/Yes |
| e-Financeira | evtAberturaeFinanceira | Abertura e-Financeira | Semestral | XML | No/No |
| e-Financeira | evtFechamentoeFinanceira | Fechamento e-Financeira | Semestral | XML | Yes/Yes |
| e-Financeira | evtMovOpFin | Mov. Operações Financeiras | Semestral | XML | Yes/Yes |
| e-Financeira | evtMovPP | Mov. Previdência Privada | Semestral | XML | No/No |
| e-Financeira | evtMovOpFinAnual | Mov. Operações Fin. Anual | Annual | XML | Yes/Yes |
| DIMP | v10 | DIMP Versão 10 | Annual | XML | N/A |
| APIX | 001 | Dados Cadastrais | REST API | JSON | N/A |
| APIX | 002 | Contas e Transações | REST API | JSON | N/A |

**Capture:** Authority (BACEN/RFB), category, code, name, metadata

### Step 2: Optional Deadline Input

If not provided by user, use standard deadline for the template type.

### Step 3: Check Dictionary Status and Alert User

**CRITICAL:** Check dictionary BEFORE initializing context. Path: `~/.claude/docs/regulatory/dictionaries/{category}-{code}.yaml`

| Template | Has Dictionary | Validation Mode |
|----------|----------------|-----------------|
| CADOC_4010 | ✅ Yes | Automatic |
| CADOC_4016 | ✅ Yes | Automatic |
| APIX_001 | ✅ Yes | Automatic |
| EFINANCEIRA_evtCadDeclarante | ✅ Yes | Automatic |
| All others | ❌ No | Interactive |

**If NO dictionary exists → AskUserQuestion:**
- Question: "Template has no pre-configured dictionary. Gate 1 will use batch approval by confidence level (~10-15 min). Proceed?"
- Options: "Proceed" | "Choose different template"
- Alert user: Gate 1 will query APIs → suggest mappings → batch approval by confidence level → **auto-save dictionary** for future use

---

### Step 4: Initialize Context Object

**Base context structure (ALL fields required):**

| Field | Source | Example |
|-------|--------|---------|
| `authority` | Step 1 | "BACEN" or "RFB" |
| `template_category` | Step 1 | "CADOC", "e-Financeira", "DIMP", "APIX" |
| `template_code` | Step 1.1 | "4010", "evtMovOpFin", "v10", "001" |
| `template_name` | Registry | "Informações de Cadastro" |
| `template_selected` | Computed | "CADOC 4010" |
| `dictionary_status` | Step 3 | `{has_dictionary, dictionary_path, validation_mode}` |
| `documentation_path` | Registry | ".claude/docs/regulatory/templates/..." |
| `deadline` | User/Default | "2025-12-31" |
| `gate1/gate2/gate3` | Initialize | null (populated by subsequent gates) |
| `is_new_template` | Step 1.0 | false (default) or true (new template) |
| `template_spec_url` | Step 1.0 | null (default) or URL/path of official spec |
| `reporter_dev_url` | Step 1.0 | null (default) or Reporter dev environment URL |

**Template-Specific Extensions:**

| Category | Extra Fields |
|----------|--------------|
| CADOC | `format: "XML"`, `frequency: "monthly"/"daily"` |
| e-Financeira | `format: "XML"`, `event_module`, `event_category`, `event_frequency`, `fatca_applicable`, `crs_applicable` |
| DIMP | `format: "XML"`, `frequency: "annual"` |
| APIX | `format: "JSON"`, `api_type: "REST"` |

**Documentation Paths:**
- CADOC: `.claude/docs/regulatory/templates/BACEN/CADOC/cadoc-4010-4016.md`
- e-Financeira: `.claude/docs/regulatory/templates/RFB/EFINANCEIRA/efinanceira.md`
- DIMP: `.claude/docs/regulatory/templates/RFB/DIMP/dimp-v10-manual.md`
- APIX: `.claude/docs/regulatory/templates/BACEN/APIX/{code}/`

---

## State Tracking Output

Output on completion: `SKILL: regulatory-templates-setup | STATUS: COMPLETE | TEMPLATE: {template_selected} | DEADLINE: {deadline} | NEXT: → Gate 1`

## Success Criteria

- ✅ Template selected and validated
- ✅ Deadline established (input or default)
- ✅ Context object initialized with ALL fields
- ✅ Dictionary status checked

**Output:** Return complete `context` object to parent skill.