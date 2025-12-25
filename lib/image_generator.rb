class ImageGenerator
  GENERATED_FILE = '.generated.yml'

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
    Util::GLOBAL_DEFAULTS
      .fetch('defaults', {})
      .merge(defaults)
      .merge(values)
      .merge(
        generation_message:,
        version:,
        image_name:,
        output_dir:
      )
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

    puts "Found orphaned directories not in manifest:"
    orphans.each { |dir| puts "  - #{dir}" }
    if $stdin.tty?
      print "Remove these directories? [y/N] "
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
    File.write(GENERATED_FILE, all_generated.to_yaml)
  end

  def version_directories
    @details.fetch('versions').keys.map { |v| "#{image_name}/#{v}" }
  end

  def read_generated_file
    return {} unless File.exist?(GENERATED_FILE)

    YAML.safe_load_file(GENERATED_FILE, permitted_classes: []) || {}
  end
end
