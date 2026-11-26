require 'open3'
require_relative 'change_classifier'
require_relative 'image_graph'

# Which image directories a CI run has to build (Strategy: All or Changed).
# Every doubt resolves to All.
module BuildScope
  # Events whose changes can be measured against a base commit
  DIFFABLE_EVENTS = %w[pull_request push].freeze
  COMMIT_SHA = /\A\h{40}\z/
  NO_COMMIT = ('0' * 40).freeze

  class All
    def include?(_dir)
      true
    end
  end

  class Changed
    def initialize(dirs)
      @dirs = dirs
    end

    def include?(dir)
      @dirs.include?(dir)
    end
  end

  # Paths changed since a base commit, or nil when git cannot tell
  class GitDiff
    def initialize(root:)
      @root = root
    end

    def call(base)
      # --no-renames lists the old path too, so the directory a file left is rebuilt
      out, status = Open3.capture2('git', '-C', @root, 'diff', '--name-only', '--no-renames', base, 'HEAD')
      out.split("\n") if status.success?
    end
  end

  class << self
    def for(event:, base:, classifier:, graph:, diff:)
      return all("event #{event.inspect}") unless DIFFABLE_EVENTS.include?(event)
      return all("no usable base commit #{base.inspect}") unless usable?(base)

      paths = diff.call(base)
      return all("git diff against #{base} failed") unless paths

      changed(paths, classifier, graph)
    end

    private

    def usable?(base)
      COMMIT_SHA.match?(base.to_s) && base != NO_COMMIT
    end

    def changed(paths, classifier, graph)
      verdicts = paths.to_h { |path| [path, classifier.classify(path)] }
      culprit = verdicts.key([:all])
      return all("#{culprit} changed") if culprit

      only(graph.with_dependents(image_dirs(verdicts)))
    rescue ImageGraph::UnknownReference => e
      all(e.message)
    end

    def image_dirs(verdicts)
      verdicts.values.filter_map { |kind, dir| dir if kind == :image }.uniq
    end

    def only(dirs)
      warn "Building changed images: #{dirs.empty? ? 'none' : dirs.sort.join(' ')}"
      Changed.new(dirs)
    end

    def all(reason)
      warn "Building all images: #{reason}"
      All.new
    end
  end
end
