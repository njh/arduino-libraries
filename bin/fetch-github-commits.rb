#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/github'
Bundler.require(:default)



# Load the library data
data = JSON.parse(
  File.read('library_index_clean.json'),
  {:symbolize_names => true}
)

if File.exist?('github_commits.json')
  Commits = JSON.parse(
    File.read('github_commits.json'),
    {:symbolize_names => true}
  )
else
  Commits = {}
end

$tags = {}
def find_tag(username, reponame, version)
  key = [username, reponame].join('/')
  $tags[key] ||= get_github("/repos/#{username}/#{reponame}/tags").map {|tag| tag[:name]}
  $tags[key].each do |tag|
    majorminor = version.sub(/\.0$/, '')
    if tag =~ /^v?_?#{version}$/i
      return tag
    elsif tag =~ /^v_?#{majorminor}$/i
      return tag
    end
  end

  return nil
end


data[:libraries].each_pair do |name,library|
  library[:versions].each do |version|
    key = "#{library[:username]}/#{library[:reponame]}/#{version[:version]}"
    unless Commits.has_key?(key.to_sym)
      puts "Looking up: #{key}"

      tag = find_tag(library[:username], library[:reponame], version[:version])
      if tag.nil?
        puts "  => Failed to find tag for version"
        next
      end

      response = get_github("/repos/#{library[:username]}/#{library[:reponame]}/commits/#{tag}")
      if response.is_a?(Hash) and response[:message].nil?
        Commits[key] = response
        Commits[key][:tag] = tag
        puts "  => Ok"
      else
        puts "  => #{response}"
        exit(-1)
      end
    end
  end

  # Regularly write to disk, so we can re-start the script
  File.open('github_commits.json', 'wb') do |file|
    file.write JSON.pretty_generate(Commits)
  end
end
