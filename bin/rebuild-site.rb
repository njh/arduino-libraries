#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)


# Load the library data
libraries = JSON.parse(
  File.read('library_index.json'),
  {:symbolize_names => true}
)

# Load the ERB templates
Templates = {}
Dir.foreach('views') do |filename|
  if filename =~ /^(\w+).html.erb$/
    template_key = $1.to_sym
    Templates[template_key] = Tilt::ERBTemplate.new(
      "views/#{filename}",
      :escape_html => true
    )
  end
end

def render(filename, template, args={})
  filename = "public/#{filename}"
  dirname = File.dirname(filename)
  FileUtils.mkdir_p(dirname) unless Dir.exist?(dirname)

  File.open(filename, 'wb') do |file|
    file.write Templates[:layout].render(self, args) {
      Templates[template].render(self, args)
    }
  end
end


render(
  'index.html',
  :index,
  :title => "Library List",
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
