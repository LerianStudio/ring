# Incident Severity Classification

Canonical source for incident severity definitions used across all ops-team agents and skills.

## Severity Levels

| Level | Name | Definition | Response Time | Escalation |
|-------|------|------------|---------------|------------|
| **SEV1** | Critical | Complete service outage, data loss, security breach | < 15 minutes | Immediate executive notification |
| **SEV2** | Major | Partial outage, degraded performance affecting >50% users | < 30 minutes | On-call escalation chain |
| **SEV3** | Minor | Limited impact, workaround available, <10% users affected | < 2 hours | On-call acknowledgment |
| **SEV4** | Low | Cosmetic issues, documentation bugs, minor inconvenience | Next business day | Standard ticket workflow |

## SEV1 - Critical (P1)

**Criteria (ANY ONE triggers SEV1):**
- Complete production outage
- Data loss or corruption
- Security breach confirmed
- Payment/transaction processing failure
- Regulatory compliance violation in progress

**Required Response:**
1. Page all on-call responders immediately
2. Notify executive stakeholders within 15 minutes
3. Establish war room / incident channel
4. Status page update within 15 minutes
5. Customer communication within 30 minutes

**Example Scenarios:**
- Database cluster completely unavailable
- Authentication service down
- Ransomware detected
- All API endpoints returning 5xx

## SEV2 - Major (P2)

**Criteria (ANY ONE triggers SEV2):**
- Partial service degradation >50% users
- Single critical component failure with no redundancy
- Significant performance degradation (>300% latency)
- Secondary security incident (potential breach)
- Backup systems activated due to primary failure

**Required Response:**
1. Page primary on-call within 5 minutes
2. Notify stakeholders within 30 minutes
3. Status page update within 30 minutes
4. Progress updates every 30 minutes

**Example Scenarios:**
- One of three database replicas down
- API latency 5x normal
- Suspicious login activity detected
- Partial data sync failure

## SEV3 - Minor (P3)

**Criteria:**
- Limited user impact (<10%)
- Workaround available
- Non-critical feature unavailable
- Monitoring alert with no user impact

**Required Response:**
1. On-call acknowledgment within 30 minutes
2. Assessment within 2 hours
3. Resolution within 8 hours or escalate

**Example Scenarios:**
- Single non-critical service restart
- Minor UI bug in admin panel
- Non-production environment issues
- Scheduled maintenance overrun

## SEV4 - Low (P4)

**Criteria:**
- No user impact
- Cosmetic issues
- Documentation errors
- Enhancement requests

**Required Response:**
1. Acknowledge next business day
2. Prioritize in next sprint/iteration
3. Track in standard issue tracker

**Example Scenarios:**
- Typo in error message
- Minor log format inconsistency
- Documentation outdated
- Performance optimization opportunity

## Severity Determination Matrix

Use this matrix when multiple factors are present:

| User Impact | Data Risk | Security Risk | Resulting Severity |
|-------------|-----------|---------------|-------------------|
| Complete outage | Any | Any | **SEV1** |
| Any | Data loss | Any | **SEV1** |
| Any | Any | Active breach | **SEV1** |
| >50% users | None | None | **SEV2** |
| <50% users | Potential | Potential | **SEV2** |
| <10% users | None | None | **SEV3** |
| None | None | None | **SEV4** |

## Escalation Paths

| Severity | Escalation Chain |
|----------|-----------------|
| **SEV1** | On-call -> Engineering Lead -> VP Engineering -> CTO -> CEO |
| **SEV2** | On-call -> Engineering Lead -> VP Engineering |
| **SEV3** | On-call -> Engineering Lead |
| **SEV4** | Standard ticket workflow |

## De-escalation Criteria

**SEV1 to SEV2:**
- Primary service restored
- No ongoing data loss
- Security breach contained

**SEV2 to SEV3:**
- Impact reduced to <10% users
- Workaround implemented
- No risk of escalation

**Resolution Criteria (ALL must be true):**
- Root cause identified
- Fix implemented and verified
- Monitoring confirms stability
- No related alerts for 15+ minutes

## Anti-Rationalization for Severity

| Rationalization | Why It's WRONG | Correct Action |
|-----------------|----------------|----------------|
| "Only affects a few users" | A few users could be high-value customers | **Assess business impact, not just count** |
| "No one has complained yet" | Absence of complaints != absence of impact | **Verify with monitoring data** |
| "It's working for me" | Your experience != user experience | **Check multiple perspectives** |
| "Similar issue was SEV3 before" | Past severity != current severity | **Assess each incident independently** |
