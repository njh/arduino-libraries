#!/usr/bin/env ruby

desc "Download the Library Index JSON file from arduino.cc"
file 'library_index_raw.json' do |task|
  sh 'curl',
     '--fail',
     '--output', task.name,
     'http://downloads.arduino.cc/libraries/library_index.json'
end

desc "Create the clean index JSON file"
file 'library_index_clean.json' => 'library_index_raw.json' do |task|
  ruby 'bin/build-clean-index.rb'
end

desc "Download information about repos from Github"
file 'github_repos.json' => 'library_index_clean.json' do |task|
  ruby 'bin/fetch-github-repos.rb'
end

desc "Download information about version tags from Github"
file 'github_commits.json' => 'library_index_clean.json' do |task|
  ruby 'bin/fetch-github-commits.rb'
end

desc "Create the index JSON file with added Github info"
file 'library_index_with_github.json' => ['library_index_clean.json', 'github_repos.json', 'github_commits.json'] do |task|
  ruby 'bin/build-index-with-github.rb'
end

desc "Create Linked Data files"
task :build_linkeddata => ['schema_org_context.json', 'library_index_with_github.json'] do
  ruby 'bin/build-linkeddata.rb'
end

desc "Download JSON context file from schema.org"
file 'schema_org_context.json' do |task|
  sh 'curl',
     '--fail',
     '--location',
     '--output', task.name,
     '--header', 'Accept: application/ld+json',
     'http://schema.org/'
end

desc "Create HTML files"
task :build_site => ['library_index_with_github.json'] do
  ruby 'bin/build-site.rb'
end

desc "Create sitemap file"
file 'public/sitemap.xml' => ['library_index_with_github.json'] do
  ruby 'bin/build-sitemap.rb'
end

desc "Create RSS Feed file"
file 'public/feed.xml' => ['library_index_with_github.json'] do
  ruby 'bin/build-rss-feed.rb'
end

desc "Generate all the required files in public"
task :build => [:build_linkeddata, :build_site, 'public/feed.xml', 'public/sitemap.xml']

desc "Run a local web server on port 3000"
task :server => :build do
  require 'webrick'
  server = WEBrick::HTTPServer.new(
    :Port => 3000,
    :DocumentRoot => File.join(Dir.pwd, 'public')
  )
  trap('INT') { server.shutdown }
  server.start
end

desc "Upload the files in public/ to the live web server"
task :upload => :build do
  sh 'rsync -avz --delete -e ssh public/ njh@www.arduinolibraries.info:/srv/www/arduino-libraries/'
end

task :default => :build

desc "Deleted all the generated files (based on .gitignore)"
task :clean do
  File.foreach('.gitignore') do |line|
    # For safety
    next unless line =~ /^\w+/
    sh 'rm', '-Rf', line.strip
  end
end
