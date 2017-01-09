#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)

# Load the library data
data = JSON.parse(
  File.read('library_index_with_github.json'),
  {:symbolize_names => true}
)

# Extract the fields we want in the search index
index = data[:libraries].values.map do |library|
  {
    :key => library[:key],
    :name => library[:name],
    :sentence => library[:sentence]
  }
end

File.open('public/search-index.json', 'wb') do |file|
  file.write index.to_json
end
