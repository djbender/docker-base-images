####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:ruby`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }
variable "ARCH" {default="" }

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
    "ghcr.io/djbender/ruby:3.1",
    "ghcr.io/djbender/ruby:3.1-resolute",
    "ghcr.io/djbender/ruby:3.1.7",
    "ghcr.io/djbender/ruby:3.1.7-resolute"
  ]
  context = "${PWD}/ruby/3.1"
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/ruby:cache-3.1-${ARCH}",
    "type=registry,ref=ghcr.io/djbender/ruby:3.1"
  ]
}

target "ruby-dev" {
  target = "ruby-dev"
  inherits = ["ruby"]
  tags = [
    "ghcr.io/djbender/ruby:3.1-dev",
    "ghcr.io/djbender/ruby:3.1-dev-resolute",
    "ghcr.io/djbender/ruby:3.1.7-dev",
    "ghcr.io/djbender/ruby:3.1.7-dev-resolute"
  ]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/ruby:cache-dev-3.1-${ARCH}",
    "type=registry,ref=ghcr.io/djbender/ruby:3.1-dev"
  ]
}
