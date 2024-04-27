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
  tags = ["ghcr.io/djbender/node:10", "ghcr.io/djbender/node:10-bionic", "ghcr.io/djbender/node:10.24.1", "ghcr.io/djbender/node:10.24.1-bionic"]
  context = "${PWD}/node/10"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/10"
  ]
  cache-to = [
    "type=gha,scope=node/10,mode=max"
  ]
}


target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = ["ghcr.io/djbender/node:10-dev-bionic", "ghcr.io/djbender/node:10.24.1-dev", "ghcr.io/djbender/node:10.24.1-dev-bionic"]
  cache-from = ["type=gha,scope=node-dev/10"]
  cache-to = ["type=gha,scope=node-dev/10,mode=max"]
}
