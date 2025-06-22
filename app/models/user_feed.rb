class UserFeed

  def initialize(user)
    @user = user
  end

  def feed
    @feed ||= REDIS.call("ZRANGE", feed_key, 0, -1)
  end

  def add_to_feed(sleep_log)
    # TODO adjust score
    REDIS.call("ZADD", feed_key, 69, sleep_log.id)
  end

  private

  def feed_key
    "feed:#{@user.id}"
  end
end