require 'tilt'

# Load the ERB templates
Templates = {}
Dir.foreach('views') do |filename|
  if filename =~ /^(\w+)\.(\w+)\.erb$/
    template_key = $1.to_sym
    Templates[template_key] = Tilt::ErubisTemplate.new(
      "views/#{filename}",
      :escape_html => true
    )
  end
end


def render(filename, template, args={})
  publicpath = "public/#{filename}"
  dirname = File.dirname(publicpath)
  FileUtils.mkdir_p(dirname) unless Dir.exist?(dirname)

  args[:url] ||= "https://www.arduinolibraries.info/#{filename}".sub!(%r|/index.html$|, '')
  args[:rss_url] ||= nil
  args[:description] ||= nil
  args[:jsonld] ||= nil
  
  File.open(publicpath, 'wb') do |file|
    file.write Templates[:layout].render(self, args) {
      Templates[template].render(self, args)
    }
  end
end
