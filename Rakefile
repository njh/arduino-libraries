#!/usr/bin/env ruby


def download(filename, url, accept=nil)
  args = [
    '--fail',
    '--silent',
    '--location',
    '--show-error',
    '--output', filename,
  ]
  args += ['--header', "Accept: #{accept}"] unless accept.nil?
  args << url
  sh 'curl', *args
end

desc "Download the Library Index JSON file from arduino.cc"
file 'library_index_raw.json' do |task|
  download(task.name, 'https://downloads.arduino.cc/libraries/library_index.json')
end

desc "Download extra information about authors"
file 'authors_extras.csv' do |task|
  download(task.name, 'https://docs.google.com/spreadsheets/d/1ARqkeEmVVApylSDVZ6s_97-YtvlklE8k05F2EOlO0MY/pub?gid=465469161&single=true&output=csv')
end

desc "Download extra information about repositories"
file 'repos_extras.csv' do |task|
  download(task.name, 'https://docs.google.com/spreadsheets/d/1ARqkeEmVVApylSDVZ6s_97-YtvlklE8k05F2EOlO0MY/pub?gid=278607893&single=true&output=csv')
end

namespace :twitter do
  desc "Follow everyone listed in the authors file"
  task :follow => 'authors_extras.csv' do
    ruby 'bin/twitter-follow.rb'
  end

  desc "Publish tweets about latest releases"
  task :publish => ['library_index_with_github.json'] do
    ruby 'bin/twitter-publish.rb'
  end
end

desc "Create the clean index JSON file"
file 'library_index_clean.json' => ['library_index_raw.json', 'authors_extras.csv', 'repos_extras.csv', 'spdx_licences.json'] do |task|
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

desc "Download information about users from Github"
file 'github_users.json' => 'library_index_clean.json' do |task|
  ruby 'bin/fetch-github-users.rb'
end

desc "Create the index JSON file with added Github info"
file 'library_index_with_github.json' => ['library_index_clean.json', 'github_repos.json', 'github_commits.json', 'github_users.json'] do |task|
  ruby 'bin/build-index-with-github.rb'
end

desc "Create Linked Data files"
task :build_linkeddata => ['schema_org_context.json', 'library_index_with_github.json'] do
  ruby 'bin/build-linkeddata.rb'
end

desc "Download JSON context file from schema.org"
file 'schema_org_context.json' do |task|
  download(
    task.name,
    'http://schema.org/',
    'application/ld+json'
  )
end

desc "Download SPDX license data"
file 'spdx_licences.json' do |task|
  download(
    task.name,
    'https://raw.githubusercontent.com/spdx/license-list-data/master/json/licenses.json'
  )
end

desc "Create HTML files"
task :build_site => ['library_index_with_github.json'] do
  ruby 'bin/build-site.rb'
end

desc "Create Aritecture Variants file"
file 'public/architecture-variants.html' => ['library_index_with_github.json'] do
  ruby 'bin/build-architecture-variants.rb'
end

desc "Create RSS Feed file"
file 'public/feed.xml' => ['library_index_with_github.json'] do
  ruby 'bin/build-rss-feed.rb'
end

desc "Create search index JSON file"
file 'public/search-index.json' => ['library_index_with_github.json'] do
  ruby 'bin/build-search-index.rb'
end

desc "Create sitemap file"
file 'public/sitemap.xml' => ['library_index_with_github.json'] do
  ruby 'bin/build-sitemap.rb'
end

desc "Generate all the required files in public"
task :build => [:build_linkeddata, :build_site, 'public/architecture-variants.html', 'public/feed.xml', 'public/search-index.json', 'public/sitemap.xml']

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

desc "Upload the files in public/ to S3"
task :upload => :build do
  sh 'rsync -avz --delete -e "ssh -p 5104" public/ arduino-libs@ssh.skypi.hostedpi.com:/srv/www/arduino-libraries/'
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
