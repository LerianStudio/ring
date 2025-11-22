# CLAUDE.md Auto-Bootstrap Design

**Date:** 2025-11-22
**Status:** Approved
**Owner:** Ring Plugin Team

## Overview

Automatically generate CLAUDE.md files for git repositories that lack them. This bootstraps repository documentation by analyzing codebase architecture through sequential and parallel Explore agents, synthesizing findings into a concise, actionable CLAUDE.md file.

**Goal:** Seamless onboarding - users open a repo without CLAUDE.md, and within 30-60 seconds have comprehensive documentation automatically injected into their session.

**Constraints:**
- Maximum 500 lines (token-conscious for context re-injection)
- Automatic execution on SessionStart (no user intervention)
- Internal tooling (optimized for company use, opinionated)

## Architecture

### 1. Hook Architecture

**New hook:** `hooks/claude-md-bootstrap.sh`

**Execution flow:**
```
SessionStart (startup|resume)
  ↓
claude-md-bootstrap.sh
  ↓
Is this a git repo? (.git/ exists)
  ↓ YES
Does CLAUDE.md exist? (${CLAUDE_PROJECT_DIR}/CLAUDE.md)
  ↓ NO
Run bootstrap process:
  1. Dispatch Explore agent (Sonnet, very thorough) → identify layers
  2. Parse layer findings
  3. Dispatch parallel Explore agents (Haiku) → one per layer
  4. Aggregate findings
  5. Dispatch synthesis agent (Sonnet) → generate CLAUDE.md
  6. Validate output (≤500 lines, format check)
  7. Write to ${CLAUDE_PROJECT_DIR}/CLAUDE.md
  ↓
session-start.sh (loads generated CLAUDE.md)
  ↓
Session begins with full context
```

**Integration with hooks.json:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/claude-md-bootstrap.sh"
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

**Key decisions:**
- Bootstrap runs **before** session-start (generated CLAUDE.md loads immediately)
- Only triggers on `startup|resume` (not `clear|compact`)
- Checks git repo first (fast fail for non-applicable contexts)
- Idempotent (never overwrites existing CLAUDE.md)

### 2. Exploration Strategy

**Phase 1: Layer Discovery (Sequential)**

Dispatch single **Explore agent (Sonnet, very thorough)**:

```bash
Task(
  subagent_type="Explore",
  model="sonnet",
  description="Discover architectural layers",
  prompt="""
  Analyze this codebase's layered architecture:

  1. Identify ALL architectural layers (e.g., API, business logic, data, UI, infrastructure)
  2. For each layer, provide:
     - Layer name
     - Primary directories/files
     - Key responsibilities
     - Technologies used
  3. Identify cross-cutting concerns (auth, logging, config, testing)

  Format response as structured data for parsing.
  Be exhaustive - include every distinct layer you find.
  """
)
```

**Output example:**
```
Layers identified:
- API Layer: src/api/, src/routes/ (Express.js REST endpoints)
- Business Logic: src/services/, src/domain/ (Core business rules)
- Data Layer: src/repositories/, src/models/ (PostgreSQL + Prisma ORM)
- Frontend: src/components/, src/pages/ (React + TypeScript)
- Infrastructure: docker/, k8s/ (Container orchestration)

Cross-cutting:
- Authentication: src/middleware/auth.ts
- Logging: src/utils/logger.ts
- Configuration: config/
```

**Phase 2: Layer Deep-Dive (Parallel)**

Parse Phase 1 output → dispatch **parallel Explore agents (Haiku)** for **ALL layers**:

```bash
# For each layer discovered:
Task(
  subagent_type="Explore",
  model="haiku",  # Fast, cost-effective
  description=f"Explore {layer.name}",
  prompt=f"""
  Deep-dive into the {layer.name} of this codebase:

  Focus on: {layer.directories}

  Provide:
  1. Key components and their roles
  2. Important patterns/conventions
  3. Common workflows
  4. Notable files (with exact paths)
  5. Dependencies and integrations

  Be concise but complete (max 150 words).
  """
)
```

**Key decisions:**
- Initial discovery uses **Sonnet** (thorough, comprehensive layer identification)
- Parallel layer agents use **Haiku** (fast, cost-effective, focused analysis)
- Audit **ALL layers** found (no artificial limits)
- Cap each layer at ~150 words (scales with layer count, enforced by 500-line final cap)

**Model selection rationale:**
- **Sonnet for discovery:** Needs thoroughness to identify all architectural layers
- **Haiku for parallel exploration:** Focused scope (single layer), speed matters, cost scales linearly with layer count
- **Sonnet for synthesis:** Quality critical for final output

### 3. Content Aggregation & Synthesis

**Aggregation:**

```python
# Pseudo-code for data collection
aggregated_data = {
  "repo_overview": layer_discovery_output.overview,
  "tech_stack": layer_discovery_output.technologies,
  "layers": [],
  "cross_cutting": layer_discovery_output.cross_cutting
}

for layer_agent_output in parallel_results:
  aggregated_data["layers"].append({
    "name": layer_agent_output.layer_name,
    "directories": layer_agent_output.directories,
    "summary": layer_agent_output.summary,
    "key_files": layer_agent_output.notable_files,
    "patterns": layer_agent_output.patterns
  })
```

**Synthesis (Final Sonnet Agent):**

```bash
Task(
  subagent_type="general-purpose",
  model="sonnet",
  description="Generate CLAUDE.md from findings",
  prompt=f"""
  You are generating a CLAUDE.md file for this repository.

  INPUT DATA:
  - Repository overview: {repo_overview}
  - Tech stack: {tech_stack}
  - Architectural layers: {layers}
  - Cross-cutting concerns: {cross_cutting}

  CONSTRAINTS:
  - Maximum 500 lines (HARD LIMIT)
  - Token-conscious (this file gets re-injected every prompt)
  - Actionable and practical (not generic)

  REQUIRED SECTIONS:
  1. Repository Overview (2-3 sentences max)
  2. Architecture (layer-by-layer breakdown)
  3. Common Commands (git, build, test, deploy)
  4. Key Workflows (how developers work in this repo)
  5. Important Patterns (conventions, anti-patterns)

  STYLE:
  - Concise bullet points
  - Use exact file paths (e.g., src/api/routes.ts:45)
  - Focus on "how to work in this repo" not "what this repo does"
  - Prioritize information Claude needs to write good code here

  Follow the template structure below:

  {template_content}

  Generate the complete CLAUDE.md content now.
  """
)
```

**Key decisions:**
- Synthesis uses **Sonnet** (quality over speed for final output)
- Prompt explicitly enforces 500-line constraint
- Focus on actionability (how-to) over description (what-is)
- Requires exact paths (no generic placeholders)

### 4. CLAUDE.md Template Structure

**Enforced template for synthesis agent:**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

[2-3 sentence summary: What this repo does, primary technologies, architectural style]

## Architecture

### Core Components

[For each layer discovered, create subsection with format:]

**[Layer Name]** (`primary/directories/`)
- [Key responsibility in 1 line]
- [Notable files: path/to/file.ext - what it does]
- [Important patterns/conventions]
- [Dependencies/integrations]

### Cross-Cutting Concerns

[Auth, logging, config, testing - where they live and how they work]

## Common Commands

### [Category 1: e.g., Development]
```bash
# [Command purpose]
[actual command]

# [Another command purpose]
[actual command]
```

### [Category 2: e.g., Testing]
[Same format as above]

### [Category 3: e.g., Deployment]
[Same format as above]

## Key Workflows

### [Workflow 1: e.g., Adding a New Feature]
1. [Step with specific paths/commands]
2. [Step with specific paths/commands]
3. [Step with specific paths/commands]

### [Workflow 2: e.g., Running Tests]
[Same format as above]

## Important Patterns

### [Pattern Category 1: e.g., Code Organization]
- [Pattern 1]
- [Pattern 2]

### [Pattern Category 2: e.g., Naming Conventions]
- [Convention 1]
- [Convention 2]

### Anti-Patterns to Avoid
- [Anti-pattern 1 with explanation]
- [Anti-pattern 2 with explanation]

## [Optional Section: Testing Strategy / Deployment / etc.]

[Only include if critical to working in this repo]
```

**Template enforcement rules:**

1. **Exact paths required** - No generic `src/` without specifics
2. **Commands must be runnable** - No `npm run <command>`, use actual command names
3. **Workflows must reference real files** - e.g., "Edit `config/database.yml:23`"
4. **Line budget per section (guidelines):**
   - Repository Overview: ~5 lines
   - Architecture: ~250 lines (scales with layer count)
   - Common Commands: ~75 lines
   - Key Workflows: ~100 lines
   - Important Patterns: ~50 lines
   - Optional sections: ~20 lines

**Total: ≤500 lines (hard constraint enforced post-generation)**

### 5. Error Handling & Edge Cases

**Failure scenarios and recovery:**

| Scenario | Detection | Response |
|----------|-----------|----------|
| **Not a git repo** | Check `.git/` exists | Skip bootstrap silently (return empty hook output) |
| **CLAUDE.md already exists** | Check file existence | Skip bootstrap silently (idempotent) |
| **Layer discovery agent fails** | Task tool returns error | Write minimal fallback CLAUDE.md with error note |
| **Layer agent timeout** | Task timeout (>120s) | Continue with partial results, note missing layers in output |
| **Layer agent returns empty** | Parse returns no layers | Use single-layer fallback (treat repo as monolithic) |
| **Synthesis agent fails** | Task tool returns error | Write template-only CLAUDE.md with placeholder sections |
| **Generated CLAUDE.md >500 lines** | Count lines after generation | Truncate at 500 lines with "... (truncated)" note at end |
| **File write permission denied** | Write fails with EPERM | Log error to stderr, skip file creation, continue session normally |

**Fallback CLAUDE.md template (used on error):**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Repository Overview

[Auto-generated CLAUDE.md - bootstrap process encountered errors]

## Architecture

[Analysis incomplete - delete this file to trigger regeneration on next session]

## Common Commands

```bash
# Check git status
git status

# View recent commits
git log --oneline -10
```

## Notes

This CLAUDE.md was auto-generated but the analysis process failed.
You can:
- Edit this file manually with repository-specific guidance
- Delete this file to trigger regeneration on next session start
- Check hook logs for error details
```

**User-visible feedback (hook output):**

Success:
```
✓ Generated CLAUDE.md (analyzed 8 layers across 450 lines)
```

Partial success:
```
⚠ Generated CLAUDE.md (2 of 8 layers timed out - see file for details)
```

Failure:
```
✗ Failed to generate CLAUDE.md - created minimal template at ./CLAUDE.md
```

**Graceful degradation philosophy:**
- Even on complete failure, users get *something* (minimal template) they can edit
- Silent failures for non-applicable contexts (non-git repos)
- Partial results preferred over no results (some layers better than none)
- Clear user feedback about generation status

## Implementation Components

### Files to Create/Modify

**New files:**
1. `hooks/claude-md-bootstrap.sh` - Main bootstrap orchestration script
2. `hooks/README-claude-md-bootstrap.md` - Documentation for the feature

**Modified files:**
1. `hooks/hooks.json` - Add claude-md-bootstrap to SessionStart hooks (before session-start.sh)

### Data Flow

```
SessionStart trigger
  ↓
claude-md-bootstrap.sh
  ├─ Check .git/ exists → No: exit silently
  ├─ Check CLAUDE.md exists → Yes: exit silently
  └─ Run bootstrap:
      │
      ├─ Phase 1: Layer Discovery (Sonnet, ~15-20s)
      │   └─ Parse output → Extract layers
      │
      ├─ Phase 2: Parallel Layer Exploration (Haiku, ~20-30s)
      │   ├─ Dispatch N agents (one per layer)
      │   └─ Aggregate results
      │
      ├─ Phase 3: Synthesis (Sonnet, ~10-15s)
      │   ├─ Generate CLAUDE.md content
      │   └─ Validate (≤500 lines)
      │
      └─ Write CLAUDE.md to disk
  ↓
session-start.sh (loads CLAUDE.md via claude-md-reminder)
  ↓
User session begins with full context
```

**Total time budget:** ~45-65 seconds (acceptable for automatic execution)

## Success Criteria

**Quality metrics:**
1. Generated CLAUDE.md contains exact file paths (not generic)
2. Commands are runnable (tested with bash -n check)
3. Workflows reference real files discovered during exploration
4. ≤500 lines (enforced constraint)

**Performance metrics:**
1. Bootstrap completes in <90 seconds (90th percentile)
2. Median completion time: 45-60 seconds
3. Success rate: >90% (fallback template for remaining cases)

**User experience:**
1. Seamless - runs automatically without user intervention
2. Fast - doesn't significantly delay session start
3. Actionable - generated docs immediately useful for Claude
4. Safe - never overwrites existing CLAUDE.md

## Future Enhancements

**Potential improvements (out of scope for MVP):**

1. **Incremental updates:** Detect when CLAUDE.md is outdated (compare git history), offer regeneration
2. **Template library:** Pre-built templates for common stack patterns (React app, Go microservice, etc.)
3. **User customization:** Config file for controlling section priorities, line budgets
4. **Quality validation:** Post-generation quality checks (path existence, command validity)
5. **Manual trigger:** `/ring:regenerate-claude-md` command for on-demand regeneration

## Appendix: Example Generated CLAUDE.md

**Input:** Hypothetical Express.js + React + PostgreSQL monorepo

**Output (abridged):**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Repository Overview

Full-stack web application using Express.js backend, React frontend, and PostgreSQL database. Monorepo structure with shared TypeScript types between frontend and backend.

## Architecture

### Core Components

**API Layer** (`backend/src/api/`)
- REST endpoints handling HTTP requests
- Notable files:
  - `backend/src/api/routes.ts` - Route definitions
  - `backend/src/api/controllers/` - Request handlers
- Pattern: Controller → Service → Repository
- Integrations: Express.js, JWT auth middleware

**Business Logic** (`backend/src/services/`)
- Core business rules and domain logic
- Notable files:
  - `backend/src/services/user.service.ts` - User management
  - `backend/src/services/auth.service.ts` - Authentication
- Pattern: Service classes with dependency injection
- Integrations: Repositories, external APIs

**Data Layer** (`backend/src/repositories/`)
- Database access and ORM interactions
- Notable files:
  - `backend/src/repositories/base.repository.ts` - Base repository pattern
  - `backend/src/db/migrations/` - Database schema migrations
- Technologies: Prisma ORM, PostgreSQL
- Pattern: Repository pattern with Prisma client

**Frontend** (`frontend/src/`)
- React single-page application
- Notable files:
  - `frontend/src/App.tsx` - Root component
  - `frontend/src/pages/` - Page components
  - `frontend/src/components/` - Reusable UI components
- Technologies: React 18, TypeScript, React Router
- Pattern: Functional components with hooks

### Cross-Cutting Concerns

- **Authentication:** `backend/src/middleware/auth.ts` - JWT verification middleware
- **Logging:** `backend/src/utils/logger.ts` - Winston-based structured logging
- **Configuration:** `backend/config/` - Environment-based config (dev, staging, prod)
- **Testing:** `**/*.test.ts` - Jest unit tests, `e2e/` - Cypress E2E tests

## Common Commands

### Development
```bash
# Install dependencies
npm install

# Start backend dev server
npm run dev:backend

# Start frontend dev server
npm run dev:frontend

# Run both concurrently
npm run dev
```

### Testing
```bash
# Run all tests
npm test

# Run backend tests
npm run test:backend

# Run frontend tests
npm run test:frontend

# E2E tests
npm run test:e2e
```

### Database
```bash
# Run migrations
npm run db:migrate

# Seed database
npm run db:seed

# Reset database (drop + migrate + seed)
npm run db:reset
```

## Key Workflows

### Adding a New API Endpoint
1. Define route in `backend/src/api/routes.ts`
2. Create controller in `backend/src/api/controllers/`
3. Implement service in `backend/src/services/`
4. Add repository method in `backend/src/repositories/` (if DB access needed)
5. Write tests in `backend/src/api/__tests__/`
6. Update API docs in `docs/api.md`

### Adding a New React Component
1. Create component file in `frontend/src/components/` or `frontend/src/pages/`
2. Add TypeScript types/interfaces
3. Implement component with hooks
4. Write tests in co-located `*.test.tsx` file
5. Export from `frontend/src/components/index.ts` if reusable

## Important Patterns

### Code Organization
- Monorepo structure: `backend/`, `frontend/`, `shared/`
- Collocated tests: Tests live next to implementation files
- Barrel exports: Use `index.ts` files for clean imports

### Naming Conventions
- Files: kebab-case (`user-service.ts`)
- Classes: PascalCase (`UserService`)
- Functions: camelCase (`getUserById`)
- Constants: SCREAMING_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`)

### Anti-Patterns to Avoid
- Never commit `.env` files (use `.env.example` as template)
- Don't bypass auth middleware in routes (always protect endpoints)
- Avoid direct database queries in controllers (use repositories)
- Don't skip migrations (always create migration for schema changes)
```

---

**End of Design Document**
