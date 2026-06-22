require_relative '../lib/dependabot_generator'
require_relative '../lib/util'

RSpec.describe DependabotGenerator do
  subject(:generator) { described_class.new(task_name: 'generate:dependabot') }

  describe '#generate' do
    before { allow(File).to receive(:write) }

    it 'writes the rendered manifest to .github/dependabot.yml' do
      generator.generate

      expect(File).to have_received(:write).with(
        a_string_ending_with('.github/dependabot.yml'),
        a_string_including('package-ecosystem: docker')
      )
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
