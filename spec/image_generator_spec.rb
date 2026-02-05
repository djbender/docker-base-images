require 'tmpdir'
require 'fileutils'
require_relative '../lib/util'
require_relative '../lib/image_generator'
require_relative '../lib/template'
require_relative '../lib/metadata'
require_relative '../lib/generation_message'

RSpec.describe ImageGenerator do
  describe '#generate' do
    let(:tmpdir) { Dir.mktmpdir }
    let(:template_dir) { File.join(tmpdir, 'test', 'template') }

    before do
      FileUtils.mkdir_p(template_dir)

      # Create minimal Dockerfile template
      File.write(File.join(template_dir, 'Dockerfile.erb'), <<~ERB)
        FROM <%= base_image %>
      ERB

      # Create minimal docker-bake.hcl template
      File.write(File.join(template_dir, 'docker-bake.hcl.erb'), <<~ERB)
        target "<%= image_name %>" {
          tags = ["<%= registry %>/<%= image_name %>:<%= version %>"]
        }
      ERB

      # Stub Util methods to use tmpdir
      allow(Util).to receive(:build_template_dir).with('test').and_return(File.join(tmpdir, 'test', 'template'))
      allow(Util).to receive(:build_output_path) { |*parts| File.join(tmpdir, *parts) }

      # Prevent orphan cleanup from prompting for input
      allow($stdin).to receive(:tty?).and_return(false)

      # Silence generator output
      allow($stdout).to receive(:write)

      # Use temp file for .generated.yml tracking
      ImageGenerator.generated_file = File.join(tmpdir, '.generated.yml')
    end

    after do
      FileUtils.rm_rf(tmpdir)
      ImageGenerator.generated_file = nil
    end

    it 'interpolates %{registry} in base_image' do
      details = {
        'versions' => {
          '1.0' => {
            'base_image' => '%{registry}/core:noble'
          }
        }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      # Capture stdout to suppress generation messages
      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout

      dockerfile = File.read(File.join(tmpdir, 'test', '1.0', 'Dockerfile'))
      expect(dockerfile).to include('FROM ghcr.io/djbender/core:noble')
    end

    it 'passes registry to templates for ERB interpolation' do
      details = {
        'versions' => {
          '2.0' => {}
        }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout

      bake_file = File.read(File.join(tmpdir, 'test', '2.0', 'docker-bake.hcl'))
      expect(bake_file).to include('tags = ["ghcr.io/djbender/test:2.0"]')
    end

    it 'raises helpful error for unknown placeholders' do
      details = {
        'versions' => {
          '1.0' => {
            'bad_field' => '%{unknown_placeholder}'
          }
        }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to raise_error(KeyError, /Unknown placeholder.*test.*bad_field.*unknown_placeholder/)
    end
  end
end
