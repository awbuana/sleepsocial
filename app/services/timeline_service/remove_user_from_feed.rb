module TimelineService
  class RemoveUserFromFeed < ::BaseService
    def initialize(user, target_user_id, options = {})
      @user = user
      @target_user_id = target_user_id
    end

    def perform
      user_feed = UserFeed.new(@user)

      logs = user_feed.feed
      logs.select!{ |log| log.user_id == target_user_id.to_i }

      user_feed.remove_from_feed(logs)
    end
  end
end
