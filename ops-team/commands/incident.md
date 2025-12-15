---
name: ring-ops-team:incident
description: Initiate production incident response workflow with structured triage, coordination, and documentation
argument-hint: "[severity] [brief-description]"
---

# Production Incident Command

This command initiates structured incident response following SRE best practices.

## Usage

```
/incident SEV2 API latency spike affecting 30% of users
```

## Workflow

### Step 1: Incident Declaration

Parse the severity and description from the command arguments.

**If severity not provided:**
- Ask user to classify: SEV1 (Critical), SEV2 (Major), SEV3 (Minor), SEV4 (Low)
- Reference severity criteria from `ops-incident-response` skill

**If description not provided:**
- Ask for brief incident description
- What is the symptom?
- What is affected?

### Step 2: Dispatch Incident Responder

```
Task tool:
  subagent_type: "incident-responder"
  model: "opus"
  prompt: |
    PRODUCTION INCIDENT DECLARED

    **Severity:** [SEV level]
    **Description:** [incident description]
    **Declared at:** [timestamp UTC]

    IMMEDIATE ACTIONS REQUIRED:
    1. Assess current impact
    2. Identify initial hypothesis
    3. Recommend immediate mitigation
    4. Document timeline

    Please provide:
    - Impact assessment
    - Initial triage findings
    - Recommended immediate actions
    - Communication template for stakeholders
```

### Step 3: Create Incident Structure

Based on incident-responder assessment, create:

1. **Incident Timeline** - Track all events
2. **Impact Assessment** - Document affected users/services
3. **Communication Updates** - Status for stakeholders
4. **Action Tracker** - Track mitigation steps

### Step 4: Ongoing Support

Throughout the incident:

- Track progress and timeline updates
- Coordinate between specialists if needed
- Document all actions taken
- Prepare for post-incident review

## Output Format

```markdown
# Incident Response Initiated

**Incident ID:** INC-YYYY-MMDD-HHMM
**Severity:** SEV[X]
**Status:** Active
**Incident Commander:** [assigned]

## Initial Assessment

[From incident-responder agent]

## Impact

[User/service impact summary]

## Immediate Actions

1. [Action 1] - Owner: [name] - Status: [status]
2. [Action 2] - Owner: [name] - Status: [status]

## Communication

**Internal Update:**
> [Template for team communication]

**External Update (if applicable):**
> [Template for customer communication]

## Next Update

Expected: [timestamp]
```

## Severity Reference

| SEV | Definition | Response Time |
|-----|------------|---------------|
| SEV1 | Complete outage, data loss, security breach | <15 min |
| SEV2 | Partial outage, >50% users affected | <30 min |
| SEV3 | Limited impact, workaround available | <2 hours |
| SEV4 | Minimal impact, next business day | NBD |

## Related Skills

- `ops-incident-response` - Full incident response workflow
- `incident-responder` - Specialist agent for incident management

## Anti-Rationalization

| Rationalization | Required Action |
|-----------------|-----------------|
| "It's a small incident, skip formal process" | **All incidents follow same structure** |
| "Document later" | **Document in real-time** |
| "Skip stakeholder communication" | **Communication is mandatory** |
