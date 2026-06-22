require_relative '../lib/dependabot_generator'
require_relative '../lib/generation_message'
require_relative '../lib/image_generator'
require_relative '../lib/template'
require_relative '../lib/util'

namespace :generate do
  Util::MANIFEST.each do |image_name, details|
    desc "Generate all #{image_name} Dockerfiles"
    task image_name do |t|
      ImageGenerator.new(image_name:, details:, task_name: t.name).generate
    end
  end

  desc 'Generate .github/dependabot.yml from manifest'
  task :dependabot do |t|
    DependabotGenerator.new(task_name: t.name).generate
  end

  # This one must be last for the dependency resolution magic to work
  desc 'Generate all templatized Dockerfiles'
  task 'all' => Rake.application.tasks.select { |t| t.name.start_with?('generate') }.map(&:name)
end
