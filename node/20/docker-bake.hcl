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
    "ghcr.io/djbender/node:20",
    "ghcr.io/djbender/node:20-resolute",
    "ghcr.io/djbender/node:20.20.2",
    "ghcr.io/djbender/node:20.20.2-resolute"
  ]
  context = "${PWD}/node/20"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/node:cache-20-${ARCH}",
    "type=registry,ref=ghcr.io/djbender/node:20"
  ]
}

target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = [
    "ghcr.io/djbender/node:20-dev",
    "ghcr.io/djbender/node:20-dev-resolute",
    "ghcr.io/djbender/node:20.20.2-dev",
    "ghcr.io/djbender/node:20.20.2-dev-resolute"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/node:cache-dev-20-${ARCH}",
    "type=registry,ref=ghcr.io/djbender/node:20-dev"
  ]
}
