require_relative '../lib/dependabot_generator'
require_relative '../lib/util'

RSpec.describe DependabotGenerator do
  subject(:generator) { described_class.new(task_name: 'generate:dependabot') }

  describe '#initialize' do
    it 'accepts no-arg construction' do
      expect { described_class.new }.not_to raise_error
    end

    it 'stores task_name' do
      gen = described_class.new(task_name: 'generate:deps')
      expect(gen.task_name).to eq('generate:deps')
    end

    it 'stores nil task_name by default' do
      gen = described_class.new
      expect(gen.task_name).to be_nil
    end
  end

  describe '#generate' do
    before { allow(File).to receive(:write) }

    it 'writes the rendered manifest to .github/dependabot.yml' do
      generator.generate

      expect(File).to have_received(:write).with(
        a_string_ending_with('.github/dependabot.yml'),
        a_string_including('package-ecosystem: docker')
      )
    end

    it 'writes to an absolute path under PROJECT_DIR' do
      generator.generate

      expect(File).to have_received(:write).with(
        File.join(Util::PROJECT_DIR, '.github', 'dependabot.yml'),
        anything
      )
    end

    it 'prints generating message to stdout' do
      expect { generator.generate }.to output(%r{Generating \.github/dependabot\.yml}).to_stdout
    end

    it 'prints Done! to stdout' do
      expect { generator.generate }.to output(/Done!/).to_stdout
    end
  end

  describe '#docker_directories' do
    it 'returns one <image>/<version> per manifest version' do
      expected = Util::MANIFEST.flat_map do |image_name, details|
        details.fetch('versions').keys.map { |version| "#{image_name}/#{version}" }
      end

      expect(generator.docker_directories).to eq(expected)
    end

    it 'does not include the removed globals key' do
      expect(generator.docker_directories).not_to include(a_string_starting_with('globals/'))
    end
  end

  describe 'rendered output' do
    let(:output) do
      generator.send(:render)
    end

    it 'includes the generation notice' do
      expect(output).to include('NOTICE: This is a generated file')
    end

    it 'includes the task name in the generation notice' do
      expect(output).to include('rake generate:dependabot')
    end

    it 'emits a docker stanza for every directory' do
      generator.docker_directories.each do |dir|
        expect(output).to include("directory: #{dir}")
      end
    end

    it 'keeps the static github-actions and bundler ecosystems' do
      expect(output).to include('package-ecosystem: github-actions')
      expect(output).to include('package-ecosystem: bundler')
    end
  end
end
