local cortex = import 'cortex/cortex.libsonnet';

cortex {
  _config+:: {
    namespace: 'cortex',
  },

  _images+:: {
    // cortex: 'localenv/cortex:latest',
  },
}
