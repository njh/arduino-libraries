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
