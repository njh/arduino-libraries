#!/usr/bin/env ruby

require 'bundler/setup'
require 'rss'
require './lib/helpers'
Bundler.require(:default)

# Load the library data
data = JSON.parse(
  File.read('library_index_with_github.json'),
  {:symbolize_names => true}
)

libraries = library_sort(data[:libraries], :release_date, 50)

rss = RSS::Maker.make("atom") do |maker|
  maker.channel.updated = Time.now.to_s
  maker.channel.about = "http://www.arduinolibraries.info/feed.xml"
  maker.channel.title = "Latest Arduino Library Releases"
  maker.channel.author = "Nicholas Humfrey"

  libraries.each do |library|
    maker.items.new_item do |item|
      item.link = "http://www.arduinolibraries.info/libraries/#{library[:key]}"
      item.title = "#{library[:name]} v#{library[:version]} released"
      item.updated = Time.parse(library[:release_date])
    end
  end
end

File.open('public/feed.xml', 'wb') do |file|
  file.puts rss
end
