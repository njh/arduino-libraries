$twitter = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV['ARDUINOLIBS_CONSUMER_KEY'] or raise "ARDUINOLIBS_CONSUMER_KEY is not set"
  config.consumer_secret = ENV['ARDUINOLIBS_CONSUMER_SECRET'] or raise "ARDUINOLIBS_CONSUMER_SECRET is not set"
  config.access_token = ENV['ARDUINOLIBS_ACCESS_TOKEN'] or raise "ARDUINOLIBS_ACCESS_TOKEN is not set"
  config.access_token_secret = ENV['ARDUINOLIBS_ACCESS_TOKEN_SECRET'] or raise "ARDUINOLIBS_ACCESS_TOKEN_SECRET is not set"
end
