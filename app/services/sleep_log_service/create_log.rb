module SleepLogService
  class CreateLog < ::BaseService

    def initialize(user, options = {})
      @user = user
    end

    def perform
      ActiveRecord::Base.transaction(isolation: :serializable) do
        pending_log = SleepLog.find_by(user_id: @user, clock_out: nil)
        raise SleepLogService::Error.new('User must clock out pending log first') if pending_log

        log = SleepLog.new
        log.user = @user
        log.save!

        log
      end
    end

  end
end