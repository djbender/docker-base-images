require 'open3'
require 'tempfile'
require_relative '../lib/change_classifier'
require_relative '../lib/util'

RSpec.describe ChangeClassifier do
  subject(:classifier) { described_class.load(image_dirs: %w[node/2 node/22 core/noble]) }

  describe '.load' do
    let(:file) { Tempfile.new(['rules', '.yml']) }

    after { file.unlink }

    def load_rules(yaml)
      File.write(file.path, yaml)
      described_class.load(image_dirs: [], path: file.path)
    end

    it 'applies the rules in the given file, build_all first' do
      loaded = load_rules("build_all: ['a/keep']\nignore: ['a/*']\n")

      expect(%w[a/keep a/other b].map { |path| loaded.classify(path) }).to eq([[:all], [:ignore], [:all]])
    end

    it 'fails loudly when a list is missing' do
      expect { load_rules("ignore: []\n") }.to raise_error(KeyError, /build_all/)
    end
  end

  describe '#classify' do
    it 'attributes a file inside an image directory to that image' do
      expect(classifier.classify('node/22/Dockerfile')).to eq([:image, 'node/22'])
    end

    %w[
      README.md core/README.md LICENSE site/app.rb spec/util_spec.rb bin/rake config/mutant.yml
      node/template/Dockerfile.erb manifest.yml .generated.yml ruby/examples/Dockerfile
      .github/dependabot.yml .github/template/dependabot.yml.erb
      .github/workflows/cleanup-packages.yml .github/workflows/deploy-docs.yml
      .gitignore .rspec .rubocop.yml .overcommit.sample.yml Parkfile Gemfile Gemfile.lock .ruby-version
    ].each do |path|
      it "ignores #{path}" do
        expect(classifier.classify(path)).to eq([:ignore])
      end
    end

    %w[
      .github/workflows/build-images.yml .github/workflows/actions.lock
      lib/tag_generator.rb rakelib/ci.rake Rakefile change_rules.yml
      .github/scripts/merge-manifests.sh
    ].each do |path|
      it "builds everything for build input #{path}" do
        expect(classifier.classify(path)).to eq([:all])
      end
    end

    it 'names the rules file itself, so no ignore pattern can silently cover it' do
      expect(classifier.explicit?('change_rules.yml')).to be(true)
    end

    it 'lets build inputs win over ignore rules' do
      expect(classifier.classify('lib/README.md')).to eq([:all])
    end

    it 'builds everything for a path no rule knows about' do
      expect(classifier.classify('scripts/foo.sh')).to eq([:all])
    end
  end

  describe '#explicit?' do
    %w[node/22/Dockerfile lib/util.rb README.md .github/scripts/merge-manifests.sh].each do |path|
      it "is true when a rule names #{path}" do
        expect(classifier.explicit?(path)).to be(true)
      end
    end

    it 'is false when the path only builds everything by default' do
      expect(classifier.explicit?('scripts/foo.sh')).to be(false)
    end
  end

  # Attributing a file to one image is only safe while each build sees just its own directory.
  describe 'bake contexts in the generated image directories' do
    it 'never reach outside the image directory' do
      Util.image_dirs.each do |dir|
        bake = File.read(File.join(Util::PROJECT_DIR, dir, Util::BAKE_FILE))

        expect(bake.scan(/^\s*context = "(.*)"$/).flatten.uniq).to eq(["${PWD}/#{dir}"]), dir
        expect(bake).not_to match(/^\s*contexts\b/), dir
      end
    end
  end

  # Fails when someone adds a file without deciding what it should rebuild.
  describe 'rules against the tracked files' do
    subject(:classifier) { described_class.load(image_dirs: Util.image_dirs) }

    let(:tracked) { Open3.capture2('git', 'ls-files', chdir: File.expand_path('..', __dir__)).first.split("\n") }

    it 'has a rule for every tracked file' do
      expect(tracked.reject { |path| classifier.explicit?(path) }).to eq([])
    end
  end
end
