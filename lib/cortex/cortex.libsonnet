local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

k +
(import 'lib/consul.libsonnet') +
(import 'lib/distributor.libsonnet') +
(import 'lib/ingester.libsonnet') +
//(import 'lib/table-manager.libsonnet') +
(import 'lib/querier.libsonnet') +
(import 'lib/query-frontend.libsonnet') +
(import 'images.libsonnet') +
(import 'config.libsonnet')
