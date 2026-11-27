require_relative 'util'
require_relative 'tag_generator'

# One merge matrix entry per image version (Strategy: Built or Retagged)
module MergeEntry
  # A freshly built image gets every tag, merged from its per-arch images
  class Built
    def initialize(image_name, version, sha:)
      @image_name = image_name
      @version = version
      @values = Util.version_values(image_name, version)
      @sha = sha
    end

    def to_h
      {
        version: @version,
        primary_target: @image_name,
        registry: Util::REGISTRY,
        primary_tags: tags(:primary_tags).join(' '),
        dev_tags: tags(:dev_tags).join(' ')
      }
    end

    private

    def tags(kind)
      TagGenerator.public_send(kind, @image_name, @values.merge('github_sha' => @sha))
    end
  end

  # An unchanged image only gets this commit's SHA tags, copied from a published image
  class Retagged < Built
    def initialize(image_name, version, sha:, base:)
      super(image_name, version, sha:)
      @base = base
    end

    def to_h
      super.merge(
        primary_sources: TagGenerator.primary_source_tags(@image_name, @values, @base).join(' '),
        dev_sources: TagGenerator.dev_source_tags(@image_name, @values, @base).join(' ')
      )
    end

    private

    # What the SHA adds; version, major and latest tags must not move
    def tags(kind)
      super - TagGenerator.public_send(kind, @image_name, @values)
    end
  end
end
