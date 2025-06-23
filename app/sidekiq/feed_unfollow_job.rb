class FeedUnfollowJob
  include Sidekiq::Job

  def perform(user_id, target_user_id)
    user = User.find(user_id)

    TimelineService.remove_user_from_feed(user, target_user_id)
  rescue => e
    puts e.message
  end
end
