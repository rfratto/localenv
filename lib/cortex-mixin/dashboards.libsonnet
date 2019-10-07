local utils = (import 'mixin-utils/utils.libsonnet');

local g = (import 'grafana-builder/grafana.libsonnet') + {
  qpsPanel(selector)::
    super.qpsPanel(selector) + {
      targets: [
        target {
          interval: '1m',
        }
        for target in super.targets
      ],
    },

  latencyPanel(metricName, selector, multiplier='1e3')::
    super.latencyPanel(metricName, selector, multiplier) + {
      targets: [
        target {
          interval: '1m',
        }
        for target in super.targets
      ],
    },
};

{
  dashboards+: {
    'cortex-writes.json': $.cortex_writes_dashboard,

    'cortex-reads.json': $.cortex_reads_dashboard,

    'cortex-chunks.json':
      g.dashboard('Cortex / Chunks')
      .addMultiTemplate('cluster', 'kube_pod_container_info{image=~".*cortex.*"}', 'cluster')
      .addMultiTemplate('namespace', 'kube_pod_container_info{image=~".*cortex.*"}', 'namespace')
      .addRow(
        g.row('Active Series / Chunks')
        .addPanel(
          g.panel('Series') +
          g.queryPanel('sum(cortex_ingester_memory_series{cluster=~"$cluster", job=~"($namespace)/ingester"})', 'series'),
        )
        .addPanel(
          g.panel('Chunks per series') +
          g.queryPanel('sum(cortex_ingester_memory_chunks{cluster=~"$cluster", job=~"($namespace)/ingester"}) / sum(cortex_ingester_memory_series{cluster=~"$cluster", job=~"($namespace)/ingester"})', 'chunks'),
        )
      )
      .addRow(
        g.row('Flush Stats')
        .addPanel(
          g.panel('Utilization') +
          g.latencyPanel('cortex_ingester_chunk_utilization', '{cluster=~"$cluster", job=~"($namespace)/ingester"}', multiplier='1') +
          { yaxes: g.yaxes('percentunit') },
        )
        .addPanel(
          g.panel('Age') +
          g.latencyPanel('cortex_ingester_chunk_age_seconds', '{cluster=~"$cluster", job=~"($namespace)/ingester"}'),
        ),
      )
      .addRow(
        g.row('Flush Stats')
        .addPanel(
          g.panel('Size') +
          g.latencyPanel('cortex_ingester_chunk_length', '{cluster=~"$cluster", job=~"($namespace)/ingester"}', multiplier='1') +
          { yaxes: g.yaxes('short') },
        )
        .addPanel(
          g.panel('Entries') +
          g.queryPanel('sum(rate(cortex_chunk_store_index_entries_per_chunk_sum{cluster=~"$cluster", job=~"($namespace)/ingester"}[5m])) / sum(rate(cortex_chunk_store_index_entries_per_chunk_count{cluster=~"$cluster", job=~"($namespace)/ingester"}[5m]))', 'entries'),
        ),
      )
      .addRow(
        g.row('Flush Stats')
        .addPanel(
          g.panel('Queue Length') +
          g.queryPanel('cortex_ingester_flush_queue_length{cluster=~"$cluster", job=~"($namespace)/ingester"}', '{{instance}}'),
        )
        .addPanel(
          g.panel('Flush Rate') +
          g.qpsPanel('cortex_ingester_chunk_age_seconds_count{cluster=~"$cluster", job=~"($namespace)/ingester"}'),
        ),
      ),

    'cortex-queries.json':
      g.dashboard('Cortex / Queries')
      .addMultiTemplate('cluster', 'kube_pod_container_info{image=~".*cortex.*"}', 'cluster')
      .addMultiTemplate('namespace', 'kube_pod_container_info{image=~".*cortex.*"}', 'namespace')
      .addRow(
        g.row('Query Frontend')
        .addPanel(
          g.panel('Queue Duration') +
          g.latencyPanel('cortex_query_frontend_queue_duration_seconds', '{cluster=~"$cluster", job=~"($namespace)/query-frontend"}'),
        )
        .addPanel(
          g.panel('Retries') +
          g.latencyPanel('cortex_query_frontend_retries', '{cluster=~"$cluster", job=~"($namespace)/query-frontend"}', multiplier=1) +
          { yaxes: g.yaxes('short') },
        )
        .addPanel(
          g.panel('Queue Length') +
          g.queryPanel('cortex_query_frontend_queue_length{cluster=~"$cluster", job=~"($namespace)/query-frontend"}', '{{cluster}} / {{namespace}} / {{instance}}'),
        )
      )
      .addRow(
        g.row('Query Frontend - Results Cache')
        .addPanel(
          g.panel('Cache Hit %') +
          g.queryPanel('sum(rate(cortex_cache_hits{cluster=~"$cluster",job=~"($namespace)/query-frontend"}[1m])) / sum(rate(cortex_cache_fetched_keys{cluster=~"$cluster",job=~"($namespace)/query-frontend"}[1m]))', 'Hit Rate') +
          { yaxes: g.yaxes({ format: 'percentunit', max: 1 }) },
        )
        .addPanel(
          g.panel('Cache misses') +
          g.queryPanel('sum(rate(cortex_cache_fetched_keys{cluster=~"$cluster",job=~"($namespace)/query-frontend"}[1m])) - sum(rate(cortex_cache_hits{cluster=~"$cluster",job=~"($namespace)/query-frontend"}[1m]))', 'Miss Rate'),
        )
      )
      .addRow(
        g.row('Querier')
        .addPanel(
          g.panel('Stages') +
          g.queryPanel('max by (slice) (prometheus_engine_query_duration_seconds{quantile="0.9",cluster=~"$cluster",job=~"($namespace)/querier"}) * 1e3', '{{slice}}') +
          { yaxes: g.yaxes('ms') } +
          g.stack,
        )
        .addPanel(
          g.panel('Chunk cache misses') +
          g.queryPanel('sum(rate(cortex_cache_fetched_keys{cluster=~"$cluster",job=~"($namespace)/querier",name="chunksmemcache"}[1m])) - sum(rate(cortex_cache_hits{cluster=~"$cluster",job=~"($namespace)/querier",name="chunksmemcache"}[1m]))', 'Hit rate'),
        )
        .addPanel(
          g.panel('Chunk cache corruptions') +
          g.queryPanel('sum(rate(cortex_cache_corrupt_chunks_total{cluster=~"$cluster",job=~"($namespace)/querier"}[1m]))', 'Corrupt chunks'),
        )
      )
      .addRow(
        g.row('Querier - Index Cache')
        .addPanel(
          g.panel('Total entries') +
          g.queryPanel('sum(querier_cache_added_new_total{cache="store.index-cache-read.fifocache", cluster=~"$cluster",job=~"($namespace)/querier"}) - sum(querier_cache_evicted_total{cache="store.index-cache-read.fifocache", cluster=~"$cluster",job=~"($namespace)/querier"})', 'Entries'),
        )
        .addPanel(
          g.panel('Cache Hit %') +
          g.queryPanel('(sum(rate(querier_cache_gets_total{cache="store.index-cache-read.fifocache", cluster=~"$cluster",job=~"($namespace)/querier"}[1m])) - sum(rate(querier_cache_misses_total{cache="store.index-cache-read.fifocache", cluster=~"$cluster",job=~"($namespace)/querier"}[1m]))) / sum(rate(querier_cache_gets_total{cache="store.index-cache-read.fifocache", cluster=~"$cluster",job=~"($namespace)/querier"}[1m]))', 'hit rate')
          { yaxes: g.yaxes({ format: 'percentunit', max: 1 }) },
        )
        .addPanel(
          g.panel('Churn Rate') +
          g.queryPanel('sum(rate(querier_cache_evicted_total{cache="store.index-cache-read.fifocache", cluster=~"$cluster",job=~"($namespace)/querier"}[1m]))', 'churn rate'),
        )
      )
      .addRow(
        g.row('Ingester')
        .addPanel(
          g.panel('Series per Query') +
          utils.latencyRecordingRulePanel('cortex_ingester_queried_series', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/ingester')], multiplier=1) +
          { yaxes: g.yaxes('short') },
        )
        .addPanel(
          g.panel('Chunks per Query') +
          utils.latencyRecordingRulePanel('cortex_ingester_queried_chunks', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/ingester')], multiplier=1) +
          { yaxes: g.yaxes('short') },
        )
        .addPanel(
          g.panel('Samples per Query') +
          utils.latencyRecordingRulePanel('cortex_ingester_queried_samples', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/ingester')], multiplier=1) +
          { yaxes: g.yaxes('short') },
        )
      )
      .addRow(
        g.row('Chunk Store')
        .addPanel(
          g.panel('Index Lookups per Query') +
          utils.latencyRecordingRulePanel('cortex_chunk_store_index_lookups_per_query', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/querier')], multiplier=1) +
          { yaxes: g.yaxes('short') },
        )
        .addPanel(
          g.panel('Series (pre-intersection) per Query') +
          utils.latencyRecordingRulePanel('cortex_chunk_store_series_pre_intersection_per_query', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/querier')], multiplier=1) +
          { yaxes: g.yaxes('short') },
        )
        .addPanel(
          g.panel('Series (post-intersection) per Query') +
          utils.latencyRecordingRulePanel('cortex_chunk_store_series_post_intersection_per_query', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/querier')], multiplier=1) +
          { yaxes: g.yaxes('short') },
        )
        .addPanel(
          g.panel('Chunks per Query') +
          utils.latencyRecordingRulePanel('cortex_chunk_store_chunks_per_query', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/querier')], multiplier=1) +
          { yaxes: g.yaxes('short') },
        )
      ),

    'frontend.json':
      g.dashboard('Frontend')
      .addMultiTemplate('cluster', 'kube_pod_container_info{image=~".*cortex.*"}', 'cluster')
      .addMultiTemplate('namespace', 'kube_pod_container_info{image=~".*cortex.*"}', 'namespace')
      .addRow(
        g.row('Cortex Reqs (cortex_gw)')
        .addPanel(
          g.panel('QPS') +
          g.qpsPanel('cortex_gw_request_duration_seconds_count{cluster=~"$cluster", job=~"($namespace)/cortex-gw"}')
        )
        .addPanel(
          g.panel('Latency') +
          utils.latencyRecordingRulePanel('cortex_gw_request_duration_seconds', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/cortex-gw')])
        )
      ),

    'ruler.json':
      g.dashboard('Cortex / Ruler')
      .addMultiTemplate('cluster', 'kube_pod_container_info{image=~".*cortex.*"}', 'cluster')
      .addMultiTemplate('namespace', 'kube_pod_container_info{image=~".*cortex.*"}', 'namespace')
      .addRow(
        g.row('Rule Evaluations')
        .addPanel(
          g.panel('EPS') +
          g.queryPanel('sum(rate(cortex_prometheus_rule_evaluations_total{cluster=~"$cluster", job=~"($namespace)/ruler"}[$__interval]))', 'rules processed'),
        )
        .addPanel(
          g.panel('Latency') +
          g.queryPanel(
            |||
              sum (rate(cortex_prometheus_rule_evaluation_duration_seconds_sum{cluster=~"$cluster", job=~"($namespace)/ruler"}[$__interval]))
                /
              sum (rate(cortex_prometheus_rule_evaluation_duration_seconds_count{cluster=~"$cluster", job=~"($namespace)/ruler"}[$__interval]))
            |||, 'average'
          ),
        )
      )
      .addRow(
        g.row('Group Evaluations')
        .addPanel(
          g.panel('Missed Iterations') +
          g.queryPanel('sum(rate(prometheus_rule_group_iterations_missed_total{cluster=~"$cluster", job=~"($namespace)/ruler"}[$__interval]))', 'iterations missed'),
        )
        .addPanel(
          g.panel('Latency') +
          g.queryPanel(
            |||
              sum (rate(cortex_prometheus_rule_group_duration_seconds_sum{cluster=~"$cluster", job=~"($namespace)/ruler"}[$__interval]))
                /
              sum (rate(cortex_prometheus_rule_group_duration_seconds_count{cluster=~"$cluster", job=~"($namespace)/ruler"}[$__interval]))
            |||, 'average'
          ),
        )
      ),

    'cortex-scaling.json':
      g.dashboard('Cortex / Scaling')
      .addMultiTemplate('cluster', 'kube_pod_container_info{image=~".*cortex.*"}', 'cluster')
      .addMultiTemplate('namespace', 'kube_pod_container_info{image=~".*cortex.*"}', 'namespace')
      .addRow(
        g.row('Workload-based scaling')
        .addPanel(
          g.panel('Workload-based scaling') + { sort: { col: 1, desc: false } } +
          g.tablePanel([
            |||
              sum by (cluster, namespace, deployment) (
                kube_deployment_spec_replicas{cluster=~"$cluster", namespace=~"$namespace", deployment=~"ingester|memcached"}
                or
                label_replace(
                  kube_statefulset_replicas{cluster=~"$cluster", namespace=~"$namespace", deployment=~"ingester|memcached"},
                  "deployment", "$1", "statefulset", "(.*)"
                )
              )
            |||,
            |||
              quantile_over_time(0.99, sum by (cluster, namespace, deployment) (label_replace(rate(cortex_distributor_received_samples_total{cluster=~"$cluster", namespace=~"$namespace"}[1m]), "deployment", "ingester", "cluster", ".*"))[1h:])
                * 3 / 80e3
            |||,
            |||
              label_replace(
                sum by(cluster, namespace) (
                  cortex_ingester_memory_series{cluster=~"$cluster", namespace=~"$namespace"}
                ) / 1e+6,
                "deployment", "ingester", "cluster", ".*"
              )
                or
              label_replace(
                sum by (cluster, namespace) (
                  4 * cortex_ingester_memory_series{cluster=~"$cluster", namespace=~"$namespace", job=~".+/ingester"}
                    *
                  cortex_ingester_chunk_size_bytes_sum{cluster=~"$cluster", namespace=~"$namespace", job=~".+/ingester"}
                    /
                  cortex_ingester_chunk_size_bytes_count{cluster=~"$cluster", namespace=~"$namespace", job=~".+/ingester"}
                )
                  /
                avg by (cluster, namespace) (memcached_limit_bytes{cluster=~"$cluster", namespace=~"$namespace", job=~".+/memcached"}),
                "deployment", "memcached", "namespace", ".*"
              )
            |||,
          ], {
            cluster: { alias: 'Cluster' },
            namespace: { alias: 'Namespace' },
            deployment: { alias: 'Deployment' },
            'Value #A': { alias: 'Current Replicas', decimals: 0 },
            'Value #B': { alias: 'Required Replicas, by ingestion rate', decimals: 0 },
            'Value #C': { alias: 'Required Replicas, by active series', decimals: 0 },
          })
        )
      )
      .addRow(
        (g.row('Resource-based scaling') + { height: '500px' })
        .addPanel(
          g.panel('Resource-based scaling') + { sort: { col: 1, desc: false } } +
          g.tablePanel([
            |||
              sum by (cluster, namespace, deployment) (
                kube_deployment_spec_replicas{cluster=~"$cluster", namespace=~"$namespace"}
                or
                label_replace(
                  kube_statefulset_replicas{cluster=~"$cluster", namespace=~"$namespace"},
                  "deployment", "$1", "statefulset", "(.*)"
                )
              )
            |||,
            |||
              sum by (cluster, namespace, deployment) (
                kube_deployment_spec_replicas{cluster=~"$cluster", namespace=~"$namespace"}
                or
                label_replace(
                  kube_statefulset_replicas{cluster=~"$cluster", namespace=~"$namespace"},
                  "deployment", "$1", "statefulset", "(.*)"
                )
              )
                *
              quantile_over_time(0.99, sum by (cluster, namespace, deployment) (label_replace(rate(container_cpu_usage_seconds_total{cluster=~"$cluster", namespace=~"$namespace"}[1m]), "deployment", "$1", "pod_name", "^(.*)-(?:([0-9]+)|([a-z0-9]+)-([a-z0-9]+))$"))[24h:])
                /
              sum by (cluster, namespace, deployment) (label_replace(kube_pod_container_resource_requests_cpu_cores{cluster=~"$cluster", namespace=~"$namespace"}, "deployment", "$1", "pod", "^(.*)-(?:([0-9]+)|([a-z0-9]+)-([a-z0-9]+))$"))
            |||,
            |||
              sum by (cluster, namespace, deployment) (
                kube_deployment_spec_replicas{cluster=~"$cluster", namespace=~"$namespace"}
                or
                label_replace(
                  kube_statefulset_replicas{cluster=~"$cluster", namespace=~"$namespace"},
                  "deployment", "$1", "statefulset", "(.*)"
                )
              )
                *
              quantile_over_time(0.99, sum by (cluster, namespace, deployment) (label_replace(container_memory_usage_bytes{cluster=~"$cluster", namespace=~"$namespace"}, "deployment", "$1", "pod_name", "^(.*)-(?:([0-9]+)|([a-z0-9]+)-([a-z0-9]+))$"))[24h:1m])
                /
              sum by (cluster, namespace, deployment) (label_replace(kube_pod_container_resource_requests_memory_bytes{cluster=~"$cluster", namespace=~"$namespace"}, "deployment", "$1", "pod", "^(.*)-(?:([0-9]+)|([a-z0-9]+)-([a-z0-9]+))$"))
            |||,
          ], {
            cluster: { alias: 'Cluster' },
            namespace: { alias: 'Namespace' },
            deployment: { alias: 'Deployment' },
            'Value #A': { alias: 'Current Replicas', decimals: 0 },
            'Value #B': { alias: 'Required Replicas, by CPU usage', decimals: 0 },
            'Value #C': { alias: 'Required Replicas, by Memory usage', decimals: 0 },
          })
        )
      ),
  },

  cortex_writes_dashboard::
    g.dashboard('Cortex / Writes')
    .addMultiTemplate('cluster', 'kube_pod_container_info{image=~".*cortex.*"}', 'cluster')
    .addMultiTemplate('namespace', 'kube_pod_container_info{image=~".*cortex.*"}', 'namespace')
    .addRow(
      (g.row('Headlines') +
       {
         height: '100px',
         showTitle: false,
       })
      .addPanel(
        g.panel('Samples / s') +
        g.statPanel('sum(rate(cortex_distributor_received_samples_total{cluster=~"$cluster", job=~"($namespace)/distributor"}[5m]))', format='reqps')
      )
      .addPanel(
        g.panel('Active Series') +
        g.statPanel(|||
          sum(cortex_ingester_memory_series{cluster=~"$cluster", job=~"($namespace)/ingester"}
          / on(namespace) group_left
          max by (namespace) (cortex_distributor_replication_factor{cluster=~"$cluster", job=~"($namespace)/distributor"}))
        |||, format='short')
      )
      .addPanel(
        g.panel('QPS') +
        g.statPanel('sum(rate(cortex_gw_request_duration_seconds_count{cluster=~"$cluster", job=~"($namespace)/cortex-gw", route="cortex-write"}[5m]))', format='reqps')
      )
    )
    .addRow(
      g.row('Distributor')
      .addPanel(
        g.panel('QPS') +
        g.qpsPanel('cortex_request_duration_seconds_count{cluster=~"$cluster", job=~"($namespace)/distributor"}')
      )
      .addPanel(
        g.panel('Latency') +
        utils.latencyRecordingRulePanel('cortex_request_duration_seconds', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/distributor')])
      )
    )
    .addRow(
      g.row('Ingester')
      .addPanel(
        g.panel('QPS') +
        g.qpsPanel('cortex_request_duration_seconds_count{cluster=~"$cluster", job=~"($namespace)/ingester",route="/cortex.Ingester/Push"}')
      )
      .addPanel(
        g.panel('Latency') +
        utils.latencyRecordingRulePanel('cortex_request_duration_seconds', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/ingester'), utils.selector.eq('route', '/cortex.Ingester/Push')])
      )
    ),

  cortex_reads_dashboard::
    g.dashboard('Cortex / Reads')
    .addMultiTemplate('cluster', 'kube_pod_container_info{image=~".*cortex.*"}', 'cluster')
    .addMultiTemplate('namespace', 'kube_pod_container_info{image=~".*cortex.*"}', 'namespace')
    .addRow(
      g.row('Querier')
      .addPanel(
        g.panel('QPS') +
        g.qpsPanel('cortex_request_duration_seconds_count{cluster=~"$cluster", job=~"($namespace)/querier"}')
      )
      .addPanel(
        g.panel('Latency') +
        utils.latencyRecordingRulePanel('cortex_request_duration_seconds', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/querier')])
      )
    )
    .addRow(
      g.row('Ingester')
      .addPanel(
        g.panel('QPS') +
        g.qpsPanel('cortex_request_duration_seconds_count{cluster=~"$cluster", job=~"($namespace)/ingester",route!~"/cortex.Ingester/Push|metrics|ready|traces"}')
      )
      .addPanel(
        g.panel('Latency') +
        utils.latencyRecordingRulePanel('cortex_request_duration_seconds', [utils.selector.re('cluster', '$cluster'), utils.selector.re('job', '($namespace)/ingester'), utils.selector.nre('route', '/cortex.Ingester/Push|metrics|ready')])
      )
    ),
}
