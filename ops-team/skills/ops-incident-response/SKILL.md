---
name: ops-incident-response
description: |
  Structured workflow for production incident management following SRE best practices.
  Covers incident declaration, triage, coordination, resolution, and post-mortem.

trigger: |
  - Production outage or degradation
  - Customer-impacting issues
  - Security incidents
  - SLA breach risk

skip_when: |
  - Development environment issues -> standard debugging
  - Non-production alerts -> normal ticket workflow
  - Planned maintenance -> change management

related:
  similar: [systematic-debugging]
  uses: [incident-responder]
---

# Incident Response Workflow

This skill defines the structured process for handling production incidents. It MUST be followed for all SEV1, SEV2, and SEV3 incidents.

See [shared-patterns/incident-severity.md](../shared-patterns/incident-severity.md) for severity definitions.

---

## Incident Response Phases

| Phase | Focus | Owner |
|-------|-------|-------|
| **1. Detection** | Identify and confirm incident | Monitoring/On-call |
| **2. Declaration** | Assess severity, declare incident | Incident Commander |
| **3. Triage** | Identify impact and initial hypothesis | Response Team |
| **4. Mitigation** | Restore service, implement workaround | Engineering Team |
| **5. Resolution** | Permanent fix, verification | Engineering Team |
| **6. Post-Incident** | RCA, action items, documentation | Incident Commander |

---

## Phase 1: Detection

**Trigger:** Alert fires or user report received.

### Required Actions

1. **Acknowledge alert** within SLA (see severity matrix)
2. **Initial assessment:**
   - What is the symptom?
   - What is affected?
   - When did it start?
3. **Check for related alerts** - Is this isolated or part of larger issue?

### Detection Checklist

- [ ] Alert acknowledged in monitoring system
- [ ] Initial symptom documented
- [ ] Related alerts checked
- [ ] Recent deployments checked
- [ ] Known issue list checked

---

## Phase 2: Declaration

**Owner:** First responder declares incident, assigns severity.

### Severity Assignment

| Criteria | SEV1 | SEV2 | SEV3 |
|----------|------|------|------|
| Complete outage | X | | |
| Data loss risk | X | | |
| >50% users affected | | X | |
| <50% users affected | | | X |
| Workaround available | | | X |

See [shared-patterns/incident-severity.md](../shared-patterns/incident-severity.md) for complete definitions.

### Declaration Actions

1. **Create incident channel** (if SEV1/SEV2):
   - Format: `#incident-YYYY-MM-DD-brief-description`
   - Post initial summary

2. **Assign Incident Commander (IC)**:
   - SEV1: Senior on-call or escalate to manager
   - SEV2/SEV3: Primary on-call

3. **Update status page** (if customer-facing):
   - Acknowledge incident
   - Set appropriate severity
   - Estimated update time

### Declaration Template

```markdown
**INCIDENT DECLARED**

**Severity:** SEV[1/2/3]
**Title:** [Brief description]
**Incident Commander:** @[name]
**Channel:** #incident-[date]-[slug]

**Impact:**
- Services affected: [list]
- Users affected: [count/percentage]
- Started: [timestamp UTC]

**Current Status:**
[Brief description of current state]

**Next Update:** [timestamp]
```

---

## Phase 3: Triage

**Owner:** Incident Commander coordinates, engineering investigates.

### Triage Questions (5 Whys Approach)

1. What is the exact symptom?
2. What changed recently? (deployments, config, traffic)
3. What is the blast radius?
4. What is the root cause hypothesis?
5. What is the quickest path to mitigation?

### Triage Checklist

- [ ] Service dependencies mapped
- [ ] Recent changes identified
- [ ] Error patterns analyzed
- [ ] Resource utilization checked
- [ ] Initial hypothesis formed

### Communication During Triage

**Update frequency by severity:**
| Severity | Internal Update | External Update |
|----------|-----------------|-----------------|
| SEV1 | Every 10 min | Every 15 min |
| SEV2 | Every 15 min | Every 30 min |
| SEV3 | Every 30 min | As needed |

---

## Phase 4: Mitigation

**Owner:** Engineering implements fix, IC coordinates.

### Mitigation Options (in order of preference)

1. **Rollback** - If recent deployment caused issue
2. **Scale** - If capacity related
3. **Restart** - If state corruption
4. **Failover** - If regional/AZ issue
5. **Feature disable** - If specific feature causes issue
6. **Hotfix** - If rollback not possible

### Mitigation Checklist

- [ ] Mitigation option selected with rationale
- [ ] Change approved (SEV1: skip formal, document later)
- [ ] Implementation tracked in incident channel
- [ ] Verification criteria defined
- [ ] Rollback plan ready

### Mitigation Template

```markdown
**MITIGATION IN PROGRESS**

**Action:** [description]
**Owner:** @[name]
**Started:** [timestamp]

**Verification:**
- [ ] [criterion 1]
- [ ] [criterion 2]

**Rollback Plan:**
[If mitigation fails, do X]
```

---

## Phase 5: Resolution

**Owner:** Engineering confirms fix, IC verifies resolution.

### Resolution Criteria

**ALL must be true before marking resolved:**

1. **Primary symptom resolved** - Users no longer affected
2. **Monitoring confirms** - Metrics returned to baseline
3. **No related alerts** - All triggered alerts cleared
4. **Verification period passed** - 15 min stability for SEV1/2

### Resolution Checklist

- [ ] Primary symptom verified resolved
- [ ] Metrics returned to normal
- [ ] All related alerts resolved
- [ ] Verification period completed
- [ ] Customer communication sent (if applicable)
- [ ] Status page updated to resolved

### Resolution Template

```markdown
**INCIDENT RESOLVED**

**Duration:** [X hours Y minutes]
**Resolution Time:** [timestamp UTC]

**Root Cause:**
[Brief description of what caused the incident]

**Fix Applied:**
[What was done to resolve]

**Next Steps:**
- [ ] RCA scheduled for [date]
- [ ] Action items tracked in [location]

**Retrospective:** [date/time]
```

---

## Phase 6: Post-Incident

**Owner:** Incident Commander schedules RCA, tracks action items.

### RCA Requirements

| Severity | RCA Required | Timeline |
|----------|--------------|----------|
| SEV1 | MANDATORY | 48 hours |
| SEV2 | MANDATORY | 1 week |
| SEV3 | Optional | 2 weeks |

### RCA Template

```markdown
# Incident Post-Mortem: [Title]

**Incident ID:** INC-YYYY-NNNN
**Date:** YYYY-MM-DD
**Duration:** X hours Y minutes
**Severity:** SEV[1/2/3]
**Author:** @[incident commander]

## Summary
[2-3 sentence summary of what happened]

## Impact
- **Users Affected:** [count/percentage]
- **Revenue Impact:** [if applicable]
- **SLA Impact:** [if applicable]

## Timeline
| Time (UTC) | Event |
|------------|-------|
| HH:MM | [event] |

## Root Cause
[Technical description of the root cause]

## Contributing Factors
1. [Factor 1]
2. [Factor 2]

## What Went Well
1. [Item 1]
2. [Item 2]

## What Could Be Improved
1. [Item 1]
2. [Item 2]

## Action Items
| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
| [action] | @[name] | YYYY-MM-DD | Open |

## Lessons Learned
[Key takeaways for the team]
```

### Post-Incident Checklist

- [ ] RCA document created
- [ ] Blameless retrospective held
- [ ] Action items assigned and tracked
- [ ] Runbook updated (if applicable)
- [ ] Monitoring improved (if gaps found)
- [ ] Incident documented in knowledge base

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Document later, fix first" | Memory fades in hours | **Document AS you fix** |
| "Small incident, skip RCA" | Small incidents reveal systemic issues | **RCA for SEV1/SEV2 minimum** |
| "Root cause is obvious" | Obvious != correct | **Investigate with data** |
| "Skip verification period" | Premature resolution = reopen | **Wait full verification period** |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Mark resolved now, verify later" | "Cannot mark resolved until verification complete. This prevents reopened incidents." |
| "Skip the RCA, we know what happened" | "RCA is mandatory for this severity. Schedule within required timeline." |
| "No time for documentation" | "Real-time documentation takes 30 seconds per event. Memory loss causes worse rework." |

---

## Dispatch Specialist

For complex incidents, dispatch the incident-responder agent:

```
Task tool:
  subagent_type: "incident-responder"
  model: "opus"
  prompt: |
    INCIDENT: [description]
    SEVERITY: SEV[X]
    CURRENT STATUS: [state]
    REQUEST: [specific assistance needed]
```
