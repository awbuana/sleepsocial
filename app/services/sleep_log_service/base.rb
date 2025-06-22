module SleepLogService
  class Base < ::BaseService
    def now_with_buffer
      Time.now.utc + 15.seconds # buffer
    end
  end
end
