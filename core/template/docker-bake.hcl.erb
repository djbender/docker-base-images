<%= generation_message -%>

# https://docs.docker.com/engine/reference/commandline/buildx_bake/#file-definition
<%
# Specify any additional tags here, see defaults defined in lib/metadata.rb
core_tags = []
core_tags.push("#{full_image_path}:dev") if flavor == 'dev' && !!latest
custom_tags = docker_tags(core_tags)
%>

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
