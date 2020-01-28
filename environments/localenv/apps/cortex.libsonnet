local cortex = import 'cortex/cortex.libsonnet';
local settings = import 'settings.libsonnet';

cortex {
  _config+:: {
    namespace: 'cortex',

    ingester_replicas: 1,
    distributor_replicas: 1,
    querier_replicas: 1,
    replication_factor: 1,
  },

  ingester_args+:: {
    'log.level': 'info',
  },

  ns:
    $.core.v1.namespace.new($._config.namespace),
} + settings.cortex.extra_config
