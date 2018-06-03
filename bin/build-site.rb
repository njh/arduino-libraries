#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/helpers'
require './lib/render'
Bundler.require(:default)


# Load the library data
data = JSON.parse(
  File.read('library_index_with_github.json'),
  {:symbolize_names => true}
)

@count = data[:libraries].keys.count
@types = data[:types]
@categories = data[:categories]
@architectures = data[:architectures]
@licenses = data[:licenses]
@authors = data[:authors]

render(
  'index.html',
  :index,
  :title => "Arduino Library List",
  :description => "A catalogue of the #{@count} Arduino Libraries",
  :rss_url => "https://www.arduinolibraries.info/feed.xml",
  :most_recent => library_sort(data[:libraries], :release_date),
  :most_stars => library_sort(data[:libraries], :stargazers_count),
  :most_forked => library_sort(data[:libraries], :forks)
)

render(
  'libraries/index.html',
  :list,
  :title => 'All Libraries',
  :synopsis => "A list of the <i>#{@count}</i> "+
               "libraries registered in the Arduino Library Manager.",
  :keys => data[:libraries].keys,
  :libraries => data[:libraries]
)

data[:types].each_pair do |type,libraries|
  render(
    "types/#{type.to_s.keyize}/index.html",
    :list,
    :title => type,
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries of the type #{type}.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

data[:categories].each_pair do |category,libraries|
  render(
    "categories/#{category.to_s.keyize}/index.html",
    :list,
    :title => category,
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries in the category #{category}.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

data[:architectures].each_pair do |architecture,libraries|
  render(
    "architectures/#{architecture.to_s.keyize}/index.html",
    :list,
    :title => architecture.capitalize,
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries in the architecture #{architecture}.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

data[:licenses].each_pair do |license,libraries|
  render(
    "licenses/#{license.to_s.keyize}/index.html",
    :list,
    :title => license.to_s.gsub('-',' '),
    :synopsis => "A list of the <i>#{libraries.count}</i> "+
                 "libraries that are licensed with the #{link_to_license(license)} license.",
    :keys => libraries.map {|key| key.to_sym},
    :libraries => data[:libraries]
  )
end

render(
  "authors/index.html",
  :authors,
  :title => "List of Aurduino Library Authors",
  :authors => data[:authors]
)

data[:authors].each_pair do |username,author|
  render(
    "authors/#{username}/index.html",
    :author,
    :title => author[:name],
    :username => username,
    :author => author,
    :jsonld => File.read("public/authors/#{username}.json"),
    :libraries => data[:libraries]
  )
end

data[:libraries].each_pair do |key,library|
  render(
    "libraries/#{key}/index.html",
    :show,
    :title => library[:name],
    :description => library[:sentence],
    :jsonld => File.read("public/libraries/#{key}.json"),
    :library => library
  )
end
