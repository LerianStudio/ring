---
name: ring:reviewing-operational-risk
description: "Reviewing a Go/TS service's operational risk by mapping integration failure points (external HTTP calls, queue consumers, outbound webhooks), simulating stuck intermediate states for each entity in a flow, and classifying each scenario into tiers — then emitting operational runbooks (Tier 2) or gap specs (Tier 3). Two entry modes: explore an existing codebase, or read a dev-cycle plan.md and epic artifacts. Use before production hardening, incident retros, or at dev-cycle end. Skip for prototypes, pure libraries, or when no integration boundaries exist."
---

# Operational Risk Review

## When to use
- Preparing a service for production and want to know what breaks when a flow gets stuck
- After a dev-cycle: pressure-test the newly built flows for recovery gaps
- Incident retro: formalize which failure modes have a rescue path and which do not
- You need operational runbooks or a backlog of "missing rescue mechanism" gap specs

## Skip when
- Prototype / throwaway PoC not heading to production
- Pure library or SDK with no integration boundaries (no external calls, queues, or webhooks)
- Single-question check (use a targeted read instead of the full review)

## Related
**Complementary:** ring:auditing-production-readiness (broad readiness scoring), ring:mapping-service-resources (resource inventory), ring:running-dev-cycle (optional end-of-cycle hook)

## What this produces
For every failure scenario, a **tier** and an actionable artifact:

| Tier | Meaning | Output |
|------|---------|--------|
| **Tier 1** | The app resolves it itself — automatic retry, compensation, TTL/expiry, DLQ replay | Note only (documented as self-healing) |
| **Tier 2** | An **external trigger exists** that unblocks it — an API call, an endpoint, a Console/UI action | **Operational runbook** with concrete steps |
| **Tier 3** | **Gap** — no rescue path exists short of direct DB intervention | **Gap spec** (what's missing, who can act today, what should exist) |

## Audience
The output is always written **for the developer running the skill** (tech lead or engineer). Runbooks assume operator access; gap specs assume backlog ownership.

---

## How this skill runs: a hybrid (mechanical + judgement) flow

The review is split into two phases so the deterministic work is not left to the LLM:

**Phase 1 — mechanical (`scan-integration-points.mjs`, run by the dev):**
A zero-dependency Node.js script traverses the target repo and finds integration
boundaries (external HTTP calls, queue consumers, event publishers, outbound
webhooks). For each point it heuristically records whether retry, DLQ, timeout,
rollback/compensation, and idempotency patterns appear nearby. It emits a
structured JSON report. It is generic: it runs on any Go or TypeScript/Node.js
Lerian repo. This phase is repeatable and produces the same map every time.

**Phase 2 — judgement (this agent, from here on):**
The agent takes the JSON as structured context, runs the confirmation dialogue,
simulates stuck states, classifies Tier 1/2/3, and writes runbooks (T2) and gap
specs (T3). This is the analysis that needs a human-in-the-loop and cannot be
reduced to regex.

> **The developer runs the `.mjs` first and pastes/attaches its JSON output to
> the agent before the dialogue begins.** In Mode A the agent uses that JSON as
> the boundary map instead of re-deriving it by hand. See **Step 1 (Mode A)**.

---

## Step 0: Determine entry mode

Ask the developer (or infer from context):

- **Mode A — Codebase explore:** review an existing service by scanning its integration boundaries.
- **Mode B — Plan context:** review flows just built in a dev-cycle by reading `plan.md` and the current cycle's epic artifacts, without exploring the whole repo.

If a `plan.md` (ring:writing-plans format) with an active cycle is present and the developer wants to review *what was just built*, prefer **Mode B**. Otherwise use **Mode A**.

---

## Step 1 (Mode A): Map integration boundaries — run the scanner first

The boundary map is produced **mechanically** by the script, not by hand. The
developer runs it against the target repo and gives the JSON to the agent:

```bash
# From the target repo root (any Go or TS/Node.js Lerian service):
node /path/to/reviewing-operational-risk/scan-integration-points.mjs . --out ops-risk-scan.json
# then paste/attach ops-risk-scan.json to the agent before the dialogue.
```

> **Monorepo / hexagonal Go — do NOT scan only the service subdir.** In a
> hexagonal layout the outbound boundaries live in the imported `pkg/*` (or
> shared adapter) packages, **not** under `apps/<svc>`. Scanning only
> `apps/<svc>` returns a **false 0**. The scanner defends against this: given a
> subdir it walks up to the repo/module root, scans the whole tree, and
> attributes each boundary to its service via top-level dir. **Always run from
> the repo root (or let the scanner expand to it) so `pkg/*` adapters and
> `ports/out` methods are included.** If you must scan a single subdir, pass
> `--no-repo-root` and expect the map to miss shared adapters. Whenever
> `integration_points == 0` for a service that imports `ports/out`, the scanner
> emits an explicit `warnings[]` entry — treat it as a scope error, not a clean
> bill of health.

The scanner is **port-aware and adapter-aware**: each method of a `ports/out`
interface is treated as a boundary candidate (`category: "outbound_port"`), and
its resilience is inferred over the whole concrete **adapter file** — so an SDK
adapter (e.g. `midazsdk.WithTimeout`, `DoWithRetry`) that never calls `net/http`
directly is still detected. Resilience for Go line-matches is inferred over the
**enclosing function**, not a fixed ±N-line window, so a retry/timeout wrapper
elsewhere in the function still counts.

**Optional per-repo config (`.ops-risk.json`)** at the repo root tunes
detection: `shared_adapter_dirs`, `http_wrapper_packages`, `outbound_port_globs`,
and `exclude_handler_globs`. The scanner **auto-generates a default on first run**
if none exists (pass `--no-gen-config` to skip). Edit it to match the repo's
layout before a serious review.

The script emits `ring.ops-risk.integration-scan.v1` JSON:

```jsonc
{
  "scan_root": "/repo", "requested_target": "/repo/apps/svc",
  "warnings": [ { "level": "warn", "code": "zero_boundaries_in_port_service",
                 "service": "apps/svc", "message": "0 fronteiras num serviço que importa ports/out ..." } ],
  "summary": {
    "files_scanned": 210, "integration_points": 102,
    "by_category": {...}, "by_service": {...}, "files_by_top_dir": {...},
    "services_importing_ports_out": ["apps/svc"], "http_wrapper_packages_detected": ["httpclient"]
  },
  "integration_points": [
    { "category": "http_outbound", "direction": "outbound", "language": "go",
      "service": "apps/svc", "file": "internal/x.go", "line": 156, "snippet": "...",
      "resilience": { "retry": false, "dlq": false, "timeout": true,
                      "rollback": false, "idempotency": false } },
    { "category": "outbound_port", "direction": "outbound", "language": "go",
      "service": "pkg", "file": "pkg/midazadapter/adapter.go", "line": 42,
      "port": { "interface": "PaymentPort", "method": "Charge", "declared_in": "apps/svc/ports/out/gateway.go" },
      "resilience": { "retry": true, "timeout": true, "dlq": false, "rollback": false, "idempotency": false } }
  ],
  "resilience_gaps": [ { "file": "...", "line": 156, "category": "...", "service": "...", "missing": ["retry","dlq"] } ]
}
```

Always read `warnings[]` first: a `zero_integration_points` or
`zero_boundaries_in_port_service` warning means the map is probably incomplete
(scope error) and must not be treated as "no boundaries exist".

The agent consumes this JSON as the starting boundary map. **Treat every hit as
a candidate and every `false` resilience flag as a prompt to verify, not a
confirmed gap** — the regex scan is deterministic but heuristic. The focus stays
on what the service **expects to receive and how it reacts when it does not** —
do NOT leave the repo to inspect dependencies.

If the script cannot be run (no Node.js, restricted env), fall back to manual
greps for the same boundaries — **run these from the repo root and cover the
same root set as the scanner** (`internal/ components/ pkg/ src/ apps/ cmd/
services/ plugins/`), not just the service subdir:

```bash
grep -rn "http.NewRequest\|http.Client\|resty\|req.Get\|req.Post\|Do(ctx\|httpclient.\|DoWithRetry\|New.*Client(" internal/ components/ pkg/ apps/ cmd/ services/ plugins/ 2>/dev/null
grep -rn "axios\|fetch(\|got(\|undici" internal/ components/ pkg/ src/ apps/ cmd/ services/ plugins/ 2>/dev/null      # TS
grep -rn "Consume(\|Subscribe(\|HandleDelivery\|amqp\|rabbitmq\|sqs\|kafka" internal/ components/ pkg/ src/ apps/ cmd/ services/ plugins/ 2>/dev/null
grep -rn "Publish(\|Produce(\|NotifyURL\|callbackURL\|webhookURL" internal/ components/ pkg/ src/ apps/ cmd/ services/ plugins/ 2>/dev/null
grep -rln "ports/out\|port.[A-Z].*Port" internal/ components/ apps/ cmd/ services/ plugins/ 2>/dev/null   # find hexagonal outbound ports, then read their adapters in pkg/
```

For **each** integration point, confirm the resilience posture (the script
pre-fills these flags; verify them against the code):

| Attribute | What to check |
|-----------|---------------|
| Retry | Is there a retry policy (count, backoff)? |
| Rollback / compensation | On failure, is there a compensating action or saga step? |
| DLQ | Dead-letter queue or parking for un-processable messages? |
| Timeout handling | Explicit context timeout + handling of the timeout path? |
| Idempotency | Safe to reprocess without duplicate side effects? |

Produce a **boundary map**: `{integration_point, direction, entities_touched, resilience: {retry, rollback, dlq, timeout, idempotency}}`.

---

## Step 1 (Mode B): Extract the flow from the plan

Read the cycle's `plan.md` and the epic artifacts of the **current cycle** only:

- `## Phase Overview` + the active phase's `### Epic N.M:` sections → the flows built this cycle
- Each epic's task blocks → the entities created/mutated and the transitions between them
- Any linked design docs (data model, API contracts) referenced by the epics

Produce, per flow: `{flow_name, entry_point, entities[], state_transitions[], terminal_state}`. Do not scan the whole repo — the plan is the source.

---

## Step 2: Confirmation dialogue with the developer

Before analysing failures, confirm the model out loud and get agreement. In
Mode A, drive this dialogue **from the scanner JSON** — walk the developer
through the `integration_points` and the `resilience_gaps` the script surfaced,
and let them correct false positives/negatives before you classify anything:

```
For flow "<flow_name>":
  Entry point:      <e.g. POST /transfers>
  Terminal state:   <e.g. transfer.status = SETTLED>
  Entities & states: <entity: [state1 → state2 → state3]>
  Dependencies:     <external calls / queues / webhooks identified>

Is this correct? Anything missing or misidentified?
```

Incorporate corrections before proceeding. This gate prevents analysing a wrong model.

---

## Step 3: Simulate stuck intermediate states

For **each intermediate state** of **each entity** in the flow, simulate a failure of progression and trace downstream impact:

```
For entity E, transition Sn → Sn+1:
  1. Assume E is stuck in Sn (the transition never completes).
  2. What triggers Sn → Sn+1? (a consumer, an HTTP response, a scheduled job, a user action)
  3. If that trigger never fires or fails:
     - What downstream entities/flows are blocked or left inconsistent?
     - Is there money / data / a user commitment left in limbo?
  4. What, if anything, moves E forward or unwinds it?
```

Record one **scenario** per stuck state.

---

## Step 4: Classify each scenario into a tier

| Tier | Test | Example |
|------|------|---------|
| **Tier 1** | A mechanism inside the app recovers it with no human trigger | automatic retry with backoff, saga compensation, message TTL + DLQ replay, expiry job |
| **Tier 2** | A rescue path exists but needs an **external trigger** | re-drive endpoint, admin API, "retry" button in Console, replay CLI |
| **Tier 3** | No rescue path exists without touching the database directly | stuck row with no re-drive, orphaned record no API can fix |

Downgrade honestly: if the "retry" only works when the DB is hand-edited first, it's **Tier 3**, not Tier 2.

---

## Step 5: Emit outputs

Write to `docs/ops-risk/<flow-or-service>-<YYYY-MM-DD>.md`.

### Tier 2 → Operational runbook
```
### Runbook: <scenario>
Symptom:        <how an operator recognises the stuck state>
Detection:      <query / metric / log to confirm>
Trigger:        <the exact API call / endpoint / Console action that unblocks it>
Steps:          1. ... 2. ... 3. ...
Verification:   <how to confirm the entity reached terminal state>
Blast radius:   <what else is affected while stuck>
```

### Tier 3 → Gap spec
```
### Gap: <scenario>
What's missing:     <the rescue mechanism that does not exist>
Impact if hit:      <blast radius, data/money at risk, frequency estimate>
Who can act today:  <e.g. only a DBA with prod write access>
What should exist:   <new API / endpoint / Console UI action / automated job>
Suggested owner:    <team / epic to carry it>
```

### Summary table (top of file)
```
| Flow | Entity | Stuck state | Tier | Artifact |
|------|--------|-------------|------|----------|
```

---

## Step 6: Present to the developer

Summarize: mode used, flows reviewed, scenario count per tier, the count of Tier 3 gaps (the important number), and the path to the generated file. Offer to open issues for Tier 3 gaps if the developer wants a backlog.

## Red Flags — STOP
- Classifying a scenario Tier 2 when the "trigger" only works after a manual DB edit → it is **Tier 3**.
- Leaving the repo in Mode A to audit a dependency's internals → out of scope; review only how THIS service reacts.
- Skipping the Step 2 confirmation dialogue → you may be analysing the wrong flow model.
- Trusting the scanner's `resilience` flags as ground truth → they are heuristic; a `true` is a hint and a `false` is a prompt to verify, never a final verdict.
- Starting the analysis in Mode A without the `scan-integration-points.mjs` JSON when Node.js is available → run the mechanical phase first, then reason over its output.
- **Scanning only `apps/<svc>` in a hexagonal monorepo and trusting a `0` result** → the boundaries live in imported `pkg/*` adapters; a subdir-only scan is a false 0. Run from the repo root (the scanner auto-expands) and never treat a `warnings[]` scope alert as "no boundaries exist".
- Reporting only Tier 3 counts without the concrete "what should exist" → a gap without a spec is not actionable.

## Common Mistakes
- **Analysing happy path only.** The whole point is the stuck intermediate states, not the terminal success.
- **Treating a DLQ as Tier 1 automatically.** A DLQ with no replay path is really a Tier 2 (needs a re-drive) or Tier 3 (nothing drains it).
- **Mode B scope creep.** In plan-context mode, read the plan and epic artifacts — do not fall back into full-repo exploration.
