module TimelineService
  class PrecomputedFeed < ::BaseService
    def initialize(user, options = {})
      @user = user
    end

    def perform
      user_feed = UserFeed.new(@user)
      SleepLog.where(id: user_feed.feed)
    end
  end
end
