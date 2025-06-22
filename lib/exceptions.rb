# frozen_string_literal: true

module Sleepsocial
  class Error < StandardError; end
  class NotPermittedError < Error; end
  class ValidationError < Error; end
end
