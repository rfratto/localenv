{
  local configMap = $.core.v1.configMap,
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local deployment = $.apps.v1.deployment,
  local service = $.core.v1.service,

  query_frontend_args::
    {
      target: 'query-frontend',

      // No auth in local Cortex
      'auth.enabled': false,

      // Need log.level=debug so all queries are logged, needed for analyse.py.
      'log.level': 'debug',

      // Increase HTTP server response write timeout, as we were seeing some
      // queries that return a lot of data timeing out.
      'server.http-write-timeout': '1m',

      // Split long queries up into multiple day-long queries.
      'querier.split-queries-by-day': true,

      // Cache query results.
      'querier.align-querier-with-step': true,

      // Compress HTTP responses; improves latency for very big results and slow
      // connections.
      'querier.compress-http-responses': true,

      // So it can recieve big responses from the querier.
      'server.grpc-max-recv-msg-size-bytes': 100 << 20,

      // Limit queries to 1 day
      'store.max-query-length': '24h',
    },

  query_frontend_container::
    container.new('query-frontend', $._images.query_frontend) +
    container.withPorts([
      containerPort.newNamed(name='http-metrics', containerPort=80),
      containerPort.newNamed(name='grpc', containerPort=9095),
    ]) +
    container.withArgsMixin($.util.mapToFlags($.query_frontend_args)) +
    $.util.resourcesRequests('100m', '100Mi') +
    $.util.resourcesLimits('200m', '250Mi'),

  query_frontend_deployment:
    deployment.new('query-frontend', 2, [
      $.query_frontend_container,
    ]) +
    deployment.mixin.metadata.withNamespace($._config.namespace) +
    $.storage_config_mixin,

  query_frontend_service:
    $.util.serviceFor($.query_frontend_deployment) +
    service.mixin.metadata.withNamespace($._config.namespace),
}
