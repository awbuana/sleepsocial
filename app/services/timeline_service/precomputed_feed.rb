module TimelineService
  class PrecomputedFeed < ::BaseService
    def initialize(user, options = {})
      @user = user
    end

    # TODO: filter out old logs
    def perform
      user_feed = UserFeed.new(@user)
      logs = SleepLog.fetch_multi(user_feed.feed, includes: :user)

      logs.sort_by { |log| [log.sleep_duration, log.id] }.reverse
    end
  end
end
