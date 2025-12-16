---
name: using-ops-team
description: |
  5 specialist operations agents for platform engineering, incident response,
  cloud cost optimization, infrastructure architecture, and security operations.
  Dispatch when you need production operations expertise.

trigger: |
  - Production incident management -> incident-responder
  - Platform/service mesh operations -> platform-engineer
  - Cloud cost analysis and optimization -> cloud-cost-optimizer
  - Infrastructure design/capacity/DR -> infrastructure-architect
  - Security audits and compliance -> security-operations

skip_when: |
  - Development infrastructure (IaC, Docker) -> use devops-engineer
  - Application development -> use ring-dev-team specialists
  - Code review -> use ring-default reviewers

related:
  similar: [using-ring, using-dev-team]
---

# Using Ring Operations Specialists

The ring-ops-team plugin provides 5 specialized operations agents. Use them via `Task tool with subagent_type:`.

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) and [using-ring](https://raw.githubusercontent.com/LerianStudio/ring/main/default/skills/using-ring/SKILL.md) for canonical workflow requirements and ORCHESTRATOR principle. This skill introduces ops-team-specific agents.

**Remember:** Follow the **ORCHESTRATOR principle** from `using-ring`. Dispatch agents to handle complexity; don't operate tools directly.

---

## Domain Distinction: ops-team vs dev-team

**CRITICAL:** Understand when to use each plugin:

| Domain | Plugin | Agents |
|--------|--------|--------|
| **Development Infrastructure** | ring-dev-team | devops-engineer (Docker, IaC, CI/CD) |
| **Production Operations** | ring-ops-team | platform-engineer, incident-responder, etc. |

| Scenario | Use |
|----------|-----|
| "Set up Dockerfile and docker-compose" | `devops-engineer` |
| "Configure service mesh for production" | `platform-engineer` |
| "Create Terraform modules" | `devops-engineer` |
| "Design multi-region architecture" | `infrastructure-architect` |
| "Handle production outage" | `incident-responder` |
| "Optimize cloud costs" | `cloud-cost-optimizer` |

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Decision Type | Examples | Action |
|--------------|----------|--------|
| **Production Changes** | Infrastructure modifications | STOP. Change management required. Ask user. |
| **Security Incidents** | Potential breach | STOP. Security team lead + legal. |
| **Cost Commitments** | Reserved instance purchases | STOP. Finance approval required. |
| **Architecture Decisions** | Region selection, DR strategy | STOP. Strategic decision. Ask user. |

**You CANNOT make production-impacting decisions autonomously. STOP and ask.**

---

## Common Misconceptions - REJECTED

| Misconception | Reality |
|--------------|---------|
| "I can handle this myself" | ORCHESTRATOR principle: dispatch specialists, don't implement directly. This is NON-NEGOTIABLE. |
| "Ops tasks are simple" | Operations has production impact. Specialist oversight is MANDATORY. |
| "Same as DevOps" | dev-team DevOps handles development infrastructure. ops-team handles production operations. |
| "Cost analysis is just math" | Cost optimization requires business context and risk assessment. DISPATCH specialist. |
| "Security is handled by dev reviewers" | Security-reviewer handles code. security-operations handles infrastructure security. BOTH needed. |

**Self-sufficiency bias check:** If you're tempted to handle operations directly, ask:
1. Is there a specialist for this? (Check the 5 specialists below)
2. Does this affect production systems?
3. Am I avoiding dispatch because it feels like "overhead"?

**If ANY answer is yes -> You MUST DISPATCH the specialist. This is NON-NEGOTIABLE.**

---

## Anti-Rationalization Table

**If you catch yourself thinking ANY of these, STOP:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This is a small operations task" | Small tasks can cause big outages | **DISPATCH specialist** |
| "I already know how to do this" | Your knowledge != production context | **DISPATCH specialist** |
| "Just checking logs/metrics" | Log analysis requires domain expertise | **DISPATCH specialist** |
| "Cost report is straightforward" | Cost optimization needs risk assessment | **DISPATCH specialist** |
| "Security scan results are clear" | Findings need prioritization and context | **DISPATCH specialist** |
| "Incident seems minor" | Minor incidents can escalate. Proper triage required. | **DISPATCH incident-responder** |

---

### Cannot Be Overridden

**These requirements are NON-NEGOTIABLE:**

| Requirement | Why It Cannot Be Waived |
|-------------|------------------------|
| **Dispatch to specialist** | Specialists have production context |
| **Incident documentation** | Memory fades, audit trails required |
| **Change management** | Production changes need oversight |
| **Security escalation** | Security incidents have legal implications |
| **Cost approval chain** | Financial commitments need authorization |

**User cannot override these. Time pressure cannot override these. "Small task" cannot override these.**

---

## Pressure Resistance

**When facing pressure to bypass specialist dispatch:**

| User Says | Your Response |
|-----------|---------------|
| "Production is down, no time for specialist" | "I understand the urgency. Specialist dispatch ensures proper incident response. Dispatching incident-responder with URGENT context now." |
| "Just restart the service quickly" | "Production restarts require change management. Dispatching incident-responder to assess proper remediation." |
| "Cost analysis can wait" | "Cost optimization opportunities have time-value. Dispatching cloud-cost-optimizer for data-driven analysis." |
| "Security finding is false positive" | "All security findings require verified documentation. Dispatching security-operations to properly assess." |
| "I know the architecture, skip review" | "Architecture decisions have long-term impact. Dispatching infrastructure-architect to validate." |

**Critical Reminder:**
- **Urgency != Permission to bypass** - Emergencies require MORE care, not less
- **Authority != Permission to bypass** - Ring standards override human preferences
- **Familiarity != Permission to bypass** - Production context differs from assumptions

---

## 5 Operations Specialists

| Agent | Specializations | Use When |
|-------|-----------------|----------|
| **`platform-engineer`** | Service mesh, API gateways, developer platforms, self-service infrastructure | Service mesh config, API gateway setup, platform abstractions, developer portals |
| **`incident-responder`** | Incident management, RCA, post-mortems, blameless culture | Production incidents, outages, incident coordination, root cause analysis |
| **`cloud-cost-optimizer`** | Cost analysis, RI management, FinOps, tagging | Cost reviews, optimization recommendations, reserved instance planning |
| **`infrastructure-architect`** | Multi-region, DR, capacity planning, migrations | Architecture design, DR strategy, capacity planning, infrastructure lifecycle |
| **`security-operations`** | Security audits, compliance, vulnerability management | Security assessments, compliance validation, vulnerability remediation |

**Dispatch template:**
```
Task tool:
  subagent_type: "{agent-name}"
  model: "opus"
  prompt: "{Your specific request with context}"
```

**Note:** All ops-team agents require `model: "opus"` for production-grade analysis.

---

## When to Use Operations Specialists vs Other Teams

### Use Operations Specialists for:
- Production infrastructure management
- Incident response and coordination
- Cloud cost optimization
- Infrastructure architecture design
- Security operations and compliance

### Use Development Team (ring-dev-team) for:
- Application development
- Development infrastructure (Docker, IaC)
- CI/CD pipeline development
- Application testing
- Observability implementation

### Use Default Reviewers (ring-default) for:
- Code quality review
- Business logic review
- Security code review (application-level)

**Teams complement each other:** Operations handles production, Development handles code, Reviewers handle quality.

---

## Dispatching Multiple Specialists

If you need multiple specialists (e.g., incident + security), dispatch in **parallel**:

```
CORRECT:
Task #1: incident-responder
Task #2: security-operations
(Both run in parallel)

WRONG:
Task #1: incident-responder
(Wait for response)
Task #2: security-operations
(Sequential = 2x slower)
```

---

## Emergency Response Protocol

**Production incidents DO NOT bypass specialist dispatch:**

| Scenario | Wrong Approach | Correct Approach |
|----------|----------------|------------------|
| Production down | "Fix directly, document later" | Dispatch incident-responder with URGENT flag |
| Security alert | "I'll check the logs" | Dispatch security-operations for proper assessment |
| Cost anomaly | "Probably normal spike" | Dispatch cloud-cost-optimizer to investigate |

**Emergency Dispatch Template:**
```
Task tool:
  subagent_type: "incident-responder"
  model: "opus"
  prompt: "URGENT PRODUCTION INCIDENT: [brief context]. [Your specific request]"
```

---

## Available in This Plugin

**Agents:** See "5 Operations Specialists" table above.

**Skills:**
- `using-ops-team` (this) - Plugin introduction
- `ops-incident-response` - Incident management workflow
- `ops-capacity-planning` - Capacity planning process
- `ops-cost-optimization` - Cost optimization workflow
- `ops-disaster-recovery` - DR planning and testing
- `ops-security-audit` - Security audit workflow
- `ops-platform-onboarding` - Service onboarding to platform
- `ops-migration-planning` - Migration planning process

**Commands:**
- `/incident` - Production incident management
- `/capacity-review` - Infrastructure capacity review
- `/cost-analysis` - Cloud cost analysis
- `/security-audit` - Security audit workflow

---

## Integration with Other Plugins

- **ring-default** - ORCHESTRATOR principle, code reviewers
- **ring-dev-team** - Development infrastructure, application code
- **ring-finops-team** - Financial/regulatory compliance
- **ring-pm-team** - Product planning, pre-dev workflows

Dispatch based on your need:
- Production operations -> ring-ops-team agents
- Development infrastructure -> devops-engineer
- Application code -> ring-dev-team specialists
- Code review -> ring-default reviewers
