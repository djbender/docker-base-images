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
  tags = ["ghcr.io/djbender/node:14", "ghcr.io/djbender/node:14-", "ghcr.io/djbender/node:14--jammy", "ghcr.io/djbender/node:14.21.3-", "ghcr.io/djbender/node:14.21.3--jammy"]
  context = "${PWD}/node/14"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/14"
  ]
  cache-to = [
    "type=gha,scope=node/14,mode=max"
  ]
}
