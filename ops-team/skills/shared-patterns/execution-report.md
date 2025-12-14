# Execution Report Format

Canonical format for execution reports across all ops-team skills and agents.

## Standard Report Structure

All ops-team execution reports MUST follow this structure:

```markdown
## Summary

[1-2 sentence summary of what was done]

## Execution Details

### Actions Taken

| Action | Status | Notes |
|--------|--------|-------|
| [action] | [Completed/In Progress/Blocked] | [details] |

### Findings

| Finding | Severity | Impact | Recommendation |
|---------|----------|--------|----------------|
| [finding] | [CRITICAL/HIGH/MEDIUM/LOW] | [impact description] | [action to take] |

## Evidence

[Commands run, outputs captured, metrics collected]

## Blockers (if any)

| Blocker | Impact | Required Decision |
|---------|--------|-------------------|
| [blocker] | [what it blocks] | [decision needed from user] |

## Next Steps

1. [Immediate action required]
2. [Follow-up action]
3. [Long-term recommendation]
```

## Severity Classifications

Use consistent severity across all ops-team reports:

| Severity | Criteria | Response Time |
|----------|----------|---------------|
| **CRITICAL** | Production impact, security breach, data loss risk | Immediate (< 1 hour) |
| **HIGH** | Degraded service, compliance violation, significant cost | < 24 hours |
| **MEDIUM** | Performance impact, minor security gap, efficiency loss | < 1 week |
| **LOW** | Best practice deviation, documentation gap, optimization opportunity | Next sprint |

## Incident-Specific Report Additions

For incident response reports, include:

```markdown
## Incident Timeline

| Time (UTC) | Event | Actor |
|------------|-------|-------|
| HH:MM | [event] | [who/what] |

## Impact Assessment

- **Duration**: [time]
- **Users Affected**: [count/percentage]
- **Revenue Impact**: [if applicable]
- **SLA Impact**: [if applicable]

## Root Cause

[Identified root cause or "Under investigation"]

## Prevention

[Actions to prevent recurrence]
```

## Cost Analysis Report Additions

For cost optimization reports, include:

```markdown
## Cost Summary

| Category | Current Monthly | Projected Savings | % Reduction |
|----------|-----------------|-------------------|-------------|
| [category] | $X,XXX | $X,XXX | XX% |

## Optimization Opportunities

| Opportunity | Effort | Savings/Month | ROI Timeline |
|-------------|--------|---------------|--------------|
| [opportunity] | [Low/Medium/High] | $X,XXX | [X months] |

## Risk Assessment

| Optimization | Risk Level | Mitigation |
|--------------|------------|------------|
| [optimization] | [Low/Medium/High] | [how to mitigate] |
```

## Security Audit Report Additions

For security audit reports, include:

```markdown
## Compliance Status

| Framework | Status | Gaps |
|-----------|--------|------|
| [framework] | [Compliant/Non-Compliant/Partial] | [gap count] |

## Vulnerability Summary

| Severity | Count | Remediated | Pending |
|----------|-------|------------|---------|
| Critical | X | X | X |
| High | X | X | X |
| Medium | X | X | X |
| Low | X | X | X |

## Remediation Plan

| Vulnerability | Priority | Owner | Target Date |
|---------------|----------|-------|-------------|
| [vuln] | [1-5] | [team/person] | [date] |
```

## Report Quality Checklist

Before submitting any report, verify:

- [ ] Summary is concise (1-2 sentences)
- [ ] All findings have severity assigned
- [ ] Evidence section includes actual command output
- [ ] Blockers clearly state required decisions
- [ ] Next steps are actionable and specific
- [ ] Timestamps are in UTC
- [ ] Metrics use consistent units
