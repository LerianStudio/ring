# Speaker Notes

Speaker notes are embedded in the deck HTML as a single JSON block and surfaced to the presenter view via a regex extraction. This document specifies the schema, the embedding pattern, and the writing voice.

## JSON Schema

The speaker-notes block is a **flat array of strings**. Each array element is the full speaker copy for one slide. Array index corresponds to slide order: `notes[0]` is the cover slide, `notes[1]` is slide 2, and so on.

```json
[
  "<speaker copy for slide 1>",
  "<speaker copy for slide 2>",
  "<speaker copy for slide 3>"
]
```

**Array length SHOULD match `<section>` count inside `<deck-stage>`.** The runtime warns in the console (`[deck-stage] Speaker-notes length N != slide count M`) if the counts differ, but it does NOT throw — missing indices render as `(no notes)` in the presenter view and the deck keeps working. Treat the warning as a soft gate: match exactly for production decks; during authoring it's normal to be one off.

### Embedded Entry Shape

- **Type:** string (not object).
- **Delimiter within a string:** `\n\n` for paragraph breaks. Single `\n` breaks render as spaces in presenter view.
- **Content:** plain prose. No Markdown. No HTML. No bullets.
- **Escape:** standard JSON string escaping (`\"`, `\\`, `\n`).
- **FORBIDDEN substring:** `</script>` anywhere inside a note string. The presenter extraction uses a regex that terminates on the first `</script>` — an embedded occurrence closes the inline JSON block prematurely and corrupts every note after it. `presenter-view.js` strips HTML comments before `JSON.parse`, but the `</script>` boundary is unforgeable. If you must reference the tag in speaker copy, break it: `"</scr" + "ipt>"` in source, or just write "script tag" in prose.

## Embedding Pattern

The block lives in `<head>` of `deck.html`:

```html
<head>
  <meta charset="utf-8" />
  <title>… deck title …</title>
  …

  <script type="application/json" id="speaker-notes">
  [
    "Welcome everyone. This is our first formal board meeting. …",
    "Quick map of where we're going. Five acts. …",
    …
  ]
  </script>

  …
</head>
```

**REQUIRED attributes on the `<script>` tag:**

| Attribute | Value | Why |
| --- | --- | --- |
| `type` | `"application/json"` | Prevents the browser from executing the block as script |
| `id` | `"speaker-notes"` | Stable selector for the presenter-view fetch |

## Presenter View Extraction

Presenter view (opened on the second screen) fetches `/deck.html` and regex-extracts the JSON block — it does NOT iframe the deck, because that would run the deck's own WebSocket client and double-subscribe.

```javascript
// In presenter.html runtime:
async function loadNotes() {
  const res = await fetch('/deck.html');
  const html = await res.text();
  const match = html.match(
    /<script type="application\/json" id="speaker-notes">([\s\S]*?)<\/script>/
  );
  if (!match) throw new Error('speaker-notes block not found in /deck.html');
  return JSON.parse(match[1]);
}
```

**Why regex, not DOMParser:** parsing 1920×1080 deck HTML in a second tab wastes memory and re-executes inline scripts. The regex is deterministic because the block has fixed attributes.

## Writing Voice

Speaker notes are **the script the presenter reads**, not a slide summary. Tone is first-person presenter voice, direct, concrete, ready to speak aloud.

### Rules

| Rule | Reason |
| --- | --- |
| Speaking voice, not bullets | The presenter reads this aloud. Fragments break cadence. |
| One paragraph per slide, `\n\n` separators between paragraphs if >1 | Presenter scans paragraph-by-paragraph during delivery. |
| Named concrete data first, abstractions second | "ARR is $4.2M" before "growth is strong" — the audience gets the fact before the gloss. |
| Target ~90–120 words per slide | ~30 seconds of speech at a conference pace. |
| Second-person tense for the audience; first-person for the speaker | "You'll see…" / "I want to flag…". Never third-person ("the presenter walks through"). |
| No self-reference to the slide | "Let me show you…" beats "On this slide…". The slide is the prop, not the subject. |

### Word Budget — Why 90–120

- Public-speaking cadence ≈ 130–150 words/minute.
- Slide-bound delivery ≈ 100–120 words/minute (pauses, gestures).
- 30 seconds per slide × 3 words/second ≈ 90 words as the lower floor.
- Above 120 words, the presenter reads instead of presents — hand the audience the deck and save 89 minutes.

## Gold-Standard Examples

Three entries from the reference deck (`lerian-ppt-example.html`) with commentary on why they work.

### Example 1 — Portfolio slide (index 2)

```text
Let me show you what's actually shipping. Six products in production — Midaz,
Matcher, Tracer, Flowker, Fetcher, Reporter — the full core-banking stack.
Underwriter is the seventh — credit decisioning — fully spec'd, build underway
in the repo today; that closes the loop for credit workflows. Plus six plugins
live today, including Pix Direto and TED Direto. The pipeline is the regulated
Brazilian stuff that takes time: Credit, Payments, BC Correios, SIMBA, BacenJud
Direto. The point of this slide: the 'you don't have product X' objection is
dead. We have the portfolio.
```

**Why it works:**
- Opens with "Let me show you" — presenter voice, active verb.
- Names every product concretely before stating the thesis.
- Ends with the takeaway ("the objection is dead") — the thing the audience should remember.
- 98 words — inside the target band.

### Example 2 — Q1 P&L (index 7)

```text
Q1 P&L. The number that will raise eyebrows is AI spend — three hundred fifteen
to four hundred forty thousand reais a month. That is deliberate. It's the bet
behind discussion number three. Runway is twenty months at gross burn,
thirty-two months net of revenue — comfortably long either way. One nuance
worth knowing: we bill day one — revenue equals cash, no grace period,
no deferred.
```

**Why it works:**
- Names the concrete number ("three hundred fifteen to four hundred forty thousand") before the abstraction ("deliberate").
- Cross-references the strategic discussion ("discussion number three") — gives the presenter a natural hand-off.
- Numbers are written out as words — MUST for anything the presenter says aloud. Digits interrupt reading flow.
- 72 words — short but complete. This is a factual slide; not every note needs 120 words.

### Example 3 — Discussion one (index 12)

```text
Discussion one. We've been calling it Vercel for financial services. Client
deploys our products plus their own apps on Lerian infrastructure — three
tiers, managed to SaaS. Seventy percent of new logos want this already. The
question isn't whether. It's timing, positioning, and whether we should
reframe the company around it. Where are we wrong?
```

**Why it works:**
- Immediately names the framing ("Vercel for financial services") before unpacking it.
- Ends with the board-facing question ("Where are we wrong?") — invites the debate the slide is built for.
- 60 words — low end of the range. A discussion-opener slide is a prompt, not a monologue; the actual content is the board response.

## Authoring Checklist

```
Before committing speaker-notes JSON:

[ ] 1. Array length matches <section> count inside <deck-stage>? (Soft gate — mismatch warns but doesn't throw; match for production.)
[ ] 2. Every string is speaking voice (first-person presenter, not slide summary)?
[ ] 3. Every slide has named data before abstraction?
[ ] 4. Numbers expected to be spoken aloud are written as words, not digits?
[ ] 5. Word count per slide is 60–120 (hit the target for content slides; shorter for discussion openers)?
[ ] 6. Zero "on this slide…" / "in this diagram…" self-references?
[ ] 7. Zero literal `</script>` substrings anywhere in any note (breaks inline-JSON extraction)?
[ ] 8. JSON parses cleanly (test with JSON.parse in browser console)?

If any checkbox is no → Rewrite the note. Speaker notes ship once; redoing live is expensive.
```
