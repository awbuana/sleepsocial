module SleepLogService
  class CreateLog < ::BaseService

    def initialize(user, options = {})
      @user = user
    end

    def perform
      log = SleepLog.new

      ActiveRecord::Base.transaction(isolation: :serializable) do
        pending_log = SleepLog.find_by(user_id: @user, clock_out: nil)
        raise SleepLogService::Error.new('User must clock out pending log first') if pending_log

        log.user = @user
        log.clock_in = Time.now.utc
        log.save!

        log
      end

      FeedFanOutJob.perform_async(log.id)

      log
    end

  end
end