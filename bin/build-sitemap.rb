#!/usr/bin/env ruby

require 'bundler/setup'
require 'find'
Bundler.require(:default)


File.open('public/sitemap.xml', 'wb') do |file|
  builder = Nokogiri::XML::Builder.new
  builder.urlset(
    'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
    'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
    'xsi:schemaLocation' => 'http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd'
  ) {
    Find.find('public') do |path|
      next unless File.file?(path) and path.match(/\.html$/)
      path.sub!(%r|^public|, '')
      path.sub!(%r|/index\.html$|, '')
      path = '/' if path.empty?
      
      builder.url do
        builder.loc("http://www.arduinolibraries.info" + path)
      end
    end
  }

  file.write builder.to_xml
end
