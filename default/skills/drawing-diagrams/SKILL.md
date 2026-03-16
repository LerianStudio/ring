---
name: drawing-diagrams
description: Generate Mermaid diagrams from context and open them in mermaid.live in the browser. Use when the user asks for a diagram, visualization, flowchart, sequence diagram, ER diagram, or any visual
  representation of code, architecture, or processes. Produces lightweight, shareable mermaid.live URLs that open in the browser for interactive editing.
license: MIT
compatibility: Requires Python 3 (standard library only) and a browser. Uses `open` on macOS; Linux users need `xdg-open`.
metadata:
  skip_when: The user needs a rich, branded, or styled HTML visualization (use ring:visual-explainer instead). This skill produces shareable mermaid.live URLs; visual-explainer produces self-contained Lerian-branded
    HTML files.
---

# Mermaid Live Diagram Generator

Generate Mermaid diagrams and open them directly in mermaid.live in the user's browser.

## When to Use

- User explicitly asks for a diagram, chart, or visualization
- User asks to visualize architecture, data flow, state machines, sequences, relationships
- When explaining complex systems where a visual would be more effective than prose
- User says "draw", "diagram", "visualize", "chart", "flowchart", "show me"

## Workflow

### Step 1: Determine Diagram Type

Choose the most appropriate Mermaid diagram type:

| Need | Diagram Type | Keyword |
|------|-------------|---------|
| Process flow, decision trees | Flowchart | `flowchart TD` or `flowchart LR` |
| API calls, message passing | Sequence | `sequenceDiagram` |
| OOP structure, interfaces | Class | `classDiagram` |
| Database schema, entities | ER | `erDiagram` |
| State machines, lifecycles | State | `stateDiagram-v2` |
| Project timelines | Gantt | `gantt` |
| Distribution/proportions | Pie | `pie` |
| Git branch strategy | Git Graph | `gitGraph` |
| User experience mapping | Journey | `journey` |
| Prioritization matrix | Quadrant | `quadrantChart` |
| Data over time | XY Chart | `xychart-beta` |
| Chronological events | Timeline | `timeline` |
| Brainstorming | Mindmap | `mindmap` |

### Step 2: Write the Mermaid Code

Write clean, well-structured Mermaid code. Key syntax rules:

**Flowchart nodes:**
- `A[Rectangle]` `A(Rounded)` `A{Diamond}` `A((Circle))` `A[(Database)]`
- Edges: `-->` (arrow), `-.->` (dotted), `==>` (thick), `~~~` (invisible)
- Link text: `A -->|label| B`
- Subgraphs: `subgraph title ... end`

**Sequence diagrams:**
- `participant A` or `actor A`
- Arrows: `->>` (solid+arrow), `-->>` (dotted+arrow), `-x` (destroy), `-)` (async)
- Blocks: `loop`, `alt/else`, `opt`, `par/and`, `critical/option`, `break`
- Notes: `Note right of A: text`
- `autonumber` for sequence numbers

**ER diagrams:**
- Relationships: `||--o{` (one to many), `||--||` (one to one), `}o--o{` (many to many)
- `--` (identifying/solid), `..` (non-identifying/dashed)
- Attributes: `ENTITY { type name PK/FK/UK "comment" }`

**Class diagrams:**
- Visibility: `+` public, `-` private, `#` protected, `~` package
- Relations: `<|--` inheritance, `*--` composition, `o--` aggregation, `-->` association
- `<<interface>>`, `<<abstract>>` annotations

**State diagrams:**
- `[*]` for start/end states
- `state "description" as s1`
- `<<choice>>`, `<<fork>>`, `<<join>>`
- `--` separator for concurrent states

**CRITICAL: Avoid the word `end` in lowercase inside node labels** -- it's a reserved keyword. Use `End`, `END`, or wrap in quotes.

### Step 3: Encode and Open in Browser

Write the mermaid code to a temp file, then use the bundled encoder script:

```bash
# macOS: uses `open`. On Linux, replace `open` with `xdg-open`.
cat <<'MERMAID_EOF' | python3 ~/.claude/skills/drawing-diagrams/mermaid-encode.py | xargs open
<mermaid code here>
MERMAID_EOF
```

Options:
- `--theme dark` -- use dark theme (options: default, dark, forest, neutral)
- `--view` -- open in view-only mode (no editor)
- `--rough` -- hand-drawn/sketchy style

Example with options:
```bash
cat <<'MERMAID_EOF' | python3 ~/.claude/skills/drawing-diagrams/mermaid-encode.py --theme forest --rough | xargs open
flowchart LR
    A[Start] --> B{Decision}
    B -->|Yes| C[Do thing]
    B -->|No| D[Other thing]
MERMAID_EOF
```

### Step 4: Inform the User

After opening the browser, tell the user:
- What diagram type was chosen and why
- A brief description of what the diagram shows
- That it's open in mermaid.live where they can edit it further
- The mermaid.live URL (so they can share it)

## Diagram Design Guidelines

1. **Readable labels**: Use short, descriptive text. No full sentences in nodes.
2. **Logical flow direction**: TD for hierarchies, LR for sequences/timelines.
3. **Use subgraphs**: Group related nodes for clarity in complex diagrams.
4. **Color with purpose**: Use `classDef` to highlight important nodes (errors in red, success in green, etc.)
5. **Keep it focused**: A diagram should communicate ONE main idea. Split complex systems into multiple diagrams.

## Quick Reference: Common Patterns

### Architecture Diagram
```
flowchart TD
    subgraph Client
        A[Browser] --> B[Mobile App]
    end
    subgraph API["API Gateway"]
        C[Load Balancer]
    end
    subgraph Services
        D[Auth Service]
        E[Core Service]
        F[Notification Service]
    end
    Client --> API --> Services
```

### Database Schema
```
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ LINE_ITEM : contains
    PRODUCT ||--o{ LINE_ITEM : "ordered in"
```

### API Flow
```
sequenceDiagram
    autonumber
    Client->>+API: POST /resource
    API->>+DB: INSERT
    DB-->>-API: OK
    API-->>-Client: 201 Created
```

## Important Notes

- The encoder script uses ONLY Python standard library -- no pip install needed
- Works on macOS (uses `open` command) -- for Linux, users would need `xargs xdg-open`
- URLs have no expiry -- they're self-contained (the diagram state IS the URL)
- Very large diagrams may exceed URL length limits (~2000 chars for some browsers, ~65K for most modern ones)
- The `--rough` flag gives a hand-drawn sketchy look (nice for presentations)
