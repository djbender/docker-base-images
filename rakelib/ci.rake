require 'json'
require 'git'

# lib/util has shared constants and methods used in rake tasks
require_relative '../lib/util'
require_relative '../lib/tag_generator'

DEFAULT_BRANCH = 'main'.freeze
PLATFORMS = %w[linux/amd64 linux/arm64].freeze

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

    desc 'Generate core merge matrix (one entry per version, no platform expansion)'
    task 'core-merge' do
      core_filter = proc { |image_name| image_name == 'core' }

      puts merge_matrix(&core_filter).to_json
    end

    desc 'Generate common merge matrix (one entry per version, no platform expansion)'
    task 'common-merge' do
      common_filter = proc { |image_name| !image_name.start_with?('core') }

      puts merge_matrix(&common_filter).to_json
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
# Generates matrix entries for each version × platform combination
# Each entry includes platform-specific cache keys and runner selection
#
def matrix(&)
  branch_suffix = current_branch == DEFAULT_BRANCH ? '' : "-#{current_branch.gsub(/[^a-zA-Z0-9\-_]/, '-')}"

  {
    include: Util::MANIFEST.select(&).flat_map do |image_name, details|
      details.fetch('versions').keys.flat_map do |version|
        # Generate entry for each platform (native builds on both archs)
        PLATFORMS.map do |platform|
          arch_suffix = platform == 'linux/arm64' ? 'arm64' : 'amd64'
          runner = platform == 'linux/arm64' ? 'ubuntu-24.04-arm' : 'ubuntu-24.04'

          # Build cache refs
          cache_tag = "#{version}-#{arch_suffix}"
          cache_tag_branch = "#{cache_tag}#{branch_suffix}"
          cache_registry = "#{Util::REGISTRY}/#{image_name}"

          if main_branch?
            primary_cache_from = [cache_from_ref(image_name, cache_registry, cache_tag)]
            dev_cache_from = [cache_from_ref("#{image_name}-dev", cache_registry, "dev-#{cache_tag}")]
          else
            # Feature branch: branch+arch cache with fallback to main arch cache
            primary_cache_from = [
              cache_from_ref(image_name, cache_registry, cache_tag_branch),
              cache_from_ref(image_name, cache_registry, cache_tag)
            ]
            dev_cache_from = [
              cache_from_ref("#{image_name}-dev", cache_registry, "dev-#{cache_tag_branch}"),
              cache_from_ref("#{image_name}-dev", cache_registry, "dev-#{cache_tag}")
            ]
          end

          {
            bake: Pathname.new("#{image_name}/#{version}") + Util::BAKE_FILE,
            version: version,
            primary_target: image_name,
            dev_target: "#{image_name}-dev",
            platform: platform,
            arch: arch_suffix,
            runner: runner,
            registry: Util::REGISTRY,
            primary_cache_from: primary_cache_from.join("\n"),
            primary_cache_to: cache_to_ref(image_name, cache_registry, cache_tag_branch),
            dev_cache_from: dev_cache_from.join("\n"),
            dev_cache_to: cache_to_ref("#{image_name}-dev", cache_registry, "dev-#{cache_tag_branch}")
          }
        end
      end
    end
  }
end

# Generates merge matrix entries (one per version, no platform expansion)
# Used by merge jobs to create multi-arch manifests
# Includes all tags from TagGenerator for manifest creation
def merge_matrix(&)
  {
    include: Util::MANIFEST.select(&).flat_map do |image_name, details|
      defaults = details.fetch('defaults', {})

      details.fetch('versions').keys.map do |version|
        version_values = details.fetch('versions').fetch(version) || {}
        values = Util::GLOBAL_DEFAULTS
          .fetch('defaults', {})
          .merge(defaults)
          .merge(version_values)
          .merge('version' => version, 'image_name' => image_name)

        {
          version: version,
          primary_target: image_name,
          registry: Util::REGISTRY,
          primary_tags: TagGenerator.primary_tags(image_name, values).join(' '),
          dev_tags: TagGenerator.dev_tags(image_name, values).join(' ')
        }
      end
    end
  }
end

def cache_from_ref(target, registry, tag)
  "#{target}.cache-from=type=registry,ref=#{registry}:cache-#{tag}"
end

def cache_to_ref(target, registry, tag)
  "#{target}.cache-to=type=registry,ref=#{registry}:cache-#{tag},mode=max"
end

def main_branch?
  current_branch == DEFAULT_BRANCH
end

def current_branch
  branch = ENV['GITHUB_REF'] || "refs/heads/#{Git.open(Dir.getwd).current_branch}"
  branch.gsub('refs/heads/', '')
end
