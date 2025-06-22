class FeedInsertJob
  include Sidekiq::Job

  def perform(user_id, sleep_log_id)
    user = User.find(user_id)
    sleep_log = SleepLog.find(sleep_log_id)

    TimelineService.insert_log_to_feed(user, sleep_log)
  rescue => e
    puts e.message
  end
end
