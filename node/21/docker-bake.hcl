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
  tags = ["ghcr.io/djbender/node:21", "ghcr.io/djbender/node:21-", "ghcr.io/djbender/node:21--noble", "ghcr.io/djbender/node:21.7.3-", "ghcr.io/djbender/node:21.7.3--noble", "ghcr.io/djbender/node:latest"]
  context = "${PWD}/node/21"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/21"
  ]
  cache-to = [
    "type=gha,scope=node/21,mode=max"
  ]
}


target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = ["ghcr.io/djbender/node:21-dev-noble", "ghcr.io/djbender/node:21.7.3-dev", "ghcr.io/djbender/node:21.7.3-dev-noble", "ghcr.io/djbender/node:dev"]
  cache-from = ["type=gha,scope=node-dev/21"]
  cache-to = ["type=gha,scope=node-dev/21,mode=max"]
}
