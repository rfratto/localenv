(import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet') +
(import 'images.libsonnet') +
{
  _util:: {
    configMapVolumeMount(configMap, path, volumeMountMixin={})::
      local name = configMap.metadata.name,
            hash = std.md5(std.toString(configMap)),
            container = $.core.v1.container,
            deployment = $.apps.v1.deployment,
            volumeMount = $.core.v1.volumeMount,
            volume = $.core.v1.volume,
            addMount(c) = c + container.withVolumeMountsMixin(
        volumeMount.new(name, path) +
        volumeMountMixin,
      );

      deployment.mapContainers(addMount) +
      deployment.mixin.spec.template.spec.withVolumesMixin([
        volume.fromConfigMap(name, name) + {
          configMap+: {
            defaultMode: std.parseOctal('0775'),
          },
        },
      ]) +
      deployment.mixin.spec.template.metadata.withAnnotationsMixin({
        ['%s-hash' % name]: hash,
      }),
  },

  local configMap = $.core.v1.configMap,
  local pvc = $.core.v1.persistentVolumeClaim,
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local deployment = $.apps.v1.deployment,
  local volumeMount = $.core.v1.volumeMount,
  local volume = $.core.v1.volume,

  openvpn_config_map:
    configMap.new('openvpn-config') +
    configMap.withData({
      'configure.sh': (importstr './files/configure.sh'),
      'newClientCert.sh': (importstr './files/newClientCert.sh'),
      'openvpn.conf': (importstr './files/openvpn.conf'),
      'revokeClientCert.sh': (importstr './files/revokeClientCert.sh'),
      'setup-certs.sh': (importstr './files/setup-certs.sh'),
    }),

  openvpn_container::
    container.new('openvpn', $._images.openvpn) +
    { securityContext: { capabilities: { add: ['NET_ADMIN'] } } } +
    container.withEnvMixin([{
      name: 'PODIPADDR',
      valueFrom: { fieldRef: { fieldPath: 'status.podIP' } },
    }]) +
    container.withCommand([
      '/etc/openvpn/setup/configure.sh',
    ]) +
    container.withPorts([
      containerPort.newNamed('openvpn', 443),
    ]) +
    container.withVolumeMountsMixin([
      volumeMount.new('openvpn-certs', '/etc/openvpn/certs'),
    ]),

  certs_pvc:
    { apiVersion: 'v1', kind: 'PersistentVolumeClaim' } +
    pvc.new() +
    pvc.mixin.metadata.withName('openvpn-certs') +
    pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
    pvc.mixin.spec.resources.withRequests({ storage: '10Gi' }),

  openvpn_deployment:
    deployment.new('openvpn', 1, [
      $.openvpn_container,
    ]) +
    deployment.mixin.spec.template.spec.withVolumesMixin([
      volume.fromPersistentVolumeClaim('openvpn-certs', 'openvpn-certs'),
    ]) +
    $._util.configMapVolumeMount($.openvpn_config_map, '/etc/openvpn/setup') +
    deployment.mixin.spec.template.spec.withTerminationGracePeriodSeconds(4800),

  openvpn_service:
    k.util.serviceFor($.openvpn_deployment),
}
