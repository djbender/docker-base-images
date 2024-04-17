<%= generation_message -%>

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition
<%
# Specify any additional tags here, see defaults defined in lib/metadata.rb
clojure_tags = [
  "#{full_image_path}:#{java_version}",
  "#{full_image_path}:#{java_version}-#{distribution_code_name}",
  "#{full_image_path}:#{java_version}-lein-#{lein_version}",
  "#{full_image_path}:#{java_version}-lein-#{lein_version}-#{distribution_code_name}",
]
# if we end up with a second flavor we can then use this next line. See other
# docker-bake.hcl templates for examples
# clojure_tags.push("#{full_image_path}:#{java_version}") if flavor&.casecmp('slim')&.zero?
custom_tags = docker_tags(clojure_tags || [])
-%>

variable "PWD" {default="" }

group "default" {
  targets = ["<%= image_name %>"]
}

# NOTE: the context is required for now due to https://github.com/docker/buildx/issues/1028
target "<%= image_name %>" {
  tags = <%= custom_tags %>
  context = "${PWD}/<%= image_name %>/<%= version %>"
  platforms = ["linux/amd64", "linux/arm64"]
  cache-from = [
    "type=gha,scope=<%= image_name %>/<%= version %>"
  ]
  cache-to = [
    "type=gha,scope=<%= image_name %>/<%= version %>,mode=max"
  ]
}
