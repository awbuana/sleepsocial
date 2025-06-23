class FeedComputeJob
  include Sidekiq::Job

  def perform(user_id, followed_user_id)
    user = User.find_by(user_id)
    return unless user

    followed_user = User.find_by(followed_user_id)
    return unless followed_user

    TimelineService.backfill_feed_by_user(user, followed_user)
  end
end
