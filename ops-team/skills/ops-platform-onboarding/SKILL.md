---
name: ops-platform-onboarding
description: |
  Structured workflow for onboarding new services to the internal platform
  including infrastructure provisioning, observability setup, and documentation.

trigger: |
  - New service deployment to platform
  - Service migration to platform
  - Platform capability adoption
  - Team onboarding to platform

skip_when: |
  - Application development -> use ring-dev-team specialists
  - Existing service configuration changes -> standard change management
  - Non-platform infrastructure -> use ops-infrastructure-architect

related:
  similar: [dev-cycle]
  uses: [platform-engineer]
---

# Platform Onboarding Workflow

This skill defines the structured process for onboarding services to the internal developer platform. Use it to ensure consistent, compliant service deployments.

---

## Onboarding Phases

| Phase | Focus | Output |
|-------|-------|--------|
| **1. Requirements** | Gather service requirements | Requirements doc |
| **2. Golden Path Selection** | Choose deployment pattern | Selected template |
| **3. Infrastructure Provisioning** | Create service resources | Infrastructure ready |
| **4. Observability Setup** | Configure monitoring | Dashboards/alerts |
| **5. Security Configuration** | Apply security controls | Security validated |
| **6. Documentation** | Complete service docs | Runbook ready |
| **7. Handoff** | Transfer to service team | Ownership confirmed |

---

## Phase 1: Requirements Gathering

### Service Requirements Checklist

```markdown
## Service Onboarding Request

**Service Name:** [name]
**Team:** [owning team]
**Requested By:** [name]
**Target Date:** YYYY-MM-DD

### Service Information

| Attribute | Value |
|-----------|-------|
| Service type | [API / Worker / Batch / Frontend] |
| Language/runtime | [Go / Node.js / Python / etc.] |
| Criticality | [Tier 1/2/3/4] |
| External traffic | [Yes / No] |
| Data sensitivity | [PII / Financial / Public] |

### Resource Requirements

| Resource | Requirement | Notes |
|----------|-------------|-------|
| CPU | [cores] | [peak/average] |
| Memory | [GB] | [peak/average] |
| Storage | [GB] | [type: SSD/HDD] |
| Database | [type] | [shared/dedicated] |
| Cache | [type] | [shared/dedicated] |

### Dependencies

| Dependency | Type | SLA Required |
|------------|------|--------------|
| [service] | Internal | [Yes/No] |
| [external] | External | [Yes/No] |

### Compliance Requirements

- [ ] SOC2
- [ ] PCI-DSS
- [ ] GDPR
- [ ] HIPAA
- [ ] Other: ____________
```

---

## Phase 2: Golden Path Selection

### Available Golden Paths

| Golden Path | Use Case | Includes |
|-------------|----------|----------|
| **api-service** | REST/GraphQL APIs | ALB, EKS, RDS, ElastiCache |
| **worker-service** | Background processing | SQS, EKS, auto-scaling |
| **batch-job** | Scheduled jobs | EventBridge, Lambda/Fargate |
| **frontend-app** | Static sites, SPAs | CloudFront, S3, API Gateway |
| **data-pipeline** | ETL, streaming | Kinesis, Glue, S3 |

### Golden Path Selection Matrix

| Requirement | api-service | worker-service | batch-job |
|-------------|-------------|----------------|-----------|
| HTTP traffic | Yes | No | No |
| Queue processing | Optional | Yes | Optional |
| Scheduled runs | No | No | Yes |
| Real-time | Yes | Near-real-time | No |
| Auto-scaling | Yes | Yes | N/A |

### Selection Template

```markdown
## Golden Path Selection

**Service:** [name]
**Selected Path:** [api-service / worker-service / etc.]

### Rationale

1. Service type [X] matches [golden path] pattern
2. Traffic requirements of [X] supported by [features]
3. Compliance requirements met by built-in [controls]

### Customizations Required

| Standard Component | Customization | Reason |
|--------------------|---------------|--------|
| [component] | [change] | [why] |

### Approval

- [ ] Platform team reviewed
- [ ] Security team reviewed (if customizations)
- [ ] Architecture team reviewed (if non-standard)
```

---

## Phase 3: Infrastructure Provisioning

### Provisioning Checklist

- [ ] Namespace/project created
- [ ] Compute resources provisioned
- [ ] Database provisioned (if required)
- [ ] Cache provisioned (if required)
- [ ] Load balancer configured
- [ ] DNS entries created
- [ ] SSL certificates provisioned
- [ ] Secrets stored in vault
- [ ] IAM roles/service accounts created

### Terraform/IaC Template

```hcl
# Example service provisioning
module "service" {
  source = "platform/service-template"

  service_name    = var.service_name
  team            = var.team
  environment     = var.environment
  golden_path     = "api-service"

  # Compute
  cpu_request     = "500m"
  memory_request  = "512Mi"
  replicas_min    = 2
  replicas_max    = 10

  # Database
  database_enabled = true
  database_class   = "db.t3.medium"

  # Tags
  tags = {
    Team        = var.team
    Environment = var.environment
    CostCenter  = var.cost_center
  }
}
```

### Provisioning Verification

```bash
# Verify namespace
kubectl get namespace [service-name]

# Verify compute
kubectl get deployment -n [service-name]

# Verify database
aws rds describe-db-instances --db-instance-identifier [service-db]

# Verify DNS
dig [service-name].internal.example.com
```

---

## Phase 4: Observability Setup

### Observability Checklist

- [ ] Structured logging configured
- [ ] Tracing instrumentation added
- [ ] Metrics endpoints exposed
- [ ] Service dashboard created
- [ ] SLI/SLO defined
- [ ] Alerts configured
- [ ] On-call integration set up

### Dashboard Template

Standard service dashboard includes:

| Panel | Metrics |
|-------|---------|
| Request rate | requests/sec, by status code |
| Error rate | 5xx rate, 4xx rate |
| Latency | p50, p95, p99 |
| Saturation | CPU, memory utilization |
| Dependencies | Upstream/downstream health |

### Alert Configuration

| Alert | Condition | Severity | Response |
|-------|-----------|----------|----------|
| High error rate | 5xx > 1% for 5m | Critical | Page on-call |
| High latency | p99 > 1s for 5m | Warning | Alert team |
| Low availability | uptime < 99.9% | Critical | Page on-call |
| Resource saturation | CPU > 85% for 10m | Warning | Alert team |

### SLI/SLO Definition

```markdown
## Service Level Objectives

**Service:** [name]
**SLO Version:** 1.0

| SLI | Target | Measurement |
|-----|--------|-------------|
| Availability | 99.9% | Successful requests / total requests |
| Latency | p99 < 500ms | Request duration percentile |
| Error rate | < 0.1% | 5xx responses / total responses |

### Error Budget

- Monthly budget: 43.2 minutes downtime
- Current consumption: [X]%
- Actions if budget exceeded: [escalation process]
```

---

## Phase 5: Security Configuration

### Security Checklist

- [ ] Network policies applied
- [ ] Service mesh mTLS configured
- [ ] Secrets management configured
- [ ] IAM permissions follow least privilege
- [ ] Security scanning in CI/CD
- [ ] Dependency scanning enabled
- [ ] WAF rules applied (if external)

### Network Policy Template

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: service-policy
  namespace: [service-name]
spec:
  podSelector:
    matchLabels:
      app: [service-name]
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: istio-system
      ports:
        - port: 8080
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: database
      ports:
        - port: 5432
```

### Security Review

```markdown
## Security Configuration Review

**Service:** [name]
**Reviewer:** @security-team

| Control | Status | Notes |
|---------|--------|-------|
| mTLS enabled | PASS | Istio strict mode |
| Network policies | PASS | Ingress/egress restricted |
| Secrets management | PASS | Using Vault |
| Least privilege IAM | PASS | Scoped to required resources |
| Vulnerability scanning | PASS | Trivy in CI/CD |
```

---

## Phase 6: Documentation

### Required Documentation

| Document | Purpose | Template |
|----------|---------|----------|
| **Service Overview** | What the service does | README.md |
| **Runbook** | Operational procedures | runbook.md |
| **Architecture** | Design decisions | architecture.md |
| **API Docs** | Interface documentation | OpenAPI spec |
| **On-call Guide** | Incident handling | oncall.md |

### Runbook Template

```markdown
## [Service Name] Runbook

### Service Overview

[Brief description of what the service does]

### Quick Reference

| Item | Value |
|------|-------|
| Repository | [link] |
| Dashboard | [link] |
| Logs | [query link] |
| On-call | [PagerDuty service] |

### Common Operations

#### Restart Service

```bash
kubectl rollout restart deployment/[service] -n [namespace]
```

#### Scale Service

```bash
kubectl scale deployment/[service] -n [namespace] --replicas=X
```

#### Check Logs

```bash
kubectl logs -l app=[service] -n [namespace] --tail=100
```

### Troubleshooting

| Symptom | Possible Cause | Resolution |
|---------|----------------|------------|
| High latency | DB connection pool | Scale DB or optimize queries |
| 5xx errors | Dependency down | Check upstream services |
| OOM kills | Memory leak | Investigate heap, restart |

### Escalation

| Level | Contact | When |
|-------|---------|------|
| L1 | [team Slack channel] | First response |
| L2 | [on-call engineer] | Cannot resolve in 15m |
| L3 | [service owner] | Critical/extended outage |
```

---

## Phase 7: Handoff

### Handoff Checklist

- [ ] Service owner identified and trained
- [ ] On-call rotation set up
- [ ] Access provisioned to team
- [ ] Documentation reviewed by team
- [ ] Shadowing session completed
- [ ] Ownership officially transferred

### Handoff Template

```markdown
## Service Handoff Confirmation

**Service:** [name]
**Date:** YYYY-MM-DD
**Platform Team:** @[name]
**Service Owner:** @[name]

### Completed Items

- [x] Infrastructure provisioned and documented
- [x] Observability configured
- [x] Security controls applied
- [x] Runbook created and reviewed
- [x] On-call rotation configured
- [x] Training session completed

### Outstanding Items

| Item | Owner | Due Date |
|------|-------|----------|
| [item] | [owner] | YYYY-MM-DD |

### Acknowledgment

By signing below, the service owner confirms:
1. Receipt of all documentation
2. Understanding of operational procedures
3. Acceptance of on-call responsibilities

**Service Owner:** _________________ Date: _______
**Platform Team:** _________________ Date: _______
```

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Skip documentation, code is self-explanatory" | On-call != developers | **Complete runbook** |
| "We'll add observability later" | Blind deployments = incidents | **Observability on day 1** |
| "Golden path doesn't fit exactly" | Customizations add complexity | **Justify every deviation** |
| "Security can come later" | Later = never for security | **Security from start** |
| "Team can figure it out" | Assumptions cause outages | **Complete handoff process** |

---

## Dispatch Specialist

For platform onboarding tasks, dispatch:

```
Task tool:
  subagent_type: "platform-engineer"
  model: "opus"
  prompt: |
    SERVICE ONBOARDING REQUEST
    Service: [name]
    Team: [team]
    Type: [API/Worker/Batch]
    Requirements: [summary]
    Golden Path: [if known]
```
