#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
Bundler.require(:default, :linkeddata)


# Load the library data
data = load_csv_data

# Load the schema.org context data
JSON::LD::Context.add_preloaded(
  'http://schema.org/',
  JSON::LD::Context.new.parse('schema_org_context.json')
)

FileUtils.mkdir_p("public/libraries")

data[:libraries].each_pair do |key,library|
  begin
    newest = library[:versions].first
  rescue Exception => e
    warn library
    raise e
  end

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

  if library[:license]
    jsonld['license'] = "https://spdx.org/licenses/"+library[:license]
  end
  begin
  File.open("public/libraries/#{key}.json", 'wb') do |file|
    file.write JSON.pretty_generate(jsonld)
  end
  rescue Exception => e
    warn "#{key} error: #{e}"
  end

  RDF::Turtle::Writer.open("public/libraries/#{key}.ttl") do |writer|
    JSON::LD::API.toRdf(jsonld) do |statement|
      writer << statement
    end
  end
end


FileUtils.mkdir_p("public/authors")

data[:authors].each_pair do |key,author|
  jsonld = {
      '@context' => 'http://schema.org/',
      '@type' => 'Person',
      'name' => author[:name],
      'sameAs' => [author[:github]]
  }

  jsonld['sameAs'] << "https://twitter.com/#{author[:twitter]}" unless author[:twitter].nil?
  jsonld['url'] = author[:homepage] unless author[:homepage].nil?
  jsonld['homeLocation'] = author[:location] unless author[:location].nil?

  File.open("public/authors/#{key}.json", 'wb') do |file|
    file.write JSON.pretty_generate(jsonld)
  end

  RDF::Turtle::Writer.open("public/authors/#{key}.ttl") do |writer|
    JSON::LD::API.toRdf(jsonld) do |statement|
      writer << statement
    end
  end
end
