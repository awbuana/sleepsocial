module FollowService
  class Follow < ::BaseService

    def initialize(user, target_user_id, options = {})
      @user = user
      @target_user_id = target_user_id
    end

    def perform
      validate!

      target_user = User.find(@target_user_id)

      follow = ::Follow.new
      follow.user = @user
      follow.target_user = target_user

      ActiveRecord::Base.transaction(isolation: :serializable) do
        follow.save!
        @user.increment!(:num_following)
        target_user.increment!(:num_followers)
      end

      follow
    end

    private

    def validate!
      raise FollowService::Error.new('User must follow other users') if @user.id == @target_user_id
    end
  end
end