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
  tags = ["ghcr.io/djbender/node:18", "ghcr.io/djbender/node:18-noble", "ghcr.io/djbender/node:18.16.0", "ghcr.io/djbender/node:18.16.0-noble"]
  context = "${PWD}/node/18"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/18"
  ]
  cache-to = [
    "type=gha,scope=node/18,mode=max"
  ]
}


target "node-dev" {
  target = "node-dev"
  inherits = ["node"]
  tags = ["ghcr.io/djbender/node:18-dev-noble", "ghcr.io/djbender/node:18.16.0-dev", "ghcr.io/djbender/node:18.16.0-dev-noble"]
  cache-from = ["type=gha,scope=node-dev/18"]
  cache-to = ["type=gha,scope=node-dev/18,mode=max"]
}
