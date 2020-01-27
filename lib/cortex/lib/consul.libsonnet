local cfg = import '../config.libsonnet';
local consul = import 'github.com/grafana/jsonnet-libs/consul/consul.libsonet';


consul + cfg {}
