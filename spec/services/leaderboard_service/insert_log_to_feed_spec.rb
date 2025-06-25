# spec/services/leaderboard_service/insert_log_to_feed_spec.rb

require 'rails_helper'

RSpec.describe LeaderboardService::InsertLogToFeed, type: :service do
  let!(:user) { create(:user) }
  let!(:feeder_user) { create(:user) }
  let!(:sleep_log) { create(:sleep_log, user: feeder_user, clock_out: Time.current) } # Default to a finished log

  let(:service) { described_class.new(user, sleep_log) }

  let(:user_feed_mock) { instance_double(UserFeed) }

  before do
    allow(UserFeed).to receive(:new).with(user).and_return(user_feed_mock)

    allow(user_feed_mock).to receive(:add_to_feed)
    allow(user_feed_mock).to receive(:resize_feed)

    allow(Follow).to receive(:find_by).with(user_id: user.id, target_user_id: feeder_user.id).and_return(instance_double(Follow))
  end

  describe '#perform' do
    context 'when the sleep log is finished and the user follows the log owner' do
      
      it 'calls add_to_feed with the sleep log' do
        service.perform
        expect(user_feed_mock).to have_received(:add_to_feed).with(sleep_log)
      end

      it 'calls resize_feed to maintain feed size' do
        service.perform
        expect(user_feed_mock).to have_received(:resize_feed)
      end

      it 'returns nil upon successful operation (as per service implementation)' do
        expect(service.perform).to be_nil
      end
    end

    context 'when the sleep log is NOT finished (clock_out is nil)' do
      let!(:sleep_log) { create(:sleep_log, user: feeder_user, clock_out: nil) } # Override for this context

      it 'does not call add_to_feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:add_to_feed)
      end

      it 'does not call resize_feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:resize_feed)
      end

      it 'returns nil due to early return' do
        expect(service.perform).to be_nil
      end
    end

    context 'when the user does NOT follow the log owner' do
      before do
        # Override the `Follow.find_by` mock to simulate no follow relationship.
        allow(Follow).to receive(:find_by).with(user_id: user.id, target_user_id: feeder_user.id).and_return(nil)
      end

      it 'does not call add_to_feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:add_to_feed)
      end

      it 'does not call resize_feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:resize_feed)
      end

      it 'returns nil due to early return' do
        expect(service.perform).to be_nil
      end
    end

    context 'when both conditions are false (log not finished and no follow)' do
      let!(:sleep_log) { create(:sleep_log, user: feeder_user, clock_out: nil) } # Log not finished

      before do
        # No follow relationship
        allow(Follow).to receive(:find_by).with(user_id: user.id, target_user_id: feeder_user.id).and_return(nil)
      end

      it 'does not call add_to_feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:add_to_feed)
      end

      it 'does not call resize_feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:resize_feed)
      end

      it 'returns nil due to early return' do
        expect(service.perform).to be_nil
      end
    end
  end
end
