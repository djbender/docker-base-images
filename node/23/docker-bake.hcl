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
  tags = ["ghcr.io/djbender/node:23", "ghcr.io/djbender/node:23-noble", "ghcr.io/djbender/node:23.6.1", "ghcr.io/djbender/node:23.6.1-noble", "ghcr.io/djbender/node:latest"]
  context = "${PWD}/node/23"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/23"
  ]
  cache-to = [
    "type=gha,scope=node/23,mode=max"
  ]
}


target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = ["ghcr.io/djbender/node:23-dev", "ghcr.io/djbender/node:23-dev-noble", "ghcr.io/djbender/node:23.6.1-dev", "ghcr.io/djbender/node:23.6.1-dev-noble", "ghcr.io/djbender/node:dev"]
  cache-from = ["type=gha,scope=node-dev/23"]
  cache-to = ["type=gha,scope=node-dev/23,mode=max"]
}
