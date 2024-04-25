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
  tags = ["ghcr.io/djbender/core:bionic"]
  context = "${PWD}/core/bionic"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = ["type=gha,scope=core/bionic"]
  cache-to = ["type=gha,scope=core/bionic,mode=max"]
}

target "core-dev" {
  target = "core-dev"
  inherits = ["core"]
  tags = []
  cache-from = ["type=gha,scope=core-dev/bionic"]
  cache-to = ["type=gha,scope=core-dev/bionic,mode=max"]
}
