require 'sinatra'
require 'kramdown'
require 'kramdown-parser-gfm'
require_relative 'site_manifest'

set :views, File.join(__dir__, 'views')
set :public_folder, File.join(__dir__, 'public')

helpers do
  def manifest
    SiteManifest
  end

  def registry
    SiteManifest.registry
  end

  def primary_tags(version)
    version.primary_tags
  end

  def dev_tags(version)
    version.dev_tags
  end

  def pull_command(image_name, tag = nil)
    img = "#{registry}/#{image_name}"
    img += ":#{tag}" if tag
    "docker pull #{img}"
  end

  def render_markdown(text)
    Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: nil).to_html
  end

  def active_class(path)
    request.path_info == path ? 'active' : ''
  end
end

get '/' do
  @title = 'Docker Base Images'
  @image_types = SiteManifest.image_types
  erb :home
end

get '/catalog' do
  @title = 'Image Catalog'
  @image_types = SiteManifest.image_types
  erb :catalog
end

%w[core ruby node].each do |type|
  get "/#{type}" do
    @title = type.capitalize
    @image_type = SiteManifest.image_type(type)
    erb :image_type
  end
end

get '/getting-started' do
  @title = 'Getting Started'
  erb :getting_started
end

get '/development' do
  @title = 'Development'
  erb :development
end

get '/changelog' do
  @title = 'Changelog'
  changelog_path = File.expand_path('../CHANGELOG.md', __dir__)
  @changelog_html = render_markdown(File.read(changelog_path))
  erb :changelog
end

get '/architecture' do
  @title = 'Architecture'
  erb :architecture
end
