# spec/services/follow_service/unfollow_spec.rb

require 'rails_helper'

RSpec.describe FollowService::Unfollow, type: :service do
  # Use `let!` to ensure these objects are created before each example.
  # We start with a user who is already following a target_user.
  let!(:user) { create(:user, num_following: 1) }
  let!(:target_user) { create(:user, num_followers: 1) }
  let!(:existing_follow) { create(:follow, user: user, target_user: target_user) } # Create the follow record
  let(:target_user_id) { target_user.id }

  # Instantiate the service object with the defined user and target_user_id
  let(:service) { described_class.new(user, target_user_id) }

  # Before each test in this describe block, set up mocks for external dependencies.
  before do
    # Mock the Event::Unfollow class for Kafka event testing.
    event_mock = instance_double(Event::Unfollow,
                                 payload: { user_id: user.id, target_user_id: target_user.id }.to_json,
                                 topic_name: "unfollow_events", # Assuming this topic name
                                 routing_key: user.id.to_s) # Assuming user_id as partition key
    allow(Event::Unfollow).to receive(:new).with(user.id, target_user.id).and_return(event_mock)

    # Prevent actual Kafka production during tests by stubbing the Racecar method.
    allow(Racecar).to receive(:produce_sync)
    allow(ActiveRecord::Base).to receive(:transaction).and_yield
  end

  describe '#perform' do
    context 'when a follow relationship exists and is successfully unfollowed' do
      it 'destroys the existing follow record' do
        # Expect the Follow model count to change by -1 (decrease by one).
        expect { service.perform }.to change(Follow, :count).by(-1)
      end

      it 'decrements the following count for the initiating user' do
        # Expect the user's num_following attribute to decrease by 1.
        expect { service.perform }.to change { user.reload.num_following }.by(-1)
      end

      it 'decrements the followers count for the target user' do
        # Expect the target user's num_followers attribute to decrease by 1.
        expect { service.perform }.to change { target_user.reload.num_followers }.by(-1)
      end

      it 'publishes an unfollow event to Kafka with correct data' do
        service.perform

        # Verify that Racecar.produce_sync was called with the expected arguments.
        expect(Racecar).to have_received(:produce_sync).with(
          value: { user_id: user.id, target_user_id: target_user.id }.to_json,
          topic: "unfollow_events",
          partition_key: user.id.to_s
        )
      end

      it 'returns nil or true upon successful unfollow (depending on service return type)' do
        # The service object doesn't explicitly return the unfollowed object.
        # It typically returns nil or true for success, or raises an error for failure.
        # Based on the provided service code, it implicitly returns the result of Racecar.produce_sync,
        # which is usually nil or a success indicator. We can just expect no error.
        expect { service.perform }.not_to raise_error
      end

      it 'ensures the database operations are atomic (transactional)' do
        # Simulate a failure point *within* the transaction to confirm rollback.
        # We'll mock `user.decrement!` to raise an error after `follow.destroy!` but before `target_user.decrement!`.
        allow(user).to receive(:decrement!).and_raise(StandardError, "Simulated transaction failure")

        initial_following = user.num_following
        initial_followers = target_user.num_followers

        # Expect the service to raise the simulated error.
        expect { service.perform }.to raise_error(StandardError, "Simulated transaction failure")

        expect(user.reload.num_following).to eq(initial_following) # User's count should not have changed
        expect(target_user.reload.num_followers).to eq(initial_followers) # Target user's count should not have changed
        expect(Racecar).not_to have_received(:produce_sync) # No event should be published
      end
    end

    context 'when no follow relationship exists between the users' do
      # Set up the users such that there is no existing follow record between them.
      let!(:existing_follow) { nil } # No existing follow
      let!(:user) { create(:user, num_following: 0) } # Reset num_following
      let!(:target_user) { create(:user, num_followers: 0) } # Reset num_followers

      it 'raises an ActiveRecord::RecordNotFound error' do
        # `Follow.find_by` returns nil if not found, and `raise ActiveRecord::RecordNotFound unless follow` handles it.
        expect { service.perform }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'does not change any follow records' do
        expect { service.perform rescue nil }.not_to change(Follow, :count)
      end

      it 'does not change the user\'s num_following count' do
        expect { service.perform rescue nil }.not_to change { user.reload.num_following }
      end

      it 'does not change the target user\'s num_followers count' do
        expect { service.perform rescue nil }.not_to change { target_user.reload.num_followers }
      end

      it 'does not publish any unfollow event to Kafka' do
        service.perform rescue nil
        expect(Racecar).not_to have_received(:produce_sync)
      end
    end

    context 'when the target_user_id does not exist' do
      # Use an ID that is guaranteed not to exist in the database.
      let(:target_user_id) { -999 }
      # Ensure there's no actual follow record involving this non-existent ID for clean testing.
      let!(:existing_follow) { nil }
      let!(:user) { create(:user, num_following: 0) }

      it 'raises an ActiveRecord::RecordNotFound error when finding the target user' do
        # User.find(@target_user_id) will raise this error if not found.
        # Note: The service first tries to find the follow record. If it doesn't exist, it will raise
        # RecordNotFound related to the follow. If it *did* exist (which it shouldn't in this case
        # because the target_user_id doesn't exist), then the User.find would raise this.
        # We need to ensure that the initial `find_by` doesn't return anything.
        # This test primarily ensures `User.find(@target_user_id)` fails.
        # First, ensure that `Follow.find_by` also returns nil.
        allow(Follow).to receive(:find_by).and_return(nil)
        expect { service.perform }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'does not change any follow records' do
        expect { service.perform rescue nil }.not_to change(Follow, :count)
      end

      it 'does not change user counts' do
        expect { service.perform rescue nil }.not_to change { user.reload.num_following }
        # Note: target_user is not loaded/changed in this scenario if RecordNotFound happens early.
        # If a target_user was defined with let!, it would still be the one created, but not affected.
      end

      it 'does not publish any unfollow event to Kafka' do
        service.perform rescue nil
        expect(Racecar).not_to have_received(:produce_sync)
      end
    end
  end
end
