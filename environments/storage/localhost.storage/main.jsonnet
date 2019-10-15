local scylla = import 'scylla/scylla.libsonnet';
local minio = import 'minio/minio.libsonnet';

scylla + minio {
  _config+:: {
    namespace: 'storage',
  },
}
