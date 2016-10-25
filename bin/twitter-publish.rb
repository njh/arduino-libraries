#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)
require './lib/helpers'
require './lib/twitter_config'


# Load the library data
data = JSON.parse(
  File.read('library_index_with_github.json'),
  {:symbolize_names => true}
)

# Get our recent tweets
first_lines = $twitter.user_timeline(
  'arduinolibs', :count => 50, :include_rts => false, :exclude_replies => true
).map {|tweet| tweet.text.split("\n").first}

# Get the amount of space a HTTP URL takes up
short_url_length = $twitter.configuration.short_url_length

libraries = library_sort(data[:libraries], :release_date, 25)
libraries.reverse.each do |library|
  author = data[:authors][library[:username].to_sym]
  mention = unless author[:twitter].nil?
    '@' + author[:twitter]
  else
    '#' + library[:username].gsub(/[^a-z0-9]/, '')
  end

  lines = ["#{library[:name]} (#{library[:version]}) for #arduino by #{mention}"]
  puts lines.first
  if first_lines.include?(lines.first)
    puts " => already tweeted"
  else
    remaining = 140 - lines.first.length - short_url_length - 4
    lines << "http://arduinolibraries.info/libraries/#{library[:key]}"
    if remaining < 1
      raise "Tweet is too long"
    elsif remaining > 20
      lines << library[:sentence].strip
      if lines[2].length > remaining
        # Trim third line if it is too long
        lines[2] = lines[2][0..remaining].sub(/\s*\w+$/, ' …')
      end
    end
    
    # Send tweet
    puts " => sending"
    $twitter.update(lines.join("\n"))
  end
end
