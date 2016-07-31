def link_to(text, href=nil)
  href=text if href.nil?
  "<a href='#{href}'>#{text}</a>"
end

def format_filesize(bytes)
  Filesize.new(bytes).pretty
end
