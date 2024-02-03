#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
Bundler.require(:default)

# Load the library data
data = load_csv_data


libraries = library_sort(data[:libraries], :release_date, 50)

template = Tilt::ErubisTemplate.new("views/feed.xml.erb", :escape_html => true)
  
File.open('public/feed.xml', 'wb') do |file|
  file.puts template.render(self,
    :libraries => libraries,
    :self_url => "https://www.arduinolibraries.info/feed.xml",
    :pub_date => Time.now.iso8601.to_s
  )
end
