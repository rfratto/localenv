local consul = import 'consul/consul.libsonnet';

{
  _images+:: consul._images {
    cortex: 'grafana/cortex-cortex:r60-e25e04b6',

    distributor: self.cortex,
    ingester: self.cortex,
    querier: self.cortex,
    query_frontend: self.cortex,
    table_manager: self.cortex,
  },
}
