---
name: regulatory-templates-setup
description: |
  Initial setup sub-skill - handles template selection and context initialization
  for the 3-gate regulatory workflow.

trigger: |
  - Called by regulatory-templates orchestrator at workflow start
  - Need to select template type and initialize context

skip_when: |
  - Not in regulatory-templates workflow
  - Setup already completed for current template

sequence:
  after: [regulatory-templates]
  before: [regulatory-templates-gate1]
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

## Setup Steps

### Step 1: Regulatory Authority Selection

**AskUserQuestion:** "Which regulatory authority template?"

| Option | Description |
|--------|-------------|
| CADOC | BACEN - Cadastro de Clientes do SFN |
| e-Financeira | RFB - SPED e-Financeira |
| DIMP | RFB - Declaração de Informações sobre Movimentação Patrimonial |
| APIX | BACEN - Open Banking API |

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
- Question: "Template has no pre-configured dictionary. Interactive validation required (~40 min). Proceed?"
- Options: "Proceed with interactive validation" | "Choose different template"
- Alert user: Query APIs → Suggest mappings → User approval each → Save as new dictionary

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