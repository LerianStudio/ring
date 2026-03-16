---
name: pre-dev-feature
description: |
  Lightweight 5-gate pre-dev workflow for small features (<2 days).
  Orchestrates topology discovery, research, PRD with UX validation,
  design validation, TRD, task breakdown, and delivery planning
  in a sequential gated process with human approval at each gate.
allowed-tools: Skill, Read, Write, Glob, Grep, Bash, Agent, AskUserQuestion
metadata:
  related:
    complementary:
    - ring:pre-dev-full
    - ring:write-plan
    - ring:worktree
    skills_orchestrated:
    - ring:pre-dev-research
    - ring:pre-dev-prd-creation
    - ring:pre-dev-design-validation
    - ring:pre-dev-trd-creation
    - ring:pre-dev-task-breakdown
    - ring:pre-dev-delivery-planning
  sequence:
    before:
    - ring:write-plan
    - ring:dev-cycle
  skip_when: |
    - Feature is complex (>=2 days) - use ring:pre-dev-full instead
    - Adds new dependencies, data models, or architecture patterns
  trigger: |
    - Feature takes <2 days to implement
    - Uses existing architecture patterns
    - Doesn't add new external dependencies
    - Doesn't create new data models/entities
    - Doesn't require multi-service integration
    - Can be completed by a single developer
  user_invocable: false
---

# Small Track Pre-Dev Workflow (5 Gates)

I'm running the **Small Track** pre-development workflow (5 gates) for your feature.

**This track is for features that:**
- Take <2 days to implement
- Use existing architecture patterns
- Don't add new external dependencies
- Don't create new data models/entities
- Don't require multi-service integration
- Can be completed by a single developer

**If any of the above are false, use `/ring:pre-dev-full` instead.**

## Document Organization

All artifacts will be saved to: `docs/pre-dev/<feature-name>/`

**First, let me ask you about your feature:**

Use the AskUserQuestion tool to gather:

**Question 1:** "What is the name of your feature?"
- Header: "Feature Name"
- This will be used for the directory name
- Use kebab-case (e.g., "user-logout", "email-validation", "payment-webhooks")

---

## Topology Discovery (MANDATORY)

MUST execute the topology discovery process as defined in [shared-patterns/topology-discovery.md](../shared-patterns/topology-discovery.md).

This step discovers the project structure (fullstack/backend-only/frontend-only), repository organization (single-repo/monorepo/multi-repo), module paths, and UI configuration. The complete algorithm with all 11 questions and auto-detection logic is in the shared pattern.

Store the result as `TopologyConfig` for use in all subsequent gates.

**After topology discovery, also gather the following feature-specific inputs:**

---

**Question 2 (CONDITIONAL):** "Does this feature require authentication or authorization?"
- **Auto-detection:** Before asking, check if `go.mod` contains `github.com/LerianStudio/lib-auth`
  - If **found** → Skip this question. Auth is already integrated at project level.
  - If **not found** → Ask this question (new project or project without auth)
- Header: "Auth Requirements"
- Options:
  - "None" - No authentication needed
  - "User authentication only" - Users must log in but no permission checks
  - "User + permissions" - Full user auth with role-based access control
  - "Service-to-service auth" - Machine-to-machine authentication only
  - "Full (user + service-to-service)" - Both user and service auth
- **Note:** For Go services requiring auth, reference `golang.md` → Access Manager Integration section during TRD creation (Gate 2)

**Question 3 (CONDITIONAL):** "Is this a licensed product/plugin?"
- **Auto-detection:** Before asking, check if `go.mod` contains `github.com/LerianStudio/lib-license-go`
  - If **found** → Skip this question. Licensing is already integrated at project level.
  - If **not found** → Ask this question (new project or project without licensing)
- Header: "License Requirements"
- Options:
  - "No" - Not a licensed product (open source, internal tool, etc.)
  - "Yes" - Licensed product that requires License Manager integration
- **Note:** For Go services requiring license validation, reference `golang.md` → License Manager Integration section during TRD creation (Gate 2)

**Why auto-detection?** Access Manager and License Manager are project-level infrastructure decisions, not feature-level. Once integrated, all features in the project inherit them.

**Question 4 (MANDATORY):** "Does this feature include user interface (UI)?"
- Header: "Has UI?"
- Options:
  - "Yes" - Feature includes pages, screens, forms, dashboards, or any visual interface
  - "No" - Backend-only feature (API, service, CLI, etc.)
- **IMPORTANT:** This question MUST always be asked. Do NOT assume based on feature description keywords.
- **Why mandatory?** Keyword detection is unreliable. Explicitly asking prevents skipping UI configuration.

**Question 5 (MANDATORY if Q4=Yes):** "Which UI component library should be used?"
- **Trigger:** Only ask if Q4 = "Yes"
- **Auto-detection:** Before asking, check `package.json` for existing UI libraries:
  - `@radix-ui/*` packages → shadcn/ui detected
  - `@chakra-ui/*` packages → Chakra UI detected
  - `@headlessui/*` packages → Headless UI detected
  - `@mui/*` or `@material-ui/*` → Material UI detected
  - If **library found** → Still ask, but pre-select detected option and display: "Detected: [library] from package.json"
  - If **not found** → Ask without pre-selection
- Header: "UI Library"
- Options:
  - "shadcn/ui + Radix (Recommended)" - TailwindCSS-based, highly customizable, copy-paste components
  - "Chakra UI" - Full component library with built-in theming system
  - "Headless UI" - Minimal unstyled primitives, Tailwind-native
  - "Material UI" - Google's Material Design components
  - "Ant Design" - Enterprise-grade React components
  - "Custom components only" - Build from scratch, no external UI library
- **Usage:** This choice informs wireframes (component names), TRD (dependencies), and implementation tasks
- **CANNOT be skipped:** Even with auto-detection, user must confirm the choice

**Question 6 (MANDATORY if Q4=Yes):** "Which styling approach should be used?"
- **Trigger:** Only ask if Q4 = "Yes"
- **Auto-detection:** Before asking, check `package.json` for existing styling:
  - `tailwindcss` → TailwindCSS detected
  - `styled-components` → Styled Components detected
  - `@emotion/*` → Emotion detected
  - `sass` or `node-sass` → Sass/SCSS detected
  - If **styling found** → Still ask, but pre-select detected option and display: "Detected: [styling] from package.json"
  - If **not found** → Ask without pre-selection
- Header: "Styling"
- Options:
  - "TailwindCSS (Recommended)" - Utility-first CSS, excellent for design systems
  - "CSS Modules" - Scoped CSS files, traditional approach
  - "Styled Components" - CSS-in-JS with tagged template literals
  - "Sass/SCSS" - CSS preprocessor with variables and nesting
  - "Vanilla CSS" - Plain CSS without preprocessors
- **Usage:** This choice informs wireframes (class naming), component implementation, and code review criteria
- **CANNOT be skipped:** Even with auto-detection, user must confirm the choice

**Question 7 (MANDATORY if Q4=Yes AND new project):** "What is the target accessibility level?"
- **Trigger:** Only ask if Q4 = "Yes" AND (no existing `package.json` OR no existing a11y config)
- **Auto-detection:** Check for existing accessibility configuration:
  - `@axe-core/*` in package.json → Skip, note "Detected: accessibility testing configured"
  - `pa11y` in package.json → Skip, note "Detected: accessibility testing configured"
  - `.lighthouserc.*` file exists → Skip, note "Detected: Lighthouse CI configured"
  - If **config found** → Skip question, use detected level
  - If **not found** → Ask question
- Header: "Accessibility"
- Options:
  - "WCAG 2.1 AA (Recommended)" - Standard compliance, 4.5:1 contrast for normal text, 3:1 for large text
  - "WCAG 2.1 AAA" - Enhanced compliance, 7:1 contrast for normal text, 4.5:1 for large text
  - "Basic" - Semantic HTML only, no strict contrast requirements
- **Usage:** Informs contrast validation in design-system.md, component requirements, code review criteria
- **Why this matters:** Accessibility requirements affect color choices, component design, and testing requirements

**Question 8 (MANDATORY if Q4=Yes AND new project):** "Does the application need dark mode support?"
- **Trigger:** Only ask if Q4 = "Yes" AND (no existing `package.json` OR no dark mode detected)
- **Auto-detection:** Check for existing dark mode:
  - `dark:` classes in existing components → Skip, note "Detected: dark mode classes in use"
  - CSS variables with `.dark` class in globals.css → Skip, note "Detected: dark mode CSS variables"
  - Theme provider (next-themes, etc.) in layout → Skip, note "Detected: theme provider configured"
  - If **dark mode found** → Skip question, note existing configuration
  - If **not found** → Ask question
- Header: "Dark Mode"
- Options:
  - "Light + Dark (Recommended)" - Full theme support with system preference detection
  - "Light only" - Single light theme, no dark mode
  - "Dark only" - Single dark theme (for specific apps like developer tools)
- **Usage:** Informs design-system.md color tokens, CSS architecture, component variants
- **Why this matters:** Dark mode requires dual color palettes and affects contrast calculations

**Question 9 (MANDATORY if Q4=Yes AND new project):** "What is the primary brand color?"
- **Trigger:** Only ask if Q4 = "Yes" AND (no existing `package.json` OR no brand colors detected)
- **Auto-detection:** Check for existing brand colors:
  - `tailwind.config.*` with custom `primary` color → Skip, note "Detected: primary color in Tailwind config"
  - CSS variable `--primary` or `--color-primary` in globals.css → Skip, note "Detected: primary color CSS variable"
  - If **brand color found** → Skip question, note existing configuration
  - If **not found** → Ask question
- Header: "Brand Color"
- Options:
  - "Blue" - Professional, trustworthy (finance, enterprise, healthcare)
  - "Purple" - Creative, innovative (tech startups, design tools)
  - "Green" - Growth, sustainability (fintech, eco, wellness)
  - "Orange" - Energy, action (marketplaces, social, food)
  - "Custom (specify hex)" - Custom brand color (user provides hex code)
- **Usage:** Informs design-system.md primary palette, derived colors, semantic mappings
- **Why this matters:** Brand color defines the primary visual identity and derived color palette

**Question 10 (MANDATORY if Q4=Yes AND new project):** "What typography style fits the brand?"
- **Trigger:** Only ask if Q4 = "Yes" AND (no existing `package.json` OR no custom fonts detected)
- **Auto-detection:** Check for existing typography:
  - Font imports in `layout.tsx` or `_app.tsx` → Skip, note "Detected: [font] configured"
  - `@fontsource/*` packages in package.json → Skip, note "Detected: [font] in dependencies"
  - Google Fonts in `next/font/google` imports → Skip, note "Detected: [font] from Google Fonts"
  - If **fonts found** → Skip question, note existing configuration
  - If **not found** → Ask question
- Header: "Typography"
- Options:
  - "Modern Tech (Geist) - Recommended" - Clean, technical feel, excellent for SaaS/developer tools
  - "Contemporary (Satoshi)" - Friendly, approachable, good for consumer apps
  - "Editorial (Cabinet Grotesk)" - Bold, statement-making, good for marketing/media
  - "Professional (General Sans)" - Neutral, enterprise-grade, good for B2B
- **Usage:** Informs design-system.md typography scale, font loading strategy, component styles
- **Why this matters:** Typography affects readability, brand perception, and page load performance
- **Note:** Avoid generic fonts (Inter, Roboto, Arial) per frontend standards

**UI Configuration Summary:** After Q4-Q11 (where Q11 comes from topology discovery's dynamic data question), display:
```
UI Configuration:
- Has UI: Yes/No
- UI Library: [choice] (confirmed by user)
- Styling: [choice] (confirmed by user)
- Accessibility: [WCAG AA | WCAG AAA | Basic] (for new projects)
- Dark Mode: [Light + Dark | Light only | Dark only] (for new projects)
- Brand Color: [Blue | Purple | Green | Orange | #hex] (for new projects)
- Typography: [Geist | Satoshi | Cabinet Grotesk | General Sans] (for new projects)
- API Pattern: [bff | none] (bff if dynamic data, none if static)
```

**GATE BLOCKER:** If Q4 = "Yes" but Q5 or Q6 were not answered, DO NOT proceed to Gate 0. Return and ask the missing questions. For new projects with UI, Q7-Q10 are also required.

This configuration is passed to all subsequent gates and used by:
- **Gate 0 (Research):** product-designer searches for patterns in the chosen library
- **Gate 1 (PRD/UX):** wireframes use component names from the library
- **Gate 2 (TRD):** dependencies section lists the UI library and styling framework
- **Gate 3 (Tasks):** implementation tasks reference specific components

After getting the feature name (and auth/license/UI requirements if applicable), create the directory structure and run the 5-gate workflow:

```bash
mkdir -p docs/pre-dev/<feature-name>
```

## Gate 0: Research Phase (Lightweight)

**Skill:** ring:pre-dev-research

Even small features benefit from quick research:

1. Determine research mode (usually **modification** for small features)
2. Dispatch 4 research agents in PARALLEL (quick mode):
   - ring:repo-research-analyst (codebase patterns)
   - ring:best-practices-researcher (external best practices)
   - ring:framework-docs-researcher (tech stack docs)
   - ring:product-designer (UX research, mode: ux-research)
3. Save to: `docs/pre-dev/<feature-name>/research.md`
4. Get human approval before proceeding

**Gate 0 Pass Criteria (Small Track):**
- [ ] Research mode determined
- [ ] Existing patterns identified (if any)
- [ ] No conflicting implementations found
- [ ] Product/UX research documented

**Note:** For very simple changes, Gate 0 can be abbreviated - focus on checking for existing patterns.

## Gate 1: PRD Creation + UX Validation

**Skill:** ring:pre-dev-prd-creation

1. Ask user to describe the feature (what problem does it solve, who are the users, what's the business value)
2. Create PRD document with:
   - Problem statement
   - User stories
   - Acceptance criteria
   - Success metrics
   - Out of scope
3. Save to: `docs/pre-dev/<feature-name>/prd.md`
4. Run Gate 1 validation checklist
5. Dispatch product-designer for UX validation (mode: ux-validation)
6. Save to: `docs/pre-dev/<feature-name>/ux-criteria.md`
7. **If feature has UI:** product-designer also creates wireframes
8. Save to: `docs/pre-dev/<feature-name>/wireframes/`
9. Get human approval before proceeding

**Gate 1 Pass Criteria:**
- [ ] Problem is clearly defined
- [ ] User value is measurable
- [ ] Acceptance criteria are testable
- [ ] Scope is explicitly bounded
- [ ] UX criteria defined (ux-criteria.md created)
- [ ] Wireframes created (if feature has UI)
- [ ] User flows documented (if feature has UI)

## Gate 1.5: Design Validation (if feature has UI)

**Skill:** ring:pre-dev-design-validation

**Purpose:** Verify UX specifications are complete before investing in technical architecture.

### HARD GATE: This Gate CANNOT Be Skipped for UI Features

**If Q4 = "Yes" (feature has UI), this gate is MANDATORY. No exceptions.**

1. **Skip condition:** ONLY if feature has NO UI (Q4 = "No", backend-only)
2. Load and validate all design artifacts:
   - ux-criteria.md
   - wireframes/*.yaml
   - wireframes/user-flows.md
3. Run systematic validation checklist:
   - Section 1: Wireframe Completeness (CRITICAL)
   - Section 2: UI States Coverage (CRITICAL)
   - Section 3: Accessibility Specifications
   - Section 4: Responsive Specifications
   - Section 5: User Flow Completeness
   - Section 6: Content Specifications
4. Save report to: `docs/pre-dev/<feature-name>/design-validation.md`
5. Evaluate verdict:
   - **DESIGN VALIDATED:** Proceed to Gate 2
   - **CRITICAL GAPS:** STOP. Return to Gate 1 to fix gaps. CANNOT proceed.
   - **MINOR GAPS:** Ask user - proceed with documented risk or fix first?
6. Get human approval before proceeding

**Gate 1.5 Pass Criteria:**
- [ ] All wireframes have ASCII prototypes
- [ ] All screens define loading/error/empty/success states
- [ ] Accessibility criteria specified in ux-criteria.md
- [ ] Responsive behavior documented
- [ ] User flows cover happy path AND error paths
- [ ] Button labels and error messages are specific (not generic)

### BLOCKER: Gate 2 (TRD) Will REFUSE to Start Without This

**Gate 2 (TRD) checks for design-validation.md before proceeding.**
- If feature has UI AND design-validation.md is missing → TRD will STOP
- If design-validation.md exists but verdict is not VALIDATED → TRD will STOP

**Why this gate exists:** Incomplete design specs cause 10x implementation rework. Validating now saves time later.

### Anti-Rationalization

| Excuse | Reality |
|--------|---------|
| "We're behind schedule, skip validation" | Skipping causes 10x rework. You'll be MORE behind. |
| "Design looks complete to me" | "Looks complete" ≠ validated. Run systematic check. |
| "We can validate later" | TRD depends on complete design. Cannot proceed without. |
| "Just this once" | No exceptions. Every UI feature needs validation. |

## Gate 2: TRD Creation (Skipping Feature Map)

**Skill:** ring:pre-dev-trd-creation

1. Load PRD from `docs/pre-dev/<feature-name>/prd.md`
2. Note: No Feature Map exists (small track) - map PRD features directly to components
3. Create TRD document with:
   - Architecture style (pattern names, not products)
   - Component design (technology-agnostic)
   - Data architecture (conceptual)
   - Integration patterns
   - Security architecture
   - **NO specific tech products** (use "Relational Database" not "PostgreSQL")
4. Save to: `docs/pre-dev/<feature-name>/trd.md`
5. Run Gate 2 validation checklist
6. Get human approval before proceeding

**Gate 2 Pass Criteria:**
- [ ] All PRD features mapped to components
- [ ] Component boundaries are clear
- [ ] Interfaces are technology-agnostic
- [ ] No specific products named

## Gate 3: Task Breakdown (Skipping API/Data/Deps)

**Skill:** ring:pre-dev-task-breakdown

1. Load PRD from `docs/pre-dev/<feature-name>/prd.md`
2. Load TRD from `docs/pre-dev/<feature-name>/trd.md`
3. Note: No Feature Map, API Design, Data Model, or Dependency Map exist (small track)
4. Run AI-assisted time estimation:
   - Auto-detect tech stack from repository files (go.mod, package.json, pyproject.toml, etc.)
   - Note: Small Track has no Dependency Map, so inspect repo directly
   - Dispatch specialized agent based on detected stack:
     - Go (go.mod detected) → ring:backend-engineer-golang
     - TypeScript/Node (package.json + backend) → ring:backend-engineer-typescript
     - React/Next.js (package.json + frontend) → ring:frontend-engineer
     - Mixed/Unknown → ring:codebase-explorer
   - Agent analyzes scope and estimates AI-agent-hours per task
   - Output includes: AI estimate (hours), confidence level (High/Medium/Low), detailed breakdown
5. Create task breakdown document with:
   - Value-driven decomposition
   - Each task delivers working software
   - AI-agent-hours estimates (not story points)
   - Maximum task size: 16 AI-agent-hours
   - Dependencies mapped
   - Testing strategy per task
6. Save to: `docs/pre-dev/<feature-name>/tasks.md`
7. Run Gate 3 validation checklist
8. Get human approval

**Gate 3 Pass Criteria:**
- [ ] Every task delivers user value
- [ ] No task larger than 16 AI-agent-hours
- [ ] All tasks have AI estimates with confidence levels
- [ ] Dependencies are clear
- [ ] Testing approach defined

## Gate 4: Delivery Planning (MANDATORY)

**Skill:** ring:pre-dev-delivery-planning

1. Load tasks from `docs/pre-dev/<feature-name>/tasks.md` (with AI-agent-hours estimates)
2. Ask user for delivery inputs:
   - Start date (when team begins work)
   - Team composition (how many developers)
   - Delivery cadence (sprint/cycle/continuous)
   - Period configuration (if sprint/cycle: duration + start date)
   - Human validation multiplier (1.2x-2.5x, default 1.5x or custom)
3. Apply AI-based time calculation:
   - Formula: `(ai_estimate x multiplier / 0.90) / 8 / team_size = calendar_days`
   - Capacity: 90% available capacity (10% overhead for API limits, context loading, tool execution)
   - Note: 0.90 in formula = available capacity factor, not overhead percentage
   - Multiplier represents human validation overhead
4. Analyze dependencies and critical path
5. Calculate realistic timeline with period boundaries
6. Identify parallelization opportunities and resource allocation
7. Create delivery roadmap with Gantt-style timeline
8. Save to: `docs/pre-dev/<feature-name>/delivery-roadmap.md` + `delivery-roadmap.json`
9. Run Gate 4 validation checklist
10. Get human approval

**Gate 4 Pass Criteria:**
- [ ] All tasks scheduled with realistic dates
- [ ] Critical path identified and validated
- [ ] Team capacity: 90% (AI Agent standard)
- [ ] Period boundaries respected (if sprint/cycle)
- [ ] Spill overs identified and documented
- [ ] Parallel streams defined
- [ ] Risk milestones flagged
- [ ] Contingency buffer added (10-20%)
- [ ] Formula used: (ai_estimate x multiplier / 0.90) / 8 / team_size = calendar_days

## After Completion

Report to human:

```
Small Track (5 gates) complete for <feature-name>

Artifacts created (paths depend on topology.structure):

**For single-repo:**
- docs/pre-dev/<feature-name>/research.md
- docs/pre-dev/<feature-name>/prd.md
- docs/pre-dev/<feature-name>/ux-criteria.md
- docs/pre-dev/<feature-name>/wireframes/
- docs/pre-dev/<feature-name>/design-validation.md (if UI)
- docs/pre-dev/<feature-name>/trd.md
- docs/pre-dev/<feature-name>/tasks.md
- docs/pre-dev/<feature-name>/delivery-roadmap.md
- docs/pre-dev/<feature-name>/delivery-roadmap.json

**For monorepo:**
- docs/pre-dev/<feature-name>/research.md (root - shared)
- docs/pre-dev/<feature-name>/prd.md (root - shared)
- docs/pre-dev/<feature-name>/trd.md (root - shared)
- docs/pre-dev/<feature-name>/tasks.md (root - index)
- docs/pre-dev/<feature-name>/delivery-roadmap.md (root - shared)
- docs/pre-dev/<feature-name>/delivery-roadmap.json (root - shared)
- {frontend.path}/docs/pre-dev/<feature-name>/ux-criteria.md
- {frontend.path}/docs/pre-dev/<feature-name>/wireframes/
- {frontend.path}/docs/pre-dev/<feature-name>/design-validation.md (if UI)
- {frontend.path}/docs/pre-dev/<feature-name>/tasks.md (filtered)
- {backend.path}/docs/pre-dev/<feature-name>/tasks.md (filtered)

**For multi-repo:**
- Both repos: research.md, prd.md, trd.md (synchronized), delivery-roadmap.md, delivery-roadmap.json
- Frontend repo: ux-criteria.md, wireframes/, design-validation.md, tasks.md
- Backend repo: tasks.md

Skipped from full workflow:
- Feature Map (features simple enough to map directly)
- API Design (no new APIs - standards discovery not applicable)
- Data Model (no new data structures - standards discovery not applicable)
- Dependency Map (no new dependencies)
- Subtask Creation (tasks small enough already)

Next steps:
1. Review artifacts in docs/pre-dev/<feature-name>/
2. Use delivery-roadmap.md to communicate timelines to stakeholders
3. Use /ring:worktree to create isolated workspace
4. Use /ring:write-plan to create implementation plan
5. Execute the plan
```

## Remember

- This is the **Small Track** - lightweight and fast (5 gates)
- **Gate 0 (Research) checks for existing patterns** even for small features
- **Gate 1.5 (Design Validation) ensures UI specs are complete** before technical work
- **Gate 4 (Delivery Planning) is MANDATORY** - creates realistic roadmap with timeline
- If feature grows during planning, switch to `/ring:pre-dev-full`
- All documents saved to `docs/pre-dev/<feature-name>/`
- Get human approval at each gate
- Technology decisions happen later in Dependency Map (not in this track)
- Delivery roadmap (WHEN/WHO) complements write-plan (HOW)

---

## MANDATORY: Skills Orchestration

**This skill orchestrates multiple sub-skills in a 5-gate workflow.**

### Gate Sequence

| Gate | Skill | Purpose | New Outputs |
|------|-------|---------|-------------|
| 0 | `ring:pre-dev-research` | Domain, technical, and UX research (4 agents) | research.md (includes Product/UX Research) |
| 1 | `ring:pre-dev-prd-creation` | Product requirements + UX validation + wireframes | prd.md, ux-criteria.md, wireframes/ (if UI) |
| 1.5 | `ring:pre-dev-design-validation` | Verify UX specs complete (if UI) | design-validation.md |
| 2 | `ring:pre-dev-trd-creation` | Technical requirements | trd.md |
| 3 | `ring:pre-dev-task-breakdown` | Task decomposition | tasks.md |
| 4 | `ring:pre-dev-delivery-planning` | Delivery roadmap | delivery-roadmap.md, .json |

### Execution Pattern

```
For each gate:
  Use Skill tool: [gate-skill]
  Wait for human approval
  Proceed to next gate
```

Each skill contains its own:
- Anti-rationalization tables
- Gate pass criteria
- Output format requirements

**Do NOT skip gates.** Each gate builds on the previous gate's output.
