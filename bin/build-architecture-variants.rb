#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
require './lib/render'
Bundler.require(:default)

# Load the library data
data = load_csv_data


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
  :sorted_architectures => architectures.keys.sort { |a,b|
    architectures[b].count <=> architectures[a].count
  },
  :libraries => data[:libraries]
)
