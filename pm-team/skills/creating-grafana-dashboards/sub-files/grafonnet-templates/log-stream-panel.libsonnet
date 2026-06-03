// Log stream panel using LogQL (Loki).
// Templated for lib-observability/log structured emissions.
//
// Required Loki datasource configuration:
//   - derivedFields with trace_id link to Tempo (so log lines link to traces)
//   See reference.md §7 "Log-to-Trace Links".

local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

{
  // logStream(title, serviceLabel, [extraFilters], [tenantFilter])
  //   serviceLabel: typically the value of `service` label in your Loki labels (== service name)
  //   extraFilters: array of LogQL line filters, e.g., ['|= "error"', '| json']
  //   tenantFilter: when true injects | json | tenant_id =~ "$tenant_id"
  logStream(title, serviceLabel, extraFilters=[], tenantFilter=false)::
    local base = '{service="' + serviceLabel + '"}';
    local extras = std.join(' ', extraFilters);
    local tenantClause = if tenantFilter then ' | json | tenant_id =~ "$tenant_id"' else '';
    g.panel.logs.new(title)
    + g.panel.logs.queryOptions.withTargets([
        g.query.loki.new('${loki_datasource}', base + ' ' + extras + tenantClause),
      ])
    + g.panel.logs.options.withShowTime(true)
    + g.panel.logs.options.withWrapLogMessage(true)
    + g.panel.logs.options.withSortOrder('Descending')
    + g.panel.logs.options.withDedupStrategy('signature'),
}
