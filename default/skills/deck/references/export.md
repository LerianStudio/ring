# PDF Export

PDF export converts the live deck to a paginated PDF at pixel-perfect 1920×1080. The export script drives a headless Chromium via Puppeteer, navigates through every slide, and appends each page to a combined document via `pdf-lib`.

Scope: **PDF (two paths) + PPTX (screenshots mode) in v1.** Editable PPTX — text + shapes mapped from CSS — remains deferred; see the PPTX footnote at the end for why.

## Toolbar

Every deck has a floating toolbar on the bottom-center: Tweak / Presenter / PDF / PPTX / Remote.

- **PDF and PPTX buttons** call the dev-server, which spawns the Puppeteer export and streams the result back for download. Takes 10-30s; the button shows a spinner while running.
- **Tweak** opens a feedback panel that writes to `feedback.jsonl` (see `references/server.md` for the `/feedback` endpoint). The author then tells Claude "check tweaks" to review the captured notes.
- **Presenter** opens `/presenter` in a new window.
- **Remote** shows the LAN URL in a modal so the speaker can load `/remote` on a phone.
- Toolbar auto-hides in fullscreen (presentation mode) and is never captured in exports (hidden when `body.exporting`).
- **Keyboard:** `T` toggles the tweak panel, `H` toggles toolbar visibility.

## Two export paths

Two routes to PDF, same 1920×1080 geometry:

- **Path A — `pnpm export` (Puppeteer, scripted/CI).** Driven by `scripts/export-pdf.mjs`: launches headless Chromium, per-slide navigation via `window.__deck.goto(n)`, awaits `document.fonts.ready` per slide, captures each slide with `page.pdf()`, merges via `pdf-lib`. Use this in CI, cron jobs, and anything non-interactive. Deterministic artifact — the exact bytes your dev loop produces.
- **Path B — `Cmd+P → Save as PDF` (browser-native).** Works because `<deck-stage>` injects `@page { size: 1920px 1080px; margin: 0 }` into `document.head` on upgrade, and its shadow-DOM `@media print` un-stacks slides into native print-page flow. Fastest route for ad-hoc exports. **Caveat:** browser rasterization can subtly differ from Puppeteer (font-hinting, subpixel AA). For a deterministic artifact that matches what ran in your dev loop, use Path A.
- **Path C — `pnpm export:pptx` (screenshots mode).** Driven by `scripts/export-pptx.mjs`: Puppeteer captures one PNG per slide at 1920×1080 full-bleed, then `pptxgenjs` assembles a `.pptx` with each PNG placed as a full-slide background and the matching speaker note attached via `addNotes()`. Produces `deck.pptx` in the project root. **Not editable in PowerPoint** — the slides are background images. Use when (a) the recipient requires a `.pptx` file, or (b) you need speaker notes embedded for handoff. If you want editable PowerPoint (text + shapes), export PDF + re-author — Ring doesn't support editable PPTX v1 (CSS layout doesn't map cleanly to PowerPoint shapes). `pnpm export:pptx:chrome` uses system Chrome; same fallback as PDF.

### The `noscale` attribute

`<deck-stage>` normally applies a `transform: scale()` to fit the canvas to the viewport. For Path A, that would distort Puppeteer's 1920×1080 capture. The controller sets `noscale` on `<deck-stage>` when it detects `?export=true`; `scripts/export-pdf.mjs` also sets it directly as belt-and-suspenders. With `noscale` present, the canvas renders at native 1920×1080 and Puppeteer captures a pixel-perfect frame.

## Entry Point

```bash
npm run export            # runs scripts/export.mjs
```

Prerequisites:

- Dev server MUST be running on `http://localhost:${PORT:-7007}`.
- All Google Fonts MUST load (confirmed by the font-ready await — see HARD GATE below).

Output: `./deck.pdf` in the project root. On success, the script prints the absolute path:

```
✓ Exported 25 slides → /Users/…/project/deck.pdf
```

## Launch Configuration

```javascript
import puppeteer from 'puppeteer';

const browser = await puppeteer.launch({
  headless: 'new',
  args: ['--no-sandbox', '--disable-dev-shm-usage'],
});

const page = await browser.newPage();
await page.setViewport({
  width: 1920,
  height: 1080,
  deviceScaleFactor: 1,
});
```

**Why these args:**

| Arg | Reason |
| --- | --- |
| `--no-sandbox` | Required for CI runners (Docker, GitHub Actions) where the user namespace is already restricted. |
| `--disable-dev-shm-usage` | `/dev/shm` is 64MB in many containers; Chromium falls over on 1920×1080 screenshots without this. |
| `deviceScaleFactor: 1` | MUST stay 1. Higher scales bloat the PDF and drift type rendering from the live deck. |

## Query-Param Trick

The export script navigates to `http://localhost:7007/?export=true`. The deck runtime respects this flag by:

- **Disabling the WebSocket client** — no live-reload race condition between chokidar and `page.pdf()`.
- **Disabling CSS animations/transitions** — avoids capturing mid-animation frames.
- **Exposing a stable `window.__deck` interface** — six methods, documented below.

### `window.__deck` — runtime contract

All six methods are public contract. Puppeteer uses `goto(n)` and `total()`; the remaining four support runtime/keyboard/remote integration and are safe to call from any client (presenter iframe, manual console debugging, post-message bridge).

| Method | Signature | Role |
| --- | --- | --- |
| `goto(n)` | `(n: integer) => Promise<void>` | Jumps to zero-based slide `n`. Resolves after the slide is painted (double-rAF in export mode). Primary Puppeteer contract. |
| `total()` | `() => integer` | Returns the slide count (`<deck-stage> > <section>` length). Primary Puppeteer contract. |
| `next()` | `() => Promise<void>` | Advances one slide. Used by keyboard nav, remote "Next". |
| `prev()` | `() => Promise<void>` | Steps back one slide. Used by keyboard nav, remote "Previous". |
| `current()` | `() => integer` | Returns the current zero-based slide index. Used by presenter view + remote to hydrate UI. |
| `blank(on)` | `(on: boolean) => void` | Toggles the blank overlay. Used by remote "Blank" button and `B` keypress. |

```javascript
// In assets/deck-stage.js:
const params = new URLSearchParams(location.search);
const exportMode = params.get('export') === 'true';

if (!exportMode) {
  connectWebSocket();
}

if (exportMode) {
  document.documentElement.style.setProperty('--anim-duration', '0s');
}

window.__deck = {
  goto:    (n)  => { /* switch to slide n, sync; returns Promise */ },
  next:    ()   => { /* goto(current + 1); returns Promise */ },
  prev:    ()   => { /* goto(current - 1); returns Promise */ },
  total:   ()   => document.querySelectorAll('deck-stage > section').length,
  current: ()   => /* zero-based index */,
  blank:   (on) => { /* toggle blank overlay */ },
};
```

The `?export=true` contract is MANDATORY. Deck runtimes MUST implement it; export scripts MUST set it. Runtime contract also includes a same-origin `postMessage` listener — parent frames can `iframe.contentWindow.postMessage({ type: 'nav', slide: N }, '*')` and deck-stage routes that to `gotoIndex(N, { silent: true })`. Cross-origin messages are ignored. This is how `presenter.html` drives its thumbnail iframes without WebSocket echo.

## Per-Slide Loop

```javascript
import { PDFDocument } from 'pdf-lib';

await page.goto('http://localhost:7007/?export=true', {
  waitUntil: 'networkidle0',
});
await page.evaluateHandle('document.fonts.ready');

const total = await page.evaluate(() => window.__deck.total());
const combined = await PDFDocument.create();

for (let i = 0; i < total; i++) {
  await page.evaluate((n) => window.__deck.goto(n), i);
  await page.evaluateHandle('document.fonts.ready');  // HARD GATE — see below

  const buffer = await page.pdf({
    width: '1920px',
    height: '1080px',
    printBackground: true,
    pageRanges: '1',
  });

  const slideDoc = await PDFDocument.load(buffer);
  const [copiedPage] = await combined.copyPages(slideDoc, [0]);
  combined.addPage(copiedPage);
}

const outBytes = await combined.save();
const outPath = path.resolve('./deck.pdf');
await fs.writeFile(outPath, outBytes);
console.log(`✓ Exported ${total} slides → ${outPath}`);

await browser.close();
```

## HARD GATE — Font-Ready Await

```javascript
await page.evaluateHandle('document.fonts.ready');
```

**MUST call this before every `page.pdf()`**, not just once after initial load.

**Why:** Google Fonts load async. On the first slide, `document.fonts.ready` resolves after Poppins + IBM Plex Serif + JetBrains Mono have arrived. On subsequent slides, a font file request can re-open if a new weight/style is needed (e.g., Poppins 700 on one slide only). Skipping the per-slide await on the suspicion "fonts already loaded" produces a PDF where one slide renders with system-font fallbacks — the kind of bug nobody catches until the deck is on screen.

FORBIDDEN pattern:

```javascript
// WRONG — loads fonts once, then assumes.
await page.evaluateHandle('document.fonts.ready');
for (let i = 0; i < total; i++) {
  await page.evaluate((n) => window.__deck.goto(n), i);
  await page.pdf({ … });   // fonts may substitute mid-loop
}
```

REQUIRED pattern:

```javascript
for (let i = 0; i < total; i++) {
  await page.evaluate((n) => window.__deck.goto(n), i);
  await page.evaluateHandle('document.fonts.ready');   // every iteration
  await page.pdf({ … });
}
```

## PDF Parameters

| Parameter | Value | Why |
| --- | --- | --- |
| `width` | `'1920px'` | MUST match viewport. String-with-unit, not number. |
| `height` | `'1080px'` | MUST match viewport. |
| `printBackground: true` | REQUIRED — otherwise `.slide.dark` and `.slide.accent` render white. |
| `pageRanges: '1'` | Captures only the current slide. Prevents Chromium's auto-paginator from inserting extra blanks on tall content. |
| `preferCSSPageSize` | NOT used. Explicit width/height wins. |
| `margin` | omitted (defaults to zero) |

## Output Location

Default: `./deck.pdf` in the project root. MUST print the absolute path on success so users can pipe it to `open` / `xdg-open` / their file manager.

Override via env or CLI (Wave 2 implementation detail):

```bash
OUT=./handouts/board-v2.pdf npm run export
# or
npm run export -- --out ./handouts/board-v2.pdf
```

## Puppeteer Weight (footnote)

Puppeteer bundles its own Chromium (~200MB post-install). This is the default in v1 because it gives zero-config UX — `npm install && npm run export` works without the user having Chrome installed.

**Alternative:** `puppeteer-core` + `channel: 'chrome'` uses the system Chrome (~50MB install). Revisit if install weight becomes a complaint. Swapping is a two-line change:

```javascript
// Before
import puppeteer from 'puppeteer';
const browser = await puppeteer.launch({ … });

// After
import puppeteer from 'puppeteer-core';
const browser = await puppeteer.launch({ channel: 'chrome', … });
```

## PPTX Scope (footnote)

**v1 ships screenshots-mode PPTX only** (Path C). Each slide is a full-bleed PNG with the matching speaker note attached via `pptxgenjs` `addNotes()`. The deliverable opens in PowerPoint and plays correctly; the content is not editable inside PowerPoint because the slides are images, not native shapes.

**Editable PPTX remains deferred.** HTML → native-PowerPoint shapes is lossy for:

- **Absolute positioning** — `position: absolute` and nested flex layouts don't map to PowerPoint's slide-layout primitives.
- **Custom grid layouts** — CSS grid with `align-items: stretch` becomes a manual table rebuild.
- **CSS-based charts** — any chart drawn in divs or SVG becomes a flattened image, losing the native PowerPoint chart editability users expect.

A v2 graceful-degradation path could map:

- KPI tiles → text boxes.
- 2×2 matrix → scatter chart.
- Tables → native PowerPoint tables.
- Everything else → flattened PNG per slide (which is what v1 already does for every slide).

Until then, if the user asks for an editable PPTX, the correct answer is "screenshots-mode PPTX now, editable PPTX when the content-shape mapping lands."

## Export Checklist

```
Before shipping the export script:

[ ] 1. Launch args include --no-sandbox and --disable-dev-shm-usage?
[ ] 2. Viewport is exactly 1920×1080 with deviceScaleFactor:1?
[ ] 3. Navigation URL includes ?export=true?
[ ] 4. document.fonts.ready awaited BEFORE every page.pdf() (not just once)?
[ ] 5. page.pdf() uses width:'1920px', height:'1080px', printBackground:true, pageRanges:'1'?
[ ] 6. Combined PDF uses pdf-lib copyPages — no per-slide separate files?
[ ] 7. Output path is printed absolute on success?
[ ] 8. Browser closed in a finally block so crashes don't leak Chromium?

If any checkbox is no → Export is incomplete. Fix before shipping.
```
