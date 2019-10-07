{
  prometheus_config:: {
    global: {
      scrape_interval: '15s',
    },

    rule_files: [
      'recording.rules',
    ],

    scrape_configs: [
      {
        job_name: 'kubernetes-pods',
        kubernetes_sd_configs: [{
          role: 'pod',
        }],

        tls_config: {
          ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
          insecure_skip_verify: $._config.prometheus.insecure_skip_verify,
        },
        bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token',

        // You can specify the following annotations on pods:
        //   prometheus.io.scrape: false - don't scrape this pod
        //   prometheus.io.scheme: https - use https for scraping
        //   prometheus.io.port - scrape this port
        //   prometheus.io.path - scrape this path
        //   prometheus.io.param-<parameter> - send ?parameter=value with the scrape
        relabel_configs: [
          // Drop anything annotated with prometheus.io.scrape=false
          {
            source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scrape'],
            action: 'drop',
            regex: 'false',
          },

          // Drop any endpoint whose pod port name does not end with metrics
          {
            source_labels: ['__meta_kubernetes_pod_container_port_name'],
            action: 'keep',
            regex: '.*-metrics',
          },

          // Allow pods to override the scrape scheme with
          // prometheus.io.scheme=https
          {
            source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_scheme'],
            action: 'replace',
            target_label: '__scheme__',
            regex: '^(https?)$',
            replacement: '$1',
          }

          // Allow service to override the scrape path with
          // prometheus.io.path=<path>
          {
            source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_path'],
            action: 'replace',
            target_label: '__metrics_path__',
            regex: '^(.+)$',
            replacement: '$1',
          },

          // Allow service to override the scrape port with
          // prometheus.io.port=<port>
          {
            source_labels: ['__meta_kubernetes_pod_annotation_prometheus_io_port'],
            action: 'replace',
            target_label: '__address__',
            regex: '(.+?)(\\:\\d+)?;(\\d+)',
            replacement: '$1:$3',
          },

          // Drop pods without a name label
          {
            source_labels: ['__meta_kubernetes_pod_label_name'],
            action: 'drop',
            regex: '^$',
          },

          // Rename jobs to be <namespace>/<name, from pod name label>
          {
            source_labels: ['__meta_kubernetes_namespace', '__meta_kubernetes_pod_label_name'],
            action: 'replace',
            separator: '/',
            target_label: 'job',
            replacement: '$1',
          },

          // But also include the namespace as a separate label, for routing alerts
          {
            source_labels: ['__meta_kubernetes_namespace'],
            action: 'replace',
            target_label: 'namespace',
          },

          // Rename instances to be the pod name
          {
            source_labels: ['__meta_kubernetes_pod_name'],
            action: 'replace',
            target_label: 'instance',
          },

          {
            regex: '__meta_kubernetes_pod_annotation_prometheus_io_param_(.+)',
            action: 'labelmap',
            replacement: '__param_$1',
          },

          // Drop pods with phase Succeeded or Failed
          {
            source_labels: ['__meta_kubernetes_pod_phase'],
            action: 'drop',
            regex: '^(Succeeded|Failed)$',
          },
        ],
      },

      // A separate scrape config for kube-state-metrics which doesn't add
      // a namespace label, instead taking the namespace label from the exported
      // timeseries. This prevents the exported namespace label being renamed
      // to exported_namespace, and allows us to route alerts based on namespace.
      {
        job_name: '%s/kube-state-metrics' % $._config.namespace,
        kubernetes_sd_configs: [{
          role: 'pod',
          namespaces: {
            names: [$._config.namespace],
          },
        }],

        tls_config: {
          ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
          insecure_skip_verify: $._config.prometheus.insecure_skip_verify,
        },
        bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token',

        relabel_configs: [
          // Drop anything who's service is not kube-state-metrics
          // Rename jobs to be <namespace>/<name, from pod name label>
          {
            source_labels: ['__meta_kubernetes_pod_label_name'],
            regex: 'kube-state-metrics',
            action: 'keep',
          },

          // Rename instances to be the pod name.
          // As the scrape two ports of KSM, include the port name in the instance
          // name.  Otherwise alerts about scrape failures and timeouts won't work.
          {
            source_labels: ['__meta_kubernetes_pod_name', '__meta_kubernetes_pod_container_port_name'],
            action: 'replace',
            separator: ':',
            target_label: 'instance',
          },
        ],
      },

      // A separate scrape config for node-exported which maps the nodename onto
      // the instance label.
      {
        job_name: '%s/node-exporter' % $._config.namespace,
        kubernetes_sd_configs: [{
          role: 'pod',
          namespaces: {
            names: [$._config.namespace],
          },
        }],

        tls_config: {
          ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
          insecure_skip_verify: $._config.prometheus.insecure_skip_verify,
        },
        bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token',

        relabel_configs: [
          // Drop anything who's name is not node-exporter.
          {
            source_labels: ['__meta_kubernetes_pod_label_name'],
            regex: 'node-exporter',
            action: 'keep',
          },

          // Rename instances to be the node name.
          {
            source_labels: ['__meta_kubernetes_pod_node_name'],
            action: 'replace',
            target_label: 'instance',
          },

          // But also include the namespace as a separate label, for routing alerts
          {
            source_labels: ['__meta_kubernetes_namespace'],
            action: 'replace',
            target_label: 'namespace',
          },
        ],
      },

      // A scrape config to gather all kubelet metrics.
      {
        job_name: 'kube-system/kubelet',
        kubernetes_sd_configs: [{
          role: 'node',
        }],

        tls_config: {
          ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
          insecure_skip_verify: $._config.prometheus.insecure_skip_verify,
        },
        bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token',

        relabel_configs: [
          {
            target_label: '__address__',
            replacement: $._config.prometheus.api_server_address,
          },
          {
            target_label: '__scheme__',
            replacement: 'https',
          },
          {
            source_labels: ['__meta_kubernetes_node_name'],
            regex: '(.+)',
            target_label: '__metrics_path__',
            replacement: '/api/v1/nodes/${1}/proxy/metrics',
          },
        ],
      },

      // As of k8s 1.7.3, cAdvisor metrics are available via kubelet using the /metrics/cadvisor path
      {
        job_name: 'kube-system/cadvisor',
        kubernetes_sd_configs: [{
          role: 'node',
        }],
        scheme: 'https',

        bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token',
        tls_config: {
          ca_file: '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
          insecure_skip_verify: $._config.prometheus.insecure_skip_verify,
        },

        relabel_configs: [
          {
            target_label: '__address__',
            replacement: 'kubernetes.default.svc:443',
          },
          {
            source_labels: ['__meta_kubernetes_node_name'],
            regex: '(.+)',
            target_label: '__metrics_path__',
            replacement: '/api/v1/nodes/${1}/proxy/metrics/cadvisor',
          },
        ],

        metric_relabel_configs: [
          // Drop container_* metrics with no image.
          {
            source_labels: ['__name__', 'image'],
            regex: 'container_([a-z_]+);',
            action: 'drop',
          },

          // Drop a bunch of metrics which are disabled but still sent, see
          // https://github.com/google/cadvisor/issues/1925.
          {
            source_labels: ['__name__'],
            regex: 'container_(network_tcp_usage_total|network_udp_usage_total|tasks_state|cpu_load_average_10s)',
            action: 'drop',
          },
        ],
      },
    ],
  },
}
