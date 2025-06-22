class FeedInsertJob
  include Sidekiq::Job

  def perform(user_id, sleep_log_id)
    puts "#{user_id} - #{sleep_log_id}"
    # Do something
  end
end
