#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)


# Load the library data
libraries = JSON.parse(
  File.read('library_index.json'),
  {:symbolize_names => true}
)

# Load the ERB templates
templates = {}
Dir.foreach('views') do |filename|
  if filename =~ /^(\w+).html.erb$/
    template_key = $1.to_sym
    template_data = File.read("views/#{filename}")
    templates[template_key] = Erubis::EscapedEruby.new(template_data)
  end
end

File.open("public/index.html", 'wb') do |file|
  file.write templates[:index].result(:libraries => libraries)
end

libraries.each_pair do |key,library|
  dir = "public/libraries/#{key}"
  FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
  File.open("#{dir}/index.html", 'wb') do |file|
    file.write templates[:show].result(:library => library)
  end
end
