# lib/util has shared constants and methods used in rake tasks
require_relative '../lib/util'

namespace :build do
  desc 'Build core images'
  task :core do
    core_filter = proc { |image_name| image_name == 'core' }

    Build.matrix(&core_filter).each { |bake_file| Build.run(bake_file) }
  end

  desc 'Build common images'
  task :common do
    core_filter = proc { |image_name| image_name != 'core' }

    Build.matrix(&core_filter).each { |bake_file| Build.run(bake_file) }
  end

  desc 'Build ruby images'
  task :ruby do
    core_filter = proc { |image_name| image_name == 'ruby' }

    Build.matrix(&core_filter).each { |bake_file| Build.run(bake_file) }
  end

  desc 'Build node images'
  task :node do
    core_filter = proc { |image_name| image_name == 'node' }

    Build.matrix(&core_filter).each { |bake_file| Build.run(bake_file) }
  end

  desc 'Build all images'
  task all: Rake.application.tasks.select { |t| t.name.start_with?('build') }.map(&:name)
end

module Build
  def self.arch
    ENV.fetch('ARCH') { RUBY_PLATFORM.include?('arm') ? 'arm64' : 'amd64' }
  end

  def self.run(bake_file)
    cmd = command(bake_file)
    puts "$ #{cmd.join(' ')}"
    system(*cmd, exception: true)
  end

  def self.command(bake_file)
    ENV['ARCH'] = arch
    %W[docker buildx bake --file #{bake_file} --set *.platform=linux/#{arch} --load]
  end

  def self.matrix(&)
    Util::MANIFEST.select(&).flat_map do |image_name, details|
      details.fetch('versions').keys.flat_map do |version|
        ["#{image_name}/#{version}/#{Util::BAKE_FILE}"]
      end
    end
  end
end
