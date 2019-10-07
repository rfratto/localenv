// grafana creates an instance of Grafana without authentication.
// If lib/admin is being used, it adds an entry for Grafana on the
// portal page.
//
// Grafana uses the /grafana base path.

(import 'config.libsonnet') +
(import 'images.libsonnet') +
(import 'lib/datasources.libsonnet') +
(import 'lib/grafana.libsonnet')
