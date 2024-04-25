class ImageGenerator
  attr_accessor :details, :image_name, :task_name

  def initialize(image_name:, details:, task_name:)
    @details = details
    @image_name = image_name
    @task_name = task_name
  end

  def generate
    puts "Generating #{image_name} Dockerfiles"
    @details.fetch('versions').each do |version, values|
      print "- #{version}... "
      values ||= {}
      Util.with_clean_output_dir(image_name, version) do |output_dir|
        templates.each do |template|
          template.render(template_values(values:, version:, output_dir:)).to(output_dir)
        end
        # copy_non_template_files(output_dir:)
      end
      puts 'Done!'
    end
  end

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

  def copy_non_template_files(output_dir:)
    files_to_copy = Dir.glob(File.join(template_dir, '**')).reject do |path|
      templates.any? { |template| File.identical?(path, template.path) }
    end
    FileUtils.cp_r(files_to_copy, output_dir, preserve: true)
  end
end
