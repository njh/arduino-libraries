#!/usr/bin/env ruby

require 'bundler/setup'
require 'find'
Bundler.require(:default)


MIME_TYPE_MAP = {
  :css => 'text/css',
  :csv => 'text/csv',
  :html => 'text/html',
  :ico => 'image/x-icon',
  :js => 'text/javascript',
  :json => 'application/json',
  :png => 'image/png',
  :ttl => 'text/turtle',
  :txt => 'text/plain',
  :xml => 'application/xml',
  :xslt => 'application/xml',
}

CACHE_CONTROL = 'public,max-age=3600'




# First create a list of files
filelist = {}
Find.find('public/') do |localpath|
  next unless FileTest.file?(localpath)
  next if File.basename(localpath).match(/^\./)
  
  remotepath = localpath.sub(%r|^public/|, '')
  unless remotepath == 'index.html'
    # Remove index.html from path for S3 bucket
    remotepath.sub!(%r|/index.html$|, '')
  end

  filelist[localpath] = remotepath
end

puts "Uploading: #{filelist.keys.count} files"



client = Aws::S3::Client.new(:region => 'eu-west-1')
bucket = Aws::S3::Bucket.new(
  'origin.arduinolibraries.info',
  :client => client
)

raise "Error: S3 bucket does not exist" unless bucket.exists?


# Upload each of the files
filelist.each_pair do |localpath,remotepath|
  suffix = File.extname(localpath)[1..-1].downcase.to_sym || :html
  puts "  => Uploading '#{localpath}' to '#{remotepath}' (#{suffix})"

  # Work out the MIME type for the file
  mime_type = MIME_TYPE_MAP[suffix]
  raise "No MIME Type defined for '#{suffix}'" if mime_type.nil?

  File.open(localpath, 'rb') do |file|
    bucket.put_object(
      :key => remotepath,
      :acl => 'public-read',
      :content_type => mime_type,
      :cache_control => CACHE_CONTROL,
      :body => file,
    )
  end
end


puts "Deleting unknown files from bucket"
bucket.objects.each do |obj|
  unless filelist.values.include?(obj.key)
    puts "  => #{obj.key}"
    obj.delete
  end
end

puts "Done."
