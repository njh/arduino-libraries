#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/github'
Bundler.require(:default)



# Load the library data
data = JSON.parse(
  File.read('library_index_clean.json'),
  {:symbolize_names => true}
)

if File.exist?('github_repos.json')
  Repos = JSON.parse(
    File.read('github_repos.json'),
    {:symbolize_names => true}
  )
else
  Repos = {}
end


data[:libraries].each_pair do |name,library|
  key = "#{library[:username]}/#{library[:reponame]}"
  unless Repos.has_key?(key.to_sym)
    puts "Fetching: #{name} => #{key}"
    response = get_github("/repos/#{key}")
    if response.is_a?(Hash) and response[:message].nil?
      Repos[key] = response
      puts "  => OK"
    else
      puts "  => #{response}"
      exit(-1)
    end

    # Regularly write to disk, so we can re-start the script
    File.open('github_repos.json', 'wb') do |file|
      file.write JSON.pretty_generate(Repos)
    end
  end
end
