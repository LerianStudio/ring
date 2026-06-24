---
name: ring:analyzing-options
description: "Analyzing different approaches for a task or problem with structured comparisons, effort estimates, and recommendations. Use when facing strategic decisions, architecture choices, or multiple viable approaches. Skip when there's an obvious single approach or the decision is already made."
user-invocable: true
argument-hint: "<task-or-problem-description>"
---

# Analyzing Options

## When to use
- Facing multiple viable approaches to a task or problem
- Making strategic decisions or architecture choices
- Needing structured comparison with effort estimates
- Evaluating trade-offs between competing solutions

## Skip when
- There's an obvious single approach
- The decision is already made
- The task is trivial and doesn't warrant analysis

## Related
**Similar:** ring:writing-plans — use writing-plans when the approach is decided and you need phased execution

---

For the given task or problem, provide a structured analysis following this format:

## Instructions

### 1. Problem Understanding

- Clearly restate the problem/goal
- Identify key requirements and constraints
- List any assumptions being made

### 2. Approach Options

For each viable approach (aim for 3-5 options):

#### Option [N]: [Descriptive Name]

**Overview:** Brief description of the approach

**Benefits:**

- List 3-5 key advantages
- Focus on technical and business value

**Trade-offs:**

- List 2-4 potential drawbacks or limitations
- Be honest about complexity or risks

**Implementation Details:**

- High-level steps required
- Key technologies or patterns involved
- Integration points or dependencies

**Effort Estimate:**

- **Complexity**: Low/Medium/High
- **Time**: Rough estimate (hours/days/weeks)
- **Team Size**: Solo developer / Small team / Large team
- **Maintenance**: Ongoing effort required

**Best For:** Describe scenarios where this approach excels

### 3. Recommendation Matrix

Create a comparison table:

| Approach | Complexity | Time | Risk | Scalability | Maintainability | Overall Score |
| -------- | ---------- | ---- | ---- | ----------- | --------------- | ------------- |
| Option 1 | Low        | 2d   | Low  | Medium      | High            | 7/10          |
| Option 2 | High       | 2w   | Med  | High        | Medium          | 6/10          |
| etc...   |            |      |      |             |                 |               |

### 4. Recommended Approach

- State your primary recommendation with rationale
- Suggest a fallback option if the primary fails
- Highlight any critical decision points

### 5. Next Steps

- List immediate actions for the chosen approach
- Identify what additional information might be needed
- Suggest proof-of-concept or validation steps

## Guidelines

- Be objective and data-driven in analysis
- Consider both short-term and long-term implications
- Include non-technical factors (team skills, deadlines, budget)
- Provide actionable insights, not just theoretical comparisons
- When possible, reference similar successful implementations
