require_relative '../lib/tag_generator'
require_relative '../lib/util'

RSpec.describe TagGenerator do
  let(:registry) { Util::REGISTRY }

  describe '.primary_tags' do
    context 'with core image' do
      it 'generates version tag' do
        tags = described_class.primary_tags('core', 'version' => 'jammy')

        expect(tags).to include("#{registry}/core:jammy")
      end

      it 'includes SHA tag when github_sha value present' do
        tags = described_class.primary_tags('core', 'version' => 'jammy', 'github_sha' => 'abc123')

        expect(tags).to include("#{registry}/core:abc123")
      end

      it 'excludes SHA tag when github_sha value absent' do
        tags = described_class.primary_tags('core', 'version' => 'jammy')

        expect(tags.none? { |t| t.match?(/:[a-f0-9]{40}$/) }).to be true
      end

      it 'does not read GITHUB_SHA from the environment' do
        original = ENV.fetch('GITHUB_SHA', nil)
        ENV['GITHUB_SHA'] = 'deadbeef'

        tags = described_class.primary_tags('core', 'version' => 'jammy')

        expect(tags).not_to include("#{registry}/core:deadbeef")
      ensure
        ENV['GITHUB_SHA'] = original
      end

      it 'includes latest tag when latest: true' do
        tags = described_class.primary_tags('core', 'version' => 'noble', 'latest' => true)

        expect(tags).to include("#{registry}/core:latest")
      end

      it 'includes rolling tag when rolling: true' do
        tags = described_class.primary_tags('core', 'version' => 'noble', 'rolling' => true)

        expect(tags).to include("#{registry}/core:rolling")
      end

      it 'includes additional_tags from manifest' do
        tags = described_class.primary_tags(
          'core',
          'version' => 'jammy',
          'additional_tags' => ["#{registry}/core:lts"]
        )

        expect(tags).to include("#{registry}/core:lts")
      end
    end

    context 'with flavor' do
      it 'generates flavor tag' do
        tags = described_class.primary_tags('core', 'version' => 'jammy', 'flavor' => 'slim')

        expect(tags).to include("#{registry}/core:jammy-slim")
        expect(tags).to include("#{registry}/core:jammy")
      end

      it 'ignores empty flavor string' do
        tags = described_class.primary_tags('core', 'version' => 'jammy', 'flavor' => '')

        expect(tags).to eq(["#{registry}/core:jammy"])
      end

      it 'skips version tag when flavor is dev' do
        tags = described_class.primary_tags('core', 'version' => 'jammy', 'flavor' => 'dev')

        expect(tags).not_to include("#{registry}/core:jammy")
        expect(tags).to include("#{registry}/core:jammy-dev")
      end

      it 'handles version already containing flavor' do
        tags = described_class.primary_tags('core', 'version' => 'jammy-slim', 'flavor' => 'slim')

        expect(tags).to eq(["#{registry}/core:jammy-slim"])
      end
    end

    context 'with ruby image' do
      let(:ruby_values) do
        {
          'version' => '3.3',
          'ruby_version' => '3.3.0',
          'ruby_major' => '3.3',
          'distribution_code_name' => 'noble'
        }
      end

      it 'generates full version tag' do
        tags = described_class.primary_tags('ruby', ruby_values)

        expect(tags).to include("#{registry}/ruby:3.3.0")
      end

      it 'generates version-distribution tag' do
        tags = described_class.primary_tags('ruby', ruby_values)

        expect(tags).to include("#{registry}/ruby:3.3.0-noble")
      end

      it 'generates major version tag' do
        tags = described_class.primary_tags('ruby', ruby_values)

        expect(tags).to include("#{registry}/ruby:3.3")
      end

      it 'generates major-distribution tag' do
        tags = described_class.primary_tags('ruby', ruby_values)

        expect(tags).to include("#{registry}/ruby:3.3-noble")
      end
    end

    context 'with node image' do
      let(:node_values) do
        {
          'version' => '22',
          'node_version' => '22.1.0',
          'node_major' => '22',
          'distribution_code_name' => 'noble'
        }
      end

      it 'generates language-specific tags' do
        tags = described_class.primary_tags('node', node_values)

        expect(tags).to include("#{registry}/node:22.1.0")
        expect(tags).to include("#{registry}/node:22.1.0-noble")
        expect(tags).to include("#{registry}/node:22")
        expect(tags).to include("#{registry}/node:22-noble")
      end
    end

    context 'with unknown image' do
      it 'returns only default tags' do
        tags = described_class.primary_tags('unknown', 'version' => '1.0')

        expect(tags).to eq(["#{registry}/unknown:1.0"])
      end
    end

    it 'returns sorted unique tags' do
      tags = described_class.primary_tags(
        'core',
        'version' => 'jammy',
        'github_sha' => 'abc123',
        'additional_tags' => ["#{registry}/core:jammy"] # duplicate
      )

      expect(tags).to eq(tags.uniq.sort)
    end

    it 'accepts string keys' do
      tags = described_class.primary_tags('core', 'version' => 'jammy')

      expect(tags).to include("#{registry}/core:jammy")
    end
  end

  describe '.dev_tags' do
    context 'with core image' do
      it 'generates distribution-dev tag' do
        tags = described_class.dev_tags('core', 'version' => 'jammy', 'distribution_code_name' => 'jammy')

        expect(tags).to include("#{registry}/core:jammy-dev")
      end

      it 'includes SHA tag when github_sha value present' do
        tags = described_class.dev_tags(
          'core',
          'version' => 'jammy',
          'distribution_code_name' => 'jammy',
          'github_sha' => 'def456'
        )

        expect(tags).to include("#{registry}/core:def456")
      end

      it 'includes dev tag when latest: true' do
        tags = described_class.dev_tags(
          'core',
          'version' => 'noble',
          'distribution_code_name' => 'noble',
          'latest' => true
        )

        expect(tags).to include("#{registry}/core:dev")
      end

      it 'includes additional_dev_tags from manifest' do
        tags = described_class.dev_tags(
          'core',
          'version' => 'jammy',
          'distribution_code_name' => 'jammy',
          'additional_dev_tags' => ["#{registry}/core:jammy-development"]
        )

        expect(tags).to include("#{registry}/core:jammy-development")
      end
    end

    context 'with ruby image' do
      let(:ruby_values) do
        {
          'version' => '3.3',
          'ruby_version' => '3.3.0',
          'ruby_major' => '3.3',
          'distribution_code_name' => 'noble'
        }
      end

      it 'generates full version dev tags' do
        tags = described_class.dev_tags('ruby', ruby_values)

        expect(tags).to include("#{registry}/ruby:3.3.0-dev")
        expect(tags).to include("#{registry}/ruby:3.3.0-dev-noble")
      end

      it 'generates major version dev tags' do
        tags = described_class.dev_tags('ruby', ruby_values)

        expect(tags).to include("#{registry}/ruby:3.3-dev")
        expect(tags).to include("#{registry}/ruby:3.3-dev-noble")
      end
    end

    context 'with node image' do
      let(:node_values) do
        {
          'version' => '22',
          'node_version' => '22.1.0',
          'node_major' => '22',
          'distribution_code_name' => 'noble'
        }
      end

      it 'generates language-specific dev tags' do
        tags = described_class.dev_tags('node', node_values)

        expect(tags).to include("#{registry}/node:22.1.0-dev")
        expect(tags).to include("#{registry}/node:22.1.0-dev-noble")
        expect(tags).to include("#{registry}/node:22-dev")
        expect(tags).to include("#{registry}/node:22-dev-noble")
      end
    end

    context 'with unknown image' do
      it 'returns only default dev tags' do
        tags = described_class.dev_tags('unknown', 'version' => '1.0')

        expect(tags).to eq([])
      end

      it 'includes SHA when github_sha value present' do
        tags = described_class.dev_tags('unknown', 'version' => '1.0', 'github_sha' => 'xyz789')

        expect(tags).to eq(["#{registry}/unknown:xyz789"])
      end
    end

    it 'returns sorted unique tags' do
      tags = described_class.dev_tags(
        'core',
        'version' => 'jammy',
        'distribution_code_name' => 'jammy'
      )

      expect(tags).to eq(tags.uniq.sort)
    end

    it 'sorts multiple dev tags alphabetically' do
      tags = described_class.dev_tags(
        'core',
        'version' => 'jammy',
        'distribution_code_name' => 'jammy',
        'github_sha' => 'zzz'
      )

      expect(tags).to eq(["#{registry}/core:jammy-dev", "#{registry}/core:zzz"])
    end

    it 'deduplicates when additional_dev_tags repeats a generated tag' do
      tags = described_class.dev_tags(
        'core',
        'version' => 'jammy',
        'distribution_code_name' => 'jammy',
        'additional_dev_tags' => ["#{registry}/core:jammy-dev"]
      )

      expect(tags).to eq(["#{registry}/core:jammy-dev"])
    end
  end
end
