#!/usr/bin/env ruby

require 'bundler/setup'
require 'find'
require './lib/helpers'
Bundler.require(:default)

# # Load the library data
data = load_csv_data


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
        builder.loc("https://www.arduinolibraries.info" + path)
        if path =~ %r|/libraries/(.+)|
          library = data[:libraries][$1.to_sym]
          if library and library[:versions].first[:release_date]
            builder.lastmod(library[:versions].first[:release_date])
          end
        elsif path == '/'
          builder.lastmod(Time.now.utc.iso8601)
          builder.changefreq('daily')
        end
      end
    end
  }

  file.write builder.to_xml
end
