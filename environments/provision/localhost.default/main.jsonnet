local provisioner = import 'provisioner/provisioner.libsonnet';

provisioner +
{
  _config+:: {
    namespace: 'default',
  },
}
