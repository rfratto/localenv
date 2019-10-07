{
  // extend with calls from $.grafana.datasource.new
  grafana_datasources+::
    $.grafana.datasource.new(
      'Prometheus',
      'http://prometheus.%s.svc.cluster.local/prometheus' % $._config.namespace,
      true,
    ),

  grafana:: {
    datasource:: {
      // new creates a new prometheus datasource.
      new(name, url, default=false, method='GET'):: {
        ['%s.yml' % name]: $.util.manifestYaml({
          apiVersion: 1,
          datasources: [{
            name: name,
            type: 'prometheus',
            access: 'proxy',
            url: url,
            isDefault: default,
            version: 1,
            editable: false,
            jsonData: {
              httpMethod: method,
            },
          }],
        }),
      },
    },
  },


}
