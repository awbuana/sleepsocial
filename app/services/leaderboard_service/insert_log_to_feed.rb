module LeaderboardService
  class InsertLogToFeed < LeaderboardService::Base
    def initialize(user, sleep_log, options = {})
      @user = user
      @sleep_log = sleep_log
    end

    def perform
      # only show finished sleep log
      return unless @sleep_log.clock_out.present?

      # skip expired log
      return if @sleep_log.clock_in < leaderboard_threshold

      # return if user not follow another user anymore
      follow = Follow.find_by(user_id: @user.id, target_user_id: @sleep_log.user_id)
      return unless follow

      user_feed.add_to_feed(@sleep_log)
      user_feed.resize_feed # resize feed if overflow. to save memory space
    end

    private

    def user_feed
      @user_feed ||= UserFeed.new(@user)
    end
  end
end
