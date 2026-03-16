---
name: using-finops-team
description: |
  3 FinOps agents: 2 for Brazilian financial regulatory compliance (BACEN, RFB,
  Open Banking), 1 for infrastructure cost estimation when onboarding customers.
  Supports any regulatory template via open intake system.
metadata:
  dependencies:
  - ring:finops-analyzer
  - ring:finops-automation
  - ring:infrastructure-cost-estimator
  - ring:regulatory-templates
  role: guide
  skip_when: |-
    - Non-Brazilian regulations → use appropriate resources
    - Non-AWS infrastructure → adapt formulas
    - One-time cost question → direct calculation
  trigger: |
    - Brazilian regulatory reporting (BACEN, RFB)
    - Financial compliance requirements
    - Open Banking specifications
    - Template generation for Reporter platform
    - Infrastructure cost estimation for new customers
    - AWS capacity planning and pricing
---

# Using Ring FinOps & Regulatory Agents

The ring-finops-team plugin provides 3 specialized FinOps agents: 2 for Brazilian financial compliance and 1 for infrastructure cost estimation. Use them via `Task tool with subagent_type:`.

**Remember:** Follow the **ORCHESTRATOR principle** from `ring:using-ring`. Dispatch agents to handle regulatory complexity; don't implement compliance manually.

---

## 3 FinOps Specialists

### 0. Infrastructure Cost Estimator (Customer Onboarding)
**`ring:infrastructure-cost-estimator`** (v5.0)

**Architecture: Skill Orchestrates → Agent Calculates**
```
SKILL gathers ALL data (including environment selection + Helm configs) → Agent calculates per-environment breakdown
```

**How it works:**
1. **Skill asks products:** "Which products does customer need?" (Access Manager always included)
2. **Skill collects:** Repo path, TPS, total customers
3. **Skill asks environment:** "Which environments to calculate?" (Homolog, Production, or Both)
4. **Skill reads LerianStudio/helm:** Only for selected products
5. **Skill asks per component:** "Shared or Dedicated?" for each (VPC, EKS, PostgreSQL, Valkey, etc.)
6. **Skill asks backup policy:** "What backup retention for Production?" (Homolog always minimal)
7. **Skill collects billing:** Unit, price, volume
8. **Skill dispatches:** Agent with products + actual Helm values + environments + backup config
9. **Agent calculates:** Per-environment costs including backup costs (minimal for Homolog, full for Production)
10. **Agent returns:** Side-by-side Homolog vs Production breakdown + backup costs + combined profitability

**Backup Policy Differences:**

| Environment | Retention | Snapshots | PITR | Cost Impact |
|-------------|-----------|-----------|------|-------------|
| **Homolog** | 1-7 days | Automated only | No | ~Free (within AWS limits) |
| **Production** | 7-35 days | Daily + weekly | Yes | R$ 38-580/month (TPS-based) |

**Products Available:**

| Product | Selection | Sharing | Chart |
|---------|-----------|---------|-------|
| **Access Manager** | ALWAYS | ALWAYS SHARED | `charts/plugin-access-manager` |
| **Core one Core** | Customer choice | Per-customer | `charts/midaz` |
| **Reporter** | Customer choice | Per-customer | `charts/reporter` |

**Data source:** `git@github.com:LerianStudio/helm.git`

**Sharing Model Definitions:**
- **SHARED** = Schema-based multi-tenancy (same instance, different schemas per customer)
- **DEDICATED** = Fully isolated instance (no other customers on this infrastructure)

**Per-Component Sharing Model:**
```
| Component | Sharing | Isolation | Customers | Cost/Customer |
|-----------|---------|-----------|-----------|---------------|
| EKS Cluster | SHARED | Namespace per customer | 5 | R$ 414 (÷5) |
| PostgreSQL | DEDICATED | Own RDS instance | 1 | R$ 1,490 (full) |
| Valkey | SHARED | Key prefix per customer | 5 | R$ 130 (÷5) |
```

**Output (7 sections):**
1. Discovered Services
2. **Infrastructure Components** (per-component breakdown)
3. **Cost by Category** (compute, database, network, storage, backups %)
4. **Backup Costs by Environment** (Homolog minimal vs Production full)
5. **Shared vs Dedicated Summary** (clear separation)
6. Profitability Analysis
7. Summary

**Example dispatch (with per-component sharing + backup config):**
```
Task tool:
  subagent_type: "ring:infrastructure-cost-estimator"
  prompt: |
    Calculate infrastructure costs and profitability.

    ALL DATA PROVIDED (do not ask questions):

    Infrastructure:
    - Repo: /path/to/repo
    - Helm Source: LerianStudio/helm
    - TPS: 100
    - Total Customers on Platform: 5

    Actual Resource Configurations (READ from LerianStudio/helm):
    | Service | CPU Request | Memory Request | HPA | Source |
    |---------|-------------|----------------|-----|--------|
    | onboarding | 1500m | 512Mi | 2-5 | midaz |
    | transaction | 2000m | 512Mi | 3-9 | midaz |
    | auth | 500m | 256Mi | 3-9 | access-manager |
    | ... | ... | ... | ... | ... |

    Component Sharing Model:
    | Component | Sharing | Customers |
    |-----------|---------|-----------|
    | EKS Cluster | SHARED | 5 |
    | PostgreSQL | DEDICATED | 1 |
    | Valkey | SHARED | 5 |
    | DocumentDB | SHARED | 5 |
    | RabbitMQ | SHARED | 5 |

    Backup Configuration:
    | Environment | Retention | Snapshots | PITR | Expected Cost |
    |-------------|-----------|-----------|------|---------------|
    | Homolog | 1-7 days | Automated only | No | ~Free |
    | Production | 7 days | Daily (7) | Yes | R$ 38-175/month |

    Billing Model:
    - Billing Unit: transaction
    - Price per Unit: R$ 0.10
    - Expected Volume: 1,000,000/month
```

**Skill:** `ring:infrastructure-cost-estimation` - Reads LerianStudio/helm at runtime, orchestrates data collection.

---

### 1. FinOps Analyzer (Compliance Analysis) - Regulatory
**`ring:finops-analyzer`**

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
  subagent_type: "ring:finops-analyzer"
  prompt: "Analyze BACEN COSIF requirements for corporate account reporting"
```

---

### 2. FinOps Automation (Template Generation)
**`ring:finops-automation`**

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
  subagent_type: "ring:finops-automation"
  prompt: "Generate BACEN COSIF template from analyzed requirements"
```

---

## Regulatory Workflow: 5-Stage Process (3 mandatory + 2 optional)

The workflow supports **any regulatory template** — not just the pre-defined list. For unknown templates, provide the official spec (URL/XSD/PDF) and Gate 1 will extract fields, suggest mappings, and auto-save the dictionary.

### Setup: Template Selection
**Purpose:** Select or define the template. For pre-defined templates with dictionary → fast path. For new templates → provide spec.

**Supports:**
- Pre-defined templates with dictionaries: CADOC 4010, 4016, APIX 001, evtCadDeclarante
- **Any regulatory template** via "Novo template" option (BACEN, RFB, CVM, SUSEP, COAF, or other)

---

### Gate 1: Compliance Analysis + Auto-Save
**Agent:** ring:finops-analyzer
**Purpose:** Understand requirements, map fields, save dictionary

**New in this version:**
- Loads **DATA_SOURCES.md** before any mapping (canonical field reference)
- Fetches **Reporter docs online** (source of truth for filters/syntax)
- **Cross-dictionary pattern matching** to reuse knowledge from existing templates
- **Batch approval** by confidence level (replaces O(n) field-by-field questions)
- **Auto-saves dictionary** after approval → next run is automatic (~5 min)

**Output:** compliance analysis + dictionary saved + registry updated

---

### Gate 2: Validation & Confirmation
**Agent:** ring:finops-analyzer (again)
**Purpose:** Validate mappings, test transformations, accounting checks
**Output:** validated specification document

---

### Gate 3: Template Generation
**Agent:** ring:finops-automation
**Purpose:** Generate executable .tpl templates from validated specifications
**Output:** complete .tpl + .tpl.docs files for Reporter platform

---

### Gate Teste: Dev Environment Validation *(optional)*
**Purpose:** Validate generated template in the Reporter dev environment
**Triggered when:** `reporter_dev_url` configured in Setup AND user opts in
**Output:** Confirmed render or feedback for Gate 3 correction

---

### Contribution Gate: PR to Ring *(optional, new templates only)*
**Purpose:** Open PR to LerianStudio/ring to share the new template with the community
**Triggered when:** new template was created AND user wants to contribute
**Includes:** dictionary YAML + updated registry.yaml + .tpl file
**Commit:** signed with user's own GitHub token (never agent credentials)
**Output:** PR URL

---

## Supported Regulatory Standards

### BACEN (Central Bank of Brazil)
- **COSIF** – Chart of accounts and accounting rules
- **CADOCs** – Financial instruments catalog (4010, 4016, 4111, and others)
- **APIX** – Open Banking API (001, 002, and others)
- **Manual de Normas** – Regulatory requirements
- **Any other BACEN obligation** (via "Novo template" + official spec)

### RFB (Brazilian Federal Revenue)
- **e-Financeira** – Electronic financial reporting (all 6 events)
- **DIMP** – Asset movement declaration (v10)
- **SPED** – Electronic data exchange system
- **ECF** – Financial institutions data
- **Any other RFB obligation** (via "Novo template" + official spec)

### Open Banking
- **API specifications** – Data sharing standards
- **Security requirements** – Auth and encryption
- **Integration patterns** – System interoperability

### Data Sources Reference
Canonical field reference: `finops-team/docs/regulatory/templates/DATA_SOURCES.md`

---

## Decision: Which Agent?

| Need | Agent | Use Case |
|------|-------|----------|
| **Is this deal profitable?** | ring:infrastructure-cost-estimator | Calculate revenue - cost = profit |
| **Shared vs dedicated costs** | ring:infrastructure-cost-estimator | Per-component cost attribution |
| **Infrastructure breakdown** | ring:infrastructure-cost-estimator | Detailed component costs by category |
| **Break-even analysis** | ring:infrastructure-cost-estimator | Minimum volume to cover costs |
| **Regulatory analysis** | ring:finops-analyzer | Analyze BACEN/RFB specs, identify fields |
| **Mapping validation** | ring:finops-analyzer | Confirm correctness, validate |
| **Template generation** | ring:finops-automation | Create .tpl files, finalize |

---

## When to Use FinOps Agents

### Use ring:infrastructure-cost-estimator for:
- ✅ **"How much will this cost on AWS?"** – Auto-discovers from docker-compose
- ✅ **"Which components are shared vs dedicated?"** – Per-component cost attribution
- ✅ **"What's the cost breakdown by category?"** – Compute, database, network percentages
- ✅ **"Is this deal profitable?"** – Calculates revenue, cost, and gross margin
- ✅ **Customer onboarding** – Full detailed breakdown + profitability analysis
- ✅ **Break-even analysis** – Shows minimum volume needed to cover costs

### Use ring:finops-analyzer for:
- ✅ **Understanding regulations** – What does BACEN require?
- ✅ **Compliance research** – How do we map our data?
- ✅ **Requirement analysis** – Which fields are required?
- ✅ **Validation** – Does our mapping match the spec?

### Use ring:finops-automation for:
- ✅ **Template creation** – Build .tpl files
- ✅ **Specification execution** – Convert analysis to templates
- ✅ **Reporter platform prep** – Generate deployment files
- ✅ **Production readiness** – Finalize compliance implementation

---

## Dispatching Multiple FinOps Agents

If you need both analysis and template generation, **dispatch sequentially** (analyze first, then automate):

```
Workflow:
Step 1: Dispatch ring:finops-analyzer
  └─ Returns: compliance analysis
Step 2: Dispatch ring:finops-automation
  └─ Returns: .tpl templates

Note: These must run sequentially because automation depends on analysis.
```

---

## ORCHESTRATOR Principle

Remember:
- **You're the orchestrator** – Dispatch agents, don't implement compliance manually
- **Don't write BACEN specs yourself** – Dispatch analyzer to understand
- **Don't generate templates by hand** – Dispatch automation agent
- **Combine with ring:using-ring principle** – Skills + Agents = complete workflow

### Good Example (ORCHESTRATOR):
> "I need BACEN compliance. Let me dispatch ring:finops-analyzer to understand requirements, then ring:finops-automation to generate templates."

### Bad Example (OPERATOR):
> "I'll manually read BACEN documentation and write templates myself."

---

## Reporter Platform Integration

Generated .tpl files integrate directly with Reporter platform:
- **Input:** Validated specifications from ring:finops-analyzer
- **Output:** .tpl files (XML, HTML, TXT formats)
- **Deployment:** Direct integration with Reporter
- **Validation:** Compliance verified by template structure

---

## Available in This Plugin

**Agents (3):**
- ring:infrastructure-cost-estimator (Infrastructure cost estimation)
- ring:finops-analyzer (Regulatory Gates 1-2)
- ring:finops-automation (Regulatory Gate 3)

**Skills (7):**
- using-finops-team (this skill - plugin introduction)
- infrastructure-cost-estimation (AWS cost estimation methodology)
- regulatory-templates (overview/index skill)
- regulatory-templates-setup (Gate 0: Setup & initialization)
- regulatory-templates-gate1 (Gate 1: Compliance analysis)
- regulatory-templates-gate2 (Gate 2: Field mapping & validation)
- regulatory-templates-gate3 (Gate 3: Template generation)

**Note:** If agents are unavailable, check if ring-finops-team is enabled in `.claude-plugin/marketplace.json`.

---

## Severity Calibration

**MUST classify FinOps issues using these severity levels:**

| Severity | Definition | Examples | Action |
|----------|------------|----------|--------|
| **CRITICAL** | BLOCKS regulatory submission OR cost estimation invalid | - Mandatory regulatory field unmapped<br>- Cost calculation produces negative values<br>- Agent unavailable for required gate<br>- Compliance violation detected | **HARD BLOCK** - Cannot proceed |
| **HIGH** | REQUIRES resolution for accurate output | - LOW confidence mappings > 20%<br>- Cost attribution model incorrect<br>- Template syntax errors<br>- Profitability calculation wrong | **MUST resolve** before completion |
| **MEDIUM** | SHOULD fix for optimal results | - Optional fields skipped<br>- Minor cost estimation assumptions<br>- Documentation incomplete<br>- Suboptimal template structure | **SHOULD fix** - document if deferred |
| **LOW** | Minor improvements possible | - Report formatting<br>- Additional breakdown detail<br>- Documentation enhancements | **OPTIONAL** - note in output |

---

## Blocker Criteria - STOP and Report

**You MUST distinguish between decisions you CAN make vs those requiring escalation.**

| Decision Type | Examples | Action |
|---------------|----------|--------|
| **Can Decide** | Agent selection, cost calculation methodology, template format | **Proceed with dispatch** |
| **MUST Escalate** | Agent unavailable, required input missing, ambiguous requirements | **STOP and ask for clarification** |
| **CANNOT Override** | Regulatory field requirements, cost accuracy standards, gate sequencing | **HARD BLOCK** - Must follow process |

**HARD GATES (STOP immediately):**

1. **Agent Unavailable:** Required FinOps agent not accessible
2. **Missing Input Data:** Cannot proceed without required information
3. **Regulatory Ambiguity:** Cannot determine compliance requirements
4. **Cost Data Invalid:** Pricing or configuration data missing

---

## Cannot Be Overridden

**NON-NEGOTIABLE requirements (no exceptions, no user override):**

| Requirement | Why NON-NEGOTIABLE | Verification |
|-------------|-------------------|--------------|
| **Agent-Based Execution** | Manual compliance work bypasses validation | Used Task tool with subagent_type |
| **Sequential Gates for Regulatory** | Gate dependencies require order | Gates run 1→2→3 |
| **Accurate Cost Attribution** | Wrong costs = wrong business decisions | Sharing model applied correctly |
| **100% Mandatory Field Coverage** | Regulatory submissions require ALL fields | All mandatory fields mapped |

**User CANNOT:**
- Skip gates in regulatory workflow ("just generate template" = NO)
- Ignore cost attribution model ("assume all shared" = NO)
- Bypass agent dispatch ("I'll do it manually" = NO)
- Accept partial regulatory coverage ("map critical only" = NO)

---

## Pressure Resistance

### FinOps-Specific Pressures

| User Says | Your Response |
|-----------|---------------|
| "Just estimate costs without reading Helm charts" | "I CANNOT produce accurate estimates without actual resource configurations. MUST read LerianStudio/helm for current CPU/memory values." |
| "Skip Gate 2, we trust Gate 1 analysis" | "I CANNOT skip Gate 2. Validation is MANDATORY to verify mappings before template generation. Gate 1 analysis ≠ Gate 2 validation." |
| "Assume all components shared for simplicity" | "I CANNOT assume sharing model. MUST ask for each component (PostgreSQL, DocumentDB, Valkey, etc.) - cost attribution depends on it." |
| "Regulatory template looks right, skip testing" | "I CANNOT skip testing. MUST validate with sample data per Gate 2 requirements. Visual inspection ≠ validated correctness." |
| "Use last month's cost estimates" | "I CANNOT reuse old estimates without verification. Helm configs change, pricing updates, requirements evolve. MUST recalculate." |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Cost estimation is straightforward, skip Helm read" | Actual values differ from defaults. Assumptions lead to budget overruns | **Read actual Helm chart configs** |
| "Gate 2 is redundant after good Gate 1 analysis" | Analysis ≠ validation. Gate 2 catches what Gate 1 missed | **Run all gates sequentially** |
| "All components are obviously shared" | Each component has different isolation requirements. Assumptions wrong | **Ask per-component sharing model** |
| "Manual template is faster than agent" | Manual bypasses validation layers. Agents apply systematic checks | **Use finops-automation agent** |
| "Previous estimate still valid" | Configurations change. Old estimates drift from reality | **Recalculate with current data** |
| "Only need critical regulatory fields" | BACEN/RFB require 100% mandatory coverage. Partial = rejected | **Map ALL mandatory fields** |

---

## When Not Needed

**MUST skip FinOps agents only when ALL conditions are true:**

| Condition | Verification Required |
|-----------|----------------------|
| 1. Non-Brazilian regulations | Confirm regulatory authority is NOT BACEN/RFB |
| 2. Non-AWS infrastructure | Confirm target is NOT AWS (adapt pricing formulas) |
| 3. One-time simple calculation | Direct math without component attribution |
| 4. Existing valid estimate | Previous estimate < 30 days AND no config changes |

**Signs You MUST Use FinOps Agents:**

- Brazilian regulatory template (BACEN CADOC, RFB e-Financeira, DIMP, Open Banking)
- Customer onboarding cost estimation
- Per-component cost attribution required
- Profitability analysis needed
- Regulatory compliance validation required

---

## Integration with Other Plugins

- **ring:using-ring** (default) – ORCHESTRATOR principle for ALL agents
- **ring:using-dev-team** – Developer specialists
- **ring:using-pm-team** – Pre-dev workflow agents

Dispatch based on your need:
- General code review → default plugin agents
- Regulatory compliance → ring-finops-team agents
- Developer expertise → ring-dev-team agents
- Feature planning → ring-pm-team agents
