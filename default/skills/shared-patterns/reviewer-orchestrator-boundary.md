# Reviewer-Orchestrator Boundary

**CRITICAL PRINCIPLE: Reviewers REPORT, Agents FIX**

This document defines the mandatory separation of responsibilities between reviewer agents and implementation agents.

---

## The Orchestrator Principle

```
┌─────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR                             │
│  (ring:running-dev-cycle, user, or workflow coordinator)                │
│                                                                 │
│  1. Dispatches reviewers in parallel                            │
│  2. Collects review reports                                     │
│  3. Dispatches appropriate agent to fix issues                  │
│  4. Re-runs reviewers after fixes                               │
└─────────────────────────────────────────────────────────────────┘
         │                                    │
         ▼                                    ▼
┌─────────────────────────────┐          ┌─────────────────────────────────┐
│         REVIEWERS           │          │     IMPLEMENTATION AGENTS       │
│                             │          │                                 │
│ • ring:code-reviewer        │          │ • ring:backend-go               │
│ • ring:logic-reviewer       │          │ • ring:backend-ts               │
│ • ring:security-reviewer    │          │ • ring:frontend                 │
│ • ring:test-reviewer        │          │                                 │
│ • ring:nil-reviewer         │          │                                 │
│ • ring:dead-code-reviewer   │          │                                 │
│ • ring:perf-reviewer        │          │                                 │
│ • ring:tenancy-reviewer     │          │                                 │
│ • ring:commons-reviewer     │          │                                 │
│                             │          │                                 │
│ OUTPUT: Report              │          │ OUTPUT: Code changes            │
│ ACTION: NONE                │          │ ACTION: Edit, Create, Delete    │
│                             │          │                                 │
│ CANNOT: Edit files          │          │ CAN: Implement fixes            │
│ CANNOT: Fix issues          │          │ CAN: Run tests                  │
│ CANNOT: Run tests           │          │                                 │
└─────────────────────────────┘          └─────────────────────────────────┘
```

---

## Reviewer Responsibilities (MANDATORY)

| Responsibility | Description | Action |
|----------------|-------------|--------|
| **IDENTIFY** | Find issues, vulnerabilities, logic errors | Document with file:line references |
| **CLASSIFY** | Assign severity (CRITICAL/HIGH/MEDIUM/LOW) | Use calibration table |
| **EXPLAIN** | Describe problem and business impact | Include attack vectors, failure scenarios |
| **RECOMMEND** | Provide remediation guidance | Show corrected code as EXAMPLE |
| **REPORT** | Generate structured verdict | PASS/FAIL/NEEDS_DISCUSSION |

---

## Reviewer Prohibitions (NON-NEGOTIABLE)

| FORBIDDEN Action | Why It's Wrong | Correct Action |
|------------------|----------------|----------------|
| **Using Edit tool** | Reviewers are inspectors, not mechanics | Report issue → Orchestrator dispatches agent |
| **Using Create tool** | File creation is implementation work | Recommend file structure in report |
| **Running fix commands** | Execution is orchestrator's job | Include commands as recommendations |
| **Modifying code directly** | Breaks separation of concerns | Document required changes in report |
| **"I'll just fix this quickly"** | Scope creep destroys review integrity | **NO.** Report it. Let agent fix it. |
| **"Small fix, faster if I do it"** | Efficiency ≠ correctness. Process exists for a reason. | **NO.** Report it. Re-run after fix. |

---

## Why This Separation Matters

### 1. Review Integrity
- Reviewer who fixes code cannot objectively verify the fix
- "I fixed it, so it's correct" is self-confirmation bias
- Fresh eyes on fixes catch issues the fixer missed

### 2. Specialization
- Reviewers optimize for FINDING issues (broad coverage, checklist discipline)
- Implementers optimize for FIXING issues (deep context, correct patterns)
- Mixed roles = diluted effectiveness

### 3. Audit Trail
- Clear separation creates traceable workflow
- Who found it (reviewer) ≠ Who fixed it (agent)
- Enables proper accountability and learning

### 4. Parallel Execution
- Reviewers run in parallel (code, business-logic, security, test, nil-safety, dead-code, performance, multi-tenant, lib-commons)
- If reviewers also fixed, they'd need sequential execution
- Separation enables faster review cycles

---

## Orchestrator Workflow After Review

When reviewers report issues, orchestrator MUST:

```
1. AGGREGATE all reviewer findings
2. PRIORITIZE by severity (CRITICAL first)
3. DISPATCH appropriate agent:
   - Security issues → security specialist or backend engineer
   - Logic issues → backend engineer
   - Code quality → refactoring specialist or original implementer
4. VERIFY fix by re-running ALL reviewers
5. REPEAT until all reviewers PASS
```

---

## Anti-Rationalization Table for Reviewers

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "I'll fix this one-liner, it's trivial" | Trivial changes can introduce bugs. You're a reviewer, not an implementer. | **REPORT the issue. Do NOT edit.** |
| "Faster if I just fix it now" | Speed ≠ correctness. The agent doing the fix should verify it compiles/passes tests. | **REPORT the issue. Let agent fix + verify.** |
| "I know exactly how to fix this" | Knowing how ≠ having authority to do it. Your role is REVIEW. | **REPORT with recommendation. Do NOT implement.** |
| "It's my code anyway, I can fix my own issues" | Self-review of self-fixes is invalid. Fresh eyes required. | **REPORT the issue. Different agent or re-review required.** |
| "The orchestrator will take too long" | Process overhead is cheaper than bugs. Trust the workflow. | **REPORT and wait. Orchestrator handles dispatch.** |
| "This security issue is urgent, I should fix it immediately" | Urgency doesn't change your role. Report CRITICAL, orchestrator prioritizes. | **REPORT as CRITICAL. Orchestrator fast-tracks fix.** |

---

## How to Reference This Pattern

In reviewer agents, add this section:

```markdown
## Orchestrator Boundary

**HARD GATE:** This reviewer REPORTS issues. It does NOT fix them.

See [shared-patterns/reviewer-orchestrator-boundary.md](../skills/shared-patterns/reviewer-orchestrator-boundary.md) for:
- Why reviewers CANNOT edit files
- How orchestrator dispatches fixes
- Anti-rationalization table for "I'll just fix it" temptation

**Your output:** Structured report with VERDICT, Issues, Recommendations
**Your action:** NONE - Do NOT use Edit, Create, or Execute tools to modify code
**After you report:** Orchestrator dispatches appropriate agent to implement fixes
```

---

## Integration with ring:running-dev-cycle

The `ring:running-dev-cycle` skill enforces this boundary at Gate 8 (Review):

1. **Dispatch the selected review pool in parallel**: all 9 default reviewers (code, business-logic, security, test, nil-safety, dead-code, performance, multi-tenant, lib-commons), plus triggered conditional specialists in the same batch
2. **Collect structured reports** from each reviewer
3. **If any reviewer returns FAIL:**
   - Extract issues from report
   - Dispatch appropriate implementation agent with fix instructions
   - Re-run the selected review pool after fix
4. **Only proceed to Gate 9** when the selected review pool returns PASS

This ensures fixes are always reviewed before proceeding.
