// Gauge panels for USE methodology (Utilization, Saturation).
//   - saturationGauge: utilization as percentage with thresholds
//   - currentValueStat: instantaneous gauge value as a stat panel
//
// For lib-observability metrics UpDownCounter and ObservableGauge primitives.

local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

{
  // saturationGauge(title, metric, capacityMetric, [tenantFilter])
  //   metric:         current usage gauge
  //   capacityMetric: capacity gauge (or numeric literal as string)
  //   Renders as gauge panel with threshold bands at 70%, 85%, 95%.
  saturationGauge(title, metric, capacityMetric, tenantFilter=false)::
    local filter = if tenantFilter then '{tenant_id=~"$tenant_id"}' else '';
    g.panel.gauge.new(title)
    + g.panel.gauge.queryOptions.withTargets([
        g.query.prometheus.new(
          '${datasource}',
          metric + filter + ' / ' + capacityMetric + filter,
        ),
      ])
    + g.panel.gauge.standardOptions.withUnit('percentunit')
    + g.panel.gauge.standardOptions.withMin(0)
    + g.panel.gauge.standardOptions.withMax(1)
    + g.panel.gauge.standardOptions.withDecimals(2)
    + g.panel.gauge.standardOptions.thresholds.withMode('percentage')
    + g.panel.gauge.standardOptions.thresholds.withSteps([
        { color: 'green', value: null },
        { color: 'yellow', value: 70 },
        { color: 'orange', value: 85 },
        { color: 'red', value: 95 },
      ])
    + g.panel.gauge.options.withShowThresholdLabels(true)
    + g.panel.gauge.options.withShowThresholdMarkers(true),

  // currentValueStat(title, metric, unit, [tenantFilter])
  //   For showing instantaneous values (active connections, queue depth, etc.)
  currentValueStat(title, metric, unit='short', tenantFilter=false)::
    local filter = if tenantFilter then '{tenant_id=~"$tenant_id"}' else '';
    g.panel.stat.new(title)
    + g.panel.stat.queryOptions.withTargets([
        g.query.prometheus.new('${datasource}', metric + filter),
      ])
    + g.panel.stat.standardOptions.withUnit(unit)
    + g.panel.stat.options.withColorMode('value')
    + g.panel.stat.options.withGraphMode('area')
    + g.panel.stat.options.withReduceOptions({
        calcs: ['lastNotNull'],
        fields: '',
        values: false,
      }),
}
