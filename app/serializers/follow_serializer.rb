class FollowSerializer < ActiveModel::Serializer
  attribute :id
  attribute :user
  attribute :target_user
  attribute :created_at

  def user
    UserSerializer.new(object.user)
  end

  def target_user
    UserSerializer.new(object.target_user)
  end
end
