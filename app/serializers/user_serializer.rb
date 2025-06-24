class UserSerializer < ActiveModel::Serializer
  attribute :id
  attribute :name
  attribute :num_following
  attribute :num_followers
  attribute :created_at
end
