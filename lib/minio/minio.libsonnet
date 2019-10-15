local k = import 'ksonnet-util/kausal.libsonnet';
local config = import 'config.libsonnet';
local images = import 'images.libsonnet';

local configMap = k.core.v1.configMap;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local pvc = k.core.v1.persistentVolumeClaim;
local deployment = k.apps.v1beta1.deployment;
local volumeMount = k.core.v1.volumeMount;
local volume = k.core.v1.volume;

config + images +
{
  minio_container::
    container.new('minio', $._images.minio) +
    container.withPorts([
      containerPort.newNamed('tcp', 9000),
    ]) +
    container.withArgs([
      'server',
      '/data',
    ]) +
    container.withEnvMap({
      'MINIO_ACCESS_KEY': 'admin',
      'MINIO_SECRET_KEY': 'password',
    }) +
    container.withVolumeMountsMixin(
      volumeMount.new('minio-data', '/data'),
    ) +
    k.util.resourcesRequests('150m', '250Mi') +
    k.util.resourcesLimits('1000m', '750Mi'),

  minio_pvc:
    { apiVersion: 'v1', kind: 'PersistentVolumeClaim' } +
    pvc.new() +
    pvc.mixin.metadata.withName('minio-data') +
    pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
    pvc.mixin.spec.resources.withRequests({ storage: '10Gi' }),

  minio_deployment:
    deployment.new('minio', 1, [
      $.minio_container,
    ]) +
    deployment.mixin.spec.template.spec.withVolumesMixin([
      volume.fromPersistentVolumeClaim('minio-data', 'minio-data'),
    ]) +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(180),

  minio_service:
    k.util.serviceFor($.minio_deployment),
}
