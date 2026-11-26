require 'tmpdir'
require 'fileutils'
require_relative '../lib/image_graph'

RSpec.describe ImageGraph do
  describe '#with_dependents against this repository' do
    subject(:graph) { described_class.new }

    it 'includes images built FROM a tagged core image' do
      result = graph.with_dependents(['core/noble'])

      expect(result).to include('core/noble', 'ruby/3.1', 'ruby/2.7')
      expect(result).not_to include('node/22', 'core/jammy')
    end

    it 'treats an untagged reference as the latest core' do
      expect(graph.with_dependents(['core/resolute'])).to include('node/22', 'ruby/4.0')
    end

    it 'resolves every registry reference in the repository' do
      expect { graph.with_dependents(Util.image_dirs) }.not_to raise_error
    end
  end

  describe '#with_dependents' do
    subject(:graph) { described_class.new(root: root, manifest: manifest) }

    let(:root) { Dir.mktmpdir }
    let(:manifest) do
      %w[base middle top copier other].to_h { |name| [name, { 'versions' => { '1' => { 'latest' => true } } }] }
    end
    let(:dockerfiles) do
      {
        'base' => "FROM ubuntu:noble\n",
        'middle' => "FROM --platform=$BUILDPLATFORM ghcr.io/djbender/base:1 AS middle\n",
        'top' => "FROM ghcr.io/djbender/middle\n",
        'copier' => "FROM ubuntu:noble\nCOPY --from=ghcr.io/djbender/base:1 /a /a\n",
        'other' => "# FROM ghcr.io/djbender/base:1\n# COPY --from=ghcr.io/djbender/base:1 /a /a\nFROM ubuntu:noble\n"
      }
    end

    before do
      dockerfiles.each do |name, content|
        FileUtils.mkdir_p("#{root}/#{name}/1")
        File.write("#{root}/#{name}/1/Dockerfile", content)
      end
    end

    after { FileUtils.rm_rf(root) }

    it 'follows dependents transitively, including COPY --from, ignoring comments' do
      expect(graph.with_dependents(['base/1'])).to contain_exactly('base/1', 'middle/1', 'top/1', 'copier/1')
    end

    context 'with a reference to a dev tag' do
      let(:manifest) do
        super().merge('base' => { 'versions' => { '1' => { 'additional_dev_tags' => 'ghcr.io/djbender/base:1-dev' } } })
      end
      let(:dockerfiles) { super().merge('top' => "FROM ghcr.io/djbender/base:1-dev\n") }

      it 'counts it as a dependent' do
        expect(graph.with_dependents(['base/1'])).to include('top/1')
      end
    end

    it 'returns nothing for nothing' do
      expect(graph.with_dependents([])).to eq([])
    end

    context 'with a reference to an image the manifest does not produce' do
      let(:dockerfiles) { super().merge('top' => "FROM ghcr.io/djbender/missing:9\n") }

      it 'raises UnknownReference naming it' do
        expect { graph.with_dependents(['base/1']) }
          .to raise_error(ImageGraph::UnknownReference, %r{top/1.*ghcr\.io/djbender/missing:9})
      end
    end
  end
end
