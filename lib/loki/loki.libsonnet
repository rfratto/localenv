local k = import 'ksonnet-util/kausal.libsonnet';
local config = import 'config.libsonnet';
local loki_config = import 'loki-config.libsonnet';
local images = import 'images.libsonnet';

local configMap = k.core.v1.configMap;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local pvc = k.core.v1.persistentVolumeClaim;
local deployment = k.apps.v1beta1.deployment;
local volumeMount = k.core.v1.volumeMount;
local volume = k.core.v1.volume;

config + images + loki_config +
{
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
