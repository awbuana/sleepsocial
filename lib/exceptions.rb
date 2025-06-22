# frozen_string_literal: true

module Sleepsocial
  class Error < StandardError; end
  class UnauthenticatedError < Error; end
  class PermissionDeniedError < Error; end
end
