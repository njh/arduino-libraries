#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)
require './lib/twitter_config'
require 'csv'

following = []
$twitter.friends(:count => 200, :skip_status => true).each do |friend|
  following << friend.screen_name.downcase
end

CSV.foreach('authors_extras.csv', :headers => true) do |row|
  screenname = row['Twitter']
  next unless screenname =~ /\w+/
  screenname.downcase!

  puts "Following: #{screenname}"
  if following.include?(screenname)
    puts " => Already following"
  else
  	user = $twitter.user(screenname)
  	if user.protected
      puts " => User protected"
    else
      result = $twitter.follow!(user)
      unless result.empty?
        puts " => Ok"
      end
    end
    sleep 1
  end

  puts
end
