{
  _config+:: {
    admin_services+: [
      { title: 'Prometheus', path: 'prometheus', url: '%s/prometheus/' % $._config.prometheus.external_hostname },
    ],

    nodeExporterSelector: 'job="%s/node-exporter"' % $._config.namespace,  // Also used by node-mixin.

    prometheus: {
      name: 'prometheus',

      api_server_address: 'kubernetes.default.svc.cluster.local:443',
      insecure_skip_verify: false,
      external_hostname: 'http://prometheus.%(namespace)s.svc.cluster.local' % $._config,
      path: '/prometheus/',
      port: 80,
      web_route_prefix: self.path,
      retention: '15d',
    },
  },
}
