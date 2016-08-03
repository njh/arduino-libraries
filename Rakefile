#!/usr/bin/env ruby

file 'arduino_library_index.json' do |task|
  sh 'curl',
     '--fail',
     '--output', task.name,
     'http://downloads.arduino.cc/libraries/library_index.json'
end

file 'library_index.json' => 'arduino_library_index.json' do |task|
  ruby 'bin/build-index.rb'
end

task :build => ['library_index.json'] do
  ruby 'bin/build-site.rb'
end

task :server => :build do
  require 'webrick'
  server = WEBrick::HTTPServer.new(
    :Port => 3000,
    :DocumentRoot => File.join(Dir.pwd, 'public')
  )
  trap('INT') { server.shutdown }
  server.start
end

task :upload => :build do
  sh 'rsync -avz --delete -e ssh public/ njh@www.arduinolibraries.info:/srv/www/arduino-libraries/'
end

task :default => :build

task :clean do
  File.foreach('.gitignore') do |line|
    # For safety
    next unless line =~ /^\w+/
    sh 'rm', '-Rf', line.strip
  end
end
