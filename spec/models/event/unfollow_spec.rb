require 'rails_helper'

RSpec.describe Event::Unfollow, type: :model do
  let(:user_id) { 10 }
  let(:unfollowed_user_id) { 20 }
  subject { described_class.new(user_id, unfollowed_user_id) }

  it "initializes with user_id and unfollowed_user_id" do
    expect(subject.instance_variable_get(:@user_id)).to eq(user_id)
    expect(subject.instance_variable_get(:@unfollowed_user_id)).to eq(unfollowed_user_id)
  end

  it "returns the correct topic_name" do
    expect(subject.topic_name).to eq("feed-updates")
  end

  it "returns the correct routing_key" do
    expect(subject.routing_key).to eq(user_id.to_s)
  end

  it "returns the correct data payload" do
    expected_data = {
      user_id: user_id,
      unfollowed_user_id: unfollowed_user_id
    }
    expect(subject.data).to eq(expected_data)
  end
end
