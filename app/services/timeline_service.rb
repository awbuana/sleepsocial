module TimelineService
  class Error < BaseService::ServiceError; end

  module_function

  def precomputed_feed(*args); TimelineService::PrecomputedFeed.new(*args).perform; end
  def insert_log_to_feed(*args); TimelineService::InsertLogToFeed.new(*args).perform; end
  def remove_user_from_feed(*args); TimelineService::RemoveUserFromFeed.new(*args).perform; end
end
