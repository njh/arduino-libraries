#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)
require './lib/helpers'

COPY_REPO_PROPERTIES = [
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

github_users = JSON.parse(
  File.read('github_users.json'),
  {:symbolize_names => true}
)

github_commits = JSON.parse(
  File.read('github_commits.json'),
  {:symbolize_names => true}
)

data[:libraries].each_pair do |key,library|
  github_key = "#{library[:username]}/#{library[:reponame]}"
  github = github_repos[github_key.to_sym]
  unless github.nil?
    COPY_REPO_PROPERTIES.each do |prop|
      library[prop] = github[prop]
    end
    unless github[:license].nil?
      library[:license] ||= github[:license][:spdx_id]
    end
  end

  library[:versions].each do |version|
    github_version_key = "#{github_key}/#{version[:version]}"
    github = github_commits[github_version_key.to_sym]
    unless github.nil?
      version[:github] = "#{library[:github]}/commits/#{github[:tag]}"
      version[:git_sha] = github[:sha]
      version[:release_date] = github[:commit][:committer][:date]
    end
  end
  
  if library[:versions].first[:release_date]
    library[:release_date] = library[:versions].first[:release_date]
  end
end

data[:authors].each_pair do |username,author|
  github = github_users[username.to_sym]
  unless github.nil?
    if !github[:name].nil? and github[:name] != username
      author[:name] = github[:name]
    end
    author[:homepage] = fix_url(github[:blog]) unless github[:blog].nil?
    author[:location] = github[:location]
    author[:company] = github[:company]
    if github[:twitter_username]
      if author[:twitter] and author[:twitter] != github[:twitter_username]
        $stderr.puts "Warning: differing twitter accounts"
        $stderr.puts "   Author extras: #{author[:twitter]}"
        $stderr.puts "   Github: #{github[:twitter_username]}"
      else
        author[:twitter] = github[:twitter_username]
      end
    end
  end
end

# Create an index of licenses
data[:licenses] = {}
data[:libraries].each_pair do |key, library|
  next unless library[:license] =~ /^[\w\-\.]+$/
  license = library[:license]
  data[:licenses][license] ||= []
  data[:licenses][license] << key
end


# Finally, write to back to disk
File.open('library_index_with_github.json', 'wb') do |file|
  file.write JSON.pretty_generate(data)
end
