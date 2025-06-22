# frozen_string_literal: true

class BaseService
  class ServiceError < StandardError; end

  def perform(*)
    raise NotImplementedError
  end
end