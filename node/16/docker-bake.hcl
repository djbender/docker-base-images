####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:node`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }

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
    "ghcr.io/djbender/node:16",
    "ghcr.io/djbender/node:16-jammy",
    "ghcr.io/djbender/node:16.20.2",
    "ghcr.io/djbender/node:16.20.2-jammy"
  ]
  context = "${PWD}/node/16"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/node:cache-16",
    "type=registry,ref=ghcr.io/djbender/node:16"
  ]
  cache-to = ["type=registry,ref=ghcr.io/djbender/node:cache-16,mode=max"]
}

target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = [
    "ghcr.io/djbender/node:16-dev",
    "ghcr.io/djbender/node:16-dev-jammy",
    "ghcr.io/djbender/node:16.20.2-dev",
    "ghcr.io/djbender/node:16.20.2-dev-jammy"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/node:cache-dev-16",
    "type=registry,ref=ghcr.io/djbender/node:dev-16"
  ]
  cache-to = ["type=registry,ref=ghcr.io/djbender/node:cache-dev-16,mode=max"]
}
