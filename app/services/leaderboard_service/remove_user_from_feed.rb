module LeaderboardService
  class RemoveUserFromFeed < LeaderboardService::Base
    def initialize(user, target_user_id, options = {})
      @user = user
      @target_user_id = target_user_id
    end

    def perform
      # return if user follow another user
      follow = Follow.find_by(user_id: @user.id, target_user_id: @target_user_id)
      return if follow

      user_feed = UserFeed.new(@user)

      logs = user_feed.feed
      logs.select! { |log| log.user_id == @target_user_id.to_i }

      user_feed.remove_from_feed(logs)
    end
  end
end
