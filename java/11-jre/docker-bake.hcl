# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `rake generate:java`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }

group "default" {
  targets = ["java"]
}

# NOTE: the context is required for now due to https://github.com/docker/buildx/issues/1028
target "java" {
  tags = ["ghcr.io/djbender/java:11-jre", "ghcr.io/djbender/java:11-jre-jammy"]
  context = "${PWD}/java/11-jre"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=java/11-jre",
    "type=registry,ref=ghcr.io/get-bridge/java:11-jre-cache"
  ]
  cache-to = [
    # disabled while GitHub Actions cache is cranky
    # "type=gha,scope=java/11-jre,mode=max"
  ]
}
