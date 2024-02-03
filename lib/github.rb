require 'net/https'
require 'json'
require 'thread'

GITHUB_API = 'https://api.github.com/'

def http_get_recursive(uri, count = 0, headers: nil)
  http = Net::HTTP.new(uri.host, uri.inferred_port)
  if uri.scheme == 'https'
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  end

  request = Net::HTTP::Get.new(uri.request_uri)
  request['Accept'] = 'application/json'
  request['User-Agent'] = 'arduniolibraries.info fetcher'
  if ENV['GITHUB_API_TOKEN']
    request['Authorization'] = 'token ' + ENV['GITHUB_API_TOKEN']
  else
    $stderr.puts "Warning: GITHUB_API_TOKEN environment variable is not set"
  end
  unless headers.nil?
    headers.each do |key, value|
      request[key] = value unless value.nil?
    end
  end

  response = http.request(request)
  if response.code =~ /^3/ and response.code != '304'
    location = Addressable::URI.parse(response['Location'])
    warn "Being redirected from '#{uri}' to '#{location}'"
    raise "Redirected too many times" if count > 5
    http_get_recursive(location, count + 1, headers: headers)
  elsif (response.code == '403' or response.code == '429') and response['x-ratelimit-remaining'].to_i == 0
    wait_till = response['x-ratelimit-reset'].to_i
    now = Time.now.to_i
    warn "Rate limit exceeded. Waiting till #{Time.at wait_till} (#{wait_till - now}s)."
    sleep(wait_till - now)
    http_get_recursive(uri, count + 1, headers: headers)
  elsif response.code =~ /^2/ or response.code == '304' # 304 = Not modified
    response
  else
    warn "Error: #{request.method} #{request.path}"
    warn "#{response.inspect}"
    raise response.inspect
  end
end

def get_github(path, parameters=nil, headers:nil)
  uri = Addressable::URI.parse(GITHUB_API)
  uri.path = path
  uri.query_values = parameters unless parameters.nil?

  response = http_get_recursive(uri, headers: headers)
  if response.content_type == 'application/json'
    [
      JSON.parse(
        response.body,
        {:symbolize_names => true}
      ),
      response
    ]
  else
    [
      response.body,
      response,
    ]
  end
end

def github_headers(row)
  return {} if row.nil?
  headers = {}
  headers['if-none-match'] = row[:etag].sub!('W/', '') if row[:etag]
  headers['if-modified-since'] = row[:last_modified] if row[:last_modified]
  headers
end

# Should be fine if `MAX_DOWNLOAD_THREADS` > core_count as threads do only network calls
MAX_DOWNLOAD_THREADS = 20

def parallel_each(arr, &map_fn)
  idx_queue = Queue.new ((arr.is_a?Array) ? arr.length.times : arr.keys)
  idx_queue.close
  
  threads = MAX_DOWNLOAD_THREADS.times.map do
    Thread.new do
      while !(idx_queue.closed? && idx_queue.empty?) do
        idx = idx_queue.pop
        if idx.nil?
          # possible ?
          next
        end
        if map_fn.arity == 0
          map_fn.call
        elsif map_fn.arity == 1
          map_fn.call arr[idx]
        else
          map_fn.call idx, arr[idx]
        end
      end
    end
  end
  threads.each(&:join)
end
