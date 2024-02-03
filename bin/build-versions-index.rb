#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/github'
require './lib/helpers'
Bundler.require(:default)
require 'csv'

data = JSON.parse(
  File.read('library_index_clean.json'),
  {:symbolize_names => true}
)

OUT_FILE = 'versions_index.csv'
TMP_OUT_FILE = OUT_FILE + '.tmp'
BKP_OUT_FILE = OUT_FILE + '.bkp'


IN_FILE = (File.size?(TMP_OUT_FILE).to_i >= File.size?(OUT_FILE).to_i) ? TMP_OUT_FILE : OUT_FILE
# If last run created more data than before it stopped at,
# build over that data in this run.

COPY_INDEX_PROPERTIES = [
  :version,
  :archiveFileName,
  :url,
  :size,
]

csv_headers = [
  :key,
  :repo_key,
  :etag,
  :last_updated,
  *COPY_INDEX_PROPERTIES,
  :github,
  :git_sha,
  :release_date,
].uniq

JSON_COLUMNS = []

SavedDocs = {}
if File.exist?(IN_FILE)
  puts "Resuming from #{IN_FILE}"
  CSV.foreach(IN_FILE, :headers => true, :header_converters => [->(v) { v.to_sym }]) do |row|
    row = row.to_hash
    JSON_COLUMNS.each do |prop|
      unless row[prop] == '' || row[prop].nil?
        row[prop] = JSON.parse(row[prop], {:symbolize_names => true})
      end
    end
    SavedDocs[row[:key].to_sym] = row
  end
else
  puts "No previous file to resume"
end

$tags = {}
def find_tag(username, reponame, version)
  key = [username, reponame].join('/')
  if $tags[key].nil?
    $tags[key] = []
    body, = get_github("/repos/#{username}/#{reponame}/tags")
    if body.include?(:message)
      raise body[:message]
    end
    $tags[key] = body.map {|tag| tag[:name]}
  end
  tag_by_majorminor = nil
  tag_by_anymatch = nil

  $tags[key].each do |tag|
    majorminor = version.sub(/\.0$/, '')
    if tag =~ /^v?_?#{version}$/i
      tag_by_majorminor = tag
    elsif tag =~ /^v?_?#{majorminor}$/i
      return tag
    elsif tag =~ /#{version}/i
      tag_by_anymatch = tag
    end
  end
  return tag_by_majorminor unless tag_by_majorminor.nil?
  return tag_by_anymatch unless tag_by_anymatch.nil?

  return nil
end

all_versions = data[:libraries].flat_map do |lib_key, library|
  library[:versions].map do |version|
    {
      :lib_key => lib_key,
      :library => library,
      :version => version
    }
  end
end

# all_versions.slice! 5..(all_versions.length)

CSV.open(TMP_OUT_FILE, 'w', :headers => csv_headers, :write_headers => true) do |csv|
end

update_count = 0
unchanged_count = 0
error_count = 0
mutex = Mutex.new
begin
  parallel_each(all_versions) do |lib_version|
    library_key = lib_version[:lib_key]
    library = lib_version[:library]
    version = lib_version[:version]

    library_github_key = "#{library[:username]}/#{library[:reponame]}"
    key = "#{library_github_key}/#{version[:version]}"

    saved_doc = SavedDocs[key.to_sym]
    begin
      if saved_doc.nil? or saved_doc[:github].nil?
        tag = find_tag(library[:username], library[:reponame], version[:version])
      else
        tag = saved_doc[:github].sub(/.*commits\//, '')
      end
      raise "Tag not found" if tag.nil?
      body, response = get_github("/repos/#{library_github_key}/commits/#{tag}", headers: github_headers(saved_doc))
    rescue Exception => e
      is_error = true
      warn "Error #{key} : #{e}"
    end
    
    not_modified = response.code == '304' unless response.nil?
    puts "Updated   :: #{key}" if not_modified == false
    puts "Unchanged :: #{key}" if not_modified
    puts "Not Found :: #{key}" if not_modified.nil?
    row = saved_doc || { :key => key }
    row[:repo_key] = library_key
    COPY_INDEX_PROPERTIES.each do |prop|
      row[prop] = version[prop]
    end
    if !not_modified and !body.nil?
      tag = body[:tag] if body[:tag]
      row[:github] = "#{library[:github]}/commits/#{tag}" unless tag.nil?
      row[:git_sha] = body[:sha]
      row[:release_date] = body[:commit][:committer][:date]
    end
    row[:etag] = response['etag'] unless response.nil?
    row[:last_modified] = response['last-modified'] unless response.nil?

    row_arr = csv_headers.map do |h|
      row[h]
    end
    mutex.synchronize do
      unchanged_count += 1 if not_modified
      update_count += 1 if not_modified == false
      error_count += 1 if is_error
      CSV.open(TMP_OUT_FILE, 'a', :headers => csv_headers) do |csv|
        csv << row_arr
      end
    end
  end

  if File.exist?(OUT_FILE)
    File.rename(OUT_FILE, BKP_OUT_FILE)
  end
  File.rename(TMP_OUT_FILE, OUT_FILE)
ensure
  puts "Saved #{update_count + unchanged_count + error_count} / #{all_versions.length} versions."
  puts "#{update_count} updated"
  puts "#{unchanged_count} unchaged"
  puts "#{error_count} errored"
end
