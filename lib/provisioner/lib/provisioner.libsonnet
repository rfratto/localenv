{
  provisioner_config:: {
    nodePathMap: [
      {
        node: 'DEFAULT_PATH_FOR_NON_LISTED_NODES',
        paths: ['/tmp/local-path-provisioner/data'],
      },
    ],
  },

  local policyRule = $.rbac.v1beta1.policyRule,

  provisioner_rbac:
    $.util.rbac('provisioner', [
      policyRule.new() +
      policyRule.withApiGroups(['']) +
      policyRule.withResources(['nodes', 'persistentvolumeclaims']) +
      policyRule.withVerbs(['get', 'list', 'watch']),

      policyRule.new() +
      policyRule.withApiGroups(['']) +
      policyRule.withResources(['endpoints', 'persistentvolumes', 'pods']) +
      policyRule.withVerbs(['*']),

      policyRule.new() +
      policyRule.withApiGroups(['']) +
      policyRule.withResources(['events']) +
      policyRule.withVerbs(['create', 'patch']),

      policyRule.new() +
      policyRule.withApiGroups(['storage.k8s.io']) +
      policyRule.withResources(['storageclasses']) +
      policyRule.withVerbs(['get', 'list', 'watch']),
    ]),

  local configMap = $.core.v1.configMap,

  provisioner_config_map:
    configMap.new('provisioner-config') +
    configMap.withData({ 'config.json': std.manifestJson($.provisioner_config) }),

  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,

  provisioner_container::
    container.new('provisioner', $._images.provisioner) +
    container.withCommand([
      'local-path-provisioner',
      '--debug',
      'start',
      '--config',
      '/etc/config/config.json',
      '--provisioner-name',
      $._config.provisioner.provisioner_name,
    ]) +
    container.withEnv([
      { name: 'POD_NAMESPACE', value: $._config.namespace },
    ]),

  local deployment = $.apps.v1.deployment,

  provisioner_deployment:
    deployment.new('provisioner', 1, [$.provisioner_container]) +
    deployment.mixin.spec.template.spec.withServiceAccount('provisioner') +
    $.util.configVolumeMount('provisioner-config', '/etc/config') +
    $.util.podPriority('critical'),

  local storageClass = $.storage.v1.storageClass,

  provisioner_storage_class:
    storageClass.new() +
    storageClass.withProvisioner($._config.provisioner.provisioner_name) +
    storageClass.withReclaimPolicy('Delete') +
    storageClass.mixin.metadata.withName('provisioner-storage') +
    storageClass.mixin.metadata.withAnnotations({
      'storageclass.kubernetes.io/is-default-class': 'true',
    }) +
    { volumeBindingMode: 'WaitForFirstConsumer' },

}
