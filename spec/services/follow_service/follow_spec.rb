# spec/services/follow_service/follow_spec.rb

require 'rails_helper'

RSpec.describe FollowService::Follow, type: :service do
  let!(:user) { create(:user) }
  let!(:target_user) { create(:user) }
  let(:target_user_id) { target_user.id }

  let(:service) { described_class.new(user, target_user_id) }

  before do
    event_mock = instance_double(Event::Follow,
                                 payload: { user_id: user.id, target_user_id: target_user.id }.to_json,
                                 topic_name: "follow_events",
                                 routing_key: user.id.to_s)

    allow(Event::Follow).to receive(:new).with(user.id, target_user.id).and_return(event_mock)
    allow(Racecar).to receive(:produce_sync)
    allow(ActiveRecord::Base).to receive(:transaction).and_yield
  end

  describe '#perform' do
    context 'when the follow is valid and successful' do
      it 'creates a new follow record in the database' do
        expect { service.perform }.to change(Follow, :count).by(1)
      end

      it 'increments the following count for the initiating user' do
        expect { service.perform }.to change { user.reload.num_following }.by(1)
      end

      it 'increments the followers count for the target user' do
        expect { service.perform }.to change { target_user.reload.num_followers }.by(1)
      end

      it 'publishes a follow event to Kafka with correct data' do
        service.perform

        expect(Racecar).to have_received(:produce_sync).with(
          value: { user_id: user.id, target_user_id: target_user.id }.to_json,
          topic: "follow_events",
          partition_key: user.id.to_s
        )
      end

      it 'returns the newly created follow object' do
        returned_follow = service.perform

        expect(returned_follow).to be_a(Follow)
        expect(returned_follow.user).to eq(user)
        expect(returned_follow.target_user).to eq(target_user)
        expect(returned_follow).to be_persisted
      end

      it 'ensures the database operations are atomic (transactional)' do
        allow(user).to receive(:increment!).and_raise(StandardError, "Simulated transaction failure")

        initial_following = user.num_following
        initial_followers = target_user.num_followers

        expect { service.perform }.to raise_error(StandardError, "Simulated transaction failure")

        expect(user.reload.num_following).to eq(initial_following)
        expect(target_user.reload.num_followers).to eq(initial_followers)
        expect(Racecar).not_to have_received(:produce_sync)
      end
    end

    context 'when the user tries to follow themselves' do
      let(:target_user_id) { user.id }

      it 'raises a FollowService::Error with a specific message' do
        expect { service.perform }.to raise_error(FollowService::Error, "User must follow other users")
      end

      it 'does not create any new follow record' do
        expect { service.perform rescue nil }.not_to change(Follow, :count)
      end

      it 'does not increment the user\'s num_following count' do
        expect { service.perform rescue nil }.not_to change { user.reload.num_following }
      end

      it 'does not increment the target user\'s num_followers count' do
        expect { service.perform rescue nil }.not_to change { target_user.reload.num_followers }
      end

      it 'does not publish any follow event to Kafka' do
        service.perform rescue nil
        expect(Racecar).not_to have_received(:produce_sync)
      end
    end

    context 'when the target_user_id does not exist' do
      let(:target_user_id) { -999 }

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect { service.perform }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'does not create any new follow record' do
        expect { service.perform rescue nil }.not_to change(Follow, :count)
      end

      it 'does not increment user counts' do
        expect { service.perform rescue nil }.not_to change { user.reload.num_following }
        expect { service.perform rescue nil }.not_to change { target_user.reload.num_followers }
      end

      it 'does not publish any follow event to Kafka' do
        service.perform rescue nil
        expect(Racecar).not_to have_received(:produce_sync)
      end
    end
  end
end
