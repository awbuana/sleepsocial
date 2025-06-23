class Event::InsertSleepLog < Event::Base

  def initialize(user_id, sleep_log_id)
    @user_id = user_id
    @sleep_log_id = sleep_log_id
  end

  def topic_name
    "feed-updates"
  end

  def routing_key
    @user_id.to_s
  end

  def data
    {
      user_id: @user_id,
      sleep_log_id: @sleep_log_id
    }
  end
end