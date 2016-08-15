require 'net/https'
require 'json'

def get_github(path)
  http = Net::HTTP.new('api.github.com', 443)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  request = Net::HTTP::Get.new(path)
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

