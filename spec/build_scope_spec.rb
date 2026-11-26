require 'tmpdir'
require 'fileutils'
require 'stringio'
require 'open3'
require_relative '../lib/build_scope'

RSpec.describe BuildScope do
  let(:log) { StringIO.new }

  before { allow(described_class).to receive(:warn) { |message| log.puts(message) } }

  def scope_for(changed: ['node/22/Dockerfile'], event: 'pull_request', base: 'a' * 40, graph: ImageGraph.new)
    described_class.for(event: event, base: base, graph: graph,
                        classifier: ChangeClassifier.new(image_dirs: Util.image_dirs),
                        diff: ->(_base) { changed })
  end

  def built(scope)
    Util.image_dirs.select { |dir| scope.include?(dir) }
  end

  def expect_full_build(scope, reason)
    expect(built(scope)).to eq(Util.image_dirs)
    expect(log.string).to match(reason)
  end

  it 'includes only the changed image' do
    expect(built(scope_for)).to eq(['node/22'])
    expect(log.string).to include('node/22')
  end

  it 'includes nothing when only ignored files changed' do
    expect(built(scope_for(changed: ['CHANGELOG.md', 'spec/util_spec.rb']))).to eq([])
    expect(log.string).to include('none')
  end

  it 'includes the dependents of a changed core image' do
    expect(built(scope_for(changed: ['core/noble/Dockerfile']))).to include('core/noble', 'ruby/3.1')
  end

  it 'prunes pushes as well as pull requests' do
    expect(built(scope_for(event: 'push'))).to eq(['node/22'])
  end

  it 'builds everything when a build input changed' do
    expect_full_build(scope_for(changed: ['node/22/Dockerfile', 'lib/util.rb']), %r{lib/util\.rb})
  end

  ['schedule', 'workflow_dispatch', nil].each do |event|
    it "builds everything for the #{event.inspect} event" do
      expect_full_build(scope_for(event: event), /event/)
    end
  end

  [nil, '', '0' * 40, '--output=/tmp/x', 'main'].each do |base|
    it "builds everything when the base is #{base.inspect}" do
      expect_full_build(scope_for(base: base), /base/)
    end
  end

  it 'builds everything when the diff fails' do
    expect_full_build(scope_for(changed: nil), /diff/)
  end

  it 'builds everything when the image graph cannot be resolved' do
    graph = instance_double(ImageGraph)
    allow(graph).to receive(:with_dependents).and_raise(ImageGraph::UnknownReference, 'unknown image x')

    expect_full_build(scope_for(graph: graph), /unknown image x/)
  end

  describe BuildScope::GitDiff do
    subject(:git_diff) { described_class.new(root: root) }

    let(:root) { Dir.mktmpdir }

    after { FileUtils.rm_rf(root) }

    def git(*args)
      out, status = Open3.capture2('git', '-C', root, '-c', 'user.name=t', '-c', 'user.email=t@example.com',
                                   '-c', 'commit.gpgsign=false', *args)
      raise "git #{args.first} failed" unless status.success?

      out.strip
    end

    def first_commit
      git('init', '--quiet')
      FileUtils.mkdir_p("#{root}/old")
      File.write("#{root}/old/file", 'content')
      git('add', 'old/file')
      git('commit', '--quiet', '-m', 'first')
      git('rev-parse', 'HEAD')
    end

    it 'lists both sides of a move since the base' do
      base = first_commit
      FileUtils.mkdir_p("#{root}/new")
      git('mv', 'old/file', 'new/file')
      git('commit', '--quiet', '-m', 'move')

      expect(git_diff.call(base)).to contain_exactly('old/file', 'new/file')
    end

    it 'returns nil when the base commit does not exist' do
      first_commit

      expect(git_diff.call('b' * 40)).to be_nil
    end
  end
end
