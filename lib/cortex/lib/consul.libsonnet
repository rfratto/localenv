local cfg = import '../config.libsonnet';
local consul = import 'consul/consul.libsonnet';

consul + cfg {}
