module FollowService
  class Error < BaseService::ServiceError; end

  module_function

  def follow(*args); FollowService::Follow.new(*args).perform; end
  def unfollow(*args); FollowService::Unfollow.new(*args).perform; end
end
