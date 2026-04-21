---
name: ring:deck
description: Scaffold Lerian-branded HTML presentation projects with live-reload dev server, presenter view on second screen, phone-as-remote over WebSocket, auto-scaling canvas (authored at 1920×1080, fits any viewport), in-browser toolbar (tweak/presenter/PDF/PPTX/remote), feedback-to-file loop for iterating with Claude, PPTX + PDF export (Puppeteer), browser-native PDF (Cmd+P), and `npm start` one-command bootstrap. Use when the user asks for a deck, presentation, board deck, investor deck, or slide deck.
trigger: |
  - User asks to create a deck, presentation, board deck, investor deck, conference deck, all-hands deck, or any Lerian-branded slide deliverable
  - User says "make a deck", "build a deck", "new presentation", "slide deck"
  - User needs a self-contained, locally-served deliverable with speaker notes, remote control, and PDF export
skip_when: |
  - User is editing an already-scaffolded deck — edit the deck's deck.html directly
  - User wants a non-presentational document (memo, one-pager, email) — those use different formats
  - User wants a single static HTML visualization with no tooling — use ring:visualize instead
prerequisites:
  - node_installed (>=18.0.0)
  - pnpm_installed OR npm_installed
verification: |
  - Scaffolded project directory exists with deck.html, presenter.html, remote.html, assets/, scripts/, package.json, LICENSE, README.md
  - `pnpm install` (or npm) completes without error
  - `pnpm dev` boots dev server on port 7007
  - Main deck loads at http://localhost:7007/
  - Presenter view loads at http://localhost:7007/presenter
  - Remote loads at http://<LAN-IP>:7007/remote from a phone on same network
  - Keyboard navigation in main deck propagates to presenter + remote
  - `pnpm export` produces deck.pdf with correct fonts (Poppins + IBM Plex Serif — no system-font substitution)
---

# ring:deck — Lerian Editorial Deck Scaffolder

Scaffold a self-contained Node project for a Lerian-branded HTML presentation. Every deck ships with a live-reload dev server, a presenter view designed for a second screen, a phone-as-remote over WebSocket, and Puppeteer-driven PDF export. The output is a working local project the user runs themselves — not a single HTML file, not a hosted site.

## When to use this skill

Use whenever the user asks for a branded slide deliverable: board deck, investor update, conference talk, all-hands, customer pitch, internal review. The trigger is "deck-shaped output" — sequenced sections, speaker notes, something a human will present live.

- "Make me a board deck for Q2"
- "Build an investor deck for the Series A conversation"
- "I need a conference talk deck"
- "Scaffold a new presentation for next week's all-hands"
- "New slide deck for the product review"

## When NOT to use this skill

- **Editing an already-scaffolded deck** — edit `deck.html` inside that project directly. The scaffold is a one-shot bootstrap, not an editor.
- **Non-presentational documents** — memos, one-pagers, exec emails, PR descriptions. These are written content, not sequenced slides.
- **Single static HTML visualization** — a diagram, dashboard, or comparison table is `ring:visualize`. That skill produces one `.html` file; this skill produces a Node project.

## Two Lerian Design Systems Side by Side

**HARD GATE.** `ring:deck` uses editorial tokens (Amarelo `#FEED02`, Poppins + IBM Plex Serif, JetBrains Mono) intentionally separate from `ring:visualize`'s product-console tokens (`#FDCB28` sunglow, Inter). Both systems are canonical Lerian. MUST NOT cross-mix tokens. A deck with `ring:visualize`'s Inter + sunglow is wrong; a diagram with `ring:deck`'s Poppins + Amarelo is wrong. Keep the systems pure.

## Mandatory Reading — HARD GATE

Before writing any slide content, MUST read:

1. `references/design-tokens.md` — all colors, fonts, spacing, radii
2. `references/layout-rules.md` — **THE critical craft discipline** (vertical-canvas model, `flex: 1; min-height: 0`, no fixed-height cards, 24px text floor, dynamic pagination)
3. `references/slide-archetypes.md` — when to use each of 9 archetypes
4. `references/ui-primitives.md` — eyebrow, pill, kpi, ticks, numbered, table.grid, dashed-hairline, narrative-arc, transition-column, org-node-flag, dual-sided-argument, inline-mini-legend
5. `references/chart-primitives.md` — stacked-horizontal-bar, vertical-bar-chart, 2x2-matrix, funnel (+ monetary overlay), inline-micro-chart
6. `references/speaker-notes.md` — JSON schema + oral-delivery writing guidance

Server + export references (read when tooling questions come up):

7. `references/server.md` — dev server, WebSocket protocol, port override, trust model
8. `references/export.md` — Puppeteer PDF export flow

Skipping any of refs 1-6 before writing slides is the #1 failure mode. The layout rules in particular encode years of craft discipline — reading the description below is NOT a substitute for reading the file.

## Skill Workflow

### Phase 1: Gather minimum-viable requirements

MUST ask the user (skip questions already answered):

1. **Deck title** — e.g., "Lerian Board Meeting Q2 2026"
2. **Audience** — board, investors, conference, team, external partner
3. **Rough slide count** — 10 / 20 / 30+
4. **Directory name** — defaults to kebab-cased title

MUST NOT ask about: tokens, fonts, layout, runtime, export. Those are fixed by the skill — asking is validation theater.

### Phase 2: Read mandatory references

See Mandatory Reading above. HARD GATE — MUST NOT write slides without reading refs 1-6.

### Phase 3: Scaffold project

**Sanitize substitution variables first.** Before copying any template, compute:

- `DECK_TITLE` = the user-supplied title verbatim (e.g., `"Q2 2026 Board Deck"`). Used inside HTML text nodes — HTML-escape `<`, `>`, `&` if the title contains them.
- `DECK_NAME` = `DECK_TITLE.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '')`. MUST be kebab-case — it's the project directory name AND the `"name"` field in `package.json`, which rejects spaces, quotes, and most punctuation. Example: `"Q2 2026 Board Deck" → "q2-2026-board-deck"`.
- `YEAR` = current 4-digit year.
- `COPYRIGHT_HOLDER` = `"Lerian Studio"` unless the user specifies otherwise.

Naive `str.replace` on an unsanitized title breaks `package.json` (quotes, newlines) and fails filesystem validation. Sanitize first, substitute second.

Then create `<DECK_NAME>/` directory with these files (copy from the skill's `templates/`, `assets/`, and `scripts/` directories):

| Source (skill)                     | Destination (scaffolded deck)                |
| ---------------------------------- | -------------------------------------------- |
| `templates/deck.html`              | `deck.html` (substitute `{{DECK_TITLE}}`)    |
| `templates/presenter.html`         | `presenter.html`                             |
| `templates/remote.html`            | `remote.html`                                |
| `templates/package.json.tmpl`      | `package.json` (substitute `{{DECK_NAME}}`)  |
| `assets/*`                         | `assets/*`                                   |
| `scripts/*`                        | `scripts/*`                                  |
| `templates/LICENSE.tmpl`           | `LICENSE` (substitute `{{YEAR}}`, `{{COPYRIGHT_HOLDER}}` — default `Lerian Studio`) |
| `templates/README.md.tmpl`         | `README.md` (substitute `{{DECK_TITLE}}`, `{{DECK_NAME}}`) |
| `templates/.gitignore.tmpl`        | `.gitignore` (no substitution)               |

### Phase 4: Compose slides in deck.html

For each slide:

1. Pick an archetype from `references/slide-archetypes.md`
2. Inline the archetype body from `templates/slide-<name>.html`
3. Replace placeholder content with actual content
4. Obey `references/layout-rules.md` (`flex: 1`, `min-height: 0`, no fixed-height cards, 24px text floor)
5. Use primitives from `references/ui-primitives.md`
6. Use charts from `references/chart-primitives.md` where applicable

### Phase 5: Write speaker notes

- Flat JSON array of strings
- One entry per `<section>`, zero-indexed matching `<section>` order
- `\n\n` for paragraph breaks
- Speaking voice (not written voice) — concrete data first, then context
- See `references/speaker-notes.md` for full guidance

### Phase 6: Hand off to user

Print the Handoff Message Template (below). Do NOT run `pnpm install` or `pnpm dev` for the user — the deck is theirs to run.

## Anti-Rationalization Table

| Rationalization                                             | Why It's WRONG                                                                         | Required Action                                                  |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| "Content is simple, I can skip `layout-rules.md`"           | Simple content still breaks with fixed-height cards. Skipping the gate is the #1 failure mode. | **MUST read layout-rules.md**                                    |
| "I'll pick colors that look nicer than Amarelo"             | `#FEED02` Amarelo is Lerian brand primary, not a style choice. Swapping is a rebrand, not a tweak. | **MUST use tokens from design-tokens.md**                        |
| "I can skip speaker notes"                                  | Notes surface in presenter view — presenters rely on them. Empty notes = unusable presenter view. | **MUST write notes for every slide**                             |
| "Deck already has fonts — I'll skip the Google Fonts block" | Every scaffolded deck is self-contained. The fonts block in `deck.html` is mandatory.  | **MUST preserve the Google Fonts import block**                  |
| "User said 'just a quick deck' — I can skip archetypes"     | Archetypes encode the layout discipline. "Quick" does not mean "worse."                | **MUST use archetypes from slide-archetypes.md**                 |
| "I'll use Chart.js for richer charts"                       | v1 is pure CSS/HTML. Chart.js is v2 work.                                              | **MUST use only the 4 chart primitives**                         |
| "I'll mix deck tokens and visualize tokens"                 | Editorial and product-console design systems are deliberately separate.                | **MUST keep deck tokens pure**                                   |
| "I'll hardcode the slide count in pagination"               | `<section>` count is dynamic. `deck-stage.js` fills pagination at runtime.             | **MUST use `<span class="page-num">` + `<span class="page-total">` pattern** |
| "Puppeteer install is slow — I'll skip it"                  | Export is a first-class feature. Install is a one-time cost.                           | **MUST include puppeteer in package.json**                       |
| "Reading the reference summary in this SKILL.md is enough"  | Summaries are lossy. Token values, exact class names, and pattern structure live in the reference files. | **MUST use the Read tool to open each reference file**           |

## Pressure Resistance

| User Says                                                 | Your Response                                                                                                                                                                                                                              |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| "Just make a simple HTML file, no Node project"           | "Cannot: dev server + presenter + remote + export require Node. If you want a single static HTML without tooling, use `ring:visualize` instead — different skill, different purpose."                                                       |
| "Skip the presenter view, I don't need it"                | "Generated anyway — costs nothing, adds value if needed later. Zero-config removal: just don't open the /presenter URL."                                                                                                                   |
| "Use Inter instead of Poppins"                            | "Cannot: `#FEED02` Amarelo + Poppins + IBM Plex Serif is Lerian editorial brand. For Inter/sunglow tokens, use `ring:visualize`."                                                                                                          |
| "Skip the license file"                                   | "Cannot: Lerian open-source commitment is a third rail. Apache 2.0 license ships with every scaffold."                                                                                                                                     |
| "Don't watch files, just write the deck once"             | "Cannot: dev server + chokidar is the scaffold default. For a static export, run `pnpm export` and distribute the PDF."                                                                                                                    |
| "Host the deck online"                                    | "Out of scope. Scaffolded deck is local-network. Hosting is the user's choice — any static host (Vercel, Cloudflare Pages) serves `deck.html` + `assets/` + `scripts/` (minus `dev-server.mjs`). Document if the user asks."               |
| "Build me a timeline/quote/org-chart slide"               | "Not in v1 archetype set. Options: (a) use `content` or `content-accent` with a close-enough layout, (b) flag as v2 candidate and proceed without it."                                                                                     |

## Blocker Criteria — STOP and Report

STOP and report to the user if:

| Decision Type               | Blocker Condition                                                                                          | Required Action                                                                       |
| --------------------------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Missing Runtime             | Node not installed, or Node version < 18.0.0                                                               | STOP — user must install Node 18+ before proceeding                                   |
| Directory Collision         | Target directory exists and is non-empty                                                                   | STOP and ask: overwrite, rename, or cancel                                            |
| Unsupported Archetype       | User asks for timeline, quote, org-chart, image-hero                                                       | STOP — report these are v2 candidates; offer alternatives from the 9 archetypes       |
| Unsupported Export          | User asks for editable-PowerPoint PPTX (text + shapes, not screenshots)                                    | STOP — report v1 PPTX is screenshots mode only (PNG per slide + speaker notes via `addNotes()`); editable PPTX is deferred because CSS layout doesn't map cleanly to PowerPoint shapes. Offer: PDF + re-author manually, or accept screenshots-mode PPTX. |
| Theme Customization         | User asks for accent override, density toggle, font swap                                                   | STOP — report v1 is locked to Lerian editorial tokens; customization is v2            |
| Auth on Remote              | User asks for PIN or auth on the remote control                                                            | STOP — report v1 is local-network trust model; PIN auth is v2                         |

HARD BLOCK — cannot proceed:

- If the skill's `references/` directory is missing any mandatory file (any of the 8 refs) → report which is missing; instruct user to re-clone the plugin repo.
- If the skill's `templates/` is missing any archetype or `deck.html` → same remediation.

## Severity Calibration

| Severity | Examples                                                                                  | Action                                                    |
| -------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| CRITICAL | Fixed-height cards used; hardcoded pagination `NN/17`; wrong color tokens; wrong fonts    | MUST fix before completing                                |
| HIGH     | Text smaller than 24px floor; chart without `aria-label`; speaker notes missing           | SHOULD fix; warn user if shipping as-is                   |
| MEDIUM   | Placeholder content not replaced; too many `content-accent` slides (more than 3)          | Warn user; user decides                                   |
| LOW      | Minor typography drift (e.g., 80px hero where 96px would fit)                             | Mention; user decides                                     |

## Cannot Be Overridden (Non-Negotiable)

- **Lerian brand tokens** — Amarelo `#FEED02`, Poppins + IBM Plex Serif, JetBrains Mono
- **Apache 2.0 license** on scaffolded deck
- **Dynamic pagination** via `<span class="page-num">` + `<span class="page-total">` (two documented exceptions: appendix letter pagination `A1 / 8` and main-deck companion letter-suffix `09b / 14` — both hardcoded without the `.page-num` class so the runtime leaves them alone, see [`references/slide-archetypes.md` → Pagination convention](references/slide-archetypes.md#pagination-convention))
- **`flex: 1; min-height: 0`** on main content grids (layout-rules.md HARD GATE)
- **Speaker-notes JSON structure** — flat array of strings
- **WebSocket protocol** — 5 message types (`nav`, `blank`, `state`, `hello`, `reload`) in v1. `state` and `nav` carry a `total` field so the remote can render `N / M` once the main deck has announced totals. See `references/server.md` for the full protocol.
- **Self-contained scaffold** — every deck is an independent Node project; no shared workspace dependency

## Known Limitations (v1)

- **Remote shows `N / ?`** for slide-total until the first nav event fires. Server doesn't know total until main deck broadcasts. Fine for most flows; users rarely notice.
- **No auth on remote** — local network trust model. Document in handoff.
- **Puppeteer bundled Chromium** weighs ~200MB per scaffolded deck. `pnpm export:chrome` uses system Chrome instead.
- **Google Fonts online dependency** — scaffolded deck fetches fonts from Google CDN. Offline presentations need a pre-cached browser.

## Handoff Message Template

After scaffolding, print this to the user:

```
Deck scaffolded at: ./<deck-name>/

Next steps:
  cd <deck-name>
  npm start                 # one command: installs deps if needed, boots
                            # dev server on http://localhost:7007, and
                            # auto-opens the deck in your default browser.
                            # (Suppress the auto-open with AUTO_OPEN=false.)

During the presentation:
  - Main deck:   http://localhost:7007
  - Presenter:   http://localhost:7007/presenter  (open on second screen)
  - Remote:      http://<LAN-IP>:7007/remote      (open on phone, same Wi-Fi)

In-browser toolbar (floating, bottom-center):
  Tweak      capture feedback on the active slide — appended to
             feedback.jsonl. Tell Claude "check tweaks" to review.
  Presenter  opens /presenter in a new window
  PDF        triggers Puppeteer export, streams deck.pdf for download
  PPTX       same flow for deck.pptx (screenshots + speaker notes)
  Remote     shows the LAN URL for the phone remote

Keyboard controls (main deck):
  →/Space  next slide
  ←        previous slide
  F        fullscreen
  S        toggle speaker notes overlay
  G        go to slide number
  B        blank screen
  T        toggle tweak panel
  H        toggle toolbar visibility

Export from the terminal (optional — the toolbar buttons are easier):
  npm run export            # PDF via bundled Chromium (~200MB first time)
  npm run export:chrome     # PDF via system Chrome (~50MB, faster)
  npm run export:pptx       # PPTX (screenshots + notes, not editable)

Local network only — no auth. Don't expose port 7007 publicly.
```

## Future Work (v2 Candidates)

- Editable PPTX export (text + shapes mapped from CSS layout, not screenshots) — v1 ships screenshots mode only
- Data-driven mode: YAML/JSON content files + template binding
- Theme customization: accent override, density toggle
- Additional archetypes: timeline, quote, org-chart, image-hero, photo-grid
- Remote auth: short-lived rotating PIN displayed on main screen
- Chart.js opt-in for richer analytics
- Self-contained HTML bundle export (no-CDN offline package)
- Multi-deck workspace (shared deps)
