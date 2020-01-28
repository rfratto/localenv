local consul = import
  'github.com/grafana/jsonnet-libs/consul/consul.libsonnet';

consul {
  local configMap = $.core.v1.configMap,
  consul_config_map+:
    configMap.mixin.metadata.withNamespace($._config.namespace),

  local deployment = $.apps.v1.deployment,
  consul_deployment+:
    deployment.mixin.metadata.withNamespace($._config.namespace),

  local service = $.core.v1.service,
  consul_service+:
    service.mixin.metadata.withNamespace($._config.namespace),
}
