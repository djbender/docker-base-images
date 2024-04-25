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
  tags = ["ghcr.io/djbender/core:latest", "ghcr.io/djbender/core:noble"]
  context = "${PWD}/core/noble"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = ["type=gha,scope=core/noble"]
  cache-to = ["type=gha,scope=core/noble,mode=max"]
}

target "core-dev" {
  target = "core-dev"
  inherits = ["core"]
  tags = ["ghcr.io/djbender/core:dev"]
  cache-from = ["type=gha,scope=core-dev/noble"]
  cache-to = ["type=gha,scope=core-dev/noble,mode=max"]
}
