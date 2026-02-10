####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:ruby`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }

group "default" {
  targets = [
    "ruby",
    "ruby-dev"
  ]
}

# NOTE: the context is required for now due to https://github.com/docker/buildx/issues/1028
target "ruby" {
  target = "ruby"
  tags = [
    "ghcr.io/djbender/ruby:2.5",
    "ghcr.io/djbender/ruby:2.5-bionic",
    "ghcr.io/djbender/ruby:2.5.9",
    "ghcr.io/djbender/ruby:2.5.9-bionic"
  ]
  context = "${PWD}/ruby/2.5"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/ruby:cache-2.5",
    "type=registry,ref=ghcr.io/djbender/ruby:2.5"
  ]
  cache-to = ["type=registry,ref=ghcr.io/djbender/ruby:cache-2.5,mode=max"]
}

target "ruby-dev" {
  target = "ruby-dev"
  inherits = ["ruby"]
  tags = [
    "ghcr.io/djbender/ruby:2.5-dev",
    "ghcr.io/djbender/ruby:2.5-dev-bionic",
    "ghcr.io/djbender/ruby:2.5.9-dev",
    "ghcr.io/djbender/ruby:2.5.9-dev-bionic"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/ruby:cache-dev-2.5",
    "type=registry,ref=ghcr.io/djbender/ruby:dev-2.5"
  ]
  cache-to = ["type=registry,ref=ghcr.io/djbender/ruby:cache-dev-2.5,mode=max"]
}
