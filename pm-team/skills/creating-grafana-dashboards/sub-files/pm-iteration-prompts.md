# PM Iteration Prompts (Gate 5)

Gate 5 is the human-decision gate. Orchestrator presents the proposed themes from Gate 4
and walks the PM through structured questions. Iteration loops back to Gate 4 (full or
single-theme) until PM responds `APPROVED: <theme list>`.

This file is a SCRIPT for the orchestrator — copy-paste sections verbatim into PM-facing
text, adapt placeholders to dictionary contents.

---

## Opening Frame (always first message)

```
Telemetry sweep complete. Dictionary at docs/dashboards/telemetry-dictionary.md
captured: <N> counters, <N> histograms, <N> gauges, <N> spans, <N> log fields.

Cross-cutting consistency: <N> inconsistencies flagged (see dictionary "Cross-cutting"
section). <surface critical inconsistencies inline if any>

I've proposed <N> themes for dashboards. Plans drafted at /tmp/dashboards-plan-*.md.

Walking through them now — your call on each.
```

---

## Per-theme Decision Block

For EACH proposed theme, present this block and collect PM input before proceeding to the next theme:

```
═══════════════════════════════════════════════
THEME: {theme_name}
Proposed dashboards: {N}
Methodology: RED | USE | hybrid
Tenant-aware: yes | no

Audience (proposed):
  Primary:   {role}
  Secondary: {role}

SLIs surfaced:
  - {sli_1}
  - {sli_2}

Time range default: {1h | 6h | 24h | 7d}

Panels (summary):
  Dashboard "{d1}": {panel_count} panels — {one-line summary}
  Dashboard "{d2}": {panel_count} panels — {one-line summary}

Alert candidates:
  {N} panels suggested for alerting (full list in plan file)
═══════════════════════════════════════════════
```

Then ask, in this exact order:

### Q1 — Theme name + scope

```
Q1. Theme name "{theme_name}" — accept, rename, merge with another, or reject?

Options:
  ACCEPT                       → keep as is
  RENAME -> {new_name}         → rename, plan unchanged
  MERGE WITH {other_theme}     → fold into another
  SPLIT INTO {a}, {b}          → plan needs decomposition (loops Gate 4)
  REJECT                       → drop this theme entirely
```

### Q2 — Audience

```
Q2. Audience "{primary}/{secondary}" — does this match who actually opens this dashboard?

Common audiences:
  - engineering    (devs investigating issues)
  - product        (PMs checking adoption / business KPIs)
  - exec           (leadership glance, high-level health)
  - ops/oncall     (real-time during incidents)
  - support        (customer-facing issue triage)

Wrong audience changes panel choice (exec wants stats, oncall wants time-series).
```

### Q3 — SLIs

```
Q3. SLIs surfaced: {list}. Anything missing? Anything that doesn't belong?

Reminder: an SLI is something you'd put in an SLO contract. "Average latency"
is not an SLI; "p99 latency under 200ms for 99.5% of requests" is.
```

### Q4 — Time range default

```
Q4. Default time range: {value}. Match the operational cadence?

Heuristic:
  - oncall/ops:        1h or 6h (real-time)
  - engineering:       24h (debugging across deploys)
  - product/exec:      7d or 30d (trend visibility)
```

### Q5 — Alert thresholds

```
Q5. Suggested alerts on {N} panels:
  - {panel_1} → {threshold} (severity: {PAGE|TICKET|INFO})
  - {panel_2} → {threshold} (severity: {PAGE|TICKET|INFO})
  ...

Per panel:
  KEEP                          → as proposed
  ADJUST {panel}: {new_threshold}
  ESCALATE {panel}: {new_severity}
  DEMOTE {panel}: {new_severity}
  DROP {panel}                  → no alert
```

### Q6 — Missing dashboards

```
Q6. What did you EXPECT for this theme that I didn't propose?

If you say "X is missing", I'll propose a panel layout for it (loops Gate 4 for this theme).
```

---

## Cross-theme Decision Block

After all per-theme blocks, present:

### Q7 — Theme additions

```
Q7. Themes I did NOT propose but you want:

Examples I sometimes miss:
  - Cost / billing dashboards (not telemetry-emitted, business KPIs)
  - Capacity-planning dashboards (long-range trends, weekly/monthly)
  - Compliance / audit dashboards (regulatory reporting)
  - SLO error-budget dashboards (multi-window burn-rate)

Format: "ADD theme {name}: {one-line description of what it's for}"
```

### Q8 — Cross-theme consistency

```
Q8. The dictionary flagged {N} cross-cutting inconsistencies (e.g., metrics labeled
with tenant_id but spans missing it). These will weaken dashboards built on those
primitives.

Path forward:
  FIX FIRST          → block dashboard work, surface tasks via ring:running-dev-cycle to fix instrumentation
  ACCEPT             → proceed with dashboards; inconsistencies degrade exemplars/correlation but don't break anything
  PARTIAL: {list}    → fix specific subset before proceeding
```

### Q9 — Final approval

```
Q9. Approval list — which themes proceed to Gate 6 (Grafonnet authoring)?

Format your final response as ONE of:

  APPROVED: {theme1} {theme2} {theme3}
    → orchestrator dispatches Gate 6 per listed theme

  REVISE theme {name}: {change}
    → loops Gate 4 for that theme only

  BLOCKED: {reason}
    → halts skill, returns context for triage
```

---

## Loop-Back Mechanics

The orchestrator interprets PM responses and re-enters Gate 4 selectively:

| PM Response | Loop behavior |
|-------------|---------------|
| `ACCEPT` per Q1 | No loop |
| `RENAME -> {new}` | Loop Q4 light: regenerate plan filename and dashboard titles only |
| `MERGE WITH {other}` | Loop Q4 full: re-propose merged plan combining both themes |
| `SPLIT INTO {a},{b}` | Loop Q4 full: decompose into two plans |
| `REJECT` | Drop theme from approval list |
| `ADJUST {panel}: {threshold}` | Patch in plan file, no full Q4 loop |
| `ADD theme {name}: {desc}` | Q4 light: propose new plan grounded in dictionary |
| `FIX FIRST` (Q8) | Halt skill, generate task list via ring:running-dev-cycle handoff |
| `APPROVED` | Proceed to Gate 6 |

---

## Surfacing Inconsistencies (Required Behavior)

If Angle 6 (cross-cutting) reports inconsistencies in `tenant_propagation.inconsistencies` or `error_attribution.partial_attribution_sites`, the orchestrator MUST surface them in the opening frame BEFORE Q1. PM cannot make sound decisions on dashboards built on broken cross-cutting.

Format:

```
⚠ Cross-cutting inconsistencies flagged:

  Tenant propagation:
    - internal/services/auth.go:88 — metric labeled tenant_id but span lacks tenant_id attribute
    - ...

  Error attribution (partial):
    - internal/handlers/transfer.go:42 — error path missing span.RecordError
    - ...

Affected dashboards:
  - "auth/" theme: tenant exemplars will be incomplete
  - "transfer/" theme: error rate panels won't link to causal traces

Recommendation: address before dashboards. PM call.
```

This is a soft block — PM can still ACCEPT and proceed, but the surface is mandatory.
