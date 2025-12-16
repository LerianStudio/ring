---
name: ops-disaster-recovery
description: |
  Structured workflow for disaster recovery planning, implementation, and testing
  including RTO/RPO definition, DR strategy selection, and failover procedures.

trigger: |
  - DR strategy development
  - DR plan review/update
  - DR testing/drills
  - Post-incident DR improvement

skip_when: |
  - Day-to-day backup operations -> standard procedures
  - Application-level redundancy -> use ring-dev-team specialists
  - Single-instance failure recovery -> standard runbooks

related:
  similar: [ops-capacity-planning]
  uses: [infrastructure-architect]
---

# Disaster Recovery Workflow

This skill defines the structured process for disaster recovery planning and testing. Use it for comprehensive DR strategy development and validation.

---

## DR Planning Phases

| Phase | Focus | Output |
|-------|-------|--------|
| **1. Business Impact** | Define criticality and requirements | BIA document |
| **2. Strategy Selection** | Choose appropriate DR strategy | DR strategy |
| **3. Architecture Design** | Design DR infrastructure | DR architecture |
| **4. Runbook Development** | Document failover procedures | DR runbooks |
| **5. Testing** | Validate DR capabilities | Test report |
| **6. Maintenance** | Keep DR current | Update schedule |

---

## Phase 1: Business Impact Analysis

### Service Classification

Classify services by business criticality:

| Tier | Definition | RTO | RPO | Example Services |
|------|------------|-----|-----|------------------|
| **Tier 1** | Critical - business cannot operate | <15 min | <1 min | Payment processing |
| **Tier 2** | Important - significant impact | <1 hour | <15 min | Customer portal |
| **Tier 3** | Standard - moderate impact | <4 hours | <1 hour | Internal tools |
| **Tier 4** | Low - minimal impact | <24 hours | <24 hours | Dev environments |

### BIA Template

```markdown
## Business Impact Analysis

**Assessment Date:** YYYY-MM-DD
**Assessed By:** [name]

### Service Classification

| Service | Business Function | Revenue Impact | Tier | RTO | RPO |
|---------|------------------|----------------|------|-----|-----|
| payment-api | Process transactions | $X,XXX/hour | 1 | 15 min | 1 min |
| customer-portal | Customer access | $XXX/hour | 2 | 1 hour | 15 min |
| admin-tools | Internal operations | $0/hour | 3 | 4 hours | 1 hour |

### Data Classification

| Data Type | Classification | Backup Frequency | Retention |
|-----------|---------------|------------------|-----------|
| Transaction data | Critical | Continuous | 7 years |
| Customer data | Important | Hourly | 3 years |
| Application logs | Standard | Daily | 90 days |

### Dependencies

| Service | Dependencies | DR Impact |
|---------|--------------|-----------|
| payment-api | Database, payment-gateway | All must fail over together |
| customer-portal | Database, auth-service | Sequential failover possible |
```

---

## Phase 2: Strategy Selection

### DR Strategy Comparison

| Strategy | RTO | RPO | Cost | Complexity | Best For |
|----------|-----|-----|------|------------|----------|
| **Backup & Restore** | Hours | Hours | $ | Low | Tier 4 services |
| **Pilot Light** | 30-60 min | Minutes | $$ | Medium | Tier 3 services |
| **Warm Standby** | 10-30 min | Seconds-Minutes | $$$ | Medium-High | Tier 2 services |
| **Hot Standby** | <10 min | Seconds | $$$$ | High | Tier 1 services |
| **Multi-Active** | Near-zero | Near-zero | $$$$$ | Very High | Ultra-critical |

### Strategy Selection Matrix

```markdown
## DR Strategy Selection

### Requirements Summary

| Requirement | Value |
|-------------|-------|
| Target RTO | [X minutes/hours] |
| Target RPO | [X minutes/hours] |
| Budget | $[X,XXX]/month for DR |
| Compliance | [frameworks] |

### Strategy Decision

**Selected Strategy:** [Pilot Light / Warm Standby / Hot Standby]

**Rationale:**
1. RTO requirement of [X] achieved by [strategy]
2. RPO requirement of [X] achieved with [replication method]
3. Budget of $[X]/month supports [strategy] (~XX% of production cost)
4. Compliance requirement for [X] met with [features]

### Trade-offs Accepted

| Trade-off | Impact | Mitigation |
|-----------|--------|------------|
| Higher DR cost | +$X/month | Justified by RTO requirement |
| Manual failover steps | 5-10 min added | Automation planned Q2 |
```

---

## Phase 3: Architecture Design

### DR Architecture Components

| Component | Primary | DR | Replication |
|-----------|---------|----|----|
| DNS | Route53 | Route53 | Global service |
| Load Balancer | ALB (us-east-1) | ALB (us-west-2) | Configuration sync |
| Compute | EKS (us-east-1) | EKS (us-west-2) | GitOps deployment |
| Database | Aurora (us-east-1) | Aurora Global (us-west-2) | Async replication |
| Storage | S3 (us-east-1) | S3 (us-west-2) | Cross-region replication |
| Secrets | Secrets Manager | Secrets Manager | Manual sync |

### Architecture Diagram Template

```
Primary Region (us-east-1)          DR Region (us-west-2)
┌─────────────────────────┐         ┌─────────────────────────┐
│                         │         │                         │
│  ┌─────────────────┐    │         │  ┌─────────────────┐    │
│  │     ALB         │    │         │  │     ALB         │    │
│  └────────┬────────┘    │         │  └────────┬────────┘    │
│           │             │         │           │ (standby)   │
│  ┌────────┴────────┐    │         │  ┌────────┴────────┐    │
│  │  EKS Cluster    │    │         │  │  EKS Cluster    │    │
│  │  (Active)       │    │         │  │  (Standby)      │    │
│  └────────┬────────┘    │         │  └────────┬────────┘    │
│           │             │         │           │             │
│  ┌────────┴────────┐    │  async  │  ┌────────┴────────┐    │
│  │  Aurora         │────┼────────►│  │  Aurora         │    │
│  │  (Primary)      │    │         │  │  (Replica)      │    │
│  └─────────────────┘    │         │  └─────────────────┘    │
│                         │         │                         │
└─────────────────────────┘         └─────────────────────────┘
              │                               │
              └───────────┬───────────────────┘
                          │
                   ┌──────┴──────┐
                   │   Route53   │
                   │   (Global)  │
                   └─────────────┘
```

---

## Phase 4: Runbook Development

### Failover Runbook Structure

```markdown
## Failover Runbook: [Service Name]

**Version:** 1.0
**Last Updated:** YYYY-MM-DD
**Owner:** [team]

### Pre-Conditions

- [ ] DR region healthy (check dashboard)
- [ ] Replication lag <[X seconds/minutes]
- [ ] On-call personnel available
- [ ] Communication channels ready

### Failover Decision Criteria

| Criteria | Automatic | Manual |
|----------|-----------|--------|
| Primary region unavailable >5 min | Yes | - |
| Replication lag >15 min | - | Yes |
| Data corruption detected | - | Yes |
| Planned maintenance | - | Yes |

### Failover Steps

1. **Verify DR Readiness** (2 min)
   ```bash
   # Check DR database status
   aws rds describe-db-clusters --region us-west-2

   # Check EKS cluster status
   kubectl --context=dr get nodes
   ```

2. **Stop Writes to Primary** (1 min)
   ```bash
   # Scale down primary services
   kubectl --context=primary scale deployment/api --replicas=0
   ```

3. **Promote DR Database** (5 min)
   ```bash
   # Promote Aurora replica
   aws rds failover-global-cluster \
     --global-cluster-identifier my-global-cluster \
     --target-db-cluster-identifier dr-cluster
   ```

4. **Activate DR Services** (2 min)
   ```bash
   # Scale up DR services
   kubectl --context=dr scale deployment/api --replicas=10
   ```

5. **Update DNS** (1-5 min propagation)
   ```bash
   # Update Route53 health check
   aws route53 update-health-check \
     --health-check-id xxx \
     --disabled
   ```

6. **Verify Service** (5 min)
   ```bash
   # Health check
   curl https://api.example.com/health

   # Synthetic transaction
   ./scripts/synthetic-test.sh
   ```

### Rollback Steps

[If failover causes issues, steps to return to primary]

### Communication Template

**Internal:**
> DR failover initiated for [service] at [time UTC].
> Estimated completion: [X minutes].
> IC: [name]

**External (if customer-facing):**
> We are currently experiencing issues with [service].
> Our team is working to restore service.
> Status page: [url]
```

---

## Phase 5: Testing

### DR Test Types

| Test Type | Frequency | Scope | Impact |
|-----------|-----------|-------|--------|
| **Tabletop** | Quarterly | Full scenario walkthrough | None |
| **Component** | Monthly | Individual component failover | Minimal |
| **Partial** | Quarterly | Non-production failover | Low |
| **Full** | Annually | Production failover | Moderate |

### DR Test Template

```markdown
## DR Test Report

**Test Date:** YYYY-MM-DD
**Test Type:** [Tabletop/Component/Partial/Full]
**Scope:** [services tested]

### Test Objectives

1. Validate RTO of <[X minutes]
2. Validate RPO of <[X minutes]
3. Verify runbook accuracy
4. Identify gaps in DR readiness

### Test Results

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| RTO | 15 min | 12 min | PASS |
| RPO | 1 min | 45 sec | PASS |
| Data integrity | 100% | 100% | PASS |
| Runbook accuracy | 100% | 85% | PARTIAL |

### Timeline

| Time | Action | Status |
|------|--------|--------|
| 10:00 | Test initiated | OK |
| 10:02 | Primary shutdown simulated | OK |
| 10:08 | DR database promoted | OK |
| 10:12 | DR services activated | OK |
| 10:15 | Service verified | OK |

### Issues Found

| Issue | Severity | Action Required |
|-------|----------|-----------------|
| Step 4 command incorrect | Medium | Update runbook |
| DNS propagation slower | Low | Reduce TTL |

### Lessons Learned

1. [Lesson 1]
2. [Lesson 2]

### Action Items

| Item | Owner | Due Date |
|------|-------|----------|
| Update runbook step 4 | @ops | YYYY-MM-DD |
| Reduce DNS TTL | @platform | YYYY-MM-DD |
```

---

## Phase 6: Maintenance

### DR Maintenance Schedule

| Activity | Frequency | Owner |
|----------|-----------|-------|
| Runbook review | Quarterly | Platform team |
| DR test | Per test schedule | SRE team |
| Replication monitoring | Daily (automated) | Monitoring |
| Cost review | Monthly | FinOps |
| Architecture review | Annually | Architecture team |

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "DR can be added later" | DR added later is rarely tested | **DR is day-1 requirement** |
| "Backups are good enough" | Backups != DR. RTO is hours vs minutes. | **Design proper DR strategy** |
| "Too expensive for DR" | DR cost << outage cost | **Calculate business impact** |
| "We'll figure it out during incident" | Panic != good decisions | **Document runbooks NOW** |
| "Tested last year, still good" | Systems change constantly | **Test regularly** |

---

## Dispatch Specialist

For DR planning tasks, dispatch:

```
Task tool:
  subagent_type: "infrastructure-architect"
  model: "opus"
  prompt: |
    DR PLANNING REQUEST
    Services: [services requiring DR]
    RTO Requirement: [target]
    RPO Requirement: [target]
    Current State: [existing DR if any]
    REQUEST: [design/review/test planning]
```
