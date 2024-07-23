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
  tags = ["ghcr.io/djbender/ruby:2.6", "ghcr.io/djbender/ruby:2.6-bionic", "ghcr.io/djbender/ruby:2.6.10", "ghcr.io/djbender/ruby:2.6.10-bionic"]
  context = "${PWD}/ruby/2.6"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = ["type=gha,scope=ruby/2.6"]
  cache-to = ["type=gha,scope=ruby/2.6,mode=max"]
}

target "ruby-dev" {
  target = "ruby-dev"
  inherits = ["ruby"]
  tags = ["ghcr.io/djbender/ruby:2.6-dev-bionic", "ghcr.io/djbender/ruby:2.6.10-dev", "ghcr.io/djbender/ruby:2.6.10-dev-bionic"]
  cache-from = ["type=gha,scope=ruby-dev/2.6"]
  cache-to = ["type=gha,scope=ruby-dev/2.6,mode=max"]
}
