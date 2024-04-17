require 'json'

# lib/util has shared constants and methods used in rake tasks
require_relative '../lib/util'

namespace :ci do
  namespace 'set-matrix' do
    desc 'Generate core index of bake config, cache, and set-matrix output'
    task :core do
      core_filter = proc { |image_name| image_name == 'core' }

      puts matrix(&core_filter).to_json
    end

    desc 'Generate non-core index of bake config, cache, and set-matrix output'
    task :'non-core' do
      non_core_filter = proc { |image_name| image_name != 'core' && image_name != 'clojure' }

      puts matrix(&non_core_filter).to_json
    end

    desc 'Generate clojure index of bake config, cache, and set-matrix output'
    task :clojure do
      non_core_filter = proc { |image_name| image_name == 'clojure' }

      puts matrix(&non_core_filter).to_json
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
            "*.cache-from=type=gha,scope=#{image_name}/#{version}",
            # "*.cache-from=type=registry,ref=#{ghcr_registry}/djbender/#{image_name}:#{version}-cache"
          ].join("\n"),
          'cache-to' => [
            "*.cache-to=type=gha,scope=#{image_name}/#{version},mode=max",
            # "*.cache-to=type=registry,ref=#{ghcr_registry}/djbender/#{image_name}:#{version}-cache,mode=max"
          ].join("\n")
        }
      end
    end
  }
end

def ghcr_registry
  Util::GLOBAL_DEFAULTS.fetch('defaults').fetch('ghcr_registry')
end
