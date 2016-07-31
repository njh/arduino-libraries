#!/usr/bin/env ruby

require 'json'
require 'semverly'

class String
  def keyize
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1-\2').
    gsub(/([a-z\d])([A-Z])/,'\1-\2').
    gsub(/\s+/,'-').
    downcase
  end
end

VersionSecificKeys = [
  'version', 'url', 'archiveFileName', 'size', 'checksum'
]


# Load the library data
library_data = JSON.parse(
  File.read('arduino_library_index.json')
)

# First collate the versions
libraries = {}
library_data['libraries'].each do |entry|
  key = entry['name'].keyize
  entry['semver'] = SemVer.parse(entry['version'])
  libraries[key] ||= {}
  libraries[key]['versions'] ||= []
  libraries[key]['versions'] << entry
end

# Sort each library by the version number
libraries.each_pair do |key, library|
  library['versions'] = library['versions'].
    sort_by {|item| item['semver']}.
    reverse
end

# The take the metadata from the newest version
libraries.each_pair do |key, library|
  # Copy over the non-specific version keys from the newest
  newest = library['versions'].first
  library['version'] = newest['version']
  newest.keys.each do |key|
    unless VersionSecificKeys.include?(key)
      library[key] = newest[key]
    end
  end

  # Delete the non-specific version keys from each version
  library['versions'].each do |version|
    version.keys.each do |key|
      version.delete(key) unless VersionSecificKeys.include?(key)
    end
  end
end

# Finally, write to back to disk
File.open('library_index.json', 'wb') do |file|
  file.write JSON.pretty_generate(libraries)
end
