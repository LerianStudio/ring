# Two-Track Pre-Dev Workflow Design

**Date:** 2025-11-06
**Status:** Draft
**Author:** Ring Team

## Problem Statement

Current 8-gate pre-dev workflow is comprehensive but overkill for small features:
- Adding a button (<1 day work) requires 8 planning documents
- Simple bug fix with API change needs full workflow
- Overhead discourages proper planning for small work

Result: Developers skip pre-dev entirely for "small" work, then discover it wasn't small.

## Solution: Two-Track System

### Track Selection Criteria

**Small Track (3 gates)** - Use when feature meets ALL:
- ✅ Estimated implementation: <2 days
- ✅ No new external dependencies
- ✅ No new data models/entities
- ✅ No multi-service integration
- ✅ Uses existing architecture patterns
- ✅ Single developer can complete

**Large Track (8 gates)** - Use when feature has ANY:
- ❌ Estimated implementation: ≥2 days
- ❌ New external dependencies (APIs, databases, services)
- ❌ New data models or entities
- ❌ Multi-service integration
- ❌ New architecture patterns
- ❌ Requires team collaboration

**When in doubt:** Use Large Track. Better over-plan than under-plan.

## Small Track (3 Gates)

**Gate 1: pre-dev-prd-creation**
- Define WHAT and WHY
- Success criteria
- Constraints
- **Output:** PRD.md

**Gate 2: pre-dev-trd-creation**
- Define HOW (architecture approach)
- Component breakdown
- **Output:** TRD.md

**Gate 3: pre-dev-task-breakdown**
- Work increments
- **Output:** PLAN.md with tasks

**Skip:**
- Feature Map (only one feature)
- API Design (may be internal only)
- Data Model (may not need persistence)
- Dependency Map (uses existing stack)
- Subtask Creation (tasks already small)

**Total time:** 30-60 minutes planning for <2 day implementation

## Large Track (8 Gates)

**Full workflow:**
1. PRD Creation - Business requirements
2. Feature Map - Feature relationships
3. TRD Creation - Technical architecture
4. API Design - Component contracts
5. Data Model - Entity relationships
6. Dependency Map - Technology selection
7. Task Breakdown - Work increments
8. Subtask Creation - Atomic units

**Total time:** 2-4 hours planning for ≥2 day implementation

## Decision Tree

```
Feature request received
    ↓
Estimate implementation time?
    ↓
< 2 days ──────────────┐
    ↓                  ↓
Check criteria      ≥ 2 days
    ↓                  ↓
All ✓ criteria?    LARGE TRACK
    ↓ YES              (8 gates)
    ↓ NO
    ↓
SMALL TRACK ←──────────┘
(3 gates)
```

## Examples

### Small Track Examples

**Add logout button to UI:**
- Estimate: 4 hours
- No new dependencies (uses existing auth)
- No data model changes
- Uses existing UI patterns
- **Track:** Small (3 gates)

**Fix email validation:**
- Estimate: 1 day
- No new dependencies
- No data model
- Bug fix in existing code
- **Track:** Small (3 gates)

**Add API rate limiting:**
- Estimate: 1.5 days
- Uses existing middleware pattern
- No new data models
- Single service change
- **Track:** Small (3 gates)

### Large Track Examples

**Add user authentication:**
- Estimate: 3-5 days
- New dependencies (JWT library, session store)
- New data models (User, Session)
- Multi-service (auth service + API changes)
- **Track:** Large (8 gates)

**Implement payment processing:**
- Estimate: 1 week
- New dependencies (Stripe SDK, webhook handler)
- New data models (Payment, Transaction, Subscription)
- Multi-service integration
- New architecture pattern (event-driven payments)
- **Track:** Large (8 gates)

**Add file upload with CDN:**
- Estimate: 3 days
- New dependencies (S3 SDK, image processing)
- New data models (Upload, Asset)
- Multi-service (storage + CDN)
- **Track:** Large (8 gates)

## Implementation

### Where to Add Two-Track Guidance

**Option 1: Update using-ring skill**
- Add "Pre-Dev Track Selection" section
- Decision tree before starting planning

**Option 2: Create new skill: pre-dev-track-selection**
- Dedicated skill for choosing track
- Used before any pre-dev gate

**Option 3: Update each pre-dev skill's "When to Use"**
- Add "Skip this gate if Small Track" to gates 2, 4, 5, 6, 8

**Recommendation:** Option 1 (using-ring) - central decision point before workflow starts.

## Benefits

**Reduces planning overhead for small work:**
- 30-60 min planning (vs 2-4 hours)
- Still gets requirements + architecture + tasks
- Encourages proper planning even for "small" work

**Maintains rigor for complex work:**
- Large features still get full 8-gate treatment
- Multi-service, new models, new dependencies = full planning

**Clear decision criteria:**
- Objective criteria (time, dependencies, models)
- When in doubt, use Large Track

## Risks

**Risk 1: Small features become large mid-implementation**
- Mitigation: If feature grows during implementation, switch to Large Track
- Add remaining gates (Feature Map, API Design, etc.)

**Risk 2: Developers always pick Small Track**
- Mitigation: "When in doubt, use Large Track" + ANY criteria violation = Large
- Make Large Track the default, Small Track requires ALL ✓

**Risk 3: Team disagreement on track**
- Mitigation: Clear objective criteria (2 days, dependencies, models, services)
- If team disagrees, use Large Track

## Success Metrics

- Small features (<2 days) use Small Track: 30-60 min planning
- Large features (≥2 days) use Large Track: 2-4 hours planning
- Zero features skip planning entirely
- Track switches mid-implementation: <10% (indicates good estimation)

## Next Steps

1. Update using-ring skill with two-track decision tree
2. Update each pre-dev gate with "Small Track: Skip this gate" guidance
3. Test with real feature scenarios
4. Iterate based on usage patterns
