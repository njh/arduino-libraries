#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/github'
Bundler.require(:default)



# Load the library data
data = JSON.parse(
  File.read('library_index_clean.json'),
  {:symbolize_names => true}
)

if File.exist?('github_users.json')
  Users = JSON.parse(
    File.read('github_users.json'),
    {:symbolize_names => true}
  )
else
  Users = {}
end


data[:authors].each_pair do |username,user|
  unless Users.has_key?(username.to_sym)
    puts "Fetching: #{username}"
    response = get_github("/users/#{username}")
    if response.is_a?(Hash) and response[:message].nil?
      unless response[:name].nil?
        response[:name].strip!
        response[:name] = nil if response[:name] == ''
      end
      Users[username] = response
      puts "  => OK"

      # Regularly write to disk, so we can re-start the script
      File.open('github_users.json', 'wb') do |file|
        file.write JSON.pretty_generate(Users)
      end
    else
      puts "  => #{response}"
      exit(-1)
    end
  end
end
