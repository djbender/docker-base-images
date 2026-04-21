####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:core`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }
variable "ARCH" {default="" }

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
    "ghcr.io/djbender/core:resolute"
  ]
  context = "${PWD}/core/resolute"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/core:cache-resolute-${ARCH}",
    "type=registry,ref=ghcr.io/djbender/core:resolute"
  ]
}

target "core-dev" {
  target = "core-dev"
  inherits = ["core"]
  tags = [
    "ghcr.io/djbender/core:dev",
    "ghcr.io/djbender/core:resolute-dev"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/core:cache-dev-resolute-${ARCH}",
    "type=registry,ref=ghcr.io/djbender/core:resolute-dev"
  ]
}
