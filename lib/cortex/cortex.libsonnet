local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local consul = import 'github.com/grafana/jsonnet-libs/consul/consul.libsonet';

k +
consul +
(import 'images.libsonnet') +
(import 'config.libsonnet') +
(import 'lib/distributor.libsonnet') +
(import 'lib/ingester.libsonnet') +
(import 'lib/table-manager.libsonnet') +
(import 'lib/querier.libsonnet') +
(import 'lib/query-frontend.libsonnet')
