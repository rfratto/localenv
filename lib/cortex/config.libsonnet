{
  local configMap = $.core.v1.configMap,
  local deployment = $.apps.v1.deployment,

  _config+:: {
    consul_replicas: 1,
    distributor_replicas: 1,
    querier_replicas: 1,
    ingester_replicas: 1,
    replication_factor: 1,

    querier_concurrency: 8,

    cortex: {
      schema: [
        /*
          {
            from: '2019-10-01',
            store: 'cassandra',
            object_store: 's3',
            schema: 'v10',
            index: {
              prefix: 'index_',
              period: '6h',
            },
            chunks: {
              prefix: 'chunks_',
              period: '6h',
            },
          },
        */
      ],
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
        'distributor.replication-factor': $._config.replication_factor,
        'distributor.shard-by-all-labels': true,
        'distributor.health-check-ingesters': true,
        'ring.heartbeat-timeout': '10m',
        'auth.enabled': false,
      },

      storage: {
        'config-yaml': '/etc/cortex/schema/config.yaml',
      },

      storageConfig: {
        /*
          's3.url':
          'http://admin:password@minio.storage.svc.cluster.local:9000/cortex',
          's3.force-path-style': true,

          'cassandra.keyspace': 'cortex',
          'cassandra.addresses': 'scylla.storage.svc.cluster.local',

          'cassandra.timeout': '5s',
          'cassandra.connect-timeout': '5s',
        */

        'config-yaml': '/etc/cortex/schema/config.yaml',
      },

      query: {
        'querier.ingester-streaming': true,
        'querier.batch-iterators': true,
        'store.min-chunk-age': '15m',
        'querier.query-ingesters-within': '12h',
        'store.cardinality-limit': 1e6,
        'store.max-query-length': '24h',
      },
    },
  },

  storage_config:
    configMap.new('schema') +
    configMap.mixin.metadata.withNamespace($._config.namespace) +
    configMap.withData({
      'config.yaml': $.util.manifestYaml({
        configs: $._config.cortex.schema,
      }),
    }),

  storage_config_mixin::
    $.util.configMapVolumeMount($.storage_config, '/etc/cortex/schema'),
}
