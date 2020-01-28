# localenv

`localenv` is a Tanka environment made for running a development stack locally
made for testing.

This repo has no guarantees of stability; breaking changes may be made
at any time.

## Dependencies

- Docker
- [k3d >=v1.5.1](https://github.com/rancher/k3d)
- [Tanka >=0.7.0](https://github.com/grafana/tanka)

### Docker Warning

If running Docker on Windows or macOS, you'll have to increase the RAM allocated
to the VM to at least 4GB.

## Getting Started

Run the following scripts to create your cluster and add it to your
~/.kube/config file:

```bash
make bootstrap
./scripts/create_k3d.bash
./scripts/merge_k3d_config.bash
```

The first command, `make bootstrap`, generates a `lib/settings.libsonnet`
file. This file is used throughout all the environments and configures the
behavior of how certain environments are deployed. Please read the file and
configure it to your liking, although the defaults should be fine for
playing around with localenv.

First, delete the local path provisioner `k3d` comes with and apply
`environments/provision`:

```bash
k delete storageclass local-path
tk apply environments/provision/localhost.default
```

Wait a little bit for this to finish, then apply `environments/localenv`:

```bash
tk apply environments/localenv/localhost.default
```

If you navigate to `http://localhost:8080`, you should see a landing page with all exposed services.

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

## Note on Tanka Structure

Tanka is generally written for deploying consistent and reproducable
environments. This concept doesn't work for `localenv` where different
machines may have deployments in slightly different states to meet their
current testing needs.

To solve the problem of introducing git diffs or accidentally checking in
temporary changes, this repo introduces a `settings.libsonnet` file to tweak what gets deployed. This is a bad idea for production; `settings.libsonnet` is exempt from version control and allows multiple users to deploy multiple different environments.

Please don't use this repository as an inspiration for your production
environment; follow the recommended Tanka guidelines instead.
