require 'rails_helper'

RSpec.describe SleepLog, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    let(:user) { create(:user) }

    it 'is valid with a clock_in and clock_out where clock_out is greater than clock_in' do
      sleep_log = build(:sleep_log, user: user, clock_in: 8.hours.ago, clock_out: Time.current)
      expect(sleep_log).to be_valid
    end

    it 'is valid without a clock_out initially (user is currently sleeping)' do
      sleep_log = build(:sleep_log, user: user, clock_out: nil)
      expect(sleep_log).to be_valid
    end

    it 'is invalid when clock_out is less than clock_in' do
      sleep_log = build(:sleep_log, :invalid_times, user: user)
      expect(sleep_log).not_to be_valid
      expect(sleep_log.errors[:clock_out]).to include('must be greater than clock in')
    end

    it 'is invalid without a user' do
      sleep_log = build(:sleep_log, user: nil)
      expect(sleep_log).not_to be_valid
      expect(sleep_log.errors[:user]).to include('must exist')
    end
  end

  describe '#sleep_duration' do
    let(:user) { create(:user) }

    it 'returns nil if clock_out is not set' do
      sleep_log = build(:sleep_log, :no_clock_out, user: user)
      expect(sleep_log.sleep_duration).to be_nil
    end

    it 'calculates the correct sleep duration in hours' do
      # Example: 1 hour sleep
      sleep_log = build(:sleep_log, :short_sleep, user: user)
      expect(sleep_log.sleep_duration).to eq(1)

      # Example: 8 hour sleep
      sleep_log_long = build(:sleep_log, :long_sleep, user: user)
      expect(sleep_log_long.sleep_duration).to eq(10)

      # Test with minutes, ensuring it truncates to integer hours
      sleep_log_with_minutes = build(:sleep_log, user: user, clock_in: 8.hours.ago - 30.minutes, clock_out: Time.current)
      # 8.5 hours should return 8 (integer truncation)
      expect(sleep_log_with_minutes.sleep_duration).to eq(8)
    end
  end
end
