(import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet') +
(import 'config.libsonnet') +
(import 'loki-config.libsonnet') +
(import 'images.libsonnet') +
{
  local configMap = $.core.v1.configMap,
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local pvc = $.core.v1.persistentVolumeClaim,
  local deployment = $.apps.v1.deployment,
  local volumeMount = $.core.v1.volumeMount,
  local volume = $.core.v1.volume,
  local service = $.core.v1.service,

  loki_config_map:
    configMap.new('loki-config') +
    configMap.mixin.metadata.withNamespace($._config.namespace) +
    configMap.withData({
      'config.yaml': $.util.manifestYaml($.loki_config),
    }),

  loki_container::
    container.new('loki', $._images.loki) +
    container.withPorts([
      containerPort.newNamed(name='http-metrics', containerPort=80),
      containerPort.newNamed(name='grpc', containerPort=9095),
    ]) +
    container.withVolumeMountsMixin(
      volumeMount.new('loki-data', '/tmp/loki'),
    ) +
    container.withArgsMixin(
      $.util.mapToFlags($._config.loki.commonArgs),
    ),

  loki_pvc:
    { apiVersion: 'v1', kind: 'PersistentVolumeClaim' } +
    pvc.new() +
    pvc.mixin.metadata.withName('loki-data') +
    pvc.mixin.metadata.withNamespace($._config.namespace) +
    pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
    pvc.mixin.spec.resources.withRequests({ storage: '10Gi' }),

  loki_deployment:
    deployment.new('loki', 1, [
      $.loki_container,
    ]) +
    deployment.mixin.metadata.withNamespace($._config.namespace) +
    deployment.mixin.spec.template.spec.withVolumesMixin([
      volume.fromPersistentVolumeClaim('loki-data', 'loki-data'),
    ]) +
    $.util.configMapVolumeMount($.loki_config_map, '/etc/loki') +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(4800),

  loki_service:
    $.util.serviceFor($.loki_deployment) +
    service.mixin.metadata.withNamespace($._config.namespace),
}
