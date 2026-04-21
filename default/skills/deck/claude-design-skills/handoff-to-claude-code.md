# Handoff to Claude Code

**Category:** Modify
**Output:** Developer handoff package for porting a design to production code

## What it does

Packages a design (HTML artifact) into a format another AI coding agent — or a human engineer — can port to a real codebase. Structure, tokens, components, assets, and implementation notes in one bundle.

## When to use

- User is ready to ship a design as production code
- Designer-to-engineer handoff
- Moving an artifact from this environment into a real codebase (Next.js, React Native, etc.)

## What's in the bundle

- **Source HTML** — the final artifact, with all styles inlined or in sibling files
- **Component inventory** — every distinct component used, with variants noted
- **Tokens** — colors, type, spacing, radii, shadows as a single JSON or CSS file
- **Assets** — every image, icon, font referenced (not cross-project-linked)
- **Implementation notes** — a README that explains:
  - Target stack assumptions (if any)
  - Non-obvious behaviors (animations, persistence, API calls)
  - Accessibility considerations
  - Where to find each piece of the puzzle
- **Screenshots** — reference captures of every screen/state

## Principles

- **Self-contained** — no cross-project paths, no external dependencies beyond CDNs
- **Opinionated defaults** — pick one state per component for the main, document other states in the README
- **Real copy** — no lorem ipsum, no placeholder content
- **Named tokens, not hex** — colors referenced by `--color-text-primary`, not `#1a1a1a`

## Process

1. Audit the source artifact — inventory components, tokens, assets
2. Extract tokens to a shared file
3. Refactor components to use token references
4. Write the README with a component tour and implementation notes
5. Zip and present for download, or hand off the folder as-is

## Don't

- Ship pinned CDN URLs without a note about swapping for package installs
- Leave TODO comments or dev-only scaffolding
- Assume the downstream engineer knows how the artifact worked — explain it
