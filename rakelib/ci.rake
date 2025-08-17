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
  branch_suffix = current_branch == DEFAULT_BRANCH ? '' : "-#{current_branch.gsub(/[^a-zA-Z0-9\-_]/, '-')}"

  {
    include: Util::MANIFEST.select(&).flat_map do |image_name, details|
      details.fetch('versions').keys.flat_map do |version|
        # Build cache-from arrays
        if main_branch?
          # Main branch: only use the main cache
          primary_cache_from = ["#{image_name}.cache-from=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-#{version}"]
          dev_cache_from = ["#{image_name}-dev.cache-from=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-dev-#{version}"]
        else
          # Feature branch: use branch-specific cache with fallback to main cache
          primary_cache_from = [
            "#{image_name}.cache-from=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-#{version}#{branch_suffix}",
            "#{image_name}.cache-from=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-#{version}"
          ]
          dev_cache_from = [
            "#{image_name}-dev.cache-from=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-dev-#{version}#{branch_suffix}",
            "#{image_name}-dev.cache-from=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-dev-#{version}"
          ]
        end

        [
          # Primary image configuration
          {
            bake: Pathname.new("#{image_name}/#{version}") + Util::BAKE_FILE,
            target: image_name,
            'cache-from' => primary_cache_from.join("\n"),
            'cache-to' => [
              "#{image_name}.cache-to=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-#{version}#{branch_suffix},mode=max"
            ].join("\n"),
            'platform' => platform.join("\n")
          },
          # Dev image configuration
          {
            bake: Pathname.new("#{image_name}/#{version}") + Util::BAKE_FILE,
            target: "#{image_name}-dev",
            'cache-from' => dev_cache_from.join("\n"),
            'cache-to' => [
              "#{image_name}-dev.cache-to=type=registry,ref=ghcr.io/djbender/#{image_name}:cache-dev-#{version}#{branch_suffix},mode=max"
            ].join("\n"),
            'platform' => platform.join("\n")
          }
        ]
      end
    end
  }
end

def platform
  return [] if main_branch?

  ["*.platform=#{os}/#{arch}"]
end

def main_branch?
  current_branch == DEFAULT_BRANCH
end

def current_branch
  branch = ENV['GITHUB_REF'] || "refs/heads/#{Git.open(Dir.getwd).current_branch}"
  branch.gsub('refs/heads/', '')
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
