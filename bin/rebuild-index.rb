#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)
require './lib/helpers'


VersionSecificKeys = [
  :version, :url, :archiveFileName, :size, :checksum
]


# Load the library data
source_data = JSON.parse(
  File.read('arduino_library_index.json'),
  {:symbolize_names => true}
)

data = {
  :libraries => {},
  :types => {},
  :categories => {},
  :architectures => {},
  :authors => {}
}

# First collate the versions
source_data[:libraries].each do |entry|
  key = entry[:name].keyize
  entry[:types].map! {|t| t == 'Arduino' ? 'Official' : t }
  entry[:architectures].map! {|arch| arch.downcase }
  entry[:semver] = SemVer.parse(entry[:version])
  data[:libraries][key] ||= {}
  data[:libraries][key][:versions] ||= []
  data[:libraries][key][:versions] << entry
end

# Sort each library by the version number
data[:libraries].each_pair do |key, library|
  library[:versions] = library[:versions].
    sort_by {|item| item[:semver]}.
    reverse
end

# Then take the metadata for each library from the newest version
data[:libraries].each_pair do |key, library|
  # Copy over the non-specific version keys from the newest
  newest = library[:versions].first
  library[:version] = newest[:version]
  newest.keys.each do |key|
    unless VersionSecificKeys.include?(key)
      library[key] = newest[key]
    end
  end

  # Delete the non-specific version keys from each version
  library[:versions].each do |version|
    version.keys.each do |key|
      version.delete(key) unless VersionSecificKeys.include?(key)
    end
  end
end

# Create an index of types
data[:libraries].each_pair do |key, library|
  library[:types].each do |type|
    data[:types][type] ||= []
    data[:types][type] << key
  end
end

# Create an index of categories
data[:libraries].each_pair do |key, library|
  data[:categories][library[:category]] ||= []
  data[:categories][library[:category]] << key
end

# Create an index of architectures
data[:libraries].each_pair do |key, library|
  next if library[:architectures].nil?
  library[:architectures].each do |architecture|
    architecture = 'Any' if architecture == '*'
    next unless architecture =~ /^\w+$/
    data[:architectures][architecture] ||= []
    data[:architectures][architecture] << key
  end
end

# Create an index of the Authors
data[:libraries].each_pair do |key, library|
  names = []
  library[:author].split(/\s*,\s*/).each do |author|
    if author =~ /^(.+?)\s*(<.+>)?$/
      names << $1
    end
  end

  if library[:versions].first[:url] =~ %r|http://downloads.arduino.cc/libraries/([\w\-]+)/|
    library[:username] = username = $1.downcase
    data[:authors][username] ||= {}
    data[:authors][username][:names] ||= []
    names.each do |name|
      unless data[:authors][username][:names].include?(name)
        data[:authors][username][:names] << name
      end
    end
    data[:authors][username][:libraries] ||= []
    data[:authors][username][:libraries] << key
  end
end

# Finally, write to back to disk
File.open('library_index.json', 'wb') do |file|
  file.write JSON.pretty_generate(data)
end
