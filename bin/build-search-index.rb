#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
Bundler.require(:default)

# Load the library data
data = load_csv_data

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
