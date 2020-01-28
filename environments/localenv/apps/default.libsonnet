local settings = import 'settings.libsonnet';
local default = import 'default/default.libsonnet';
local cortex_mixin = import 'cortex-mixin/mixin.libsonnet';
local loki_mixin = import
'github.com/grafana/loki/production/loki-mixin/mixin.libsonnet';
local promtail = import 'github.com/grafana/loki/production/ksonnet/promtail/promtail.libsonnet';

default +
(if settings.cortex.enabled then cortex_mixin else {}) +
(if settings.loki.enabled then promtail else {}) +
(if settings.loki.enabled then loki_mixin else {}) +
{
  _config+:: {
    namespace: 'default',
    dashboard_config_maps: 8,
    prometheus+: {
      retention: '1d',
    },

    // We don't bother to check if Loki is enabled here since
    // this is only used when Promtail is imported.
    promtail_config+: {
      clients: [{
        scheme:: 'http',
        hostname:: 'loki.loki.svc.cluster.local',
        external_labels: {},
      }],
    },
  },

  grafana_datasources+::
    (
      if settings.cortex.enabled
      then $.grafana.datasource.new(
        'Cortex',
        'http://querier.cortex.svc.cluster.local/api/prom',
        false,
      )
      else {}
    ) +
    (
      if settings.loki.enabled
      then $.grafana.datasource.new(
        'Loki',
        'http://loki.loki.svc.cluster.local',
        type='loki',
      )
      else {}
    )

  prometheus_config+:: {
    local cortex_remote_write = (
      if settings.prometheus.remote_write_cortex &&
         settings.cortex.enabled
      then [{ url:
      'http://distributor.cortex.svc.cluster.local/api/prom/push' }]
      else []
    ),

    remote_write+: (
      cortex_remote_write +
      settings.prometheus.extra_remote_writes
    ),
  },

  local service = $.core.v1.service,

  // Make nginx available on the hostport, binding
  // it 30000 ports above.
  //
  // If using k3d, create with --publish 8080:30080
  // to always make available on the host.
  nginx_service+:
    local bindNodePort(port) =
      port { nodePort: port.port + 30000 };

    service.mixin.spec.withPorts([
      bindNodePort(port)
      for port in super.nginx_service.spec.ports
    ]) +
    service.mixin.spec.withType('NodePort'),
}
