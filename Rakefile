#!/usr/bin/env ruby

file 'arduino_library_index.json' do |task|
  sh 'curl',
     '--fail',
     '--output', task.name,
     'http://downloads.arduino.cc/libraries/library_index.json'
end

file 'library_index.json' => 'arduino_library_index.json' do |task|
  ruby 'bin/rebuild-index.rb'
end

task :rebuild => ['library_index.json']

task :default => :rebuild

task :clean do
  File.delete('library_index.json')
end
