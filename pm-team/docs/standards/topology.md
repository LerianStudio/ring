# Project Topology Standards

Standards for project structure discovery and multi-module coordination in Ring workflows.

---

## Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [Feature Scope](#1-feature-scope) | backend-only, frontend-only, fullstack |
| 2 | [Repository Structure](#2-repository-structure) | single-repo, monorepo, multi-repo |
| 3 | [TopologyConfig Schema](#3-topologyconfig-schema) | YAML schema for topology configuration |
| 4 | [Module Organization](#4-module-organization) | unified vs per-module docs |
| 5 | [Context Switching](#5-context-switching) | when to prompt for directory change |
| 6 | [Multi-Repo Coordination](#6-multi-repo-coordination) | handling separate repositories |
| 7 | [PROJECT_RULES.md Hierarchy](#7-project_rulesmd-hierarchy) | rule precedence in multi-module projects |
| 8 | [API Pattern](#8-api-pattern) | bff or none - determines agent assignment |
| 9 | [Documentation Placement](#9-documentation-placement) | Where docs are stored per structure |

---

## 1. Feature Scope

Feature scope determines how many working directories are needed and which agents to dispatch.

| Scope | Description | Working Directories | Agents |
|-------|-------------|---------------------|--------|
| `backend-only` | API, services, data layer only | Single | backend-go / backend-ts |
| `frontend-only` | UI, BFF routes only | Single | frontend / bff-ts |
| `fullstack` | Both backend and frontend | May require multiple | Both backend and frontend agents |

### When to Use Each Scope

| Scope | Examples |
|-------|----------|
| `backend-only` | REST API endpoint, database migration, background job |
| `frontend-only` | UI component, page layout, client-side validation |
| `fullstack` | User authentication, CRUD feature with UI, real-time updates |

---

## 2. Repository Structure

Repository structure affects how docs are organized and how tasks are distributed.

| Structure | When | Doc Location | Task Distribution |
|-----------|------|--------------|-------------------|
| `single-repo` | All code in one repo, same directory | Unified in `docs/pre-dev/{feature}/` | Single `plan.md` |
| `monorepo` | Multiple packages in one repo (e.g., `packages/*`) | Module-specific docs may live per module | Single `plan.md`; epics tagged with `**Target:**` |
| `multi-repo` | Separate repos for backend/frontend | Coordinator repo | Single `plan.md` copied into each repo; local dev-cycle executes only epics whose `**Target:**` matches |

### Structure Detection Hints

| Indicator | Likely Structure |
|-----------|------------------|
| Single `package.json` or `go.mod` at root | `single-repo` |
| `packages/`, `apps/`, `libs/` directories | `monorepo` |
| User specifies external path | `multi-repo` |

---

## 3. TopologyConfig Schema

TopologyConfig is persisted in the `research.md` frontmatter and propagated through all gates.

```yaml
topology:
  # Required
  scope: fullstack | backend-only | frontend-only
  structure: single-repo | monorepo | multi-repo

  # Required for monorepo and multi-repo
  modules:
    backend:
      path: string          # Relative path (monorepo) or absolute path (multi-repo)
      language: golang | typescript
    frontend:
      path: string          # Relative path (monorepo) or absolute path (multi-repo)
      framework: nextjs | react | vue | angular

  # Required for fullstack
  doc_organization: unified | per-module
```

### Example Configurations

**Single-repo (backend-only):**
```yaml
topology:
  scope: backend-only
  structure: single-repo
```

**Monorepo (fullstack):**
```yaml
topology:
  scope: fullstack
  structure: monorepo
  modules:
    backend:
      path: packages/api
      language: golang
    frontend:
      path: packages/web
      framework: nextjs
  doc_organization: unified
```

**Multi-repo (fullstack):**
```yaml
topology:
  scope: fullstack
  structure: multi-repo
  modules:
    backend:
      path: /home/user/projects/my-api
      language: typescript
    frontend:
      path: /home/user/projects/my-frontend
      framework: react
  doc_organization: per-module
```

---

## 4. Module Organization

`doc_organization` governs where module-specific supporting docs (ux-criteria.md, wireframes/, openapi.yaml, schema files) live. It does NOT split the plan: **plan.md is always a single document per feature**, at the feature's pre-dev directory in the primary repo.

### Unified Organization (Default)

All docs in the feature's pre-dev directory:

```
docs/pre-dev/{feature}/
├── research.md
├── prd.md
├── trd.md
└── plan.md           # Single plan; epics carry **Target:** tags on multi-module topologies
```

**Epic format (multi-module topologies):**
```markdown
### Epic 1.2: User API Endpoint

...epic details...

**Target:** backend
**Status:** Pending
```

The `**Target:** backend | frontend | infra` line is optional, placed right before `**Status:**`, and only used on monorepo fullstack / multi-repo topologies.

### Per-Module Organization

Module-specific supporting docs move to module directories; the plan does not split:

```
docs/pre-dev/{feature}/
├── research.md
├── prd.md
├── trd.md
└── plan.md           # Single plan — never split per module

{backend.path}/docs/pre-dev/{feature}/
├── openapi.yaml
└── schema.sql        # or schema.prisma

{frontend.path}/docs/pre-dev/{feature}/
├── ux-criteria.md
└── wireframes/
```

### When to Use Each

| Organization | When | Benefits |
|--------------|------|----------|
| `unified` | Small features, tight integration | Everything in one place |
| `per-module` | Large features, separate teams, multi-repo | Module docs live next to the code they describe |

---

## 5. Context Switching

### When Context Switch Occurs

| Scenario | Action |
|----------|--------|
| Epic `**Target:**` differs from current module | Prompt user for confirmation |
| First task of execution | Set initial module (no prompt) |
| Returning to previously visited module | No prompt (context cached) |
| Epic with no `**Target:**` line | Execute in primary repo root |

### Context Switch Prompt

```
AskUserQuestion:
  question: "Switching to {module} module at {path}. Continue?"
  header: "Context"
  options:
    - label: "Continue"
      description: "Switch to {module} and execute task"
    - label: "Skip task"
      description: "Skip this task and continue"
    - label: "Stop"
      description: "Stop execution"
```

### Optimizing Context Switches

To minimize context switches, execution skills SHOULD batch tasks by module:

```
Original order: [backend, frontend, backend, frontend]
Optimized order: [backend, backend, frontend, frontend]
```

**Note:** Only reorder if tasks have no dependencies between modules.

---

## 6. Multi-Repo Coordination

### Coordinator Repository

When `structure: multi-repo`, the repository where `/ring:planning-small-features` is run becomes the "coordinator":

- All pre-dev docs stay in coordinator
- Task files are generated with clear module markers
- Execution requires manual or scripted distribution

### Task Distribution

**Automatic Placement:** Documents are now automatically written to the correct repository based on `doc_placement: distributed`.

- Shared documents (research.md, prd.md, trd.md, plan.md) are written to both repos — plan.md is the SAME single document in each copy
- Backend documents (openapi.yaml, schema.sql/schema.prisma) go to backend repo
- Frontend documents (ux-criteria.md, wireframes/) go to frontend repo
- Each repo's local dev-cycle executes only epics whose `**Target:**` matches that repo

**See Section 9 (Documentation Placement)** for complete placement rules.

**Manual Sync (if needed):**
If automatic placement fails or repos are on different machines:

```bash
# Sync shared docs from backend to frontend
rsync -av {backend.path}/docs/pre-dev/{feature}/research.md {frontend.path}/docs/pre-dev/{feature}/
rsync -av {backend.path}/docs/pre-dev/{feature}/prd.md {frontend.path}/docs/pre-dev/{feature}/
rsync -av {backend.path}/docs/pre-dev/{feature}/trd.md {frontend.path}/docs/pre-dev/{feature}/
```

### Execution in Multi-Repo

When executing multi-repo tasks:
1. Skill reads task's `working_directory`
2. Prompts for context switch (includes full path)
3. Instructs agent to `cd` to target directory
4. Agent reads `PROJECT_RULES.md` from target if exists

---

## 7. PROJECT_RULES.md Hierarchy

### Precedence Rules

In multi-module projects, PROJECT_RULES.md files are merged with clear precedence:

| Level | Location | Precedence |
|-------|----------|------------|
| Root | `./PROJECT_RULES.md` | Lowest (base rules) |
| Module | `{module_path}/PROJECT_RULES.md` | Highest (overrides root) |

### Merge Behavior

```
Root PROJECT_RULES.md:
  - Use conventional commits
  - All code must have tests

Backend PROJECT_RULES.md:
  - Use Go 1.22+
  - Tests use testify

Result for backend tasks:
  - Use conventional commits (from root)
  - All code must have tests (from root)
  - Use Go 1.22+ (from module)
  - Tests use testify (from module)
```

### Conflict Resolution

When same rule exists in both:
- **Module rule wins** - more specific context
- Agent MUST note in output: "Using module-specific rule for X"

---

## 8. API Pattern

API Pattern determines how the frontend communicates with backend services and affects agent assignment. Canonical source: [topology-discovery.md](../../skills/shared-patterns/topology-discovery.md) — only two values exist.

### Pattern Options

| Pattern | Description | Use When |
|---------|-------------|----------|
| `bff` | Frontend calls a BFF layer (Next.js API Routes → backends) | Any dynamic data — MANDATORY, not a choice |
| `none` | No API layer | Static frontend with no backend calls |

`direct` is **FORBIDDEN** (API keys exposed in browser, CORS, no server-side validation/caching) and `other` was removed. Client-side code MUST NEVER call backend APIs, databases, or external services directly.

### Pattern Decision

Dynamic data? Yes → `bff` (mandatory). No → `none` (static frontend).

### Agent Assignment by Pattern

| API Pattern | Frontend Tasks | Agent |
|-------------|----------------|-------|
| `bff` | API routes, data aggregation | `ring:bff-ts` |
| `bff` | UI components, pages | `ring:frontend` |
| `none` | UI components, pages, forms | `ring:frontend` |

### Pattern in TopologyConfig

```yaml
topology:
  scope: fullstack
  structure: single-repo
  api_pattern: bff  # MANDATORY if dynamic data; "none" if static
```

### Defaults

| Scope | Default Pattern | Rationale |
|-------|-----------------|-----------|
| `fullstack` | `bff` | Fullstack implies dynamic data; BFF is mandatory for it |
| `frontend-only` | `bff` or `none` | Per Q5: dynamic data → bff, static → none |
| `backend-only` | N/A | No frontend to consider |

---

## 9. Documentation Placement

Documentation placement determines where pre-dev artifacts are written based on project structure.

### Placement Modes

| Mode | Structure | Description |
|------|-----------|-------------|
| `unified` | single-repo | All docs in `docs/pre-dev/{feature}/` |
| `per-module` | monorepo | Docs distributed to module directories |
| `distributed` | multi-repo | Docs written to each repository |

### Document Types and Placement

| Document | Type | single-repo | monorepo | multi-repo |
|----------|------|-------------|----------|------------|
| research.md | Shared | Root | Root | Both repos |
| prd.md | Shared | Root | Root | Both repos |
| feature-map.md | Shared | Root | Root | Both repos |
| trd.md | Shared | Root | Root | Both repos |
| ux-criteria.md | Frontend | Root | Frontend module | Frontend repo |
| wireframes/ | Frontend | Root | Frontend module | Frontend repo |
| openapi.yaml | Backend | Root | Backend module | Backend repo |
| schema.sql / schema.prisma | Backend | Root | Backend module | Backend repo |
| dependencies.md | Split | Root | Root + modules | Per repo |
| plan.md | Single | Root | Root | Copied to each repo (same document; Target-filtered execution) |

### Single-Repo (unified)

All documentation stays in the repository root:

```
docs/pre-dev/{feature}/
├── research.md
├── prd.md
├── feature-map.md
├── ux-criteria.md
├── wireframes/
├── trd.md
├── openapi.yaml
├── schema.sql         # or schema.prisma (stack-native)
├── dependencies.md
└── plan.md
```

### Monorepo (per-module)

Shared docs at root, module-specific docs in module directories:

```
# Root (shared)
docs/pre-dev/{feature}/
├── research.md
├── prd.md
├── trd.md
└── plan.md            # Single plan — epics carry **Target:** tags; never split per module

# Backend module
{backend.path}/docs/pre-dev/{feature}/
├── openapi.yaml
├── schema.sql         # or schema.prisma (stack-native)
└── dependencies.md    # Backend dependencies

# Frontend module
{frontend.path}/docs/pre-dev/{feature}/
├── ux-criteria.md
├── wireframes/
└── dependencies.md    # Frontend dependencies
```

### Multi-Repo (distributed)

Shared docs copied to both repos, module-specific docs in respective repos:

```
# Backend repository
{backend.path}/docs/pre-dev/{feature}/
├── research.md        # Copy of shared
├── prd.md             # Copy of shared
├── trd.md             # Copy of shared
├── openapi.yaml
├── schema.sql         # or schema.prisma (stack-native)
├── dependencies.md
└── plan.md            # Copy of the single plan — local dev-cycle executes only epics with **Target:** backend

# Frontend repository
{frontend.path}/docs/pre-dev/{feature}/
├── research.md        # Copy of shared
├── prd.md             # Copy of shared
├── trd.md             # Copy of shared
├── ux-criteria.md
├── wireframes/
├── dependencies.md
└── plan.md            # Copy of the single plan — local dev-cycle executes only epics with **Target:** frontend
```

### Implementation Notes

**For skills writing documents:**

1. Read `topology.structure` from research.md frontmatter
2. Use path resolution logic from `topology-discovery.md`
3. Create directories before writing
4. For multi-repo shared docs, write to both paths

**Backward Compatibility:**

- Single-repo behavior is unchanged
- Existing projects without `doc_placement` default to `unified`
- Skills MUST handle missing `topology` in frontmatter gracefully

---

## Checklist

When implementing topology support:

- [ ] TopologyConfig persisted in research.md frontmatter
- [ ] All gates read topology from frontmatter
- [ ] Epics carry `**Target:**` tags on multi-module topologies (right before `**Status:**`)
- [ ] Execution skills implement context switching
- [ ] Multi-repo copies the single plan.md into each repo (Target-filtered execution)
- [ ] PROJECT_RULES.md hierarchy respected
- [ ] api_pattern captured for fullstack features
