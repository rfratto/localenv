(import 'dashboards.libsonnet') +
(import 'recording_rules.libsonnet') +
{
  _config+:: {
    admin_services+: [
      {
        title: 'Cortex / Ring (distributor)',
        path: 'cortex/distributor/ring',
        url: 'http://distributor.cortex.svc.cluster.local/ring',
        custom: |||
          proxy_redirect "/" "$scheme://$http_host/cortex/distributor/";
        |||,
      },
      {
        title: 'Cortex / Ring (querier)',
        path: 'cortex/querier/ring',
        url: 'http://querier.cortex.svc.cluster.local/ring',
        custom: |||
          proxy_redirect "/" "$scheme://$http_host/cortex/querier/";
        |||,
      },
    ],
  },
}
