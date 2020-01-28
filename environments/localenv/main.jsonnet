local cortex = import './apps/cortex.libsonnet';
local default = import './apps/default.libsonnet';
local loki = import './apps/loki.libsonnet';
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
}
