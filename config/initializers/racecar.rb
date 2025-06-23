Racecar.configure do |config|
  config.max_wait_time = 10 # seconds
  config.min_message_queue_size = 5
  config.logger = Rails.logger
end
