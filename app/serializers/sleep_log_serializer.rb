class SleepLogSerializer < ActiveModel::Serializer
  attribute :id
  attribute :user
  attribute :clock_in
  attribute :clock_out
  attribute :sleep_duration_in_minutes
  attribute :created_at

  def user
    UserSerializer.new(object.fetch_user)
  end

  def sleep_duration_in_minutes
    object.sleep_duration
  end
end
