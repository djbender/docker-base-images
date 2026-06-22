require 'erb'
require_relative 'generation_message'
require_relative 'util'

# Generates .github/dependabot.yml from manifest.yml so the docker
# ecosystem entries can never drift from the image versions we build.
# Unlike ImageGenerator (one file per image/version), this renders a
# single aggregate file, so it has its own lightweight generator.
class DependabotGenerator
  TEMPLATE_PATH = File.join('.github', 'template', 'dependabot.yml.erb').freeze
  OUTPUT_PATH = File.join('.github', 'dependabot.yml').freeze

  attr_reader :task_name

  def initialize(task_name: nil)
    @task_name = task_name
  end

  def generate
    puts 'Generating .github/dependabot.yml'
    File.write(output_path, render)
    puts 'Done!'
  end

  # One docker directory (<image>/<version>) per manifest version, in
  # manifest order. 'globals' is already removed from Util::MANIFEST.
  def docker_directories
    Util::MANIFEST.flat_map do |image_name, details|
      details.fetch('versions').keys.map { |version| "#{image_name}/#{version}" }
    end
  end

  def generation_message
    GenerationMessage.new(task_name).render
  end

  private

  def template_path
    File.join(Util::PROJECT_DIR, TEMPLATE_PATH)
  end

  def output_path
    File.join(Util::PROJECT_DIR, OUTPUT_PATH)
  end

  def render
    ERB.new(File.read(template_path), trim_mode: '-').result(binding)
  end
end
