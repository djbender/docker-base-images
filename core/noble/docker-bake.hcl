####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:core`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }

group "default" {
  targets = [
    "core",
    "core-dev"
  ]
}

# NOTE: the context is required for now due to https://github.com/docker/buildx/issues/1028
target "core" {
  target = "core"
  tags = [
    "ghcr.io/djbender/core:latest",
    "ghcr.io/djbender/core:noble"
  ]
  context = "${PWD}/core/noble"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/core:cache-noble",
    "type=registry,ref=ghcr.io/djbender/core:noble"
  ]
  cache-to = ["type=registry,ref=ghcr.io/djbender/core:cache-noble,mode=max"]
}

target "core-dev" {
  target = "core-dev"
  inherits = ["core"]
  tags = [
    "ghcr.io/djbender/core:dev",
    "ghcr.io/djbender/core:noble-dev"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/core:cache-dev-noble",
    "type=registry,ref=ghcr.io/djbender/core:dev-noble"
  ]
  cache-to = ["type=registry,ref=ghcr.io/djbender/core:cache-dev-noble,mode=max"]
}
