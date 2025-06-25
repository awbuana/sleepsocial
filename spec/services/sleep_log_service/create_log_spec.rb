# spec/services/sleep_log_service/create_log_spec.rb

require 'rails_helper'
require 'timecop' # For controlling time in tests

RSpec.describe SleepLogService::CreateLog, type: :service do
  let!(:user) { create(:user) }
  let(:frozen_time) { Time.zone.parse("2024-06-25 10:00:00 UTC") }

  let(:params) do
    {
      clock_in: frozen_time - 8.hours, # 02:00:00 UTC
      clock_out: frozen_time - 1.hour  # 09:00:00 UTC
    }
  end

  let(:service) { described_class.new(user, params) }

  before do
    Timecop.freeze(frozen_time)
    allow_any_instance_of(SleepLogService::CreateLog).to receive(:now_with_buffer).and_return(Time.current)

    event_mock = instance_double(Event::SleepLogCreated,
                                 payload: { user_id: user.id, sleep_log_id: anything }.to_json,
                                 topic_name: "sleep_log_events",
                                 routing_key: user.id.to_s)
    allow(Event::SleepLogCreated).to receive(:new).with(user.id, anything).and_return(event_mock)
    allow(Racecar).to receive(:produce_sync)
    allow(ActiveRecord::Base).to receive(:transaction).and_yield
  end

  after do
    Timecop.return
  end

  describe '#perform' do
    context 'when the log creation is valid and successful' do
      context 'with both clock_in and clock_out provided' do
        it 'creates a new sleep log record in the database' do
          expect { service.perform }.to change(SleepLog, :count).by(1)
        end

        it 'sets the correct clock_in and clock_out times' do
          log = service.perform
          expect(log.user).to eq(user)
          expect(log.clock_in.to_i).to eq(params[:clock_in].to_i)
          expect(log.clock_out.to_i).to eq(params[:clock_out].to_i)
          expect(log).to be_persisted # Ensure it's saved
        end

        it 'publishes a sleep log created event to Kafka' do
          log = service.perform
          expect(Racecar).to have_received(:produce_sync).with(
            value: { user_id: user.id, sleep_log_id: anything }.to_json,
            topic: "sleep_log_events",
            partition_key: user.id.to_s
          )
        end

        it 'returns the newly created sleep log object' do
          returned_log = service.perform
          expect(returned_log).to be_a(SleepLog)
          expect(returned_log.user).to eq(user)
          expect(returned_log.clock_in.to_i).to eq(params[:clock_in].to_i)
        end
      end

      context 'with only clock_in provided (creating a pending log)' do
        let(:params) do
          {
            clock_in: frozen_time - 2.hours, # 08:00:00 UTC
            clock_out: nil # No clock_out
          }
        end

        it 'creates a new sleep log record with clock_out as nil' do
          expect { service.perform }.to change(SleepLog, :count).by(1)
          log = SleepLog.last
          expect(log.user).to eq(user)
          expect(log.clock_in.to_i).to eq(params[:clock_in].to_i)
          expect(log.clock_out).to be_nil
        end

        it 'does not publish a Kafka event' do
          service.perform
          expect(Racecar).not_to have_received(:produce_sync)
        end

        it 'returns the newly created pending sleep log object' do
          returned_log = service.perform
          expect(returned_log).to be_a(SleepLog)
          expect(returned_log.clock_out).to be_nil
        end
      end

      context 'when clock_in is not provided (defaults to Time.now.utc)' do
        let(:params) do
          {
            clock_in: nil, # Clock in is nil
            clock_out: nil
          }
        end

        it 'creates a new sleep log record with clock_in set to current time' do
          expect { service.perform }.to change(SleepLog, :count).by(1)
          log = SleepLog.last
          expect(log.user).to eq(user)
          expect(log.clock_in.to_i).to be_within(1).of(frozen_time.to_i)
          expect(log.clock_out).to be_nil
        end
      end
    end

    context 'when there are validation errors' do
      context 'when a pending log already exists for the user' do
        let!(:pending_log) { create(:sleep_log, user: user, clock_out: nil) }

        it 'raises a SleepLogService::Error' do
          expect { service.perform }.to raise_error(SleepLogService::Error, "User must clock out pending log first")
        end

        it 'does not create a new sleep log' do
          expect { service.perform rescue nil }.not_to change(SleepLog, :count)
        end

        it 'does not publish any Kafka event' do
          service.perform rescue nil
          expect(Racecar).not_to have_received(:produce_sync)
        end
      end

      context 'when clock_in time overlaps with an existing sleep log' do
        # Test scenarios for overlapping:
        # Existing: [-----]
        # New:      [--] (new inside existing)
        # New:    [-------] (existing inside new)
        # New: [----] (partial overlap at start)
        # New:    [----] (partial overlap at end)
        let!(:existing_sleep_log) do
          create(:sleep_log, user: user,
                 clock_in: frozen_time - 10.hours, # 00:00:00 UTC
                 clock_out: frozen_time - 5.hours) # 05:00:00 UTC
        end

        context 'when the new log is entirely within an existing log' do
          let(:params) do
            {
              clock_in: frozen_time - 8.hours, # 02:00:00 UTC
              clock_out: frozen_time - 7.hours  # 03:00:00 UTC
            }
          end

          it 'raises a SleepLogService::Error' do
            expect { service.perform }.to raise_error(SleepLogService::Error, "Clock in time is overlapped with existing sleep log")
          end
        end

        context 'when an existing log is entirely within the new log' do
          let(:params) do
            {
              clock_in: frozen_time - 12.hours, # 22:00:00 UTC (previous day)
              clock_out: frozen_time - 2.hours  # 08:00:00 UTC
            }
          end

          it 'raises a SleepLogService::Error' do
            expect { service.perform }.to raise_error(SleepLogService::Error, "Clock in time is overlapped with existing sleep log")
          end
        end

        context 'when the new log partially overlaps at the start' do
          let(:params) do
            {
              clock_in: frozen_time - 12.hours, # 22:00:00 UTC (previous day)
              clock_out: frozen_time - 6.hours  # 04:00:00 UTC
            }
          end

          it 'raises a SleepLogService::Error' do
            expect { service.perform }.to raise_error(SleepLogService::Error, "Clock in time is overlapped with existing sleep log")
          end
        end

        context 'when the new log partially overlaps at the end' do
          let(:params) do
            {
              clock_in: frozen_time - 6.hours, # 04:00:00 UTC
              clock_out: frozen_time - 1.hour  # 09:00:00 UTC
            }
          end

          it 'raises a SleepLogService::Error' do
            expect { service.perform }.to raise_error(SleepLogService::Error, "Clock in time is overlapped with existing sleep log")
          end
        end

        context 'when clock_in is exactly the same as an existing clock_out' do
          let(:params) do
            {
              clock_in: frozen_time - 5.hours, # 05:00:00 UTC (exactly existing_sleep_log.clock_out)
              clock_out: frozen_time - 4.hours
            }
          end

          it 'raises a SleepLogService::Error' do
            # This should still raise if the query is `clock_in <= new_clock_in AND clock_out >= new_clock_in`
            # which it is.
            expect { service.perform }.to raise_error(SleepLogService::Error, "Clock in time is overlapped with existing sleep log")
          end
        end

        context 'when clock_out is exactly the same as an existing clock_in' do
          let(:params) do
            {
              clock_in: frozen_time - 11.hours,
              clock_out: frozen_time - 10.hours # 00:00:00 UTC (exactly existing_sleep_log.clock_in)
            }
          end

          it 'raises a SleepLogService::Error' do
            expect { service.perform }.to raise_error(SleepLogService::Error, "Clock in time is overlapped with existing sleep log")
          end
        end

        it 'does not create a new sleep log during overlap' do
          expect { service.perform rescue nil }.not_to change(SleepLog, :count)
        end

        it 'does not publish any Kafka event during overlap' do
          service.perform rescue nil
          expect(Racecar).not_to have_received(:produce_sync)
        end
      end

      context 'when clock_in is in the future' do
        let(:params) do
          {
            clock_in: frozen_time + 1.minute, # 1 minute in the future
            clock_out: nil
          }
        end

        it 'raises a SleepLogService::Error' do
          expect { service.perform }.to raise_error(SleepLogService::Error, /Clock in must be lower than/)
        end

        it 'does not create a new sleep log' do
          expect { service.perform rescue nil }.not_to change(SleepLog, :count)
        end

        it 'does not publish any Kafka event' do
          service.perform rescue nil
          expect(Racecar).not_to have_received(:produce_sync)
        end
      end

      context 'when clock_out is in the future (and clock_in is valid)' do
        let(:params) do
          {
            clock_in: frozen_time - 2.hours,
            clock_out: frozen_time + 1.minute # 1 minute in the future
          }
        end

        it 'raises a SleepLogService::Error' do
          expect { service.perform }.to raise_error(SleepLogService::Error, /Clock out must be lower than/)
        end

        it 'does not create a new sleep log' do
          expect { service.perform rescue nil }.not_to change(SleepLog, :count)
        end

        it 'does not publish any Kafka event' do
          service.perform rescue nil
          expect(Racecar).not_to have_received(:produce_sync)
        end
      end
    end

    context 'when a database transaction error occurs' do
      let(:params) do
        {
          clock_in: frozen_time - 3.hours,
          clock_out: frozen_time - 1.hour
        }
      end

      it 'rolls back all changes and does not produce event' do
        allow_any_instance_of(SleepLog).to receive(:save!).and_raise(StandardError, "Simulated transaction failure")
        expect { service.perform }.to raise_error(StandardError, "Simulated transaction failure")

        expect_any_instance_of(SleepLog).not_to receive(:save!) # No new log should be created
        expect(Racecar).not_to have_received(:produce_sync) # No event should be published
      end
    end
  end
end
