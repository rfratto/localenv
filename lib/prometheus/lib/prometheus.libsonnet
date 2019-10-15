local config = import 'prometheus-config.libsonnet';

config {
  local policyRule = $.rbac.v1beta1.policyRule,

  prometheus_rbac:
    $.util.rbac($._config.prometheus.name, [
      policyRule.new() +
      policyRule.withApiGroups(['']) +
      policyRule.withResources(['nodes', 'nodes/proxy', 'services', 'endpoints', 'pods']) +
      policyRule.withVerbs(['get', 'list', 'watch']),

      policyRule.new() +
      policyRule.withNonResourceUrls('/metrics') +
      policyRule.withVerbs(['get']),
    ]),

  local configMap = $.core.v1.configMap,

  prometheus_config_map:
    configMap.new('%s-config' % $._config.prometheus.name) +
    configMap.withData({
      'prometheus.yml': $.util.manifestYaml($.prometheus_config),
      'recording.rules': $.util.manifestYaml($.prometheusRules),
    }),

  local container = $.core.v1.container,

  prometheus_container::
    container.new('prometheus', $._images.prometheus) +
    container.withPorts($.core.v1.containerPort.new('http-metrics', 80)) +
    container.withArgs([
      '--config.file=/etc/prometheus/prometheus.yml',
      '--web.listen-address=:%s' % $._config.prometheus.port,
      '--web.external-url=%(external_hostname)s%(path)s' % $._config.prometheus,
      '--web.enable-lifecycle',
      '--web.route-prefix=%s' % $._config.prometheus.web_route_prefix,
      '--storage.tsdb.path=/prometheus/data',
      '--storage.tsdb.wal-compression',
      '--storage.tsdb.retention=%s' % $._config.prometheus.retention,
    ]) +
    $.util.resourcesRequests('250m', '250Mi') +
    $.util.resourcesLimits('500m', '500Mi'),

  local pvc = $.core.v1.persistentVolumeClaim,

  prometheus_pvc::
    pvc.new() +
    pvc.mixin.metadata.withName('%s-data' % $._config.prometheus.name) +
    pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
    pvc.mixin.spec.resources.withRequests({ storage: '1Gi' }),

  local statefulSet = $.apps.v1beta1.statefulSet,
  local volumeMount = $.core.v1.volumeMount,

  prometheus_statefulSet:
    statefulSet.new($._config.prometheus.name, 1, [
      self.prometheus_container.withVolumeMountsMixin(
        volumeMount.new('%s-data' % $._config.prometheus.name, '/prometheus')
      ),
    ], self.prometheus_pvc) +
    statefulSet.mixin.spec.withServiceName('prometheus') +
    statefulSet.mixin.spec.template.metadata.withAnnotations({
      'prometheus.io.path': '%smetrics' % $._config.prometheus.web_route_prefix,
    }) +
    statefulSet.mixin.spec.template.spec.securityContext.withRunAsUser(0) +
    statefulSet.mixin.spec.template.spec.withServiceAccount($._config.prometheus.name)
    +
    $.util.configMapVolumeMount(self.prometheus_config_map, '/etc/prometheus') +
    $.util.podPriority('critical'),

  prometheus_service:
    $.util.serviceFor($.prometheus_statefulSet),
}
