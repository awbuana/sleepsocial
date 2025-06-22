class FollowSerializer < ActiveModel::Serializer
  attribute :id
  attribute :user_id
  attribute :target_user_id
  attribute :created_at
end
