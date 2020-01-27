(import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet') +
(import 'config.libsonnet') +
(import 'images.libsonnet') +
{
  local configMap = $.core.v1.configMap,
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local pvc = $.core.v1.persistentVolumeClaim,
  local deployment = $.apps.v1.deployment,
  local volumeMount = $.core.v1.volumeMount,
  local volume = $.core.v1.volume,

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
