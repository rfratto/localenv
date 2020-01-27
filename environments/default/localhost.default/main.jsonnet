local consul_mixin = import 'consul-mixin/mixin.libsonnet';
local cortex_mixin = import 'cortex-mixin/mixin.libsonnet';
local default = import 'default/default.libsonnet';
local temp = import 'temp.libsonnet';

default +
cortex_mixin +
consul_mixin +
temp +
{
  _config+:: {
    namespace: 'default',
    prometheus+: {
      retention: '1d',
    },
  },

  // Add Cortex data source
  grafana_datasources+::
    $.grafana.datasource.new(
      'Loki',
      'http://loki.loki.svc.cluster.local',
      type='loki',
    ) +
    $.grafana.datasource.new(
      'Cortex',
      'http://querier.cortex.svc.cluster.local/api/prom',
      false,
    ),

  prometheus_config+:: {
    remote_write+: [
      // {
        // url: 'http://distributor.cortex.svc.cluster.local/api/prom/push',
      // },
    ],
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
