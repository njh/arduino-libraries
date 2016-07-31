#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)


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
  :categories => {}
}

# First collate the versions
source_data[:libraries].each do |entry|
  key = entry[:name].keyize
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

# Finally, write to back to disk
File.open('library_index.json', 'wb') do |file|
  file.write JSON.pretty_generate(data)
end
