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
   name: ring:your-skill-name
   description: Single paragraph (≤500 chars target, 1,536 cap). States WHAT the skill does, WHEN to invoke, and WHEN to skip.
   ---

   # Your Skill Name

   ## When to use
   - Specific condition that mandates this skill
   - Another trigger condition

   ## Skip when
   - When NOT to use → alternative skill
   - Another exclusion
   ```

   Required frontmatter fields: `name`, `description`. Optional: `argument-hint`, `allowed-tools`, `model`, `disable-model-invocation`, `user-invocable`, `paths`. Trigger/skip/sequence/related content lives in body H2 sections — see [docs/FRONTMATTER_SCHEMA.md](FRONTMATTER_SCHEMA.md) for the full schema.

3. Test with:

   ```
   Skill tool: "ring:testing-skills-with-subagents"
   ```

4. Skill auto-loads next SessionStart via `default/hooks/generate-skills-ref.py`

### Production Readiness Audit (ring-default)

The **production-readiness-audit** skill (`ring:production-readiness-audit`) evaluates codebase production readiness across **44 dimensions** (43 base + 1 conditional multi-tenant) in 5 categories. **Invocation:** use the Skill tool or the `/ring:production-readiness-audit` command when preparing for production, conducting security/quality reviews, or assessing technical debt. **Batch behavior:** runs 10 explorer agents per batch and appends results incrementally to a single report file (`docs/audits/production-readiness-{date}-{time}.md`) to avoid context bloat. **Output:** scored report (0–430 base, max 440 with multi-tenant) with severity ratings and standards cross-reference. Implementation details: [default/skills/production-readiness-audit/SKILL.md](../default/skills/production-readiness-audit/SKILL.md).

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

## Plugin-Specific Using-\* Skills

Each plugin auto-loads a `using-{plugin}` skill via SessionStart hook to introduce available agents and capabilities:

### Default Plugin

- `ring:using-ring` → ORCHESTRATOR principle, mandatory workflow
- Always injected, always mandatory
- Located: `default/skills/using-ring/SKILL.md`

### Ring Dev Team Plugin

- `ring:using-dev-team` → specialist developer agents
- Auto-loads when ring-dev-team plugin is enabled
- Located: `dev-team/skills/using-dev-team/SKILL.md`
- Agents (invoke as `ring:{agent-name}`):
  - ring:backend-engineer-golang
  - ring:backend-engineer-typescript
  - ring:frontend-bff-engineer-typescript
  - ring:frontend-designer
  - ring:frontend-engineer
  - ring:helm-engineer
  - ring:prompt-quality-reviewer
  - ring:ui-engineer

### Ring PM Team Plugin

- `ring:using-pm-team` → Pre-dev workflow skills (8 gates)
- Auto-loads when ring-pm-team plugin is enabled
- Located: `pm-team/skills/using-pm-team/SKILL.md`
- Skills: 8 pre-dev gates for feature planning

### Ring TW Team Plugin

- `using-tw-team` → 3 technical writing agents for documentation
- Auto-loads when ring-tw-team plugin is enabled
- Located: `tw-team/skills/using-tw-team/SKILL.md`
- Agents (invoke as `ring:{agent-name}`):
  - ring:functional-writer (guides)
  - ring:api-writer (API reference)
  - ring:docs-reviewer (quality review)
- Commands: review-docs

### Hook Configuration

- Each plugin has: `{plugin}/hooks/hooks.json` + `{plugin}/hooks/session-start.sh`
- SessionStart hook executes, outputs additionalContext with skill reference
- Only plugins in marketplace.json get loaded (conditional)

---

## Creating Review Agents

1. Add to `dev-team/agents/your-reviewer.md` with a documented `## Output Format` body section (see [AGENT_DESIGN.md](AGENT_DESIGN.md))

2. Reference in `default/skills/codereview/SKILL.md` under `Default Reviewers` or `Conditional Specialist Reviewers`

3. Dispatch via Task tool:

   ```
   subagent_type="ring:your-reviewer"
   ```

4. **MUST run in parallel** with other reviewers (single message, multiple Tasks)

---

## Pre-Dev Workflow

### Simple Features (<2 days): `/ring:pre-dev-feature`

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

### Complex Features (≥2 days): `/ring:pre-dev-full`

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

## Development Cycle (10-gate — cadence-classified)

`ring:dev-cycle` is now a lean backend flow. Backend implementation owns TDD, coverage, docker-compose/local runtime, basic health/observability checks, and delivery verification in Gate 0.

**Subtask cadence** (runs for each subtask, or for the task itself if no subtasks):
- Gate 0 — Implementation (includes Delivery Verification exit check inline)

**Task cadence** (runs once per task, after all subtasks complete Gate 0):
- Gate 8 — Review (9 default reviewers plus triggered specialists on cumulative task diff)
- Gate 9 — Validation (aggregates EVERY subtask's acceptance criteria + one human approval, after Gate 8 passes)

**Cycle cadence** (runs once per cycle at the end):
- Multi-Tenant Verify
- `ring:dev-report` aggregate
- Final Commit

Inputs for task-cadence gates receive UNION of changed files across all subtasks of the task. Multi-tenant adaptation is integrated into Gate 0. All gates are MANDATORY. Invoke with `/ring:dev-cycle [tasks-file]` or Skill tool `ring:dev-cycle`. State is persisted to `docs/ring:dev-cycle/current-cycle.json`. See `dev-team/skills/shared-patterns/gate-cadence-classification.md` for full taxonomy and [dev-team/skills/dev-cycle/SKILL.md](../dev-team/skills/dev-cycle/SKILL.md) for full protocol.

---

## Parallel Code Review

### Instead of sequential (180 min)

```python
review1  = Task("ring:code-reviewer")               # 20 min
review2  = Task("ring:business-logic-reviewer")     # 20 min
review3  = Task("ring:security-reviewer")           # 20 min
review4  = Task("ring:test-reviewer")               # 20 min
review5  = Task("ring:nil-safety-reviewer")         # 20 min
review6  = Task("ring:dead-code-reviewer")          # 20 min
review7  = Task("ring:performance-reviewer")        # 20 min
review8  = Task("ring:multi-tenant-reviewer")       # 20 min
review9  = Task("ring:lib-commons-reviewer")        # 20 min
```

### Run parallel (20 min total)

```python
Task.parallel([
    ("ring:code-reviewer", prompt),
    ("ring:business-logic-reviewer", prompt),
    ("ring:security-reviewer", prompt),
    ("ring:test-reviewer", prompt),
    ("ring:nil-safety-reviewer", prompt),
    ("ring:dead-code-reviewer", prompt),
    ("ring:performance-reviewer", prompt),
    ("ring:multi-tenant-reviewer", prompt),
    ("ring:lib-commons-reviewer", prompt)
])  # Single message, 9 default tool calls; add triggered specialists in same batch
```

### Key rule

Always dispatch all 9 default reviewers in a single message with multiple Task tool calls. Add `ring:lib-observability-reviewer`, `ring:lib-systemplane-reviewer`, or `ring:lib-streaming-reviewer` to that same batch only when their stack triggers match.

---

## Related Documents

- [CLAUDE.md](../CLAUDE.md) - Main project instructions (references this document)
- [AGENT_DESIGN.md](AGENT_DESIGN.md) - Agent output formats
- [PROMPT_ENGINEERING.md](PROMPT_ENGINEERING.md) - Language patterns

---

## Reviewer-Pool Synchronization

When adding or removing a code review agent in the `ring:codereview` pool:

**⛔ SEVEN-FILE REVIEWER-POOL SYNCHRONIZATION RULE:**

1. Edit `default/skills/codereview/SKILL.md` — default reviewer table, conditional trigger table, dynamic dispatch count, status semantics, output format Reviewer Verdicts table
2. Edit `default/skills/codereview/reviewers/dispatch-prompts.md` — add/remove default Task blocks or conditional Task blocks, renumber default tasks, and update eligibility rules
3. Edit reviewer agent files in `dev-team/agents/*-reviewer.md` — active code-review reviewers live only in the dev-team plugin
4. Edit `dev-team/hooks/validate-gate-progression.sh` — 9 default reviewer verdict requirements plus optional conditional verdict requirements
5. Edit `dev-team/skills/dev-cycle/SKILL.md` and `dev-team/skills/dev-cycle/gates/gate-8-review.md` — Gate 8 state shape and dynamic reviewer references
6. Edit shared patterns that enumerate reviewers — `default/skills/shared-patterns/reviewer-slicing-strategy.md`, `default/skills/shared-patterns/reviewer-orchestrator-boundary.md`, `dev-team/skills/shared-patterns/shared-anti-rationalization.md`, `dev-team/skills/shared-patterns/gate-cadence-classification.md`
7. Edit public/plugin docs — `CLAUDE.md`, `README.md`, `MANUAL.md`, `ARCHITECTURE.md`, `.claude-plugin/marketplace.json`, and installer messages

**All files in same commit** — MUST NOT update one without the others.

**Note:** `dev-team/skills/using-dev-team/SKILL.md` does NOT enumerate reviewers and does NOT contain backend Gate 8 or frontend Gate 7 tables. Do not invent such tables; that skill describes specialist developer agents, not the review pool. If you need a reviewer enumeration there in the future, add it explicitly — until then, skip it.

**⛔ ADDITIONAL SWEEP (secondary consumers, should also update same commit):**

- `default/skills/using-ring/SKILL.md` — entry-point skill reminder
- `default/skills/writing-plans/SKILL.md` — plan output format instructing plans to dispatch reviewers
- `ring-install.sh` — user-facing install advertisement (interactive menu + `--claude` / `--factory` / `--opencode` / `--codex` / `--all`)
- `docs/PROMPT_ENGINEERING.md` — canonical example of strong language
- `docs/WORKFLOWS.md` — workflow documentation
- `MANUAL.md`, `README.md`, `ARCHITECTURE.md` — public-facing docs
- `.claude-plugin/marketplace.json` — plugin descriptions + keywords
- Any dev-team skill that dispatches `ring:codereview` (e.g., `dev-multi-tenant`, `dev-systemplane-migration`)

**⛔ CHECKLIST: Adding/Removing a Reviewer**

```
Before committing changes to the codereview pool:

[ ] 1. Updated codereview/SKILL.md (dispatch + state + output format)?
[ ] 2. Updated frontmatter description in the new/removed reviewer agent (generic "Runs in parallel with other reviewers")?
[ ] 3. Updated validate-gate-progression.sh (9 default verdicts + optional conditional verdicts)?
[ ] 4. Updated dev-cycle/SKILL.md (Gate 8 + all "N reviewers" refs)?
[ ] 5. Updated shared-patterns files enumerating reviewers?
[ ] 6. Swept secondary consumers (using-ring, writing-plans, docs, marketplace.json)?
[ ] 7. Grep sanity: grep -rn "N reviewer|all N" --include="*.md" --include="*.sh" returns zero stale counts?

If any checkbox is no → Fix before committing.
```

**Why this rule exists:** In 2026-04-18 dogfood, we discovered that when `performance-reviewer` was added to the pool some time prior, 7+ files were never updated. Adding 2 more reviewers then cascaded into ~65 stale references across 22 files. This rule makes the propagation explicit.

---

## Documentation Sync Checklist

**When modifying agents, skills, or hooks, check all these files for consistency:**

```
Root Documentation:
├── CLAUDE.md              # Project instructions (source of truth)
├── MANUAL.md              # Team quick reference guide
├── README.md              # Public documentation
└── ARCHITECTURE.md        # Architecture diagrams

Reference Documentation:
├── docs/PROMPT_ENGINEERING.md  # Assertive language patterns
├── docs/AGENT_DESIGN.md        # Output formats, standards compliance
├── docs/FRONTMATTER_SCHEMA.md  # Canonical YAML frontmatter fields
└── docs/WORKFLOWS.md           # Detailed workflow instructions

Plugin Hooks (inject context at session start):
├── default/hooks/session-start.sh
├── dev-team/hooks/session-start.sh
├── pm-team/hooks/session-start.sh
└── tw-team/hooks/session-start.sh

Using-* Skills (plugin introductions):
├── default/skills/using-ring/SKILL.md
├── dev-team/skills/using-dev-team/SKILL.md
├── pm-team/skills/using-pm-team/SKILL.md
└── tw-team/skills/using-tw-team/SKILL.md
```

**Checklist when adding/modifying:**

- [ ] CLAUDE.md updated? → AGENTS.md auto-updates (symlink)
- [ ] AGENTS.md symlink broken? → Restore with `ln -sf CLAUDE.md AGENTS.md`
- [ ] Agent added? Update hooks, using-\* skills, MANUAL.md, README.md
- [ ] Skill added? Update CLAUDE.md architecture, hooks if plugin-specific
- [ ] Plugin added? Create hooks/, using-\* skill, update marketplace.json
- [ ] Names changed? Search repo: `grep -r "old-name" --include="*.md" --include="*.sh"`

**Naming Convention Enforcement:**

- [ ] All agent invocations use `ring:agent-name` format
- [ ] All skill invocations use `ring:skill-name` format
- [ ] No bare agent/skill names in invocation contexts (must have ring: prefix)
- [ ] No deprecated `ring-{plugin}:` format used

---

## Content Duplication Prevention

Before adding any content to prompts, skills, agents, or documentation:

1. **SEARCH FIRST**: `grep -r "keyword" --include="*.md"` — Check if content already exists
2. **If content exists** → **REFERENCE it**, DO NOT duplicate. Use: `See [file](path) for details`
3. **If adding new content** → Add to the canonical source per table below
4. **MUST NOT copy** content between files — link to the single source of truth

| Information Type      | Canonical Source                                         |
| --------------------- | -------------------------------------------------------- |
| Critical rules        | CLAUDE.md                                                |
| Language patterns     | docs/PROMPT_ENGINEERING.md                               |
| Agent schemas         | docs/AGENT_DESIGN.md                                     |
| Frontmatter fields    | docs/FRONTMATTER_SCHEMA.md                               |
| Workflows             | docs/WORKFLOWS.md                                        |
| Plugin overview       | README.md                                                |
| Agent requirements    | CLAUDE.md (Agent Modification section)                   |
| Shared skill patterns | `{plugin}/skills/shared-patterns/*.md`                   |
| Standards modules     | `dev-team/docs/standards/{stack}/{module}.md`            |

**Shared Patterns Rule (MANDATORY):**
When content is reused across multiple skills within a plugin:

1. **Extract to shared-patterns**: Create `{plugin}/skills/shared-patterns/{pattern-name}.md`
2. **Reference from skills**: Use `See [shared-patterns/{name}.md](../shared-patterns/{name}.md)`
3. **MUST NOT duplicate**: If the same table/section appears in 2+ skills → extract to shared-patterns

| Shared Pattern Type           | Location                                                      |
| ----------------------------- | ------------------------------------------------------------- |
| Pressure resistance scenarios | `{plugin}/skills/shared-patterns/pressure-resistance.md`      |
| Anti-rationalization tables   | `{plugin}/skills/shared-patterns/anti-rationalization.md`     |
| Execution report format       | `{plugin}/skills/shared-patterns/execution-report.md`         |
| Standards coverage table      | `{plugin}/skills/shared-patterns/standards-coverage-table.md` |
