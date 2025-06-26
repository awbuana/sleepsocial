require 'rails_helper'
require 'timecop' # For controlling time in tests

RSpec.describe LeaderboardService::BackfillFeedByFollowing, type: :service do
  let!(:user) { create(:user, last_backfill_at: nil) } # User performing the backfill
  let!(:followed_user_1) { create(:user) }
  let!(:followed_user_2) { create(:user) }

  # Create follow relationships for the 'user'
  let!(:follow_1) { create(:follow, user: user, target_user: followed_user_1, id: 1) }
  let!(:follow_2) { create(:follow, user: user, target_user: followed_user_2, id: 2) }

  # Instantiate the service object
  let(:service) { described_class.new(user) }

  # A fixed "current" time for consistent testing.
  let(:frozen_time) { Time.zone.parse("2024-06-25 10:00:00 UTC") }

  before do
    # Freeze time for consistent test results, especially for `Time.now.utc` and `6.hour.ago.utc`.
    Timecop.freeze(frozen_time)

    # Stub `Racecar` methods to prevent actual Kafka calls.
    allow(Racecar).to receive(:produce_async)
    # The `wait_for_delivery` method takes a block. Simulate calling that block.
    allow(Racecar).to receive(:wait_for_delivery).and_yield


    # Mock the ActiveRecord Relation for `user.following` for `find_in_batches`.
    # This is crucial for controlling what followings are "found" and yielded.
    followings_relation_mock = instance_double(ActiveRecord::Relation)
    allow(user).to receive(:following).and_return(followings_relation_mock)
    # Chain the `order` call, making it return the same mock relation.
    allow(followings_relation_mock).to receive(:order).with(:id).and_return(followings_relation_mock)
    allow(followings_relation_mock).to receive(:find_in_batches).and_yield([ follow_1, follow_2 ])
  end

  after do
    Timecop.return # Unfreeze time after each test.
  end

  describe '#perform' do
    context 'when the user has not been recently backfilled' do
      before do
        # Ensure `last_backfill_at` is nil or older than 6 hours for this context.
        user.update_column(:last_backfill_at, frozen_time - 7.hours) # Or nil, as per initial `let!`
      end

      it 'updates the user\'s last_backfill_at timestamp' do
        expect(user).to receive(:update!).with(last_backfill_at: anything)
        service.perform
      end

      it 'iterates through the user\'s followings' do
        service.perform
        # Verify that `order` and `find_in_batches` were called on the `following` relation.
        expect(user.following).to have_received(:order).with(:id)
        expect(user.following).to have_received(:find_in_batches)

        allow(Racecar).to receive(:produce_async)
      end

      it 'produces an async Kafka event for each followed user' do
        service.perform
        # Verify `Racecar.produce_async` was called with the correct event payloads.
        expect(Racecar).to have_received(:produce_async).exactly(2).times
      end

      it 'waits for Kafka messages to be delivered' do
        service.perform
        expect(Racecar).to have_received(:wait_for_delivery)
      end

      context 'when the user has 1 followings' do
        let(:event) { Event::BackfillFeedByUser.new(user.id, follow_1.id) }

        before do
          # Override `find_in_batches` to yield an empty array.
          allow(user.following).to receive(:find_in_batches).and_yield([ follow_1 ])
        end

        it 'produces an async Kafka event for each followed user' do
          service.perform
          # Verify `Racecar.produce_async` was called with the correct event payloads.
          expect(Racecar).to have_received(:produce_async).with({
            value: event.payload,
            partition_key: event.routing_key,
            topic: event.topic_name
          })
        end
      end

      context 'when the user has no followings' do
        before do
          # Override `find_in_batches` to yield an empty array.
          allow(user.following).to receive(:find_in_batches).and_yield([])
        end

        it 'updates the user\'s last_backfill_at timestamp' do
          service.perform
          expect(user.reload.last_backfill_at).to be_within(1.second).of(frozen_time)
        end

        it 'does not produce any Kafka events' do
          service.perform
          expect(Racecar).not_to have_received(:produce_async)
        end

        it 'still calls wait_for_delivery' do
          service.perform
          # `wait_for_delivery` block is still called, even if no messages were put into the queue.
          expect(Racecar).to have_received(:wait_for_delivery)
        end
      end
    end

    context 'when the user has been recently backfilled (within 6 hours)' do
      before do
        # Set `last_backfill_at` to be very recent.
        user.update_column(:last_backfill_at, frozen_time - 5.hours)
      end

      it 'does not update the user\'s last_backfill_at timestamp' do
        initial_last_backfill_at = user.last_backfill_at
        service.perform
        expect(user.reload.last_backfill_at).to eq(initial_last_backfill_at)
      end

      it 'does not query for user\'s followings' do
        service.perform
        # The service returns early, so `user.following` should not be accessed.
        expect(user).not_to have_received(:following) # This might need to be stubbed on the user object itself
      end

      it 'does not produce any Kafka events' do
        service.perform
        expect(Racecar).not_to have_received(:produce_async)
      end

      it 'does not call wait_for_delivery' do
        service.perform
        expect(Racecar).not_to have_received(:wait_for_delivery)
      end

      it 'returns nil due to early return' do
        expect(service.perform).to be_nil
      end
    end
  end
end
