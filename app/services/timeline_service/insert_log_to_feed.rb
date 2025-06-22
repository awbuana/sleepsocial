module TimelineService
  class InsertLogToFeed < ::BaseService
    def initialize(user, sleep_log, options = {})
      @user = user
      @sleep_log = sleep_log
    end

    def perform
      # only show finished sleep log
      return unless @sleep_log.clock_out.present?

      user_feed = UserFeed.new(@user)
      user_feed.add_to_feed(@sleep_log)
    end
  end
end
