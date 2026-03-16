---
name: pre-dev-prd-creation
description: |
  Gate 1: Business requirements document - defines WHAT/WHY before HOW.
  Creates PRD with problem definition, user stories, success metrics.
metadata:
  sequence:
    before:
    - ring:pre-dev-feature-map
    - ring:pre-dev-trd-creation
  skip_when: |
    - PRD already exists and validated → proceed to Gate 2
    - Pure technical task without business impact → TRD directly
    - Bug fix → systematic-debugging
  trigger: |
    - Starting new product or major feature
    - User asks to "plan", "design", or "architect"
    - About to write code without documented requirements
    - Asked to create PRD or requirements document
---

# PRD Creation - Business Before Technical

## Foundational Principle

**Business requirements (WHAT/WHY) must be fully defined before technical decisions (HOW/WHERE).**

Mixing business and technical concerns creates:
- Requirements that serve implementation convenience, not user needs
- Technical constraints that limit product vision
- Inability to evaluate alternatives objectively
- Cascade failures when requirements change

**The PRD answers**: WHAT we're building and WHY it matters to users and business.
**The PRD never answers**: HOW we'll build it or WHERE components will live.

## Mandatory Workflow

| Phase | Activities |
|-------|------------|
| **0. Load Research** | Check `docs/pre-dev/{feature}/research.md`; review codebase patterns, best practices, framework constraints, UX research; reference findings with `file:line` notation |
| **1. Problem Discovery** | Define problem without solution bias; identify specific users; quantify pain with metrics/evidence |
| **2. Business Requirements** | Executive summary (3 sentences); user personas (goals, frustrations); user stories (As/I want/So that); success metrics (measurable); scope boundaries (in/out) |
| **3. Gate 1 Validation** | Problem articulated; impact quantified; users identified; features address problem; metrics measurable; scope explicit |
| **4. UX Validation** | Dispatch `product-designer` to validate PRD against user needs and create `ux-criteria.md` |

## Explicit Rules

### ✅ DO Include in PRD
Problem definition and user pain points, user personas (demographics, goals, frustrations), user stories with acceptance criteria, feature requirements (WHAT not HOW), success metrics (adoption, satisfaction, KPIs), scope boundaries (in/out explicitly), go-to-market considerations

### ❌ NEVER Include in PRD
Architecture diagrams or component design, technology choices (languages, frameworks, databases), implementation approaches or algorithms, database schemas or API specifications, code examples or package dependencies, infrastructure needs or deployment strategies, system integration patterns

### Separation Rules
1. **If it's a technology name** → Not in PRD (goes in Dependency Map)
2. **If it's a "how to build"** → Not in PRD (goes in TRD)
3. **If it's implementation** → Not in PRD (goes in Tasks/Subtasks)
4. **If it describes system behavior** → Not in PRD (goes in TRD)

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Just a quick technical note won't hurt" | Technical details constrain business thinking. Keep them separate. |
| "Stakeholders need to know it's feasible" | Feasibility comes in TRD after business requirements are locked. |
| "The implementation is obvious" | Obvious to you ≠ obvious to everyone. Separate concerns. |
| "I'll save time by combining PRD and TRD" | You'll waste time rewriting when requirements change. |
| "This is a simple feature, no need for formality" | Simple features still need clear requirements. Follow the process. |
| "I can skip Gate 1, I know it's good" | Gates exist because humans are overconfident. Validate. |
| "The problem is obvious, no need for personas" | Obvious to you ≠ validated with users. Document it. |
| "Success metrics can be defined later" | Defining metrics later means building without targets. Do it now. |
| "I'll just add this one API endpoint detail" | API design is technical architecture. Stop. Keep it in TRD. |
| "But we already decided on PostgreSQL" | Technology decisions come after business requirements. Wait. |
| "CEO/CTO says it's a business constraint" | Authority doesn't change what's technical. Abstract it anyway. |
| "Investors need to see specific vendors/tech" | Show phasing and constraints abstractly. Vendors go in TRD. |
| "This is product scoping, not technical design" | Scope = capabilities. Technology = implementation. Different things. |
| "Mentioning Stripe shows we're being practical" | Mentioning "payment processor" shows the same. Stay abstract. |
| "PRDs can mention tech when it's a constraint" | PRDs mention capabilities needed. TRD maps capabilities to tech. |
| "Context matters - this is for exec review" | Context doesn't override principles. Executives get abstracted version. |

## Security Requirements Discovery (Business Level)

**During PRD creation, identify if the feature requires access control:**

| Business Question | If Yes → Document |
|-------------------|-------------------|
| Does this feature handle user-specific data? | "Users can only access their own [data type]" |
| Are there different user roles with different permissions? | "Admins can [X], regular users can [Y]" |
| Does this feature need to identify who performed an action? | "Audit trail required for [action type]" |
| Does this integrate with other internal services? | "Service must authenticate to [service name]" |
| Are there regulatory requirements (GDPR, PCI-DSS, HIPAA)? | "Must comply with [regulation] for [data type]" |

**What to include in PRD:**
- ✅ "Only authenticated users can access this feature"
- ✅ "Users can only view/edit their own records"
- ✅ "Admin approval required for [action]"
- ✅ "Must track who performed each action"

**What NOT to include in PRD:**
- ❌ "Use JWT tokens" (technology choice → TRD)
- ❌ "Integrate with Access Manager" (architecture → TRD)
- ❌ "OAuth2 flow" (protocol choice → TRD)

**Note:** The TRD (Gate 3) will translate these business requirements into authentication/authorization architecture patterns. For Go services, refer to `golang.md` → Access Manager Integration section during TRD creation.

---

## Red Flags - STOP

If you catch yourself writing or thinking any of these in a PRD, **STOP**:

- Technology product names (PostgreSQL, Redis, Kafka, AWS, etc.)
- Framework or library names (React, Fiber, Express, etc.)
- Words like: "architecture", "component", "service", "endpoint", "schema"
- Phrases like: "we'll use X to do Y" or "the system will store data in Z"
- Code examples or API specifications
- "How we'll implement" or "Technical approach"
- Database table designs or data models
- Integration patterns or protocols

**When you catch yourself**: Move that content to a "technical notes" section to transfer to TRD later. Keep PRD pure business.

## Data Source Discovery (Frontend-only Features)

**⛔ MANDATORY:** If feature is frontend-only (uses existing backend APIs), this section MUST be completed.

### When to Apply

Check `research.md` frontmatter for topology:
```yaml
topology:
  scope: frontend-only  # ← This triggers data source discovery
```

### Step 1: Identify Existing APIs

**Document all existing APIs the feature will consume:**

```markdown
## Data Sources

### Existing Backend APIs

| API | Endpoint Pattern | Description | Documentation |
|-----|------------------|-------------|---------------|
| User API | /api/v1/users/* | User management | link to docs |
| Orders API | /api/v1/orders/* | Order operations | link to docs |

### API Capabilities Needed

| User Story | Required Capability | Available API | Gap? |
|------------|---------------------|---------------|------|
| US-001 | Get user profile | GET /users/:id | No |
| US-002 | List user orders | GET /orders?userId= | No |
| US-003 | Export order PDF | None | Yes - needs BFF |
```

### Step 2: Identify API Gaps

**If user story requires capability not available in existing APIs:**

| Gap Type | Action |
|----------|--------|
| Data aggregation needed | Flag: "BFF required for aggregation" |
| Data transformation needed | Flag: "BFF required for transformation" |
| Missing endpoint | Flag: "Backend enhancement needed" |
| Multiple API calls for single view | Flag: "BFF recommended for optimization" |

### Step 3: Document in PRD

**Add to PRD under "Technical Context" section:**

```markdown
## Technical Context (Frontend-only)

**Data Source Type:** Existing Backend APIs

**Available APIs:**
- User API (v1) - user management operations
- Orders API (v1) - order CRUD operations

**API Gaps Identified:**
- [ ] No endpoint for aggregated dashboard data → BFF needed
- [ ] PDF export not available → Backend enhancement OR BFF generation

**BFF Requirements:** [None | Aggregation | Transformation | Both]
```

### Rationalization Table for Data Source Discovery

| Excuse | Reality |
|--------|---------|
| "We'll discover APIs during implementation" | Discovery during implementation causes rework. Document now. |
| "Frontend devs know the APIs" | Documentation prevents tribal knowledge. Write it down. |
| "APIs are obvious from the codebase" | Obvious to you ≠ documented for AI agents. Be explicit. |
| "We don't need BFF, just call APIs directly" | Multiple API calls = poor UX. Evaluate BFF need properly. |
| "BFF adds complexity" | BFF complexity < spaghetti frontend API calls. Evaluate objectively. |

## Gate 1 Validation Checklist

| Category | Requirements |
|----------|--------------|
| **Problem Definition** | Problem articulated (1-2 sentences); impact quantified/qualified; users specifically identified; current workarounds documented |
| **Solution Value** | Features address core problem; success metrics measurable; ROI case documented; user value clear per feature |
| **Scope Clarity** | In-scope items explicit; out-of-scope with rationale; assumptions documented; business dependencies identified |
| **Market Fit** | Differentiation clear; value proposition validated; business case sound; go-to-market outlined |
| **Data Sources (frontend-only)** | Existing APIs documented; API capabilities mapped to user stories; API gaps identified; BFF requirements determined |

**Gate Result:** ✅ PASS → UX Validation → Feature Map | ⚠️ CONDITIONAL (address gaps) | ❌ FAIL (return to discovery)

## Phase 4: UX Validation + Wireframes

**After PRD passes Gate 1 validation, dispatch product-designer for UX validation:**

```
Task(
  subagent_type="ring:product-designer",
  prompt="Validate PRD at docs/pre-dev/{feature}/prd.md against user needs. Mode: ux-validation.

  UI Configuration (from pre-dev command):
  - UI Library: {ui_library}  // e.g., shadcn/ui, Chakra UI, or auto-detected
  - Styling: {styling}        // e.g., TailwindCSS, CSS Modules, or auto-detected

  Create ux-criteria.md with: problem validation status, refined personas, UX acceptance criteria (functional, usability, accessibility, responsive).

  If feature has UI components, also create wireframes/ directory with low-fidelity prototypes using the specified UI library components and styling approach."
)
```

**IMPORTANT: Pass UI Configuration to product-designer**

The UI Library and Styling choices (from `/pre-dev-feature` or `/pre-dev-full` questions) MUST be passed to product-designer:
- If user selected a library → Use that library's component names in wireframes
- If auto-detected from package.json → Use the detected library
- If "Custom components only" → Use generic component names

This ensures wireframes reference real components that will be available during implementation.

**UX Validation Outputs:**
- `docs/pre-dev/{feature}/ux-criteria.md` - UX acceptance criteria
- `docs/pre-dev/{feature}/wireframes/` - Low-fidelity prototypes (if feature has UI)
  - `{screen-name}.yaml` - YAML wireframe specification per screen
  - `user-flows.md` - User flow diagrams with state transitions

**UI Detection Rule:**
If PRD contains any of these, feature HAS UI and wireframes are REQUIRED:
- User stories mentioning: "see", "view", "click", "navigate", "page", "screen", "button", "form"
- Features involving: login, dashboard, settings, profile, reports, notifications
- Any user-facing interaction

**UX Validation Checklist:**

| Check | Required | Condition |
|-------|----------|-----------|
| Problem validation status documented | Yes | Always |
| Personas refined based on PRD | Yes | Always |
| Functional UX criteria defined | Yes | Always |
| Usability criteria defined | Yes | Always |
| Accessibility criteria defined | Yes | Always |
| Responsive criteria defined | Yes | Always |
| All PRD user stories have UX criteria | Yes | Always |
| Wireframes created for each screen | Yes | If feature has UI |
| User flows documented | Yes | If feature has UI |
| State coverage table complete | Yes | If feature has UI |

**Wireframe YAML Format:**
```yaml
screen: Screen Name
route: /path
layout: layout-type
components:
  - id: component-id
    type: component-type
    # ... component specs
states:
  default: { ... }
  loading: { ... }
  error: { ... }
responsive:
  mobile: { ... }
  desktop: { ... }
accessibility:
  keyboard: [ ... ]
  screen-reader: [ ... ]
```

### Document Placement (based on topology.structure)

**prd.md placement:**

| Structure | prd.md Location |
|-----------|-----------------|
| single-repo | `docs/pre-dev/{feature}/prd.md` |
| monorepo | `docs/pre-dev/{feature}/prd.md` (root) |
| multi-repo | Write to BOTH repos |

**ux-criteria.md and wireframes/ placement:**

| Structure | Location |
|-----------|----------|
| single-repo | `docs/pre-dev/{feature}/` |
| monorepo | `{frontend.path}/docs/pre-dev/{feature}/` |
| multi-repo | `{frontend.path}/docs/pre-dev/{feature}/` |

**Why frontend path for UX docs?** UX criteria and wireframes are consumed by frontend engineers. Placing them in the frontend module/repo ensures they are discoverable where they'll be used.

**Directory creation for multi-module:**
```bash
# Read topology from research.md frontmatter
# Create appropriate directories:

# For monorepo - frontend module
mkdir -p "{frontend.path}/docs/pre-dev/{feature}"

# For multi-repo - both repos for prd.md, frontend for UX
mkdir -p "{backend.path}/docs/pre-dev/{feature}"
mkdir -p "{frontend.path}/docs/pre-dev/{feature}"
```

**If UX validation fails:**
- Conflicting user needs → Return to Phase 1 (Problem Discovery)
- Missing persona details → Enrich PRD personas
- Unclear acceptance criteria → Iterate with product-designer
- Missing wireframes for UI feature → product-designer must create them

## Common Violations

| Violation | Wrong | Correct |
|-----------|-------|---------|
| **Tech in Features** | "FR-001: Use JWT tokens for session, bcrypt for passwords, OAuth2 with Google" | "FR-001: Users can create accounts and securely log in. Value: Access personalized content. Success: 95% authenticate first attempt" |
| **Implementation in Stories** | "As user, I want to store data in PostgreSQL so queries are fast" | "As user, I want dashboard to load in <2 seconds so I can quickly access information" |
| **Architecture in Problem** | "Our microservices architecture doesn't support real-time notifications" | "Users miss important updates because they must manually refresh. 78% report missing time-sensitive info" |
| **Authority-Based Bypass** | "MVP: Stripe for payments, PostgreSQL (we already use it)" | "Phase 1: Integrate with existing payment vendor (2-week timeline); leverage existing database infrastructure. TRD will document specific vendor selection" |

## Confidence Scoring

| Factor | Points | Criteria |
|--------|--------|----------|
| Market Validation | 0-25 | Direct user feedback: 25, Market research: 15, Assumptions: 5 |
| Problem Clarity | 0-25 | Quantified pain: 25, Qualitative evidence: 15, Hypothetical: 5 |
| Solution Fit | 0-25 | Proven pattern: 25, Adjacent pattern: 15, Novel: 5 |
| Business Value | 0-25 | Clear ROI: 25, Indirect value: 15, Uncertain: 5 |

**Action:** 80+ autonomous | 50-79 present options | <50 ask discovery questions

## Design System Generation (For New Projects with UI)

**MANDATORY:** If feature has UI (Q4=Yes) AND project is new (no existing design system), generate `design-system.md` based on Q7-Q10 responses.

**Trigger Conditions:**
- Q4 = "Yes" (feature has UI)
- No existing `globals.css` with CSS variables OR no `tailwind.config.*` with custom colors
- Q7-Q10 were answered (not auto-detected from existing config)

**design-system.md Template:**

```markdown
# Design System - {Feature Name}

## Configuration Source
- Accessibility: {Q7 response}
- Dark Mode: {Q8 response}
- Brand Color: {Q9 response}
- Typography: {Q10 response}

## Color Palette

### Primary
| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--primary` | {derived from Q9} | {lighter for dark} | Main actions, links |
| `--primary-foreground` | #ffffff | {dark text} | Text on primary |
| `--primary-hover` | {darker shade} | {lighter shade} | Hover states |

### Neutral
| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--background` | #ffffff | #0f172a | Page background |
| `--foreground` | #0f172a | #f8fafc | Primary text |
| `--muted` | #f1f5f9 | #1e293b | Secondary backgrounds |
| `--muted-foreground` | #64748b | #94a3b8 | Secondary text |
| `--border` | #e2e8f0 | #334155 | Borders, dividers |

### Semantic
| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--success` | #16a34a | #22c55e | Success states |
| `--warning` | #ca8a04 | #eab308 | Warning states |
| `--error` | #dc2626 | #ef4444 | Error states |

## Contrast Validation ({Q7 level})

| Combination | Required Ratio | Actual | Pass |
|-------------|----------------|--------|------|
| foreground on background | {4.5:1 or 7:1} | {calculated} | ✅/❌ |
| primary on background | {4.5:1 or 7:1} | {calculated} | ✅/❌ |
| muted-foreground on background | {4.5:1 or 7:1} | {calculated} | ✅/❌ |

## Typography

### Font Stack
- Display: {Q10 choice}, sans-serif
- Body: {Q10 choice}, sans-serif
- Mono: 'Geist Mono', ui-monospace, monospace

### Scale
| Token | Size | Line Height | Usage |
|-------|------|-------------|-------|
| text-xs | 12px | 16px | Captions |
| text-sm | 14px | 20px | Secondary |
| text-base | 16px | 24px | Body |
| text-lg | 18px | 28px | Large body |
| text-xl | 20px | 28px | Small headings |
| text-2xl | 24px | 32px | Section headings |
| text-3xl | 30px | 36px | Page headings |

## Spacing Scale (4px base)

| Token | Value |
|-------|-------|
| spacing-1 | 4px |
| spacing-2 | 8px |
| spacing-3 | 12px |
| spacing-4 | 16px |
| spacing-6 | 24px |
| spacing-8 | 32px |

## Accessibility Requirements

- **Level:** {Q7 response}
- **Minimum contrast:** {4.5:1 for AA, 7:1 for AAA}
- **Focus indicators:** 2px solid ring required
- **Touch targets:** Minimum 44x44px
- **Reduced motion:** Respect prefers-reduced-motion
```

**Color Derivation from Q9 (Brand Color):**

| Q9 Choice | --primary (Light) | --primary (Dark) |
|-----------|-------------------|------------------|
| Blue | hsl(217, 91%, 60%) | hsl(217, 91%, 65%) |
| Purple | hsl(262, 83%, 58%) | hsl(262, 83%, 63%) |
| Green | hsl(142, 76%, 36%) | hsl(142, 71%, 45%) |
| Orange | hsl(25, 95%, 53%) | hsl(25, 95%, 58%) |
| Custom | User-provided hex | Lightened 5% |

**Typography Mapping from Q10:**

| Q10 Choice | Font Family |
|------------|-------------|
| Modern Tech (Geist) | 'Geist', sans-serif |
| Contemporary (Satoshi) | 'Satoshi', sans-serif |
| Editorial (Cabinet Grotesk) | 'Cabinet Grotesk', sans-serif |
| Professional (General Sans) | 'General Sans', sans-serif |

**design-system.md Placement:**

| Structure | Location |
|-----------|----------|
| single-repo | `docs/pre-dev/{feature}/design-system.md` |
| monorepo | `{frontend.path}/docs/pre-dev/{feature}/design-system.md` |
| multi-repo | `{frontend.path}/docs/pre-dev/{feature}/design-system.md` |

**GATE BLOCKER:** If feature has UI and project is new, design-system.md MUST exist before proceeding to TRD. The TRD will reference these tokens.

## Output & After Approval

**Outputs (paths depend on topology.structure):**

| Document | single-repo | monorepo | multi-repo |
|----------|-------------|----------|------------|
| prd.md | `docs/pre-dev/{feature}/` | `docs/pre-dev/{feature}/` | Both repos |
| ux-criteria.md | `docs/pre-dev/{feature}/` | `{frontend.path}/docs/pre-dev/{feature}/` | Frontend repo |
| wireframes/ | `docs/pre-dev/{feature}/` | `{frontend.path}/docs/pre-dev/{feature}/` | Frontend repo |
| design-system.md | `docs/pre-dev/{feature}/` | `{frontend.path}/docs/pre-dev/{feature}/` | Frontend repo (new projects) |

1. ✅ Lock the PRD - no changes without formal amendment
2. ✅ Lock ux-criteria.md - defines UX acceptance for implementation
3. ✅ Lock wireframes/ - defines visual structure for ui-engineer
4. 🎯 Use all as input for Feature Map (`ring:pre-dev-feature-map`) or TRD (`ring:pre-dev-trd-creation`)
5. 🚫 Never add technical details retroactively
6. 📋 Keep business/technical strictly separated

## The Bottom Line

**If you wrote a PRD with technical details, delete it and start over.**

The PRD is business-only. Period. No exceptions. No "just this once". No "but it's relevant".

Technical details go in TRD. That's the next phase. Wait for it.

**Follow the separation. Your future self will thank you.**

---

## Standards Loading (MANDATORY)

This skill is a business requirements skill and does NOT require WebFetch of language-specific standards.

**Purpose:** PRD defines WHAT/WHY at a business level. Technical standards are irrelevant at this stage—they apply during TRD (Gate 3) and implementation.

**However**, if research.md exists from Gate 0, MUST load and reference it for:
- Existing codebase patterns
- Prior solutions from docs/solutions/
- Framework constraints discovered during research

---

## Blocker Criteria - STOP and Report

| Condition | Action | Severity |
|-----------|--------|----------|
| Problem statement cannot be articulated | STOP and conduct discovery with stakeholders | CRITICAL |
| No user personas can be identified | STOP and validate who the feature serves | CRITICAL |
| Technical details creep into PRD | STOP and remove them—move to TRD notes | HIGH |
| Success metrics cannot be defined | STOP and clarify business value | HIGH |
| Scope boundaries unclear (in/out not defined) | STOP and establish explicit scope | MEDIUM |
| research.md exists but wasn't consulted | Continue but MUST reference research findings | MEDIUM |

---

## Cannot Be Overridden

These requirements are NON-NEGOTIABLE:

- MUST NOT include technical implementation details in PRD
- MUST NOT include technology names, frameworks, or databases
- MUST define measurable success metrics
- MUST include explicit scope boundaries (in-scope/out-of-scope)
- MUST include user personas with goals and frustrations
- MUST dispatch `ring:product-designer` for UX validation after PRD
- CANNOT proceed to Gate 2/3 with unvalidated PRD

---

## Severity Calibration

| Severity | Definition | Example |
|----------|------------|---------|
| **CRITICAL** | PRD cannot be written | No problem identified, no users defined |
| **HIGH** | PRD violates separation principle | Technology names in feature requirements |
| **MEDIUM** | PRD incomplete but usable | Missing 1-2 success metrics |
| **LOW** | Minor quality issues | User story format inconsistent |

---

## Pressure Resistance

| User Says | Your Response |
|-----------|---------------|
| "Include the tech stack, stakeholders need it" | "Cannot include technology in PRD. Stakeholders see tech choices in TRD/Dependency Map. PRD stays business-only." |
| "Just mention PostgreSQL as a constraint" | "Cannot mention specific databases. Use 'persistent data storage' if needed. Tech selection happens in Gate 6." |
| "Skip UX validation, designer approved verbally" | "Cannot skip UX validation. Verbal approval isn't documented. I'll dispatch product-designer for formal validation." |
| "Success metrics can be defined later" | "Cannot defer metrics. Undefined metrics = building without targets. I'll define measurable KPIs now." |
| "Scope is obvious, skip boundaries" | "Cannot skip scope boundaries. 'Obvious' scope causes creep. I'll document explicit in/out lists." |

---

## Anti-Rationalization

| Rationalization | Why It's WRONG | Required Action |
|-----------------|----------------|-----------------|
| "Quick technical note won't hurt" | Technical details constrain business thinking | **Remove all tech, move to TRD notes** |
| "Stakeholders need feasibility context" | Feasibility comes in TRD after requirements locked | **Keep PRD pure business** |
| "The implementation is obvious" | Obvious to you ≠ obvious to everyone | **Separate concerns regardless** |
| "Combining PRD and TRD saves time" | Combining wastes time when requirements change | **Keep documents separate** |
| "This is a simple feature, no formality needed" | Simple features still need clear requirements | **Follow the process** |
| "Problem is obvious, skip personas" | Obvious to you ≠ validated with users | **Document personas** |
| "Adding one API detail helps clarity" | API design is TRD territory. Stop. Keep it in TRD | **Remove, add to TRD notes** |

---

## When This Skill Is Not Needed

- PRD already exists and is validated (Gate 1 passed)
- Pure technical task without business impact (TRD directly)
- Bug fix with known solution (use systematic-debugging)
- Documentation-only updates
- Configuration changes with no feature impact
- Refactoring with no user-facing changes
