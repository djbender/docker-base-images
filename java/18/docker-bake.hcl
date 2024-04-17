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
  tags = ["ghcr.io/djbender/java:18", "ghcr.io/djbender/java:18-jdk", "ghcr.io/djbender/java:18-jdk-jammy"]
  context = "${PWD}/java/18"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=java/18",
    "type=registry,ref=ghcr.io/get-bridge/java:18-cache"
  ]
  cache-to = [
    # disabled while GitHub Actions cache is cranky
    # "type=gha,scope=java/18,mode=max"
  ]
}
