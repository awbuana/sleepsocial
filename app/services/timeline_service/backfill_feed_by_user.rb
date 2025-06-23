module TimelineService
  class BackfillFeedByUser < ::BaseService
    def initialize(user, followed_user, options = {})
      @user = user
      @followed_user = followed_user
    end

    def perform
      # return if user not follow another user anymore
      follow = Follow.find_by(user_id: @user.id, target_user_id: @followed_user.id)
      return unless follow

      user_feed = UserFeed.new(@user)

      @followed_user.sleep_logs.where("created_at > ?", timeline_threshold).order(:id).find_in_batches do | sleep_logs |
        sleep_logs.each do |log|
          # skip sleep log if it's not finalized yet
          next unless log.clock_out

          user_feed.add_to_feed(log)
        end
      end
    end

    private

    def timeline_threshold
      7.days.ago
    end
  end
end
