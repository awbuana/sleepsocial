module TimelineService
  class Error < BaseService::ServiceError; end

  module_function

  def precomputed_feed(*args); TimelineService::PrecomputedFeed.new(*args).perform; end
end