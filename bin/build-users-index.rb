#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/github'
Bundler.require(:default)
require 'csv'
require './lib/helpers'

data = JSON.parse(
  File.read('library_index_clean.json'),
  {:symbolize_names => true}
)

OUT_FILE = 'users_index.csv'
TMP_OUT_FILE = OUT_FILE + '.tmp'
BKP_OUT_FILE = OUT_FILE + '.bkp'


IN_FILE = (File.size?(TMP_OUT_FILE).to_i >= File.size?(OUT_FILE).to_i) ? TMP_OUT_FILE : OUT_FILE
# If last run created more data than before it stopped at,
# build over that data in this run.

COPY_INDEX_PROPERTIES = [
  :name,
  :github,
  # :libraries,
  :twitter,
  :homepage,
]
COPY_GITHUB_PROPERTIES = [
  :name,
  :location,
  :company,
  :type,
  :avatar_url,
  :email,
  :bio,
  # :homepage,
  # :twitter,
]
csv_headers = [
  :key,
  :etag,
  :last_modified,
  *COPY_INDEX_PROPERTIES,
  *COPY_GITHUB_PROPERTIES,
].uniq
JSON_COLUMNS = [
  # :libraries
]

SavedDocs = {}
if File.exist?(IN_FILE)
  puts "Resuming from #{IN_FILE}"
  CSV.foreach(IN_FILE, :headers => true, :header_converters => [->(v) { v.to_sym }]) do |row|
    JSON_COLUMNS.each do |prop|
      row = row.to_hash
      unless row[prop] == '' || row[prop].nil?
        row[prop] = JSON.parse(row[prop], {:symbolize_names => true})
      end
    end
    SavedDocs[row[:key].to_sym] = row
  end
else
  puts "No previous file to resume"
end

CSV.open(TMP_OUT_FILE, 'w', :headers => csv_headers, :write_headers => true) do |csv|
end

update_count = 0
unchanged_count = 0
error_count = 0
mutex = Mutex.new
begin
  parallel_each(data[:authors]) do |username, author|
    key = "#{username}"
    key_sym = key.to_sym
    # puts "Downloading #{key}"
    
    begin
      body, response = get_github("/users/#{key}", headers: github_headers(SavedDocs[key_sym]))
    rescue Exception => e
      is_error = true
      warn "Error #{key} : #{e}"
    end

    not_modified = response.code == '304' unless response.nil?
    puts "Updated   :: #{key}" if not_modified == false
    puts "Unchanged :: #{key}" if not_modified
    puts "Not Found :: #{key}" if not_modified.nil?
    row = SavedDocs[key_sym] || { :key => key }
    COPY_INDEX_PROPERTIES.each do |prop|
      row[prop] = author[prop]
    end
    if !not_modified and !body.nil?
      COPY_GITHUB_PROPERTIES.each do |prop|
        row[prop] = body[prop] unless body[prop].nil?
      end
      row[:homepage] = fix_url(body[:blog]) unless body[:blog].nil?
      if body[:twitter_username]
        if row[:twitter] and row[:twitter] != body[:twitter_username]
          warn "Warning: differing twitter accounts\n\tAuthor extras: #{row[:twitter]}\n\tGithub: #{body[:twitter_username]}"
        else
          row[:twitter] = body[:twitter_username]
        end
      end
    end
    row[:etag] = response['etag'] unless response.nil?
    row[:last_modified] = response['last-modified'] unless response.nil?
    JSON_COLUMNS.each do |col|
      row[col] = JSON.dump(row[col]) unless row[col].nil?
    end
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
  puts "Saved #{update_count + unchanged_count + error_count} / #{data[:authors].length} users."
  puts "#{update_count} updated"
  puts "#{unchanged_count} unchaged"
  puts "#{error_count} errored"
end
