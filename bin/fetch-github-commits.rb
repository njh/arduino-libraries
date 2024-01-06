#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/github'
Bundler.require(:default)



# Load the library data
data = JSON.parse(
  File.read('library_index_clean.json'),
  {:symbolize_names => true}
)

Commits = {}
if File.exist?('github_commits.json') and !File.zero?('github_commits.json')
  begin
    Commits = JSON.parse(
      File.read('github_commits.json'),
      {:symbolize_names => true}
    )
  rescue JSON::ParserError => exp
    puts "Failed to parse existing commits file: #{exp}"
    Commits = {}
  end
end

$tags = {}
def find_tag(username, reponame, version)
  key = [username, reponame].join('/')
  if $tags[key].nil?
    result = get_github("/repos/#{username}/#{reponame}/tags")
    if result.include?(:message)
      raise result[:message]
    end
    $tags[key] = result.map {|tag| tag[:name]}
  end
  $tags[key].each do |tag|
    majorminor = version.sub(/\.0$/, '')
    if tag =~ /^v?_?#{version}$/i
      return tag
    elsif tag =~ /^v?_?#{majorminor}$/i
      return tag
    end
  end

  return nil
end

do_write = false
data[:libraries].each_pair do |name,library|
  library[:versions].each do |version|
    key = "#{library[:username]}/#{library[:reponame]}/#{version[:version]}"
    unless Commits.has_key?(key.to_sym)
      puts "Looking up #{name}: #{key}"

      tag = find_tag(library[:username], library[:reponame], version[:version])
      if tag.nil?
        puts "  => Failed to find tag for version"
        Commits[key] = nil
        do_write = true
        next
      end

      response = get_github("/repos/#{library[:username]}/#{library[:reponame]}/commits/#{tag}")
      if response.is_a?(Hash) and response[:message].nil?
        Commits[key] = response
        Commits[key][:tag] = tag
        do_write = true
        puts "  => Ok"
      else
        puts "  => #{response}"
        exit(-1)
      end
    end

    # Regularly write to disk, so we can re-start the script
    if do_write
      File.open('github_commits.json', 'wb') do |file|
        file.write JSON.pretty_generate(Commits)
      end
      do_write = false
    end
  end

end
