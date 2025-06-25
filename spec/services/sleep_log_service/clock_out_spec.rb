require 'rails_helper'
require 'timecop' # Ensure Timecop is available for time manipulation

RSpec.describe SleepLogService::ClockOut, type: :service do
  let!(:user) { create(:user) }
  let!(:sleep_log) { create(:sleep_log, user: user, clock_out: nil) } # Start with no clock_out

  let(:valid_clock_out_time) { Time.current - 1.hour }
  let(:service) { described_class.new(user, sleep_log, valid_clock_out_time.to_s) }

  before do
    Timecop.freeze(Time.current)

    allow_any_instance_of(SleepLogService::ClockOut).to receive(:now_with_buffer).and_return(Time.current)

    event_mock = instance_double(Event::SleepLogCreated,
                                 payload: { user_id: user.id, sleep_log_id: sleep_log.id }.to_json,
                                 topic_name: "sleep_log_events",
                                 routing_key: user.id.to_s)
    allow(Event::SleepLogCreated).to receive(:new).with(user.id, sleep_log.id).and_return(event_mock)
  allow(Racecar).to receive(:produce_sync)
  end

  # After each test, unfreeze time to prevent interference with other tests.
  after do
    Timecop.return
  end

  describe '#perform' do
    context 'when the clock out is valid and successful' do
      it 'sets the clock_out time on the sleep log' do
        service.perform
        expect(sleep_log.reload.clock_out.to_i).to eq(valid_clock_out_time.to_i)
      end

      it 'saves the sleep log to the database' do
        expect { service.perform }.not_to raise_error
        expect(sleep_log.reload.clock_out).not_to be_nil
      end

      it 'publishes a sleep log created event to Kafka' do
        service.perform

        expect(Racecar).to have_received(:produce_sync).with(
          value: { user_id: user.id, sleep_log_id: sleep_log.id }.to_json,
          topic: "sleep_log_events",
          partition_key: user.id.to_s
        )
      end

      it 'returns the updated sleep log object' do
        returned_sleep_log = service.perform
        expect(returned_sleep_log).to eq(sleep_log)
        expect(returned_sleep_log.clock_out.to_i).to eq(valid_clock_out_time.to_i)
      end

      it 'ensures the database operations are atomic (transactional)' do
        allow(sleep_log).to receive(:save!).and_raise(StandardError, "Simulated transaction failure")

        initial_clock_out = sleep_log.clock_out # Should be nil initially

        expect { service.perform }.to raise_error(StandardError, "Simulated transaction failure")

        expect(sleep_log.reload.clock_out).to eq(initial_clock_out)
        expect(Racecar).not_to have_received(:produce_sync)
      end
    end

    context 'when there are validation errors' do
      context 'when the sleep log does not belong to the user' do
        let!(:other_user) { create(:user) }
        let!(:sleep_log) { create(:sleep_log, user: other_user, clock_out: nil) }

        it 'raises a Sleepsocial::PermissionDeniedError' do
          expect { service.perform }.to raise_error(Sleepsocial::PermissionDeniedError)
        end

        it 'does not update the sleep log' do
          initial_clock_out = sleep_log.clock_out
          expect { service.perform rescue nil }.not_to change { sleep_log.reload.clock_out }
          expect(sleep_log.reload.clock_out).to eq(initial_clock_out)
        end

        it 'does not publish any Kafka event' do
          service.perform rescue nil
          expect(Racecar).not_to have_received(:produce_sync)
        end
      end

      context 'when the user has already clocked out' do
        let!(:sleep_log) { create(:sleep_log, user: user, clock_out: Time.current - 2.hours) }

        it 'raises a SleepLogService::Error for already clocked out' do
          expect { service.perform }.to raise_error(SleepLogService::Error, "User already clocked out")
        end

        it 'does not update the sleep log' do
          initial_clock_out = sleep_log.clock_out
          expect { service.perform rescue nil }.not_to change { sleep_log.reload.clock_out }
          expect(sleep_log.reload.clock_out).to eq(initial_clock_out)
        end

        it 'does not publish any Kafka event' do
          service.perform rescue nil
          expect(Racecar).not_to have_received(:produce_sync)
        end
      end

      context 'when clock_out is in the future' do
        let(:valid_clock_out_time) { Time.current + 1.minute }

        it 'raises a SleepLogService::Error for clock out in the future' do
          expect { service.perform }.to raise_error(SleepLogService::Error, /Clock out must be lower than/)
        end

        it 'does not update the sleep log' do
          initial_clock_out = sleep_log.clock_out
          expect { service.perform rescue nil }.not_to change { sleep_log.reload.clock_out }
          expect(sleep_log.reload.clock_out).to eq(initial_clock_out)
        end

        it 'does not publish any Kafka event' do
          service.perform rescue nil
          expect(Racecar).not_to have_received(:produce_sync)
        end
      end
    end
  end
end
