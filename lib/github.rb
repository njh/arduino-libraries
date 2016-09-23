require 'net/https'
require 'json'

GITHUB_API = 'https://api.github.com/'

def get_github(path, parameters={})
  uri = Addressable::URI.parse(GITHUB_API)
  uri.path = path
  uri.query_values = parameters
  
  http = Net::HTTP.new(uri.host, uri.inferred_port)
  if uri.scheme == 'https'
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  end

  request = Net::HTTP::Get.new(uri.request_uri)
  request['ACCEPT'] = 'application/json'
  request['USER_AGENT'] = 'arduniolibraries.info fetcher '
  if ENV['GITHUB_API_TOKEN']
    request['Authorization'] = 'token ' + ENV['GITHUB_API_TOKEN']
  else
    $stderr.puts "Warning: GITHUB_API_TOKEN environment variable is not set"
  end

  response = http.request(request)
  if response.content_type == 'application/json'
    JSON.parse(
      response.body,
      {:symbolize_names => true}
    )
  else
    response.body
  end
end

