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
  scylla_container::
    container.new('scylla', $._images.scylla) +
    container.withPorts([
      containerPort.newNamed('comm', 7000),
      containerPort.newNamed('proto', 9042),
      containerPort.newNamed('jmx', 7199),
    ]) +
    container.withVolumeMountsMixin(
      volumeMount.new('scylla-data', '/var/lib/scylla'),
    ) +
    k.util.resourcesRequests('150m', '250Mi') +
    k.util.resourcesLimits('500m', '750Mi'),

  scylla_pvc:
    { apiVersion: 'v1', kind: 'PersistentVolumeClaim' } +
    pvc.new() +
    pvc.mixin.metadata.withName('scylla-data') +
    pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
    pvc.mixin.spec.resources.withRequests({ storage: '10Gi' }),

  scylla_deployment:
    deployment.new('scylla', 1, [
      $.scylla_container,
    ]) +
    deployment.mixin.spec.template.spec.withVolumesMixin([
      volume.fromPersistentVolumeClaim('scylla-data', 'scylla-data'),
    ]) +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(180),

  scylla_service:
    k.util.serviceFor($.scylla_deployment),
}
