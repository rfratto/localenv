{
  _config+:: {
    grafana: {
      provisioning_dir: '/etc/grafana/provisioning',
    },

    grafana_root_url: 'http://nginx.%(namespace)s.svc.cluster.local/grafana' % $._config,

    admin_services+: [
      { title: 'Grafana', path: 'grafana', url: 'http://grafana.%(namespace)s.svc.cluster.local/' % $._config, allowWebsockets: true },
    ],
  },
}
