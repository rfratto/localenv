{
  local configMap = $.core.v1.configMap,
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local deployment = $.apps.v1.deployment,
  local service = $.core.v1.service,

  ingester_args::
    $._config.cortex_flags.common +
    $._config.cortex_flags.ring +
    $._config.cortex_flags.storage +
    $._config.cortex_flags.storageConfig +
    {
      target: 'ingester',

      'distributor.replication-factor': $._config.replication_factor,

      'ingester.num-tokens': 128,
      'ingester.join-after': '30s',
      'ingester.max-transfer-retries': 60,
      'ingester.claim-on-rollout': true,
      'ingester.heartbeat-period': '15s',

      'ingester.retain-period': '15m',
      'ingester.max-chunk-age': '6h',
      'ingester.normalise-tokens': true,
      'ingester.flush-op-timeout': '5m',
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
    k.util.resourcesRequests('100m', '100Mi') +
    k.util.resourcesLimits('200m', '250Mi'),

  ingester_deployment:
    deployment.new('ingester', $._config.ingester_replicas, [
      $.ingester_container,
    ]) +
    $.storage_config_mixin +
    deployment.mixin.spec.withMinReadySeconds(15) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxSurge(0) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxUnavailable(1) +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(4800),

  ingester_service:
    k.util.serviceFor($.ingester_deployment),
}
