class UserFeed

  def initialize(user)
    @user = user
  end

  def feed
    @feed ||= REDIS.call("ZREVRANGE", feed_key, 0, -1)
  end

  def add_to_feed(sleep_log)
    REDIS.call("ZADD", feed_key, score(sleep_log), member_key(sleep_log))
  end

  def remove_from_feed(member_keys)
    REDIS.call("ZREM", feed_key, member_keys)
  end

  def self.parse_member(member_key)
    k, ts = member_key.split("#")

    [k, Time.parse(ts)]
  end

  private

  def feed_key
    "feed:#{@user.id}"
  end

  def score(sleep_log)
    sleep_log.sleep_duration
  end

  def member_key(sleep_log)
    "#{sleep_log.id}##{sleep_log.created_at}"
  end
end