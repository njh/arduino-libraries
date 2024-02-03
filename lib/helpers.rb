require 'csv'
require 'json'
require 'set'

class String
  def keyize
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1-\2').
    gsub(/([a-z\d])([A-Z])/,'\1-\2').
    gsub(/\W+/,'-').
    downcase
  end
end


def days_ago(timestamp)
  days = (Time.now - Time.parse(timestamp)) / 86400
  if days <= 1
    'today'
  elsif days <= 2
    'yesterday'
  else
    "#{days.floor} days ago"
  end
end

def fix_url(url)
  if url.nil? or url.strip == ''
    return nil
  end

  # Add http:// if there isn't one
  unless url =~ /^http/
    url = "http://#{url}"
  end

  # Add a trailing slash, if there isn't one
  unless url =~ %r[^https?://.+/]
    url += '/'
  end

  if url =~ /github\.com/
    # Remove www. from github URLs
    url.sub!(%r[https?://(www\.)?github\.com/], 'https://github.com/')
  
    # Remove .git from the end of Github urls
    url.sub!(%r[\.git$], '')
  end
  
  return url
end

def link_to(text, attributes={})
  attributes['href'] ||= text
  str = attributes.to_a.map {|k,v| "#{k}='#{v}'"}.join(' ')
  "<a #{str}>#{text}</a>"
end

def link_to_category(category)
  link_to(category, :href => "/categories/#{category.keyize}")
end

def link_to_license(license, title=nil)
  if license.nil?
    "Unknown"
  else
    title = license.to_s.gsub('-', ' ') if title.nil?
    link_to(title, :href => "https://choosealicense.com/licenses/#{license.downcase}/")
  end
end

def pretty_list(list)
  if list.nil?
    "<i>Unknown</i>"
  elsif list == ['*']
    "Any"
  else
    list.join(', ')
  end
end

def format_filesize(bytes)
  Filesize.new(bytes).pretty
end

def library_sort(libraries, key, limit=10)
  libraries.values.
    reject {|library| library[key].nil?}.
    sort_by {|library| library[key]}.
    reverse.
    slice(0, limit)
end

def strip_html(html)
  Nokogiri::HTML(html).inner_text
end

def remove_links(text)
  text.gsub(%r|(\w+)://|, '').gsub(/(\w+)\.(\w+)/, '\\1․\\2')
end

LIBRARY_JSON_COLUMNS = [
  :architectures,
  :dependencies,
  :providesIncludes,
  :types,
].to_set
NUMERIC_COLUMNS = [
  :stargazers_count,
  :watchers_count,
  :forks,
].to_set

$csv_data = nil
CSV::Converters[:custom_conv] = lambda do |value, field_info|
  return value if value.nil?
  if LIBRARY_JSON_COLUMNS.include? field_info.header 
    JSON.parse(value, {:symbolize_names => true})
  elsif NUMERIC_COLUMNS.include? field_info.header
    if value.include? '.'
      value.to_f
    else
      value.to_i
    end
  else
    value
  end
end

def load_csv_data(force_load=false)
  return $csv_data if !force_load and !$csv_data.nil?
  data = {
    :libraries => {},
    :authors => {},
    :licenses => {},
    :architectures => {},
    :types => {},
    :categories => {},
  }
  csv_options = {
    :headers => true,
    :header_converters => [->(v) { v.to_sym }],
    :converters => [:custom_conv]
  }
  
  CSV.foreach('users_index.csv', **csv_options) do |row|
    data[:authors][row[:key].to_sym] = row.to_hash
  end

  CSV.foreach('repos_index.csv', **csv_options) do |row|
    lib_key = row[:name].keyize.to_sym
    data[:libraries][lib_key] = row.to_hash
    
    data[:authors][row[:username].to_sym] ||= {}
    data[:authors][row[:username].to_sym][:libraries] ||= []
    data[:authors][row[:username].to_sym][:libraries] << row[:key]

    if row[:architectures].is_a?Array and !row[:architectures].empty?
      row[:architectures].each do |architecture|
        architecture = architecture.downcase
        architecture = 'Unknown' if architecture.strip.empty?
        architecture = 'Any' if architecture == '*' || architecture == '"*"' # `CosmosNV2` version `1.2.0` has architecture = ["\"*\""] in raw file
        data[:architectures][architecture.to_sym] ||= []
        data[:architectures][architecture.to_sym] << row[:key]
      end
    else
      architecture = 'Unknown'
      data[:architectures][architecture.to_sym] ||= []
      data[:architectures][architecture.to_sym] << row[:key]
    end

    license = row[:license]
    license = 'NA' if license.nil? or license.strip.empty?
    data[:licenses][license.to_sym] ||= []
    data[:licenses][license.to_sym] << row[:key]

    if row[:types].is_a?Array and !row[:types].empty?
      row[:types].each do |type|
        type = 'Unknown' if type.strip.empty?
        data[:types][type.to_sym] ||= []
        data[:types][type.to_sym] << row[:key]
      end
    else
      type = 'Unknown'
      data[:types][type.to_sym] ||= []
      data[:types][type.to_sym] << row[:key]
    end

    category = row[:category]
    category = 'Unknown' if category.nil? or category.strip.empty?
    data[:categories][category.to_sym] ||= []
    data[:categories][category.to_sym] << row[:key]
  end

  CSV.foreach('versions_index.csv', **csv_options) do |row|
    library = data[:libraries][row[:repo_key].to_sym]
    library[:versions] ||= []
    library[:versions] << row.to_hash
    library[:release_date] = (library[:release_date].to_s > row[:release_date].to_s) ? library[:release_date] : row[:release_date]
  end

  $csv_data = data
  data
end
