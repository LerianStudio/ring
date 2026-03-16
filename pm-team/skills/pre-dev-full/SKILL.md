---
name: pre-dev-full
description: |
  Complete 10-gate pre-dev workflow for large features (>=2 days).
  Orchestrates topology discovery, research, PRD, feature map, design validation,
  TRD, API design, data model, dependency map, task breakdown, subtask creation,
  and delivery planning in a sequential gated process with human approval at each gate.
allowed-tools: Skill, Read, Write, Glob, Grep, Bash, Agent, AskUserQuestion
metadata:
  related:
    complementary:
    - ring:pre-dev-feature
    - ring:write-plan
    - ring:worktree
    skills_orchestrated:
    - ring:pre-dev-research
    - ring:pre-dev-prd-creation
    - ring:pre-dev-feature-map
    - ring:pre-dev-design-validation
    - ring:pre-dev-trd-creation
    - ring:pre-dev-api-design
    - ring:pre-dev-data-model
    - ring:pre-dev-dependency-map
    - ring:pre-dev-task-breakdown
    - ring:pre-dev-subtask-creation
    - ring:pre-dev-delivery-planning
  sequence:
    before:
    - ring:write-plan
    - ring:dev-cycle
  skip_when: |
    - Feature is simple (<2 days, existing patterns) - use ring:pre-dev-feature instead
    - No new dependencies, data models, or architecture patterns needed
  trigger: |
    - Feature takes >=2 days to implement
    - Adds new external dependencies (APIs, databases, libraries)
    - Creates new data models or entities
    - Requires multi-service integration
    - Uses new architecture patterns
    - Requires team collaboration
  user_invocable: false
---

# Full Track Pre-Dev Workflow (10 Gates)

I'm running the **Full Track** pre-development workflow (10 gates) for your feature.

**This track is for features that have ANY of:**
- Take >=2 days to implement
- Add new external dependencies (APIs, databases, libraries)
- Create new data models or entities
- Require multi-service integration
- Use new architecture patterns
- Require team collaboration

**If feature is simple (<2 days, existing patterns), use `/ring:pre-dev-feature` instead.**

## Document Organization

All artifacts will be saved to: `docs/pre-dev/<feature-name>/`

**First, let me ask you about your feature:**

Use the AskUserQuestion tool to gather:

**Question 1:** "What is the name of your feature?"
- Header: "Feature Name"
- This will be used for the directory name
- Use kebab-case (e.g., "auth-system", "payment-processing", "file-upload")

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
- **Note:** For Go services requiring auth, reference `golang.md` → Access Manager Integration section during TRD creation (Gate 3) and Dependency Map (Gate 6)

**Question 3 (CONDITIONAL):** "Is this a licensed product/plugin?"
- **Auto-detection:** Before asking, check if `go.mod` contains `github.com/LerianStudio/lib-license-go`
  - If **found** → Skip this question. Licensing is already integrated at project level.
  - If **not found** → Ask this question (new project or project without licensing)
- Header: "License Requirements"
- Options:
  - "No" - Not a licensed product (open source, internal tool, etc.)
  - "Yes" - Licensed product that requires License Manager integration
- **Note:** For Go services requiring license validation, reference `golang.md` → License Manager Integration section during TRD creation (Gate 3) and Dependency Map (Gate 6)

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

**GATE BLOCKER:** If Q4 = "Yes" but Q5 or Q6 were not answered, DO NOT proceed to Gate 0. Return and ask the missing questions. For new projects with UI, Q7-Q10 are also required. If scope = "Fullstack" or "Frontend-only" with UI, the dynamic data question (from topology discovery) must be answered.

This configuration is passed to all subsequent gates and used by:
- **Gate 0 (Research):** product-designer searches for patterns in the chosen library
- **Gate 1 (PRD/UX):** criteria reference available components
- **Gate 2 (Feature Map/UX Design):** wireframes use component names from the library
- **Gate 3 (TRD):** architecture considers UI library constraints
- **Gate 6 (Dependency Map):** lists UI library and styling framework as dependencies
- **Gate 7 (Tasks):** implementation tasks reference specific components

After getting the feature name (and auth/license/UI requirements if applicable), create the directory structure and run the 10-gate workflow:

```bash
mkdir -p docs/pre-dev/<feature-name>
```

## Gate 0: Research Phase

**Skill:** ring:pre-dev-research

1. Determine research mode by asking user or inferring from context:
   - **greenfield**: New capability, no existing patterns
   - **modification**: Extending existing functionality
   - **integration**: Connecting external systems

2. Dispatch 4 research agents in PARALLEL:
   - ring:repo-research-analyst (codebase patterns, file:line refs)
   - ring:best-practices-researcher (web search, Context7)
   - ring:framework-docs-researcher (tech stack, versions)
   - ring:product-designer (UX research, user problem validation, mode: ux-research)

3. Aggregate findings into research document
4. Save to: `docs/pre-dev/<feature-name>/research.md`
5. Run Gate 0 validation checklist
6. Get human approval before proceeding

**Gate 0 Pass Criteria:**
- [ ] Research mode determined and documented
- [ ] All 4 agents dispatched and returned
- [ ] At least one file:line reference (if modification mode)
- [ ] At least one external URL (if greenfield mode)
- [ ] docs/solutions/ knowledge base searched
- [ ] Tech stack versions documented
- [ ] Product/UX research documented

## Gate 1: PRD Creation + UX Validation

**Skill:** ring:pre-dev-prd-creation

1. Ask user to describe the feature (problem, users, business value)
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
7. Get human approval before proceeding

**Gate 1 Pass Criteria:**
- [ ] Problem is clearly defined
- [ ] User value is measurable
- [ ] Acceptance criteria are testable
- [ ] Scope is explicitly bounded
- [ ] UX criteria defined (ux-criteria.md created)

## Gate 2: Feature Map Creation + UX Design

**Skill:** ring:pre-dev-feature-map

1. Load PRD from `docs/pre-dev/<feature-name>/prd.md`
2. Load ux-criteria.md from `docs/pre-dev/<feature-name>/ux-criteria.md`
3. Create feature map document with:
   - Feature relationships and dependencies
   - Domain boundaries
   - Integration points
   - Scope visualization
4. Save to: `docs/pre-dev/<feature-name>/feature-map.md`
5. Run Gate 2 validation checklist
6. Dispatch product-designer for UX design (mode: ux-design)
7. Save to: `docs/pre-dev/<feature-name>/user-flows.md`
8. Save to: `docs/pre-dev/<feature-name>/wireframes/` (directory with YAML specs)
9. Get human approval before proceeding

**Gate 2 Pass Criteria:**
- [ ] All features from PRD mapped
- [ ] Relationships are clear
- [ ] Domain boundaries defined
- [ ] Feature interactions documented
- [ ] User flows documented (user-flows.md created)
- [ ] Wireframe specs created (wireframes/ directory)

## Gate 2.5: Design Validation (if feature has UI)

**Skill:** ring:pre-dev-design-validation

**Purpose:** Verify UX specifications are complete before investing in technical architecture.

### HARD GATE: This Gate CANNOT Be Skipped for UI Features

**If Q4 = "Yes" (feature has UI), this gate is MANDATORY. No exceptions.**

1. **Skip condition:** ONLY if feature has NO UI (Q4 = "No", backend-only)
2. Load and validate all design artifacts:
   - ux-criteria.md
   - wireframes/*.yaml
   - wireframes/user-flows.md (or user-flows.md)
3. Run systematic validation checklist:
   - Section 1: Wireframe Completeness (CRITICAL)
   - Section 2: UI States Coverage (CRITICAL)
   - Section 3: Accessibility Specifications
   - Section 4: Responsive Specifications
   - Section 5: User Flow Completeness
   - Section 6: Content Specifications
4. Save report to: `docs/pre-dev/<feature-name>/design-validation.md`
5. Evaluate verdict:
   - **DESIGN VALIDATED:** Proceed to Gate 3
   - **CRITICAL GAPS:** STOP. Return to Gate 2 to fix gaps. CANNOT proceed.
   - **MINOR GAPS:** Ask user - proceed with documented risk or fix first?
6. Get human approval before proceeding

**Gate 2.5 Pass Criteria:**
- [ ] All wireframes have ASCII prototypes
- [ ] All screens define loading/error/empty/success states
- [ ] Accessibility criteria specified in ux-criteria.md
- [ ] Responsive behavior documented
- [ ] User flows cover happy path AND error paths
- [ ] Button labels and error messages are specific (not generic)

### BLOCKER: Gate 3 (TRD) Will REFUSE to Start Without This

**Gate 3 (TRD) checks for design-validation.md before proceeding.**
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

## Gate 3: TRD Creation

**Skill:** ring:pre-dev-trd-creation

1. Load PRD from `docs/pre-dev/<feature-name>/prd.md`
2. Load Feature Map from `docs/pre-dev/<feature-name>/feature-map.md`
3. Map Feature Map domains to architectural components
4. Create TRD document with:
   - Architecture style (pattern names, not products)
   - Component design (technology-agnostic)
   - Data architecture (conceptual)
   - Integration patterns
   - Security architecture
   - **NO specific tech products**
5. Save to: `docs/pre-dev/<feature-name>/trd.md`
6. Run Gate 3 validation checklist
7. Get human approval before proceeding

**Gate 3 Pass Criteria:**
- [ ] All Feature Map domains mapped to components
- [ ] All PRD features mapped to components
- [ ] Component boundaries are clear
- [ ] Interfaces are technology-agnostic
- [ ] No specific products named

## Gate 4: API Design

**Skill:** ring:pre-dev-api-design

1. **Phase 0:** Ask user for API naming standards (URL/file/none)
2. If provided: Load and extract to `api-standards-ref.md`
3. Load previous artifacts (PRD, Feature Map, TRD)
4. Create API design document with:
   - Component contracts and interfaces
   - Request/response formats (using standards if available)
   - Error handling patterns
   - Integration specifications
5. Save to: `docs/pre-dev/<feature-name>/api-design.md`
6. Run Gate 4 validation checklist
7. Get human approval before proceeding

**Gate 4 Pass Criteria:**
- [ ] Standards discovery completed (asked user)
- [ ] All component interfaces defined
- [ ] Contracts are clear and complete
- [ ] Error cases covered
- [ ] Protocol-agnostic (no REST/gRPC specifics yet)
- [ ] Field naming follows standards (if provided) or best practices

## Gate 5: Data Model

**Skill:** ring:pre-dev-data-model

1. **Phase 0:** Determine database field naming strategy
   - Check if Gate 4 API standards exist
   - Ask user: Convert to snake_case? Keep camelCase? Load separate DB dictionary? Define manually?
   - Generate `db-standards-ref.md` with automatic conversion and mapping if applicable
2. Load previous artifacts (API Design, TRD, Feature Map, PRD)
3. Create data model document with:
   - Entity relationships and schemas (using field naming strategy from Phase 0)
   - Data ownership boundaries
   - Access patterns
   - Migration strategy
   - API-to-DB field mapping (automatically generated if conversion applied)
4. Save to: `docs/pre-dev/<feature-name>/data-model.md`
5. Run Gate 5 validation checklist
6. Get human approval before proceeding

**Gate 5 Pass Criteria:**
- [ ] Field naming strategy determined (asked user)
- [ ] All entities defined with relationships
- [ ] Data ownership is clear
- [ ] Access patterns documented
- [ ] Database-agnostic (no PostgreSQL/MongoDB specifics yet)
- [ ] Schema naming follows chosen strategy
- [ ] API-to-DB mapping documented (if API standards exist)

## Gate 6: Dependency Map

**Skill:** ring:pre-dev-dependency-map

1. Load previous artifacts
2. Create dependency map document with:
   - **NOW we select specific technologies**
   - Concrete versions and packages
   - Rationale for each choice
   - Alternative evaluations
3. Save to: `docs/pre-dev/<feature-name>/dependency-map.md`
4. Run Gate 6 validation checklist
5. Get human approval before proceeding

**Gate 6 Pass Criteria:**
- [ ] All technologies selected with rationale
- [ ] Versions pinned (no "latest")
- [ ] Alternatives evaluated
- [ ] Tech stack is complete

## Gate 7: Task Breakdown

**Skill:** ring:pre-dev-task-breakdown

1. Load all previous artifacts (PRD, Feature Map, TRD, API Design, Data Model, Dependency Map)
2. Run AI-assisted time estimation:
   - Auto-detect tech stack from Dependency Map (if available) OR repository files (go.mod, package.json, etc.)
   - Dispatch specialized agent based on detected stack:
     - Go (go.mod detected) → ring:backend-engineer-golang
     - TypeScript/Node (package.json + backend) → ring:backend-engineer-typescript
     - React/Next.js (package.json + frontend) → ring:frontend-engineer
     - Mixed/Unknown → ring:codebase-explorer
   - Agent analyzes scope and estimates AI-agent-hours per task
   - Output includes: AI estimate (hours), confidence level (High/Medium/Low), detailed breakdown
   - **AI-agent-hours definition:** Time for AI agent to implement via ring:dev-cycle (includes TDD, automated review, SRE validation, DevOps setup)
3. Create task breakdown document with:
   - Value-driven decomposition
   - Each task delivers working software
   - AI-agent-hours estimates (not story points)
   - Maximum task size: 16 AI-agent-hours
   - Dependencies mapped
   - Testing strategy per task
4. Save to: `docs/pre-dev/<feature-name>/tasks.md`
5. Run Gate 7 validation checklist
6. Get human approval before proceeding

**Gate 7 Pass Criteria:**
- [ ] Every task delivers user value
- [ ] No task larger than 16 AI-agent-hours
- [ ] All tasks have AI estimates with confidence levels (minimum: >=67% High or >=34% Medium with reviewer approval)
- [ ] Dependencies are clear
- [ ] Testing approach defined

**Confidence Level Definition:**

| Level | Numeric Range | Meaning | Pass Threshold |
|-------|---------------|---------|----------------|
| **High** | 67-100% (0.67-1.0) | Clear scope, standard patterns, libs available | Pass |
| **Medium** | 34-66% (0.34-0.66) | Some custom logic, partial lib support | Pass (borderline) |
| **Low** | 0-33% (0.0-0.33) | Novel algorithms, vague scope, no lib support | Requires review |

**Gate 7 minimum threshold:** Tasks must have confidence >= 67% (High) or >= 34% (Medium with reviewer approval).

**Borderline cases (Medium confidence):** PM Lead must review and approve before proceeding.

**Example conversion (AI-agent-hours → calendar time):**
```
Given:
- ai_estimate = 8 AI-agent-hours (Medium confidence, 55%)
- multiplier = 1.5 (human validation)
- capacity = 0.90 (90% available)
- team_size = 1 developer

Step-by-step calculation:
Step 1: ai_estimate x multiplier = 8h x 1.5 = 12h adjusted
Step 2: adjusted / capacity = 12h / 0.90 = 13.33h calendar
Step 3: calendar / 8h/day = 13.33h / 8 = 1.67 developer-days
Step 4: developer-days / team_size = 1.67 / 1 = 1.67 calendar days ~ 2 days

Formula:
  (ai_estimate x multiplier / capacity) / 8 / team_size
  = (8 x 1.5 / 0.90) / 8 / 1
  = 1.67 calendar days
```

## Gate 8: Subtask Creation

**Skill:** ring:pre-dev-subtask-creation

1. Load tasks from `docs/pre-dev/<feature-name>/tasks.md`
2. Create subtask breakdown document with:
   - Bite-sized steps (2-5 minutes each)
   - TDD-based implementation steps
   - Complete code (no placeholders)
   - Zero-context executable
3. Save to: `docs/pre-dev/<feature-name>/subtasks.md`
4. Run Gate 8 validation checklist
5. Get human approval

**Gate 8 Pass Criteria:**
- [ ] Every subtask is 2-5 minutes
- [ ] TDD cycle enforced (test first)
- [ ] Complete code provided
- [ ] Zero-context test passes

## Gate 9: Delivery Planning (MANDATORY)

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
9. Run Gate 9 validation checklist
10. Get human approval

**Gate 9 Pass Criteria:**
- [ ] All tasks scheduled with realistic dates
- [ ] Critical path identified and validated
- [ ] Team capacity: 90% (AI Agent standard)
- [ ] Period boundaries respected (if sprint/cycle)
- [ ] Spill overs identified and documented
- [ ] Parallel streams defined
- [ ] Risk milestones flagged
- [ ] Contingency buffer added (10-20%)
- [ ] Formula applied: (ai_estimate x multiplier / 0.90) / 8 / team_size = calendar_days

## After Completion

Report to human:

```
Full Track (10 gates) complete for <feature-name>

Artifacts created (paths depend on topology.structure):

**For single-repo (all in docs/pre-dev/<feature-name>/):**
- research.md (Gate 0) - includes Product/UX Research
- prd.md (Gate 1)
- ux-criteria.md (Gate 1) - UX acceptance criteria
- feature-map.md (Gate 2)
- user-flows.md (Gate 2) - Detailed user flows
- wireframes/ (Gate 2) - Wireframe specs (YAML)
- design-validation.md (Gate 2.5) - Design completeness report (if UI)
- trd.md (Gate 3)
- api-design.md (Gate 4)
- api-standards-ref.md (Gate 4 - if standards provided)
- data-model.md (Gate 5)
- db-standards-ref.md (Gate 5 - always generated)
- dependency-map.md (Gate 6)
- tasks.md (Gate 7)
- subtasks.md (Gate 8)
- delivery-roadmap.md (Gate 9)
- delivery-roadmap.json (Gate 9)

**For monorepo (distributed by module):**
*Root (shared):* research.md, prd.md, feature-map.md, trd.md, tasks.md (index), delivery-roadmap.md, delivery-roadmap.json
*Backend module:* api-design.md, data-model.md, dependency-map.md, tasks.md
*Frontend module:* ux-criteria.md, user-flows.md, wireframes/, design-validation.md, dependency-map.md, tasks.md

**For multi-repo (per-repository):**
*Both repos:* research.md, prd.md, trd.md (synchronized), delivery-roadmap.md, delivery-roadmap.json
*Backend repo:* api-design.md, data-model.md, dependency-map.md, tasks.md
*Frontend repo:* ux-criteria.md, user-flows.md, wireframes/, design-validation.md, dependency-map.md, tasks.md

Planning time: 2.5-4.5 hours (comprehensive with UX design)

Next steps:
1. Review artifacts in docs/pre-dev/<feature-name>/
2. Use delivery-roadmap.md to communicate timelines to stakeholders
3. Use /ring:worktree to create isolated workspace
4. Use /ring:write-plan to create implementation plan
5. Execute the plan (ui-engineer will use user-flows.md and wireframes/)
```

## Remember

- This is the **Full Track** - comprehensive and thorough (10 gates)
- All gates provide maximum planning depth
- **Gate 0 (Research) runs 4 agents in parallel** for codebase, best practices, framework docs, and UX research
- **Gate 1 creates ux-criteria.md** with UX acceptance criteria
- **Gate 2 creates user-flows.md and wireframes/** with detailed UX design
- **Gate 2.5 (Design Validation) ensures UI specs are complete** before technical work
- Technology decisions happen at Gate 6 (Dependency Map)
- **Gate 9 (Delivery Planning) is MANDATORY** - creates realistic roadmap with timeline
- All documents saved to `docs/pre-dev/<feature-name>/`
- Get human approval at each gate before proceeding
- Planning investment (2.5-4.5 hours) pays off during implementation
- Delivery roadmap (WHEN/WHO) complements write-plan (HOW)

---

## MANDATORY: Skills Orchestration

**This skill orchestrates multiple sub-skills in a 10-gate workflow.**

### Gate Sequence

| Gate | Skill | Purpose | New Outputs |
|------|-------|---------|-------------|
| 0 | `ring:pre-dev-research` | Domain, technical, and UX research (4 agents) | research.md (includes Product/UX Research) |
| 1 | `ring:pre-dev-prd-creation` | Product requirements + UX validation | prd.md, ux-criteria.md |
| 2 | `ring:pre-dev-feature-map` | Feature scope + UX design | feature-map.md, user-flows.md, wireframes/ |
| 2.5 | `ring:pre-dev-design-validation` | Verify UX specs complete (if UI) | design-validation.md |
| 3 | `ring:pre-dev-trd-creation` | Technical requirements | trd.md |
| 4 | `ring:pre-dev-api-design` | API contracts | api-design.md |
| 5 | `ring:pre-dev-data-model` | Data architecture | data-model.md |
| 6 | `ring:pre-dev-dependency-map` | Technology selection | dependency-map.md |
| 7 | `ring:pre-dev-task-breakdown` | Task decomposition | tasks.md |
| 8 | `ring:pre-dev-subtask-creation` | Implementation steps | subtasks.md |
| 9 | `ring:pre-dev-delivery-planning` | Delivery roadmap | delivery-roadmap.md, .json |

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
