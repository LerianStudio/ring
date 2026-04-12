# Anti-Rationalization: Orchestrator Direct Editing

**Applies to:** Skills and workflows that orchestrate code changes (e.g., ring:codereview Gate 4, ring:dev-cycle)

**CRITICAL PRINCIPLE: Orchestrators DISPATCH agents to fix issues. Orchestrators do NOT edit source files directly.**

---

## Why Orchestrators CANNOT Edit Source Files

1. **Role Separation**: Orchestrators coordinate workflow; agents implement changes
2. **Specialization**: Implementation agents have standards knowledge, test runners, IDE context
3. **Audit Trail**: Clear separation of who coordinated vs who implemented
4. **Quality Gates**: Agent changes go through review; orchestrator bypasses would skip this

---

## Anti-Rationalization Table

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "It's a one-line fix" | Size is irrelevant. Orchestrators don't edit code. | **Dispatch agent** |
| "I already know how to fix it" | Knowing ≠ permission. Orchestrators orchestrate. | **Dispatch agent** |
| "Agent dispatch takes too long" | Consistency > speed. Always dispatch. | **Dispatch agent** |
| "Just adding a TODO comment" | TODO comments are code changes. Agents write code. | **Dispatch agent** |
| "The reviewer told me exactly what to change" | Instructions are for the agent, not you. | **Dispatch agent** |
| "I'll fix it faster myself" | Fast + wrong > slow + right. Dispatch agent. | **Dispatch agent** |
| "It's just a small fix" | Size is irrelevant. Orchestrators don't edit code. | **Dispatch agent** |
| "I can add TODO comments quickly" | Orchestrators don't write to source files. Period. | **Dispatch agent** |
| "Agent dispatch is overkill for this" | Consistency > convenience. Always dispatch. | **Dispatch agent** |
| "CodeRabbit already told me what to fix" | Knowing the fix ≠ permission to implement. | **Dispatch agent** |

---

## HARD GATE Check

Before ANY Edit/Write/Create operation on source files:

```text
STOP. Ask yourself:
1. Am I an orchestrator (skill/workflow coordinator)? → YES
2. Is this a source code file? → Check extension (.go, .ts, .tsx, .py, etc.)
3. If YES to both → DISPATCH AGENT. Do NOT edit directly.

If you catch yourself about to use Edit/Write/Create on source files → STOP. Dispatch agent.
```

---

## How to Reference This Pattern

In orchestrating skills (e.g., ring:codereview, ring:dev-cycle), add:

```markdown
### Orchestrator Boundaries (HARD GATE)

**See [shared-patterns/orchestrator-direct-editing-anti-rationalization.md](../shared-patterns/orchestrator-direct-editing-anti-rationalization.md) for anti-rationalization table.**

**Key prohibition:** Edit/Write/Create on source files is FORBIDDEN. Always dispatch agent.

**If you catch yourself about to use Edit/Write/Create on source files → STOP. Dispatch agent.**
```
