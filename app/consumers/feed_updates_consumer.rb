class FeedUpdatesConsumer < BaseConsumer
  subscribes_to "feed-updates"

  def perform(message)
    event = JSON.parse(message.value)

    case event["event_name"]
    when "Event::SleepLogCreated"
      fan_out_sleep_log(event)
    when "Event::InsertSleepLog"
      insert_sleep_log(event)
    when "Event::Follow"
      follow_job(event)
    when "Event::Unfollow"
      unfollow_job(event)
    end
  end

  private

  def insert_sleep_log(event)
    sleep_log_id = event["data"]["sleep_log_id"]
    user_id = event["data"]["user_id"]

    user = User.find_by(id: user_id)
    return unless user

    sleep_log = SleepLog.find_by(id: sleep_log_id)
    return unless sleep_log

    TimelineService.insert_log_to_feed(user, sleep_log)
  end

  def fan_out_sleep_log(event)
    sleep_log_id = event["data"]["sleep_log_id"]
    sleep_log = SleepLog.find_by(id: sleep_log_id)
    return unless sleep_log

    user = sleep_log.user

    user.followers.select(:id).order(:id).find_in_batches do | users |
      users.each do |user|
        event = {
          name: "insert_sleep_log_job",
          data: {
            user_id: user.id,
            sleep_log_id: sleep_log_id
          }
        }

        Racecar.produce_sync(value: event.to_json, topic: "feed-updates", partition_key: user.id.to_s)
      end
    end
  end

  def unfollow_job(event)
    user_id = event["data"]["user_id"]
    user = User.find_by(id: user_id)
    return unless user

    target_user_id = event["data"]["unfollowed_user_id"]
    TimelineService.remove_user_from_feed(user, target_user_id)
  end

  def follow_job(event)
    user_id = event["data"]["user_id"]
    user = User.find_by(id: user_id)
    return unless user

    followed_user_id = event["data"]["followed_user_id"]
    followed_user = User.find_by(id: followed_user_id)
    return unless followed_user

    TimelineService.backfill_feed_by_user(user, followed_user)
  end
end
