local cortex = import './apps/cortex.libsonnet';
local default = import './apps/default.libsonnet';
local loki = import './apps/loki.libsonnet';
local openvpn = import './apps/openvpn.libsonnet';
local settings = import 'settings.libsonnet';

{
  default: default,
  cortex: (
    if settings.cortex.enabled
    then cortex
    else {}
  ),
  loki: (
    if settings.loki.enabled
    then loki
    else {}
  ),
  openvpn: (
    if settings.openvpn.enabled
    then openvpn
    else {}
  ),
}
