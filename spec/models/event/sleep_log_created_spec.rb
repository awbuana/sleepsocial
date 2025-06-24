require 'rails_helper'

RSpec.describe Event::SleepLogCreated, type: :model do
  let(:user_id) { 1000 }
  let(:sleep_log_id) { 2000 }
  subject { described_class.new(user_id, sleep_log_id) }

  it "initializes with user_id and sleep_log_id" do
    expect(subject.instance_variable_get(:@user_id)).to eq(user_id)
    expect(subject.instance_variable_get(:@sleep_log_id)).to eq(sleep_log_id)
  end

  it "returns the correct topic_name" do
    expect(subject.topic_name).to eq("sleep-log-created")
  end

  it "returns the correct routing_key" do
    expect(subject.routing_key).to eq(user_id.to_s)
  end

  it "returns the correct data payload" do
    expected_data = {
      user_id: user_id,
      sleep_log_id: sleep_log_id
    }
    expect(subject.data).to eq(expected_data)
  end
end
