require 'fileutils'
require 'pathname'
require 'rake'
require 'yaml'

# Util class is used by ../rakelib/*.rake files
class Util
  PROJECT_DIR = Rake.original_dir
  PROJECT_PATHNAME = Pathname.new(PROJECT_DIR)
  BAKE_FILE = 'docker-bake.hcl'.freeze
  MANIFEST = YAML.load_file(File.join(PROJECT_DIR, 'manifest.yml'), aliases: true)

  # Get global defaults, and delete from yml so they are not translated into a docker image
  GLOBAL_DEFAULTS = MANIFEST.delete('globals')
  REGISTRY = GLOBAL_DEFAULTS.fetch('defaults').fetch('registry').freeze

  # Used by Util#with_clean_output_dir to build out paths
  # example:
  #  input of ['ruby', '3.1'] would return <project_dir>/ruby/3.1
  def self.build_output_path(*parts)
    File.join(PROJECT_DIR, *parts)
  end

  # In generate rake tasks, this method is used to generate the template paths
  def self.build_template_dir(image_name)
    File.join(image_name, 'template')
  end

  # In generate rake tasks, this method is used to
  # remove files, and ensure directories exist
  #
  # Example:
  #   deletes PROJECT_DIR/ruby/3.1 if the path exists
  #   recreates PROJECT_DIR/ruby/3.1
  def self.with_clean_output_dir(*path_parts)
    output_dir = build_output_path(*path_parts)
    FileUtils.rm_r(output_dir) if File.exist?(output_dir)
    FileUtils.mkdir_p(output_dir)
    yield output_dir
  end
end
