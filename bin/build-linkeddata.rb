#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
Bundler.require(:default, :linkeddata)


# Load the library data
data = JSON.parse(
  File.read('library_index_with_github.json'),
  {:symbolize_names => true}
)

# Load the schema.org context data
JSON::LD::Context.add_preloaded(
  'http://schema.org/',
  JSON::LD::Context.new.parse('schema_org_context.json')
)

FileUtils.mkdir_p("public/libraries")

data[:libraries].each_pair do |key,library|
  newest = library[:versions].first

  jsonld = {
      '@context' => 'http://schema.org/',
      '@type' => 'SoftwareApplication',
      'name' => library[:name],
      'description' => library[:sentence],
      'url' => library[:website],
      'author' => {
        '@type' => 'Person',
        'name' => library[:author],
      },
      'applicationCategory' => library[:category],
      'operatingSystem' => 'Arduino',
      'downloadUrl' => newest[:url],
      'softwareVersion' => newest[:version],
      'fileSize' => newest[:size].to_i / 1024,
  }

  if newest[:release_date]
    jsonld['datePublished'] = Time.parse(newest[:release_date]).strftime('%Y-%m-%d')
  end

  File.open("public/libraries/#{key}.json", 'wb') do |file|
    file.write JSON.pretty_generate(jsonld)
  end

  RDF::Turtle::Writer.open("public/libraries/#{key}.ttl") do |writer|
    JSON::LD::API.toRdf(jsonld) do |statement|
      writer << statement
    end
  end
end
