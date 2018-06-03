#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
require './lib/render'
Bundler.require(:default)

# Load the library data
data = JSON.parse(
  File.read('library_index_with_github.json'),
  {:symbolize_names => true}
)


architectures = {}

data[:libraries].each_pair do |key, library|
  next if library[:architectures].nil?
  library[:architectures].each do |architecture|
    if architecture =~ /^\w+$/
      architectures[architecture] ||= []
      architectures[architecture] << key
    end
  end
end


render(
  "architecture-variants.html",
  :architecture_variants,
  :title => "List of library architecture variants",
  :architectures => architectures,
  :libraries => data[:libraries]
)
