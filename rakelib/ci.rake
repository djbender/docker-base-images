require 'json'
require 'git'

# lib/util has shared constants and methods used in rake tasks
require_relative '../lib/util'

DEFAULT_BRANCH = 'main'

namespace :ci do
  namespace 'set-matrix' do
    desc 'Generate core index of bake config, cache, and set-matrix output'
    task :core do
      core_filter = proc { |image_name| image_name == 'core' }

      puts matrix(&core_filter).to_json
    end

    desc 'Generate common index of bake config, cache, and set-matrix output'
    task :common do
      common_filter = proc { |image_name| !image_name.start_with?('core') }

      puts matrix(&common_filter).to_json
    end
  end
end

# input is a proc like:
#
#     proc { |image_name| image_name == 'core' }
#
# and must be dereferenced when called:
#
#     matrix(&filter)
#
# this returns an object that looks something like:
#
# {
#   "include": [
#     {
#       "bake": "core/jammy/docker-bake.hcl",
#       "cache": [
#         "type=gha,scope=core/jammy",
#         "ghcr.io/djbender/core:jammy-cache"
#       ]
#     },
#     {...}
#   ]
# }
#
def matrix(&)
  {
    include: Util::MANIFEST.select(&).flat_map do |image_name, details|
      details.fetch('versions').keys.map do |version|
        {
          bake: Pathname.new("#{image_name}/#{version}") + Util::BAKE_FILE,
          'cache-from' => [
            "*.cache-from=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-#{version}",
            "*.cache-from=type=registry,ref=ghcr.io/djbender/#{image_name}:#{version}"
          ].join("\n"),
          'cache-to' => [
            "*.cache-to=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-#{version},mode=max"
          ].join("\n"),
          'platform' => platform.join("\n")
        }
      end
    end
  }
end

def platform
  return [] if main_branch?

  ["*.platform=#{os}/#{arch}"]
end

def main_branch?
  current_branch == "refs/heads/#{DEFAULT_BRANCH}"
end

def current_branch
  ENV['GITHUB_REF'] || "refs/heads/#{Git.open(Dir.getwd).current_branch}"
end

def os
  'linux'
end

def arch
  cpu = RbConfig::CONFIG['host_cpu']

  case cpu
  when /x86_64/
    'amd64'
  when /arm64|aarch64/
    'arm64'
  else
    'unknown'
  end
end

def ghcr_registry
  Util::GLOBAL_DEFAULTS.fetch('defaults').fetch('ghcr_registry')
end
