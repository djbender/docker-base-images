require 'erb'
require_relative 'metadata'

class Template
  attr_reader :path, :erb

  def initialize(template_path)
    @path = template_path
    @erb = ERB.new(File.read(template_path), trim_mode: '-')
  end

  def filename
    File.basename(path)
  end

  # This method is called via the Rakefile
  # and the values passed in are parsed from the ../manifest.yml file.
  def render(values)
    TemplateRenderer.new(self, Metadata.new(values))
  end

  def self.render_into_dockerfile(path, values)
    new(path).render(values).to_string
  end

  class TemplateRenderer
    def initialize(template, context)
      @template = template
      @context = context
    end

    def to(output_dir)
      filename = @template.filename.delete_suffix('.erb')
      output_path = File.join(output_dir, filename)
      File.write(output_path, to_string)
    end

    def to_string
      @template.erb.result(@context.get_binding)
    end
  end
end
