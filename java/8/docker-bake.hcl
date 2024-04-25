####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:java`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }

group "default" {
  targets = ["java"]
}

# NOTE: the context is required for now due to https://github.com/docker/buildx/issues/1028
target "java" {
  tags = ["ghcr.io/djbender/java:8", "ghcr.io/djbender/java:8-jdk", "ghcr.io/djbender/java:8-jdk-noble"]
  context = "${PWD}/java/8"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=java/8"
  ]
  cache-to = [
    "type=gha,scope=java/8,mode=max"
  ]
}
