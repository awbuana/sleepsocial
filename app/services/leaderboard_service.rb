module LeaderboardService
  class Error < BaseService::ServiceError; end

  module_function

  def precomputed_feed(*args); LeaderboardService::PrecomputedFeed.new(*args).perform; end
  def insert_log_to_feed(*args); LeaderboardService::InsertLogToFeed.new(*args).perform; end
  def remove_user_from_feed(*args); LeaderboardService::RemoveUserFromFeed.new(*args).perform; end
  def backfill_feed_by_user(*args); LeaderboardService::BackfillFeedByUser.new(*args).perform; end
  def backfill_feed_by_following(*args); LeaderboardService::BackfillFeedByFollowing.new(*args).perform; end
end
