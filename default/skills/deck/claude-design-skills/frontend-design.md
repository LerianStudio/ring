# Frontend design

**Category:** Modify
**Output:** Aesthetic direction when there's no existing brand system

## When to use

- User hasn't attached a design system or UI kit
- The brief is "make it look good" with no visual reference
- Building something that needs a coherent aesthetic from scratch
- The design feels generic / defaults-y and needs more character

## Core principle

**Commit to a bold direction.** The worst frontend design is the one that hedges — safe grays, system fonts, centered everything. Pick an aesthetic and push it.

## Aesthetic directions to consider

Pick one per project. Don't blend.

- **Dark editorial** — near-black bg, one warm accent, serif or sharp sans, mono for metadata
- **Warm minimal** — off-white, terracotta or olive accent, soft shadows, generous whitespace
- **Classic consulting** — cream paper, restrained serifs, thin rules, ordered
- **Swiss / editorial print** — high contrast black/white, one punchy accent (yellow, red), grid-obvious
- **Brutalist** — raw HTML defaults, Times New Roman, hard edges, monospace, visible seams
- **Vibrant SaaS** — gradients, rounded everything, soft shadows, bright accents
- **Terminal / hacker** — monospace, green-on-black or amber, CRT feel
- **Magazine** — oversized type, pull quotes, drop caps, mixed serifs and sans

## Type

- Pick 1–2 families. Usually one display + one body, or one sans + one mono.
- Avoid overused: Inter, Roboto, Arial, Fraunces, system-ui
- Consider: Instrument Serif, GT America, Söhne, JetBrains Mono, IBM Plex, Space Grotesk, Fraunces (if used sparingly), Domaine

## Color

- Use `oklch()` for harmonious hues when extending a palette
- Neutrals do most of the work — get the grays right before picking accents
- 1–2 accent colors max
- Dark bg + warm accent almost always works

## Composition

- **Asymmetry** beats centered. Offsets, drops, pull-outs.
- **Generous whitespace** — if in doubt, add more
- **Scale contrast** — tiny metadata next to huge display type
- **Grids** — show they're there (visible lines) or hide them entirely
- **CSS Grid and flexbox** are your friends. `text-wrap: pretty`. `font-feature-settings`. Variable fonts.

## Anti-patterns (AI slop tropes)

- Aggressive gradient backgrounds
- Emoji everywhere
- Rounded corners + left-border accent on every container
- Self-drawn SVG illustrations (use placeholders)
- Overused font pairings

## Process

1. Ask the user for aesthetic preferences (use `questions_v2` with svg-options if possible)
2. Commit to one direction in words before touching code: "Dark editorial, Instrument Serif display, JetBrains Mono for metadata, orange accent, hairline dividers"
3. Build a small token set (4 colors, 2 fonts, spacing scale)
4. Apply consistently — don't drift mid-design
