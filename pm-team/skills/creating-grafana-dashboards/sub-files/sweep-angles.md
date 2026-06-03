## Explorer Angle Specifications

MANDATORY: All 7 angles run on every Sweep. The catalog below is the source of truth
for what each explorer looks for. MUST NOT edit angle specs at dispatch time — copy
verbatim into the explorer prompt.

Each explorer writes a single JSON file at `/tmp/dashboards-sweep-{N}-{angle-slug}.json`
following the schema in `dictionary-schema.md`. If no findings: write file with
empty `primitives` array (do NOT skip the file).

---

#### Angle 1: Counter metrics

**Severity:** REQUIRED — counters are the foundation of rate panels.

**Detection Patterns:**
- `meter.Int64Counter("name", ...)` and `meter.Float64Counter(...)` constructor calls
- `.Add(ctx, n, attribute.String(k, v), ...)` increment sites — capture argument shape
- Counter declarations stored as struct fields (e.g., `s.requestsTotal`) — trace the field back to its constructor
- Re-exported counters from internal `metrics` packages — follow the call chain to the Int64Counter call
- Counters declared but never incremented → record as `dead_counter: true`

**Schema (per primitive):**
```json
{
  "kind": "counter",
  "name": "ledger_transactions_total",
  "instrument_type": "Int64Counter",
  "unit": "1",
  "description": "...",
  "labels": ["tenant_id", "transaction_type", "result"],
  "label_cardinality_estimate": "low|medium|high|unbounded",
  "emission_sites": [{"file": "internal/services/ledger.go", "line": 142, "function": "PostTransaction"}],
  "tenant_scoped": true,
  "dead_counter": false,
  "notes": "..."
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for counter metric primitives emitted via lib-observability/metrics (canonical) or
> lib-commons/v5/commons/opentelemetry (deprecated shim — still emits, but flag the import for migration).
> MUST find every `meter.Int64Counter(...)`, `meter.Float64Counter(...)` constructor call across `internal/`,
> `cmd/`, and `pkg/`. For each counter, record file:line of the constructor, the metric name string, the
> unit (default "1" if absent), the description, and every `.Add(...)` increment site with the labels passed.
> Trace counters stored on structs back to the constructor — the metric name lives at the constructor, not
> the Add site. Estimate label cardinality: enum-like values are LOW, IDs are HIGH, free-form strings are
> UNBOUNDED. Mark `tenant_scoped: true` if `tenant_id` appears in any Add site's attributes. Mark
> `dead_counter: true` if the constructor exists but no Add site references it. Severity REQUIRED — every
> counter is a rate-panel candidate.

---

#### Angle 2: Histogram metrics

**Severity:** REQUIRED — histograms drive latency, payload-size, and SLO panels.

**Detection Patterns:**
- `meter.Float64Histogram("name", ...)` and `meter.Int64Histogram(...)` constructor calls
- `.Record(ctx, value, attribute.String(k, v), ...)` emission sites
- `metric.WithExplicitBucketBoundaries([]float64{...})` boundary configuration
- `metric.WithUnit("ms"|"s"|"By"|"1")` unit declaration
- Histograms used for things that should be counters (e.g., recording `1` for every request) → flag as `histogram_misuse`
- Wall-clock duration measured via `time.Since(start).Seconds()` recorded into a Float64Histogram → standard latency pattern, no flag

**Schema (per primitive):**
```json
{
  "kind": "histogram",
  "name": "http_request_duration_seconds",
  "instrument_type": "Float64Histogram",
  "unit": "s",
  "description": "...",
  "labels": ["tenant_id", "method", "route", "status_class"],
  "label_cardinality_estimate": "low|medium|high|unbounded",
  "boundaries": [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  "boundaries_source": "explicit|default",
  "emission_sites": [{"file": "internal/middleware/metrics.go", "line": 67, "function": "Middleware"}],
  "tenant_scoped": true,
  "histogram_misuse": false,
  "notes": "..."
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for histogram metric primitives emitted via lib-observability/metrics (canonical) or
> lib-commons/v5/commons/opentelemetry (deprecated shim — still emits, but flag the import for migration).
> MUST find every `meter.Float64Histogram(...)`, `meter.Int64Histogram(...)` constructor call. For each, record
> file:line of the constructor, the metric name, the unit (look for `metric.WithUnit("...")`; if absent, infer
> from the metric name suffix — `_seconds`→s, `_bytes`→By, `_total`→1), the description, the bucket boundaries
> (look for `metric.WithExplicitBucketBoundaries(...)`; if absent, mark `boundaries_source: "default"` with empty
> array), and every `.Record(...)` site with the labels and the value-source expression. Estimate label cardinality
> as in Angle 1. Mark `tenant_scoped: true` if `tenant_id` appears in any Record site. Mark `histogram_misuse: true`
> if the recorded values are constant (e.g., always `1`) — these should be counters. Severity REQUIRED — histograms
> are the primary input for latency dashboards and SLO error budgets.

---

#### Angle 3: Gauge metrics

**Severity:** REQUIRED — gauges drive saturation and instantaneous-state panels.

**Detection Patterns:**
- `meter.Int64UpDownCounter(...)` and `Float64UpDownCounter(...)` — synchronous gauges
- `meter.Int64ObservableGauge(...)` and `Float64ObservableGauge(...)` — async via callback
- `meter.RegisterCallback(...)` registering observable instruments
- UpDownCounter `.Add(ctx, +1)` / `.Add(ctx, -1)` patterns for in-flight tracking
- Observable callbacks reading from runtime sources (DB pool stats, channel depth, queue length)

**Schema (per primitive):**
```json
{
  "kind": "gauge",
  "name": "active_connections",
  "instrument_type": "Int64UpDownCounter|Int64ObservableGauge|Float64ObservableGauge",
  "unit": "1",
  "description": "...",
  "labels": ["tenant_id", "pool_name"],
  "label_cardinality_estimate": "low|medium|high|unbounded",
  "synchronous": true,
  "callback_source": "internal/db/pool.go:Stats()" ,
  "emission_sites": [{"file": "internal/db/pool.go", "line": 45, "function": "registerMetrics"}],
  "tenant_scoped": false,
  "notes": "..."
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for gauge primitives emitted via lib-observability/metrics (canonical) or
> lib-commons/v5/commons/opentelemetry (deprecated shim — still emits, but flag the import for migration). MUST find:
> (a) `meter.Int64UpDownCounter(...)`, `meter.Float64UpDownCounter(...)` — synchronous gauges; (b)
> `meter.Int64ObservableGauge(...)`, `meter.Float64ObservableGauge(...)` — async observable gauges. For
> synchronous gauges, find every `.Add(...)` site. For observable gauges, find the registered callback
> via `meter.RegisterCallback(...)` and capture what the callback reads (e.g., `db.Stats().OpenConnections`).
> Record file:line of the constructor, the metric name, unit, description, labels, and the source expression
> for observable gauges in `callback_source`. Severity REQUIRED — gauges are the primary input for saturation
> dashboards and capacity-planning panels.

---

#### Angle 4: Trace spans

**Severity:** REQUIRED — spans drive trace exemplars on histogram panels and the tracing-aware service map.

**Detection Patterns:**
- `tracer.Start(ctx, "name", trace.WithSpanKind(...), trace.WithAttributes(...))` invocations
- `defer span.End()` paired with each Start (flag missing pairs as `unbounded_span`)
- `span.SetAttributes(attribute.String(...))` post-Start attribute additions
- `span.RecordError(err)` and `span.SetStatus(codes.Error, msg)` error attribution
- Span kind: Server (incoming), Client (outgoing), Producer/Consumer (messaging), Internal (default)
- Parent-child structure: spans started inside another span's context inherit parent
- Spans started but never ended → `unbounded_span: true` (these will leak)

**Schema (per primitive):**
```json
{
  "kind": "span",
  "name": "ledger.post_transaction",
  "span_kind": "Internal|Server|Client|Producer|Consumer",
  "description": "...",
  "attributes": ["tenant_id", "transaction_id", "transaction_type"],
  "attribute_cardinality_estimate": "low|medium|high|unbounded",
  "error_recording": "always|on_failure|none",
  "parent_span_pattern": "http.handler|grpc.handler|amqp.consumer|root|internal",
  "emission_sites": [{"file": "internal/services/ledger.go", "line": 130, "function": "PostTransaction"}],
  "tenant_scoped": true,
  "unbounded_span": false,
  "notes": "..."
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for trace span primitives emitted via lib-observability/tracing (canonical) or
> lib-commons/v5/commons/opentelemetry (deprecated shim — still emits, but flag the import for migration).
> MUST find every `tracer.Start(ctx, "name", ...)` call across `internal/`, `cmd/`, `pkg/`. For each
> span, record file:line of Start, the span name, the SpanKind (look for `trace.WithSpanKind(...)`;
> default is `SpanKindInternal`), the description (from doc comments above the function or inferred
> from the span name), every attribute set via `WithAttributes` or post-Start `SetAttributes`, and
> whether `RecordError` + `SetStatus(codes.Error, ...)` is called on error paths. Identify the parent
> span pattern: HTTP middleware, gRPC interceptor, RabbitMQ consumer wrapper, root, or internal.
> CRITICAL: verify every `tracer.Start(...)` has a paired `defer span.End()` in the same function; if
> not, mark `unbounded_span: true` — this is a span leak. Mark `tenant_scoped: true` if `tenant_id`
> appears in attributes. Severity REQUIRED — spans are the navigation surface from dashboard to
> root-cause investigation.

---

#### Angle 5: Structured log fields

**Severity:** REQUIRED — log fields drive log panels and log-to-trace correlation.

**Detection Patterns:**
- `lib-observability/log` (canonical) or `lib-commons/v5/commons/log` (deprecated shim) logger usage
- `log.With(zap.String("k", v), ...)` field-attaching call sites
- Log-level usage distribution: Debug, Info, Warn, Error, Fatal — levels NOT in use are flagged
- Trace correlation: logs emitted inside a span context auto-correlate; bare logger usage outside spans is flagged
- Sensitive field emissions: `password`, `token`, `secret`, `key`, `credit_card` substrings → `pii_risk: true`

**Schema (per field):**
```json
{
  "kind": "log_field",
  "name": "transaction_id",
  "level_distribution": {"debug": 0, "info": 12, "warn": 1, "error": 3},
  "type_observed": "string|int|float|bool|object",
  "emission_sites": [{"file": "internal/services/ledger.go", "line": 145, "level": "info"}],
  "trace_correlated": true,
  "pii_risk": false,
  "notes": "..."
}
```

Top-level summary in same JSON file:
```json
{
  "log_levels_in_use": ["info", "warn", "error"],
  "log_levels_unused": ["debug", "fatal"],
  "trace_correlation_coverage_pct": 87.5,
  "pii_risk_field_count": 0
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for structured log emissions via lib-observability/log (canonical) or
> lib-commons/v5/commons/log (deprecated shim — still emits, but flag the import for migration). MUST find every
> logger call site (`logger.Info(...)`, `logger.Warn(...)`, `logger.Error(...)`, `logger.Debug(...)`,
> `logger.With(...).Info(...)`, etc.). For each unique field name attached via `With` or appearing as
> a structured field, record file:line, the field name, the type observed (from the value expression),
> and the level. Aggregate per-field across all sites. Compute level distribution per field. Compute
> trace_correlation_coverage_pct = (sites where logger call is inside a tracer.Start span context) /
> (total sites). Flag PII risk: any field name containing `password`, `token`, `secret`, `api_key`,
> `credit_card`, `ssn`, `cpf`, `cnpj`. Severity REQUIRED — log fields are the primary input for log
> panels in dashboards.

---

#### Angle 6: Cross-cutting concerns (tenant, trace, error attribution)

**Severity:** CRITICAL — cross-cutting consistency is what makes dashboards correlatable.

**Detection Patterns:**
- `tenant_id` propagation: extracted from context, then attached as label/attribute consistently across metrics + spans + logs
- `trace_id` / `span_id` propagation: automatic via OTel context propagation through HTTP/gRPC headers
- Error attribution pattern: `span.RecordError(err)` + `span.SetStatus(codes.Error, ...)` + structured log at error level + counter increment with `result="error"` label
- Inconsistencies to detect:
  - Metric labeled `tenant_id` but co-emitted span lacks `tenant_id` attribute
  - Span records error but no error counter increments
  - Error log emitted but no span error recording
  - `tenant_id` extracted but discarded (not propagated to metric/span/log)

**Schema:**
```json
{
  "tenant_propagation": {
    "source_call": "tmcore.GetTenantIDContext",
    "metric_labels_with_tenant": ["ledger_transactions_total", "..."],
    "span_attributes_with_tenant": ["ledger.post_transaction", "..."],
    "log_fields_with_tenant_correlation_pct": 92.0,
    "inconsistencies": [
      {"site": "internal/services/auth.go:88", "issue": "metric tenant-labeled but span lacks tenant_id attribute"}
    ]
  },
  "trace_correlation": {
    "log_to_trace_coverage_pct": 87.5,
    "metric_exemplar_capable_count": 14,
    "broken_propagation_sites": []
  },
  "error_attribution": {
    "complete_attribution_sites": [{"file": "...", "line": 0, "primitive_set": ["span", "metric", "log"]}],
    "partial_attribution_sites": [{"file": "...", "line": 0, "missing": ["span_record_error"]}],
    "no_attribution_sites": [{"file": "...", "line": 0}]
  }
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for cross-cutting telemetry consistency. This angle CROSS-REFERENCES Angles 1–5
> findings; you may receive their JSON files as input. MUST verify three contracts:
>
> 1. **Tenant propagation**: For every metric site labeling `tenant_id`, find the surrounding function;
>    verify that any tracer.Start in the same function attaches `tenant_id` as a span attribute, and
>    any logger call in the same function attaches `tenant_id` as a log field. Record inconsistencies.
>
> 2. **Trace correlation**: Compute the percentage of logger.Error/Warn/Info call sites that occur within
>    an active span context. Compute the count of histograms whose Record sites are inside an active span
>    (these are exemplar-capable for Grafana exemplar links).
>
> 3. **Error attribution**: For every error-handling block (`if err != nil`), check whether the block
>    contains: (a) `span.RecordError(err)`, (b) `span.SetStatus(codes.Error, ...)`, (c) `logger.Error`,
>    (d) a counter increment with `result="error"` or equivalent failure label. Classify each error site
>    as complete (all four), partial (some), or no_attribution.
>
> Severity CRITICAL — dashboards built on inconsistent cross-cutting will mislead operators. Flag every
> inconsistency with file:line.

---

#### Angle 7: Framework instrumentation

**Severity:** REQUIRED — framework instrumentation governs what auto-emits versus what requires manual span/metric attention.

**Detection Patterns:**
- HTTP middleware: `otelfiber.Middleware`, `otelhttp.NewHandler`, `otelmux.Middleware`, custom Lerian middleware
- gRPC: `otelgrpc.UnaryServerInterceptor`, `otelgrpc.StreamServerInterceptor`
- RabbitMQ: lib-commons consumer wrappers that span-wrap delivery handling
- Outgoing HTTP: `otelhttp.NewTransport` wrapping `http.Client.Transport`
- Database: `otelsql.Open`, pgx tracer wiring, MongoDB client option `monitor.NewMonitor()`
- Auto-emitted metric/span names — capture so the dictionary doesn't double-count manual instrumentation

**Schema:**
```json
{
  "http_server_instrumented": {
    "framework": "fiber|echo|gin|net/http|none",
    "middleware_site": "internal/http/server.go:42",
    "auto_metrics": ["http.server.request.duration", "http.server.active_requests"],
    "auto_spans": ["http.server"],
    "manual_overrides": []
  },
  "grpc_server_instrumented": {
    "instrumented": true,
    "interceptor_site": "internal/grpc/server.go:66",
    "auto_metrics": ["rpc.server.duration"],
    "auto_spans": ["grpc.{method}"]
  },
  "rabbitmq_consumer_instrumented": {
    "instrumented": true,
    "wrapper_site": "internal/messaging/consumer.go:29",
    "auto_spans": ["amqp.consume.{queue}"]
  },
  "outgoing_http_instrumented": {
    "instrumented": true,
    "wrapper_site": "internal/clients/http.go:18"
  },
  "database_instrumented": {
    "postgres": "pgx-otel|otelsql|none",
    "mongodb": "command-monitor|none",
    "auto_spans": ["pg.query", "mongo.command"]
  }
}
```

**Explorer Dispatch Prompt Template:**

> Sweep the target repo for framework-level OTel instrumentation. MUST detect:
>
> 1. HTTP server: identify framework (Fiber/Echo/Gin/net/http), find middleware registration site,
>    capture the auto-emitted metric and span names per the framework's convention.
> 2. gRPC server: find `otelgrpc.UnaryServerInterceptor` / `StreamServerInterceptor` registrations.
> 3. RabbitMQ consumers: find lib-commons consumer wrappers; record auto-span pattern per queue.
> 4. Outgoing HTTP clients: find `otelhttp.NewTransport` wrapping or absence thereof.
> 5. Database: detect pgx OTel tracer, otelsql, MongoDB command monitor wiring.
>
> The point of this angle is to PREVENT double-counting manual instrumentation in the dictionary.
> If a framework auto-emits `http.server.request.duration`, manual `meter.Float64Histogram("my_http_duration")`
> elsewhere is redundant — flag as `redundant_with_framework: true`. Severity REQUIRED — without this
> angle, the dictionary will list 2× metrics (one auto, one manual) for the same observable.
