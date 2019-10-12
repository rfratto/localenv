local admin = import 'admin/admin.libsonnet';
local grafana = import 'grafana/grafana.libsonnet';
local node_mixin = import 'node-mixin/mixin.libsonnet';
local prometheus_dashboards = import 'prometheus-mixin/dashboards.libsonnet';
local prometheus = import 'prometheus/prometheus.libsonnet';
local promtail = import 'promtail/promtail.libsonnet';

promtail +
node_mixin +
admin +
grafana +
prometheus +
prometheus_dashboards +
{
  local grafanaDashboards = super.grafanaDashboards,

  _config+:: {
    promtail_config+: {
      clients: [{
        scheme:: 'http',
        hostname:: 'loki.loki.svc.cluster.local',
        external_labels: {},
      }],
    },
  },

  // Override grafana dashboards and set the timezone to blank
  grafanaDashboards:: {
    [filename]: grafanaDashboards[filename] {
      timezone: '',
    }
    for filename in std.objectFields(grafanaDashboards)
  },
}
