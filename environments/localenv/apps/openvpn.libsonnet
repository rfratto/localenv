local openvpn = import 'openvpn/openvpn.libsonnet';
local settings = import 'settings.libsonnet';

openvpn {
  _config+:: {
    namespace: 'openvpn',
  },

  ns:
    $.core.v1.namespace.new($._config.namespace),
}
