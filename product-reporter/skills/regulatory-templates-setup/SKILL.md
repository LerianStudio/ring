---
name: regulatory-templates-setup
description: Initial setup for regulatory templates - handles template selection and context initialization
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

Use `AskUserQuestion` tool to present regulatory authority selection:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which regulatory authority template do you want to create?",
      header: "Authority",
      multiSelect: false,
      options: [
        {
          label: "CADOC",
          description: "BACEN - Cadastro de Clientes do SFN (select specific document next)"
        },
        {
          label: "e-Financeira",
          description: "RFB - SPED e-Financeira (select specific event next)"
        },
        {
          label: "DIMP",
          description: "RFB - Declaração de Informações sobre Movimentação Patrimonial"
        },
        {
          label: "APIX",
          description: "BACEN - Open Banking API (select specific API next)"
        }
      ]
    }
  ]
})
```

---

### Step 1.1: Template Selection (Conditional by Authority)

**Based on authority selected, show specific template options:**

#### If "CADOC" selected:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which CADOC document do you want to create?",
      header: "CADOC",
      multiSelect: false,
      options: [
        {
          label: "4010",
          description: "Informações de Cadastro - Cadastral Information"
        },
        {
          label: "4016",
          description: "Informações de Operações de Crédito - Credit Operations"
        },
        {
          label: "4111",
          description: "Operações de Câmbio - Foreign Exchange Operations"
        }
      ]
    }
  ]
})
```

**CADOC Template Details:**

| Code | Name | Description | Frequency |
|------|------|-------------|-----------|
| 4010 | Informações de Cadastro | Client cadastral data | Monthly |
| 4016 | Operações de Crédito | Credit operation details | Monthly |
| 4111 | Operações de Câmbio | Foreign exchange operations | Daily |

---

#### If "e-Financeira" selected:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which e-Financeira event do you want to create?",
      header: "Event",
      multiSelect: false,
      options: [
        {
          label: "evtCadDeclarante",
          description: "Cadastro do Declarante - Entity registration (GIIN, FATCA/CRS)"
        },
        {
          label: "evtAberturaeFinanceira",
          description: "Abertura e-Financeira - Opens reporting period (semester)"
        },
        {
          label: "evtFechamentoeFinanceira",
          description: "Fechamento e-Financeira - Closes period and consolidates totals"
        },
        {
          label: "evtMovOpFin",
          description: "Movimento de Operações Financeiras - Semestral financial movements"
        }
      ]
    }
  ]
})

// If user selects "Other", show remaining events:
AskUserQuestion({
  questions: [
    {
      question: "Select additional e-Financeira event type:",
      header: "Event",
      multiSelect: false,
      options: [
        {
          label: "evtMovPP",
          description: "Movimento de Previdência Privada - Private pension (PGBL, VGBL)"
        },
        {
          label: "evtMovOpFinAnual",
          description: "Movimento de Operações Financeiras Anual - Annual consolidated"
        }
      ]
    }
  ]
})
```

**e-Financeira Event Details:**

| Event Code | Event Name | Module | Frequency |
|------------|------------|--------|-----------|
| evtCadDeclarante | Cadastro do Declarante | Structural | Per Period |
| evtAberturaeFinanceira | Abertura e-Financeira | Structural | Semestral |
| evtFechamentoeFinanceira | Fechamento e-Financeira | Structural | Semestral |
| evtMovOpFin | Mov. Operações Financeiras | Financial Operations | Semestral |
| evtMovPP | Mov. Previdência Privada | Private Pension | Semestral |
| evtMovOpFinAnual | Mov. Operações Fin. Anual | Financial Operations | Annual |

---

#### If "DIMP" selected:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which DIMP version do you want to create?",
      header: "DIMP",
      multiSelect: false,
      options: [
        {
          label: "v10",
          description: "DIMP Versão 10 - Current version (Movimentação Patrimonial)"
        }
      ]
    }
  ]
})
```

**DIMP Template Details:**

| Version | Name | Description | Frequency |
|---------|------|-------------|-----------|
| v10 | DIMP v10 | Declaração de Informações sobre Movimentação Patrimonial | Annual |

---

#### If "APIX" selected:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which APIX (Open Banking) API do you want to create?",
      header: "APIX",
      multiSelect: false,
      options: [
        {
          label: "001",
          description: "Dados Cadastrais - Registration/Customer Data API"
        },
        {
          label: "002",
          description: "Contas e Transações - Accounts & Transactions API"
        }
      ]
    }
  ]
})
```

**APIX Template Details:**

| Code | Name | Description | Type |
|------|------|-------------|------|
| 001 | Dados Cadastrais | Customer registration data | REST API |
| 002 | Contas e Transações | Account balances and transactions | REST API |

---

### Selection Flow Diagram

```
┌─────────────────────────────────────┐
│ Step 1: Select Authority            │
│ ○ CADOC (BACEN)                     │
│ ○ e-Financeira (RFB)                │
│ ○ DIMP (RFB)                        │
│ ○ APIX (BACEN)                      │
└──────────────┬──────────────────────┘
               │
    ┌──────────┼──────────┬───────────┐
    ▼          ▼          ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ CADOC  │ │e-Financ│ │  DIMP  │ │  APIX  │
│────────│ │────────│ │────────│ │────────│
│○ 4010  │ │○ evtCad│ │○ v10   │ │○ 001   │
│○ 4016  │ │○ evtAbe│ │        │ │○ 002   │
│○ 4111  │ │○ evtFec│ │        │ │        │
│        │ │○ evtMov│ │        │ │        │
│        │ │○ evtPP │ │        │ │        │
│        │ │○ evtAnu│ │        │ │        │
└────────┘ └────────┘ └────────┘ └────────┘
```

**Capture and extract:**
- Authority (BACEN, RFB)
- Template category (CADOC, e-Financeira, DIMP, APIX)
- Template code (e.g., "4010", "evtMovOpFin", "v10", "001")
- Template name (full descriptive name)
- Additional metadata based on template type

### Step 2: Optional Deadline Input

If not provided by user, use standard deadline for the template type.

### Step 3: Check Dictionary Status and Alert User

**CRITICAL: Before initializing context, check if template has a data dictionary:**

```javascript
// Dictionary status check - MANDATORY
// STANDARDIZED DICTIONARY PATH
const DICTIONARY_BASE_PATH = "~/.claude/docs/regulatory/dictionaries";

const TEMPLATES_WITH_DICTIONARY = {
  "CADOC_4010": `${DICTIONARY_BASE_PATH}/cadoc-4010.yaml`,
  "CADOC_4016": `${DICTIONARY_BASE_PATH}/cadoc-4016.yaml`,
  "APIX_001": `${DICTIONARY_BASE_PATH}/apix-001.yaml`,
  "EFINANCEIRA_evtCadDeclarante": `${DICTIONARY_BASE_PATH}/efinanceira-evtCadDeclarante.yaml`
};

const TEMPLATES_WITHOUT_DICTIONARY = [
  "CADOC_4111",
  "APIX_002",
  "EFINANCEIRA_evtAberturaeFinanceira",
  "EFINANCEIRA_evtFechamentoeFinanceira",
  "EFINANCEIRA_evtMovOpFin",
  "EFINANCEIRA_evtMovPP",
  "EFINANCEIRA_evtMovOpFinAnual",
  "DIMP_v10"
];

function checkDictionaryStatus(templateKey) {
  if (TEMPLATES_WITH_DICTIONARY[templateKey]) {
    return {
      has_dictionary: true,
      dictionary_path: TEMPLATES_WITH_DICTIONARY[templateKey],
      validation_mode: "automatic"
    };
  } else {
    return {
      has_dictionary: false,
      dictionary_path: null,
      validation_mode: "interactive"
    };
  }
}
```

**If template has NO dictionary, alert user with AskUserQuestion:**

```javascript
// Alert user about interactive validation requirement
if (!dictionaryStatus.has_dictionary) {
  await AskUserQuestion({
    questions: [{
      question: `⚠️ Template '${templateSelected}' does NOT have a pre-configured data dictionary.\n\n` +
                `This means you will need to MANUALLY VALIDATE each field mapping in Gate 1.\n\n` +
                `The process will:\n` +
                `1. Query API schemas (Midaz, CRM)\n` +
                `2. Suggest mappings for each regulatory field\n` +
                `3. Ask YOUR APPROVAL via selection boxes or custom typing\n` +
                `4. Save approved mappings as new dictionary for future use\n\n` +
                `Do you want to proceed?`,
      header: "Dictionary",
      multiSelect: false,
      options: [
        {
          label: "Proceed with interactive validation",
          description: "I'll validate each field mapping manually"
        },
        {
          label: "Choose different template",
          description: "Select a template that has pre-configured dictionary"
        }
      ]
    }]
  });
}
```

---

### Step 4: Initialize Context Object

Create and return the complete initial context based on selections:

```javascript
// Base context structure (common to all templates)
let context = {
  // From Step 1 - Authority selection
  authority: "BACEN", // or "RFB"
  template_category: "CADOC", // or "e-Financeira", "DIMP", "APIX"

  // From Step 1.1 - Template selection
  template_code: "4010", // specific code selected
  template_name: "Informações de Cadastro", // full name

  // Computed fields
  template_selected: "CADOC 4010", // combined identifier

  // Dictionary status (CRITICAL - determines validation mode)
  // STANDARDIZED PATH: ~/.claude/docs/regulatory/dictionaries/
  dictionary_status: {
    has_dictionary: true/false,
    dictionary_path: "~/.claude/docs/regulatory/dictionaries/cadoc-4010.yaml" or null,
    validation_mode: "automatic" or "interactive"
  },

  // Documentation reference (auto-resolved)
  documentation_path: ".claude/docs/regulatory/templates/BACEN/CADOC/cadoc-4010-4016.md",

  // Optional user input
  deadline: "2025-12-31", // or ask if needed

  // Gates (to be populated by subsequent sub-skills)
  gate1: null,
  gate2: null,
  gate3: null
};
```

---

### Template-Specific Context Extensions

#### CADOC Context

```javascript
const cadocContext = {
  ...baseContext,
  authority: "BACEN",
  template_category: "CADOC",
  template_code: "4010", // or "4016", "4111"
  template_name: "Informações de Cadastro",
  template_selected: "CADOC 4010",
  documentation_path: ".claude/docs/regulatory/templates/BACEN/CADOC/cadoc-4010-4016.md",
  format: "XML",
  frequency: "monthly" // or "daily" for 4111
};
```

#### e-Financeira Context

```javascript
const efinanceiraContext = {
  ...baseContext,
  authority: "RFB",
  template_category: "e-Financeira",
  template_code: "evtMovOpFin", // event code selected
  template_name: "Movimento de Operações Financeiras",
  template_selected: "e-Financeira evtMovOpFin",
  documentation_path: ".claude/docs/regulatory/templates/RFB/EFINANCEIRA/efinanceira.md",
  format: "XML",

  // e-Financeira specific fields
  event_module: "financial_operations", // or "private_pension", "structural"
  event_category: "movement", // or "structural"
  event_frequency: "semestral", // or "annual", "per_period"
  fatca_applicable: true,
  crs_applicable: true
};
```

#### DIMP Context

```javascript
const dimpContext = {
  ...baseContext,
  authority: "RFB",
  template_category: "DIMP",
  template_code: "v10",
  template_name: "DIMP Versão 10",
  template_selected: "DIMP v10",
  documentation_path: ".claude/docs/regulatory/templates/RFB/DIMP/dimp-v10-manual.md",
  format: "XML",
  frequency: "annual"
};
```

#### APIX Context

```javascript
const apixContext = {
  ...baseContext,
  authority: "BACEN",
  template_category: "APIX",
  template_code: "001", // or "002"
  template_name: "Dados Cadastrais",
  template_selected: "APIX 001",
  documentation_path: ".claude/docs/regulatory/templates/BACEN/APIX/001/",
  format: "JSON",
  api_type: "REST"
};
```

---

### Template Mapping Reference

```javascript
const TEMPLATE_REGISTRY = {
  // CADOC Templates (BACEN)
  CADOC: {
    authority: "BACEN",
    templates: {
      "4010": {
        name: "Informações de Cadastro",
        description: "Client cadastral data",
        frequency: "monthly",
        format: "XML",
        documentation: ".claude/docs/regulatory/templates/BACEN/CADOC/cadoc-4010-4016.md"
      },
      "4016": {
        name: "Operações de Crédito",
        description: "Credit operation details",
        frequency: "monthly",
        format: "XML",
        documentation: ".claude/docs/regulatory/templates/BACEN/CADOC/cadoc-4010-4016.md"
      },
      "4111": {
        name: "Operações de Câmbio",
        description: "Foreign exchange operations",
        frequency: "daily",
        format: "XML",
        documentation: ".claude/docs/regulatory/templates/BACEN/CADOC/cadoc-4010-4016.md"
      }
    }
  },

  // e-Financeira Templates (RFB)
  "e-Financeira": {
    authority: "RFB",
    templates: {
      evtCadDeclarante: {
        name: "Cadastro do Declarante",
        module: "structural",
        category: "structural",
        frequency: "per_period",
        format: "XML",
        fatca_applicable: true,
        crs_applicable: true,
        description: "Entity registration with GIIN, FATCA/CRS categories",
        documentation: ".claude/docs/regulatory/templates/RFB/EFINANCEIRA/efinanceira.md"
      },
      evtAberturaeFinanceira: {
        name: "Abertura e-Financeira",
        module: "structural",
        category: "structural",
        frequency: "semestral",
        format: "XML",
        fatca_applicable: false,
        crs_applicable: false,
        description: "Opens reporting period (dtIni/dtFim)",
        documentation: ".claude/docs/regulatory/templates/RFB/EFINANCEIRA/efinanceira.md"
      },
      evtFechamentoeFinanceira: {
        name: "Fechamento e-Financeira",
        module: "structural",
        category: "structural",
        frequency: "semestral",
        format: "XML",
        fatca_applicable: true,
        crs_applicable: true,
        description: "Closes period, consolidates PP/OpFin/OpFinAnual totals",
        documentation: ".claude/docs/regulatory/templates/RFB/EFINANCEIRA/efinanceira.md"
      },
      evtMovOpFin: {
        name: "Movimento de Operações Financeiras",
        module: "financial_operations",
        category: "movement",
        frequency: "semestral",
        format: "XML",
        fatca_applicable: true,
        crs_applicable: true,
        description: "Financial movements - accounts, balances, income",
        documentation: ".claude/docs/regulatory/templates/RFB/EFINANCEIRA/efinanceira.md"
      },
      evtMovPP: {
        name: "Movimento de Previdência Privada",
        module: "private_pension",
        category: "movement",
        frequency: "semestral",
        format: "XML",
        fatca_applicable: false,
        crs_applicable: false,
        description: "Private pension movements - PGBL, VGBL, etc.",
        documentation: ".claude/docs/regulatory/templates/RFB/EFINANCEIRA/efinanceira.md"
      },
      evtMovOpFinAnual: {
        name: "Movimento de Operações Financeiras Anual",
        module: "financial_operations",
        category: "movement",
        frequency: "annual",
        format: "XML",
        fatca_applicable: true,
        crs_applicable: true,
        description: "Annual consolidated financial movements",
        documentation: ".claude/docs/regulatory/templates/RFB/EFINANCEIRA/efinanceira.md"
      }
    }
  },

  // DIMP Templates (RFB)
  DIMP: {
    authority: "RFB",
    templates: {
      v10: {
        name: "DIMP Versão 10",
        description: "Declaração de Informações sobre Movimentação Patrimonial",
        frequency: "annual",
        format: "XML",
        documentation: ".claude/docs/regulatory/templates/RFB/DIMP/dimp-v10-manual.md"
      }
    }
  },

  // APIX Templates (BACEN - Open Banking)
  APIX: {
    authority: "BACEN",
    templates: {
      "001": {
        name: "Dados Cadastrais",
        description: "Customer registration data API",
        api_type: "REST",
        format: "JSON",
        documentation: ".claude/docs/regulatory/templates/BACEN/APIX/001/"
      },
      "002": {
        name: "Contas e Transações",
        description: "Account balances and transactions API",
        api_type: "REST",
        format: "JSON",
        documentation: ".claude/docs/regulatory/templates/BACEN/APIX/002/"
      }
    }
  }
};
```

---

## State Tracking Output

After completing setup, output:

```
SKILL: regulatory-templates-setup
STATUS: COMPLETE
TEMPLATE: {context.template_selected}
DEADLINE: {context.deadline}
NEXT: → Gate 1: Regulatory Compliance Analysis
```

---

## Success Criteria

Setup is complete when:
- ✅ Template selected and validated
- ✅ Deadline established (input or default)
- ✅ Context object initialized with all values
- ✅ Documentation URL identified for selected template

---

## Output

Return the complete `context` object to the parent skill for use in subsequent gates.