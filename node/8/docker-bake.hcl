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
  tags = ["ghcr.io/djbender/node:8", "ghcr.io/djbender/node:8-bionic", "ghcr.io/djbender/node:8.17.0", "ghcr.io/djbender/node:8.17.0-bionic"]
  context = "${PWD}/node/8"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/node:cache-8",
    "type=registry,ref=ghcr.io/djbender/node:8"
  ]
  cache-to = [
    "type=registry,ref=ghcr.io/djbender/node:cache-8,mode=max"
  ]
}


target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = ["ghcr.io/djbender/node:8-dev", "ghcr.io/djbender/node:8-dev-bionic", "ghcr.io/djbender/node:8.17.0-dev", "ghcr.io/djbender/node:8.17.0-dev-bionic"]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/node:cache-dev-8",
    "type=registry,ref=ghcr.io/djbender/node:dev-8"
  ]
  cache-to = ["type=registry,ref=ghcr.io/djbender/node:cache-dev-8,mode=max"]
}
