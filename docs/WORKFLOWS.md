# Ring Workflows Reference

This document contains detailed workflow instructions for adding skills, agents, hooks, and other Ring components.

---

## Adding a New Skill

### For Core Ring Skills

1. Create directory:
   ```bash
   mkdir default/skills/your-skill-name/
   ```

2. Write `default/skills/your-skill-name/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: your-skill-name
   description: |
     Brief description of WHAT the skill does (method/technique).

   trigger: |
     - Specific condition that mandates this skill
     - Another trigger condition

   skip_when: |
     - When NOT to use → alternative skill
     - Another exclusion

   sequence:
     after: [prerequisite-skill]   # Optional: ordering
     before: [following-skill]

   related:
     similar: [differentiate-from]      # Optional: disambiguation
     complementary: [pairs-well-with]
   ---
   ```

3. Test with:
   ```
   Skill tool: "testing-skills-with-subagents"
   ```

4. Skill auto-loads next SessionStart via `default/hooks/generate-skills-ref.py`

### For Product/Team-Specific Skills

1. Create plugin directory:
   ```bash
   mkdir -p product-xyz/{skills,agents,commands,hooks}
   ```

2. Add to `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "ring-product-xyz",
     "description": "Product XYZ specific skills",
     "version": "0.1.0",
     "source": "./product-xyz"
   }
   ```

3. Follow same skill structure as default plugin

---

## Modifying Hooks

1. Edit `default/hooks/hooks.json` for trigger configuration

2. Scripts in `default/hooks/`:
   - `session-start.sh` - Runs on startup
   - `claude-md-bootstrap.sh` - CLAUDE.md context

3. Test hook output:
   ```bash
   bash default/hooks/session-start.sh
   ```
   Must output JSON with `additionalContext` field

4. SessionStart hooks run on:
   - `startup|resume`
   - `clear|compact`

5. Note: `${CLAUDE_PLUGIN_ROOT}` resolves to plugin root (`default/` for core plugin)

---

## Plugin-Specific Using-* Skills

Each plugin auto-loads a `using-{plugin}` skill via SessionStart hook to introduce available agents and capabilities:

### Default Plugin
- `using-ring` → ORCHESTRATOR principle, mandatory workflow
- Always injected, always mandatory
- Located: `default/skills/using-ring/SKILL.md`

### Ring Dev Team Plugin
- `using-dev-team` → 7 specialist developer agents
- Auto-loads when ring-dev-team plugin is enabled
- Located: `dev-team/skills/using-dev-team/SKILL.md`
- Agents (invoke as `{agent-name}`):
  - backend-engineer-golang
  - backend-engineer-typescript
  - devops-engineer
  - frontend-bff-engineer-typescript
  - frontend-designer
  - qa-analyst
  - sre

### Ring FinOps Team Plugin
- `using-finops-team` → 2 FinOps agents for Brazilian compliance
- Auto-loads when ring-finops-team plugin is enabled
- Located: `finops-team/skills/using-finops-team/SKILL.md`
- Agents (invoke as `{agent-name}`):
  - finops-analyzer (compliance analysis)
  - finops-automation (template generation)

### Ring PM Team Plugin
- `using-pm-team` → Pre-dev workflow skills (8 gates)
- Auto-loads when ring-pm-team plugin is enabled
- Located: `pm-team/skills/using-pm-team/SKILL.md`
- Skills: 8 pre-dev gates for feature planning

### Ring TW Team Plugin
- `using-tw-team` → 3 technical writing agents for documentation
- Auto-loads when ring-tw-team plugin is enabled
- Located: `tw-team/skills/using-tw-team/SKILL.md`
- Agents (invoke as `{agent-name}`):
  - functional-writer (guides)
  - api-writer (API reference)
  - docs-reviewer (quality review)
- Commands: write-guide, write-api, review-docs

### Hook Configuration
- Each plugin has: `{plugin}/hooks/hooks.json` + `{plugin}/hooks/session-start.sh`
- SessionStart hook executes, outputs additionalContext with skill reference
- Only plugins in marketplace.json get loaded (conditional)

---

## Creating Review Agents

1. Add to `default/agents/your-reviewer.md` with output_schema (see [AGENT_DESIGN.md](AGENT_DESIGN.md))

2. Reference in `default/skills/requesting-code-review/SKILL.md:85`

3. Dispatch via Task tool:
   ```
   subagent_type="your-reviewer"
   ```

4. **MUST run in parallel** with other reviewers (single message, multiple Tasks)

---

## Pre-Dev Workflow

### Simple Features (<2 days): `/pre-dev-feature`

```
├── Gate 0: pm-team/skills/pre-dev-research
│   └── Output: docs/pre-dev/feature/research.md (parallel agents)
├── Gate 1: pm-team/skills/pre-dev-prd-creation
│   └── Output: docs/pre-dev/feature/PRD.md
├── Gate 2: pm-team/skills/pre-dev-trd-creation
│   └── Output: docs/pre-dev/feature/TRD.md
└── Gate 3: pm-team/skills/pre-dev-task-breakdown
    └── Output: docs/pre-dev/feature/tasks.md
```

### Complex Features (≥2 days): `/pre-dev-full`

```
├── Gate 0: Research Phase
│   └── 3 parallel agents: repo-research, best-practices, framework-docs
├── Gates 1-3: Same as simple workflow
├── Gate 4: pm-team/skills/pre-dev-api-design
│   └── Output: docs/pre-dev/feature/API.md
├── Gate 5: pm-team/skills/pre-dev-data-model
│   └── Output: docs/pre-dev/feature/data-model.md
├── Gate 6: pm-team/skills/pre-dev-dependency-map
│   └── Output: docs/pre-dev/feature/dependencies.md
├── Gate 7: pm-team/skills/pre-dev-task-breakdown
│   └── Output: docs/pre-dev/feature/tasks.md
└── Gate 8: pm-team/skills/pre-dev-subtask-creation
    └── Output: docs/pre-dev/feature/subtasks.md
```

---

## Parallel Code Review

### Instead of sequential (60 min)

```python
review1 = Task("code-reviewer")           # 20 min
review2 = Task("business-logic-reviewer") # 20 min
review3 = Task("security-reviewer")       # 20 min
```

### Run parallel (20 min total)

```python
Task.parallel([
    ("code-reviewer", prompt),
    ("business-logic-reviewer", prompt),
    ("security-reviewer", prompt)
])  # Single message, 3 tool calls
```

### Key rule

Always dispatch all 3 reviewers in a single message with multiple Task tool calls.

---

## Related Documents

- [CLAUDE.md](../CLAUDE.md) - Main project instructions (references this document)
- [AGENT_DESIGN.md](AGENT_DESIGN.md) - Agent output schemas
- [PROMPT_ENGINEERING.md](PROMPT_ENGINEERING.md) - Language patterns
