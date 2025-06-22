module TimelineService
  class PrecomputedFeed < ::BaseService
    def initialize(user, options = {})
      @user = user
    end

    def perform
      user_feed = UserFeed.new(@user)
      logs = SleepLog.fetch_multi(user_feed.feed)

      logs.sort_by { |log| log.sleep_duration }.reverse
    end
  end
end
