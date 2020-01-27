# localenv

`localenv` is a Tanka environment made for running a development stack locally
made for testing.

## Dependencies

- Docker
- [k3d >=v1.5.1](https://github.com/rancher/k3d)
- [Tanka >=0.7.0](https://github.com/grafana/tanka)

### Docker Warning

If running Docker on Windows or macOS, you'll have to increase the RAM allocated
to the VM to at least 4GB.

## Getting Started

Run the following to create your cluster:

```bash
k3d create \
  --publish 8080:30080 \
  -v /tmp/local-path-provisioner/data/:/tmp/local-path-provisioner/data/
```

Then run `cat $(k3d get-kubeconfig)` to see the created kubeconfig file and
manually merge its settings into your local `$KUBECONFIG` (defaults to
`~/.kube/config`).

Now run `tk apply` to provision the PVC controller:

```bash
tk apply environments/provision/localhost.default
```

Finally, apply the default environment:

```bash
tk apply environments/default/localhost.default
```

If you navigate to `http://localhost:8080`, you should see a landing page with
all exposed services.

You can then apply any optional environments:

- `tk apply environments/cortex/localhost.cortex`

## Testing Images

Testing new images depends on a deployment already existing and a Docker
container being built.

After building a Docker container, deploy to the k3d cluster using
`k3d import-images <image_name>`. This will move all image tags for the given
name to the cluster.

If not already overriden, change the image being used for the appropriate
services to the latest tag and

Then override the image name the cluster is using to the latest tag. Finally,
any time you want to test a new image, run `kubectl rollout restart <resource>`
to rolling restart the appropriate resources.

### Example with Cortex

From Cortex, run the following:

```bash
# Builds localenv/cortex:latest
$ BUILD_IMAGE=quay.io/cortexproject/build-image IMAGE_PREFIX=localenv/ make all

# Import the new images into the cluster
$ k3d import-images localenv/cortex

# Restart all Cortex deployments
$ kubectl -ncortex rollout restart \
  deployment/ingester \
  deployment/querier \
  deployment/distributor
```
