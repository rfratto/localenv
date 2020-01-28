# TODO

This is a loosely organized document describing the work I'd like to do for
localenv.

## Goals

- [ ] Update documentation to describe OpenVPN usage for debugging
      Cortex (or Loki)
- [ ] Change `environments` structure (see below for thoughts)

## Tasks

- [x] Migrate `environments/cortex` to `environments/localenv`
- [x] Migrate `environments/loki` to `environments/localenv`
- [ ] Migrate `environments/openvpn` to `environments/localenv`
- [ ] Migrate `environments/storage` to `environments/localenv`
- [ ] Use Loki microservices (and remote storage)
- [ ] Conditionally enable tablemanager in Cortex
- [x] Promtail dashboard?

## Change `environments` structure

Currently, localenv is a bit too static and it's going to lead me to either
comment out stuff in a pushed commit or create a bunch of different environments
with different configurations set (i.e.,
`environments/cortex-with-five-ingesters-and-local-storage`).

I'm planning on a few changes for this:

1. Remove the nested folders for environments. This is only intended for
   localhost systems anyway, and this will clean up the directory structure
   just a little.
2. Generate environment tweaks with `make`.
