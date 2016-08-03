class String
  def keyize
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1-\2').
    gsub(/([a-z\d])([A-Z])/,'\1-\2').
    gsub(/\W+/,'-').
    downcase
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
