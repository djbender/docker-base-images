class ImageGenerator
  DEFAULT_GENERATED_FILE = '.generated.yml'.freeze

  class << self
    attr_writer :generated_file

    def generated_file
      @generated_file || DEFAULT_GENERATED_FILE
    end
  end

  attr_reader :details, :image_name, :task_name

  def initialize(image_name:, details:, task_name:)
    @details = details
    @image_name = image_name
    @task_name = task_name
  end

  def generate
    puts "Generating #{image_name} Dockerfiles"
    cleanup_orphaned_directories
    @details.fetch('versions').each do |version, values|
      print "- #{version}... "
      values ||= {}
      Util.with_clean_output_dir(image_name, version) do |output_dir|
        templates.each do |template|
          template.render(template_values(values:, version:, output_dir:)).to(output_dir)
        end
      end
      puts 'Done!'
    end
    save_generated_dirs
  end

  private

  def template_values(values:, version:, output_dir:)
    merged = Util::GLOBAL_DEFAULTS
      .fetch('defaults', {})
      .merge(defaults)
      .merge(values)
      .merge(
        generation_message:,
        version:,
        image_name:,
        output_dir:
      )
    interpolate_registry(merged)
  end

  def interpolate_registry(values)
    values.transform_values.with_index do |v, _|
      next v unless v.is_a?(String)

      format(v, registry: Util::REGISTRY)
    rescue KeyError => e
      key = values.key(v)
      # rubocop:disable Style/FormatStringToken
      raise KeyError,
            "Unknown placeholder in #{image_name} manifest key '#{key}': #{e.message}. Only %{registry} is supported."
      # rubocop:enable Style/FormatStringToken
    end
  end

  def template_filenames
    # TODO: refactor with Set?
    @details.fetch('template_files') { [] }.tap do |files|
      files << 'Dockerfile.erb' unless files.include?('Dockerfile.erb')
      files << 'docker-bake.hcl.erb' unless files.include?('docker-bake.hcl.erb')
    end
  end

  def template_dir
    Util.build_template_dir(@image_name)
  end

  def templates
    template_filenames.map { |filename| Template.new(File.join(template_dir, filename)) }
  end

  def generation_message
    GenerationMessage.new(@task_name).render
  end

  def defaults
    @details.fetch('defaults', {})
  end

  def cleanup_orphaned_directories
    previously_generated = read_generated_file.fetch(image_name, [])
    orphans = previously_generated - version_directories
    return if orphans.empty?

    puts 'Found orphaned directories not in manifest:'
    orphans.each { |dir| puts "  - #{dir}" }
    if $stdin.tty?
      print 'Remove these directories? [y/N] '
      return unless $stdin.gets.chomp.downcase == 'y'
    end

    orphans.each do |dir|
      next unless File.directory?(dir)

      puts "Removing: #{dir}"
      FileUtils.rm_r(dir)
    end
  end

  def save_generated_dirs
    all_generated = read_generated_file
    all_generated[image_name] = version_directories.sort
    File.write(self.class.generated_file, all_generated.to_yaml)
  end

  def version_directories
    @details.fetch('versions').keys.map { |v| "#{image_name}/#{v}" }
  end

  def read_generated_file
    return {} unless File.exist?(self.class.generated_file)

    YAML.safe_load_file(self.class.generated_file, permitted_classes: []) || {}
  end
end
