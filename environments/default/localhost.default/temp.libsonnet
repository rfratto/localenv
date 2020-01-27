{
  local daemonSet = $.apps.v1.daemonSet,
  promtail_daemonset+:
    daemonSet.new('promtail', [$.promtail_container]) +
    daemonSet.mixin.spec.template.spec.withServiceAccount('promtail') +
    $.util.configVolumeMount('promtail', '/etc/promtail') +
    $.util.hostVolumeMount('varlog', '/var/log', '/var/log') +
    $.util.hostVolumeMount('varlibdockercontainers', $._config.promtail_config.container_root_path + '/containers', $._config.promtail_config.container_root_path + '/containers', readOnly=true),
}
