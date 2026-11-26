# Sorts a changed file into: rebuild one image, rebuild nothing, or rebuild all.
# Anything no rule knows about rebuilds everything, so list drift only costs CI time.
class ChangeClassifier
  # Files that cannot change what any image contains. Templates and the manifest
  # are safe here because CI fails unless the generated image dirs match them.
  IGNORE_GLOBS = %w[
    **/*.md
    LICENSE
    {site,spec,bin,config}/**/*
    */template/**/*
    manifest.yml
    .generated.yml
    ruby/examples/**/*
    .github/dependabot.yml
    .github/template/**/*
    .github/workflows/{cleanup-packages,deploy-docs}.yml
    .gitignore
    .rspec
    .rubocop.yml
    .overcommit.sample.yml
    .ruby-version
    Parkfile
    Gemfile
    Gemfile.lock
  ].freeze

  # Files that decide how every image is built. Checked before IGNORE_GLOBS.
  BUILD_ALL_GLOBS = %w[
    .github/workflows/build-images.yml
    .github/workflows/actions.lock
    {lib,rakelib}/**/*
    Rakefile
  ].freeze

  FNMATCH_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB

  def initialize(image_dirs:)
    @image_dirs = image_dirs
  end

  def classify(path)
    dir = image_dir_for(path)
    return [:image, dir] if dir
    return [:all] if match?(BUILD_ALL_GLOBS, path)
    return [:ignore] if match?(IGNORE_GLOBS, path)

    [:all]
  end

  # False when classify only answered :all because nothing matched
  def explicit?(path)
    !image_dir_for(path).nil? || match?(BUILD_ALL_GLOBS + IGNORE_GLOBS, path)
  end

  private

  def match?(globs, path)
    globs.any? { |glob| File.fnmatch?(glob, path, FNMATCH_FLAGS) }
  end

  def image_dir_for(path)
    @image_dirs.find { |dir| path.start_with?("#{dir}/") }
  end
end
