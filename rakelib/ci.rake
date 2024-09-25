require 'hcl'

# lib/util has shared constants and methods used in rake tasks
require_relative '../lib/util'

namespace :ci do
  namespace 'set-matrix' do
    desc 'Generate core index of bake config, cache, and set-matrix output'
    task :core do
      core_filter = proc { |image_name| image_name == 'core' }

      puts matrix(&core_filter).to_json
    end

    desc 'Generate common index of bake config, cache, and set-matrix output'
    task :common do
      common_filter = proc { |image_name| !image_name.start_with?('core') && image_name != 'clojure' }

      puts matrix(&common_filter).to_json
    end

    desc 'Generate post-java index of bake config, cache, and set-matrix output'
    task :'post-java' do
      post_java_filter = proc { |image_name| image_name == 'clojure' }

      puts matrix(&post_java_filter).to_json
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
  cache_keys = %w[cache-from cache-to]
  {
    include: Util::MANIFEST.select(&).flat_map do |image_name, details|
      details.fetch('versions').keys.map do |version|
        bake_file = Pathname.new("#{image_name}/#{version}") + Util::BAKE_FILE
        hcl_data = bake_file
          .read
          .lines
          .reject { |l| l.start_with?('#') }
          .join
        data = HCL::Parser.new(hcl_data).parse

        image = data.fetch('target').fetch(image_name)

        cache = cache_keys.to_h do |key|
          [key, image.fetch(key).map { |v| v.dup.prepend("*.#{key}=") }]
        end
        {
          bake: Pathname.new("#{image_name}/#{version}") + Util::BAKE_FILE
        }.merge(cache)
      end
    end
  }
end

def ghcr_registry
  Util::GLOBAL_DEFAULTS.fetch('defaults').fetch('ghcr_registry')
end
