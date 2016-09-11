#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
Bundler.require(:default)

# Load the library data
data = JSON.parse(
  File.read('library_index_with_github.json'),
  {:symbolize_names => true}
)

libraries = library_sort(data[:libraries], :release_date, 50)

template = Tilt::ErubisTemplate.new("views/feed.xml.erb")
  
File.open('public/feed.xml', 'wb') do |file|
  file.puts template.render(self,
    :libraries => libraries,
    :self_url => "http://www.arduinolibraries.info/feed.xml",
    :pub_date => Time.now.iso8601.to_s
  )
end
