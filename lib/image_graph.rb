require_relative 'util'
require_relative 'tag_generator'

# Which image directories are built from which, read from the generated Dockerfiles.
class ImageGraph
  class UnknownReference < StandardError; end

  # Matches `FROM ref` and `from=ref` (COPY --from, RUN --mount) outside comments
  REFERENCE = /^\s*FROM\s+(?:--\S+\s+)*(\S+)|^(?!\s*#).*?\bfrom=([^\s,]+)/i

  def initialize(root: Util::PROJECT_DIR, manifest: Util::MANIFEST)
    @root = root
    @manifest = manifest
  end

  def with_dependents(dirs)
    found = dirs.to_set
    loop do
      added = parents.select { |dir, upstream| !found.include?(dir) && upstream.any? { |u| found.include?(u) } }
      return found.to_a if added.empty?

      found.merge(added.keys)
    end
  end

  private

  # { "ruby/3.1" => ["core/noble"], ... }
  def parents
    @parents ||= tags_by_dir.keys.to_h do |dir|
      [dir, registry_references(dir).map { |ref| resolve(ref, dir) }]
    end
  end

  def resolve(ref, dir)
    dir_by_tag.fetch(ref) { raise UnknownReference, "#{dir} references unknown image #{ref}" }
  end

  def registry_references(dir)
    File.read(File.join(@root, dir, 'Dockerfile'))
      .scan(REFERENCE)
      .map { |match| match.compact.first }
      .select { |ref| ref.start_with?("#{Util::REGISTRY}/") }
      .map { |ref| ref.split('/').last.include?(':') ? ref : "#{ref}:latest" }
  end

  def dir_by_tag
    @dir_by_tag ||= tags_by_dir.flat_map { |dir, tags| tags.map { |tag| [tag, dir] } }.to_h
  end

  def tags_by_dir
    @tags_by_dir ||= @manifest.flat_map do |image_name, details|
      details.fetch('versions').keys.map do |version|
        values = Util.version_values(image_name, version, manifest: @manifest)
        tags = TagGenerator.primary_tags(image_name, values) + TagGenerator.dev_tags(image_name, values)
        ["#{image_name}/#{version}", tags]
      end
    end.to_h
  end
end
