module SleepLogService
  class Error < BaseService::ServiceError; end

  module_function

  def create_log(*args); SleepLogService::CreateLog.new(*args).perform; end
end