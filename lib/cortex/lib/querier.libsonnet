local cfg = import '../config.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';

local configMap = k.core.v1.configMap;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local deployment = k.apps.v1beta1.deployment;
local service = k.core.v1.service;

cfg {
  querier_args::
    $._config.cortex_flags.common +
    $._config.cortex_flags.ring +
    $._config.cortex_flags.storage +
    $._config.cortex_flags.query +
    $._config.cortex_flags.distributor +
    {
      target: 'querier',
    },

  querier_container::
    container.new('querier', $._images.querier) +
    container.withPorts([
      containerPort.newNamed('http-metrics', 80),
      containerPort.newNamed('grpc', 9095),
    ]) +
    container.withArgsMixin(k.util.mapToFlags($.querier_args)) +
    k.util.resourcesRequests('250m', '250Mi') +
    k.util.resourcesLimits('500m', '500Mi'),

  querier_deployment:
    deployment.new('querier', 3, [
      $.querier_container,
    ]) +
    $.storage_config_mixin,


  querier_service:
    k.util.serviceFor($.querier_deployment),
}
