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
  tags = ["ghcr.io/djbender/node:20", "ghcr.io/djbender/node:20-noble", "ghcr.io/djbender/node:20.19.2", "ghcr.io/djbender/node:20.19.2-noble"]
  context = "${PWD}/node/20"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/20"
  ]
  cache-to = [
    "type=gha,scope=node/20,mode=max"
  ]
}


target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = ["ghcr.io/djbender/node:20-dev", "ghcr.io/djbender/node:20-dev-noble", "ghcr.io/djbender/node:20.19.2-dev", "ghcr.io/djbender/node:20.19.2-dev-noble"]
  cache-from = ["type=gha,scope=node-dev/20"]
  cache-to = ["type=gha,scope=node-dev/20,mode=max"]
}
