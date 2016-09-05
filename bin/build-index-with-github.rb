#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)
require './lib/helpers'

COPY_PROPERTIES = [
  :stargazers_count,
  :watchers_count,
  :forks
]

# Load the library data
data = JSON.parse(
  File.read('library_index_clean.json'),
  {:symbolize_names => true}
)

github_repos = JSON.parse(
  File.read('github_repos.json'),
  {:symbolize_names => true}
)

data[:libraries].each_pair do |key,library|
  github_key = "#{library[:username]}/#{library[:reponame]}".to_sym
  github = github_repos[github_key]
  unless github.nil?
    COPY_PROPERTIES.each do |prop|
      library[prop] = github[prop]
    end
  end
end

# Finally, write to back to disk
File.open('library_index_with_github.json', 'wb') do |file|
  file.write JSON.pretty_generate(data)
end
