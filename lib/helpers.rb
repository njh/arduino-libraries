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

def link_to(text, attributes={})
  attributes['href'] ||= text
  str = attributes.to_a.map {|k,v| "#{k}='#{v}'"}.join(' ')
  "<a #{str}>#{text}</a>"
end

def link_to_category(category)
  link_to(category, :href => "/categories/#{category.keyize}")
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
