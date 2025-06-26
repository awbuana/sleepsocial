class SleepLogCreatedConsumer < BaseConsumer
  subscribes_to "sleep-log-created"

  def perform(message)
    event = JSON.parse(message.value)
    fan_out_sleep_log(event)
  end

  private

  def fan_out_sleep_log(event)
    sleep_log_id = event["data"]["sleep_log_id"]
    sleep_log = SleepLog.find_by(id: sleep_log_id)
    return unless sleep_log

    user = sleep_log.user
    # ordering by id confuses MySQL, lead to use primary index
    Follow.use_index('index_follows_on_target_user_id').where(target_user: user).select(:user_id, :id).order(:id).find_in_batches do | followers |
      followers.each do |follower|
        event = Event::InsertLogToFeed.new(follower.user_id, sleep_log_id)
        Racecar.produce_sync(value: event.payload, topic: event.topic_name, partition_key: event.routing_key)
      end
    end
  end
end
