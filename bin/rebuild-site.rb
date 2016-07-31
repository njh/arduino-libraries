#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
Bundler.require(:default)


# Load the library data
libraries = JSON.parse(
  File.read('library_index.json'),
  {:symbolize_names => true}
)

# Load the ERB templates
Templates = {}
Dir.foreach('views') do |filename|
  if filename =~ /^(\w+)\.(\w+)\.erb$/
    template_key = $1.to_sym
    Templates[template_key] = Tilt::ErubisTemplate.new(
      "views/#{filename}",
      :escape_html => true
    )
  end
end

Filenames = []
def render(filename, template, args={})
  publicpath = "public/#{filename}"
  dirname = File.dirname(publicpath)
  FileUtils.mkdir_p(dirname) unless Dir.exist?(dirname)

  File.open(publicpath, 'wb') do |file|
    file.write Templates[:layout].render(self, args) {
      Templates[template].render(self, args)
    }
  end
  
  Filenames << filename
end


render(
  'index.html',
  :index,
  :title => 'All Libraries',
  :libraries => libraries
)

libraries.each_pair do |key,library|
  render(
    "libraries/#{key}/index.html",
    :show,
    :title => library[:name],
    :library => library
  )
end

File.open('public/sitemap.xml', 'wb') do |file|
  builder = Nokogiri::XML::Builder.new
  builder.urlset(
    'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
    'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
    'xsi:schemaLocation' => 'http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd'
  ) {
    Filenames.each do |filename|
      builder.url do
        url = "http://www.arduinolibraries.info/#{filename}"
        url.sub!(%r|/index.html$|, '')
        builder.loc(url)
      end
    end
  }

  file.write builder.to_xml
end
