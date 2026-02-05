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

    # rubocop:disable Style/FormatStringToken
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

      expect { generator.generate }.to raise_error(
        KeyError, /Unknown placeholder.*test.*bad_field.*unknown_placeholder/
      )
    end
    # rubocop:enable Style/FormatStringToken

    it 'merges image-level defaults with version values' do
      details = {
        'defaults' => { 'base_image' => 'ubuntu:22.04' },
        'versions' => { '1.0' => {} }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout

      dockerfile = File.read(File.join(tmpdir, 'test', '1.0', 'Dockerfile'))
      expect(dockerfile).to include('FROM ubuntu:22.04')
    end

    it 'version values override defaults' do
      details = {
        'defaults' => { 'base_image' => 'ubuntu:20.04' },
        'versions' => { '1.0' => { 'base_image' => 'ubuntu:22.04' } }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout

      dockerfile = File.read(File.join(tmpdir, 'test', '1.0', 'Dockerfile'))
      expect(dockerfile).to include('FROM ubuntu:22.04')
    end

    it 'saves generated directories to .generated.yml' do
      details = {
        'versions' => { '1.0' => {}, '2.0' => {} }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout

      generated = YAML.load_file(File.join(tmpdir, '.generated.yml'))
      expect(generated['test']).to contain_exactly('test/1.0', 'test/2.0')
    end

    it 'uses custom template_files from details' do
      # Create custom template
      File.write(File.join(template_dir, 'custom.txt.erb'), 'custom: <%= version %>')

      details = {
        'template_files' => ['custom.txt.erb'],
        'versions' => { '1.0' => {} }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout

      # Custom template rendered
      expect(File.read(File.join(tmpdir, 'test', '1.0', 'custom.txt'))).to eq('custom: 1.0')
      # Default templates also rendered
      expect(File.exist?(File.join(tmpdir, 'test', '1.0', 'Dockerfile'))).to be true
      expect(File.exist?(File.join(tmpdir, 'test', '1.0', 'docker-bake.hcl'))).to be true
    end

    it 'handles nil version values' do
      details = {
        'versions' => { '1.0' => nil }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout
      expect(File.exist?(File.join(tmpdir, 'test', '1.0', 'Dockerfile'))).to be true
    end

    it 'skips non-string values during registry interpolation' do
      details = {
        'versions' => {
          '1.0' => {
            'numeric_value' => 123,
            'array_value' => %w[a b],
            'hash_value' => { 'nested' => 'data' }
          }
        }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      # Should not raise - non-strings are passed through unchanged
      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout
    end

    it 'does not duplicate Dockerfile.erb when already in template_files' do
      details = {
        'template_files' => ['Dockerfile.erb', 'docker-bake.hcl.erb'],
        'versions' => { '1.0' => {} }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      # Should generate without error (no duplicate template processing)
      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout
    end

    it 'handles empty .generated.yml file' do
      # Write empty/nil YAML
      File.write(File.join(tmpdir, '.generated.yml'), '')

      details = { 'versions' => { '1.0' => {} } }
      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout
    end

    context 'orphan cleanup' do
      it 'removes orphaned directories when user confirms' do
        # Create orphan at relative path (code uses relative paths)
        FileUtils.mkdir_p('test/old_version')
        File.write('test/old_version/Dockerfile', 'old')

        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/old_version'] }.to_yaml
        )

        allow($stdin).to receive(:tty?).and_return(true)
        allow($stdin).to receive(:gets).and_return("y\n")

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(
          image_name: 'test',
          details: details,
          task_name: 'generate:test'
        )

        expect { generator.generate }.to output(/orphaned.*old_version.*Removing/m).to_stdout

        expect(File.exist?('test/old_version')).to be false
      ensure
        FileUtils.rm_rf('test/old_version')
      end

      it 'keeps orphaned directories when user declines' do
        FileUtils.mkdir_p('test/old_version')

        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/old_version'] }.to_yaml
        )

        allow($stdin).to receive(:tty?).and_return(true)
        allow($stdin).to receive(:gets).and_return("n\n")

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(
          image_name: 'test',
          details: details,
          task_name: 'generate:test'
        )

        expect { generator.generate }.to output(/orphaned/i).to_stdout

        expect(File.exist?('test/old_version')).to be true
      ensure
        FileUtils.rm_rf('test/old_version')
      end

      it 'auto-removes orphans in non-TTY mode' do
        FileUtils.mkdir_p('test/old_version')

        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/old_version'] }.to_yaml
        )

        allow($stdin).to receive(:tty?).and_return(false)

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(
          image_name: 'test',
          details: details,
          task_name: 'generate:test'
        )

        expect { generator.generate }.to output(/orphaned.*Removing/m).to_stdout

        expect(File.exist?('test/old_version')).to be false
      ensure
        FileUtils.rm_rf('test/old_version')
      end

      it 'skips removal for non-existent orphan directories' do
        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/missing_dir'] }.to_yaml
        )

        allow($stdin).to receive(:tty?).and_return(false)

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(
          image_name: 'test',
          details: details,
          task_name: 'generate:test'
        )

        # Should not raise, outputs orphan notice but no Removing
        expect { generator.generate }.to output(/orphaned/i).to_stdout
        expect { generator.generate }.not_to output(/Removing/i).to_stdout
      end
    end
  end

  describe '.generated_file' do
    after { described_class.generated_file = nil }

    it 'returns default when not set' do
      described_class.generated_file = nil
      expect(described_class.generated_file).to eq('.generated.yml')
    end

    it 'returns custom value when set' do
      described_class.generated_file = '/custom/path.yml'
      expect(described_class.generated_file).to eq('/custom/path.yml')
    end
  end

  describe '#initialize' do
    it 'stores image_name, details, and task_name' do
      details = { 'versions' => {} }
      generator = described_class.new(
        image_name: 'ruby',
        details: details,
        task_name: 'generate:ruby'
      )

      expect(generator.image_name).to eq('ruby')
      expect(generator.details).to eq(details)
      expect(generator.task_name).to eq('generate:ruby')
    end
  end
end
