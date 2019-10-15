#!/usr/bin/env bash

k3d create \
  --name localenv \
  --publish 8080:30080 \
  -v /tmp/local-path-provisioner/localenv/:/tmp/local-path-provisioner/data/
