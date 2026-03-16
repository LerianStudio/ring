---
name: infrastructure-cost-estimation
description: |
  Orchestrates infrastructure cost estimation with tier-based or custom TPS sizing.
  Offers pre-configured tiers (Starter/Growth/Business/Enterprise) or custom TPS input.
  Skill discovers components, asks shared/dedicated for EACH, selects environment(s),
  reads actual Helm chart configs, then dispatches agent for accurate calculations.
metadata:
  skip_when: |-
    - No docker-compose in repo → manual estimation needed
    - Non-AWS target → adapt pricing
  trigger: |
    - "How much will this cost on AWS?"
    - "Estimate infrastructure for [repo]"
    - "What should we charge the customer?"
    - "Is this deal profitable?"
    - Adding new customer to platform
  version: 6.0.0
---

# Infrastructure Cost Estimation

## Architecture: Skill Orchestrates, Agent Calculates

```
┌─────────────────────────────────────────────────────────────┐
│                    SKILL (Orchestrator)                     │
│                                                             │
│  Step 1: Select Products                                    │
│    - Access Manager: ALWAYS (shared platform)               │
│    - Core one Core: [YES / NO]                                 │
│    - Reporter: [YES / NO]                                   │
│                                                             │
│  Step 2: Basic Info                                         │
│    - Repo path, Total customers                             │
│                                                             │
│  Step 2a: Infrastructure Sizing (NEW in v6.0)               │
│    - Option 1: Tier (Starter/Growth/Business/Enterprise)    │
│    - Option 2: Custom TPS (backwards compatible)            │
│                                                             │
│  Step 3: Select Environment(s) to Calculate                 │
│    - [x] Homolog (us-east-2, Single-AZ, 1 replica)         │
│    - [x] Production (sa-east-1, Multi-AZ, 3 replicas)      │
│                                                             │
│  Step 4: Read Helm Charts (for selected products only)      │
│    - ALWAYS: charts/plugin-access-manager/values.yaml       │
│    - If Core one: charts/midaz/values.yaml                     │
│    - If Reporter: charts/reporter/values.yaml               │
│                                                             │
│  Step 5: Ask PER COMPONENT: Shared or Dedicated?            │
│    - VPC, EKS, PostgreSQL, Valkey, etc.                     │
│                                                             │
│  Steps 6-7: Database Config + Billing Model                 │
│                                                             │
│  ↓ All data collected (products + tier/TPS + Helm configs)  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    AGENT (Calculator)                       │
│                                                             │
│  Receives: Products + Tier/TPS + Helm configs → Calculates: │
│  - Infrastructure costs PER ENVIRONMENT (Homolog + Prod)    │
│  - EKS node sizing from tier config OR actual CPU/memory    │
│  - Cost attribution (shared ÷ customers, dedicated = full)  │
│  - Access Manager costs ALWAYS shared across ALL customers  │
│  - Profitability analysis (using combined env costs)        │
│                                                             │
│  Returns: Side-by-side Homolog vs Production breakdown      │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 1: Select Products for This Customer

**Ask which products the customer needs:**

| Product | Selection | Sharing | Services |
|---------|-----------|---------|----------|
| **Access Manager** | ALWAYS INCLUDED | ALWAYS SHARED | identity, auth |
| **Core one Core** | Required | Customer choice | onboarding, transaction, ledger, crm |
| **Reporter** | Optional | Customer choice | manager, worker, frontend |

**Use AskUserQuestion for product selection:**
```
AskUserQuestion:
  question: "Which products does this customer need? (Access Manager is always included)"
  header: "Products"
  multiSelect: true
  options:
    - label: "Core one Core + Reporter (Recommended)"
      description: "Full platform: ledger + regulatory reporting"
    - label: "Core one Core only"
      description: "Base ledger platform without reporting"
```

**Product → Helm Chart Mapping:**

| Product | Helm Chart | Always Read |
|---------|------------|-------------|
| Access Manager | `charts/plugin-access-manager/values.yaml` | YES (always shared) |
| Core one Core | `charts/midaz/values.yaml` | If selected |
| Reporter | `charts/reporter/values.yaml` | If selected |

---

## Step 2: Gather Basic Information

| Input | Required | Question | Example |
|-------|----------|----------|---------|
| **Repo Path** | Yes | "What is the application repository path?" | `/workspace/midaz` |
| **Helm Charts Repo** | Optional | "Path to LerianStudio/helm repository?" | `/workspace/helm` |
| **Total Customers** | Yes | "How many customers share the platform?" | `5` |

**Why Helm Charts Repo?** LerianStudio/helm contains actual CPU/memory configurations per service. Without it, the agent uses Core one default values.

**Note:** TPS/Tier selection moved to Step 2a below.

---

## Step 2a: Select Infrastructure Sizing Method (NEW in v6.0)

**Choose between pre-configured tier or custom TPS:**

### 2a.1: Ask Sizing Method

```
AskUserQuestion:
  question: "How would you like to size the infrastructure?"
  header: "Sizing Method"
  multiSelect: false
  options:
    - label: "Pre-configured Tier (Recommended)"
      description: "Choose optimized tier by TPS range - faster, cost-optimized"
    - label: "Custom TPS"
      description: "Specify exact TPS for custom infrastructure sizing"
```

### 2a.2: If "Pre-configured Tier" Selected

```
AskUserQuestion:
  question: "Which infrastructure tier matches your expected traffic?"
  header: "Tier"
  multiSelect: false
  options:
    - label: "Starter (50-100 TPS) - ~R$ 11.7k/mo"
      description: "Small deployments, POC, single tenant. 2× c6i.large nodes."
    - label: "Growth (100-500 TPS) - ~R$ 19.3k/mo"
      description: "Growing business, moderate traffic. 3× c6i.xlarge nodes."
    - label: "Business (500-1,500 TPS) - ~R$ 27.5k/mo (Recommended)"
      description: "Production app, full HA. 4× c6i.xlarge nodes, Multi-AZ."
    - label: "Enterprise (1,500-5,000 TPS) - ~R$ 56.7k/mo"
      description: "Mission critical, high performance. 8× c6i.2xlarge nodes."
```

**Tier Reference:** See [infrastructure-tiers-by-tps.md](../../docs/infrastructure-tiers-by-tps.md) for detailed tier specifications.

**Tier Configurations (stored for agent dispatch):**

| Tier | Target TPS | Max Capacity | Prod Nodes | Prod Replicas (auth) |
|------|-----------|--------------|------------|---------------------|
| Starter | 100 | 670 | 2× c6i.large | 1 |
| Growth | 500 | 1,340 | 3× c6i.xlarge | 2 |
| Business | 1,500 | 2,010 | 4× c6i.xlarge | 3 |
| Enterprise | 5,000 | 6,030 | 8× c6i.2xlarge | 9 |

### 2a.3: If "Custom TPS" Selected

```
AskUserQuestion:
  question: "What is the expected TPS (transactions per second)?"
  header: "TPS"
  multiSelect: false
  options:
    - label: "50 TPS"
      description: "Low traffic, testing"
    - label: "150 TPS"
      description: "Small to medium traffic"
    - label: "500 TPS"
      description: "Medium to high traffic"
    - label: "Custom value"
      description: "I'll specify exact TPS"
```

**Custom TPS Calculation:**
- Agent will calculate required replicas: `(TPS ÷ 670) × 1.25` for auth service
- Agent will size EKS nodes based on total CPU/memory requirements
- More flexible but requires more calculation

---

## Step 3: Select Environment(s) to Calculate

**Ask which environments need cost estimation:**

| Environment | Region | Configuration | Use Case |
|-------------|--------|---------------|----------|
| **Homolog** | us-east-2 (Ohio) | Single-AZ, 1 replica, ~35% cheaper | Testing, staging |
| **Production** | sa-east-1 (São Paulo) | Multi-AZ, 3 replicas, full HA | Live traffic |

**Use AskUserQuestion for environment selection:**
```
AskUserQuestion:
  question: "Which environments should be estimated?"
  header: "Environments"
  multiSelect: true
  options:
    - label: "Both (Recommended)"
      description: "Calculate Homolog + Production costs for complete picture"
    - label: "Production only"
      description: "Calculate only production environment (São Paulo)"
    - label: "Homolog only"
      description: "Calculate only homolog/staging environment (Ohio)"
```

**Environment Differences:**

| Aspect | Homolog | Production |
|--------|---------|------------|
| **Region** | us-east-2 (Ohio) | sa-east-1 (São Paulo) |
| **Pricing** | ~35% cheaper | Full price |
| **Replicas** | 1 per service | 3 per service (HA) |
| **Database** | Single-AZ | Multi-AZ + Read Replicas |
| **NAT Gateways** | 1 (single AZ) | 3 (one per AZ) |

---

## Step 4: Read Selected Product Helm Charts

### 4a. Always Read Access Manager (ALWAYS SHARED)

**Access Manager is platform-level infrastructure - ALWAYS included, ALWAYS shared across all customers.**

```
ALWAYS READ: charts/plugin-access-manager/values.yaml

Services:
- identity (100m CPU, 128Mi memory)
- auth (500m CPU, 256Mi memory)

Infrastructure (shared):
- auth-database (PostgreSQL for Casdoor)
- valkey (session cache)
```

**Cost Attribution:** Access Manager costs are ALWAYS divided by total platform customers.

### 4b. Read Selected Products (Based on Step 1)

**Read ONLY the Helm charts for products selected in Step 1:**

| Product Selected | Helm Chart to Read | Services |
|------------------|-------------------|----------|
| **Core one Core** (if selected) | `charts/midaz/values.yaml` | onboarding, transaction, ledger, crm |
| **Reporter** (if selected) | `charts/reporter/values.yaml` | manager, worker, frontend |

**Example - Customer selected "Core one Core + Reporter":**
```
Read: charts/plugin-access-manager/values.yaml  → ALWAYS (shared platform)
Read: charts/midaz/values.yaml                  → Selected
Read: charts/reporter/values.yaml               → Selected
```

**Example - Customer selected "Core one Core only":**
```
Read: charts/plugin-access-manager/values.yaml  → ALWAYS (shared platform)
Read: charts/midaz/values.yaml                  → Selected
Skip: charts/reporter/values.yaml               → Not selected
```

### 4c. Extract Resource Configurations

**Source:** `git@github.com:LerianStudio/helm.git`

**For each service, extract:**
```yaml
resources:
  requests:
    cpu: ???m      # CPU request in millicores
    memory: ???Mi  # Memory request
autoscaling:
  minReplicas: ?   # Minimum replicas
  maxReplicas: ?   # Maximum replicas
```

**Example from LerianStudio/helm values.yaml:**
```yaml
transaction:
  replicaCount: 3
  resources:
    requests:
      cpu: 2000m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 512Mi
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 9
```

**If no Helm repo available**, use Core one default values from this document.

### 4d. Read Actual Resources (DYNAMIC - from LerianStudio/helm)

**MUST read actual values at runtime - DO NOT use hardcoded values.**

**Source Repository:** `git@github.com:LerianStudio/helm.git`

**Files to Read:**

| Chart | Path | Services |
|-------|------|----------|
| **Core one Core** | `charts/midaz/values.yaml` | onboarding, transaction, ledger, crm |
| **Reporter** | `charts/reporter/values.yaml` | manager, worker, frontend |
| **Access Manager** | `charts/plugin-access-manager/values.yaml` | identity, auth |

**What to Extract per Service:**

```yaml
# For each service, extract:
resources:
  requests:
    cpu: ???m      # CPU request in millicores
    memory: ???Mi  # Memory request
  limits:
    cpu: ???m      # CPU limit
    memory: ???Mi  # Memory limit

autoscaling:
  minReplicas: ?   # Minimum replicas
  maxReplicas: ?   # Maximum replicas

# For databases (postgresql, mongodb, valkey, rabbitmq):
# Look for resourcesPreset or explicit resources block
```

**How to Read:**

1. If local clone exists: `Read tool` on values.yaml files
2. If no local clone: `WebFetch` from GitHub raw URLs:
   - `https://raw.githubusercontent.com/LerianStudio/helm/main/charts/midaz/values.yaml`
   - `https://raw.githubusercontent.com/LerianStudio/helm/main/charts/reporter/values.yaml`
   - `https://raw.githubusercontent.com/LerianStudio/helm/main/charts/plugin-access-manager/values.yaml`

**Fallback:** If plugin/service not found, use Core one core setup as baseline.

---

## Step 5: Ask Per-Component Sharing Model (CRITICAL)

<critical-warning>
⛔ **HARD GATE: MUST ASK ABOUT ALL DATABASE COMPONENTS**

This step requires asking about **BOTH** database types in a SINGLE question:
- **PostgreSQL** (RDS) - Relational database
- **DocumentDB** (MongoDB) - Document database

**FORBIDDEN:** Asking only about PostgreSQL and forgetting DocumentDB.
**REQUIRED:** Use the multiSelect AskUserQuestion with ALL components listed.
</critical-warning>

> **Reference:** See [infrastructure-cost-estimation-guide.md](../../docs/infrastructure-cost-estimation-guide.md#component-sharing-model-critical-input) for:
> - Sharing model definitions (SHARED vs DEDICATED vs ALWAYS SHARED)
> - How sharing works in practice per component
> - NAT Gateway architecture (ALWAYS SHARED)

**Components That MUST Be Asked:**
1. VPC, 2. EKS Nodes, 3. **PostgreSQL**, 4. **DocumentDB**, 5. Valkey, 6. RabbitMQ

**Note:** NAT Gateway and ALB are ALWAYS SHARED (platform-level resources).

**MANDATORY: Use AskUserQuestion tool with multiSelect:**

```
AskUserQuestion:
  question: "Which components need DEDICATED instances? (All others use schema-based sharing)"
  header: "Dedicated"
  multiSelect: true
  options:
    - label: "VPC"
      description: "Fully isolated network (separate VPC per customer)"
    - label: "PostgreSQL"
      description: "Fully isolated RDS instance (not schema-based)"
    - label: "DocumentDB"
      description: "Fully isolated DocumentDB cluster"
    - label: "Valkey"
      description: "Fully isolated ElastiCache cluster"
    - label: "RabbitMQ"
      description: "Fully isolated Amazon MQ broker"
    - label: "EKS Nodes"
      description: "Dedicated compute nodes (separate node group)"
```

**Step 5 Verification Checklist:**
```
[ ] Used multiSelect question (not individual questions per component)
[ ] PostgreSQL included in options
[ ] DocumentDB included in options
[ ] All 6 configurable components listed
[ ] User response captured for ALL components

If any checkbox is NO → STOP and fix before proceeding to Step 6.
```

---

## Step 6: Database Configuration (Production Only)

**For PRODUCTION environment, ask about database HA configuration:**

### Multi-AZ (High Availability)

| Option | Description | Cost Impact |
|--------|-------------|-------------|
| **Multi-AZ = YES** | Automatic failover, standby in different AZ | 2x database cost |
| **Multi-AZ = NO** | No automatic failover | 1x database cost |

**Default:** Production = Multi-AZ YES, Homolog = Multi-AZ NO

### Read Replicas (Scale Reads)

| TPS Range | Recommended Replicas | Why |
|-----------|---------------------|-----|
| < 100 TPS | 0 replicas | Primary can handle load |
| 100-300 TPS | 1 replica | Offload read queries |
| > 300 TPS | 2 replicas | Distribute read load |

**Use AskUserQuestion for database HA:**
```
AskUserQuestion:
  question: "For PRODUCTION databases, what HA configuration?"
  header: "Database HA"
  multiSelect: false
  options:
    - label: "Multi-AZ + Read Replicas (Recommended)"
      description: "Full HA: automatic failover + read scaling"
    - label: "Multi-AZ only"
      description: "Automatic failover, no read replicas"
    - label: "Single-AZ (Not recommended)"
      description: "No HA - only for cost-sensitive scenarios"
```

**Note:** Homolog/Staging always uses Single-AZ, no read replicas (testing only).

---

## Step 6b: Backup Configuration (Per Environment)

**Backup policies differ significantly between Homolog and Production:**

### Backup Types

| Backup Type | Description | AWS Service |
|-------------|-------------|-------------|
| **RDS Automated Backups** | Point-in-Time Recovery (PITR) | Included in RDS |
| **RDS Snapshots** | Manual/scheduled full backups | RDS Snapshots |
| **S3 Application Backups** | Application data exports | S3 Standard |
| **DocumentDB Backups** | Continuous backup + snapshots | DocumentDB |

### Environment-Specific Defaults

| Environment | Backup Type | Retention | PITR | Cost |
|-------------|-------------|-----------|------|------|
| **Homolog** | Automated only | 1-7 days | No | Minimal |
| **Production** | Full (automated + snapshots) | 7-35 days | Yes | Higher |

### Backup Cost Components

| Component | Pricing | Notes |
|-----------|---------|-------|
| **RDS Automated Backup** | Free up to DB size | Beyond DB size: R$ 0.10/GB/month |
| **RDS Snapshots** | R$ 0.10/GB/month | Per snapshot retained |
| **S3 Standard** | R$ 0.12/GB/month | Application backups |
| **S3 Glacier** | R$ 0.02/GB/month | Archive (30+ days) |
| **DocumentDB Backup** | R$ 0.10/GB/month | Beyond retention period |

### Backup Sizing by TPS

| TPS | DB Storage | Homolog Backup | Production Backup | S3 App Backup |
|-----|------------|----------------|-------------------|---------------|
| **1-50** | 50GB | ~0 (free tier) | ~50GB × 2 snapshots | 25GB |
| **50-200** | 150GB | ~0 (free tier) | ~150GB × 3 snapshots | 75GB |
| **200-500** | 500GB | ~50GB (excess) | ~500GB × 4 snapshots | 250GB |

### Backup Configuration Questions

**Use AskUserQuestion for backup policy:**
```
AskUserQuestion:
  question: "What backup retention policy for PRODUCTION?"
  header: "Backup Policy"
  multiSelect: false
  options:
    - label: "Standard (7-day retention, daily snapshots) (Recommended)"
      description: "7-day PITR + 7 daily snapshots (moderate cost)"
    - label: "Extended (35-day retention, daily + weekly snapshots)"
      description: "35-day PITR + daily/weekly snapshots (higher cost)"
    - label: "Minimal (1-day retention, weekly snapshots)"
      description: "1-day PITR + weekly snapshots (lower cost, higher risk)"
```

**Homolog Backup Policy:**
- Always minimal (1-7 day retention)
- No additional snapshots needed (testing environment)
- Cost: Typically free (within RDS automated backup limit)

---

## Step 7: Gather Billing Model

| Input | Question | Example |
|-------|----------|---------|
| **Billing Unit** | "What is the billing unit?" | `transaction` |
| **Price per Unit** | "What price per unit?" | `R$ 0.10` |
| **Expected Volume** | "Expected monthly volume?" | `1,000,000` |

---

## Step 8: Dispatch Agent with Complete Data

**BEFORE dispatching, skill MUST read actual resource configs:**

### 8a. Read Current Values from LerianStudio/helm (Based on Selected Products)

```
# ALWAYS read (platform-level, shared)
Read: charts/plugin-access-manager/values.yaml → Extract: identity, auth resources

# Read based on product selection (Step 1)
If Core one Core selected:
  Read: charts/midaz/values.yaml → Extract: onboarding, transaction, ledger, crm resources

If Reporter selected:
  Read: charts/reporter/values.yaml → Extract: manager, worker, frontend resources

# Also extract database configurations for selected products
```

### 8b. Dispatch Agent with Collected Data

**Only dispatch AFTER reading actual values for selected products.**

**Two dispatch patterns:**
1. **Tier-based** (user selected pre-configured tier)
2. **Custom TPS** (user specified exact TPS)

---

#### Pattern 1: Tier-Based Dispatch

**If user selected a tier in Step 2a, provide tier configuration:**

```
Task tool:
  subagent_type: "ring:infrastructure-cost-estimator"
  prompt: |
    Calculate infrastructure costs using PRE-CONFIGURED TIER.

    Tier: BUSINESS (500-1,500 TPS)
    Target TPS: 1,500
    Max Capacity: 2,010 TPS

    Tier Configuration:
    Production:
      Replicas: auth=3, transaction=3, onboarding=2, identity=1, auth-backend=1
      Nodes: 4× c6i.xlarge (4 vCPU, 8 GiB each)
      Databases:
        - auth-postgresql: db.m7g.large (Multi-AZ + 1 replica)
        - midaz-postgresql: db.m7g.large (Multi-AZ + 1 replica)
        - documentdb: db.r8g.large (Multi-AZ + 1 replica)
      Cache:
        - auth-valkey: cache.m7g.large (Multi-AZ)
        - midaz-valkey: cache.m7g.large (Multi-AZ)
      Queue:
        - rabbitmq: mq.m7g.large (active/standby)

    Homolog:
      Nodes: 2× c6i.xlarge
      Databases: All db.m7g.large (Single-AZ)

    Products Selected:
    - Access Manager: ALWAYS INCLUDED (shared platform)
    - Core one Core: YES
    - Reporter: NO

    Infrastructure:
    - App Repo: /workspace/midaz
    - Total Customers on Platform: 5

    Environments to Calculate: [Homolog, Production]

    Actual Resource Configurations (from Helm charts):
    [INSERT VALUES FROM charts/plugin-access-manager/values.yaml]
    [INSERT VALUES FROM charts/midaz/values.yaml]

    Component Sharing Model:
    [... same as before ...]

    Database Configuration:
    [... same as before ...]

    Billing Model:
    [... same as before ...]

    Calculate and return:
    [... same 11 sections as before ...]
```

---

#### Pattern 2: Custom TPS Dispatch

**If user specified custom TPS, agent calculates infrastructure:**

```
Task tool:
  subagent_type: "ring:infrastructure-cost-estimator"
  prompt: |
    Calculate infrastructure costs for CUSTOM TPS.

    TPS: 750 (custom)

    Calculate required infrastructure:
    - Required auth replicas = (750 ÷ 670) × 1.25 = ~2 replicas
    - Required transaction replicas = (750 ÷ 815) × 1.25 = ~2 replicas
    - Calculate EKS node sizing from total CPU/memory requirements
    - Use appropriate database instance sizes for traffic level

    Products Selected:
    - Access Manager: ALWAYS INCLUDED (shared platform)
    - Core one Core: YES
    - Reporter: NO

    Infrastructure:
    - App Repo: /workspace/midaz
    - Helm Charts Source: LerianStudio/helm
    - Total Customers on Platform: 5

    Environments to Calculate: [Homolog, Production]

    Actual Resource Configurations (from Helm charts):
    [INSERT VALUES FROM charts/plugin-access-manager/values.yaml]
    [INSERT VALUES FROM charts/midaz/values.yaml]

    Component Sharing Model:
    [... same as before ...]

    Database Configuration:
    [... same as before ...]

    Billing Model:
    [... same as before ...]

    Calculate and return:
    [... same 11 sections as before ...]
```

**Note:** Custom TPS dispatch is backwards compatible with v5.0.

---

## Quick Reference

> **Pricing Tables:** See [infrastructure-cost-estimation-guide.md](../../docs/infrastructure-cost-estimation-guide.md#pricing-reference) for complete AWS pricing (São Paulo and Ohio regions).

---

## Expected Output Sections (from Agent)

> **Full Output Format:** See [infrastructure-cost-estimation-guide.md](../../docs/infrastructure-cost-estimation-guide.md#outputs) for detailed output section descriptions.

The agent returns 11 required sections:
1. Discovered Services
2. Compute Resources (from LerianStudio/helm)
3. Homolog Environment Costs
4. Production Environment Costs
5. Environment Comparison
6. Infrastructure Components (Consolidated)
7. Cost by Category
8. Shared vs Dedicated Summary
9. TPS Capacity Analysis
10. Profitability Analysis (Combined Environments)
11. Summary

---

## Example Workflow

### User Request:
> "Estimate costs for Core one with 100 TPS, 5 customers sharing, PostgreSQL dedicated"

### Step 1: Select Products
```
Products Selected:
- Access Manager: ALWAYS INCLUDED (shared)
- Core one Core: YES
- Reporter: YES (full platform)
```

### Step 2: Basic Info
```
Repo: /workspace/midaz
Total Customers: 5
```

### Step 2a: Sizing Method
```
User selected: "Pre-configured Tier"
Tier: STARTER (50-100 TPS)
```

### Steps 3-7: Skill Gathers Data
```
Environments: Both (Homolog + Production)

Component Sharing:
- EKS Cluster: SHARED (5)
- PostgreSQL: DEDICATED (1)  ← user specified
- Valkey: SHARED (5)
- DocumentDB: SHARED (5)
- RabbitMQ: SHARED (5)

Billing:
- Unit: transaction
- Price: R$ 0.10
- Volume: 1,000,000/month
```

### Step 8a: Skill Reads LerianStudio/helm (for selected products)
```
# ALWAYS read (platform-level)
Read: charts/plugin-access-manager/values.yaml
  → identity: 100m CPU, 128Mi memory, 1-3 replicas
  → auth: 500m CPU, 256Mi memory, 3-9 replicas

# Core one Core (selected)
Read: charts/midaz/values.yaml
  → onboarding: 1500m CPU, 512Mi memory, 2-5 replicas
  → transaction: 2000m CPU, 512Mi memory, 3-9 replicas
  → ledger: 1500m CPU, 256Mi memory, 2-9 replicas

# Reporter (selected)
Read: charts/reporter/values.yaml
  → manager: 100m CPU, 256Mi memory
  → worker: 100m CPU, 128Mi memory
  → frontend: 100m CPU, 128Mi memory
```

### Step 8b: Skill Dispatches Agent
```
Agent receives: Products selected + actual Helm values + all collected data
```

### Agent Returns:
```
## Summary

| Metric | Value |
|--------|-------|
| Shared Infrastructure | R$ 1,018/customer |
| Dedicated Infrastructure | R$ 1,490/customer |
| **Total Cost/Customer** | **R$ 2,508/month** |
| Monthly Revenue | R$ 100,000 |
| Gross Profit | R$ 97,492 |
| Gross Margin | 97.5% |
```

---

---

## Severity Calibration

**MUST classify cost estimation issues using these severity levels:**

| Severity | Definition | Examples | Impact |
|----------|------------|----------|--------|
| **CRITICAL** | BLOCKS cost estimation OR produces invalid results | - Helm chart data unavailable<br>- No service discovery possible<br>- Pricing data missing<br>- Sharing model undefined | **HARD BLOCK** - Cannot produce estimate |
| **HIGH** | REQUIRES resolution for accurate estimate | - Partial Helm data only<br>- Some components missing from model<br>- TPS capacity mismatch<br>- Billing data incomplete | **MUST resolve** before final estimate |
| **MEDIUM** | SHOULD address for optimal accuracy | - Using default values (Helm unavailable)<br>- Assumptions documented but unverified<br>- Minor data gaps filled with estimates | **SHOULD address** - document assumptions |
| **LOW** | Minor improvements possible | - Additional breakdown detail<br>- Report formatting<br>- Supplementary analysis | **OPTIONAL** - note in summary |

**Classification Rules:**

**CRITICAL = ANY of:**
- Cannot read ANY Helm chart (no resource data)
- Sharing model not provided for ANY component
- Missing required billing data (unit, price, volume)
- Service discovery produces zero services

**HIGH = ANY of:**
- Missing Helm data for specific products (Core one, Reporter, Access Manager)
- Component sharing model incomplete (some components undefined)
- TPS value inconsistent with tier selection
- Database or backup configuration ambiguous

---

## Blocker Criteria - STOP and Report

**You MUST distinguish between decisions you CAN make vs those requiring escalation.**

| Decision Type | Examples | Action |
|---------------|----------|--------|
| **Can Decide** | Default backup retention, tier recommendation, calculation methodology | **Proceed with estimation** |
| **MUST Escalate** | Helm charts inaccessible, ambiguous sharing model, conflicting TPS requirements | **STOP and ask for clarification** |
| **CANNOT Override** | Per-component sharing question, environment selection, actual Helm values over defaults, complete billing data | **HARD BLOCK** - Must collect first |

**HARD GATES (STOP immediately):**

1. **No Helm Access:** Cannot read LerianStudio/helm charts
2. **Missing Sharing Model:** Component sharing not specified
3. **Incomplete Billing:** Unit, price, or volume missing
4. **Zero Services:** Service discovery found nothing

**Escalation Message Template:**
```markdown
⛔ **COST ESTIMATION BLOCKER**

**Issue:** [Specific blocker]
**Impact:** [What cannot be calculated]
**Required:** [What needs to be provided]

**Cannot dispatch agent until resolved.**
```

---

## Pressure Resistance

### Cost Estimation-Specific Pressures

| User Says | Your Response |
|-----------|---------------|
| "Just estimate without Helm charts" | "I CANNOT produce accurate estimates without actual resource configurations. Default values may differ significantly from actual deployment. Let me attempt to read LerianStudio/helm first." |
| "Assume all components shared" | "I CANNOT assume sharing model. MUST ask for each component explicitly. PostgreSQL DEDICATED vs SHARED changes cost by R$1,000+/month." |
| "Skip environment selection, just do production" | "I MUST confirm which environments to calculate. Most customers need BOTH Homolog + Production. Combined cost is the realistic budget." |
| "Use last month's Helm values" | "I CANNOT use cached values. MUST read current Helm charts - configurations change frequently. 5-minute read prevents budget surprises." |
| "DocumentDB same as PostgreSQL" | "I CANNOT assume database sharing models match. MUST ask about PostgreSQL AND DocumentDB separately - different isolation requirements common." |
| "Skip profitability, just give costs" | "I SHOULD include profitability analysis. It takes 30 seconds and answers the real question: Is this deal worth pursuing?" |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Assume all components are shared" | Customer may have dedicated DB | **ASK for each component** |
| "Skip component questions" | Cost attribution will be wrong | **MUST ask shared/dedicated** |
| "Agent can figure it out" | Agent calculates, skill orchestrates | **Skill collects all data** |
| "Just use total customers" | Some components may be dedicated | **Per-component model required** |
| "Asked about PostgreSQL, that covers databases" | **PostgreSQL ≠ DocumentDB** - they are separate components with different costs | **MUST ask about BOTH PostgreSQL AND DocumentDB** |
| "DocumentDB is obviously shared/dedicated like PostgreSQL" | Customer may want different isolation levels for different data types | **Ask about each database separately in multiSelect** |
| "I'll ask about databases separately" | Separate questions risk forgetting one | **Use single multiSelect with ALL components** |
| "Default Helm values are close enough" | Actual configs often differ 2-3x from defaults | **Read actual Helm chart values** |
| "Skip environment comparison" | Customers need both Homolog + Production costs | **Calculate BOTH environments** |

---

## Checklist Before Dispatch

```
STEP 1 - PRODUCTS:
[ ] Products selected (Core one Core, Reporter)?
[ ] Access Manager included (ALWAYS)?

STEP 2 - BASIC INFO:
[ ] Repo path collected?
[ ] Total customers collected?

STEP 2a - SIZING (NEW in v6.0):
[ ] Sizing method selected (Tier OR Custom TPS)?
  If Tier:
    [ ] Tier selected (Starter/Growth/Business/Enterprise)?
  If Custom TPS:
    [ ] TPS value collected?

STEP 3 - ENVIRONMENTS:
[ ] Environments selected (Homolog, Production, Both)?

STEP 4 - HELM CHARTS:
[ ] LerianStudio/helm values read for selected products?

STEP 5 - COMPONENT SHARING (CRITICAL):
DATABASE COMPONENTS - verify BOTH:
[ ] PostgreSQL sharing model collected? (SHARED or DEDICATED)
[ ] DocumentDB sharing model collected? (SHARED or DEDICATED)

OTHER COMPONENTS:
[ ] VPC sharing model collected?
[ ] EKS Nodes sharing model collected?
[ ] Valkey sharing model collected?
[ ] RabbitMQ sharing model collected?

STEP 6-7 - DATABASE & BILLING:
[ ] Database HA configuration collected?
[ ] Backup policy collected?
[ ] Billing unit collected?
[ ] Price per unit collected?
[ ] Expected volume collected?

If any NO → Ask user first, then dispatch.
⛔ If PostgreSQL OR DocumentDB is missing → STOP and ask about BOTH databases.
```
