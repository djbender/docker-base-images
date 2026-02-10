# Centralized cache reference string builder for Docker buildx
module CacheRef
  def self.from(registry, tag)
    "type=registry,ref=#{registry}:cache-#{tag}"
  end

  def self.to(registry, tag)
    "#{from(registry, tag)},mode=max"
  end

  # Fallback cache source using the image tag directly (no cache- prefix)
  def self.fallback(registry, tag)
    "type=registry,ref=#{registry}:#{tag}"
  end
end
