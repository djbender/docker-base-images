# Commit SHA tags, mixed into TagGenerator
module ShaTags
  # Where to re-tag an unchanged image from, best first: the base commit's SHA
  # tag never moves, the published version tag can
  def primary_source_tags(image_name, values, base_sha)
    source_tags(image_name, symbolize_keys(values)[:version], base_sha)
  end

  def dev_source_tags(image_name, values, base_sha)
    source_tags(image_name, "#{symbolize_keys(values)[:version]}-dev", base_sha)
  end

  private

  def source_tags(image_name, version, base_sha)
    base = "#{TagGenerator::REGISTRY}/#{image_name}"

    [sha_tag(base, version, base_sha), "#{base}:#{version}"]
  end

  # Written once per commit, never moved
  def sha_tag(base, version, sha)
    "#{base}:#{version}-#{sha}"
  end
end
