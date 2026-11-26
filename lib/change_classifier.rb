require 'yaml'

# Sorts a changed file into: rebuild one image, rebuild nothing, or rebuild all.
# The rules live in change_rules.yml. Anything they do not mention rebuilds
# everything, so drift in them only costs CI time.
class ChangeClassifier
  RULES_FILE = File.expand_path('../change_rules.yml', __dir__).freeze
  FNMATCH_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB

  def self.load(image_dirs:, path: RULES_FILE)
    rules = YAML.safe_load_file(path)

    new(image_dirs: image_dirs, build_all: rules.fetch('build_all'), ignore: rules.fetch('ignore'))
  end

  def initialize(image_dirs:, build_all:, ignore:)
    @image_dirs = image_dirs
    @build_all = build_all
    @ignore = ignore
  end

  def classify(path)
    dir = image_dir_for(path)
    return [:image, dir] if dir
    return [:all] if match?(@build_all, path)
    return [:ignore] if match?(@ignore, path)

    [:all]
  end

  # False when classify only answered :all because nothing matched
  def explicit?(path)
    !image_dir_for(path).nil? || match?(@build_all + @ignore, path)
  end

  private

  def match?(globs, path)
    globs.any? { |glob| File.fnmatch?(glob, path, FNMATCH_FLAGS) }
  end

  def image_dir_for(path)
    @image_dirs.find { |dir| path.start_with?("#{dir}/") }
  end
end
