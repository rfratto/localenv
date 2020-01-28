.PHONY: all bootstrap
all: bootstrap

bootstrap:
	@bash -c '[[ -f ./lib/settings.libsonnet ]] || (cp ./lib/settings.libsonnet{.example,} && echo "Created lib/settings.libsonnet")'
