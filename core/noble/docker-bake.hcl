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
  cache-from = [
    "type=gha,scope=core/noble",
    "type=registry,ref=ghcr.io/djbender/core:noble-buildcache"
  ]
  cache-to = [
    "type=gha,scope=core/noble,mode=max",
    "type=registry,ref=ghcr.io/djbender/core:noble-buildcache,mode=max"
  ]
}

target "core-dev" {
  target = "core-dev"
  inherits = ["core"]
  tags = ["ghcr.io/djbender/core:dev", "ghcr.io/djbender/core:noble-dev"]
  cache-from = [
    "type=gha,scope=core-dev/noble",
    "type=registry,ref=ghcr.io/djbender/core-dev:noble-buildcache",
  ]
  cache-to = [
    "type=gha,scope=core-dev/noble,mode=max",
    "type=registry,ref=ghcr.io/djbender/core-dev:noble-buildcache,mode=max"
  ]
}
