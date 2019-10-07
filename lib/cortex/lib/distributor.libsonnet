local cfg = import '../config.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';

local configMap = k.core.v1.configMap;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local deployment = k.apps.v1beta1.deployment;
local service = k.core.v1.service;

cfg {
  distributor_args::
    $._config.cortex_flags.common +
    $._config.cortex_flags.ring +
    $._config.cortex_flags.distributor +
    {
      target: 'distributor',

      'distributor.ingestion-rate-limit': 10000,
      'distributor.ingestion-burst-size': 20000,
      'validation.reject-old-samples': true,
      'validation.reject-old-samples.max-age': '6h',
      'distributor.remote-timeout': '20s',
    },

  distributor_container::
    container.new('distributor', $._images.distributor) +
    container.withPorts([
      containerPort.newNamed('http-metrics', 80),
      containerPort.newNamed('grpc', 9095),
    ]) +
    container.withArgsMixin(k.util.mapToFlags($.distributor_args)) +
    k.util.resourcesRequests('250m', '250Mi') +
    k.util.resourcesLimits('500m', '500Mi'),

  distributor_deployment:
    deployment.new('distributor', 3, [
      $.distributor_container,
    ]) +
    deployment.mixin.spec.withMinReadySeconds(60) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxSurge(0) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxUnavailable(1) +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(4800),

  distributor_service:
    k.util.serviceFor($.distributor_deployment) +
    service.mixin.spec.withClusterIp('None'),
}
