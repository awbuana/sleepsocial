# spec/services/leaderboard_service/remove_user_from_feed_spec.rb

require 'rails_helper'
require 'timecop' # For controlling time in tests

RSpec.describe LeaderboardService::RemoveUserFromFeed, type: :service do
  let!(:user) { create(:user) }
  let!(:target_user) { create(:user) }
  let!(:another_user) { create(:user) } # For testing mixed feed content

  let(:service) { described_class.new(user, target_user.id) }

  let(:user_feed_mock) { instance_double(UserFeed) }

  let(:target_user_log_1) { UserFeed::Member.new(1, target_user.id, Time.current - 5.hours) }
  let(:target_user_log_2) { UserFeed::Member.new(2, target_user.id, Time.current - 10.hours) }
  let(:another_user_log) { UserFeed::Member.new(3, another_user.id, Time.current - 7.hours) }

  before do
    Timecop.freeze(Time.current)

    allow(UserFeed).to receive(:new).with(user).and_return(user_feed_mock)
    allow(user_feed_mock).to receive(:feed).and_return([target_user_log_1, target_user_log_2, another_user_log])
    allow(user_feed_mock).to receive(:remove_from_feed) # Stub this method, we'll verify it's called.
    allow(Follow).to receive(:find_by).with(user_id: user.id, target_user_id: target_user.id).and_return(nil)
  end

  after do
    Timecop.return # Unfreeze time after each test
  end

  describe '#perform' do
    context 'when the user does NOT follow the target user' do

      it 'fetches the user feed' do
        service.perform
        expect(user_feed_mock).to have_received(:feed)
      end

      it 'removes only the target user\'s logs from the feed' do
        service.perform
        expect(user_feed_mock).to have_received(:remove_from_feed).with([target_user_log_1, target_user_log_2])
      end

      context 'and there are no logs from the target user in the feed' do
        before do
          allow(user_feed_mock).to receive(:feed).and_return([another_user_log])
        end

        it 'calls remove_from_feed with an empty array' do
          service.perform
          expect(user_feed_mock).to have_received(:remove_from_feed).with([])
        end
      end

      context 'and the user feed is empty' do
        before do
          allow(user_feed_mock).to receive(:feed).and_return([])
        end

        it 'calls remove_from_feed with an empty array' do
          service.perform
          expect(user_feed_mock).to have_received(:remove_from_feed).with([])
        end
      end
    end

    context 'when the user DOES follow the target user' do
      let!(:existing_follow) { instance_double(Follow) }

      before do
        allow(Follow).to receive(:find_by).with(user_id: user.id, target_user_id: target_user.id).and_return(existing_follow)
      end

      it 'does not fetch the user feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:feed)
      end

      it 'does not remove any logs from the feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:remove_from_feed)
      end

      it 'returns nil (due to early return)' do
        expect(service.perform).to be_nil
      end
    end
  end
end
