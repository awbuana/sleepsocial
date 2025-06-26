require 'rails_helper'
require 'timecop'

RSpec.describe LeaderboardService::BackfillFeedByUser, type: :service do
  let!(:user) { create(:user) }
  let!(:followed_user) { create(:user) }
  let(:frozen_time) { Time.zone.parse("2024-06-25 10:00:00 UTC") }

  # Instantiate the service object.
  let(:service) { described_class.new(user, followed_user) }

  let(:user_feed_mock) { instance_double(UserFeed) }
  let(:leaderboard_threshold_time) { frozen_time - 7.days } # Logs older than this are considered "too old"

  before do
    Timecop.freeze(frozen_time)

    # Mock the `UserFeed.new` call to return our controlled mock object.
    allow(UserFeed).to receive(:new).with(user).and_return(user_feed_mock)
    allow(user_feed_mock).to receive(:add_to_feed) # Stub this method, we'll verify it's called.

    # Mock the `leaderboard_threshold` method that the service calls.
    allow_any_instance_of(LeaderboardService::BackfillFeedByUser).to receive(:leaderboard_threshold).and_return(leaderboard_threshold_time)

    # By default, assume a follow relationship exists for successful scenarios.
    allow(Follow).to receive(:find_by).with(user_id: user.id, target_user_id: followed_user.id).and_return(instance_double(Follow))

    # Mock the ActiveRecord Relation for followed_user.sleep_logs for `find_in_batches`.
    # This is crucial for controlling what logs are "found" and yielded.
    # We create a mock relation that responds to `where`, `order`, and `find_in_batches`.
    sleep_logs_relation_mock = instance_double(ActiveRecord::Relation)
    allow(followed_user).to receive(:sleep_logs).and_return(sleep_logs_relation_mock)

    # Chain the `where` and `order` calls, making them return the same mock relation.
    allow(sleep_logs_relation_mock).to receive(:where).with("clock_in > ?", leaderboard_threshold_time).and_return(sleep_logs_relation_mock)
    allow(sleep_logs_relation_mock).to receive(:order).with(:id).and_return(sleep_logs_relation_mock)
    allow(sleep_logs_relation_mock).to receive(:find_in_batches).and_yield([]) # Default to yielding an empty array
  end

  after do
    Timecop.return # Unfreeze time after each test.
  end

  describe '#perform' do
    context 'when the user follows the followed_user' do
      # Let's define some sample sleep logs for the followed_user.
      let!(:finished_log_1) { create(:sleep_log, user: followed_user, clock_in: frozen_time - 2.days, clock_out: frozen_time - 1.day, id: 101) } # Within threshold, finished
      let!(:finished_log_2_old) { create(:sleep_log, user: followed_user, clock_in: frozen_time - 8.days, clock_out: frozen_time - 7.days - 1.hour, id: 102) } # Outside threshold, finished
      let!(:pending_log) { create(:sleep_log, user: followed_user, clock_in: frozen_time - 3.days, clock_out: nil, id: 103) } # Within threshold, not finished
      let!(:finished_log_3) { create(:sleep_log, user: followed_user, clock_in: frozen_time - 4.days, clock_out: frozen_time - 3.days, id: 104) } # Within threshold, finished

      before do
        # Configure `find_in_batches` to yield batches of our test logs.
        # Ensure logs are yielded in the order they would be fetched (by ID).
        allow(followed_user.sleep_logs).to receive(:find_in_batches) do |&block|
          # Filter logs by clock_in > leaderboard_threshold_time before yielding.
          # The mock relation already handles `where` and `order`, so here we just simulate yielding.
          relevant_logs = [ finished_log_1, finished_log_2_old, pending_log, finished_log_3 ].select do |log|
            log.clock_in > leaderboard_threshold_time
          end.sort_by(&:id) # Sort by ID as per `order(:id)`

          # Yield in batches (e.g., in a single batch for simplicity here)
          block.call(relevant_logs)
        end
      end

      it 'iterates through relevant sleep logs of the followed user' do
        service.perform
        # Verify that `where` and `order` were called on the relation.
        expect(followed_user.sleep_logs).to have_received(:where).with("clock_in > ?", leaderboard_threshold_time)
        expect(followed_user.sleep_logs).to have_received(:order).with(:id)
        # Verify that `find_in_batches` was called.
        expect(followed_user.sleep_logs).to have_received(:find_in_batches)
      end

      it 'adds only finished sleep logs within the threshold to the user feed' do
        service.perform
        # `finished_log_1` and `finished_log_3` should be added.
        expect(user_feed_mock).to have_received(:add_to_feed).with(finished_log_1)
        expect(user_feed_mock).to have_received(:add_to_feed).with(finished_log_3)
      end

      it 'does not add unfinished sleep logs to the user feed' do
        service.perform
        # `pending_log` should not be added.
        expect(user_feed_mock).not_to have_received(:add_to_feed).with(pending_log)
      end

      it 'does not add sleep logs older than the leaderboard threshold' do
        service.perform
        # `finished_log_2_old` should not be added because its clock_in is too old.
        expect(user_feed_mock).not_to have_received(:add_to_feed).with(finished_log_2_old)
      end

      it 'initializes UserFeed for the current user' do
        service.perform
        expect(UserFeed).to have_received(:new).with(user)
      end
    end

    context 'when the user does NOT follow the followed_user' do
      before do
        allow(Follow).to receive(:find_by).with(user_id: user.id, target_user_id: followed_user.id).and_return(nil)
      end

      it 'does not initialize UserFeed' do
        service.perform
        expect(UserFeed).not_to have_received(:new)
      end

      it 'does not query for followed user\'s sleep logs' do
        service.perform
        expect(followed_user).not_to have_received(:sleep_logs)
      end

      it 'does not add any logs to the user feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:add_to_feed)
      end

      it 'returns nil due to early return' do
        expect(service.perform).to be_nil
      end
    end

    context 'when followed_user has no relevant sleep logs' do
      before do
        allow(followed_user.sleep_logs).to receive(:find_in_batches).and_yield([])
      end

      it 'does not call add_to_feed' do
        service.perform
        expect(user_feed_mock).not_to have_received(:add_to_feed)
      end
    end
  end
end
