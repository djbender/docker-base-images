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
  tags = ["ghcr.io/djbender/node:12", "ghcr.io/djbender/node:12-", "ghcr.io/djbender/node:12--bionic", "ghcr.io/djbender/node:12.22.12-", "ghcr.io/djbender/node:12.22.12--bionic"]
  context = "${PWD}/node/12"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/12"
  ]
  cache-to = [
    "type=gha,scope=node/12,mode=max"
  ]
}


target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = ["ghcr.io/djbender/node:12-dev-bionic", "ghcr.io/djbender/node:12.22.12-dev", "ghcr.io/djbender/node:12.22.12-dev-bionic"]
  cache-from = ["type=gha,scope=node-dev/12"]
  cache-to = ["type=gha,scope=node-dev/12,mode=max"]
}
