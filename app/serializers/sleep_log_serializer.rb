class SleepLogSerializer < ActiveModel::Serializer
  attribute :id
  attribute :user_id
  attribute :clock_out
  attribute :created_at
end
