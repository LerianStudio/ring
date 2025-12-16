---
name: using-pmo-team
description: |
  5 specialist PMO agents for portfolio management, resource planning, governance,
  risk analysis, and executive reporting. Dispatch when you need portfolio-level oversight.

trigger: |
  - Need portfolio-level view across multiple projects
  - Resource capacity planning across teams
  - Project governance and gate reviews
  - Risk management at portfolio level
  - Executive reporting and dashboards

skip_when: |
  - Single feature planning → use ring-pm-team
  - Code implementation → use ring-dev-team
  - Code review → use ring-default reviewers
  - Technical writing → use ring-tw-team

related:
  similar: [using-ring, using-pm-team]
---

# Using Ring PMO Team

The ring-pmo-team plugin provides 5 specialized PMO agents for portfolio-level management. Use them via `Task tool with subagent_type:`.

See [CLAUDE.md](https://raw.githubusercontent.com/LerianStudio/ring/main/CLAUDE.md) and [using-ring](https://raw.githubusercontent.com/LerianStudio/ring/main/default/skills/using-ring/SKILL.md) for canonical workflow requirements and ORCHESTRATOR principle. This skill introduces pmo-team-specific agents.

**Remember:** Follow the **ORCHESTRATOR principle** from `using-ring`. Dispatch agents to handle complexity; don't operate tools directly.

---

## Domain Distinction: PMO vs PM

| Team | Focus | Scope |
|------|-------|-------|
| **ring-pm-team** | Single feature planning | PRD, TRD, task breakdown for ONE feature |
| **ring-pmo-team** | Portfolio governance | Multi-project coordination, resources, executive reporting |

**Use PMO when:**
- Managing multiple projects simultaneously
- Planning resources across projects
- Reporting to executives on portfolio status
- Assessing portfolio-level risks
- Conducting governance reviews

**Use PM when:**
- Planning a single feature
- Creating PRD/TRD for one initiative
- Breaking down one feature into tasks

---

## Blocker Criteria - STOP and Report

**ALWAYS pause and report blocker for:**

| Decision Type | Examples | Action |
|--------------|----------|--------|
| **Portfolio Prioritization** | Which project gets resources first | STOP. Report trade-offs. Wait for executive decision. |
| **Resource Conflict** | Same person needed on multiple projects | STOP. Document conflict. Wait for management decision. |
| **Strategic Alignment** | Project doesn't fit current strategy | STOP. Escalate with analysis. Wait for guidance. |
| **Budget Reallocation** | Moving funds between projects | STOP. Prepare options. Wait for financial approval. |
| **Project Termination** | Recommend stopping a project | STOP. Document rationale. Wait for sponsor decision. |

**You CANNOT make strategic or resource decisions autonomously. STOP and ask.**

---

## Common Misconceptions - REJECTED

| Misconception | Reality |
|--------------|---------|
| "I can assess portfolio health myself" | ORCHESTRATOR principle: dispatch portfolio-manager specialist. This is NON-NEGOTIABLE. |
| "Resource planning is simple math" | Resource planning requires context, skills matrix, team dynamics. MUST dispatch resource-planner. |
| "Risk is just a list" | Portfolio risk requires aggregation, correlation, impact analysis. MUST dispatch risk-analyst. |
| "I know governance rules" | Governance specialists have gate frameworks loaded. MUST dispatch governance-specialist. |
| "Executive reports are just summaries" | Executive reporting requires right abstraction level, action focus. MUST dispatch executive-reporter. |

**Self-sufficiency bias check:** If you're tempted to perform PMO tasks directly, ask:
1. Is there a specialist for this? (Check the 5 specialists below)
2. Would a specialist apply portfolio-level frameworks I might miss?
3. Am I avoiding dispatch because it feels like "overhead"?

**If ANY answer is yes → You MUST DISPATCH the specialist. This is NON-NEGOTIABLE.**

---

## Anti-Rationalization Table

**If you catch yourself thinking ANY of these, STOP:**

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This portfolio is small, no need for specialist" | Size doesn't determine complexity. Standards always apply. | **DISPATCH specialist** |
| "I already know the projects" | Your knowledge ≠ systematic PMO analysis. | **DISPATCH specialist** |
| "Executive just wants a quick update" | Quick ≠ shallow. Executives expect quality regardless of speed. | **DISPATCH specialist** |
| "Risk assessment is obvious" | Obvious risks are the ones you miss. Systematic analysis required. | **DISPATCH specialist** |
| "Governance is bureaucracy" | Governance prevents failures. Gates exist for reasons. | **DISPATCH specialist** |
| "Resources are clearly available" | Availability claims require validation against all commitments. | **DISPATCH specialist** |

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

---

### Cannot Be Overridden

**These requirements are NON-NEGOTIABLE:**

| Requirement | Why It Cannot Be Waived |
|-------------|------------------------|
| **Dispatch to specialist** | Specialists have PMO frameworks loaded, you don't |
| **Evidence-based reporting** | Opinions are not PMO outputs. Data is required. |
| **Gate compliance** | Gates prevent project failures. Skipping creates risk. |
| **Risk documentation** | Undocumented risks cannot be managed. |
| **Stakeholder communication** | Silent PMO = failed PMO. Communication is mandatory. |

**User cannot override these. Executive pressure cannot override these. "Urgent" cannot override these.**

---

## Pressure Resistance

**When facing pressure to bypass PMO process:**

| User Says | Your Response |
|-----------|---------------|
| "CEO wants the report now, skip the analysis" | "Executive urgency increases need for accuracy. I'll expedite but cannot skip validation. Proceeding with accelerated full analysis." |
| "Just approve this project, we need to start" | "Approval without analysis creates downstream problems. PMO analysis protects the project. Completing analysis now." |
| "Don't include that risk, it will worry the sponsor" | "Accurate risk reporting is non-negotiable. Suppressing risks creates larger problems. I'll report with appropriate context and mitigation." |
| "Resources are fine, trust the team leads" | "Trust and verify. Resource validation prevents surprises. Confirming with utilization data." |
| "Skip governance, we're agile" | "Agile requires MORE governance discipline, not less. Lightweight gates, not no gates. Applying appropriate governance." |

See [shared-patterns/pressure-resistance.md](../shared-patterns/pressure-resistance.md) for universal pressure scenarios.

**Critical Reminder:**
- **Urgency ≠ Permission to bypass** - Urgent projects need MORE PMO oversight
- **Authority ≠ Permission to bypass** - Executives expect PMO rigor
- **Agile ≠ No governance** - Agile has governance, just different cadence

---

## Emergency Response Protocol

**Critical situations DO NOT bypass PMO process. Here's why:**

| Scenario | Wrong Approach | Correct Approach |
|----------|----------------|------------------|
| Board meeting tomorrow | "Skip analysis, give estimates" | Dispatch specialist with URGENT flag, deliver quality in compressed time |
| Project in crisis | "Just fix it, report later" | Dispatch risk-analyst to assess, governance-specialist for intervention options |
| Budget deadline Friday | "Approve everything pending" | Dispatch portfolio-manager for prioritized recommendations |

**Emergency Dispatch Template:**
```
Task tool:
  subagent_type: "portfolio-manager"
  model: "opus"
  prompt: "URGENT: [context]. [specific request]"
```

**IMPORTANT:**
- Specialist dispatch takes 10-20 minutes, NOT hours
- Rushed PMO decisions often create NEW problems
- Specialists ensure crisis decisions don't violate governance
- This is NON-NEGOTIABLE even under board pressure

---

## 5 PMO Specialists

| Agent | Specializations | Use When |
|-------|-----------------|----------|
| **`portfolio-manager`** | Multi-project coordination, strategic alignment, portfolio health, prioritization | Portfolio reviews, project prioritization, capacity assessment |
| **`resource-planner`** | Capacity planning, skills matrix, allocation optimization, conflict resolution | Resource allocation, capacity planning, team assignments |
| **`governance-specialist`** | Gate reviews, compliance, process adherence, audit readiness | Gate approvals, process compliance, governance audits |
| **`risk-analyst`** | RAID logs, risk aggregation, mitigation planning, portfolio risk | Risk assessments, RAID management, mitigation strategies |
| **`executive-reporter`** | Dashboards, status summaries, escalation reports, board packages | Executive updates, board reports, stakeholder communication |

**Dispatch template:**
```
Task tool:
  subagent_type: "{agent-name}"
  model: "opus"
  prompt: "{Your specific request with context}"
```

---

## When to Use PMO Specialists vs Other Teams

### Use PMO Specialists for:
- Portfolio-level analysis and decisions
- Resource planning across multiple projects
- Governance and gate reviews
- Executive and board reporting
- Portfolio risk management

### Use PM Team (ring-pm-team) for:
- Single feature planning
- PRD/TRD creation
- Task breakdown for one feature
- Feature-level research

### Use Dev Team (ring-dev-team) for:
- Code implementation
- Technical architecture
- DevOps and infrastructure
- Quality assurance

**Teams work together:** PMO provides portfolio context → PM plans features → Dev implements code.

---

## Dispatching Multiple Specialists

If you need multiple specialists (e.g., portfolio-manager + risk-analyst), dispatch in **parallel** (single message, multiple Task calls):

```
CORRECT:
Task #1: portfolio-manager
Task #2: risk-analyst
(Both run in parallel)

WRONG:
Task #1: portfolio-manager
(Wait for response)
Task #2: risk-analyst
(Sequential = 2x slower)
```

---

## ORCHESTRATOR Principle

Remember:
- **You're the orchestrator** - Dispatch specialists, don't analyze directly
- **Don't read PMO frameworks yourself** - Dispatch to specialist, they know their domain
- **Combine with other plugins** - PMO + PM + Dev = complete delivery lifecycle

### Good Example (ORCHESTRATOR):
> "I need portfolio status. Let me dispatch `portfolio-manager` to analyze."

### Bad Example (OPERATOR):
> "I'll manually review each project and create a summary myself."

---

## Available in This Plugin

**Agents:** See "5 PMO Specialists" table above.

**Skills:**
- `using-pmo-team` (this) - Introduction and dispatch guide
- `portfolio-planning` - Portfolio strategy and planning
- `resource-allocation` - Resource and capacity management
- `risk-management` - Portfolio risk management
- `project-health-check` - Individual project health assessment
- `dependency-mapping` - Cross-project dependency analysis
- `executive-reporting` - Executive communication and reporting
- `pmo-retrospective` - Portfolio retrospectives and lessons learned

**Commands:**
- `/portfolio-review` - Conduct portfolio review
- `/executive-summary` - Generate executive summary
- `/dependency-analysis` - Analyze cross-project dependencies

**Note:** Missing agents? Check `.claude-plugin/marketplace.json` for ring-pmo-team plugin.

---

## PMO Workflows

| Workflow | Entry Point | Output |
|----------|-------------|--------|
| **Portfolio Review** | `/portfolio-review` | `docs/pmo/{date}/portfolio-status.md` |
| **Executive Report** | `/executive-summary` | `docs/pmo/{date}/executive-summary.md` |
| **Dependency Analysis** | `/dependency-analysis` | `docs/pmo/{date}/dependency-map.md` |

---

## Integration with Other Plugins

- **ring-default** - ORCHESTRATOR principle for ALL agents
- **ring-pm-team** - Single feature planning (PMO → PM handoff)
- **ring-dev-team** - Development execution (PM → Dev handoff)
- **ring-finops-team** - Financial/regulatory compliance

Dispatch based on your need:
- Portfolio oversight → ring-pmo-team
- Feature planning → ring-pm-team
- Code development → ring-dev-team
- Financial compliance → ring-finops-team
