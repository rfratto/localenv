local loki = import 'loki/loki.libsonnet';
local settings = import 'settings.libsonnet';

loki {
  _config+:: {
    namespace: 'loki',
  },

  ns:
    $.core.v1.namespace.new($._config.namespace),
} + settings.loki.extra_config
