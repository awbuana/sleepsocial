require 'rails_helper'
require 'timecop' # For controlling time in tests

RSpec.describe LeaderboardService::PrecomputedFeed, type: :service do
  let!(:user) { create(:user) }
  let(:frozen_time) { Time.zone.parse("2024-06-25 10:00:00 UTC") }
  let(:options) { {} }

  let(:service) { described_class.new(user, options) }

  # Mock the `UserFeed` object to control its behavior without hitting Redis.
  let(:user_feed_mock) { instance_double(UserFeed) }

  let(:leaderboard_threshold_time) { frozen_time - 3.hours } # Logs older than this are expired

  before do
    # Freeze time for consistent test results.
    Timecop.freeze(frozen_time)

    # Mock the `UserFeed.new` call to return our controlled mock object.
    allow(UserFeed).to receive(:new).with(user).and_return(user_feed_mock)

    allow(user_feed_mock).to receive(:feed)
    allow(user_feed_mock).to receive(:remove_from_feed)

    allow(SleepLog).to receive(:fetch_multi)
    allow_any_instance_of(LeaderboardService::PrecomputedFeed).to receive(:leaderboard_threshold).and_return(leaderboard_threshold_time)
  end

  after do
    Timecop.return # Unfreeze time after each test.
  end

  describe '#perform' do
    let!(:expired_sleep_log_1) { build_stubbed(:sleep_log, id: 10, user: create(:user), clock_out: frozen_time + 4.hours, clock_in: frozen_time - 4.hours) } # Expired
    let!(:valid_sleep_log_1) { build_stubbed(:sleep_log, id: 20, user: create(:user), clock_out: frozen_time + 200.hours, clock_in: frozen_time - 2.hours) } # Valid
    let!(:valid_sleep_log_2) { build_stubbed(:sleep_log, id: 30, user: create(:user), clock_out: frozen_time + 150.hours, clock_in: frozen_time - 1.hour) } # Valid
    let!(:expired_sleep_log_2) { build_stubbed(:sleep_log, id: 40, user: create(:user), clock_out: frozen_time + 50.hours, clock_in: frozen_time - 5.hours) } # Expired

    let(:expired_logs) {
      [
        UserFeed::Member.new(expired_sleep_log_1.id, expired_sleep_log_1.user_id, expired_sleep_log_1.clock_in),
        UserFeed::Member.new(expired_sleep_log_2.id, expired_sleep_log_2.user_id, expired_sleep_log_2.clock_in)
      ]
    }

    let(:user_feed_members) do
      [
        UserFeed::Member.new(valid_sleep_log_1.id, valid_sleep_log_1.user_id, valid_sleep_log_1.clock_in),
        UserFeed::Member.new(valid_sleep_log_2.id, valid_sleep_log_2.user_id, valid_sleep_log_2.clock_in)
      ] + expired_logs
    end

    before do
      # Configure `user_feed_mock.feed` to return our predefined members.
      # The arguments for `feed` are @offset and @limit + GET_FEED_LIMIT_BUFFER.
      # For default options, this means 0 and 20 + 50 = 70.
      allow(user_feed_mock).to receive(:feed).with(0, 70).and_return(user_feed_members)

      # Configure `SleepLog.fetch_multi` to return the actual ActiveRecord objects
      # when it's called with the IDs of the valid (non-expired) logs.
      allow(SleepLog).to receive(:fetch_multi).with([ valid_sleep_log_1.id, valid_sleep_log_2.id ], includes: :user)
                                              .and_return([ valid_sleep_log_1, valid_sleep_log_2 ])
    end

    context 'with default limit and offset' do
      it 'retrieves feeds with buffer from UserFeed' do
        service.perform
        # Default limit is 20, buffer is 50, so total is 70.
        expect(user_feed_mock).to have_received(:feed).with(0, 70)
      end

      it 'removes expired logs from the UserFeed' do
        service.perform
        # Expect `remove_from_feed` to be called with the identified expired logs.
        # Ensure the logs passed are the actual `UserFeed::Member` objects.
        expect(user_feed_mock).to have_received(:remove_from_feed).with(expired_logs)
      end

      it 'fetches only non-expired sleep logs from the database' do
        service.perform
        # Expect `fetch_multi` to be called with the IDs of valid logs.
        expect(SleepLog).to have_received(:fetch_multi).with([ valid_sleep_log_1.id, valid_sleep_log_2.id ], includes: :user)
      end

      it 'returns sleep logs sorted by sleep_duration descending, then id descending' do
        result = service.perform
        # The expected order for [valid_sleep_log_1 (200), valid_sleep_log_2 (150)]
        # should be valid_sleep_log_1 then valid_sleep_log_2.
        expect(result[:data]).to eq([ valid_sleep_log_1, valid_sleep_log_2 ])
      end

      it 'returns the correct limit and offset in the response' do
        result = service.perform
        expect(result[:limit]).to eq(20)
        expect(result[:offset]).to eq(0)
      end

      context 'when there are no expired logs' do
        let(:user_feed_members) do
          [
            UserFeed::Member.new(valid_sleep_log_1.id, valid_sleep_log_1.user_id, valid_sleep_log_1.clock_in),
            UserFeed::Member.new(valid_sleep_log_2.id, valid_sleep_log_2.user_id, valid_sleep_log_2.clock_in)
          ]
        end

        before do
          allow(user_feed_mock).to receive(:remove_from_feed)
        end

        it 'does not call remove_from_feed' do
          service.perform
          expect(user_feed_mock).not_to have_received(:remove_from_feed).with(anything)
        end

        it 'fetches all available valid logs' do
          service.perform
          expect(SleepLog).to have_received(:fetch_multi).with([ valid_sleep_log_1.id, valid_sleep_log_2.id ], includes: :user)
        end
      end

      context 'when the feed contains fewer logs than the limit after filtering' do
        # Assume only one valid log exists after filtering, and limit is 20.
        let(:user_feed_members) do
          [
            UserFeed::Member.new(valid_sleep_log_2.id, valid_sleep_log_2.user_id, valid_sleep_log_2.clock_in),
            UserFeed::Member.new(expired_sleep_log_1.id, expired_sleep_log_1.user_id, expired_sleep_log_1.clock_in)
          ]
        end

        before do
          allow(SleepLog).to receive(:fetch_multi).with([ valid_sleep_log_2.id ], includes: :user)
                                                  .and_return([ valid_sleep_log_2 ])
        end

        it 'returns all available valid logs, up to the limit' do
          result = service.perform
          expect(result[:data].size).to eq(1)
          expect(result[:data]).to eq([ valid_sleep_log_2 ])
        end
      end

      context 'when the feed is empty' do
        before do
          allow(user_feed_mock).to receive(:feed).with(0, 70).and_return([])
          allow(SleepLog).to receive(:fetch_multi).and_return([])
        end

        it 'returns an empty data array' do
          result = service.perform
          expect(result[:data]).to be_empty
        end
      end
    end

    context 'with custom limit and offset' do
      let(:options) { { limit: 1, offset: 1 } } # Requesting 1 log, skipping the first

      # Need to adjust mock `feed` call arguments based on custom options.
      before do
        # @offset is 1, @limit is 1, GET_FEED_LIMIT_BUFFER is 50.
        # So, feed call will be with (1, 1 + 50) = (1, 51).
        allow(user_feed_mock).to receive(:feed).with(1, 51).and_return(user_feed_members[1..-1]) # Simulate offset
        allow(SleepLog).to receive(:fetch_multi).with([ valid_sleep_log_2.id ], includes: :user)
                                                .and_return([ valid_sleep_log_2 ])
      end

      it 'retrieves feeds with the specified offset and buffered limit' do
        service.perform
        expect(user_feed_mock).to have_received(:feed).with(1, 51)
      end

      it 'returns logs based on the specified offset and limit' do
        result = service.perform
        # Given the offset 1 and limit 1, and the sorted non-expired logs [valid_sleep_log_1, valid_sleep_log_2],
        # it should return only valid_sleep_log_2.
        expect(result[:data]).to eq([ valid_sleep_log_2 ])
        expect(result[:limit]).to eq(1)
        expect(result[:offset]).to eq(1)
      end
    end

    context 'when fetch_multi returns logs not in order' do
      before do
        # The service sorts them after fetching, so this should still produce the correct sorted output.
        allow(SleepLog).to receive(:fetch_multi).with([ valid_sleep_log_1.id, valid_sleep_log_2.id ], includes: :user)
                                                .and_return([ valid_sleep_log_2, valid_sleep_log_1 ]) # Return in wrong order
      end

      it 'correctly sorts the sleep logs by sleep_duration and id' do
        result = service.perform
        expect(result[:data]).to eq([ valid_sleep_log_1, valid_sleep_log_2 ]) # Still expects correct sorted order
      end
    end
  end
end
