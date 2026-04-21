# Migrate the Lerian Deck Runtime to a Web Component Architecture

## Context

The current deck runtime in `default/skills/deck/scripts/deck-stage.js` is an imperative controller built on global state and direct DOM queries. Three limitations matter:

1. **No auto-scaling.** Decks authored at 1920×1080 break on any other display. Presenter iframes hack around this with `width: 400%; transform: scale(0.25)`.
2. **Slides unmount when inactive.** `display: none` tears down embedded state — videos reset, React trees re-mount on re-entry, iframes reload. Any live-demo slide loses state on nav.
3. **No lifecycle hook for authored slide code.** Charts and timers on slides can't react to becoming active — they either run continuously (burning CPU off-screen) or never run.

Claude Design ships a Web Component `<deck-stage>` that solves all three: inner canvas with `transform: scale()` fits any viewport; slides are `visibility: hidden` (not unmounted); a `slidechange` CustomEvent provides lifecycle. It also ships a `@page` print rule so `Cmd+P → Save as PDF` produces a clean one-page-per-slide output with zero tooling — a useful fallback alongside our Puppeteer script.

Our current system has clean cleavage: `window.__deck` is already a stable public API, `<deck-stage>` is already the wrapper element (just not yet a real custom element), `sync-client.js` is already a clean network layer. Adopting the Web Component is a surgical upgrade of one layer — not a system rewrite.

**Rollout:** hard cutover. Existing scaffolded decks are unaffected (they have frozen copies of `scripts/`); only new scaffolds pick up the change. No opt-in flag, no dual-engine diff-test scaffolding.

## Approach

Replace the imperative runtime with a two-file Web Component architecture.

### File changes

**Full rewrite — `default/skills/deck/scripts/deck-stage.js` (~500 lines)**

Adopt Claude Design's pattern, adapted for our constraints:

- `customElements.define('deck-stage', class extends HTMLElement)` with shadow DOM + `<slot>`.
- Inner `.canvas` at design size (1920×1080 from `width`/`height` attributes); outer container uses `transform: scale(s)` to fit viewport, letterboxed.
- Slides are slotted light-DOM children. `::slotted(*)` uses `position: absolute !important; inset: 0 !important; visibility: hidden; opacity: 0` — verified no `display` override in the Claude Design source, so our `.slide { display: flex; flex-direction: column }` survives intact.
- Active slide gets `data-deck-active` attribute (visibility/opacity toggled via CSS).
- **Export-mode fallback.** When `noscale` attribute is set AND `body.exporting` class is set, `::slotted` rules switch to `display: none` on inactive slides. Matches today's Puppeteer capture model — avoids sub-pixel drift and page-count confusion in `page.pdf({pageRanges: '1'})`.
- Dispatches `slidechange` CustomEvent: `{index, previousIndex, total, slide, previousSlide, reason}` — bubbles, composes out of shadow DOM.
- Injects `@page { size: 1920px 1080px; margin: 0 }` into `document.head` (shadow DOM can't host `@page`). `@media print` un-stacks slides for native `Cmd+P → Save as PDF`.
- Keyboard (component-owned): ←, →, PgUp, PgDn, Space, Home, End, 0–9. **Does NOT handle R** (reserved for presenter timer reset).
- Public instance methods: `goto(i)`, `next()`, `prev()`, `reset()`, `get index`, `get length`.
- Mobile tap zones (left/right thirds) via `@media (hover: hover) and (pointer: fine) { display: none }` guard.
- `noscale` attribute disables the scale transform (Puppeteer export mode).
- **Pure engine.** No Lerian branding, no `window.__deck`, no F/S/G/B keys, no blank overlay, no notes panel, no hash sync, no sync integration, no speaker-notes reading, no stagger animation, no localStorage. All that lives in the controller.

**New file — `default/skills/deck/scripts/deck-controller.js` (~180 lines)**

All Lerian-specific behavior. Waits for `<deck-stage>` to upgrade, then attaches.

- **Public API:** `window.__deck = {goto, next, prev, total, current, blank}` — backed by the Web Component instance + internal blank state. Preserves Puppeteer contract exactly.
- **Init sequence (race-free):**
  ```
  customElements.whenDefined('deck-stage')
    → stage = document.querySelector('deck-stage')
    → read stage.length, stage.index synchronously
    → fill pagination (.page-num / .page-total in paginated slides)
    → if ?export=true: body.classList.add('exporting'); stage.setAttribute('noscale', '')
    → if hash #slide=N and N ≠ stage.index: stage.goto(N - 1)
    → subscribe to 'slidechange'
    → connect sync (unless export mode)
  ```
- **Hash sync:** on `slidechange`, `history.replaceState(null, '', '#slide=' + (idx + 1))` unless `body.exporting`. Hash is primary; no localStorage (keeps presenter iframes deterministic — they pass `?export=true#slide=N`).
- **Keyboard (controller-owned):** F (fullscreen), S (notes panel toggle), G (goto prompt), B (blank toggle), R (no-op — reserved for presenter). Guards `INPUT|TEXTAREA|SELECT|[contenteditable]`.
- **Blank overlay:** creates `#deck-blank-overlay` on `document.body` — NOT inside shadow root (must escape scale transform).
- **Speaker-notes panel:** reads `<script type="application/json" id="speaker-notes">`, validates length matches `stage.length` (warn on mismatch), renders panel on S key, updates content on `slidechange`. Panel lives on `document.body`.
- **Stagger animation:** on `slidechange`, add `.slide-enter` to `e.detail.slide`, set `animationDelay: i * 80ms` on direct children, remove class after animation. Skipped when `body.exporting`.
- **Sync bridge:**
  - On load (non-export): `DeckSync.connect('/ws', {onOpen, onNav, onBlank, onState, onReload})`.
  - `onOpen` → `sync.send({type: 'hello', total: stage.length})`; record `lastHelloTotal`.
  - `onNav` → `suppressSend = true; stage.goto(msg.slide); suppressSend = false`.
  - `onBlank` → apply blank state, no echo.
  - `onState` → apply slide + blank + total.
  - `onReload` → `location.reload()`.
  - On `slidechange` (not `reason: 'init'`, not suppressed): `sync.send({type: 'nav', slide, total})`.
  - On blank toggle (non-remote): `sync.send({type: 'blank', on})`.
  - **Total re-announce:** on `slidechange` if `stage.length !== lastHelloTotal`, resend hello (handles author adds/removes slides + hot reload).

**Changed — `default/skills/deck/templates/deck.html`**

- `<deck-stage width="1920" height="1080">` — explicit attributes (component reads them).
- Script load order below `</deck-stage>`:
  ```html
  <script src="/assets/sync-client.js"></script>
  <script src="/assets/deck-stage.js"></script>
  <script src="/assets/deck-controller.js"></script>
  ```
- Remove any author-level `@media print { section { page-break-after: always } }` — the component now owns print rules.
- No changes to slide structure, speaker-notes embedding, or design tokens.

**Changed — `default/skills/deck/scripts/export-pdf.mjs`**

Minimal surgical edit: before the slide loop, belt-and-suspenders set of `noscale` + `body.exporting`:
```js
await page.evaluate(() => {
  document.querySelector('deck-stage')?.setAttribute('noscale', '');
  document.body.classList.add('exporting');
});
```
Controller sets these when it detects `?export=true`, but the explicit set guards against any upgrade-order race. `window.__deck` contract unchanged. Puppeteer launch flags, font-ready per-slide await, pdf-lib merge all unchanged.

**Changed — `default/skills/deck/scripts/dev-server.mjs`**

Verify watched paths include `deck-controller.js`. If chokidar globs `assets/` or `scripts/`, no change needed — confirm with a read.

**Unchanged**

- `scripts/sync-client.js` — no edits.
- `scripts/presenter-view.js` — no edits. Works via WebSocket; the iframe 400%/scale(0.25) hack stays for this migration and can be simplified in a follow-up.
- `scripts/remote-control.js` — no edits (talks to server only).
- `templates/presenter.html`, `templates/remote.html` — no edits.

**Reference documentation updates**

- `references/export.md` — document two export paths: `pnpm export` (Puppeteer, scripted/CI) vs. `Cmd+P → Save as PDF` (browser-native). Note the `@page` rule and `noscale` attribute.
- `references/server.md` — note the new script load order.
- `references/layout-rules.md` — add section: slides are absolute-stacked, not document-flow. `position: fixed` inside a slide is broken by the scale transform's containing block — author overlays must live on `document.body` (already the convention).
- `SKILL.md` — one-line in "What this skill provides" mentioning auto-scaling + browser-native PDF export.

### Critical files to read before implementation

- `default/skills/deck/scripts/deck-stage.js` — current imperative runtime (preserve exact behaviors).
- `default/skills/deck/scripts/sync-client.js` — sync protocol controller must speak.
- `default/skills/deck/scripts/export-pdf.mjs` — export contract (`window.__deck.*`, `?export=true`, font-ready) controller + component must honor.
- `default/skills/deck/templates/deck.html` — speaker-notes embedding, script load order.
- `default/skills/deck/scripts/presenter-view.js` — must not break; verify iframe thumbnails still work end-to-end.

### Existing utilities to reuse (port verbatim)

- `window.DeckSync.connect(url, handlers)` — wire protocol + reconnect backoff + export-mode stub. Untouched.
- Keyboard shortcut input-guard (`INPUT|TEXTAREA|SELECT|[contenteditable]`) — port from `deck-stage.js:193`.
- `#slide=N` hash parse/write — port from `deck-stage.js:88-94`.
- `applyStagger` logic (80ms per child) — port from existing stagger function.
- Blank overlay DOM creation (`#deck-blank-overlay`, z-index layering) — port from `deck-stage.js:124`.
- Notes panel DOM creation (`#deck-notes-panel`) — port from `deck-stage.js:163-168`.
- `helloTotal` re-announce guard — port from `deck-stage.js:14, 41-43`.

## Verification

End-to-end checks (all must pass before merge):

1. **Scaffold:** `pnpm install && pnpm dev` → open `http://localhost:7007`. Deck renders at viewport size, letterboxed.
2. **Auto-scale:** resize window to 1440×810, 1280×720, 2560×1440. Deck fits each viewport. No horizontal scroll. Text stays crisp.
3. **Keyboard:** ←, →, Space, Home, End, 0–9, R, F, S, G, B all work as documented. No double-fires.
4. **Hash sync:** nav to slide 5 → copy URL (`#slide=5`) → new tab → lands on slide 5.
5. **Presenter:** open `/presenter` in second tab. Main deck nav reflects in presenter. Thumbnails show current + next. Timer resets on R.
6. **Remote:** open `/remote` on phone. Prev/Next/Blank/Goto/First/Last all work. Slide count displays correctly.
7. **Puppeteer export:** `pnpm export`. `deck.pdf` has one slide per page at 1920×1080. Page count = slide count. Visual spot-check slides 1, 5, 10 vs. live deck at 100% zoom.
8. **Browser print:** `Cmd+P → Save as PDF`. Same one-slide-per-page output. Same visual check as (7).
9. **Slide state preservation (marquee):** author a `<video autoplay loop muted>` on a slide. Play. Nav away. Nav back. Video timestamp > 0 (not restarted).
10. **`slidechange` event:** `document.querySelector('deck-stage').addEventListener('slidechange', e => console.log(e.detail.reason))`. Nav via keyboard / tap zones / remote / API. Verify each `reason` value fires (`keyboard`, `click`, `tap`, `api`).
11. **Hot reload:** save `deck.html`. Deck reloads. Controller re-attaches. Remote still shows correct slide count.
12. **Add slide + reload:** author adds a new `<section>` + updates speaker notes. Hot reload. Remote shows new total (re-announce hello worked).

**Gate conditions:**
- Regression on (9) is the marquee win lost — blocker.
- Regression on (7) breaks CI/scripted export — blocker.
- Regression on (5) or (6) breaks the presenter/remote protocol — blocker.
- Regressions on (3) are expected for F/S/G/B during dev; must be clean at merge.
