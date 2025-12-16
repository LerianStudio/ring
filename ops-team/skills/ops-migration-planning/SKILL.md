---
name: ops-migration-planning
description: |
  Structured workflow for infrastructure migration planning including cloud migrations,
  technology upgrades, and data center transitions.

trigger: |
  - Cloud-to-cloud migration
  - On-premises to cloud migration
  - Technology platform upgrades
  - Data center consolidation/exit

skip_when: |
  - Application refactoring -> use ring-dev-team specialists
  - Database schema migrations -> use ring-dev-team specialists
  - Simple resource moves -> standard change management

related:
  similar: [ops-disaster-recovery]
  uses: [infrastructure-architect, platform-engineer]
---

# Migration Planning Workflow

This skill defines the structured process for infrastructure migration planning. Use it for systematic, risk-managed migration execution.

---

## Migration Planning Phases

| Phase | Focus | Output |
|-------|-------|--------|
| **1. Discovery** | Understand current state | Inventory document |
| **2. Assessment** | Evaluate migration options | Assessment report |
| **3. Planning** | Design migration approach | Migration plan |
| **4. Preparation** | Build target environment | Environment ready |
| **5. Migration** | Execute migration | Migrated workloads |
| **6. Validation** | Verify success | Validation report |
| **7. Cutover** | Switch production traffic | Cutover complete |
| **8. Optimization** | Tune and optimize | Optimized state |

---

## Phase 1: Discovery

### Discovery Checklist

- [ ] Application inventory complete
- [ ] Infrastructure dependencies mapped
- [ ] Data flows documented
- [ ] Integration points identified
- [ ] Current costs documented
- [ ] Performance baselines captured
- [ ] Compliance requirements listed

### Discovery Template

```markdown
## Migration Discovery Report

**Project:** [migration name]
**Date:** YYYY-MM-DD
**Scope:** [on-prem to AWS / AWS to GCP / etc.]

### Application Inventory

| Application | Type | Language | Database | Traffic | Criticality |
|-------------|------|----------|----------|---------|-------------|
| api-service | API | Go | PostgreSQL | 1000 rps | Tier 1 |
| worker | Worker | Python | Redis | N/A | Tier 2 |
| frontend | SPA | React | N/A | 500 rps | Tier 2 |

### Infrastructure Inventory

| Resource | Current | Count | Utilization | Notes |
|----------|---------|-------|-------------|-------|
| Web servers | VM 4CPU/8GB | 10 | 40% avg | Auto-scaled |
| App servers | VM 8CPU/16GB | 20 | 60% avg | Fixed |
| Database | PostgreSQL | 1 primary + 2 replica | 70% | 500GB data |
| Cache | Redis | 3 node cluster | 30% | 10GB data |

### Dependencies

| From | To | Type | Migration Impact |
|------|-----|------|------------------|
| api-service | PostgreSQL | Direct | Must migrate together |
| api-service | Redis | Direct | Can migrate independently |
| frontend | api-service | HTTP | Can migrate independently |

### Data Inventory

| Data Store | Size | Growth Rate | Sensitivity | Retention |
|------------|------|-------------|-------------|-----------|
| PostgreSQL | 500GB | 10GB/month | PII | 7 years |
| S3 | 2TB | 100GB/month | Public | 1 year |
| Redis | 10GB | Stable | Session | N/A |
```

---

## Phase 2: Assessment

### Migration Strategy Options

| Strategy | Description | Best For | Risk |
|----------|-------------|----------|------|
| **Rehost** (Lift & Shift) | Move as-is | Quick migration, legacy | Low |
| **Replatform** | Minor optimizations | Cloud-native benefits | Medium |
| **Refactor** | Redesign for cloud | Maximum benefit | High |
| **Retire** | Decommission | Unused systems | None |
| **Retain** | Keep in place | Not suitable for migration | None |

### Assessment Matrix

```markdown
## Migration Assessment

### Per-Application Strategy

| Application | Strategy | Rationale | Effort | Risk |
|-------------|----------|-----------|--------|------|
| api-service | Replatform | Containerize, use managed DB | Medium | Low |
| worker | Rehost | Already containerized | Low | Low |
| legacy-app | Retire | Unused, no traffic | None | None |

### Migration Waves

| Wave | Applications | Dependencies | Duration | Risk |
|------|--------------|--------------|----------|------|
| 1 | worker, cache | None | 2 weeks | Low |
| 2 | api-service, DB | Worker | 4 weeks | Medium |
| 3 | frontend | API | 1 week | Low |

### Cost Analysis

| Item | Current Monthly | Target Monthly | Delta |
|------|-----------------|----------------|-------|
| Compute | $10,000 | $8,000 | -20% |
| Database | $5,000 | $6,000 | +20% |
| Network | $2,000 | $1,500 | -25% |
| **Total** | **$17,000** | **$15,500** | **-9%** |

### Migration Costs (One-time)

| Item | Cost | Notes |
|------|------|-------|
| Data transfer | $500 | S3 to S3 |
| Parallel running | $8,000 | 2 weeks overlap |
| Consulting | $10,000 | Optional |
| **Total** | **$18,500** | |
```

---

## Phase 3: Planning

### Migration Plan Template

```markdown
## Migration Plan

**Project:** [name]
**Target Date:** YYYY-MM-DD
**Migration Lead:** [name]

### Timeline

| Phase | Start | End | Duration |
|-------|-------|-----|----------|
| Preparation | YYYY-MM-DD | YYYY-MM-DD | 2 weeks |
| Wave 1 | YYYY-MM-DD | YYYY-MM-DD | 2 weeks |
| Wave 2 | YYYY-MM-DD | YYYY-MM-DD | 4 weeks |
| Wave 3 | YYYY-MM-DD | YYYY-MM-DD | 1 week |
| Optimization | YYYY-MM-DD | YYYY-MM-DD | 2 weeks |

### Resource Requirements

| Role | Allocation | Duration |
|------|------------|----------|
| Migration Lead | 100% | Full project |
| Platform Engineer | 50% | Full project |
| Application Developers | 25% per team | Per wave |
| DBA | 50% | Waves 1-2 |

### Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Data loss | Low | Critical | Multiple backups, validation |
| Extended downtime | Medium | High | Rollback plan, parallel running |
| Performance degradation | Medium | Medium | Load testing, monitoring |
| Integration failures | Medium | High | Integration testing pre-cutover |

### Rollback Criteria

Migration will be rolled back if ANY of the following occur:
1. Data integrity issues detected
2. Performance degradation >20% vs baseline
3. Critical functionality not working
4. Security vulnerability discovered
5. Stakeholder veto during cutover window
```

---

## Phase 4: Preparation

### Environment Preparation

- [ ] Target infrastructure provisioned
- [ ] Network connectivity established
- [ ] Security controls configured
- [ ] Monitoring set up
- [ ] CI/CD pipelines updated
- [ ] Secrets migrated
- [ ] DNS prepared (low TTL)

### Preparation Checklist

```markdown
## Environment Preparation Status

### Infrastructure

| Component | Status | Verified By | Date |
|-----------|--------|-------------|------|
| VPC/Network | Complete | @platform | YYYY-MM-DD |
| Compute clusters | Complete | @platform | YYYY-MM-DD |
| Database | Complete | @dba | YYYY-MM-DD |
| Cache | Complete | @platform | YYYY-MM-DD |
| Load balancers | Complete | @platform | YYYY-MM-DD |

### Connectivity

| Connection | Source | Target | Status |
|------------|--------|--------|--------|
| VPN tunnel | Source DC | Target VPC | Active |
| Database replication | Source DB | Target DB | Active |
| API connectivity | Source app | Target deps | Verified |

### Data Sync

| Data Store | Method | Lag | Status |
|------------|--------|-----|--------|
| PostgreSQL | Logical replication | <5 sec | Active |
| S3 | Cross-region replication | <15 min | Active |
| Redis | None (rebuild on migration) | N/A | N/A |
```

---

## Phase 5: Migration Execution

### Migration Execution Checklist

```markdown
## Wave [N] Migration Runbook

**Date:** YYYY-MM-DD
**Start Time:** HH:MM UTC
**Migration Lead:** [name]

### Pre-Migration Checks

- [ ] All team members available
- [ ] Communication channels ready
- [ ] Rollback plan reviewed
- [ ] Stakeholders notified
- [ ] Monitoring dashboards open
- [ ] Data sync lag acceptable

### Migration Steps

| Step | Action | Owner | Expected Duration | Rollback |
|------|--------|-------|-------------------|----------|
| 1 | Freeze source changes | App team | 5 min | Unfreeze |
| 2 | Final data sync | DBA | 15 min | N/A |
| 3 | Stop source application | App team | 2 min | Restart source |
| 4 | Verify data sync complete | DBA | 5 min | N/A |
| 5 | Start target application | App team | 5 min | Stop target |
| 6 | Run smoke tests | QA | 10 min | Stop target |
| 7 | Update DNS/routing | Platform | 5 min | Revert DNS |
| 8 | Monitor for 30 min | All | 30 min | Rollback |

### Post-Migration Verification

- [ ] Application responding
- [ ] Error rates normal
- [ ] Latency within baseline
- [ ] Data integrity verified
- [ ] All integrations working
```

---

## Phase 6: Validation

### Validation Checklist

- [ ] Functional testing passed
- [ ] Performance testing passed
- [ ] Integration testing passed
- [ ] Security validation passed
- [ ] Data integrity verified
- [ ] Monitoring working

### Validation Report Template

```markdown
## Migration Validation Report

**Wave:** [N]
**Date:** YYYY-MM-DD
**Status:** [PASS / FAIL]

### Functional Validation

| Test | Expected | Actual | Status |
|------|----------|--------|--------|
| Login flow | Success | Success | PASS |
| API endpoints | All 200/201 | All 200/201 | PASS |
| Background jobs | Processing | Processing | PASS |

### Performance Validation

| Metric | Baseline | Target | Actual | Status |
|--------|----------|--------|--------|--------|
| p50 latency | 50ms | <60ms | 45ms | PASS |
| p99 latency | 200ms | <250ms | 180ms | PASS |
| Error rate | 0.1% | <0.2% | 0.08% | PASS |
| Throughput | 1000 rps | >900 rps | 1100 rps | PASS |

### Data Validation

| Check | Method | Result |
|-------|--------|--------|
| Row counts | SELECT COUNT(*) | Match |
| Checksums | MD5 on sample | Match |
| Foreign keys | Constraint check | Valid |
| Indexes | Index verification | Present |
```

---

## Phase 7: Cutover

### Cutover Criteria

**ALL must be true to proceed with production cutover:**

1. All validation tests passed
2. Rollback plan tested and ready
3. Stakeholder approval obtained
4. Communication sent
5. On-call team ready
6. Monitoring in place

### Cutover Runbook

```markdown
## Production Cutover Runbook

**Date:** YYYY-MM-DD
**Cutover Window:** HH:MM - HH:MM UTC
**Cutover Lead:** [name]

### Go/No-Go Checklist

- [ ] Validation report approved
- [ ] Rollback tested within 24h
- [ ] Stakeholder sign-off received
- [ ] Customer communication sent
- [ ] Team availability confirmed
- [ ] War room established

### Cutover Steps

1. **T-30min:** Final go/no-go meeting
2. **T-15min:** Final data sync verification
3. **T-0:** Begin cutover (follow wave runbook)
4. **T+30min:** Initial validation complete
5. **T+2h:** Extended monitoring
6. **T+24h:** Declare migration complete (or rollback)

### Rollback Decision Points

| Time | Trigger | Decision |
|------|---------|----------|
| T+15min | Critical errors | Immediate rollback |
| T+30min | >5% error rate | Rollback recommended |
| T+1h | Performance issues | Evaluate, possible rollback |
| T+2h | Stability issues | Extended evaluation |
```

---

## Phase 8: Optimization

### Post-Migration Optimization

- [ ] Right-size resources based on actual usage
- [ ] Enable cost optimization features
- [ ] Clean up source environment
- [ ] Update documentation
- [ ] Conduct lessons learned
- [ ] Archive migration artifacts

### Optimization Template

```markdown
## Post-Migration Optimization Report

**Migration:** [name]
**Optimization Period:** YYYY-MM-DD to YYYY-MM-DD

### Resource Optimization

| Resource | Initial Size | Optimized Size | Savings |
|----------|--------------|----------------|---------|
| Compute | 10 x m5.xlarge | 8 x m5.large | $400/mo |
| Database | db.r5.2xlarge | db.r5.xlarge | $200/mo |

### Source Environment Cleanup

| Resource | Action | Date | Savings |
|----------|--------|------|---------|
| Old VMs | Terminated | YYYY-MM-DD | $5,000/mo |
| Old storage | Deleted | YYYY-MM-DD | $500/mo |

### Lessons Learned

1. **What went well:** [items]
2. **What could improve:** [items]
3. **Action items for future migrations:** [items]
```

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Big bang is faster" | Big bang has higher risk | **Migrate in waves** |
| "Skip parallel running" | No safety net | **Run parallel minimum 1 week** |
| "Data validation is overkill" | Data loss is catastrophic | **Validate every migration** |
| "Rollback won't be needed" | Optimism != planning | **Test rollback before cutover** |
| "We can optimize later" | Later = never | **Right-size during optimization phase** |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Migrate everything this weekend" | "Big bang migrations carry unacceptable risk. Wave-based migration is required." |
| "Skip parallel running, too expensive" | "Parallel running is safety net. Cost is justified by risk reduction." |
| "Data validation takes too long" | "Data integrity is non-negotiable. Validation is required before cutover." |
| "We trust the process, skip rollback test" | "Rollback test is mandatory. Untested rollbacks fail when needed." |

---

## Dispatch Specialists

For migration planning tasks, dispatch:

```
Task tool:
  subagent_type: "infrastructure-architect"
  model: "opus"
  prompt: |
    MIGRATION PLANNING REQUEST
    Type: [cloud-to-cloud / on-prem-to-cloud / upgrade]
    Source: [current environment]
    Target: [target environment]
    Scope: [applications/services]
    Timeline: [desired completion]
    Constraints: [budget, compliance, etc.]
```

For platform preparation:

```
Task tool:
  subagent_type: "platform-engineer"
  model: "opus"
  prompt: |
    MIGRATION ENVIRONMENT PREPARATION
    Target Platform: [platform details]
    Services: [services to migrate]
    Requirements: [infrastructure requirements]
```
