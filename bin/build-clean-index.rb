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
CSV.foreach('repos_extras.csv', :headers => true) do |row|
  reponame_overrides[row['key']] = row['reponame']
  username_overrides[row['key']] = row['username']
end

author_extras = {}
CSV.foreach('authors_extras.csv', :headers => true) do |row|
  username = row['Username'].downcase
  author_extras[username] ||= {}
  row.to_hash.each_pair do |key,value|
    author_extras[username][key.downcase.to_sym] = value
  end
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
  key = entry[:name].keyize
  next if key.nil? or key.empty?

  entry[:key] = key
  entry[:types].map! {|t| t == 'Arduino' ? 'Official' : t }
  entry[:architectures].map! {|arch| arch.downcase }
  entry[:semver] = SemVer.parse(entry[:version])
  entry[:sentence] = strip_html(entry[:sentence])
  entry[:website] = fix_url(entry[:website])
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
    elsif library[:website] =~ %r|github\.com/#{username}/([\w\-\.]+)|i
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

EMAIL_REGEXP = Regexp.new('\s*<.*>\s*')

# Create an index of the Authors
data[:libraries].each_pair do |key, library|
  # Remove email addresses
  library[:author].gsub!(EMAIL_REGEXP, '')
  library[:maintainer].gsub!(EMAIL_REGEXP, '')

  username = library[:username]
  extras = author_extras[username]
  raise "Author not found in extras file: #{username}" if extras.nil?
  
  data[:authors][username] ||= {}
  data[:authors][username][:name] = library[:author]
  data[:authors][username][:github] = "https://github.com/#{username}"
  data[:authors][username][:twitter] = extras[:twitter]
  data[:authors][username][:homepage] = fix_url(extras[:homepage])
  data[:authors][username][:libraries] ||= []
  data[:authors][username][:libraries] << key
end

# Finally, write to back to disk
File.open('library_index_clean.json', 'wb') do |file|
  file.write JSON.pretty_generate(data)
end
