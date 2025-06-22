module FollowService
  class Unfollow < ::BaseService

    def initialize(user, target_user_id, options = {})
      @user = user
      @target_user_id = target_user_id
    end

    def perform
      follow = ::Follow.find_by(user_id: @user.id, target_user_id: @target_user_id)
      raise ActiveRecord::RecordNotFound unless follow

      target_user = User.find(@target_user_id)

      ActiveRecord::Base.transaction(isolation: :serializable) do
        follow.destroy!
        @user.decrement!(:num_following)
        target_user.decrement!(:num_followers)
      end
    end
  end
end