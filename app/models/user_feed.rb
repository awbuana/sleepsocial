class UserFeed

  class Member
    attr_reader :id, :user_id, :created_at

    def initialize(id, user_id, created_at)
      @id = id
      @user_id = user_id
      @created_at = created_at
    end
  end

  def initialize(user)
    @user = user
  end

  def feed
    @feed ||= begin
      members = REDIS.call("ZREVRANGE", feed_key, 0, -1)
      members.map{ |m| parse_member(m) }
    end
  end

  def add_to_feed(sleep_log)
    REDIS.call("ZADD", feed_key, score(sleep_log), member_key(sleep_log))
  end

  def remove_keys_from_feed(members)
    member_keys = members.map{ |m| member_key(m) }
    REDIS.call("ZREM", feed_key, member_keys)
  end

  private

  def feed_key
    "feed:#{@user.id}"
  end

  def parse_member(member_key)
    res = JSON.parse(member_key)
    res["ts"] = Time.parse(res["ts"])
    
    Member.new(res['id'], res['uid'], res['ts'])
  end

  def score(sleep_log)
    sleep_log.sleep_duration
  end

  def member_key(sleep_log)
    {uid: sleep_log.user_id, id: sleep_log.id, ts: sleep_log.created_at.strftime("%Y%m%dT%H%M%S%z")}.to_json
  end
end