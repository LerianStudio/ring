// Histogram-based latency panels. Two variants:
//   - latencyHeatmap: distribution heatmap (best signal for outlier patterns)
//   - latencyQuantiles: time-series of p50/p95/p99 (best for SLO tracking)
//
// Both work on histograms emitted via lib-observability tracing's
// meter.Float64Histogram. Suffix the base name with _bucket for histogram_quantile.

local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

{
  // latencyHeatmap(title, metric, [tenantFilter])
  //   metric: histogram base name (e.g., 'http_server_request_duration_seconds')
  //           Template appends _bucket and _count as needed.
  latencyHeatmap(title, metric, tenantFilter=false)::
    local filter = if tenantFilter then '{tenant_id=~"$tenant_id"}' else '';
    g.panel.heatmap.new(title)
    + g.panel.heatmap.queryOptions.withTargets([
        g.query.prometheus.new(
          '${datasource}',
          'sum by (le) (rate(' + metric + '_bucket' + filter + '[$__rate_interval]))',
        )
        + g.query.prometheus.withLegendFormat('{{ le }}')
        + g.query.prometheus.withFormat('heatmap'),
      ])
    + g.panel.heatmap.options.withCalculate(false)
    + g.panel.heatmap.options.color.withScheme('Spectral')
    + g.panel.heatmap.options.yAxis.withUnit('s')
    + g.panel.heatmap.options.exemplars.withColor('rgba(255,0,255,0.7)'),
  // Note: exemplars require Tempo wired as datasource exemplar destination.
  // See reference.md §7 "Trace Exemplars on Histograms".

  // latencyQuantiles(title, metric, [quantiles], [tenantFilter])
  //   quantiles: array of quantile values, default [0.5, 0.95, 0.99]
  latencyQuantiles(title, metric, quantiles=[0.5, 0.95, 0.99], tenantFilter=false)::
    local filter = if tenantFilter then '{tenant_id=~"$tenant_id"}' else '';
    g.panel.timeSeries.new(title)
    + g.panel.timeSeries.queryOptions.withTargets([
        g.query.prometheus.new(
          '${datasource}',
          'histogram_quantile(' + std.toString(q) + ', sum by (le) (rate(' + metric + '_bucket' + filter + '[$__rate_interval])))',
        )
        + g.query.prometheus.withLegendFormat('p' + std.toString(q * 100))
        for q in quantiles
      ])
    + g.panel.timeSeries.standardOptions.withUnit('s')
    + g.panel.timeSeries.options.legend.withDisplayMode('table')
    + g.panel.timeSeries.options.legend.withCalcs(['mean', 'max'])
    + g.panel.timeSeries.options.tooltip.withMode('multi'),
}
