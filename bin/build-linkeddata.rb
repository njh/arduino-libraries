#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
Bundler.require(:default)


# Load the library data
data = JSON.parse(
  File.read('library_index.json'),
  {:symbolize_names => true}
)


data[:libraries].each_pair do |key,library|
  newest = library[:versions].first

  jsonld = {
      '@context' => 'http://schema.org/',
      '@type' => 'SoftwareApplication',
      'name' => library[:name],
      'description' => library[:sentence],
      'url' => library[:website],
      'author' => {
        '@type' => 'Person',
        :name => library[:author],
      },
      'applicationCategory' => library[:category],
      'operatingSystem' => 'Arduino',
      'downloadUrl' => newest[:url],
      'softwareVersion' => newest[:version],
      'fileSize' => newest[:size].to_i / 1024,
  }

  File.open("public/libraries/#{key}.json", 'wb') do |file|
    file.write JSON.pretty_generate(jsonld)
  end
end
