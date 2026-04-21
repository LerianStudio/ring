# Dev Server, Presenter View, and Remote Control

The deck runtime ships three surfaces served by one small Express + WebSocket server:

- **Deck** — `/` — the main projected screen.
- **Presenter** — `/presenter` — second screen with slide thumbnails, current/next preview, speaker notes, timer.
- **Remote** — `/remote` — phone-friendly controller to advance slides, go back, blank the screen.

All three are coordinated by a single WebSocket channel.

## Express Routes

```javascript
import express from 'express';
import path from 'path';

const app = express();
const root = path.resolve('.');

app.get('/',           (req, res) => res.sendFile(path.join(root, 'deck.html')));
app.get('/deck.html',  (req, res) => res.sendFile(path.join(root, 'deck.html')));
app.get('/presenter',  (req, res) => res.sendFile(path.join(root, 'presenter.html')));
app.get('/remote',     (req, res) => res.sendFile(path.join(root, 'remote.html')));
app.use('/assets',     express.static(path.join(root, 'assets')));
```

| Route | Serves | Notes |
| --- | --- | --- |
| `GET /` | `deck.html` | Main canvas |
| `GET /deck.html` | `deck.html` | Same file — presenter view fetches this to extract speaker notes (see `speaker-notes.md`) |
| `GET /presenter` | `presenter.html` | Second-screen view |
| `GET /remote` | `remote.html` | Phone-friendly controller |
| `GET /assets/*` | static files from `./assets/` | Wordmark SVG, deck.js, fonts (if self-hosted) |

**Why `/deck.html` is aliased:** the presenter view fetches the deck HTML as plain text to regex-extract the speaker-notes JSON block. Serving it as a static file at a predictable URL is simpler than exposing a separate `/api/notes` endpoint. See [`speaker-notes.md`](speaker-notes.md) for the extraction contract (including the `</script>` substring ban in note strings).

## Dev-server endpoints

The complete route surface area exposed by `scripts/dev-server.mjs`:

| Route | Method | Serves | Notes |
| --- | --- | --- | --- |
| `/` | GET | `deck.html` | Main canvas |
| `/presenter` | GET | `presenter.html` | Second-screen view |
| `/remote` | GET | `remote.html` | Phone-friendly controller |
| `/health` | GET | `{ok:true}` JSON | Liveness probe for the toolbar + start script |
| `/lan-url` | GET | `{url:"http://IP:PORT/remote"}` | LAN URL surfaced by the toolbar's Remote modal |
| `/assets/*` | GET | static files from `./assets/` | No caching headers in dev |
| `/feedback` | POST | appends to `./feedback.jsonl` | Body: `{slideIndex:int, slideLabel:string, text:string}`. Returns `{ok:true}` |
| `/export/pdf` | POST | `application/pdf` stream | Spawns `scripts/export-pdf.mjs` with `SKIP_DEV_SERVER=true`, streams the generated PDF back. Serialized — returns 429 if another export is in flight |
| `/export/pptx` | POST | `application/vnd.openxmlformats-officedocument.presentationml.presentation` stream | Same pattern via `scripts/export-pptx.mjs` |

The `/export/*` endpoints exist so the toolbar PDF/PPTX buttons can trigger an export without the user dropping to a terminal. They're serialized behind a single mutex — a second request while one is running gets `HTTP 429` rather than spawning a parallel Puppeteer.

## Auto-open browser

On `server.listen()`, the dev-server opens `http://localhost:${PORT}` in the user's default browser via the `open` npm package. Suppress with `AUTO_OPEN=false` when you're iterating quickly or running on a headless machine. This keeps onboarding frictionless for less-technical users running `npm start` — the deck appears without them looking up the URL.

## `SKIP_DEV_SERVER` env convention

`scripts/export-pdf.mjs` and `scripts/export-pptx.mjs` both spin up a dev-server if one isn't already running. When the dev-server invokes them via `POST /export/*`, it sets `SKIP_DEV_SERVER=true` so the child process reuses the running server instead of trying to bind the same port. Without this flag the export would fail with `EADDRINUSE`.

The convention is one-directional: only the `/export/*` handler sets it. Authors running `pnpm export` or `pnpm export:pptx` from a terminal never touch this env — the script starts its own dev-server if needed and cleans up on exit.

## Deck script load order

`deck.html` loads three scripts in order:

```html
<script src="/assets/sync-client.js"></script>
<script src="/assets/deck-stage.js"></script>
<script src="/assets/deck-controller.js"></script>
```

- `sync-client.js` exports `window.DeckSync` — WebSocket client used by the controller to bridge `nav`/`blank`/`state`/`reload` to the server.
- `deck-stage.js` defines the `<deck-stage>` custom element: auto-scaling canvas via `transform: scale()`, visibility-based slide switching, `slidechange` CustomEvent, component-owned keyboard shortcuts (arrows, space, home, end, pgup, pgdn, 0–9), and injected `@page` + shadow-DOM `@media print` rules.
- `deck-controller.js` gates on `customElements.whenDefined('deck-stage')` and attaches Lerian behaviors: the public `window.__deck` API, hash sync, `#deck-blank-overlay` on `document.body`, notes panel, stagger, sync bridge, F/S/G/B/R (no-op) keys, Escape, `postMessage` listener, and speaker-notes parsing.

Dev-server's chokidar already watches `assets/` as a directory, so `deck-controller.js` is hot-reloaded automatically with no server change.

## WebSocket Endpoint

Single endpoint: `/ws`. Handled by the `ws` package on the same HTTP server.

```javascript
import { WebSocketServer } from 'ws';
const wss = new WebSocketServer({ server, path: '/ws' });
```

## File Watching (Chokidar)

```javascript
import chokidar from 'chokidar';

chokidar.watch(
  ['deck.html', 'presenter.html', 'remote.html', 'assets/**', 'scripts/**'],
  { ignoreInitial: true }
).on('all', (event, filePath) => {
  console.log(`[watch] ${event} ${filePath} — broadcasting reload`);
  broadcast({ type: 'reload' });
});
```

- Watches: `deck.html`, `presenter.html`, `remote.html`, `assets/**`, `scripts/**`.
- Ignores: `node_modules/**`, `deck.pdf`, `.git/**` (chokidar's defaults cover most).
- On any change, broadcast `{ type: "reload" }` to all WebSocket clients. Clients hard-reload the page on receipt.

## WebSocket Message Schema

**Five message types**, all JSON-encoded strings. No versioning in v1 — if the schema evolves, bump to v2 explicitly. Two directions: client → server (`hello`, `nav`, `blank`) and server → client (`state`, `nav`, `blank`, `reload`). `nav` and `blank` travel both directions — the server rebroadcasts what clients send.

### `hello` — announce slide count (client → server)

Direction: `deck-stage.js` → server, once per WebSocket `open`.

```json
{ "type": "hello", "total": 17 }
```

- `total`: positive integer, the count of `<deck-stage> > <section>` elements in `deck.html`.
- Only the deck client knows the authoritative slide count — presenter and remote learn it from the server. `hello` is how the server learns it too.
- On receipt, server stores `state.total` AND rebroadcasts `{ type: 'state', … }` so presenter/remote update their `N / M` pagination.
- `deck-stage.js` also re-sends `hello` when its slide count changes across a hot-reload (see `fillPagination`).

### `nav` — navigate to a slide

Direction: any client → server → broadcast to all clients.

```json
// client → server
{ "type": "nav", "slide": 4, "total": 17 }

// server → all clients (rebroadcast, clamped)
{ "type": "nav", "slide": 4, "total": 17 }
```

- `slide`: zero-indexed section position.
- `total` (optional, client → server): deck-stage piggybacks current slide count as belt-and-suspenders re-assertion. Server updates `state.total` if the payload is a positive integer.
- Server clamps `slide` to `[0, total - 1]` when `total` is known; when `total === null` (no `hello` yet), only clamps below 0.
- Emitted by deck on keyboard nav, presenter on click, remote on next/prev.
- Rebroadcast to every connected client with the (possibly clamped) slide and the current `state.total` (may be `null`).

### `blank` — toggle blank screen

Direction: any client → server → broadcast to all clients.

```json
{ "type": "blank", "on": true }
```

- `on`: `true` = blank the main canvas to solid black; `false` = restore.
- Emitted by remote "Blank" button or `B` keypress on deck.
- Useful when the speaker wants the audience to look at them, not the slide.

### `state` — hydrate / rebroadcast current state

Direction: server → clients.

```json
{ "type": "state", "slide": 4, "blank": false, "total": 17 }
```

- Sent **once** when a WebSocket client connects, carrying the authoritative `{ slide, blank, total }`.
- Sent **again** to everyone after the server processes a `hello` — so presenter/remote learn `total` the moment deck-stage announces it.
- `total` MAY be `null` until a deck client has sent `hello`. Clients MUST treat `total === null` as "unknown" (render `?` or `–` for pagination; dim "next" controls in an ambiguous end-of-deck state).

### `reload` — file changed

Direction: server → all clients.

```json
{ "type": "reload" }
```

- Triggered by chokidar on any watched file change (debounced ~50ms to collapse editor-save bursts).
- Clients MUST hard-reload the page on receipt.

## Server State

The server holds minimal in-memory state:

```javascript
const state = {
  slide: 0,       // current slide index
  blank: false,   // blank-on-main-canvas flag
  total: null,    // null until a deck-stage client announces via hello
};
```

On `hello`, update `state.total` and rebroadcast `state` to all clients. On `nav` or `blank`, update state THEN broadcast. On new-client connect, send `state` with the current values (including `total`, possibly `null`). No persistence — restart resets to slide 0 and total `null`.

## WebSocket Handshake Policy

`verifyClient` enforces a minimal CSWSH (cross-site WebSocket hijacking) defense. The allowed origin set is computed once at boot and checked on every handshake:

| Origin header | Behavior |
| --- | --- |
| `http://localhost:{PORT}` | Accept |
| `http://127.0.0.1:{PORT}` | Accept |
| `http://{LAN-IP}:{PORT}` (detected via `detectLanIp`) | Accept |
| Any other origin | Reject (handshake returns 401) |
| No `Origin` header (Puppeteer, `curl`, Node scripts) | Accept |

Puppeteer's embedded Chromium issues same-origin connections but non-browser Node WebSocket clients typically omit `Origin` — we accept those rather than force export scripts to synthesize headers. This keeps the export path working while blocking drive-by JavaScript in a random tab on the same machine from driving your deck.

## Per-Connection Rate Limit (v1 backstop)

Each WebSocket connection has a token bucket: capacity **10 tokens**, refill **10 tokens/sec**. Every inbound message consumes one token; when the bucket is empty, messages are **dropped silently** (the connection is NOT closed). This is an intentional v1 backstop against a runaway remote/presenter/deck client spamming `nav`, not an auth mechanism.

- Silent drop, not disconnect — avoids tearing down a slow client during a transient burst.
- No token refund on rejection.
- Bucket is per-socket and resets on reconnect.

If a legitimate workflow trips the limit (e.g., scripted demos), raise `BUCKET_CAPACITY` or `BUCKET_REFILL_PER_MS` in `scripts/dev-server.mjs`; don't remove the limiter.

## Trust Model — Local Network Only

**REQUIRED: document this in the server startup log.**

The server has **no authentication**. Anyone on the same LAN can connect to `/ws` and send `nav` or `blank` messages. This is acceptable because:

- Decks are ephemeral — run during a single presentation, then stopped.
- The attack surface is the people physically near the presenter.
- Adding auth adds friction (pairing phone-remote requires typing a code) for a benefit the threat model doesn't justify.

**CANNOT deploy this server to the public internet.** It is strictly a localhost + LAN tool. Any CI that spins up the server MUST bind to `127.0.0.1` only, not `0.0.0.0`.

**Document this explicitly** in the startup banner:

```
Ring Deck Server
  deck:      http://localhost:7007/
  presenter: http://localhost:7007/presenter
  remote:    http://192.168.1.42:7007/remote
  ⚠ local network only — no authentication
```

## Port & Host Binding

```javascript
const PORT = parseInt(process.env.PORT || '7007', 10);
const HOST = process.env.HOST || '0.0.0.0';
server.listen(PORT, HOST);
```

| Setting | Default | Override | Reason |
| --- | --- | --- | --- |
| Port | `7007` | `PORT=<n>` env | Unused by most dev tooling; memorable. |
| Host | `0.0.0.0` | `HOST=<addr>` env | Binds all interfaces so phone on LAN can reach `/remote`. |

**Security implication of `0.0.0.0`:** anyone on the LAN reaches the server. Accept the implication (see Trust Model) or set `HOST=127.0.0.1` and give up phone-remote.

## Phone Remote URL

The phone connects to `http://<machine-ip>:7007/remote`. The startup banner auto-detects and prints the LAN IP so users don't have to look it up:

```javascript
import os from 'os';

const TUNNEL_IFACE_RE = /^(utun|ppp|tun|wg)\d*/i;

function detectLanIp() {
  const candidates = [];
  for (const [name, list] of Object.entries(os.networkInterfaces())) {
    if (!list) continue;
    for (const iface of list) {
      if (iface.family !== 'IPv4' || iface.internal) continue;
      candidates.push({ name, address: iface.address });
    }
  }
  // Prefer non-tunnel interfaces so the phone on the same Wi-Fi can reach them.
  const nonTunnel = candidates.find((c) => !TUNNEL_IFACE_RE.test(c.name));
  if (nonTunnel) return nonTunnel.address;
  if (candidates.length > 0) return candidates[0].address;
  return null;
}
```

If the machine has no LAN IP, fall back to `localhost` — the remote URL won't work from another device, but the deck still runs locally.

### Troubleshooting: Phone can't reach the remote URL

1. **Tunnel interfaces are filtered.** `detectLanIp` ignores `utun*`, `ppp*`, `tun*`, `wg*` interfaces because VPN tunnels (Cisco AnyConnect, corporate VPNs) typically aren't reachable from a phone on the same Wi-Fi. The printed IP prefers `en0`/`eth0`-style physical interfaces.
2. **VPN clients that don't match the filter can still win.** Tailscale (`tailscale0`), Cloudflare WARP, and ZeroTier may expose an IPv4 not covered by the tunnel regex. If the printed IP looks like Tailscale's `100.x.x.x` range or otherwise isn't on your Wi-Fi subnet, disconnect the VPN and restart the server, or apply a manual override:

    ```bash
    # macOS
    ipconfig getifaddr en0
    # Linux
    hostname -I | awk '{print $1}'

    # Then force the bind and use that IP on the phone:
    HOST=0.0.0.0 PORT=7007 npm run dev
    ```

3. **Firewall on the host machine.** macOS (System Settings → Network → Firewall) and Windows Defender may block inbound connections on port 7007. Allow the Node process or open the port for local subnets.
4. **Phone on a different SSID / guest network.** Many home routers isolate guest Wi-Fi from the primary LAN. Join the same SSID as the host machine before troubleshooting routing.

## V2 Candidate — Rotating PIN Auth

Not in v1. Recorded here so the decision isn't relitigated every release.

- Server generates a short-lived PIN (4–6 digits, rotates every 10 minutes).
- Main screen displays the PIN as a small chrome element.
- Phone-remote must enter the PIN before its WebSocket `nav`/`blank` messages are accepted.
- Deck and presenter clients (connecting over localhost) bypass the check.

Adds friction; defeats drive-by LAN shenanigans. Revisit if any user reports an incident.

## Startup Checklist

```
Before shipping the server script:

[ ] 1. Routes for /, /deck.html, /presenter, /remote, /assets/* all wired?
[ ] 2. WebSocket endpoint at /ws with verifyClient origin allow-list?
[ ] 3. Chokidar watches deck.html, presenter.html, remote.html, assets/**, scripts/** (with reload debounce)?
[ ] 4. Five WS message types implemented (hello, nav, blank, state, reload) with the rebroadcast-after-hello flow?
[ ] 5. state message sent on new-client connect AND after each hello (so presenter/remote learn total)?
[ ] 6. Per-connection token bucket (10 msg/s, capacity 10, silent drop) applied to inbound messages?
[ ] 7. Startup banner prints deck/presenter/remote URLs with LAN IP auto-detected (tunnels filtered)?
[ ] 8. Startup banner includes "local network only — no authentication" warning?
[ ] 9. PORT and HOST env overrides respected?

If any checkbox is no → The server is incomplete. Fix before shipping.
```
