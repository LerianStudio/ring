---
name: using-product-reporter
description: FinOps agents for Brazilian financial regulatory compliance - dispatch when implementing BACEN, RFB, or Open Banking requirements
when_to_use: When implementing Brazilian regulatory reporting, financial compliance, or Open Banking specifications - use when you need compliance analysis or template generation
---

# Using Ring FinOps & Regulatory Agents

The ring-product-reporter plugin provides 2 specialized FinOps agents for Brazilian financial compliance. Use them via `Task tool with subagent_type:`.

**Remember:** Follow the **ORCHESTRATOR principle** from `using-ring`. Dispatch agents to handle regulatory complexity; don't implement compliance manually.

---

## 2 FinOps Specialists

### 1. FinOps Analyzer (Compliance Analysis)
**`ring-product-reporter:finops-analyzer`**

**Specializations:**
- Brazilian regulatory compliance analysis
- BACEN (Central Bank) requirements:
  - COSIF (accounting chart of accounts)
  - CADOCs (financial instruments catalog)
- RFB (Federal Revenue) requirements:
  - e-Financeira (financial reporting)
  - SPED (electronic data exchange)
- Open Banking specifications
- Field mapping & validation

**Use When:**
- Analyzing regulatory requirements (Gate 1-2)
- Validating field mappings for compliance
- Understanding BACEN/RFB specifications
- Planning compliance architecture
- Determining required data structures

**Output:** Compliance analysis, field mappings, validation rules

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-product-reporter:finops-analyzer"
  model: "opus"
  prompt: "Analyze BACEN COSIF requirements for corporate account reporting"
```

---

### 2. FinOps Automation (Template Generation)
**`ring-product-reporter:finops-automation`**

**Specializations:**
- Template generation from specifications
- .tpl file creation for Reporter platform
- XML template generation
- HTML template generation
- TXT template generation
- Reporter platform integration

**Use When:**
- Generating regulatory report templates (Gate 3)
- Creating BACEN/RFB compliant templates
- Building Reporter platform files
- Converting specifications to executable templates
- Finalizing compliance implementation

**Output:** Complete .tpl template files, ready for Reporter platform

**Example dispatch:**
```
Task tool:
  subagent_type: "ring-product-reporter:finops-automation"
  model: "opus"
  prompt: "Generate BACEN COSIF template from analyzed requirements"
```

---

## Regulatory Workflow: 3-Gate Process

Brazilian regulatory compliance follows a 3-gate workflow:

### Gate 1: Compliance Analysis
**Agent:** finops-analyzer
**Purpose:** Understand requirements, identify fields, validate mappings
**Output:** compliance analysis document

**Dispatch when:**
- Starting regulatory feature
- Need to understand BACEN/RFB specs
- Planning field mappings

---

### Gate 2: Validation & Confirmation
**Agent:** finops-analyzer (again)
**Purpose:** Confirm mappings are correct, validate against specs
**Output:** validated specification document

**Dispatch when:**
- Ready to confirm compliance understanding
- Need secondary validation
- Before moving to template generation

---

### Gate 3: Template Generation
**Agent:** finops-automation
**Purpose:** Generate executable .tpl templates from validated specifications
**Output:** complete .tpl files for Reporter platform

**Dispatch when:**
- Specifications are finalized & validated
- Ready to create Reporter templates
- Need production-ready compliance files

---

## Supported Regulatory Standards

### BACEN (Central Bank of Brazil)
- **COSIF** – Chart of accounts and accounting rules
- **CADOCs** – Financial instruments and derivatives catalog
- **Manual de Normas** – Regulatory requirements

### RFB (Brazilian Federal Revenue)
- **e-Financeira** – Electronic financial reporting
- **SPED** – Electronic data exchange system
- **ECF** – Financial institutions data

### Open Banking
- **API specifications** – Data sharing standards
- **Security requirements** – Auth and encryption
- **Integration patterns** – System interoperability

---

## Decision: Which Agent?

| Phase | Agent | Use Case |
|-------|-------|----------|
| Understanding requirements | finops-analyzer | Analyze specs, identify fields |
| Validating mappings | finops-analyzer | Confirm correctness, validate |
| Generating templates | finops-automation | Create .tpl files, finalize |

---

## When to Use FinOps Agents

### Use finops-analyzer for:
- ✅ **Understanding regulations** – What does BACEN require?
- ✅ **Compliance research** – How do we map our data?
- ✅ **Requirement analysis** – Which fields are required?
- ✅ **Validation** – Does our mapping match the spec?

### Use finops-automation for:
- ✅ **Template creation** – Build .tpl files
- ✅ **Specification execution** – Convert analysis to templates
- ✅ **Reporter platform prep** – Generate deployment files
- ✅ **Production readiness** – Finalize compliance implementation

---

## Dispatching Multiple FinOps Agents

If you need both analysis and template generation, **dispatch sequentially** (analyze first, then automate):

```
Workflow:
Step 1: Dispatch finops-analyzer
  └─ Returns: compliance analysis
Step 2: Dispatch finops-automation
  └─ Returns: .tpl templates

Note: These must run sequentially because automation depends on analysis.
```

---

## ORCHESTRATOR Principle

Remember:
- **You're the orchestrator** – Dispatch agents, don't implement compliance manually
- **Don't write BACEN specs yourself** – Dispatch analyzer to understand
- **Don't generate templates by hand** – Dispatch automation agent
- **Combine with using-ring principle** – Skills + Agents = complete workflow

### Good Example (ORCHESTRATOR):
> "I need BACEN compliance. Let me dispatch finops-analyzer to understand requirements, then finops-automation to generate templates."

### Bad Example (OPERATOR):
> "I'll manually read BACEN documentation and write templates myself."

---

## Reporter Platform Integration

Generated .tpl files integrate directly with Reporter platform:
- **Input:** Validated specifications from finops-analyzer
- **Output:** .tpl files (XML, HTML, TXT formats)
- **Deployment:** Direct integration with Reporter
- **Validation:** Compliance verified by template structure

---

## Available in This Plugin

**Agents:**
- finops-analyzer (Gate 1-2)
- finops-automation (Gate 3)

**Skills:**
- using-product-reporter (this skill)
- regulatory-templates* (multi-gate workflow skills)

**Note:** If agents are unavailable, check if ring-product-reporter is enabled in `.claude-plugin/marketplace.json`.

---

## Integration with Other Plugins

- **using-ring** (default) – ORCHESTRATOR principle for ALL agents
- **using-developers** – Developer specialists
- **using-team-product** – Pre-dev workflow agents

Dispatch based on your need:
- General code review → default plugin agents
- Regulatory compliance → ring-product-reporter agents
- Developer expertise → ring-developers agents
- Feature planning → ring-team-product agents
