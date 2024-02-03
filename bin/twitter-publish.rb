#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)
require './lib/helpers'
require './lib/twitter_config'

# Length of a Twitter short URL
TWEET_MAX_LENGTH = 280
SHORT_URL_LENGTH = 23


# Load the library data
data = load_csv_data

# Get our recent tweets
first_lines = $twitter.user_timeline(
  'arduinolibs', :count => 50, :include_rts => false, :exclude_replies => true
).map {|tweet| tweet.text.split("\n").first}


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
    remaining = TWEET_MAX_LENGTH - lines.first.length - SHORT_URL_LENGTH - 4
    lines << "https://arduinolibraries.info/libraries/#{library[:key]}"
    if remaining < 1
      raise "Tweet is too long"
    elsif remaining > 20
      lines << remove_links(library[:sentence].strip)
      if lines[2].length > remaining
        # Trim third line if it is too long
        lines[2] = lines[2][0..remaining].sub(/\s*\w+$/, ' …')
      end
    end
    
    # Send tweet
    puts " => sending"
    $twitter.update(lines.join("\n"))
    sleep 1
  end
end
