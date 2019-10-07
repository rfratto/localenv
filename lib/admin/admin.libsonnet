// admin creates an admin portal using nginx that can forward to any
// number of services.
//
// By default, no services are created, but _config.admin_services
// can be updated with any number of objects like so:
//
// admin_services+: [
//    { title: 'Grafana', path: 'grafana', url: 'http://grafana.default.svc.cluster.local/', allowWebsockets: true },
// ]
//
// The path determines the subpath to expose for the service and the URL is the
// root URL of the service to forward to. Note that the service should be
// configured to expect web traffic from a base URL matching the path exposed
// to the user.

(import 'ksonnet-util/kausal.libsonnet') +
(import 'config.libsonnet') +
(import 'images.libsonnet') +
(import 'lib/nginx.libsonnet')
