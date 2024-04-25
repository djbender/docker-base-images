####################################
# NOTICE: This is a generated file #
####################################
#
# To update this file please edit the relevant template and run the generation
# task `rake generate:clojure`

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition

variable "PWD" {default="" }

group "default" {
  targets = ["clojure"]
}

# NOTE: the context is required for now due to https://github.com/docker/buildx/issues/1028
target "clojure" {
  tags = ["ghcr.io/djbender/clojure:11", "ghcr.io/djbender/clojure:11-dev", "ghcr.io/djbender/clojure:11-lein-2.9.1", "ghcr.io/djbender/clojure:11-lein-2.9.1-noble", "ghcr.io/djbender/clojure:11-noble", "ghcr.io/djbender/clojure:latest"]
  context = "${PWD}/clojure/11"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=clojure/11"
  ]
  cache-to = [
    "type=gha,scope=clojure/11,mode=max"
  ]
}
