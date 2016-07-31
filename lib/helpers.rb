def link_to(text, href=nil)
  href=text if href.nil?
  "<a href='#{href}'>#{text}</a>"
end

def pretty_list(list)
  if list.nil?
    "<i>Unknown</i>"
  elsif list == ['*']
    "All"
  else
    list.join(', ')
  end
end

def format_filesize(bytes)
  Filesize.new(bytes).pretty
end
