require 'open3'
require 'json'

namespace :docker do
  desc 'pull all images from ghcr.io'
  task :pull do
    targets.each do |target|
      puts "Fetching tag: #{target}..."
      system("DOCKER_CLI_HINTS=false docker pull #{target}", exception: true)
      print "\n"
    end
  end

  desc 'rmi all images from ghcr.io'
  task :rmi do
    targets.each do |target|
      puts "Removing tag: #{target}..."
      system("DOCKER_CLI_HINTS=false docker rmi #{target}", exception: true)
      print "\n"
    end
  end
end

def targets
  Dir.glob('*/*/docker-bake.hcl').flat_map do |bake|
    stdout, _status = Open3.capture2("docker buildx bake --file #{bake} --print")
    JSON.parse(stdout).fetch('target').values.flat_map { |v| v.fetch('tags') }
  rescue JSON::ParserError, TypeError
    warn "[FATAL]: unable to parse bake output for file: #{bake}"
    warn "stdout was: #{stdout}"
    raise
  end
end
