class SleepLogCreatedConsumer < BaseConsumer
  subscribes_to "sleep-log-created"

  def perform(message)
    event = JSON.parse(message.value)
    fan_out_sleep_log(event)
  end

  private

  def fan_out_sleep_log(event)
    sleep_log_id = event['data']['sleep_log_id']
    sleep_log = SleepLog.find_by(id: sleep_log_id)
    return unless sleep_log

    user = sleep_log.user

    user.followers.select(:id).order(:id).find_in_batches do | users |
      users.each do |user|
        event = Event::InsertSleepLog.new(user.id, sleep_log_id)
        Racecar.produce_sync(value: event.payload, topic: event.topic_name, partition_key: event.routing_key)
      end
    end
  end
end
