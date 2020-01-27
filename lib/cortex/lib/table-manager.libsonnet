{
  local configMap = $.core.v1.configMap,
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local deployment = $.apps.v1.deployment,
  local service = $.core.v1.service,

  table_manager_args::
    $._config.cortex_flags.storageConfig +
    {
      target: 'table-manager',

      'dynamodb.poll-interval': '1m',
      'dynamodb.periodic-table.grace-period': '3h',

      'table-manager.retention-deletes-enabled': true,
      'table-manager.retention-period': '48h',
    },

  table_manager_container::
    container.new('table-manager', $._images.table_manager) +
    container.withPorts([
      containerPort.newNamed('http-metrics', 80),
      containerPort.newNamed('grpc', 9095),
    ]) +
    container.withArgsMixin(k.util.mapToFlags($.table_manager_args)) +
    k.util.resourcesRequests('100m', '100Mi') +
    k.util.resourcesLimits('200m', '200Mi'),

  table_manager_deployment:
    deployment.new('table-manager', 1, [$.table_manager_container]) +
    $.storage_config_mixin,

  table_manager_service:
    k.util.serviceFor($.table_manager_deployment),
}
