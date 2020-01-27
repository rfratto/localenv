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

  loki_config_map:
    configMap.new('loki-config') +
    configMap.withData({
      'config.yaml': k.util.manifestYaml($.loki_config),
    }),

  loki_container::
    container.new('loki', $._images.loki) +
    container.withPorts([
      containerPort.newNamed('http-metrics', 80),
      containerPort.newNamed('grpc', 9095),
    ]) +
    container.withVolumeMountsMixin(
      volumeMount.new('loki-data', '/tmp/loki'),
    ) +
    container.withArgsMixin(
      k.util.mapToFlags($._config.loki.commonArgs),
    ),

  loki_pvc:
    { apiVersion: 'v1', kind: 'PersistentVolumeClaim' } +
    pvc.new() +
    pvc.mixin.metadata.withName('loki-data') +
    pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
    pvc.mixin.spec.resources.withRequests({ storage: '10Gi' }),

  loki_deployment:
    deployment.new('loki', 1, [
      $.loki_container,
    ]) +
    deployment.mixin.spec.template.spec.withVolumesMixin([
      volume.fromPersistentVolumeClaim('loki-data', 'loki-data'),
    ]) +
    k.util.configMapVolumeMount($.loki_config_map, '/etc/loki') +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(4800),

  loki_service:
    k.util.serviceFor($.loki_deployment),
}
