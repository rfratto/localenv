{
  grafana_config+:: {
    sections: {
      'auth.anonymous': {
        enabled: true,
        org_role: 'Admin',
      },
      server: {
        http_port: 80,
        root_url: $._config.grafana_root_url,
      },
      analytics: {
        reporting_enabled: false,
      },
      users: {
        default_theme: 'dark',
      },
      explore+: {
        enabled: true,
      },
    },
  },

  local configMap = $.core.v1.configMap,

  grafana_config_map:
    configMap.new('grafana-config') +
    configMap.withData({ 'grafana.ini': std.manifestIni($.grafana_config) }),

  dashboards+:: {},
  grafana_dashboards+:: {},
  grafanaDashboards+:: $.dashboards + $.grafana_dashboards,

  grafana_dashboard_config_map:
    if $._config.dashboard_config_maps > 0
    then {}
    else
      configMap.new('dashboards') +
      configMap.withDataMixin({
        [name]: std.toString(
          $.grafanaDashboards[name] +
          { uid: std.substr(std.md5(std.toString($.grafanaDashboards[name])), 0, 9) }
        )
        for name in std.objectFields($.grafanaDashboards)
      }),

  grafana_dashboards_config_maps: {
    ['dashboard-%d' % shard]:
      configMap.new('dashboards-%d' % shard) +
      configMap.withDataMixin({
        [name]: std.toString(
          $.grafanaDashboards[name] +
          { uid: std.substr(std.md5(std.toString($.grafanaDashboards[name])), 0, 9) }
        )
        for name in std.objectFields($.grafanaDashboards)
        if std.codepoint(std.md5(name)[1]) % $._config.dashboard_config_maps == shard
      })
    for shard in std.range(0, $._config.dashboard_config_maps - 1)
  },

  grafana_datasource_config_map:
    configMap.new('grafana-datasources') +
    configMap.withDataMixin($.grafana_datasources),

  grafana_dashboard_provisioning_config_map:
    configMap.new('grafana-dashboard-provisioning') +
    configMap.withData({
      'dashboards.yml': $.util.manifestYaml({
        apiVersion: 1,
        providers: [{
          name: 'dashboards',
          orgId: 1,
          folder: '',
          type: 'file',
          disableDeletion: true,
          editable: false,
          options: {
            path: '/grafana/dashboards',
          },
        }],
      }),
    }),


  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,

  grafana_container::
    container.new('grafana', $._images.grafana) +
    container.withPorts(containerPort.new('grafana', 80)) +
    container.withCommand([
      '/usr/share/grafana/bin/grafana-server',
      '--homepath=/usr/share/grafana',
      '--config=/etc/grafana-config/grafana.ini',
    ]) +
    $.util.resourcesRequests('10m', '40Mi'),

  local deployment = $.apps.v1.deployment,

  grafana_deployment:
    deployment.new('grafana', 1, [$.grafana_container]) +
    deployment.mixin.spec.template.spec.securityContext.withRunAsUser(0) +
    $.util.configMapVolumeMount(self.grafana_config_map, '/etc/grafana-config') +
    $.util.configMapVolumeMount(self.grafana_datasource_config_map, '%(provisioning_dir)s/datasources' % $._config.grafana) +
    $.util.configMapVolumeMount(self.grafana_dashboard_provisioning_config_map, '%(provisioning_dir)s/dashboards' % $._config.grafana) +
    (
      if $._config.dashboard_config_maps == 0
      then $.util.configMapVolumeMount(self.grafana_dashboard_config_map, '/grafana/dashboards')
      else
        std.foldr(
          function(m, acc) m + acc,
          [
            $.util.configVolumeMount('dashboards-%d' % shard, '/grafana/dashboards/%d' % shard)
            for shard in std.range(0, $._config.dashboard_config_maps - 1)
          ],
          {}
        )
    ) +
    $.util.podPriority('critical'),

  grafana_service:
    $.util.serviceFor($.grafana_deployment),
}
