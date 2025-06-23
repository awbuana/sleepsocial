module SleepLogService
  class CreateLog < SleepLogService::Base
    def initialize(user, params, options = {})
      @user = user
      @clock_in = params[:clock_in]
      @clock_out = params[:clock_out]
    end

    def perform
      validate!

      log = SleepLog.new

      ActiveRecord::Base.transaction(isolation: :serializable) do
        pending_log = SleepLog.find_by(user_id: @user, clock_out: nil)
        raise SleepLogService::Error.new("User must clock out pending log first") if pending_log

        overlapped = SleepLog.where("user_id = ? AND clock_in <= ? AND clock_out >= ?", @user.id, @clock_in, @clock_in).exists?
        overlapped ||= SleepLog.where("user_id = ? AND clock_in >= ? AND clock_out <= ?", @user.id, @clock_in, @clock_out).exists?
        raise SleepLogService::Error.new("Clock in time is overlapped with existing sleep log") if overlapped

        log.user = @user
        log.clock_in =  @clock_in || Time.now.utc
        log.clock_out = @clock_out if @clock_out.present?
        log.save!

        log
      end


      produce_event(log) if log.clock_out.present?

      log
    end

    private

    def validate!
      now = now_with_buffer
      raise SleepLogService::Error.new("Clock in must be lower than #{now}") if @clock_in > now
      raise SleepLogService::Error.new("Clock out must be lower than #{now}") if @clock_out && @clock_out > now
    end

    def produce_event(log)
      event = Event::SleepLogCreated.new(log.user_id, log.id)
      Racecar.produce_sync(value: event.payload, topic: event.topic_name, partition_key: event.routing_key)
    end
  end
end
