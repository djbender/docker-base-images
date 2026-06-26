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
      described_class.generated_file = File.join(tmpdir, '.generated.yml')
    end

    after do
      FileUtils.rm_rf(tmpdir)
      described_class.generated_file = nil
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
        KeyError, /Unknown placeholder in test manifest key 'bad_field':.*unknown_placeholder/
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

    it 'saves generated directories to .generated.yml sorted' do
      # Supply versions out of order to prove the output is sorted
      details = {
        'versions' => { '2.0' => {}, '1.0' => {} }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout

      generated = YAML.load_file(File.join(tmpdir, '.generated.yml'))
      expect(generated['test']).to eq(['test/1.0', 'test/2.0'])
    end

    it 'exposes the rendered generation_message to templates' do
      File.write(File.join(template_dir, 'gen.txt.erb'), '<%= generation_message %>')

      details = {
        'template_files' => ['gen.txt.erb'],
        'versions' => { '1.0' => {} }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout

      rendered = File.read(File.join(tmpdir, 'test', '1.0', 'gen.txt'))
      expect(rendered).to include('NOTICE: This is a generated file')
      expect(rendered).to include('rake generate:test')
    end

    it 'exposes output_dir to templates' do
      File.write(File.join(template_dir, 'dir.txt.erb'), 'dir=<%= output_dir %>')

      details = {
        'template_files' => ['dir.txt.erb'],
        'versions' => { '1.0' => {} }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout

      output_dir = File.join(tmpdir, 'test', '1.0')
      expect(File.read(File.join(output_dir, 'dir.txt'))).to eq("dir=#{output_dir}")
    end

    it 'prints per-version progress' do
      details = { 'versions' => { '1.0' => {} } }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect { generator.generate }.to output(/- 1\.0\.\.\. Done!/).to_stdout
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

    it 'passes non-string values through interpolation unchanged' do
      # Template echoes a non-string value so we can assert it survives intact
      File.write(File.join(template_dir, 'num.txt.erb'), 'n=<%= numeric_value %>')

      details = {
        'template_files' => ['num.txt.erb'],
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

      expect { generator.generate }.to output(/Generating test Dockerfiles/).to_stdout
      expect(File.read(File.join(tmpdir, 'test', '1.0', 'num.txt'))).to eq('n=123')
    end

    it 'does not duplicate default templates already in template_files' do
      details = {
        'template_files' => ['Dockerfile.erb', 'docker-bake.hcl.erb'],
        'versions' => { '1.0' => {} }
      }

      generator = described_class.new(
        image_name: 'test',
        details: details,
        task_name: 'generate:test'
      )

      expect(generator.send(:template_filenames))
        .to eq(['Dockerfile.erb', 'docker-bake.hcl.erb'])
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

    context 'with orphan cleanup' do
      # Orphan paths are relative to the working directory, so run each example in
      # a throwaway cwd: the repo is never polluted and examples cannot leak state
      # into one another (which previously made mutation results non-deterministic).
      around do |example|
        Dir.mktmpdir { |cwd| Dir.chdir(cwd) { example.run } }
      end

      it 'removes orphaned directories when user confirms' do
        FileUtils.mkdir_p('test/old_version')

        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/old_version'] }.to_yaml
        )

        allow($stdin).to receive_messages(tty?: true, gets: "y\n")

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(image_name: 'test', details:, task_name: 'generate:test')

        expect { generator.generate }.to output(
          %r{orphaned.*old_version.*Remove these directories\? \[y/N\].*Removing}m
        ).to_stdout

        expect(File).not_to exist('test/old_version')
      end

      it 'does not announce orphan cleanup when there are no orphans' do
        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(
          image_name: 'test',
          details: details,
          task_name: 'generate:test'
        )

        expect { generator.generate }.not_to output(/orphaned directories/i).to_stdout
      end

      it 'does not treat current version directories as orphans' do
        FileUtils.mkdir_p('test/1.0')
        FileUtils.mkdir_p('test/old_version')

        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/1.0', 'test/old_version'] }.to_yaml
        )

        allow($stdin).to receive(:tty?).and_return(false)

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(image_name: 'test', details:, task_name: 'generate:test')

        # Only the orphan is removed; the current version dir is left alone
        expect { generator.generate }.to output(%r{Removing: test/old_version}).to_stdout
        expect(File).to exist('test/1.0')
        expect(File).not_to exist('test/old_version')
      end

      it 'treats an uppercase Y confirmation as yes' do
        FileUtils.mkdir_p('test/old_version')

        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/old_version'] }.to_yaml
        )

        allow($stdin).to receive_messages(tty?: true, gets: "Y\n")

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(image_name: 'test', details:, task_name: 'generate:test')

        expect { generator.generate }.to output(%r{Removing: test/old_version}).to_stdout
        expect(File).not_to exist('test/old_version')
      end

      it 'keeps orphaned directories when user declines' do
        FileUtils.mkdir_p('test/old_version')

        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/old_version'] }.to_yaml
        )

        allow($stdin).to receive_messages(tty?: true, gets: "n\n")

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(image_name: 'test', details:, task_name: 'generate:test')

        expect { generator.generate }.to output(/orphaned/i).to_stdout

        expect(File).to exist('test/old_version')
      end

      it 'auto-removes orphans in non-TTY mode' do
        FileUtils.mkdir_p('test/old_version')

        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/old_version'] }.to_yaml
        )

        allow($stdin).to receive(:tty?).and_return(false)

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(image_name: 'test', details:, task_name: 'generate:test')

        expect { generator.generate }.to output(/orphaned.*Removing/m).to_stdout

        expect(File).not_to exist('test/old_version')
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

      it 'continues removing subsequent orphans after skipping a non-directory entry' do
        FileUtils.mkdir_p('test/real_dir')
        # 'test/not_a_dir' is a file, not a directory
        FileUtils.mkdir_p('test')
        File.write('test/not_a_dir', '')

        File.write(
          File.join(tmpdir, '.generated.yml'),
          { 'test' => ['test/not_a_dir', 'test/real_dir'] }.to_yaml
        )

        allow($stdin).to receive(:tty?).and_return(false)

        details = { 'versions' => { '1.0' => {} } }
        generator = described_class.new(image_name: 'test', details:, task_name: 'generate:test')

        expect { generator.generate }.to output(%r{Removing: test/real_dir}).to_stdout
        expect(File).not_to exist('test/real_dir')
        expect(File).to exist('test/not_a_dir')
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
