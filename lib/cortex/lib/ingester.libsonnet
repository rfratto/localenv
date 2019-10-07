local cfg = import '../config.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';

local configMap = k.core.v1.configMap;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local deployment = k.apps.v1beta1.deployment;
local service = k.core.v1.service;

cfg {
  ingester_args::
    $._config.cortex_flags.common +
    $._config.cortex_flags.ring +
    $._config.cortex_flags.storage +
    {
      target: 'ingester',

      'ingester.num-tokens': 128,
      'ingester.join-after': '30s',
      'ingester.max-transfer-retries': 60,
      'ingester.claim-on-rollout': true,
      'ingester.heartbeat-period': '15s',
      'ingester.retain-period': '15m',
      'ingester.max-chunk-age': '6h',
    },

  ingester_container::
    container.new('ingester', $._images.ingester) +
    container.withPorts([
      containerPort.newNamed('http-metrics', 80),
      containerPort.newNamed('grpc', 9095),
    ]) +
    container.withArgsMixin(k.util.mapToFlags($.ingester_args)) +
    container.mixin.readinessProbe.httpGet.withPath('/ready') +
    container.mixin.readinessProbe.httpGet.withPort(80) +
    container.mixin.readinessProbe.withInitialDelaySeconds(15) +
    container.mixin.readinessProbe.withTimeoutSeconds(1) +
    k.util.resourcesRequests('250m', '250Mi') +
    k.util.resourcesLimits('500m', '500Mi'),

  ingester_deployment:
    deployment.new('ingester', 5, [
      $.ingester_container,
    ]) +
    $.storage_config_mixin +
    deployment.mixin.spec.withMinReadySeconds(60) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxSurge(0) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxUnavailable(1) +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(4800),

  ingester_service:
    k.util.serviceFor($.ingester_deployment),
}
