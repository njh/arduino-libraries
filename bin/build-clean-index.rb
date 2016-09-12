#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)
require './lib/helpers'
require 'csv'


VersionSecificKeys = [
  :version, :url, :archiveFileName, :size, :checksum
]


# Load the library data
source_data = JSON.parse(
  File.read('library_index_raw.json'),
  {:symbolize_names => true}
)

# Load the overrides files - where the github repo name doesn't mark the library name
reponame_overrides = {}
username_overrides = {}
CSV.foreach('github_repos_overrides.csv', :headers => true) do |row|
  reponame_overrides[row['key']] = row['reponame']
  username_overrides[row['key']] = row['username']
end

data = {
  :libraries => {},
  :types => {},
  :categories => {},
  :architectures => {},
  :authors => {}
}

# First collate the versions
source_data[:libraries].each do |entry|
  entry[:key] = key = entry[:name].keyize
  entry[:types].map! {|t| t == 'Arduino' ? 'Official' : t }
  entry[:architectures].map! {|arch| arch.downcase }
  entry[:semver] = SemVer.parse(entry[:version])
  entry[:sentence] = strip_html(entry[:sentence])
  entry[:website].sub!(%r[https?://(www\.)?github\.com/], 'https://github.com/')
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

  # Work out the Github URL
  if newest[:url] =~ %r|http://downloads.arduino.cc/libraries/([\w\-]+)/([\w\-]+)-|i
    username, reponame = $1, $2

    # Check if an username override is set
    if username_overrides.has_key?(key)
      username = username_overrides[key]
    end

    # Check if an repo name override is set
    if reponame_overrides.has_key?(key)
      reponame = reponame_overrides[key]
    elsif library[:website] =~ %r|github\.com/#{username}/([\w\-]+)|i
      # If a website is given try using that if preference to download name
      reponame = $1
    end

    library[:username] = username.downcase
    library[:reponame] = reponame.downcase
    library[:github] = "https://github.com/#{username}/#{reponame}"
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
    if author =~ /^(.+?)\s*(<.+>)?/
      names << $1
    end
  end

  # Remove email addresses
  library[:author].gsub!(/\s*[\<\(].*[\>\)]\s*/, '')
  library[:maintainer].gsub!(/\s*[\<\(].*[\>\)]\s*/, '')

  username = library[:username]
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

# Finally, write to back to disk
File.open('library_index_clean.json', 'wb') do |file|
  file.write JSON.pretty_generate(data)
end
