---
name: ops-security-audit
description: |
  Structured workflow for infrastructure security audits including compliance
  validation, vulnerability assessment, and security posture review.

trigger: |
  - Quarterly security reviews
  - Compliance audit preparation
  - Security incident post-mortem
  - New service security assessment

skip_when: |
  - Application code security -> use security-reviewer
  - Active security incident -> use ops-incident-response
  - Penetration testing -> external security team

related:
  similar: [security-reviewer]
  uses: [security-operations]
---

# Security Audit Workflow

This skill defines the structured process for infrastructure security audits. Use it for systematic security assessment and compliance validation.

---

## Security Audit Phases

| Phase | Focus | Output |
|-------|-------|--------|
| **1. Scope Definition** | Define audit boundaries | Audit plan |
| **2. Automated Scanning** | Run security tools | Scan results |
| **3. Manual Review** | Deep-dive analysis | Finding details |
| **4. Compliance Mapping** | Map to frameworks | Compliance report |
| **5. Remediation Planning** | Prioritize fixes | Remediation plan |
| **6. Verification** | Confirm fixes | Closure report |

---

## Phase 1: Scope Definition

### Audit Scope Template

```markdown
## Security Audit Scope

**Audit ID:** SEC-AUDIT-YYYY-NNN
**Audit Period:** YYYY-MM-DD to YYYY-MM-DD
**Auditor:** [name/team]

### In Scope

| Category | Components |
|----------|------------|
| **Accounts** | AWS Account 123456789, 987654321 |
| **Regions** | us-east-1, us-west-2 |
| **Services** | EC2, RDS, S3, IAM, VPC, EKS |
| **Environments** | Production, Staging |
| **Compliance** | SOC2 Type II, PCI-DSS 4.0 |

### Out of Scope

| Category | Reason |
|----------|--------|
| Development accounts | Covered by separate audit |
| Application code | Covered by code review process |
| Third-party SaaS | Covered by vendor assessments |

### Audit Objectives

1. Validate compliance with [framework]
2. Identify security vulnerabilities in infrastructure
3. Assess IAM and access control posture
4. Review network security configuration
5. Evaluate logging and monitoring coverage
```

---

## Phase 2: Automated Scanning

### Security Scanning Tools

| Tool | Purpose | Scope |
|------|---------|-------|
| **AWS Security Hub** | Aggregated findings | All AWS services |
| **AWS Config** | Configuration compliance | Resource configuration |
| **GuardDuty** | Threat detection | Account activity |
| **Trivy** | Container vulnerabilities | EKS images |
| **Checkov** | IaC security | Terraform/CloudFormation |
| **ScoutSuite** | Cloud security audit | Multi-cloud |

### Scan Execution Template

```bash
# AWS Security Hub findings
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}'

# AWS Config compliance
aws configservice get-compliance-summary-by-config-rule

# Trivy container scan
trivy image --severity CRITICAL,HIGH [image]

# Checkov IaC scan
checkov -d /path/to/terraform --framework terraform
```

### Scan Results Template

```markdown
## Automated Scan Results

**Scan Date:** YYYY-MM-DD
**Tools Used:** Security Hub, Trivy, Checkov

### Summary by Severity

| Source | Critical | High | Medium | Low |
|--------|----------|------|--------|-----|
| Security Hub | X | X | X | X |
| Trivy | X | X | X | X |
| Checkov | X | X | X | X |
| **Total** | **X** | **X** | **X** | **X** |

### Critical Findings Requiring Immediate Action

| Finding ID | Source | Description |
|------------|--------|-------------|
| SEC-001 | Security Hub | [description] |
| SEC-002 | Trivy | [description] |
```

---

## Phase 3: Manual Review

### Review Checklist

#### IAM Review

- [ ] Root account MFA enabled
- [ ] Root account not used for daily operations
- [ ] Password policy meets requirements
- [ ] No users with inline policies
- [ ] Service accounts use roles, not keys
- [ ] Access keys rotated <90 days
- [ ] Unused IAM users/roles identified

#### Network Security Review

- [ ] VPC flow logs enabled
- [ ] No 0.0.0.0/0 ingress rules (except public ALB)
- [ ] Security groups follow least privilege
- [ ] NACLs configured appropriately
- [ ] VPC endpoints for AWS services
- [ ] No public RDS instances
- [ ] No public S3 buckets (unless intended)

#### Data Protection Review

- [ ] S3 buckets encrypted (SSE-S3 or SSE-KMS)
- [ ] EBS volumes encrypted
- [ ] RDS instances encrypted
- [ ] SSL/TLS for data in transit
- [ ] KMS key rotation enabled
- [ ] Secrets in Secrets Manager (not code/config)

#### Logging & Monitoring Review

- [ ] CloudTrail enabled (all regions)
- [ ] CloudTrail logs encrypted
- [ ] CloudTrail log validation enabled
- [ ] VPC flow logs enabled
- [ ] GuardDuty enabled
- [ ] Security Hub enabled
- [ ] Alert rules for critical events

### Manual Review Template

```markdown
## Manual Review Findings

### IAM Security

| Check | Status | Finding |
|-------|--------|---------|
| Root MFA | PASS | MFA enabled |
| Root usage | PASS | No root activity in 90 days |
| Password policy | PARTIAL | Missing complexity requirement |
| Access key age | FAIL | 3 keys >90 days |

### Network Security

| Check | Status | Finding |
|-------|--------|---------|
| VPC flow logs | PASS | Enabled on all VPCs |
| SG 0.0.0.0/0 | FAIL | sg-xxx allows SSH from anywhere |
| Public RDS | PASS | No public instances |

[Continue for all categories...]
```

---

## Phase 4: Compliance Mapping

### SOC2 Control Mapping

| Control | Requirement | Evidence | Status |
|---------|-------------|----------|--------|
| CC6.1 | Logical access controls | IAM policies, MFA | Compliant |
| CC6.6 | System boundaries | VPC, security groups | Compliant |
| CC6.7 | Encryption in transit | TLS configuration | Compliant |
| CC7.1 | System monitoring | CloudTrail, GuardDuty | Compliant |
| CC7.2 | Anomaly detection | GuardDuty findings | Partial |

### PCI-DSS Mapping

| Requirement | Description | Evidence | Status |
|-------------|-------------|----------|--------|
| 1.3 | Firewall configuration | Security groups | Compliant |
| 3.4 | Encryption at rest | KMS, S3 encryption | Compliant |
| 8.3 | Strong authentication | MFA, IAM policies | Partial |
| 10.2 | Audit logging | CloudTrail | Compliant |
| 11.3 | Vulnerability scanning | Security Hub | Compliant |

### Compliance Summary Template

```markdown
## Compliance Status Report

**Assessment Date:** YYYY-MM-DD
**Frameworks:** SOC2 Type II, PCI-DSS 4.0

### Overall Status

| Framework | Total Controls | Compliant | Partial | Non-Compliant |
|-----------|---------------|-----------|---------|---------------|
| SOC2 | 50 | 45 | 3 | 2 |
| PCI-DSS | 40 | 35 | 4 | 1 |

### Non-Compliant Controls

| Framework | Control | Gap | Remediation |
|-----------|---------|-----|-------------|
| SOC2 | CC7.2 | Anomaly alerting incomplete | Enable GuardDuty alerts |
| PCI-DSS | 8.3 | MFA not enforced for all | Enable MFA requirement |
```

---

## Phase 5: Remediation Planning

### Prioritization Matrix

| Priority | Criteria | SLA |
|----------|----------|-----|
| **P1** | Critical vulnerability, compliance blocker | 24 hours |
| **P2** | High vulnerability, significant risk | 7 days |
| **P3** | Medium vulnerability, moderate risk | 30 days |
| **P4** | Low vulnerability, best practice | 90 days |

### Remediation Plan Template

```markdown
## Remediation Plan

**Plan Created:** YYYY-MM-DD
**Total Findings:** XX
**Critical/High:** XX

### Remediation Actions

| Finding | Priority | Owner | Target Date | Status |
|---------|----------|-------|-------------|--------|
| SEC-001 | P1 | @security | YYYY-MM-DD | In Progress |
| SEC-002 | P2 | @platform | YYYY-MM-DD | Not Started |
| SEC-003 | P2 | @devops | YYYY-MM-DD | Not Started |

### Detailed Remediation

#### SEC-001: IAM Access Keys >90 Days

**Finding:** 3 IAM users have access keys older than 90 days
**Risk:** Credential compromise risk increases over time
**Remediation:**
1. Identify key usage patterns
2. Create rotation schedule
3. Rotate keys for each user
4. Update applications using keys
5. Disable old keys after verification

**Owner:** @security
**Target Date:** YYYY-MM-DD
```

---

## Phase 6: Verification

### Verification Checklist

- [ ] Remediation implemented
- [ ] Re-scan with same tools
- [ ] Finding resolved in scan results
- [ ] No regression introduced
- [ ] Documentation updated

### Closure Report Template

```markdown
## Security Audit Closure Report

**Audit ID:** SEC-AUDIT-YYYY-NNN
**Audit Period:** YYYY-MM-DD to YYYY-MM-DD
**Closure Date:** YYYY-MM-DD

### Summary

| Metric | Count |
|--------|-------|
| Total findings | XX |
| Remediated | XX |
| Accepted risk | XX |
| Deferred | XX |

### Remediation Summary

| Priority | Found | Remediated | Accepted | Deferred |
|----------|-------|------------|----------|----------|
| P1 | X | X | 0 | 0 |
| P2 | X | X | X | 0 |
| P3 | X | X | X | X |
| P4 | X | X | X | X |

### Risk Acceptances

| Finding | Risk Description | Accepting Authority | Review Date |
|---------|------------------|---------------------|-------------|
| SEC-XXX | [description] | CISO | YYYY-MM-DD |

### Next Audit

**Scheduled:** YYYY-MM-DD
**Focus Areas:** [areas based on this audit]
```

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Internal service, security can be relaxed" | Internal breaches are common | **Apply standards uniformly** |
| "False positive, ignore it" | All findings need verification | **Document evidence** |
| "Too many findings to fix" | Prioritize by severity | **Triage systematically** |
| "Compliance is just checkbox" | Compliance reflects real risk | **Treat as minimum bar** |
| "Security slows us down" | Breach slows you permanently | **Integrate security in process** |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Skip security review, deadline tomorrow" | "Security review is mandatory. Cannot release with unreviewed changes. Scheduling expedited review." |
| "That's a false positive" | "All findings require documented verification. Will assess with evidence." |
| "Accept all remaining risks" | "Risk acceptance requires proper documentation and authority sign-off. Preparing risk acceptance forms." |
| "Legacy system, different rules" | "Legacy systems are higher risk. Stricter standards apply." |

---

## Dispatch Specialist

For security audit tasks, dispatch:

```
Task tool:
  subagent_type: "security-operations"
  model: "opus"
  prompt: |
    SECURITY AUDIT REQUEST
    Scope: [accounts, regions, services]
    Compliance Frameworks: [SOC2, PCI-DSS, etc.]
    Focus Areas: [IAM, network, data, etc.]
    Previous Findings: [reference if follow-up]
```
