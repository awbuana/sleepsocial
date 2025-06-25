module SleepLogService
  class ClockOut < SleepLogService::Base
    def initialize(user, sleep_log, clock_out, options = {})
      @user = user
      @sleep_log = sleep_log
      @clock_out = Time.parse(clock_out)
    end

    def perform
      validate!

      ActiveRecord::Base.transaction do
        @sleep_log.lock!

        @sleep_log.clock_out = @clock_out
        @sleep_log.save!
      end

      produce_event

      @sleep_log
    end

    private

    def validate!
      raise Sleepsocial::PermissionDeniedError if @sleep_log.user_id != @user.id
      raise SleepLogService::Error.new("User already clocked out") if @sleep_log.clock_out

      now = now_with_buffer
      raise SleepLogService::Error.new("Clock out must be lower than #{now}") if @clock_out > now
    end

    def produce_event
      event = Event::SleepLogCreated.new(@sleep_log.user_id, @sleep_log.id)
      Racecar.produce_sync(value: event.payload, topic: event.topic_name, partition_key: event.routing_key)
    end
  end
end
