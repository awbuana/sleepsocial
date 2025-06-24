module TimelineService
  class BackfillFeedByFollowing < ::BaseService
    def initialize(user, options = {})
      @user = user
    end

    def perform
      return if recently_backfilled?

      @user.update!(last_backfill_at: Time.now.utc)
      @user.following.order(:id).find_in_batches do | followings |
        Racecar.wait_for_delivery do
          followings.each do |following|
            event = Event::BackfillFeedByUser.new(@user.id, following.id)
            Racecar.produce_async(value: event.payload, topic: event.topic_name, partition_key: event.routing_key)
          end
        end
      end
    end

    private

    def recently_backfilled?
      @user.last_backfill_at && @user.last_backfill_at > 6.hour.ago.utc
    end
  end
end
