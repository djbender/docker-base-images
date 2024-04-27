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
  tags = ["ghcr.io/djbender/node:14", "ghcr.io/djbender/node:14-noble", "ghcr.io/djbender/node:14.21.3", "ghcr.io/djbender/node:14.21.3-noble"]
  context = "${PWD}/node/14"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/14"
  ]
  cache-to = [
    "type=gha,scope=node/14,mode=max"
  ]
}


target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = ["ghcr.io/djbender/node:14-dev-noble", "ghcr.io/djbender/node:14.21.3-dev", "ghcr.io/djbender/node:14.21.3-dev-noble"]
  cache-from = ["type=gha,scope=node-dev/14"]
  cache-to = ["type=gha,scope=node-dev/14,mode=max"]
}
