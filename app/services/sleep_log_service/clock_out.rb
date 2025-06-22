module SleepLogService
  class ClockOut < ::BaseService
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

      FeedFanOutJob.perform_async(@sleep_log.id)

      @sleep_log
    end

    private

    def validate!
      raise Sleepsocial::PermissionDeniedError if @sleep_log.user_id != @user.id
      raise SleepLogService::Error.new("Clock out must be present") unless @clock_out
      raise SleepLogService::Error.new("User already clocked out") if @sleep_log.clock_out
      raise SleepLogService::Error.new("Clock out must be lower than now") if @clock_out > Time.now.utc + 15.seconds # buffer
    end
  end
end
