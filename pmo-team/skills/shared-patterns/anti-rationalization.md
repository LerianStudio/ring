# Anti-Rationalization Patterns for PMO

Canonical source for anti-rationalization patterns used by all pmo-team agents and skills.

AI models naturally attempt to be "helpful" by making autonomous decisions. This is DANGEROUS in portfolio management. These tables use aggressive language intentionally to override the AI's instinct to be accommodating.

## Universal PMO Anti-Rationalizations

These rationalizations are ALWAYS wrong, regardless of context:

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "This project is low priority, skip governance" | ALL projects require governance. Priority determines sequencing, not compliance. | **Apply full governance. No priority exemption.** |
| "Executive already approved, skip analysis" | Executive approval doesn't replace PMO validation. Executives expect due diligence. | **Complete full analysis. Report findings.** |
| "Deadline pressure means skip risk assessment" | Deadline pressure INCREASES risk. Skipping assessment compounds problems. | **Risk assessment is MANDATORY. No deadline exemption.** |
| "Similar project succeeded, reuse assumptions" | Each project is unique. Past success doesn't guarantee future success. | **Analyze THIS project. No assumption reuse.** |
| "Stakeholder said it's urgent, bypass process" | Urgency ≠ permission to skip. Process protects urgent projects too. | **Follow complete process. Urgency handled within process.** |

---

## Agent-Specific Anti-Rationalizations

### Portfolio Manager

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Small project, doesn't need portfolio view" | ALL projects consume resources and create dependencies. | **Include in portfolio analysis** |
| "Already in flight, too late to assess" | In-flight projects need MORE oversight, not less. | **Assess and report status** |
| "Stakeholder politics too complex" | Politics affect delivery. Ignoring them doesn't remove them. | **Document and escalate if needed** |

### Resource Planner

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Team said they can handle it" | Team optimism ≠ capacity analysis. Overcommitment causes burnout. | **Verify with data, not promises** |
| "We'll figure out resources later" | Resource planning is PREREQUISITE, not afterthought. | **Plan resources BEFORE approval** |
| "One person can do multiple projects" | Context switching costs 20-40% productivity. Math matters. | **Calculate realistic allocation** |

### Governance Specialist

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Process slows us down" | Process prevents rework. Rework slows down MORE. | **Enforce full process** |
| "This gate is just bureaucracy" | Gates exist because problems occurred. History teaches. | **Complete ALL gate requirements** |
| "Team is experienced, reduce oversight" | Experience doesn't eliminate risk. Oversight protects everyone. | **Apply standard governance** |

### Risk Analyst

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "We've mitigated this risk before" | Past mitigation ≠ current mitigation. Context changes. | **Assess current state** |
| "Low probability, skip detailed analysis" | Low probability × high impact = significant risk. | **Analyze ALL identified risks** |
| "Team will handle it if it occurs" | Unplanned handling = crisis. Planning = controlled response. | **Document response plans** |

### Executive Reporter

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Bad news can wait" | Delayed bad news = worse news. Executives need truth. | **Report immediately with context** |
| "Too much detail for executives" | Under-reporting creates blind spots. Right detail level matters. | **Provide actionable summary + details available** |
| "Green status because no one complained" | Silence ≠ health. Verify with data. | **Evidence-based status only** |

---

## Skill-Specific Anti-Rationalizations

### Portfolio Review

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Only review troubled projects" | Healthy projects can hide emerging issues. | **Review ALL active projects** |
| "Metrics look good, skip deep dive" | Metrics can mask problems. Qualitative review essential. | **Combine metrics + qualitative analysis** |

### Risk Management

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Risk register is up to date" | Risk registers decay. Validation is continuous. | **Validate currency of ALL risks** |
| "No new risks identified" | Absence of new risks = incomplete analysis OR stable project. Determine which. | **Document analysis process and findings** |

---

## How to Reference This File

**For Agents:**
```markdown
## Anti-Rationalization

See [shared-patterns/anti-rationalization.md](../skills/shared-patterns/anti-rationalization.md) for universal and agent-specific anti-rationalizations.

### Domain-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| [Domain-specific rationalization] | [Domain-specific reason] | **[Domain-specific action]** |
```

**For Skills:**
```markdown
## Anti-Rationalization Table

See [shared-patterns/anti-rationalization.md](../shared-patterns/anti-rationalization.md) for universal anti-rationalizations.

### Skill-Specific Anti-Rationalizations

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| [Skill-specific rationalization] | [Skill-specific reason] | **[Skill-specific action]** |
```
