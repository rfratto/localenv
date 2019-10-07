// prometheus creates an instance of Prometheus.
// If lib/admin is being used, it adds an entry for Prometheus on the
// portal page.

(import 'ksonnet-util/kausal.libsonnet') +
(import 'config.libsonnet') +
(import 'images.libsonnet') +
(import 'lib/node-exporter.libsonnet') +
(import 'lib/kube-state-metrics.libsonnet') +
(import 'lib/prometheus.libsonnet')
