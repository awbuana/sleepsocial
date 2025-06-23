class Event::Unfollow < Event::Base
  def initialize(user_id, unfollowed_user_id)
    @user_id = user_id
    @unfollowed_user_id = unfollowed_user_id
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
      unfollowed_user_id: @unfollowed_user_id
    }
  end
end
