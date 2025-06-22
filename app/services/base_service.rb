# frozen_string_literal: true

class BaseService
  def perform(*)
    raise NotImplementedError
  end
end