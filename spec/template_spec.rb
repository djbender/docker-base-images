require 'tmpdir'
require 'fileutils'
require_relative '../lib/template'

RSpec.describe Template do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(tmpdir) }

  def create_template(content)
    path = File.join(tmpdir, 'test.erb')
    File.write(path, content)
    path
  end

  describe '#initialize' do
    it 'reads template file and creates ERB instance' do
      path = create_template('Hello <%= name %>')
      template = described_class.new(path)

      expect(template.path).to eq(path)
      expect(template.erb).to be_a(ERB)
    end
  end

  describe '#filename' do
    it 'returns basename of template path' do
      path = create_template('content')
      template = described_class.new(path)

      expect(template.filename).to eq('test.erb')
    end
  end

  describe '#render' do
    it 'returns a TemplateRenderer' do
      path = create_template('<%= foo %>')
      template = described_class.new(path)

      renderer = template.render({ 'foo' => 'bar' })

      expect(renderer).to be_a(Template::TemplateRenderer)
    end
  end

  describe '.render_into_dockerfile' do
    it 'renders template to string with given values' do
      path = create_template('FROM <%= base_image %>')

      result = described_class.render_into_dockerfile(path, { 'base_image' => 'ubuntu:22.04' })

      expect(result).to eq('FROM ubuntu:22.04')
    end
  end

  describe Template::TemplateRenderer do
    describe '#to_string' do
      it 'renders template with context values' do
        path = create_template('Version: <%= version %>')
        template = Template.new(path)
        renderer = template.render({ 'version' => '1.2.3' })

        expect(renderer.to_string).to eq('Version: 1.2.3')
      end

      it 'handles ERB trim mode' do
        path = create_template(<<~ERB)
          <% if true -%>
          trimmed
          <% end -%>
        ERB
        template = Template.new(path)
        renderer = template.render({})

        expect(renderer.to_string).to eq("trimmed\n")
      end
    end

    describe '#to' do
      it 'writes rendered content to output directory' do
        path = create_template('Hello <%= name %>')
        template = Template.new(path)
        renderer = template.render({ 'name' => 'World' })

        output_dir = File.join(tmpdir, 'output')
        FileUtils.mkdir_p(output_dir)
        renderer.to(output_dir)

        output_file = File.join(output_dir, 'test')
        expect(File.exist?(output_file)).to be true
        expect(File.read(output_file)).to eq('Hello World')
      end

      it 'strips .erb suffix from filename' do
        template_path = File.join(tmpdir, 'Dockerfile.erb')
        File.write(template_path, 'FROM ubuntu')
        template = Template.new(template_path)
        renderer = template.render({})

        output_dir = File.join(tmpdir, 'output')
        FileUtils.mkdir_p(output_dir)
        renderer.to(output_dir)

        expect(File.exist?(File.join(output_dir, 'Dockerfile'))).to be true
        expect(File.exist?(File.join(output_dir, 'Dockerfile.erb'))).to be false
      end
    end
  end
end
