{
  _config+:: {
    // Optionally shard dashboards into multiple config maps.
    // Set to the number of desired config maps.  0 to disable.
    dashboard_config_maps: 0,

    grafana: {
      provisioning_dir: '/etc/grafana/provisioning',
    },

    grafana_root_url: 'http://nginx.%(namespace)s.svc.cluster.local/grafana' % $._config,

    admin_services+: [
      { title: 'Grafana', path: 'grafana', url: 'http://grafana.%(namespace)s.svc.cluster.local/' % $._config, allowWebsockets: true },
    ],
  },
}
