$twitter = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV['ARDUINOLIBS_CONSUMER_KEY'] or raise "ARDUINOLIBS_CONSUMER_KEY is not set"
  config.consumer_secret = ENV['ARDUINOLIBS_CONSUMER_SECRET'] or raise "ARDUINOLIBS_CONSUMER_SECRET is not set"
  config.oauth_token = ENV['ARDUINOLIBS_OAUTH_TOKEN'] or raise "ARDUINOLIBS_OAUTH_TOKEN is not set"
  config.oauth_token_secret = ENV['ARDUINOLIBS_OAUTH_TOKEN_SECRET'] or raise "ARDUINOLIBS_OAUTH_TOKEN_SECRET is not set"
end
