{
  local configMap = $.core.v1.configMap,
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local deployment = $.apps.v1.deployment,
  local service = $.core.v1.service,

  distributor_args::
    $._config.cortex_flags.common +
    $._config.cortex_flags.ring +
    $._config.cortex_flags.distributor +
    {
      target: 'distributor',

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
    k.util.resourcesRequests('100m', '100Mi') +
    k.util.resourcesLimits('200m', '250Mi'),

  distributor_deployment:
    deployment.new('distributor', $._config.distributor_replicas, [
      $.distributor_container,
    ]) +
    deployment.mixin.spec.withMinReadySeconds(60) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxSurge(0) +
    deployment.mixin.spec.strategy.rollingUpdate.withMaxUnavailable(1) +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(4800),

  distributor_service:
    k.util.serviceFor($.distributor_deployment),
}
