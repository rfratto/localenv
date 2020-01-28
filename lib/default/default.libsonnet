(import 'github.com/prometheus/node_exporter/docs/node-mixin/mixin.libsonnet') +
(import 'admin/admin.libsonnet') +
(import 'grafana/grafana.libsonnet') +
(import 'prometheus/prometheus.libsonnet') +
(import 'github.com/prometheus/prometheus/documentation/prometheus-mixin/dashboards.libsonnet') +
{
  local grafanaDashboards = super.grafanaDashboards,

  // Override grafana dashboards and set the timezone to blank
  grafanaDashboards:: {
    [filename]: grafanaDashboards[filename] {
      timezone: '',
    }
    for filename in std.objectFields(grafanaDashboards)
  },
}
