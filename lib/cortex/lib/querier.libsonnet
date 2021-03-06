{
  local configMap = $.core.v1.configMap,
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local deployment = $.apps.v1.deployment,
  local service = $.core.v1.service,

  querier_args::
    $._config.cortex_flags.common +
    $._config.cortex_flags.ring +
    $._config.cortex_flags.query +
    $._config.cortex_flags.distributor +
    $._config.cortex_flags.storage +
    $._config.cortex_flags.storageConfig +
    {
      target: 'querier',

      // Limit to N/2 worker threads per frontend, as we have two frontends.
      'querier.worker-parallelism': $._config.querier_concurrency / 2,
      'querier.frontend-address': 'query-frontend.%(namespace)s.svc.cluster.local:9095' % $._config,
      'querier.frontend-client.grpc-max-send-msg-size': 100 << 20,
    },

  querier_container::
    container.new('querier', $._images.querier) +
    container.withPorts([
      containerPort.newNamed(name='http-metrics', containerPort=80),
      containerPort.newNamed(name='grpc', containerPort=9095),
    ]) +
    container.withArgsMixin($.util.mapToFlags($.querier_args)) +
    $.util.resourcesRequests('100m', '100Mi') +
    $.util.resourcesLimits('200m', '250Mi'),

  querier_deployment:
    deployment.new('querier', $._config.querier_replicas, [
      $.querier_container,
    ]) +
    deployment.mixin.metadata.withNamespace($._config.namespace) +
    $.storage_config_mixin,

  querier_service:
    $.util.serviceFor($.querier_deployment) +
    service.mixin.metadata.withNamespace($._config.namespace),
}
