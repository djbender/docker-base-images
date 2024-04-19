# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `rake generate:node`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }

group "default" {
  targets = ["node"]
}

# NOTE: the context is required for now due to https://github.com/docker/buildx/issues/1028
target "node" {
  tags = ["ghcr.io/djbender/node:12-dev", "ghcr.io/djbender/node:12-dev-bionic", "ghcr.io/djbender/node:12.22.12-dev", "ghcr.io/djbender/node:12.22.12-dev-bionic"]
  context = "${PWD}/node/12-dev"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/12-dev"
  ]
  cache-to = [
    "type=gha,scope=node/12-dev,mode=max"
  ]
}