# Create design system

**Category:** Create
**Output:** A design system / UI kit as a browsable HTML asset with registered components

## Role

Systems designer. The output is the raw material other designs will be built from: tokens, type, spacing, components, patterns. It should be opinionated, coherent, and usable.

## Structure

A design system in this environment is a folder of files that later designs can read from cross-project. Typical structure:

```
colors.md          # palette + semantic tokens
type.md            # typography scale, fonts, usage
spacing.md         # spacing + radii + shadows
components/        # per-component HTML samples
  button.html
  input.html
  card.html
  badge.html
brand.md           # voice, logo, imagery guidelines
README.md          # index + principles
```

Each HTML component sample should be registered as an asset in the review manifest with a `group`: `Type`, `Colors`, `Spacing`, `Components`, `Brand`.

## Tokens

Define tokens in CSS custom properties or as a shared JSON/JS object. Every color, type size, spacing value, border radius, and shadow gets a token name. No raw hex in components.

Include **semantic tokens** (`--color-text-primary`, `--color-surface`, `--color-danger`) layered on top of raw palette tokens (`--gray-900`, `--blue-500`).

## Type

- Pick 1–2 families max. Commit to a scale (usually 6–10 sizes).
- Define weights used, line heights, letter spacing
- Show real examples at each size — not just the numbers

## Colors

- Define a palette (10+ neutrals, 3–6 accents, status colors)
- Show swatches with hex + token name + contrast ratios against white/black
- Define dark mode tokens if relevant

## Spacing

- Use a scale (4, 8, 12, 16, 24, 32, 48, 64…). No one-off values.
- Show radii and shadows with real cards applying them

## Components

Each component gets a dedicated HTML page showing:
- Anatomy diagram
- All variants (sizes, colors, states)
- Usage do's and don'ts
- Live HTML/CSS that can be copied

## Don't

- Invent colors or sizes that aren't in the system
- Skip semantic tokens — raw palette alone is not enough
- Use emoji in components unless the brand calls for it
- Build components that don't match the tokens

## Process

1. Ask about brand, voice, audience, inspirations, existing assets
2. Lock tokens first (colors, type, spacing) — components come after
3. Build one component at a time, registering each as an asset
4. Write the README as a tour of the system
