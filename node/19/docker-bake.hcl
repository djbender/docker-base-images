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
  tags = ["ghcr.io/djbender/node:19", "ghcr.io/djbender/node:19-slim", "ghcr.io/djbender/node:19-slim-jammy", "ghcr.io/djbender/node:19.9.0-slim", "ghcr.io/djbender/node:19.9.0-slim-jammy"]
  context = "${PWD}/node/19"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=node/19"
  ]
  cache-to = [
    "type=gha,scope=node/19,mode=max"
  ]
}
