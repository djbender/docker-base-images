####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:node`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }
variable "ARCH" {default="" }

group "default" {
  targets = [
    "node",
    "node-dev"
  ]
}

# NOTE: the context is required for now due to https://github.com/docker/buildx/issues/1028
target "node" {
  target = "node"
  tags = [
    "ghcr.io/djbender/node:22",
    "ghcr.io/djbender/node:22-resolute",
    "ghcr.io/djbender/node:22.22.2",
    "ghcr.io/djbender/node:22.22.2-resolute"
  ]
  context = "${PWD}/node/22"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/node:cache-22-${ARCH}",
    "type=registry,ref=ghcr.io/djbender/node:22"
  ]
}

target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = [
    "ghcr.io/djbender/node:22-dev",
    "ghcr.io/djbender/node:22-dev-resolute",
    "ghcr.io/djbender/node:22.22.2-dev",
    "ghcr.io/djbender/node:22.22.2-dev-resolute"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/node:cache-dev-22-${ARCH}",
    "type=registry,ref=ghcr.io/djbender/node:22-dev"
  ]
}
