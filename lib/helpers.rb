def link_to(text, href=nil)
  href=text if href.nil?
  "<a href='#{href}'>#{text}</a>"
end
