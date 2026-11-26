require 'fileutils'
require 'open3'
require 'tmpdir'

# Runs the script against a fake docker that keeps its "registry" in files
RSpec.describe 'merge-manifests.sh' do # rubocop:disable RSpec/DescribeClass
  let(:dir) { Dir.mktmpdir }
  let(:existing) { [] }
  let(:inspect_error) { nil }
  let(:env) do
    {
      'IMAGE_BASE' => "#{image}:3.4", 'GITHUB_RUN_ID' => '42', 'GITHUB_SHA' => sha,
      'PRIMARY_TAGS' => "#{image}:3.4 #{image}:3.4-#{sha}", 'DEV_TAGS' => "#{image}:3.4-dev-#{sha}",
      'PRIMARY_SOURCES' => '', 'DEV_SOURCES' => ''
    }
  end

  def sha = 'abc123'
  def image = 'reg.test/ruby'

  after { FileUtils.remove_entry(dir) }

  before do
    File.write(File.join(dir, 'docker'), <<~SH)
      #!/usr/bin/env bash
      # docker buildx imagetools (inspect REF | create -t TAG SOURCE...)
      if [[ $3 == inspect ]]; then
        if [[ -n $INSPECT_ERROR ]]; then echo "ERROR: $INSPECT_ERROR" >&2; exit 1; fi
        grep -qxF "$4" "$FAKE_DIR/existing" && exit 0
        echo "ERROR: $4: not found" >&2
        exit 1
      fi
      shift 3
      echo "$*" >> "$FAKE_DIR/created"
    SH
    File.chmod(0o755, File.join(dir, 'docker'))
    File.write(File.join(dir, 'existing'), existing.map { |ref| "#{ref}\n" }.join)
  end

  def merge
    vars = env.merge('PATH' => "#{dir}:#{ENV.fetch('PATH')}", 'FAKE_DIR' => dir,
                     'INSPECT_ERROR' => inspect_error.to_s)
    Open3.capture2e(vars, File.expand_path('../.github/scripts/merge-manifests.sh', __dir__))
  end

  def created
    path = File.join(dir, 'created')
    File.exist?(path) ? File.readlines(path, chomp: true) : []
  end

  def arch_sources(suffix)
    "#{image}:3.4#{suffix}-42-amd64 #{image}:3.4#{suffix}-42-arm64"
  end

  context 'with a built image' do
    it 'creates every tag from the per-arch images of this run' do
      output, status = merge

      expect(status).to be_success, output
      expect(created).to eq([
                              "-t #{image}:3.4 #{arch_sources('')}",
                              "-t #{image}:3.4-#{sha} #{arch_sources('')}",
                              "-t #{image}:3.4-dev-#{sha} #{arch_sources('-dev')}"
                            ])
    end

    context 'when SHA tags already exist' do
      let(:existing) { ["#{image}:3.4", "#{image}:3.4-#{sha}", "#{image}:#{sha}"] }
      let(:env) { super().merge('PRIMARY_TAGS' => existing.join(' ')) }

      it 'leaves them alone and still moves the other tags' do
        output, status = merge

        expect(status).to be_success, output
        expect(created.map { |line| line.split[1] }).to eq(["#{image}:3.4", "#{image}:3.4-dev-#{sha}"])
        expect(output).to include("Skipping existing SHA tag #{image}:3.4-#{sha}")
        expect(output).to include("Skipping existing SHA tag #{image}:#{sha}")
      end
    end
  end

  context 'with an unchanged image' do
    let(:env) do
      super().merge(
        'PRIMARY_TAGS' => "#{image}:3.4-#{sha}", 'DEV_TAGS' => "#{image}:3.4-dev-#{sha}",
        'PRIMARY_SOURCES' => "#{image}:3.4-base #{image}:3.4",
        'DEV_SOURCES' => "#{image}:3.4-dev-base #{image}:3.4-dev"
      )
    end

    context 'when the base SHA tags exist' do
      let(:existing) { ["#{image}:3.4-base", "#{image}:3.4", "#{image}:3.4-dev-base", "#{image}:3.4-dev"] }

      it 're-tags from them' do
        output, status = merge

        expect(status).to be_success, output
        expect(created).to eq([
                                "-t #{image}:3.4-#{sha} #{image}:3.4-base",
                                "-t #{image}:3.4-dev-#{sha} #{image}:3.4-dev-base"
                              ])
      end
    end

    context 'when only the version tags exist' do
      let(:existing) { ["#{image}:3.4", "#{image}:3.4-dev"] }

      it 're-tags from them' do
        output, status = merge

        expect(status).to be_success, output
        expect(created).to eq([
                                "-t #{image}:3.4-#{sha} #{image}:3.4",
                                "-t #{image}:3.4-dev-#{sha} #{image}:3.4-dev"
                              ])
      end
    end

    context 'when no source exists' do
      let(:existing) { ["#{image}:3.4"] }

      it 'fails' do
        output, status = merge

        expect(status).not_to be_success
        expect(output).to include("No source found among: #{image}:3.4-dev-base #{image}:3.4-dev")
      end
    end

    context 'when the registry cannot be read' do
      let(:existing) { ["#{image}:3.4"] }
      let(:inspect_error) { 'unauthorized' }

      it 'fails without creating anything' do
        output, status = merge

        expect(status).not_to be_success
        expect(output).to include('unauthorized')
        expect(created).to eq([])
      end
    end
  end

  context 'when a required variable is missing' do
    let(:env) { super().merge('GITHUB_SHA' => '') }

    it 'fails' do
      _, status = merge

      expect(status).not_to be_success
      expect(created).to eq([])
    end
  end
end
