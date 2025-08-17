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
  tags = ["ghcr.io/djbender/ruby:3.2", "ghcr.io/djbender/ruby:3.2-noble", "ghcr.io/djbender/ruby:3.2.8", "ghcr.io/djbender/ruby:3.2.8-noble"]
  context = "${PWD}/ruby/3.2"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/ruby:cache-3.2",
    "type=registry,ref=ghcr.io/djbender/ruby:3.2"
  ]
  cache-to = ["type=registry,ref=ghcr.io/djbender/ruby:cache-3.2,mode=max"]
}

target "ruby-dev" {
  target = "ruby-dev"
  inherits = ["ruby"]
  tags = ["ghcr.io/djbender/ruby:3.2-dev-noble", "ghcr.io/djbender/ruby:3.2.8-dev", "ghcr.io/djbender/ruby:3.2.8-dev-noble"]
  cache-from = [
    "type=registry,ref=ghcr.io/djbender/ruby:cache-dev-3.2",
    "type=registry,ref=ghcr.io/djbender/ruby:dev-3.2"
  ]
  cache-to = ["type=registry,ref=ghcr.io/djbender/ruby:cache-dev-3.2,mode=max"]
}
