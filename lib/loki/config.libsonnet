{
  _config+:: {
    namespace: error 'must define namespace',
    cluster: error 'must define cluster',

    loki: {
      commonArgs: {
        'config.file': '/etc/loki/config.yaml',
      },
    },
  },
}
