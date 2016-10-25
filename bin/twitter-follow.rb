#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)
require './lib/twitter_config'
require 'csv'

CSV.foreach('authors_extras.csv', :headers => true) do |row|
  next unless row['Twitter'] =~ /\w+/
  
  puts "Following: #{row['Twitter']}"
  result = $twitter.follow!(row['Twitter'])
  unless result.empty?
    puts " => Ok"
  end
end
