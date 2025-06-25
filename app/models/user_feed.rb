class UserFeed
  MAXIMUM_FEED = 5000.freeze

  class Member
    attr_reader :id, :user_id, :clock_in

    def initialize(id, user_id, clock_in)
      @id = id
      @user_id = user_id
      @clock_in = clock_in
    end
  end

  def initialize(user)
    @user = user
  end

  def feed(offset = 0, limit = -1)
    end_idx = limit < 0 ? limit : offset+limit-1
    members = REDIS.call("ZRANGE", feed_key, offset, end_idx, "REV")
    members.map { |m| parse_member(m) }
  end

  def count
    REDIS.call("ZCARD", feed_key).to_i
  end

  def add_to_feed(sleep_log)
    REDIS.call("ZADD", feed_key, score(sleep_log), member_key(sleep_log))
  end

  def remove_from_feed(members)
    member_keys = members.map { |m| member_key(m) }
    return if member_keys.blank?

    REDIS.call("ZREM", feed_key, member_keys)
  end

  def resize_feed
    members_count = count
    return if members_count <= UserFeed::MAXIMUM_FEED

    Rails.logger.info(message: "resize feed user", user_id: @user.id, count: members_count)
    REDIS.call("ZREMRANGEBYRANK", feed_key, 0, members_count-UserFeed::MAXIMUM_FEED-1)
  end

  private

  def feed_key
    "feed:#{@user.id}"
  end

  def parse_member(member_key)
    res = JSON.parse(member_key)
    res["ts"] = Time.parse(res["ts"])

    Member.new(res["id"], res["uid"], res["ts"])
  end

  def score(sleep_log)
    sleep_log.sleep_duration
  end

  def member_key(sleep_log)
    { uid: sleep_log.user_id, id: sleep_log.id, ts: sleep_log.clock_in.strftime("%Y%m%dT%H%M%S%z") }.to_json
  end
end
