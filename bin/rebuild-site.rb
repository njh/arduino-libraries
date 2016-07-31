#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
Bundler.require(:default)


# Load the library data
data = JSON.parse(
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


@count = data[:libraries].keys.count
@types = data[:types]
@categories = data[:categories]
@architectures = data[:architectures]

render(
  'index.html',
  :index,
  :title => "The catalogue of Arduino Libraries",
  :categories => data[:categories]
)

render(
  'libraries/index.html',
  :list,
  :title => 'All Libraries',
  :synopsis => "A list of the <i>#{@count}</i> "+
               "libraries registered in the Arduino Library Manager.",
  :keys => data[:libraries].keys,
  :libraries => data[:libraries]
)

data[:types].each_pair do |type,libraries|
  render(
    "types/#{type.to_s.keyize}/index.html",
    :list,
    :title => type,
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries of the type #{type}.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

data[:categories].each_pair do |category,libraries|
  render(
    "categories/#{category.to_s.keyize}/index.html",
    :list,
    :title => category,
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries in the category #{category}.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

data[:architectures].each_pair do |architecture,libraries|
  render(
    "architectures/#{architecture.to_s.keyize}/index.html",
    :list,
    :title => architecture.capitalize,
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries in the architecture #{architecture}.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

data[:libraries].each_pair do |key,library|
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
