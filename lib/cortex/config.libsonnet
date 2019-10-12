local k = import 'ksonnet-util/kausal.libsonnet';

local configMap = k.core.v1.configMap;
local deployment = k.apps.v1beta1.deployment;

{
  _config+:: {
    consul_replicas: 1,

    cortex: {
      schema: [],
    },

    cortex_flags+: {
      common: {
        'log.level': 'info',
      },

      ring: {
        'consul.hostname': 'consul.%s.svc.cluster.local:8500' % $._config.namespace,
        'consul.consistent-reads': false,
        'ring.prefix': '',
        'ring.store': 'consul',
      },

      distributor: {
        'distributor.replication-factor': 3,
        'distributor.shard-by-all-labels': true,
        'distributor.health-check-ingesters': true,
        'ring.heartbeat-timeout': '10m',
        'auth.enabled': false,
      },

      storage: {
        'chunk.storage-client': 'inmemory',
        'config-yaml': '/etc/cortex/schema/config.yaml',
      },

      query: {
        'querier.ingester-streaming': true,
        'querier.batch-iterators': true,
        'store.min-chunk-age': '15m',
        'querier.query-ingesters-within': '8h',
        'store.cardinality-limit': 1e6,
        'store.max-query-length': '24h',
      },
    },
  },

  storage_config:
    configMap.new('schema') +
    configMap.withData({
      'config.yaml': $.util.manifestYaml({
        configs: $._config.cortex.schema,
      }),
    }),

  storage_config_mixin::
    $.util.configMapVolumeMount($.storage_config, '/etc/cortex/schema'),
}
