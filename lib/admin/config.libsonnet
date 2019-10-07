{
  _config+:: {
    // admin_services should be a list of objects that define entries on the
    // admin portal for users to click on and visit sites.
    //
    // For example:
    //   { title: 'Grafana', path: 'grafana', url: 'http://grafana.default.svc.cluster.local/', allowWebsockets: true },
    //
    // The following properties are supported:
    //
    // title:           name to display in list (required)
    // path:            subpath for URL (i.e., /<path>). (required)
    // url:             url to forward to. (required)
    // redirect:        if true, redirects to the URL provided.
    // allowWebsockets: if true, allows websocket connections.
    // subfilter:       if true, replaces root paths to the path defined by path.
    admin_services+: [],
  },
}
